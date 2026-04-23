module rs_dec_syn 
#(
    parameter WIDTH = 10,
    parameter NSYM = 30
)
(
    input  logic                clk,        // Tín hiệu clock
    input  logic                rst_n,      // Reset (active low)
    input  logic                sop_in,     // Start of Packet (Bắt đầu gói tin)
    input  logic                valid_in,   // Báo hiệu dữ liệu vào hợp lệ
    input  logic [WIDTH-1:0]    data_in,    // Input R (Received Data) (10-bit)
    
    output logic                valid_out,  // Báo hiệu tính xong (kết thúc gói)
    output logic                ready,      // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic                error,      // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
    output logic [WIDTH-1:0]    syn_out [NSYM-1:0] // Output song song 30 syndromes
);

    // Internal signals
    logic               reg_en;
    logic               control;
    logic [WIDTH-1:0]   feedback  [NSYM-1:0];   // Mảng lưu trữ giá trị feedback cho mỗi thanh ghi syndrome, được tính toán từ dữ liệu đầu vào và giá trị syndrome hiện tại thông qua logic feedback
    logic [WIDTH-1:0]   reg_in    [NSYM-1:0];   // Mảng lưu trữ giá trị đầu vào cho mỗi thanh ghi syndrome, được tạo ra từ giá trị feedback sau khi nhân với hằng số alpha^i tương ứng thông qua các bộ nhân hằng số
    logic               count_en;               // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên          
    logic               count_done;             // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm trong module rs_dec_syn_cnt

    // --- 1. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // Mỗi bộ nhân này sẽ nhận giá trị feedback từ bước trước và nhân với một hằng số alpha^i tương ứng 
    // để tạo ra giá trị mới cho thanh ghi syndrome tiếp theo.

    assign reg_in[0] = feedback[0]; // S0: Nhân với alpha^0 = 1 (Thực tế là pass-through)
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

    // --- 2. Instantiate 30 Datapath Modules cho Syndrome Calculation ---
    genvar i;
    generate
        for (i = 0; i < NSYM; i++) begin : GEN_DPATH
            rs_dec_syn_dpath_i DPath (
                .clk        (clk),
                .rst_n      (rst_n),
                .data_in    (data_in),
                .valid_out  (valid_out),
                .reg_en     (reg_en),
                .control    (control),
                .reg_in     (reg_in[i]),   // Chỉ truyền reg_in của thanh ghi syndrome đầu tiên vào datapath, các thanh ghi syndrome tiếp theo sẽ được tính toán trong datapath dựa trên giá trị feedback và hằng số alpha^i
                .feedback   (feedback[i]), // Chỉ truyền feedback của thanh ghi syndrome đầu tiên vào datapath, các giá trị feedback tiếp theo sẽ được tính toán trong datapath dựa trên dữ liệu đầu vào và giá trị syndrome hiện tại
                .syn_out    (syn_out[i])   // Chỉ xuất syn_out của thanh ghi syndrome đầu tiên từ datapath, các giá trị syn_out tiếp theo sẽ được xuất ra từ các thanh ghi syndrome tương ứng sau khi đã hoàn thành tính toán syndrome for gói tin
            );
        end
    endgenerate

    // --- 3. Counter để theo dõi số lượng symbols received đã được xử lý ---
    rs_dec_syn_cnt Counter (
        .clk            (clk),
        .rst_n          (rst_n),
        .count_en       (count_en),      
        .valid_out      (valid_out),     
        .count_done     (count_done)    
    );    

    // --- 4. FSM Control Logic ---
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
        .count_done (count_done),   
        .valid_out  (valid_out),
        .reg_en     (reg_en),
        .count_en   (count_en),
        .control    (control),
        .ready      (ready),
        .error      (error)
    );    

endmodule : rs_dec_syn

// --------------------------------------------------------------

