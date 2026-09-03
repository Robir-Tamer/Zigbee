/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:FIFO_WR     															*
*********************************************************************************
*/
module FIFO_RD #(
/********************************** Parameters *********************************/
    parameter Stages = 2,
    parameter Depth = 8,
    parameter Width =$clog2(Depth)+1
)(
/************************************ Inputs ***********************************/
    input   wire                    CLK,
    input   wire                    RST,
    input   wire                    Rinc,
    input   wire    [Width-1 : 0]   rq2_W_ptr,
    input   wire                    ien,
/*********************************** Outputs ***********************************/
    output  reg     [Width-1 : 0]   R_ptr,
    output  wire    [Width-1 : 0]   R_ADDR,
    output  wire                    EMPTY,
    output  wire                    nEMPTY,
    output  reg                     underrun
);
/************************************ Signals **********************************/
reg     [Width-1 : 0]   CNT;
wire    [Width-1 : 0]   R_ptr_comb;
/****************************** Assign Statements ******************************/
assign R_ptr_comb  = CNT ^ (CNT>>1);
assign R_ADDR   = (!EMPTY) ? CNT : (CNT-1);
assign EMPTY    = ((rq2_W_ptr == R_ptr_comb)) && ien;
assign nEMPTY   = (!EMPTY) && ien; 
/******************************* Seq Always Blocks *****************************/
always @(posedge CLK or negedge RST)
    begin
        if(!RST)
            begin
                CNT     <= 'b0;
                R_ptr   <= 'b0;
                underrun <= 'b0;
            end
        else if(Rinc && !EMPTY)
            begin
                CNT     <= CNT+1;
                R_ptr   <= R_ptr_comb;
                underrun <= ien && (EMPTY || (underrun && Rinc));
            end
    end
endmodule



//Underrun Concept needs fixing