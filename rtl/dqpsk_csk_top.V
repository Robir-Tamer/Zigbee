
module dqpsk_csk_top #(
    parameter FIFO_DEPTH = 4096,
    parameter FIFO_WIDTH = 2,
    parameter WL         = 6
) (
    // Inputs
    input  wire              clk, rst_n,
    input  wire signed [1:0] Real, Imag,
    input  wire              i_valid,
    // Outputs
    output wire              tx_done,
    output reg  signed [7:0] tx_real, tx_imag
);

    // DQPSK Interconnects
    wire              valid;
    wire signed [1:0] Real_o, Imag_o;

    // FIFO Interconnects
    wire              full_flag_real, empty_flag_real;
    wire              full_flag_imag, empty_flag_imag;
    wire              FIFO_valid_real, FIFO_valid_imag;
    wire signed [1:0] S_R, S_I;

    // CSK & FSM Interconnects
    wire              en;
    wire       next_item;
    wire signed [WL-1:0] csk_out_r, csk_out_i;
    wire              csk_running;

    // DQPSK Encoding Stage
    DQPSK DQPSK_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .Real(Real),
        .Imag(Imag),
        .valid(valid),
        .Real_o(Real_o),
        .Imag_o(Imag_o)
    );
    // Posedge Detector Circuit Signals
    wire tx_done_level;

    // Real Synchronous FIFO
    assign FIFO_valid_real = valid && !full_flag_real;

    FIFO_mem #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(FIFO_WIDTH)
    ) Real_Sync_FIFO (
        .clk(clk),
        .rst_n(rst_n), 
        .wr_en(FIFO_valid_real),
        .rd_en(next_item), 
        .din(Real_o),
        .dout(S_R), 
        .empty_flag(empty_flag_real),
        .full_flag(full_flag_real) 
    );

    // Imaginary Synchronous FIFO (Fixed Parameter Typo & Syntax Semicolon)
    assign FIFO_valid_imag = valid && !full_flag_imag;

    FIFO_mem #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(FIFO_WIDTH)
    ) Imag_Sync_FIFO (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(FIFO_valid_imag),
        .rd_en(next_item), 
        .din(Imag_o),
        .dout(S_I),
        .empty_flag(empty_flag_imag),
        .full_flag(full_flag_imag) 
    );

    // Chirp Waveform Generator (ROM / LUT Engine)
    assign en = (!empty_flag_imag) & (!empty_flag_real);

    CSK_GEN #(.WL(WL)) CSK_GEN_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .en(en), 
        .next_item(next_item),
        .csk_out_r(csk_out_r),
        .csk_out_i(csk_out_i),
        .running(csk_running)
    );

    // Transmission Done Detection — fires exactly when CSK_GEN has
    // finished its trailing gap (running drops) after data ran out.
    // 'ever_run' arms the check only after a real transmission has
    // started, so reset (running=0, en=0) can't false-trigger it.
    reg ever_run;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ever_run <= 1'b0;
        else if (csk_running)
            ever_run <= 1'b1;
        else if (tx_done)
            ever_run <= 1'b0;   // re-arm for the next packet
    end

    assign tx_done_level = ever_run && !csk_running;

    posedge_detector posedge_detector_DUT (
        .clk(clk),
        .rst_n(rst_n), 
        .in(tx_done_level), 
        .out(tx_done)
    );

// Modulation hardware Implementation (Complex Multiplier)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_imag <= 'd0;
        tx_real <= 'd0;
    end
    else begin
        tx_real <= (S_R * csk_out_r) - (S_I * csk_out_i);
        tx_imag <= (S_R * csk_out_i) + (S_I * csk_out_r);
    end
end

endmodule