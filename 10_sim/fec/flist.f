// ==========================================
// RS-FEC (544, 514) FILE LIST
// ==========================================

// Include directories
+incdir+./../../00_rtl/fec

// 1. GF Multiplier Constants (Leaf Cells)
./../../00_rtl/fec/gf_mul_constants.sv

// 2. RS Encoder Core (Top Module RTL)
./../../00_rtl/fec/rs_encoder.sv

// 3. Testbench (Verification)
./../../01_tb/fec/rs_encoder_tb.sv

// Set top-level module for simulation
-top rs_encoder_tb
