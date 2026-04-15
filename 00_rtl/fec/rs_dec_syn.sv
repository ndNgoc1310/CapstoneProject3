module rs_dec_syn (
    input  logic        clk,        // Tín hiệu clock
    input  logic        rst_n,      // Reset (active low)
    input  logic        sop_in,     // Start of Packet (Bắt đầu gói tin)
    input  logic        valid_in,   // Báo hiệu dữ liệu vào hợp lệ
    input  logic [9:0]  data_in,    // Input R (Received Data) (10-bit)
    
    output logic        valid_out,  // Báo hiệu tính xong (kết thúc gói)
    output logic        ready,      // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic        error,      // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
    output logic [9:0]  syn_out [29:0] // Output song song 30 syndromes
);

   // --- Parameters ---
    localparam K = 514;               // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;               // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;             // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)

    // Mảng thanh ghi lưu trữ Syndrome 
    logic [9:0] feedback    [NSYM-1:0];
    logic [9:0] reg_in      [NSYM-1:0];
    logic [9:0] reg_out     [NSYM-1:0];
    logic [NSYM-1:0] reg_en;
    logic control;

    // --- 1. Feedback Logic ---
    // Logic này sẽ thực hiện phép AND giữa giá trị của thanh ghi syndrome hiện tại và tín hiệu control
    // để xác định khi nào thực hiện feedback
    // sau đó thực hiện phép XOR với dữ liệu đầu vào để tạo ra giá trị feedback mới cho mỗi thanh ghi syndrome.
    logic [9:0] and_feedback [NSYM-1:0];
    genvar i;
    generate
        for (i = 0; i < NSYM; i++) begin : FEEDBACK_LOGIC
            and_nb #(.WIDTH(10)) AND_feedback (
                .a(reg_out[i]), 
                .b({10{control}}), 
                .y(and_feedback[i]) 
            );

            xor_nb #(.WIDTH(10)) XOR_feedback (
                .a(and_feedback[i]), 
                .b(data_in), 
                .y(feedback[i]) 
            );
        end
    endgenerate

    // --- 2. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // Mỗi bộ nhân này sẽ nhận giá trị feedback từ bước trước và nhân với một hằng số alpha^i tương ứng 
    // để tạo ra giá trị mới cho thanh ghi syndrome tiếp theo.

    // S0: Nhân với alpha^0 = 1 (Thực tế là pass-through)
    gf_mul_const_alpha0  u0  (.a(feedback[0]),  .p(reg_in[0]));
    gf_mul_const_alpha1  u1  (.a(feedback[1]),  .p(reg_in[1]));
    gf_mul_const_alpha2  u2  (.a(feedback[2]),  .p(reg_in[2]));
    gf_mul_const_alpha3  u3  (.a(feedback[3]),  .p(reg_in[3]));
    gf_mul_const_alpha4  u4  (.a(feedback[4]),  .p(reg_in[4]));
    gf_mul_const_alpha5  u5  (.a(feedback[5]),  .p(reg_in[5]));
    gf_mul_const_alpha6  u6  (.a(feedback[6]),  .p(reg_in[6]));
    gf_mul_const_alpha7  u7  (.a(feedback[7]),  .p(reg_in[7]));
    gf_mul_const_alpha8  u8  (.a(feedback[8]),  .p(reg_in[8]));
    gf_mul_const_alpha9  u9  (.a(feedback[9]),  .p(reg_in[9]));
    gf_mul_const_alpha10 u10 (.a(feedback[10]), .p(reg_in[10]));
    gf_mul_const_alpha11 u11 (.a(feedback[11]), .p(reg_in[11]));
    gf_mul_const_alpha12 u12 (.a(feedback[12]), .p(reg_in[12]));
    gf_mul_const_alpha13 u13 (.a(feedback[13]), .p(reg_in[13]));
    gf_mul_const_alpha14 u14 (.a(feedback[14]), .p(reg_in[14]));
    gf_mul_const_alpha15 u15 (.a(feedback[15]), .p(reg_in[15]));
    gf_mul_const_alpha16 u16 (.a(feedback[16]), .p(reg_in[16]));
    gf_mul_const_alpha17 u17 (.a(feedback[17]), .p(reg_in[17]));
    gf_mul_const_alpha18 u18 (.a(feedback[18]), .p(reg_in[18]));
    gf_mul_const_alpha19 u19 (.a(feedback[19]), .p(reg_in[19]));
    gf_mul_const_alpha20 u20 (.a(feedback[20]), .p(reg_in[20]));
    gf_mul_const_alpha21 u21 (.a(feedback[21]), .p(reg_in[21]));
    gf_mul_const_alpha22 u22 (.a(feedback[22]), .p(reg_in[22]));
    gf_mul_const_alpha23 u23 (.a(feedback[23]), .p(reg_in[23]));
    gf_mul_const_alpha24 u24 (.a(feedback[24]), .p(reg_in[24]));
    gf_mul_const_alpha25 u25 (.a(feedback[25]), .p(reg_in[25]));
    gf_mul_const_alpha26 u26 (.a(feedback[26]), .p(reg_in[26]));
    gf_mul_const_alpha27 u27 (.a(feedback[27]), .p(reg_in[27]));
    gf_mul_const_alpha28 u28 (.a(feedback[28]), .p(reg_in[28]));
    gf_mul_const_alpha29 u29 (.a(feedback[29]), .p(reg_in[29]));

    // --- 3. Syndrome Register ---
    // Các thanh ghi này sẽ lưu trữ giá trị syndrome tạm thời trong quá trình tính toán.
    genvar j;
    generate
        for (j = 0; j < NSYM; j++) begin : SYN_REG
            flop_r #(.WIDTH(10)) Syn_Reg (
                .clk    (clk),
                .rstn   (rst_n | valid_out),    // Reset thanh ghi khi rst_n ở mức thấp hoặc khi đã hoàn thành gói tin (valid_out = 1)
                .en     (reg_en[j]),
                .d      (reg_in[j]),
                .q      (reg_out[j])
            );
        end
    endgenerate

    // --- 4. Output Logic ---    
    // Logic này sẽ xuất giá trị syndrome từ các thanh ghi ra output syn_out, 
    // nhưng chỉ khi valid_out ở mức cao (khi đã hoàn thành gói tin).
    genvar k;
    generate
        for (k = 0; k < NSYM; k++) begin : SYN_OUT
            and_nb #(.WIDTH(10)) AND_output (
                .a(reg_out[k]),         // Giá trị syndrome hiện tại từ thanh ghi
                .b({10{valid_out}}),    // Chỉ xuất giá trị syndrome khi valid_out ở mức cao (khi đã hoàn thành gói tin)
                .y(syn_out[k]) 
            );
        end
    endgenerate

    // --- 5. FSM Control Logic ---
    // FSM này sẽ điều khiển quá trình tính toán syndrome, 
    // bao gồm việc xác định khi nào bắt đầu tính toán (khi nhận được SOP), 
    // khi nào thực hiện feedback (sau khi nhận được symbol đầu tiên), 
    // và khi nào hoàn thành tính toán syndrome (khi đã nhận đủ N symbols). 
    // FSM cũng sẽ đảm bảo rằng module chỉ sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin hiện tại, 
    // và sẽ báo lỗi nếu có tín hiệu không hợp lệ trong quá trình tính toán syndrome.
    rs_dec_syn_ctrl Control_Unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .valid_in   (valid_in),
        .valid_out  (valid_out),
        .reg_en     (reg_en),
        .control    (control),
        .ready      (ready),
        .error      (error)
    );    

endmodule : rs_dec_syn

module rs_dec_syn_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sop_in,     // Start of Packet (Bắt đầu gói tin)
    input  logic        valid_in,   // Báo hiệu dữ liệu vào hợp lệ
    output logic        valid_out,  // Báo hiệu tính xong (kết thúc gói)
    output logic [29:0] reg_en,     // Tín hiệu enable cho từng thanh ghi syndrome
    output logic        control,    // Tín hiệu điều khiển chung cho toàn bộ module
    output logic        ready,      // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic        error       // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
);
    // --- Parameters ---
    localparam K = 514;     // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;     // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;   // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)
    
    // --- Internal Signals ---
    logic [9:0] current_count;  // Bộ đếm để theo dõi số lượng symbols đã nhận, được sử dụng để xác định khi nào chuyển từ trạng thái CALC1 sang CALC2 và khi nào hoàn thành tính toán syndrome
    logic [9:0] next_count;     // Giá trị tiếp theo của bộ đếm, được tính toán trong logic output của FSM dựa trên trạng thái hiện tại và tín hiệu đầu vào

    // FSM State Definition
    typedef enum logic [2:0] {
        IDLE,   // Chờ SOP
        CALC1,  // Đang tính toán syndrome ở chu kỳ đầu tiên (chỉ nhận dữ liệu vào mà chưa thực hiện feedback)
        CALC2,  // Đang tính toán syndrome ở các chu kỳ tiếp theo (đã thực hiện feedback)
        DONE,   // Đã hoàn thành tính toán syndrome sau khi nhận đủ N symbols
        ERROR   // Trạng thái lỗi nếu có tín hiệu không hợp lệ
    } state_t;

    state_t current_state, next_state;  // Trạng thái hiện tại và trạng thái tiếp theo của FSM

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (current_state)
            IDLE: begin
                valid_out   = 1'b0;     // Chỉ báo hiệu tính xong khi đã hoàn thành gói tin
                reg_en      = '0;       // Ban đầu không enable thanh ghi nào
                control     = 1'b0;     // Ban đầu không điều khiển gì cả
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau reset
                error       = 1'b0;     // Không có lỗi khi reset
                next_count  = 10'd0;    // Reset bộ đếm về 0 khi ở trạng thái IDLE
            end

            CALC1: begin
                valid_out   = 1'b0;
                reg_en      = '1;       // Enable tất cả thanh ghi syndrome để nhận dữ liệu đầu tiên 
                control     = 1'b0;     // Riêng trong chu kỳ đầu tiên, control vẫn là 0 để chỉ nhận dữ liệu vào mà chưa thực hiện feedback
                ready       = 1'b0;     // Không sẵn sàng nhận dữ liệu mới khi đang tính toán    
                error       = 1'b0;
                next_count  = 10'd1;    // Bắt đầu đếm từ 1 khi nhận được symbol đầu tiên (SOP) để theo dõi số lượng symbols đã nhận
            end

            CALC2: begin
                valid_out   = 1'b0;     
                reg_en      = '1;
                control     = 1'b1;     // Bắt đầu thực hiện feedback sau khi đã nhận được symbol đầu tiên
                ready       = 1'b0;     
                error       = 1'b0;
                next_count  = current_count + 10'd1;    // Tăng bộ đếm lên 1 cho mỗi symbol tiếp theo nhận được trong quá trình CALC2
            end

            DONE: begin
                valid_out   = 1'b1;     // Báo hiệu đã tính xong khi đã nhận đủ N symbols
                reg_en      = '1;       
                control     = 1'b1;     // Không quan tâm, giữ nguyên trạng thái control hiện tại
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b0;
                next_count  = current_count + 10'd1;    
            end

            ERROR: begin
                valid_out   = 1'b0;
                reg_en      = '0;
                control     = 1'b0;
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b1;     // Báo lỗi nếu có tín hiệu không hợp lệ khi đang ở trạng thái IDLE hoặc CALC
                next_count  = 10'd0;    // Reset bộ đếm về 0 khi rơi vào trạng thái lỗi
            end

            default: begin
                valid_out   = 1'b0;
                reg_en      = '0;
                control     = 1'b0;
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b1;     // Báo lỗi nếu có trạng thái không xác định
                next_count  = 10'd0;    
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (current_state)
            IDLE: begin
                if (~(sop_in | valid_in))   next_state = IDLE;    // Vẫn ở trạng thái IDLE nếu chưa nhận được SOP hoặc dữ liệu không hợp lệ  
                else if (sop_in & valid_in) next_state = CALC1;   // Chuyển sang trạng thái CALC1 khi nhận được SOP và dữ liệu hợp lệ
                else                        next_state = ERROR;   // Nếu sop_in và valid_in không cùng lên cao, chuyển sang trạng thái lỗi ERROR
            end

            CALC1: begin
                if (~sop_in & valid_in) next_state = CALC2; // Chuyển sang trạng thái CALC2 khi sop_in xuống thấp nhưng vẫn nhận được dữ liệu hợp lệ (bắt đầu chu kỳ tiếp theo)
                else                    next_state = ERROR; // Nếu sop_in không xuống thấp hoặc valid_in không hợp lệ, chuyển sang trạng thái lỗi ERROR
            end
