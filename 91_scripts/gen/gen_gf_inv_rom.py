import galois
import os

def main():
    print("--- GENERATING GF(2^10) INVERSION ROM (Using Galois Lib) ---")
    
    # 1. Cấu hình trường Galois GF(2^10)
    # P(x) = x^10 + x^3 + 1 (Decimal 1033)
    gf = galois.GF(2**10, irreducible_poly=1033)
    
    # 2. Định nghĩa đường dẫn file output
    # Đảm bảo thư mục tồn tại
    output_dir = "../00_rtl/fec/common" 
    # Nếu chạy từ thư mục root của project thì đường dẫn trên là đúng.
    # Nếu chạy từ trong thư mục 91_scripts/gen thì cần điều chỉnh.
    # Để an toàn, dùng đường dẫn tương đối từ vị trí script:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    rtl_dir = os.path.abspath(os.path.join(script_dir, "../../00_rtl/fec/common"))
    
    if not os.path.exists(rtl_dir):
        os.makedirs(rtl_dir)
        
    filename = os.path.join(rtl_dir, "gf_inv_rom.sv")
    
    print(f"Generating file: {filename}")
    
    with open(filename, "w") as f:
        f.write("// =========================================================\n")
        f.write("// Auto-generated GF(2^10) Inversion ROM\n")
        f.write("// Generated using Python 'galois' library\n")
        f.write("// =========================================================\n\n")
        
        f.write("module gf_inv_rom (\n")
        f.write("    input  logic [9:0] addr,\n")
        f.write("    output logic [9:0] data\n")
        f.write(");\n")
        f.write("    always_comb begin\n")
        f.write("        case (addr)\n")
        f.write("            10'd0: data = 10'd0; // 0 has no inverse\n")
        
        # 3. Tính nghịch đảo cho các phần tử từ 1 đến 1023
        for i in range(1, 1024):
            # Tạo phần tử trong trường GF
            elem = gf(i)
            
            # Tính nghịch đảo: elem^-1
            inv_elem = elem ** -1
            
            # Chuyển về số nguyên (int) để ghi vào Verilog
            val_inv = int(inv_elem)
            
            f.write(f"            10'd{i}: data = 10'd{val_inv};\n")
            
        f.write("            default: data = 10'd0;\n")
        f.write("        endcase\n")
        f.write("    end\n")
        f.write("endmodule\n")
        
    print("-> Successfully generated 'gf_inv_rom.sv'!")

if __name__ == "__main__":
    main()