import galois
import numpy as np
import os

def save_hex(data, filename):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'w') as f:
        for val in data:
            f.write(f"{int(val):03x}\n")

def main():
    print("--- GENERATING CHIEN SEARCH VECTORS (REVERSE ENGINEERED) ---")
    
    # 1. Cấu hình trường Galois
    gf = galois.GF(2**10, irreducible_poly=1033)
    alpha = gf.primitive_element
    T = 15
    
    # 2. Định nghĩa kịch bản lỗi (Ground Truth)
    # Lỗi tại vị trí 543, 533, 500
    err_pos_idx = [0, 10, 43] 
    err_locs    = [543, 533, 500] # Vị trí thực tế = 543 - index
    err_vals    = [gf(123), gf(456), gf(789)]
    
    print(f"Injecting Errors at positions: {err_locs}")
    
    # 3. Tính Lambda(x) từ vị trí lỗi
    # Lambda(x) = Product (1 + x * alpha^Pos)
    # FIX: Dùng galois.Poly thay vì gf.Poly
    lam_poly = galois.Poly([1], field=gf)
    for loc in err_locs:
        # term = (1 + x * alpha^loc)
        # galois.Poly coeffs are [an, ..., a0]. 
        # (1 + A*x) -> coeffs [A, 1]
        term = galois.Poly([alpha**loc, 1], field=gf)
        lam_poly = lam_poly * term
        
    print("Generated Lambda (Polynomial):", lam_poly)
    
    # Chuyển Lambda thành mảng 16 phần tử (Low coeff first cho RTL)
    # coeffs của galois là High->Low. Cần đảo ngược.
    lam_coeffs = lam_poly.coeffs[::-1]
    lam_arr = np.pad(lam_coeffs, (0, 16 - len(lam_coeffs)), 'constant')
    
    # 4. Tính Omega(x)
    # Omega(x) = S(x) * Lambda(x) mod x^2T
    # Trước hết tính Syndrome S(x)
    # S_j = Sum(e_i * (alpha^loc_i)^j)
    syndromes = []
    for j in range(30):
        s_val = gf(0)
        for i in range(len(err_locs)):
            loc = err_locs[i]
            val = err_vals[i]
            s_val += val * (alpha**(loc * j))
        syndromes.append(s_val)
        
    # Lưu ý: Phép nhân đa thức S(x) * Lambda(x) phải cẩn thận chiều
    # S(x) = S0 + S1 x + ...
    # Lambda(x) = 1 + L1 x + ...
    # Ta dùng danh sách hệ số để nhân thủ công cho chắc chắn (Convolution)
    S_coeffs = syndromes # [S0, S1, ...]
    L_coeffs = list(lam_arr) # [1, L1, L2...]
    
    omg_coeffs_list = [gf(0)] * 30
    for k in range(16): # Chỉ cần tính đến bậc 15
        val = gf(0)
        for j in range(k + 1):
            if j < len(L_coeffs) and (k-j) < len(S_coeffs):
                val += L_coeffs[j] * S_coeffs[k-j]
        omg_coeffs_list[k] = val
        
    omg_arr = np.array(omg_coeffs_list[:16]) # Lấy 16 hệ số đầu
    
    # 5. Tạo Expected Output
    error_pattern_exp = [0] * 544
    for p, v in zip(err_pos_idx, err_vals):
        error_pattern_exp[p] = int(v)

    # 6. Xuất File
    # Điều chỉnh đường dẫn tương đối để chạy từ thư mục gốc hoặc thư mục gen đều được
    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(script_dir, "../../10_sim/fec/rs_dec/rs_dec_chien")
    
    # Đảm bảo thư mục tồn tại
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    save_hex(lam_arr, f"{out_dir}/lambda_in.hex")
    save_hex(omg_arr, f"{out_dir}/omega_in.hex")
    save_hex(error_pattern_exp, f"{out_dir}/error_out_exp.hex")
    
    print(f"-> Generated files in: {out_dir}")

if __name__ == "__main__":
    main()