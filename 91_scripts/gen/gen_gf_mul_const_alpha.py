import model.gf210_lib as gf
import os

def get_matrix_for_constant(c):
    """
    Tạo ma trận nhị phân 10x10 biểu diễn phép nhân hằng số c trong GF(2^10).
    Mỗi cột j của ma trận là kết quả của phép tính (c * alpha^j).
    """
    matrix = []
    for j in range(10):
        # Thực hiện nhân hằng số c với đơn thức x^j (alpha^j) trong trường GF
        val = gf.gf_mul(c, 1 << j) 
        
        # Chuyển đổi giá trị kết quả thành vector cột 10-bit nhị phân
        column = [(val >> i) & 1 for i in range(10)]
        matrix.append(column)
    
    # Chuyển vị ma trận (Transposition):
    # Chuyển từ quản lý theo cột (dữ liệu vào) sang quản lý theo dòng (dữ liệu ra).
    # m_t[i][j] == 1 nghĩa là bit đầu vào thứ j sẽ tham gia vào biểu thức XOR của bit đầu ra thứ i.
    return [[matrix[j][i] for j in range(10)] for i in range(10)]

def generate_syndrome_mults():
    # 1. Khởi tạo bảng toán học
    gf.generate_tables()
    
    # 2. Định nghĩa đường dẫn file đầu ra
    # Lưu ý: Tôi đặt file này vào thư mục rtl/fec chung hoặc thư mục con tùy bạn
    output_dir = "../00_rtl/fec/common"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    output_filename = f"{output_dir}/gf_mul_const_alpha.sv"

    print(f"Đang tạo file tổng hợp: {output_filename} ...")

    # 3. Mở file MỘT LẦN DUY NHẤT để ghi toàn bộ nội dung
    with open(output_filename, "w") as f:
        # Ghi Header chung cho file
        f.write("// =========================================================\n")
        f.write("// AUTO-GENERATED SYNDROME MULTIPLIERS FOR RS(544, 514)\n")
        f.write("// Contains 30 modules: gf_mul_const_alpha0 to alpha29\n")
        f.write("// =========================================================\n\n")

        # 4. Vòng lặp sinh 30 module liên tiếp
        for i in range(30):
            # Tính giá trị hằng số alpha^i
            constant_val = gf.power_table[i] 
            
            f.write(f"// --- Module {i}: Multiplier by Alpha^{i} (Dec: {constant_val}) ---\n")
            f.write(f"module gf_mul_const_alpha{i} (\n")
            f.write(f"    input  logic [9:0] a,\n")
            f.write(f"    output logic [9:0] p\n")
            f.write(f");\n")
            
            # Tạo ma trận nhân cho hằng số này
            m_t = get_matrix_for_constant(constant_val)
            
            # Ghi các lệnh assign
            for row in range(10):
                terms = [f"a[{col}]" for col in range(10) if m_t[row][col] == 1]
                rhs = " ^ ".join(terms) if terms else "10'b0"
                f.write(f"    assign p[{row}] = {rhs};\n")
            
            f.write("endmodule\n\n") # Xuống dòng để tách biệt các module

    print("-> Hoàn tất! Tất cả module đã được gộp trong 1 file.")

if __name__ == "__main__":
    generate_syndrome_mults()