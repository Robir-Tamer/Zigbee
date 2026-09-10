module controller_single_rate_tb ();
    // signal definition
    reg clk;
    reg rst_n;    // synchronous Active-low reset.
    reg start_tx; // indecates the start of sending operation.
    reg tx_end;   // indecates the end of sending operation, system goes to idle state
    wire mode_S;
    wire mode_F;
    wire zero_pad_en_S;
    wire zero_pad_en_F;

    // dut instantiation
    controller #(
        .rate_mode("S")
    ) slow_controller (
        .clk                (clk),
        .rst_n              (rst_n),
        .start_tx           (start_tx),
        .tx_end             (tx_end),
        .payload_length     (),
        .fifo_empty         (),
        .demux_valid        (),
        .interleaver_valid  (),

        .mode               (mode_S),
        .zero_pad_en        (zero_pad_en_S)
    );


    controller #(
        .rate_mode("F")
    ) fast_controller (
        .clk                (clk),
        .rst_n              (rst_n),
        .start_tx           (start_tx),
        .tx_end             (tx_end),
        .payload_length     (),
        .fifo_empty         (),
        .demux_valid        (),
        .interleaver_valid  (),

        .mode               (mode_F),
        .zero_pad_en        (zero_pad_en_F)
    );


    // clk gen
    initial begin
        clk = 0;
        forever #5 clk =~clk;
    end


    // stimulus and test scenarios
    initial begin
        @(negedge clk)

        // ------------------------------------------------
        // 1. Test RESET
        // ------------------------------------------------
        rst_n =0;
        start_tx =0;
        tx_end =0;
        @(negedge clk)

        if (!zero_pad_en_S && !zero_pad_en_F && !mode_S && mode_F)
            $display("PASS: Reset test");
        else
            $display("ERROR: Reset test failed");

        // Release reset
        rst_n = 1;


        // ------------------------------------------------
        // 2. start_tx : one pulse
        // ------------------------------------------------
        @(posedge clk)  start_tx = 1;
        @(posedge clk)  start_tx = 0;
        @(negedge clk)

        if ((zero_pad_en_S == 1) && (zero_pad_en_F == 1) && (mode_S == 0) && (mode_F ==1))
            $display("PASS: start_tx test");
        else
            $display("ERROR: start_tx test failed");

        repeat (5) @(negedge clk);


        // ------------------------------------------------
        // 3. tx_end : one pulse
        // ------------------------------------------------
        @(posedge clk)  tx_end = 1;
        @(posedge clk)  tx_end = 0;
        @(negedge clk)

        if ((zero_pad_en_S == 0) && (zero_pad_en_F == 0) && (mode_S == 0) && (mode_F ==1))
            $display("PASS: tx_end test");
        else
            $display("ERROR: tx_end test failed");

        $stop;
    end 
endmodule