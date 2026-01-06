/*
   Author: Kai Hughes | 2026 
   Testbench for RISC-V Bitcoin Miner Interface
   Tests the full top level
 */

`timescale 1ns/1ps

module tb_risc_miner_interface;

    logic CLOCK_50;
    logic rst_n_raw;
    logic [9:0] leds;
    
    risc_miner_interface dut (
        .CLOCK_50(CLOCK_50),
        .rst_n_raw(rst_n_raw),
        .leds(leds)
    );
    
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;  // 20ns
    end
    
    always @(leds) begin
        $display("[%0t] LEDs changed: 0x%03h (busy=%b, found=%b, exhausted=%b, nonce[6:0]=%b)",
                 $time, leds, leds[0], leds[1], leds[2], leds[9:3]);
    end
    
    initial begin
        $display("RISC-V Bitcoin Miner Interface Testbench");
        
        rst_n_raw = 0;
        
        #200;
        $display("[%0t] Releasing reset", $time);
        rst_n_raw = 1;
        
        //wait for PLL to lock and system to initialize
        $display("[%0t] Waiting for PLL lock and system init", $time);
        #5000;
        
        $display("[%0t] System should be running now", $time);
        $display("[%0t] CPU executing from program.hex", $time);
        
        fork
            begin
                wait(leds[0] == 1'b1);
                $display("[%0t] *** MINER STARTED (LED[0]=busy)***", $time);
            end
            
            //watchdog for found signal
            begin
                wait(leds[1] == 1'b1);
                $display("[%0t] **** NONCE FOUND! (LED[1]=found) ***", $time);
                $display("[%0t] Found nonce bits [6:0]: %b", $time, leds[9:3]);
            end
            
            begin
                wait(leds[2] == 1'b1);
                $display("[%0t] ****SEARCH EXHAUSTED (LED[2]=exhausted) ***", $time);
            end
        join_none
        
        // Run for a long time to see mining happen
        #100000000;  // 100ms at simulation time
        
        $display("                               ");
        $display("Test completed after 100ms sim time");
        $display("Final LED state: 0x%03h", leds);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #200000000;  // 200ms max
        $display("                               ");
        $display("TIMEOUT - Test ran too long");
        $finish;
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("risc_miner_interface.vcd");
        $dumpvars(0, tb_risc_miner_interface);
    end

endmodule

module tb_cpu_interface;

    logic        clk;
    logic        rst_n;
    
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic [3:0]  mem_wstrb;
    logic mem_valid;
    logic mem_ready;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    //testing sequencign
    initial begin
        $display("                                     ");
        $display("CPU Interface Test");
        $display("Testing memory-mapped register access");
        
        rst_n = 0;
        mem_valid = 0;
        mem_wstrb = 4'b0000;
        mem_addr = 32'h0;
        mem_wdata = 32'h0;
        
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);
        
        //Test 1: Write to max_nonce register
        $display("\n[Test 1] Writing 0x12345678 to max_nonce (0x80000004)");
        write_reg(32'h80000004, 32'h12345678);
        
        //Test 2: Read control register
        $display("\n[Test 2] Reading control register (0x80000000)");
        read_reg(32'h80000000);
        $display("Control register: 0x%08h", mem_rdata);
        
        //Test 3: Write to target register
        $display("\n[Test 3] Writing to target registers");
        write_reg(32'h80000030, 32'h00000000);
        write_reg(32'h80000034, 32'h00000000);
        write_reg(32'h80000038, 32'h00000000);
        write_reg(32'h8000003C, 32'h00000000);
        write_reg(32'h80000040, 32'h00000000);
        write_reg(32'h80000044, 32'h00000000);
        write_reg(32'h80000048, 32'h00000000);
        write_reg(32'h8000004C, 32'h0000FFFF);  //easiest
        
        // Test 4: Start mining
        $display("\n[Test 4] Starting miner (write 0x1 to control)");
        write_reg(32'h80000000, 32'h00000001);
        
        // Test 5: Poll status
        $display("\n[Test 5] Polling status");
        repeat(10) begin
            @(posedge clk);
            read_reg(32'h80000000);
            $display("  Status: 0x%08h (busy=%b, found=%b, exhausted=%b)", 
                     mem_rdata, mem_rdata[1], mem_rdata[2], mem_rdata[3]);
            repeat(100) @(posedge clk);
        end
        
        $display("\n                                     ");
        $display("CPU Interface Test Complete");
        $finish;
    end
    
    //write to reg
    task write_reg(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            mem_addr = addr;
            mem_wdata = data;
            mem_wstrb = 4'b1111;
            mem_valid = 1;
            
            @(posedge clk);
            wait(mem_ready);
            
            @(posedge clk);
            mem_valid = 0;
            mem_wstrb = 4'b0000;
            $display("  Write: addr=0x%08h, data=0x%08h", addr, data);
        end
    endtask
    
    //echo data from reg
    task read_reg(input [31:0] addr);
        begin
            @(posedge clk);
            mem_addr = addr;
            mem_wstrb = 4'b0000;
            mem_valid = 1;
            
            @(posedge clk);
            wait(mem_ready);
            
            @(posedge clk);
            mem_valid = 0;
            $display("  Read: addr=0x%08h, data=0x%08h", addr, mem_rdata);
        end
    endtask
    
    initial begin
        $dumpfile("cpu_interface.vcd");
        $dumpvars(0, tb_cpu_interface);
    end

endmodule


//RAM TESTING

module tb_ram_loading;

    logic clk;
    logic rst_n;
    
    logic [31:0] test_ram [0:4095];
    
    initial begin
        $display("       ");
        $display("RAM Loading Test");
        
        $readmemh("program.hex", test_ram);
        
        $display("\nFirst 16 words from program.hex:");
        for (int i = 0; i < 16; i++) begin
            $display("  RAM[%2d] = 0x%08h", i, test_ram[i]);
        end
        
        if (test_ram[0] == 32'h00000000) begin //nonzero testing
            $display("\n*** ERROR: RAM[0] is zero");
        end else begin
            $display("\nSUCCESS: program.hex loaded correctly");
        end
        
        $display("                               ");
        $finish;
    end

endmodule

module tb_pll;

    logic clk_50;
    logic rst;
    logic clk_100;
    logic locked;
    
    // Instantiate PLL
    Clock_100_PLL pll (
        .areset(rst),
        .inclk0(clk_50),
        .c0(clk_100),
        .locked(locked)
    );
    
    // 50MHz clock
    initial begin
        clk_50 = 0;
        forever #10 clk_50 = ~clk_50;
    end
    
    // Test
    initial begin
        $display("                                     ");
        $display("PLL Test");
        
        rst = 1;
        #100;
        rst = 0;
        
        $display("Waiting for PLL to lock");
        wait(locked);
        $display("[%0t] PLL locked!", $time);
        
        real last_edge, this_edge, period;
        @(posedge clk_100);
        last_edge = $realtime;
        @(posedge clk_100);
        this_edge = $realtime;
        period = this_edge - last_edge;
        
        $display("Output period: %.2f ns", period);
        $display("Output frequency: %.2f MHz", 1000.0/period);
        
        if (period > 9.5 && period < 10.5) begin
            $display("**SUCCESS: Output is 100MHz");
        end else begin
            $display("Timing Failture: Output frequency incorrect");
        end
        
        #1000;
        $display("Done");
        $finish;
    end

endmodule

module tb_mining_stimulus;

    logic        CLOCK_50;
    logic        rst_n_raw;
    logic [9:0]  leds;
    
    logic [31:0] nonce_out;
    logic [255:0] hash_out;
    logic miner_busy, miner_found;
    
   
    risc_miner_interface dut (
        .CLOCK_50(CLOCK_50),
        .rst_n_raw(rst_n_raw),
        .leds(leds)
    );
    
    // Tap internal signals
    assign nonce_out = dut.nonce_out;
    assign hash_out = dut.hash_out;
    assign miner_busy = dut.miner_busy;
    assign miner_found = dut.miner_found;
    
    // 50MHz clock
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end
    
    initial begin
        $display("                                               ");
        $display("Mining Stimulus Test");
        $display("Testing actual mining operation");
        
        rst_n_raw = 0;
        #500;
        rst_n_raw = 1;
        
        $display("[%0t] Waiting for CPU to start mining", $time);
        
        wait(miner_busy);
        $display("[%0t] Mining started!", $time);
        
        fork
            begin
                wait(miner_found || dut.miner_exhausted);
                if (miner_found) begin
                    $display("[%0t] *** FOUND VALID NONCE! ***", $time);
                    $display("  Nonce: 0x%08h", nonce_out);
                    $display("  Hash:  0x%064h", hash_out);
                end else begin
                    $display("[%0t] Search exhausted", $time);
                end
            end
            

            begin
                while (miner_busy) begin
                    #10000;
                    $display("[%0t] Statis: Mining             (still busy)", $time);
                end
            end
        join_any
        
        #10000;
        $display("                               ");
        $finish;
    end
    
    // Timeout
    initial begin
        #50000000;  // 50ms
        $display("                ");`
        $display("TIMEOUT");
        $finish;
    end
    
    initial begin
        $dumpfile("mining_stimulus.vcd");
        $dumpvars(0, tb_mining_stimulus);
    end

endmodule

