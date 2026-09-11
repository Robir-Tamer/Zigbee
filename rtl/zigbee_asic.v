/*
********************************** Documentaion *********************************
*Author	:Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File	:Zigbee  															    *
*********************************************************************************
*/

module zigbee_asic #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H", //H >>>>> Hybrid, F >>>>> 1mbps, S >>>>> 250kbps
    parameter wl = 6,
    parameter fl = 3,
    parameter payload_w =8,
    parameter max_payload_length =127,
    parameter header_length = 12,
    parameter dqpsk_fifo_w = 2,
    parameter dqpsk_fifo_depth = 4096
)(
/************************************ Inputs ***********************************/
    input   wire                                        fun_clk,
    input   wire                                        scan_clk,
    input   wire                                        fun_rst_n,
    input   wire                                        scan_rst_n,
    input   wire                                        test_mode,
    input   wire                                        si,
    input   wire                                        se,
    input   wire    [payload_w-1 : 0]                   payload,
    input   wire    [$clog2(max_payload_length)-1 : 0]  payload_length,
    input   wire                                        start_tx,

/*********************************** Outputs ***********************************/
    output  wire                                        so,
    output  wire    signed  [7 : 0]                     tx_real,
    output  wire    signed  [7 : 0]                     tx_imag,
    output  wire                                        tx_done    
);
/*********************************** Signals ***********************************/
wire                                    clk;
wire                                    rst_n;
wire                                    counter_wren;
wire                                    zeropadding_nextitem;
wire    [payload_w-1 : 0]               counter_wrdata;
wire    [payload_w-1 : 0]               payload_fifo_out;
wire                                    payload_fifo_full;
wire                                    payload_fifo_empty;
wire                                    zeropadding_en;
wire                                    mode;
wire                                    zeropadding_valid;
wire                                    zeropadding_out;
wire    [(rate_mode == "F"? 2:5) : 0]   e_demux_branch;
wire    [(rate_mode == "F"? 2:5) : 0]   o_demux_branch;
wire                                    demux_valid;
wire    signed  [1 : 0]                 qpsk_real_o;
wire    signed  [1 : 0]                 qpsk_imag_o;
wire                                    qpsk_valid;
wire                                    interleaver_valid_e;
wire                                    interleaver_valid_o;
wire                                    interleaver_valid;
wire                                    ppdu_i;
wire                                    ppdu_q;
wire                                    ppdu_valid;

assign interleaver_valid = interleaver_valid_e || interleaver_valid_o;
/******************************** Instantiation ********************************/

//clock Mux
mux2X1 clk_mux (
    .IN_0               (fun_clk),
    .IN_1               (scan_clk),
    .SEL                (test_mode),

    .OUT                (clk)
);

//reset Mux
mux2X1 rst_mux (
    .IN_0               (fun_rst_n),
    .IN_1               (scan_rst_n),
    .SEL                (test_mode),

    .OUT                (rst_n)
);

FIFO_mem #(.FIFO_WIDTH (payload_w), .FIFO_DEPTH (max_payload_length+1)) payload_ram (
    .clk                (clk),
    .rst_n              (rst_n),
    .wr_en              (counter_wren),
    .rd_en              (zeropadding_nextitem),
    .din                (counter_wrdata),

    .dout               (payload_fifo_out),
    .full_flag          (payload_fifo_full),
    .empty_flag         (payload_fifo_empty)
);

payload_counter #(.payload_w (payload_w), .max_payload_length (max_payload_length)) PayLoad_Counter(
    .clk                (clk),
    .rst_n              (rst_n),
    .fifo_full          (payload_fifo_full),
    .start_tx           (start_tx),
    .tx_done            (tx_done),
    .payload            (payload),
    .payload_length     (payload_length),
    
    .wr_en              (counter_wren),
    .wr_data            (counter_wrdata)
);

zeropadding #(.payload_w (payload_w), .rate_mode (rate_mode), .max_payload_length (max_payload_length), .header_length (header_length)) ZeroPadding (
    .clk                (clk),
    .rst_n              (rst_n),
    .data_i             (payload_fifo_out),
    .payload_length     (payload_length),
    .empty              (payload_fifo_empty),
    .en                 (zeropadding_en),
    .mode               (mode),

    .valid              (zeropadding_valid),
    .next_item          (zeropadding_nextitem),
    .data_o             (zeropadding_out)
);


e_o_demux #(.rate_mode (rate_mode)) DEMUX (
    .clk                (clk),
    .rst_n              (rst_n),
    .mode               (mode),
    .data_i             (zeropadding_out),
    .valid_i            (zeropadding_valid),

    .e_bits             (e_demux_branch),
    .o_bits             (o_demux_branch),
    .valid              (demux_valid)
);

controller #(
    .rate_mode          (rate_mode),
    .max_payload_length (max_payload_length)
) my_controller (
    .clk                (clk),
    .rst_n              (rst_n),
    .start_tx           (start_tx),
    .tx_end             (tx_done),
    .payload_length     (payload_length),
    .fifo_empty         (payload_fifo_empty),
    .demux_valid        (demux_valid),
    .interleaver_valid  (interleaver_valid),

    .mode               (mode),
    .zero_pad_en        (zeropadding_en)
);

top_sym_to_ppdu #(.rate_mode (rate_mode)) symbol_mapper_to_ppdu (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .mode                   (mode),
    .i_valid                (demux_valid),
    .i_data_even            (e_demux_branch),
    .i_data_odd             (o_demux_branch),

    .o_i                    (ppdu_i),
    .o_q                    (ppdu_q),
    .o_valid                (ppdu_valid),
    .interleaver_even_valid (interleaver_valid_e),
    .interleaver_odd_valid  (interleaver_valid_o)
);

QPSK_mapper QPSK (
    .clk                (clk),
    .rst_n              (rst_n),
    .i                  (ppdu_i),
    .q                  (ppdu_q),
    .i_valid            (ppdu_valid),

    .valid              (qpsk_valid),
    .out_real           (qpsk_real_o),
    .out_imag           (qpsk_imag_o)
);
dqpsk_csk_top #(.FIFO_DEPTH (dqpsk_fifo_depth), .FIFO_WIDTH (dqpsk_fifo_w), .WL (wl)) DQPSK_CSK (
    .clk                (clk),
    .rst_n              (rst_n),

    .Real               (qpsk_real_o),
    .Imag               (qpsk_imag_o),
    .i_valid            (qpsk_valid),

    .tx_done            (tx_done),
    .tx_real            (tx_real),
    .tx_imag            (tx_imag)
);
endmodule