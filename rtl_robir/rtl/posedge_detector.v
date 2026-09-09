module posedge_detector (
    input   wire  clk,
    input   wire  rst_n,
    input   wire  in,

    output  wire out
);

reg delayed_in;
always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
                delayed_in <= 'b0;
            end
        else
            begin
                delayed_in <= in;
            end
    end

assign out = in && !delayed_in;
endmodule