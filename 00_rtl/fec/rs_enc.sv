// rs_enc.sv

// Reed-Solomon (544, 514) Encoder for GF(2^10)
module rs_enc (
    input  logic        clk,        // Tín hiệu clock
    input  logic        rst_n,      // Tín hiệu reset, active low
    input  logic        sop_in,     // Đánh dấu bắt đầu một gói tin (Start of Packet)
    input  logic        valid_in,   // Tín hiệu valid cho data_in. Data_in chỉ có giá trị khi tín hiệu này mức cao
    input  logic [9:0]  data_in,    // Dữ liệu tin nhắn đầu vào 10-bit (tổng cộng 514 symbols)
    
    output logic        sop_out,    // Đánh dấu bắt đầu một gói tin ra (Start of Packet)
    output logic        valid_out,  // Tín hiệu valid cho data_out
    output logic [9:0]  data_out,   // Dữ liệu Codeword ra (544 symbols) (bao gồm cả Message và Parity)
    output logic        ready,      // Sẵn sàng nhận gói tin mới (High ở trạng thái IDLE)
    output logic        error       // Báo hiệu gói tin không hợp lệ
);

    // --- Parameters ---
    localparam K = 514;     // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;     // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;   // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)

    // --- Internal Signals ---
    logic [9:0] reg_in  [NSYM-1:0];         // Tín hiệu đầu vào cho các thanh ghi LFSR, được tính toán từ feedback và các hệ số g[i]
    logic [9:0] reg_out [NSYM-1:0];         // Tín hiệu đầu ra từ các thanh ghi LFSR, lưu trữ trạng thái hiện tại của số dư trong quá trình chia đa thức
    logic reg_en;                           // Tín hiệu enable cho các thanh ghi LFSR 
    logic [9:0] feedback_mul_gi [NSYM-1:0]; // Lưu kết quả sau khi nhân feedback với các hệ số g[i] từ 30 bộ nhân hằng số 
    logic [9:0] xor_feedback;               // Tín hiệu trung gian sau khi XOR giữa data_in và thanh ghi bậc cao nhất của số dư, được sử dụng làm input cho các bộ nhân hằng số
    logic [9:0] feedback;                   // Tín hiệu phản hồi dùng để tính toán số dư
    logic control;                          // Biến điều khiển để xác định khi nào bắt đầu xuất parity sau khi đã xuất hết 514 symbols dữ liệu
    logic count_en;                         // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
    logic count_parity;                     // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu, dựa trên giá trị của bộ đếm (count = 513, bit 9 và bit 0 đều là 1)
    logic count_done;                       // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm (count = 542, bit [9] và bit [4:1] đều là 1)

    // --- 1. Feedback Logic ---
    // XOR giữa data_in với thanh ghi bậc cao nhất của số dư (reg_out[NSYM-1]) để tạo ra giá trị feedback mới, được sử dụng làm input cho các bộ nhân hằng số
    xor_nb #(.WIDTH(10)) XOR_feedback (
        .a  (data_in),
        .b  (reg_out[NSYM-1]),
        .y  (xor_feedback)
    );

    // AND giữa giá trị feedback mới (xor_feedback) với control để chặn việc feedback của quá trình xử lý bộ syndrome của từ mã trước bị cộng lan sang symbol đầu tiên của từ mã hiện tại
    and_nb #(.WIDTH(10)) AND_feedback (
        .a  (xor_feedback),
        .b  ({10{control}}), // Mở rộng control thành 10 bit để AND với xor_feedback 
        .y  (feedback)
    );

    // --- 2. GF Constant Multipliers Instantiation ---
    // Gọi 30 module nhân hằng số từ file gf_mul_constants.sv (đã gen từ Python) để tính toán song song
    // Mỗi module nhân feedback với một hệ số g_i của đa thức tạo mã g(x)
    gf_mul_const_g0  u0  (.a(feedback), .p(feedback_mul_gi[0])); 
    gf_mul_const_g1  u1  (.a(feedback), .p(feedback_mul_gi[1]));
    gf_mul_const_g2  u2  (.a(feedback), .p(feedback_mul_gi[2]));
    gf_mul_const_g3  u3  (.a(feedback), .p(feedback_mul_gi[3]));
    gf_mul_const_g4  u4  (.a(feedback), .p(feedback_mul_gi[4]));
    gf_mul_const_g5  u5  (.a(feedback), .p(feedback_mul_gi[5]));
    gf_mul_const_g6  u6  (.a(feedback), .p(feedback_mul_gi[6]));
    gf_mul_const_g7  u7  (.a(feedback), .p(feedback_mul_gi[7]));
    gf_mul_const_g8  u8  (.a(feedback), .p(feedback_mul_gi[8]));
    gf_mul_const_g9  u9  (.a(feedback), .p(feedback_mul_gi[9]));
    gf_mul_const_g10 u10 (.a(feedback), .p(feedback_mul_gi[10]));
    gf_mul_const_g11 u11 (.a(feedback), .p(feedback_mul_gi[11]));
    gf_mul_const_g12 u12 (.a(feedback), .p(feedback_mul_gi[12]));
    gf_mul_const_g13 u13 (.a(feedback), .p(feedback_mul_gi[13]));
    gf_mul_const_g14 u14 (.a(feedback), .p(feedback_mul_gi[14]));
    gf_mul_const_g15 u15 (.a(feedback), .p(feedback_mul_gi[15]));
    gf_mul_const_g16 u16 (.a(feedback), .p(feedback_mul_gi[16]));
    gf_mul_const_g17 u17 (.a(feedback), .p(feedback_mul_gi[17]));
    gf_mul_const_g18 u18 (.a(feedback), .p(feedback_mul_gi[18]));
    gf_mul_const_g19 u19 (.a(feedback), .p(feedback_mul_gi[19]));
    gf_mul_const_g20 u20 (.a(feedback), .p(feedback_mul_gi[20]));
    gf_mul_const_g21 u21 (.a(feedback), .p(feedback_mul_gi[21]));
    gf_mul_const_g22 u22 (.a(feedback), .p(feedback_mul_gi[22]));
    gf_mul_const_g23 u23 (.a(feedback), .p(feedback_mul_gi[23]));
    gf_mul_const_g24 u24 (.a(feedback), .p(feedback_mul_gi[24]));
    gf_mul_const_g25 u25 (.a(feedback), .p(feedback_mul_gi[25]));
    gf_mul_const_g26 u26 (.a(feedback), .p(feedback_mul_gi[26]));
    gf_mul_const_g27 u27 (.a(feedback), .p(feedback_mul_gi[27]));
    gf_mul_const_g28 u28 (.a(feedback), .p(feedback_mul_gi[28]));
    gf_mul_const_g29 u29 (.a(feedback), .p(feedback_mul_gi[29]));
    // Phép nhân với g30 không cần thiết vì g30 = 1, nên feedback_mul_gi[29] đã là kết quả sau khi nhân với g30

    // --- 3. GF Addition for LFSR Update ---
    // Cập nhật giá trị vào cho từng thanh ghi LFSR bằng cách XOR kết quả nhân hằng số với giá trị hiện tại của thanh ghi trước đó
    genvar j;
    generate
        for (j = 0; j < NSYM; j++) begin : REG_IN_CALC
            if (j == 0) begin : FIRST_REG
                assign reg_in[0] = feedback_mul_gi[0]; // Thanh ghi bậc thấp nhất chỉ nhận giá trị sau khi nhân hằng số g[0] với feedback, không có giá trị nào khác cộng vào
            end else begin : OTHER_REGS
                xor_nb #(.WIDTH(10)) XOR_RegIn (
                    .a(feedback_mul_gi[j]),
                    .b(reg_out[j-1]),
                    .y(reg_in[j])
                );
            end
        end
    endgenerate

    // --- 4. LFSR Update ---
    // Sử dụng flop_r_nb để lưu giá trị mới vào các thanh ghi LFSR ở mỗi chu kỳ đồng hồ
    // Tín hiệu enable cho các thanh ghi LFSR được điều khiển bởi FSM
    genvar i;
    generate
        for (i = 0; i < NSYM; i++) begin : LFSR_REGS
            flop_r_nb #(.WIDTH(10)) Reg (
                .clk   (clk),
                .rstn  (rst_n),
                .en    (reg_en),
                .d     (reg_in[i]), 
                .q     (reg_out[i]) 
            );
        end
    endgenerate

    // --- 5. Output Logic ---
    // Dữ liệu data_out được xuất lần lượt: đầu tiên là 514 symbols dữ liệu (data_in), sau đó là 30 symbols parity (reg_out[0] đến reg_out[29])
    mux_2_nb #(.WIDTH(10)) Output_Mux (
        .d0 (reg_out[NSYM-1]),  // Chọn parity từ thanh ghi bậc cao nhất sau khi đã xuất hết 514 symbols dữ liệu
        .d1 (data_in),          // Chọn data_in trong quá trình xuất 514 symbols dữ liệu
        .s  (control),          // Chuyển sang parity sau khi đã xuất hết 514 symbols dữ liệu
        .y  (data_out)          // Kết nối đầu ra data_out
    );

    // --- 6. Counter for Output Tracking ---
    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    rs_enc_cnt Counter (
        .clk            (clk),
        .rst_n          (rst_n),
        .count_en       (count_en),       // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
        .valid_out      (valid_out),      // Tín hiệu valid_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị (bao gồm cả message và parity)
        .ready          (ready),          // Tín hiệu ready từ FSM, cho biết khi nào sẵn sàng nhận gói tin mới
        .count_parity   (count_parity),   // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message), dựa trên giá trị của bộ đếm
        .count_done     (count_done)      // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm
    );

    // --- 7. FSM Control Logic ---
    // FSM để điều khiển quá trình mã hóa, quản lý khi nào bắt đầu xuất parity và khi nào sẵn sàng nhận gói tin mới
    rs_enc_ctrl Control_Unit (
        .clk            (clk),
        .rst_n          (rst_n),
        .sop_in         (sop_in),
        .valid_in       (valid_in),
        .count_parity   (count_parity),   
        .count_done     (count_done),    
        .sop_out        (sop_out),
        .valid_out      (valid_out),
        .reg_en         (reg_en),
        .count_en       (count_en),
        .control        (control),
        .ready          (ready),
        .error          (error)
    );

