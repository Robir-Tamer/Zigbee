/*
********************************** Documentation *********************************
* File   : interleaver  (CORRECTED)
*
* 250 kb/s bit interleaver -- IEEE 802.15.4 CSS PHY, 6.5a.2.9
*
* Spec: the 64 chips of two consecutive bi-orthogonal codewords are split into
* 16 groups G0..G15 of 4 chips each, where Gn = b[4n .. 4n+3] and b0 is the
* FIRST chip transmitted.  The groups are re-emitted in the order:
*
*     G0 G13 G2 G15 G4 G9 G6 G11 G8 G5 G10 G7 G12 G1 G14 G3
*
* Vector convention used here (matches symbol_mapper / FIFO ordering):
*   - i_data[31] is chip 0 of a codeword, i_data[0] is chip 31  (MSB first)
*   - word_c  = first  codeword of the pair -> input bits b0 .. b31  (c0..c31)
*   - i_data  = second codeword of the pair -> input bits b32..b63  (d0..d31)
*   - shift_reg is packed MSB-first: output bit b'0 sits at shift_reg[63],
*     so the stream is emitted left-to-right (shift LEFT, tap the top).
*
* Fixes vs the original:
*   [1] g13/g14/g15 were never declared -> implicit 1-bit nets -> the
*       concatenation was 55 bits instead of 64 and got zero-extended.
*   [2] next_item was deasserted one cycle too early, so the FIFO (which has
*       a registered dout, 1-cycle read latency) never advanced and the
*       "second" codeword was a duplicate of the first.
*   [3] first output bit was tapped from shift_reg[16]; the correct tap is
*       shift_reg[31] (= c0 = b0) of the OLD register value.
*   [4] "H" slow branch shifted RIGHT / tapped shift_reg[1], emitting the
*       64 chips in reverse order.  Now matches "S".
*********************************************************************************
*/

