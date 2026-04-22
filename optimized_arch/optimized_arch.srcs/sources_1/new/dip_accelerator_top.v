`timescale 1ns / 1ps

module dip_accelerator_top #(
    parameter N = 3,            
    parameter BW = 8,          
    parameter ACC_BW = 16,      
    parameter MEM_FILE_A = "matrix_a.mem",       
    parameter MEM_FILE_B = "weights_pre_shifted.mem" 
)(
    input wire clk,
    input wire rst_n,
    input wire start,            
    input wire [2:0] num_tiles,

    output wire busy,
    output wire done,
    output wire result_valid    
);

    (* dont_touch = "true" *) wire [ACC_BW-1:0] result_data [0:N-1];
    
    wire wshift, pe_en, mul_en, adder_en;
    reg [15:0] addr_a;
    reg [15:0] addr_b;

    wire [BW-1:0] mem_a_data [0:N-1];   
    wire [BW-1:0] mem_b_data [0:N-1];   

    // 1. Controller
    dip_controller #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_controller (
        .clk(clk), .rst_n(rst_n), .start(start), .num_tiles(num_tiles),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .busy(busy), .done(done)
    );

    // 2. Address Generation (Pure Combinational Syncing)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a <= 0;
            addr_b <= N - 1; // Start at the bottom row of the text file!
        end else if (done) begin
            addr_a <= 0;
            addr_b <= N - 1; // Reset to the bottom row
        end else begin
            if (pe_en) addr_a <= addr_a + 1;
            
            // NO MORE 'start' kick needed! Pure reverse loading.
            if (wshift) begin
                if (addr_b > 0) addr_b <= addr_b - 1; 
            end
        end
    end

    // 3. Memory B (Combinational Pre-Shifted Weights)
    weight_memory #(
        .N(N), .BW(BW), .MEM_FILE(MEM_FILE_B)
    ) u_mem_weights (
        .addr(addr_b),            // No clk or ren needed!
        .row_data_out(mem_b_data) 
    );

    // 4. Memory A (Combinational Standard Inputs)
    matrix_memory #(
        .BW(BW), .N(N), .MEM_FILE(MEM_FILE_A)
    ) u_mem_inputs (
        .addr(addr_a),            // No clk or ren needed!
        .row_data_out(mem_a_data) 
    );

    // 5. Systolic Array Core
    dip_array #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_array_core (
        .clk(clk), .rst_n(rst_n),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .row_inputs(mem_a_data),
        .row_weight(mem_b_data), 
        .col_outputs(result_data)
    );

    assign result_valid = adder_en; 

endmodule