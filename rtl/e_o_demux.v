/*
********************************** Documentaion *********************************
*Author	:Robir Tamer                                                            *
*File	:e_o_demux  													        *
*********************************************************************************
*/

module e_o_demux #(
/********************************** Parameters *********************************/
    parameter rate_mode = "H"
)(
/************************************ Inputs ***********************************/
    input   wire            clk,
    input   wire            rst_n,
    input   wire            mode,
    input   wire            data_i,
    input   wire            valid_i,
/*********************************** Outputs ***********************************/
    output  reg     [(rate_mode == "F"? 2:5) : 0]   e_bits,
    output  reg     [(rate_mode == "F"? 2:5) : 0]   o_bits,
    output  reg                                     valid
);
/*********************************** Signals ***********************************/
reg                                     even;
reg     [(rate_mode == "F"? 2:5) : 0]   e_bits_reg;
reg     [(rate_mode == "F"? 2:5) : 0]   o_bits_reg;
reg     [(rate_mode == "F"? 1:2) : 0]   e_counter;
reg     [(rate_mode == "F"? 1:2) : 0]   o_counter;

generate
    if (rate_mode =="F")
        begin
            always @(posedge clk)
                begin
                    if (!rst_n)
                        begin
                            e_bits      <= 'b0;
                            o_bits      <= 'b0;
                            valid       <= 'b0;
                            even        <= 'b0;
                            e_bits_reg  <= 'b0;
                            o_bits_reg  <= 'b0;
                            e_counter   <= 'b0;
                            o_counter   <= 'b0;
                        end
                    else 
                        begin
                            if (valid_i)
                                begin
                                    if (!even)
                                        begin
                                            o_bits_reg  <= {data_i,o_bits_reg[2 : 1]};
                                            if (o_counter == 'b11)
                                                o_counter <= 'b1;
                                            else
                                                o_counter   <= o_counter + 'b1;
                                            even        <= !even;
                                        end
                                    else 
                                        begin
                                            e_bits_reg  <= {data_i,e_bits_reg[2 : 1]};
                                            if(e_counter == 'b11)
                                                e_counter <= 'b0;
                                            else
                                                e_counter   <= e_counter + 'b1;
                                            even        <= !even;
                                        end
                                end
                            else 
                                begin
                                    o_counter           <= 'b0;
                                    e_counter           <= 'b0;
                                end

                            if ((e_counter == 'b11) && (o_counter == 'b11))
                                begin
                                    e_bits      <= e_bits_reg;
                                    o_bits      <= o_bits_reg;
                                    valid       <= 'b1;
                                end
                            else
                                begin
                                    e_bits      <= 'b0;
                                    o_bits      <= 'b0;
                                    valid       <= 'b0;
                                 end
                        end
                end
        end
    else if (rate_mode =="S")
        begin
            always @(posedge clk)
                begin
                    if (!rst_n)
                        begin
                            e_bits      <= 'b0;
                            o_bits      <= 'b0;
                            valid       <= 'b0;
                            even        <= 'b0;
                            e_bits_reg  <= 'b0;
                            o_bits_reg  <= 'b0;
                            e_counter   <= 'b0;
                            o_counter   <= 'b0;
                        end
                    else 
                        begin
                            if (valid_i)
                                begin
                                    if (!even)
                                        begin
                                            o_bits_reg  <= {data_i,o_bits_reg[5 : 1]};
                                            if (o_counter == 'b110)
                                                o_counter <= 'b1;
                                            else
                                                o_counter   <= o_counter + 'b1;
                                            even        <= !even;
                                        end
                                    else 
                                        begin
                                            e_bits_reg  <= {data_i,e_bits_reg[5 : 1]};
                                            if(e_counter == 'b110)
                                                e_counter <= 'b0;
                                            else
                                                e_counter   <= e_counter + 'b1;
                                            even        <= !even;
                                        end
                                end
                            else 
                                begin
                                    o_counter           <= 'b0;
                                    e_counter           <= 'b0;
                                end
                            if ((e_counter == 'b110) && (o_counter == 'b110))
                                begin
                                    e_bits      <= e_bits_reg;
                                    o_bits      <= o_bits_reg;
                                    valid       <= 'b1;
                                end
                            else
                                begin
                                    e_bits      <= 'b0;
                                    o_bits      <= 'b0;
                                    valid       <= 'b0;
                                end
                        end
                end
        end
    else if (rate_mode == "H")
        begin
            always @(posedge clk)
                begin
                    if (!rst_n)
                        begin
                            e_bits      <= 'b0;
                            o_bits      <= 'b0;
                            valid       <= 'b0;
                            even        <= 'b0;
                            e_bits_reg  <= 'b0;
                            o_bits_reg  <= 'b0;
                            e_counter   <= 'b0;
                            o_counter   <= 'b0;
                        end
                    else if (!mode)
                        begin
                            if (valid_i)
                                begin
                                    if (!even)
                                        begin
                                            o_bits_reg  <= {data_i,o_bits_reg[5 : 1]};
                                            if (o_counter == 'b110)
                                                o_counter <= 'b1;
                                            else
                                                o_counter   <= o_counter + 'b1;
                                            even        <= !even;
                                        end
                                    else 
                                        begin
                                            e_bits_reg  <= {data_i,e_bits_reg[5 : 1]};
                                            if(e_counter == 'b110)
                                                e_counter <= 'b0;
                                            else
                                                e_counter   <= e_counter + 'b1;
                                            even        <= !even;
                                        end
                                end
                            else 
                                begin
                                    o_counter           <= 'b0;
                                    e_counter           <= 'b0;
                                end
                            if ((e_counter == 'b110) && (o_counter == 'b110))
                                begin
                                    e_bits      <= e_bits_reg;
                                    o_bits      <= o_bits_reg;
                                    valid       <= 'b1;
                                end
                            else
                                begin
                                    e_bits      <= 'b0;
                                    o_bits      <= 'b0;
                                    valid       <= 'b0;
                                end
                        end
                    else if (mode)
                        begin
                            if (valid_i)
                                begin
                                    o_bits_reg [5:3] <= 'b0;
                                    e_bits_reg [5:3] <= 'b0;
                                    if (!even)
                                        begin
                                            o_bits_reg[2:0]  <= {data_i,o_bits_reg[2 : 1]};
                                            if (o_counter == 'b11)
                                                o_counter <= 'b1;
                                            else
                                                o_counter   <= o_counter + 'b1;
                                            even        <= !even;
                                        end
                                    else 
                                        begin
                                            e_bits_reg[2:0]  <= {data_i,e_bits_reg[2 : 1]};
                                            if(e_counter == 'b11)
                                                e_counter <= 'b0;
                                            else
                                                e_counter   <= e_counter + 'b1;
                                            even        <= !even;
                                        end
                                end
                            else 
                                begin
                                    o_counter           <= 'b0;
                                    e_counter           <= 'b0;
                                end
                            
                            if ((e_counter == 'b11) && (o_counter == 'b11))
                                begin
                                    e_bits      <= e_bits_reg;
                                    o_bits      <= o_bits_reg;
                                    valid       <= 'b1;
                                end
                            else
                                begin
                                    e_bits      <= 'b0;
                                    o_bits      <= 'b0;
                                    valid       <= 'b0;
                                end
                        end
                end
        end
endgenerate

endmodule