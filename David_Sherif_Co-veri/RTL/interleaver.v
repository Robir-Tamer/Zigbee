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
    input                                       i_valid_c, 
    input      [(rate_mode == "F"? 3 : 31):0]   i_data,
    input                                       tx_done,
/*********************************** Outputs ***********************************/
    output reg                                  o_data,
    output reg                                  o_valid,
    output reg                                  next_item
);

reg i_valid;
always @(posedge clk)
    begin
        if(!rst_n)
            i_valid <= 'b0;
        else
            i_valid <= i_valid_c;
    end

generate
    if (rate_mode == "F") begin : gen_interleaver_1mbps
        reg [2:0]  shift_reg;
        reg [1:0]  bit_count;
        reg        busy;

        always @(posedge clk) 
        begin
            next_item   <= 'b1;
        end
        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                o_data    <= 1'b0;
                o_valid   <= 1'b0;
                shift_reg <= 3'b0;
                bit_count <= 2'b0;
                busy      <= 1'b0;
            end 
            else if (!busy && i_valid)
            begin
                shift_reg <= i_data[2:0];
                busy      <= 1'b1;
                bit_count <= 2'b0;
                o_data    <= i_data[3];
                o_valid   <= 1'b1;
            end
            else if (busy)
            begin
                if (bit_count < 2'd2) 
                begin
                    o_data    <= shift_reg[2];
                    shift_reg <= shift_reg << 1;
                    bit_count <= bit_count + 1'b1;   
                    o_valid   <= 1'b1;
                end 
                else 
                begin
                    o_data    <= shift_reg[2];
                    busy      <= 1'b0;
                    o_valid   <= 1'b1; 
                end
            end 
            else
            begin
                o_data    <= 1'b0;
                o_valid   <= 1'b0;
                busy      <= 1'b0;
            end
        end
    end

    else if (rate_mode == "S") begin : gen_interleaver_250kbps
        reg        cycle_flag;
        reg [63:0] shift_reg;
        reg [5:0]  bit_count;
        reg        busy;
        reg        first_done;
        reg        data_ready;
        wire [3:0] g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,g10,g11,g12;
        assign g0   = shift_reg [31:28];
        assign g1   = shift_reg [27:24];
        assign g2   = shift_reg [23:20];
        assign g3   = shift_reg [19:16];
        assign g4   = shift_reg [15:12];
        assign g5   = shift_reg [11:8];
        assign g6   = shift_reg [7:4];
        assign g7   = shift_reg [3:0];
        assign g8   = i_data[31:28];
        assign g9   = i_data[27:24];
        assign g10  = i_data[23:20];
        assign g11  = i_data[19:16];
        assign g12  = i_data[15:12];
        assign g13  = i_data[11:8];
        assign g14  = i_data[7:4];
        assign g15  = i_data[3:0];

        always @(posedge clk) 
        begin
            if (!rst_n) begin
                cycle_flag  <= 1'b0;
                shift_reg   <= 64'b0;
                bit_count   <= 6'd0;
                busy        <= 1'b0;
                o_data      <= 1'b0;
                o_valid     <= 1'b0;
                next_item   <= 'b0;
                first_done  <= 'b0;
                data_ready  <= 'b0;
            end 
            else 
            begin
                if (!busy) 
                begin
                    if (i_valid) 
                    begin
                        if (!first_done)
                            begin
                                next_item           <= 1'b1;
                                first_done          <= 1'b1;
                                o_valid             <= 1'b0;
                            end
                        else if (next_item && !data_ready)
                            begin
                                data_ready          <= 'b1;
                                next_item           <= 'b1;
                                o_valid             <= 1'b0;
                            end
                        if (!cycle_flag && data_ready) 
                        begin
                            shift_reg[31:0] <= i_data; 
                            cycle_flag      <= 1'b1;
                            next_item       <= 1'b0;
                        end 
                        else if (data_ready)
                        begin
                            next_item  <= 1'b0;
                            cycle_flag <= 1'b0;
                            busy       <= 1'b1;
                            bit_count  <= 6'd0;
                            shift_reg  <= {g0,g13,g2,g15,g4,g9,g6,g11,g8,g5,g10,g7,g12,g1,g14,g3};
                            // o_data     <= shift_reg[0];  // 5arban
                            //o_data    <= shift_reg[31];  // 5arban
                            o_data    <= shift_reg[16];
                            o_valid    <= 1'b1;
                            data_ready <= 'b0;
                        end
                    end
                    else if (tx_done)
                    begin
                        first_done     <= 'b0;
                        data_ready     <= 'b0;
                    end
                end 
                else 
                begin
                    if (bit_count < 6'd63) 
                    begin
                        bit_count <= bit_count + 1'b1;
                        /*
                        o_data    <= shift_reg [1];
                        shift_reg <= shift_reg >> 1;
                        */
                        o_data      <= shift_reg[62];
                        shift_reg   <= shift_reg << 1;

                        o_valid   <= 1'b1;
                        if ((bit_count == 6'd61 || bit_count == 6'd62) && i_valid)
                            begin
                                next_item   <= 1'b1;
                            end
                    end 
                    else 
                    begin
                        busy        <= 1'b0;
                        o_valid     <= 1'b0;
                        next_item   <= 1'b0;
                        if (i_valid)
                        begin
                            shift_reg[31:0] <= i_data;
                            cycle_flag      <= 1'b1;
                            data_ready      <= 1'b1;
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
        reg        first_done;
        reg        data_ready;
        wire [3:0] g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,g10,g11,g12;
        assign g0   = shift_reg [31:28];
        assign g1   = shift_reg [27:24];
        assign g2   = shift_reg [23:20];
        assign g3   = shift_reg [19:16];
        assign g4   = shift_reg [15:12];
        assign g5   = shift_reg [11:8];
        assign g6   = shift_reg [7:4];
        assign g7   = shift_reg [3:0];
        assign g8   = i_data[31:28];
        assign g9   = i_data[27:24];
        assign g10  = i_data[23:20];
        assign g11  = i_data[19:16];
        assign g12  = i_data[15:12];
        assign g13  = i_data[11:8];
        assign g14  = i_data[7:4];
        assign g15  = i_data[3:0];
        always @(posedge clk) 
        begin
            if (!rst_n) 
            begin
                cycle_flag  <= 1'b0;
                shift_reg   <= 64'b0;
                bit_count   <= 6'd0;
                busy        <= 1'b0;
                o_data      <= 1'b0;
                o_valid     <= 1'b0;
                next_item   <= 'b0;
                first_done  <= 'b0;
                data_ready  <= 'b0;
            end 
            else 
            begin
                if (mode) 
                begin
                    next_item   <= 1'b1;
                    // 1 Mbps Mode (Hybrid Fast) - Using lower 4 bits of i_data [3:0]
                    if (!busy && i_valid)
                    begin
                        shift_reg[2:0] <= i_data[2:0];
                        busy      <= 1'b1;
                        bit_count <= 6'd0; 
                        o_data    <= i_data[3];
                        o_valid   <= 1'b1;
                    end
                    else if (busy)
                    begin
                        if (bit_count < 6'd2) 
                        begin
                            o_data    <= shift_reg[2];
                            shift_reg <= shift_reg << 1;
                            bit_count <= bit_count + 1'b1;   
                            o_valid   <= 1'b1;
                        end 
                        else 
                        begin
                            o_data    <= shift_reg[2];
                            busy      <= 1'b0;
                            bit_count <= 6'd0;
                            o_valid   <= 1'b1;
                        end
                    end 
                    else
                    begin
                        o_data    <= 1'b0;
                        o_valid   <= 1'b0;
                        busy      <= 1'b0;
                    end
                end
                else 
                begin
                    // 250 Kbps Mode (Hybrid Slow)
                    if (!busy) 
                    begin
                        if (i_valid) 
                        begin
                            if (!first_done)
                                begin
                                    next_item           <= 1'b1;
                                    first_done          <= 1'b1;
                                    o_valid             <= 1'b0;
                                end
                            else if (next_item && !data_ready)
                                begin
                                    data_ready          <= 'b1;
                                    next_item           <= 'b1;
                                    o_valid             <= 1'b0;
                                end
                            if (!cycle_flag && data_ready) 
                            begin
                                shift_reg[31:0] <= i_data; 
                                cycle_flag      <= 1'b1;
                            end 
                            else if (data_ready)
                            begin
                                next_item  <= 1'b0;
                                cycle_flag <= 1'b0;
                                busy       <= 1'b1;
                                bit_count  <= 6'd0;
                                shift_reg  <= {g0,g13,g2,g15,g4,g9,g6,g11,g8,g5,g10,g7,g12,g1,g14,g3};
                                o_data     <= shift_reg[0];
                                o_valid    <= 1'b1;
                                data_ready <= 'b0;
                            end
                        end
                        else if (tx_done)
                        begin
                            first_done     <= 'b0;
                            data_ready     <= 'b0;
                        end
                    end 
                    else 
                    begin
                        if (bit_count < 6'd63) 
                        begin
                            bit_count <= bit_count + 1'b1;
                            o_data    <= shift_reg [1];
                            shift_reg <= shift_reg >> 1;
                            o_valid   <= 1'b1;
                            if ((bit_count == 6'd61 || bit_count == 6'd62) && i_valid)
                                begin
                                    next_item   <= 1'b1;
                                end
                        end 
                        else 
                        begin
                            busy        <= 1'b0;
                            o_valid     <= 1'b0;
                            next_item   <= 1'b0;
                            if (i_valid)
                            begin
                                shift_reg[31:0] <= i_data;
                                cycle_flag      <= 1'b1;
                                data_ready      <= 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end
endgenerate

endmodule