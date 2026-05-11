`timescale 1ns/1ps

module rs_uart_tx_buf_tb;

    // ==========================================
    // Parameters
    // ==========================================
    parameter CLK_PERIOD = 20; // 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8680.5 ns

    // ==========================================
    // System Signals
    // ==========================================
    logic        clk;
    logic        rst_n;
    logic        baud_clk;
    
    logic        rs_tx_vld;
    logic [9:0]  rs_tx_dat;
    logic        gbx_tx_rdy;
    
    logic        buf_tx_vld;
    logic [9:0]  buf_tx_dat;
    logic        buf_tx_err;

    // Emulator tracking variables
    integer      symbols_received;
    integer      gbx_bit_cnt;

    logic        uart_tx_busy;
    logic        uart_tx_done;

    // ==========================================
    // Clock Generation
    // ==========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        baud_clk = 0;
        forever #(BIT_TIME / 2) baud_clk = ~baud_clk;
    end

    // ==========================================
    // Waveform Dump
    // ==========================================
    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACM");
    end

    // ==========================================
    // DUT Instantiation
    // ==========================================
    rs_uart_tx_buf dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs_tx_vld  (rs_tx_vld),
        .rs_tx_dat  (rs_tx_dat),
        .gbx_tx_rdy (gbx_tx_rdy),
        .buf_tx_vld (buf_tx_vld),
        .buf_tx_dat (buf_tx_dat),
        .buf_tx_err (buf_tx_err)
    );

    // ==========================================
    // Gearbox Emulator (10-to-8 Bit Flow)
    // ==========================================
    assign gbx_tx_rdy = (gbx_bit_cnt < 8);

    // Tiến trình giả lập delay do quá trình truyền UART
    initial begin
        uart_tx_busy = 0;
        uart_tx_done = 0;
        forever begin
            @(posedge clk);
            
            // SỬA LỖI RACE CONDITION Ở ĐÂY: 
            // Giữ cờ busy thêm 1 nhịp clock để always_ff hoàn tất phép trừ gbx_bit_cnt
            if (uart_tx_done) begin
                uart_tx_done = 0;
                uart_tx_busy = 0; 
            end 
            else if (gbx_bit_cnt >= 8 && !uart_tx_busy) begin
                uart_tx_busy = 1;
                
                // Giả lập delay truyền 1 frame UART (Start + 8 Data + Stop)
                #(BIT_TIME * 10); 
                
                @(posedge clk); 
                uart_tx_done = 1; // Bật cờ done báo cho always_ff biết để trừ bit
            end
        end
    end

    // Tiến trình cập nhật số bit trong Gearbox an toàn
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            gbx_bit_cnt <= 0;
            symbols_received <= 0;
        end else begin
            if (buf_tx_vld && gbx_tx_rdy && uart_tx_done) begin
                gbx_bit_cnt <= gbx_bit_cnt + 10 - 8;
                symbols_received <= symbols_received + 1;
                $display("[%0t] GBX RX & TX  | Symbol: %4d | Buffer: %0d bits", $time, buf_tx_dat, gbx_bit_cnt + 10 - 8);
            end else if (buf_tx_vld && gbx_tx_rdy) begin
                gbx_bit_cnt <= gbx_bit_cnt + 10;
                symbols_received <= symbols_received + 1;
                $display("[%0t] GBX RX       | Symbol: %4d | Buffer: %0d bits", $time, buf_tx_dat, gbx_bit_cnt + 10);
            end else if (uart_tx_done) begin
                gbx_bit_cnt <= gbx_bit_cnt - 8;
                $display("[%0t] GBX TX Done  |              | Buffer: %0d bits", $time, gbx_bit_cnt - 8);
            end
        end
    end

    // ==========================================
    // Burst Feed Task
    // ==========================================
    task burst_feed(input int count);
        begin
            for (int i = 0; i < count; i++) begin
                @(posedge clk);
                rs_tx_vld <= 1'b1;
                rs_tx_dat <= i[9:0];
            end
            @(posedge clk);
            rs_tx_vld <= 1'b0;
            rs_tx_dat <= 10'd0;
        end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================
    initial begin
        rst_n     = 1'b0;
        rs_tx_vld = 1'b0;
        rs_tx_dat = 10'd0;
        
        #(CLK_PERIOD * 10);
        rst_n = 1'b1;
        #(CLK_PERIOD * 10);
        
        // =========================================================
        // BURST 544 SYMBOLS
        // =========================================================
        $display("---------------------------------------------------------");
        $display("[%0t] BURST 544 SYMBOLS", $time);
        $display("---------------------------------------------------------");
        
        rst_n = 1'b0;
        #(CLK_PERIOD * 5);
        rst_n = 1'b1;
        #(CLK_PERIOD * 5);
        
        burst_feed(544);
        
        while (symbols_received < 544) @(posedge clk);
        
        while (gbx_bit_cnt > 0) @(posedge clk);
        #(BIT_TIME * 15);
        
        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED.", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule
