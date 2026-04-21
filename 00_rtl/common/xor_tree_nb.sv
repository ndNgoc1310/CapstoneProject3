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

endmodule:xor_tree_nb