endmodule : rs_enc

// --------------------------------------------------------------

// Module bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
module rs_enc_cnt (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        count_en,       // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
    input  logic        valid_out,      // Tín hiệu valid_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị (bao gồm cả message và parity)
    input  logic        ready,          // Tín hiệu ready từ FSM, cho biết khi nào sẵn sàng nhận gói tin mới
    output logic        count_parity,   // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message), dựa trên giá trị của bộ đếm
    output logic        count_done      // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm
);

    // Internal signals for counter control
    logic [9:0] count_in;   // Tín hiệu đầu vào cho bộ đếm, được tính toán từ giá trị hiện tại của bộ đếm và tín hiệu valid_out để quyết định khi nào reset về 0 hoặc tăng lên 1
    logic [9:0] count_out;  // Tín hiệu đầu ra từ bộ đếm, lưu trữ số lượng symbols đã xuất ra, được sử dụng để xác định khi nào chuyển từ xuất message sang xuất parity và khi nào hoàn thành xuất codeword
    logic [9:0] count_next; // Tín hiệu trung gian để tính toán giá trị tiếp theo của bộ đếm

    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    flop_r_nb #(.WIDTH(10)) Counter (
        .clk   (clk),
        .rstn  (rst_n),
        .en    (count_en),
        .d     (count_in), 
        .q     (count_out) 
    );

    // Logic để tính toán giá trị tiếp theo của bộ đếm, được điều khiển bởi FSM
    add_nb #(.WIDTH(10)) Count_Adder (
        .a      (count_out),
        .b      (10'd1),
        .cin    (1'b0),
        .sum    (count_next),
        .cout   ()              // Không cần sử dụng tín hiệu carry out trong trường hợp này vì bộ đếm chỉ cần đếm đến 542
    );

    // Logic để reset bộ đếm về 0 khi có tín hiệu valid_out và ready cùng lên cao
    and_nb #(.WIDTH(10)) Count_Reset (
        .a  ({10{~(valid_out & ready)}}),   // Khi valid_out và ready cùng lên cao, tạo ra tín hiệu reset cho bộ đếm
        .b  (count_next),                   // Giá trị tiếp theo của bộ đếm sau khi cộng 1
        .y  (count_in)                      // Tín hiệu đầu vào cho bộ đếm, sẽ là count_next khi đang xuất message/parity, hoặc 0 khi bắt đầu gói tin mới
    );
    
    // Logic để xác định khi nào đã xuất đủ 514 symbols dữ liệu và khi nào đã xuất đủ 29 symbols parity dựa trên giá trị của bộ đếm (count = 513, bit 9 và bit 0 đều là 1)
    assign count_parity = count_out[9] & count_out[0];

    // Logic để xác định khi nào đã xuất đủ 29 symbols parity dựa trên giá trị của bộ đếm (count = 542, bit [9] và bit [4:1] đều là 1)
    assign count_done = count_out[9] & count_out[4] & count_out[3] & count_out[2] & count_out[1]; 

