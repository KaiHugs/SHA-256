//Author: Kai Hughes | 2025 
//FPGA Top Level for Bitcoin Miner

module board_miner (
    input logic CLOCK_50,       
    input logic [3:0] KEY,             

    input logic[17:0] SW,             
    
    output logic[17:0] LEDR,
    output logic[8:0] LEDG,
    
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5,
    output logic [6:0] HEX6,
    output logic [6:0] HEX7
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
    
    logic [639:0] header_template;
    assign header_template = 640'h0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e76768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d00000000;
    
    logic [255:0] target;
    always_comb begin
        case (SW[17:14])
            4'h0: target = 256'h0000000000000000000000000000000000000000000000000000000000000001;
            4'h1: target = 256'h00000000000000000000000000000000000000000000000000000000FFFFFFFF;
            4'h2: target = 256'h000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF;
            4'h3: target = 256'h0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
            4'h4: target = 256'h00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'h5: target = 256'h000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'h6: target = 256'h0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'h7: target = 256'h00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'h8: target = 256'h000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'h9: target = 256'h0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'hA: target = 256'h00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'hB: target = 256'h0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'hC: target = 256'h1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'hD: target = 256'h3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            4'hE: target = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            default: target = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        endcase
    end
    
    logic [31:0] max_nonce;
    assign max_nonce = {18'b0, SW[13:0]} << 12;

    assign LEDR[0] = busy;
    assign LEDR[1] = found;
    assign LEDR[2] = exhausted;
    assign LEDR[3] = start_pulse;
    assign LEDR[17:4] = nonce_out[13:0];
    
    assign LEDG[7:0] = hash_out[7:0];
    assign LEDG[8] = reset_n;
    
    hex_to_7seg hex0_inst (.hex(nonce_out[3:0]),   .seg(HEX0));
    hex_to_7seg hex1_inst (.hex(nonce_out[7:4]),   .seg(HEX1));
    hex_to_7seg hex2_inst (.hex(nonce_out[11:8]),  .seg(HEX2));
    hex_to_7seg hex3_inst (.hex(nonce_out[15:12]), .seg(HEX3));
    hex_to_7seg hex4_inst (.hex(nonce_out[19:16]), .seg(HEX4));
    hex_to_7seg hex5_inst (.hex(nonce_out[23:20]), .seg(HEX5));
    hex_to_7seg hex6_inst (.hex(nonce_out[27:24]), .seg(HEX6));
    hex_to_7seg hex7_inst (.hex(nonce_out[31:28]), .seg(HEX7));
    
endmodule


module hex_to_7seg (
    input  logic [3:0] hex,
    output logic [6:0] seg
);
    always_comb begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule