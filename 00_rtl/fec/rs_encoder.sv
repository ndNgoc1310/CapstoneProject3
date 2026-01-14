// rs_encoder.sv

// Reed-Solomon (544, 514) Encoder for GF(2^10)
module rs_encoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sop,          // Đánh dấu bắt đầu một gói tin (Start of Packet)
    input  logic        valid_in,     // Tín hiệu valid cho data_in. Data_in chỉ có giá trị khi tín hiệu này mức cao
    input  logic [9:0]  data_in,      // Dữ liệu tin nhắn đầu vào 10-bit (tổng cộng 514 symbols)
    
    output logic        valid_out,    // Tín hiệu valid cho data_out
    output logic [9:0]  data_out,     // Dữ liệu Codeword ra (544 symbols) (bao gồm cả Message và Parity)
    output logic        ready         // Sẵn sàng nhận gói tin mới (High ở trạng thái IDLE)
);

    // --- Parameters ---
    localparam K = 514;               // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;               // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;             // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)

    // --- Internal Signals ---
    logic [9:0] res [NSYM-1:0];         // 30 thanh ghi LFSR lưu trữ trạng thái dư của phép chia (res[0] đến res[29])
    logic [9:0] mul_results [NSYM-1:0]; // Lưu kết quả sau khi nhân feedback với các hệ số g[i] từ 30 bộ nhân hằng số 
    logic [9:0] feedback;               // Tín hiệu phản hồi dùng để tính toán số dư
    logic [9:0] count;                  // Bộ đếm để quản lý số lượng symbol đã xử lý
    
    typedef enum logic [1:0] {IDLE, MSG, PARITY} state_t;   // Định nghĩa 3 trạng thái của máy FSM
    state_t state;  // Biến lưu trạng thái hiện tại

    // --- 1. Feedback Logic ---
    // Feedback được tạo ra bằng cách XOR data_in với hệ số bậc cao nhất của số dư hiện tại - thanh ghi bậc cao nhất (res[29])
    // Feedback chỉ hoạt động khi đang ở trạng thái nhận Message
    assign feedback = ((state == MSG) || (state == IDLE && sop)) ? (data_in ^ res[NSYM-1]) : 10'd0;

    // --- 2. Constant Multipliers Instantiation ---
    // Gọi 30 module nhân hằng số từ file gf_mul_constants.sv (đã gen từ Python) để tính toán song song
    // Mỗi module nhân feedback với một hệ số g_i của đa thức tạo mã g(x)
    gf_mul_const_g0  u0  (.a(feedback), .p(mul_results[0])); 
    gf_mul_const_g1  u1  (.a(feedback), .p(mul_results[1]));
    gf_mul_const_g2  u2  (.a(feedback), .p(mul_results[2]));
    gf_mul_const_g3  u3  (.a(feedback), .p(mul_results[3]));
    gf_mul_const_g4  u4  (.a(feedback), .p(mul_results[4]));
    gf_mul_const_g5  u5  (.a(feedback), .p(mul_results[5]));
    gf_mul_const_g6  u6  (.a(feedback), .p(mul_results[6]));
    gf_mul_const_g7  u7  (.a(feedback), .p(mul_results[7]));
    gf_mul_const_g8  u8  (.a(feedback), .p(mul_results[8]));
    gf_mul_const_g9  u9  (.a(feedback), .p(mul_results[9]));
    gf_mul_const_g10 u10 (.a(feedback), .p(mul_results[10]));
    gf_mul_const_g11 u11 (.a(feedback), .p(mul_results[11]));
    gf_mul_const_g12 u12 (.a(feedback), .p(mul_results[12]));
    gf_mul_const_g13 u13 (.a(feedback), .p(mul_results[13]));
    gf_mul_const_g14 u14 (.a(feedback), .p(mul_results[14]));
    gf_mul_const_g15 u15 (.a(feedback), .p(mul_results[15]));
    gf_mul_const_g16 u16 (.a(feedback), .p(mul_results[16]));
    gf_mul_const_g17 u17 (.a(feedback), .p(mul_results[17]));
    gf_mul_const_g18 u18 (.a(feedback), .p(mul_results[18]));
    gf_mul_const_g19 u19 (.a(feedback), .p(mul_results[19]));
    gf_mul_const_g20 u20 (.a(feedback), .p(mul_results[20]));
    gf_mul_const_g21 u21 (.a(feedback), .p(mul_results[21]));
    gf_mul_const_g22 u22 (.a(feedback), .p(mul_results[22]));
    gf_mul_const_g23 u23 (.a(feedback), .p(mul_results[23]));
    gf_mul_const_g24 u24 (.a(feedback), .p(mul_results[24]));
    gf_mul_const_g25 u25 (.a(feedback), .p(mul_results[25]));
    gf_mul_const_g26 u26 (.a(feedback), .p(mul_results[26]));
    gf_mul_const_g27 u27 (.a(feedback), .p(mul_results[27]));
    gf_mul_const_g28 u28 (.a(feedback), .p(mul_results[28]));
    gf_mul_const_g29 u29 (.a(feedback), .p(mul_results[29]));

    // --- 3. LFSR Update and State Machine ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 10'd0;
            for (int j=0; j<NSYM; j++) res[j] <= 10'd0; // Reset toàn bộ thanh ghi số dư
        end else begin
            case (state)

                // Hệ thống ở trạng thái nghỉ. Các thanh ghi res[0] đến res[29] được xóa về 0.
                // Tín hiệu: ready = 1, valid_out = 0.
                // Sự kiện kích hoạt: Khi sop (Start of Packet) và valid_in cùng lên mức cao, FSM chuyển sang trạng thái MSG.
                IDLE: begin
                    count <= 10'd0;
                    ready <= 1'b1;  // Sẵn sàng nhận dữ liệu
                    if (sop && valid_in) begin  // Khi bắt đầu có gói tin
                        state <= MSG;
                        ready <= 1'b0;  // Đang bận xử lý, hạ tín hiệu ready
                        // Cập nhật giá trị ban đầu cho LFSR từ symbol đầu tiên
                        res[0] <= mul_results[0];
                        for (int j=1; j<NSYM; j++) res[j] <= res[j-1] ^ mul_results[j];
                        count <= 10'd1;
                    end
                end

                // Trong suốt 514 chu kỳ clock, dữ liệu data_in được đưa thẳng ra data_out (Pass-through).
                // Cơ chế Feedback: Tại mỗi chu kỳ, một tín hiệu feedback được tính bằng data_in XOR res[29].
                // Cập nhật LFSR: Tín hiệu feedback được đưa qua 30 bộ nhân hằng số (g0, g1,..., g29). 
                // Kết quả nhân được XOR với giá trị thanh ghi trước đó để cập nhật trạng thái mới cho LFSR.

                // Khi bộ đếm count đạt giá trị K (514), toàn bộ nội dung của tin nhắn đã được xử lý.
                // Kết quả: Lúc này, 30 thanh ghi từ res[0] đến res[29] đang chứa "số dư" của phép chia đa thức, đây chính là các parity symbols.
                // Hành động: state chuyển sang PARITY, count reset về 0.
                MSG: begin
                    if (valid_in) begin
                        
                        // CHỈ cập nhật LFSR nếu chưa xử lý xong symbol cuối cùng (K=514)
                        if (count < K) begin

                            // Logic cập nhật LFSR: res[j] = res[j-1] ^ (feedback * g[j])
                            res[0] <= mul_results[0];
                            for (int j=1; j<NSYM; j++) begin
                                res[j] <= res[j-1] ^ mul_results[j];
                            end

                            count <= count + 10'd1; // Tăng bộ đếm symbol
                        end

                        // Chuyển sang PARITY sau khi đã xử lý xong symbol thứ 514 (count = 514)
                        if (count == K) begin
                            state <= PARITY;
                            count <= 10'd0;
                        end 
                    end 
                    else if (count == K) begin
                        // Trường hợp valid_in xuống thấp ngay sau symbol cuối
                        state <= PARITY;
                        count <= 10'd0;
                    end
                end

                // Trong 30 chu kỳ tiếp theo, hệ thống không nhận thêm dữ liệu.
                // Dịch chuyển thanh ghi: Ở mỗi chu kỳ, giá trị tại thanh ghi cao nhất (res[29]) được đẩy ra data_out.
                // Cơ chế dịch: Các giá trị từ thanh ghi thấp được dịch dần lên cao: res[j] <= res[j-1].
                // Kết thúc: Khi đã đẩy đủ 30 symbols (count == 29), hệ thống quay lại trạng thái IDLE.
                PARITY: begin
                    // Sau khi nhận xong Message, đẩy 30 symbols trong thanh ghi res ra ngoài
                    for (int j=NSYM-1; j>0; j--) res[j] <= res[j-1];    // Dịch chuyển các thanh ghi
                    res[0] <= 10'd0;    // Chèn 0 vào thanh ghi thấp nhất
                    
                    if (count == NSYM-1) begin  // Đã đẩy hết 30 mã Parity
                        state <= IDLE;  // Quay về chờ gói tin mới
                        count <= 10'd0; 
                    end else begin
                        count <= count + 10'd1;
                    end
                end
            endcase
        end
    end

    // --- 4. Output Logic ---
    // Nếu đang ở MSG, xuất trực tiếp data_in (vừa mã hóa vừa truyền) 
    // Nếu đang ở PARITY, xuất giá trị từ thanh ghi bậc cao nhất của LFSR
    assign data_out  = (state == MSG) ? data_in : 
                       (state == PARITY) ? res[NSYM-1] : 10'd0;

    // Tín hiệu valid_out báo hiệu dữ liệu ra đang hợp lệ trong cả 2 giai đoạn
    assign valid_out = (state == MSG) || (state == PARITY);

endmodule 
