//Author: Kai Hughes | 2025 
//Double SHA-256 Wrapper

module sha256_double (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,         
    input  logic [511:0] block_in,      
    input  logic        init_hash,      // 1 = use initial H, 0 = use hash_in
    input  logic [255:0] hash_in,       // Previous hash for chaining
    output logic        busy,
    output logic        done,
    output logic [255:0] hash_out       // Final double-hashed result
);

    typedef enum logic [1:0] {
        IDLE,
        HASH1,
        HASH2,
        DONE_STATE
    } state_t;
    
    state_t state;
    
    //niterfacing stuff
    logic        core_start;
    logic [511:0] core_block_in;
    logic [255:0] core_hash_in;
    logic        core_init_hash;
    logic        core_busy;
    logic        core_done;
    logic [255:0] core_hash_out;
    
    logic [255:0] hash1;
    
    sha256 core (
        .clk(clk),
        .rst_n(rst_n),
        .start(core_start),
        .block_in(core_block_in),
        .hash_in(core_hash_in),
        .init_hash(core_init_hash),
        .busy(core_busy),
        .done(core_done),
        .hash_out(core_hash_out)
    );
    
    //padded block for second hash
    //thee second hash is always on a 256bit value
    logic [511:0] hash2_block;
    
    always_comb begin
        //[32-byte hash] [0x80] [zeros] [length=256 bits=0x100]
        hash2_block = {hash1, 8'h80, 184'h0, 64'h0000000000000100};
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            hash_out <= '0;
            hash1 <= '0;
            
            core_start <= 1'b0;
            core_block_in <= '0;
            core_hash_in <= '0;
            core_init_hash <= 1'b1;
            
        end else begin
            core_start <= 1'b0;
            
            case (state)
                
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    
                    if (start) begin
                        state <= HASH1; //beginging hash
                        busy <= 1'b1;
                        
                        core_block_in <= block_in;
                        core_hash_in <= hash_in;
                        core_init_hash <= init_hash;
                        core_start <= 1'b1;
                    end
                end
                
                HASH1: begin
                    if (core_done) begin
                        hash1 <= core_hash_out;
                        
                        state <= HASH2; //next hash
                        
                        core_block_in <= hash2_block;
                        core_init_hash <= 1'b1; 
                        core_start <= 1'b1;
                    end
                end
                
                HASH2: begin
                    if (core_done) begin
                        hash_out <= core_hash_out;
                        state <= DONE_STATE;
                    end
                end
                
                DONE_STATE: begin
                    done <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
                
            endcase
        end
    end

endmodule