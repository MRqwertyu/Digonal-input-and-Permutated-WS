`timescale 1ns / 1ps

module dip_accelerator_top #(
    parameter N = 6,            
    parameter BW = 16,          
    parameter ACC_BW = 32,      
    parameter MAX_TILES = 30,                                    
    parameter MEM_FILE_A = "matrix_a.mem",       
    parameter MEM_FILE_B = "weights_natural.mem" 
)(
    input wire clk,
    input wire rst_n,
    input wire start,            
    input wire [7:0] num_tiles,                                  

    output wire busy,
    output wire done,
    output wire result_valid,
    
    // --- The ARM BRAM Read Ports ---
    input  wire        arm_read_clk,
    input  wire        arm_read_en,
    input  wire [14:0] arm_read_addr,
    output reg  [31:0] arm_read_data
);

    // Internal wire for the 192-bit flattened array output
    (* dont_touch = "true" *) wire [(N*ACC_BW)-1:0] result_data; 
    
    wire wshift, pe_en, mul_en, adder_en;
    reg [15:0] addr_a;
    reg [15:0] addr_b; 

    // FLATTENED TO 1D VECTORS
    wire [(N*BW)-1:0] mem_a_data;   
    wire [(N*BW)-1:0] mem_b_data;   

    // 1. Controller 
    dip_controller #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_controller (
        .clk(clk), .rst_n(rst_n), .start(start), .num_tiles(num_tiles),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .busy(busy), .done(done)
    );

    // 2. Address Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a <= 0;
            addr_b <= 0;
        end else if (done) begin
            addr_a <= 0;
            addr_b <= 0;
        end else begin
            if (pe_en)  addr_a <= addr_a + 1;
            if (wshift) addr_b <= addr_b + 1;
        end
    end

    // 3. Memory A (Standard Inputs)
    matrix_memory #(
        .BW(BW), .N(N), .MAX_TILES(MAX_TILES), .MEM_FILE(MEM_FILE_A) 
    ) u_mem_inputs (
        .ren(pe_en), 
        .addr(addr_a),            
        .row_data_out(mem_a_data) 
    );

    // 4. Memory B (Permutating Weights)
    permutating_weight_memory #(
        .N(N), .BW(BW), .DEPTH(N), .MEM_FILE(MEM_FILE_B) 
    ) u_mem_weights (
        .ren(wshift),          
        .base_addr(addr_b[3:0]), 
        .row_data_out(mem_b_data) 
    );

    // 5. Systolic Array Core (Isomorphic Version)
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

    // =========================================================
    // 6. DUAL-PORT BRAM BRIDGE (INTERNAL)
    // =========================================================
    // This creates a small memory block inside the FPGA fabric.
    // Sized for 16 words, perfectly fitting N=6 results.
    reg [31:0] internal_bram [0:15]; 
    
    integer i;
    
    // PORT A: Hardware Write (192-bits parallel)
    always @(posedge clk) begin
        if (result_valid) begin
            // Slice the 192-bit wire into six 32-bit chunks and store them
            for (i = 0; i < N; i = i + 1) begin
                internal_bram[i] <= result_data[i*ACC_BW +: ACC_BW];
            end
        end
    end

    // PORT B: Software Read (32-bits sequential)
    always @(posedge arm_read_clk) begin
        if (arm_read_en) begin
            // AXI addresses are byte-aligned (0, 4, 8...). 
            // Dropping the bottom 2 bits [14:2] divides by 4 to get the word index (0, 1, 2...)
            arm_read_data <= internal_bram[arm_read_addr[14:2]];
        end
    end

endmodule