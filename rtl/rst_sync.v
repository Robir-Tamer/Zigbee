module rst_sync #(
    parameter Stages = 2
)(
    input   rst_n,
    input   clk,
    output  rst_n_sync 
);

DF_SYNC #(.Stages(Stages), .Width (1)) RDC (
    .DATA       (1'b1),
    .CLK        (clk),
    .RST        (rst_n),
    .OUT        (rst_n_sync)
);

endmodule