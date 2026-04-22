import os
import sys

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_lifo_test_vectors():
    print("--- GENERATING TEST VECTORS FOR LIFO BUFFER ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    
    PACKET_SIZE = 544
    TOTAL_CASES = 100
    test_cases = [] # Mảng chứa các gói tin Input
    
    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH CORNER CASES (MEMORY TESTING)
    # ---------------------------------------------------------
    
    # Case 1: All Zeros (Kiểm tra lỗi kẹt mức 1)
    test_cases.append(GF.Zeros(PACKET_SIZE))
    
    # Case 2: All Ones (0x3FF = 1023) (Kiểm tra lỗi kẹt mức 0)
    test_cases.append(GF.Ones(PACKET_SIZE) * 1023)
    
    # Case 3: Incrementing Pattern (0, 1, 2, ..., 543) (Kiểm tra lỗi chập Data/Address)
    test_cases.append(GF(list(range(PACKET_SIZE))))
    
    # Case 4: Decrementing Pattern (543, 542, ..., 0) (Kiểm tra lỗi chập Address lùi)
    test_cases.append(GF(list(range(PACKET_SIZE - 1, -1, -1))))
    
    # Case 5: Alternating Bits (0x155 và 0x2AA) (Kiểm tra Crosstalk/Stuck-at)
    # Tạo list xen kẽ bằng cách nhân mảng 2 phần tử lên 272 lần (272 * 2 = 544)
    alt_pattern = [0x155, 0x2AA] * (PACKET_SIZE // 2)
    test_cases.append(GF(alt_pattern))
    
    # Case 6 -> 100: Random GF Data
    remaining_cases = TOTAL_CASES - len(test_cases)
    for _ in range(remaining_cases):
        test_cases.append(GF.Random(PACKET_SIZE))
        
    # ---------------------------------------------------------
    # 3. TẠO DỮ LIỆU I/O VÀ CHUYỂN ĐỔI HEX (FORMATTING)
    # ---------------------------------------------------------
    in_lines = []
    out_lines = []
    
    for case_in in test_cases:
        # LIFO Behavior: Output = Input reversed
        case_out_exp = case_in[::-1]
        
        # Format Hex 3 ký tự (03X), in HOA, cách nhau bởi khoảng trắng
        str_in = " ".join([f"{int(val):03X}" for val in case_in])
        str_out_exp = " ".join([f"{int(val):03X}" for val in case_out_exp])
        
        in_lines.append(str_in)
        out_lines.append(str_out_exp)

    # ---------------------------------------------------------
    # 4. XỬ LÝ ĐƯỜNG DẪN TƯƠNG ĐỐI & GHI FILE
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi lại 2 cấp từ '91_scripts/gen' về Project Root, vào '10_sim/fec/rs_dec/rs_dec_lifo'
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_lifo"))
    
    # Tự động tạo thư mục nếu chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_lifo_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_lifo_out_exp.hex")
    
    # Ghi file
    with open(in_file_path, "w") as f:
        f.write("\n".join(in_lines) + "\n")
        
    with open(out_file_path, "w") as f:
        f.write("\n".join(out_lines) + "\n")
        
    # Thông báo hoàn thành
    print(f"-> THÀNH CÔNG! Đã tạo {TOTAL_CASES} test cases cho LIFO.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_lifo_test_vectors()
    