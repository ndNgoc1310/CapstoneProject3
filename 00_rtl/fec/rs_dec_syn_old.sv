module rs_dec_syn (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sop,       // Start of Packet (Thay cho init)
    input  logic        valid_in,  // Valid Data (Thay cho enable)
    input  logic [9:0]  data_in,   // Input u (10-bit)
    
    output logic        valid_out, // Báo hiệu tính xong (kết thúc gói)
    output logic [9:0]  syndromes [29:0] // Output song song 30 syndromes
);

   // --- Parameters ---
    localparam K = 514;               // Số lượng symbols dữ liệu (message) trong một codeword
    localparam N = 544;               // Tổng số lượng symbols sau khi mã hóa (Codeword = Message + Parity)
    localparam NSYM = 30;             // Số lượng symbols kiểm soát lỗi (Parity symbols = N - K)

    // Mảng thanh ghi lưu trữ Syndrome (Thay cho y0..y31)
    logic [9:0] syn_reg [29:0];
    logic [9:0] mul_res [29:0]; // Kết quả nhân (Thay cho scale0..scale31)

    // --- 1. Instantiate 30 Bộ Nhân Hằng Số (Generated from Python) ---
    // S0: Nhân với alpha^0 = 1 (Thực tế là pass-through)
    gf_mul_const_alpha0  u0  (.a(syn_reg[0]),  .p(mul_res[0]));
    gf_mul_const_alpha1  u1  (.a(syn_reg[1]),  .p(mul_res[1]));
    gf_mul_const_alpha2  u2  (.a(syn_reg[2]),  .p(mul_res[2]));
    gf_mul_const_alpha3  u3  (.a(syn_reg[3]),  .p(mul_res[3]));
    gf_mul_const_alpha4  u4  (.a(syn_reg[4]),  .p(mul_res[4]));
    gf_mul_const_alpha5  u5  (.a(syn_reg[5]),  .p(mul_res[5]));
    gf_mul_const_alpha6  u6  (.a(syn_reg[6]),  .p(mul_res[6]));
    gf_mul_const_alpha7  u7  (.a(syn_reg[7]),  .p(mul_res[7]));
    gf_mul_const_alpha8  u8  (.a(syn_reg[8]),  .p(mul_res[8]));
    gf_mul_const_alpha9  u9  (.a(syn_reg[9]),  .p(mul_res[9]));
    gf_mul_const_alpha10 u10 (.a(syn_reg[10]), .p(mul_res[10]));
    gf_mul_const_alpha11 u11 (.a(syn_reg[11]), .p(mul_res[11]));
    gf_mul_const_alpha12 u12 (.a(syn_reg[12]), .p(mul_res[12]));
    gf_mul_const_alpha13 u13 (.a(syn_reg[13]), .p(mul_res[13]));
    gf_mul_const_alpha14 u14 (.a(syn_reg[14]), .p(mul_res[14]));
    gf_mul_const_alpha15 u15 (.a(syn_reg[15]), .p(mul_res[15]));
    gf_mul_const_alpha16 u16 (.a(syn_reg[16]), .p(mul_res[16]));
    gf_mul_const_alpha17 u17 (.a(syn_reg[17]), .p(mul_res[17]));
    gf_mul_const_alpha18 u18 (.a(syn_reg[18]), .p(mul_res[18]));
    gf_mul_const_alpha19 u19 (.a(syn_reg[19]), .p(mul_res[19]));
    gf_mul_const_alpha20 u20 (.a(syn_reg[20]), .p(mul_res[20]));
    gf_mul_const_alpha21 u21 (.a(syn_reg[21]), .p(mul_res[21]));
    gf_mul_const_alpha22 u22 (.a(syn_reg[22]), .p(mul_res[22]));
    gf_mul_const_alpha23 u23 (.a(syn_reg[23]), .p(mul_res[23]));
    gf_mul_const_alpha24 u24 (.a(syn_reg[24]), .p(mul_res[24]));
    gf_mul_const_alpha25 u25 (.a(syn_reg[25]), .p(mul_res[25]));
    gf_mul_const_alpha26 u26 (.a(syn_reg[26]), .p(mul_res[26]));
    gf_mul_const_alpha27 u27 (.a(syn_reg[27]), .p(mul_res[27]));
    gf_mul_const_alpha28 u28 (.a(syn_reg[28]), .p(mul_res[28]));
    gf_mul_const_alpha29 u29 (.a(syn_reg[29]), .p(mul_res[29]));

    // --- 2. Sequential Logic ---
    // Bạn cần một bộ đếm để biết khi nào kết thúc 544 symbols
    logic [9:0] count;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<NSYM; i++) syn_reg[i] <= 10'd0;
            count <= 10'd0;
            valid_out <= 1'b0;
        end
        else begin
            if (valid_in) begin
                // Logic SOP: Tương đương với tín hiệu 'init' trong code tham khảo
                if (sop) begin 
                    for (int i=0; i<NSYM; i++) syn_reg[i] <= data_in; // Nạp symbol đầu tiên
                    count <= 10'd1;
                    valid_out <= 1'b0;
                end
                else begin
                    // Logic ENABLE: Tương đương 'scale ^ u'
                    for (int i=0; i<NSYM; i++) syn_reg[i] <= mul_res[i] ^ data_in;
                    
                    // Kiểm tra kết thúc gói tin (N=544)
                    if (count == N - 1) begin
                        valid_out <= 1'b1; // Báo hiệu đã tính xong
                        count <= 10'd0;
                    end else begin
                        count <= count + 10'd1;
                        valid_out <= 1'b0;
                    end
                end
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
    
    // Output assignment
    assign syndromes = syn_reg;

endmodule
