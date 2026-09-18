/*
*********************************************************************************
* File   : form_ppdu  (CORRECTED)
*
* IEEE 802.15.4 CSS PHY -- PPDU assembly (SHR prepend)
*   6.5a.3.1 Preamble : 32 ones (1 Mb/s) / 80 ones (250 kb/s)
*   6.3.2    SFD      : 16 chips, Table 20a, "starts with bit 0"
*   6.5a.2.5 "Preamble and SFD shall be applied directly to BOTH inputs
*             (I and Q) of the QPSK mapper"
*
*   SHR length : mode = 1 (fast, 1 Mb/s) -> 48 chips  (32 + 16)
*                mode = 0 (slow, 250 kb/s) -> 96 chips (80 + 16)
*
* MATLAB golden equivalent (ChirpSpreadSpectrum_Tx.m):
*     I_path = [preamble_SFD , I_path_binaryData]
*     Q_path = [preamble_SFD , Q_path_binaryData]
*   i.e. SHR_LEN header chips, then EVERY interleaver chip, once, in order.
*
*********************************************************************************
* BUGS FIXED vs the original (all three branches shared them; only the "H"
* mode=1 branch was exercised by the failing test cases):
*
* [1] ROOT CAUSE of the 1 Mb/s mismatches.  The load branch did
*         done_reg[0] <= done;
*     while simultaneously doing  done <= 1'b0.  Non-blocking assignment means
*     done_reg[0] captured the OLD value (1), injecting a false end-of-frame
*     marker at the head of the frame.  SHR_LEN+1 cycles later that marker
*     reached done_reg[48], which is exactly the restart condition
*         reg_i_valid[47] && !sending_shr && done_reg[48] && start
*     so the block re-sent the whole 48-chip SHR immediately after the first
*     payload chip.  It also gated the data path off via
*         reg_i_valid[47] && !(done_reg[48])
*     Observed in 06_QPSK_transcript.log: counts 0..47 = correct SHR,
*     counts 48..79 = a second 32-chip preamble, counts 80..95 = a second SFD.
*
* [2] done_reg was declared [shr_bits:0] but assigned {done_reg[shr_bits-2:0],
*     done} -- one bit too short, so done_reg[shr_bits] could NEVER be written.
*     In "F" and "S" (and "H" mode=0) the restart condition therefore never
*     fires at all: a second PPDU after tx_done can never be transmitted.
*
* [3] "start" was set but never cleared, so after tx_done neither restart path
*     was reachable.  The frame boundary is now an explicit 3-state FSM armed
*     by tx_done, which is what the "done/done_reg/start" trio was trying and
*     failing to express.
*
* [4] The delay line is now flushed on tx_done / reset, so chips left over from
*     frame N cannot leak into the SHR window of frame N+1.
*********************************************************************************
*/

