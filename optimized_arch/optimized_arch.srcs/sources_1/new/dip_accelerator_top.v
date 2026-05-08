`timescale 1ns / 1ps

module dip_accelerator_top #(
    parameter N = 6,                             // Scaled up to 6x6 array
    parameter BW = 16,                           // 16-bit inputs/weights
    parameter ACC_BW = 32,                       // 32-bit accumulator (Perfect ARM AXI match)
    parameter MAX_TILES = 30,                    // 30 tiles for deep power testing
    parameter MEM_FILE_A = "matrix_a.mem",       
    parameter MEM_FILE_B = "weights_natural.mem" 
)(
    // --- Standard Accelerator Control ---
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,          
    input  wire [7:0]  num_tiles,                

    output wire        busy,
    output wire        done,
    output wire        result_valid,

    // --- NEW: ARM Processor BRAM Read Interface (Port B) ---
    input  wire        arm_read_clk,
    input  wire        arm_read_en,
    input  wire [14:0] arm_read_addr,            // 16-bit address space from the processor
    output reg  [31:0] arm_read_data             // Native 32-bit data out to ARM AXI bus
);

    // ============================================================
    // Internal Wires
    // ============================================================
    wire [(N*ACC_BW)-1:0] result_data;
    
    wire wshift, pe_en, mul_en, adder_en;
    reg [15:0] addr_a;
    reg [15:0] addr_b;

    wire [(N*BW)-1:0] mem_a_data ;   
    wire [(N*BW)-1:0] mem_b_data ;   

    // ============================================================
    // 1. Streaming Controller
    // ============================================================
    dip_controller #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_controller (
        .clk(clk), .rst_n(rst_n), .start(start), .num_tiles(num_tiles),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .busy(busy), .done(done)
    );

    // ============================================================
    // 2. Input Address Generation
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a <= 0;
            addr_b <= N - 1; // Reverse loading for weights
        end else if (done) begin
            addr_a <= 0;
            addr_b <= N - 1; 
        end else begin
            if (pe_en) addr_a <= addr_a + 1;
            if (wshift) begin
                if (addr_b > 0) addr_b <= addr_b - 1; 
            end
        end
    end

    // ============================================================
    // 3. Memory Blocks (Inputs & Weights)
    // ============================================================
    weight_memory #(
        .N(N), .BW(BW), .MEM_FILE(MEM_FILE_B)
    ) u_mem_weights (
        .addr(addr_b),            
        .row_data_out(mem_b_data) 
    );

    matrix_memory #(
        .BW(BW), .N(N), .MAX_TILES(MAX_TILES), .MEM_FILE(MEM_FILE_A)
    ) u_mem_inputs (
        .ren(pe_en),              
        .addr(addr_a),            
        .row_data_out(mem_a_data) 
    );

    // ============================================================
    // 4. Systolic Array Core (The Math Engine)
    // ============================================================
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

// ============================================================
    // 5. Dual-Port BRAM Bridge (The ARM Interface)
    // ============================================================
    
    reg [11:0] write_addr; // 12 bits allows up to 4096 rows
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr <= 0;
        end else if (start) begin
            write_addr <= 0; // Reset for a new processing run
        end else if (result_valid) begin
            write_addr <= write_addr + 1;
        end
    end

    // FIX: Flattened into a single 1D Array to guarantee BRAM inference
    // 4096 rows, each row is 192-bits wide
    (* ram_style = "block" *) reg [(N*ACC_BW)-1:0] mem_array [0:4095]; 

    // PORT A: Accelerator Writing (125 MHz Clock)
    always @(posedge clk) begin
        if (result_valid) begin
            // Write all N columns simultaneously into the massive 192-bit row
            mem_array[write_addr] <= result_data;
        end
    end

    // PORT B: ARM Processor Reading (AXI Clock)
    wire [2:0]  target_col = arm_read_addr[14:12]; 
    wire [11:0] target_row = arm_read_addr[11:0];  
    
    // Intermediate register to hold the 192-bit word read from BRAM
    reg [(N*ACC_BW)-1:0] read_word;

    always @(posedge arm_read_clk) begin
        if (arm_read_en) begin
            // Read the full 192-bit row synchronously
            read_word <= mem_array[target_row];
        end
    end

    // Combinational multiplexer to extract the specific 32-bit column the ARM requested
    always @(*) begin
        arm_read_data = read_word[(target_col * ACC_BW) +: 32];
    end

endmodule