/*
********************************** Documentaion *********************************
*Author	:Robir Tamer                                                            *
*File	:zeropadding  													        *
*********************************************************************************
*/

module zeropadding #(
/********************************** Parameters *********************************/
    parameter payload_w =8,
    parameter rate_mode = "H", //H >>>>> Hybrid, F >>>>> 1mbps, S >>>>> 250kbps
    parameter max_payload_length =127,
    parameter header_length = 12
)(
/************************************ Inputs ***********************************/
    input   wire                                        clk,
    input   wire                                        rst_n,
    input   wire    [payload_w-1 : 0]                   data_i,
    input   wire    [$clog2(max_payload_length)-1 : 0]  payload_length, //assumed to be regesered by the datalink layer
    input   wire                                        empty,
    input   wire                                        en,
    input   wire                                        mode,

/*********************************** Outputs ***********************************/
    output  reg                                         valid,
    output  reg                                         next_item,
    output  reg                                         data_o
);
/*********************************** Signals ***********************************/
reg     [header_length-1 : 0]       header_reg;
wire    [header_length-1 : 0]       header;
reg     [(rate_mode == "F"? 3:4) : 0]    counter;        //Padding Counter
reg                                 header_done;
reg     [2:0]                       byte_counter;   //Readed Payload Counter
reg     [payload_w-1 : 0]           data_i_reg;

