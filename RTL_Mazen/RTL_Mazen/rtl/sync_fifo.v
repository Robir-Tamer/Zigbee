/*
********************************** Documentation *********************************
*Author :Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   :preamble_sfd_gen                                                       *
*********************************************************************************
*/
module sync_fifo #(
    parameter  FIFO_WIDTH = 32, //32 for 250 Kbps , 4 for 1 Mbps
    parameter  FIFO_DEPTH = 1024, // 1024 for 250 Kbps (12*64 = 768) , 64 for 1 Mbps (12*4 = 48)
    localparam ADDR_SIZE  = $clog2(FIFO_DEPTH)
) (
    input  wire                   clk, rst, wr_en, rd_en,
    input  wire [FIFO_WIDTH-1: 0] din,
    output reg  [FIFO_WIDTH-1: 0] dout,
    output wire                   full_flag, empty_flag
);  
    reg [FIFO_WIDTH-1: 0] mem [FIFO_DEPTH-1: 0]; 
    reg [ADDR_SIZE: 0] wr_in_addr, rd_from_addr;

    assign full_flag =  (   (wr_in_addr[ADDR_SIZE] != rd_from_addr[ADDR_SIZE]) &&
                            (wr_in_addr[ADDR_SIZE-1:0] == rd_from_addr[ADDR_SIZE-1:0])
                        )?  1: 0;

    assign empty_flag = (wr_in_addr == rd_from_addr)? 1:0;

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            wr_in_addr   <= 0;
            dout <= 0;
            rd_from_addr <= 0;
        end
        else 
        begin
            if (wr_en && (!full_flag) ) 
            begin
                mem[wr_in_addr[ADDR_SIZE-1:0]] <= din;
                wr_in_addr <= wr_in_addr +1;
            end 

            if (rd_en && (!empty_flag)) 
            begin
                dout <= mem[rd_from_addr[ADDR_SIZE-1:0]];
                rd_from_addr <= rd_from_addr +1;
                mem[rd_from_addr[ADDR_SIZE-1:0]] <= 0;
            end
        end
    end

endmodule