module cache_ahb_ctrl_mem (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB interface
    input   logic           i_hsel,

    input   logic   [31:0]  i_haddr,
    input   logic           i_hwrite,
    input   logic   [ 2:0]  i_hsize,
    input   logic   [ 2:0]  i_hburst,
    input   logic   [ 3:0]  i_hprot,
    input   logic   [ 1:0]  i_htrans,
    input   logic           i_hmastlock,
    input   logic           i_hready,
    input   logic   [31:0]  i_hwdata,

    output  logic           o_hready,
    output  logic           o_hresp,
    output  logic   [31:0]  o_hrdata,

    // Cache config signals
    input   logic           i_nbypass,
    input   logic           i_d_cache_en,
    input   logic   [31:0]  i_climit,
    input   logic           i_prefetch_dis,

    // Calc signals
    input   logic           i_miss_cache,
    input   logic   [7:0]   i_calc_addr_cache,
    input   logic   [7:0]   i_calc_addr_load,
    output  logic           o_calc_srst,
    output  logic           o_calc_en,
    output  logic           o_calc_wr_rdy,
    output  logic   [29:0]  o_calc_addr,

    // Slave signals
    input   logic           i_sl_hready,
    input   logic           i_sl_hresp,
    input   logic   [31:0]  i_sl_hrdata,

    output  logic           o_sl_hsel,
    output  logic   [31:0]  o_sl_haddr,
    output  logic           o_sl_hwrite,
    output  logic   [2:0]   o_sl_hsize,
    output  logic   [2:0]   o_sl_hburst,
    output  logic   [3:0]   o_sl_hprot,
    output  logic   [1:0]   o_sl_htrans,
    output  logic           o_sl_hmastlock,
    output  logic           o_sl_hready,
    output  logic   [31:0]  o_sl_hwdata,

    // Mem signals
    input   logic   [31:0]  i_mem_rdata,
    output  logic           o_mem_en,
    output  logic           o_mem_we,
    output  logic   [7:0]   o_mem_addr
    );

    enum logic [3:0] {IDLE, READ_CACHE, PREREAD_FLASH, READ_FLASH,
                      POST_FLASH, READ_POST_FLASH, PREF_ADDR, PREF_DATA,
                      PRETHROUGH, THROUGH} state_list;

    logic           cache_area;
    logic           cache_en;

    logic           request;
    logic           request_read;
    logic           request_read_ready;
    logic           request_reg;
    logic   [31:0]  haddr;
    logic           hwrite;
    logic   [ 2:0]  hsize;
    logic   [ 2:0]  hburst;
    logic   [ 3:0]  hprot;
    logic   [ 1:0]  htrans;
    logic           hmastlock;
    logic   [31:0]  hwdata;

    logic           switch_read_cache;
    logic           switch_preread_flash;
    logic           switch_read_flash;
    logic           switch_pref_addr_pref;
    logic           switch_pref_addr;
    logic           switch_pref_data;
    logic           switch_prethrough;
    logic           switch_through;
    logic   [3:0]   current_state;
    logic   [3:0]   next_state;
    logic           state_idle;
    logic           state_read_cache;
    logic           state_preread_flash;
    logic           state_read_flash;
    logic           state_post_flash;
    logic           state_read_post_flash;
    logic           state_pref_addr;
    logic           state_pref_data;
    logic           state_pretrough;
    logic           state_through;

    logic           gen_addr_rst_flash;
    logic           gen_addr_rst_pref;
    logic           gen_addr_rst;
    logic           gen_addr_set_1;
    logic           gen_addr_inc_flash;
    logic           gen_addr_inc_pref;
    logic           gen_addr_inc;
    logic   [1:0]   gen_addr;
    logic           gen_addr_full;

    logic           mem_gen_addr_rst;
    logic           mem_gen_addr_replace;
    logic   [1:0]   mem_gen_addr;
    logic           mem_gen_addr_full;

    logic           pref_glob_en;
    logic           pref_glob_en_rst;
    logic           pref_full_frame_set;
    logic           pref_full_frame_rst;
    logic           pref_full_frame;
    logic           pref_haddr_full;
    logic           pref_addr_inc_addr;
    logic           pref_addr_inc_data;
    logic           pref_addr_inc;
    logic   [2:0]   pref_addr;
    logic   [27:0]  pref_addr_comb;
    logic           pref_addr_full;
    logic           pref_calc_en;

    logic           mux_request_read;
    logic           mux_read_flash;
    logic           mux_through;
    logic           mux_pref;

    logic           nbypass_reg;

    // signals
    assign cache_area = i_haddr < i_climit;
    assign cache_en = i_nbypass & cache_area & (!i_hprot[0] | (i_hprot[0] & i_d_cache_en));

    // AHB-Control
    assign request = i_hsel & i_htrans[1] & i_hready;
    assign request_read = request & !i_hwrite & cache_en;
    assign request_read_ready = request_read & o_hready;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) request_reg <= 'd0;
        else request_reg <= request;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) haddr <= 'd0;
        else if (request) haddr <= i_haddr;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hwrite <= 'd0;
        else if (request) hwrite <= i_hwrite;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hsize <= 'd0;
        else if (request) hsize <= i_hsize;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hburst <= 'd0;
        else if (request) hburst <= i_hburst;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hprot <= 'd0;
        else if (request) hprot <= i_hprot;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) htrans <= 'd0;
        else if (request) htrans <= i_htrans;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hmastlock <= 'd0;
        else if (request) hmastlock <= i_hmastlock;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hwdata <= 'd0;
        else if (request_reg) hwdata <= i_hwdata;

    assign o_hready = !state_pretrough & !state_through & !state_preread_flash & !state_read_flash & !state_post_flash
                      | (state_through & i_sl_hready);
    assign o_hresp = state_through ? i_sl_hresp: 1'b0;
    assign o_hrdata = state_read_cache || state_read_post_flash ? i_mem_rdata:
                      state_through ? i_sl_hrdata: 'd0;

    // State machine
    assign switch_read_cache = request_read_ready & !i_miss_cache;
    assign switch_preread_flash = request_read_ready & i_miss_cache & !i_sl_hready;
    assign switch_read_flash = request_read_ready & i_miss_cache & i_sl_hready;
    assign switch_pref_addr_pref = pref_glob_en & !pref_addr_full & !pref_haddr_full;
    assign switch_pref_addr = state_idle & i_sl_hready & !request & !i_prefetch_dis & i_nbypass & switch_pref_addr_pref;
    assign switch_pref_data = !request & !i_hwrite & i_miss_cache & !gen_addr_full & !i_prefetch_dis & i_nbypass;
    assign switch_prethrough = i_hsel & i_htrans[1] & !cache_en & !i_sl_hready;
    assign switch_through = i_hsel & i_htrans[1] & !cache_en & i_sl_hready;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_prethrough)
                    next_state = PRETHROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_preread_flash)
                    next_state = PREREAD_FLASH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (switch_pref_addr)
                    next_state = PREF_ADDR;
                else
                    next_state = IDLE;
            READ_CACHE:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_prethrough)
                    next_state = PRETHROUGH;
                else if (switch_preread_flash)
                    next_state = PREREAD_FLASH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (!request_read_ready)
                    next_state = IDLE;
                else
                    next_state = READ_CACHE;
            PREREAD_FLASH:
                if (i_sl_hready)
                    next_state = READ_FLASH;
                else
                    next_state = PREREAD_FLASH;
            READ_FLASH:
                if (o_calc_wr_rdy)
                    next_state = POST_FLASH;
                else
                    next_state = READ_FLASH;
            POST_FLASH:
                next_state = READ_POST_FLASH;
            READ_POST_FLASH:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_prethrough)
                    next_state = PRETHROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (!request_read_ready)
                    next_state = IDLE;
                else
                    next_state = READ_FLASH;
            PREF_ADDR:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_prethrough)
                    next_state = PRETHROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_preread_flash)
                    next_state = PREREAD_FLASH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_prefetch_dis || (pref_addr_full && !i_miss_cache))
                    next_state = IDLE;
                else if (switch_pref_data)
                    next_state = PREF_DATA;
                else
                    next_state = PREF_ADDR;
            PREF_DATA:
                if (switch_through)
                    next_state = THROUGH;
                else if (switch_prethrough)
                    next_state = PRETHROUGH;
                else if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_preread_flash)
                    next_state = PREREAD_FLASH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_prefetch_dis || (pref_full_frame && mem_gen_addr_full && o_calc_wr_rdy))
                    next_state = IDLE;
                else if (switch_pref_addr && !i_miss_cache)
                    next_state = PREF_ADDR;
                else
                    next_state = PREF_DATA;
            PRETHROUGH:
                if (i_sl_hready)
                    next_state = THROUGH;
                else
                    next_state = PRETHROUGH;
            THROUGH:
                if (switch_read_cache)
                    next_state = READ_CACHE;
                else if (switch_preread_flash)
                    next_state = PREREAD_FLASH;
                else if (switch_read_flash)
                    next_state = READ_FLASH;
                else if (i_sl_hready && !request)
                    next_state = IDLE;
                else
                    next_state = THROUGH;
            default:
                next_state = IDLE;
        endcase

    assign state_idle = current_state == IDLE;
    assign state_read_cache = current_state == READ_CACHE;
    assign state_preread_flash = current_state == PREREAD_FLASH;
    assign state_read_flash = current_state == READ_FLASH;
    assign state_post_flash = current_state == POST_FLASH;
    assign state_read_post_flash = current_state == READ_POST_FLASH;
    assign state_pref_addr = current_state == PREF_ADDR;
    assign state_pref_data = current_state == PREF_DATA;
    assign state_pretrough = current_state == PRETHROUGH;
    assign state_through = current_state == THROUGH;

    // Generate address
    assign gen_addr_rst_flash = !state_read_flash | (state_read_flash & o_calc_wr_rdy);
    assign gen_addr_rst_pref = !state_pref_addr & !state_pref_data;
    assign gen_addr_rst = !gen_addr_set_1
        & ((switch_read_flash & !i_sl_hready) | (gen_addr_rst_flash & gen_addr_rst_pref));
    assign gen_addr_set_1 = (switch_read_flash | state_preread_flash) & i_sl_hready;
    assign gen_addr_inc_flash = (state_read_flash & i_sl_hready & !mem_gen_addr_full);
    assign gen_addr_inc_pref = (state_pref_addr & i_miss_cache) | (state_pref_data & i_sl_hready & !pref_full_frame);
    assign gen_addr_inc = !gen_addr_rst & !gen_addr_set_1 & (gen_addr_inc_flash | gen_addr_inc_pref);
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) gen_addr <= 'd0;
        else if (gen_addr_rst) gen_addr <= 'd0;
        else if (gen_addr_set_1) gen_addr <= 2'd1;
        else if (gen_addr_inc) gen_addr <= gen_addr + 2'd1;

    assign gen_addr_full = &gen_addr;

    // Memory managment
    assign mem_gen_addr_rst = switch_read_flash | switch_pref_addr;
    assign mem_gen_addr_replace = o_mem_we;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) mem_gen_addr <= 'd0;
        else if (mem_gen_addr_rst) mem_gen_addr <= 'd0;
        else if (mem_gen_addr_replace) mem_gen_addr <= gen_addr;

    assign mem_gen_addr_full = &mem_gen_addr;

    assign o_mem_en = switch_read_cache | o_mem_we | state_post_flash;
    assign o_mem_we = (state_read_flash | state_pref_data) & i_sl_hready;
    always_comb
        casex ({switch_read_cache, state_read_flash, state_post_flash, state_pref_data})
            4'b1xxx: o_mem_addr = i_calc_addr_cache;
            4'b01xx: o_mem_addr = {i_calc_addr_load[7:2], mem_gen_addr};
            4'b001x: o_mem_addr = i_calc_addr_load;
            4'b0001: o_mem_addr = {i_calc_addr_load[7:2], mem_gen_addr};
            default: o_mem_addr = 'd0;
        endcase

    // Prefetch managment
    assign pref_glob_en_rst = state_through | !i_nbypass | i_prefetch_dis;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) pref_glob_en <= 'd0;
        else if (pref_glob_en_rst) pref_glob_en <= 1'b0;
        else if (request_read_ready) pref_glob_en <= 1'b1;

    assign pref_full_frame_set = pref_addr_full & gen_addr_full & gen_addr_inc;
    assign pref_full_frame_rst = mem_gen_addr_full & mem_gen_addr_replace & o_calc_wr_rdy;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) pref_full_frame <= 'd0;
        else if (pref_full_frame_set) pref_full_frame <= 1'b1;
        else if (pref_full_frame_rst) pref_full_frame <= 1'b0;

    assign pref_haddr_full = haddr[6:4] == 3'h7;

    assign pref_addr_inc_addr = state_pref_addr & !i_miss_cache;
    assign pref_addr_inc_data = state_pref_data & gen_addr_full & gen_addr_inc;
    assign pref_addr_inc = (pref_addr_inc_addr | pref_addr_inc_data) & !pref_addr_full;
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) pref_addr <= 'd0;
        else if (switch_pref_addr) pref_addr <= haddr[6:4] + 3'h1;
        else if (pref_addr_inc) pref_addr <= pref_addr + 3'h1;

    assign pref_addr_comb = {haddr[31:7], pref_addr};

    assign pref_addr_full = &pref_addr;
    assign pref_calc_en = !request_read & (state_pref_addr | (state_pref_data & o_calc_wr_rdy & !pref_full_frame));

    // Slave managment
    assign mux_request_read = request_read & i_miss_cache;
    assign mux_read_flash = state_read_flash & !mem_gen_addr_full | state_preread_flash;
    assign mux_through = (switch_through | state_through) & !switch_read_cache;
    assign mux_pref = (state_pref_addr | state_pref_data) & !pref_full_frame;

    always_comb
        casex ({mux_request_read, mux_read_flash, state_pretrough, mux_through, mux_pref})
            5'b1_xxxx:
                begin
                    o_sl_hsel = 1'b1;
                    o_sl_haddr = {i_haddr[31:4], 4'h0};
                    o_sl_hwrite = 1'b0;
                    o_sl_hsize = 3'h2;
                    o_sl_hburst = i_hburst;
                    o_sl_hprot = i_hprot;
                    o_sl_htrans = i_htrans;
                    o_sl_hmastlock = i_hmastlock;
                    o_sl_hready = i_hready & i_sl_hready;
                    o_sl_hwdata = i_hwdata;
                end
            5'b0_1xxx:
                begin
                    o_sl_hsel = !mem_gen_addr_full;
                    o_sl_haddr = {haddr[31:4], gen_addr, 2'h0};
                    o_sl_hwrite = 1'b0;
                    o_sl_hsize = 3'h2;
                    o_sl_hburst = hburst;
                    o_sl_hprot = hprot;
                    o_sl_htrans = htrans;
                    o_sl_hmastlock = hmastlock;
                    o_sl_hready = i_sl_hready;
                    o_sl_hwdata = 32'd0;
                end
            5'b0_01xx:
                begin
                    o_sl_hsel = 1'b1;
                    o_sl_haddr = haddr;
                    o_sl_hwrite = hwrite;
                    o_sl_hsize = hsize;
                    o_sl_hburst = hburst;
                    o_sl_hprot = hprot;
                    o_sl_htrans = htrans;
                    o_sl_hmastlock = hmastlock;
                    o_sl_hready = i_sl_hready;
                    o_sl_hwdata = hwdata;
                end
            5'b0_001x:
                begin
                    o_sl_hsel = i_hsel;
                    o_sl_haddr = i_haddr;
                    o_sl_hwrite = i_hwrite;
                    o_sl_hsize = i_hsize;
                    o_sl_hburst = i_hburst;
                    o_sl_hprot = i_hprot;
                    o_sl_htrans = i_htrans;
                    o_sl_hmastlock = i_hmastlock;
                    o_sl_hready = i_hready;
                    o_sl_hwdata = i_hwdata;
                end
            5'b0_0001:
                begin
                    o_sl_hsel = !pref_full_frame;
                    o_sl_haddr = {pref_addr_comb, gen_addr, 2'h0};
                    o_sl_hwrite = 1'b0;
                    o_sl_hsize = 3'h2;
                    o_sl_hburst = 3'h0;
                    o_sl_hprot = 4'h1;
                    o_sl_htrans = 2'h2;
                    o_sl_hmastlock = 1'b0;
                    o_sl_hready = i_sl_hready;
                    o_sl_hwdata = 32'd0;
                end
            default:
                begin
                    o_sl_hsel = 1'b0;
                    o_sl_haddr = 32'd0;
                    o_sl_hwrite = 1'b0;
                    o_sl_hsize = 3'h0;
                    o_sl_hburst = 3'h0;
                    o_sl_hprot = 4'h0;
                    o_sl_htrans = 2'h0;
                    o_sl_hmastlock = 1'b0;
                    o_sl_hready = i_sl_hready;
                    o_sl_hwdata = 32'd0;
                end
        endcase

    // Calc managment
    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) nbypass_reg <= 'd0;
        else nbypass_reg <= i_nbypass;
    assign o_calc_srst = i_nbypass & !nbypass_reg;

    assign o_calc_en = request_read_ready | pref_calc_en;
    assign o_calc_wr_rdy = mem_gen_addr_full & o_mem_we;
    assign o_calc_addr = request_read_ready ? i_haddr[31:2]: {pref_addr_comb, 2'h0};

endmodule
