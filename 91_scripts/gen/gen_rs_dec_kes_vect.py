import galois
import numpy as np
import os

def ibm_algorithm(syndromes, gf, T=15):
    """
    Mô phỏng thuật toán Inversionless Berlekamp-Massey (iBM) dùng thư viện galois.
    Logic này phải khớp bit-accurate với RTL rs_dec_kes.sv.
    """
    # 1. Khởi tạo (tất cả là phần tử trong trường GF)
    # Lambda(x), B(x)
    lam = gf([0] * (T + 1)); lam[0] = 1
    b   = gf([0] * (T + 1)); b[0]   = 1
    
    # Omega(x), A(x) (Evaluator poly)
    omg = gf([0] * (T + 1)); omg[0] = 1 # Lưu ý: RTL init Omega[0]=1
    a   = gf([0] * (T + 1)); a[0]   = 0
    
    k_step = 0
    L = 0
    gamma = gf(1) # Phần tử tỉ lệ
    
    # Loop 2T = 30 lần (k từ 0 đến 29)
    for k in range(2 * T):
        # --- 1. Tính Delta (Discrepancy) ---
        # Delta = Sum(Lambda[i] * S[k-i])
        delta = gf(0)
        for i in range(T + 1):
            if (k - i) >= 0 and (k - i) < len(syndromes):
                # Toán tử * và + trong galois tự động xử lý GF arithmetic
                delta += lam[i] * syndromes[k - i]
                
        # --- 2. Cập nhật Lambda và Omega ---
        # Lam_new = gamma * Lam - delta * x * B
        # Omg_new = gamma * Omg - delta * x * A
        # (Lưu ý: Trong GF(2^m), trừ (-) cũng là cộng (+))
        
        lam_next = gf([0] * (T + 1))
        omg_next = gf([0] * (T + 1))
        
        for i in range(T + 1):
            # Term 1: gamma * lam[i]
            t1_lam = gamma * lam[i]
            t1_omg = gamma * omg[i]
            
            # Term 2: delta * b[i-1] (Logic dịch x*B)
            b_shift = b[i-1] if i > 0 else gf(0)
            a_shift = a[i-1] if i > 0 else gf(0)
            
            t2_lam = delta * b_shift
            t2_omg = delta * a_shift
            
            lam_next[i] = t1_lam + t2_lam
            omg_next[i] = t1_omg + t2_omg
            
        # --- 3. Cập nhật B, A, L, Gamma ---
        # Điều kiện: delta != 0 và 2*L <= k
        if delta != 0 and (2 * L <= k):
            # Update B, A = old Lambda, Omega
            b = lam.copy()
            a = omg.copy()
            # Update L, Gamma
            L = k + 1 - L
            gamma = delta
        else:
            # B, A dịch trái (x * B)
            # b_new[i] = b[i-1]
            b_new = gf([0] * (T + 1))
            a_new = gf([0] * (T + 1))
            b_new[1:] = b[:-1]
            a_new[1:] = a[:-1]
            b = b_new
            a = a_new
            
        # Apply next values
        lam = lam_next
        omg = omg_next
        k_step += 1

    return lam, omg

def save_hex(data, filename):
    # Đảm bảo thư mục tồn tại
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'w') as f:
        for val in data:
            f.write(f"{int(val):03x}\n")

def main():
    print("--- GENERATING KES TEST VECTORS (Using Galois Lib) ---")
    
    # 1. Cấu hình GF(2^10) và RS Code
    gf = galois.GF(2**10, irreducible_poly=1033)
    rs = galois.ReedSolomon(n=1023, k=993, c=0, field=gf)
    
    # 2. Tạo Message và Mã hóa (Golden Model)
    msg_len = 514
    msg_int = [i % 1024 for i in range(msg_len)]
    msg = gf(msg_int)
    
    # Encode (Shortened)
    full_codeword = rs.encode(msg)
    tx_codeword = full_codeword[-544:] # Lấy 544 symbol cuối
    
    # 3. Gây lỗi (Error Injection) - Giống logic với script syn
    rx_codeword = tx_codeword.copy()
    
    # Lỗi tại index 0 (symbol 543) và index 10 (symbol 533)
    print("Injecting errors at index 0 and 10...")
    rx_codeword[0] += gf(123)
    rx_codeword[10] += gf(456)
    
    # 4. Tính Syndromes (Input cho KES)
    # S[i] = R(alpha^i)
    r_poly = galois.Poly(rx_codeword, field=gf)
    syndromes = []
    for i in range(30):
        val = r_poly(gf.primitive_element**i)
        syndromes.append(val)
    syndromes = gf(syndromes)
    
    print("\nCalculated Syndromes (First 5):")
    print([hex(int(x)) for x in syndromes[:5]])
    
    # 5. Chạy iBM Model (Golden Model cho KES RTL)
    print("\nRunning iBM Algorithm (Python Model)...")
    lam, omg = ibm_algorithm(syndromes, gf)
    
    print("Calculated Lambda (Hex):")
    print([hex(int(x)) for x in lam])
    print("Calculated Omega (Hex):")
    print([hex(int(x)) for x in omg])
    
    # 6. Xuất file Hex
    input_file = "../10_sim/fec/rs_dec/rs_dec_kes/rs_dec_kes_input.hex"
    output_file = "../10_sim/fec/rs_dec/rs_dec_kes/rs_dec_kes_output_exp.hex"
    
    # Input: 30 Syndromes
    save_hex(syndromes, input_file)
    
    # Output: 16 Lambda + 16 Omega
    # Gộp vào 1 file để TB đọc: 16 dòng đầu là Lambda, 16 dòng sau là Omega
    combined_out = np.concatenate((lam, omg))
    save_hex(combined_out, output_file)
        
    print(f"\n-> Generated '{input_file}'")
    print(f"-> Generated '{output_file}'")

if __name__ == "__main__":
    main()