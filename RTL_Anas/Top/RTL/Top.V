// Top Module for Anas_RTL

module Top #(parameter FIFO_DEPTH = 4096,
                       FIFO_DEPTH = 2,
                       WL         = 6
            )
(
    // Anas_RTL_inputs
    input wire clk, rst_n,
    input wire [1:0] Real, Imag,
    input wire i_valid,





    // Anas_RTL_outputs
    output wire tx_done, tx_end,
    output wire [WL-1:0] tx_real, tx_imag
);

//DQPSK Signals and Instant
wire valid;
wire [1:0] Real_o, Imag_o;

DQPSK DQPSK_DUT (.clk(clk), .rst_n(rst_n), .i_valid(i_valid),
                 .Real(Real), .Imag(Imag), .valid(valid),
                 .Real_o(Real_o), .Imag_o(Imag_o));

//Real Synch FIFO Signals and Instant
wire full_flag_real, empty_flag_real;
wire FIFO_valid_real = valid && !full_flag_real;
wire [1:0] S_R;
FIFO_mem #(.FIFO_DEPTH(FIFO_DEPTH), .FIFO_DEPTH(FIFO_DEPTH)) Real_Sync_FIFO (
    .clk(clk), .rst_n(rst_n), 
    .wr_en(FIFO_valid_real), .rd_en(next_item), 
    .din(Real_o), .dout(S_R), 
    .empty_flag(empty_flag_real), .full_flag(full_flag_real) 
);

//Imag Synch FIFO Signals and Instant
wire full_flag_imag, empty_flag_imag;
wire FIFO_valid_imag = valid && !full_flag_imag;
wire [1:0] S_I;
FIFO_mem #(.FIFO_DEPTH(FIFO_DEPTH), .FIFO_DEPTH(FIFO_DEPTH)) Imag_Sync_FIFO (
    .clk(clk), .rst_n(rst_n),
    .wr_en(FIFO_valid_imag), .rd_en(next_item), 
    .din(Imag_o), .dout(S_I),
    .empty_flag(empty_flag_imag), .full_flag(full_flag_imag) 
);




//// CSK Signals
wire next_item;
