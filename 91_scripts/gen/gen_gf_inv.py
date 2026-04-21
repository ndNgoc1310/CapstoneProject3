import os

try:
    import galois
except ImportError:
    print("Thư viện 'galois' chưa được cài đặt. Vui lòng chạy: pip install galois")
    exit(1)

def generate_gf_inv():
    print("--- GENERATING GF(2^10) INVERSION ROM ---")
    
    # 1. Cấu hình trường Galois GF(2^10)
    # Đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Hệ thập phân: 1033)
    gf = galois.GF(2**10, irreducible_poly=1033)
    
    # 2. Xử lý đường dẫn động (Relative Path)
    # File script nằm ở: <Project_Root>/91_scripts/gen/gen_gf_inv.py
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Lùi lại 2 cấp (lên Project_Root), rồi chui vào 00_rtl/fec/common
    project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    output_dir = os.path.join(project_root, "00_rtl", "fec", "common")
    
    # Tạo thư mục nếu chưa tồn tại (chống lỗi thư mục)
    os.makedirs(output_dir, exist_ok=True)
    
    output_file = os.path.join(output_dir, "gf_inv.sv")
    print(f"Target Output: {output_file}")
    
    # 3. Mở file và ghi nội dung RTL
    with open(output_file, "w", encoding="utf-8") as f:
        # Template Header
        f.write("// =========================================================\n")
        f.write("// Auto-generated GF(2^10) Inversion ROM\n")
        f.write("// Generated using Python 'galois' library\n")
        f.write("// =========================================================\n\n")
        
        # Module Interface
        f.write("module gf_inv (\n")
        f.write("    input  logic [9:0] x,\n")
        f.write("    output logic [9:0] x_inv\n")
        f.write(");\n\n")
        
        # Combinational Logic Block
        f.write("    always_comb begin\n")
        f.write("        case (x)\n")
        
        # Corner Case Toán học: 0 không có nghịch đảo, ép bằng 0 cho phần cứng
        f.write("            10'd0: x_inv = 10'd0; // 0 has no inverse\n")
        
        # Vòng lặp tính toán nghịch đảo từ 1 đến 1023
        for i in range(1, 1024):
            # Tính x^-1 trong GF(2^10) và ép kiểu về int
            inv_val = int(gf(i) ** -1)
            # Ghi ra định dạng 10'd<i_val>: x_inv = 10'd<inv_val>;
            f.write(f"            10'd{i}: x_inv = 10'd{inv_val};\n")
            
        # Default Case để chống sinh Latch trong RTL
        f.write("            default: x_inv = 10'd0;\n")
        f.write("        endcase\n")
        f.write("    end\n\n")
        
        f.write("endmodule\n")

    print("-> Thành công! File SystemVerilog đã được sinh ra.")

if __name__ == "__main__":
    generate_gf_inv()