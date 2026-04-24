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
    input  logic clk,
    input  logic rst_n,
    
    // --- Encoder Interface ---
    input  logic enc_sop_in,
    input  logic enc_valid_in,
    input  logic [WIDTH-1:0] enc_data_in,
    
    output logic enc_sop_out,
    output logic enc_valid_out,
    output logic [WIDTH-1:0] enc_data_out,
    output logic enc_ready,
    output logic enc_error,
    
    // --- Decoder Interface ---
    input  logic dec_sop_in,
    input  logic dec_valid_in,
    input  logic [WIDTH-1:0] dec_data_in,
    
    output logic dec_sop_out,
    output logic dec_valid_out,
    output logic [WIDTH-1:0] dec_data_out,
    output logic dec_ready,
    output logic dec_error,

    // --- Error Monitoring Interface ---
    output logic dec_err_flg_out,               // Nối từ Chien Search
    output logic [WIDTH-1:0] dec_err_mag_out    // Nối từ Forney
);

    // Instantiate Encoder
    rs_enc #(
        .WIDTH(WIDTH), 
        .NSYM(NSYM)
    ) Encoder (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (enc_sop_in),
        .valid_in   (enc_valid_in),
        .data_in    (enc_data_in),
        .sop_out    (enc_sop_out),
        .valid_out  (enc_valid_out),
        .data_out   (enc_data_out),
        .ready      (enc_ready),
        .error      (enc_error)
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
        .valid_in       (dec_valid_in),
        .data_in        (dec_data_in),
        .sop_out        (dec_sop_out),
        .valid_out      (dec_valid_out),
        .data_out       (dec_data_out),
        .ready          (dec_ready),
        .error          (dec_error),
        .err_flg_out    (dec_err_flg_out),
        .err_mag_out    (dec_err_mag_out) 
    );

endmodule:top
