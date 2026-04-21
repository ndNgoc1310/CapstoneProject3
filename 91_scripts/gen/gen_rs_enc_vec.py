import galois
import numpy as np

def main():
    print("--- BẮT ĐẦU TẠO GOLDEN MODEL VỚI GALOIS (SHORTENED) ---")

    # 1. Cấu hình trường Galois GF(2^10)
    # P(x) = 1033 (x^10 + x^3 + 1)
    gf = galois.GF(2**10, irreducible_poly=1033) 
    print(f"Trường Galois: {gf.properties}")

    # 2. Cấu hình mã Reed-Solomon
    # LƯU Ý QUAN TRỌNG: Phải khai báo Full Code (N=1023)
    # Số parity = 30 => K_full = 1023 - 30 = 993
    # c=0: Để khớp với nghiệm alpha^0..alpha^29 của bạn
    rs = galois.ReedSolomon(n=1023, k=993, c=0, field=gf)
    
    # --- CHECK HỆ SỐ g(x) ---
    g_poly = rs.generator_poly
    coeffs = [int(x) for x in g_poly.coeffs]
    coeffs_rtl_order = coeffs[::-1] # Đảo ngược để so với g0, g1...
    
    print("\n[CHECK] Hệ số đa thức sinh g(x):")
    print(f"g0 (Hex): {hex(coeffs_rtl_order[0])} (Kỳ vọng: 0x20b)")
    print(f"g0 (Dec): {coeffs_rtl_order[0]}")
    
    # 3. Tạo dữ liệu test (Message 514 symbols)
    msg_len = 514
    msg_int = [i % 1024 for i in range(msg_len)]
    msg = gf(msg_int)

    # 4. Mã hóa (Encode)
    # Thư viện sẽ tự động Shorten: Thêm 479 số 0 vào đầu, mã hóa, rồi trả về kết quả
    full_codeword = rs.encode(msg)
    
    # 5. Xử lý kết quả (Cắt bỏ phần Zero padding nếu thư viện trả về full 1023)
    # Hàm encode của galois thường trả về độ dài bằng message + parity nếu input ngắn hơn k
    # Nhưng để chắc chắn, ta lấy 30 phần tử cuối cùng làm Parity
    parity = full_codeword[-30:]
    
    print(f"\n[CHECK] 5 Parity Symbol đầu tiên:")
    print([hex(int(x)) for x in parity[:5]])

    # Ghép lại thành codeword chuẩn 544 symbol cho testbench
    # Lưu ý: full_codeword từ thư viện có thể chỉ chứa (Msg + Parity) -> Đúng ý ta
    # Hoặc chứa (Zeros + Msg + Parity). Ta cần kiểm tra độ dài.
    if len(full_codeword) == 1023:
        # Cắt bỏ 479 số 0 đầu tiên (1023 - 544 = 479)
        final_codeword = full_codeword[479:]
    else:
        final_codeword = full_codeword

    # 6. Xuất file
    save_hex(msg, "../10_sim/fec/rs_enc/rs_enc_input.hex")
    save_hex(final_codeword, "../10_sim/fec/rs_enc/rs_enc_output_exp.hex")
    print("\n-> Đã xuất file thành công.")

def save_hex(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            f.write(f"{int(val):03x}\n")

if __name__ == "__main__":
    main()