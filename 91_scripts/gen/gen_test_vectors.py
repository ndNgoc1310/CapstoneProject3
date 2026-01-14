# gen_test_vectors.py

import model.rs_codec as rs
import model.gf210_lib as gf

def save_hex(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            # Lưu dưới dạng hex 3 chữ số (vì 10-bit tối đa 1023)
            f.write(f"{val:03x}\n")

def main():
    gf.generate_tables()
    
    # 1. Tạo tin nhắn mẫu (ví dụ: 0, 1, 2, ..., 513)
    msg = [i % 1024 for i in range(514)]
    
    # 2. Mã hóa bằng mô hình Python (Golden Model)
    # rs_encode sẽ trả về msg + 30 parity symbols
    codeword = rs.rs_encode(msg, 30)
    
    # 3. Lưu vào file
    save_hex(msg, "../10_sim/fec/input.hex")
    save_hex(codeword, "../10_sim/fec/expected.hex")
    print("Đã tạo xong input.hex và expected.hex")

if __name__ == "__main__":
    main()