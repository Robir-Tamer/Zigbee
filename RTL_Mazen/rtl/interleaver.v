/*
********************************** Documentation *********************************
*Author : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : interleaver                                                            *
*********************************************************************************
*/

module interleaver #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H"
)(
/************************************ Inputs ***********************************/
    input                                       clk, 
    input                                       rst_n, 
    input                                       mode,
    input                                       i_valid, 
    input      [(rate_mode == "F"? 3 : 31):0]   i_data, 
/*********************************** Outputs ***********************************/
    output reg                                  o_data,
    output reg                                  o_valid
);

generate
    if (rate_mode == "F") begin : gen_interleaver_1mbps
        reg [3:0]  shift_reg;
        reg [1:0]  bit_count;
        reg        busy;

        always @(posedge clk or negedge rst_n) 
        begin
            if (!rst_n) 
            begin
                o_data    <= 1'b0;
                o_valid   <= 1'b0;
                shift_reg <= 4'b0;
                bit_count <= 2'd0;
                busy      <= 1'b0;
            end 
            else 
            begin
                if (!busy) 
                begin
                    o_valid <= 1'b0;
                    if (i_valid) 
                    begin
                        shift_reg <= i_data[3:0];
                        busy      <= 1'b1;
                        bit_count <= 2'd0; 
                        o_data    <= i_data[0];
                        o_valid   <= 1'b1;
                    end
                end 
                else 
                begin
                    if (bit_count < 2'd3) 
                    begin
                        bit_count <= bit_count + 1'b1;
                        o_data    <= shift_reg[bit_count + 1'b1];
                        o_valid   <= 1'b1;
                    end 
                    else 
                    begin
                        busy      <= 1'b0;
                        o_valid   <= 1'b0;
                        if (i_valid) 
                        begin
                            shift_reg <= i_data[3:0];
                            busy      <= 1'b1;
                            bit_count <= 2'd0;
                            o_data    <= i_data[0];
                            o_valid   <= 1'b1;
                        end
                    end
                end
            end
        end
    end
    else if (rate_mode == "S") begin : gen_interleaver_250kbps
        reg        cycle_flag;
        reg [63:0] shift_reg;
        reg [5:0]  bit_count;
        reg        busy;

        always @(posedge clk or negedge rst_n) 
        begin
            if (!rst_n) begin
                cycle_flag  <= 1'b0;
                shift_reg   <= 64'b0;
                bit_count   <= 6'd0;
                busy        <= 1'b0;
                o_data      <= 1'b0;
                o_valid     <= 1'b0;
            end 
            else 
            begin
                if (!busy) 
                begin
                    o_valid <= 1'b0;
                    if (i_valid) 
                    begin
                        if (!cycle_flag) 
                        begin
                            shift_reg[31:0] <= i_data; 
                            cycle_flag      <= 1'b1;
                        end 
                        else 
                        begin
                            cycle_flag <= 1'b0;
                            busy       <= 1'b1;
                            bit_count  <= 6'd0;
                            shift_reg  <= {
                                shift_reg[15:12], // G3
                                i_data[27:24],    // G14
                                shift_reg[7:4],   // G1
                                i_data[19:16],    // G12
                                shift_reg[31:28], // G7
                                i_data[11:8],     // G10
                                shift_reg[23:20], // G5
                                i_data[3:0],      // G8
                                i_data[15:12],    // G11
                                shift_reg[27:24], // G6
                                i_data[7:4],      // G9
                                shift_reg[19:16], // G4
                                i_data[31:28],    // G15
                                shift_reg[11:8],  // G2
                                i_data[23:20],    // G13
                                shift_reg[3:0]    // G0
                            };
                            o_data     <= shift_reg[0];
                            o_valid    <= 1'b1;
                        end
                    end
                end 
                else 
                begin
                    if (bit_count < 6'd63) 
                    begin
                        bit_count <= bit_count + 1'b1;
                        o_data    <= shift_reg[bit_count + 1'b1];
                        o_valid   <= 1'b1;
                    end 
                    else 
                    begin
                        busy      <= 1'b0;
                        o_valid   <= 1'b0;
                        if (i_valid) 
                        begin
                            shift_reg[31:0] <= i_data;
                            cycle_flag      <= 1'b1;
                        end
                    end
                end
            end
        end
    end
    else if (rate_mode == "H") begin : gen_interleaver_hybrid
        reg        cycle_flag;
        reg [63:0] shift_reg;
        reg [5:0]  bit_count;
        reg        busy;

        always @(posedge clk or negedge rst_n) 
        begin
            if (!rst_n) 
            begin
                cycle_flag  <= 1'b0;
                shift_reg   <= 64'b0;
                bit_count   <= 6'd0;
                busy        <= 1'b0;
                o_data      <= 1'b0;
                o_valid     <= 1'b0;
            end 
            else 
            begin
                if (mode) 
                begin
                    // 1 Mbps Mode
                    cycle_flag <= 1'b0;
                    if (!busy) 
                    begin
                        o_valid <= 1'b0;
                        if (i_valid) 
                        begin
                            shift_reg[3:0] <= i_data[3:0];
                            busy           <= 1'b1;
                            bit_count      <= 6'd0;
                            o_data         <= i_data[0];
                            o_valid        <= 1'b1;
                        end
                    end 
                    else 
                    begin
                        if (bit_count < 6'd3) 
                        begin
                            bit_count <= bit_count + 1'b1;
                            o_data    <= shift_reg[bit_count + 1'b1];
                            o_valid   <= 1'b1;
                        end 
                        else 
                        begin
                            busy    <= 1'b0;
                            o_valid <= 1'b0;
                            if (i_valid) 
                            begin
                                shift_reg[3:0] <= i_data[3:0];
                                busy           <= 1'b1;
                                bit_count      <= 6'd0;
                                o_data         <= i_data[0];
                                o_valid        <= 1'b1;
                            end
                        end
                    end
                end 
                else begin
                    // 250 Kbps Mode
                    if (!busy) 
                    begin
                        o_valid <= 1'b0;
                        if (i_valid) 
                        begin
                            if (!cycle_flag) 
                            begin
                                shift_reg[31:0] <= i_data;
                                cycle_flag      <= 1'b1;
                            end 
                            else 
                            begin
                                cycle_flag <= 1'b0;
                                busy       <= 1'b1;
                                bit_count  <= 6'd0;
                                shift_reg  <= {
                                    shift_reg[15:12], // G3
                                    i_data[27:24],    // G14
                                    shift_reg[7:4],   // G1
                                    i_data[19:16],    // G12
                                    shift_reg[31:28], // G7
                                    i_data[11:8],     // G10
                                    shift_reg[23:20], // G5
                                    i_data[3:0],      // G8
                                    i_data[15:12],    // G11
                                    shift_reg[27:24], // G6
                                    i_data[7:4],      // G9
                                    shift_reg[19:16], // G4
                                    i_data[31:28],    // G15
                                    shift_reg[11:8],  // G2
                                    i_data[23:20],    // G13
                                    shift_reg[3:0]    // G0
                                };
                                o_data     <= shift_reg[0];
                                o_valid    <= 1'b1;
                            end
                        end
                    end 
                    else 
                    begin
                        if (bit_count < 6'd63) 
                        begin
                            bit_count <= bit_count + 1'b1;
                            o_data    <= shift_reg[bit_count + 1'b1];
                            o_valid   <= 1'b1;
                        end 
                        else 
                        begin
                            busy    <= 1'b0;
                            o_valid <= 1'b0;
                            if (i_valid) 
                            begin
                                shift_reg[31:0] <= i_data;
                                cycle_flag      <= 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end
endgenerate

endmodule