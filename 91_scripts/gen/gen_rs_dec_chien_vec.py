import galois
import os

# CẤU HÌNH HỆ THỐNG
PARALLELISM = 16
T = 15
CODE_LEN = 544
FULL_LEN = 1023
START_POS = 543

def main():
    print(f"--- GENERATING CHIEN SEARCH RTL (WITH DEBUG PRINTS) ---")
    
    gf = galois.GF(2**10, irreducible_poly=1033)
    alpha = gf.primitive_element

    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.abspath(os.path.join(script_dir, "../../00_rtl/fec"))
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    filename = os.path.join(output_dir, "rs_dec_chien.sv")
    
    with open(filename, "w") as f:
        # HEADER
        f.write(f"// Auto-generated Parallel Chien Search (P={PARALLELISM}) - DEBUG VER\n")
        f.write("module rs_dec_chien (\n")
        f.write("    input  logic        clk,\n")
        f.write("    input  logic        rst_n,\n")
        f.write("    input  logic        start,\n")
        f.write(f"    input  logic [9:0]  lam_in [0:{T}],\n")
        f.write(f"    input  logic [9:0]  omg_in  [0:{T}],\n")
        f.write("    output logic        valid_out,\n")
        f.write("    output logic        done,\n")
        f.write(f"    output logic [9:0]  error_val [0:{PARALLELISM-1}],\n")
        f.write(f"    output logic [9:0]  error_pos [0:{PARALLELISM-1}]\n")
        f.write(");\n\n")

        # INTERNAL SIGNALS
        f.write(f"    logic [9:0] lam_state [0:{T}];\n")
        f.write(f"    logic [9:0] omg_state [0:{T}];\n")
        f.write(f"    logic [9:0] count;\n")
        f.write(f"    typedef enum logic [1:0] {{IDLE, RUN, FINISH}} state_t;\n")
        f.write(f"    state_t state;\n\n")

        # HELPER
        def write_const_mul(target_sig, src_sig, const_ele):
            val = int(const_ele)
            if val == 0: f.write(f"    assign {target_sig} = 10'd0;\n")
            elif val == 1: f.write(f"    assign {target_sig} = {src_sig};\n")
            else:
                terms_list = []
                for bit_out in range(10):
                    xor_terms = []
                    for bit_in in range(10):
                        term_val = int(const_ele * (alpha**bit_in))
                        if (term_val >> bit_out) & 1: xor_terms.append(f"{src_sig}[{bit_in}]")
                    terms_list.append(" ^ ".join(xor_terms) if xor_terms else "1'b0")
                f.write("    assign " + target_sig + " = {" + ", ".join(reversed(terms_list)) + "};\n")

        # 1. INITIALIZATION LOGIC (alpha^-START)
        f.write("    // --- Initialization ---\n")
        f.write(f"    logic [9:0] lam_init [0:{T}];\n")
        f.write(f"    logic [9:0] omg_init [0:{T}];\n")
        alpha_inv_start = alpha ** (FULL_LEN - START_POS)
        for i in range(T + 1):
            write_const_mul(f"lam_init[{i}]", f"lam_in[{i}]", alpha_inv_start ** i)
            write_const_mul(f"omg_init[{i}]", f"omg_in[{i}]", alpha_inv_start ** i)

        # 2. STATE UPDATE LOGIC (alpha^16)
        f.write("\n    // --- State Update ---\n")
        f.write(f"    logic [9:0] lam_next [0:{T}];\n")
        f.write(f"    logic [9:0] omg_next [0:{T}];\n")
        alpha_step_p = alpha ** PARALLELISM
        for i in range(T + 1):
            write_const_mul(f"lam_next[{i}]", f"lam_state[{i}]", alpha_step_p ** i)
            write_const_mul(f"omg_next[{i}]", f"omg_state[{i}]", alpha_step_p ** i)

        # 3. PARALLEL EVALUATION
        f.write("\n    // --- Parallel Evaluation ---\n")
        for p in range(PARALLELISM):
            f.write(f"    // -- Ch {p} --\n")
            alpha_offset = alpha ** p 
            terms_even = []; terms_odd = []; terms_omg = []
            
            for i in range(T + 1):
                const = alpha_offset ** i
                w_lam = f"w_L_p{p}_i{i}"; w_omg = f"w_O_p{p}_i{i}"
                f.write(f"    wire [9:0] {w_lam}, {w_omg};\n")
                write_const_mul(w_lam, f"lam_state[{i}]", const)
                write_const_mul(w_omg, f"omg_state[{i}]", const)
                terms_omg.append(w_omg)
                if i % 2 == 0: terms_even.append(w_lam)
                else:          terms_odd.append(w_lam)
            
            f.write(f"    wire [9:0] sum_even_{p} = {' ^ '.join(terms_even)};\n")
            f.write(f"    wire [9:0] sum_odd_{p}  = {' ^ '.join(terms_odd)};\n")
            f.write(f"    wire [9:0] sum_omg_{p}  = {' ^ '.join(terms_omg)};\n")
            f.write(f"    wire found_{p} = (sum_even_{p} == sum_odd_{p});\n")
            
            f.write(f"    wire [9:0] inv_odd_{p}, raw_err_{p};\n")
            f.write(f"    gf_inv_rom u_inv_{p} (.addr(sum_odd_{p}), .data(inv_odd_{p}));\n")
            f.write(f"    gf_mul u_mul_raw_{p} (.a(sum_omg_{p}), .b(inv_odd_{p}), .y(raw_err_{p}));\n")

        # 4. ERROR SCALING
        f.write("\n    // --- X Tracking ---\n")
        f.write("    logic [9:0] x_base, x_base_next;\n")
        write_const_mul("x_base_next", "x_base", alpha_step_p) 

        for p in range(PARALLELISM):
            f.write(f"    wire [9:0] x_loc_{p}, err_final_{p};\n")
            write_const_mul(f"x_loc_{p}", "x_base", alpha ** p)
            f.write(f"    gf_mul u_mul_fin_{p} (.a(raw_err_{p}), .b(x_loc_{p}), .y(err_final_{p}));\n")
            f.write(f"    assign error_val[{p}] = found_{p} ? err_final_{p} : 10'd0;\n")
            f.write(f"    assign error_pos[{p}] = ({START_POS} - (count * {PARALLELISM})) - {p};\n")

        # 5. FSM
        f.write("\n    always_ff @(posedge clk or negedge rst_n) begin\n")
        f.write("        if (!rst_n) begin\n")
        f.write("            state <= IDLE; count <= 0; valid_out <= 0; done <= 0; x_base <= 0;\n")
        f.write("        end else begin\n")
        f.write("            case (state)\n")
        f.write("                IDLE: begin\n")
        f.write("                    done <= 0; valid_out <= 0;\n")
        f.write("                    if (start) begin\n")
        f.write("                        state <= RUN; count <= 0;\n")
        f.write("                        lam_state <= lam_init; omg_state <= omg_init;\n")
        f.write(f"                        x_base <= {int(alpha_inv_start)};\n")
        f.write("                    end\n")
        f.write("                end\n")
        f.write("                RUN: begin\n")
        f.write("                    valid_out <= 1;\n")
        f.write(f"                    if (count == {CODE_LEN // PARALLELISM - 1}) state <= FINISH;\n")
        f.write("                    else begin\n")
        f.write("                        count <= count + 1;\n")
        f.write("                        lam_state <= lam_next; omg_state <= omg_next;\n")
        f.write("                        x_base <= x_base_next;\n")
        f.write("                    end\n")
        f.write("                end\n")
        f.write("                FINISH: begin valid_out <= 0; done <= 1; state <= IDLE; end\n")
        f.write("            endcase\n")
        f.write("        end\n")
        f.write("    end\n")
        
        # --- DEBUG BLOCK ---
        f.write("\n    // --- DEBUG MONITOR ---\n")
        f.write("    always @(posedge clk) begin\n")
        f.write("        if (valid_out && count == 0) begin\n")
        f.write("            $display(\"[RTL DEBUG] Time=%0t Count=0 (Checking Pos 543)\", $time);\n")
        f.write("            $display(\"  lam_state[0]=%h (Should be 1)\", lam_state[0]);\n")
        f.write("            $display(\"  lam_state[1]=%h\", lam_state[1]);\n")
        f.write("            $display(\"  CH0: sum_even=%h sum_odd=%h found=%b\", sum_even_0, sum_odd_0, found_0);\n")
        f.write("            $display(\"  CH0: sum_omg=%h raw_err=%h x_loc=%h val=%h\", sum_omg_0, raw_err_0, x_loc_0, error_val[0]);\n")
        f.write("        end\n")
        f.write("    end\n")
        
        f.write("endmodule\n")
    print(f"-> DEBUG RTL Generated: {filename}")

if __name__ == "__main__":
    main()