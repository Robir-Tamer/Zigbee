/*
********************************** Documentaion *********************************
Author	    : David Sameeh 
Co-Auther   : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud
File	    : QPSK_mapper
Discription : The QPSK Mapper converts the two parallel bit streams from the
              I (In-phase) and Q (Quadrature) paths into complex QPSK symbols. 
              Each pair of I/Q bits is mapped to one of four possible 
              constellation points, represented by a real and imaginary component.
			  mapping table is found in "OPSK_Constallation_Mapping_Logic.txt" file.
              The generated QPSK symbols are then passed to the DQPSK Coding 
              block for differential encoding.			    
*********************************************************************************
*/

module QPSK_mapper (
    input  wire             clk,      // system clock
    input  wire             rst_n,    // synchronous active-low reset
    input  wire             i,        // In-phase input bit
    input  wire             q,        // Quadrature input bit 
    input  wire             i_valid,  // indicates that the input data is valid and enables the block
  
    output reg              valid,    // indicates that the output data is valid and enables the next block
    output reg signed [1:0] out_real, // real component of the mapped QPSK symbol; values: {-1, 0, +1}
    output reg signed [1:0] out_imag  // imaginary component of the mapped QPSK symbol; values: {-1, 0, +1}
);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            valid <= 0;
            out_real  <= 0;
            out_imag  <= 0;
        end

        else if (i_valid) begin
            valid <= 1;
            case ({i,q})
                2'b11: begin out_real <=  1; out_imag <=  0; end 
                2'b10: begin out_real <=  0; out_imag <= -1; end
                2'b01: begin out_real <=  0; out_imag <=  1; end
                2'b00: begin out_real <= -1; out_imag <=  0; end 
            endcase
        end

        else begin
            valid <= 0;
        end 
    end
endmodule