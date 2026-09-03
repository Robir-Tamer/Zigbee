/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:FIFO_MEM_CNTRL															*
*********************************************************************************
*/

module FIFO_MEM_CNTRL #(
/********************************** Parameters *********************************/
    parameter Width = 8,
    parameter Depth = 8,
    parameter addr_w =$clog2(Depth)
)(
/************************************ Inputs ***********************************/
    input   wire                    CLK,
    input   wire                    RST,
    input   wire                    WR_EN,
    input   wire                    EMPTY,
    input   wire    [Width-1 : 0]   WR_DATA,
    input   wire    [addr_w-1: 0]   WR_ADDR,
    input   wire    [addr_w-1: 0]   RD_ADDR,
/*********************************** Outputs ***********************************/
    output  wire     [Width-1 : 0]   RD_DATA
);
/************************************ Signals **********************************/
reg     [Width-1 : 0]  MEM [0 : Depth-1];   
/*********************************** Integers **********************************/
integer i;
/******************************* Assign Statements *****************************/
assign RD_DATA = MEM[RD_ADDR];
/******************************* Seq Always Blocks *****************************/
//data write
always @ (posedge CLK or negedge RST)
    begin
        if (!RST)
            begin
                for(i=0; i<Depth; i=i+1)
                    begin
                        MEM[i] <= 'b0;
                    end
            end 
        else if (WR_EN)
            begin
                MEM[WR_ADDR] <= WR_DATA;
            end
    end
endmodule