//Author: Kai Hughes | 2025 
//FPGA Top Level for Bitcoin Miner


module board_miner (
    input logic CLOCK_50,       
    input logic [1:0] KEY,             

    //switches for difficulty
    input logic[9:0] SW,             
    
    output logic[9:0] LEDR,            
    output logic[7:0] LEDG             
);

    
bitcoin_miner miner (
        .clk(CLOCK_50),
        .rst_n(reset_n),
        .start(start_pulse),
        .header_template(header_template),
        .target(target),
        .max_nonce(max_nonce),
        .busy(busy),
        .found(found),
        .exhausted(exhausted),
        .nonce_out(nonce_out),
        .hash_out(hash_out)
    );
    

    logic reset_n;
    // logic start_button;
    
    // always_ff @(posedge CLOCK_50) begin
    //     reset_n <= KEY[0];           
    //     start_button <= ~KEY[1];
    // end
    
    logic [2:0] key0_sync;
    logic [2:0] key1_sync;
    
    always_ff @(posedge CLOCK_50) begin
        key0_sync <= {key0_sync[1:0], KEY[0]};
        key1_sync <= {key1_sync[1:0], ~KEY[1]};
    end
    
    assign reset_n = key0_sync[2];
    
    logic start_pulse;
    logic start_button_prev;
    
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            start_button_prev <= 1'b0;
            start_pulse <= 1'b0;
        end else begin
            start_button_prev <= key1_sync[2];
            start_pulse <= key1_sync[2] && !start_button_prev;
        end
    end
    
    logic busy;
    logic found;
    logic exhausted;
    logic [31:0] nonce_out;
    logic [255:0] hash_out;
    
    //testing stuff
    logic [639:0] header_template;
    assign header_template = 640'h0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e76768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d00000000;
    
    //target based on switches
    //SW[9:6] controls difficulty
    logic [255:0] target;
    always_comb begin
        case (SW[9:6])
            4'h0: target = 256'h0000000000000000000000000000000000000000000000000000000000000000;  //Impossible
            4'h1: target = 256'h00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  //Hard
            4'h2: target = 256'h000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
            4'h3: target = 256'h0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  //Medium
            4'h4: target = 256'h00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
            4'h5: target = 256'h000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  //Easy
            4'h6: target = 256'h0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
            4'h7: target = 256'h00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
            default: target = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  //Max (all pass)
        endcase
    end
    
    //max nonce (set based on SW[5:0])
    //limits how many nonces to try before giving up
    logic [31:0] max_nonce;
    assign max_nonce = {26'b0, SW[5:0]} << 16;  //SW controls upper bits

    assign LEDR[0] = busy;           //Red LED 0: Mining active
    assign LEDR[1] = found;          //Red LED 1: Found valid nonce
    assign LEDR[2] = exhausted;      //Red LED 2: Search exhausted
    assign LEDR[9:3] = nonce_out[6:0]; 
    
    assign LEDG = hash_out[7:0];  
endmodule