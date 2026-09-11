//done by sherif ahmed

module zigbee_tb();

    // DUT parameters
    parameter rate_mode          = "S";
    parameter wl                 = 6;
    parameter fl                 = 4;
    parameter payload_w          = 8;
    parameter max_payload_length = 127;
    parameter header_length      = 12;

    // Test parameters
 // Payload length test cases
integer test_payload_length [0:2];

initial begin
    test_payload_length[0] = 0;
    test_payload_length[1] = 1;
    test_payload_length[2] = 127;
end


    // DUT inputs
    reg                         clk;
    reg                         rst_n;
    reg  [payload_w-1:0]        payload;
    reg  [$clog2(max_payload_length)-1:0] payload_length;
    reg                         start_tx;

    // DUT outputs
    wire [7:0]               tx_real;
    wire [7:0]               tx_imag;
    wire                        tx_done;

        zigbee #(
        .rate_mode          (rate_mode),
        .wl                 (wl),
        .fl                 (fl),
        .payload_w          (payload_w),
        .max_payload_length (max_payload_length),
        .header_length      (header_length)
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

        reg [payload_w-1:0] payload_mem [0:max_payload_length-1];
   
integer i;
integer test_case;
//input stimulus
    initial begin
        $readmemb("payload.txt", payload_mem);
    end
 //capture the output samples in large buffer
parameter max_output_samples = 100000;

reg [7:0]   rtl_tx_real [0:max_output_samples-1];
reg [7:0]   rtl_tx_imag [0:max_output_samples-1];

integer sample_count;
//for comparing the output with MATLAB golden output
  integer real_errors ;
integer imag_errors;

initial begin  
    clk=0;  
    forever   
        #1 clk=~clk;  
    end 

// MATLAB golden output


reg [7:0]   matlab_tx_real [0:max_output_samples-1];
reg [7:0]   matlab_tx_imag [0:max_output_samples-1];

//////////////////////////////////////////////////


initial begin
  
for (test_case = 0; test_case < 3; test_case = test_case + 1) begin
    
   rst_n          = 0;
    payload        = 0;
    payload_length = 0;
    start_tx       = 0;

    // final RTL reset timing is not confirmed.
    repeat (3) @(negedge clk); //not determined cycles

    //check reset behavior
    //if(tx_done !==0 || tx_real !== 0 || tx_imag !== 0) begin
      //  $display("Error: DUT outputs are not reset to zero after reset.");
        //$stop;
    //end
    

    rst_n = 1'b1;

    $display ("rst deasserted, starting test case %0d", test_case);
    $display("Rate Mode       = %s", rate_mode);
    $display("Payload Length  = %0d", test_payload_length[test_case]);
    $display("========================================");

    // Set current payload length
    payload_length = test_payload_length[test_case];
    // Read MATLAB golden output for current test// Read MATLAB golden output for current test
if (test_case == 0) begin
    $readmemb("matlab_tx_real_S_0.txt", matlab_tx_real);
    $readmemb("matlab_tx_imag_S_0.txt", matlab_tx_imag);
end 
else if (test_case == 1) begin
    $readmemb("matlab_tx_real_S_1.txt", matlab_tx_real);
    $readmemb("matlab_tx_imag_S_1.txt", matlab_tx_imag);
end 
else if (test_case == 2) begin
    $readmemb("matlab_tx_real_S_127.txt", matlab_tx_real);
    $readmemb("matlab_tx_imag_S_127.txt", matlab_tx_imag);
end

    // Load current payload
    for (i = 0; i < test_payload_length[test_case]; i = i + 1) begin
        payload = payload_mem[i];
        @(negedge clk);
    end

    // Start transmission
    start_tx = 1'b1;
    @(negedge clk);
    start_tx = 1'b0;

    sample_count = 0;
    real_errors  = 0;
    imag_errors  = 0;

    // Capture TX output samples
    while (tx_done !== 1'b1) begin
        @(negedge clk);

        rtl_tx_real[sample_count] = tx_real;
        rtl_tx_imag[sample_count] = tx_imag;

        sample_count = sample_count + 1;
    end

    $display("TX completed. Captured %0d samples.", sample_count);
    //wait will break if tx done =1 so now we will compare
    // Compare with MATLAB
    if(tx_done==1)begin
    for (i = 0; i < sample_count; i = i + 1) begin

        if (rtl_tx_real[i] !== matlab_tx_real[i]) begin
            real_errors = real_errors + 1;

            $display("REAL MISMATCH at sample %0d: RTL=%b MATLAB=%b",
                     i, rtl_tx_real[i], matlab_tx_real[i]);
        end

        if (rtl_tx_imag[i] !== matlab_tx_imag[i]) begin
            imag_errors = imag_errors + 1;

            $display("IMAG MISMATCH at sample %0d: RTL=%b MATLAB=%b",
                     i, rtl_tx_imag[i], matlab_tx_imag[i]);
        end

    end
    end

    $display("----------------------------------------");
    $display("Test Case %0d Results", test_case);
    $display("Payload Length = %0d", test_payload_length[test_case]);
    $display("REAL errors = %0d", real_errors);
    $display("IMAG errors = %0d", imag_errors);
    $display("Total captured samples = %0d", sample_count);
    $display("----------------------------------------");

    if ((real_errors == 0) && (imag_errors == 0))
        $display("******** TEST CASE PASSED ********");
    else
        $display("******** TEST CASE FAILED ********");
end
end
    $display("All test cases completed.");
endmodule
