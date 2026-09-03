/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:FIFO_WR     															*
*********************************************************************************
*/
module FIFO_WR #(
/********************************** Parameters *********************************/
    parameter Stages = 2,
    parameter Depth = 8,
    parameter data_w = 8,
    parameter Width =$clog2(Depth)+1
)(
/************************************ Inputs ***********************************/
    input   wire                    CLK,
    input   wire                    RST,
    input   wire                    Winc,
    input   wire    [Width-1 : 0]   wq2_R_ptr,
    input   wire                    ien,
    input   wire    [data_w-1 : 0]  high_water_level,
    input   wire    [data_w-1 : 0]  low_water_level,
/*********************************** Outputs ***********************************/
    output  reg     [Width-1 : 0]   W_ptr,
    output  wire    [Width-1 : 0]   W_ADDR,
    output  wire                    FULL,
    output  wire                    nFULL,
    output  reg                     of,
    output  wire                    high_water,
    output  wire                    low_water,
    output  wire    [data_w-1 : 0]   occupancy
);
/************************************ Signals **********************************/
reg     [Width-1 : 0]   CNT;
wire    [Width-1 : 0]   W_ptr_comb;
function [Width-1:0] gray2bin;
    input [Width-1:0] gray;
    integer i;
    begin
        gray2bin[Width-1] = gray[Width-1];
        for (i = Width-2; i >= 0; i = i - 1) begin
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    end
endfunction

// RX Domain Calculation
wire [Width-1:0] r_ptr_bin_sync;
reg dec_done;

/****************************** Assign Statements ******************************/
//assign W_ptr  = CNT ^ (CNT>>1);
assign W_ADDR = CNT;
assign W_ptr_comb = CNT ^ (CNT>>1);
assign FULL   = dec_done || ((W_ptr_comb [Width-1] != wq2_R_ptr[Width-1]) && (W_ptr_comb [Width-2] != wq2_R_ptr[Width-2]) && (W_ptr_comb [Width-3 : 0] == wq2_R_ptr[Width-3 : 0])) && ien;
assign nFULL  = (!FULL) && ien;
assign r_ptr_bin_sync = gray2bin(wq2_R_ptr);
assign occupancy = W_ADDR - r_ptr_bin_sync; 
assign high_water = (occupancy >= high_water_level) && ien;
assign low_water = (occupancy <= low_water_level) && ien;

/******************************* Seq Always Blocks *****************************/
always @(posedge CLK or negedge RST)
    begin
        if(!RST)
            begin
                CNT     <= 'b0;
                W_ptr   <= 'b0;
                of      <= 'b0;
                dec_done<= 'b0;
            end
        else if(Winc)
            begin
                if (FULL && !dec_done)
                    begin
                        CNT     <= CNT;
                        dec_done<= 'b1;
                    end
                else if (!FULL)
                    begin
                        CNT <= CNT+1;
                        dec_done<= 'b0;
                    end
                else
                    begin
                        dec_done<= 'b0;
                    end
                W_ptr   <= W_ptr_comb;
                of      <= ien && (FULL || (of && Winc));
            end
    end
endmodule

//Overflow Logic Needs to be Fixed