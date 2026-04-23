import os
import sys
import random

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_syn_test_vectors():
    print("--- GENERATING TEST VECTORS FOR SYNDROME CALCULATOR ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    alpha = GF(2)
    
    N = 544
    K = 514
    N_FULL = 1023
    K_FULL = 993
    TOTAL_CASES = 100

    # BẮT BUỘC: c=0 để nghiệm bắt đầu từ alpha^0 đến alpha^29
    # Vì RS(544, 514) là mã rút gọn, ta phải dùng mã mẹ RS(1023, 993) để encode
    rs = galois.ReedSolomon(N_FULL, K_FULL, c=0, field=GF)
    
    test_cases = [] # Chứa các mảng Input R(x)
    
    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    
    # Case 1: All Zeros (Gói tin toàn 0)
    test_cases.append(GF.Zeros(N))
    
    # Case 2: All Ones (0x3FF = 1023)
    test_cases.append(GF.Ones(N) * 1023)
    
    # Case 3 -> 5: Zero Errors (Valid Codewords)
    for _ in range(3):
        msg = GF.Random(K)
        # Đệm 479 symbol '0' vào đầu (MSB) để đủ 993 symbol
        msg_padded = np.concatenate((GF.Zeros(K_FULL - K), msg))
        cw_full = rs.encode(msg_padded)
        # Cắt bỏ 479 symbol '0' ở đầu, chỉ lấy 544 symbol cuối
        cw = GF(cw_full[K_FULL - K:])
        test_cases.append(cw)
        
    # Case 6: Error at First Symbol (r_0 - MSB của đa thức R(x))
    c6 = GF.Zeros(N)
    c6[0] = GF(random.randint(1, 1023))
    test_cases.append(c6)
    
    # Case 7: Error at Last Symbol (r_543 - LSB của đa thức R(x))
    c7 = GF.Zeros(N)
    c7[N-1] = GF(random.randint(1, 1023))
    test_cases.append(c7)
    
    # Case 8 -> 20: Correctable Errors (Chèn 1 đến 15 lỗi ngẫu nhiên)
    for _ in range(13):
        msg = GF.Random(K)
        # Đệm 0 và mã hóa tương tự như trên
        msg_padded = np.concatenate((GF.Zeros(K_FULL - K), msg))
        cw_full = rs.encode(msg_padded)
        # Trích xuất codeword rút gọn và copy để chèn lỗi
        cw = GF(cw_full[K_FULL - K:])
        
        num_errs = random.randint(1, 15)
        err_pos = random.sample(range(N), num_errs)
        for p in err_pos:
            # Chèn lỗi (cộng trên trường GF tương đương phép XOR)
            cw[p] += GF(random.randint(1, 1023))
        test_cases.append(cw)
        
    # Case 21 -> 100: Random Data (Mô phỏng nhiễu trắng toàn dải)
    while len(test_cases) < TOTAL_CASES:
        test_cases.append(GF.Random(N))
        
    # ---------------------------------------------------------
    # 3. TÍNH TOÁN EXPECTED OUTPUT (RTL-MATCHING BEHAVIOR)
    # ---------------------------------------------------------
    in_lines = []
    out_lines = []
    
    for case in test_cases:
        # A. Format Input: Từ r_0 đến r_543
        in_str = " ".join([f"{int(val):03X}" for val in case])
        in_lines.append(in_str)
        
        # B. Ép mảng thành đa thức R(x) = r_0*x^543 + ... + r_543
        # galois.Poly nhận hệ số theo chiều bậc cao xuống thấp, nên đẩy trực tiếp `case` vào là chuẩn xác
        poly_R = galois.Poly(case, field=GF)
        
        # C. Tính 30 giá trị Syndrome: S_i = R(alpha^i)
        S = [poly_R(alpha**i) for i in range(30)]
        
        # D. Format Output: Bắt buộc đảo chiều từ S_29 lùi về S_0
        S_reversed = S[::-1]
        out_str = " ".join([f"{int(val):03X}" for val in S_reversed])
        out_lines.append(out_str)

    # ---------------------------------------------------------
    # 4. XỬ LÝ ĐƯỜNG DẪN TƯƠNG ĐỐI & GHI FILE
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi lại 2 cấp từ '91_scripts/gen' về Project Root, rồi vào '10_sim/fec/rs_dec/rs_dec_syn'
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_syn"))
    
    # Tự động tạo thư mục nếu chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_syn_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_syn_out_exp.hex")
    
    with open(in_file_path, "w") as f:
        f.write("\n".join(in_lines) + "\n")
        
    with open(out_file_path, "w") as f:
        f.write("\n".join(out_lines) + "\n")
        
    print(f"-> THÀNH CÔNG! Đã tạo {TOTAL_CASES} test cases cho khối Syndrome Calculator.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_syn_test_vectors()
    