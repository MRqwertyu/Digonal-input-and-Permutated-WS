% DiP vs TPU-like WS Architectural Evaluator
% Evaluates MHA and FFN workloads for an N_p x N_p systolic array

clear; clc;

%% 1. Architecture Parameters
Np = 64; % Physical array dimension (64x64)
S = 2;   % MAC pipeline stages

% Calculate latency per tile based on analytical models
% WS: 3N + S - 3
cycles_per_tile_ws = 3*Np + S - 3; 
% DiP: 2N + S - 2
cycles_per_tile_dip = 2*Np + S - 2;

%% 2. Define Transformer Workloads 
% Format: [M, K, N] for Matrix A(M x K) * Matrix B(K x N)
% M = Sequence Length, K = Input Feature Dim, N = Output Feature Dim

workloads = struct();
% Multi-Head Attention (Q, K, V Projections)
workloads(1).name = 'MHA Small (GPT-2)'; workloads(1).dims = [128, 768, 768];
workloads(2).name = 'MHA Medium (BERT)'; workloads(2).dims = [512, 1024, 1024];
workloads(3).name = 'MHA Large (GPT-3)'; workloads(3).dims = [2048, 12288, 12288];

% Feed-Forward Networks (FFN1 expansion)
workloads(4).name = 'FFN Small (GPT-2)'; workloads(4).dims = [128, 768, 3072];
workloads(5).name = 'FFN Medium (BERT)'; workloads(5).dims = [512, 1024, 4096];
workloads(6).name = 'FFN Large (GPT-3)'; workloads(6).dims = [2048, 12288, 49152];

num_workloads = length(workloads);
total_cycles_ws = zeros(num_workloads, 1);
total_cycles_dip = zeros(num_workloads, 1);
names = cell(num_workloads, 1);

%% 3. Compute Tiling and Cycle Latency
for i = 1:num_workloads
    M = workloads(i).dims(1);
    K = workloads(i).dims(2);
    N = workloads(i).dims(3);
    
    % Calculate number of hardware tiles required
    tiles_M = ceil(M / Np);
    tiles_K = ceil(K / Np);
    tiles_N = ceil(N / Np);
    total_tiles = tiles_M * tiles_K * tiles_N;
    
    % Total compute cycles (assuming tile latency bounds throughput)
    total_cycles_ws(i) = total_tiles * cycles_per_tile_ws;
    total_cycles_dip(i) = total_tiles * cycles_per_tile_dip;
    
    names{i} = workloads(i).name;
end

%% 4. Calculate Speedup and Plot
speedup = total_cycles_ws ./ total_cycles_dip;

% Made the figure slightly wider for better x-axis spacing
figure('Name', 'DiP vs WS Transformer Evaluation', 'Position', [100, 100, 900, 500]);
b = bar(speedup, 'FaceColor', [0.18, 0.31, 0.56]); 

% FIX 1: Manually set the Y-axis limit higher so text doesn't hit the ceiling
ylim([0, 1.8]); 

% FIX 2: Moved the baseline label to sit neatly below the line
yline(1, '--k', 'Baseline (WS)', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

set(gca, 'xticklabel', names, 'TickLabelInterpreter', 'none', 'FontSize', 10);

% FIX 3: Gentler angle for the X-axis labels so they don't cramp
xtickangle(25); 

ylabel('Latency Improvement Factor (x)', 'FontWeight', 'bold');
title('DiP vs. TPU-like WS: MHA & FFN Workloads (64x64 Array)', 'FontWeight', 'bold', 'FontSize', 12);
grid on;

% FIX 4: Add a tiny numerical offset (+0.03) to ytips to lift the text off the bar
xtips = b.XEndPoints;
ytips = b.YEndPoints;
labels = string(round(b.YData, 2)) + "x";
text(xtips, ytips + 0.03, labels, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
%% 5. Console Output
disp('--- Empirical Evaluation Results ---');
for i = 1:num_workloads
    fprintf('%-18s: WS Cycles = %-10d | DiP Cycles = %-10d | Speedup = %.2fx\n', ...
        names{i}, total_cycles_ws(i), total_cycles_dip(i), speedup(i));
end