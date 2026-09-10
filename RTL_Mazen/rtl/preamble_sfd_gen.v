/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   :preamble_sfd_gen                                                       *
*********************************************************************************
*/

module preamble_sfd_gen #(
    parameter rate_mode     = 0,
    parameter preamble_bits = (rate_mode == 1) ? 32 : 80,
    parameter total_bits    = preamble_bits + 16
)(
    input                        clk, mode,
    output reg [total_bits-1:0]  preamble_sfd
);

wire [15:0] sfd_word;
                                     //SFD mirrored because its [0:15] in refrence
assign sfd_word = (rate_mode == 1) ? 16'b00111001_00101110 : 16'b11000100_01011110; 

always @(posedge clk) 
    if (rate_mode == 1) 
        preamble_sfd <= {{32{1'b1}}, sfd_word};
    else 
        preamble_sfd <= {{80{1'b1}}, sfd_word};
    
endmodule