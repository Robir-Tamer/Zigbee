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
    parameter max_payload_length =127
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

endmodule