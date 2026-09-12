/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : form_ppdu                                                              *
*********************************************************************************
*/

module form_ppdu #(
/********************************** Parameters *********************************/
    parameter rate_mode     = "H",
    localparam shr_bits = (rate_mode == "F") ? 48 : 96,
    localparam total_bits    = shr_bits + 16
)(
/************************************ Inputs ***********************************/
    input  wire        clk, 
    input  wire        rst_n, 
    input  wire        mode, 
    input  wire        i_valid, 
    input  wire        i_e, 
    input  wire        i_o,
    input  wire [shr_bits-1:0] i_preamble_SFD,
/*********************************** Outputs ***********************************/
    output reg         o_i, 
    output reg         o_q, 
    output reg         o_valid
);

generate
    if (rate_mode == "F") begin : gen_form_ppdu_1mbps
        reg [shr_bits-1:0]     reg_shr;
        reg [(shr_bits*2)-1:0] reg_data_i; 
        reg [(shr_bits*2)-1:0] reg_data_q; 
        reg [6:0]              bit_count;
        reg                    sending_shr;

        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                o_i         <= 1'b0;
                o_q         <= 1'b0;
                o_valid     <= 1'b0;
                reg_data    <=  'b0;
                reg_shr     <=  'b0;
                bit_count   <= 7'b0;
                sending_shr <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid)
                begin
                    reg_shr   <= i_preamble_SFD;
                    reg_data_i[0] <= reg_data_i;
                    reg_data_q[0] <= reg_data_q;
                    bit_count   <= 7'd47; // 48 bits for Mode F
                    sending_shr <= 1'b1;
                    o_valid     <= 1'b1;
                end 
                else if (sending_shr) 
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr <= reg_shr >> 1;

                    if (bit_count == 7'd0) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
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
    end
    else if (rate_mode == "S") begin : gen_form_ppdu_250kbps
        reg [95:0] reg_shr;
        reg [6:0]  bit_count;
        reg        sending_shr;

        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                o_i         <= 1'b0;
                o_q         <= 1'b0;
                o_valid     <= 1'b0;
                reg_shr   <= 96'b0;
                bit_count   <= 7'd0;
                sending_shr <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) 
                begin
                    reg_shr   <= i_preamble_SFD;
                    bit_count   <= 7'd95; // 96 bits for Mode S
                    sending_shr <= 1'b1;
                    o_valid     <= 1'b1;
                end 
                else if (sending_shr) 
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr <= reg_shr >> 1;

                    if (bit_count == 7'd0) 
                        sending_shr <= 1'b0; 
                    else 
                        bit_count <= bit_count - 1'b1;
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
    end
    else if (rate_mode == "H") begin : gen_form_ppdu_hybrid
        reg [95:0] reg_shr;
        reg [6:0]  bit_count;
        reg        sending_shr;

        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                o_i         <= 1'b0;
                o_q         <= 1'b0;
                o_valid     <= 1'b0;
                reg_shr   <= 96'b0;
                bit_count   <= 7'd0;
                sending_shr <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) 
                begin
                    reg_shr   <= i_preamble_SFD;
                    // 48 bits (7'd47) if mode is high (1 Mbps), 96 bits (7'd95) otherwise
                    bit_count   <= mode ? 7'd47 : 7'd95; 
                    sending_shr <= 1'b1;
                    o_valid     <= 1'b1;
                end 
                else if (sending_shr) 
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr <= reg_shr >> 1;

                    if (bit_count == 7'd0) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
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
    end
endgenerate

endmodule
