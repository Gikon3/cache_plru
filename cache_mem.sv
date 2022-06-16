module cache_mem (
    input   logic           i_clk,
    input   logic           i_nreset,

    input   logic           i_enable,
    input   logic           i_write,
    input   logic   [7:0]   i_addr,
    input   logic   [31:0]  i_data,
    output  logic   [31:0]  o_data
    );

    logic   [7:0]   addr;
    logic   [31:0]  data_in;
    logic           enable;
    logic           write;
`ifndef FPGA
    assign #1 addr = i_addr;
    assign #1 data_in = i_data;
    assign #1 enable = i_enable;
    assign #1 write = i_write;

    SP_256x32m8_M3 mem (
        .Q (o_data),
        .A (addr),
        .D (data_in),
        .M (32'h0000_0000),
        .CK (i_clk),
        .CSN (!enable),
        .WEN (!write),
        .OEN (1'b0)
        );
`else
     logic   [31:0]  memory  [255:0];

     //always_latch
     always @(posedge i_clk)
         if (!i_clk && i_nreset && i_write) memory[i_addr] <= i_data;
     assign o_data = memory[i_addr];
`endif	 
endmodule
