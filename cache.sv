module cache (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB-Mem interface
    input   logic           i_hsel_m,

    input   logic   [31:0]  i_haddr_m,
    input   logic           i_hwrite_m,
    input   logic   [ 2:0]  i_hsize_m,
    input   logic   [ 2:0]  i_hburst_m,
    input   logic   [ 3:0]  i_hprot_m,
    input   logic   [ 1:0]  i_htrans_m,
    input   logic           i_hmastlock_m,
    input   logic           i_hready_m,
    input   logic   [31:0]  i_hwdata_m,

    output  logic           o_hready_m,
    output  logic           o_hresp_m,
    output  logic   [31:0]  o_hrdata_m,

    // Cache config signals
    input   logic           i_nbypass,
    input   logic   [31:0]  i_climit,
    input   logic           i_prefetch_dis,
    input   logic           i_d_cache_en,

    // AHB-out intrface
    output  logic           o_hsel_sl,
    output  logic           o_hready_i_sl,
    output  logic   [31:0]  o_haddr_sl,
    output  logic           o_hwrite_sl,
    output  logic   [2:0]   o_hsize_sl,
    output  logic   [2:0]   o_hburst_sl,
    output  logic   [3:0]   o_hprot_sl,
    output  logic   [1:0]   o_htrans_sl,
    output  logic           o_hmastlock_sl,
    output  logic   [31:0]  o_hwdata_sl,
    input   logic   [31:0]  i_hrdata_sl,
    input   logic           i_hready_o_sl,
    input   logic           i_hresp_sl
    );

    logic           miss_cache;
    logic           calc_sync_rst;
    logic           calc_en;
    logic   [29:0]  calc_addr;
    logic           calc_wr_rdy;
    logic   [7:0]   calc_mem_addr_cache;
    logic   [7:0]   calc_mem_addr_load;
    logic   [31:0]  mem_rdata;
    logic           mem_en;
    logic           mem_we;
    logic   [7:0]   mem_addr;

    cache_ahb_ctrl_mem cache_ahb_ctrl_mem (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_hsel (i_hsel_m),
        .i_haddr (i_haddr_m),
        .i_hwrite (i_hwrite_m),
        .i_hsize (i_hsize_m),
        .i_hburst (i_hburst_m),
        .i_hprot (i_hprot_m),
        .i_htrans (i_htrans_m),
        .i_hmastlock (i_hmastlock_m),
        .i_hready (i_hready_m),
        .i_hwdata (i_hwdata_m),
        .o_hready (o_hready_m),
        .o_hresp (o_hresp_m),
        .o_hrdata (o_hrdata_m),

        .i_nbypass (i_nbypass),
        .i_d_cache_en (i_d_cache_en),
        .i_climit (i_climit),
        .i_prefetch_dis (i_prefetch_dis),

        .i_miss_cache (miss_cache),
        .i_calc_addr_cache (calc_mem_addr_cache),
        .i_calc_addr_load (calc_mem_addr_load),
        .o_calc_srst (calc_sync_rst),
        .o_calc_en (calc_en),
        .o_calc_wr_rdy (calc_wr_rdy),
        .o_calc_addr (calc_addr),

        .i_sl_hready (i_hready_o_sl),
        .i_sl_hresp (i_hresp_sl),
        .i_sl_hrdata (i_hrdata_sl),
        .o_sl_hsel (o_hsel_sl),
        .o_sl_haddr (o_haddr_sl),
        .o_sl_hwrite (o_hwrite_sl),
        .o_sl_hsize (o_hsize_sl),
        .o_sl_hburst (o_hburst_sl),
        .o_sl_hprot (o_hprot_sl),
        .o_sl_htrans (o_htrans_sl),
        .o_sl_hmastlock (o_hmastlock_sl),
        .o_sl_hready (o_hready_i_sl),
        .o_sl_hwdata (o_hwdata_sl),

        .i_mem_rdata (mem_rdata),
        .o_mem_en (mem_en),
        .o_mem_we (mem_we),
        .o_mem_addr (mem_addr)
        );

    cache_calc cache_calc (
        .i_clk (i_hclk),
        .i_nreset (i_hnreset),

        .i_srst (calc_sync_rst),
        .i_en (calc_en),
        .i_addr (calc_addr),
        .i_wr_ready (calc_wr_rdy),
        .o_miss_cache (miss_cache),
        .o_mem_addr_cache (calc_mem_addr_cache),
        .o_mem_addr_load (calc_mem_addr_load)
        );

    cache_mem cache_mem(
        .i_clk (i_hclk),
        .i_nreset (i_hnreset),

        .i_enable (mem_en),
        .i_write (mem_we),
        .i_addr (mem_addr),
        .i_data (i_hrdata_sl),
        .o_data (mem_rdata)
        );

endmodule
