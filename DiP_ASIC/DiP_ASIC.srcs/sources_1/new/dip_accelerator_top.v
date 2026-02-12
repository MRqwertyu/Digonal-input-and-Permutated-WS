`timescale 1ns / 1ps

module dip_accelerator_top #(
    parameter N = 4,            // Array Size (N x N)
    parameter BW = 16,          // Data Bit Width
    parameter ACC_BW = 32,      // Accumulator Bit Width
    parameter MEM_FILE_A = "inputs.mem",       // Normal Input Matrix
    parameter MEM_FILE_B = "weights_natural.mem" // Normal Weight Matrix (Hardware handles permutation!)
)(
    input wire clk,
    input wire rst_n,
    input wire start,           // Start Signal
    input wire [15:0] num_tiles,// Number of tiles to process

    // Status Outputs
    output wire busy,
    output wire done,

    // Data Outputs (Result from the bottom of the array)
    output wire [ACC_BW-1:0] result_data [0:N-1],
    output wire result_valid    // Indicates when valid results stream out
);

    /* ----------------------------------------------------------------
     * Internal Signals
     * ---------------------------------------------------------------- */
    
    // Control Signals
    wire wshift;
    wire pe_en;
    wire mul_en;
    wire adder_en;

    // Data Buses
    wire [BW-1:0] mem_a_data [0:N-1];   // From Memory A -> Array Inputs
    wire [BW-1:0] mem_b_data [0:N-1];   // From Permutated Memory B -> Array Weights

    // Memory Address Pointers
    reg [15:0] addr_a;
    reg [15:0] addr_b;

    /* ----------------------------------------------------------------
     * 1. The Controller Instance
     * ---------------------------------------------------------------- */
    dip_controller #(
        .N(N), 
        .BW(BW), 
        .ACC_BW(ACC_BW)
    ) u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .num_tiles(num_tiles),
        
        // Control Outputs
        .wshift(wshift),
        .pe_en(pe_en),
        .mul_en(mul_en),
        .adder_en(adder_en),
        
        // Status
        .busy(busy),
        .done(done)
    );

    /* ----------------------------------------------------------------
     * 2. Address Generation Logic
     * ---------------------------------------------------------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a <= 16'd0;
            addr_b <= 16'd0;
        end else if (done) begin
            addr_a <= 16'd0;
            addr_b <= 16'd0;
        end else begin
            // Increment Input Address (Matrix A) during processing
            if (pe_en) 
                addr_a <= addr_a + 1;
                
            // Increment Weight Address (Matrix B) during loading
            if (wshift) 
                addr_b <= addr_b + 1;
        end
    end

    /* ----------------------------------------------------------------
     * 3. Memory Instances
     * ---------------------------------------------------------------- */
    
    // Memory A (Standard Inputs)
    matrix_memory #(
        .BW(BW), 
        .N(N), 
        .MEM_FILE(MEM_FILE_A)
    ) u_mem_inputs (
        .clk(clk),
        .rst_n(rst_n),
        .ren(pe_en),      
        .addr(addr_a),    
        .row_data_out(mem_a_data)
    );

    // Memory B (PERMUTATING WEIGHT MEMORY)
    // This is the custom module we designed to handle the rotation logic.
    permutating_weight_memory #(
        .N(N),
        .BW(BW),
        .DEPTH(16) // Ensure this is deep enough for your matrix size
    ) u_mem_weights_permutated (
        .clk(clk),
        .ren(wshift),          // Read enable comes from wshift
        .base_addr(addr_b[3:0]), // Connect the lower bits of our address counter
        .row_data_out(mem_b_data) // Connects directly to the array's row_weight input
    );

    /* ----------------------------------------------------------------
     * 4. The Systolic Array Core
     * ---------------------------------------------------------------- */
    dip_array #(
        .N(N), 
        .BW(BW), 
        .ACC_BW(ACC_BW)
    ) u_array_core (
        .clk(clk),
        .rst_n(rst_n),
        
        // Controls
        .wshift(wshift),
        .pe_en(pe_en),
        .mul_en(mul_en),
        .adder_en(adder_en),
        
        // Data Inputs
        .row_inputs(mem_a_data),
        .row_weight(mem_b_data), // Now receiving correctly permutated data!
        
        // Data Outputs
        .col_outputs(result_data)
    );

    /* ----------------------------------------------------------------
     * 5. Output Valid Logic
     * ---------------------------------------------------------------- */
    assign result_valid = adder_en; 

endmodule