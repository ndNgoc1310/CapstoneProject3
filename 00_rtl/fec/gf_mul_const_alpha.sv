// =========================================================
// AUTO-GENERATED SYNDROME MULTIPLIERS FOR RS(544, 514)
// Contains 30 modules: gf_mul_const_alpha0 to alpha29
// =========================================================

// --- Module 0: Multiplier by Alpha^0 (Dec: 1) ---
module gf_mul_const_alpha0 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[0];
    assign p[1] = a[1];
    assign p[2] = a[2];
    assign p[3] = a[3];
    assign p[4] = a[4];
    assign p[5] = a[5];
    assign p[6] = a[6];
    assign p[7] = a[7];
    assign p[8] = a[8];
    assign p[9] = a[9];
endmodule

// --- Module 1: Multiplier by Alpha^1 (Dec: 2) ---
module gf_mul_const_alpha1 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[9];
    assign p[1] = a[0];
    assign p[2] = a[1];
    assign p[3] = a[2] ^ a[9];
    assign p[4] = a[3];
    assign p[5] = a[4];
    assign p[6] = a[5];
    assign p[7] = a[6];
    assign p[8] = a[7];
    assign p[9] = a[8];
endmodule

// --- Module 2: Multiplier by Alpha^2 (Dec: 4) ---
module gf_mul_const_alpha2 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[8];
    assign p[1] = a[9];
    assign p[2] = a[0];
    assign p[3] = a[1] ^ a[8];
    assign p[4] = a[2] ^ a[9];
    assign p[5] = a[3];
    assign p[6] = a[4];
    assign p[7] = a[5];
    assign p[8] = a[6];
    assign p[9] = a[7];
endmodule

// --- Module 3: Multiplier by Alpha^3 (Dec: 8) ---
module gf_mul_const_alpha3 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[7];
    assign p[1] = a[8];
    assign p[2] = a[9];
    assign p[3] = a[0] ^ a[7];
    assign p[4] = a[1] ^ a[8];
    assign p[5] = a[2] ^ a[9];
    assign p[6] = a[3];
    assign p[7] = a[4];
    assign p[8] = a[5];
    assign p[9] = a[6];
endmodule

// --- Module 4: Multiplier by Alpha^4 (Dec: 16) ---
module gf_mul_const_alpha4 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[6];
    assign p[1] = a[7];
    assign p[2] = a[8];
    assign p[3] = a[6] ^ a[9];
    assign p[4] = a[0] ^ a[7];
    assign p[5] = a[1] ^ a[8];
    assign p[6] = a[2] ^ a[9];
    assign p[7] = a[3];
    assign p[8] = a[4];
    assign p[9] = a[5];
endmodule

// --- Module 5: Multiplier by Alpha^5 (Dec: 32) ---
module gf_mul_const_alpha5 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[5];
    assign p[1] = a[6];
    assign p[2] = a[7];
    assign p[3] = a[5] ^ a[8];
    assign p[4] = a[6] ^ a[9];
    assign p[5] = a[0] ^ a[7];
    assign p[6] = a[1] ^ a[8];
    assign p[7] = a[2] ^ a[9];
    assign p[8] = a[3];
    assign p[9] = a[4];
endmodule

// --- Module 6: Multiplier by Alpha^6 (Dec: 64) ---
module gf_mul_const_alpha6 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[4];
    assign p[1] = a[5];
    assign p[2] = a[6];
    assign p[3] = a[4] ^ a[7];
    assign p[4] = a[5] ^ a[8];
    assign p[5] = a[6] ^ a[9];
    assign p[6] = a[0] ^ a[7];
    assign p[7] = a[1] ^ a[8];
    assign p[8] = a[2] ^ a[9];
    assign p[9] = a[3];
endmodule

// --- Module 7: Multiplier by Alpha^7 (Dec: 128) ---
module gf_mul_const_alpha7 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[3];
    assign p[1] = a[4];
    assign p[2] = a[5];
    assign p[3] = a[3] ^ a[6];
    assign p[4] = a[4] ^ a[7];
    assign p[5] = a[5] ^ a[8];
    assign p[6] = a[6] ^ a[9];
    assign p[7] = a[0] ^ a[7];
    assign p[8] = a[1] ^ a[8];
    assign p[9] = a[2] ^ a[9];
endmodule

