import os
import sys
import random

try:
    import numpy as np
    import galois
except ImportError:
    print("Lỗi: Thiếu thư viện. Vui lòng chạy lệnh: pip install numpy galois")
    sys.exit(1)

def generate_kes_test_vectors():
    # ---------------------------------------------------------
    # 1. KHỞI TẠO TOÁN HỌC & CẤU HÌNH (MATHEMATICAL SETUP)
    # ---------------------------------------------------------
    # GF(2^10) với p(x) = x^10 + x^3 + 1 (Dec: 1033)
    gf = galois.GF(2**10, irreducible_poly=1033)
    alpha = gf.primitive_element  # Tương đương giá trị 2
    
    t = 15      # Khả năng sửa lỗi tối đa
    synd_len = 30  # Số byte Parity (2t = 30)
    msg_len = 544  # Chiều dài mã RS(544, 514)
    total_cases = 100 # Tổng số test cases cần tạo (bao gồm cả corner cases và random cases)

    # ---------------------------------------------------------
    # 2. KHỞI TẠO DANH SÁCH LỖI CORNER CASES (DIRECTED TESTGEN)
    # ---------------------------------------------------------
    test_cases_errors = [] # Tạo một danh sách rỗng để lưu trữ các trường hợp lỗi (dạng list of lists) - mỗi phần tử là một danh sách lỗi cho một test case gồm các tuple (position, magnitude) - position là vị trí lỗi, magnitude là độ lớn lỗi (1..1023) trong GF(2^10)
    
    # Case 1: Zero Errors (0 lỗi)
    test_cases_errors.append([]) # Thêm vào danh sách một trường hợp không có lỗi nào (mảng rỗng) để kiểm tra tình huống lý tưởng nhất khi không có lỗi nào xảy ra. 
    
    # Case 2: Single Error (1 lỗi bất kỳ)
    test_cases_errors.append([(random.randint(0, msg_len-1), random.randint(1, 1023))]) # Thêm vào danh sách một trường hợp có một lỗi duy nhất với vị trí và độ lớn lỗi được chọn ngẫu nhiên. Vị trí lỗi được chọn trong khoảng từ 0 đến 543 (msg_len-1) và độ lớn lỗi được chọn trong khoảng từ 1 đến 1023 (tương đương với tất cả các giá trị khác 0 trong GF(2^10)). 
    
    # Case 3: Max Correctable Errors (15 lỗi ngẫu nhiên)
    pos_c3 = random.sample(range(msg_len), 15) # Lưu vào pos_c3 một danh sách gồm 15 vị trí lỗi ngẫu nhiên được chọn từ khoảng 0 đến 543 (msg_len-1) mà không có sự trùng lặp nào. Hàm random.sample đảm bảo rằng các vị trí lỗi này là duy nhất và không bị lặp lại.
    test_cases_errors.append([(p, random.randint(1, 1023)) for p in pos_c3]) # Thêm vào danh sách một trường hợp có 15 lỗi với vị trí lỗi được lấy từ pos_c3 và độ lớn lỗi được chọn ngẫu nhiên trong khoảng từ 1 đến 1023. 
    
    # Case 4: Burst Errors (15 lỗi liên tiếp)
    start_pos = random.randint(0, msg_len - 15) # Lưu vào start_pos một vị trí bắt đầu ngẫu nhiên được chọn từ khoảng 0 đến 528 (msg_len-15) để đảm bảo rằng chuỗi lỗi liên tiếp 15 lỗi sẽ không vượt quá độ dài của mã RS. 
    test_cases_errors.append([(p, random.randint(1, 1023)) for p in range(start_pos, start_pos + 15)]) # Thêm vào danh sách một trường hợp có 15 lỗi liên tiếp bắt đầu từ start_pos đến start_pos + 14, với độ lớn lỗi được chọn ngẫu nhiên trong khoảng từ 1 đến 1023. 
    
    # Case 5: Boundary Errors (Lỗi ở các biên 0, 1, 542, 543)
    pos_c5 = [0, 1, msg_len-2, msg_len-1] # Lưu vào pos_c5 một danh sách gồm 4 vị trí lỗi đặc biệt là các vị trí biên của mã RS, bao gồm vị trí 0, 1, 542 và 543.
    test_cases_errors.append([(p, random.randint(1, 1023)) for p in pos_c5]) # Thêm vào danh sách một trường hợp có lỗi ở các vị trí biên được lấy từ pos_c5, với độ lớn lỗi được chọn ngẫu nhiên trong khoảng từ 1 đến 1023. 
    
    # Case 6: Uncorrectable Errors (16 lỗi - vượt khả năng sửa)
    pos_c6 = random.sample(range(msg_len), 16) # Lưu vào pos_c6 một danh sách gồm 16 vị trí lỗi ngẫu nhiên được chọn từ khoảng 0 đến 543 (msg_len-1) mà không có sự trùng lặp nào. 
    test_cases_errors.append([(p, random.randint(1, 1023)) for p in pos_c6]) # Thêm vào danh sách một trường hợp có 16 lỗi với vị trí lỗi được lấy từ pos_c6 và độ lớn lỗi được chọn ngẫu nhiên trong khoảng từ 1 đến 1023. 
    
    # Case 7 -> 100: Random General Cases (2 đến 14 lỗi)
    for _ in range(total_cases - 6): # Vòng lặp từ 0 đến 93 để tạo thêm 93 trường hợp lỗi ngẫu nhiên.
        num_errs = random.randint(2, 14) # Lưu vào num_errs một số nguyên ngẫu nhiên được chọn từ khoảng 2 đến 14, đại diện cho số lượng lỗi trong trường hợp này.
        pos = random.sample(range(msg_len), num_errs) # Lưu vào pos một danh sách gồm num_errs vị trí lỗi ngẫu nhiên được chọn từ khoảng 0 đến 543 (msg_len-1) mà không có sự trùng lặp nào.
        test_cases_errors.append([(p, random.randint(1, 1023)) for p in pos]) # Thêm vào danh sách một trường hợp có num_errs lỗi với vị trí lỗi được lấy từ pos và độ lớn lỗi được chọn ngẫu nhiên trong khoảng từ 1 đến 1023.

    # ---------------------------------------------------------
    # 3. MÔ PHỎNG PHẦN CỨNG BẰNG PYTHON (RTL-MATCHING BEHAVIOR)
    # ---------------------------------------------------------
    inputs_hex = [] # Tạo một danh sách rỗng để lưu trữ các vector đầu vào đã được định dạng dưới dạng chuỗi Hex. Mỗi phần tử trong danh sách này sẽ là một chuỗi đại diện cho các giá trị syndrome S_29 đến S_0, được định dạng theo yêu cầu của module KES (mỗi số 3 ký tự Hex, cách nhau bằng dấu cách). Danh sách này sẽ được ghi vào file rs_dec_kes_in.hex để làm input cho testbench SystemVerilog.
    outputs_hex = [] # Tạo một danh sách rỗng để lưu trữ các vector đầu ra mong đợi đã được định dạng dưới dạng chuỗi Hex. Mỗi phần tử trong danh sách này sẽ là một chuỗi đại diện cho các giá trị Lambda_15 đến Lambda_0 và Omega_15 đến Omega_0, được định dạng theo yêu cầu của module KES (mỗi số 3 ký tự Hex, cách nhau bằng dấu cách). Danh sách này sẽ được ghi vào file rs_dec_kes_out_exp.hex để làm expected output cho testbench SystemVerilog.

    for case_idx, err_list in enumerate(test_cases_errors): # Vòng lặp qua từng trường hợp lỗi trong danh sách test_cases_errors, với case_idx là chỉ số của trường hợp hiện tại (từ 0 đến 99) và err_list là danh sách các lỗi (dạng list of tuples) cho trường hợp đó. Mỗi tuple trong err_list chứa vị trí lỗi và độ lớn lỗi tương ứng.
        # --- BƯỚC 3A: TÍNH SYNDROME ---
        S = gf.Zeros(synd_len) # Khởi tạo mảng syndrome S với 30 phần tử, tất cả đều được đặt giá trị ban đầu là 0 trong trường hữu hạn GF(2^10). Mảng này sẽ được cập nhật dựa trên các lỗi đã định nghĩa trong err_list để tính toán các giá trị syndrome S_29 đến S_0.
        for p, mag in err_list: # Vòng lặp qua từng lỗi trong err_list, với p là vị trí lỗi (từ 0 đến 543) và mag là độ lớn lỗi (từ 1 đến 1023). Đối với mỗi lỗi, ta sẽ tính toán ảnh hưởng của lỗi đó lên các giá trị syndrome S_k dựa trên công thức S_k = Σ (Y_j * X_j^k) cho k từ 0 đến 29, trong đó Y_j là độ lớn lỗi và X_j là nghiệm vị trí lỗi.
            X_j = alpha ** p  # Tính X_j là nghiệm vị trí lỗi bằng cách lấy phần tử cơ bản alpha mũ p, tương đương với 2^p trong GF(2^10). 
            Y_j = gf(mag)     # Tính Y_j là độ lớn lỗi dưới dạng phần tử của trường GF(2^10) bằng cách chuyển đổi mag (một số nguyên từ 1 đến 1023) thành phần tử tương ứng trong trường.
            for k in range(synd_len):
                S[k] += Y_j * (X_j ** k)
                
        # Format Input: S_29 giảm dần đến S_0, mỗi số 3 ký tự Hex
        # S[::-1] sẽ lật ngược mảng từ 0..29 thành 29..0
        in_str = " ".join([f"{int(s):03X}" for s in S[::-1]]) # Tạo một chuỗi in_str bằng cách nối các giá trị syndrome S_k đã được định dạng thành chuỗi Hex 3 ký tự (bằng cách sử dụng f-string với định dạng :03X) và cách nhau bằng dấu cách. Mảng S được lật ngược để đảm bảo thứ tự từ S_29 đến S_0. Chuỗi này sẽ đại diện cho vector đầu vào cho module KES trong testbench SystemVerilog.
        inputs_hex.append(in_str) # Thêm chuỗi in_str vào danh sách inputs_hex để lưu trữ vector đầu vào đã được định dạng cho trường hợp lỗi hiện tại. Sau khi vòng lặp hoàn thành, inputs_hex sẽ chứa 100 chuỗi đại diện cho các vector syndrome tương ứng với 100 trường hợp lỗi khác nhau.

        # --- BƯỚC 3B: THUẬT TOÁN iBM (INVERSIONLESS BERLEKAMP-MASSEY) ---
        # Khởi tạo các mảng phần cứng 16 phần tử
        Lam = gf.Zeros(16); Lam[0] = 1 # Mảng Lambda với 16 phần tử, được khởi tạo tất cả bằng 0 và chỉ có phần tử đầu tiên (index 0) được đặt thành 1. Đây là trạng thái ban đầu của mảng Lambda trong thuật toán iBM.
        Ome = gf.Zeros(16); Ome[0] = 1 # Mảng Omega với 16 phần tử, được khởi tạo tất cả bằng 0 và chỉ có phần tử đầu tiên (index 0) được đặt thành 1. Đây là trạng thái ban đầu của mảng Omega trong thuật toán iBM.
        Lam_aux = gf.Zeros(16); Lam_aux[1] = 1 # Mảng phụ Lambda_aux với 16 phần tử, được khởi tạo tất cả bằng 0 và chỉ có phần tử thứ hai (index 1) được đặt thành 1. Đây là trạng thái ban đầu của mảng phụ Lambda_aux trong thuật toán iBM, được sử dụng để lưu trữ giá trị Lambda trước đó khi cần thiết.
        Ome_aux = gf.Zeros(16) # Mảng phụ Omega_aux với 16 phần tử, được khởi tạo tất cả bằng 0. Đây là trạng thái ban đầu của mảng phụ Omega_aux trong thuật toán iBM, được sử dụng để lưu trữ giá trị Omega trước đó khi cần thiết.
        
        gamma = gf(1) # Biến gamma được khởi tạo với giá trị 1 trong trường GF(2^10). Gamma là một biến quan trọng trong thuật toán iBM, được sử dụng để điều chỉnh các cập nhật của mảng Lambda và Omega dựa trên giá trị Discrepancy (Delta) tại mỗi bước. Ban đầu, gamma được đặt thành 1 để đảm bảo rằng các cập nhật đầu tiên sẽ không bị nhân với 0, cho phép thuật toán bắt đầu quá trình tính toán một cách chính xác.
        L = 0 # Biến L được khởi tạo với giá trị 0, đại diện cho độ dài hiện tại của đa thức lỗi Lambda. L sẽ được cập nhật trong quá trình thuật toán iBM để phản ánh số lượng lỗi đã được phát hiện và sửa chữa. Ban đầu, L được đặt thành 0 vì chưa có lỗi nào được phát hiện khi bắt đầu thuật toán.
        
        # Vòng lặp iBM mô phỏng chính xác FSM của RTL (30 vòng)
        for r in range(synd_len): # Vòng lặp từ 0 đến 29, đại diện cho từng bước của thuật toán iBM khi xử lý các giá trị syndrome S_k. Tại mỗi bước r, thuật toán sẽ tính toán Discrepancy (Delta) dựa trên các giá trị Lambda và syndrome hiện tại, sau đó cập nhật các mảng Lambda, Omega và các mảng phụ tương ứng dựa trên giá trị Delta và điều kiện liên quan đến độ dài L. Vòng lặp này mô phỏng chính xác hoạt động của FSM trong RTL để đảm bảo rằng kết quả đầu ra sẽ khớp với kỳ vọng.
            # Tính Discrepancy (Delta)
            Delta = gf(0) # Khởi tạo Delta với giá trị 0 trong trường GF(2^10) tại mỗi bước r. Delta sẽ được tính toán dựa trên các giá trị Lambda và syndrome S hiện tại để xác định mức độ không khớp giữa đa thức lỗi hiện tại và các giá trị syndrome, từ đó quyết định cách cập nhật các mảng Lambda và Omega.
            limit = min(15, r) # Giới hạn số phần tử Lambda được sử dụng để tính Delta, không vượt quá 15 hoặc r (tùy theo bước hiện tại). Điều này đảm bảo rằng thuật toán chỉ sử dụng các phần tử Lambda có sẵn và phù hợp với bước r hiện tại khi tính toán Discrepancy.
            for i in range(limit + 1):
                Delta += Lam[i] * S[r - i] # Tính Delta bằng cách cộng dồn tích của các phần tử Lambda và các giá trị syndrome tương ứng. Cụ thể, tại mỗi bước i từ 0 đến limit, ta nhân phần tử Lambda thứ i với giá trị syndrome S tại vị trí r - i và cộng dồn vào Delta. Kết quả cuối cùng của Delta sẽ phản ánh mức độ không khớp giữa đa thức lỗi hiện tại (được biểu diễn bởi Lambda) và các giá trị syndrome, từ đó ảnh hưởng đến cách cập nhật các mảng Lambda và Omega trong bước tiếp theo của thuật toán iBM.
                
            delta_flag = (Delta != 0) and (2 * L <= r) # Tính delta_flag dựa trên giá trị Delta và độ dài L. delta_flag sẽ được đặt thành True nếu Delta khác 0 (tức là có sự không khớp) và đồng thời 2 * L nhỏ hơn hoặc bằng r (tức là độ dài hiện tại của đa thức lỗi Lambda không vượt quá nửa số bước đã thực hiện). Nếu delta_flag là True, điều này cho thấy rằng cần phải cập nhật các mảng Lambda và Omega một cách đáng kể, bao gồm cả việc dịch phải các thanh ghi phụ và cập nhật biến gamma. Nếu delta_flag là False, điều này cho thấy rằng chỉ cần cập nhật các mảng Lambda và Omega một cách nhẹ nhàng hơn mà không cần thay đổi độ dài L hoặc dịch các thanh ghi phụ.
            
            # Parallel update (dùng toán tử + vì cộng và trừ trong GF(2) là giống nhau (XOR))
            Lam_next = (gamma * Lam) + (Delta * Lam_aux) # Tính Lam_next bằng cách nhân mảng Lambda hiện tại với gamma và cộng (theo phép cộng trong GF(2^10)) với tích của Delta và mảng phụ Lambda_aux. Toán tử + ở đây đại diện cho phép cộng trong trường hữu hạn, tương đương với phép XOR. Kết quả Lam_next sẽ là mảng Lambda được cập nhật dựa trên giá trị Discrepancy (Delta) và điều kiện delta_flag.
            Ome_next = (gamma * Ome) + (Delta * Ome_aux) # Tính Ome_next bằng cách nhân mảng Omega hiện tại với gamma và cộng (theo phép cộng trong GF(2^10)) với tích của Delta và mảng phụ Omega_aux. Toán tử + ở đây đại diện cho phép cộng trong trường hữu hạn, tương đương với phép XOR. Kết quả Ome_next sẽ là mảng Omega được cập nhật dựa trên giá trị Discrepancy (Delta) và điều kiện delta_flag.
            
            if delta_flag:
                # Dịch phải các thanh ghi Lambda và nhét 0 vào MSB (Index 0)
                Lam_aux_next = np.insert(Lam[:-1], 0, gf(0)) # Nếu delta_flag là True, ta sẽ cập nhật mảng phụ Lambda_aux bằng cách dịch phải mảng Lambda hiện tại (bỏ phần tử cuối cùng) và chèn một giá trị 0 vào vị trí đầu tiên (MSB). Cụ thể, np.insert(Lam[:-1], 0, gf(0)) sẽ tạo ra một mảng mới bằng cách lấy tất cả phần tử của Lam trừ phần tử cuối cùng (Lam[:-1]) và chèn giá trị 0 (gf(0)) vào vị trí đầu tiên của mảng mới này. Điều này tương đương với việc dịch phải mảng Lambda và đặt phần tử mới ở MSB thành 0.
                Ome_aux_next = np.insert(Ome[:-1], 0, gf(0)) # Tương tự, nếu delta_flag là True, ta sẽ cập nhật mảng phụ Omega_aux bằng cách dịch phải mảng Omega hiện tại (bỏ phần tử cuối cùng) và chèn một giá trị 0 vào vị trí đầu tiên (MSB). Cụ thể, np.insert(Ome[:-1], 0, gf(0)) sẽ tạo ra một mảng mới bằng cách lấy tất cả phần tử của Ome trừ phần tử cuối cùng (Ome[:-1]) và chèn giá trị 0 (gf(0)) vào vị trí đầu tiên của mảng mới này. Điều này tương đương với việc dịch phải mảng Omega và đặt phần tử mới ở MSB thành 0.
                gamma_next = Delta # Nếu delta_flag là True, ta sẽ cập nhật biến gamma_next bằng cách gán giá trị của Delta cho gamma_next. Điều này có nghĩa là gamma sẽ được điều chỉnh dựa trên giá trị Discrepancy (Delta) tại bước hiện tại, ảnh hưởng đến cách cập nhật các mảng Lambda và Omega trong các bước tiếp theo của thuật toán iBM.
                L = r + 1 - L # Nếu delta_flag là True, ta sẽ cập nhật độ dài L bằng công thức L = r + 1 - L. Công thức này được sử dụng trong thuật toán iBM để điều chỉnh độ dài của đa thức lỗi Lambda dựa trên bước hiện tại r và độ dài L trước đó. Khi có sự không khớp (Delta khác 0) và điều kiện về độ
            else:
                Lam_aux_next = np.insert(Lam_aux[:-1], 0, gf(0)) # Nếu delta_flag là False, ta sẽ cập nhật mảng phụ Lambda_aux bằng cách dịch phải mảng Lambda_aux hiện tại (bỏ phần tử cuối cùng) và chèn một giá trị 0 vào vị trí đầu tiên (MSB). Cụ thể, np.insert(Lam_aux[:-1], 0, gf(0)) sẽ tạo ra một mảng mới bằng cách lấy tất cả phần tử của Lam_aux trừ phần tử cuối cùng (Lam_aux[:-1]) và chèn giá trị 0 (gf(0)) vào vị trí đầu tiên của mảng mới này. Điều này tương đương với việc dịch phải mảng Lambda_aux và đặt phần tử mới ở MSB thành 0.
                Ome_aux_next = np.insert(Ome_aux[:-1], 0, gf(0)) # Tương tự, nếu delta_flag là False, ta sẽ cập nhật mảng phụ Omega_aux bằng cách dịch phải mảng Omega_aux hiện tại (bỏ phần tử cuối cùng) và chèn một giá trị 0 vào vị trí đầu tiên (MSB). Cụ thể, np.insert(Ome_aux[:-1], 0, gf(0)) sẽ tạo ra một mảng mới bằng cách lấy tất cả phần tử của Ome_aux trừ phần tử cuối cùng (Ome_aux[:-1]) và chèn giá trị 0 (gf(0)) vào vị trí đầu tiên của mảng mới này. Điều này tương đương với việc dịch phải mảng Omega_aux và đặt phần tử mới ở MSB thành 0.
                gamma_next = gamma # Nếu delta_flag là False, ta sẽ giữ nguyên giá trị của gamma cho gamma_next. Điều này có nghĩa là nếu không có sự không khớp đáng kể nào được phát hiện (Delta bằng 0 hoặc điều kiện về độ dài
                # L không đổi
                
            # Cập nhật chốt FF (Flip-Flops)
            Lam = Lam_next
            Ome = Ome_next
            Lam_aux = Lam_aux_next
            Ome_aux = Ome_aux_next
            gamma = gamma_next
            
        # Format Output: Lam_15 giảm dần đến Lam_0, rồi Ome_15 giảm dần đến Ome_0
        out_lam_str = " ".join([f"{int(l):03X}" for l in Lam[::-1]]) # Tạo một chuỗi out_lam_str bằng cách nối các giá trị Lambda_i đã được định dạng thành chuỗi Hex 3 ký tự (bằng cách sử dụng f-string với định dạng :03X) và cách nhau bằng dấu cách. Mảng Lam được lật ngược để đảm bảo thứ tự từ Lam_15 đến Lam_0. Chuỗi này sẽ đại diện cho phần Lambda của vector đầu ra mong đợi cho module KES trong testbench SystemVerilog.
        out_ome_str = " ".join([f"{int(o):03X}" for o in Ome[::-1]]) # Tạo một chuỗi out_ome_str bằng cách nối các giá trị Omega_i đã được định dạng thành chuỗi Hex 3 ký tự (bằng cách sử dụng f-string với định dạng :03X) và cách nhau bằng dấu cách. Mảng Ome được lật ngược để đảm bảo thứ tự từ Ome_15 đến Ome_0. Chuỗi này sẽ đại diện cho phần Omega của vector đầu ra mong đợi cho module KES trong testbench SystemVerilog.
        out_str = out_lam_str + " " + out_ome_str # Kết hợp chuỗi out_lam_str và out_ome_str thành một chuỗi out_str duy nhất, với phần Lambda ở trước và phần Omega ở sau, cách nhau bằng một dấu cách. Chuỗi out_str sẽ đại diện cho vector đầu ra mong đợi hoàn chỉnh (bao gồm cả Lambda và Omega) cho module KES trong testbench SystemVerilog.
        outputs_hex.append(out_str) # Thêm chuỗi out_str vào danh sách outputs_hex để lưu trữ vector đầu ra mong đợi đã được định dạng cho trường hợp lỗi hiện tại. Sau khi vòng lặp hoàn thành, outputs_hex sẽ chứa 100 chuỗi đại diện cho các vector Lambda và Omega tương ứng với 100 trường hợp lỗi khác nhau.

    # ---------------------------------------------------------
    # 4. GHI FILE BẰNG ĐƯỜNG DẪN TƯƠNG ĐỐI (RELATIVE PATH EXPORT)
    # ---------------------------------------------------------
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.abspath(os.path.join(script_dir, "..", "..", "10_sim", "fec", "rs_dec", "rs_dec_kes"))
    os.makedirs(target_dir, exist_ok=True)
    
    in_file_path = os.path.join(target_dir, "rs_dec_kes_in.hex")
    out_file_path = os.path.join(target_dir, "rs_dec_kes_out_exp.hex")
    
    with open(in_file_path, "w") as f_in:
        f_in.write("\n".join(inputs_hex) + "\n")
        
    with open(out_file_path, "w") as f_out:
        f_out.write("\n".join(outputs_hex) + "\n")

    print(f"-> Thành công! Đã tạo 100 test cases Corner Cases cho module KES.")
    print(f"   + Input Vectors : {in_file_path}")
    print(f"   + Expected Out  : {out_file_path}")

if __name__ == "__main__":
    generate_kes_test_vectors()