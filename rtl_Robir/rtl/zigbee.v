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



endmodule