// --- Module 8: Multiplier by Alpha^8 (Dec: 256) ---
module gf_mul_const_alpha8 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[2] ^ a[9];
    assign p[1] = a[3];
    assign p[2] = a[4];
    assign p[3] = a[2] ^ a[5] ^ a[9];
    assign p[4] = a[3] ^ a[6];
    assign p[5] = a[4] ^ a[7];
    assign p[6] = a[5] ^ a[8];
    assign p[7] = a[6] ^ a[9];
    assign p[8] = a[0] ^ a[7];
    assign p[9] = a[1] ^ a[8];
endmodule

// --- Module 9: Multiplier by Alpha^9 (Dec: 512) ---
module gf_mul_const_alpha9 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[1] ^ a[8];
    assign p[1] = a[2] ^ a[9];
    assign p[2] = a[3];
    assign p[3] = a[1] ^ a[4] ^ a[8];
    assign p[4] = a[2] ^ a[5] ^ a[9];
    assign p[5] = a[3] ^ a[6];
    assign p[6] = a[4] ^ a[7];
    assign p[7] = a[5] ^ a[8];
    assign p[8] = a[6] ^ a[9];
    assign p[9] = a[0] ^ a[7];
endmodule

// --- Module 10: Multiplier by Alpha^10 (Dec: 9) ---
module gf_mul_const_alpha10 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[0] ^ a[7];
    assign p[1] = a[1] ^ a[8];
    assign p[2] = a[2] ^ a[9];
    assign p[3] = a[0] ^ a[3] ^ a[7];
    assign p[4] = a[1] ^ a[4] ^ a[8];
    assign p[5] = a[2] ^ a[5] ^ a[9];
    assign p[6] = a[3] ^ a[6];
    assign p[7] = a[4] ^ a[7];
    assign p[8] = a[5] ^ a[8];
    assign p[9] = a[6] ^ a[9];
endmodule

// --- Module 11: Multiplier by Alpha^11 (Dec: 18) ---
module gf_mul_const_alpha11 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[6] ^ a[9];
    assign p[1] = a[0] ^ a[7];
    assign p[2] = a[1] ^ a[8];
    assign p[3] = a[2] ^ a[6];
    assign p[4] = a[0] ^ a[3] ^ a[7];
    assign p[5] = a[1] ^ a[4] ^ a[8];
    assign p[6] = a[2] ^ a[5] ^ a[9];
    assign p[7] = a[3] ^ a[6];
    assign p[8] = a[4] ^ a[7];
    assign p[9] = a[5] ^ a[8];
endmodule

// --- Module 12: Multiplier by Alpha^12 (Dec: 36) ---
module gf_mul_const_alpha12 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[5] ^ a[8];
    assign p[1] = a[6] ^ a[9];
    assign p[2] = a[0] ^ a[7];
    assign p[3] = a[1] ^ a[5];
    assign p[4] = a[2] ^ a[6];
    assign p[5] = a[0] ^ a[3] ^ a[7];
    assign p[6] = a[1] ^ a[4] ^ a[8];
    assign p[7] = a[2] ^ a[5] ^ a[9];
    assign p[8] = a[3] ^ a[6];
    assign p[9] = a[4] ^ a[7];
endmodule

// --- Module 13: Multiplier by Alpha^13 (Dec: 72) ---
module gf_mul_const_alpha13 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[4] ^ a[7];
    assign p[1] = a[5] ^ a[8];
    assign p[2] = a[6] ^ a[9];
    assign p[3] = a[0] ^ a[4];
    assign p[4] = a[1] ^ a[5];
    assign p[5] = a[2] ^ a[6];
    assign p[6] = a[0] ^ a[3] ^ a[7];
    assign p[7] = a[1] ^ a[4] ^ a[8];
    assign p[8] = a[2] ^ a[5] ^ a[9];
    assign p[9] = a[3] ^ a[6];
endmodule

// --- Module 14: Multiplier by Alpha^14 (Dec: 144) ---
module gf_mul_const_alpha14 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[3] ^ a[6];
    assign p[1] = a[4] ^ a[7];
    assign p[2] = a[5] ^ a[8];
    assign p[3] = a[3] ^ a[9];
    assign p[4] = a[0] ^ a[4];
    assign p[5] = a[1] ^ a[5];
    assign p[6] = a[2] ^ a[6];
    assign p[7] = a[0] ^ a[3] ^ a[7];
    assign p[8] = a[1] ^ a[4] ^ a[8];
    assign p[9] = a[2] ^ a[5] ^ a[9];
endmodule

