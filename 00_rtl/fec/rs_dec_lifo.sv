module rs_dec_lifo
#(
    parameter WIDTH = 10,
    parameter K = 544
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             push_sop,
    input logic             push_en,
    input logic [WIDTH-1:0] dat_in,
    input logic             pop_sop,
    input logic             pop_en,

    output logic                vld_out,
    output logic [WIDTH-1:0]    dat_out
);

    // Internal signals
    logic [WIDTH-1:0] ram [0:K-1];
    logic [WIDTH-1:0] wr_addr, rd_addr;
    logic [WIDTH-1:0] wr_addr_nxt, rd_addr_nxt;
    logic [WIDTH-1:0] wr_ptr, rd_ptr;

    // --- 1.
    mux_2_nb #(.WIDTH(WIDTH)) Wr_Ptr_Mux (
        .d0 (wr_ptr),
        .d1 (WIDTH'('d0)),
        .s  (push_sop),
        .y  (wr_addr)
    );

    mux_2_nb #(.WIDTH(WIDTH)) Rd_Ptr_Mux (
        .d0 (rd_ptr),
        .d1 (WIDTH'('d543)),
        .s  (pop_sop),
        .y  (rd_addr)
    );    

    // --- 2.
    always_ff @(posedge clk) begin
        if (push_en) begin
            ram[wr_addr] <= dat_in;
        end
        
        if (pop_en) begin
            dat_out <= ram[rd_addr];
        end
    end

    // --- 3.
    add_sub_nb #(.WIDTH(WIDTH)) Wr_Ptr_Add (
        .a      (wr_addr),
        .b      (WIDTH'('d1)),
        .cin    (1'b0),
        .sum    (wr_addr_nxt),
        .cout   ()
    );

    flop_r_nb #(.WIDTH(WIDTH)) Wr_Ptr_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (push_en),
        .d      (wr_addr_nxt),
        .q      (wr_ptr)
    );

    add_sub_nb #(.WIDTH(WIDTH)) Rd_Ptr_Sub (
        .a      (rd_addr),
        .b      (WIDTH'('d1)),
        .cin    (1'b1),
        .sum    (rd_addr_nxt),
        .cout   ()
    );

    flop_r_nb #(.WIDTH(WIDTH)) Rd_Ptr_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (pop_en),
        .d      (rd_addr_nxt),
        .q      (rd_ptr)
    );

    // --- 4.
    flop_r_nb #(.WIDTH(1)) Vld_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (1'b1),
        .d      (pop_en),
        .q      (vld_out)
    );

endmodule: rs_dec_lifo
