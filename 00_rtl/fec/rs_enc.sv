// rs_enc.sv

// Reed-Solomon (544, 514) Encoder for GF(2^10)
module rs_enc 
#(
    parameter WIDTH = 10,
    parameter NSYM = 30
)
(
    input  logic                clk,    // Tín hiệu clock
    input  logic                rst_n,  // Tín hiệu reset, active low
    input  logic                sop_in, // Đánh dấu bắt đầu một gói tin (Start of Packet)
    input  logic                vld_in, // Tín hiệu valid cho dat_in. dat_in chỉ có giá trị khi tín hiệu này mức cao
    input  logic [WIDTH-1:0]    dat_in, // Dữ liệu tin nhắn đầu vào 10-bit (tổng cộng 514 symbols)
    
    output logic                sop_out,    // Đánh dấu bắt đầu một gói tin ra (Start of Packet)
    output logic                vld_out,    // Tín hiệu valid cho dat_out
    output logic [WIDTH-1:0]    dat_out,    // Dữ liệu Codeword ra (544 symbols) (bao gồm cả Message và Parity)
    output logic                sys_rdy,    // Sẵn sàng nhận gói tin mới (High ở trạng thái IDLE)
    output logic                sys_err     // Báo hiệu gói tin không hợp lệ
);

    // --- Internal Signals ---
    logic [WIDTH-1:0]   reg_in  [NSYM-1:0];     // Tín hiệu đầu vào cho các thanh ghi LFSR, được tính toán từ fdbk và các hệ số g[i]
    logic [WIDTH-1:0]   reg_out [NSYM-1:0];     // Tín hiệu đầu ra từ các thanh ghi LFSR, lưu trữ trạng thái hiện tại của số dư trong quá trình chia đa thức
    logic               reg_en;                 // Tín hiệu enable cho các thanh ghi LFSR 
    logic [WIDTH-1:0]   fb_mul_gi [NSYM-1:0];   // Lưu kết quả sau khi nhân fdbk với các hệ số g[i] từ 30 bộ nhân hằng số 
    logic [WIDTH-1:0]   xor_fdbk;               // Tín hiệu trung gian sau khi XOR giữa dat_in và thanh ghi bậc cao nhất của số dư, được sử dụng làm input cho các bộ nhân hằng số
    logic [WIDTH-1:0]   fdbk;                   // Tín hiệu phản hồi dùng để tính toán số dư
    logic               ctrl;                   // Biến điều khiển để xác định khi nào bắt đầu xuất parity sau khi đã xuất hết 514 symbols dữ liệu
    logic               cnt_par;                // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu, dựa trên giá trị của bộ đếm (count = 513, bit 9 và bit 0 đều là 1)
    logic               cnt_end;                // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm (count = 542, bit [9] và bit [4:1] đều là 1)

    // --- 1. Feedback Logic ---
    // XOR giữa dat_in với thanh ghi bậc cao nhất của số dư (reg_out[NSYM-1]) để tạo ra giá trị fdbk mới, được sử dụng làm input cho các bộ nhân hằng số
    xor_nb #(.WIDTH(WIDTH)) Fbk_Xor (
        .a  (dat_in),
        .b  (reg_out[NSYM-1]),
        .y  (xor_fdbk)
    );

    // AND giữa giá trị fdbk mới (xor_fdbk) với ctrl để chặn việc fdbk của quá trình xử lý bộ syndrome của từ mã trước bị cộng lan sang symbol đầu tiên của từ mã hiện tại
    and_nb #(.WIDTH(WIDTH)) Fbk_And (
        .a  (xor_fdbk),
        .b  ({WIDTH{ctrl}}), // Mở rộng ctrl thành WIDTH bit để AND với xor_fdbk 
        .y  (fdbk)
    );

    // --- 2. GF Constant Multipliers Instantiation ---
    // Gọi 30 module nhân hằng số từ file gf_mul_constants.sv (đã gen từ Python) để tính toán song song
    // Mỗi module nhân fdbk với một hệ số g_i của đa thức tạo mã g(x)
    gf_mul_const_g0  u0  (.a(fdbk), .p(fb_mul_gi[0])); 
    gf_mul_const_g1  u1  (.a(fdbk), .p(fb_mul_gi[1]));
    gf_mul_const_g2  u2  (.a(fdbk), .p(fb_mul_gi[2]));
    gf_mul_const_g3  u3  (.a(fdbk), .p(fb_mul_gi[3]));
    gf_mul_const_g4  u4  (.a(fdbk), .p(fb_mul_gi[4]));
    gf_mul_const_g5  u5  (.a(fdbk), .p(fb_mul_gi[5]));
    gf_mul_const_g6  u6  (.a(fdbk), .p(fb_mul_gi[6]));
    gf_mul_const_g7  u7  (.a(fdbk), .p(fb_mul_gi[7]));
    gf_mul_const_g8  u8  (.a(fdbk), .p(fb_mul_gi[8]));
    gf_mul_const_g9  u9  (.a(fdbk), .p(fb_mul_gi[9]));
    gf_mul_const_g10 u10 (.a(fdbk), .p(fb_mul_gi[10]));
    gf_mul_const_g11 u11 (.a(fdbk), .p(fb_mul_gi[11]));
    gf_mul_const_g12 u12 (.a(fdbk), .p(fb_mul_gi[12]));
    gf_mul_const_g13 u13 (.a(fdbk), .p(fb_mul_gi[13]));
    gf_mul_const_g14 u14 (.a(fdbk), .p(fb_mul_gi[14]));
    gf_mul_const_g15 u15 (.a(fdbk), .p(fb_mul_gi[15]));
    gf_mul_const_g16 u16 (.a(fdbk), .p(fb_mul_gi[16]));
    gf_mul_const_g17 u17 (.a(fdbk), .p(fb_mul_gi[17]));
    gf_mul_const_g18 u18 (.a(fdbk), .p(fb_mul_gi[18]));
    gf_mul_const_g19 u19 (.a(fdbk), .p(fb_mul_gi[19]));
    gf_mul_const_g20 u20 (.a(fdbk), .p(fb_mul_gi[20]));
    gf_mul_const_g21 u21 (.a(fdbk), .p(fb_mul_gi[21]));
    gf_mul_const_g22 u22 (.a(fdbk), .p(fb_mul_gi[22]));
    gf_mul_const_g23 u23 (.a(fdbk), .p(fb_mul_gi[23]));
    gf_mul_const_g24 u24 (.a(fdbk), .p(fb_mul_gi[24]));
    gf_mul_const_g25 u25 (.a(fdbk), .p(fb_mul_gi[25]));
    gf_mul_const_g26 u26 (.a(fdbk), .p(fb_mul_gi[26]));
    gf_mul_const_g27 u27 (.a(fdbk), .p(fb_mul_gi[27]));
    gf_mul_const_g28 u28 (.a(fdbk), .p(fb_mul_gi[28]));
    gf_mul_const_g29 u29 (.a(fdbk), .p(fb_mul_gi[29]));
    // Phép nhân với g30 không cần thiết vì g30 = 1, nên fb_mul_gi[29] đã là kết quả sau khi nhân với g30

    // --- 3. GF Addition for LFSR Update ---
    // Cập nhật giá trị vào cho từng thanh ghi LFSR bằng cách XOR kết quả nhân hằng số với giá trị hiện tại của thanh ghi trước đó
    genvar j;
    generate
        for (j = 0; j < NSYM; j++) begin : REG_IN_CALC
            if (j == 0) begin : FIRST_REG
                assign reg_in[0] = fb_mul_gi[0]; // Thanh ghi bậc thấp nhất chỉ nhận giá trị sau khi nhân hằng số g[0] với fdbk, không có giá trị nào khác cộng vào
            end else begin : OTHER_REGS
                xor_nb #(.WIDTH(WIDTH)) Reg_In_Xor (
                    .a(fb_mul_gi[j]),
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
            flop_r_nb #(.WIDTH(WIDTH)) Reg (
                .clk   (clk),
                .rst_n (rst_n),
                .en    (reg_en),
                .d     (reg_in[i]), 
                .q     (reg_out[i]) 
            );
        end
    endgenerate

    // --- 5. Output Logic ---
    // Dữ liệu dat_out được xuất lần lượt: đầu tiên là 514 symbols dữ liệu (dat_in), sau đó là 30 symbols parity (reg_out[0] đến reg_out[29])
    mux_2_nb #(.WIDTH(WIDTH)) Out_Mux (
        .d0 (reg_out[NSYM-1]),  // Chọn parity từ thanh ghi bậc cao nhất sau khi đã xuất hết 514 symbols dữ liệu
        .d1 (dat_in),           // Chọn dat_in trong quá trình xuất 514 symbols dữ liệu
        .s  (ctrl),             // Chuyển sang parity sau khi đã xuất hết 514 symbols dữ liệu
        .y  (dat_out)           // Kết nối đầu ra dat_out
    );

    // --- 6. Counter for Output Tracking ---
    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    rs_enc_cnt Counter (
        .clk        (clk),
        .rst_n      (rst_n),
        .reg_en     (reg_en),   // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
        .vld_out    (vld_out),  // Tín hiệu vld_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị (bao gồm cả message và parity)
        .sys_rdy    (sys_rdy),  // Tín hiệu sys_rdy từ FSM, cho biết khi nào sẵn sàng nhận gói tin mới
        .cnt_par    (cnt_par),  // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message), dựa trên giá trị của bộ đếm
        .cnt_end    (cnt_end)   // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm
    );

    // --- 7. FSM Control Logic ---
    // FSM để điều khiển quá trình mã hóa, quản lý khi nào bắt đầu xuất parity và khi nào sẵn sàng nhận gói tin mới
    rs_enc_ctrl Control_Unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .vld_in     (vld_in),
        .cnt_par    (cnt_par),   
        .cnt_end    (cnt_end),    
        .sop_out    (sop_out),
        .vld_out    (vld_out),
        .reg_en     (reg_en),
        .ctrl       (ctrl),
        .sys_rdy    (sys_rdy),
        .sys_err    (sys_err)
    );

