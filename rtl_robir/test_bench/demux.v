`timescale 1ns/1ps

module tb_e_o_demux;

    // Parameters (exact match to design)
    parameter rate_mode = "H";

    // Testbench signals
    reg clk;
    reg rst_n;
    reg mode;
    reg data_i;
    reg valid_i;

    wire [ (rate_mode == "F" ? 2 : 5) : 0 ] e_bits;
    wire [ (rate_mode == "F" ? 2 : 5) : 0 ] o_bits;
    wire valid;

    // Instantiate the Unit Under Test (UUT)
    e_o_demux #(
        .rate_mode(rate_mode)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .data_i(data_i),
        .valid_i(valid_i),
        .e_bits(e_bits),
        .o_bits(o_bits),
        .valid(valid)
    );

    // Clock generation (32 MHz equivalent / 10ns period)
    always #5 clk = ~clk;

    // Task to feed a serial stream bit by bit
    // Bits string should be provided from first-received (LSB) to last-received
    task send_stream(input reg m, input [11:0] stream, input integer bit_count);
        integer i;
        begin
            @(negedge clk);
            mode = m;
            for (i = 0; i < bit_count; i = i + 1) begin
                data_i  = stream[i];
                valid_i = 1'b1;
                @(negedge clk);
            end
            valid_i = 1'b0;
            data_i  = 1'b0;
        end
    endtask

    // Stimulus process
    initial begin
        // Initialize signals
        clk     = 0;
        rst_n   = 0;
        mode    = 0;
        data_i  = 0;
        valid_i = 0;

        // Apply reset at the beginning only
        #20;
        rst_n = 1;
        #20;

        // ---------------------------------------------------------
        // TEST CASE 1: Mode = 0 (Full 6 bits distributed to even/odd)
        // Providing 6 bits: e.g., 6'b101010 (stream order: LSB to MSB -> 0, 1, 0, 1, 0, 1)
        // ---------------------------------------------------------
        $display("--- Starting Test Case 1: Mode = 0 ---");
        send_stream(1'b0, 'b101010101010, 12);

        // Wait a few cycles between bursts
        #40;

        // ---------------------------------------------------------
        // TEST CASE 2: Mode = 1 (3 bits data + padding zeros)
        // Providing 6 bits example: 6'b101010 (similar pattern, mapped into 3 bits + zeros)
        // ---------------------------------------------------------
        $display("--- Starting Test Case 2: Mode = 1 ---");
        send_stream(1'b1, 'b010101, 6);

        // Wait for results and finish simulation
        #100;
        $display("--- Simulation Finished ---");
        $stop;
    end

endmodule