module cache_calc (
    input   logic           i_clk,
    input   logic           i_nreset,

    input   logic           i_srst,
    input   logic           i_en,
    input   logic   [29:0]  i_addr, // [29:8] - tag, [7:5] - block, [4:0] - word
    input   logic           i_wr_ready,
    output  logic           o_miss_cache,
    output  logic   [7:0]   o_mem_addr_cache,
    output  logic   [7:0]   o_mem_addr_load
    );

    logic   [21:0]  addr_tag;
    logic   [2:0]   addr_block;
    logic   [24:0]  addr_tag_block;
    logic   [4:0]   addr_word;
    logic   [2:0]   addr_group;

    logic   [7:0]   hit_tag_block_bus;
    logic   [2:0]   num_hit_tag_block;
    logic           hit_tag_block;
    logic           miss_tag_block;
    logic           miss_word_group;

    logic           reliability_full;
    logic           lru_bit_replace_en;
    logic           miss_block0;
    logic           hit_block0;
    logic           replace_block0;
    logic           miss_block1;
    logic           hit_block1;
    logic           replace_block1;
    logic           miss_block2;
    logic           hit_block2;
    logic           replace_block2;
    logic           miss_block3;
    logic           hit_block3;
    logic           replace_block3;
    logic           miss_block4;
    logic           hit_block4;
    logic           replace_block4;
    logic           miss_block5;
    logic           hit_block5;
    logic           replace_block5;
    logic           miss_block6;
    logic           hit_block6;
    logic           replace_block6;
    logic           miss_block7;
    logic           hit_block7;
    logic           replace_block7;
    logic   [6:0]   lru_bit;
    logic   [2:0]   num_fetch_block;

    logic   [24:0]  tag_block_mem [7:0];
    logic   [2:0]   addr_load_block;
    logic   [4:0]   addr_load_word;
    logic   [2:0]   dust_mem_sel_group;
    logic   [7:0]   dust_mem [7:0];

    assign addr_tag = i_addr[29:8];
    assign addr_block = i_addr[7:5];
    assign addr_tag_block = {addr_tag, addr_block};
    assign addr_word = i_addr[4:0];
    assign addr_group = addr_word[4:2];

    // Miss managment
    generate
    genvar i;
    for (i = 0; i < 8; i ++) begin: hit_gen
        assign hit_tag_block_bus[i] = i_en && tag_block_mem[i] == addr_tag_block;
    end endgenerate

    always_comb
        casex (hit_tag_block_bus)
            8'bxxxx_xxx1: num_hit_tag_block = 3'd0;
            8'bxxxx_xx10: num_hit_tag_block = 3'd1;
            8'bxxxx_x100: num_hit_tag_block = 3'd2;
            8'bxxxx_1000: num_hit_tag_block = 3'd3;
            8'bxxx1_0000: num_hit_tag_block = 3'd4;
            8'bxx10_0000: num_hit_tag_block = 3'd5;
            8'bx100_0000: num_hit_tag_block = 3'd6;
            8'b1000_0000: num_hit_tag_block = 3'd7;
            default: num_hit_tag_block = 3'd0;
        endcase

    assign hit_tag_block = |hit_tag_block_bus;
    assign miss_tag_block = i_en & !hit_tag_block;
    assign miss_word_group = i_en && dust_mem[num_hit_tag_block][addr_group] == 1'b0;
    assign o_miss_cache = miss_tag_block | miss_word_group;

    // Cache management
    assign lru_bit_replace_en = i_en;

    assign miss_block0 = miss_tag_block & !lru_bit[6] & !lru_bit[4] & !lru_bit[0];
    assign hit_block0 = i_en && hit_tag_block && num_hit_tag_block == 'd0;
    assign replace_block0 = lru_bit_replace_en & (miss_block0 | hit_block0);

    assign miss_block1 = miss_tag_block & miss_tag_block & !lru_bit[6] & !lru_bit[4] & lru_bit[0];
    assign hit_block1 = i_en && hit_tag_block && num_hit_tag_block == 'd1;
    assign replace_block1 = lru_bit_replace_en & (miss_block1 | hit_block1);

    assign miss_block2 = miss_tag_block & !lru_bit[6] & lru_bit[4] & !lru_bit[1];
    assign hit_block2 = i_en && hit_tag_block && num_hit_tag_block == 'd2;
    assign replace_block2 = lru_bit_replace_en & (miss_block2 | hit_block2);

    assign miss_block3 = miss_tag_block & !lru_bit[6] & lru_bit[4] & lru_bit[1];
    assign hit_block3 = i_en && hit_tag_block && num_hit_tag_block == 'd3;
    assign replace_block3 = lru_bit_replace_en & (miss_block3 | hit_block3);

    assign miss_block4 = miss_tag_block & lru_bit[6] & !lru_bit[5] & !lru_bit[2];
    assign hit_block4 = i_en && hit_tag_block && num_hit_tag_block == 'd4;
    assign replace_block4 = lru_bit_replace_en & (miss_block4 | hit_block4);

    assign miss_block5 = miss_tag_block & lru_bit[6] & !lru_bit[5] & lru_bit[2];
    assign hit_block5 = i_en && hit_tag_block && num_hit_tag_block == 'd5;
    assign replace_block5 = lru_bit_replace_en & (miss_block5 | hit_block5);

    assign miss_block6 = miss_tag_block & lru_bit[6] & lru_bit[5] & !lru_bit[3];
    assign hit_block6 = i_en && hit_tag_block && num_hit_tag_block == 'd6;
    assign replace_block6 = lru_bit_replace_en & (miss_block6 | hit_block6);

    assign miss_block7 = miss_tag_block & lru_bit[6] & lru_bit[5] & lru_bit[3];
    assign hit_block7 = i_en && hit_tag_block && num_hit_tag_block == 'd7;
    assign replace_block7 = lru_bit_replace_en & (miss_block7 | hit_block7);

    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) lru_bit <= 'd0;
        else if (i_srst) lru_bit <= 'd0;
        else if (replace_block0) begin
            lru_bit[6] <= 1'b1;
            lru_bit[4] <= 1'b1;
            lru_bit[0] <= 1'b1;
        end
        else if (replace_block1) begin
            lru_bit[6] <= 1'b1;
            lru_bit[4] <= 1'b1;
            lru_bit[0] <= 1'b0;
        end
        else if (replace_block2) begin
            lru_bit[6] <= 1'b1;
            lru_bit[4] <= 1'b0;
            lru_bit[1] <= 1'b1;
        end
        else if (replace_block3) begin
            lru_bit[6] <= 1'b1;
            lru_bit[4] <= 1'b0;
            lru_bit[1] <= 1'b0;
        end
        else if (replace_block4) begin
            lru_bit[6] <= 1'b0;
            lru_bit[5] <= 1'b1;
            lru_bit[2] <= 1'b1;
        end
        else if (replace_block5) begin
            lru_bit[6] <= 1'b0;
            lru_bit[5] <= 1'b1;
            lru_bit[2] <= 1'b0;
        end
        else if (replace_block6) begin
            lru_bit[6] <= 1'b0;
            lru_bit[5] <= 1'b0;
            lru_bit[3] <= 1'b1;
        end
        else if (replace_block7) begin
            lru_bit[6] <= 1'b0;
            lru_bit[5] <= 1'b0;
            lru_bit[3] <= 1'b0;
        end

    always_comb
        casex (lru_bit)
            7'b0x0_xxx0: num_fetch_block = 3'd0;
            7'b0x0_xxx1: num_fetch_block = 3'd1;
            7'b0x1_xx0x: num_fetch_block = 3'd2;
            7'b0x1_xx1x: num_fetch_block = 3'd3;
            7'b10x_x0xx: num_fetch_block = 3'd4;
            7'b10x_x1xx: num_fetch_block = 3'd5;
            7'b11x_0xxx: num_fetch_block = 3'd6;
            7'b11x_1xxx: num_fetch_block = 3'd7;
            default: num_fetch_block = 3'd0;
        endcase

    // Associative memory
    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) for (int i = 0; i < 8; i ++) tag_block_mem[i] <= 'd0;
        else if (i_srst) for (int i = 0; i < 8; i ++) tag_block_mem[i] <= 'd0;
        else if (miss_tag_block) tag_block_mem[num_fetch_block] <= addr_tag_block;

    assign addr_load_block = o_mem_addr_load[7:5];
    assign addr_load_word = o_mem_addr_load[4:0];
    assign dust_mem_sel_group = addr_load_word[4:2];
    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) for (int i = 0; i < 8; i ++) dust_mem[i] <= 'd0;
        else if (i_srst) for (int i = 0; i < 8; i ++) dust_mem[i] <= 'd0;
        else if (miss_tag_block) dust_mem[num_fetch_block] <= 'd0;
        else if (i_wr_ready) dust_mem[addr_load_block][dust_mem_sel_group] <= 1'b1;

    // Memory address
    assign o_mem_addr_cache = {num_hit_tag_block, addr_word};
    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) o_mem_addr_load <= 'd0;
        else if (i_srst) o_mem_addr_load <= 'd0;
        else if (i_en && miss_tag_block) o_mem_addr_load <= {num_fetch_block, addr_word};
        else if (i_en && miss_word_group) o_mem_addr_load <= {num_hit_tag_block, addr_word};

endmodule
