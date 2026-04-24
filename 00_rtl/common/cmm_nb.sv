// cmm_nb.sv

module add_1b
(
        input   logic   a, b, cin,
        output  logic   sum, cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a ^ b));

endmodule: add_1b

// --------------------

module add_sub_nb
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
                    .b   (b[i] ^ cin), // XOR for subtraction
                    .cin (cin),
                    .sum (sum[i]),
                    .cout(carry[i])
                );
            end else begin
                add_1b u_adder (
                    .a   (a[i]),
                    .b   (b[i] ^ cin), // XOR for subtraction
                    .cin (carry[i-1]),
                    .sum (sum[i]),
                    .cout(carry[i])
                );
            end
        end
    endgenerate

xor (cout, carry[WIDTH-1], cin);

endmodule: add_sub_nb

// --------------------

module and_nb
#(parameter WIDTH = 32)

(
    input   logic   [WIDTH-1:0] a, b,
    output  logic   [WIDTH-1:0] y
);

assign y = a & b;

endmodule: and_nb

// --------------------

module xor_nb
#(parameter WIDTH = 32)

(
    input   logic   [WIDTH-1:0] a, b,
    output  logic   [WIDTH-1:0] y
);

assign y = a ^ b;

endmodule: xor_nb

// --------------------

module mux_2_nb
#(parameter WIDTH = 32)
(
    input   logic   [WIDTH-1:0] d0, d1,
    input   logic               s,
    output  logic   [WIDTH-1:0] y
);

assign y = s ? d1 : d0;

endmodule: mux_2_nb

// --------------------

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

endmodule: flop_r_nb

// --------------------

module xor_tree_nb 
#(
    parameter WIDTH = 10,
    parameter N = 16
)
(
    input logic [WIDTH-1:0] in [N-1:0],
    output logic [WIDTH-1:0] out
);

    // --- Internal Signals ---
    // Mảng chứa toàn bộ các node trong cây (bao gồm Inputs và Internal Wires).
    // Một cây nhị phân giảm trừ (reduction tree) với N lá luôn có chính xác 2*N - 1 node.
    logic [WIDTH-1:0] nodes [2*N-1];

    genvar i, k;
    generate
        // 1. Gán N lá (leaf nodes) đầu tiên của cây bằng chính giá trị từ input
        for (i = 0; i < N; i++) begin : GEN_INPUTS
            assign nodes[i] = in[i];
        end

        // 2. Xây dựng cấu trúc cây phần cứng (Instantiate N-1 cổng XOR)
        // Thuật toán: Cổng XOR thứ k sẽ lấy 2 node liền kề (2*k và 2*k+1) để tạo ra node mới (N+k).
        // Cấu trúc này tự động cân bằng (auto-balancing) các tầng logic ở bước tổng hợp.
        for (k = 0; k < N - 1; k++) begin : gen_xor_tree
            xor_nb #(.WIDTH(WIDTH)) U_Xor (
                .a  (nodes[2*k]),
                .b  (nodes[2*k + 1]),
                .y  (nodes[N + k])
            );
        end
    endgenerate

    // 3. Output cuối cùng luôn nằm ở đỉnh cây (root node)
    assign out = nodes[2*N - 2];

endmodule: xor_tree_nb