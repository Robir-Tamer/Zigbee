module CSK_GEN #(
    parameter WL = 6
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   en,
    output wire                   next_item,
    output reg  signed [WL-1:0]   csk_out_r,
    output reg  signed [WL-1:0]   csk_out_i,
    output reg                    running
);

    reg signed [WL-1:0] chrip_sample_r [0:151];
    reg signed [WL-1:0] chrip_sample_i [0:151];

    reg [7:0] addr_ptr;
    reg [6:0] samble_cnt;
    reg       which_gab;    // 0: Even Gap (10 cycles), 1: Odd Gap (70 cycles)
    reg       first_fetch;
    reg       boundary_d;
    wire      stop_now;


    assign stop_now = running && !en && (addr_ptr == 8'd0) && (samble_cnt == 7'd0);
    assign next_item = running && (first_fetch || boundary_d);

    always @(posedge clk) begin
        if(!rst_n) begin
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
                // Clear startup flag after first clock cycle
                if (first_fetch) begin
                    first_fetch <= 1'b0;
                end

                // Register the boundary condition -- this is what delays
                // next_item by exactly the same 1 cycle the ROM read is
                // delayed, keeping the two aligned.
                boundary_d <= (addr_ptr <= 8'd151) && (samble_cnt == 7'd37);

                if (addr_ptr <= 8'd151) begin
                    csk_out_r <= chrip_sample_r[addr_ptr];
                    csk_out_i <= chrip_sample_i[addr_ptr];
                
                    addr_ptr <= addr_ptr + 1'b1;

                    if (samble_cnt < 7'd37) begin
                        samble_cnt <= samble_cnt + 1'b1;
                    end 
                    else begin
                        samble_cnt <= 7'd0;
                    end
                end 
                else begin
                    // Gap Period: Zero out outputs
                    csk_out_r <= {WL{1'b0}};
                    csk_out_i <= {WL{1'b0}};

                    if (!which_gab) begin
                        // Even Gap (10 cycles)
                        if (samble_cnt < 7'd9) begin
                            samble_cnt <= samble_cnt + 1'b1;
                        end 
                        else begin
                            samble_cnt <= 7'd0;
                            addr_ptr   <= 8'd0;
                            which_gab  <= 1'b1;
                        end
                    end 
                    else begin
                        // Odd Gap (70 cycles)
                        if (samble_cnt < 7'd69) begin
                            samble_cnt <= samble_cnt + 1'b1;
                        end 
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

    //Filling Real and Imag ROMS Values 
//Manual Filling to avoid probelms with File reading during ASIC FLow with Synopsys tools
// 1 - Filling the real part ROM
initial begin
    chrip_sample_r[0] = 6'sb000000; // +0.0000
    chrip_sample_r[1] = 6'sb000001; // +0.0625
    chrip_sample_r[2] = 6'sb111111; // -0.0625
    chrip_sample_r[3] = 6'sb111011; // -0.3125
    chrip_sample_r[4] = 6'sb111110; // -0.1250
    chrip_sample_r[5] = 6'sb001010; // +0.6250
    chrip_sample_r[6] = 6'sb001011; // +0.6875
    chrip_sample_r[7] = 6'sb111011; // -0.3125
    chrip_sample_r[8] = 6'sb110000; // -1.0000
    chrip_sample_r[9] = 6'sb110111; // -0.5625
    chrip_sample_r[10] = 6'sb000111; // +0.4375
    chrip_sample_r[11] = 6'sb010000; // +1.0000
    chrip_sample_r[12] = 6'sb001011; // +0.6875
    chrip_sample_r[13] = 6'sb111101; // -0.1875
    chrip_sample_r[14] = 6'sb110010; // -0.8750
    chrip_sample_r[15] = 6'sb110001; // -0.9375
    chrip_sample_r[16] = 6'sb111001; // -0.4375
    chrip_sample_r[17] = 6'sb000100; // +0.2500
    chrip_sample_r[18] = 6'sb001101; // +0.8125
    chrip_sample_r[19] = 6'sb010000; // +1.0000
    chrip_sample_r[20] = 6'sb001101; // +0.8125
    chrip_sample_r[21] = 6'sb000111; // +0.4375
    chrip_sample_r[22] = 6'sb111111; // -0.0625
    chrip_sample_r[23] = 6'sb111000; // -0.5000
    chrip_sample_r[24] = 6'sb110011; // -0.8125
    chrip_sample_r[25] = 6'sb110000; // -1.0000
    chrip_sample_r[26] = 6'sb110000; // -1.0000
    chrip_sample_r[27] = 6'sb110001; // -0.9375
    chrip_sample_r[28] = 6'sb110011; // -0.8125
    chrip_sample_r[29] = 6'sb110101; // -0.6875
    chrip_sample_r[30] = 6'sb110111; // -0.5625
    chrip_sample_r[31] = 6'sb111000; // -0.5000
    chrip_sample_r[32] = 6'sb111010; // -0.3750
    chrip_sample_r[33] = 6'sb111011; // -0.3125
    chrip_sample_r[34] = 6'sb111100; // -0.2500
    chrip_sample_r[35] = 6'sb111101; // -0.1875
    chrip_sample_r[36] = 6'sb111110; // -0.1250
    chrip_sample_r[37] = 6'sb111111; // -0.0625
    chrip_sample_r[38] = 6'sb000000; // +0.0000
    chrip_sample_r[39] = 6'sb111111; // -0.0625
    chrip_sample_r[40] = 6'sb111110; // -0.1250
    chrip_sample_r[41] = 6'sb111101; // -0.1875
    chrip_sample_r[42] = 6'sb111100; // -0.2500
    chrip_sample_r[43] = 6'sb111011; // -0.3125
    chrip_sample_r[44] = 6'sb111010; // -0.3750
    chrip_sample_r[45] = 6'sb111000; // -0.5000
    chrip_sample_r[46] = 6'sb110111; // -0.5625
    chrip_sample_r[47] = 6'sb110101; // -0.6875
    chrip_sample_r[48] = 6'sb110011; // -0.8125
    chrip_sample_r[49] = 6'sb110001; // -0.9375
    chrip_sample_r[50] = 6'sb110000; // -1.0000
    chrip_sample_r[51] = 6'sb110000; // -1.0000
    chrip_sample_r[52] = 6'sb110011; // -0.8125
    chrip_sample_r[53] = 6'sb111000; // -0.5000
    chrip_sample_r[54] = 6'sb111111; // -0.0625
    chrip_sample_r[55] = 6'sb000111; // +0.4375
    chrip_sample_r[56] = 6'sb001101; // +0.8125
    chrip_sample_r[57] = 6'sb010000; // +1.0000
    chrip_sample_r[58] = 6'sb001101; // +0.8125
    chrip_sample_r[59] = 6'sb000100; // +0.2500
    chrip_sample_r[60] = 6'sb111001; // -0.4375
    chrip_sample_r[61] = 6'sb110001; // -0.9375
    chrip_sample_r[62] = 6'sb110010; // -0.8750
    chrip_sample_r[63] = 6'sb111101; // -0.1875
    chrip_sample_r[64] = 6'sb001011; // +0.6875
    chrip_sample_r[65] = 6'sb010000; // +1.0000
    chrip_sample_r[66] = 6'sb000111; // +0.4375
    chrip_sample_r[67] = 6'sb110111; // -0.5625
    chrip_sample_r[68] = 6'sb110000; // -1.0000
    chrip_sample_r[69] = 6'sb111011; // -0.3125
    chrip_sample_r[70] = 6'sb001011; // +0.6875
    chrip_sample_r[71] = 6'sb001010; // +0.6250
    chrip_sample_r[72] = 6'sb111110; // -0.1250
    chrip_sample_r[73] = 6'sb111011; // -0.3125
    chrip_sample_r[74] = 6'sb111111; // -0.0625
    chrip_sample_r[75] = 6'sb000001; // +0.0625
    chrip_sample_r[76] = 6'sb000000; // +0.0000
    chrip_sample_r[77] = 6'sb000001; // +0.0625
    chrip_sample_r[78] = 6'sb111111; // -0.0625
    chrip_sample_r[79] = 6'sb111011; // -0.3125
    chrip_sample_r[80] = 6'sb111110; // -0.1250
    chrip_sample_r[81] = 6'sb001010; // +0.6250
    chrip_sample_r[82] = 6'sb001011; // +0.6875
    chrip_sample_r[83] = 6'sb111011; // -0.3125
    chrip_sample_r[84] = 6'sb110000; // -1.0000
    chrip_sample_r[85] = 6'sb110111; // -0.5625
    chrip_sample_r[86] = 6'sb000111; // +0.4375
    chrip_sample_r[87] = 6'sb010000; // +1.0000
    chrip_sample_r[88] = 6'sb001011; // +0.6875
    chrip_sample_r[89] = 6'sb111101; // -0.1875
    chrip_sample_r[90] = 6'sb110010; // -0.8750
    chrip_sample_r[91] = 6'sb110001; // -0.9375
    chrip_sample_r[92] = 6'sb111001; // -0.4375
    chrip_sample_r[93] = 6'sb000100; // +0.2500
    chrip_sample_r[94] = 6'sb001101; // +0.8125
    chrip_sample_r[95] = 6'sb010000; // +1.0000
    chrip_sample_r[96] = 6'sb001101; // +0.8125
    chrip_sample_r[97] = 6'sb000111; // +0.4375
    chrip_sample_r[98] = 6'sb111111; // -0.0625
    chrip_sample_r[99] = 6'sb111000; // -0.5000
    chrip_sample_r[100] = 6'sb110011; // -0.8125
    chrip_sample_r[101] = 6'sb110000; // -1.0000
    chrip_sample_r[102] = 6'sb110000; // -1.0000
    chrip_sample_r[103] = 6'sb110001; // -0.9375
    chrip_sample_r[104] = 6'sb110011; // -0.8125
    chrip_sample_r[105] = 6'sb110101; // -0.6875
    chrip_sample_r[106] = 6'sb110111; // -0.5625
    chrip_sample_r[107] = 6'sb111000; // -0.5000
    chrip_sample_r[108] = 6'sb111010; // -0.3750
    chrip_sample_r[109] = 6'sb111011; // -0.3125
    chrip_sample_r[110] = 6'sb111100; // -0.2500
    chrip_sample_r[111] = 6'sb111101; // -0.1875
    chrip_sample_r[112] = 6'sb111110; // -0.1250
    chrip_sample_r[113] = 6'sb111111; // -0.0625
    chrip_sample_r[114] = 6'sb000000; // +0.0000
    chrip_sample_r[115] = 6'sb111111; // -0.0625
    chrip_sample_r[116] = 6'sb111110; // -0.1250
    chrip_sample_r[117] = 6'sb111101; // -0.1875
    chrip_sample_r[118] = 6'sb111100; // -0.2500
    chrip_sample_r[119] = 6'sb111011; // -0.3125
    chrip_sample_r[120] = 6'sb111010; // -0.3750
    chrip_sample_r[121] = 6'sb111000; // -0.5000
    chrip_sample_r[122] = 6'sb110111; // -0.5625
    chrip_sample_r[123] = 6'sb110101; // -0.6875
    chrip_sample_r[124] = 6'sb110011; // -0.8125
    chrip_sample_r[125] = 6'sb110001; // -0.9375
    chrip_sample_r[126] = 6'sb110000; // -1.0000
    chrip_sample_r[127] = 6'sb110000; // -1.0000
    chrip_sample_r[128] = 6'sb110011; // -0.8125
    chrip_sample_r[129] = 6'sb111000; // -0.5000
    chrip_sample_r[130] = 6'sb111111; // -0.0625
    chrip_sample_r[131] = 6'sb000111; // +0.4375
    chrip_sample_r[132] = 6'sb001101; // +0.8125
    chrip_sample_r[133] = 6'sb010000; // +1.0000
    chrip_sample_r[134] = 6'sb001101; // +0.8125
    chrip_sample_r[135] = 6'sb000100; // +0.2500
    chrip_sample_r[136] = 6'sb111001; // -0.4375
    chrip_sample_r[137] = 6'sb110001; // -0.9375
    chrip_sample_r[138] = 6'sb110010; // -0.8750
    chrip_sample_r[139] = 6'sb111101; // -0.1875
    chrip_sample_r[140] = 6'sb001011; // +0.6875
    chrip_sample_r[141] = 6'sb010000; // +1.0000
    chrip_sample_r[142] = 6'sb000111; // +0.4375
    chrip_sample_r[143] = 6'sb110111; // -0.5625
    chrip_sample_r[144] = 6'sb110000; // -1.0000
    chrip_sample_r[145] = 6'sb111011; // -0.3125
    chrip_sample_r[146] = 6'sb001011; // +0.6875
    chrip_sample_r[147] = 6'sb001010; // +0.6250
    chrip_sample_r[148] = 6'sb111110; // -0.1250
    chrip_sample_r[149] = 6'sb111011; // -0.3125
    chrip_sample_r[150] = 6'sb111111; // -0.0625
    chrip_sample_r[151] = 6'sb000001; // +0.0625
end
// 2 - Filling the imag part ROM
initial begin
    chrip_sample_i[0] = 6'sb000000; // +0.0000
    chrip_sample_i[1] = 6'sb000000; // +0.0000
    chrip_sample_i[2] = 6'sb111110; // -0.1250
    chrip_sample_i[3] = 6'sb000000; // +0.0000
    chrip_sample_i[4] = 6'sb001001; // +0.5625
    chrip_sample_i[5] = 6'sb000110; // +0.3750
    chrip_sample_i[6] = 6'sb110110; // -0.6250
    chrip_sample_i[7] = 6'sb110001; // -0.9375
    chrip_sample_i[8] = 6'sb111110; // -0.1250
    chrip_sample_i[9] = 6'sb001101; // +0.8125
    chrip_sample_i[10] = 6'sb001110; // +0.8750
    chrip_sample_i[11] = 6'sb000010; // +0.1250
    chrip_sample_i[12] = 6'sb110100; // -0.7500
    chrip_sample_i[13] = 6'sb110000; // -1.0000
    chrip_sample_i[14] = 6'sb111000; // -0.5000
    chrip_sample_i[15] = 6'sb000101; // +0.3125
    chrip_sample_i[16] = 6'sb001110; // +0.8750
    chrip_sample_i[17] = 6'sb010000; // +1.0000
    chrip_sample_i[18] = 6'sb001010; // +0.6250
    chrip_sample_i[19] = 6'sb000000; // +0.0000
    chrip_sample_i[20] = 6'sb110111; // -0.5625
    chrip_sample_i[21] = 6'sb110001; // -0.9375
    chrip_sample_i[22] = 6'sb110000; // -1.0000
    chrip_sample_i[23] = 6'sb110010; // -0.8750
    chrip_sample_i[24] = 6'sb110111; // -0.5625
    chrip_sample_i[25] = 6'sb111100; // -0.2500
    chrip_sample_i[26] = 6'sb000001; // +0.0625
    chrip_sample_i[27] = 6'sb000110; // +0.3750
    chrip_sample_i[28] = 6'sb001001; // +0.5625
    chrip_sample_i[29] = 6'sb001011; // +0.6875
    chrip_sample_i[30] = 6'sb001101; // +0.8125
    chrip_sample_i[31] = 6'sb001110; // +0.8750
    chrip_sample_i[32] = 6'sb001101; // +0.8125
    chrip_sample_i[33] = 6'sb001011; // +0.6875
    chrip_sample_i[34] = 6'sb001000; // +0.5000
    chrip_sample_i[35] = 6'sb000101; // +0.3125
    chrip_sample_i[36] = 6'sb000010; // +0.1250
    chrip_sample_i[37] = 6'sb000000; // +0.0000
    chrip_sample_i[38] = 6'sb000000; // +0.0000
    chrip_sample_i[39] = 6'sb000000; // +0.0000
    chrip_sample_i[40] = 6'sb000010; // +0.1250
    chrip_sample_i[41] = 6'sb000101; // +0.3125
    chrip_sample_i[42] = 6'sb001000; // +0.5000
    chrip_sample_i[43] = 6'sb001011; // +0.6875
    chrip_sample_i[44] = 6'sb001101; // +0.8125
    chrip_sample_i[45] = 6'sb001110; // +0.8750
    chrip_sample_i[46] = 6'sb001101; // +0.8125
    chrip_sample_i[47] = 6'sb001011; // +0.6875
    chrip_sample_i[48] = 6'sb001001; // +0.5625
    chrip_sample_i[49] = 6'sb000110; // +0.3750
    chrip_sample_i[50] = 6'sb000001; // +0.0625
    chrip_sample_i[51] = 6'sb111100; // -0.2500
    chrip_sample_i[52] = 6'sb110111; // -0.5625
    chrip_sample_i[53] = 6'sb110010; // -0.8750
    chrip_sample_i[54] = 6'sb110000; // -1.0000
    chrip_sample_i[55] = 6'sb110001; // -0.9375
    chrip_sample_i[56] = 6'sb110111; // -0.5625
    chrip_sample_i[57] = 6'sb000000; // +0.0000
    chrip_sample_i[58] = 6'sb001010; // +0.6250
    chrip_sample_i[59] = 6'sb010000; // +1.0000
    chrip_sample_i[60] = 6'sb001110; // +0.8750
    chrip_sample_i[61] = 6'sb000101; // +0.3125
    chrip_sample_i[62] = 6'sb111000; // -0.5000
    chrip_sample_i[63] = 6'sb110000; // -1.0000
    chrip_sample_i[64] = 6'sb110100; // -0.7500
    chrip_sample_i[65] = 6'sb000010; // +0.1250
    chrip_sample_i[66] = 6'sb001110; // +0.8750
    chrip_sample_i[67] = 6'sb001101; // +0.8125
    chrip_sample_i[68] = 6'sb111110; // -0.1250
    chrip_sample_i[69] = 6'sb110001; // -0.9375
    chrip_sample_i[70] = 6'sb110110; // -0.6250
    chrip_sample_i[71] = 6'sb000110; // +0.3750
    chrip_sample_i[72] = 6'sb001001; // +0.5625
    chrip_sample_i[73] = 6'sb000000; // +0.0000
    chrip_sample_i[74] = 6'sb111110; // -0.1250
    chrip_sample_i[75] = 6'sb000000; // +0.0000
    chrip_sample_i[76] = 6'sb000000; // +0.0000
    chrip_sample_i[77] = 6'sb000000; // +0.0000
    chrip_sample_i[78] = 6'sb000010; // +0.1250
    chrip_sample_i[79] = 6'sb000000; // +0.0000
    chrip_sample_i[80] = 6'sb110111; // -0.5625
    chrip_sample_i[81] = 6'sb111010; // -0.3750
    chrip_sample_i[82] = 6'sb001010; // +0.6250
    chrip_sample_i[83] = 6'sb001111; // +0.9375
    chrip_sample_i[84] = 6'sb000010; // +0.1250
    chrip_sample_i[85] = 6'sb110011; // -0.8125
    chrip_sample_i[86] = 6'sb110010; // -0.8750
    chrip_sample_i[87] = 6'sb111110; // -0.1250
    chrip_sample_i[88] = 6'sb001100; // +0.7500
    chrip_sample_i[89] = 6'sb010000; // +1.0000
    chrip_sample_i[90] = 6'sb001000; // +0.5000
    chrip_sample_i[91] = 6'sb111011; // -0.3125
    chrip_sample_i[92] = 6'sb110010; // -0.8750
    chrip_sample_i[93] = 6'sb110000; // -1.0000
    chrip_sample_i[94] = 6'sb110110; // -0.6250
    chrip_sample_i[95] = 6'sb000000; // +0.0000
    chrip_sample_i[96] = 6'sb001001; // +0.5625
    chrip_sample_i[97] = 6'sb001111; // +0.9375
    chrip_sample_i[98] = 6'sb010000; // +1.0000
    chrip_sample_i[99] = 6'sb001110; // +0.8750
    chrip_sample_i[100] = 6'sb001001; // +0.5625
    chrip_sample_i[101] = 6'sb000100; // +0.2500
    chrip_sample_i[102] = 6'sb111111; // -0.0625
    chrip_sample_i[103] = 6'sb111010; // -0.3750
    chrip_sample_i[104] = 6'sb110111; // -0.5625
    chrip_sample_i[105] = 6'sb110101; // -0.6875
    chrip_sample_i[106] = 6'sb110011; // -0.8125
    chrip_sample_i[107] = 6'sb110010; // -0.8750
    chrip_sample_i[108] = 6'sb110011; // -0.8125
    chrip_sample_i[109] = 6'sb110101; // -0.6875
    chrip_sample_i[110] = 6'sb111000; // -0.5000
    chrip_sample_i[111] = 6'sb111011; // -0.3125
    chrip_sample_i[112] = 6'sb111110; // -0.1250
    chrip_sample_i[113] = 6'sb000000; // +0.0000
    chrip_sample_i[114] = 6'sb000000; // +0.0000
    chrip_sample_i[115] = 6'sb000000; // +0.0000
    chrip_sample_i[116] = 6'sb111110; // -0.1250
    chrip_sample_i[117] = 6'sb111011; // -0.3125
    chrip_sample_i[118] = 6'sb111000; // -0.5000
    chrip_sample_i[119] = 6'sb110101; // -0.6875
    chrip_sample_i[120] = 6'sb110011; // -0.8125
    chrip_sample_i[121] = 6'sb110010; // -0.8750
    chrip_sample_i[122] = 6'sb110011; // -0.8125
    chrip_sample_i[123] = 6'sb110101; // -0.6875
    chrip_sample_i[124] = 6'sb110111; // -0.5625
    chrip_sample_i[125] = 6'sb111010; // -0.3750
    chrip_sample_i[126] = 6'sb111111; // -0.0625
    chrip_sample_i[127] = 6'sb000100; // +0.2500
    chrip_sample_i[128] = 6'sb001001; // +0.5625
    chrip_sample_i[129] = 6'sb001110; // +0.8750
    chrip_sample_i[130] = 6'sb010000; // +1.0000
    chrip_sample_i[131] = 6'sb001111; // +0.9375
    chrip_sample_i[132] = 6'sb001001; // +0.5625
    chrip_sample_i[133] = 6'sb000000; // +0.0000
    chrip_sample_i[134] = 6'sb110110; // -0.6250
    chrip_sample_i[135] = 6'sb110000; // -1.0000
    chrip_sample_i[136] = 6'sb110010; // -0.8750
    chrip_sample_i[137] = 6'sb111011; // -0.3125
    chrip_sample_i[138] = 6'sb001000; // +0.5000
    chrip_sample_i[139] = 6'sb010000; // +1.0000
    chrip_sample_i[140] = 6'sb001100; // +0.7500
    chrip_sample_i[141] = 6'sb111110; // -0.1250
    chrip_sample_i[142] = 6'sb110010; // -0.8750
    chrip_sample_i[143] = 6'sb110011; // -0.8125
    chrip_sample_i[144] = 6'sb000010; // +0.1250
    chrip_sample_i[145] = 6'sb001111; // +0.9375
    chrip_sample_i[146] = 6'sb001010; // +0.6250
    chrip_sample_i[147] = 6'sb111010; // -0.3750
    chrip_sample_i[148] = 6'sb110111; // -0.5625
    chrip_sample_i[149] = 6'sb000000; // +0.0000
    chrip_sample_i[150] = 6'sb000010; // +0.1250
    chrip_sample_i[151] = 6'sb000000; // +0.0000
end

endmodule