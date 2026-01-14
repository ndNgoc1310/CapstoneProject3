// Auto-generated GF(2^10) Constant Multipliers
// Generator Polynomial coefficients for RS(544, 514)

module gf_mul_const_g0 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g0
);
    assign p[0] = a[0] ^ a[1] ^ a[7] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[1] ^ a[2] ^ a[8] ^ a[9];
    assign p[2] = a[1] ^ a[2] ^ a[3] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[7] ^ a[8] ^ a[9];
    assign p[4] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[5] = a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[9];
    assign p[6] = a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7];
    assign p[7] = a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[8] = a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[9] = a[0] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g1 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g1
);
    assign p[0] = a[1] ^ a[2] ^ a[4] ^ a[8];
    assign p[1] = a[0] ^ a[2] ^ a[3] ^ a[5] ^ a[9];
    assign p[2] = a[1] ^ a[3] ^ a[4] ^ a[6];
    assign p[3] = a[1] ^ a[5] ^ a[7] ^ a[8];
    assign p[4] = a[2] ^ a[6] ^ a[8] ^ a[9];
    assign p[5] = a[3] ^ a[7] ^ a[9];
    assign p[6] = a[0] ^ a[4] ^ a[8];
    assign p[7] = a[1] ^ a[5] ^ a[9];
    assign p[8] = a[0] ^ a[2] ^ a[6];
    assign p[9] = a[0] ^ a[1] ^ a[3] ^ a[7];
endmodule

module gf_mul_const_g2 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g2
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

module gf_mul_const_g3 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g3
);
    assign p[0] = a[3] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[4] ^ a[7] ^ a[8] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[5] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[7] ^ a[8];
    assign p[4] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[8] ^ a[9];
    assign p[5] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[9];
    assign p[6] = a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6];
    assign p[7] = a[0] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7];
    assign p[8] = a[1] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[9] = a[2] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g4 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g4
);
    assign p[0] = a[0] ^ a[3] ^ a[5] ^ a[6] ^ a[7];
    assign p[1] = a[1] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[2] = a[2] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[4] = a[0] ^ a[1] ^ a[6] ^ a[8] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[2] ^ a[7] ^ a[9];
    assign p[6] = a[1] ^ a[2] ^ a[3] ^ a[8];
    assign p[7] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[9];
    assign p[8] = a[1] ^ a[3] ^ a[4] ^ a[5];
    assign p[9] = a[2] ^ a[4] ^ a[5] ^ a[6];
endmodule

module gf_mul_const_g5 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g5
);
    assign p[0] = a[0] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[1] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[2] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6];
    assign p[4] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7];
    assign p[5] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[6] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[7] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[8] = a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[9] = a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g6 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g6
);
    assign p[0] = a[2] ^ a[3] ^ a[7] ^ a[9];
    assign p[1] = a[3] ^ a[4] ^ a[8];
    assign p[2] = a[4] ^ a[5] ^ a[9];
    assign p[3] = a[0] ^ a[2] ^ a[3] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[4] = a[1] ^ a[3] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[5] = a[2] ^ a[4] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[6] = a[3] ^ a[5] ^ a[6] ^ a[8] ^ a[9];
    assign p[7] = a[0] ^ a[4] ^ a[6] ^ a[7] ^ a[9];
    assign p[8] = a[0] ^ a[1] ^ a[5] ^ a[7] ^ a[8];
    assign p[9] = a[1] ^ a[2] ^ a[6] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g7 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g7
);
    assign p[0] = a[0] ^ a[3] ^ a[4];
    assign p[1] = a[1] ^ a[4] ^ a[5];
    assign p[2] = a[2] ^ a[5] ^ a[6];
    assign p[3] = a[4] ^ a[6] ^ a[7];
    assign p[4] = a[5] ^ a[7] ^ a[8];
    assign p[5] = a[6] ^ a[8] ^ a[9];
    assign p[6] = a[0] ^ a[7] ^ a[9];
    assign p[7] = a[0] ^ a[1] ^ a[8];
    assign p[8] = a[1] ^ a[2] ^ a[9];
    assign p[9] = a[2] ^ a[3];
endmodule

module gf_mul_const_g8 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g8
);
    assign p[0] = a[1] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[2] ^ a[5] ^ a[6] ^ a[9];
    assign p[2] = a[1] ^ a[3] ^ a[6] ^ a[7];
    assign p[3] = a[1] ^ a[2] ^ a[5] ^ a[7] ^ a[9];
    assign p[4] = a[2] ^ a[3] ^ a[6] ^ a[8];
    assign p[5] = a[0] ^ a[3] ^ a[4] ^ a[7] ^ a[9];
    assign p[6] = a[0] ^ a[1] ^ a[4] ^ a[5] ^ a[8];
    assign p[7] = a[1] ^ a[2] ^ a[5] ^ a[6] ^ a[9];
    assign p[8] = a[2] ^ a[3] ^ a[6] ^ a[7];
    assign p[9] = a[0] ^ a[3] ^ a[4] ^ a[7] ^ a[8];
