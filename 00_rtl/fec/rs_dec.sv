module rs_dec
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15,
    parameter K = 544
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             sop_in,
    input logic             vld_in,
    input logic [WIDTH-1:0] dat_in,

    output logic                sop_out,
    output logic                vld_out,
    output logic [WIDTH-1:0]    dat_out,
    output logic                sys_rdy,
    output logic                sys_err,

    // --- Error Monitoring Interface ---
    output logic                err_flg_out,    // Nối từ Chien Search
    output logic [WIDTH-1:0]    err_mag_out     // Nối từ Forney
);

    // Internal signals
    logic               syn_to_kes_valid;
    logic [WIDTH-1:0]   syn_to_kes_syn [NSYM-1:0];

    logic               kes_to_chien_valid;
    logic [WIDTH-1:0]   kes_to_chien_lam [ORDER:0];
    logic [WIDTH-1:0]   kes_to_chien_ome [ORDER:0];
    logic [4:0]         kes_to_chien_len;

    logic               chien_sop_out;
    logic               chien_vld_out;
    logic               chien_to_forney_err_flg;
    logic [WIDTH-1:0]   chien_to_forney_l_val_der;
    logic [WIDTH-1:0]   chien_to_forney_o_val;

    logic [WIDTH-1:0]   forney_err_mag;

    logic               lifo_vld_out;
    logic [WIDTH-1:0]   lifo_dat_out;

    logic               syn_rdy, kes_rdy, chien_rdy;
    logic               syn_err, kes_err, chien_err;

    logic [WIDTH-1:0]   err_mag_delay;
    logic               sop_out_delay;
    logic               err_flg_delay;

    // --- 1. Submodules

    rs_dec_syn #(.WIDTH(WIDTH), .NSYM(NSYM)) Syn (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .vld_in     (vld_in),
        .dat_in     (dat_in),

        .vld_out    (syn_to_kes_valid),
        .syn_out    (syn_to_kes_syn),

        .sys_rdy    (syn_rdy),
        .sys_err    (syn_err)
    );
    
    rs_dec_kes #(.WIDTH(WIDTH), .NSYM(NSYM), .ORDER(ORDER), .CNT_WIDTH(5)) Kes (
        .clk        (clk),
        .rst_n      (rst_n),
        .vld_in     (syn_to_kes_valid),
        .syn_in     (syn_to_kes_syn),

        .vld_out    (kes_to_chien_valid),
        .lam_out    (kes_to_chien_lam),
        .ome_out    (kes_to_chien_ome),

        .len_out    (kes_to_chien_len),

        .sys_rdy    (kes_rdy),
        .sys_err    (kes_err)
    );

    rs_dec_chien #(.WIDTH(WIDTH), .ORDER(ORDER), .CNT_WIDTH(10)) Chien (
        .clk        (clk),
        .rst_n      (rst_n),
        .vld_in     (kes_to_chien_valid),
        .lam_in     (kes_to_chien_lam),
        .ome_in     (kes_to_chien_ome),

        .len_in     (kes_to_chien_len),

        .sop_out    (chien_sop_out),
        .vld_out    (chien_vld_out),
        .err_flg    (chien_to_forney_err_flg),
        .l_val_der  (chien_to_forney_l_val_der),
        .o_val      (chien_to_forney_o_val),

        .sys_rdy    (chien_rdy),
        .sys_err    (chien_err)
    );

    rs_dec_forney #(.WIDTH(WIDTH)) Forney (
        .err_flg    (chien_to_forney_err_flg),
        .l_val_der  (chien_to_forney_l_val_der),
        .o_val      (chien_to_forney_o_val),

        .err_mag    (forney_err_mag)
    );

    rs_dec_lifo #(.WIDTH(WIDTH), .K(K)) Lifo (
        .clk        (clk),
        .rst_n      (rst_n),
        .push_sop   (sop_in),
        .push_en    (vld_in),
        .dat_in     (dat_in),
        .pop_sop    (chien_sop_out),
        .pop_en     (chien_vld_out),

        .vld_out    (lifo_vld_out),
        .dat_out    (lifo_dat_out)
    );

    // --- 2. Delay
    flop_r_nb #(.WIDTH(WIDTH)) Err_Mag_Delay_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (chien_vld_out),
        .d      (forney_err_mag),
        .q      (err_mag_delay)
    );
    
    flop_r_nb #(.WIDTH(1)) Sop_Delay_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (chien_vld_out),
        .d      (chien_sop_out),
        .q      (sop_out_delay)
    );

    flop_r_nb #(.WIDTH(1)) Err_Flg_Delay_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (chien_vld_out), 
        .d      (chien_to_forney_err_flg),
        .q      (err_flg_delay)
    );

    // --- 3. Error Correction
    xor_nb #(.WIDTH(WIDTH)) Err_Cor (
        .a  (lifo_dat_out),
        .b  (err_mag_delay),
        .y  (dat_out)
    );

    // --- 4.
    assign vld_out = lifo_vld_out;
    assign sop_out = sop_out_delay;
    assign sys_rdy = syn_rdy & kes_rdy & chien_rdy;
    assign sys_err = syn_err | kes_err | chien_err;

    // --- Error Monitoring Interface ---
    assign err_flg_out = err_flg_delay;
    assign err_mag_out = err_mag_delay;
    
endmodule: rs_dec




