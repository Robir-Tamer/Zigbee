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

    // Synthesizable Constant ROM Arrays (Replaces initial blocks)
    const logic signed [WL-1:0] chrip_sample_r [0:151] = '{
        6'sb000000, 6'sb000001, 6'sb111111, 6'sb111011, 6'sb111110, 6'sb001010, 6'sb001011, 6'sb111011,
        6'sb110000, 6'sb110111, 6'sb000111, 6'sb010000, 6'sb001011, 6'sb111101, 6'sb110010, 6'sb110001,
        6'sb111001, 6'sb000100, 6'sb001101, 6'sb010000, 6'sb001101, 6'sb000111, 6'sb111111, 6'sb111000,
        6'sb110011, 6'sb110000, 6'sb110000, 6'sb110001, 6'sb110011, 6'sb110101, 6'sb110111, 6'sb111000,
        6'sb111010, 6'sb111011, 6'sb111100, 6'sb111101, 6'sb111110, 6'sb111111, 6'sb000000, 6'sb111111,
        6'sb111110, 6'sb111101, 6'sb111100, 6'sb111011, 6'sb111010, 6'sb111000, 6'sb110111, 6'sb110101,
        6'sb110011, 6'sb110001, 6'sb110000, 6'sb110000, 6'sb110011, 6'sb111000, 6'sb111111, 6'sb000111,
        6'sb001101, 6'sb010000, 6'sb001101, 6'sb000100, 6'sb111001, 6'sb110001, 6'sb110010, 6'sb111101,
        6'sb001011, 6'sb010000, 6'sb000111, 6'sb110111, 6'sb110000, 6'sb111011, 6'sb001011, 6'sb001010,
        6'sb111110, 6'sb111011, 6'sb111111, 6'sb000001, 6'sb000000, 6'sb000001, 6'sb111111, 6'sb111011,
        6'sb111110, 6'sb001010, 6'sb001011, 6'sb111011, 6'sb110000, 6'sb110111, 6'sb000111, 6'sb010000,
        6'sb001011, 6'sb111101, 6'sb110010, 6'sb110001, 6'sb111001, 6'sb000100, 6'sb001101, 6'sb010000,
        6'sb001101, 6'sb000111, 6'sb111111, 6'sb111000, 6'sb110011, 6'sb110000, 6'sb110000, 6'sb110001,
        6'sb110011, 6'sb110101, 6'sb110111, 6'sb111000, 6'sb111010, 6'sb111011, 6'sb111100, 6'sb111101,
        6'sb111110, 6'sb111111, 6'sb000000, 6'sb111111, 6'sb111110, 6'sb111101, 6'sb111100, 6'sb111011,
        6'sb111010, 6'sb111000, 6'sb110111, 6'sb110101, 6'sb110011, 6'sb110001, 6'sb110000, 6'sb110000,
        6'sb110011, 6'sb111000, 6'sb111111, 6'sb000111, 6'sb001101, 6'sb010000, 6'sb001101, 6'sb000100,
        6'sb111001, 6'sb110001, 6'sb110010, 6'sb111101, 6'sb001011, 6'sb010000, 6'sb000111, 6'sb110111,
        6'sb110000, 6'sb111011, 6'sb001011, 6'sb001010, 6'sb111110, 6'sb111011, 6'sb111111, 6'sb000001
    };

    const logic signed [WL-1:0] chrip_sample_i [0:151] = '{
        6'sb000000, 6'sb000000, 6'sb111110, 6'sb000000, 6'sb001001, 6'sb000110, 6'sb110110, 6'sb110001,
        6'sb111110, 6'sb001101, 6'sb001110, 6'sb000010, 6'sb110100, 6'sb110000, 6'sb111000, 6'sb000101,
        6'sb001110, 6'sb010000, 6'sb001010, 6'sb000000, 6'sb110111, 6'sb110001, 6'sb110000, 6'sb110010,
        6'sb110111, 6'sb111100, 6'sb000001, 6'sb000110, 6'sb001001, 6'sb001011, 6'sb001101, 6'sb001110,
        6'sb001101, 6'sb001011, 6'sb001000, 6'sb000101, 6'sb000010, 6'sb000000, 6'sb000000, 6'sb000000,
        6'sb000010, 6'sb000101, 6'sb001000, 6'sb001011, 6'sb001101, 6'sb001110, 6'sb001101, 6'sb001011,
        6'sb001001, 6'sb000110, 6'sb000001, 6'sb111100, 6'sb110111, 6'sb110010, 6'sb110000, 6'sb110001,
        6'sb110111, 6'sb000000, 6'sb001010, 6'sb010000, 6'sb001110, 6'sb000101, 6'sb111000, 6'sb110000,
        6'sb110100, 6'sb000010, 6'sb001110, 6'sb001101, 6'sb111110, 6'sb110001, 6'sb110110, 6'sb000110,
        6'sb001001, 6'sb000000, 6'sb111110, 6'sb000000, 6'sb000000, 6'sb000000, 6'sb000010, 6'sb000000,
        6'sb110111, 6'sb111010, 6'sb001010, 6'sb001111, 6'sb000010, 6'sb110011, 6'sb110010, 6'sb111110,
        6'sb001100, 6'sb010000, 6'sb001000, 6'sb111011, 6'sb110010, 6'sb110000, 6'sb110110, 6'sb000000,
        6'sb001001, 6'sb001111, 6'sb010000, 6'sb001110, 6'sb001001, 6'sb000100, 6'sb111111, 6'sb111010,
        6'sb110111, 6'sb110101, 6'sb110011, 6'sb110010, 6'sb110011, 6'sb110101, 6'sb111000, 6'sb111011,
        6'sb111110, 6'sb000000, 6'sb000000, 6'sb000000, 6'sb111110, 6'sb111011, 6'sb111000, 6'sb110101,
        6'sb110011, 6'sb110010, 6'sb110011, 6'sb110101, 6'sb110111, 6'sb111010, 6'sb111111, 6'sb000100,
        6'sb001001, 6'sb001110, 6'sb010000, 6'sb001111, 6'sb001001, 6'sb000000, 6'sb110110, 6'sb110000,
        6'sb110010, 6'sb111011, 6'sb001000, 6'sb010000, 6'sb001100, 6'sb111110, 6'sb110010, 6'sb110011,
        6'sb000010, 6'sb001111, 6'sb001010, 6'sb111010, 6'sb110111, 6'sb000000, 6'sb000010, 6'sb000000
    };

    reg [7:0] addr_ptr;
    reg [6:0] samble_cnt;
    reg       which_gab;    // 0: Even Gap (10 cycles), 1: Odd Gap (70 cycles)
    reg       first_fetch;
    reg       boundary_d;
    wire      stop_now;

    assign stop_now = running && !en && (addr_ptr > 8'd151) &&
                      ( (!which_gab && samble_cnt == 7'd9)  ||
                        ( which_gab && samble_cnt == 7'd69) );
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
                if (first_fetch) begin
                    first_fetch <= 1'b0;
                end

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

endmodule