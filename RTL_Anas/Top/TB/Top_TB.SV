`timescale 1ns/1ps

// ============================================================================
// TESTBENCH: Top_TB
// PURPOSE  : Self-checking verification of the full CSS PHY transmitter
//            chain (DQPSK differential encoder -> dual Sync FIFOs (I/Q) ->
//            CSK_GEN chirp ROM/frame generator -> complex multiplier ->
//            tx_real/tx_imag), driven directly at the DQPSK's raw QPSK
//            symbol inputs (Real, Imag), bypassing the earlier stages
//            (Zero Padding/Demux/Symbol Mapper/Interleaver/Form PPDU) which
//            are verified separately against the MATLAB golden model.
//
// HOW THE SELF-CHECKING WORKS (three independent checks, all running
// concurrently against the same DUT run):
//   1. DQPSK correctness  : a golden differential-encoder model is computed
//      in this testbench (task send_symbol), pushed into a queue, and
//      compared cycle-by-cycle against the DUT's actual Real_o/Imag_o.
//   2. Multiplier correctness : every time a new symbol is latched by
//      CSK_GEN (next_item pulses), this TB independently recomputes the
//      expected complex product (S_R+jS_I)*(csk_out_r+j csk_out_i) and
//      compares it against the DUT's registered tx_real/tx_imag one cycle
//      later (accounting for the known 1-cycle multiplier latency).
//   3. Frame completion : tx_done is awaited explicitly after all symbols
//      have been pushed, confirming the full frame (including its
//      mandatory trailing gap) actually completes.
//
// TWO SCENARIOS ARE RUN IN THIS FILE, BACK TO BACK, SHARING THE SAME
// pass_cnt/fail_cnt COUNTERS FOR ONE COMBINED FINAL VERDICT:
//   PHASE 1 (original): 4 blocks x 4 symbols = 16 symbols total. Since
//     gaps alternate even(10 cycles)/odd(70 cycles) starting from even on
//     block 1, an EVEN-numbered block count (4) means the LAST block is
//     odd-indexed -> this run's frame terminates on the ODD (70-cycle) gap.
//   PHASE 2 (new): 3 blocks x 4 symbols = 12 symbols total. An ODD block
//     count means the last block is even-indexed -> this run's frame
//     terminates on the EVEN (10-cycle) gap instead. This specifically
//     exercises the OTHER termination path (10-cycle gap -> running drops
//     -> tx_done fires), which Phase 1 alone never reaches.
//
// Each phase applies a full reset and re-initializes the golden DQPSK
// reference model (reset_ref_model) so the two runs are fully independent
// packets, not a continuation of one another.
// ============================================================================

module Top_TB #(
    parameter FIFO_DEPTH = 4096,
    parameter FIFO_WIDTH = 2,
    parameter WL         = 6
)();

    // ---- Clock and Reset Signals ----
    reg clk = 0;
    reg rst_n = 1;

    // ---- DUT Inputs ----
    reg i_valid = 0;
    reg signed [1:0] Real = 0;
    reg signed [1:0] Imag = 0;

    // ---- DUT Outputs ----
    wire tx_done, tx_end;
    wire signed [7:0] tx_real, tx_imag;

    // ---- Verification Counters & Flags (shared across BOTH phases,
    //      giving one combined pass/fail verdict at the very end) ----
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer symbol_index = 0;
    integer modulation_sample_cnt = 0;

    // ---- Expected Output Queues for Self-Checking Verification ----
    // (DQPSK golden outputs are pushed here by send_symbol() and consumed,
    //  in order, by the DQPSK-match monitor below.)
    reg signed [1:0] exp_dqpsk_r [$];
    reg signed [1:0] exp_dqpsk_i [$];

    // ---- Reference Shift Registers matching DQPSK hardware model ----
    // (4-lane feedback register mirroring DQPSK.v's own Real_FF/Imag_FF,
    //  reset to (1,1) on every lane per spec: S0=S1=S2=S3=exp(j*pi/4).)
    reg signed [1:0] ref_real_ff [0:3];
    reg signed [1:0] ref_imag_ff [0:3];

    // ---- DUT Instantiation ----
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

    // ---- 32 MHz Clock Generation (31.25 ns Period) ----
    always #15.625 clk = ~clk;

    // ---- Helper Task: reset the golden DQPSK feedback model to its
    //      spec-mandated initial state (all 4 lanes = 1+1j). Must be
    //      called every time the DUT itself is reset, so the golden
    //      model and hardware start each packet from the same state. ----
    task reset_ref_model;
        integer i;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                ref_real_ff[i] = 2'sb01;
                ref_imag_ff[i] = 2'sb01;
            end
        end
    endtask

    // ---- Helper Task: drive one QPSK symbol into the DUT, AND compute
    //      the golden expected DQPSK output for it in lockstep, pushing
    //      the result into the comparison queues. This task is reused,
    //      unmodified, by both Phase 1 and Phase 2 below. ----
    task send_symbol(input signed [1:0] in_r, input signed [1:0] in_i);
        reg signed [1:0] exp_r, exp_i;
        begin
            @(negedge clk);
            i_valid = 1'b1;
            Real    = in_r;
            Imag    = in_i;

            // Golden differential encoder, matching DQPSK.v's equation:
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

            // Shift the golden reference register (mirrors DQPSK.v's own
            // 4-deep shift chain exactly).
            ref_real_ff[3] = ref_real_ff[2];
            ref_real_ff[2] = ref_real_ff[1];
            ref_real_ff[1] = ref_real_ff[0];
            ref_real_ff[0] = exp_r;

            ref_imag_ff[3] = ref_imag_ff[2];
            ref_imag_ff[2] = ref_imag_ff[1];
            ref_imag_ff[1] = ref_imag_ff[0];
            ref_imag_ff[0] = exp_i;

            // Queue the expected result for the DQPSK-match monitor below.
            exp_dqpsk_r.push_back(exp_r);
            exp_dqpsk_i.push_back(exp_i);
        end
    endtask

    // ---- Helper Task: apply a full synchronous reset to the DUT and
    //      re-initialize the golden model, so each phase starts as a
    //      genuinely independent packet, not a continuation of the
    //      previous phase's leftover state. ----
    task apply_reset;
        begin
            rst_n   = 0;
            i_valid = 0;
            Real    = 0;
            Imag    = 0;
            reset_ref_model();
            repeat (3) @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // Main Test Stimulus
    initial begin
        $display("========================================================================================================================");
        $display("                                  STARTING COMPLETE TOP MODULE VERIFICATION PIPELINE                                    ");
        $display("========================================================================================================================");

        clk = 0;
        apply_reset();

        // ================================================================
        // PHASE 1 : ODD-GAP-ENDING SCENARIO (unchanged from the original
        // directed test). 4 blocks x 4 symbols = 16 symbols. Block count
        // is EVEN -> last block index is ODD -> frame ends on the 70-cycle
        // (odd) gap before tx_done fires.
        // ================================================================
        $display("[TIME %0t ps] [PHASE 1] Odd-gap-ending scenario: 4 blocks x 4 symbols = 16 symbols.", $time);

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

        $display("========================================================================================================================");
        $display("[TIME %0t ps] [PHASE 1] All 16 symbols pushed. Waiting for tx_done (expect ODD/70-cycle gap termination)...", $time);
        $display("========================================================================================================================");
        @(posedge tx_done);
        $display("[TIME %0t ps] [PHASE 1] tx_done Detected HIGH.", $time);
        repeat (10) @(posedge clk);

        // ================================================================
        // PHASE 2 (NEW) : EVEN-GAP-ENDING SCENARIO. 3 blocks x 4 symbols =
        // 12 symbols. Block count is ODD -> last block index is EVEN ->
        // frame ends on the 10-cycle (even) gap before tx_done fires.
        // This exercises the termination path Phase 1 never reaches.
        // Fresh reset applied first so this is an independent packet.
        // ================================================================
        $display("========================================================================================================================");
        $display("[TIME %0t ps] [PHASE 2] Applying fresh reset for even-gap-ending scenario...", $time);
        apply_reset();
        $display("[TIME %0t ps] [PHASE 2] Even-gap-ending scenario: 3 blocks x 4 symbols = 12 symbols.", $time);

        repeat (3) begin
            send_symbol( 2'sb01,  2'sb00); // Symbol 1: ( 1,  0)
            send_symbol(-2'sb01,  2'sb00); // Symbol 2: (-1,  0)
            send_symbol( 2'sb00,  2'sb01); // Symbol 3: ( 0,  1)
            send_symbol( 2'sb00, -2'sb01); // Symbol 4: ( 0, -1)

            @(negedge clk);
            i_valid = 1'b0;
            Real    = 2'sb00;
            Imag    = 2'sb00;
            $display("[TIME %0t ps] [PHASE 2] De-asserting i_valid. Inserting Inter-frame Gap...", $time);
            repeat (2) @(posedge clk);
        end

        $display("========================================================================================================================");
        $display("[TIME %0t ps] [PHASE 2] All 12 symbols pushed. Waiting for tx_done (expect EVEN/10-cycle gap termination)...", $time);
        $display("========================================================================================================================");
        @(posedge tx_done);
        $display("[TIME %0t ps] [PHASE 2] tx_done Detected HIGH.", $time);
        repeat (10) @(posedge clk);

        // ---- Combined Verification Results Summary (both phases) ----
        $display("========================================================================================================================");
        $display("                                    FINAL VERIFICATION REPORT (PHASE 1 + PHASE 2 COMBINED)                              ");
        $display("========================================================================================================================");
        $display("  > TOTAL CHECKS PASSED           : %0d", pass_cnt);
        $display("  > TOTAL CHECKS FAILED           : %0d", fail_cnt);
        $display("  > TOTAL DQPSK SYMBOLS PROCESSED : %0d", symbol_index);
        $display("  > TOTAL MODULATION SAMPLES CHEKD: %0d", modulation_sample_cnt);
        if (fail_cnt == 0 && pass_cnt > 0) begin
            $display("  > FINAL STATUS                  : TESTBENCH PASSED SUCCESSFULLY! (both odd-gap and even-gap terminations verified)");
        end else begin
            $display("  > FINAL STATUS                  : TESTBENCH FAILED WITH ERRORS!");
        end
        $display("========================================================================================================================");

        $stop;
    end

    // ========================================================================
    // MONITOR 1: Self-checking DQPSK output verification. Runs continuously
    // for the ENTIRE simulation (both phases), popping one golden value
    // per valid DUT output, so it needs no per-phase modification at all.
    // ========================================================================
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

    // ========================================================================
    // MONITOR 2: Self-checking complex multiplier verification. Independently
    // recomputes (S_R+jS_I)*(csk_out_r+j csk_out_i) every time CSK_GEN
    // latches a new symbol (next_item pulses), and compares against the
    // DUT's registered tx_real/tx_imag one cycle later (the known,
    // deliberate 1-cycle multiplier latency established earlier in this
    // project). Also content-agnostic -- covers both phases automatically.
    // ========================================================================
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

            // Q1.4 signed fixed point (6 bits: 1 sign + 1 integer + 4
            // fraction bits) -> real floating point, for display only.
            float_csk_r = $itor(csk_r_val) / 16.0;
            float_csk_i = $itor(csk_i_val) / 16.0;

            // Integer arithmetic exactly matching the DUT's own hardware
            // multiplier (no rounding/truncation applied here on purpose --
            // the DUT keeps the full-width product, so the golden check
            // must too).
            calc_tx_real = (s_r_val * csk_r_val) - (s_i_val * csk_i_val);
            calc_tx_imag = (s_r_val * csk_i_val) + (s_i_val * csk_r_val);

            // Q3.4 output (8 bits: 1 sign + 3 integer + 4 fraction) -> real,
            // for display only.
            float_tx_r = $itor(calc_tx_real) / 16.0;
            float_tx_i = $itor(calc_tx_imag) / 16.0;

            // tx_real/tx_imag are REGISTERED (1-cycle latency) -- wait one
            // cycle before comparing, matching that known pipeline delay.
            @(posedge clk);
            if (tx_real === calc_tx_real && tx_imag === calc_tx_imag) begin
                $display("[TIME %0t ps] [TX MODULATOR] Complex Chirp Multiplication Sample #%0d:", $time, modulation_sample_cnt);
                $display("    > Read Symbol Vector (S_R + j S_I)  : (%2d + j%2d)", s_r_val, s_i_val);
                $display("    > ROM Wave Vector (csk_out_r, _i)    : Raw Fixed-Point Q1.4 = (%3d + j%3d) | Math Float = (%6.4f + j%6.4f)",
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
                $display("    > ROM Wave Vector (csk_out_r, _i)    : Raw Fixed-Point Q1.4 = (%3d + j%3d) | Math Float = (%6.4f + j%6.4f)",
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