module DQPSK (
    input  wire              clk, rst_n, i_valid,
    input  wire signed [1:0] Real, Imag,
    output reg               valid,
    output reg  signed [1:0] Real_o, Imag_o
);

reg signed [1:0] Real_FF [0:3];
reg signed [1:0] Imag_FF [0:3]; 

always @(posedge clk) begin
    if (!rst_n) begin
        Real_FF[0] <= 2'sb01; Real_FF[1] <= 2'sb01; Real_FF[2] <= 2'sb01; Real_FF[3] <= 2'sb01;
        Imag_FF[0] <= 2'sb01; Imag_FF[1] <= 2'sb01; Imag_FF[2] <= 2'sb01; Imag_FF[3] <= 2'sb01;
        Real_o  <= 2'sb00;
        Imag_o  <= 2'sb00;
        valid <= 1'b0;
    end
    else begin
        valid <= i_valid;
        if (i_valid) begin
            // Register calculated output to align with registered valid
            Real_o <= (Real * Real_FF[3]) - (Imag * Imag_FF[3]);
            Imag_o <= (Real * Imag_FF[3]) + (Imag * Real_FF[3]);

            // Shift delay chain using calculated result
            {Real_FF[3], Real_FF[2], Real_FF[1], Real_FF[0]} <= {Real_FF[2], Real_FF[1], Real_FF[0], (Real * Real_FF[3]) - (Imag * Imag_FF[3])}; 
            {Imag_FF[3], Imag_FF[2], Imag_FF[1], Imag_FF[0]} <= {Imag_FF[2], Imag_FF[1], Imag_FF[0], (Real * Imag_FF[3]) + (Imag * Real_FF[3])};  
        end
    end
end

endmodule