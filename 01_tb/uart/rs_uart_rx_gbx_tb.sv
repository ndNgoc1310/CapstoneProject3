`timescale 1ns/1ps

module rs_uart_rx_gbx_tb;

    // ==========================================
    // Parameters
    // ==========================================
    parameter CLK_PERIOD = 20; // Clock hệ thống 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8680.5 ns

    // ==========================================
    // System Signals
    // ==========================================
    logic clk;
    logic rst_n;
    logic baud_clk; // Clock giả lập ứng với baud rate

    // UART Core Signals
    logic       rx_serial;
    logic       i_rx_en;
    logic       i_rx_rden;
    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;
    logic       uart_rx_fifo_empty;

    // Gearbox Signals
    logic       rs_sel; // 0: Encoder, 1: Decoder
    logic       gbx_rx_vld;
    logic [9:0] gbx_rx_dat;
    logic       gbx_rx_err;

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
    // Instantiation: UART Core (RX Only)
    // ==========================================
    uart_core u_uart (
        .i_clk             (clk),
        .i_rst_n           (rst_n),
        .i_bclk_en         (1'b1),
        .i_baud_divisor    (-16'd27), // 50MHz / (115200 * 16) = 27.12
        .i_parity_en       (1'b0),
        .i_even_parity     (1'b0),
        .i_dbg_lloopback   (1'b0),
        .i_dbg_sloopback   (1'b0),
        
        // TX ports (Tied off)
        .i_tx_en           (1'b0),
        .i_tx_data         (8'd0),
        .i_tx_wren         (1'b0),
        .i_tx_fifo_clr     (~rst_n),
        
        // RX ports
        .i_rx_en           (i_rx_en),
        .i_rx              (rx_serial),
        .i_rx_fifo_clr     (~rst_n),
        .i_rx_rden         (i_rx_rden),
        .o_rx_data         (uart_rx_data),
        .o_rx_done         (uart_rx_valid),
        .o_rx_fifo_empty   (uart_rx_fifo_empty),
        
        // Unused outputs
        .o_tx_idle(), .o_tx_done(), .o_tx_fifo_empty(), .o_tx_fifo_full(), 
        .o_tx_fifo_level(), .o_rx_idle(), .o_rx_fifo_full(), .o_rx_fifo_level(), 
        .o_rx_frame_error(), .o_rx_parity_error(), .o_rx_data_is_zero(), .o_tx()
    );

    // ==========================================
    // Instantiation: RS Enc RX Gearbox
    // ==========================================
    rs_uart_rx_gbx u_gbx (
        .clk           (clk),
        .rst_n         (rst_n),
        .uart_rx_vld   (uart_rx_valid), // Nối vào o_rx_done của UART
        .uart_rx_dat   (uart_rx_data),  // Nối vào o_rx_data của UART
        .rs_sel        (rs_sel),
        .gbx_rx_vld    (gbx_rx_vld),
        .gbx_rx_dat    (gbx_rx_dat),
        .gbx_rx_err    (gbx_rx_err)
    );

    // ==========================================
    // UART TX Emulator Task (PC gửi Data)
    // ==========================================
    task send_uart_byte(input logic [7:0] tx_data);
        integer i;
        begin
            rx_serial = 1'b0; // Start bit
            #(BIT_TIME);
            
            // Gửi dữ liệu: LSB trước (Bit 0 -> Bit 7)
            for (i = 0; i < 8; i++) begin
                rx_serial = tx_data[i]; 
                #(BIT_TIME);
            end
            
            rx_serial = 1'b1; // Stop bit
            #(BIT_TIME);
            
            // Độ trễ ngắt quãng giữa các byte
            #(BIT_TIME * 2); 
        end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================
    integer k;
    
    initial begin
        // Khởi tạo các tín hiệu
        rst_n     = 0;
        rx_serial = 1; // Mức Idle mặc định của chuẩn UART
        i_rx_en   = 1;
        
        // Tự động kéo dữ liệu liên tục ra khỏi FIFO ngay khi có
        // Lõi async_fifo bên trong UART đã có cơ chế bảo vệ empty, 
        // nên việc giữ rden=1 là hợp lệ.
        i_rx_rden = 1; 

        // Đợi hệ thống ổn định và nhả Reset
        #(CLK_PERIOD * 20);
        rst_n = 1; 
        #(CLK_PERIOD * 20);

        $display("[%0t] STARTING SIMULATION...", $time);

        // ---------------------------------------------------------
        // TÌNH HUỐNG 1: CHẾ ĐỘ ENCODER (rs_sel = 0)
        // ---------------------------------------------------------
        rs_sel = 0;
        $display("[%0t] TÌNH HUỐNG 1: RS_ENC_MODE. Gửi 642 bytes ('a'/'b')", $time);

        for (k = 0; k < 642; k++) begin
            if (k % 2 == 0) begin
                send_uart_byte(8'h61); // Gửi 'a' 
            end else begin
                send_uart_byte(8'h62); // Gửi 'b' 
            end
        end

        // Đợi module Gearbox xả nốt trạng thái LOAD_FINAL và hoàn tất chu kỳ
        #(BIT_TIME * 15); 
        
        $display("---------------------------------------------------------");

        // ---------------------------------------------------------
        // TÌNH HUỐNG 2: CHẾ ĐỘ DECODER (rs_sel = 1)
        // ---------------------------------------------------------
        rs_sel = 1;
        $display("[%0t] TÌNH HUỐNG 2: RS_DEC_MODE. Gửi 680 bytes ('c'/'d')", $time);

        for (k = 0; k < 680; k++) begin
            if (k % 2 == 0) begin
                send_uart_byte(8'h63); // Gửi 'c'
            end else begin
                send_uart_byte(8'h64); // Gửi 'd'
            end
        end

        // Đợi module hoàn tất chu kỳ
        #(BIT_TIME * 15);
        
        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED.", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule: rs_uart_rx_gbx_tb
