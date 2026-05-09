// =========================================================
// Module Chính: WRAPPER
// Bọc tất cả các thành phần lại và map ra I/O thực tế của DE10-Standard
// =========================================================
module wrapper
(
    input  logic       CLOCK_50,
    
    input  logic [9:0] SW,
    input  logic [3:0] KEY,
    
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0] LEDR
);

    // --- 1. Đặt tên gợi nhớ cho các chân I/O ---
    logic clk, rst_n, start_test;

    logic [1:0] disp_mode;

    logic [6:0] hex_led [5:0];
    logic       key_nxt, key_prv;
    logic [2:0] mode_sw;
    logic       enc_err_led, dec_err_led;

    // --- 2. Tín hiệu kết nối nội bộ ---
    logic       enc_sop_in, enc_vld_in;
    logic [9:0] enc_dat_in;
    logic       enc_sop_out, enc_vld_out, enc_rdy, enc_err;
    logic [9:0] enc_dat_out;
    
    logic       dec_sop_in, dec_vld_in;
    logic [9:0] dec_dat_in;
    logic       dec_sop_out, dec_vld_out, dec_rdy, dec_err, dec_err_flg;
    logic [9:0] dec_err_mag;
    logic [9:0] dec_dat_out;
    
    logic [9:0] inj_cnt;
    logic [9:0] corr_cnt;
    logic [9:0] rd_inj_pos, rd_inj_mag;
    logic [9:0] rd_dec_pos, rd_dec_mag;
    logic [9:0] disp_idx;

    // --- 3. Instantiations ---

    // Hardware Data Generator
    msg_pumper #(.K(514)) PUMPER (
        .clk        (clk),
        .rst_n      (rst_n),
        .start_test (start_test),
        .enc_rdy    (enc_rdy),
        .enc_sop_in (enc_sop_in),
        .enc_vld_in (enc_vld_in),
        .enc_dat_in (enc_dat_in)
    );

    // Top-Level Codec (RS_ENC + RS_DEC)
    top #(.WIDTH(10), .NSYM(30), .ORDER(15), .K(544)) RS_CODEC_TOP (
        .clk                (clk),
        .rst_n              (rst_n),
        .enc_sop_in         (enc_sop_in),
        .enc_vld_in         (enc_vld_in),
        .enc_dat_in         (enc_dat_in),
        .enc_sop_out        (enc_sop_out),
        .enc_vld_out        (enc_vld_out),
        .enc_dat_out        (enc_dat_out),
        .enc_rdy            (enc_rdy),
        .enc_err            (enc_err),
        .dec_sop_in         (dec_sop_in),
        .dec_vld_in         (dec_vld_in),
        .dec_dat_in         (dec_dat_in),
        .dec_sop_out        (dec_sop_out),
        .dec_vld_out        (dec_vld_out),
        .dec_dat_out        (dec_dat_out),
        .dec_rdy            (dec_rdy),
        .dec_err            (dec_err),
        .dec_err_flg_out    (dec_err_flg),
        .dec_err_mag_out    (dec_err_mag)
    );

    // Error Injector (Khối chèn lỗi)
    err_inj #(.WIDTH(10)) INJECTOR (
        .clk            (clk),
        .rst_n          (rst_n),
        .mode_sw        (mode_sw), 
        .sop_in         (enc_sop_out),
        .vld_in         (enc_vld_out),
        .dat_in         (enc_dat_out),
        .sop_out        (dec_sop_in),
        .vld_out        (dec_vld_in),
        .dat_out        (dec_dat_in),
        .inj_cnt        (inj_cnt),
        .rd_addr        (disp_idx),
        .rd_inj_pos     (rd_inj_pos),
        .rd_inj_mag     (rd_inj_mag)
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
        .inj_cnt        (inj_cnt),
        .key_nxt        (key_nxt),
        .key_prv        (key_prv),
        .disp_idx       (disp_idx)
    );

    // Hex Multiplexing (Trích xuất ra 6 LED 7 đoạn)
    hex_mux HEX_DISP (
        .disp_mode      (disp_mode),
        .inj_cnt        (inj_cnt),
        .corr_cnt       (corr_cnt),
        .rd_inj_pos     (rd_inj_pos),
        .rd_inj_mag     (rd_inj_mag),
        .rd_dec_pos     (rd_dec_pos),
        .rd_dec_mag     (rd_dec_mag),
        .hex0           (hex_led[0]),
        .hex1           (hex_led[1]),
        .hex2           (hex_led[2]),
        .hex3           (hex_led[3]),
        .hex4           (hex_led[4]),
        .hex5           (hex_led[5])
    );

    // LED Cờ Error cho Decoder
    flop_r_nb #(.WIDTH(1)) Enc_Error_LED (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (enc_sop_out | enc_err),
        .d     (enc_err), 
        .q     (enc_err_led) 
    );

    
    flop_r_nb #(.WIDTH(1)) Dec_Error_LED (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (dec_sop_out | dec_err),
        .d     (dec_err), 
        .q     (dec_err_led) 
    );

    // --- 4. I/O MAPPING ---
    assign clk          = CLOCK_50;

    assign rst_n        = KEY[0];
    assign start_test   = ~KEY[1]; 
    assign key_nxt      = KEY[2];
    assign key_prv      = KEY[3];

    // case(mode_sw)
    //     3'b000: target_err = 10'd0;
    //     3'b001: target_err = 10'd5;
    //     3'b010: target_err = 10'd15;    // Max correctable (burst)    
    //     3'b011: target_err = 10'd15;    // Max correctable
    //     3'b100: target_err = 10'd16;    // Uncorrectable
    //     3'b101: target_err = 10'd100;   // Case 100 lỗi
    //     3'b110: target_err = 10'd514;   // Hết Message
    //     3'b111: target_err = 10'd544;   // Toàn bộ gói tin
    //     default: target_err = 10'd0;
    // endcase

    assign mode_sw      = SW[2:0];
    assign disp_mode    = SW[4:3]; 

    assign LEDR[0]      = inj_cnt == corr_cnt;  // Cờ PASS
    assign LEDR[1]      = enc_err_led;          // Cờ Error cho Encoder
    assign LEDR[2]      = dec_err_led;          // Cờ Error cho Decoder
    assign LEDR[9:8]    = disp_mode;

    assign HEX0         = hex_led[0];
    assign HEX1         = hex_led[1];
    assign HEX2         = hex_led[2];
    assign HEX3         = hex_led[3];
    assign HEX4         = hex_led[4];
    assign HEX5         = hex_led[5];

