# rs_codec.py

from .gf210_lib import gf_mul, gf_add, power_table, log_table

def gf_poly_mul(p, q):
    """Nhân hai đa thức trong GF(2^10)"""

    # 1. Khởi tạo danh sách kết quả với kích thước bậc n + m
    shift = [0] * (len(p) + len(q) - 1)   # Độ dài danh sách kết quả = len(p) + len(q) - 1

    # 2. Vòng lặp lồng nhau để nhân từng cặp hệ số
    for j in range(len(q)):         # Duyệt từng hệ số của đa thức q
        for i in range(len(p)):     # Duyệt từng hệ số của đa thức p

            # 3. Nhân hai hệ số trong GF(2^10)
            product = gf_mul(p[i], q[j])    # Dùng hàm gf_mul đã viết trước đó

            # 4. Cộng dồn vào vị trí i + j của đa thức kết quả
            shift[i + j] ^= product   # Trong GF, phép cộng là phép XOR (^=)

    return shift

def generate_generator_poly(nsym):
    """Tạo đa thức g(x) = (x+a^0)(x+a^1)...(x+a^{nsym-1})"""

    # 1. Khởi tạo đa thức g ban đầu là 1 (tương đương g(x) = 1)
    g = [1]

    # 2. Vòng lặp nhân thêm từng thừa số (x + alpha^i)
    for i in range(nsym):

        # Tạo đa thức bậc nhất: factor = 1*x^1 + alpha^i*x^0
        # Trong danh sách: [hệ số x^0, hệ số x^1] -> [power_table[i], 1]
        factor = [power_table[i], 1]

        # 3. Nhân đa thức hiện tại g với thừa số mới
        # Sử dụng hàm gf_poly_mul đã viết
        g = gf_poly_mul(g, factor)

    return g

def rs_encode(msg, nsym):
    """Mã hóa Reed-Solomon sử dụng kiến trúc LFSR"""

    # 1. Lấy đa thức tạo mã g(x) đã tính ở bước trước
    gen = generate_generator_poly(nsym)

    # 2. Khởi tạo 30 ngăn nhớ (registers) của LFSR bằng 0
    shift = [0] * nsym    # Đây là nơi chứa phần dư (parity) đang tính toán dở dang
    
    # 3. Duyệt qua từng symbol của tin nhắn (514 vòng lặp)
    for i in range(len(msg)):

        # Tính toán giá trị phản hồi (Feedback)
        feedback = msg[i] ^ shift[nsym-1]  # Là XOR của symbol hiện tại với ngăn nhớ bậc cao nhất

        # Lưu giá trị cũ để giả lập tính song song (non-blocking assignment)
        prev_shift = list(shift)
        
        # Cập nhật các ngăn nhớ
        if feedback != 0:

            # Dịch chuyển và tính toán cho 29 ngăn đầu: từ shift[29] xuống shift[1]
            for j in range(nsym-1, 0, -1): shift[j] = prev_shift[j-1] ^ gf_mul(gen[j], feedback) # Ngăn j-1 nhận giá trị ngăn j XOR với (feedback * hệ số g)

            # Ngăn cuối cùng nhận giá trị (feedback * hệ số g cuối)
            shift[0] = gf_mul(gen[0], feedback)

        else:
            # Nếu feedback bằng 0, chỉ đơn giản là dịch chuyển các ngăn
            for j in range(nsym-1, 0, -1): shift[j] = prev_shift[j-1]
            shift[0] = 0

    # 4. Kết quả là Tin nhắn gốc + 30 ngăn nhớ (Parity)
    # Xuất parity từ shift[29] xuống shift[0]
    parity = shift[::-1]
    return msg + parity