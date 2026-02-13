`timescale 1ns / 1ps

module dip_controller #(
    parameter N = 4,
    parameter BW = 16,
    parameter ACC_BW = 32
)(
    input wire clk,
    input wire rst_n,
    input wire start,              // Start processing
    input wire [15:0] num_tiles,   // Number of input tiles to process
    
    // Control outputs to array
    output reg wshift,
    output reg pe_en,
    output reg mul_en,
    output reg adder_en,
    
    // Status outputs
    output reg busy,
    output reg done
);

    // FSM States
    localparam IDLE        = 3'd0;
    localparam WEIGHT_LOAD = 3'd1;
    localparam PROCESSING  = 3'd2;
    localparam DONE        = 3'd3;
    
    reg [2:0] state, next_state;
    reg [15:0] cycle_counter;
    reg [15:0] tile_counter;
    
    // Cycle requirements based on paper [cite: 1]
    // Loading takes N cycles (to shift weights all the way down)
    localparam WEIGHT_LOAD_CYCLES = N+1;        
    // Processing takes 2N cycles to fully flush the systolic wave (Latency = 2N)
    localparam PROCESSING_CYCLES = 4*N-5;       
    
    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = WEIGHT_LOAD;
            end
            
            WEIGHT_LOAD: begin
                // -1 because counter starts at 0
                if (cycle_counter >= WEIGHT_LOAD_CYCLES -1)
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
                // Condition 1: Current tile cycle is finished
                if (cycle_counter >= PROCESSING_CYCLES - 1) begin
                    // Condition 2: Was this the last tile?
                    // FIX: Check if we are at (num_tiles - 1)
                    if (tile_counter >= num_tiles - 1)
                        next_state = DONE;
                    else
                        // Determine if we repeat PROCESSING for next tile
                        next_state = PROCESSING; 
                end
            end
            
            DONE: begin
                if (!start)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Cycle Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 16'd0;
        end else begin
            case (state)
                WEIGHT_LOAD: begin
                    if (cycle_counter >= WEIGHT_LOAD_CYCLES - 1)
                        cycle_counter <= 16'd0;
                    else
                        cycle_counter <= cycle_counter + 1;
                end
                
                PROCESSING: begin
                    if (cycle_counter >= PROCESSING_CYCLES - 1)
                        cycle_counter <= 16'd0;
                    else
                        cycle_counter <= cycle_counter + 1;
                end
                
                default: cycle_counter <= 16'd0;
            endcase
        end
    end
    
    // Tile Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tile_counter <= 16'd0;
        end else if (state == IDLE) begin
            tile_counter <= 16'd0;
        end else if (state == PROCESSING) begin
            // Increment only at the very end of a processing block
            if (cycle_counter >= PROCESSING_CYCLES - 1)
                tile_counter <= tile_counter + 1;
        end
    end
    
    // Output Control Signals
    // Note: Registered outputs (Moore Machine) introduce 1 cycle delay 
    // relative to state transition, which aligns perfectly with counters starting at 0.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wshift    <= 1'b0;
            pe_en     <= 1'b0;
            mul_en    <= 1'b0;
            adder_en  <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
        end else begin
            // Defaults
            wshift    <= 1'b0;
            pe_en     <= 1'b0;
            mul_en    <= 1'b0;
            adder_en  <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;

            case (next_state) // Optimization: Use next_state to remove 1-cycle output latency
                IDLE: begin
                   // All 0
                end
                
                WEIGHT_LOAD: begin
                    wshift    <= 1'b1;  // Load Weights
                    busy      <= 1'b1;
                end
                
                PROCESSING: begin
                    pe_en     <= 1'b1;  // Move Inputs Diagonally
                    mul_en    <= 1'b1;  // Multiply
                    adder_en  <= 1'b1;  // Accumulate
                    busy      <= 1'b1;
                end
                
                DONE: begin
                    done      <= 1'b1;
                end
            endcase
        end
    end

endmodule