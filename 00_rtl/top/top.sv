// =========================================================
// Project: Reed-Solomon Codec Demo on DE10-Standard
// Module: top.sv
// Function: End-to-end RS(544, 514) Demo with Error Injection
// =========================================================

module top
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15,
    parameter K = 544
)
(
    input  logic                clk,
    input  logic                rst_n,
    
    // --- Encoder Interface ---
    input  logic                enc_sop_in,
    input  logic                enc_vld_in,
    input  logic [WIDTH-1:0]    enc_dat_in,
    
    output logic                enc_sop_out,
    output logic                enc_vld_out,
    output logic [WIDTH-1:0]    enc_dat_out,
    output logic                enc_rdy,
    output logic                enc_err,
    
    // --- Decoder Interface ---
    input  logic                dec_sop_in,
    input  logic                dec_vld_in,
    input  logic [WIDTH-1:0]    dec_dat_in,
    
    output logic                dec_sop_out,
    output logic                dec_vld_out,
    output logic [WIDTH-1:0]    dec_dat_out,
    output logic                dec_rdy,
    output logic                dec_err,

    // --- Error Monitoring Interface ---
    output logic                dec_err_flg_out,    // Nối từ Chien Search
    output logic [WIDTH-1:0]    dec_err_mag_out     // Nối từ Forney
);

    // Instantiate Encoder
    rs_enc #(
        .WIDTH(WIDTH), 
        .NSYM(NSYM)
    ) Encoder (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (enc_sop_in),
        .vld_in     (enc_vld_in),
        .dat_in     (enc_dat_in),
        .sop_out    (enc_sop_out),
        .vld_out    (enc_vld_out),
        .dat_out    (enc_dat_out),
        .sys_rdy    (enc_rdy),
        .sys_err    (enc_err)
    );

    // Instantiate Decoder
    rs_dec #(
        .WIDTH(WIDTH), 
        .NSYM(NSYM), 
        .ORDER(ORDER), 
        .K(K)
    ) Decoder (
        .clk            (clk),
        .rst_n          (rst_n),
        .sop_in         (dec_sop_in),
        .vld_in         (dec_vld_in),
        .dat_in         (dec_dat_in),
        .sop_out        (dec_sop_out),
        .vld_out        (dec_vld_out),
        .dat_out        (dec_dat_out),
        .sys_rdy        (dec_rdy),
        .sys_err        (dec_err),
        .err_flg_out    (dec_err_flg_out),
        .err_mag_out    (dec_err_mag_out) 
    );

endmodule: top
