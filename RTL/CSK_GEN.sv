module CSK_GEN #(
    parameter WL = 6
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 en,
    output wire                 next_item,
    output reg  signed [WL-1:0] csk_out_r,
    output reg  signed [WL-1:0] csk_out_i,
    output reg                  running
);

    // ----------------------------------------------------------------
    // ROM via case statements
    // Formality-safe: purely combinational mux-trees with literal values.
    // No const arrays, no undriven nets.
    // ----------------------------------------------------------------
    reg [7:0] addr_ptr;

    reg signed [WL-1:0] rom_r, rom_i;

    always @(*) begin
        case (addr_ptr)
            8'd0:   rom_r = 6'sb000000;
            8'd1:   rom_r = 6'sb000001;
            8'd2:   rom_r = 6'sb111111;
            8'd3:   rom_r = 6'sb111011;
            8'd4:   rom_r = 6'sb111110;
            8'd5:   rom_r = 6'sb001010;
            8'd6:   rom_r = 6'sb001011;
            8'd7:   rom_r = 6'sb111011;
            8'd8:   rom_r = 6'sb110000;
            8'd9:   rom_r = 6'sb110111;
            8'd10:  rom_r = 6'sb000111;
            8'd11:  rom_r = 6'sb010000;
            8'd12:  rom_r = 6'sb001011;
            8'd13:  rom_r = 6'sb111101;
            8'd14:  rom_r = 6'sb110010;
            8'd15:  rom_r = 6'sb110001;
            8'd16:  rom_r = 6'sb111001;
            8'd17:  rom_r = 6'sb000100;
            8'd18:  rom_r = 6'sb001101;
            8'd19:  rom_r = 6'sb010000;
            8'd20:  rom_r = 6'sb001101;
            8'd21:  rom_r = 6'sb000111;
            8'd22:  rom_r = 6'sb111111;
            8'd23:  rom_r = 6'sb111000;
            8'd24:  rom_r = 6'sb110011;
            8'd25:  rom_r = 6'sb110000;
            8'd26:  rom_r = 6'sb110000;
            8'd27:  rom_r = 6'sb110001;
            8'd28:  rom_r = 6'sb110011;
            8'd29:  rom_r = 6'sb110101;
            8'd30:  rom_r = 6'sb110111;
            8'd31:  rom_r = 6'sb111000;
            8'd32:  rom_r = 6'sb111010;
            8'd33:  rom_r = 6'sb111011;
            8'd34:  rom_r = 6'sb111100;
            8'd35:  rom_r = 6'sb111101;
            8'd36:  rom_r = 6'sb111110;
            8'd37:  rom_r = 6'sb111111;
            8'd38:  rom_r = 6'sb000000;
            8'd39:  rom_r = 6'sb111111;
            8'd40:  rom_r = 6'sb111110;
            8'd41:  rom_r = 6'sb111101;
            8'd42:  rom_r = 6'sb111100;
            8'd43:  rom_r = 6'sb111011;
            8'd44:  rom_r = 6'sb111010;
            8'd45:  rom_r = 6'sb111000;
            8'd46:  rom_r = 6'sb110111;
            8'd47:  rom_r = 6'sb110101;
            8'd48:  rom_r = 6'sb110011;
            8'd49:  rom_r = 6'sb110001;
            8'd50:  rom_r = 6'sb110000;
            8'd51:  rom_r = 6'sb110000;
            8'd52:  rom_r = 6'sb110011;
            8'd53:  rom_r = 6'sb111000;
            8'd54:  rom_r = 6'sb111111;
            8'd55:  rom_r = 6'sb000111;
            8'd56:  rom_r = 6'sb001101;
            8'd57:  rom_r = 6'sb010000;
            8'd58:  rom_r = 6'sb001101;
            8'd59:  rom_r = 6'sb000100;
            8'd60:  rom_r = 6'sb111001;
            8'd61:  rom_r = 6'sb110001;
            8'd62:  rom_r = 6'sb110010;
            8'd63:  rom_r = 6'sb111101;
            8'd64:  rom_r = 6'sb001011;
            8'd65:  rom_r = 6'sb010000;
            8'd66:  rom_r = 6'sb000111;
            8'd67:  rom_r = 6'sb110111;
            8'd68:  rom_r = 6'sb110000;
            8'd69:  rom_r = 6'sb111011;
            8'd70:  rom_r = 6'sb001011;
            8'd71:  rom_r = 6'sb001010;
            8'd72:  rom_r = 6'sb111110;
            8'd73:  rom_r = 6'sb111011;
            8'd74:  rom_r = 6'sb111111;
            8'd75:  rom_r = 6'sb000001;
            8'd76:  rom_r = 6'sb000000;
            8'd77:  rom_r = 6'sb000001;
            8'd78:  rom_r = 6'sb111111;
            8'd79:  rom_r = 6'sb111011;
            8'd80:  rom_r = 6'sb111110;
            8'd81:  rom_r = 6'sb001010;
            8'd82:  rom_r = 6'sb001011;
            8'd83:  rom_r = 6'sb111011;
            8'd84:  rom_r = 6'sb110000;
            8'd85:  rom_r = 6'sb110111;
            8'd86:  rom_r = 6'sb000111;
            8'd87:  rom_r = 6'sb010000;
            8'd88:  rom_r = 6'sb001011;
            8'd89:  rom_r = 6'sb111101;
            8'd90:  rom_r = 6'sb110010;
            8'd91:  rom_r = 6'sb110001;
            8'd92:  rom_r = 6'sb111001;
            8'd93:  rom_r = 6'sb000100;
            8'd94:  rom_r = 6'sb001101;
            8'd95:  rom_r = 6'sb010000;
            8'd96:  rom_r = 6'sb001101;
            8'd97:  rom_r = 6'sb000111;
            8'd98:  rom_r = 6'sb111111;
            8'd99:  rom_r = 6'sb111000;
            8'd100: rom_r = 6'sb110011;
            8'd101: rom_r = 6'sb110000;
            8'd102: rom_r = 6'sb110000;
            8'd103: rom_r = 6'sb110001;
            8'd104: rom_r = 6'sb110011;
            8'd105: rom_r = 6'sb110101;
            8'd106: rom_r = 6'sb110111;
            8'd107: rom_r = 6'sb111000;
            8'd108: rom_r = 6'sb111010;
            8'd109: rom_r = 6'sb111011;
            8'd110: rom_r = 6'sb111100;
            8'd111: rom_r = 6'sb111101;
            8'd112: rom_r = 6'sb111110;
            8'd113: rom_r = 6'sb111111;
            8'd114: rom_r = 6'sb000000;
            8'd115: rom_r = 6'sb111111;
            8'd116: rom_r = 6'sb111110;
            8'd117: rom_r = 6'sb111101;
            8'd118: rom_r = 6'sb111100;
            8'd119: rom_r = 6'sb111011;
            8'd120: rom_r = 6'sb111010;
            8'd121: rom_r = 6'sb111000;
            8'd122: rom_r = 6'sb110111;
            8'd123: rom_r = 6'sb110101;
            8'd124: rom_r = 6'sb110011;
            8'd125: rom_r = 6'sb110001;
            8'd126: rom_r = 6'sb110000;
            8'd127: rom_r = 6'sb110000;
            8'd128: rom_r = 6'sb110011;
            8'd129: rom_r = 6'sb111000;
            8'd130: rom_r = 6'sb111111;
            8'd131: rom_r = 6'sb000111;
            8'd132: rom_r = 6'sb001101;
            8'd133: rom_r = 6'sb010000;
            8'd134: rom_r = 6'sb001101;
            8'd135: rom_r = 6'sb000100;
            8'd136: rom_r = 6'sb111001;
            8'd137: rom_r = 6'sb110001;
            8'd138: rom_r = 6'sb110010;
            8'd139: rom_r = 6'sb111101;
            8'd140: rom_r = 6'sb001011;
            8'd141: rom_r = 6'sb010000;
            8'd142: rom_r = 6'sb000111;
            8'd143: rom_r = 6'sb110111;
            8'd144: rom_r = 6'sb110000;
            8'd145: rom_r = 6'sb111011;
            8'd146: rom_r = 6'sb001011;
            8'd147: rom_r = 6'sb001010;
            8'd148: rom_r = 6'sb111110;
            8'd149: rom_r = 6'sb111011;
            8'd150: rom_r = 6'sb111111;
            8'd151: rom_r = 6'sb000001;
            default: rom_r = 6'sb000000;
        endcase
    end

    always @(*) begin
        case (addr_ptr)
            8'd0:   rom_i = 6'sb000000;
            8'd1:   rom_i = 6'sb000000;
            8'd2:   rom_i = 6'sb111110;
            8'd3:   rom_i = 6'sb000000;
            8'd4:   rom_i = 6'sb001001;
            8'd5:   rom_i = 6'sb000110;
            8'd6:   rom_i = 6'sb110110;
            8'd7:   rom_i = 6'sb110001;
            8'd8:   rom_i = 6'sb111110;
            8'd9:   rom_i = 6'sb001101;
            8'd10:  rom_i = 6'sb001110;
            8'd11:  rom_i = 6'sb000010;
            8'd12:  rom_i = 6'sb110100;
            8'd13:  rom_i = 6'sb110000;
            8'd14:  rom_i = 6'sb111000;
            8'd15:  rom_i = 6'sb000101;
            8'd16:  rom_i = 6'sb001110;
            8'd17:  rom_i = 6'sb010000;
            8'd18:  rom_i = 6'sb001010;
            8'd19:  rom_i = 6'sb000000;
            8'd20:  rom_i = 6'sb110111;
            8'd21:  rom_i = 6'sb110001;
            8'd22:  rom_i = 6'sb110000;
            8'd23:  rom_i = 6'sb110010;
            8'd24:  rom_i = 6'sb110111;
            8'd25:  rom_i = 6'sb111100;
            8'd26:  rom_i = 6'sb000001;
            8'd27:  rom_i = 6'sb000110;
            8'd28:  rom_i = 6'sb001001;
            8'd29:  rom_i = 6'sb001011;
            8'd30:  rom_i = 6'sb001101;
            8'd31:  rom_i = 6'sb001110;
            8'd32:  rom_i = 6'sb001101;
            8'd33:  rom_i = 6'sb001011;
            8'd34:  rom_i = 6'sb001000;
            8'd35:  rom_i = 6'sb000101;
            8'd36:  rom_i = 6'sb000010;
            8'd37:  rom_i = 6'sb000000;
            8'd38:  rom_i = 6'sb000000;
            8'd39:  rom_i = 6'sb000000;
            8'd40:  rom_i = 6'sb000010;
            8'd41:  rom_i = 6'sb000101;
            8'd42:  rom_i = 6'sb001000;
            8'd43:  rom_i = 6'sb001011;
            8'd44:  rom_i = 6'sb001101;
            8'd45:  rom_i = 6'sb001110;
            8'd46:  rom_i = 6'sb001101;
            8'd47:  rom_i = 6'sb001011;
            8'd48:  rom_i = 6'sb001001;
            8'd49:  rom_i = 6'sb000110;
            8'd50:  rom_i = 6'sb000001;
            8'd51:  rom_i = 6'sb111100;
            8'd52:  rom_i = 6'sb110111;
            8'd53:  rom_i = 6'sb110010;
            8'd54:  rom_i = 6'sb110000;
            8'd55:  rom_i = 6'sb110001;
            8'd56:  rom_i = 6'sb110111;
            8'd57:  rom_i = 6'sb000000;
            8'd58:  rom_i = 6'sb001010;
            8'd59:  rom_i = 6'sb010000;
            8'd60:  rom_i = 6'sb001110;
            8'd61:  rom_i = 6'sb000101;
            8'd62:  rom_i = 6'sb111000;
            8'd63:  rom_i = 6'sb110000;
            8'd64:  rom_i = 6'sb110100;
            8'd65:  rom_i = 6'sb000010;
            8'd66:  rom_i = 6'sb001110;
            8'd67:  rom_i = 6'sb001101;
            8'd68:  rom_i = 6'sb111110;
            8'd69:  rom_i = 6'sb110001;
            8'd70:  rom_i = 6'sb110110;
            8'd71:  rom_i = 6'sb000110;
            8'd72:  rom_i = 6'sb001001;
            8'd73:  rom_i = 6'sb000000;
            8'd74:  rom_i = 6'sb111110;
            8'd75:  rom_i = 6'sb000000;
            8'd76:  rom_i = 6'sb000000;
            8'd77:  rom_i = 6'sb000000;
            8'd78:  rom_i = 6'sb000010;
            8'd79:  rom_i = 6'sb000000;
            8'd80:  rom_i = 6'sb110111;
            8'd81:  rom_i = 6'sb111010;
            8'd82:  rom_i = 6'sb001010;
            8'd83:  rom_i = 6'sb001111;
            8'd84:  rom_i = 6'sb000010;
            8'd85:  rom_i = 6'sb110011;
            8'd86:  rom_i = 6'sb110010;
            8'd87:  rom_i = 6'sb111110;
            8'd88:  rom_i = 6'sb001100;
            8'd89:  rom_i = 6'sb010000;
            8'd90:  rom_i = 6'sb001000;
            8'd91:  rom_i = 6'sb111011;
            8'd92:  rom_i = 6'sb110010;
            8'd93:  rom_i = 6'sb110000;
            8'd94:  rom_i = 6'sb110110;
            8'd95:  rom_i = 6'sb000000;
            8'd96:  rom_i = 6'sb001001;
            8'd97:  rom_i = 6'sb001111;
            8'd98:  rom_i = 6'sb010000;
            8'd99:  rom_i = 6'sb001110;
            8'd100: rom_i = 6'sb001001;
            8'd101: rom_i = 6'sb000100;
            8'd102: rom_i = 6'sb111111;
            8'd103: rom_i = 6'sb111010;
            8'd104: rom_i = 6'sb110111;
            8'd105: rom_i = 6'sb110101;
            8'd106: rom_i = 6'sb110011;
            8'd107: rom_i = 6'sb110010;
            8'd108: rom_i = 6'sb110011;
            8'd109: rom_i = 6'sb110101;
            8'd110: rom_i = 6'sb111000;
            8'd111: rom_i = 6'sb111011;
            8'd112: rom_i = 6'sb111110;
            8'd113: rom_i = 6'sb000000;
            8'd114: rom_i = 6'sb000000;
            8'd115: rom_i = 6'sb000000;
            8'd116: rom_i = 6'sb111110;
            8'd117: rom_i = 6'sb111011;
            8'd118: rom_i = 6'sb111000;
            8'd119: rom_i = 6'sb110101;
            8'd120: rom_i = 6'sb110011;
            8'd121: rom_i = 6'sb110010;
            8'd122: rom_i = 6'sb110011;
            8'd123: rom_i = 6'sb110101;
            8'd124: rom_i = 6'sb110111;
            8'd125: rom_i = 6'sb111010;
            8'd126: rom_i = 6'sb111111;
            8'd127: rom_i = 6'sb000100;
            8'd128: rom_i = 6'sb001001;
            8'd129: rom_i = 6'sb001110;
            8'd130: rom_i = 6'sb010000;
            8'd131: rom_i = 6'sb001111;
            8'd132: rom_i = 6'sb001001;
            8'd133: rom_i = 6'sb000000;
            8'd134: rom_i = 6'sb110110;
            8'd135: rom_i = 6'sb110000;
            8'd136: rom_i = 6'sb110010;
            8'd137: rom_i = 6'sb111011;
            8'd138: rom_i = 6'sb001000;
            8'd139: rom_i = 6'sb010000;
            8'd140: rom_i = 6'sb001100;
            8'd141: rom_i = 6'sb111110;
            8'd142: rom_i = 6'sb110010;
            8'd143: rom_i = 6'sb110011;
            8'd144: rom_i = 6'sb000010;
            8'd145: rom_i = 6'sb001111;
            8'd146: rom_i = 6'sb001010;
            8'd147: rom_i = 6'sb111010;
            8'd148: rom_i = 6'sb110111;
            8'd149: rom_i = 6'sb000000;
            8'd150: rom_i = 6'sb000010;
            8'd151: rom_i = 6'sb000000;
            default: rom_i = 6'sb000000;
        endcase
    end

    // ----------------------------------------------------------------
    // Control registers
    // ----------------------------------------------------------------
    reg [6:0] samble_cnt;
    reg       which_gab;    // 0: Even Gap (10 cycles), 1: Odd Gap (70 cycles)
    reg       first_fetch;
    reg       boundary_d;
    wire      stop_now;

    assign stop_now = running && !en && (addr_ptr > 8'd151) &&
                      ( (!which_gab && samble_cnt == 7'd9)  ||
                        ( which_gab && samble_cnt == 7'd69) );
    assign next_item = running && (first_fetch || boundary_d);

    // ----------------------------------------------------------------
    // Sequential logic — identical behaviour, const arrays replaced by
    // the combinational ROM outputs rom_r / rom_i above
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            running     <= 1'b0;
            addr_ptr    <= 8'd0;
            samble_cnt  <= 7'd0;
            which_gab   <= 1'b0;
            first_fetch <= 1'b1;
            boundary_d  <= 1'b0;
            csk_out_r   <= {WL{1'b0}};
            csk_out_i   <= {WL{1'b0}};
        end
        else begin
            if (!running && en)
                running <= 1'b1;
            else if (stop_now)
                running <= 1'b0;

            if (!running || stop_now) begin
                addr_ptr    <= 8'd0;
                samble_cnt  <= 7'd0;
                which_gab   <= 1'b0;
                first_fetch <= 1'b1;
                boundary_d  <= 1'b0;
                csk_out_r   <= {WL{1'b0}};
                csk_out_i   <= {WL{1'b0}};
            end
            else begin
                if (first_fetch)
                    first_fetch <= 1'b0;

                boundary_d <= (addr_ptr <= 8'd151) && (samble_cnt == 7'd37);

                if (addr_ptr <= 8'd151) begin
                    // Read from combinational ROM
                    csk_out_r <= rom_r;
                    csk_out_i <= rom_i;

                    addr_ptr <= addr_ptr + 1'b1;

                    if (samble_cnt < 7'd37)
                        samble_cnt <= samble_cnt + 1'b1;
                    else
                        samble_cnt <= 7'd0;
                end
                else begin
                    // Gap Period: zero outputs
                    csk_out_r <= {WL{1'b0}};
                    csk_out_i <= {WL{1'b0}};

                    if (!which_gab) begin
                        // Even Gap (10 cycles)
                        if (samble_cnt < 7'd9)
                            samble_cnt <= samble_cnt + 1'b1;
                        else begin
                            samble_cnt <= 7'd0;
                            addr_ptr   <= 8'd0;
                            which_gab  <= 1'b1;
                        end
                    end
                    else begin
                        // Odd Gap (70 cycles)
                        if (samble_cnt < 7'd69)
                            samble_cnt <= samble_cnt + 1'b1;
                        else begin
                            samble_cnt <= 7'd0;
                            addr_ptr   <= 8'd0;
                            which_gab  <= 1'b0;
                        end
                    end
                end
            end
        end
    end

endmodule