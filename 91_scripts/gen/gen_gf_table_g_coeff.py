import os
import sys

# Bẫy lỗi import các thư viện cốt lõi
try:
    import numpy as np
    import pandas as pd
    import galois
except ImportError:
    print("Lỗi: Thiếu một hoặc nhiều thư viện cốt lõi.")
    print("Vui lòng chạy lệnh: pip install galois pandas openpyxl numpy")
    sys.exit(1)

def generate_g_coeffs_table():
    print("--- GENERATING GENERATOR POLYNOMIAL COEFFICIENTS ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # Khởi tạo trường GF(2^10) với đa thức p(x) = x^10 + x^3 + 1 (Dec: 1033)
    gf = galois.GF(2**10, irreducible_poly=1033)
    alpha = gf.primitive_element
    
    # Tạo 30 nghiệm của đa thức g(x): alpha^0, alpha^1, ..., alpha^29
    roots = alpha ** np.arange(30)
    
    # Nhân bung đa thức g(x) = (x - a^0)(x - a^1)...(x - a^29)
    g_poly = galois.Poly.Roots(roots, field=gf)
    
    # QUAN TRỌNG: galois trả về hệ số từ bậc cao nhất (x^30) xuống thấp nhất (x^0)
    # RTL Engineer cần hệ số g_i tương ứng với bậc x^i, nên phải đảo ngược mảng
    coeffs_asc = g_poly.coeffs[::-1]
    
    data = []
    
    # ---------------------------------------------------------
    # 2. SINH DỮ LIỆU BẢNG (DATA FORMATTING)
    # ---------------------------------------------------------
    # Duyệt qua mảng hệ số đã đảo ngược (từ g_0 đến g_30)
    for i, coeff in enumerate(coeffs_asc):
        val_dec = int(coeff)
        # Định dạng nhị phân 10-bit, lấp đầy số 0 ở MSB nếu cần
        val_bin = format(val_dec, '010b')
        
        data.append({
            "Index (i)": i,
            "g_i (Decimal)": val_dec,
            "g_i (Binary 10-bit)": val_bin
        })
        
    df = pd.DataFrame(data)
    
    # ---------------------------------------------------------
    # 3. XỬ LÝ ĐƯỜNG DẪN (RELATIVE PATH RESOLUTION)
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi về Project Root, trỏ tới 92_doc/table/
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "92_doc", "table"))
    os.makedirs(target_dir, exist_ok=True)
    
    file_path = os.path.join(target_dir, "gf_g_coefficients.xlsx")
    print(f"Target Output: {file_path}")
    
    # ---------------------------------------------------------
    # 4. GHI FILE EXCEL (EXCEL EXPORT)
    # ---------------------------------------------------------
    try:
        df.to_excel(file_path, index=False, engine='openpyxl')
        print(f"-> Thành công! Bảng hệ số với {len(df)} phần tử đã được lưu.")
        
        # In nhẹ kết quả ra Terminal để người dùng Verify nhanh
        print("\n--- Quick Verify (First 3 & Last 3) ---")
        print(df.head(3).to_string(index=False))
        print("...")
        print(df.tail(3).to_string(index=False))
        
    except ImportError:
        print("Lỗi: Không tìm thấy thư viện 'openpyxl'.")
        print("Vui lòng chạy lệnh: pip install openpyxl")
        sys.exit(1)

if __name__ == "__main__":
    generate_g_coeffs_table()