`default_nettype none

module form_ppdu #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H",
    parameter shr_bits  = (rate_mode == "F") ? 48 : 96
)(
/************************************ Inputs ***********************************/
    input  wire                clk,
    input  wire                rst_n,
    input  wire                mode,            // H only: 1 = fast (1 Mb/s), 0 = slow
    input  wire                i_valid,
    input  wire                i_e,             // interleaver even path -> I
    input  wire                i_o,             // interleaver odd  path -> Q
    input  wire                tx_done,
    input  wire [shr_bits-1:0] i_preamble_SFD,  // chip 0 in bit [0]
/*********************************** Outputs ***********************************/
    output reg                 o_i,
    output reg                 o_q,
    output reg                 o_valid
);

/* --------------------------------------------------------------------------- *
 *  Rate selection
 * --------------------------------------------------------------------------- */
    localparam CNT_W = (shr_bits > 48) ? 7 : 6;

    // 1 for the 1 Mb/s framing, 0 for the 250 kb/s framing
    wire fast_sel = (rate_mode == "F") ? 1'b1 :
                    (rate_mode == "S") ? 1'b0 : mode;

    // Number of SHR chips to prepend to this frame
    wire [CNT_W-1:0] shr_len = fast_sel ? 48 : 96;

/* --------------------------------------------------------------------------- *
 *  Data delay line
 *  The SHR occupies the first shr_len output cycles, so the payload chips that
 *  arrive during that window must be held back by exactly shr_len cycles.
 *  Tapping at [shr_len-1] reproduces the upstream valid pattern (the 1 Mb/s
 *  interleaver bursts 4 chips then idles 2) shifted by shr_len cycles, with no
 *  chip inserted, duplicated or dropped.
 * --------------------------------------------------------------------------- */
    reg [shr_bits-1:0] reg_data_i;
    reg [shr_bits-1:0] reg_data_q;
    reg [shr_bits-1:0] reg_valid;

    wire dl_i = fast_sel ? reg_data_i[47] : reg_data_i[shr_bits-1];
    wire dl_q = fast_sel ? reg_data_q[47] : reg_data_q[shr_bits-1];
    wire dl_v = fast_sel ? reg_valid [47] : reg_valid [shr_bits-1];

/* --------------------------------------------------------------------------- *
 *  Frame FSM
 * --------------------------------------------------------------------------- */
    localparam [1:0] ST_IDLE = 2'd0,   // waiting for the first chip of a frame
                     ST_SHR  = 2'd1,   // streaming preamble + SFD
                     ST_DATA = 2'd2;   // streaming the delayed payload

    reg [1:0]          state;
    reg [shr_bits-1:0] reg_shr;
    reg [CNT_W-1:0]    bit_count;      // SHR chips still to send after this one

    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            o_i        <= 1'b0;
            o_q        <= 1'b0;
            o_valid    <= 1'b0;
            reg_shr    <= {shr_bits{1'b0}};
            reg_data_i <= {shr_bits{1'b0}};
            reg_data_q <= {shr_bits{1'b0}};
            reg_valid  <= {shr_bits{1'b0}};
            bit_count  <= {CNT_W{1'b0}};
            state      <= ST_IDLE;
        end
        else
        begin
            // The delay line advances every cycle, including the cycle the SHR
            // is loaded, so the chip present at the load cycle lands on the
            // output exactly shr_len cycles later -- immediately after the SHR.
            reg_data_i <= {reg_data_i[shr_bits-2:0], i_e};
            reg_data_q <= {reg_data_q[shr_bits-2:0], i_o};
            reg_valid  <= {reg_valid [shr_bits-2:0], i_valid};

            case (state)

            // ------------------------------------------------------------- //
            ST_IDLE:
            begin
                o_i     <= 1'b0;
                o_q     <= 1'b0;
                o_valid <= 1'b0;

                if (i_valid)
                begin
                    // chip 0 of the preamble goes out this cycle
                    o_i       <= i_preamble_SFD[0];
                    o_q       <= i_preamble_SFD[0];
                    o_valid   <= 1'b1;

                    reg_shr   <= i_preamble_SFD >> 1;
                    bit_count <= shr_len - 1'b1;
                    state     <= ST_SHR;
                end
            end

            // ------------------------------------------------------------- //
            ST_SHR:
            begin
                o_i     <= reg_shr[0];
                o_q     <= reg_shr[0];
                o_valid <= 1'b1;
                reg_shr <= reg_shr >> 1;

                bit_count <= bit_count - 1'b1;
                if (bit_count == {{(CNT_W-1){1'b0}}, 1'b1})   // == 1
                    state <= ST_DATA;
            end

            // ------------------------------------------------------------- //
            ST_DATA:
            begin
                o_i     <= dl_i;
                o_q     <= dl_q;
                o_valid <= dl_v;
            end

            // ------------------------------------------------------------- //
            default:
            begin
                o_i     <= 1'b0;
                o_q     <= 1'b0;
                o_valid <= 1'b0;
                state   <= ST_IDLE;
            end

            endcase

            // End of packet: arm the next PPDU and flush the pipe so no stale
            // chip can be mistaken for the start of frame N+1.
            if (tx_done)
            begin
                state      <= ST_IDLE;
                o_i        <= 1'b0;
                o_q        <= 1'b0;
                o_valid    <= 1'b0;
                bit_count  <= {CNT_W{1'b0}};
                reg_data_i <= {shr_bits{1'b0}};
                reg_data_q <= {shr_bits{1'b0}};
                reg_valid  <= {shr_bits{1'b0}};
            end
        end
    end

endmodule

`default_nettype wire
