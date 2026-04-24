module rs_dec_syn 
#(
    parameter WIDTH = 10,
    parameter NSYM = 30
)
(
    input  logic                clk,                // Tín hiệu clock
    input  logic                rst_n,              // Reset (active low)
    input  logic                sop_in,             // Start of Packet (Bắt đầu gói tin)
    input  logic                vld_in,             // Báo hiệu dữ liệu vào hợp lệ
    input  logic [WIDTH-1:0]    dat_in,             // Input R (Received Data) (10-bit)
    
    output logic                vld_out,            // Báo hiệu tính xong (kết thúc gói)
    output logic                sys_rdy,            // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic                sys_err,            // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
    output logic [WIDTH-1:0]    syn_out [NSYM-1:0]  // Output song song 30 syndromes
);

    // Internal signals
    logic               reg_en;
    logic               ctrl;
    logic [WIDTH-1:0]   fdbk    [NSYM-1:0]; // Mảng lưu trữ giá trị fdbk cho mỗi thanh ghi syndrome, được tính toán từ dữ liệu đầu vào và giá trị syndrome hiện tại thông qua logic fdbk
    logic [WIDTH-1:0]   reg_in  [NSYM-1:0]; // Mảng lưu trữ giá trị đầu vào cho mỗi thanh ghi syndrome, được tạo ra từ giá trị fdbk sau khi nhân với hằng số alpha^i tương ứng thông qua các bộ nhân hằng số
    logic               cnt_en;             // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên          
    logic               cnt_end;            // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm trong module rs_dec_syn_cnt

    // --- 1. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // Mỗi bộ nhân này sẽ nhận giá trị fdbk từ bước trước và nhân với một hằng số alpha^i tương ứng 
    // để tạo ra giá trị mới cho thanh ghi syndrome tiếp theo.

    assign reg_in[0] = fdbk[0]; // S0: Nhân với alpha^0 = 1 (Thực tế là pass-through)
    gf_mul_const_alpha1  u1  (.a(fdbk[1]),  .p(reg_in[1]));
    gf_mul_const_alpha2  u2  (.a(fdbk[2]),  .p(reg_in[2]));
    gf_mul_const_alpha3  u3  (.a(fdbk[3]),  .p(reg_in[3]));
    gf_mul_const_alpha4  u4  (.a(fdbk[4]),  .p(reg_in[4]));
    gf_mul_const_alpha5  u5  (.a(fdbk[5]),  .p(reg_in[5]));
    gf_mul_const_alpha6  u6  (.a(fdbk[6]),  .p(reg_in[6]));
    gf_mul_const_alpha7  u7  (.a(fdbk[7]),  .p(reg_in[7]));
    gf_mul_const_alpha8  u8  (.a(fdbk[8]),  .p(reg_in[8]));
    gf_mul_const_alpha9  u9  (.a(fdbk[9]),  .p(reg_in[9]));
    gf_mul_const_alpha10 u10 (.a(fdbk[10]), .p(reg_in[10]));
    gf_mul_const_alpha11 u11 (.a(fdbk[11]), .p(reg_in[11]));
    gf_mul_const_alpha12 u12 (.a(fdbk[12]), .p(reg_in[12]));
    gf_mul_const_alpha13 u13 (.a(fdbk[13]), .p(reg_in[13]));
    gf_mul_const_alpha14 u14 (.a(fdbk[14]), .p(reg_in[14]));
    gf_mul_const_alpha15 u15 (.a(fdbk[15]), .p(reg_in[15]));
    gf_mul_const_alpha16 u16 (.a(fdbk[16]), .p(reg_in[16]));
    gf_mul_const_alpha17 u17 (.a(fdbk[17]), .p(reg_in[17]));
    gf_mul_const_alpha18 u18 (.a(fdbk[18]), .p(reg_in[18]));
    gf_mul_const_alpha19 u19 (.a(fdbk[19]), .p(reg_in[19]));
    gf_mul_const_alpha20 u20 (.a(fdbk[20]), .p(reg_in[20]));
    gf_mul_const_alpha21 u21 (.a(fdbk[21]), .p(reg_in[21]));
    gf_mul_const_alpha22 u22 (.a(fdbk[22]), .p(reg_in[22]));
    gf_mul_const_alpha23 u23 (.a(fdbk[23]), .p(reg_in[23]));
    gf_mul_const_alpha24 u24 (.a(fdbk[24]), .p(reg_in[24]));
    gf_mul_const_alpha25 u25 (.a(fdbk[25]), .p(reg_in[25]));
    gf_mul_const_alpha26 u26 (.a(fdbk[26]), .p(reg_in[26]));
    gf_mul_const_alpha27 u27 (.a(fdbk[27]), .p(reg_in[27]));
    gf_mul_const_alpha28 u28 (.a(fdbk[28]), .p(reg_in[28]));
    gf_mul_const_alpha29 u29 (.a(fdbk[29]), .p(reg_in[29]));

    // --- 2. Instantiate 30 Datapath Modules cho Syndrome Calculation ---
    genvar i;
    generate
        for (i = 0; i < NSYM; i++) begin : GEN_DPATH
            rs_dec_syn_dpath_i DPath (
                .clk        (clk),
                .rst_n      (rst_n),
                .dat_in     (dat_in),
                .vld_out    (vld_out),
                .reg_en     (reg_en),
                .ctrl       (ctrl),
                .reg_in     (reg_in[i]),    // Chỉ truyền reg_in của thanh ghi syndrome đầu tiên vào datapath, các thanh ghi syndrome tiếp theo sẽ được tính toán trong datapath dựa trên giá trị fdbk và hằng số alpha^i
                .fdbk       (fdbk[i]),      // Chỉ truyền fdbk của thanh ghi syndrome đầu tiên vào datapath, các giá trị fdbk tiếp theo sẽ được tính toán trong datapath dựa trên dữ liệu đầu vào và giá trị syndrome hiện tại
                .syn_out    (syn_out[i])    // Chỉ xuất syn_out của thanh ghi syndrome đầu tiên từ datapath, các giá trị syn_out tiếp theo sẽ được xuất ra từ các thanh ghi syndrome tương ứng sau khi đã hoàn thành tính toán syndrome for gói tin
            );
        end
    endgenerate

    // --- 3. Counter để theo dõi số lượng symbols received đã được xử lý ---
    rs_dec_syn_cnt Counter (
        .clk        (clk),
        .rst_n      (rst_n),
        .cnt_en     (cnt_en),      
        .vld_out    (vld_out),     
        .cnt_end    (cnt_end)    
    );    

    // --- 4. FSM Control Logic ---
    // FSM này sẽ điều khiển quá trình tính toán syndrome, 
    // bao gồm việc xác định khi nào bắt đầu tính toán (khi nhận được SOP), 
    // khi nào thực hiện fdbk (sau khi nhận được symbol đầu tiên), 
    // và khi nào hoàn thành tính toán syndrome (khi đã nhận đủ N symbols). 
    // FSM cũng sẽ đảm bảo rằng module chỉ sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin hiện tại, 
    // và sẽ báo lỗi nếu có tín hiệu không hợp lệ trong quá trình tính toán syndrome.
    rs_dec_syn_ctrl Control_Unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .vld_in     (vld_in),
        .cnt_end    (cnt_end),   
        .vld_out    (vld_out),
        .reg_en     (reg_en),
        .cnt_en     (cnt_en),
        .ctrl       (ctrl),
        .sys_rdy    (sys_rdy),
        .sys_err    (sys_err)
    );    

