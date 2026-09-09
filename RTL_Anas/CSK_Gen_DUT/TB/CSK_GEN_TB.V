`timescale 1ns / 1ps

module CSK_GEN_tb;

    parameter WL = 6;
    parameter CLK_PERIOD = 10;

    reg                   clk;
    reg                   rst_n;
    reg                   en;
    wire                  next_item;
    wire signed [WL-1:0]  csk_out_r;
    wire signed [WL-1:0]  csk_out_i;
    wire                  running;      // NEW: now a real port, not a hierarchical peek

    integer frame_active_count;
    integer gap_count;
    integer gap_cycle_target;
    integer total_next_item_pulses;
    integer errors;

    reg expect_next_item_next_cycle;
    reg running_prev;
    reg running_drop_seen;
    reg check_addr_glitch_next_cycle;

    CSK_GEN #(.WL(WL)) dut (
        .clk(clk), .rst_n(rst_n), .en(en),
        .next_item(next_item),
        .csk_out_r(csk_out_r), .csk_out_i(csk_out_i),
        .running(running)              // NEW: connect the added port
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    always @(posedge clk) begin
        if (en && next_item) total_next_item_pulses <= total_next_item_pulses + 1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (running === 1'bx) begin
                $display("[FAIL] Time %0t: running is X post-reset!", $time);
                errors = errors + 1;
            end
            if (^dut.addr_ptr === 1'bx || ^dut.samble_cnt === 1'bx) begin
                $display("[FAIL] Time %0t: addr_ptr/samble_cnt X post-reset!", $time);
                errors = errors + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (en) begin
            if (expect_next_item_next_cycle) begin
                if (next_item !== 1'b1) begin
                    $display("[FAIL] Time %0t: next_item did NOT assert one cycle after subchirp boundary (addr_ptr=%0d)!",
                              $time, dut.addr_ptr);
                    errors = errors + 1;
                end
            end
            expect_next_item_next_cycle <= 1'b0;

            if (dut.addr_ptr <= 8'd151 && dut.samble_cnt == 7'd37) begin
                if (next_item !== 1'b0) begin
                    $display("[FAIL] Time %0t: next_item asserted ONE CYCLE TOO EARLY at addr_ptr=%0d!",
                              $time, dut.addr_ptr);
                    errors = errors + 1;
                end
                expect_next_item_next_cycle <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        running_prev <= running;
        if (running !== running_prev) begin
            $display("[MONITOR] Time %0t: running %b -> %b (addr_ptr=%0d, samble_cnt=%0d, en=%b)",
                      $time, running_prev, running, dut.addr_ptr, dut.samble_cnt, en);
            if (running_prev === 1'b1 && running === 1'b0) begin
                running_drop_seen = 1'b1;
                check_addr_glitch_next_cycle <= 1'b1;
            end
        end

        if (check_addr_glitch_next_cycle) begin
            check_addr_glitch_next_cycle <= 1'b0;
            if (dut.addr_ptr !== 8'd0 || dut.samble_cnt !== 7'd0) begin
                $display("[FAIL] Time %0t: GLITCH -- addr_ptr=%0d samble_cnt=%0d (expected 0,0) after running dropped.",
                          $time, dut.addr_ptr, dut.samble_cnt);
                errors = errors + 1;
            end else begin
                $display("[PASS] Time %0t: No glitch after running dropped.", $time);
            end
            if (csk_out_r !== {WL{1'b0}} || csk_out_i !== {WL{1'b0}}) begin
                $display("[FAIL] Time %0t: csk_out nonzero (%0d,%0d) right after running dropped!",
                          $time, csk_out_r, csk_out_i);
                errors = errors + 1;
            end
        end
    end

    task wait_for_addr_ptr(input [7:0] target);
        begin
            while (dut.addr_ptr !== target) @(posedge clk);
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; en = 0; errors = 0;
        total_next_item_pulses = 0;
        expect_next_item_next_cycle = 0;
        running_prev = 1'b0; running_drop_seen = 1'b0;
        check_addr_glitch_next_cycle = 1'b0;

        $dumpfile("CSK_GEN_tb_running.vcd");
        $dumpvars(0, CSK_GEN_tb);

        $display("==================================================");
        $display("  CSK_GEN_tb : RESET FIX + REALISTIC EN-DROP TEST  ");
        $display("  (updated for 'running' output port)              ");
        $display("==================================================");

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk); #1;

        if (running !== 1'b0 || dut.addr_ptr !== 8'd0 || dut.samble_cnt !== 8'd0) begin
            $display("[FAIL] Time %0t: Post-reset state not clean (running=%b, addr_ptr=%0d, samble_cnt=%0d)!",
                      $time, running, dut.addr_ptr, dut.samble_cnt);
            errors = errors + 1;
        end else
            $display("[PASS] Post-reset state clean: running=0, addr_ptr=0, samble_cnt=0 (no X).");

        @(posedge clk);
        en <= 1'b1;
        @(posedge clk);
        #1;
        if (next_item !== 1'b1) begin
            $display("[FAIL] Time %0t: next_item was NOT asserted on startup!", $time);
            errors = errors + 1;
        end else
            $display("[PASS] Time %0t: Startup pre-load pulse correctly asserted.", $time);
        @(posedge clk);

        $display("\n--- Frame 1: baseline, en stays high ---");
        while (running !== 1'b1) @(posedge clk);
        frame_active_count = 0;
        while (dut.addr_ptr <= 8'd151) begin
            @(posedge clk);
            frame_active_count = frame_active_count + 1;
        end
        if (frame_active_count == 152)
            $display("[PASS] Frame 1 Active Stage: 152 samples.");
        else begin
            $display("[FAIL] Frame 1 Active Stage: expected 152, got %0d!", frame_active_count);
            errors = errors + 1;
        end

        gap_count = 0;
        gap_cycle_target = (dut.which_gab == 1'b0) ? 10 : 70;
        while (dut.addr_ptr > 8'd151) begin
            @(posedge clk);
            gap_count = gap_count + 1;
        end
        if (gap_count == gap_cycle_target)
            $display("[PASS] Frame 1 Gap Stage: %0d cycles (%s Gap), correct.",
                      gap_count, (gap_cycle_target == 10) ? "Even" : "Odd");
        else begin
            $display("[FAIL] Frame 1 Gap Stage: expected %0d, got %0d!", gap_cycle_target, gap_count);
            errors = errors + 1;
        end

        $display("\n--- Frame 2: en drops exactly as active block ends (addr_ptr 151->152) ---");
        wait_for_addr_ptr(8'd151);
        @(posedge clk);
        @(negedge clk);
        en <= 1'b0;
        $display("[STIMULUS] Time %0t: en deasserted at addr_ptr=%0d", $time, dut.addr_ptr);

        if (dut.addr_ptr !== 8'd152)
            $display("[WARN] Time %0t: expected addr_ptr==152 at drop point, got %0d.", $time, dut.addr_ptr);

        gap_count = 0;
        gap_cycle_target = (dut.which_gab == 1'b0) ? 10 : 70;
        $display("[INFO] Entering %s Gap (%0d cycles expected) with en=0 throughout.",
                  (gap_cycle_target == 10) ? "Even" : "Odd", gap_cycle_target);

        while (dut.addr_ptr > 8'd151) begin
            if (running !== 1'b1) begin
                $display("[FAIL] Time %0t: running dropped MID-GAP (gap_count=%0d of %0d)!",
                          $time, gap_count, gap_cycle_target);
                errors = errors + 1;
            end
            if (csk_out_r !== {WL{1'b0}} || csk_out_i !== {WL{1'b0}}) begin
                $display("[FAIL] Time %0t: Non-zero output during trailing gap!", $time);
                errors = errors + 1;
            end
            @(posedge clk);
            gap_count = gap_count + 1;
        end

        if (gap_count == gap_cycle_target)
            $display("[PASS] Trailing gap ran the FULL correct duration (%0d cycles) despite en=0.", gap_count);
        else begin
            $display("[FAIL] Trailing gap duration wrong: expected %0d, got %0d!", gap_cycle_target, gap_count);
            errors = errors + 1;
        end

        @(posedge clk);   // let running's drop fully settle before checking

        if (running !== 1'b0) begin
            $display("[FAIL] Time %0t: running did NOT drop after trailing gap completed!", $time);
            errors = errors + 1;
        end else
            $display("[PASS] running correctly dropped to 0 at the post-gap frame boundary.");

        repeat (5) begin
            @(posedge clk);
            if (running !== 1'b0 || next_item !== 1'b0) begin
                $display("[FAIL] Time %0t: Module unexpectedly active after stop (running=%b, next_item=%b)!",
                          $time, running, next_item);
                errors = errors + 1;
            end
        end
        $display("[PASS] Module remained idle for 5 cycles after stopping.");

        #(CLK_PERIOD * 5);
        $display("\n==================================================");
        $display("               SIMULATION SUMMARY                  ");
        $display("==================================================");
        $display("running_drop observed          : %s", running_drop_seen ? "YES" : "NO");
        $display("Total next_item pulses         : %0d", total_next_item_pulses);
        if (errors == 0)
            $display(">> RESULT: ALL CHECKS PASSED. <<");
        else
            $display(">> RESULT: %0d ERROR(S) -- see [FAIL] lines above. <<", errors);
        $display("==================================================");

        $stop;
    end

endmodule