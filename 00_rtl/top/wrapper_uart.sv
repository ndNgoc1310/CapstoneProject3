// Module: wrapper_uart
// Dự án: Reed-Solomon Codec RS(544, 514) Demo qua External USB-to-TTL (Bypass HPS)
// Giao tiếp: Thuần FPGA logic, dùng GPIO_RX và GPIO_TX (Giao tiếp Hercules)
// =====================================================================

module wrapper_uart (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,     // KEY: Rst, KEY[1]: Nxt, KEY[2]: Prv
    input  logic [9:0]  SW,      // SW[3]: Mode (0=Enc, 1=Dec), SW[4:3]: Disp Mode
    
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR,
    
    // --- Giao tiếp UART trực tiếp qua GPIO ---
    inout  logic [35:0] GPIO 
);

    // ==========================================
    // 1. TÍN HIỆU ĐIỀU KHIỂN CHUNG
    // ==========================================
    logic clk, rst_n, mode;
    assign clk   = CLOCK_50;
    assign rst_n = KEY[0];
    assign mode  = SW[9];

    // ==========================================
    // 2. KHỞI TẠO UART IP CORE
    // ==========================================
    logic [7:0] uart_rx_data, uart_tx_data;
    logic       uart_rx_valid, uart_tx_wren;
    logic       uart_tx_fifo_full;

    uart_core u_uart (
        .i_clk             (clk),
        .i_rst_n           (rst_n),
        .i_bclk_en         (1'b1),
        .i_baud_divisor    (-16'd27),   // 50MHz / 115200
        .i_parity_en       (1'b0),
        .i_even_parity     (1'b0),
        .i_dbg_lloopback   (1'b0),
        .i_dbg_sloopback   (1'b0),
        
        .i_tx_en           (1'b1),
        .i_tx_data         (uart_tx_data),
        .i_tx_wren         (uart_tx_wren),
        .o_tx_idle         (),
        .o_tx_done         (),
        .i_tx_fifo_clr     (1'b0),
        .o_tx_fifo_empty   (),
        .o_tx_fifo_full    (uart_tx_fifo_full),
        .o_tx_fifo_level   (),
        
        .i_rx_en           (1'b1),
        .i_rx_rden         (1'b1), // Liên tục rút data từ FIFO của core
        .o_rx_data         (uart_rx_data),
        .o_rx_idle         (),
        .o_rx_done         (uart_rx_valid),
        .i_rx_fifo_clr     (1'b0),
        .o_rx_fifo_empty   (),
        .o_rx_fifo_full    (),
        .o_rx_fifo_level   (),
        .o_rx_frame_error  (),
        .o_rx_parity_error (),
        .o_rx_data_is_zero (),
        
        .o_tx              (GPIO[0]),
        .i_rx              (GPIO[1])
    );

    // ==========================================
    // 3. RX GEARBOX (8-bit to 10-bit) + FLUSH (Zero-padding)
    // ==========================================
    logic        rx_codec_sop, rx_codec_valid;
    logic [9:0]  rx_codec_data;
    
    logic [39:0] rx_buffer;
    logic [5:0]  rx_bit_cnt;
    logic [9:0]  rx_byte_cnt;
    logic [9:0]  rx_sym_cnt;
    logic [9:0]  target_bytes;
    
    // Encoder cần 642 bytes, Decoder cần 680 bytes
    assign target_bytes = (mode == 1'b0) ? 10'd642 : 10'd680;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_buffer      <= '0;
            rx_bit_cnt     <= '0;
            rx_byte_cnt    <= '0;
            rx_sym_cnt     <= '0;
            rx_codec_valid <= 0;
            rx_codec_sop   <= 0;
        end else begin
            rx_codec_valid <= 0;
            rx_codec_sop   <= 0;
            
            // Nếu có byte mới từ UART
            if (uart_rx_valid) begin
                rx_buffer   <= (rx_buffer << 8) | uart_rx_data;
                rx_bit_cnt  <= rx_bit_cnt + 6'd8;
                rx_byte_cnt <= (rx_byte_cnt == target_bytes - 1) ? 10'd0 : rx_byte_cnt + 10'd1;
            end 
            // Cắt 10 bit trên cùng đưa vào RS Codec
            else if (rx_bit_cnt >= 6'd10) begin
                rx_codec_data  <= (rx_buffer >> (rx_bit_cnt - 6'd10)) & 10'h3FF;
                rx_bit_cnt     <= rx_bit_cnt - 6'd10;
                rx_codec_valid <= 1'b1;
                
                if (rx_sym_cnt == 0) rx_codec_sop <= 1'b1;
                rx_sym_cnt <= (rx_sym_cnt == ((mode == 0) ? 10'd513 : 10'd543)) ? 10'd0 : rx_sym_cnt + 10'd1;
            end 
            // Flush cho trường hợp 642 bytes (còn lẻ 6 bit, phải zero-pad 4 bit '0' để đẩy ra symbol 514)
            else if (rx_byte_cnt == 0 && rx_bit_cnt > 0 && rx_bit_cnt < 6'd10) begin
                rx_codec_data  <= (rx_buffer << (6'd10 - rx_bit_cnt)) & 10'h3FF;
                rx_bit_cnt     <= 0;
                rx_codec_valid <= 1'b1;
                
                if (rx_sym_cnt == 0) rx_codec_sop <= 1'b1;
                rx_sym_cnt <= (rx_sym_cnt == ((mode == 0) ? 10'd513 : 10'd543)) ? 10'd0 : rx_sym_cnt + 10'd1;
            end
        end
    end

    // ==========================================
    // 4. KẾT NỐI REED-SOLOMON CODEC (TOP)
    // ==========================================
    logic enc_rdy, dec_rdy, enc_err, dec_err, dec_err_flg;
    logic enc_sop_out, dec_sop_out, enc_vld_out, dec_vld_out;
    logic [9:0] enc_dat_out, dec_dat_out, dec_err_mag;

    logic        codec_vld_out;
    logic [9:0]  codec_dat_out;

    assign codec_vld_out = (mode == 0) ? enc_vld_out : dec_vld_out;
    assign codec_dat_out = (mode == 0) ? enc_dat_out : dec_dat_out;

    top #(
        .WIDTH(10), .NSYM(30), .ORDER(15), .K(544)
    ) u_rs_codec_top (
        .clk             (clk),
        .rst_n           (rst_n),
        
        .enc_sop_in      ((mode == 0) ? rx_codec_sop : 1'b0),
        .enc_vld_in      ((mode == 0) ? rx_codec_valid : 1'b0),
        .enc_dat_in      (rx_codec_data),
        .enc_sop_out     (enc_sop_out),
        .enc_vld_out     (enc_vld_out),
        .enc_dat_out     (enc_dat_out),
        .enc_rdy         (enc_rdy),
        .enc_err         (enc_err),
        
        .dec_sop_in      ((mode == 1) ? rx_codec_sop : 1'b0),
        .dec_vld_in      ((mode == 1) ? rx_codec_valid : 1'b0),
        .dec_dat_in      (rx_codec_data),
        .dec_sop_out     (dec_sop_out),
        .dec_vld_out     (dec_vld_out),
        .dec_dat_out     (dec_dat_out),
        .dec_rdy         (dec_rdy),
        .dec_err         (dec_err),
        .dec_err_flg_out (dec_err_flg),
        .dec_err_mag_out (dec_err_mag)
    );

    // ==========================================
    // 5. TX FIFO (Chống tràn) & GEARBOX (10-bit to 8-bit)
    // ==========================================
    // RS Codec xả 544 symbol ở 50MHz, tạo hồ chứa 1024x10-bit để UART truyền dần
    logic [9:0] tx_fifo_mem [0:1023];
    logic [9:0] tx_fifo_wr_ptr;
    logic [9:0] tx_fifo_rd_ptr;
    logic [10:0] tx_fifo_count;
    
    logic       tx_fifo_rd_en;
    logic [9:0] tx_fifo_q;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_wr_ptr <= 0;
            tx_fifo_rd_ptr <= 0;
            tx_fifo_count  <= 0;
        end else begin
            if (codec_vld_out) begin
                tx_fifo_mem[tx_fifo_wr_ptr] <= codec_dat_out;
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 10'd1;
            end
            if (tx_fifo_rd_en) begin
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 10'd1;
            end
            
            if (codec_vld_out && !tx_fifo_rd_en)
                tx_fifo_count <= tx_fifo_count + 11'd1;
            else if (!codec_vld_out && tx_fifo_rd_en)
                tx_fifo_count <= tx_fifo_count - 11'd1;
        end

        tx_fifo_q <= tx_fifo_mem[tx_fifo_rd_ptr];
    end
    
    wire tx_fifo_empty = (tx_fifo_count == 0);

    // TX Gearbox
    logic [19:0] tx_buffer;
    logic [4:0]  tx_bit_cnt;
    logic        reading_fifo;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_buffer     <= '0;
            tx_bit_cnt    <= '0;
            reading_fifo  <= 1'b0;
            tx_fifo_rd_en <= 1'b0;
            uart_tx_wren  <= 1'b0;
            uart_tx_data  <= '0;
        end else begin
            uart_tx_wren  <= 1'b0;
            tx_fifo_rd_en <= 1'b0;
            
            if (reading_fifo) begin
                tx_buffer    <= (tx_buffer << 10) | tx_fifo_q;
                tx_bit_cnt   <= tx_bit_cnt + 5'd10;
                reading_fifo <= 1'b0;
            end
            else if (tx_bit_cnt >= 5'd8) begin
                // Nếu uart_core rảnh, cắt 8 bit ép xuống TX
                if (!uart_tx_fifo_full && !uart_tx_wren) begin
                    uart_tx_data <= (tx_buffer >> (tx_bit_cnt - 5'd8)) & 8'hFF;
                    uart_tx_wren <= 1'b1;
                    tx_bit_cnt   <= tx_bit_cnt - 5'd8;
                end
            end
            else if (!tx_fifo_empty && !tx_fifo_rd_en) begin
                tx_fifo_rd_en <= 1'b1;
                reading_fifo  <= 1'b1;
            end
        end
    end

    // ==========================================
    // 6. THEO DÕI VÀ HIỂN THỊ LỖI (TRACKING RAM & LED)
    // ==========================================
    logic [9:0] corr_cnt, disp_idx;
    logic [9:0] rd_dec_pos, rd_dec_mag;
    logic enc_err_led, dec_err_led;
    
    // RAM lưu vết lỗi từ Decoder (Submodule từ file wrapper.sv của bạn)
    dec_err_track_ram DEC_RAM (
        .clk         (clk),
        .rst_n       (rst_n),
        .dec_vld_out (dec_vld_out),
        .dec_sop_out (dec_sop_out),
        .dec_err_flg (dec_err_flg),
        .dec_err_mag (dec_err_mag),
        .rd_addr     (disp_idx),
        .corr_cnt    (corr_cnt),
        .rd_pos      (rd_dec_pos),
        .rd_mag      (rd_dec_mag)
    );

    disp_key_ctrl KEY_CTRL (
        .clk         (clk),
        .rst_n       (rst_n),
        .disp_mode   (SW[4:3]),
        .inj_cnt     (corr_cnt),
        .key_nxt     (KEY[2]),
        .key_prv     (KEY[3]),
        .disp_idx    (disp_idx)
    );

    hex_mux HEX_DISP (
        .disp_mode   (SW[4:3]),
        .inj_cnt     (10'd0), 
        .corr_cnt    (corr_cnt),
        .rd_inj_pos  (10'd0),
        .rd_inj_mag  (10'd0),
        .rd_dec_pos  (rd_dec_pos),
        .rd_dec_mag  (rd_dec_mag),
        .hex0 (HEX0), .hex1 (HEX1), .hex2 (HEX2),
        .hex3 (HEX3), .hex4 (HEX4), .hex5 (HEX5)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_err_led <= 0;
            dec_err_led <= 0;
        end else begin
            if (enc_sop_out | enc_err) enc_err_led <= enc_err;
            if (dec_sop_out | dec_err) dec_err_led <= dec_err;
        end
    end

    // LEDR hiển thị Mode, Cờ Lỗi và trạng thái Sẵn sàng của bộ Gearbox
    assign LEDR = {SW[4:3], 5'b0, dec_err_led, enc_err_led, mode};

endmodule

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

