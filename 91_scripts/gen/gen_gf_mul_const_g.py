# gen_gf_mul.py

import model.gf210_lib as gf  # Thư viện toán học GF(2^10) đã xây dựng
import model.rs_codec as rs   # Thư viện mã hóa Reed-Solomon

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

def generate_rtl_constants(file_path):
    """
    Hàm chính để tính toán đa thức tạo mã và xuất file SystemVerilog.
    """
    # Khởi tạo bảng Log/Antilog cho các phép tính GF
    gf.generate_tables()
    
    # Tạo đa thức tạo mã g(x) bậc 30 cho chuẩn RS(544, 514)
    # Kết quả trả về 31 hệ số (g0 đến g30)
    g_poly = rs.generate_generator_poly(30) 
    
    with open(file_path, "w") as f:
        # Ghi header cho file RTL
        f.write("// Auto-generated GF(2^10) Constant Multipliers\n")
        f.write("// Generator Polynomial coefficients for RS(544, 514)\n\n")
        
        # Duyệt qua 30 hệ số đầu tiên (g0 đến g29). g30=1 không cần bộ nhân.
        for idx in range(30):
            c = g_poly[idx]
            m_t = get_matrix_for_constant(c)
            
            # Bắt đầu định nghĩa một module SystemVerilog cho mỗi hệ số g_i
            f.write(f"module gf_mul_const_g{idx} (\n")
            f.write(f"    input  logic [9:0] a, // Feedback input\n")
            f.write(f"    output logic [9:0] p  // Result p = a * g{idx}\n")
            f.write(f");\n")
            
            # Sinh phương trình logic cho từng bit đầu ra từ p[0] đến p[9]
            for i in range(10):
                # Tìm các chỉ số j mà tại đó m_t[i][j] bằng 1
                terms = [f"a[{j}]" for j in range(10) if m_t[i][j] == 1]
                
                # Nối các biến đầu vào bằng toán tử XOR (^). 
                # Nếu không có bit nào (hệ số bằng 0), gán giá trị 0 tĩnh.
                rhs = " ^ ".join(terms) if terms else "10'b0"
                f.write(f"    assign p[{i}] = {rhs};\n")
            
            f.write(f"endmodule\n\n")

if __name__ == "__main__":
    # Đường dẫn xuất file RTL vào thư mục 01_rtl
    output_file = "../00_rtl/fec/gf_mul_constants.sv"
    generate_rtl_constants(output_file)
    print(f"Successfully generated {output_file}")