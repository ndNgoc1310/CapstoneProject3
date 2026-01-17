module rs_dec_kes (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,            // Bắt đầu tính (khi Syndrome Calc xong)
    input  logic [9:0]  syndromes_in [29:0], // 30 Syndromes từ khối trước
    
    output logic        done,             // Báo hiệu xong
    output logic [9:0]  lambda [15:0],    // Kết quả Lambda (Bậc tối đa 15)
    output logic [9:0]  omega [15:0]      // Kết quả Omega
);

    // --- Constants ---
    localparam T = 15;
    localparam K_STEPS = 30; // 2T = 30 bước lặp

    // --- States ---
    typedef enum logic [1:0] {IDLE, CALC, FINISH} state_t;
    state_t state;

    // --- Internal Registers ---
    logic [9:0] lam_reg [15:0];
    logic [9:0] b_reg   [15:0];
    logic [9:0] omg_reg [15:0];
    logic [9:0] a_reg   [15:0];
    
    logic [9:0] syn_shift   [29:0];   // Shift register cho Syndromes
    logic [9:0] syn_window  [15:0];
    
    logic [9:0] delta, gamma;
    logic [4:0] k_cnt;  // Đếm bước lặp (0..29)
    logic [4:0] L;      // Độ dài hiệu dụng hiện tại

    // --- Signals for Computation ---
    logic [9:0] del_term [15:0];  // Kết quả nhân từng phần tử để tính Delta
    
    logic [9:0] lam_term    [15:0];    // gamma * lambda
    logic [9:0] del_term_b  [15:0];    // delta * b
    logic [9:0] lam_next    [15:0];
    
    logic [9:0] omg_term    [15:0];    // gamma * omega
    logic [9:0] del_term_a  [15:0];    // delta * a
    logic [9:0] omg_next    [15:0];

    // ============================================================
    // 1. DELTA CALCULATION UNIT (Dot Product)
    // Delta = Sum(Lambda[i] * Syndrome[current - i])
    // Với cấu trúc Shift Register Syndrome, Syndrome[i] tương ứng S_{k-i}
    // ============================================================
    always_comb begin
        // Phần tử 0 là Syndrome hiện tại S_k (lấy trực tiếp từ input dựa vào k_cnt)
        syn_window[0] = syndromes_in[k_cnt]; 
        
        // Các phần tử tiếp theo là lịch sử: index j ứng với S_{k-j}
        // syn_shift[0] lưu S_{k-1}
        // syn_shift[j-1] lưu S_{k-j}
        for (int j = 1; j <= T; j++) begin
            syn_window[j] = syn_shift[j-1];
        end
    end
    
    genvar i;
    generate
        for (i = 0; i <= T; i++) begin : gen_delta_mul
            // Syndromes dịch chuyển sao cho syn_shift[i] luôn khớp với lam_reg[i]
            // Nhân Lambda[i] với S[k-i]
            gf_mul u_mul_delta (
                .a(lam_reg[i]), 
                .b(syn_window[i]), 
                .y(del_term[i])
            );
        end
    endgenerate

    // Cây XOR để cộng dồn del_term (Có thể viết loop cho gọn)
    always_comb begin
        delta = 10'd0;
        for (int j = 0; j <= T; j++) begin
            delta = delta ^ del_term[j];
        end
    end

    // ============================================================
    // 2. POLYNOMIAL UPDATE UNIT
    // Lambda_new = gamma * Lambda + delta * (x * B)
    // Omega_new  = gamma * Omega  + delta * (x * A)
    // (x * B) nghĩa là dịch B sang phải 1 đơn vị (hoặc dùng index thấp hơn)
    // ============================================================
    generate
        for (i = 0; i <= T; i++) begin : gen_update_mul
            // Tính gamma * lambda[i]
            gf_mul u_mul_g_lam (.a(gamma), .b(lam_reg[i]), .y(lam_term[i]));
            
            // Tính delta * b[i-1] (Logic dịch: b[-1] = 0)
            // Lưu ý: Trong iBM, B được cập nhật trước đó hoặc song song.
            // Ở đây ta dùng b_reg cũ. b_shifted[i] = b_reg[i-1]
            logic [9:0] b_val;
            assign b_val = (i == 0) ? 10'd0 : b_reg[i-1];
            gf_mul u_mul_d_b   (.a(delta), .b(b_val),      .y(del_term_b[i]));

            // Tương tự cho Omega
            gf_mul u_mul_g_omg (.a(gamma), .b(omg_reg[i]), .y(omg_term[i]));
            
            logic [9:0] a_val;
            assign a_val = (i == 0) ? 10'd0 : a_reg[i-1];
            gf_mul u_mul_d_a   (.a(delta), .b(a_val),      .y(del_term_a[i]));
        end
    endgenerate

    // Kết hợp kết quả cập nhật
    always_comb begin
        for (int j = 0; j <= T; j++) begin
            lam_next[j] = lam_term[j] ^ del_term_b[j];
            omg_next[j] = omg_term[j] ^ del_term_a[j];
        end
    end

    // ============================================================
    // 3. FINITE STATE MACHINE & SEQUENTIAL LOGIC
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            k_cnt <= 5'd0;
            done  <= 1'b0;
            // Reset Registers
            for (int j=0; j<=T; j++) begin
                lam_reg[j] <= 10'd0; b_reg[j] <= 10'd0;
                omg_reg[j] <= 10'd0; a_reg[j] <= 10'd0;
            end
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= CALC;
                        k_cnt <= 5'd0;
                        L     <= 5'd0;
                        gamma <= 10'd1; // Gamma khởi tạo = 1
                        
                        // Load Syndromes
                        for (int j=0; j<K_STEPS; j++) syn_shift[j] <= 10'd0;
                        
                        // Init Polynomials
                        lam_reg[0] <= 10'd1; b_reg[0] <= 10'd1;
                        omg_reg[0] <= 10'd1; a_reg[0] <= 10'd0; // Omega init khác B một chút trong Dual
                        // Lưu ý: Omega init phụ thuộc định nghĩa, thường Omega(0)=1
                        // A init = 0 vì bậc Omega thấp hơn
                        for (int j=1; j<=T; j++) begin
                            lam_reg[j] <= 10'd0; b_reg[j] <= 10'd0;
                            omg_reg[j] <= 10'd0; a_reg[j] <= 10'd0;
                        end
                    end
                end

                CALC: begin
                    // 1. Cập nhật Delta cho vòng lặp tiếp theo (hoặc dùng delta hiện tại)
                    // Ở đây delta là combinatorial từ lam_reg và syn_shift HIỆN TẠI
                    // Nên nó chính là delta_k
                    logic [9:0] d_curr;
                    d_curr = delta; 
                    
                    // 2. Cập nhật Lambda và Omega
                    for (int j=0; j<=T; j++) begin
                        lam_reg[j] <= lam_next[j];
                        omg_reg[j] <= omg_next[j];
                    end

                    // 3. Cập nhật B, A, L, Gamma (Thuật toán iBM)
                    // Điều kiện: delta != 0 và 2*L <= k
                    if (d_curr != 0 && (2*L <= k_cnt)) begin
                        // Cập nhật B = Lambda_old, A = Omega_old
                        for (int j=0; j<=T; j++) begin
                            b_reg[j] <= lam_reg[j];
                            a_reg[j] <= omg_reg[j];
                        end
                        // Cập nhật L và Gamma
                        L <= k_cnt + 1 - L;
                        gamma <= d_curr;
                    end
                    else begin
                        // B và A dịch trái (x * B)
                        // Trong kiến trúc này, ta giữ nguyên B, việc nhân x*B được xử lý ở logic "del_term_b"
                        // bằng cách lấy b[i-1]. 
                        // NHƯNG chờ đã: Logic del_term_b lấy b_reg[i-1], nghĩa là tự động dịch mỗi clock?
                        // KHÔNG. Logic del_term_b dùng B ĐANG CÓ.
                        // Nếu ta không update B, B vẫn giữ nguyên.
                        // -> Ta cần logic dịch B thủ công nếu không thỏa điều kiện update.
                        
                        // Logic chuẩn: B_new = x * B_old (dịch)
                        // Do thanh ghi b_reg cố định, ta phải dịch giá trị:
                        // b_reg[j] <= b_reg[j-1]
                        for (int j=T; j>0; j--) begin
                            b_reg[j] <= b_reg[j-1];
                            a_reg[j] <= a_reg[j-1];
                        end
                        b_reg[0] <= 10'd0;
                        a_reg[0] <= 10'd0;
                    end

                    // 4. Shift Syndromes (Chuẩn bị cho next step)
                    syn_shift[0] <= syndromes_in[k_cnt];
                    for (int j=1; j<T; j++) syn_shift[j] <= syn_shift[j-1];

                    // 5. Loop control
                    if (k_cnt == K_STEPS - 1) begin
                        state <= FINISH;
                    end else begin
                        k_cnt <= k_cnt + 1;
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    // Giữ nguyên giá trị Lambda/Omega output
                    state <= IDLE; // Hoặc giữ ở FINISH tùy handshake
                end
            endcase
        end
    end

    // Output assignments
    assign lambda = lam_reg;
    assign omega  = omg_reg;

endmodule