// Module bộ đếm để theo dõi số lượng symbols received đã được xử lý
module rs_dec_syn_cnt 
#(
    parameter WIDTH = 10
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic count_en,       // Tín hiệu enable cho bộ đếm
    input  logic valid_out,      // Tín hiệu valid_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị
    output logic count_done      // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm (khi count_out đạt giá trị 542, tức là đã nhận đủ N symbols)
);

    // Internal signals 
    logic [WIDTH-1:0] count_in;   // Tín hiệu đầu vào cho bộ đếm, được tính toán từ giá trị hiện tại của bộ đếm và tín hiệu valid_out để quyết định khi nào reset về 0 hoặc tăng lên 1
    logic [WIDTH-1:0] count_out;  // Tín hiệu đầu ra từ bộ đếm, lưu trữ số lượng symbols đã xuất ra, được sử dụng để xác định khi nào chuyển từ xuất message sang xuất parity và khi nào hoàn thành xuất codeword
    logic [WIDTH-1:0] count_next; // Tín hiệu trung gian để tính toán giá trị tiếp theo của bộ đếm

    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    flop_r_nb #(.WIDTH(WIDTH)) Counter (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (count_en),
        .d     (count_in), 
        .q     (count_out) 
    );

    // Logic để tính toán giá trị tiếp theo của bộ đếm, được điều khiển bởi FSM
    add_sub_nb #(.WIDTH(WIDTH)) Count_Adder (
        .a      (count_out),
        .b      (WIDTH'('d1)),
        .cin    (1'b0),
        .sum    (count_next),
        .cout   ()              // Không cần sử dụng tín hiệu carry out trong trường hợp này vì bộ đếm chỉ cần đếm đến 542
    );

    // Logic để reset bộ đếm về 0 khi có tín hiệu valid_out và ready cùng lên cao
    and_nb #(.WIDTH(WIDTH)) Count_Reset (
        .a  ({WIDTH{~valid_out}}), // Khi valid_out và ready cùng lên cao, tạo ra tín hiệu reset cho bộ đếm
        .b  (count_next),       // Giá trị tiếp theo của bộ đếm sau khi cộng 1
        .y  (count_in)          // Tín hiệu đầu vào cho bộ đếm, sẽ là count_next khi đang xuất message/parity, hoặc 0 khi bắt đầu gói tin mới
    );
    
    // Logic để xác định khi nào đã xử lý xong 543 received symbols (count = 542, bit [9] và bit [4:1] đều là 1)
    assign count_done = count_out[9] & count_out[4] & count_out[3] & count_out[2] & count_out[1]; 

endmodule : rs_dec_syn_cnt  

// --------------------------------------------------------------

// Datapath cho RS Decoder Syndrome Calculation index i (từ 0 đến 29)
module rs_dec_syn_dpath_i 
#(
    parameter WIDTH = 10
)
(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [WIDTH-1:0]    data_in,   
    input  logic                valid_out,
    input  logic                reg_en,   
    input  logic                control,
    input  logic [WIDTH-1:0]    reg_in,
    output logic [WIDTH-1:0]    feedback,    
    output logic [WIDTH-1:0]    syn_out 
);

    // Internal signals
    logic [WIDTH-1:0] reg_out;  // Mảng thanh ghi lưu trữ Syndrome 
    logic [WIDTH-1:0] and_feedback;

    // --- 1. Feedback Logic ---
    // AND giữa giá trị thanh ghi syndrome với control để chặn việc feedback của quá trình xử lý bộ syndrome của từ mã trước bị cộng lan sang symbol đầu tiên của từ mã hiện tại
    and_nb #(.WIDTH(WIDTH)) AND_feedback (
        .a(reg_out), 
        .b({WIDTH{control}}), 
        .y(and_feedback) 
    );

    // XOR (GF addition) giữa symbol tiếp theo (data_in) với giá trị feedback (tổng đang cộng dồn) từ bước trước (and_feedback) để tạo ra giá trị feedback mới
    xor_nb #(.WIDTH(WIDTH)) XOR_feedback (
        .a(and_feedback), 
        .b(data_in), 
        .y(feedback) 
    );

    // --- 2. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // 30 module này được khai báo chung ở module rs_dec_syn để tạo ra giá trị đầu vào cho các thanh ghi syndrome ở module rs_dec_syn_dpath.
    // Mỗi bộ nhân này sẽ nhận giá trị feedback từ bước trước và nhân với một hằng số alpha^i tương ứng 
    // để tạo ra giá trị mới cho thanh ghi syndrome tiếp theo.


    // --- 3. Syndrome Register ---
    // Các thanh ghi này sẽ lưu trữ giá trị syndrome tạm thời trong quá trình tính toán.
    flop_r_nb #(.WIDTH(WIDTH)) Syn_Reg (
        .clk    (clk),
        .rst_n  (rst_n),  
        .en     (reg_en),
        .d      (reg_in),
        .q      (reg_out)
    );

    // --- 4. Output Logic ---    
    // Logic này sẽ xuất giá trị syndrome từ các thanh ghi ra output syn_out, 
    // nhưng chỉ khi valid_out ở mức cao (khi đã hoàn thành gói tin).
    and_nb #(.WIDTH(WIDTH)) AND_output (
        .a  (feedback),        // Giá trị feedback cuối cùng sau khi cộng với dữ liệu đầu vào (R0) mà chưa nhân với hằng số alpha^i, được sử dụng làm giá trị syndrome cuối cùng
        .b  ({WIDTH{valid_out}}),    // Chỉ xuất giá trị syndrome khi valid_out ở mức cao (khi đã hoàn thành gói tin)
        .y  (syn_out) 
    );

endmodule : rs_dec_syn_dpath_i

// --------------------------------------------------------------

