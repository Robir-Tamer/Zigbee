/*
********************************** Documentation *********************************
*Author : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : preamble_sfd_gen                                                       *
*********************************************************************************
*/

module preamble_sfd_gen #(
/********************************** Parameters *********************************/
    parameter  rate_mode     = "H",
    localparam shr_bits      = (rate_mode == "F") ? 48 : 96
)(
/************************************ Inputs ***********************************/
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       mode,
/*********************************** Outputs ***********************************/
    output reg  [shr_bits-1:0]        preamble_sfd
);

    generate
        if (rate_mode == "F") begin : gen_fast_mode
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = 16'b00111001_00101110;
            
            always @(posedge clk) 
                if (!rst_n) 
                    preamble_sfd <= 'b0;              
                else
                    preamble_sfd <= {sfd_word, {32{1'b1}}}; 
                
            
        end 
        
        else if (rate_mode == "S") begin : gen_slow_mode
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = 16'b11000100_01011110;
            
            always @(posedge clk) 
                if (!rst_n)   
                    preamble_sfd <= 'b0;
                else 
                    preamble_sfd <= {sfd_word, {80{1'b1}}}; 
                
        end 

        else begin : gen_hybrid_mode 
            
            wire [15:0] sfd_word;
            // SFD mirrored because its [0:15] in reference
            assign sfd_word = (mode == 1) ? 16'b00111001_00101110 : 16'b11000100_01011110;      

            always @(posedge clk) 
                if (!rst_n) 
                    preamble_sfd <= 'b0;
                 
                else 
                    if (mode)
                        preamble_sfd <= {48'b0, sfd_word, {32{1'b1}}}; 
                    else
                        preamble_sfd <= {sfd_word, {80{1'b1}}};                    
        end
    endgenerate

endmodule