/*
********************************** Documentaion *********************************
*Author	:Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File	:Zigbee  															    *
*********************************************************************************
*/

module zigbee #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H", //H >>>>> Hybrid, F >>>>> 1mbps, S >>>>> 250kbps
    parameter wl = 6,
    parameter fl = 3,
    parameter payload_w =8,
    parameter max_payload_length =127,
    parameter header_length = 12
)(
/************************************ Inputs ***********************************/
    input   wire                                        clk,
    input   wire                                        rst_n,
    input   wire    [payload_w-1 : 0]                   payload,
    input   wire    [$clog2(max_payload_length)-1 : 0]  payload_length,
    input   wire                                        start_tx,

/*********************************** Outputs ***********************************/
    output  wire    [wl-1 : 0]                          tx_real,
    output  wire    [wl-1 : 0]                          tx_imag,
    output  wire                                        tx_done    
);
/*********************************** Signals ***********************************/
wire                        counter_wren;
wire                        zeropadding_nextitem;
wire    [payload_w-1 : 0]   counter_wrdata;
wire    [payload_w-1 : 0]   payload_fifo_out;
wire                        payload_fifo_full;
wire                        payload_fifo_empty;
wire                        rst_n_sync;
wire                        zeropadding_en;
wire                        mode;
wire                        zeropadding_valid;
wire                        zeropadding_out;
wire    [(rate_mode == "F"? 2:5) : 0]   e_demux_branch;
wire    [(rate_mode == "F"? 2:5) : 0]   o_demux_branch;
wire                                    demux_valid;
/******************************** Instantiation ********************************/
rst_sync #(.Stages ('d2)) RDC (
    .clk        (clk),
    .rst_n      (rst_n),

    .rst_n_sync (rst_n_sync)
);

FIFO_mem #(.FIFO_WIDTH (payload_w), .FIFO_DEPTH (max_payload_length+1)) payload_ram (
    .clk            (clk),
    .rst_n          (rst_n_sync),
    .wr_en          (counter_wren),
    .rd_en          (zeropadding_nextitem),
    .din            (counter_wrdata),

    .dout           (payload_fifo_out),
    .full_flag      (payload_fifo_full),
    .empty_flag     (payload_fifo_empty)
);

payload_counter #(.payload_w (payload_w), .max_payload_length (max_payload_length)) PayLoad_Counter(
    .clk            (clk),
    .rst_n          (rst_n_sync),
    .fifo_full      (payload_fifo_full),
    .start_tx       (start_tx),
    .tx_done        (tx_done),
    .payload        (payload),
    .payload_length (payload_length),
    
    .wr_en          (counter_wren),
    .wr_data        (counter_wrdata)
);

zeropadding #(.payload_w (payload_w), .rate_mode (rate_mode), .max_payload_length (max_payload_length), .header_length (header_length)) ZeroPadding (
    .clk            (clk),
    .rst_n          (rst_n_sync),
    .data_i         (payload_fifo_out),
    .payload_length (payload_length),
    .empty          (payload_fifo_empty),
    .en             (zeropadding_en),
    .mode           (mode),

    .valid          (zeropadding_valid),
    .next_item      (zeropadding_nextitem),
    .data_o         (zeropadding_out)
);


e_o_demux #(.rate_mode (rate_mode)) DEMUX (
    .clk        (clk),
    .rst_n      (rst_n_sync),
    .mode       (mode),
    .data_i     (zeropadding_out),
    .valid_i    (zeropadding_valid),

    .e_bits     (e_demux_branch),
    .o_bits     (o_demux_branch),
    .valid      (demux_valid)
);
endmodule