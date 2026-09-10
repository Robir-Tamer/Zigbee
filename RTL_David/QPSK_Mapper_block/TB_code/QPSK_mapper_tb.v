module QPSK_mapper_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg i;
    reg q;
    reg i_valid;

    wire valid;
    wire signed [1:0] out_real;
    wire signed [1:0] out_imag;

    // DUT instantiation
    QPSK_mapper dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .i        (i),
        .q        (q),
        .i_valid  (i_valid),
        .valid    (valid),
        .out_real (out_real),
        .out_imag (out_imag)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test procedure
    initial begin

        @(negedge clk);

        // Initialize inputs
        rst_n   = 0;    i= 0;   q= 0;  i_valid = 0;

        // ------------------------------------------------
        // 1. Test RESET
        // ------------------------------------------------
        @(negedge clk);

        if (valid !== 0 || out_real !== 0 || out_imag !== 0)
            $display("ERROR: Reset test failed");
        else
            $display("PASS: Reset test");

        // Release reset
        rst_n = 1;

        // ------------------------------------------------
        // 2. Test 00 -> (-1, 0)
        // ------------------------------------------------
        i = 0;
        q = 0;
        i_valid = 1;

        @(negedge clk);

        if (valid !== 1 || out_real !== -1 || out_imag !== 0)
            $display("ERROR: 00 mapping failed");
        else
            $display("PASS: 00 -> (-1, 0)");

        // ------------------------------------------------
        // 3. Test 01 -> (0, +1)
        // ------------------------------------------------
        i = 0;
        q = 1;

        @(negedge clk);

        if (valid !== 1 || out_real !== 0 || out_imag !== 1)
            $display("ERROR: 01 mapping failed");
        else
            $display("PASS: 01 -> (0, +1)");

        // ------------------------------------------------
        // 4. Test 10 -> (0, -1)
        // ------------------------------------------------
        i = 1;
        q = 0;

        @(negedge clk);

        if (valid !== 1 || out_real !== 0 || out_imag !== -1)
            $display("ERROR: 10 mapping failed");
        else
            $display("PASS: 10 -> (0, -1)");

        // ------------------------------------------------
        // 5. Test 11 -> (+1, 0)
        // ------------------------------------------------
        i = 1;
        q = 1;

        @(negedge clk);

        if (valid !== 1 || out_real !== 1 || out_imag !== 0)
            $display("ERROR: 11 mapping failed");
        else
            $display("PASS: 11 -> (+1, 0)");

        // ------------------------------------------------
        // 6. Test i_valid = 0
        // ------------------------------------------------
        i_valid = 0;

        @(negedge clk);

        if (valid !== 0)
            $display("ERROR: i_valid test failed");
        else
            $display("PASS: i_valid = 0 -> valid = 0");

        // ------------------------------------------------
        // 7. Test reset again during operation
        // ------------------------------------------------
        i_valid = 1;
        i = 1;
        q = 1;

        @(posedge clk);     #1;
        // Now assert reset
        rst_n = 0;

        @(posedge clk);
        #1;

        if (valid !== 0 || out_real !== 0 || out_imag !== 0)
            $display("ERROR: Reset during operation failed");
        else
            $display("PASS: Reset during operation");

        // ------------------------------------------------
        // 8. Release reset and verify operation again
        // ------------------------------------------------
        rst_n = 1;
        i = 0;
        q = 1;
        i_valid = 1;

        @(posedge clk);
        #1;

        if (valid !== 1 || out_real !== 0 || out_imag !== 1)
            $display("ERROR: Operation after reset failed");
        else
            $display("PASS: Operation after reset");

        // ------------------------------------------------
        // End simulation
        // ------------------------------------------------
        $display("-----------------------------------");
        $display("QPSK Mapper Testbench Completed");
        $display("-----------------------------------");

        $stop;
    end

endmodule