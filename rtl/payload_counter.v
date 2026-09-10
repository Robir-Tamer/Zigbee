/*
********************************** Documentaion *********************************
*Author	:Robir Tamer                                                            *
*File	:payload_counter  													    *
*********************************************************************************
*/

module payload_counter #(
/********************************** Parameters *********************************/
    parameter payload_w =8,
    parameter max_payload_length =127
)(
/************************************ Inputs ***********************************/
    input   wire                                        clk,
    input   wire                                        rst_n,
    input   wire                                        fifo_full,
    input   wire                                        start_tx,
    input   wire                                        tx_done,
    input   wire    [payload_w-1 : 0]                   payload,
    input   wire    [$clog2(max_payload_length)-1 : 0]  payload_length, //assumed to be regesered by the datalink layer
/*********************************** Outputs ***********************************/
    output  reg                                         wr_en,
    output  reg     [payload_w-1 : 0]                   wr_data
);
/*********************************** Signals ***********************************/
reg     [$clog2(max_payload_length)-1 : 0]  counter;
wire                                        en;
reg                                         running;

/******************************* Assign Statements *****************************/
assign en = !(start_tx || fifo_full || running);

/*************************** Sequential Always Blocks **************************/
always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
                counter <= 'b0;
                wr_en   <= 'b0;
                wr_data <= 'b0;
                running <= 'b0;
            end
        else if (en)
            begin
                if (counter != payload_length)
                    begin
                        counter <= counter + 1'b1;
                        wr_en   <= 1'b1;
                        wr_data <= payload;
                    end
                else
                    begin
                        counter <= counter;
                        wr_en   <= 1'b0;
                        wr_data <= 'b0;
                    end
            end
        else if (start_tx == 1'b1)
            begin
                running <= 1'b1;
            end
        else if (tx_done == 1'b1)
            begin
                running <= 1'b0;
                counter <= 'b0;
            end
    end
endmodule