// current_count[4] & current_count[3] & current_count[2] & current_count[1] & current_count[0]
            CALC2: begin
                if ((~sop_in & valid_in) & ~(current_count[9] & current_count[5]))      next_state = CALC2; // Tiếp tục ở lại trạng thái CALC2 nếu vẫn còn dữ liệu vào hợp lệ và chưa nhận đủ N symbols (count = 543, bit 9 và các bit [4:1] đều là 1)
                else if (~(sop_in | valid_in) & (current_count[9] & current_count[5]))  next_state = DONE;  // Khi đã nhận đủ N symbols (count = 543, bit 9 và các bit [4:1] đều là 1) và sop_in đã xuống thấp, chuyển sang trạng thái DONE để hoàn thành gói tin
                else                                                                    next_state = ERROR; // Nếu valid_in xuống thấp trước khi nhận đủ N symbols, hoặc sop_in vẫn còn cao sau khi đã nhận đủ N symbols, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
            end

            DONE: begin
                if (sop_in & valid_in)          next_state = CALC1; // Nếu nhận được gói tin mới ngay sau khi hoàn thành gói tin trước đó (sop_in và valid_in cùng lên cao) và bộ đếm đã đạt giá trị 545 (bit 9, bit 5 và bit 0 đều là 1), chuyển sang trạng thái CALC1 để bắt đầu tính toán syndrome cho gói tin mới
                else if (~(sop_in | valid_in))  next_state = IDLE;  // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                            next_state = ERROR; // Nếu có tín hiệu không hợp lệ (ví dụ: nhận được gói tin mới khi bộ đếm chưa đạt giá trị 545, hoặc nhận được gói tin mới ngay sau khi hoàn thành gói tin trước đó nhưng bộ đếm chưa đạt giá trị 545), chuyển sang trạng thái lỗi ERROR
            end

            ERROR: begin
                if (sop_in & valid_in)          next_state = CALC1; // Nếu nhận được gói tin mới sau khi đã rơi vào trạng thái lỗi, chuyển sang trạng thái CALC1 để bắt đầu tính toán syndrome cho gói tin mới
                else if (~(sop_in | valid_in))  next_state = IDLE;  // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                            next_state = ERROR; // Nếu có tín hiệu không hợp lệ, vẫn giữ nguyên trạng thái lỗi ERROR
            end

            default: next_state = ERROR;    // Nếu FSM rơi vào trạng thái không xác định, chuyển sang trạng thái lỗi ERROR
        endcase
    end

    // --- 3. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            current_state   <= IDLE;  // Reset về trạng thái IDLE khi rst_n ở mức thấp
            current_count   <= 10'd0;    // Reset bộ đếm về 0 khi rst_n ở mức thấp
        end
        else begin
            current_state <= next_state;   // Cập nhật trạng thái hiện tại với trạng thái tiếp theo ở mỗi chu kỳ đồng hồ
            current_count <= next_count;   // Cập nhật bộ đếm hiện tại với giá trị tiếp theo
        end
    end

endmodule : rs_dec_syn_ctrl