endmodule: rs_dec_syn

// --------------------------------------------------------------

// Module bộ đếm để theo dõi số lượng symbols received đã được xử lý
module rs_dec_syn_cnt 
#(
    parameter WIDTH = 10
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic cnt_en,       // Tín hiệu enable cho bộ đếm
    input  logic vld_out,      // Tín hiệu vld_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị
    output logic cnt_end      // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm (khi cnt_out đạt giá trị 542, tức là đã nhận đủ N symbols)
);

    // Internal signals 
    logic [WIDTH-1:0] cnt_in;   // Tín hiệu đầu vào cho bộ đếm, được tính toán từ giá trị hiện tại của bộ đếm và tín hiệu vld_out để quyết định khi nào reset về 0 hoặc tăng lên 1
    logic [WIDTH-1:0] cnt_out;  // Tín hiệu đầu ra từ bộ đếm, lưu trữ số lượng symbols đã xuất ra, được sử dụng để xác định khi nào chuyển từ xuất message sang xuất parity và khi nào hoàn thành xuất codeword
    logic [WIDTH-1:0] cnt_nxt; // Tín hiệu trung gian để tính toán giá trị tiếp theo của bộ đếm

    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    flop_r_nb #(.WIDTH(WIDTH)) Counter (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (cnt_en),
        .d     (cnt_in), 
        .q     (cnt_out) 
    );

    // Logic để tính toán giá trị tiếp theo của bộ đếm, được điều khiển bởi FSM
    add_sub_nb #(.WIDTH(WIDTH)) Count_Adder (
        .a      (cnt_out),
        .b      (WIDTH'('d1)),
        .cin    (1'b0),
        .sum    (cnt_nxt),
        .cout   ()               // Không cần sử dụng tín hiệu carry out trong trường hợp này vì bộ đếm chỉ cần đếm đến 542
    );

    // Logic để reset bộ đếm về 0 khi có tín hiệu vld_out và sys_rdy cùng lên cao
    and_nb #(.WIDTH(WIDTH)) Count_Reset (
        .a  ({WIDTH{~vld_out}}),    // Khi vld_out và sys_rdy cùng lên cao, tạo ra tín hiệu reset cho bộ đếm
        .b  (cnt_nxt),              // Giá trị tiếp theo của bộ đếm sau khi cộng 1
        .y  (cnt_in)                // Tín hiệu đầu vào cho bộ đếm, sẽ là cnt_nxt khi đang xuất message/parity, hoặc 0 khi bắt đầu gói tin mới
    );
    
    // Logic để xác định khi nào đã xử lý xong 543 received symbols (count = 542, bit [9] và bit [4:1] đều là 1)
    assign cnt_end = cnt_out[9] & cnt_out[4] & cnt_out[3] & cnt_out[2] & cnt_out[1]; 

