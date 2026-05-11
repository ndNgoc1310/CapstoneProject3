`timescale 1ns/1ps

module rs_uart_rx_buf_tb;

    // ==========================================
    // Parameters
    // ==========================================
    parameter CLK_PERIOD = 20; // 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8680.5 ns

    // ==========================================
    // System Signals
    // ==========================================
    logic clk;
    logic rst_n;
    logic baud_clk; 
    logic rs_sel; // 0: Encode, 1: Decode

    // UART Core Signals
    logic       rx_serial;
    logic       i_rx_en;
    logic       i_rx_rden;
    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;
    logic       uart_rx_fifo_empty;

    // Gearbox Signals
    logic       gbx_rx_vld;
    logic [9:0] gbx_rx_dat;
    logic       gbx_rx_err;

    // Buffer Signals
    logic       buf_rx_sop;
    logic       buf_rx_vld;
    logic [9:0] buf_rx_dat;
    logic       buf_rx_err;

    // ==========================================
    // Cấu hình Clock & Waveform Dump
    // ==========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        baud_clk = 0;
        forever #(BIT_TIME / 2) baud_clk = ~baud_clk;
    end

    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACM");
    end

    // ==========================================
    // Instantiation: UART Core (RX)
    // ==========================================
    uart_core u_uart (
        .i_clk             (clk),
        .i_rst_n           (rst_n),
        .i_bclk_en         (1'b1),
        .i_baud_divisor    (-16'd27), 
        .i_parity_en       (1'b0),
        .i_even_parity     (1'b0),
        .i_dbg_lloopback   (1'b0),
        .i_dbg_sloopback   (1'b0),
        
        .i_tx_en           (1'b0),
        .i_tx_data         (8'd0),
        .i_tx_wren         (1'b0),
        .i_tx_fifo_clr     (~rst_n),
        
        .i_rx_en           (i_rx_en),
        .i_rx              (rx_serial),
        .i_rx_fifo_clr     (~rst_n),
        .i_rx_rden         (i_rx_rden),
        .o_rx_data         (uart_rx_data),
        .o_rx_done         (uart_rx_valid),
        .o_rx_fifo_empty   (uart_rx_fifo_empty),
        
        .o_tx_idle(), .o_tx_done(), .o_tx_fifo_empty(), .o_tx_fifo_full(),
        .o_tx_fifo_level(), .o_rx_idle(), .o_rx_fifo_full(), .o_rx_fifo_level(),
        .o_rx_frame_error(), .o_rx_parity_error(), .o_rx_data_is_zero(), .o_tx()
    );

    // ==========================================
    // Instantiation: RX Gearbox
    // ==========================================
    rs_uart_rx_gbx u_gbx (
        .clk           (clk),
        .rst_n         (rst_n),
        .rs_sel        (rs_sel),
        .uart_rx_vld   (uart_rx_valid),
        .uart_rx_dat   (uart_rx_data),
        .gbx_rx_vld    (gbx_rx_vld),
        .gbx_rx_dat    (gbx_rx_dat),
        .gbx_rx_err    (gbx_rx_err)
    );

    // ==========================================
    // Instantiation: RX Buffer
    // ==========================================
    rs_uart_rx_buf u_buf (
        .clk           (clk),
        .rst_n         (rst_n),
        .rs_sel        (rs_sel),
        .gbx_rx_vld    (gbx_rx_vld),
        .gbx_rx_dat    (gbx_rx_dat),
        .buf_rx_sop    (buf_rx_sop),
        .buf_rx_vld    (buf_rx_vld),
        .buf_rx_dat    (buf_rx_dat),
        .buf_rx_err    (buf_rx_err)
    );

    // ==========================================
    // UART TX Emulator Task
    // ==========================================
    task send_uart_byte(input logic [7:0] tx_data);
        integer i;
        begin
            rx_serial = 1'b0; // Start bit
            #(BIT_TIME);
            
            for (i = 0; i < 8; i++) begin
                rx_serial = tx_data[i];
                #(BIT_TIME);
            end
            
            rx_serial = 1'b1; // Stop bit
            #(BIT_TIME);
            
            // Inter-byte delay
            #(BIT_TIME * 2);
        end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================
    integer k;
    
    initial begin
        rst_n     = 0;
        rx_serial = 1;
        i_rx_en   = 1;
        i_rx_rden = 1; // Tự động đọc liên tục
        rs_sel    = 0;

        #(CLK_PERIOD * 20);
        rst_n = 1; 
        #(CLK_PERIOD * 20);

        $display("---------------------------------------------------------");
        $display("[%0t] STARTING SIMULATION...", $time);
        $display("---------------------------------------------------------");

        // ---------------------------------------------------------
        // SCENARIO 1: RS_ENC (rs_sel = 0) - 642 bytes ('a' / 'b')
        // ---------------------------------------------------------
        rs_sel = 0;
        $display("[%0t] SCENARIO 1: ENCODER MODE (rs_sel = 0)", $time);

        for (k = 0; k < 642; k++) begin
            if (k % 2 == 0) send_uart_byte(8'h61); // 'a'
            else            send_uart_byte(8'h62); // 'b'
        end

        // Chờ Gearbox xử lý byte cuối và Buffer xả toàn bộ dữ liệu ra
        // Quá trình xả 514 symbols mất 514 nhịp clock
        #(CLK_PERIOD * 1000);
        
        $display("---------------------------------------------------------");

        // ---------------------------------------------------------
        // SCENARIO 2: RS_DEC (rs_sel = 1) - 680 bytes ('c' / 'd')
        // ---------------------------------------------------------
        rs_sel = 1;
        $display("[%0t] SCENARIO 2: DECODER MODE (rs_sel = 1)", $time);

        for (k = 0; k < 680; k++) begin
            if (k % 2 == 0) send_uart_byte(8'h63); // 'c'
            else            send_uart_byte(8'h64); // 'd'
        end

        // Chờ Buffer xả toàn bộ 544 symbols
        #(CLK_PERIOD * 1000);
        
        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED.", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule
