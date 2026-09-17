//done by sherif ahmed
//done by sherif ahmed

module zigbee_tb();

    //-- DUT --------------------------------------------------------
    // DUT parameters
    parameter  rate_mode          = "F";
    parameter  wl                 = 6;
    parameter  fl                 = 4;
    parameter  payload_w          = 8;
    parameter  max_payload_length = 127;
    parameter  header_length      = 12;
    parameter  dqpsk_fifo_w       = 2;
    parameter  dqpsk_fifo_depth   = 4096;
    localparam pay_size           = $clog2(max_payload_length);

    // DUT inputs
    reg                  clk;
    reg                  rst_n;
    reg  [payload_w-1:0] payload;
    reg  [pay_size-1:0]  payload_length;
    reg                  start_tx;

    // DUT outputs
    wire [7:0]           tx_real;
    wire [7:0]           tx_imag;
    wire                 tx_done;

    // DUT instantiation 
    zigbee_fpga #(
        .rate_mode          (rate_mode),
        .wl                 (wl),
        .fl                 (fl),
        .payload_w          (payload_w),
        .max_payload_length (max_payload_length),
        .header_length      (header_length),
        .dqpsk_fifo_w       (dqpsk_fifo_w),
        .dqpsk_fifo_depth   (dqpsk_fifo_depth)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .payload        (payload),
        .payload_length (payload_length),
        .start_tx       (start_tx),

        .tx_real        (tx_real),
        .tx_imag        (tx_imag),
        .tx_done        (tx_done)
    );

    //-- clk gen --------------------------------------------------
    initial begin  
        clk=0;  
        forever   
            #1 clk=~clk;  
    end 
   
    //-- input stimulus -------------------------------------------
    reg [payload_w-1:0] payload_mem [0:max_payload_length-1];
    initial begin
        $readmemb("../Scripts/payload_ai.txt", payload_mem);
    end


    //-- Test parameters -------------------------------------------
    parameter max_output_samples = 100000;  //capture the output samples in large buffer
    reg        [7:0]   rtl_tx_real   [0:max_output_samples-1];
    reg        [7:0]   rtl_tx_imag   [0:max_output_samples-1];
    reg signed [3:0]   rtl_QPSK_real_then_imag [0:max_output_samples-1];
    reg        [1:0]   rtl_interleaver [0:max_output_samples-1];
    reg        [7:0]   rtl_symbol_mapper [0:max_output_samples-1];
    reg        [5:0]   rtl_demux [0:max_output_samples-1];
    reg                rtl_zero_padding [0:max_output_samples-1];
    reg signed [7:0]   rtl_dqpsk_real_then_imag [0:max_output_samples-1];





    integer test_payload_length [0:10];      // Payload length test cases
    initial begin
        // test_payload_length[0] = 32;
        test_payload_length[1] = 28;
        // test_payload_length[2] = 127;
    end








    // for comparing the output with MATLAB golden output
    integer sample_count;

    integer real_errors ;
    integer imag_errors;

    integer real_correct;
    integer imag_correct;

    integer QPSK_count;
    integer QPSK_errors;
    integer QPSK_correct;

    integer inter_count;
    integer inter_corr;
    integer inter_errors;

    integer symbol_count;
    integer symbol_errors;
    integer symbol_correct;

    integer demux_count;
    integer demux_errors;
    integer demux_correct;

    integer zero_padding_count;
    integer zero_padding_errors;
    integer zero_padding_correct;

