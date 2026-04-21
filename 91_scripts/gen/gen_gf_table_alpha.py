import os
import sys

# Bẫy lỗi import các thư viện chính
try:
    import galois
    import pandas as pd
except ImportError as e:
    print("Lỗi: Thiếu thư viện cốt lõi.")
    print("Vui lòng chạy lệnh sau trong Terminal: pip install galois pandas openpyxl")
    sys.exit(1)

def generate_gf_alpha_table():
    print("--- GENERATING GF(2^10) ALPHA ELEMENTS EXCEL TABLE ---")
    
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Dec: 1033)
    gf = galois.GF(2**10, irreducible_poly=1033)
    alpha = gf.primitive_element
    
    data = []
    
    # ---------------------------------------------------------
    # 2. SINH DỮ LIỆU BẢNG (DATA GENERATION)
    # ---------------------------------------------------------
    # Chạy vòng lặp từ i = 0 đến 1022 (tổng cộng 1023 phần tử)
    for i in range(1023):
        # Tính lũy thừa alpha^i
        val = alpha ** i
        val_dec = int(val)
        
        # Chuyển sang chuỗi nhị phân 10-bit (nhồi số 0 ở MSB nếu thiếu)
        val_bin = format(val_dec, '010b')
        
        # Thêm vào mảng dữ liệu (tương ứng với các cột)
        data.append({
            "Index (i)": i,
            "Alpha^i (Decimal)": val_dec,
            "Alpha^i (Binary 10-bit)": val_bin
        })
        
    # Chuyển mảng từ điển thành Pandas DataFrame
    df = pd.DataFrame(data)
    
    # ---------------------------------------------------------
    # 3. XỬ LÝ ĐƯỜNG DẪN (RELATIVE PATH RESOLUTION)
    # ---------------------------------------------------------
    # Thư mục chứa script hiện tại (91_scripts/gen/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi về Project Root, trỏ tới 92_doc/table/
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "92_doc", "table"))
    
    # Tự động tạo thư mục nếu nó chưa tồn tại
    os.makedirs(target_dir, exist_ok=True)
    
    file_path = os.path.join(target_dir, "gf_alpha_elements.xlsx")
    print(f"Target Output: {file_path}")
    
    # ---------------------------------------------------------
    # 4. GHI FILE EXCEL (EXCEL EXPORT)
    # ---------------------------------------------------------
    try:
        # Xuất file Excel, không in cột index mặc định của pandas
        df.to_excel(file_path, index=False, engine='openpyxl')
        print("-> Thành công! File gf_alpha_elements.xlsx đã được sinh ra.")
    except ImportError:
        # Pandas văng lỗi này nếu hàm to_excel được gọi nhưng chưa cài openpyxl
        print("Lỗi: Không tìm thấy thư viện 'openpyxl'.")
        print("Pandas cần thư viện này để ghi file định dạng .xlsx.")
        print("Vui lòng chạy lệnh: pip install openpyxl")
        sys.exit(1)

if __name__ == "__main__":
    generate_gf_alpha_table()