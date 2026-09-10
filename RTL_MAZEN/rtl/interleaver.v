/*
********************************** Documentaion *********************************
*Author	:Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud, David Sameeh *
*File	:interleaver  															    *
*********************************************************************************
*/
module interleaver (
    input             clk, rst, i_valid, 
    input      [31:0] i_data, 
    output reg [63:0] o_data,
    output reg        o_valid
);

reg [31:0] lower_half;
// output of symbol_mapper is 32 bits , while input of interleaver is 64 bits
reg cycle_flag;

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        lower_half <= 32'b0;
        cycle_flag <= 1'b0;
        o_data     <= 64'b0;
        o_valid    <= 1'b0;
    end 
    else 
    begin
        if (i_valid) 
        begin
            if (!cycle_flag) 
            begin
                lower_half <= i_data;
                cycle_flag <= 1'b1;
                o_valid    <= 1'b0;
            end 
            else 
            begin
                cycle_flag <= 1'b0;
                o_data <= {
                    lower_half[3:0],   // G0
                    i_data[23:20],     // G13
                    lower_half[11:8],  // G2
                    i_data[31:28],     // G15
                    lower_half[19:16], // G4
                    i_data[7:4],       // G9
                    lower_half[27:24], // G6
                    i_data[15:12],     // G11
                    i_data[3:0],       // G8
                    lower_half[23:20], // G5
                    i_data[11:8],      // G10
                    lower_half[31:28], // G7
                    i_data[19:16],     // G12
                    lower_half[7:4],   // G1
                    i_data[27:24],     // G14
                    lower_half[15:12]  // G3
                };
                o_valid <= 1'b1;
            end
        end 
        else 
        begin
            o_valid <= 1'b0;
        end
    end
end

endmodule
