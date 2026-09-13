/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : form_ppdu                                                              *
*********************************************************************************
*/

module form_ppdu #(
/********************************** Parameters *********************************/
    parameter  rate_mode     = "H",
    localparam shr_bits      = (rate_mode == "F") ? 48 : 96
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
        reg [shr_bits-2:0] reg_shr;
        reg [shr_bits-1:0] reg_data_i; 
        reg [shr_bits-1:0] reg_data_q; 
        reg [shr_bits-1:0] reg_data_valid;
        reg [5:0]          bit_count;
        reg                sending_shr;

        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                o_i            <= 1'b0;
                o_q            <= 1'b0;
                o_valid        <= 1'b0;
                reg_data_i     <=  'b0;
                reg_data_q     <=  'b0;
                reg_data_valid <=  'b0;
                reg_shr        <=  'b0;
                bit_count      <= 6'b0;
                sending_shr    <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) // [1] starting transmitting SHR when i_valid is asserted
                begin
                    reg_shr       <= i_preamble_SFD[shr_bits-1:1];

                    o_i           <= i_preamble_SFD[0];
                    o_q           <= i_preamble_SFD[0]; 

                    reg_data_i[0]     <= i_e;
                    reg_data_q[0]     <= i_o;
                    reg_data_valid[0] <= i_valid;
                    
                    bit_count     <= 6'd48; // 48 bits for Mode F
                    sending_shr   <= 1'b1;
                    o_valid       <= 1'b1;
                end 
                else if (sending_shr) // [2] Transmitting SHR
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr   <= reg_shr >> 1;

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};

                    if (bit_count == 6'd2) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
                end 
                else if (reg_data_valid[shr_bits-1]) // [3] Transmitting stored data after SHR then New ones 
                begin
                    o_i     <= reg_data_i[shr_bits-1];
                    o_q     <= reg_data_q[shr_bits-1];

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};
                    
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
        reg [shr_bits-2:0] reg_shr;
        reg [shr_bits-1:0] reg_data_i; 
        reg [shr_bits-1:0] reg_data_q; 
        reg [shr_bits-1:0] reg_data_valid;
        reg [6:0]          bit_count;
        reg                sending_shr;

        always @(posedge clk) 
        begin
           if (!rst_n) 
            begin
                o_i            <= 1'b0;
                o_q            <= 1'b0;
                o_valid        <= 1'b0;
                reg_data_i     <=  'b0;
                reg_data_q     <=  'b0;
                reg_data_valid <=  'b0;
                reg_shr        <=  'b0;
                bit_count      <= 7'b0;
                sending_shr    <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) // [1] starting transmitting SHR when i_valid is asserted
                begin
                    reg_shr       <= i_preamble_SFD[shr_bits-1:1];

                    o_i           <= i_preamble_SFD[0];
                    o_q           <= i_preamble_SFD[0]; 

                    reg_data_i[0]     <= i_e;
                    reg_data_q[0]     <= i_o;
                    reg_data_valid[0] <= i_valid;
                    
                    bit_count     <= 7'd96; // 96 bits for Mode F
                    sending_shr   <= 1'b1;
                    o_valid       <= 1'b1;
                end 
                else if (sending_shr) // [2] Transmitting SHR
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr   <= reg_shr >> 1;

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};

                    if (bit_count == 7'd2) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
                end 
                else if (reg_data_valid[shr_bits-1]) // [3] Transmitting stored data after SHR then New ones 
                begin
                    o_i     <= reg_data_i[shr_bits-1];
                    o_q     <= reg_data_q[shr_bits-1];

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};
                    
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
    reg [shr_bits-2:0] reg_shr;
    reg [shr_bits-1:0] reg_data_i; 
    reg [shr_bits-1:0] reg_data_q; 
    reg [shr_bits-1:0] reg_data_valid;
    reg [6:0]          bit_count;
    reg                sending_shr;

    always @(posedge clk) 
    begin
        if (mode)
        begin
            if (!rst_n) 
            begin
                o_i            <= 1'b0;
                o_q            <= 1'b0;
                o_valid        <= 1'b0;
                reg_data_i     <=  'b0;
                reg_data_q     <=  'b0;
                reg_data_valid <=  'b0;
                reg_shr        <=  'b0;
                bit_count      <= 7'b0;
                sending_shr    <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) 
                begin
                    reg_shr       <= i_preamble_SFD[shr_bits-1:1];

                    o_i           <= i_preamble_SFD[0];
                    o_q           <= i_preamble_SFD[0]; 

                    reg_data_i[0]     <= i_e;
                    reg_data_q[0]     <= i_o;
                    reg_data_valid[0] <= i_valid;
                    
                    // 48 bits if mode is high (1 Mbps), 96 bits otherwise
                    bit_count     <= mode ? 7'd48 : 7'd96;
                    sending_shr   <= 1'b1;
                    o_valid       <= 1'b1;
                end 
                else if (sending_shr) 
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr   <= reg_shr >> 1;

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};

                    if (bit_count == 7'd2) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
                end 
                else if (reg_data_valid[47]) 
                begin
                    o_i     <= reg_data_i[47];
                    o_q     <= reg_data_q[47];

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};
                    
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
        //////////////////////////////////
        else
        begin
            if (!rst_n) 
            begin
                o_i            <= 1'b0;
                o_q            <= 1'b0;
                o_valid        <= 1'b0;
                reg_data_i     <=  'b0;
                reg_data_q     <=  'b0;
                reg_data_valid <=  'b0;
                reg_shr        <=  'b0;
                bit_count      <= 7'b0;
                sending_shr    <= 1'b0;
            end 
            else 
            begin
                if (i_valid && !sending_shr && !o_valid) 
                begin
                    reg_shr       <= i_preamble_SFD[shr_bits-1:1];

                    o_i           <= i_preamble_SFD[0];
                    o_q           <= i_preamble_SFD[0]; 

                    reg_data_i[0]     <= i_e;
                    reg_data_q[0]     <= i_o;
                    reg_data_valid[0] <= i_valid;
                    
                    // 48 bits if mode is high (1 Mbps), 96 bits otherwise
                    bit_count     <= mode ? 7'd48 : 7'd96;
                    sending_shr   <= 1'b1;
                    o_valid       <= 1'b1;
                end 
                else if (sending_shr) 
                begin
                    o_i       <= reg_shr[0];
                    o_q       <= reg_shr[0];
                    reg_shr   <= reg_shr >> 1;

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};

                    if (bit_count == 7'd2) 
                        sending_shr <= 1'b0;
                    else 
                        bit_count <= bit_count - 1'b1;
                end 
                else if (reg_data_valid[shr_bits-1]) 
                begin
                    o_i     <= reg_data_i[shr_bits-1];
                    o_q     <= reg_data_q[shr_bits-1];

                    reg_data_i     <= {reg_data_i[shr_bits-2:0], i_e};
                    reg_data_q     <= {reg_data_q[shr_bits-2:0], i_o};
                    reg_data_valid <= {reg_data_valid[shr_bits-2:0], i_valid};
                    
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
end
endgenerate

endmodule