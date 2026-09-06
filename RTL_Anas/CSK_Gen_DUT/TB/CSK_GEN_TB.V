`timescale 1ns/1ps

module CSK_GEN_TB #(parameter WL = 6);
reg clk = 0, en = 0;
reg [7:0] addr_ptr;
wire next_item;
wire signed [WL-1:0] csk_out_r;
wire signed [WL-1:0] csk_out_i;

CSK_GEN #(.WL(WL)) CSK_GEN_DUT (
    .clk(clk), .en(en), .addr_ptr(addr_ptr),
    .next_item(next_item),
    .csk_out_r(csk_out_r), .csk_out_i(csk_out_i)
);

always #5 clk = ~clk;

initial begin
    //Simulating the Controller Scenario
    //1 - Asserting Enable & Initializing addr_ptr 
    addr_ptr = 0;
    #7 en = 1;
    //2 - address point is increading and Fetching 
    // the Chirp signal sample each clock cycle
    //going above 152 samples to inspect CSK Behaviour
    repeat(155) begin
        @(posedge clk) begin
            addr_ptr = addr_ptr + 1'b1;
        end
    end
    //3 - Deasserting Enable
    en = 0;
    // Repeating the Scenario
        //1 - Asserting Enable & Initializing addr_ptr 
    addr_ptr = 0;
    #15 en = 1;
    //2 - address point is increading and Fetching 
    // the Chirp signal sample each clock cycle
    //going above 152 samples to inspect CSK Behaviour
    repeat(155) begin
        @(posedge clk) begin
            addr_ptr = addr_ptr + 1'b1;
        end
    end
    $stop;
end

endmodule