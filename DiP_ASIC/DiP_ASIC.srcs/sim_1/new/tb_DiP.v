`timescale 1ns / 1ps

module tb_top;

    // ============================================================
    // 1. Parameters & Signals
    // ============================================================
    parameter N = 5;
    parameter BW = 16;
    parameter ACC_BW = 32;
    
    // Clock and Reset
    reg clk;
    reg rst_n;
    
    // Control Inputs
    reg start;
    reg [15:0] num_tiles;
    
    // Outputs
    wire busy;
    wire done;
    wire [ACC_BW-1:0] result_data [0:N-1]; // Array of outputs
    wire result_valid;

    // ============================================================
    // 2. Instantiate the Top Module
    // ============================================================
    dip_accelerator_top #(
        .N(N),
        .BW(BW),
        .ACC_BW(ACC_BW),
        .MEM_FILE_A("matrix_a.mem"),        // Ensure these files exist in Sim folder
        .MEM_FILE_B("weights_natural.mem")
    ) u_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .num_tiles(num_tiles),
        .busy(busy),
        .done(done),
        // .result_data(result_data), // NOTE: Verilog arrays in ports can be tricky
        // Some tools require flattening. For simulation, let's access internal wires if needed.
        .result_valid(result_valid)
    );

    // ============================================================
    // 3. Clock Generation (10ns Period = 100MHz)
    // ============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // 4. Test Sequence
    // ============================================================
    initial begin
        // --- Setup ---
        $display("------------------------------------------------");
        $display("Starting DiP Accelerator Simulation");
        $display("------------------------------------------------");
        
        // Initial Values
        rst_n = 0;
        start = 0;
        num_tiles = 1; // Process 1 Tile (4x4)
        
        // --- Apply Reset ---
        #20;
        rst_n = 1;
        $display("[%0t] Reset Released", $time);
        
        // --- Start Operation ---
        #20;
        start = 1;
        $display("[%0t] Start Pulse Applied", $time);
        #10;
        start = 0;

        // --- Wait for Completion ---
        wait(done);
        $display("[%0t] DONE signal received!", $time);
        
        // --- Small Delay to see final waves ---
        #50;
        
        $display("------------------------------------------------");
        $display("Simulation Completed Successfully");
        $display("------------------------------------------------");
        $finish;
    end
    
    // ============================================================
    // 5. Monitor Results
    // ============================================================
    // Since 'result_data' is an unpacked array output, it might be hard to connect
    // in standard Verilog depending on your tool version. 
    // We will "spy" on the internal array output to print it.
    
integer i;
    always @(posedge clk) begin
        if (result_valid) begin
            // 1. Print the timestamp and header
            $write("[%0t] Valid Output: ", $time);
            
            // 2. Loop through N elements using $write (no newline)
            for (i = 0; i < N; i = i + 1) begin
                $write("%d ", u_top.result_data[i]);
            end
            
            // 3. Finalize the line with a newline
            $display(""); 
        end
    end

endmodule