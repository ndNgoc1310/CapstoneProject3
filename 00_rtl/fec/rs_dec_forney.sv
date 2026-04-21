module rs_dec_forney
#(
    parameter WIDTH = 10
)
(
    input logic err_flg,
    input logic [WIDTH-1:0] l_val_der,
    input logic [WIDTH-1:0] o_val,

    output logic [WIDTH-1:0] err_mag
);

    // Internal signals
    logic [WIDTH-1:0] l_val_der_inv;
    logic [WIDTH-1:0] err_mag_raw;

    gf_inv L_Val_Der_Inv (
        .x  (l_val_der),
        .y  (l_val_der_inv)
    );

    gf_mul Err_Mag_Mul (
        .a  (l_val_der_inv),
        .b  (o_val),
        .p  (err_mag_raw)
    );

    and_nb #(.WIDTH(WIDTH)) Err_Mag_And (
        .a  (err_mag_raw),
        .b  ({WIDTH{err_flg}}),
        .y  (err_mag)
    );

endmodule:rs_dec_forney
