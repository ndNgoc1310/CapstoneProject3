import model.gf210_lib as gf
import os

def generate_full_multiplier():
    # 1. Khởi tạo bảng toán học
    gf.generate_tables()
    
    # 2. Thiết lập đường dẫn output (dùng đường dẫn tương đối an toàn)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    output_dir = os.path.join(project_root, "00_rtl", "fec", "common")
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    filename = os.path.join(output_dir, "gf_mul.sv")
    
    print(f"Đang tạo bộ nhân GF(2^10) tổng quát: {filename}")
    
    with open(filename, "w") as f:
        f.write("// Auto-generated GF(2^10) General Multiplier\n")
        f.write("module gf_mul (\n")
        f.write("    input  logic [9:0] a,\n")
        f.write("    input  logic [9:0] b,\n")
        f.write("    output logic [9:0] y\n")
        f.write(");\n")
        f.write("    // Logic y = a * b in GF(2^10)\n")
        
        # contribution[k] lưu danh sách các tích a[i]&b[j] đóng góp vào bit y[k]
        contribution = [[] for _ in range(10)]
        
        for i in range(10): # Bit của a
            for j in range(10): # Bit của b
                # Tính x^i * x^j = x^(i+j) mod P(x)
                
                # --- SỬA LỖI TẠI ĐÂY ---
                if (i + j) < 10:
                    # Nếu bậc < 10, không cần modulo, bit bật là i+j
                    prod = 1 << (i + j) 
                else:
                    # Nếu bậc >= 10, dùng thư viện để nhân và lấy dư
                    val_a = 1 << i
                    val_b = 1 << j
                    prod = gf.gf_mul(val_a, val_b)
                # -----------------------
                
                # Kiểm tra kết quả prod có những bit nào bật
                for k in range(10):
                    if (prod >> k) & 1:
                        # Nếu bit k bật, nghĩa là a[i]*b[j] tham gia vào y[k]
                        contribution[k].append(f"(a[{i}] & b[{j}])")
                        
        # Ghi logic assign ra file
        for k in range(10):
            if not contribution[k]:
                f.write(f"    assign y[{k}] = 1'b0;\n")
            else:
                # Nối các phần tử bằng XOR (^)
                rhs = " ^ ".join(contribution[k])
                f.write(f"    assign y[{k}] = {rhs};\n")
                
        f.write("endmodule\n")

if __name__ == "__main__":
    generate_full_multiplier()