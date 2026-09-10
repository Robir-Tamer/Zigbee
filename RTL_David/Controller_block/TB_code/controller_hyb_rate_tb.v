module controller_hyb_rate_tb ();
    // signal definition
    reg clk;
    reg rst_n;    // synchronous Active-low reset.
    reg start_tx; // indecates the start of sending operation.
    reg tx_end;   // indecates the end of sending operation, system goes to idle state
    wire mode;
    wire zero_pad_en;

    // dut instantiation
    controller #(
        .rate_mode("H")
    ) hyb_controller (
        .clk                (clk),
        .rst_n              (rst_n),
        .start_tx           (start_tx),
        .tx_end             (tx_end),
        .payload_length     (),
        .fifo_empty         (),
        .demux_valid        (),
        .interleaver_valid  (),

        .mode               (mode),
        .zero_pad_en        (zero_pad_en)
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

        if ((zero_pad_en == 0) && (mode == 0))
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

        if ((zero_pad_en == 1) && (mode == 1))
            $display("PASS: start_tx single clock cycle test");
        else
            $display("ERROR: start_tx single clock cycle test failed");

        repeat (5) @(negedge clk);


        // ------------------------------------------------
        // 3. tx_end : end sending
        // ------------------------------------------------
        @(posedge clk)  tx_end = 1;
        @(posedge clk)  tx_end = 0;
        @(negedge clk)

        if ((zero_pad_en == 0) && (mode == 0))
            $display("PASS: end sending test");
        else
            $display("ERROR: end sending test failed");


        // ------------------------------------------------
        // 4. start_tx : two pulses
        // ------------------------------------------------
        @(posedge clk)  start_tx = 1;   @(posedge clk)
        @(posedge clk)  start_tx = 0;
        @(negedge clk)

        if ((zero_pad_en == 1) && (mode == 0))
            $display("PASS: start_tx double clock cycle test");
        else
            $display("ERROR: start_tx double clock cycle test failed");

        repeat (5) @(negedge clk);


        // ------------------------------------------------
        // 5. tx_end : end sending
        // ------------------------------------------------
        @(posedge clk)  tx_end = 1;
        @(posedge clk)  tx_end = 0;
        @(negedge clk)

        if ((zero_pad_en == 0) && (mode == 0))
            $display("PASS: end sending test");
        else
            $display("ERROR: end sending test failed");



        $stop;
    end 
endmodule