endmodule: rs_enc

// --------------------------------------------------------------

// Module bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
module rs_enc_cnt 
#(
    parameter WIDTH = 10,
    parameter NSYM = 30
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic reg_en,    // Tín hiệu enable cho bộ đếm, được điều khiển bởi FSM để bắt đầu đếm khi nhận được symbol đầu tiên của message và tiếp tục đếm trong suốt quá trình xuất message và parity
    input  logic vld_out,   // Tín hiệu vld_out từ FSM, cho biết khi nào đang xuất dữ liệu có giá trị (bao gồm cả message và parity)
    input  logic sys_rdy,   // Tín hiệu sys_rdy từ FSM, cho biết khi nào sẵn sàng nhận gói tin mới
    output logic cnt_par,   // Tín hiệu để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message), dựa trên giá trị của bộ đếm
    output logic cnt_end    // Tín hiệu để xác định khi nào đã xuất đủ 29 symbols parity, dựa trên giá trị của bộ đếm
);

    // Internal signals for counter ctrl
    logic [WIDTH-1:0] cnt_in;   // Tín hiệu đầu vào cho bộ đếm, được tính toán từ giá trị hiện tại của bộ đếm và tín hiệu vld_out để quyết định khi nào reset về 0 hoặc tăng lên 1
    logic [WIDTH-1:0] cnt_out;  // Tín hiệu đầu ra từ bộ đếm, lưu trữ số lượng symbols đã xuất ra, được sử dụng để xác định khi nào chuyển từ xuất message sang xuất parity và khi nào hoàn thành xuất codeword
    logic [WIDTH-1:0] cnt_nxt;  // Tín hiệu trung gian để tính toán giá trị tiếp theo của bộ đếm

    // Bộ đếm để theo dõi số lượng symbols đã xuất ra, được enable bởi FSM khi bắt đầu xuất message và tiếp tục đếm trong suốt quá trình xuất message và parity
    flop_r_nb #(.WIDTH(WIDTH)) Cnt_Reg (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (reg_en),
        .d     (cnt_in), 
        .q     (cnt_out) 
    );

    // Logic để tính toán giá trị tiếp theo của bộ đếm, được điều khiển bởi FSM
    add_sub_nb #(.WIDTH(WIDTH)) Cnt_Add (
        .a      (cnt_out),
        .b      (WIDTH'('d1)),
        .cin    (1'b0),
        .sum    (cnt_nxt),
        .cout   ()              // Không cần sử dụng tín hiệu carry out trong trường hợp này vì bộ đếm chỉ cần đếm đến 542
    );

    // Logic để reset bộ đếm về 0 khi có tín hiệu vld_out và sys_rdy cùng lên cao
    and_nb #(.WIDTH(WIDTH)) Cnt_Rst (
        .a  ({WIDTH{(~sys_rdy)}}),              // Khi sys_rdy lên cao, tạo ra tín hiệu reset cho bộ đếm
        .b  (cnt_nxt),                          // Giá trị tiếp theo của bộ đếm sau khi cộng 1
        .y  (cnt_in)                            // Tín hiệu đầu vào cho bộ đếm, sẽ là cnt_nxt khi đang xuất message/parity, hoặc 0 khi bắt đầu gói tin mới
    );
    
    // Logic để xác định khi nào đã xuất đủ 514 symbols dữ liệu và khi nào đã xuất đủ 29 symbols parity dựa trên giá trị của bộ đếm (count = 513, bit 9 và bit 0 đều là 1)
    assign cnt_par = cnt_out[9] & cnt_out[0];

    // Logic để xác định khi nào đã xuất đủ 29 symbols parity dựa trên giá trị của bộ đếm (count = 542, bit [9] và bit [4:1] đều là 1)
    assign cnt_end = cnt_out[9] & cnt_out[4] & cnt_out[3] & cnt_out[2] & cnt_out[1]; 

