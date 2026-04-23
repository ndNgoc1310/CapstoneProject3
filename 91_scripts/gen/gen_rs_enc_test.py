import os
import sys
import random

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_enc_test_vectors():
    print("--- GENERATING TEST VECTORS FOR REED-SOLOMON ENCODER ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    
    # Kích thước mã rút gọn RS(544, 514)
    N_SHORT = 544
    K_SHORT = 514
    
    # Kích thước mã mẹ RS(1023, 993)
    N_FULL = 1023
    K_FULL = 993
    PAD_LEN = N_FULL - N_SHORT # 479 symbols 0
    
    TOTAL_CASES = 100
    
    # BẮT BUỘC: Khởi tạo mã gốc RS(1023, 993) với c=0 (khớp với phần cứng)
    rs = galois.ReedSolomon(N_FULL, K_FULL, c=0, field=GF)
    
    test_cases = [] # Chứa các mảng Message (514 symbols)
    
    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    
    # Case 1: All Zeros
    test_cases.append(GF.Zeros(K_SHORT))
    
    # Case 2: All Ones (0x3FF = 1023)
    test_cases.append(GF.Ones(K_SHORT) * 1023)
    
    # Case 3: Single Impulse at Start (m_0 = 1, còn lại = 0)
    c3 = GF.Zeros(K_SHORT)
    c3[0] = 1
    test_cases.append(c3)
    
    # Case 4: Single Impulse at End (m_513 = 1, còn lại = 0)
    c4 = GF.Zeros(K_SHORT)
    c4[-1] = 1
    test_cases.append(c4)
    
    # Case 5: Incrementing Pattern (0, 1, 2, ..., 513)
    test_cases.append(GF(np.arange(K_SHORT)))
    
    # Case 6: Alternating Pattern (0x155 và 0x2AA)
    # Tạo list xen kẽ bằng cách lặp mảng 2 phần tử lên 257 lần (257 * 2 = 514)
    alt_pattern = [0x155, 0x2AA] * (K_SHORT // 2)
    test_cases.append(GF(alt_pattern))
    
    # Case 7 -> 100: Random Data
    while len(test_cases) < TOTAL_CASES:
        test_cases.append(GF.Random(K_SHORT))
        
    # ---------------------------------------------------------
    # 3. TÍNH TOÁN EXPECTED OUTPUT (SHORTENED ENCODING)
    # ---------------------------------------------------------
    in_lines = []
    out_lines = []
    
    for msg in test_cases:
        # A. Format Input: 514 symbols của Message
        in_str = " ".join([f"{int(val):03X}" for val in msg])
        in_lines.append(in_str)
        
        # B. Rút gọn Mã (Shortening Strategy):
        # Đệm 479 số 0 vào đầu mảng Message
        msg_full = np.concatenate((GF.Zeros(PAD_LEN), msg))
        
        # Gọi hàm Encode của mã mẹ để tạo mảng 1023 symbols
        cw_full = rs.encode(msg_full)
        
        # Cắt bỏ 479 số 0 ở đầu mảng, bọc lại bằng GF để giữ nguyên metadata Galois Field
        cw_short = GF(cw_full[PAD_LEN:])
        
        # C. Format Output: 544 symbols của Codeword rút gọn
        out_str = " ".join([f"{int(val):03X}" for val in cw_short])
        out_lines.append(out_str)

    # ---------------------------------------------------------
    # 4. XỬ LÝ ĐƯỜNG DẪN TƯƠNG ĐỐI & GHI FILE
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi lại 2 cấp từ '91_scripts/gen' về Project Root, vào '10_sim/fec/rs_enc'
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_enc"))
    
    # Tự động tạo thư mục nếu chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_enc_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_enc_out_exp.hex")
    
    with open(in_file_path, "w") as f:
        f.write("\n".join(in_lines) + "\n")
        
    with open(out_file_path, "w") as f:
        f.write("\n".join(out_lines) + "\n")
        
    print(f"-> THÀNH CÔNG! Đã tạo {TOTAL_CASES} test cases cho khối RS Encoder.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_enc_test_vectors()
    