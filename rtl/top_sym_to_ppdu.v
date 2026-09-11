/*
********************************** Documentation *********************************
*Author : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : top_sym_to_ppdu                                                                    *
*********************************************************************************
*/

module top_sym_to_ppdu #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H"
)(
/************************************ Inputs ***********************************/
    input  wire                                 clk,
    input  wire                                 rst_n,
    input  wire                                 mode,
    input  wire                                 i_valid,
    input  wire [(rate_mode == "F" ? 2 : 5):0]  i_data_even,
    input  wire [(rate_mode == "F" ? 2 : 5):0]  i_data_odd,
/*********************************** Outputs ***********************************/
    output wire                                 o_i,
    output wire                                 o_q,
    output wire                                 o_valid
);

    localparam DATA_WIDTH    = (rate_mode == "F") ? 4 : 32;
    localparam PREAMBLE_BITS = (rate_mode == "F") ? 32 : 80;
    localparam TOTAL_BITS    = PREAMBLE_BITS + 16;

    // Internal wires for even path
    wire [DATA_WIDTH-1:0] mapper_even_data;
    wire                  mapper_even_valid;
    wire [DATA_WIDTH-1:0] fifo_even_dout;
    wire                  fifo_even_full;
    wire                  fifo_even_empty;
    wire                  interleaver_even_data;
    wire                  interleaver_even_valid;

    // Internal wires for odd path
    wire [DATA_WIDTH-1:0] mapper_odd_data;
    wire                  mapper_odd_valid;
    wire [DATA_WIDTH-1:0] fifo_odd_dout;
    wire                  fifo_odd_full;
    wire                  fifo_odd_empty;
    wire                  interleaver_odd_data;
    wire                  interleaver_odd_valid;

    // Internal wire for preamble and SFD generator output
    wire [TOTAL_BITS-1:0] preamble_sfd_wire;

    // =========================================================================
    // 0. Preamble and SFD Generator
    // =========================================================================

    preamble_sfd_gen #(
        .rate_mode          (rate_mode)
    ) u_preamble_sfd_gen (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .preamble_sfd       (preamble_sfd_wire)
    );

    // =========================================================================
    // 1. Even Path: Symbol Mapper -> Sync FIFO -> Interleaver
    // =========================================================================
    
    symbol_mapper #(
        .rate_mode          (rate_mode)
    ) u_symbol_mapper_even (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .i_data             (i_data_even),
        .i_valid            (i_valid),
        .o_data             (mapper_even_data),
        .o_valid            (mapper_even_valid)
    );

    FIFO_mem #(
        .FIFO_WIDTH         ((rate_mode == "F") ? 4 : 32),
        .FIFO_DEPTH         ((rate_mode == "F") ? 64 : 1024)
    ) u_sync_fifo_even (
        .clk                (clk),
        .rst_n              (rst_n),
        .wr_en              (mapper_even_valid),
        .rd_en              (1'b1), //Always enabled
        .din                (mapper_even_data),
        .dout               (fifo_even_dout),
        .full_flag          (), //Not needed
        .empty_flag         (fifo_even_empty) //Inverted & TO interleaver i_valid
    );

    interleaver #(
        .rate_mode          (rate_mode)
    ) u_interleaver_even (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .i_valid            (!fifo_even_empty),
        .i_data             (fifo_even_dout),
        .o_data             (interleaver_even_data),
        .o_valid            (interleaver_even_valid)
    );

    // =========================================================================
    // 2. Odd Path: Symbol Mapper -> Sync FIFO -> Interleaver
    // =========================================================================

    symbol_mapper #(
        .rate_mode          (rate_mode)
    ) u_symbol_mapper_odd (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .i_data             (i_data_odd),
        .i_valid            (i_valid),
        .o_data             (mapper_odd_data),
        .o_valid            (mapper_odd_valid)
    );

    FIFO_mem #(
        .FIFO_WIDTH         ((rate_mode == "F") ? 4 : 32),
        .FIFO_DEPTH         ((rate_mode == "F") ? 64 : 1024)
    ) u_sync_fifo_odd (
        .clk                (clk),
        .rst_n              (rst_n),
        .wr_en              (mapper_odd_valid),
        .rd_en              (1'b1), //Always enabled
        .din                (mapper_odd_data),
        .dout               (fifo_odd_dout),
        .full_flag          (), //Not needed
        .empty_flag         (fifo_odd_empty) //Inverted & TO interleaver i_valid
    );

    interleaver #(
        .rate_mode          (rate_mode)
    ) u_interleaver_odd (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .i_valid            (!fifo_odd_empty),
        .i_data             (fifo_odd_dout),
        .o_data             (interleaver_odd_data),
        .o_valid            (interleaver_odd_valid)
    );

    // =========================================================================
    // 3. PPDU Frame Formatting Block (Combines Preamble/SFD with Interleaved Data)
    // =========================================================================

    form_ppdu #(
        .rate_mode          (rate_mode)
    ) u_form_ppdu (
        .clk                (clk),
        .rst_n              (rst_n),
        .mode               (mode),
        .i_valid            (interleaver_even_valid || interleaver_odd_valid),
        .i_e                (interleaver_even_data),
        .i_o                (interleaver_odd_data),
        .i_preamble_SFD     (preamble_sfd_wire),
        .o_i                (o_i),
        .o_q                (o_q),
        .o_valid            (o_valid)
    );

endmodule