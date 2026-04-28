`timescale 1ns / 1ps
// =====================================================================
// Module: uart.sv (Top-level UART Wrapper)
// Chức năng: Tích hợp UART RX và UART TX (Đã có MUX chọn luồng bên trong)
// Tương tác: Trực tiếp nối dây I/O vật lý và kết nối với module top.sv
// =====================================================================

module uart #(
    parameter CLK_FREQ   = 50_000_000, // Tần số hệ thống (50 MHz)
    parameter BAUD_RATE  = 115200,     // Tốc độ Baud Hercules
    parameter WIDTH      = 10,         // Độ rộng symbol GF(2^10)
    parameter FIFO_DEPTH = 1024        // Độ sâu FIFO
)(
    input  logic             clk,
    input  logic             rst_n,

    // ==========================================
    // 1. GIAO TIẾP VẬT LÝ VỚI MÁY TÍNH (Cáp USB/GPIO)
    // ==========================================
    input  logic             rxd,      // Chân nhận dữ liệu từ Hercules
    output logic             txd,      // Chân truyền dữ liệu lên Hercules

    // ==========================================
    // 2. TÍN HIỆU ĐIỀU KHIỂN CHUNG
    // ==========================================
    input  logic             mode,     // 0 = Chế độ Encoder, 1 = Chế độ Decoder

    // ==========================================
    // 3. KÊNH NHẬN (UART RX -> Hướng vào RS Codec)
    // ==========================================
    input  logic             rx_codec_ready, // RS Codec (enc hoặc dec) báo rảnh
    output logic             rx_codec_sop,   // Báo hiệu Symbol 10-bit đầu tiên
    output logic             rx_codec_valid, // Báo hiệu Symbol 10-bit hợp lệ
    output logic [WIDTH-1:0] rx_codec_data,  // Symbol 10-bit đã được "Bit-packed" từ UART RX

    // ==========================================
    // 4. KÊNH TRUYỀN (RS Codec -> Hướng ra UART TX)
    // ==========================================
    // --- Nguồn từ Encoder ---
    input  logic             tx_enc_valid_out, // Cờ Valid từ ngõ ra enc
    input  logic [WIDTH-1:0] tx_enc_data_out,  // Data 10-bit từ ngõ ra enc
    
    // --- Nguồn từ Decoder ---
    input  logic             tx_dec_valid_out, // Cờ Valid từ ngõ ra dec
    input  logic [WIDTH-1:0] tx_dec_data_out,  // Data 10-bit từ ngõ ra dec
    
    output logic             tx_busy           // Cờ báo UART TX đang bận (Tùy chọn hiển thị LED)
);

    // =================================================================
    // KHỞI TẠO MODULE: UART RECEIVER (RX)
    // =================================================================
    uart_rx #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .WIDTH      (WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_uart_rx (
        .clk         (clk),
        .rst_n       (rst_n),
        
        .rxd         (rxd),
        .mode        (mode),
        
        .codec_ready (rx_codec_ready),
        .codec_sop   (rx_codec_sop),
        .codec_valid (rx_codec_valid),
        .codec_data  (rx_codec_data)
    );

    // =================================================================
    // KHỞI TẠO MODULE: UART TRANSMITTER (TX)
    // (Đã tích hợp MUX chọn luồng enc/dec dựa trên mode)
    // =================================================================
    uart_tx #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .WIDTH      (WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_uart_tx (
        .clk           (clk),
        .rst_n         (rst_n),
        
        .mode          (mode),
        
        .enc_valid_out (tx_enc_valid_out),
        .enc_data_out  (tx_enc_data_out),
        
        .dec_valid_out (tx_dec_valid_out),
        .dec_data_out  (tx_dec_data_out),
        
        .txd           (txd),
        .tx_busy       (tx_busy)
    );

endmodule: uart