endmodule: rs_enc_cnt   

// --------------------------------------------------------------

// Module điều khiển FSM cho RS Encoder
module rs_enc_ctrl
(
    input  logic clk,
    input  logic rst_n,
    input  logic sop_in,    // Đánh dấu bắt đầu một gói tin vào (Start of Packet)
    input  logic vld_in,    // Tín hiệu valid cho dat_in, chỉ có giá trị khi đang nhận symbols dữ liệu (message)
    input  logic cnt_par,   // Tín hiệu từ bộ đếm để xác định khi nào đã xuất đủ 514 symbols dữ liệu (message)
    input  logic cnt_end,   // Tín hiệu từ bộ đếm để xác định khi nào đã xuất đủ 29 symbols parity
    output logic sop_out,   // Đánh dấu bắt đầu một gói tin ra (Start of Packet), chỉ được đánh dấu ở symbol đầu tiên của message
    output logic vld_out,   // Tín hiệu valid cho dat_out, có giá trị trong suốt quá trình xuất message và parity
    output logic reg_en,    // Tín hiệu enable cho 30 thanh ghi LFSR, được điều khiển bởi FSM để cập nhật trong quá trình nhận message và xuất parity
    output logic ctrl,      // Biến điều khiển để xác định khi nào bắt đầu xuất parity sau khi đã xuất hết 514 symbols dữ liệu
    output logic sys_rdy,   // Sẵn sàng nhận gói tin mới, chỉ ở mức cao khi FSM ở trạng thái IDLE hoặc sau khi hoàn thành xuất codeword
    output logic sys_err    // Báo hiệu gói tin không hợp lệ, được đặt ở mức cao khi nhận được tín hiệu không hợp lệ trong quá trình IDLE hoặc MSG, hoặc khi FSM rơi vào trạng thái không xác định
);

    // Định nghĩa các trạng thái của FSM
    typedef enum logic [2:0] {
        IDLE,   // Trạng thái nghỉ, sẵn sàng nhận gói tin mới  
        MSG,    // Trạng thái nhận và xuất symbols dữ liệu (message), sop_out chỉ được đánh dấu ở symbol đầu tiên
        PARITY, // Trạng thái xuất symbols parity sau khi đã xuất hết 514 symbols dữ liệu
        DONE,   // Trạng thái xuất symbol parity cuối cùng và sẵn sàng nhận gói tin mới
        ERROR   // Trạng thái lỗi khi nhận được tín hiệu không hợp lệ (ví dụ sop_in hoặc vld_in không đúng) trong quá trình IDLE hoặc MSG
    } state_t;

    state_t state_cur, state_nxt;  // Trạng thái hiện tại và trạng thái tiếp theo của FSM

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_cur)
            IDLE: begin // Mealy Machine: Đáp ứng ngay lập tức (Zero-latency pass-through)
                sop_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                vld_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                ctrl    = 1'b1; 
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1;  // Ép sys_rdy = 0 khi có dữ liệu vào để tránh trigger mạch reset bộ đếm
                sys_err = 1'b0;
            end

            MSG: begin
                sop_out = 1'b0; // Chỉ đánh dấu sop_out ở symbol đầu tiên, sau đó hạ xuống
                vld_out = 1'b1;   
                reg_en  = 1'b1;
                ctrl    = 1'b1;    
                sys_rdy = 1'b0;   
                sys_err = 1'b0;   
            end

            PARITY: begin
                sop_out = 1'b0;    
                vld_out = 1'b1;   
                reg_en  = 1'b1; 
                ctrl    = 1'b0; // Chuyển sang xuất parity
                sys_rdy = 1'b0;   
                sys_err = 1'b0;   
            end

            DONE: begin
                sop_out = 1'b0;    
                vld_out = 1'b1;   
                reg_en  = 1'b1;  
                ctrl    = 1'b0;     
                sys_rdy = 1'b1; // Sẵn sàng nhận gói tin mới sau khi đã hoàn thành xuất codeword
                sys_err = 1'b0;   
            end

            ERROR: begin
                sop_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                vld_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                ctrl    = 1'b1; 
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1;  // Ép sys_rdy = 0 khi có dữ liệu vào để tránh trigger mạch reset bộ đếm
                sys_err = 1'b1;                             // Vẫn báo cờ lỗi ở nhịp này để testbench nhận biết
            end

            default: begin // ERROR
                sop_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                vld_out = (sop_in & vld_in) ? 1'b1 : 1'b0;
                reg_en  = (sop_in & vld_in) ? 1'b1 : 1'b0;
                ctrl    = 1'b1; 
                sys_rdy = (sop_in & vld_in) ? 1'b0 : 1'b1;  // Ép sys_rdy = 0 khi có dữ liệu vào để tránh trigger mạch reset bộ đếm
                sys_err = 1'b1;                             // Vẫn báo cờ lỗi ở nhịp này để testbench nhận biết
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (state_cur)
                IDLE: begin
                    if (~(sop_in | vld_in))     state_nxt = IDLE;   // Ở lại trạng thái IDLE nếu chưa có gói tin mới
                    else if (sop_in & vld_in)   state_nxt = MSG;    // Khi sop_in và vld_in cùng lên cao, chuyển sang trạng thái MSG để bắt đầu xử lý gói tin
                    else                        state_nxt = ERROR;  // Nếu sop_in và vld_in không cùng lên cao, chuyển sang trạng thái lỗi ERROR
                end

                MSG: begin
                    if ((~sop_in & vld_in) & ~cnt_par)      state_nxt = MSG;    // Tiếp tục ở lại trạng thái MSG nếu vẫn còn dữ liệu message và chưa nhận đủ 514 symbols (count = 514, bit 9 và bit 1 đều là 1)
                    else if ((~sop_in & vld_in) & cnt_par)  state_nxt = PARITY; // Khi đã nhận đủ 514 symbols dữ liệu (count = 513, bit 9 và bit 0 đều là 1), chuyển sang trạng thái xuất parity
                    else                                    state_nxt = ERROR;  // Nếu vld_in xuống thấp trước khi nhận đủ 514 symbols, hoặc sop_in vẫn còn cao sau khi đã nhận symbol đầu tiên, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
                end

                PARITY: begin
                    if (~(sop_in | vld_in) & ~cnt_end)      state_nxt = PARITY; // Khi chưa xuất đủ 29 symbols parity (count < 542), tiếp tục ở lại trạng thái PARITY để xuất tiếp các symbols parity còn lại
                    else if (~(sop_in | vld_in) & cnt_end)  state_nxt = DONE;   // Khi đã xuất đủ 29 symbols parity (count = 542, bit [9:1] đều là 1), chuyển sang trạng thái DONE để xuất symbol parity cuối cùng và sẵn sàng nhận gói tin mới
                    else                                    state_nxt = ERROR;  // Nếu vld_in vẫn còn cao sau khi đã xuất đủ parity, hoặc sop_in lên cao trước khi đã xuất đủ parity, đều là tín hiệu không hợp lệ và chuyển sang trạng thái lỗi ERROR
                end

                DONE: begin
                    if (~(sop_in | vld_in)) state_nxt = IDLE;  // 
                    else                    state_nxt = ERROR; // 
                end

                ERROR: begin
                    if (sop_in & vld_in)            state_nxt = MSG;    // Khi ở trạng thái lỗi, nếu nhận được gói tin mới, chuyển sang trạng thái MSG để bắt đầu xử lý gói tin mới
                    else if (~(sop_in | vld_in))    state_nxt = IDLE;   // Khi ở trạng thái lỗi, nếu không nhận được gói tin mới, quay về trạng thái IDLE để sẵn sàng nhận gói tin mới
                    else                            state_nxt = ERROR;  // Nếu ở trạng thái lỗi, nhưng tín hiệu sop_in và vld_in không hợp lệ (ví dụ sop_in lên cao mà vld_in không lên cao, hoặc ngược lại), vẫn ở lại trạng thái lỗi ERROR
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

endmodule: rs_enc_ctrl
