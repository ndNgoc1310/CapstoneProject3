import os
import sys
import random

try:
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện 'galois'. Vui lòng chạy lệnh: pip install galois")
    sys.exit(1)

def generate_forney_test_vectors():
    print("--- GENERATING TEST VECTORS FOR FORNEY EVALUATOR ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    
    TOTAL_TESTS = 10000
    test_cases = [] # Lưu các tuple: (err_flg, l_val_der, o_val)
    
    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    
    # Case 1: Không có lỗi (err_flg = 0)
    for _ in range(10):
        test_cases.append((0, random.randint(0, 1023), random.randint(0, 1023)))
        
    # Case 2: Cờ lỗi bật nhưng O_val = 0
    for _ in range(10):
        test_cases.append((1, random.randint(1, 1023), 0))
        
    # Case 3: Lỗi chia cho 0 (Hardware Exception: l_val_der = 0)
    for _ in range(10):
        test_cases.append((1, 0, random.randint(0, 1023)))
        
    # Case 4: Cả L_val_der và O_val đều bằng 0
    test_cases.append((1, 0, 0))
    
    # Case 5: O_val giống hệt L_val_der (X != 0)
    for _ in range(10):
        x = random.randint(1, 1023)
        test_cases.append((1, x, x))
        
    # Case 6: L_val_der = 1
    for _ in range(10):
        test_cases.append((1, 1, random.randint(0, 1023)))
        
    # Case 7: Quét Exhaustive (Random hóa diện rộng)
    # Thiên vị err_flg = 1 (90%) để tập trung test logic tính toán Galois
    while len(test_cases) < TOTAL_TESTS:
        err_flg = 1 if random.random() < 0.9 else 0
        l_val = random.randint(0, 1023)
        o_val = random.randint(0, 1023)
        test_cases.append((err_flg, l_val, o_val))
        
    # ---------------------------------------------------------
    # 3. MÔ PHỎNG PHẦN CỨNG BẰNG PYTHON (RTL-MATCHING BEHAVIOR)
    # ---------------------------------------------------------
    def hardware_forney(err_flg, l_val, o_val):
        """
        Mô phỏng chính xác thuật toán Forney và các ngoại lệ phần cứng.
        """
        # Cổng AND với {10{err_flg}} ở đầu ra mạch RTL
        if err_flg == 0:
            return 0
            
        # [QUAN TRỌNG] Bẫy lỗi ZeroDivisionError để khớp với RTL:
        # Trong phần cứng, ROM gf_inv quy định địa chỉ 0 trả về giá trị 0.
        if l_val == 0:
            return 0
            
        # Nếu không có ngoại lệ, tính toán GF bình thường
        l_inv = GF(l_val) ** -1
        err_mag = GF(o_val) * l_inv
        
        return int(err_mag)

    # Tính toán mảng Expected Output
    in_lines = []
    out_lines = []
    
    for case in test_cases:
        e_flg, l_val, o_val = case
        mag = hardware_forney(e_flg, l_val, o_val)
        
        # Format Hex 1 ký tự cho cờ, 3 ký tự (in HOA) cho dữ liệu 10-bit
        in_lines.append(f"{e_flg:1X} {l_val:03X} {o_val:03X}")
        out_lines.append(f"{mag:03X}")

    # ---------------------------------------------------------
    # 4. XỬ LÝ ĐƯỜNG DẪN TƯƠNG ĐỐI & GHI FILE
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi lại 2 cấp từ '91_scripts/gen' về Project Root, rồi vào '10_sim/fec/rs_dec/rs_dec_forney'
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_forney"))
    
    # Tạo thư mục nếu chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_forney_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_forney_out_exp.hex")
    
    with open(in_file_path, "w") as f:
        f.write("\n".join(in_lines) + "\n")
        
    with open(out_file_path, "w") as f:
        f.write("\n".join(out_lines) + "\n")
        
    print(f"-> THÀNH CÔNG! Đã tạo {TOTAL_TESTS} test cases.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_forney_test_vectors()
