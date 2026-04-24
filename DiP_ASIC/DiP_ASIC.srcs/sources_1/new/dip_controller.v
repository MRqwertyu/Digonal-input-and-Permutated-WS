`timescale 1ns / 1ps

module dip_controller #(
<<<<<<< HEAD
    parameter N = 3,
=======
    parameter N = 4,
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    parameter BW = 16,
    parameter ACC_BW = 32
)(
    input wire clk,
    input wire rst_n,
<<<<<<< HEAD
    input wire start,              
    input wire [7:0] num_tiles,   // Expanded to 8 bits to support 30+ tiles
    
=======
    input wire start,              // Start processing
    input wire [2:0] num_tiles,   // Number of input tiles to process
    
    // Control outputs to array
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    output reg wshift,
    output reg pe_en,
    output reg mul_en,
    output reg adder_en,
    
<<<<<<< HEAD
=======
    // Status outputs
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
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
<<<<<<< HEAD
    
    localparam WEIGHT_LOAD_CYCLES = N;        
    
    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
=======
    reg [15:0] tile_counter;
    
    // Cycle requirements based on paper [cite: 1]
    // Loading takes N cycles (to shift weights all the way down)
    localparam WEIGHT_LOAD_CYCLES = N;        
    // Processing takes 2N cycles to fully flush the systolic wave (Latency = 2N)
    localparam PROCESSING_CYCLES = 3*N-1;       
    
    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    end
    
    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
<<<<<<< HEAD
                if (start) next_state = WEIGHT_LOAD;
            end
            
            WEIGHT_LOAD: begin
                if (cycle_counter >= WEIGHT_LOAD_CYCLES - 1)
=======
                if (start)
                    next_state = WEIGHT_LOAD;
            end
            
            WEIGHT_LOAD: begin
                // -1 because counter starts at 0
                if (cycle_counter >= WEIGHT_LOAD_CYCLES -1)
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
<<<<<<< HEAD
                // CONTINUOUS STREAMING MATH:
                // Time to feed all valid rows = (num_tiles * N)
                // Time to flush the final answers out = (2 * N)
                if (cycle_counter >= (num_tiles * N) + (2 * N) - 1) begin
                    next_state = DONE;
=======
                // Condition 1: Current tile cycle is finished
                if (cycle_counter >= PROCESSING_CYCLES - 1) begin
                    // Condition 2: Was this the last tile?
                    // FIX: Check if we are at (num_tiles - 1)
                    if (tile_counter >= num_tiles - 1)
                        next_state = DONE;
                    else
                        // Determine if we repeat PROCESSING for next tile
                        next_state = PROCESSING; 
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
                end
            end
            
            DONE: begin
<<<<<<< HEAD
                if (!start) next_state = IDLE;
=======
                if (!start)
                    next_state = IDLE;
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Cycle Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 16'd0;
<<<<<<< HEAD
        end else if (state != next_state) begin
            // Reset counter to 0 immediately when changing states
            cycle_counter <= 16'd0; 
        end else if (state == WEIGHT_LOAD || state == PROCESSING) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
    
    // Output Control Signals (Moore Machine)
=======
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
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
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

<<<<<<< HEAD
            case (next_state) 
                WEIGHT_LOAD: begin
                    wshift    <= 1'b1;  
=======
            case (next_state) // Optimization: Use next_state to remove 1-cycle output latency
                IDLE: begin
                   // All 0
                end
                
                WEIGHT_LOAD: begin
                    wshift    <= 1'b1;  // Load Weights
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
                    busy      <= 1'b1;
                end
                
                PROCESSING: begin
<<<<<<< HEAD
                    pe_en     <= 1'b1;  // Streams addresses 0 all the way to 89 perfectly
                    mul_en    <= 1'b1;  
                    adder_en  <= 1'b1;  
=======
                    pe_en     <= 1'b1;  // Move Inputs Diagonally
                    mul_en    <= 1'b1;  // Multiply
                    adder_en  <= 1'b1;  // Accumulate
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
                    busy      <= 1'b1;
                end
                
                DONE: begin
                    done      <= 1'b1;
                end
            endcase
        end
    end

endmodule