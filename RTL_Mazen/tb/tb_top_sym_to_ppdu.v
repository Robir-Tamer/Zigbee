/*
********************************** Documentation *********************************
*Author : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : tb_top_sym_to_ppdu                                                      *
*********************************************************************************
*/

module tb_top_sym_to_ppdu;

    // Parameters - Set to Hybrid Mode
    parameter RATE_MODE = "H";
    parameter CLK_PERIOD = 10; // 10 ns clock -> 100 MHz

    // Inputs
    reg         clk;
    reg         rst_n;
    reg         mode;
    reg         i_valid;
    // In Hybrid mode ("H"), input data width is 6 bits [5:0]
    reg  [5:0]  i_data_even;
    reg  [5:0]  i_data_odd;

    // Outputs
    wire        o_i;
    wire        o_q;
    wire        o_valid;
    wire        interleaver_even_valid;
    wire        interleaver_odd_valid;

    // Instantiate Top Module with all 11 ports connected
    top_sym_to_ppdu #(
        .rate_mode(RATE_MODE)
    ) u_ut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .mode                   (mode),
        .i_valid                (i_valid),
        .i_data_even            (i_data_even),
        .i_data_odd             (i_data_odd),
        .o_i                    (o_i),
        .o_q                    (o_q),
        .o_valid                (o_valid),
        .interleaver_even_valid (interleaver_even_valid),
        .interleaver_odd_valid  (interleaver_odd_valid)
    );

    // Clock Generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    integer bit_counter = 0;

    initial begin
        $display("--------------------------------------------------------------------------------------------------------------------------------------------------");
        $display("Time(ns) | rst | mode | i_val | in_even | in_odd  | Map_E_Val Map_E_Data          | Map_O_Val Map_O_Data          | Int_E_Val Int_O_Val | o_val | o_i o_q");
        $display("--------------------------------------------------------------------------------------------------------------------------------------------------");
    end

    always @(posedge clk) begin
        if (rst_n && (i_valid || o_valid || u_ut.mapper_even_valid || u_ut.mapper_odd_valid || interleaver_even_valid)) begin
            $display("%0t      |  %b  |  %b   |   %b   |  %6b |  %6b |     %b     | %32b |     %b     | %32b |     %b     |     %b     |   %b   |  %b   %b", 
                     $time, rst_n, mode, i_valid, i_data_even, i_data_odd, 
                     u_ut.mapper_even_valid, u_ut.mapper_even_data, 
                     u_ut.mapper_odd_valid, u_ut.mapper_odd_data, 
                     interleaver_even_valid, interleaver_odd_valid, 
                     o_valid, o_i, o_q);
        end
        
        if (o_valid) begin
            bit_counter = bit_counter + 1;
        end
    end

    initial begin
        rst_n       = 1'b0; // Assert active-low reset initially
        mode        = 1'b1; // Set mode to 1 Mhz (Hybrid mode F)
        i_valid     = 1'b0;
        i_data_even = 6'b0;
        i_data_odd  = 6'b0;

        repeat(2) @(negedge clk);
        rst_n       = 1'b1; // Release reset
        repeat(2) @(negedge clk);

        $display("[INFO] Reset released. Starting symbol transmission...");

        // Send a stream of symbols ensuring upper bits [5:3] are padded with zeros
        send_symbols(3'b001, 3'b010);
        send_symbols(3'b100, 3'b111);
        send_symbols(3'b011, 3'b101);

        // Allow enough time for the full PPDU frame to completely shift out
        repeat(300) @(negedge clk);

        $display("--------------------------------------------------------------------------------------------------------------------------------------------------");
        $display("[INFO] Simulation finished. Total valid output bits monitored: %0d", bit_counter);
        $display("--------------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end

    // Task to push 3-bit values into lower bits while keeping upper padding bits [5:3] explicitly 0
    task send_symbols(input [2:0] sym_even, input [2:0] sym_odd);
        begin
            @(negedge clk);
            i_valid     <= 1'b1;
            i_data_even <= {3'b000, sym_even}; // Upper bits [5:3] padded with 0
            i_data_odd  <= {3'b000, sym_odd};  // Upper bits [5:3] padded with 0
            @(negedge clk);
            i_valid     <= 1'b0;
            i_data_even <= 6'b0;
            i_data_odd  <= 6'b0;
            repeat(300) @(negedge clk); // Spacing between input injections
        end
    endtask

endmodule