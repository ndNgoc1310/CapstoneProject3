# gf210_lib.py

# GF(2^10) Arithmetic Script for RS-FEC
# Primitive Polynomial: p(x) = x^10 + x^3 + 1 (1033 decimal)

PRIM_POLY = 1033    # Primitive Polynomial: p(x) = x^10 + x^3 + 1 (1033 decimal/1000001001 binary)
FIELD_SIZE = 1024

# Khởi tạo bảng tra cứu
power_table = [0] * (FIELD_SIZE * 2) # Nhân đôi kích thước để tránh modulo 1023 khi nhân
log_table = [0] * FIELD_SIZE

def generate_tables():
    """Tạo bảng Power (Antilog) và Logarithm cho GF(2^10)"""
    x = 1
    for i in range(1023):
        power_table[i] = x
        log_table[x] = i
        x <<= 1
        # Nếu vượt quá 10 bit (bit thứ 10 set), thực hiện XOR với đa thức bất khả quy
        if x & 1024:
            x ^= PRIM_POLY
    
    # Điền nửa sau của power_table để tối ưu phép nhân (xử lý tràn số mũ)
    for i in range(1023, 2046):
        power_table[i] = power_table[i - 1023]

def gf_add(a, b):
    """Phép cộng trong GF(2^10) - Thực chất là phép XOR"""
    return a ^ b

def gf_mul(a, b):
    """Phép nhân trong GF(2^10) sử dụng bảng Log/Antilog"""
    if a == 0 or b == 0:
        return 0
    # Công thức: Antilog[(Log[A] + Log[B])]
    # Sử dụng power_table kích thước 2046 để không cần tính (Log[A] + Log[B]) % 1023
    return power_table[log_table[a] + log_table[b]]