generate
    if (rate_mode == "F")
        begin
            always @(posedge clk or negedge rst_n)
                begin
                    if (!rst_n)
                        begin
                            valid       <= 1'b0;
                            next_item   <= 1'b0;
                            data_o      <= 1'b0;
                            counter     <= 'b0;
                            header_done <= 1'b0;
                            header_reg  <= 'b0;
                            byte_counter<= 3'b0;
                        end
                    else if (en)
                        begin
                            if (!header_done && !empty)
                                begin
                                    valid               <= 1'b1;
                                    if (counter == 0)
                                        begin
                                            header_reg  <= {{6{1'b0}},payload_length} >> 1;
                                            data_o      <= payload_length [0];
                                            counter     <= counter + 1'b1;
                                        end
                                    else
                                        begin
                                            {header_reg,data_o} <= {1'b0,header_reg};
                                            if (counter == 'd11)
                                                begin
                                                    counter     <= 'b0;
                                                    header_done <= 1'b1;
                                                    next_item   <= 1'b0;
                                                    
                                                end
                                            else
                                                begin
                                                    counter     <= counter + 1'b1;
                                                    if (counter == 'd10)
                                                        next_item   <= 1'b1;
                                                end
                                            
                                            
                                        end
                                end
                            else if (header_done)
                                begin
                                    if (!empty)
                                        begin
                                            valid               <= 1'b1;
                                            byte_counter        <= byte_counter + 1;
                                            if (byte_counter ==4'd5) //start reading only while sending the last bit in the current item
                                                begin
                                                    next_item   <= 1'b1;
                                                end
                                            else    
                                                begin
                                                    next_item   <= 1'b0;
                                                end

                                            if (byte_counter == 0)
                                                begin
                                                    data_i_reg  <= data_i >>1;
                                                    data_o      <= data_i[0];
                                                end
                                            else
                                                begin
                                                    {data_i_reg,data_o} <= {1'b0,data_i_reg};
                                                end
                                            
                                            if (counter == 'd5)
                                                begin
                                                    counter     <= 'b0;
                                                end
                                            else 
                                                begin
                                                    counter     <= counter + 1'b1;
                                                end
                                        end
                                    else
                                        begin
                                            if (counter == 4'd5)
                                                begin
                                                    counter     <= 'b0;
                                                end
                                            if (counter == 'b0 && byte_counter == 4'd0)
                                                begin
                                                    data_o      <= 1'b0;
                                                    counter     <= counter + 1'b1;
                                                    byte_counter<= 'd1;
                                                end
                                            else if(counter != 'b0)
                                                begin
                                                    data_o      <= 1'b0;
                                                    if (counter == 'd23)
                                                        begin
                                                            counter     <= 'b0;
                                                        end
                                                    else
                                                        begin
                                                            counter     <= counter + 1'b1;
                                                        end
                                                    valid       <= 1'b1;
                                                    byte_counter<= 'd1;
                                                end
                                            else
                                                begin
                                                    valid       <= 1'b0;
                                                    header_done <= 1'b0;
                                                end
                                        end
                                end
                        end
                end
        end
    else if (rate_mode == "S")
        begin
            always @(posedge clk or negedge rst_n)
                begin
                    if (!rst_n)
                        begin
                            valid       <= 1'b0;
                            next_item   <= 1'b0;
                            data_o      <= 1'b0;
                            counter     <= 'b0;
                            header_done <= 1'b0;
                            header_reg  <= 'b0;
                            byte_counter<= 3'b0;
                        end
                    else if (en)
                        begin
                            if (!header_done && !empty)
                                begin
                                    valid               <= 1'b1;
                                    counter             <= counter + 1'b1;
                                    if (counter == 'b0)
                                        begin
                                            header_reg  <= {{6{1'b0}},payload_length} >> 1;
                                            data_o      <= payload_length [0];
                                        end
                                    else
                                        begin
                                            {header_reg,data_o} <= {1'b0,header_reg};
                                            if (counter == 4'd11)
                                                begin
                                                    header_done <= 1'b1;
                                                    next_item   <= 1'b0;
                                                end
                                            else if (counter == 'd10)
                                                begin
                                                    next_item   <= 1'b1;
                                                end
                                        end
                                end
                            else if (header_done)
                                begin
                                    if (!empty)
                                        begin
                                            valid               <= 1'b1;
                                            byte_counter        <= byte_counter + 1;
                                            if (byte_counter ==4'd5) //start reading only while sending the last bit in the current item
                                                begin
                                                    next_item   <= 1'b1;
                                                end
                                            else    
                                                begin
                                                    next_item   <= 1'b0;
                                                end

                                            if (byte_counter == 0)
                                                begin
                                                    data_i_reg  <= data_i >>1;
                                                    data_o      <= data_i[0];
                                                end
                                            else
                                                begin
                                                    {data_i_reg,data_o} <= {1'b0,data_i_reg};
                                                end
                                            
                                            if (counter == 'd23)
                                                begin
                                                    counter     <= 'b0;
                                                end
                                            else 
                                                begin
                                                    counter     <= counter + 1'b1;
                                                end
                                        end
                                    else
                                        begin
                                            if (counter == 'd23)
                                                begin
                                                    counter     <= 'b0;
                                                end

                                            if (counter == 'b0 && byte_counter == 4'd0)
                                                begin
                                                    data_o      <= 1'b0;
                                                    counter     <= counter + 1'b1;
                                                    byte_counter<= 'd1;
                                                end
                                            else if(counter != 'b0)
                                                begin
                                                    data_o      <= 1'b0;
                                                    if (counter == 'd23)
                                                        begin
                                                            counter     <= 'b0;
                                                        end
                                                    else
                                                        begin
                                                            counter     <= counter + 1'b1;
                                                        end
                                                    valid       <= 1'b1;
                                                    byte_counter<= 'd1;
                                                end
                                            else
                                                begin
                                                    valid       <= 1'b0;
                                                    header_done <= 1'b0;
                                                end
                                        end
                                end
                        end
                end
        end
    else if (rate_mode == "H")
        begin
            always @(posedge clk or negedge rst_n)
                begin
                    if (!rst_n)
                        begin
                            valid       <= 1'b0;
                            next_item   <= 1'b0;
                            data_o      <= 1'b0;
                            counter     <= 'b0;
                            header_done <= 1'b0;
                            header_reg  <= 'b0;
                            byte_counter<= 3'b0;
                        end
                    else if (en)
                        begin
                            
                            if (!mode)
                                begin
                                    if (!header_done && !empty)
                                        begin
                                            valid               <= 1'b1;
                                            counter             <= counter + 1'b1;
                                            if (counter == 'b0)
                                                begin
                                                    header_reg  <= {{6{1'b0}},payload_length} >> 1;
                                                    data_o      <= payload_length [0];
                                                end
                                            else
                                                begin
                                                    {header_reg,data_o} <= {1'b0,header_reg};
                                                    if (counter == 4'd11)
                                                        begin
                                                            header_done <= 1'b1;
                                                            next_item   <= 1'b0;
                                                        end
                                                    else if (counter == 'd10)
                                                        begin
                                                            next_item   <= 1'b1;
                                                        end
                                                end
                                        end
                                    else if (header_done)
                                        begin
                                            if (!empty)
                                                begin
                                                    valid               <= 1'b1;
                                                    byte_counter        <= byte_counter + 1;
                                                    if (byte_counter ==4'd5) //start reading only while sending the last bit in the current item
                                                        begin
                                                            next_item   <= 1'b1;
                                                        end
                                                    else    
                                                        begin
                                                            next_item   <= 1'b0;
                                                        end

                                                    if (byte_counter == 0)
                                                        begin
                                                            data_i_reg  <= data_i >>1;
                                                            data_o      <= data_i[0];
                                                        end
                                                    else
                                                        begin
                                                            {data_i_reg,data_o} <= {1'b0,data_i_reg};
                                                        end

                                                    if (counter == 'd23)
                                                        begin
                                                            counter     <= 'b0;
                                                        end
                                                    else 
                                                        begin
                                                            counter     <= counter + 1'b1;
                                                        end
                                                end
                                            else
                                                begin
                                                    if (counter == 'b0 && byte_counter == 4'd0)
                                                        begin
                                                            data_o      <= 1'b0;
                                                            counter     <= counter + 1'b1;
                                                            byte_counter<= 'd1;
                                                        end
                                                    else if(counter != 'b0)
                                                        begin
                                                            data_o      <= 1'b0;
                                                            if (counter == 'd23)
                                                                begin
                                                                    counter     <= 'b0;
                                                                end
                                                            else
                                                                begin
                                                                    counter     <= counter + 1'b1;
                                                                end
                                                            valid       <= 1'b1;
                                                            byte_counter<= 'd1;
                                                        end
                                                    else
                                                        begin
                                                            valid       <= 1'b0;
                                                            header_done <= 1'b0;
                                                        end
                                                end
                                        end
                                end
                            else if (mode)
                                begin
                                    if (!header_done && !empty)
                                        begin
                                            valid               <= 1'b1;
                                            if (counter == 0)
                                                begin
                                                    header_reg  <= {{6{1'b0}},payload_length} >> 1;
                                                    data_o      <= payload_length [0];
                                                    counter     <= counter + 1'b1;
                                                end
                                            else
                                                begin
                                                    {header_reg,data_o} <= {1'b0,header_reg};
                                                    if (counter == 4'd11)
                                                        begin
                                                            counter     <= 'b0;
                                                            header_done <= 1'b1;
                                                            next_item   <= 1'b0;
                                                        end
                                                    else
                                                        begin
                                                            counter     <= counter + 1'b1;
                                                            if (counter == 'd10)
                                                                next_item   <= 1'b1;
                                                        end


                                                end
                                        end
                                    else if (header_done)
                                        begin
                                            if (!empty)
                                                begin
                                                    valid               <= 1'b1;
                                                    byte_counter        <= byte_counter + 1;
                                                    if (byte_counter ==4'd5) //start reading only while sending the last bit in the current item
                                                        begin
                                                            next_item   <= 1'b1;
                                                        end
                                                    else    
                                                        begin
                                                            next_item   <= 1'b0;
                                                        end

                                                    if (byte_counter == 0)
                                                        begin
                                                            data_i_reg  <= data_i >>1;
                                                            data_o      <= data_i[0];
                                                        end
                                                    else
                                                        begin
                                                            {data_i_reg,data_o} <= {1'b0,data_i_reg};
                                                        end

                                                    if (counter == 'd5)
                                                        begin
                                                            counter     <= 'b0;
                                                        end
                                                    else 
                                                        begin
                                                            counter     <= counter + 1'b1;
                                                        end
                                                end
                                            else
                                                begin
                                                    
                                                    if (counter == 'b0 && byte_counter == 4'd0)
                                                        begin
                                                            data_o      <= 1'b0;
                                                            counter     <= counter + 1'b1;
                                                            byte_counter<= 'd1;
                                                        end
                                                    else if(counter != 'b0)
                                                        begin
                                                            data_o      <= 1'b0;
                                                            if (counter == 'd5)
                                                                begin
                                                                    counter     <= 'b0;
                                                                end
                                                            else
                                                                begin
                                                                    counter     <= counter + 1'b1;
                                                                end
                                                            valid       <= 1'b1;
                                                            byte_counter<= 'd1;
                                                        end
                                                    else
                                                        begin
                                                            valid       <= 1'b0;
                                                            header_done <= 1'b0;
                                                        end
                                                end
                                        end
                                end     
                        end     
                end
        end     
endgenerate
endmodule