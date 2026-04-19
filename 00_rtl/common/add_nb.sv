`timescale 1ns/1ps

module add_nb
#(parameter WIDTH = 32)
(
    input   logic   [WIDTH-1:0] a, b,
    input   logic               cin,
    output  logic   [WIDTH-1:0] sum,
    output  logic               cout
);

logic [WIDTH-1:0] carry;

genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_ADDER
            if (i == 0) begin
                add_1b u_adder (
                    .a   (a[i]),
                    .b   (b[i]),
                    .cin (cin),
                    .sum (sum[i]),
                    .cout(carry[i])
                );
            end else begin
                add_1b u_adder (
                    .a   (a[i]),
                    .b   (b[i]),
                    .cin (carry[i-1]),
                    .sum (sum[i]),
                    .cout(carry[i])
                );
            end
        end
    endgenerate

xor (cout, carry[WIDTH-1], cin);

endmodule:add_nb

