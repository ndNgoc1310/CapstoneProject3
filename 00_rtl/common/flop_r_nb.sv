`timescale 1ns/1ps

module flop_r_nb
#(parameter WIDTH = 8)

(
    input   logic               clk, rstn, en,
    input   logic   [WIDTH-1:0] d,
    output  logic   [WIDTH-1:0] q
);

always_ff @(posedge clk, negedge rstn)
    if      (~rstn) q <= 0;
    else if (en)    q <= d;

endmodule:flop_r_nb


