import pandas as pd

# Cấu hình thông số GF(2^10)
PRIM_POLY = 1033
FIELD_SIZE = 1024

def generate_tables():
    # 1. Tạo bảng Antilog và Log
    antilog = [0] * FIELD_SIZE
    log = [0] * FIELD_SIZE
    curr = 1
    
    for i in range(FIELD_SIZE - 1):
        antilog[i] = curr
        log[curr] = i
        # Nhân với alpha (dịch trái 1 bit)
        curr <<= 1
        if curr & 1024: # Nếu vượt quá 10 bit
            curr ^= PRIM_POLY
            
    # 2. Hàm nhân trong GF(1024) dùng bảng Log/Antilog
    def gf_mul(x, y):
        if x == 0 or y == 0: return 0
        res_log = (log[x] + log[y]) % 1023
        return antilog[res_log]

    # 3. Tạo đa thức g(x) bậc 30: g(x) = (x + a^0)(x + a^1)...(x + a^29)
    # Hệ số lưu từ bậc cao đến bậc thấp: [coeff_x30, coeff_x29, ..., coeff_x0]
    g = [1]
    for i in range(30):
        new_g = [0] * (len(g) + 1)
        alpha_i = antilog[i]
        for j in range(len(g)):
            # Nhân đa thức: g(x) * (x + alpha^i)
            # x * g(x)
            new_g[j] ^= g[j]
            # alpha^i * g(x)
            new_g[j+1] ^= gf_mul(g[j], alpha_i)
        g = new_g

    # 4. Chuẩn bị dữ liệu cho Excel
    # Sheet 1: Log Table
    log_data = {
        'x (Decimal)': list(range(FIELD_SIZE)),
        'log(x)': [log[i] if i != 0 else 'UNDEFINED' for i in range(FIELD_SIZE)]
    }
    
    # Sheet 2: Antilog Table
    antilog_data = {
        'i (Exponent)': list(range(FIELD_SIZE - 1)),
        'alpha^i (Value)': [antilog[i] for i in range(FIELD_SIZE - 1)]
    }
    
    # Sheet 3: Generator Polynomial g(x)
    g_data = {
        'x^k': [f'x^{30-i}' for i in range(31)],
        'Hệ số (Decimal)': g,
        'Hệ số (Binary)': [bin(val)[2:].zfill(10) for val in g]
    }

    # Xuất ra file Excel
    with pd.ExcelWriter('GF2_10_Table.xlsx') as writer:
        pd.DataFrame(log_data).to_excel(writer, sheet_name='Log_Table', index=False)
        pd.DataFrame(antilog_data).to_excel(writer, sheet_name='Antilog_Table', index=False)
        pd.DataFrame(g_data).to_excel(writer, sheet_name='Generator_Polynomial', index=False)

    print("Đã tạo file 'GF2_10_Table.xlsx' thành công!")

if __name__ == "__main__":
    generate_tables()