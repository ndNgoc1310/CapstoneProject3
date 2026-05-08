`timescale 1ns / 1ps
// =====================================================================
// Module: wrapper_uart (Top-level)
// Chức năng: Nối dây các module con theo phong cách Structural
// =====================================================================

module wrapper_uart (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,     
    input  logic [9:0]  SW,      
    
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR,
    
    inout  wire  [35:0] GPIO 
);

    // ==========================================
    // Tín hiệu toàn cục
    // ==========================================
    logic clk, rst_n, mode;
    logic [1:0] disp_mode;

    assign clk       = CLOCK_50;
    assign rst_n     = KEY[0];
    assign mode      = SW[9];
    assign disp_mode = SW[4:3];

    // ==========================================
    // Tín hiệu kết nối giữa các module
    // ==========================================
    // UART Core <-> RX Gearbox
    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;
    
    // RX Gearbox <-> Input Buffer FIFO
    logic       gbx_rx_valid;
    logic [9:0] gbx_rx_data;
    
    // Input Buffer FIFO <-> RS Codec TOP
    logic       rx_codec_sop;
    logic       rx_codec_valid;
    logic [9:0] rx_codec_data;
    
    // RS Codec TOP <-> TX Buffer FIFO
    logic       enc_vld_out, dec_vld_out;
    logic [9:0] enc_dat_out, dec_dat_out;
    logic       enc_rdy, dec_rdy;
    logic       enc_sop_out, dec_sop_out;
    logic       enc_err, dec_err;
    logic [9:0] dec_err_mag;
    logic       dec_err_flg;

    logic       codec_vld_out;
    logic [9:0] codec_dat_out;
    logic       codec_rdy;

    assign codec_vld_out = (mode == 1'b0) ? enc_vld_out : dec_vld_out;
    assign codec_dat_out = (mode == 1'b0) ? enc_dat_out : dec_dat_out;
    assign codec_rdy     = (mode == 1'b0) ? enc_rdy : dec_rdy;

    // TX Buffer FIFO <-> UART Core
    logic [7:0] uart_tx_data;
    logic       uart_tx_wren;
    logic       uart_tx_fifo_full;

    // Ngoại vi
    logic [9:0] corr_cnt, disp_idx;
    logic [9:0] rd_dec_pos, rd_dec_mag;
    logic       enc_err_led, dec_err_led;

    // ==========================================
    // INSTANTIATION CÁC SUB-MODULE
    // ==========================================

    // 1. Lõi UART
    uart_core u_uart (
        .i_clk             (clk),
        .i_rst_n           (rst_n),
        .i_bclk_en         (1'b1),
        .i_baud_divisor    (-16'd27), 
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
        .i_rx_rden         (1'b1), 
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

    // 2. Hộp số chuyển từ 8-bit sang 10-bit
    uart_rx_gearbox u_rx_gearbox (
        .clk             (clk),
        .rst_n           (rst_n),
        .mode            (mode),
        .uart_rx_valid   (uart_rx_valid),
        .uart_rx_data    (uart_rx_data),
        .gbx_rx_valid    (gbx_rx_valid),
        .gbx_rx_data     (gbx_rx_data)
    );

    // 3. Hồ chứa (FIFO) kiểm soát luồng dữ liệu vào RS Codec (Chứa FSM)
    uart_rx_buffer u_rx_buffer (
        .clk             (clk),
        .rst_n           (rst_n),
        .mode            (mode),
        .codec_rdy       (codec_rdy),
        .gbx_rx_valid    (gbx_rx_valid),
        .gbx_rx_data     (gbx_rx_data),
        .rx_codec_sop    (rx_codec_sop),
        .rx_codec_valid  (rx_codec_valid),
        .rx_codec_data   (rx_codec_data)
    );

    // 4. Lõi Reed-Solomon
    top #(
        .WIDTH(10), .NSYM(30), .ORDER(15), .K(544)
    ) u_rs_codec_top (
        .clk             (clk),
        .rst_n           (rst_n),
        
        .enc_sop_in      ((mode == 1'b0) ? rx_codec_sop   : 1'b0),
        .enc_vld_in      ((mode == 1'b0) ? rx_codec_valid : 1'b0),
        .enc_dat_in      (rx_codec_data),
        .enc_sop_out     (enc_sop_out),
        .enc_vld_out     (enc_vld_out),
        .enc_dat_out     (enc_dat_out),
        .enc_rdy         (enc_rdy),
        .enc_err         (enc_err),
        
        .dec_sop_in      ((mode == 1'b1) ? rx_codec_sop   : 1'b0),
        .dec_vld_in      ((mode == 1'b1) ? rx_codec_valid : 1'b0),
        .dec_dat_in      (rx_codec_data),
        .dec_sop_out     (dec_sop_out),
        .dec_vld_out     (dec_vld_out),
        .dec_dat_out     (dec_dat_out),
        .dec_rdy         (dec_rdy),
        .dec_err         (dec_err),
        .dec_err_flg_out (dec_err_flg),
        .dec_err_mag_out (dec_err_mag)
    );

    // 5. Hồ chứa đầu ra & Hộp số tách từ 10-bit sang 8-bit
    uart_tx_buffer u_tx_buffer (
        .clk               (clk),
        .rst_n             (rst_n),
        .codec_vld_out     (codec_vld_out),
        .codec_dat_out     (codec_dat_out),
        .uart_tx_fifo_full (uart_tx_fifo_full),
        .uart_tx_wren      (uart_tx_wren),
        .uart_tx_data      (uart_tx_data)
    );

    // ==========================================
    // CÁC MODULE NGOẠI VI (Giao diện hiển thị)
    // ==========================================
    dec_err_track_ram u_err_track (
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

    disp_key_ctrl u_key_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .disp_mode   (disp_mode),
        .inj_cnt     (corr_cnt),
        .key_nxt     (KEY[2]),
        .key_prv     (KEY[3]),
        .disp_idx    (disp_idx)
    );

    hex_mux u_hex_mux (
        .disp_mode   (disp_mode),
        .inj_cnt     (10'd0), 
        .corr_cnt    (corr_cnt),
        .rd_inj_pos  (10'd0),
        .rd_inj_mag  (10'd0),
        .rd_dec_pos  (rd_dec_pos),
        .rd_dec_mag  (rd_dec_mag),
        .hex0 (HEX0), .hex1 (HEX1), .hex2 (HEX2),
        .hex3 (HEX3), .hex4 (HEX4), .hex5 (HEX5)
    );

    // Logic điều khiển LED
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_err_led <= 0;
            dec_err_led <= 0;
        end else begin
            if (enc_sop_out | enc_err) enc_err_led <= enc_err;
            if (dec_sop_out | dec_err) dec_err_led <= dec_err;
        end
    end

    assign LEDR = {disp_mode, 4'b0, codec_rdy, dec_err_led, enc_err_led, mode};

endmodule: wrapper_uart

// =====================================================================
// Sub-Module: uart_rx_gearbox
// Chức năng: Đóng gói luồng 8-bit thành 10-bit
// =====================================================================
module uart_rx_gearbox (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       mode,
    input  logic       uart_rx_valid,
    input  logic [7:0] uart_rx_data,
    
    output logic       gbx_rx_valid,
    output logic [9:0] gbx_rx_data
);
    logic [39:0] rx_buffer;
    logic [5:0]  rx_bit_cnt;
    logic [9:0]  rx_byte_cnt;
    logic [9:0]  target_bytes;
    
    assign target_bytes = (mode == 1'b0) ? 10'd642 : 10'd680;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gbx_rx_valid    <= 0;
            gbx_rx_data     <= '0;
            rx_buffer       <= '0;
            rx_bit_cnt      <= '0;
            rx_byte_cnt     <= '0;
        end else begin            
            if (uart_rx_valid) begin
                gbx_rx_valid    <= 0;
                gbx_rx_data     <= '0;
                rx_buffer       <= (rx_buffer << 8) | uart_rx_data;
                rx_bit_cnt      <= rx_bit_cnt + 6'd8;
                rx_byte_cnt     <= rx_byte_cnt + 10'd1;
            end 
            else if (rx_bit_cnt >= 6'd10) begin
                gbx_rx_valid    <= 1'b1;
                gbx_rx_data     <= 10'((rx_buffer >> (rx_bit_cnt - 6'd10)) & 40'h3FF);
                rx_buffer       <= rx_buffer;
                rx_bit_cnt      <= rx_bit_cnt - 6'd10;
                rx_byte_cnt     <= rx_byte_cnt;
            end 
            else if (rx_byte_cnt == target_bytes) begin
                gbx_rx_valid    <= 1'b1;
                gbx_rx_data     <= 10'((rx_buffer << (6'd10 - rx_bit_cnt)) & 40'h3FF);
                rx_buffer       <= '0;
                rx_bit_cnt      <= '0;
                rx_byte_cnt     <= '0;
            end
            else begin
                gbx_rx_valid    <= 1'b0;
                gbx_rx_data     <= '0;
                rx_buffer       <= rx_buffer;
                rx_bit_cnt      <= rx_bit_cnt;
                rx_byte_cnt     <= rx_byte_cnt;
            end
        end
    end
endmodule: uart_rx_gearbox

// =====================================================================
// Sub-Module: uart_rx_buffer
// Chức năng: Input FIFO sử dụng 3-block FSM điều khiển việc Flush (Xả data)
// =====================================================================
module uart_rx_buffer (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       mode,
    input  logic       codec_rdy,
    input  logic       gbx_rx_valid,
    input  logic [9:0] gbx_rx_data,
    
    output logic       rx_codec_sop,
    output logic       rx_codec_valid,
    output logic [9:0] rx_codec_data
);

    // --- Khai báo Data Path (Memory & Counters) ---
    logic [9:0]  in_fifo_mem [0:1023];
    logic [9:0]  in_fifo_wr_ptr;
    logic [9:0]  in_fifo_rd_ptr;
    logic [10:0] in_fifo_count;
    logic [9:0]  target_symbols;
    logic [9:0]  flush_cnt;
    
    assign target_symbols = (mode == 1'b0) ? 10'd514 : 10'd544;

    // --- Định nghĩa FSM ---
    typedef enum logic {
        IDLE, 
        FLUSH
    } state_t;

    state_t state_cur, state_nxt;
    logic flushing;

    // Nhóm 1: Output Logic (always_comb)
    always_comb begin
        case (state_cur)
            IDLE:  flushing = 1'b0;
            FLUSH: flushing = 1'b1;
            default: flushing = 1'b0;
        endcase
    end

    // Nhóm 2: Next State Logic (always_comb)
    always_comb begin
        case (state_cur)
            IDLE: begin
                // Đủ 1 gói tin VÀ bộ giải mã rảnh thì mới chuyển state sang xả lũ
                if (in_fifo_count >= target_symbols && codec_rdy) 
                    state_nxt = FLUSH;
                else                                              
                    state_nxt = IDLE;
            end
            FLUSH: begin
                // Xả tới symbol cuối cùng thì quay về IDLE
                if (flush_cnt == target_symbols - 1)              
                    state_nxt = IDLE;
                else                                              
                    state_nxt = FLUSH;
            end
            default: state_nxt = IDLE;
        endcase
    end

    // Nhóm 3: State Register Update (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state_cur <= IDLE;
        else        state_cur <= state_nxt;
    end

    // --- Datapath Logic (Ghi và Đọc FIFO) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_fifo_wr_ptr <= '0;
            in_fifo_count  <= '0;
        end else begin
            if (gbx_rx_valid) begin
                in_fifo_mem[in_fifo_wr_ptr] <= gbx_rx_data;
                in_fifo_wr_ptr <= in_fifo_wr_ptr + 10'd1;
            end

            // Quản lý biến đếm số lượng data trong kho
            if (gbx_rx_valid && !flushing) begin
                in_fifo_count <= in_fifo_count + 11'd1;
            end else if (!gbx_rx_valid && flushing) begin
                in_fifo_count <= in_fifo_count - 11'd1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_fifo_rd_ptr <= '0;
            flush_cnt      <= '0;
            rx_codec_valid <= 1'b0;
            rx_codec_sop   <= 1'b0;
            rx_codec_data  <= '0;
        end else begin
            if (flushing) begin
                rx_codec_data  <= in_fifo_mem[in_fifo_rd_ptr];
                rx_codec_valid <= 1'b1;
                rx_codec_sop   <= (flush_cnt == 0); // Đánh dấu SOP ở nhịp đầu tiên
                in_fifo_rd_ptr <= in_fifo_rd_ptr + 10'd1;
                flush_cnt      <= flush_cnt + 10'd1;
            end else begin
                rx_codec_valid <= 1'b0;
                rx_codec_sop   <= 1'b0;
                flush_cnt      <= '0;
            end
        end
    end
endmodule: uart_rx_buffer

// =====================================================================
// Sub-Module: uart_tx_buffer
// Chức năng: Lưu trữ 10-bit từ RS Codec và dịch ra 8-bit đưa xuống UART
// =====================================================================
module uart_tx_buffer (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       codec_vld_out,
    input  logic [9:0] codec_dat_out,
    input  logic       uart_tx_fifo_full,
    
    output logic       uart_tx_wren,
    output logic [7:0] uart_tx_data
);
    // --- 1. FIFO Memory (Giữ nguyên logic cũ nhưng tách biệt) ---
    logic [9:0]  tx_fifo_mem [0:1023];
    logic [9:0]  tx_fifo_wr_ptr, tx_fifo_rd_ptr;
    logic [10:0] tx_fifo_count;
    logic        fifo_rd_signal;
    logic [9:0]  fifo_data_out;

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
            if (fifo_rd_signal) begin
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 10'd1;
            end
            // Cập nhật đếm kho
            if (codec_vld_out && !fifo_rd_signal)       tx_fifo_count <= tx_fifo_count + 11'd1;
            else if (!codec_vld_out && fifo_rd_signal)  tx_fifo_count <= tx_fifo_count - 11'd1;
        end
    end
    assign fifo_data_out = tx_fifo_mem[tx_fifo_rd_ptr];

    // --- 2. TX Gearbox FSM (Giải quyết triệt để việc đọc lặp) ---
    typedef enum logic [1:0] {IDLE, FETCH, PROC} state_t;
    state_t state_cur, state_nxt;

    logic [19:0] shift_reg;
    logic [4:0]  bit_left;
    logic [7:0]  raw_byte;

    // Khối 1: Output logic
    assign fifo_rd_signal = (state_cur == FETCH);
    assign uart_tx_data   = raw_byte; // Nếu cần đảo bit, thực hiện ở đây

    // Khối 2: Next State logic
    always_comb begin
        state_nxt = state_cur;
        case (state_cur)
            IDLE: begin
                // Chỉ lấy thêm data khi kho có đồ VÀ bồn chứa tạm đang cạn (< 8 bit)
                if (tx_fifo_count > 0 && bit_left < 5'd8) state_nxt = FETCH;
                else if (bit_left >= 5'd8)               state_nxt = PROC;
            end
            FETCH: begin
                state_nxt = PROC; // Đã ra lệnh đọc, chuyển sang băm
            end
            PROC: begin
                // Băm cho đến khi còn dưới 8 bit thì quay về IDLE để xem có cần lấy thêm không
                if (bit_left < 5'd8) state_nxt = IDLE;
            end
        endcase
    end

    // Khối 3: Datapath (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_cur    <= IDLE;
            shift_reg    <= '0;
            bit_left     <= '0;
            uart_tx_wren <= 1'b0;
            raw_byte     <= '0;
        end else begin
            state_cur    <= state_nxt;
            uart_tx_wren <= 1'b0;

            case (state_cur)
                FETCH: begin
                    // Dữ liệu từ RAM sẽ xuất hiện ở nhịp sau (khi state đã là PROC)
                end
                PROC: begin
                    if (fifo_rd_signal_delayed) begin // Dùng một cờ trễ 1 nhịp để bắt data từ RAM
                         shift_reg <= (shift_reg << 10) | fifo_data_out;
                         bit_left  <= bit_left + 5'd10;
                    end 
                    else if (bit_left >= 5'd8 && !uart_tx_fifo_full && !uart_tx_wren) begin
                         raw_byte     <= (shift_reg >> (bit_left - 5'd8)) & 8'hFF;
                         uart_tx_wren <= 1'b1;
                         bit_left     <= bit_left - 5'd8;
                    end
                end
            endcase
        end
    end

    // Cờ trễ để bắt dữ liệu RAM Sync
    logic fifo_rd_signal_delayed;
    always_ff @(posedge clk) fifo_rd_signal_delayed <= fifo_rd_signal;

endmodule

// =========================================================
// Các module phụ trợ (Giữ nguyên)
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
            dec_sym_cnt <= '0;
            corr_cnt <= '0;
        end else if (dec_vld_out) begin 
            if (dec_sop_out) begin
                dec_sym_cnt <= 10'd1;
                if (dec_err_flg) begin
                    dec_pos_mem[0]  <= 10'd543; 
                    dec_mag_mem[0]  <= dec_err_mag;
                    corr_cnt <= 10'd1;
                end else begin
                    corr_cnt <= 10'd0;
                end
            end else begin
                dec_sym_cnt <= dec_sym_cnt + 10'd1;
                if (dec_err_flg) begin
                    dec_pos_mem[corr_cnt]    <= 10'd543 - dec_sym_cnt;
                    dec_mag_mem[corr_cnt]    <= dec_err_mag;
                    corr_cnt                 <= corr_cnt + 10'd1;
                end
            end

            rd_pos <= dec_pos_mem[rev_rd_addr];
            rd_mag <= dec_mag_mem[rev_rd_addr];
        end
    end

    logic [9:0] rev_rd_addr;
    assign rev_rd_addr = (corr_cnt > 0) ? (corr_cnt - 10'd1 - rd_addr) : 10'd0;

endmodule: dec_err_track_ram

module disp_key_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  disp_mode,
    input  logic [9:0]  inj_cnt,
    input  logic        key_nxt,
    input  logic        key_prv,
    
    output logic [9:0]  disp_idx
);
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

    wire next_pressed = ~key_nxt_debounced & key_nxt_d;
    wire prev_pressed = ~key_prv_debounced & key_prv_d;

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
            2'b00: begin 
                hex_left_val  = inj_cnt;
                hex_right_val = corr_cnt;
            end
            2'b01: begin 
                hex_left_val  = (inj_cnt > 0) ? rd_inj_pos : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_pos : 10'd0;
            end
            2'b10: begin 
                hex_left_val  = (inj_cnt > 0) ? rd_inj_mag : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_mag : 10'd0;
            end
            default: begin
                hex_left_val  = '0;
                hex_right_val = '0;
            end
        endcase
    end

    led_7s_enc_dec_3d Display_Left (
        .dec_in    (hex_left_val),
        .enc_out_0 (hex3),
        .enc_out_1 (hex4),
        .enc_out_2 (hex5)
    );
    
    led_7s_enc_dec_3d Display_Right (
        .dec_in    (hex_right_val),
        .enc_out_0 (hex0),
        .enc_out_1 (hex1),
        .enc_out_2 (hex2)
    );
endmodule: hex_mux

module led_7s_enc_dec_1d (
	input   logic [3:0] dec_in,
	output  logic [6:0] enc_out
);

	always_comb begin
		case (dec_in)
			4'd0:		enc_out = 7'b100_0000;	// 0x40
			4'd1:		enc_out = 7'b111_1001;	// 0x79
			4'd2:		enc_out = 7'b010_0100;	// 0x24
			4'd3:		enc_out = 7'b011_0000;	// 0x30
			4'd4:		enc_out = 7'b001_1001;	// 0x19
			4'd5:		enc_out = 7'b001_0010;	// 0x12
			4'd6:		enc_out = 7'b000_0010;	// 0x02
			4'd7:		enc_out = 7'b111_1000;	// 0x78
			4'd8:		enc_out = 7'b000_0000;	// 0x00
			4'd9:		enc_out = 7'b001_0000;	// 0x10
			default:	enc_out = 7'b111_1111;	// all segments off
		endcase
	end

endmodule: led_7s_enc_dec_1d

module led_7s_enc_dec_3d (
	input   logic [9:0] dec_in,
	output  logic [6:0] enc_out_0, enc_out_1, enc_out_2
);

	logic [3:0] hundreds, tens, units;

	always_comb begin
		hundreds = (4)'(dec_in / 10'd100);
		tens = (4)'((dec_in % 10'd100) / 10'd10);
		units = (4)'(dec_in % 10'd10);
	end

	led_7s_enc_dec_1d Enc_0 (
		.dec_in		(units),
		.enc_out	(enc_out_0)
	);

	led_7s_enc_dec_1d Enc_1 (
		.dec_in		(tens),
		.enc_out	(enc_out_1)
	);

	led_7s_enc_dec_1d Enc_2 (
		.dec_in		(hundreds),
		.enc_out	(enc_out_2)
	);

endmodule: led_7s_enc_dec_3d
