import galois
import numpy as np

def main():
    print("--- GENERATING TEST VECTORS FOR SYNDROME CALCULATOR ---")

    # 1. Cấu hình GF(2^10) và RS Code
    gf = galois.GF(2**10, irreducible_poly=1033)
    # Full code length N=1023, K=993 (Shortened to 544, 514)
    rs = galois.ReedSolomon(n=1023, k=993, c=0, field=gf)

    # 2. Tạo tin nhắn và mã hóa
    msg_len = 514
    msg_int = [i % 1024 for i in range(msg_len)]
    msg = gf(msg_int)
    
    # Encode (Shortened)
    full_codeword = rs.encode(msg)
    # Lấy 544 symbol cuối cùng (Data + Parity)
    tx_codeword = full_codeword[-544:]

    # 3. GÂY LỖI (Error Injection)
    # Nếu không có lỗi, Syndrome sẽ toàn 0 -> Test không hiệu quả
    rx_codeword = tx_codeword.copy()
    
    # Gây lỗi tại vị trí đầu tiên (Symbol 543) và vị trí thứ 10
    rx_codeword[0] += 123  # Lỗi ngẫu nhiên
    rx_codeword[10] += 456
    
    print(f"Injecting errors at index 0 (val={rx_codeword[0]}) and 10 (val={rx_codeword[10]})")

    # 4. Tính Syndrome (Golden Model)
    # Chuyển rx_codeword thành đa thức để tính giá trị tại alpha^i
    # Lưu ý: galois Poly mặc định hệ số cao đứng trước (đúng với thứ tự truyền của ta)
    r_poly = galois.Poly(rx_codeword, field=gf)
    
    syndromes = []
    # Tính S0 ... S29
    for i in range(30):
        # S[i] = R(alpha^i)
        val = r_poly(gf.primitive_element**i)
        syndromes.append(val)
        
    syndromes = gf(syndromes)
    
    print("\nExpected Syndromes (First 5):")
    print([hex(int(x)) for x in syndromes[:5]])

    # 5. Xuất file Hex
    # rx_input.hex: Dữ liệu đầu vào cho RTL (chứa lỗi)
    save_hex(rx_codeword, "../10_sim/fec/rs_dec/rs_dec_syn/rs_dec_syn_input.hex")
    
    # syndrome_expected.hex: Kết quả kỳ vọng (30 dòng)
    save_hex(syndromes, "../10_sim/fec/rs_dec/rs_dec_syn/rs_dec_output_exp.hex")
    
    print("\n-> Generated 'rs_dec_syn_input.hex' and 'rs_dec_output_exp.hex'")

def save_hex(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            f.write(f"{int(val):03x}\n")

if __name__ == "__main__":
    main()