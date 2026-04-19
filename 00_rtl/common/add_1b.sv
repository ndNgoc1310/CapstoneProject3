`timescale 1ns/1ps

module add_1b
(
        input   logic   a, b, cin,
        output  logic   sum, cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a ^ b));

endmodule:add_1b
