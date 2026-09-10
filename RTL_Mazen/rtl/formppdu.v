module form_ppdu #(
    parameter rate_mode = "H"
)(
    input  wire        clk, rst, mode, i_valid, i_e, i_o, i_SHR,
    input  wire [95:0] i_preamble_SFD,
    output reg         o_i, o_q, o_valid
);

    reg [95:0] shift_reg;
    reg [6:0]  bit_count;

always @(posedge clk) 
begin
    if (rst) 
    begin
        o_i       <= 1'b0;
        o_q       <= 1'b0;
        o_valid   <= 1'b0;
        shift_reg <= 96'b0;
        bit_count   <= 7'd0;
    end 
    else 
    begin
        if (i_SHR) 
        begin
            if (!o_valid) 
            begin
                shift_reg <= i_preamble_SFD;
                bit_count   <= (rate_mode == "F") ? 7'd47 : 7'd95;
            end

            o_i     <= shift_reg[0];
            o_q     <= shift_reg[0];
            o_valid <= 1'b1;
            shift_reg <= shift_reg >> 1;
        end 
        else 
        begin
            o_i     <= i_e;
            o_q     <= i_o;
            o_valid <= i_valid;
        end
    end
end

endmodule