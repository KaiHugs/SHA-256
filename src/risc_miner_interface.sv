/*Author: Kai Hughes | 2025
Wrapper with Miner Integration

0x0000_0000 - 0x0000_3FFF: RAM (16KB)
0x8000_0000: Miner Control Register
bit 0: start
bit 1: busy (RO)
bit 2: found (RO)
bit 3: exhausted (RO)
0x8000_0004: Max Nonce
0x8000_0008: Nonce Output (RO)
0x8000_000C: Hash Output Word 0 (RO)
0x8000_0010: Hash Output Word 1 (RO)

0x8000_0028: Hash Output Word 7 (RO)
0x8000_0030: Target Word 0
0x8000_0034: Target Word 1

0x8000_004C: Target Word 7
0x8000_0050-0x8000_009F: Header stuff
*/

module risc_miner_interface (
    input  logic        clk,
    input  logic        rst_n,
    output logic [9:0]  leds
);

    //cpu bus
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0]  mem_wstrb;
    logic        mem_valid, mem_ready;

    picorv32 cpu (
        .clk(clk),
        .resetn(rst_n),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_wstrb(mem_wstrb),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready)
    );

    //miner regs
    logic        miner_start;
    logic        miner_busy;
    logic        miner_found;
    logic        miner_exhausted;

    logic [31:0]  max_nonce_reg;
    logic [639:0] header_template_reg;
    logic [255:0] target_reg;

    logic [31:0]  nonce_out;
    logic [255:0] hash_out;

    bitcoin_miner miner (
        .clk(clk),
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
        ram_sel   = (mem_addr[31:16] == 16'h0000);
        miner_sel = (mem_addr[31:16] == 16'h8000);
    end

    //16kb
    logic [31:0] ram [0:4095];
    logic [31:0] ram_rdata;

    initial begin
        $readmemh("program.hex", ram);
    end

    always_ff @(posedge clk) begin
        if (ram_sel && mem_valid) begin
            if (mem_wstrb[0]) ram[mem_addr[13:2]][7:0]   <= mem_wdata[7:0];
            if (mem_wstrb[1]) ram[mem_addr[13:2]][15:8]  <= mem_wdata[15:8];
            if (mem_wstrb[2]) ram[mem_addr[13:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) ram[mem_addr[13:2]][31:24] <= mem_wdata[31:24];
            ram_rdata <= ram[mem_addr[13:2]];
        end
    end

    //miner mmio
    logic [31:0] miner_rdata;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            miner_start          <= 1'b0;
            max_nonce_reg        <= 32'h0010_0000;
            header_template_reg  <= 640'h0;
            target_reg           <= {256{1'b1}};
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
                    8'h40: target_reg[127:96]  <= mem_wdata;
                    8'h44: target_reg[95:64]   <= mem_wdata;
                    8'h48: target_reg[63:32]   <= mem_wdata;
                    8'h4c: target_reg[31:0]    <= mem_wdata;

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
                    8'h90: header_template_reg[127:96]  <= mem_wdata;
                    8'h94: header_template_reg[95:64]   <= mem_wdata;
                    8'h98: header_template_reg[63:32]   <= mem_wdata;
                    8'h9c: header_template_reg[31:0]    <= mem_wdata;
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

    assign leds[0]   = miner_busy;
    assign leds[1]   = miner_found;
    assign leds[2]   = miner_exhausted;
    assign leds[9:3] = nonce_out[6:0];

endmodule
