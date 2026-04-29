`timescale 1ns / 1ps
// =====================================================================
// Module: wrapper_uart
// Dự án: Reed-Solomon Codec RS(544, 514) Demo qua Hercules (UART)
// Thiết bị: Terasic DE10-Standard (Cyclone V)
// =====================================================================

module wrapper_uart (
    // --- Clock & Reset ---
    input  logic        CLOCK_50, 

    input  logic [3:0]  KEY,       
    input  logic [9:0]  SW,        

    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR,

    // --- HPS UART Physical Pins ---
    inout  wire         HPS_UART_RX,
    inout  wire         HPS_UART_TX,

    // --- HPS DDR3 Physical Pins (BẮT BUỘC ĐỂ KHẮC PHỤC LỖI 35030) ---
    output wire [12:0]  HPS_DDR3_ADDR,
    output wire [2:0]   HPS_DDR3_BA,
    output wire         HPS_DDR3_CAS_N,
    output wire         HPS_DDR3_CKE,
    output wire         HPS_DDR3_CK_N,
    output wire         HPS_DDR3_CK_P,
    output wire         HPS_DDR3_CS_N,
    output wire         HPS_DDR3_DM,
    inout  wire [7:0]   HPS_DDR3_DQ,
    inout  wire         HPS_DDR3_DQS_N,
    inout  wire         HPS_DDR3_DQS_P,
    output wire         HPS_DDR3_ODT,
    output wire         HPS_DDR3_RAS_N,
    output wire         HPS_DDR3_RESET_N,
    input  wire         HPS_DDR3_RZQ,
    output wire         HPS_DDR3_WE_N   
);

    // --- 1. Đặt tên gợi nhớ cho các chân I/O ---
    logic clk, rst_n, mode; 

    logic [1:0] disp_mode;

    logic [6:0] hex_led [5:0];
    logic       key_nxt, key_prv;
    logic       enc_err_led, dec_err_led;

    logic       uart_rxd, uart_txd;

    // --- 2. Khai báo các dây tín hiệu nội bộ nối giữa UART và TOP ---
    logic       rx_codec_ready;
    logic       rx_codec_sop;
    logic       rx_codec_valid;
    logic [9:0] rx_codec_data;

    logic       enc_vld_out, dec_vld_out;
    logic [9:0] enc_dat_out, dec_dat_out;
    logic       enc_rdy, dec_rdy;
    logic       enc_sop_out, dec_sop_out;
    logic       enc_err, dec_err;
    logic [9:0] dec_err_mag;
    logic       dec_err_flg;

    //
    logic [9:0] rd_dec_pos, rd_dec_mag;
    logic [9:0] corr_cnt;
    logic [9:0] disp_idx;

    // Khai báo mảng tín hiệu Loan I/O (mặc định của Cyclone V là 67 bit)
    logic [66:0] loan_io_in;
    logic [66:0] loan_io_out;
    logic [66:0] loan_io_oe;

    // --- 3. I/O MAPPING ---
    assign clk          = CLOCK_50;

    assign rst_n        = KEY[0];     // Nhấn nút KEY[0] để Reset toàn mạch
    assign key_nxt      = KEY[2];
    assign key_prv      = KEY[3];

    assign disp_mode    = SW[4:3]; 
    assign mode         = SW[9];     

    assign LEDR[0]      = rx_codec_ready;
    assign LEDR[1]      = enc_err_led;          // Cờ Error cho Encoder
    assign LEDR[2]      = dec_err_led;          // Cờ Error cho Decoder
    assign LEDR[9:8]    = disp_mode;
    
    assign HEX0         = hex_led[0];
    assign HEX1         = hex_led[1];
    assign HEX2         = hex_led[2];
    assign HEX3         = hex_led[3];
    assign HEX4         = hex_led[4];
    assign HEX5         = hex_led[5]; 

    assign uart_rxd         = loan_io_in[49];   // Lấy tín hiệu từ cáp USB chui qua HPS (loan_io_in) đưa vào module UART
    assign loan_io_out[50]  = uart_txd;         // Lấy tín hiệu từ module UART đẩy ngược ra HPS (loan_io_out) để lên cáp USB
    assign loan_io_oe[50]   = 1'b1;             // Cực kỳ quan trọng: Mở khóa xuất tín hiệu (Output Enable) cho chân số 50
    
    // --- 4. Instantiations ---

    // Khởi tạo khối HPS
    hps_uart_system u_hps (
        .clk_clk                           (clk),
        .reset_reset_n                     (rst_n),
        .loan_io_in                        (loan_io_in),     
        .loan_io_out                       (loan_io_out),    
        .loan_io_oe                        (loan_io_oe),
        .hps_io_hps_io_gpio_inst_LOANIO49  (HPS_UART_RX),
        .hps_io_hps_io_gpio_inst_LOANIO50  (HPS_UART_TX),

        // ĐỊNH TUYẾN CHÂN BỘ NHỚ HPS DDR3 RA TOP-LEVEL (KẾT NỐI ĐỦ BIT)
        .memory_mem_a                      (HPS_DDR3_ADDR),     // Đầy đủ 15 bit
        .memory_mem_ba                     (HPS_DDR3_BA),       // Đầy đủ 3 bit
        .memory_mem_ck                     (HPS_DDR3_CK_P),
        .memory_mem_ck_n                   (HPS_DDR3_CK_N),
        .memory_mem_cke                    (HPS_DDR3_CKE),
        .memory_mem_cs_n                   (HPS_DDR3_CS_N),
        .memory_mem_ras_n                  (HPS_DDR3_RAS_N),
        .memory_mem_cas_n                  (HPS_DDR3_CAS_N),
        .memory_mem_we_n                   (HPS_DDR3_WE_N),
        .memory_mem_reset_n                (HPS_DDR3_RESET_N),
        .memory_mem_dq                     (HPS_DDR3_DQ),       // Đầy đủ 32 bit
        .memory_mem_dqs                    (HPS_DDR3_DQS_P),    // Đầy đủ 4 bit
        .memory_mem_dqs_n                  (HPS_DDR3_DQS_N),    // Đầy đủ 4 bit
        .memory_mem_odt                    (HPS_DDR3_ODT),
        .memory_mem_dm                     (HPS_DDR3_DM),       // Đầy đủ 4 bit
        .memory_oct_rzqin                  (HPS_DDR3_RZQ)
    );


    // Instantiate Module UART (Hệ thống truyền thông) ---
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
        
        .tx_busy          ()
    );

    // --- Logic phân luồng (MUX/DEMUX) cho tín hiệu Ready ---
    // UART cần biết module nào (Enc hay Dec) đang sẵn sàng để rút data từ FIFO
    assign rx_codec_ready = (mode == 1'b0) ? enc_rdy : dec_rdy;

    // Instantiate Module TOP (Bộ não RS Codec) 
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
        
        .enc_sop_out   (enc_sop_out), 
        .enc_vld_out   (enc_vld_out),
        .enc_dat_out   (enc_dat_out),
        .enc_rdy       (enc_rdy),
        .enc_err       (enc_err), 
        
        // --- Giao diện Decoder ---
        // Chỉ cấp Valid/SOP cho Decoder nếu đang ở mode 1
        .dec_sop_in    ((mode == 1'b1) ? rx_codec_sop   : 1'b0),
        .dec_vld_in    ((mode == 1'b1) ? rx_codec_valid : 1'b0),
        .dec_dat_in    (rx_codec_data), // Data chung
        
        .dec_sop_out   (dec_sop_out), 
        .dec_vld_out   (dec_vld_out),
        .dec_dat_out   (dec_dat_out),
        .dec_rdy       (dec_rdy),
        .dec_err       (dec_err), 
        
        // Các tín hiệu giám sát lỗi (Monitor) có thể nối vào bộ hiển thị LED 7 đoạn nếu cần
        .dec_err_flg_out (dec_err_flg),
        .dec_err_mag_out (dec_err_mag)
    );

    // Decoder Error Tracking RAM (Lưu lịch sử sửa lỗi)
    dec_err_track_ram DEC_RAM (
        .clk                (clk),
        .rst_n              (rst_n),
        .dec_vld_out        (dec_vld_out),
        .dec_sop_out        (dec_sop_out),
        .dec_err_flg        (dec_err_flg),
        .dec_err_mag        (dec_err_mag),
        .rd_addr            (disp_idx),
        .corr_cnt           (corr_cnt),
        .rd_pos             (rd_dec_pos),
        .rd_mag             (rd_dec_mag)
    );

    // Hiển thị & Điều khiển KEY
    disp_key_ctrl KEY_CTRL (
        .clk            (clk),
        .rst_n          (rst_n),
        .disp_mode      (disp_mode),
        .inj_cnt        (corr_cnt),
        .key_nxt        (key_nxt),
        .key_prv        (key_prv),
        .disp_idx       (disp_idx)
    );

    // Hex Multiplexing (Trích xuất ra 6 LED 7 đoạn)
    hex_mux HEX_DISP (
        .disp_mode      (disp_mode),
        .inj_cnt        ('0),
        .corr_cnt       (corr_cnt),
        .rd_inj_pos     ('0),
        .rd_inj_mag     ('0),
        .rd_dec_pos     (rd_dec_pos),
        .rd_dec_mag     (rd_dec_mag),
        .hex0           (hex_led[0]),
        .hex1           (hex_led[1]),
        .hex2           (hex_led[2]),
        .hex3           (hex_led[3]),
        .hex4           (hex_led[4]),
        .hex5           (hex_led[5])
    );

    // Bắt (Capture) và chốt trạng thái lỗi của Encoder và Decoder
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            enc_err_led <= 1'b0;
            dec_err_led <= 1'b0;
        end else begin
            // Cập nhật LED báo lỗi khi có cờ báo lỗi hoặc reset lại khi bắt đầu gói tin mới (SOP)
            if (enc_sop_out | enc_err) enc_err_led <= enc_err;
            if (dec_sop_out | dec_err) dec_err_led <= dec_err;
        end
    end

endmodule: wrapper_uart

// =========================================================
// Module 1: DECODER ERROR TRACKING RAM
// Lưu trữ lịch sử các lỗi đã sửa được từ khối Decoder
// =========================================================
module dec_err_track_ram (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        dec_vld_out,
    input  logic        dec_sop_out,
    input  logic        dec_err_flg,
    input  logic [9:0]  dec_err_mag,
    input  logic [9:0]  rd_addr,
    
    output logic [9:0]  corr_cnt,
    output logic [9:0]  rd_pos,
    output logic [9:0]  rd_mag
);
    logic [9:0] dec_sym_cnt;
    logic [9:0] dec_pos_mem [0:543];
    logic [9:0] dec_mag_mem [0:543];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dec_sym_cnt     <= '0;
            corr_cnt <= '0;
        end else if (dec_vld_out) begin 
            if (dec_sop_out) begin
                dec_sym_cnt <= 10'd1;
                if (dec_err_flg) begin
                    // FIX: LIFO xuất symbol 543 đầu tiên
                    dec_pos_mem[0]  <= 10'd543; 
                    dec_mag_mem[0]  <= dec_err_mag;
                    corr_cnt <= 10'd1;
                end else begin
                    corr_cnt <= 10'd0;
                end
            end else begin
                dec_sym_cnt <= dec_sym_cnt + 10'd1;
                if (dec_err_flg) begin
                    // FIX: Quy đổi toạ độ ngược của LIFO về toạ độ gốc của gói tin
                    dec_pos_mem[corr_cnt]    <= 10'd543 - dec_sym_cnt;
                    dec_mag_mem[corr_cnt]    <= dec_err_mag;
                    corr_cnt                 <= corr_cnt + 10'd1;
                end
            end
        end
    end

    // FIX: Đảo ngược Index đọc mảng để Error đầu tiên vào trùng với Error đầu tiên ra
    logic [9:0] rev_rd_addr;
    assign rev_rd_addr = (corr_cnt > 0) ? (corr_cnt - 10'd1 - rd_addr) : 10'd0;

    assign rd_pos = dec_pos_mem[rev_rd_addr];
    assign rd_mag = dec_mag_mem[rev_rd_addr];

endmodule: dec_err_track_ram

// =========================================================
// Module 2: HIỂN THỊ & ĐIỀU KHIỂN KEY (Tiến/Lùi Index)
// Xử lý nút bấm, chống dội và điều hướng con trỏ Index RAM
// =========================================================
module disp_key_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  disp_mode,
    input  logic [9:0]  inj_cnt,
    input  logic        key_nxt,
    input  logic        key_prv,
    
    output logic [9:0]  disp_idx
);
    // --- Tạo Tick 10ms ---
    logic [18:0] tick_cnt;
    logic tick_10ms;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tick_cnt    <= 0;
            tick_10ms   <= 0;
        end else begin
            if (tick_cnt == 19'd500_000) begin
                tick_cnt    <= 0;
                tick_10ms   <= 1'b1;
            end else begin
                tick_cnt    <= tick_cnt + 19'd1;
                tick_10ms   <= 1'b0;
            end
        end
    end

    // --- Lấy mẫu nút bấm sau mỗi 10ms để triệt nhiễu cơ học ---
    logic key_nxt_debounced, key_prv_debounced;
    logic key_nxt_d, key_prv_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            key_nxt_debounced <= 1'b1;
            key_prv_debounced <= 1'b1;
        end else if (tick_10ms) begin
            key_nxt_debounced <= key_nxt;
            key_prv_debounced <= key_prv;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            key_nxt_d <= 1'b1;
            key_prv_d <= 1'b1;
        end else begin
            key_nxt_d <= key_nxt_debounced;
            key_prv_d <= key_prv_debounced;
        end
    end

    // Tạo xung 1 nhịp clock duy nhất khi phát hiện sườn xuống (Bấm nút)
    wire next_pressed = ~key_nxt_debounced & key_nxt_d;
    wire prev_pressed = ~key_prv_debounced & key_prv_d;

    // Logic điều hướng (Navigation)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            disp_idx <= 10'd0;
        end else begin
            if (disp_mode != 2'b00 && inj_cnt > 0) begin
                if (next_pressed) begin
                    if (disp_idx < inj_cnt - 10'd1) disp_idx <= disp_idx + 10'd1;
                    else disp_idx <= 10'd0;
                end 
                else if (prev_pressed) begin
                    if (disp_idx > 0) disp_idx <= disp_idx - 10'd1;
                    else disp_idx <= inj_cnt - 10'd1;
                end
            end else begin
                disp_idx <= 10'd0;
            end
        end
    end
endmodule: disp_key_ctrl

// =========================================================
// Module 3: HEX MULTIPLEXING (3 Chữ số)
// Điều phối dữ liệu để xuất ra 6 LED 7 đoạn
// =========================================================
module hex_mux (
    input  logic [1:0] disp_mode,
    input  logic [9:0] inj_cnt,
    input  logic [9:0] corr_cnt,
    input  logic [9:0] rd_inj_pos,
    input  logic [9:0] rd_inj_mag,
    input  logic [9:0] rd_dec_pos,
    input  logic [9:0] rd_dec_mag,
    
    output logic [6:0] hex0, hex1, hex2, hex3, hex4, hex5
);
    logic [9:0] hex_left_val, hex_right_val;
    
    always_comb begin
        case (disp_mode)
            2'b00: begin // Mode 0: SỐ LƯỢNG (Count)
                hex_left_val  = inj_cnt;
                hex_right_val = corr_cnt;
            end
            2'b01: begin // Mode 1: VỊ TRÍ (Position)
                hex_left_val  = (inj_cnt > 0) ? rd_inj_pos : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_pos : 10'd0;
            end
            2'b10: begin // Mode 2: ĐỘ LỚN (Magnitude)
                hex_left_val  = (inj_cnt > 0) ? rd_inj_mag : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_mag : 10'd0;
            end
            default: begin
                hex_left_val  = '0;
                hex_right_val = '0;
            end
        endcase
    end

    // Cụm trái: HEX5 (Trăm), HEX4 (Chục), HEX3 (Đơn vị)
    led_7s_enc_dec_3d Display_Left (
        .dec_in    (hex_left_val),
        .enc_out_0 (hex3),
        .enc_out_1 (hex4),
        .enc_out_2 (hex5)
    );
    
    // Cụm phải: HEX2 (Trăm), HEX1 (Chục), HEX0 (Đơn vị)
    led_7s_enc_dec_3d Display_Right (
        .dec_in    (hex_right_val),
        .enc_out_0 (hex0),
        .enc_out_1 (hex1),
        .enc_out_2 (hex2)
    );
endmodule: hex_mux

