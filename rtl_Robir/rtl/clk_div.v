/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:CLK_DIV																*
*********************************************************************************
*/

module clk_div(
/************************************ Inputs ***********************************/
    input   wire                ref_clk,
    input   wire                rst,
    input   wire                en,
    input   wire                div_ratio,
/*********************************** Outputs ***********************************/
    output  reg                 o_clk
);
/*********************************** Signals ***********************************/
reg cnt;

/******************************* Seq Always Blocks *****************************/
always @(posedge ref_clk or negedge rst)
    begin
        if (!rst)
            begin
                cnt<=0;
                o_clk<=0;
            end 
        else if (en)
            begin
                if (div_ratio)
                    begin
                        o_clk <= ref_clk;
                    end
                else
                    begin
                         if (cnt == 'd1)
                            begin
                                o_clk <= ~o_clk; 
                            end
                        else    
                            begin
                                o_clk <= o_clk; 
                                
                            end
                        cnt   <= cnt + 1;
                    end
            end
    end
endmodule