endmodule

module gf_mul_const_g9 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g9
);
    assign p[0] = a[1] ^ a[2] ^ a[6] ^ a[9];
    assign p[1] = a[2] ^ a[3] ^ a[7];
    assign p[2] = a[0] ^ a[3] ^ a[4] ^ a[8];
    assign p[3] = a[2] ^ a[4] ^ a[5] ^ a[6];
    assign p[4] = a[0] ^ a[3] ^ a[5] ^ a[6] ^ a[7];
    assign p[5] = a[1] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[6] = a[2] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[7] = a[3] ^ a[6] ^ a[8] ^ a[9];
    assign p[8] = a[0] ^ a[4] ^ a[7] ^ a[9];
    assign p[9] = a[0] ^ a[1] ^ a[5] ^ a[8];
endmodule

module gf_mul_const_g10 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g10
);
    assign p[0] = a[0] ^ a[2] ^ a[4] ^ a[5] ^ a[7] ^ a[9];
    assign p[1] = a[1] ^ a[3] ^ a[5] ^ a[6] ^ a[8];
    assign p[2] = a[2] ^ a[4] ^ a[6] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[8] ^ a[9];
    assign p[4] = a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[9];
    assign p[5] = a[0] ^ a[2] ^ a[4] ^ a[5] ^ a[6];
    assign p[6] = a[0] ^ a[1] ^ a[3] ^ a[5] ^ a[6] ^ a[7];
    assign p[7] = a[1] ^ a[2] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[8] = a[0] ^ a[2] ^ a[3] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[9] = a[1] ^ a[3] ^ a[4] ^ a[6] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g11 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g11
);
    assign p[0] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[8];
    assign p[1] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[2] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[3] = a[1] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[4] = a[0] ^ a[2] ^ a[4] ^ a[7] ^ a[8];
    assign p[5] = a[0] ^ a[1] ^ a[3] ^ a[5] ^ a[8] ^ a[9];
    assign p[6] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[6] ^ a[9];
    assign p[7] = a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[7];
    assign p[8] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[8];
    assign p[9] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[7] ^ a[9];
endmodule

module gf_mul_const_g12 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g12
);
    assign p[0] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[8];
    assign p[1] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[3] = a[1] ^ a[4] ^ a[7] ^ a[9];
    assign p[4] = a[0] ^ a[2] ^ a[5] ^ a[8];
    assign p[5] = a[0] ^ a[1] ^ a[3] ^ a[6] ^ a[9];
    assign p[6] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[7];
    assign p[7] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[8];
    assign p[8] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[9];
    assign p[9] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[7];
endmodule

module gf_mul_const_g13 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g13
);
    assign p[0] = a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[7];
    assign p[1] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[8];
    assign p[2] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[3] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[4] = a[1] ^ a[4] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[5] = a[0] ^ a[2] ^ a[5] ^ a[6] ^ a[8] ^ a[9];
    assign p[6] = a[1] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[7] = a[0] ^ a[2] ^ a[4] ^ a[7] ^ a[8];
    assign p[8] = a[0] ^ a[1] ^ a[3] ^ a[5] ^ a[8] ^ a[9];
    assign p[9] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[6] ^ a[9];
endmodule

module gf_mul_const_g14 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g14
);
    assign p[0] = a[0] ^ a[2] ^ a[3] ^ a[9];
    assign p[1] = a[1] ^ a[3] ^ a[4];
    assign p[2] = a[2] ^ a[4] ^ a[5];
    assign p[3] = a[2] ^ a[5] ^ a[6] ^ a[9];
    assign p[4] = a[3] ^ a[6] ^ a[7];
    assign p[5] = a[4] ^ a[7] ^ a[8];
    assign p[6] = a[5] ^ a[8] ^ a[9];
    assign p[7] = a[0] ^ a[6] ^ a[9];
    assign p[8] = a[0] ^ a[1] ^ a[7];
    assign p[9] = a[1] ^ a[2] ^ a[8];
endmodule

module gf_mul_const_g15 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g15
);
    assign p[0] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[7] ^ a[8];
    assign p[1] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[8] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[4] ^ a[6];
    assign p[4] = a[1] ^ a[2] ^ a[5] ^ a[7];
    assign p[5] = a[0] ^ a[2] ^ a[3] ^ a[6] ^ a[8];
    assign p[6] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[7] ^ a[9];
    assign p[7] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[8];
    assign p[8] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[6] ^ a[9];
    assign p[9] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[7];
endmodule

