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
