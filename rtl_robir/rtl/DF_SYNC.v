/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:ٍDF_SYNC          														 *
*********************************************************************************
*/
module DF_SYNC #(
/********************************** Parameters *********************************/
    parameter Stages = 2,
    parameter Depth = 8,
    parameter Width =$clog2(Depth)+1
)(
/************************************ Inputs ***********************************/
    input   wire    [Width-1 : 0]   DATA,
    input   wire                    CLK,
    input   wire                    RST,
/*********************************** Outputs ***********************************/
    output  reg     [Width-1 : 0]   OUT
);
/************************************ Signals **********************************/
reg     [Stages-1 : 0]   ffs    [Width-1 : 0]; // ffs[bit][stage]
/*********************************** Integers **********************************/
integer i;
/******************************* Seq Always Blocks *****************************/
//flipflops behaviour
always @(posedge CLK or negedge RST)
    begin
        if(!RST)
            begin
                for (i=0; i<Width; i=i+1)
                    begin
                        ffs[i] <= 'b0;
                    end
            end
        else
            begin
                for (i=0; i<Width; i=i+1)
                    begin
                        ffs[i] <= {DATA[i], ffs[i][Stages-1 : 1]};
                    end
            end
    end
/****************************** Comb Always Blocks *****************************/
always @(*)
    begin
        for (i=0; i<Width; i=i+1)
            begin
                OUT[i] = ffs[i][0];
            end
    end
endmodule

    