module gf_mul_const_g16 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g16
);
    assign p[0] = a[1] ^ a[3] ^ a[4] ^ a[6] ^ a[8];
    assign p[1] = a[2] ^ a[4] ^ a[5] ^ a[7] ^ a[9];
    assign p[2] = a[3] ^ a[5] ^ a[6] ^ a[8];
    assign p[3] = a[1] ^ a[3] ^ a[7] ^ a[8] ^ a[9];
    assign p[4] = a[0] ^ a[2] ^ a[4] ^ a[8] ^ a[9];
    assign p[5] = a[1] ^ a[3] ^ a[5] ^ a[9];
    assign p[6] = a[0] ^ a[2] ^ a[4] ^ a[6];
    assign p[7] = a[0] ^ a[1] ^ a[3] ^ a[5] ^ a[7];
    assign p[8] = a[1] ^ a[2] ^ a[4] ^ a[6] ^ a[8];
    assign p[9] = a[0] ^ a[2] ^ a[3] ^ a[5] ^ a[7] ^ a[9];
endmodule

module gf_mul_const_g17 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g17
);
    assign p[0] = a[4] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[6] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[6] ^ a[8];
    assign p[4] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[7] ^ a[9];
    assign p[5] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[8];
    assign p[6] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[7] ^ a[9];
    assign p[7] = a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[8];
    assign p[8] = a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[9] = a[3] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
endmodule

module gf_mul_const_g18 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g18
);
    assign p[0] = a[3] ^ a[8];
    assign p[1] = a[4] ^ a[9];
    assign p[2] = a[0] ^ a[5];
    assign p[3] = a[1] ^ a[3] ^ a[6] ^ a[8];
    assign p[4] = a[2] ^ a[4] ^ a[7] ^ a[9];
    assign p[5] = a[3] ^ a[5] ^ a[8];
    assign p[6] = a[4] ^ a[6] ^ a[9];
    assign p[7] = a[0] ^ a[5] ^ a[7];
    assign p[8] = a[1] ^ a[6] ^ a[8];
    assign p[9] = a[2] ^ a[7] ^ a[9];
endmodule

module gf_mul_const_g19 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g19
);
    assign p[0] = a[0] ^ a[1] ^ a[4] ^ a[6] ^ a[8];
    assign p[1] = a[1] ^ a[2] ^ a[5] ^ a[7] ^ a[9];
    assign p[2] = a[2] ^ a[3] ^ a[6] ^ a[8];
    assign p[3] = a[1] ^ a[3] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[4] = a[0] ^ a[2] ^ a[4] ^ a[7] ^ a[8] ^ a[9];
    assign p[5] = a[1] ^ a[3] ^ a[5] ^ a[8] ^ a[9];
    assign p[6] = a[0] ^ a[2] ^ a[4] ^ a[6] ^ a[9];
    assign p[7] = a[1] ^ a[3] ^ a[5] ^ a[7];
    assign p[8] = a[2] ^ a[4] ^ a[6] ^ a[8];
    assign p[9] = a[0] ^ a[3] ^ a[5] ^ a[7] ^ a[9];
endmodule

module gf_mul_const_g20 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g20
);
    assign p[0] = a[0] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7];
    assign p[1] = a[1] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[2] = a[2] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[4] = a[0] ^ a[1] ^ a[5] ^ a[6] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[2] ^ a[6] ^ a[7];
    assign p[6] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[7] ^ a[8];
    assign p[7] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[8] ^ a[9];
    assign p[8] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[9];
    assign p[9] = a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6];
endmodule

module gf_mul_const_g21 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g21
);
    assign p[0] = a[2] ^ a[6] ^ a[7];
    assign p[1] = a[0] ^ a[3] ^ a[7] ^ a[8];
    assign p[2] = a[1] ^ a[4] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[4] = a[0] ^ a[1] ^ a[6] ^ a[7] ^ a[8];
    assign p[5] = a[1] ^ a[2] ^ a[7] ^ a[8] ^ a[9];
    assign p[6] = a[2] ^ a[3] ^ a[8] ^ a[9];
    assign p[7] = a[3] ^ a[4] ^ a[9];
    assign p[8] = a[0] ^ a[4] ^ a[5];
    assign p[9] = a[1] ^ a[5] ^ a[6];
endmodule

module gf_mul_const_g22 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g22
);
    assign p[0] = a[0] ^ a[1] ^ a[5] ^ a[6];
    assign p[1] = a[1] ^ a[2] ^ a[6] ^ a[7];
    assign p[2] = a[0] ^ a[2] ^ a[3] ^ a[7] ^ a[8];
    assign p[3] = a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[8] ^ a[9];
    assign p[4] = a[0] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[6] = a[1] ^ a[2] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[7] = a[2] ^ a[3] ^ a[7] ^ a[8] ^ a[9];
    assign p[8] = a[3] ^ a[4] ^ a[8] ^ a[9];
    assign p[9] = a[0] ^ a[4] ^ a[5] ^ a[9];
