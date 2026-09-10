`timescale 1ns/1ps

module Top_TB #(
    parameter FIFO_DEPTH = 4096,
    parameter FIFO_WIDTH = 2,
    parameter WL         = 6
)();

    // Clock and Reset Signals
    reg clk = 0;
    reg rst_n = 1;

    // DUT Inputs
    reg i_valid = 0;
    reg signed [1:0] Real = 0;
    reg signed [1:0] Imag = 0;

    // DUT Outputs
    wire tx_done, tx_end;
    wire signed [7:0] tx_real, tx_imag;

    // Verification Counters & Flags
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer symbol_index = 0;
    integer modulation_sample_cnt = 0;

    // Expected Output Queues for Self-Checking Verification
    reg signed [1:0] exp_dqpsk_r [$];
    reg signed [1:0] exp_dqpsk_i [$];

    // Reference Shift Registers matching DQPSK hardware model
    reg signed [1:0] ref_real_ff [0:3];
    reg signed [1:0] ref_imag_ff [0:3];

    // DUT Instantiation
    Top #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(FIFO_WIDTH),
        .WL(WL)
    ) Top_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .Real(Real),
        .Imag(Imag),
        .tx_done(tx_done),
        .tx_end(tx_end),
        .tx_real(tx_real),
        .tx_imag(tx_imag)
    );

    // 32 MHz Clock Generation (31.25 ns Period)
    always #15.625 clk = ~clk;

    // Helper Task to Reset DQPSK Model Registers
    task reset_ref_model;
        integer i;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                ref_real_ff[i] = 2'sb01;
                ref_imag_ff[i] = 2'sb01;
            end
        end
    endtask

    // Helper Task to Apply Input Symbol & Calculate DQPSK Golden Reference
    task send_symbol(input signed [1:0] in_r, input signed [1:0] in_i);
        reg signed [1:0] exp_r, exp_i;
        begin
            @(negedge clk);
            i_valid = 1'b1;
            Real    = in_r;
            Imag    = in_i;

            // Compute expected DQPSK outputs matching module equation:
            // Real_o = (Real * Real_FF[3]) - (Imag * Imag_FF[3])
            // Imag_o = (Real * Imag_FF[3]) + (Imag * Real_FF[3])
            exp_r = (in_r * ref_real_ff[3]) - (in_i * ref_imag_ff[3]);
            exp_i = (in_r * ref_imag_ff[3]) + (in_i * ref_real_ff[3]);

            $display("------------------------------------------------------------------------------------------------------------------------");
            $display("[TIME %0t ps] [STIMULUS] Driving Symbol #%0d into Top Module:", $time, symbol_index);
            $display("    > Input Data Vector       : (%2d + j%2d)", in_r, in_i);
            $display("    > DQPSK Shift Register[3] : (%2d + j%2d)", ref_real_ff[3], ref_imag_ff[3]);
            $display("    > DQPSK Math Equation     : (%2d + j%2d) * (%2d + j%2d)", in_r, in_i, ref_real_ff[3], ref_imag_ff[3]);
            $display("                              = [((%2d * %2d) - (%2d * %2d)) + j((%2d * %2d) + (%2d * %2d))]",
                     in_r, ref_real_ff[3], in_i, ref_imag_ff[3], in_r, ref_imag_ff[3], in_i, ref_real_ff[3]);
            $display("                              = (%2d + j%2d)", exp_r, exp_i);

            // Update Golden Reference Shift Register
            ref_real_ff[3] = ref_real_ff[2];
            ref_real_ff[2] = ref_real_ff[1];
            ref_real_ff[1] = ref_real_ff[0];
            ref_real_ff[0] = exp_r;

            ref_imag_ff[3] = ref_imag_ff[2];
            ref_imag_ff[2] = ref_imag_ff[1];
            ref_imag_ff[1] = ref_imag_ff[0];
            ref_imag_ff[0] = exp_i;

            // Push to Verification FIFO Queue
            exp_dqpsk_r.push_back(exp_r);
            exp_dqpsk_i.push_back(exp_i);
        end
    endtask

    // Main Test Stimulus
    initial begin
        $display("========================================================================================================================");
        $display("                                  STARTING COMPLETE TOP MODULE VERIFICATION PIPELINE                                    ");
        $display("========================================================================================================================");

        reset_ref_model();
        clk     = 0;
        rst_n   = 0;
        i_valid = 0;
        Real    = 0;
        Imag    = 0;

        // Apply Reset
        $display("[TIME %0t ps] [SYSTEM] Asserting Hardware Reset (rst_n = 0)...", $time);
        repeat (3) @(posedge clk);
        rst_n = 1;
        $display("[TIME %0t ps] [SYSTEM] De-asserting Reset (rst_n = 1). System Active.", $time);
        @(posedge clk);

        // Send 4 Sequences of 4 Combinations: (1,0), (-1,0), (0,1), (0,-1)
        repeat (4) begin
            send_symbol( 2'sb01,  2'sb00); // Symbol 1: ( 1,  0)
            send_symbol(-2'sb01,  2'sb00); // Symbol 2: (-1,  0)
            send_symbol( 2'sb00,  2'sb01); // Symbol 3: ( 0,  1)
            send_symbol( 2'sb00, -2'sb01); // Symbol 4: ( 0, -1)

            // De-assert valid between blocks
            @(negedge clk);
            i_valid = 1'b0;
            Real    = 2'sb00;
            Imag    = 2'sb00;
            $display("[TIME %0t ps] [STIMULUS] De-asserting i_valid. Inserting Inter-frame Gap...", $time);
            repeat (2) @(posedge clk);
        end

        // Wait for Transmission Complete Signal
        $display("========================================================================================================================");
        $display("[TIME %0t ps] [STIMULUS] All 16 Input Symbols Pushed. Waiting for Tx Complete Signal (tx_done)...", $time);
        $display("========================================================================================================================");
        @(posedge tx_done);
        $display("[TIME %0t ps] [SYSTEM] 'tx_done' Flag Detected HIGH!", $time);
        repeat (10) @(posedge clk);

        // Verification Results Summary
        $display("========================================================================================================================");
        $display("                                              FINAL VERIFICATION REPORT                                                 ");
        $display("========================================================================================================================");
        $display("  > TOTAL CHECKS PASSED           : %0d", pass_cnt);
        $display("  > TOTAL CHECKS FAILED           : %0d", fail_cnt);
        $display("  > TOTAL DQPSK SYMBOLS PROCESSED : %0d", symbol_index);
        $display("  > TOTAL MODULATION SAMPLES CHEKD: %0d", modulation_sample_cnt);
        if (fail_cnt == 0 && pass_cnt > 0) begin
            $display("  > FINAL STATUS                  : TESTBENCH PASSED SUCCESSFULLY!");
        end else begin
            $display("  > FINAL STATUS                  : TESTBENCH FAILED WITH ERRORS!");
        end
        $display("========================================================================================================================");

        $stop;
    end

    // Self-Checking Monitor for DQPSK Output Hardware Alignment
    always @(posedge clk) begin
        if (rst_n && Top_DUT.DQPSK_DUT.valid) begin
            if (exp_dqpsk_r.size() > 0) begin
                reg signed [1:0] expected_r, expected_i;
                expected_r = exp_dqpsk_r.pop_front();
                expected_i = exp_dqpsk_i.pop_front();

                if (Top_DUT.DQPSK_DUT.Real_o === expected_r && Top_DUT.DQPSK_DUT.Imag_o === expected_i) begin
                    $display("[TIME %0t ps] [DQPSK MATCH] Symbol #%0d successfully encoded and written to FIFO:", $time, symbol_index);
                    $display("    > HW Output Vector : (%2d + j%2d)", Top_DUT.DQPSK_DUT.Real_o, Top_DUT.DQPSK_DUT.Imag_o);
                    $display("    > Golden Expected  : (%2d + j%2d)", expected_r, expected_i);
                    $display("    > Verification     : MATCH SUCCESSFUL [PASSED]");
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[TIME %0t ps] [DQPSK ERROR] Symbol #%0d Mismatch Detected:", $time, symbol_index);
                    $display("    > HW Output Vector : (%2d + j%2d)", Top_DUT.DQPSK_DUT.Real_o, Top_DUT.DQPSK_DUT.Imag_o);
                    $display("    > Golden Expected  : (%2d + j%2d)", expected_r, expected_i);
                    $display("    > Verification     : MISMATCH DETECTED [FAILED]");
                    fail_cnt = fail_cnt + 1;
                end
                symbol_index = symbol_index + 1;
            end
        end
    end

    // Dynamic Multiplier Verification (Active Output Modulation Check)
    always @(posedge clk) begin
        if (rst_n && Top_DUT.CSK_GEN_DUT.running && Top_DUT.next_item) begin
            reg signed [7:0] calc_tx_real, calc_tx_imag;
            reg signed [1:0]  s_r_val, s_i_val;
            reg signed [5:0]  csk_r_val, csk_i_val;
            real float_csk_r, float_csk_i;
            real float_tx_r, float_tx_i;

            s_r_val   = Top_DUT.S_R;
            s_i_val   = Top_DUT.S_I;
            csk_r_val = Top_DUT.csk_out_r;
            csk_i_val = Top_DUT.csk_out_i;

            // Convert Q1.5 signed fixed point (6 bits: 1 sign bit, 5 fractional bits) to Real Floating Point
            float_csk_r = $itor(csk_r_val) / 32.0;
            float_csk_i = $itor(csk_i_val) / 32.0;

            // Perform Integer Arithmetic Matching Top Hardware Pipeline
            calc_tx_real = (s_r_val * csk_r_val) - (s_i_val * csk_i_val);
            calc_tx_imag = (s_r_val * csk_i_val) + (s_i_val * csk_r_val);

            // Convert Q3.4 output (8 bits: 1 sign, 3 integer, 4 fractional bits) to Real Floating Point
            float_tx_r = $itor(calc_tx_real) / 16.0;
            float_tx_i = $itor(calc_tx_imag) / 16.0;

            // Verify calculation against hardware pipeline on following clock cycle
            @(posedge clk);
            if (tx_real === calc_tx_real && tx_imag === calc_tx_imag) begin
                $display("[TIME %0t ps] [TX MODULATOR] Complex Chirp Multiplication Sample #%0d:", $time, modulation_sample_cnt);
                $display("    > Read Symbol Vector (S_R + j S_I)  : (%2d + j%2d)", s_r_val, s_i_val);
                $display("    > ROM Wave Vector (csk_out_r, _i)    : Raw Fixed-Point Q1.5 = (%3d + j%3d) | Math Float = (%6.4f + j%6.4f)",
                         csk_r_val, csk_i_val, float_csk_r, float_csk_i);
                $display("    > Complex Operation                 : (%2d + j%2d) * (%6.4f + j%6.4f)",
                         s_r_val, s_i_val, float_csk_r, float_csk_i);
                $display("    > Math Expansion                    : [((%2d * %6.4f) - (%2d * %6.4f)) + j((%2d * %6.4f) + (%2d * %6.4f))]",
                         s_r_val, float_csk_r, s_i_val, float_csk_i, s_r_val, float_csk_i, s_i_val, float_csk_r);
                $display("    > Hardware Output (tx_real + j tx_imag): Raw Q3.4 Integer = (%4d + j%4d) | Math Float = (%7.4f + j%7.4f)",
                         tx_real, tx_imag, float_tx_r, float_tx_i);
                $display("    > Modulator Verification            : MATCH SUCCESSFUL [PASSED]");
                $display("------------------------------------------------------------------------------------------------------------------------");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[TIME %0t ps] [TX MODULATOR ERROR] Mismatch at Sample #%0d:", $time, modulation_sample_cnt);
                $display("    > Read Symbol Vector (S_R + j S_I)  : (%2d + j%2d)", s_r_val, s_i_val);
                $display("    > ROM Wave Vector (csk_out_r, _i)    : Raw Fixed-Point Q1.5 = (%3d + j%3d) | Math Float = (%6.4f + j%6.4f)",
                         csk_r_val, csk_i_val, float_csk_r, float_csk_i);
                $display("    > HW Output (tx_real, tx_imag)      : (%4d + j%4d)", tx_real, tx_imag);
                $display("    > Expected Output                   : (%4d + j%4d)", calc_tx_real, calc_tx_imag);
                $display("    > Modulator Verification            : MISMATCH DETECTED [FAILED]");
                $display("------------------------------------------------------------------------------------------------------------------------");
                fail_cnt = fail_cnt + 1;
            end
            modulation_sample_cnt = modulation_sample_cnt + 1;
        end
    end

endmodule