//Author: Kai Hughes | 2025 
//Bitcoin Mining Controller controlling nonce attempts

module bitcoin_miner (
    input  logic clk,
    input  logic rst_n,  
    input  logic start,              
    input  logic [639:0] header_template,   //80-byte header with nonce=0 
    input  logic [255:0] target,           
    input  logic [31:0]  max_nonce,         
    output logic busy,              
    output logic found,              
    output logic exhausted,          //no valid nonce
    output logic [31:0]  nonce_out,         //valid nonce
    output logic [255:0] hash_out           
);

    typedef enum logic [3:0] {
        IDLE,
        LOAD,
        BUILD_BLOCKS,
        HASH,
        HASH_WAIT1,
        HASH_WAIT2,
        CHECK,
        INCREMENT,
        FOUND_STATE,
        EXHAUSTED_STATE
    } state_t;
    
    state_t state;
    
    logic [31:0] nonce;
    
    logic [639:0] header;
    
    // Bitcoin header 640bits or 2 blocks
    logic [511:0] block0, block1;
    
    logic hasher_start;
    logic [511:0] hasher_block_in;
    logic hasher_init_hash;
    logic [255:0] hasher_hash_in;
    logic hasher_busy;
    logic hasher_done;
    logic [255:0] hasher_hash_out;
    
    sha256 hasher (
        .clk(clk),
        .rst_n(rst_n),
        .start(hasher_start),
        .block_in(hasher_block_in),
        .init_hash(hasher_init_hash),
        .hash_in(hasher_hash_in),
        .busy(hasher_busy),
        .done(hasher_done),
        .hash_out(hasher_hash_out)
    );
    
    logic [1:0] hash_stage;
    
    always_comb begin
        header = header_template;
        //insert nonce at bytes 76-79 (bits [31:0])
        //bitcoin uses little-endian, so byte 76 gets nonce[7:0]
        header[31:0] = {nonce[7:0], nonce[15:8], nonce[23:16], nonce[31:24]};
    end
    
    //block 0: First 512 bits (64 bytes)
    //block 1: Remaining 128 bits (16 bytes) + padding
    always_comb begin
        block0 = header[639:128];  // First 64 bytes
        
        //[16 bytes] [0x80] [zeros] [length in bits = 640 = 0x280]
        block1 = {header[127:0], 8'h80, 312'h0, 64'h0000000000000280};
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            found <= 1'b0;
            exhausted <= 1'b0;
            nonce <= '0;
            nonce_out <= '0;
            hash_out <= '0;
            hash_stage <= '0;
            
            hasher_start <= 1'b0;
            hasher_block_in <= '0;
            hasher_init_hash <= 1'b1;
            hasher_hash_in <= '0;
            
        end else begin
            hasher_start <= 1'b0;
            
            case (state)
                
                IDLE: begin
                    found <= 1'b0;
                    exhausted <= 1'b0;
                    busy <= 1'b0;
                    
                    if (start) begin
                        state <= LOAD;
                        busy <= 1'b1;
                    end
                end
                
                LOAD: begin
                    // Initialize for mining
                    nonce <= 32'h0;
                    hash_stage <= 2'b00;
                    state <= BUILD_BLOCKS;
                end
                
                BUILD_BLOCKS: begin
                    //block 0
                    state <= HASH;
                    hash_stage <= 2'b00;
                    
                    //hashing block 0 
                    hasher_block_in <= block0;
                    hasher_init_hash <= 1'b1;
                    hasher_start <= 1'b1;
                end
                
                
                HASH: begin
                    if (hasher_done) begin
                        case (hash_stage)
                            2'b00: begin
                                hash_stage <= 2'b01;
                                state <= HASH_WAIT1;
                                
                                // hasher_block_in <= block1;
                                // hasher_hash_in <= hasher_hash_out;
                                // hasher_init_hash <= 1'b0;
                                // hasher_start <= 1'b1;
                            end
                            
                            2'b01: begin
                                hash_stage <= 2'b10;
                                state <= HASH_WAIT2;
                                
                                // hasher_block_in <= {hasher_hash_out, 8'h80, 184'h0, 64'h0000000000000100};
                                // hasher_init_hash <= 1'b1;
                                // hasher_hash_in <= '0;
                                // hasher_start <= 1'b1;
                            end
                            
                            2'b10: begin
                                hash_out <= hasher_hash_out;
                                state <= CHECK;
                            end
                        endcase
                    end
                end
                
                HASH_WAIT1: begin
                    state <= HASH;
                    
                    hasher_block_in <= block1;
                    hasher_hash_in <= hasher_hash_out;
                    hasher_init_hash <= 1'b0;
                    hasher_start <= 1'b1;
                end
                
                HASH_WAIT2: begin
                    state <= HASH;
                    
                    hasher_block_in <= {hasher_hash_out, 8'h80, 184'h0, 64'h0000000000000100};
                    hasher_init_hash <= 1'b1;
                    hasher_hash_in <= '0;
                    hasher_start <= 1'b1;
                end
                
                CHECK: begin
                    if (hash_out < target) begin
                        state <= FOUND_STATE;
                        found <= 1'b1;
                        nonce_out <= nonce;
                    end else begin
                        state <= INCREMENT;
                    end
                end
                
                INCREMENT: begin
                    if (nonce >= max_nonce) begin
                        state <= EXHAUSTED_STATE;
                        exhausted <= 1'b1;
                    end else begin
                        nonce <= nonce + 1;
                        state <= BUILD_BLOCKS;
                    end
                end
                
                FOUND_STATE: begin
                    busy <= 1'b0;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                EXHAUSTED_STATE: begin
                    busy <= 1'b0;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                    busy <= 1'b0;
                    found <= 1'b0;
                    exhausted <= 1'b0;
                end
            endcase
        end
    end

endmodule