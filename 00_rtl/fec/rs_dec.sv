module rs_dec
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15,
    parameter K = 544
)
(
    input logic clk,
    input logic rst_n,
    input logic sop_in,
    input logic valid_in,
    input logic [WIDTH-1:0] data_in,

    output logic sop_out,
    output logic valid_out,
    output logic [WIDTH-1:0] data_out,
    output logic ready,
    output logic error
);

    // Internal signals
    logic syn_to_kes_valid;
    logic [WIDTH-1:0] syn_to_kes_syn [NSYM-1:0];

    logic kes_to_chien_valid;
    logic [WIDTH-1:0] kes_to_chien_lam [ORDER:0];
    logic [WIDTH-1:0] kes_to_chien_ome [ORDER:0];

    logic chien_sop_out;
    logic chien_valid_out;
    logic chien_to_forney_err_flg;
    logic [WIDTH-1:0] chien_to_forney_l_val_der;
    logic [WIDTH-1:0] chien_to_forney_o_val;

    logic [WIDTH-1:0] forney_err_mag;

    logic lifo_valid_out;
    logic [WIDTH-1:0] lifo_data_out;

    logic syn_ready, kes_ready, chien_ready;
    logic syn_error, kes_error, chien_error;

    logic [WIDTH-1:0] err_mag_delay;
    logic sop_out_delay;

    // --- 1. Submodules

    rs_dec_syn #(.WIDTH(WIDTH), .NSYM(NSYM)) Syn (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .valid_in   (valid_in),
        .data_in    (data_in),

        .valid_out  (syn_to_kes_valid),
        .syn_out    (syn_to_kes_syn),

        .ready      (syn_ready),
        .error      (syn_error)
    );
    
    rs_dec_kes #(.WIDTH(WIDTH), .NSYM(NSYM), .ORDER(ORDER), .CNT_WIDTH(5)) Kes (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (syn_to_kes_valid),
        .syn_in     (syn_to_kes_syn),

        .valid_out  (kes_to_chien_valid),
        .lam_out    (kes_to_chien_lam),
        .ome_out    (kes_to_chien_ome),

        .ready      (kes_ready),
        .error      (kes_error)
    );

    rs_dec_chien #(.WIDTH(WIDTH), .ORDER(ORDER), .CNT_WIDTH(10)) Chien (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_in       (kes_to_chien_valid),
        .lam_in         (kes_to_chien_lam),
        .ome_in         (kes_to_chien_ome),

        .sop_out        (chien_sop_out),
        .valid_out      (chien_valid_out),
        .err_flg        (chien_to_forney_err_flg),
        .l_val_der      (chien_to_forney_l_val_der),
        .o_val          (chien_to_forney_o_val),

        .ready          (chien_ready),
        .error          (chien_error)
    );

    rs_dec_forney #(.WIDTH(WIDTH)) Forney (
        .err_flg        (chien_to_forney_err_flg),
        .l_val_der      (chien_to_forney_l_val_der),
        .o_val          (chien_to_forney_o_val),

        .err_mag        (forney_err_mag)
    );

    rs_dec_lifo #(.WIDTH(WIDTH), .K(K)) Lifo (
        .clk        (clk),
        .rst_n      (rst_n),
        .push_sop   (sop_in),
        .push_en    (valid_in),
        .data_in    (data_in),
        .pop_sop    (chien_sop_out),
        .pop_en     (chien_valid_out),

        .valid_out  (lifo_valid_out),
        .data_out   (lifo_data_out)
    );

    // --- 2.
    flop_r_nb #(.WIDTH(WIDTH)) Err_Mag_Delay_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (chien_valid_out),
        .d      (forney_err_mag),
        .q      (err_mag_delay)
    );

    xor_nb #(.WIDTH(WIDTH)) Err_Cor (
        .a  (lifo_data_out),
        .b  (err_mag_delay),
        .y  (data_out)
    );

    // --- 3.
    assign valid_out = lifo_valid_out;
    
    flop_r_nb #(.WIDTH(1)) Sop_Delay_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (1'b1),
        .d      (chien_sop_out),
        .q      (sop_out)
    );

    assign ready = syn_ready & kes_ready & chien_ready;
    assign error = syn_error | kes_error | chien_error;


endmodule:rs_dec




