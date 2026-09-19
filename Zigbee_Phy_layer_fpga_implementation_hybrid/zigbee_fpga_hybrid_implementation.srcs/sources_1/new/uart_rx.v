module uart_rx #(
    parameter CLK_FREQ  = 32000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg [7:0]  data_out,
    output reg        data_vld
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    localparam [1:0] S_IDLE  = 2'b00,
                     S_START = 2'b01,
                     S_DATA  = 2'b10,
                     S_STOP  = 2'b11;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift_reg;
    
    reg rx_sync_1;
    reg rx_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            rx_sync_1 <= 1'b1;
            rx_reg    <= 1'b1;
        end else begin
            rx_sync_1 <= rx;
            rx_reg    <= rx_sync_1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            clk_count    <= 0;
            bit_index    <= 0;
            data_out     <= 0;
            data_vld     <= 1'b0;
            rx_shift_reg <= 0;
        end else begin
            data_vld <= 1'b0; 
            
            case (state)
                S_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_reg == 1'b0) 
                        state <= S_START;
                end
                
                S_START: begin
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_reg == 1'b0) begin
                            clk_count <= 0;
                            state     <= S_DATA;
                        end else begin
                            state     <= S_IDLE; 
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                
                S_DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_shift_reg[bit_index] <= rx_reg;
                        
                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= S_STOP;
                        end
                    end
                end
                
                S_STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        if (rx_reg == 1'b1) begin 
                            data_out <= rx_shift_reg;
                            data_vld <= 1'b1;
                        end
                        state <= S_IDLE;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule