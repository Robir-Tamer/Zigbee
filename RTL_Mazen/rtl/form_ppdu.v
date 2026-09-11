/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   :form_ppdu                                                       *
*********************************************************************************
*/

module form_ppdu #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H"
)(
/************************************ Inputs ***********************************/
    input  wire        clk, 
    input  wire        rst, 
    input  wire        mode, 
    input  wire        i_valid, 
    input  wire        i_e, 
    input  wire        i_o,
    input  wire [95:0] i_preamble_SFD,
/*********************************** Outputs ***********************************/
    output reg         o_i, 
    output reg         o_q, 
    output reg         o_valid
);

    reg [95:0] shift_reg;
    reg [6:0]  bit_count;
    reg        sending_shr;

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            o_i         <= 1'b0;
            o_q         <= 1'b0;
            o_valid     <= 1'b0;
            shift_reg   <= 96'b0;
            bit_count   <= 7'd0;
            sending_shr <= 1'b0;
        end 
        else 
        begin
            if (i_valid && !sending_shr && !o_valid) 
            begin
                shift_reg   <= i_preamble_SFD;
                bit_count   <= (rate_mode == "F") ? 7'd47 : 7'd95;
                sending_shr <= 1'b1;
                o_valid     <= 1'b1;
            end

            if (sending_shr) 
            begin
                o_i <= shift_reg[0];
                o_q <= shift_reg[0];
                shift_reg <= shift_reg >> 1;

                if (bit_count == 7'd0) 
                begin
                    sending_shr <= 1'b0;
                end 
                else 
                begin
                    bit_count <= bit_count - 1'b1;
                end
            end 
            else if (i_valid) 
            begin
                o_i     <= i_e;
                o_q     <= i_o;
                o_valid <= 1'b1;
            end 
            else 
            begin
                o_i     <= 1'b0;
                o_q     <= 1'b0;
                o_valid <= 1'b0;
            end
        end
    end

endmodule