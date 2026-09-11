/*
********************************** Documentaion *********************************
Author	    : David Sameeh 
Co-Auther   : Robir Tamer, Anas Abo-Lila, Sherief Ahmad, Mazen Mahmoud
File	    : controller.v
Discription : The controlle block: trigers the enable signals for different blocks.
              It also decides which sending mode is used if parameter "rate_mode" = 'H' 
              depending on the input start_tx:
               * if "start_tx" is asserted for 1 clock cycle --> 1 Mbps (mode = 1)
               * if "start_tx" is asserted for 2 clock cycles --> 250 Kbps (mode = 0)
*********************************************************************************
*/

module controller #(
    parameter rate_mode = "F", // S --> 250 Kbps, F --> 1 Mbps, H --> Hybrid
    parameter max_payload_length =127
) (
    input clk,
    input rst_n,    // synchronous Active-low reset.
    input start_tx, // indecates the start of sending operation.
    input tx_end,   // indecates the end of sending operation, system goes to idle state
    input   wire    [$clog2(max_payload_length)-1 : 0]  payload_length,
    input fifo_empty,
    input demux_valid,
    input interleaver_valid,

    output wire mode,
    output wire zero_pad_en
);
    reg idle_flage; // indecate if the system is in idle state
    assign zero_pad_en = !idle_flage; 

    generate
        // ------------------------------ Slow Data-Rate: 250 Kbps -------------------------------
        if (rate_mode == "S") begin      : slow_rate_250Kbps
            assign mode = 0;                

            always @(posedge clk) begin
                if      (!rst_n)   begin idle_flage <= 1'b1; end 
                else if (tx_end)   begin idle_flage <= 1'b1; end 
                else if (start_tx) begin idle_flage <= 1'b0; end
            end
        end

        // ------------------------------- Fast Data-Rate: 1 Mbps --------------------------------
        else if (rate_mode == "F") begin  : fast_rate_1Mbps
            assign mode = 1;                

            always @(posedge clk) begin
                if      (!rst_n)   begin idle_flage <= 1'b1; end 
                else if (tx_end)   begin idle_flage <= 1'b1; end 
                else if (start_tx) begin idle_flage <= 1'b0; end
            end
        end

        // -------------------------- Default generate: Hybrid Data-Rate -------------------------
        else begin  : hybrid_mode
            reg [1:0] counter_for_mode_detection; // 1--> 1 Mbps (mode = 1),  2--> 250 Kbps (mode = 0)

            always @(posedge clk) begin
                if (!rst_n) begin
                    counter_for_mode_detection <= 0;
                    idle_flage <= 1;
                end  

                else if (tx_end) begin
                    counter_for_mode_detection <= 0;
                    idle_flage <= 1;
                end

                else if (start_tx) begin 
                    counter_for_mode_detection <= counter_for_mode_detection +1;
                    idle_flage <= 0;
                end
            end

            assign mode = (counter_for_mode_detection == 0)? 1'b0:
                          ((start_tx == 0) && (counter_for_mode_detection == 1))? 1'b1:
                          ((start_tx == 0) && (counter_for_mode_detection == 2))? 1'b0 : 1'b0;
        end
    endgenerate
endmodule


// Intantiation Templte

// controller #(
//     .rate_mode()
// ) my_controller (
//     .clk                (),
//     .rst_n              (),
//     .start_tx           (),
//     .tx_end             (),
//     .payload_length     (),
//     .fifo_empty         (),
//     .demux_valid        (),
//     .interleaver_valid  (),

//     .mode               (),
//     .zero_pad_en        ()
// );