// FSM Control Unit cho RS Decoder Syndrome Calculation
module rs_dec_syn_ctrl 
(
    input  logic clk,
    input  logic rst_n,
    input  logic sop_in,     // Start of Packet (Bắt đầu gói tin)
    input  logic valid_in,   // Báo hiệu dữ liệu vào hợp lệ
    input  logic count_done, // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm trong module rs_dec_syn_cnt
    output logic valid_out,  // Báo hiệu tính xong (kết thúc gói)
    output logic reg_en,     // Tín hiệu enable cho các thanh ghi syndrome
    output logic count_en,   // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên
    output logic control,    // Tín hiệu điều khiển chung cho toàn bộ module
    output logic ready,      // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic error       // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
);

    // FSM State Definition
    typedef enum logic [1:0] {
        IDLE,   // Chờ SOP
        CALC,   // Đang tính toán syndrome ở chu kỳ đầu tiên
        DONE,   // Đã hoàn thành tính toán syndrome sau khi nhận đủ N symbols
        ERROR   // Trạng thái lỗi nếu có tín hiệu không hợp lệ
    } state_t;

    state_t state_current, state_next;  // Trạng thái hiện tại và trạng thái tiếp theo của FSM

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_current)
            IDLE: begin
                valid_out   = 1'b0;     // Chỉ báo hiệu tính xong khi đã hoàn thành gói tin
                reg_en      = (sop_in & valid_in) ? 1'b1 : 1'b0;    // Bật enable NGAY LẬP TỨC ở nhịp có SOP (Mealy Machine)
                count_en    = (sop_in & valid_in) ? 1'b1 : 1'b0;    // Bật enable NGAY LẬP TỨC ở nhịp có SOP (Mealy Machine)
                control     = 1'b0;     // control = 0 để nạp thẳng r0
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau reset
                error       = 1'b0;     // Không có lỗi khi reset
            end

            CALC: begin
                valid_out   = 1'b0;     
                reg_en      = 1'b1;
                count_en    = 1'b1;     
                control     = 1'b1;     // Bắt đầu thực hiện feedback sau khi đã nhận được symbol đầu tiên
                ready       = 1'b0;     
                error       = 1'b0;
            end

            DONE: begin
                valid_out   = 1'b1;     // Báo hiệu đã tính xong khi đã nhận đủ N symbols
                reg_en      = 1'b1;       
                count_en    = 1'b1;     // Vẫn enable bộ đếm để load giá trị 0 nhằm reset
                control     = 1'b1;     // Giữ control để xuất ra feedback cuối cùng cho các syndrome
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b0;
            end

            ERROR: begin
                valid_out   = 1'b0;
                reg_en      = 1'b0;
                count_en    = 1'b0;
                control     = 1'b0;
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b1;     // Báo lỗi nếu có tín hiệu không hợp lệ khi đang ở trạng thái IDLE hoặc CALC
            end

            default: begin
                valid_out   = 1'b0;
                reg_en      = 1'b0;
                count_en    = 1'b0;
                control     = 1'b0;
                ready       = 1'b1;     // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                error       = 1'b1;     // Báo lỗi nếu có trạng thái không xác định
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (state_current)
            IDLE: begin
                if (~(sop_in | valid_in))   state_next = IDLE;  // Vẫn ở trạng thái IDLE nếu chưa nhận được SOP hoặc dữ liệu không hợp lệ  
                else if (sop_in & valid_in) state_next = CALC;  // Chuyển sang trạng thái CALC khi nhận được SOP và dữ liệu hợp lệ
                else                        state_next = ERROR; // Nếu sop_in và valid_in không cùng lên cao, chuyển sang trạng thái lỗi ERROR
            end

            CALC: begin
                if ((~sop_in & valid_in) & ~count_done)     state_next = CALC;  // Tiếp tục ở lại trạng thái CALC nếu vẫn còn dữ liệu vào hợp lệ và chưa nhận đủ N symbols (count = 542, bit 9 và các bit [4:1] đều là 1)
                else if ((~sop_in & valid_in) & count_done) state_next = DONE;  // Khi đã nhận đủ N symbols (count = 542, bit 9 và các bit [4:1] đều là 1) và sop_in đã xuống thấp, chuyển sang trạng thái DONE để hoàn thành gói tin
                else                                        state_next = ERROR; // Nếu valid_in xuống thấp trước khi nhận đủ N symbols, hoặc sop_in vẫn còn cao sau khi đã nhận đủ N symbols, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
            end

            DONE: begin
                if (~sop_in & valid_in) state_next = IDLE;  // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                    state_next = ERROR; 
            end

            ERROR: begin
                if (sop_in & valid_in)          state_next = CALC; // Nếu nhận được gói tin mới sau khi đã rơi vào trạng thái lỗi, chuyển sang trạng thái CALC để bắt đầu tính toán syndrome cho gói tin mới
                else if (~(sop_in | valid_in))  state_next = IDLE;  // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                            state_next = ERROR; // Nếu có tín hiệu không hợp lệ, vẫn giữ nguyên trạng thái lỗi ERROR
            end

            default: state_next = ERROR;    // Nếu FSM rơi vào trạng thái không xác định, chuyển sang trạng thái lỗi ERROR
        endcase
    end

    // --- 3. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_current   <= IDLE;  // Reset về trạng thái IDLE khi rst_n ở mức thấp
        end
        else begin
            state_current <= state_next;   // Cập nhật trạng thái hiện tại với trạng thái tiếp theo ở mỗi chu kỳ đồng hồ
        end
    end

endmodule : rs_dec_syn_ctrl
