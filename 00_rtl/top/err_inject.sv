// =========================================================
// Module: err_inject.sv
// Function: Hardware Error Injection with PRBS/LFSR Memory Tracking
// =========================================================
module err_inject
#(
    parameter WIDTH = 10
)
(
    input  logic clk, rst_n,
    input  logic [2:0] mode_sw,
    input  logic sop_in, valid_in,
    input  logic [WIDTH-1:0] data_in,
    
    output logic sop_out, valid_out,
    output logic [WIDTH-1:0] data_out,
    
    // Memory Interface cho Wrapper đọc
    output logic [9:0] injected_count,
    input  logic [9:0] read_addr,        // Đọc lỗi thứ index (từ 0 -> 543)
    output logic [WIDTH-1:0] read_inj_pos,
    output logic [WIDTH-1:0] read_inj_mag
);

    logic [9:0] symbol_cnt;
    logic [9:0] target_err;
    logic inject_en;
    logic [WIDTH-1:0] noise;
    
    // RAM lưu Vị trí và Độ lớn lỗi đã chèn
    logic [WIDTH-1:0] pos_mem [0:543];
    logic [WIDTH-1:0] mag_mem [0:543];

    // Tạo tín hiệu tổ hợp "Tiên đoán" ngay tại nhịp SOP
    logic [9:0] current_sym;
    logic [9:0] current_inj_cnt;
    assign current_sym     = sop_in ? 10'd0 : symbol_cnt;
    assign current_inj_cnt = sop_in ? 10'd0 : injected_count;

    // =========================================================
    // 1. MẠCH SINH SỐ NGẪU NHIÊN (16-bit LFSR PRBS Generator)
    // Đa thức LFSR cực đại: x^16 + x^14 + x^13 + x^11 + 1
    // =========================================================
    logic [15:0] lfsr;
    wire lfsr_fb = lfsr[6] ^ lfsr[7] ^ lfsr[8] ^ lfsr[9];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            lfsr <= 16'hACE1; // Seed khác 0 (Rất quan trọng cho LFSR)
        end else if (valid_in) begin
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
    logic random_inject;
    always_comb begin
        case (mode_sw)
            3'b000: random_inject = 1'b0;
            3'b001: random_inject = ({lfsr[4], lfsr[2], lfsr[5], lfsr[6], lfsr[1], lfsr[0]} == 6'b0); // Xác suất 1/128 (~ 4 lỗi rải rác)
            3'b010: random_inject = (lfsr[7:0] == 8'b0); // Xác suất 1/256
            3'b011: random_inject = ({lfsr[2], lfsr[5], lfsr[6], lfsr[1], lfsr[0]} == 5'b0); // Xác suất 1/64  (~ 8.5 lỗi rải rác)
            3'b100: random_inject = ({lfsr[2], lfsr[5], lfsr[6], lfsr[1], lfsr[0]} == 5'b0); // Xác suất 1/64
            3'b101: random_inject = ({lfsr[6], lfsr[1], lfsr[0]} == 3'b0); // Xác suất 1/8   (~ 68 lỗi rải rác)
            default: random_inject = 1'b1;               // Chèn toàn bộ
        endcase
    end

    // ÉP BUỘC CHÈN LỖI (Force Inject): 
    // Nếu gần hết gói tin mà bộ ngẫu nhiên vẫn chưa chèn đủ target_err,
    // mạch sẽ ép buộc chèn lỗi vào tất cả các symbol còn lại cho đến khi đủ số lượng.
    logic force_inject;
    assign force_inject = (10'd544 - current_sym) <= (target_err - current_inj_cnt);

    // LOGIC DUY TRÌ LỖI CỤM (BURST ACTIVE)
    logic is_burst_mode;
    logic burst_active;
    
    assign is_burst_mode = (mode_sw == 3'b010);

    // Nếu đang ở Mode Burst VÀ đã chèn ít nhất 1 lỗi (tức là đã tìm được điểm Start) 
    // VÀ chưa đạt đủ target 15 lỗi -> Bắt buộc chèn liên tiếp ở các nhịp tiếp theo!
    assign burst_active = is_burst_mode && (current_inj_cnt > 0) && (current_inj_cnt < target_err);

    // Mạch quyết định chèn lỗi cuối cùng (OR của 3 điều kiện)
    assign inject_en = valid_in && (current_inj_cnt < target_err) && 
                       (random_inject || force_inject || burst_active);

    // =========================================================
    // 4. LOGIC TẠO ĐỘ LỚN LỖI NGẪU NHIÊN (RANDOM MAGNITUDE)
    // =========================================================
    logic [WIDTH-1:0] random_mag;
    // Lấy 10 bit từ LFSR. Nếu vô tình rơi vào 0 (không tạo ra lỗi), ép thành 1.
    assign random_mag = (lfsr[9:0] == 10'd0) ? 10'd1 : lfsr[9:0];

    assign noise = inject_en ? random_mag : 10'd0;

    // =========================================================
    // 5. CẬP NHẬT RAM LƯU TRỮ VÀ XUẤT DỮ LIỆU
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            symbol_cnt <= '0;
            injected_count <= '0;
        end else if (valid_in) begin
            if (sop_in) begin
                symbol_cnt <= 10'd1;
                if (inject_en) begin 
                    pos_mem[0] <= 10'd0;        
                    mag_mem[0] <= noise;        
                    injected_count <= 10'd1;
                end else begin
                    injected_count <= 10'd0;
                end
            end else begin
                symbol_cnt <= symbol_cnt + 10'd1;
                if (inject_en) begin
                    pos_mem[injected_count] <= current_sym;
                    mag_mem[injected_count] <= noise;
                    injected_count <= injected_count + 10'd1;
                end
            end
        end
    end

    // Giao tiếp luồng dữ liệu
    assign sop_out   = sop_in;
    assign valid_out = valid_in;
    assign data_out  = data_in ^ noise; // Cộng GF(2) là XOR
    
    // Giao tiếp RAM cho Wrapper
    assign read_inj_pos = pos_mem[read_addr];
    assign read_inj_mag = mag_mem[read_addr];

endmodule:err_inject
