/*
    FIFO is memory structure that stores and retrieves data 
    elements in the order they were added. The FIFO memory will 
    be designed to have two main operations: writing (enqueuing) data 
    and reading (dequeuing) data
*/

module FIFO_mem #(
    parameter  FIFO_WIDTH = 16,
    parameter  FIFO_DEPTH = 512,
    localparam ADDR_SIZE  = $clog2(FIFO_DEPTH)
) (
    input  wire                   clk,  
    input  wire                   rst,     // synch active-high
    input  wire                   wr_en,   // active-high enable writing din in FIFO if it is not full
    input  wire                   rd_en,   // active-high enable reading data from FIFO if it is not empty 
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

    // Write port logic
    always @(posedge clk) begin
        if (rst) begin
            wr_in_addr   <= 0;
            dout <= 0;
            rd_from_addr <= 0;
        end
        else begin
            if (wr_en && (!full_flag) ) begin
                mem[wr_in_addr[ADDR_SIZE-1:0]] <= din;
                wr_in_addr <= wr_in_addr +1;
            end 

            if (rd_en && (!empty_flag)) begin
                dout <= mem[rd_from_addr[ADDR_SIZE-1:0]];
                rd_from_addr <= rd_from_addr +1;
                mem[rd_from_addr[ADDR_SIZE-1:0]] <= 8'h00;
            end
        end
    end
endmodule