import os
import sys
import random

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_top_decoder_test_vectors():
    print("--- GENERATING SYSTEM-LEVEL TEST VECTORS FOR RS_DEC ---")
    
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
    PAD_LEN = N_FULL - N_SHORT # 479 symbols 0 đệm thêm
    
    TOTAL_CASES = 100
    
    # Khởi tạo mã gốc RS(1023, 993) với c=0 (khớp với phần cứng)
    rs = galois.ReedSolomon(N_FULL, K_FULL, c=0, field=GF)
    
    # Hàm phụ trợ: Sinh Codeword hợp lệ dài 544 symbols
    def get_valid_shortened_cw(msg_short=None):
        if msg_short is None:
            msg_short = GF.Random(K_SHORT)
        # Đệm 479 số 0 vào MSB
        msg_full = np.concatenate((GF.Zeros(PAD_LEN), msg_short))
        # Mã hóa bằng mã mẹ
        cw_full = rs.encode(msg_full)
        # Cắt bỏ 479 số 0 ở đầu, bọc lại bằng GF() để bảo toàn metadata Galois Field
        return GF(cw_full[PAD_LEN:])

    # Hai mảng song song chứa Input (bị nhiễu) và Expected (gốc)
    inputs_corrupted = []
    expected_clean = []
    
    # ---------------------------------------------------------
    # 2. CHIẾN LƯỢC CHÈN LỖI (ERROR INJECTION SCENARIOS)
    # ---------------------------------------------------------
    
    # Case 1: Clean All-Zeros (Gói tin toàn 0, không lỗi)
    cw_c1 = get_valid_shortened_cw(GF.Zeros(K_SHORT))
    expected_clean.append(cw_c1)
    inputs_corrupted.append(cw_c1.copy())
    
    # Case 2: Clean Random (Gói tin ngẫu nhiên, không lỗi)
    cw_c2 = get_valid_shortened_cw()
    expected_clean.append(cw_c2)
    inputs_corrupted.append(cw_c2.copy())
    
    # Case 3: Single Error at MSB (Lỗi tại index 0)
    cw_c3 = get_valid_shortened_cw()
    corrupted_c3 = cw_c3.copy()
    corrupted_c3[0] += GF(random.randint(1, 1023)) # Phép cộng trong GF chính là XOR
    expected_clean.append(cw_c3)
    inputs_corrupted.append(corrupted_c3)
    
    # Case 4: Single Error at LSB (Lỗi tại index 543)
    cw_c4 = get_valid_shortened_cw()
    corrupted_c4 = cw_c4.copy()
    corrupted_c4[-1] += GF(random.randint(1, 1023))
    expected_clean.append(cw_c4)
    inputs_corrupted.append(corrupted_c4)
    
    # Case 5: Max Correctable Errors (15 lỗi ngẫu nhiên)
    cw_c5 = get_valid_shortened_cw()
    corrupted_c5 = cw_c5.copy()
    err_pos_c5 = random.sample(range(N_SHORT), 15)
    for p in err_pos_c5:
        corrupted_c5[p] += GF(random.randint(1, 1023))
    expected_clean.append(cw_c5)
    inputs_corrupted.append(corrupted_c5)
    
    # Case 6: Max Burst Errors (15 lỗi liên tiếp)
    cw_c6 = get_valid_shortened_cw()
    corrupted_c6 = cw_c6.copy()
    start_idx = random.randint(0, N_SHORT - 15)
    for p in range(start_idx, start_idx + 15):
        corrupted_c6[p] += GF(random.randint(1, 1023))
    expected_clean.append(cw_c6)
    inputs_corrupted.append(corrupted_c6)
    
    # Case 7 -> 100: General Random Errors (Từ 2 đến 14 lỗi)
    while len(inputs_corrupted) < TOTAL_CASES:
        cw_rnd = get_valid_shortened_cw()
        corrupted_rnd = cw_rnd.copy()
        num_errs = random.randint(2, 14)
        err_pos_rnd = random.sample(range(N_SHORT), num_errs)
        for p in err_pos_rnd:
            corrupted_rnd[p] += GF(random.randint(1, 1023))
            
        expected_clean.append(cw_rnd)
        inputs_corrupted.append(corrupted_rnd)
        
    # ---------------------------------------------------------
    # 3. ĐỊNH DẠNG DỮ LIỆU ĐẦU RA (FILE FORMATTING)
    # ---------------------------------------------------------
    in_lines = []
    exp_lines = []
    
    for i in range(TOTAL_CASES):
        # Format Hex 10-bit (3 ký tự), cách nhau bởi khoảng trắng
        in_str = " ".join([f"{int(val):03X}" for val in inputs_corrupted[i]])
        exp_str = " ".join([f"{int(val):03X}" for val in expected_clean[i]])
        
        in_lines.append(in_str)
        exp_lines.append(exp_str)

    # ---------------------------------------------------------
    # 4. XỬ LÝ ĐƯỜNG DẪN TƯƠNG ĐỐI & GHI FILE
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi 2 cấp từ '91_scripts/gen', đi vào '10_sim/fec/rs_dec/rs_dec'
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec"))
    
    # Tự động tạo cây thư mục nếu chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_in.hex")
    exp_file_path = os.path.join(target_dir, "rs_dec_out_exp.hex")
    
    with open(in_file_path, "w") as f:
        f.write("\n".join(in_lines) + "\n")
        
    with open(exp_file_path, "w") as f:
        f.write("\n".join(exp_lines) + "\n")
        
    print(f"-> THÀNH CÔNG! Đã tạo {TOTAL_CASES} System-Level Testcases cho rs_dec.")
    print(f"   + Input Vectors (Corrupted) : {in_file_path}")
    print(f"   + Expected Out  (Cleaned)   : {exp_file_path}")

if __name__ == "__main__":
    generate_top_decoder_test_vectors()
