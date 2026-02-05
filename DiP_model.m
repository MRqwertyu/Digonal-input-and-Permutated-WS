% DiP Systolic Array Simulator for Matrix Multiplication
% Based on "DiP: A Scalable, Energy-Efficient Systolic Array" [cite: 8, 178]
clear; clc;

%% 1. Configuration & Data Initialization
N = 4; % Array Size (N x N)
% Define Input Matrices (A x B = Y)
% Matrix A (Inputs) - Random integers
MatA = randi([1, 9], N, N);
% Matrix B (Weights) - Random integers
MatB = randi([1, 9], N, N);

fprintf('--- DiP Systolic Array Simulation (N=%d) ---\n', N);
disp('Matrix A (Inputs):'); disp(MatA);
disp('Matrix B (Weights):'); disp(MatB);
disp('Expected Result (MatA * MatB):'); disp(MatA * MatB);

%% 2. Weight Permutation (The "P" in DiP)
% Algorithm 1 from paper: Shift and rotate each column by its index [cite: 261, 268]
PermutatedWeights = zeros(N, N);
for col = 1:N
    % Get the column
    original_col = MatB(:, col);
    % Calculate shift amount (col index - 1 because MATLAB is 1-based)
    shift_amount = col - 1;
    % Circular shift (rotate up)
    perm_col = circshift(original_col, -shift_amount);
    PermutatedWeights(:, col) = perm_col;
end

disp('Permutated Weight Matrix (loaded into PEs):');
disp(PermutatedWeights);

%% 3. Simulation Setup
% Initialize Processing Elements (PEs)
% PEs structure: Value (Weight), PartialSum, InputBuffer
PEs = repmat(struct('Weight', 0, 'Psum', 0, 'InVal', 0), N, N);

% Load Weights into PEs (Stationary)
for r = 1:N
    for c = 1:N
        PEs(r,c).Weight = PermutatedWeights(r,c);
    end
end

% Total Cycles: 
% 2N + S - 2 (Latency) + Streaming overhead
% We will run enough cycles to ensure all partial sums flush out.
total_cycles = 3 * N; 
OutputMatrix = zeros(N, N);

fprintf('\n--- Cycle-Accurate Execution ---\n');

%% 4. Cycle-by-Cycle Execution
for cycle = 1:total_cycles
    
    % --- Step A: Move Partial Sums Down (Vertical Shift) ---
    % Do this in reverse order (bottom-up) to avoid overwriting before read
    for r = N:-1:1
        for c = 1:N
            if r == N
                % This is the bottom row. Psums exiting here are Final Results.
                % But we only capture valid results at specific times.
                % In hardware, these stream out. We capture them here.
                % (Note: Output timing depends on specific DiP pipeline depth)
            else
                % Pass Psum to the PE below
                PEs(r+1, c).Psum = PEs(r, c).Psum;
            end
        end
    end
    
    % Clear Psums for top row (new accumulations start here)
    for c = 1:N
        PEs(1, c).Psum = 0;
    end

    % --- Step B: Move Inputs Diagonally (DiP Dataflow) ---
    % Inputs move from PE(r, c) to PE(r+1, c+1) generally, 
    % but DiP connects Leftmost PE of a row to Rightmost PE of next row.
    % Ref: "leftmost PE column connected to rightmost PE column in subsequent row" 
    
    % Store current inputs to move them after processing
    current_inputs = zeros(N, N);
    for r = 1:N
        for c = 1:N
            current_inputs(r,c) = PEs(r,c).InVal;
        end
    end
    
    % Feed NEW inputs from Matrix A into the array
    % Input Matrix A is fed diagonally.
    % Row 'i' of A enters Row 'i' of PEs.
    % However, data is delayed/skewed.
    % In DiP: Input(row, cycle) logic.
    
    % Reset inputs for this cycle
    for r = 1:N
        for c = 1:N
            PEs(r,c).InVal = 0; 
        end
    end
    
    % Logic for data movement between PEs (Diagonal Interconnects)
    % [cite: 179] "Input matrix moves diagonally across the PEs"
    for r = 2:N
        % Connection: Row(r-1) -> Row(r)
        % Specifically: PE(r-1, 1) -> PE(r, N) (Wrap around diagonal)
        PEs(r, N).InVal = current_inputs(r-1, 1);
        
        % Standard Diagonal: PE(r-1, c+1) -> PE(r, c)
        % (Based on Fig 3a arrows: PE01->PE10, PE02->PE11) [cite: 278]
        for c = 1:N-1
            PEs(r, c).InVal = current_inputs(r-1, c+1);
        end
    end
    
    % Feed New Data from Matrix A into Row 1
    % The paper states inputs are loaded into the first row and shift down.
    % Cycle logic: element A(r, k) enters at specific time.
    % For DiP, entire rows of A are loaded into Row 0 of PEs over time?
    % Fig 3 shows: Cycle 0 -> Row 1 of inputs loaded to PE Row 0.
    input_row_idx = cycle; 
    if input_row_idx <= N
        % Load row 'input_row_idx' of Matrix A into top PE row
        % But we must align with the permutation. 
        % In Fig 3c, Input row (1,2,3) enters PE00, PE01, PE02 at Cycle 0.
        for c = 1:N
            PEs(1, c).InVal = MatA(input_row_idx, c);
        end
    end
    
    % --- Step C: Compute (MAC Operation) ---
    for r = 1:N
        for c = 1:N
            % MAC: Psum = Psum + (Weight * Input)
            % Note: In hardware, Psum calculation happens before shift or after.
            % We calculate NOW, and this result shifts down in Next Cycle.
            
            % If we strictly follow "Input moves diagonally", the input currently
            % residing in the PE is used.
            
            if PEs(r,c).InVal ~= 0
               product = PEs(r,c).Weight * PEs(r,c).InVal;
               PEs(r,c).Psum = PEs(r,c).Psum + product;
            end
        end
    end
    
    % --- Capture Outputs ---
    % Outputs emerge from the bottom row.
    % We capture the accumulated Psum from the bottom row PEs *after* calculation
    % but before they are overwritten/cleared in next loop.
    % We accumulate results into a buffer because multiple partials pass through.
    % Wait... In WS, the partial sum moves down collecting terms. 
    % When it leaves the bottom, it is the FINAL answer for that indices pair.
    
    % Logic check: A row of Matrix A interacts with all weights.
    % The 'Psum' traveling down represents one element of the Output Matrix Y.
    % Which element? It depends on the input timing.
    
    % Simply capturing the values exiting the bottom row:
    if cycle >= N
        output_row_idx = cycle - N + 1; % Simple offset calculation
        if output_row_idx <= N
            % In DiP, output rows emerge sequentially (Cycle 3, 4, 5 in Fig 3)
            for c = 1:N
                % The value currently in the bottom row (before shifting out)
                % is the result for Output(output_row_idx, c)
                % *Wait*, due to permutation, the columns might be rotated?
                % Fig 3(c) Cycle 3: Output Row 1 exits.
                % Fig 3(c) Cycle 4: Output Row 2 exits.
                OutputMatrix(output_row_idx, c) = PEs(N, c).Psum;
            end
        end
    end
end

fprintf('Simulation Complete.\n');
disp('Simulated Output Matrix:');
disp(OutputMatrix);

% Verification
Difference = abs((MatA * MatB) - OutputMatrix);
if sum(Difference(:)) == 0
    disp('SUCCESS: Simulation matches expected matrix multiplication.');
else
    disp('WARNING: Mismatch detected. Debugging required.');
    disp('Difference:'); disp(Difference);
end