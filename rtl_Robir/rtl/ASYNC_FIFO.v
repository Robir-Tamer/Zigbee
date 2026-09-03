/*
********************************** Documentaion *********************************
*Author	:Robir Tamer															*
*File	:ASYNC_FIFO 															*
*********************************************************************************
*/

module ASYNC_FIFO #(
/********************************** Parameters *********************************/
    parameter Width  = 8,
    parameter Depth  = 128,
    parameter Stages = 2,
    parameter ptr_Width =$clog2(Depth)+1,
    parameter addr_Width =$clog2(Depth)+1,
    parameter allow_overwrite = 0           // 1 >>>> allow overwriting , 0 >>>> don't allow over writing
)(
/************************************ Inputs ***********************************/
    input   wire                    W_CLK,
    input   wire                    W_RST,
    input   wire                    W_INC,
    input   wire                    R_CLK,
    input   wire                    R_RST,
    input   wire                    R_INC,
    input   wire    [Width-1 : 0]   WR_DATA,
    input   wire                    ien,
    input   wire     [Width-1 : 0]  high_water_level,
    input   wire     [Width-1 : 0]  low_water_level,
/*********************************** Outputs ***********************************/
    output  wire                    FULL,
    output  wire                    nFULL,
    output  wire                    EMPTY,
    output  wire                    nEMPTY,
    output  wire    [Width-1 : 0]   RD_DATA,
    output  wire                    of,
    output  wire    [Width-1 : 0]   occupancy,      // ramaining elements in the FIFO
    output  wire                    high_water,
    output  wire                    low_water,
    output  wire                    underrun
);
/************************************ Signals **********************************/

wire    [addr_Width-1 : 0]  WR_ADDR;    
wire    [addr_Width-1 : 0]  RD_ADDR;    
wire    [ptr_Width-1 : 0]   W_ptr,R_ptr;
wire    [ptr_Width-1 : 0]   rq2_W_ptr,wq2_R_ptr;
/********************************* Instantiation *******************************/
/**** MEMORY HANDLING SECTION ****/
generate
    if (allow_overwrite == 0)
        begin
            wire                        WR_EN;
            FIFO_MEM_CNTRL #(.Width (Width), .Depth (Depth)) RAM (
                .CLK        (W_CLK),
                .RST        (W_RST),
                .WR_EN      (WR_EN),
                .EMPTY      (EMPTY),
                .WR_DATA    (WR_DATA),
                .WR_ADDR    (WR_ADDR[ptr_Width-2:0]),
                .RD_ADDR    (RD_ADDR[ptr_Width-2:0]),
                .RD_DATA    (RD_DATA)
            );
            EN_LOGIC Enable(
                .A  (W_INC),
                .B  (FULL),
                .EN (WR_EN)
            );
        end
    else
        begin
            FIFO_MEM_CNTRL #(.Width (Width), .Depth (Depth)) RAM (
                .CLK        (W_CLK),
                .RST        (W_RST),
                .WR_EN      (W_INC),
                .EMPTY      (EMPTY),
                .WR_DATA    (WR_DATA),
                .WR_ADDR    (WR_ADDR[ptr_Width-2:0]),
                .RD_ADDR    (RD_ADDR[ptr_Width-2:0]),
                .RD_DATA    (RD_DATA)
            );
        end
endgenerate

/**** Syncronizers ****/
DF_SYNC #(.Stages (Stages), .Depth (Depth)) W2R(
    .CLK    (R_CLK),
    .RST    (R_RST),
    .DATA   (W_ptr),
    .OUT    (rq2_W_ptr)
);
DF_SYNC #(.Stages (Stages), .Depth (Depth)) R2W(
    .CLK    (W_CLK),
    .RST    (W_RST),
    .DATA   (R_ptr),
    .OUT    (wq2_R_ptr)
);
/**** FIFO Write ****/
FIFO_WR #(.Stages (Stages), .Depth (Depth)) Write (
    .CLK                (W_CLK),
    .RST                (W_RST),
    .Winc               (W_INC),
    .wq2_R_ptr          (wq2_R_ptr),
    .ien                (ien),
    .high_water_level   (high_water_level),
    .low_water_level    (low_water_level),
    .W_ptr              (W_ptr),
    .W_ADDR             (WR_ADDR),
    .FULL               (FULL),
    .nFULL               (nFULL),
    .of                 (of),
    .high_water         (high_water),
    .low_water         (low_water),
    .occupancy          (occupancy)
);      
/**** FIFO Read ****/
FIFO_RD #(.Stages (Stages), .Depth (Depth)) Read (
    .CLK        (R_CLK),
    .RST        (R_RST),
    .Rinc       (R_INC),
    .rq2_W_ptr  (rq2_W_ptr),
    .ien        (ien),
    .R_ptr      (R_ptr),
    .R_ADDR     (RD_ADDR),
    .EMPTY      (EMPTY),
    .nEMPTY     (nEMPTY),
    .underrun   (underrun)
);
endmodule