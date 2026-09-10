/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   :preamble_sfd_gen                                                        *
*********************************************************************************
*/

module preamble_sfd_gen #(
/********************************** Parameters *********************************/
    parameter rate_mode     = "H",
    parameter preamble_bits = (rate_mode == "F") ? 32 : 80,
    parameter total_bits    = preamble_bits + 16
)(
/************************************ Inputs ***********************************/
    input                             clk, rst, mode,
/*********************************** Outputs ***********************************/
    output reg [total_bits-1:0]       preamble_sfd,
    output reg                        o_valid
);

    generate
        if (rate_mode == "F") begin : gen_fast_mode
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = 16'b00111001_00101110;
            
            always @(posedge clk or posedge rst) 
            begin
                if (rst) 
                begin
                    preamble_sfd <= 'b0;
                    o_valid      <= 1'b0;
                end 
                else 
                begin
                    preamble_sfd <= {sfd_word, {32{1'b1}}}; 
                    o_valid      <= 1'b1;
                end
            end
        end 
        
        else if (rate_mode == "S") begin : gen_slow_mode
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = 16'b11000100_01011110;
            
            always @(posedge clk or posedge rst) 
            begin
                if (rst) 
                begin
                    preamble_sfd <= 'b0;
                    o_valid      <= 1'b0;
                end 
                else 
                begin
                    preamble_sfd <= {sfd_word, {80{1'b1}}}; 
                    o_valid      <= 1'b1;
                end
            end
        end 

        else begin : gen_hybrid_mode 
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = (mode == 1) ? 16'b00111001_00101110 : 16'b11000100_01011110;      

            always @(posedge clk or posedge rst) 
            begin
                if (rst) 
                begin
                    preamble_sfd <= 'b0;
                    o_valid      <= 1'b0;
                end 
                else 
                begin
                    if (mode)
                        preamble_sfd <= {sfd_word, {32{1'b1}}}; 
                    else
                        preamble_sfd <= {sfd_word, {80{1'b1}}}; 
                    
                    o_valid      <= 1'b1;
                end
            end
        end
    endgenerate

endmodule
