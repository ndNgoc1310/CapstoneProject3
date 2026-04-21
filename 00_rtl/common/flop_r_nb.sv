`timescale 1ns/1ps

module flop_r_nb
#(parameter WIDTH = 8)

(
    input   logic               clk, rst_n, en,
    input   logic   [WIDTH-1:0] d,
    output  logic   [WIDTH-1:0] q
);

always_ff @(posedge clk, negedge rst_n)
    if      (~rst_n)    q <= 0;
    else if (en)        q <= d;

endmodule:flop_r_nb


