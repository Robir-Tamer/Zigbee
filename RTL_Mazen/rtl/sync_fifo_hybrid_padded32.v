/*
********************************** Documentation *********************************
*Author : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File   : sync_fifo                                                             *
*********************************************************************************
*/

module sync_fifo_hybrid_padded32 #(
    parameter      rate_mode  = "H", 
    parameter      FIFO_WIDTH = (rate_mode == "F") ? 4 : 32, // 4 for 1 Mbps, 32 for 250 Kbps
    parameter      FIFO_DEPTH = (rate_mode == "F") ? 64 : 1024, // 64 for 1 Mbps, 1024 for 250 Kbps
    localparam     ADDR_SIZE  = $clog2(FIFO_DEPTH)
) (
    input  wire                   clk, rst, mode, wr_en, rd_en, 
    input  wire  [FIFO_WIDTH-1:0] din,
    output reg   [FIFO_WIDTH-1:0] dout,
    output wire                   full_flag, 
    output wire                   empty_flag
);  

    reg [FIFO_WIDTH-1:0] mem [FIFO_DEPTH-1:0]; 
    
    reg [ADDR_SIZE:0] wr_in_addr, rd_from_addr;

    wire [FIFO_WIDTH-1:0] padded_din;

    generate
        if (rate_mode == "H") begin : gen_hybrid_padding
            assign padded_din = mode ? {{ (FIFO_WIDTH - 4){1'b0} }, din[3:0]} : din;
        end 
        else begin : gen_normal_din
            assign padded_din = din;
        end
    endgenerate

    assign full_flag  = ( (wr_in_addr[ADDR_SIZE]   != rd_from_addr[ADDR_SIZE]) &&
                          (wr_in_addr[ADDR_SIZE-1:0] == rd_from_addr[ADDR_SIZE-1:0]) );

    assign empty_flag = (wr_in_addr == rd_from_addr);

    always @(posedge clk)  
    begin
        if (rst)  
        begin
            wr_in_addr   <= {(ADDR_SIZE+1){1'b0}};
            rd_from_addr <= {(ADDR_SIZE+1){1'b0}};
            dout         <= {FIFO_WIDTH{1'b0}};
        end 
        else  
        begin
            if (wr_en && !full_flag)  
            begin
                mem[wr_in_addr[ADDR_SIZE-1:0]] <= padded_din;
                wr_in_addr <= wr_in_addr + 1'b1;
            end  

            if (rd_en && !empty_flag)  
            begin
                dout <= mem[rd_from_addr[ADDR_SIZE-1:0]];
                rd_from_addr <= rd_from_addr + 1'b1;
            end 
        end
    end

endmodule