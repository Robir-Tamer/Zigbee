`timescale 1ns/1ps

module tb_DQPSK;

    // Testbench Signals
    reg              clk;
    reg              rst_n;
    reg              i_valid;
    reg  signed [1:0] Real, Imag;

    wire             valid;
    wire signed [1:0] Real_o, Imag_o;

    // Statistics & Verification Counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer symbol_counter = 0;

    // Golden Reference Model State Registers
    reg signed [1:0] ref_R [0:3];
    reg signed [1:0] ref_I [0:3];
    reg signed [1:0] exp_R_q;
    reg signed [1:0] exp_I_q;
    reg              exp_valid_q;

    // Pipeline Registers to hold mathematical operands for transcript display
    reg signed [1:0] op_a, op_b; // Input symbol (a + j*b)
    reg signed [1:0] op_c, op_d; // Reference carrier state (c + j*d)

    // QPSK Symbol Constants
    localparam signed [1:0] P_ONE  = 2'sb01; //  1
    localparam signed [1:0] N_ONE  = 2'sb11; // -1
    localparam signed [1:0] ZERO   = 2'sb00; //  0

    // Instantiate Design Under Test (DUT)
    DQPSK dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .Real(Real),
        .Imag(Imag),
        .valid(valid),
        .Real_o(Real_o),
        .Imag_o(Imag_o)
    );

    // 100 MHz Clock Generation (10 ns period)
    always #5 clk = ~clk;

    // =========================================================================
    // GOLDEN REFERENCE MODEL (1-cycle latency pipeline)
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_R[0] <= 2'sb01; ref_R[1] <= 2'sb01; ref_R[2] <= 2'sb01; ref_R[3] <= 2'sb01;
            ref_I[0] <= 2'sb01; ref_I[1] <= 2'sb01; ref_I[2] <= 2'sb01; ref_I[3] <= 2'sb01;
            exp_R_q     <= 2'sb00;
            exp_I_q     <= 2'sb00;
            exp_valid_q <= 1'b0;
            op_a        <= 2'sb00;
            op_b        <= 2'sb00;
            op_c        <= 2'sb00;
            op_d        <= 2'sb00;
        end else begin
            exp_valid_q <= i_valid;
            if (i_valid) begin
                // Capture operands for transcript display
                op_a <= Real;
                op_b <= Imag;
                op_c <= ref_R[3];
                op_d <= ref_I[3];

                // Predict registered output
                exp_R_q <= (Real * ref_R[3]) - (Imag * ref_I[3]);
                exp_I_q <= (Real * ref_I[3]) + (Imag * ref_R[3]);

                // Update internal reference feedback delay line
                {ref_R[3], ref_R[2], ref_R[1], ref_R[0]} <= {ref_R[2], ref_R[1], ref_R[0], (Real * ref_R[3]) - (Imag * ref_I[3])};
                {ref_I[3], ref_I[2], ref_I[1], ref_I[0]} <= {ref_I[2], ref_I[1], ref_I[0], (Real * ref_I[3]) + (Imag * ref_R[3])};
            end
        end
    end

    // =========================================================================
    // AUTOMATED CHECKER (Evaluated on falling clock edge)
    // =========================================================================
    always @(negedge clk) begin
        if (rst_n) begin
            // Check valid flag alignment
            if (valid !== exp_valid_q) begin
                $display("[ERROR @ %0tps] Valid Flag Mismatch! Expected: %b, Got: %b", $time, exp_valid_q, valid);
                fail_count = fail_count + 1;
            end

            // Check math output when data is valid
            if (valid) begin
                symbol_counter = symbol_counter + 1;
                if ((Real_o === exp_R_q) && (Imag_o === exp_I_q)) begin
                    $display("[PASS  @ %0tps] Symbol #%0d | (%0d + j*%0d) * (%0d + j*%0d) = (%0d + j*%0d)", 
                             $time, symbol_counter, op_a, op_b, op_c, op_d, Real_o, Imag_o);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL  @ %0tps] Symbol #%0d | Math: (%0d + j*%0d) * (%0d + j*%0d) | Expected: (%0d + j*%0d), Got: (%0d + j*%0d)", 
                             $time, symbol_counter, op_a, op_b, op_c, op_d, exp_R_q, exp_I_q, Real_o, Imag_o);
                    fail_count = fail_count + 1;
                end
            end
        end
    end

    // =========================================================================
    // TASKS FOR DRIVING INPUTS
    // =========================================================================
    task send_symbol(input signed [1:0] r_in, input signed [1:0] i_in);
        begin
            @(posedge clk);
            Real    <= r_in;
            Imag    <= i_in;
            i_valid <= 1'b1;
        end
    endtask

    task send_idle(input integer cycles);
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(posedge clk);
                Real    <= ZERO;
                Imag    <= ZERO;
                i_valid <= 1'b0;
            end
        end
    endtask

    // =========================================================================
    // STIMULUS SUITE
    // =========================================================================
    initial begin
        $dumpfile("dqpsk_tb.vcd");
        $dumpvars(0, tb_DQPSK);

        // Initialize Inputs
        clk     = 1'b0;
        rst_n   = 1'b0;
        i_valid = 1'b0;
        Real    = ZERO;
        Imag    = ZERO;

        // --- TEST 1: Reset Verification ---
        $display("\n--- TEST 1: Reset Sequence ---");
        #25;
        rst_n = 1'b1;
        send_idle(2);

        // --- TEST 2: Single Isolated Symbols ---
        $display("\n--- TEST 2: Isolated Symbols (+1, +j, -1, -j) ---");
        send_symbol(P_ONE, ZERO);  // +1
        send_idle(3);
        send_symbol(ZERO,  P_ONE); // +j
        send_idle(3);
        send_symbol(N_ONE, ZERO);  // -1
        send_idle(3);
        send_symbol(ZERO,  N_ONE); // -j
        send_idle(4);

        // --- TEST 3: Continuous Stream ---
        $display("\n--- TEST 3: Continuous Symbol Stream (12 Symbols) ---");
        send_symbol(P_ONE, ZERO);  // +1
        send_symbol(ZERO,  P_ONE); // +j
        send_symbol(N_ONE, ZERO);  // -1
        send_symbol(ZERO,  N_ONE); // -j
        send_symbol(P_ONE, ZERO);  // +1
        send_symbol(P_ONE, ZERO);  // +1
        send_symbol(ZERO,  P_ONE); // +j
        send_symbol(N_ONE, ZERO);  // -1
        send_symbol(ZERO,  N_ONE); // -j
        send_symbol(N_ONE, ZERO);  // -1
        send_symbol(ZERO,  P_ONE); // +j
        send_symbol(P_ONE, ZERO);  // +1
        send_idle(5);

        // --- TEST 4: Intermittent Stalled Stream ---
        $display("\n--- TEST 4: Intermittent Stream (Pause/Resume State Hold) ---");
        send_symbol(P_ONE, ZERO);
        send_symbol(ZERO,  N_ONE);
        send_idle(2);
        send_symbol(N_ONE, ZERO);
        send_idle(1);
        send_symbol(ZERO,  P_ONE);
        send_idle(4);

        // --- FINAL SUMMARY ---
        $display("\n==================================================");
        $display("                 SIMULATION RESULTS               ");
        $display("==================================================");
        $display(" Total Symbols Checked : %0d", symbol_counter);
        $display(" Passed Checks         : %0d", pass_count);
        $display(" Failed Checks         : %0d", fail_count);
        $display("==================================================");

        if (fail_count == 0 && pass_count > 0)
            $display(" STATUS: TEST PASSED SUCCESSFULLY!");
        else
            $display(" STATUS: TEST FAILED WITH ERRORS!");

        $stop;
    end

endmodule