endmodule : rs_enc_cnt   

// --------------------------------------------------------------

// Module điều khiển FSM cho RS Encoder
module rs_enc_ctrl (
    input  logic clk,
    input  logic rst_n,
    input  logic sop_in,        // Đánh dấu bắt đầu một gói tin vào (Start of Packet)
    input  logic valid_in,      // Tín hiệu valid cho data_in, chỉ có giá trị khi đang nhận symbols dữ liệu (message)
    input  logic count_parity,  // Tín hiệu từ bộ đếm để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message)
    input  logic count_done,    // Tín hiệu từ bộ đếm để xác định khi nào đã xuất đủ 29 symbols parity
    output logic sop_out,       // Đánh dấu bắt đầu một gói tin ra (Start of Packet), chỉ được đánh dấu ở symbol đầu tiên của message
    output logic valid_out,     // Tín hiệu valid cho data_out, có giá trị trong suốt quá trình xuất message và parity
    output logic reg_en,        // Tín hiệu enable cho 30 thanh ghi LFSR, được điều khiển bởi FSM để cập nhật trong quá trình nhận message và xuất parity
    output logic count_en,      // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
    output logic control,       // Biến điều khiển để xác định khi nào bắt đầu xuất parity sau khi đã xuất hết 514 symbols dữ liệu
    output logic ready,         // Sẵn sàng nhận gói tin mới, chỉ ở mức cao khi FSM ở trạng thái IDLE hoặc sau khi hoàn thành xuất codeword
    output logic error          // Báo hiệu gói tin không hợp lệ, được đặt ở mức cao khi nhận được tín hiệu không hợp lệ trong quá trình IDLE hoặc MSG, hoặc khi FSM rơi vào trạng thái không xác định
);

    // --- Parameters ---
    localparam K = 514;     // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;     // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;   // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)

    // --- Internal Signals ---

    // Định nghĩa các trạng thái của FSM
    typedef enum logic [2:0] {
        IDLE,   // Trạng thái nghỉ, sẵn sàng nhận gói tin mới  
        MSG1,   // Trạng thái nhận và xuất symbols dữ liệu (message), sop_out chỉ được đánh dấu ở symbol đầu tiên
        MSG2,   // Trạng thái tiếp tục nhận và xuất symbols dữ liệu (message) sau symbol đầu tiên
        PARITY, // Trạng thái xuất symbols parity sau khi đã xuất hết 514 symbols dữ liệu
        DONE,   // Trạng thái xuất symbol parity cuối cùng và sẵn sàng nhận gói tin mới
        ERROR   // Trạng thái lỗi khi nhận được tín hiệu không hợp lệ (ví dụ sop_in hoặc valid_in không đúng) trong quá trình IDLE hoặc MSG
    } state_t;

    state_t state_current, state_next;  // Trạng thái hiện tại và trạng thái tiếp theo của FSM

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_current)
            IDLE: begin
                sop_out     = 1'b0;     // Không đánh dấu bắt đầu gói tin ra khi ở trạng thái IDLE 
                valid_out   = 1'b0;     // Dữ liệu đầu ra không có giá trị khi ở trạng thái IDLE
                reg_en      = 1'b0;       // Không enable bất kỳ thanh ghi LFSR nào khi ở trạng thái IDLE
                count_en    = 1'b0;     // Không enable bộ đếm khi ở trạng thái IDLE
                control     = 1'b0;     // Không quan tâm về control khi ở trạng thái IDLE, mặc định là 0
                ready       = 1'b1;     // Sẵn sàng nhận gói tin mới khi ở trạng thái IDLE
                error       = 1'b0;     // Không có lỗi khi ở trạng thái IDLE
            end

            MSG1: begin
                sop_out     = 1'b1;     // Chỉ đánh dấu sop_out ở symbol đầu tiên của message
                valid_out   = 1'b1;     // Dữ liệu đầu ra có giá trị trong suốt quá trình xuất message
                reg_en      = 1'b1;       // Enable tất cả các thanh ghi LFSR để cập nhật trong quá trình nhận message
                count_en    = 1'b1;     // Enable bộ đếm khi ở trạng thái MSG1
                control     = 1'b1;     // Bắt đầu với việc xuất message
                control     = 1'b1;     // Bắt đầu với việc xuất message
                ready       = 1'b0;     // Không sẵn sàng nhận dữ liệu mới khi đang xử lý message
                error       = 1'b0;   
            end

            MSG2: begin
                sop_out     = 1'b0;     // Chỉ đánh dấu sop_out ở symbol đầu tiên, sau đó hạ xuống
                valid_out   = 1'b1;   
                reg_en      = 1'b1;
                count_en    = 1'b1;     
                control     = 1'b1;    
                ready       = 1'b0;   
                error       = 1'b0;   
            end

            PARITY: begin
                sop_out     = 1'b0;    
                valid_out   = 1'b1;   
                reg_en      = 1'b1; 
                count_en    = 1'b1;
                control     = 1'b0;     // Chuyển sang xuất parity
                ready       = 1'b0;   
                error       = 1'b0;   
            end

            DONE: begin
                sop_out     = 1'b0;    
                valid_out   = 1'b1;   
                reg_en      = 1'b1;  
                count_en    = 1'b1;     // Enable bộ đếm để load giá trị 0 khi bắt đầu gói tin mới 
                control     = 1'b0;     
                ready       = 1'b1;     // Sẵn sàng nhận gói tin mới sau khi đã hoàn thành xuất codeword
                error       = 1'b0;   
            end

            ERROR: begin
                sop_out     = 1'b0;    
                valid_out   = 1'b0;     // Dữ liệu đầu ra không có giá trị khi ở trạng thái lỗi
                reg_en      = 1'b0;     // Không enable bất kỳ thanh ghi LFSR nào khi ở trạng thái lỗi
                count_en    = 1'b0;     // Không enable bộ đếm khi ở trạng thái lỗi
                control     = 1'b0;     // Không quan tâm về control khi ở trạng thái lỗi, mặc định là 0
                ready       = 1'b1;     // Sẵn sàng nhận gói tin mới khi ở trạng thái lỗi để có thể phục hồi sau lỗi
                error       = 1'b1;     // Báo hiệu lỗi khi ở trạng thái lỗi
            end

            default: begin
                sop_out     = 1'b0;    
                valid_out   = 1'b0;   
                reg_en      = 1'b0; 
                count_en    = 1'b0;
                control     = 1'b0;    
                ready       = 1'b1;   
                error       = 1'b1;     // Báo hiệu lỗi nếu FSM rơi vào trạng thái không xác định
            end
        endcase
    end

    // --- 3. FSM State Transition Logic ---
    always_comb begin
        case (state_current)
                IDLE: begin
                    if (~(sop_in | valid_in))   state_next = IDLE;      // Ở lại trạng thái IDLE nếu chưa có gói tin mới
                    else if (sop_in & valid_in) state_next = MSG1;      // Khi sop_in và valid_in cùng lên cao, chuyển sang trạng thái MSG để bắt đầu xử lý gói tin
                    else                        state_next = ERROR;     // Nếu sop_in và valid_in không cùng lên cao, chuyển sang trạng thái lỗi ERROR
                end

                MSG1: begin
                    if (~sop_in & valid_in) state_next = MSG2;  // Sau khi đã nhận được symbol đầu tiên của message, tiếp tục ở trạng thái MSG2 để nhận và xuất tiếp các symbols dữ liệu còn lại
                    else                    state_next = ERROR; // Nếu sop_in vẫn còn cao sau khi đã nhận symbol đầu tiên, hoặc valid_in xuống thấp trước khi nhận được symbol đầu tiên, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
                end

                MSG2: begin
                    if ((~sop_in & valid_in) & ~count_parity)       state_next = MSG2;      // Tiếp tục ở lại trạng thái MSG2 nếu vẫn còn dữ liệu message và chưa nhận đủ 514 symbols (count = 514, bit 9 và bit 1 đều là 1)
                    else if (~(sop_in | valid_in) & count_parity)   state_next = PARITY;    // Khi đã nhận đủ 514 symbols dữ liệu (count = 513, bit 9 và bit 0 đều là 1), chuyển sang trạng thái xuất parity
                    else                                            state_next = ERROR;     // Nếu valid_in xuống thấp trước khi nhận đủ 514 symbols, hoặc sop_in vẫn còn cao sau khi đã nhận symbol đầu tiên, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
                end

                PARITY: begin
                    if (~(sop_in | valid_in) & ~count_done)     state_next = PARITY;    // Khi chưa xuất đủ 29 symbols parity (count < 542), tiếp tục ở lại trạng thái PARITY để xuất tiếp các symbols parity còn lại
                    else if (~(sop_in | valid_in) & count_done) state_next = DONE;      // Khi đã xuất đủ 29 symbols parity (count = 542, bit [9:1] đều là 1), chuyển sang trạng thái DONE để xuất symbol parity cuối cùng và sẵn sàng nhận gói tin mới
                    else                                        state_next = ERROR;     // Nếu valid_in vẫn còn cao sau khi đã xuất đủ parity, hoặc sop_in lên cao trước khi đã xuất đủ parity, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
                end

                DONE: begin
                    if (sop_in & valid_in)          state_next = MSG1;  // Khi ở trạng thái DONE, nếu nhận được gói tin mới, chuyển sang trạng thái MSG1 để bắt đầu xử lý gói tin mới
                    else if (~(sop_in | valid_in))  state_next = IDLE;  // Khi ở trạng thái DONE, nếu không nhận được gói tin mới, quay về trạng thái IDLE để sẵn sàng nhận gói tin mới
                    else                            state_next = ERROR; // Nếu ở trạng thái DONE, nhưng tín hiệu sop_in và valid_in không hợp lệ (ví dụ sop_in lên cao mà valid_in không lên cao, hoặc ngược lại), chuyển sang trạng thái lỗi ERROR
                end

                ERROR: begin
                    if (sop_in & valid_in)          state_next = MSG1;  // Khi ở trạng thái lỗi, nếu nhận được gói tin mới, chuyển sang trạng thái MSG1 để bắt đầu xử lý gói tin mới
                    else if (~(sop_in | valid_in))  state_next = IDLE;  // Khi ở trạng thái lỗi, nếu không nhận được gói tin mới, quay về trạng thái IDLE để sẵn sàng nhận gói tin mới
                    else                            state_next = ERROR; // Nếu ở trạng thái lỗi, nhưng tín hiệu sop_in và valid_in không hợp lệ (ví dụ sop_in lên cao mà valid_in không lên cao, hoặc ngược lại), vẫn ở lại trạng thái lỗi ERROR
                end 

                default: state_next = ERROR;    // Nếu FSM rơi vào trạng thái không xác định, chuyển sang trạng thái lỗi ERROR
        endcase
    end
    
    // --- 4. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_current   <= IDLE;  // Reset về trạng thái IDLE khi rst_n ở mức thấp
        end
        else begin
            state_current <= state_next;   // Cập nhật trạng thái hiện tại với trạng thái tiếp theo ở mỗi chu kỳ đồng hồ
        end
    end

endmodule : rs_enc_ctrl
