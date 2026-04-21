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
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    alpha = GF(2)
    
    n = 544      # Tổng số symbol của Codeword
    k = 514      # Số symbol của Message
    num_cases = 100
    
    # Sinh đa thức tạo mã g(x) = (x - a^0)(x - a^1)...(x - a^29)
    roots = alpha ** np.arange(30)
    g_poly = galois.Poly.Roots(roots, field=GF)

    # Hàm phụ trợ: Sinh một Codeword hợp lệ dài 544 symbols
    # Codeword = Message * x^30 + Parity
    def get_valid_codeword():
        msg = GF.Random(k)
        # Shift message lên 30 bậc bằng cách thêm 30 số 0 vào cuối mảng
        shifted_msg = np.concatenate((msg, GF.Zeros(30)))
        poly_shifted = galois.Poly(shifted_msg)
        
        # Chia cho g(x) lấy phần dư làm Parity
        _, parity_poly = divmod(poly_shifted, g_poly)
        parity_coeffs = parity_poly.coeffs
        
        # Đảm bảo Parity luôn đủ 30 symbols (nhồi 0 lên trước nếu thiếu)
        pad_len = 30 - len(parity_coeffs)
        if pad_len > 0:
            parity_padded = np.concatenate((GF.Zeros(pad_len), parity_coeffs))
        else:
            parity_padded = parity_coeffs
            
        # Nối Message và Parity thành mảng 544 symbols (từ R_543 giảm dần đến R_0)
        return np.concatenate((msg, parity_padded))

    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    test_cases = []
    
    # Case 1: All Zeros
    test_cases.append(GF.Zeros(n))
    
    # Case 2: All Ones (10'h3FF = 1023)
    test_cases.append(GF.Ones(n) * 1023)
    
    # Case 3: Valid Codeword (Expected Syndrome = All 0)
    test_cases.append(get_valid_codeword())
    
    # Case 4: Single Error at MSB (R_543)
    cw_c4 = get_valid_codeword()
    cw_c4[0] += GF(random.randint(1, 1023))
    test_cases.append(cw_c4)
    
    # Case 5: Single Error at LSB (R_0)
    cw_c5 = get_valid_codeword()
    cw_c5[-1] += GF(random.randint(1, 1023))
    test_cases.append(cw_c5)
    
    # Case 6: Max Correctable Errors (15 errors at random positions)
    cw_c6 = get_valid_codeword()
    pos_c6 = random.sample(range(n), 15)
    cw_c6[pos_c6] += GF.Random(15, low=1)
    test_cases.append(cw_c6)
    
    # Case 7: Burst Errors (15 consecutive errors)
    cw_c7 = get_valid_codeword()
    start_pos = random.randint(0, n - 15)
    cw_c7[start_pos:start_pos+15] += GF.Random(15, low=1)
    test_cases.append(cw_c7)
    
    # Case 8 -> 100: Random Errors (1 to 30 errors)
    for _ in range(num_cases - 7):
        cw_rnd = get_valid_codeword()
        num_errs = random.randint(1, 30)
        pos = random.sample(range(n), num_errs)
        cw_rnd[pos] += GF.Random(num_errs, low=1)
        test_cases.append(cw_rnd)

    # ---------------------------------------------------------
    # 3. TÍNH EXPECTED SYNDROMES BẰNG HORNER'S METHOD
    # ---------------------------------------------------------
    expected_outputs = []
    for cw in test_cases:
        syndromes = []
        # Tính S_i với i từ 0 đến 29
        for i in range(30):
            reg = GF(0)
            root_i = alpha ** i
            feedback = GF(0)
            
            # Cập nhật thanh ghi theo từng chu kỳ (Symbol đi vào từ R_543 đến R_0)
            for symbol in cw:
                feedback = reg + symbol
                reg = feedback * root_i
                
            # Giá trị feedback ở chu kỳ cuối cùng (sau khi quét hết 544 symbols) chính là Syndrome
            syndromes.append(feedback)
        expected_outputs.append(syndromes)

    # ---------------------------------------------------------
    # 4. ĐỊNH DẠNG VÀ GHI FILE (FILE EXPORT)
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_syn"))
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_syn_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_syn_out_exp.hex")
    
    # Ghi file Input: rs_dec_syn_in.hex (544 symbols mỗi dòng)
    with open(in_file_path, "w") as f_in:
        for cw in test_cases:
            # Ép kiểu int() và format chuẩn Hex 3 ký tự (03X)
            line = " ".join([f"{int(sym):03X}" for sym in cw])
            f_in.write(line + "\n")
            
    # Ghi file Output Expected: rs_dec_syn_out_exp.hex (30 syndromes mỗi dòng)
    with open(out_file_path, "w") as f_out:
        for syn in expected_outputs:
            line = " ".join([f"{int(s):03X}" for s in syn])
            f_out.write(line + "\n")

    print("-> Thành công! Đã tạo 100 test cases Corner Cases cho module Syndrome.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_syn_test_vectors()