endmodule

module gf_mul_const_g23 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g23
);
    assign p[0] = a[4] ^ a[5] ^ a[7] ^ a[8];
    assign p[1] = a[5] ^ a[6] ^ a[8] ^ a[9];
    assign p[2] = a[0] ^ a[6] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[4] ^ a[5];
    assign p[4] = a[1] ^ a[2] ^ a[5] ^ a[6];
    assign p[5] = a[0] ^ a[2] ^ a[3] ^ a[6] ^ a[7];
    assign p[6] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[7] ^ a[8];
    assign p[7] = a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[8] = a[2] ^ a[3] ^ a[5] ^ a[6] ^ a[9];
    assign p[9] = a[3] ^ a[4] ^ a[6] ^ a[7];
endmodule

module gf_mul_const_g24 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g24
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

module gf_mul_const_g25 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g25
);
    assign p[0] = a[1] ^ a[5] ^ a[7] ^ a[8];
    assign p[1] = a[2] ^ a[6] ^ a[8] ^ a[9];
    assign p[2] = a[3] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[4] = a[1] ^ a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[5] = a[0] ^ a[2] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[6] = a[1] ^ a[3] ^ a[4] ^ a[7] ^ a[8];
    assign p[7] = a[2] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[8] = a[3] ^ a[5] ^ a[6] ^ a[9];
    assign p[9] = a[0] ^ a[4] ^ a[6] ^ a[7];
endmodule

module gf_mul_const_g26 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g26
);
    assign p[0] = a[3] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[1] = a[0] ^ a[4] ^ a[5] ^ a[6] ^ a[9];
    assign p[2] = a[0] ^ a[1] ^ a[5] ^ a[6] ^ a[7];
    assign p[3] = a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[4] = a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[5] = a[0] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[6] = a[0] ^ a[1] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[7] = a[0] ^ a[1] ^ a[2] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[8] = a[1] ^ a[2] ^ a[3] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[9] = a[2] ^ a[3] ^ a[4] ^ a[7] ^ a[8] ^ a[9];
endmodule

module gf_mul_const_g27 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g27
);
    assign p[0] = a[0] ^ a[3] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[1] = a[0] ^ a[1] ^ a[4] ^ a[6] ^ a[7] ^ a[8];
    assign p[2] = a[1] ^ a[2] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[2] ^ a[5] ^ a[7] ^ a[8];
    assign p[4] = a[0] ^ a[1] ^ a[3] ^ a[6] ^ a[8] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[7] ^ a[9];
    assign p[6] = a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[8];
    assign p[7] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[9];
    assign p[8] = a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[7];
    assign p[9] = a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[8];
endmodule

module gf_mul_const_g28 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g28
);
    assign p[0] = a[1] ^ a[5] ^ a[7] ^ a[8];
    assign p[1] = a[2] ^ a[6] ^ a[8] ^ a[9];
    assign p[2] = a[3] ^ a[7] ^ a[9];
    assign p[3] = a[0] ^ a[1] ^ a[4] ^ a[5] ^ a[7];
    assign p[4] = a[1] ^ a[2] ^ a[5] ^ a[6] ^ a[8];
    assign p[5] = a[0] ^ a[2] ^ a[3] ^ a[6] ^ a[7] ^ a[9];
    assign p[6] = a[1] ^ a[3] ^ a[4] ^ a[7] ^ a[8];
    assign p[7] = a[2] ^ a[4] ^ a[5] ^ a[8] ^ a[9];
    assign p[8] = a[3] ^ a[5] ^ a[6] ^ a[9];
    assign p[9] = a[0] ^ a[4] ^ a[6] ^ a[7];
endmodule

module gf_mul_const_g29 (
    input  logic [9:0] a, // Feedback input
    output logic [9:0] p  // Result p = a * g29
);
    assign p[0] = a[0] ^ a[1] ^ a[5] ^ a[6] ^ a[7] ^ a[9];
    assign p[1] = a[0] ^ a[1] ^ a[2] ^ a[6] ^ a[7] ^ a[8];
    assign p[2] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[7] ^ a[8] ^ a[9];
    assign p[3] = a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8];
    assign p[4] = a[0] ^ a[1] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[5] = a[0] ^ a[1] ^ a[2] ^ a[4] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[6] = a[1] ^ a[2] ^ a[3] ^ a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[7] = a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
    assign p[8] = a[3] ^ a[4] ^ a[5] ^ a[7] ^ a[8] ^ a[9];
    assign p[9] = a[0] ^ a[4] ^ a[5] ^ a[6] ^ a[8] ^ a[9];
endmodule

