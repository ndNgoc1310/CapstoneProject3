import os
import sys

try:
    import numpy as np
    import galois
except ImportError:
    print("Error: numpy and galois libraries are required. Install with 'pip install numpy galois'")
    sys.exit(1)

def generate_top_test_vectors():
    # 1. Khởi tạo Toán học (Math Setup)
    # GF(2^10) với đa thức nguyên thủy p(x) = x^10 + x^3 + 1 (Dec: 1033)
    GF = galois.GF(2**10, irreducible_poly=1033)
    
    # Cấu hình mã RS(544, 514) rút gọn từ RS(1023, 993)
    N_SHORT, K_SHORT = 544, 514
    N_FULL, K_FULL = 1023, 993
    PAD_LEN = N_FULL - N_SHORT
    
    # Bắt buộc c=0 để phần cứng sinh hằng số từ alpha^0
    rs = galois.ReedSolomon(N_FULL, K_FULL, c=0, field=GF)

    # Khởi tạo Message (Mảng tĩnh tăng dần 0 -> 513)
    msg = GF(np.arange(K_SHORT))
    
    # Encode (Đệm 479 symbol 0, encode, rồi cắt 479 số 0 ở đầu)
    msg_padded = np.concatenate((GF.Zeros(PAD_LEN), msg))
    cw_full = rs.encode(msg_padded)
    cw_clean = GF(cw_full[PAD_LEN:])

    # Cấu hình 8 Corner Cases (Modes)
    target_errs = [0, 15, 5, 15, 16, 100, 514, 544]
    
    # Khởi tạo LFSR 16-bit Seed đúng 1 lần duy nhất
    lfsr = 0xACE1

    top_in_lines = []
    top_out_exp_lines = []

    # Hàm định dạng Hex 10-bit (3 ký tự in HOA)
    def format_hex(arr):
        return " ".join([f"{int(x):03X}" for x in arr])

    for mode in range(8):
        target_err = target_errs[mode]
        current_inj_cnt = 0
        cw_corrupted = np.copy(cw_clean)

        # 3B. Thuật toán LFSR và Chèn lỗi
        for current_sym in range(N_SHORT):

            # B1. Xác định điều kiện chèn
            random_inject = False
            if mode == 0: random_inject = False
            elif mode == 1: random_inject = (lfsr & 0xFF) == 0
            elif mode == 2: random_inject = (lfsr & 0x7F) == 0
            elif mode == 3: random_inject = (lfsr & 0x3F) == 0
            elif mode == 4: random_inject = (lfsr & 0x3F) == 0
            elif mode == 5: random_inject = (lfsr & 0x07) == 0
            elif mode == 6: random_inject = True
            elif mode == 7: random_inject = True

            force_inject = (N_SHORT - current_sym) <= (target_err - current_inj_cnt)
            burst_active = (mode == 1) and (0 < current_inj_cnt < target_err)
            inject_en = (current_inj_cnt < target_err) and (random_inject or force_inject or burst_active)

            # B2. Tạo độ lớn lỗi (Noise)
            val = lfsr & 0x3FF
            noise = 1 if val == 0 else val

            # B3. Chèn lỗi
            if inject_en:
                cw_corrupted[current_sym] = cw_clean[current_sym] ^ GF(noise)
                current_inj_cnt += 1

            # B4. Tính Feedback LFSR (Các bit 1, 2, 3, 4)
            lfsr_fb = ((lfsr >> 1) & 1) ^ ((lfsr >> 2) & 1) ^ ((lfsr >> 3) & 1) ^ ((lfsr >> 4) & 1)
            
            # B5. Dịch LFSR
            lfsr = ((lfsr & 0x7FFF) << 1) | lfsr_fb

        # 3C. Giải mã và Thống kê
        cw_corrupted_padded = np.concatenate((GF.Zeros(PAD_LEN), cw_corrupted))
        err_flg = np.zeros(N_SHORT, dtype=int)
        err_mag = GF.Zeros(N_SHORT)
        
        try:
            # FIX: Yêu cầu trả về số lỗi (errors=True)
            dec_msg, num_errs = rs.decode(cw_corrupted_padded, errors=True)
            
            # Nếu num_errs == -1 nghĩa là Uncorrectable, chủ động ném Exception
            if num_errs == -1:
                raise ValueError("Uncorrectable Error Detected")
                
            # Nếu Correctable
            dec_error = 0
            dec_data_out = cw_clean
            for i in range(N_SHORT):
                if cw_clean[i] != cw_corrupted[i]:
                    err_flg[i] = 1
                    err_mag[i] = cw_clean[i] ^ cw_corrupted[i]
        except BaseException:
            # Bắt Exception nếu Uncorrectable
            dec_error = 1
            dec_data_out = cw_corrupted
            # err_flg và err_mag giữ nguyên là mảng 0

        # Lưu log đầu vào theo chuẩn
        top_in_lines.append(f"MODE {mode}")
        top_in_lines.append(f"ENC_IN {format_hex(msg)}")
        top_in_lines.append(f"DEC_IN {format_hex(cw_corrupted)}")

        # Lưu log đầu ra theo chuẩn
        top_out_exp_lines.append(f"DEC_ERROR {dec_error}")
        top_out_exp_lines.append(f"DEC_OUT {format_hex(dec_data_out)}")
        err_flg_str = "".join([str(x) for x in err_flg])
        top_out_exp_lines.append(f"ERR_FLG {err_flg_str}")
        top_out_exp_lines.append(f"ERR_MAG {format_hex(err_mag)}")

    # 4 & 5. Định dạng File và Relative Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "top", "top"))
    os.makedirs(target_dir, exist_ok=True)

    in_file_path = os.path.join(target_dir, "top_in.hex")
    out_file_path = os.path.join(target_dir, "top_out_exp.hex")

    with open(in_file_path, "w") as f:
        f.write("\n".join(top_in_lines) + "\n")

    with open(out_file_path, "w") as f:
        f.write("\n".join(top_out_exp_lines) + "\n")

    print(f"Hoàn thành sinh Test Vectors!")
    print(f"File Input: {in_file_path}")
    print(f"File Expected Output: {out_file_path}")

if __name__ == "__main__":
    generate_top_test_vectors()
