/*Author: Kai Hughes | 2025
Interface with Miner Integration - External RAM testing

Memory Map:
0x0000_0000 - 0x0000_FFFF: SDRAM (64KB)
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
    input  logic [3:0] KEY,
    
    output logic [17:0] LEDR,
    output logic [8:0] LEDG,
    
    output logic [12:0] DRAM_ADDR,
    output logic [1:0]  DRAM_BA,
    output logic        DRAM_CAS_N,
    output logic        DRAM_CKE,
    output logic        DRAM_CLK,
    output logic        DRAM_CS_N,
    inout  wire  [15:0] DRAM_DQ,
    output logic [1:0]  DRAM_DQM,
    output logic        DRAM_RAS_N,
    output logic        DRAM_WE_N
);

    logic rst_n_raw;
    assign rst_n_raw = KEY[0];

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

    picorv32 #(
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .COMPRESSED_ISA(0)
    ) cpu (
        .clk(clk_100),
        .resetn(rst_n),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_wstrb(mem_wstrb),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready),
        .mem_instr(),
        .trap()
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
 
    logic [31:0] sdram_rdata;
    logic sdram_ready;
    logic [15:0] sdram_addr;
    logic sdram_wren;
    logic [31:0] sdram_wdata;
    logic [3:0] sdram_wstrb;
    
    assign sdram_addr = mem_addr[16:1];
    assign sdram_wren = ram_sel && mem_valid && |mem_wstrb;
    assign sdram_wdata = mem_wdata;
    assign sdram_wstrb = mem_wstrb;
    
    sdram_controller sdram_ctrl (
        .clk(clk_100),
        .rst_n(rst_n),
        
        .addr(sdram_addr),
        .wdata(sdram_wdata),
        .rdata(sdram_rdata),
        .wstrb(sdram_wstrb),
        .valid(ram_sel && mem_valid),
        .ready(sdram_ready),
        
        .DRAM_ADDR(DRAM_ADDR),
        .DRAM_BA(DRAM_BA),
        .DRAM_CAS_N(DRAM_CAS_N),
        .DRAM_CKE(DRAM_CKE),
        .DRAM_CLK(DRAM_CLK),
        .DRAM_CS_N(DRAM_CS_N),
        .DRAM_DQ(DRAM_DQ),
        .DRAM_DQM(DRAM_DQM),
        .DRAM_RAS_N(DRAM_RAS_N),
        .DRAM_WE_N(DRAM_WE_N)
    );

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
            mem_rdata = sdram_rdata;
            mem_ready = sdram_ready;
        end else if (miner_sel) begin
            mem_rdata = miner_rdata;
            mem_ready = mem_valid;
        end else begin
            mem_rdata = 32'h0;
            mem_ready = 1'b1;
        end
    end

    assign LEDR[0] = miner_busy;
    assign LEDR[1] = miner_found;
    assign LEDR[2] = miner_exhausted;
    assign LEDR[3] = rst_n;
    assign LEDR[4] = pll_locked;
    assign LEDR[5] = mem_valid;
    assign LEDR[6] = mem_ready;
    assign LEDR[7] = ram_sel;
    assign LEDR[17:8] = nonce_out[9:0];
    
    assign LEDG[7:0] = hash_out[7:0];
    assign LEDG[8] = miner_sel;

endmodule


module sdram_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [15:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic [3:0]  wstrb,
    input  logic        valid,
    output logic        ready,
    
    output logic [12:0] DRAM_ADDR,
    output logic [1:0]  DRAM_BA,
    output logic        DRAM_CAS_N,
    output logic        DRAM_CKE,
    output logic        DRAM_CLK,
    output logic        DRAM_CS_N,
    inout  wire  [15:0] DRAM_DQ,
    output logic [1:0]  DRAM_DQM,
    output logic        DRAM_RAS_N,
    output logic        DRAM_WE_N
);

    assign DRAM_CLK = clk;
    assign DRAM_CKE = 1'b1;
    
    typedef enum logic [3:0] {
        INIT,
        IDLE,
        ACTIVATE,
        READ,
        READ_WAIT,
        WRITE,
        PRECHARGE,
        REFRESH
    } state_t;
    
    state_t state, next_state;
    
    logic [15:0] dq_out;
    logic dq_oe;
    logic [31:0] read_buffer;
    logic [9:0] refresh_counter;
    logic [3:0] cmd_delay;
    
    assign DRAM_DQ = dq_oe ? dq_out : 16'hZZZZ;
    
    logic [12:0] row_addr;
    logic [9:0] col_addr;
    logic [1:0] bank_addr;
    
    assign bank_addr = addr[15:14];
    assign row_addr = {addr[13:1]};
    assign col_addr = {addr[0], 9'b0};
    
    logic [3:0] cmd;
    localparam CMD_NOP        = 4'b0111;
    localparam CMD_ACTIVE     = 4'b0011;
    localparam CMD_READ       = 4'b0101;
    localparam CMD_WRITE      = 4'b0100;
    localparam CMD_PRECHARGE  = 4'b0010;
    localparam CMD_REFRESH    = 4'b0001;
    localparam CMD_LOAD_MODE  = 4'b0000;
    
    assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N} = cmd;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT;
            cmd_delay <= 4'd0;
            refresh_counter <= 10'd0;
            ready <= 1'b0;
            rdata <= 32'h0;
            read_buffer <= 32'h0;
        end else begin
            state <= next_state;
            
            if (refresh_counter == 10'd780)
                refresh_counter <= 10'd0;
            else
                refresh_counter <= refresh_counter + 1'b1;
            
            if (cmd_delay > 0)
                cmd_delay <= cmd_delay - 1'b1;
            
            if (state == READ_WAIT && cmd_delay == 4'd1) begin
                read_buffer <= {DRAM_DQ, DRAM_DQ};
                rdata <= {DRAM_DQ, DRAM_DQ};
            end
        end
    end
    
    always_comb begin
        next_state = state;
        cmd = CMD_NOP;
        DRAM_ADDR = 13'h0;
        DRAM_BA = 2'b00;
        DRAM_DQM = 2'b00;
        dq_out = 16'h0;
        dq_oe = 1'b0;
        ready = 1'b0;
        
        case (state)
            INIT: begin
                if (cmd_delay == 4'd0) begin
                    cmd_delay = 4'd15;
                    next_state = IDLE;
                end
            end
            
            IDLE: begin
                ready = 1'b1;
                if (valid) begin
                    next_state = ACTIVATE;
                    cmd_delay = 4'd2;
                end else if (refresh_counter == 10'd780) begin
                    next_state = REFRESH;
                    cmd = CMD_REFRESH;
                    cmd_delay = 4'd7;
                end
            end
            
            ACTIVATE: begin
                cmd = CMD_ACTIVE;
                DRAM_ADDR = row_addr;
                DRAM_BA = bank_addr;
                if (cmd_delay == 4'd0) begin
                    next_state = (|wstrb) ? WRITE : READ;
                end
            end
            
            READ: begin
                cmd = CMD_READ;
                DRAM_ADDR = {3'b001, col_addr};
                DRAM_BA = bank_addr;
                next_state = READ_WAIT;
                cmd_delay = 4'd3;
            end
            
            READ_WAIT: begin
                if (cmd_delay == 4'd0) begin
                    next_state = IDLE;
                    ready = 1'b1;
                end
            end
            
            WRITE: begin
                cmd = CMD_WRITE;
                DRAM_ADDR = {3'b001, col_addr};
                DRAM_BA = bank_addr;
                DRAM_DQM = ~wstrb[1:0];
                dq_out = wdata[15:0];
                dq_oe = 1'b1;
                next_state = IDLE;
                cmd_delay = 4'd2;
            end
            
            REFRESH: begin
                if (cmd_delay == 4'd0)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule