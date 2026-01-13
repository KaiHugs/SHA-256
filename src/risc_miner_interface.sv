/*Author: Kai Hughes | 2025
Interface with Miner Integration - External RAM testing

Memory Map:
0x0000_0000 - 0x0000_3FFF: RAM (16KB)
0x8000_0000: Miner Control Register
    bit 0: start
    bit 1: busy (RO)
    bit 2: found (RO)
    bit 3: exhausted (RO)
0x8000_0004: Max Nonce
0x8000_0008: Nonce Output (RO)
0x8000_000C-0x8000_0028: Hash Output Words 0-7 (RO)
0x8000_0030-0x8000_004C: Target Words 0-7
0x8000_0050-0x8000_009C: Header Template (20 words)
*/

module risc_miner_interface (
    input  logic CLOCK_50,
    input  logic rst_n_raw,
    output logic [9:0] leds
);

    logic clk_100;
    logic pll_locked;
    logic pll_areset;
    logic rst_n;
    logic [3:0] reset_counter;
    
    assign pll_areset = ~rst_n_raw;
    
    Clock_100_PLL pll (
        .areset(pll_areset),
        .inclk0(CLOCK_50),
        .c0(clk_100),
        .locked(pll_locked)
    );
    
    always_ff @(posedge clk_100 or negedge rst_n_raw) begin
        if (!rst_n_raw) begin
            reset_counter <= 4'h0;
            rst_n <= 1'b0;
        end else begin
            if (pll_locked) begin
                if (reset_counter != 4'hF) begin
                    reset_counter <= reset_counter + 1'b1;
                    rst_n <= 1'b0;
                end else begin
                    rst_n <= 1'b1;
                end
            end else begin
                reset_counter <= 4'h0;
                rst_n <= 1'b0;
            end
        end
    end


    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0]  mem_wstrb;
    logic mem_valid, mem_ready;

    picorv32 cpu (
        .clk(clk_100),
        .resetn(rst_n),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_wstrb(mem_wstrb),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready)
    );
 
    logic miner_start;
    logic miner_busy;
    logic miner_found;
    logic miner_exhausted;

    logic [31:0] max_nonce_reg;
    logic [639:0] header_template_reg;
    logic [255:0] target_reg;

    logic [31:0] nonce_out;
    logic [255:0] hash_out;

    bitcoin_miner miner (
        .clk(clk_100),
        .rst_n(rst_n),
        .start(miner_start),
        .header_template(header_template_reg),
        .target(target_reg),
        .max_nonce(max_nonce_reg),
        .busy(miner_busy),
        .found(miner_found),
        .exhausted(miner_exhausted),
        .nonce_out(nonce_out),
        .hash_out(hash_out)
    );

 
    logic ram_sel, miner_sel;

    always_comb begin
        ram_sel = (mem_addr[31:16] == 16'h0000);
        miner_sel = (mem_addr[31:16] == 16'h8000);
    end
 
    logic [31:0] ram_rdata;
    logic [11:0] ram_addr;     
    logic ram_wren;
    logic [31:0] ram_q;
    
    assign ram_addr = mem_addr[13:2];  
    assign ram_wren = ram_sel && mem_valid && |mem_wstrb;
    
    // RAM using altsyncram - TEST 1 NO EXTERNAL PROGRAM USING QUARTUS'
    altsyncram #(
        .operation_mode("SINGLE_PORT"),
        .width_a(32),
        .widthad_a(12),
        .numwords_a(4096),
        .outdata_reg_a("UNREGISTERED"),
        .init_file("program.hex"),
        .lpm_hint("ENABLE_RUNTIME_MOD=NO"),
        .lpm_type("altsyncram"),
        .read_during_write_mode_port_a("NEW_DATA_NO_NBE_READ"),
        .width_byteena_a(4)
    ) ram_inst (
        .clock0(clk_100),
        .address_a(ram_addr),
        .data_a(mem_wdata),
        .wren_a(ram_wren),
        .byteena_a(mem_wstrb),
        .q_a(ram_q)
    );
    
    assign ram_rdata = ram_q;

     // Miner MMIO Registers
     logic [31:0] miner_rdata;

    always_ff @(posedge clk_100 or negedge rst_n) begin
        if (!rst_n) begin
            miner_start <= 1'b0;
            max_nonce_reg <= 32'h0010_0000;
            header_template_reg <= 640'h0;
            target_reg <= {256{1'b1}};
        end else begin
            miner_start <= 1'b0;

            if (miner_sel && mem_valid && |mem_wstrb) begin
                case (mem_addr[7:0])
                    8'h00: if (mem_wdata[0]) miner_start <= 1'b1;
                    8'h04: max_nonce_reg <= mem_wdata;

                     8'h30: target_reg[255:224] <= mem_wdata;
                    8'h34: target_reg[223:192] <= mem_wdata;
                    8'h38: target_reg[191:160] <= mem_wdata;
                    8'h3c: target_reg[159:128] <= mem_wdata;
                    8'h40: target_reg[127:96] <= mem_wdata;
                    8'h44: target_reg[95:64] <= mem_wdata;
                    8'h48: target_reg[63:32] <= mem_wdata;
                    8'h4c: target_reg[31:0] <= mem_wdata;

                     8'h50: header_template_reg[639:608] <= mem_wdata;
                    8'h54: header_template_reg[607:576] <= mem_wdata;
                    8'h58: header_template_reg[575:544] <= mem_wdata;
                    8'h5c: header_template_reg[543:512] <= mem_wdata;
                    8'h60: header_template_reg[511:480] <= mem_wdata;
                    8'h64: header_template_reg[479:448] <= mem_wdata;
                    8'h68: header_template_reg[447:416] <= mem_wdata;
                    8'h6c: header_template_reg[415:384] <= mem_wdata;
                    8'h70: header_template_reg[383:352] <= mem_wdata;
                    8'h74: header_template_reg[351:320] <= mem_wdata;
                    8'h78: header_template_reg[319:288] <= mem_wdata;
                    8'h7c: header_template_reg[287:256] <= mem_wdata;
                    8'h80: header_template_reg[255:224] <= mem_wdata;
                    8'h84: header_template_reg[223:192] <= mem_wdata;
                    8'h88: header_template_reg[191:160] <= mem_wdata;
                    8'h8c: header_template_reg[159:128] <= mem_wdata;
                    8'h90: header_template_reg[127:96] <= mem_wdata;
                    8'h94: header_template_reg[95:64] <= mem_wdata;
                    8'h98: header_template_reg[63:32] <= mem_wdata;
                    8'h9c: header_template_reg[31:0] <= mem_wdata;
                endcase
            end
        end
    end

     always_comb begin
        case (mem_addr[7:0])
            8'h00: miner_rdata = {28'h0, miner_exhausted, miner_found, miner_busy, 1'b0};
            8'h04: miner_rdata = max_nonce_reg;
            8'h08: miner_rdata = nonce_out;
            8'h0c: miner_rdata = hash_out[255:224];
            8'h10: miner_rdata = hash_out[223:192];
            8'h14: miner_rdata = hash_out[191:160];
            8'h18: miner_rdata = hash_out[159:128];
            8'h1c: miner_rdata = hash_out[127:96];
            8'h20: miner_rdata = hash_out[95:64];
            8'h24: miner_rdata = hash_out[63:32];
            8'h28: miner_rdata = hash_out[31:0];
            default: miner_rdata = 32'h0;
        endcase
    end
 
    always_comb begin
        if (ram_sel) begin
            mem_rdata = ram_rdata;
            mem_ready = mem_valid;
        end else if (miner_sel) begin
            mem_rdata = miner_rdata;
            mem_ready = mem_valid;
        end else begin
            mem_rdata = 32'h0;
            mem_ready = 1'b1;
        end
    end

    assign leds[0] = miner_busy;
    assign leds[1] = miner_found;
    assign leds[2] = miner_exhausted;
    assign leds[9:3] = nonce_out[6:0];

endmodule