endmodule: rs_dec_syn_cnt  

// --------------------------------------------------------------

// Datapath cho RS Decoder Syndrome Calculation index i (từ 0 đến 29)
module rs_dec_syn_dpath_i 
#(
    parameter WIDTH = 10
)
(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [WIDTH-1:0]    dat_in,   
    input  logic                vld_out,
    input  logic                reg_en,   
    input  logic                ctrl,
    input  logic [WIDTH-1:0]    reg_in,
    output logic [WIDTH-1:0]    fdbk,    
    output logic [WIDTH-1:0]    syn_out 
);

    // Internal signals
    logic [WIDTH-1:0] reg_out;  // Mảng thanh ghi lưu trữ Syndrome 
    logic [WIDTH-1:0] and_fdbk;

    // --- 1. Feedback Logic ---
    // AND giữa giá trị thanh ghi syndrome với ctrl để chặn việc fdbk của quá trình xử lý bộ syndrome của từ mã trước bị cộng lan sang symbol đầu tiên của từ mã hiện tại
    and_nb #(.WIDTH(WIDTH)) AND_feedback (
        .a  (reg_out), 
        .b  ({WIDTH{ctrl}}), 
        .y  (and_fdbk) 
    );

    // XOR (GF addition) giữa symbol tiếp theo (dat_in) với giá trị fdbk (tổng đang cộng dồn) từ bước trước (and_fdbk) để tạo ra giá trị fdbk mới
    xor_nb #(.WIDTH(WIDTH)) XOR_feedback (
        .a  (and_fdbk), 
        .b  (dat_in), 
        .y  (fdbk) 
    );

    // --- 2. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // 30 module này được khai báo chung ở module rs_dec_syn để tạo ra giá trị đầu vào cho các thanh ghi syndrome ở module rs_dec_syn_dpath.
    // Mỗi bộ nhân này sẽ nhận giá trị fdbk từ bước trước và nhân với một hằng số alpha^i tương ứng 
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
    // nhưng chỉ khi vld_out ở mức cao (khi đã hoàn thành gói tin).
    and_nb #(.WIDTH(WIDTH)) AND_output (
        .a  (fdbk),             // Giá trị fdbk cuối cùng sau khi cộng với dữ liệu đầu vào (R0) mà chưa nhân với hằng số alpha^i, được sử dụng làm giá trị syndrome cuối cùng
        .b  ({WIDTH{vld_out}}), // Chỉ xuất giá trị syndrome khi vld_out ở mức cao (khi đã hoàn thành gói tin)
        .y  (syn_out) 
    );