// --- Module 15: Multiplier by Alpha^15 (Dec: 288) ---
module gf_mul_const_alpha15 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[2] ^ a[5] ^ a[9];
    assign p[1] = a[3] ^ a[6];
    assign p[2] = a[4] ^ a[7];
    assign p[3] = a[2] ^ a[8] ^ a[9];
    assign p[4] = a[3] ^ a[9];
    assign p[5] = a[0] ^ a[4];
    assign p[6] = a[1] ^ a[5];
    assign p[7] = a[2] ^ a[6];
    assign p[8] = a[0] ^ a[3] ^ a[7];
    assign p[9] = a[1] ^ a[4] ^ a[8];
endmodule

// --- Module 16: Multiplier by Alpha^16 (Dec: 576) ---
module gf_mul_const_alpha16 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[1] ^ a[4] ^ a[8];
    assign p[1] = a[2] ^ a[5] ^ a[9];
    assign p[2] = a[3] ^ a[6];
    assign p[3] = a[1] ^ a[7] ^ a[8];
    assign p[4] = a[2] ^ a[8] ^ a[9];
    assign p[5] = a[3] ^ a[9];
    assign p[6] = a[0] ^ a[4];
    assign p[7] = a[1] ^ a[5];
    assign p[8] = a[2] ^ a[6];
    assign p[9] = a[0] ^ a[3] ^ a[7];
endmodule

// --- Module 17: Multiplier by Alpha^17 (Dec: 137) ---
module gf_mul_const_alpha17 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[0] ^ a[3] ^ a[7];
    assign p[1] = a[1] ^ a[4] ^ a[8];
    assign p[2] = a[2] ^ a[5] ^ a[9];
    assign p[3] = a[0] ^ a[6] ^ a[7];
    assign p[4] = a[1] ^ a[7] ^ a[8];
    assign p[5] = a[2] ^ a[8] ^ a[9];
    assign p[6] = a[3] ^ a[9];
    assign p[7] = a[0] ^ a[4];
    assign p[8] = a[1] ^ a[5];
    assign p[9] = a[2] ^ a[6];
endmodule

// --- Module 18: Multiplier by Alpha^18 (Dec: 274) ---
module gf_mul_const_alpha18 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[2] ^ a[6];
    assign p[1] = a[0] ^ a[3] ^ a[7];
    assign p[2] = a[1] ^ a[4] ^ a[8];
    assign p[3] = a[5] ^ a[6] ^ a[9];
    assign p[4] = a[0] ^ a[6] ^ a[7];
    assign p[5] = a[1] ^ a[7] ^ a[8];
    assign p[6] = a[2] ^ a[8] ^ a[9];
    assign p[7] = a[3] ^ a[9];
    assign p[8] = a[0] ^ a[4];
    assign p[9] = a[1] ^ a[5];
endmodule

// --- Module 19: Multiplier by Alpha^19 (Dec: 548) ---
module gf_mul_const_alpha19 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[1] ^ a[5];
    assign p[1] = a[2] ^ a[6];
    assign p[2] = a[0] ^ a[3] ^ a[7];
    assign p[3] = a[4] ^ a[5] ^ a[8];
    assign p[4] = a[5] ^ a[6] ^ a[9];
    assign p[5] = a[0] ^ a[6] ^ a[7];
    assign p[6] = a[1] ^ a[7] ^ a[8];
    assign p[7] = a[2] ^ a[8] ^ a[9];
    assign p[8] = a[3] ^ a[9];
    assign p[9] = a[0] ^ a[4];
endmodule

// --- Module 20: Multiplier by Alpha^20 (Dec: 65) ---
module gf_mul_const_alpha20 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[0] ^ a[4];
    assign p[1] = a[1] ^ a[5];
    assign p[2] = a[2] ^ a[6];
    assign p[3] = a[3] ^ a[4] ^ a[7];
    assign p[4] = a[4] ^ a[5] ^ a[8];
    assign p[5] = a[5] ^ a[6] ^ a[9];
    assign p[6] = a[0] ^ a[6] ^ a[7];
    assign p[7] = a[1] ^ a[7] ^ a[8];
    assign p[8] = a[2] ^ a[8] ^ a[9];
    assign p[9] = a[3] ^ a[9];
endmodule

// --- Module 21: Multiplier by Alpha^21 (Dec: 130) ---
module gf_mul_const_alpha21 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[3] ^ a[9];
    assign p[1] = a[0] ^ a[4];
    assign p[2] = a[1] ^ a[5];
    assign p[3] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[4] = a[3] ^ a[4] ^ a[7];
    assign p[5] = a[4] ^ a[5] ^ a[8];
    assign p[6] = a[5] ^ a[6] ^ a[9];
    assign p[7] = a[0] ^ a[6] ^ a[7];
    assign p[8] = a[1] ^ a[7] ^ a[8];
    assign p[9] = a[2] ^ a[8] ^ a[9];
