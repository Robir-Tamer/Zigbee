/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   :mode_top_dual_path                                                     *
*********************************************************************************
*/
// module mode_top #(
//     parameter rate_mode = 0 // 0 --> 250 Kbps (Interleaver enabled), 1 --> 1 Mbps (Interleaver bypassed)
// )(
//     input                                  clk, rst, i_valid,
//     input  [((rate_mode == 1) ? 5 : 2):0]  i_data_even, 
//     input  [((rate_mode == 1) ? 5 : 2):0]  i_data_odd,  
//     output [((rate_mode == 1) ? 31: 63):0] data_o_even,
//     output [((rate_mode == 1) ? 31: 63):0] data_o_odd,
//     output                                 valid_o_even, valid_o_odd
// );

// // --- Path 1: Even Path ---
// wire [((rate_mode == 1) ? 31 : 32)-1:0] mapper_to_fifo_data_even;
// wire                                    mapper_to_fifo_valid_even;
// wire                                    fifo_full_even;
// wire                                    fifo_empty_even;
// wire [((rate_mode == 1) ? 31 : 32)-1:0] fifo_dout_even;
// wire                                    fifo_rden_even;
// assign fifo_rden_even = !fifo_empty_even;

// symbol_mapper #(.rate_mode(rate_mode)) u_symbol_mapper_even (
//     .clk(clk), .rst(rst), .i_valid(i_valid), .i_data(i_data_even),
//     .o_data(mapper_to_fifo_data_even), .o_valid(mapper_to_fifo_valid_even)
// );

// sync_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(3)) u_sync_fifo_even (
//     .clk(clk), .rst(rst), .wren(mapper_to_fifo_valid_even), .rden(fifo_rden_even),
//     .din(mapper_to_fifo_data_even), .dout(fifo_dout_even), .full(fifo_full_even), .empty(fifo_empty_even)
// );

// generate
// if (rate_mode == 0) begin : gen_interleaver_even_enabled
//     interleaver u_interleaver_even (
//         .clk(clk), .rst(rst), .i_valid(fifo_rden_even), .i_data(fifo_dout_even),
//         .o_data(data_o_even), .o_valid(valid_o_even)
//     );
// end else begin : gen_interleaver_even_bypassed
//     assign data_o_even  = fifo_dout_even;
//     assign valid_o_even = fifo_rden_even;
// end
// endgenerate


// // --- Path 2: Odd Path ---
// wire [((rate_mode == 1) ? 31 : 32)-1:0] mapper_to_fifo_data_odd;
// wire                                    mapper_to_fifo_valid_odd;
// wire                                    fifo_full_odd;
// wire                                    fifo_empty_odd;
// wire [((rate_mode == 1) ? 31 : 32)-1:0] fifo_dout_odd;
// wire                                    fifo_rden_odd;
// assign fifo_rden_odd = !fifo_empty_odd;

// symbol_mapper #(.rate_mode(rate_mode)) u_symbol_mapper_odd (
//     .clk(clk), .rst(rst), .i_valid(i_valid), .i_data(i_data_odd),
//     .o_data(mapper_to_fifo_data_odd), .o_valid(mapper_to_fifo_valid_odd)
// );

// sync_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(3)) u_sync_fifo_odd (
//     .clk(clk), .rst(rst), .wren(mapper_to_fifo_valid_odd), .rden(fifo_rden_odd),
//     .din(mapper_to_fifo_data_odd), .dout(fifo_dout_odd), .full(fifo_full_odd), .empty(fifo_empty_odd)
// );

// generate
// if (rate_mode == 0) begin : gen_interleaver_odd_enabled
//     interleaver u_interleaver_odd (
//         .clk(clk), .rst(rst), .i_valid(fifo_rden_odd), .i_data(fifo_dout_odd),
//         .o_data(data_o_odd), .o_valid(valid_o_odd)
//     );
// end else begin : gen_interleaver_odd_bypassed
//     assign data_o_odd  = fifo_dout_odd;
//     assign valid_o_odd = fifo_rden_odd;
// end
// endgenerate

// endmodule