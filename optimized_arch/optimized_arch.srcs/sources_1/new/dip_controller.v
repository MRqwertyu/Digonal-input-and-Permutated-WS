`timescale 1ns / 1ps

module dip_controller #(
    parameter N = 3,
    parameter BW = 16,
    parameter ACC_BW = 32
)(
    input wire clk,
    input wire rst_n,
    input wire start,              
    input wire [7:0] num_tiles,   // Expanded to 8 bits to support 30+ tiles
    
    output reg wshift,
    output reg pe_en,
    output reg mul_en,
    output reg adder_en,
    
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
    
    localparam WEIGHT_LOAD_CYCLES = N;        
    
    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end
    
    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = WEIGHT_LOAD;
            end
            
            WEIGHT_LOAD: begin
                if (cycle_counter >= WEIGHT_LOAD_CYCLES - 1)
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
                // CONTINUOUS STREAMING MATH:
                // Time to feed all valid rows = (num_tiles * N)
                // Time to flush the final answers out = (2 * N)
                if (cycle_counter >= (num_tiles * N) + (2 * N) - 1) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                if (!start) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Cycle Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 16'd0;
        end else if (state != next_state) begin
            // Reset counter to 0 immediately when changing states
            cycle_counter <= 16'd0; 
        end else if (state == WEIGHT_LOAD || state == PROCESSING) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
    
    // Output Control Signals (Moore Machine)
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

            case (next_state) 
                WEIGHT_LOAD: begin
                    wshift    <= 1'b1;  
                    busy      <= 1'b1;
                end
                
                PROCESSING: begin
                    pe_en     <= 1'b1;  // Streams addresses 0 all the way to 89 perfectly
                    mul_en    <= 1'b1;  
                    adder_en  <= 1'b1;  
                    busy      <= 1'b1;
                end
                
                DONE: begin
                    done      <= 1'b1;
                end
            endcase
        end
    end

endmodule