endmodule

// --- Module 22: Multiplier by Alpha^22 (Dec: 260) ---
module gf_mul_const_alpha22 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[2] ^ a[8] ^ a[9];
    assign p[1] = a[3] ^ a[9];
    assign p[2] = a[0] ^ a[4];
    assign p[3] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[4] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[5] = a[3] ^ a[4] ^ a[7];
    assign p[6] = a[4] ^ a[5] ^ a[8];
    assign p[7] = a[5] ^ a[6] ^ a[9];
    assign p[8] = a[0] ^ a[6] ^ a[7];
    assign p[9] = a[1] ^ a[7] ^ a[8];
endmodule

// --- Module 23: Multiplier by Alpha^23 (Dec: 520) ---
module gf_mul_const_alpha23 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[1] ^ a[7] ^ a[8];
    assign p[1] = a[2] ^ a[8] ^ a[9];
    assign p[2] = a[3] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[4] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[5] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[6] = a[3] ^ a[4] ^ a[7];
    assign p[7] = a[4] ^ a[5] ^ a[8];
    assign p[8] = a[5] ^ a[6] ^ a[9];
    assign p[9] = a[0] ^ a[6] ^ a[7];
endmodule

// --- Module 24: Multiplier by Alpha^24 (Dec: 25) ---
module gf_mul_const_alpha24 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[0] ^ a[6] ^ a[7];
    assign p[1] = a[1] ^ a[7] ^ a[8];
    assign p[2] = a[2] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[4] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[5] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[6] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[7] = a[3] ^ a[4] ^ a[7];
    assign p[8] = a[4] ^ a[5] ^ a[8];
    assign p[9] = a[5] ^ a[6] ^ a[9];
endmodule

// --- Module 25: Multiplier by Alpha^25 (Dec: 50) ---
module gf_mul_const_alpha25 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[5] ^ a[6] ^ a[9];
    assign p[1] = a[0] ^ a[6] ^ a[7];
    assign p[2] = a[1] ^ a[7] ^ a[8];
    assign p[3] = a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[4] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[6] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[7] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[8] = a[3] ^ a[4] ^ a[7];
    assign p[9] = a[4] ^ a[5] ^ a[8];
endmodule

// --- Module 26: Multiplier by Alpha^26 (Dec: 100) ---
module gf_mul_const_alpha26 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[4] ^ a[5] ^ a[8];
    assign p[1] = a[5] ^ a[6] ^ a[9];
    assign p[2] = a[0] ^ a[6] ^ a[7];
    assign p[3] = a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[4] = a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[5] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[6] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[7] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[8] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[9] = a[3] ^ a[4] ^ a[7];
endmodule

// --- Module 27: Multiplier by Alpha^27 (Dec: 200) ---
module gf_mul_const_alpha27 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[3] ^ a[4] ^ a[7];
    assign p[1] = a[4] ^ a[5] ^ a[8];
    assign p[2] = a[5] ^ a[6] ^ a[9];
    assign p[3] = a[0] ^ a[3] ^ a[4] ^ a[6];
    assign p[4] = a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[5] = a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[6] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[7] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[8] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[9] = a[2] ^ a[3] ^ a[6] ^ a[9];
endmodule

// --- Module 28: Multiplier by Alpha^28 (Dec: 400) ---
module gf_mul_const_alpha28 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[1] = a[3] ^ a[4] ^ a[7];
    assign p[2] = a[4] ^ a[5] ^ a[8];
    assign p[3] = a[2] ^ a[3] ^ a[5];
    assign p[4] = a[0] ^ a[3] ^ a[4] ^ a[6];
    assign p[5] = a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[6] = a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[7] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[8] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
    assign p[9] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
endmodule

// --- Module 29: Multiplier by Alpha^29 (Dec: 800) ---
module gf_mul_const_alpha29 (
    input  logic [9:0] a,
    output logic [9:0] p
);
    assign p[0] = a[1] ^ a[2] ^ a[5] ^ a[8] ^ a[9];
    assign p[1] = a[2] ^ a[3] ^ a[6] ^ a[9];
    assign p[2] = a[3] ^ a[4] ^ a[7];
    assign p[3] = a[1] ^ a[2] ^ a[4] ^ a[9];
    assign p[4] = a[2] ^ a[3] ^ a[5];
    assign p[5] = a[0] ^ a[3] ^ a[4] ^ a[6];
    assign p[6] = a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[7] = a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[8] = a[0] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[9] = a[0] ^ a[1] ^ a[4] ^ a[7] ^ a[8];
endmodule