`default_nettype none

module interleaver #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H"
)(
/************************************ Inputs ***********************************/
    input  wire                                 clk,
    input  wire                                 rst_n,
    input  wire                                 mode,        // 1 = 1 Mb/s, 0 = 250 kb/s (H only)
    input  wire                                 i_valid_c,
    input  wire [(rate_mode == "F"? 3 : 31):0]  i_data,
    input  wire                                 tx_done,
/*********************************** Outputs ***********************************/
    output reg                                  o_data,
    output reg                                  o_valid,
    output reg                                  next_item
);

reg i_valid;
always @(posedge clk)
begin
    if (!rst_n)
        i_valid <= 1'b0;
    else
        i_valid <= i_valid_c;
end

generate
/* ========================================================================== */
/*  1 Mb/s  -- no interleaving, straight parallel-to-serial (chip 0 first)    */
/* ========================================================================== */
if (rate_mode == "F") begin : gen_interleaver_1mbps

    reg [2:0] shift_reg;
    reg [1:0] bit_count;
    reg       busy;

    always @(posedge clk)
        next_item <= 1'b1;

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
            o_data    <= i_data[3];      // chip 0
            o_valid   <= 1'b1;
        end
        else if (busy)
        begin
            o_data  <= shift_reg[2];
            o_valid <= 1'b1;
            if (bit_count < 2'd2)
            begin
                shift_reg <= shift_reg << 1;
                bit_count <= bit_count + 1'b1;
            end
            else
                busy <= 1'b0;
        end
        else
        begin
            o_data  <= 1'b0;
            o_valid <= 1'b0;
            busy    <= 1'b0;
        end
    end

end

/* ========================================================================== */
/*  250 kb/s  -- 64-bit group interleaver                                     */
/* ========================================================================== */
else if (rate_mode == "S") begin : gen_interleaver_250kbps

    reg        cycle_flag;
    reg [63:0] shift_reg;
    reg [5:0]  bit_count;
    reg        busy;
    reg        first_done;
    reg        data_ready;

    // [FIX 1] all sixteen group taps declared 4 bits wide
    wire [3:0] g0, g1, g2,  g3,  g4,  g5,  g6,  g7;
    wire [3:0] g8, g9, g10, g11, g12, g13, g14, g15;

    // first codeword of the pair  -> b0 .. b31   (G0..G7)
    assign g0  = shift_reg[31:28];
    assign g1  = shift_reg[27:24];
    assign g2  = shift_reg[23:20];
    assign g3  = shift_reg[19:16];
    assign g4  = shift_reg[15:12];
    assign g5  = shift_reg[11: 8];
    assign g6  = shift_reg[ 7: 4];
    assign g7  = shift_reg[ 3: 0];
    // second codeword of the pair -> b32 .. b63  (G8..G15)
    assign g8  = i_data[31:28];
    assign g9  = i_data[27:24];
    assign g10 = i_data[23:20];
    assign g11 = i_data[19:16];
    assign g12 = i_data[15:12];
    assign g13 = i_data[11: 8];
    assign g14 = i_data[ 7: 4];
    assign g15 = i_data[ 3: 0];

    // Spec permutation, packed MSB-first: G0 occupies [63:60], G3 occupies [3:0]
    wire [63:0] interleaved = {g0, g13, g2,  g15, g4, g9, g6,  g11,
                               g8, g5,  g10, g7,  g12, g1, g14, g3};

    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            cycle_flag <= 1'b0;
            shift_reg  <= 64'b0;
            bit_count  <= 6'd0;
            busy       <= 1'b0;
            o_data     <= 1'b0;
            o_valid    <= 1'b0;
            next_item  <= 1'b0;
            first_done <= 1'b0;
            data_ready <= 1'b0;
        end
        else
        begin
            if (!busy)
            begin
                if (i_valid)
                begin
                    if (!first_done)
                    begin
                        next_item  <= 1'b1;
                        first_done <= 1'b1;
                        o_valid    <= 1'b0;
                    end
                    else if (next_item && !data_ready)
                    begin
                        data_ready <= 1'b1;
                        next_item  <= 1'b1;
                        o_valid    <= 1'b0;
                    end

                    if (!cycle_flag && data_ready)
                    begin
                        // Latch FIRST codeword of the pair.
                        // [FIX 2] next_item MUST stay high here so the FIFO
                        // advances and presents the SECOND codeword next cycle.
                        shift_reg[31:0] <= i_data;
                        cycle_flag      <= 1'b1;
                        o_valid         <= 1'b0;
                    end
                    else if (data_ready)
                    begin
                        // SECOND codeword is on i_data now -> permute and start
                        next_item  <= 1'b0;
                        cycle_flag <= 1'b0;
                        busy       <= 1'b1;
                        bit_count  <= 6'd0;
                        shift_reg  <= interleaved;
                        // [FIX 3] first output chip b'0 = G0[0] = c0, which is
                        // bit 31 of the OLD shift_reg (non-blocking assignment)
                        o_data     <= shift_reg[31];
                        o_valid    <= 1'b1;
                        data_ready <= 1'b0;
                    end
                end
                else if (tx_done)
                begin
                    first_done <= 1'b0;
                    data_ready <= 1'b0;
                    cycle_flag <= 1'b0;
                    o_valid    <= 1'b0;
                end
            end
            else
            begin
                if (bit_count < 6'd63)
                begin
                    bit_count <= bit_count + 1'b1;
                    o_data    <= shift_reg[62];     // b'1 .. b'63
                    shift_reg <= shift_reg << 1;
                    o_valid   <= 1'b1;
                    // prefetch the next pair: two rd_en pulses
                    if ((bit_count == 6'd61 || bit_count == 6'd62) && i_valid)
                        next_item <= 1'b1;
                end
                else
                begin
                    busy      <= 1'b0;
                    o_valid   <= 1'b0;
                    next_item <= 1'b0;
                    if (i_valid)
                    begin
                        shift_reg[31:0] <= i_data;  // first codeword of next pair
                        cycle_flag      <= 1'b1;
                        data_ready      <= 1'b1;
                    end
                end
            end
        end
    end

end

/* ========================================================================== */
/*  Hybrid: mode = 1 -> 1 Mb/s bypass, mode = 0 -> 250 kb/s interleaver       */
/* ========================================================================== */
else if (rate_mode == "H") begin : gen_interleaver_hybrid

    reg        cycle_flag;
    reg [63:0] shift_reg;
    reg [5:0]  bit_count;
    reg        busy;
    reg        first_done;
    reg        data_ready;

    wire [3:0] g0, g1, g2,  g3,  g4,  g5,  g6,  g7;
    wire [3:0] g8, g9, g10, g11, g12, g13, g14, g15;

    assign g0  = shift_reg[31:28];
    assign g1  = shift_reg[27:24];
    assign g2  = shift_reg[23:20];
    assign g3  = shift_reg[19:16];
    assign g4  = shift_reg[15:12];
    assign g5  = shift_reg[11: 8];
    assign g6  = shift_reg[ 7: 4];
    assign g7  = shift_reg[ 3: 0];
    assign g8  = i_data[31:28];
    assign g9  = i_data[27:24];
    assign g10 = i_data[23:20];
    assign g11 = i_data[19:16];
    assign g12 = i_data[15:12];
    assign g13 = i_data[11: 8];
    assign g14 = i_data[ 7: 4];
    assign g15 = i_data[ 3: 0];

    wire [63:0] interleaved = {g0, g13, g2,  g15, g4, g9, g6,  g11,
                               g8, g5,  g10, g7,  g12, g1, g14, g3};

    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            cycle_flag <= 1'b0;
            shift_reg  <= 64'b0;
            bit_count  <= 6'd0;
            busy       <= 1'b0;
            o_data     <= 1'b0;
            o_valid    <= 1'b0;
            next_item  <= 1'b0;
            first_done <= 1'b0;
            data_ready <= 1'b0;
        end
        else if (mode)
        begin
            // ---------------- 1 Mb/s: no interleaving ----------------
            next_item <= 1'b1;
            if (!busy && i_valid)
            begin
                shift_reg[2:0] <= i_data[2:0];
                busy           <= 1'b1;
                bit_count      <= 6'd0;
                o_data         <= i_data[3];
                o_valid        <= 1'b1;
            end
            else if (busy)
            begin
                o_data  <= shift_reg[2];
                o_valid <= 1'b1;
                if (bit_count < 6'd2)
                begin
                    shift_reg <= shift_reg << 1;
                    bit_count <= bit_count + 1'b1;
                end
                else
                begin
                    busy      <= 1'b0;
                    bit_count <= 6'd0;
                end
            end
            else
            begin
                o_data  <= 1'b0;
                o_valid <= 1'b0;
                busy    <= 1'b0;
            end
        end
        else
        begin
            // ---------------- 250 kb/s: interleaver ----------------
            if (!busy)
            begin
                if (i_valid)
                begin
                    if (!first_done)
                    begin
                        next_item  <= 1'b1;
                        first_done <= 1'b1;
                        o_valid    <= 1'b0;
                    end
                    else if (next_item && !data_ready)
                    begin
                        data_ready <= 1'b1;
                        next_item  <= 1'b1;
                        o_valid    <= 1'b0;
                    end

                    if (!cycle_flag && data_ready)
                    begin
                        shift_reg[31:0] <= i_data;
                        cycle_flag      <= 1'b1;
                        o_valid         <= 1'b0;
                    end
                    else if (data_ready)
                    begin
                        next_item  <= 1'b0;
                        cycle_flag <= 1'b0;
                        busy       <= 1'b1;
                        bit_count  <= 6'd0;
                        shift_reg  <= interleaved;
                        o_data     <= shift_reg[31];   // [FIX 4] was shift_reg[0]
                        o_valid    <= 1'b1;
                        data_ready <= 1'b0;
                    end
                end
                else if (tx_done)
                begin
                    first_done <= 1'b0;
                    data_ready <= 1'b0;
                    cycle_flag <= 1'b0;
                    o_valid    <= 1'b0;
                end
            end
            else
            begin
                if (bit_count < 6'd63)
                begin
                    bit_count <= bit_count + 1'b1;
                    o_data    <= shift_reg[62];        // [FIX 4] was shift_reg[1]
                    shift_reg <= shift_reg << 1;       // [FIX 4] was >> 1
                    o_valid   <= 1'b1;
                    if ((bit_count == 6'd61 || bit_count == 6'd62) && i_valid)
                        next_item <= 1'b1;
                end
                else
                begin
                    busy      <= 1'b0;
                    o_valid   <= 1'b0;
                    next_item <= 1'b0;
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
endgenerate

endmodule

`default_nettype wire
