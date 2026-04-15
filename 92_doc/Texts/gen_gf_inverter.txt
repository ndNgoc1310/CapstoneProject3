import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../model')))
import gf210_lib as gf

def generate_inverter_rom():
    gf.generate_tables()
    
    filename = "../00_rtl/fec/common/gf_inv_rom.sv"
    print(f"Generating {filename}...")
    
    with open(filename, "w") as f:
        f.write("// Auto-generated GF(2^10) Inversion ROM\n")
        f.write("module gf_inv_rom (\n")
        f.write("    input  logic [9:0] addr,\n")
        f.write("    output logic [9:0] data\n")
        f.write(");\n")
        f.write("    always_comb begin\n")
        f.write("        case (addr)\n")
        f.write("            10'd0: data = 10'd0; // 0 has no inverse\n")
        
        # Duyệt từ 1 đến 1023
        for i in range(1, 1024):
            # Nghịch đảo: inv(x) = antilog(1023 - log(x))
            # Vì log(x) + log(inv) = 1023 (mod 1023) = 0 => alpha^0 = 1
            idx_log = gf.log_table[i]
            inv_log = (1023 - idx_log) % 1023
            val_inv = gf.power_table[inv_log]
            
            f.write(f"            10'd{i}: data = 10'd{val_inv};\n")
            
        f.write("            default: data = 10'd0;\n")
        f.write("        endcase\n")
        f.write("    end\n")
        f.write("endmodule\n")

if __name__ == "__main__":
    generate_inverter_rom()