`timescale 1ns/1ps

module tb_zeropadding;

    // Parameters (exact match to design)
    parameter payload_w = 8;
    parameter rate_mode = "H";
    parameter max_payload_length = 127;
    parameter header_length = 12;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg [payload_w-1 : 0] data_i;
    reg [$clog2(max_payload_length)-1 : 0] payload_length;
    reg empty;
    reg en;
    reg mode;

    wire valid;
    wire next_item;
    wire data_o;

    // Instantiate the Unit Under Test (UUT)
    zeropadding #(
        .payload_w(payload_w),
        .rate_mode(rate_mode),
        .max_payload_length(max_payload_length),
        .header_length(header_length)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(data_i),
        .payload_length(payload_length),
        .empty(empty),
        .en(en),
        .mode(mode),
        .valid(valid),
        .next_item(next_item),
        .data_o(data_o)
    );

    // Clock generation (32 MHz equivalent or standard 10ns period)
    always #5 clk = ~clk;

    // Stimulus process
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        en = 0;
        empty = 1;
        mode = 0;
        payload_length = 0;
        data_i = 8'h00;

        // Apply reset
        #20;
        rst_n = 1;
        #20;
        

        // ---------------------------------------------------------
        // TEST CASE 1: Mode = 0 (2 payload bytes)
        // ---------------------------------------------------------
        $display("--- Starting Test Case 1: Mode = 0, Payload = 2 bytes ---");
        mode = 0;
        en = 1;
        payload_length = 8'd2; 
        empty = 0;             
        data_i = 8'hA5;        

        #280;

        empty = 1;
        #1000;
        en = 0;

        // ---------------------------------------------------------
        // TEST CASE 2: Mode = 1 (2 payload bytes)
        // ---------------------------------------------------------
        $display("--- Starting Test Case 2: Mode = 1, Payload = 2 bytes ---");
        rst_n = 0;
        #20;
        rst_n = 1;
        #20;
        en = 1;
        mode = 1;
        payload_length = 8'd2; 
        empty = 0;             
        data_i = 8'h5A;        

        #280;

        empty = 1;
        #150;

        // ---------------------------------------------------------
        // TEST CASE 3: Mode = 0 (3 payload bytes)
        // ---------------------------------------------------------
        $display("--- Starting Test Case 3: Mode = 0, Payload = 3 bytes ---");
        rst_n = 0;
        en = 1;
        mode = 1;
        payload_length = 8'd3; // Payload of 3 bytes (Header 12 + Payload 24 = 36 cycles)
        empty = 0;             
        data_i = 8'h33; 
        #20;
        rst_n = 1;
        #20;
        // Wait enough time for header + 3 bytes * 8 cycles = 36+ cycles
        #360;

        empty = 1;
        #1000;

        $display("--- Simulation Finished ---");
        $stop;
    end

    // Simple monitor for debugging
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset state
        end else if (next_item) begin
            data_i <= data_i + 8'h01; // Increment data pattern on each read request
        end
    end

endmodule