endmodule: rs_dec_syn_dpath_i

// --------------------------------------------------------------

// FSM Control Unit cho RS Decoder Syndrome Calculation
module rs_dec_syn_ctrl 
(
    input  logic clk,
    input  logic rst_n,
    input  logic sop_in,    // Start of Packet (Bắt đầu gói tin)
    input  logic vld_in,    // Báo hiệu dữ liệu vào hợp lệ
    input  logic cnt_end,   // Tín hiệu để xác định khi nào đã xử lý xong 543 received symbols, được tính toán từ giá trị của bộ đếm trong module rs_dec_syn_cnt
    output logic vld_out,   // Báo hiệu tính xong (kết thúc gói)
    output logic reg_en,    // Tín hiệu enable cho các thanh ghi syndrome
    output logic cnt_en,    // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên
    output logic ctrl,      // Tín hiệu điều khiển chung cho toàn bộ module
    output logic sys_rdy,   // Báo hiệu module sẵn sàng nhận dữ liệu mới (sau khi đã tính xong)
    output logic sys_err    // Báo hiệu lỗi (nếu có) trong quá trình tính toán syndrome
);

    // FSM State Definition
    typedef enum logic [1:0] {
        IDLE,   // Chờ SOP
        CALC,   // Đang tính toán syndrome ở chu kỳ đầu tiên
        DONE,   // Đã hoàn thành tính toán syndrome sau khi nhận đủ N symbols
        ERROR   // Trạng thái lỗi nếu có tín hiệu không hợp lệ
    } state_t;

    state_t state_cur, state_nxt;  // Trạng thái hiện tại và trạng thái tiếp theo của FSM

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_cur)
            IDLE: begin
                vld_out = 1'b0;                             // Chỉ báo hiệu tính xong khi đã hoàn thành gói tin
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;  // Bật enable NGAY LẬP TỨC ở nhịp có SOP (Mealy Machine)
                cnt_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;  // Bật enable NGAY LẬP TỨC ở nhịp có SOP (Mealy Machine)
                ctrl    = 1'b0;                             // ctrl = 0 để nạp thẳng r0
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1;  // Có thể hạ sys_rdy xuống 0 ngay lập tức nếu có data vào
                sys_err = 1'b0;                             // Không có lỗi khi reset
            end

            CALC: begin
                vld_out = 1'b0;     
                reg_en  = 1'b1;
                cnt_en  = 1'b1;     
                ctrl    = 1'b1; // Bắt đầu thực hiện fdbk sau khi đã nhận được symbol đầu tiên
                sys_rdy = 1'b0;     
                sys_err = 1'b0;
            end

            DONE: begin
                vld_out = 1'b1; // Báo hiệu đã tính xong khi đã nhận đủ N symbols
                reg_en  = 1'b1;       
                cnt_en  = 1'b1; // Vẫn enable bộ đếm để load giá trị 0 nhằm reset
                ctrl    = 1'b1; // Giữ ctrl để xuất ra fdbk cuối cùng cho các syndrome
                sys_rdy = 1'b1; // Sẵn sàng nhận dữ liệu mới sau khi đã hoàn thành gói tin
                sys_err = 1'b0;
            end

            ERROR: begin // Mealy Action: Chộp data ngay lập tức nếu có gói tin mới đập vào
                vld_out = 1'b0;
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                cnt_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                ctrl    = 1'b0; 
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1;  // Có thể hạ sys_rdy xuống 0 ngay lập tức nếu có data vào
                sys_err = 1'b1;                             // Vẫn báo cờ lỗi ở nhịp này để testbench nhận biết
            end

            default: begin // ERROR
                vld_out = 1'b0;
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                cnt_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                ctrl    = 1'b0; 
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1; // Có thể hạ sys_rdy xuống 0 ngay lập tức nếu có data vào
                sys_err = 1'b1; // Vẫn báo cờ lỗi ở nhịp này để testbench nhận biết
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (state_cur)
            IDLE: begin
                if (~(sop_in | vld_in))     state_nxt = IDLE;   // Vẫn ở trạng thái IDLE nếu chưa nhận được SOP hoặc dữ liệu không hợp lệ  
                else if (sop_in & vld_in)   state_nxt = CALC;   // Chuyển sang trạng thái CALC khi nhận được SOP và dữ liệu hợp lệ
                else                        state_nxt = ERROR;  // Nếu sop_in và vld_in không cùng lên cao, chuyển sang trạng thái lỗi ERROR
            end

            CALC: begin
                if ((~sop_in & vld_in) & ~cnt_end)      state_nxt = CALC;   // Tiếp tục ở lại trạng thái CALC nếu vẫn còn dữ liệu vào hợp lệ và chưa nhận đủ N symbols (count = 542, bit 9 và các bit [4:1] đều là 1)
                else if ((~sop_in & vld_in) & cnt_end)  state_nxt = DONE;   // Khi đã nhận đủ N symbols (count = 542, bit 9 và các bit [4:1] đều là 1) và sop_in đã xuống thấp, chuyển sang trạng thái DONE để hoàn thành gói tin
                else                                    state_nxt = ERROR;  // Nếu vld_in xuống thấp trước khi nhận đủ N symbols, hoặc sop_in vẫn còn cao sau khi đã nhận đủ N symbols, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
            end

            DONE: begin
                if (~sop_in & vld_in)   state_nxt = IDLE;   // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                    state_nxt = ERROR; 
            end

            ERROR: begin
                if (sop_in & vld_in)            state_nxt = CALC;   // Nếu nhận được gói tin mới sau khi đã rơi vào trạng thái lỗi, chuyển sang trạng thái CALC để bắt đầu tính toán syndrome cho gói tin mới
                else if (~(sop_in | vld_in))    state_nxt = IDLE;   // Nếu không nhận được gói tin mới, quay về trạng thái IDLE để chờ SOP tiếp theo
                else                            state_nxt = ERROR;  // Nếu có tín hiệu không hợp lệ, vẫn giữ nguyên trạng thái lỗi ERROR
            end

            default: state_nxt = ERROR; // Nếu FSM rơi vào trạng thái không xác định, chuyển sang trạng thái lỗi ERROR
        endcase
    end

    // --- 3. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_cur   <= IDLE;    // Reset về trạng thái IDLE khi rst_n ở mức thấp
        end
        else begin
            state_cur <= state_nxt; // Cập nhật trạng thái hiện tại với trạng thái tiếp theo ở mỗi chu kỳ đồng hồ
        end
    end

endmodule: rs_dec_syn_ctrl