integer dqpsk_count;
integer dqpsk_errors;
integer dqpsk_correct;


    integer i;
    integer test_case;


    integer log_file_TX;
    integer log_file_QPSK;
    integer log_file_interleaver;
    integer log_file_symbol_mapper;
    integer log_file_demux;
    integer log_file_zero_padding;
    integer log_file_dqpsk;
    //-- MATLAB golden output --------------------------------------
    reg        [7:0]   matlab_tx_real [0:max_output_samples-1];
    reg        [7:0]   matlab_tx_imag [0:max_output_samples-1];
    reg signed [3:0]   matlab_QPSK [0:max_output_samples-1];

    //interleaver
    reg        [1:0]  matlab_interleaver [0:max_output_samples-1];
    
    //symbol mapper
    reg [7:0]  matlab_symbol_mapper [0:max_output_samples-1];

    //demux
    reg [5:0]  matlab_demux [0:max_output_samples-1];

    //zero padding
    reg  matlab_zero_padding [0:max_output_samples-1];

    //dqpsk
    reg signed [7:0]  matlab_dqpsk [0:max_output_samples-1];

    ////////////////////////////////////////////////////////////////
    //-- Start Simulation ------------------------------------------
    initial begin
        // start log file
        log_file_TX            = $fopen("../F_log/00_TX_transcript.log"           , "w");
        log_file_QPSK          = $fopen("../F_log/06_QPSK_transcript.log"         , "w");
        log_file_interleaver   = $fopen("../F_log/04_interleaver_transcript.log"  , "w");
        log_file_symbol_mapper = $fopen("../F_log/03_symbol_mapper_transcript.log", "w");
        log_file_demux         = $fopen("../F_log/02_demux_transcript.log"        , "w");
        log_file_zero_padding  = $fopen("../F_log/01_zero_padding_transcript.log" , "w");
        log_file_dqpsk         = $fopen("../F_log/07_dqpsk_transcript.log"        , "w");

        $fdisplay(log_file_TX, "========================================");
        $fdisplay(log_file_TX, "Zigbee TB Started");
        $fdisplay(log_file_TX, "========================================");

        $fdisplay(log_file_QPSK, "========================================");
        $fdisplay(log_file_QPSK, "Zigbee TB Started");
        $fdisplay(log_file_QPSK, "========================================");

        $fdisplay(log_file_interleaver, "========================================");
        $fdisplay(log_file_interleaver, "Zigbee TB Started");
        $fdisplay(log_file_interleaver, "========================================");

        $fdisplay(log_file_symbol_mapper, "========================================");
        $fdisplay(log_file_symbol_mapper, "Zigbee TB Started");
        $fdisplay(log_file_symbol_mapper, "========================================");

        $fdisplay(log_file_demux, "========================================");
        $fdisplay(log_file_demux, "Zigbee TB Started");
        $fdisplay(log_file_demux, "========================================");

        $fdisplay(log_file_zero_padding, "========================================");
        $fdisplay(log_file_zero_padding, "Zigbee TB Started");
        $fdisplay(log_file_zero_padding, "========================================");

        $fdisplay(log_file_dqpsk, "========================================");
        $fdisplay(log_file_dqpsk, "Zigbee TB Started");
        $fdisplay(log_file_dqpsk, "========================================");

        

        test_case      = 1;  
        rst_n          = 0;
        payload        = 0;
        payload_length = 0;
        start_tx       = 0;

        // final RTL reset timing is not confirmed.
        repeat (2) @(negedge clk); //not determined cycles

        // check reset behavior
        if(tx_done !==0 || tx_real !== 0 || tx_imag !== 0) begin
         $display("Error: DUT outputs are not reset to zero after reset.");
            $stop;
        end
        else begin
            $display("Reset is OK.");
        end

        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display ("rst deasserted, starting test case %0d", test_case);
        $display("Rate Mode       = %s", rate_mode);
        $display("Payload Length  = %0d", test_payload_length[test_case]);
        $display("========================================");

        // Set current payload length
        payload_length = test_payload_length[test_case];
        // Read MATLAB golden output for current test
    
        if (test_case == 0) begin
            $readmemb("matlab_tx_real_F_0.txt", matlab_tx_real);
            $readmemb("matlab_tx_imag_F_0.txt", matlab_tx_imag);
        end
        else if (test_case == 1) begin
            $readmemb("../Tx_output/1Mbps/00_tx_real_1Mbps.txt", matlab_tx_real);
            $readmemb("../Tx_output/1Mbps/00_tx_imag_1Mbps.txt", matlab_tx_imag);
            $readmemb("../Tx_output/1Mbps/06_QPSK_OUT_1M.txt", matlab_QPSK);
            $readmemb("../Tx_output/1Mbps/04_interleaver_output_1M.txt", matlab_interleaver);
            $readmemb("../Tx_output/1Mbps/03_symbolmapper_output_1M.txt", matlab_symbol_mapper);
            $readmemb("../Tx_output/1Mbps/02_demux_output_1M.txt", matlab_demux);
            $readmemb("../Tx_output/1Mbps/01_zeropadding_output_1M.txt", matlab_zero_padding);
            $readmemb("../Tx_output/1Mbps/07_DQPSK_OUT_1M.txt", matlab_dqpsk);
            //to be written by david
        end
        else if (test_case == 2) begin
            $readmemb("matlab_tx_real_F_127.txt", matlab_tx_real);
            $readmemb("matlab_tx_imag_F_127.txt", matlab_tx_imag);
        end
    

        for (i = 0; i < payload_length; i = i + 1) begin
            payload = payload_mem[i];
            @(negedge clk);
        end

        // Start transmission
        start_tx = 1'b1;
        @(negedge clk);
        start_tx = 1'b0;
        
        sample_count  = 0;
        QPSK_count    = 0;
        real_errors   = 0;
        imag_errors   = 0;
        real_correct  = 0;
        imag_correct  = 0;
        QPSK_errors   =0;
        QPSK_correct =0;
        inter_count = 0;
        inter_corr = 0;
        inter_errors = 0;
        symbol_count = 0;
        symbol_errors = 0;
        symbol_correct = 0;
        demux_count = 0;
        demux_errors = 0;
        demux_correct = 0;
        zero_padding_count = 0;
        zero_padding_errors = 0;
        zero_padding_correct = 0;
        dqpsk_count = 0;
        dqpsk_errors = 0;
        dqpsk_correct = 0;

        // Capture TX output samples
        while (tx_done !== 1'b1) begin
            rtl_tx_real[sample_count] = tx_real;
            rtl_tx_imag[sample_count] = tx_imag;

//zero padding scoreboard
            if (dut.ZeroPadding.valid) begin

                rtl_zero_padding [zero_padding_count] = dut.ZeroPadding.data_o;

                if (rtl_zero_padding [zero_padding_count] !== matlab_zero_padding[zero_padding_count]) begin
                    zero_padding_errors = zero_padding_errors + 1;

                    $fdisplay(log_file_zero_padding, "ZERO PADDING MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, zero_padding_count, rtl_zero_padding[zero_padding_count], matlab_zero_padding[zero_padding_count]);
                end
                else begin 
                    zero_padding_correct = zero_padding_correct + 1;
                    $fdisplay(log_file_zero_padding, "ZERO PADDING    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, zero_padding_count, rtl_zero_padding[zero_padding_count], matlab_zero_padding[zero_padding_count]);
                end
                
                zero_padding_count = zero_padding_count +1;
            end


//demux scoreboard
            if (dut.DEMUX.valid) begin

                rtl_demux [demux_count] = {dut.DEMUX.e_bits ,dut.DEMUX.o_bits};

                if (rtl_demux [demux_count] !== matlab_demux[demux_count]) begin
                    demux_errors = demux_errors + 1;

                    $fdisplay(log_file_demux, "DEMUX MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, demux_count, rtl_demux[demux_count], matlab_demux[demux_count]);
                end
                else begin 
                    demux_correct = demux_correct + 1;
                    $fdisplay(log_file_demux, "DEMUX    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, demux_count, rtl_demux[demux_count], matlab_demux[demux_count]);
                end
                
                demux_count = demux_count +1;
            end

//symbol mapper scoreboard
if (dut.symbol_mapper_to_ppdu.mapper_even_valid) begin

                rtl_symbol_mapper [symbol_count] = {dut.symbol_mapper_to_ppdu.mapper_even_data ,dut.symbol_mapper_to_ppdu.mapper_odd_data};

                if (rtl_symbol_mapper [symbol_count] !== matlab_symbol_mapper[symbol_count]) begin
                    symbol_errors = symbol_errors + 1;

                    $fdisplay(log_file_symbol_mapper, "SYMBOL MAPPER MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, symbol_count, rtl_symbol_mapper[symbol_count], matlab_symbol_mapper[symbol_count]);
                end
                else begin 
                    symbol_correct = symbol_correct + 1;
                    $fdisplay(log_file_symbol_mapper, "SYMBOL MAPPER    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, symbol_count, rtl_symbol_mapper[symbol_count], matlab_symbol_mapper[symbol_count]);
                end
                
                symbol_count = symbol_count +1;
            end




//qpsk scoreboard
            if (dut.QPSK.valid) begin 
                rtl_QPSK_real_then_imag [QPSK_count] = {dut.QPSK.out_real, dut.QPSK.out_imag};

                if (rtl_QPSK_real_then_imag [QPSK_count] !== matlab_QPSK[QPSK_count]) begin
                    QPSK_errors = QPSK_errors + 1;

                    $fdisplay(log_file_QPSK, "QPSK MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, QPSK_count, rtl_QPSK_real_then_imag[QPSK_count], matlab_QPSK[QPSK_count]);
                end
                else begin 
                    QPSK_correct = QPSK_correct + 1;
                    $fdisplay(log_file_QPSK, "QPSK    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, QPSK_count, rtl_QPSK_real_then_imag[QPSK_count], matlab_QPSK[QPSK_count]);
                end
                
                QPSK_count = QPSK_count +1;
            end 

//interleaver scoreboard
            if (dut.symbol_mapper_to_ppdu.interleaver_even_valid) begin

                rtl_interleaver [inter_count] = {dut.symbol_mapper_to_ppdu.interleaver_even_data ,dut.symbol_mapper_to_ppdu.interleaver_odd_data};
//dut.symbol_mapper_to_ppdu.mapper_even_data
                if (rtl_interleaver [inter_count] !== matlab_interleaver[inter_count]) begin
                    inter_errors = inter_errors + 1;

                    $fdisplay(log_file_interleaver, "INTERLEAVER MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, inter_count, rtl_interleaver[inter_count], matlab_interleaver[inter_count]);
                end
                else begin 
                    inter_corr = inter_corr + 1;
                    $fdisplay(log_file_interleaver, "INTERLEAVER    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, inter_count, rtl_interleaver[inter_count], matlab_interleaver[inter_count]);
                end
                
                inter_count = inter_count +1;
            end

            if(dut.symbol_mapper_to_ppdu.interleaver_even_valid!==dut.symbol_mapper_to_ppdu.interleaver_odd_valid) begin
               $fdisplay(log_file_interleaver, "INTERLEAVER VALID MISMATCH at time: %0t: count %0d: even_valid=%b odd_valid=%b ",
                            $time, inter_count, dut.symbol_mapper_to_ppdu.interleaver_even_valid, dut.symbol_mapper_to_ppdu.interleaver_odd_valid);
                $stop;
            end

//dqpsk scoreboard
            if (dut.DQPSK_CSK.DQPSK_DUT.valid) begin 
                rtl_dqpsk_real_then_imag [dqpsk_count] = {dut.DQPSK_CSK.DQPSK_DUT.Real_o, dut.DQPSK_CSK.DQPSK_DUT.Imag_o};

                if (rtl_dqpsk_real_then_imag [dqpsk_count] !== matlab_dqpsk[dqpsk_count]) begin
                    dqpsk_errors = dqpsk_errors + 1;

                    $fdisplay(log_file_dqpsk, "DQPSK MISMATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, dqpsk_count, rtl_dqpsk_real_then_imag[dqpsk_count], matlab_dqpsk[dqpsk_count]);
                end
                else begin 
                    dqpsk_correct = dqpsk_correct + 1;
                    $fdisplay(log_file_dqpsk, "DQPSK    MATCH at time: %0t: count %0d: RTL=%b MATLAB=%b ",
                            $time, dqpsk_count, rtl_dqpsk_real_then_imag[dqpsk_count], matlab_dqpsk[dqpsk_count]);
                end
                
                dqpsk_count = dqpsk_count +1;
            end


 
 //tx scoreboard
            if (rtl_tx_real[sample_count] !== matlab_tx_real[sample_count]) begin
                real_errors = real_errors + 1;

                $fdisplay(log_file_TX, "REAL MISMATCH at time: %0t: sample %0d: RTL=%b MATLAB=%b ",
                        $time, sample_count, rtl_tx_real[sample_count], matlab_tx_real[sample_count]);
            end
            else begin 
                real_correct = real_correct + 1;
                $fdisplay(log_file_TX, "REAL MATCH at time: %0t: sample %0d: RTL=%b MATLAB=%b ",
                        $time, sample_count, rtl_tx_real[sample_count], matlab_tx_real[sample_count]);
            end


            if (rtl_tx_imag[sample_count] !== matlab_tx_imag[sample_count]) begin
                imag_errors = imag_errors + 1;

                $fdisplay(log_file_TX, "IMAG MISMATCH at time: %0t: sample %0d: RTL=%b MATLAB=%b",
                        $time, sample_count, rtl_tx_imag[sample_count], matlab_tx_imag[sample_count]);
            end
            else begin 
                imag_correct = imag_correct + 1;
                $fdisplay(log_file_TX, "IMAG MATCH at time: %0t: sample %0d: RTL=%b MATLAB=%b",
                        $time, sample_count, rtl_tx_imag[sample_count], matlab_tx_imag[sample_count]);
            end

            sample_count = sample_count + 1;
            @(negedge clk);
        end
        $display ($time, " ns: tx_done asserted.");
        $display("TX completed. Captured %0d samples.", sample_count);
        //wait will break if tx done =1 so now we will compare
        // Compare with MATLAB
            
        $display("----------------------------------------");
        $display("Test Case %0d Results", test_case);
        $display("Payload Length = %0d", test_payload_length[test_case]);

             $display("QPSK errors = %0d", QPSK_errors);
        $display("QPSK Correct = %0d", QPSK_correct);

        $display("Interleaver errors = %0d", inter_errors);
        $display("Interleaver Correct = %0d", inter_corr);

    $display("Symbol Mapper errors = %0d", symbol_errors);
        $display("Symbol Mapper Correct = %0d", symbol_correct);

        $display("Zero Padding errors = %0d", zero_padding_errors);
        $display("Zero Padding Correct = %0d", zero_padding_correct);

$display("Demux errors = %0d", demux_errors);
        $display("Demux Correct = %0d", demux_correct);
        
        $display("REAL errors = %0d", real_errors);
        $display("IMAG errors = %0d", imag_errors);
        $display("REAL Correct = %0d", real_correct);
        $display("IMAG Correct = %0d", imag_correct);
        $display("DQPSK errors = %0d", dqpsk_errors);
        $display("DQPSK Correct = %0d", dqpsk_correct);
    
        $display("Total captured samples = %0d", sample_count);
        $display("----------------------------------------");
   
        if ((real_errors == 0)         && 
            (imag_errors == 0)         && 
            (QPSK_errors == 0)              &&
            (inter_errors == 0)        && 
            (symbol_errors == 0)       && 
            (demux_errors == 0)             &&
            (zero_padding_errors == 0) && 
            (dqpsk_errors == 0) )
            $display("******** TEST CASE PASSED: All blocks behaves exactly like MATLAB model ********");
        else
            $display("******** TEST CASE FAILED ********");
    
    $display("All test cases completed.");
    $stop;
    end
    
endmodule