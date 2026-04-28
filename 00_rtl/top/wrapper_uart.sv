`timescale 1ns / 1ps
// =====================================================================
// Module: wrapper_uart
// Dự án: Reed-Solomon Codec RS(544, 514) Demo qua Hercules (UART)
// Thiết bị: Terasic DE10-Standard (Cyclone V)
// =====================================================================

module wrapper_uart (
    // --- Clock & Reset ---
    input  logic         CLOCK_50,  // Xung clock 50MHz có sẵn trên board
    input  logic [3:0]   KEY,       // KEY[0] dùng làm rst_n (Active Low)

    // --- Switch điều khiển ---
    input  logic [9:0]   SW,        // SW[0] chọn Mode (0: Encoder, 1: Decoder)

    // --- LED hiển thị trạng thái (Tùy chọn) ---
    output logic [9:0]   LEDR       // LEDR[0] báo hiệu trạng thái UART Busy

    // --- Giao tiếp UART (Nối ra GPIO Header) ---
    // Lưu ý: Bạn cần nối chân GPIO[0] vào dây TX của cáp USB-UART
    // và chân GPIO[1] vào dây RX của cáp USB-UART.
    // input  logic [35:0]  GPIO       
);

    // --- 1. Đặt tên gợi nhớ cho các chân I/O ---
    logic clk, rst_n, mode;
    assign clk   = CLOCK_50;
    assign rst_n = KEY[0];     // Nhấn nút KEY[0] để Reset toàn mạch
    assign mode  = SW[9];      // Gạt SW[9] xuống: Hercules -> Encoder
                               // Gạt SW[9] lên:   Hercules -> Decoder

    // Chân vật lý UART (Tham chiếu theo sơ đồ GPIO trên DE10-Standard)
    logic uart_rxd, uart_txd;
    // assign uart_rxd = GPIO[0]; // Chân nhận dữ liệu từ PC gửi xuống
    // assign GPIO[1]  = uart_txd; // Chân truyền dữ liệu từ FPGA lên PC

    // --- 2. Khai báo các dây tín hiệu nội bộ nối giữa UART và TOP ---
    
    // Luồng dữ liệu từ UART RX -> đi vào RS Codec
    logic        rx_codec_ready;
    logic        rx_codec_sop;
    logic        rx_codec_valid;
    logic [9:0]  rx_codec_data;

    // Luồng dữ liệu từ RS Codec -> đi ra UART TX
    logic        enc_vld_out, dec_vld_out;
    logic [9:0]  enc_dat_out, dec_dat_out;
    logic        enc_rdy, dec_rdy;

    // --- 3. Instantiate Module UART (Hệ thống truyền thông) ---
    // Module này đã bao gồm uart_rx, uart_tx, FIFO và Gearbox
    uart #(
        .CLK_FREQ(50_000_000), 
        .BAUD_RATE(115200)
    ) u_uart_system (
        .clk              (clk),
        .rst_n            (rst_n),
        
        // Vật lý
        .rxd              (uart_rxd),
        .txd              (uart_txd),
        
        // Điều khiển
        .mode             (mode),
        
        // Kênh Nhận (UART -> Codec)
        .rx_codec_ready   (rx_codec_ready),
        .rx_codec_sop     (rx_codec_sop),
        .rx_codec_valid   (rx_codec_valid),
        .rx_codec_data    (rx_codec_data),
        
        // Kênh Truyền (Codec -> UART)
        .tx_enc_valid_out (enc_vld_out),
        .tx_enc_data_out  (enc_dat_out),
        .tx_dec_valid_out (dec_vld_out),
        .tx_dec_data_out  (dec_dat_out),
        
        .tx_busy          (LEDR[0]) // Đèn LEDR[0] sẽ sáng khi đang truyền dữ liệu
    );

    // --- 4. Logic phân luồng (MUX/DEMUX) cho tín hiệu Ready ---
    // UART cần biết module nào (Enc hay Dec) đang sẵn sàng để rút data từ FIFO
    assign rx_codec_ready = (mode == 1'b0) ? enc_rdy : dec_rdy;

    // --- 5. Instantiate Module TOP (Bộ não RS Codec) ---
    top #(
        .WIDTH(10), .NSYM(30), .ORDER(15), .K(544)
    ) u_rs_codec_top (
        .clk           (clk),
        .rst_n         (rst_n),
        
        // --- Giao diện Encoder ---
        // Chỉ cấp Valid/SOP cho Encoder nếu đang ở mode 0
        .enc_sop_in    ((mode == 1'b0) ? rx_codec_sop   : 1'b0),
        .enc_vld_in    ((mode == 1'b0) ? rx_codec_valid : 1'b0),
        .enc_dat_in    (rx_codec_data), // Data chung
        
        .enc_sop_out   (), // Không dùng trong demo này
        .enc_vld_out   (enc_vld_out),
        .enc_dat_out   (enc_dat_out),
        .enc_rdy       (enc_rdy),
        .enc_err       (LEDR[8]), // LEDR[8] sáng nếu Encoder gặp lỗi giao thức
        
        // --- Giao diện Decoder ---
        // Chỉ cấp Valid/SOP cho Decoder nếu đang ở mode 1
        .dec_sop_in    ((mode == 1'b1) ? rx_codec_sop   : 1'b0),
        .dec_vld_in    ((mode == 1'b1) ? rx_codec_valid : 1'b0),
        .dec_dat_in    (rx_codec_data), // Data chung
        
        .dec_sop_out   (), // Không dùng trong demo này
        .dec_vld_out   (dec_vld_out),
        .dec_dat_out   (dec_dat_out),
        .dec_rdy       (dec_rdy),
        .dec_err       (LEDR[9]), 
        
        // Các tín hiệu giám sát lỗi (Monitor) có thể nối vào bộ hiển thị LED 7 đoạn nếu cần
        .dec_err_flg_out (),
        .dec_err_mag_out ()
    );

endmodule: wrapper_uart
