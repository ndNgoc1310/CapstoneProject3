`timescale 1ns/1ps

module and_nb
#(parameter WIDTH = 32)

(
    input   logic   [WIDTH-1:0] a, b,
    output  logic   [WIDTH-1:0] y
);

assign y = a & b;

endmodule:and_nb
