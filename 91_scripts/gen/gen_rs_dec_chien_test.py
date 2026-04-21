import os
import sys
import random

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_chien_test_vectors():
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # Khởi tạo trường GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1
    GF = galois.GF(2**10, irreducible_poly=1033)
    alpha = GF(2)
    
    num_cases = 100
    cycles = 544
    
    # Hàm phụ trợ: Tạo đa thức Lambda(x) từ danh sách vị trí lỗi
    # Toán học: Lambda(x) = Tích của (1 - alpha^(-C) * x)
    def create_lambda(error_positions):
        poly = galois.Poly([1], field=GF)
        for c in error_positions:
            # Tạo nhân tử: alpha^(-C) * x + 1
            # Hệ số bậc 1 là alpha^(-C), bậc 0 là 1
            factor = galois.Poly([alpha**(-c), GF(1)], field=GF)
            poly = poly * factor
            
        # Lấy mảng hệ số và đảo ngược (để index i tương ứng hệ số bậc x^i)
        coeffs_asc = poly.coeffs[::-1]
        
        # Đệm thêm số 0 để luôn đảm bảo có đủ 16 hệ số
        pad_len = 16 - len(coeffs_asc)
        if pad_len > 0:
            lam = np.concatenate((coeffs_asc, GF.Zeros(pad_len)))
        else:
            lam = coeffs_asc[:16] # Trích xuất 16 phần tử đầu tiên nếu vượt quá
        return lam

    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    test_cases = []
    
    # Case 1: Zero Errors
    lam_c1 = GF.Zeros(16); lam_c1[0] = 1
    ome_c1 = GF.Zeros(16)
    test_cases.append((lam_c1, ome_c1))
    
    # Case 2: Error at Cycle 0 (LSB)
    test_cases.append((create_lambda([0]), GF.Random(16)))
    
    # Case 3: Error at Cycle 543 (MSB)
    test_cases.append((create_lambda([543]), GF.Random(16)))
    
    # Case 4: Max Correctable Errors (15 errors)
    pos_c4 = random.sample(range(cycles), 15)
    test_cases.append((create_lambda(pos_c4), GF.Random(16)))
    
    # Case 5: Burst Errors (15 errors in a row)
    start_pos = random.randint(0, cycles - 15)
    pos_c5 = list(range(start_pos, start_pos + 15))
    test_cases.append((create_lambda(pos_c5), GF.Random(16)))
    
    # Case 6: Boundary Errors
    pos_c6 = [0, 1, cycles-2, cycles-1]
    test_cases.append((create_lambda(pos_c6), GF.Random(16)))
    
    # Case 7: Uncorrectable / Random Polynomial
    test_cases.append((GF.Random(16), GF.Random(16)))
    
    # Case 8 -> 100: Random Errors (2 to 14 errors)
    for _ in range(num_cases - 7):
        num_errs = random.randint(2, 14)
        pos = random.sample(range(cycles), num_errs)
        test_cases.append((create_lambda(pos), GF.Random(16)))

    # ---------------------------------------------------------
    # 3. MÔ PHỎNG PHẦN CỨNG BẰNG PYTHON (CYCLE-BY-CYCLE RTL MATCHING)
    # ---------------------------------------------------------
    inputs_hex = []
    expected_outputs_hex = []
    
    # Ma trận nhân của các thanh ghi: alpha^0, alpha^1, ..., alpha^15
    multiplier_array = alpha ** np.arange(16)

    for lam_in, ome_in in test_cases:
        # Chuẩn bị định dạng Input (lam_15 giảm dần về lam_0, sau đó ome_15 giảm dần về ome_0)
        lam_hex = [f"{int(x):03X}" for x in lam_in[::-1]]
        ome_hex = [f"{int(x):03X}" for x in ome_in[::-1]]
        inputs_hex.append(" ".join(lam_hex + ome_hex))
        
        # Nạp giá trị vào thanh ghi mô phỏng
        lam_reg = GF(lam_in)
        ome_reg = GF(ome_in)
        case_out = []
        
        # Mạch chạy đúng 544 nhịp Clock
        for c in range(cycles):
            # --- 1. Mạch Logic Tổ hợp (Combinational Logic) ---
            l_val_tot = np.sum(lam_reg)
            err_flg = 1 if l_val_tot == 0 else 0
            
            # Tính l_val_der bằng cách XOR (Cộng GF) các index lẻ: 1, 3, 5... 15
            l_val_der = np.sum(lam_reg[1::2])
            o_val = np.sum(ome_reg)
            
            # Đóng gói 21-bit: [err_flg (1)] [l_val_der (10)] [o_val (10)]
            out_val = (err_flg << 20) | (int(l_val_der) << 10) | int(o_val)
            case_out.append(f"{out_val:06X}")
            
            # --- 2. Cập nhật thanh ghi (D-Flip Flop Update) ---
            lam_reg = lam_reg * multiplier_array
            ome_reg = ome_reg * multiplier_array
            
        expected_outputs_hex.append(" ".join(case_out))

    # ---------------------------------------------------------
    # 4. LƯU FILE THEO ĐƯỜNG DẪN TƯƠNG ĐỐI
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_chien"))
    os.makedirs(target_dir, exist_ok=True)
    
    in_file = os.path.join(target_dir, "rs_dec_chien_in.hex")
    out_file = os.path.join(target_dir, "rs_dec_chien_out_exp.hex")
    
    with open(in_file, "w") as f:
        f.write("\n".join(inputs_hex) + "\n")
        
    with open(out_file, "w") as f:
        f.write("\n".join(expected_outputs_hex) + "\n")

    print(f"-> Thành công! Đã tạo 100 test cases cho khối Chien Search & Forney Evaluator.")
    print(f"   + Input Vectors : {in_file}")
    print(f"   + Expected Out  : {out_file}")

if __name__ == "__main__":
    generate_chien_test_vectors()