endmodule: wrapper

// =========================================================
// Module 1: Hardware Data Generator (Message Pumper)
// Bơm đúng K symbols vào Encoder khi có tín hiệu start_test
// =========================================================
module msg_pumper 
#(
    parameter K = 514
)
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_test,
    input  logic        enc_rdy,    
    
    output logic        enc_sop_in,
    output logic        enc_vld_in,
    output logic [9:0]  enc_dat_in
);
    // --- Tạo Tick 10ms để Debounce (Fclk = 50MHz) ---
    logic [18:0]    tick_cnt;
    logic           tick_10ms;
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

    // --- Bắt sườn nút Start (Đã Debounce) ---
    logic start_debounced, start_d;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            start_debounced <= 1'b0;
            start_d         <= 1'b0;
        end else begin
            if (tick_10ms) start_debounced <= start_test;
            start_d <= start_debounced;
        end
    end
    wire start_pulse = start_debounced & ~start_d; // Chỉ tạo 1 xung duy nhất

    logic [9:0] msg_cnt;
    typedef enum logic [1:0] {GEN_IDLE, GEN_PUMP} gen_state_t;
    gen_state_t gen_state, gen_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) gen_state <= GEN_IDLE;
        else        gen_state <= gen_nxt;
    end

    always_comb begin
        case (gen_state)
            GEN_IDLE: begin
                // Chỉ bơm khi có xung nút bấm VÀ Encoder đang Ready
                if (start_pulse && enc_rdy) gen_nxt = GEN_PUMP;
                else                        gen_nxt = GEN_IDLE;
            end
            GEN_PUMP: begin
                if (msg_cnt == 10'(K - 1)) gen_nxt = GEN_IDLE;
                else                       gen_nxt = GEN_PUMP;
            end
            default: gen_nxt = GEN_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            msg_cnt     <= '0;
            enc_sop_in  <= 1'b0;
            enc_vld_in  <= 1'b0;
            enc_dat_in  <= '0;
        end else begin
            if (gen_state == GEN_IDLE) begin
                msg_cnt     <= '0;
                enc_sop_in  <= 1'b0;
                enc_vld_in  <= 1'b0;
                enc_dat_in  <= '0;
                if (start_pulse && enc_rdy) begin
                    enc_vld_in  <= 1'b1;
                    enc_sop_in  <= 1'b1;
                    enc_dat_in  <= 10'd0;
                end
            end 
            else if (gen_state == GEN_PUMP) begin
                msg_cnt     <= msg_cnt + 10'd1;
                enc_vld_in  <= 1'b1;
                enc_sop_in  <= 1'b0;
                enc_dat_in  <= msg_cnt + 10'd1;
                
                if (msg_cnt == 10'(K - 1)) begin
                    enc_vld_in  <= 1'b0;
                    enc_dat_in  <= '0;
                end
            end
        end
    end
endmodule: msg_pumper

// =========================================================
// Module 2: DECODER ERROR TRACKING RAM
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

        rd_pos <= dec_pos_mem[rev_rd_addr];
        rd_mag <= dec_mag_mem[rev_rd_addr];
    end

    // FIX: Đảo ngược Index đọc mảng để Error đầu tiên vào trùng với Error đầu tiên ra
    logic [9:0] rev_rd_addr;
    assign rev_rd_addr = (corr_cnt > 0) ? (corr_cnt - 10'd1 - rd_addr) : 10'd0;

endmodule: dec_err_track_ram

// =========================================================
// Module 3: HIỂN THỊ & ĐIỀU KHIỂN KEY (Tiến/Lùi Index)
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
// Module 4: HEX MULTIPLEXING (3 Chữ số)
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

// =========================================================
// Module: err_inj.sv
// Function: Hardware Error Injection with PRBS/LFSR Memory Tracking
// =========================================================
module err_inj
#(
    parameter WIDTH = 10
)
(
    input  logic                clk, rst_n,
    input  logic [2:0]          mode_sw,
    input  logic                sop_in, vld_in,
    input  logic [WIDTH-1:0]    dat_in,
    
    output logic                sop_out, vld_out,
    output logic [WIDTH-1:0]    dat_out,
    
    // Memory Interface cho Wrapper đọc
    output logic [9:0]          inj_cnt,
    input  logic [9:0]          rd_addr,    // Đọc lỗi thứ index (từ 0 -> 543)
    output logic [WIDTH-1:0]    rd_inj_pos,
    output logic [WIDTH-1:0]    rd_inj_mag
);

    logic [9:0]         sym_cnt;
    logic [9:0]         target_err;
    logic               inj_en;
    logic [WIDTH-1:0]   noise;
    
    // RAM lưu Vị trí và Độ lớn lỗi đã chèn
    logic [WIDTH-1:0] pos_mem [0:543];
    logic [WIDTH-1:0] mag_mem [0:543];

    // Tạo tín hiệu tổ hợp "Tiên đoán" ngay tại nhịp SOP
    logic [9:0] cur_sym;
    logic [9:0] cur_inj_cnt;
    assign cur_sym     = sop_in ? 10'd0 : sym_cnt;
    assign cur_inj_cnt = sop_in ? 10'd0 : inj_cnt;

    // =========================================================
    // 1. MẠCH SINH SỐ NGẪU NHIÊN (16-bit LFSR PRBS Generator)
    // Đa thức LFSR cực đại: x^16 + x^14 + x^13 + x^11 + 1
    // =========================================================
    logic [15:0] lfsr;
    wire lfsr_fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            lfsr <= 16'hACE1; // Seed khác 0 (Rất quan trọng cho LFSR)
        end else if (vld_in) begin
            lfsr <= {lfsr[14:0], lfsr_fb}; // Dịch trái và nạp feedback
        end
    end

    // =========================================================
    // 2. GIẢI MÃ SỐ LƯỢNG LỖI MỤC TIÊU
    // =========================================================
    always_comb begin
        case(mode_sw)
            3'b000: target_err = 10'd0;
            3'b001: target_err = 10'd5;
            3'b010: target_err = 10'd15;    // Max correctable (burst)    
            3'b011: target_err = 10'd15;    // Max correctable
            3'b100: target_err = 10'd16;    // Uncorrectable
            3'b101: target_err = 10'd100;   // Case 100 lỗi
            3'b110: target_err = 10'd514;   // Hết Message
            3'b111: target_err = 10'd544;   // Toàn bộ gói tin
            default: target_err = 10'd0;
        endcase
    end

    // =========================================================
    // 3. LOGIC XÁC ĐỊNH VỊ TRÍ LỖI NGẪU NHIÊN
    // =========================================================
    logic rand_inj;
    always_comb begin
        case (mode_sw)
            3'b000: rand_inj = 1'b0;
            3'b001: rand_inj = ({lfsr[15], lfsr[13], lfsr[7], lfsr[4], lfsr[1], lfsr[0]} == 6'b0);     // Xác suất 1/64
            3'b010: rand_inj = ({lfsr[14], lfsr[11], lfsr[6], lfsr[4], lfsr[1], lfsr[0]} == 6'b0);     // Xác suất 1/64
            3'b011: rand_inj = ({lfsr[15], lfsr[11], lfsr[4], lfsr[2], lfsr[0]} == 5'b0);              // Xác suất 1/32
            3'b100: rand_inj = ({lfsr[14], lfsr[9], lfsr[5], lfsr[1], lfsr[0]} == 5'b0);               // Xác suất 1/32
            3'b101: rand_inj = ({lfsr[15], lfsr[8], lfsr[0]} == 3'b0);                                 // Xác suất 1/8  
            default: rand_inj = 1'b1;                                                                  // Chèn toàn bộ
        endcase
    end

    // ÉP BUỘC CHÈN LỖI (Force Inject): 
    // Nếu gần hết gói tin mà bộ ngẫu nhiên vẫn chưa chèn đủ target_err,
    // mạch sẽ ép buộc chèn lỗi vào tất cả các symbol còn lại cho đến khi đủ số lượng.
    logic force_inj;
    assign force_inj = (10'd544 - cur_sym) <= (target_err - cur_inj_cnt);

    // LOGIC DUY TRÌ LỖI CỤM (BURST ACTIVE)
    logic is_burst_mode;
    logic burst_active;
    
    assign is_burst_mode = (mode_sw == 3'b010);

    // Nếu đang ở Mode Burst VÀ đã chèn ít nhất 1 lỗi (tức là đã tìm được điểm Start) 
    // VÀ chưa đạt đủ target 15 lỗi -> Bắt buộc chèn liên tiếp ở các nhịp tiếp theo!
    assign burst_active = is_burst_mode && (cur_inj_cnt > 0) && (cur_inj_cnt < target_err);

    // Mạch quyết định chèn lỗi cuối cùng (OR của 3 điều kiện)
    assign inj_en = vld_in && (cur_inj_cnt < target_err) && (rand_inj || force_inj || burst_active);

    // =========================================================
    // 4. LOGIC TẠO ĐỘ LỚN LỖI NGẪU NHIÊN (RANDOM MAGNITUDE)
    // =========================================================
    logic [WIDTH-1:0] rand_mag;
    // Lấy 10 bit từ LFSR. Nếu vô tình rơi vào 0 (không tạo ra lỗi), ép thành 1.
    assign rand_mag = (lfsr[9:0] == 10'd0) ? 10'd1 : 
                      (lfsr[9:0] > 10'd999) ?  10'd999 : lfsr[9:0];

    assign noise = inj_en ? rand_mag : 10'd0;

    // =========================================================
    // 5. CẬP NHẬT RAM LƯU TRỮ VÀ XUẤT DỮ LIỆU
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sym_cnt <= '0;
            inj_cnt <= '0;
        end else if (vld_in) begin
            if (sop_in) begin
                sym_cnt <= 10'd1;
                if (inj_en) begin 
                    pos_mem[0] <= 10'd0;        
                    mag_mem[0] <= noise;        
                    inj_cnt <= 10'd1;
                end else begin
                    inj_cnt <= 10'd0;
                end
            end else begin
                sym_cnt <= sym_cnt + 10'd1;
                if (inj_en) begin
                    pos_mem[inj_cnt] <= cur_sym;
                    mag_mem[inj_cnt] <= noise;
                    inj_cnt <= inj_cnt + 10'd1;
                end
            end
        end
    
        // Giao tiếp RAM cho Wrapper
        rd_inj_pos <= pos_mem[rd_addr];
        rd_inj_mag <= mag_mem[rd_addr];
    end

    // Giao tiếp luồng dữ liệu
    assign sop_out   = sop_in;
    assign vld_out = vld_in;
    assign dat_out  = dat_in ^ noise; // Cộng GF(2) là XOR
    


endmodule: err_inj

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
