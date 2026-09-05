`timescale 1ns/1ps

module FIFO_mem_TB;

    // Local parameters for fast simulation (8 slots, 8-bit wide)
    parameter FIFO_WIDTH = 8;
    parameter FIFO_DEPTH = 8;
    
    // DUT Signals
    reg                    clk;
    reg                    rst_n;
    reg                    wr_en;
    reg                    rd_en;
    reg  [FIFO_WIDTH-1:0]  din;
    wire [FIFO_WIDTH-1:0]  dout;
    wire                   full_flag;
    wire                   empty_flag;

    // Test Bench Variables
    integer error_count = 0;
    integer test_step   = 0;

    // Instantiate DUT
    FIFO_mem #(
        .FIFO_WIDTH(FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full_flag(full_flag),
        .empty_flag(empty_flag)
    );

    // Clock Generation (100MHz / 10ns period)
    always #5 clk = ~clk;

    // Helper Task: Section Header
    task print_header(input [8*50:1] test_name);
        begin
            test_step = test_step + 1;
            $display("\n==================================================================");
            $display("[TEST %0d] %0s", test_step, test_name);
            $display("==================================================================");
        end
    endtask

    // Helper Task: Flag Validation
    task check_flags(input exp_full, input exp_empty, input [8*40:1] msg);
        begin
            if (full_flag !== exp_full || empty_flag !== exp_empty) begin
                $display(" [FAIL] Time=%0t | %0s | Expected [Full=%0b, Empty=%0b] Got [Full=%0b, Empty=%0b]",
                         $time, msg, exp_full, exp_empty, full_flag, empty_flag);
                error_count = error_count + 1;
            end else begin
                $display(" [PASS] Time=%0t | %0s | Flags OK [Full=%0b, Empty=%0b]",
                         $time, msg, full_flag, empty_flag);
            end
        end
    endtask

    // Stimulus & Verification Sequence
    initial begin
        clk   = 0;
        rst_n = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // -------------------------------------------------------------
        // TEST 1: Synchronous Reset Verification
        // -------------------------------------------------------------
        print_header("Synchronous Active-Low Reset Test");
        @(posedge clk);
        rst_n = 0; // Assert reset
        @(posedge clk);
        #1;
        check_flags(0, 1, "Reset Asserted");
        if (dout !== 0) begin
            $display(" [FAIL] Time=%0t | dout non-zero after reset: 0x%h", $time, dout);
            error_count = error_count + 1;
        end else begin
            $display(" [PASS] Time=%0t | dout correctly cleared to 0x00", $time);
        end
        
        rst_n = 1; // Release reset
        @(posedge clk);

        // -------------------------------------------------------------
        // TEST 2: Single Write & Read Operation
        // -------------------------------------------------------------
        print_header("Single Write and Read Operation");
        @(posedge clk);
        wr_en = 1; din = 8'hA5;
        @(posedge clk);
        wr_en = 0; din = 8'h00;
        #1;
        check_flags(0, 0, "After 1 Write Operation");

        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        #1;
        if (dout !== 8'hA5) begin
            $display(" [FAIL] Time=%0t | Read mismatch! Expected=0xA5, Got=0x%h", $time, dout);
            error_count = error_count + 1;
        end else begin
            $display(" [PASS] Time=%0t | Data matched: 0x%h", $time, dout);
        end
        check_flags(0, 1, "After Read Operation (FIFO Empty)");

        // -------------------------------------------------------------
        // TEST 3: Fill Buffer to FULL Condition
        // -------------------------------------------------------------
        print_header("Filling FIFO to Capacity (8 Elements)");
        for (integer i = 0; i < FIFO_DEPTH; i = i + 1) begin
            @(posedge clk);
            wr_en = 1; din = 8'h10 + i;
        end
        @(posedge clk);
        wr_en = 0;
        #1;
        check_flags(1, 0, "FIFO Filled to Depth");

        // -------------------------------------------------------------
        // TEST 4: Overflow Protection (Write when FULL)
        // -------------------------------------------------------------
        print_header("Overflow Guard Test (Write when FULL)");
        @(posedge clk);
        wr_en = 1; din = 8'hFF; // Should be ignored
        @(posedge clk);
        wr_en = 0;
        #1;
        check_flags(1, 0, "Flags preserved after illegal write attempt");

        // -------------------------------------------------------------
        // TEST 5: Drain FIFO Completely & Verify Sequence
        // -------------------------------------------------------------
        print_header("Draining FIFO & Validating Sequential Order");
        for (integer i = 0; i < FIFO_DEPTH; i = i + 1) begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            rd_en = 0;
            #1;
            if (dout !== (8'h10 + i)) begin
                $display(" [FAIL] Slot %0d Data mismatch! Exp=0x%h, Got=0x%h", i, (8'h10 + i), dout);
                error_count = error_count + 1;
            end else begin
                $display(" [PASS] Time=%0t | Read Slot %0d: 0x%h", $time, i, dout);
            end
        end
        #1;
        check_flags(0, 1, "FIFO Fully Drained");

        // -------------------------------------------------------------
        // TEST 6: Underflow Protection (Read when EMPTY)
        // -------------------------------------------------------------
        print_header("Underflow Guard Test (Read when EMPTY)");
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        #1;
        check_flags(0, 1, "Flags preserved after illegal read attempt");

        // -------------------------------------------------------------
        // TEST 7: Simultaneous Read & Write
        // -------------------------------------------------------------
        print_header("Simultaneous Read & Write");
        // Pre-charge 1 element
        @(posedge clk);
        wr_en = 1; din = 8'h33;
        @(posedge clk);
        wr_en = 0; #1;

        // Concurrent Write (0x44) and Read (0x33)
        @(posedge clk);
        wr_en = 1; din = 8'h44;
        rd_en = 1;
        @(posedge clk);
        wr_en = 0; rd_en = 0; #1;

        if (dout !== 8'h33) begin
            $display(" [FAIL] Simultaneous Read Mismatch! Exp=0x33, Got=0x%h", dout);
            error_count = error_count + 1;
        end else begin
            $display(" [PASS] Simultaneous Read succeeded: 0x33", $time);
        end

        // Read remaining item (0x44)
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0; #1;
        if (dout !== 8'h44) begin
            $display(" [FAIL] Read of concurrent write failed! Exp=0x44, Got=0x%h", dout);
            error_count = error_count + 1;
        end else begin
            $display(" [PASS] Read of concurrent write succeeded: 0x44", $time);
        end

        // -------------------------------------------------------------
        // TEST 8: Address Pointer Rollover (Wrap-Around)
        // -------------------------------------------------------------
        print_header("Pointer Rollover & Address Boundary Test");
        for (integer loop = 0; loop < FIFO_DEPTH * 2; loop = loop + 1) begin
            @(posedge clk);
            wr_en = 1; din = loop[7:0] + 8'hA0;
            @(posedge clk);
            wr_en = 0;
            
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            rd_en = 0; #1;
            
            if (dout !== (loop[7:0] + 8'hA0)) begin
                $display(" [FAIL] Loop %0d Mismatch! Exp=0x%h, Got=0x%h", loop, (loop[7:0]+8'hA0), dout);
                error_count = error_count + 1;
            end
        end
        $display(" [PASS] Time=%0t | Successfully wrapped around memory boundary %0d times", $time, FIFO_DEPTH * 2);

        // -------------------------------------------------------------
        // Summary Transcript Log
        // -------------------------------------------------------------
        $display("\n==================================================================");
        $display("                    VERIFICATION SUMMARY REPORT                   ");
        $display("==================================================================");
        if (error_count == 0) begin
            $display("  RESULT  : PASSED");
            $display("  DETAILS : All tests passed with 0 failures.");
        end else begin
            $display("  RESULT  : FAILED");
            $display("  DETAILS : Total Errors Encountered = %0d", error_count);
        end
        $display("==================================================================\n");

        $stop;
    end

endmodule