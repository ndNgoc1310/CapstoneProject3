module wrapper
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15,
    parameter K = 544
)
(
    input  logic CLOCK_50,
    input  logic [9:0] SW,
    input  logic [3:0] KEY,

    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    logic clk;
    logic rst_n;
    // logic sop_in;
    // logic valid_in;
    // logic [WIDTH-1:0] data_in;

    // logic sop_out;
    // logic valid_out;
    // logic [WIDTH-1:0] data_out;
    // logic ready;
    // logic error;

    // top #(.WIDTH(WIDTH), .NSYM(NSYM), .ORDER(ORDER), .K(K)) Top (
    //     .clk        (clk),
    //     .rst_n      (rst_n),
    //     .sop_in     (sop_in),
    //     .valid_in   (valid_in),
    //     .data_in    (data_in),

    //     .sop_out    (sop_out),
    //     .valid_out  (valid_out),
    //     .data_out   (data_out),
    //     .ready      (ready),
    //     .error      (error)
    // );

    assign clk = CLOCK_50;
    assign rst_n = ~KEY[0];
    assign sop_in = KEY[1];

    // ---------------------------
    logic [6:0] cnt_out, cnt_in, cnt_nxt;
    logic cnt_end;
    logic [25:0] cnt_itrvl_out, cnt_itrvl_in, cnt_itrvl_nxt;
    logic itvrl_end;

    flop_r_nb #(.WIDTH(25)) Cnt_Itrvl_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (1'b1),
        .d      (cnt_itrvl_in),
        .q      (cnt_itrvl_out)
    );

    add_sub_nb #(.WIDTH(25)) Cnt_Itrvl_Add (
        .a      (cnt_itrvl_out),
        .b      (25'd1),
        .cin    (1'b0),
        .y      (cnt_itrvl_nxt)
    );

    mux_2_nb #(.WIDTH(25)) Cnt_Itrvl_Mux (
        .d0     (cnt_itrvl_nxt),
        .d1     (25'd0),
        .s      (itvrl_end),
        .y      (cnt_itrvl_in)
    );

    assign itvrl_end = (cnt_itrvl_out == 25'd50000000);

    flop_r_nb #(.WIDTH(7)) Cnt_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (itvrl_end),
        .d      (cnt_in),
        .q      (cnt_out)
    );

    add_sub_nb #(.WIDTH(7)) Cnt_Add (
        .a      (cnt_out),
        .b      (7'd1),
        .cin    (1'b0),
        .y      (cnt_nxt)
    );

    mux_2_nb #(.WIDTH(7)) Cnt_Mux (
        .d0     (cnt_nxt),
        .d1     (7'd0),
        .s      (cnt_end),
        .y      (cnt_in)
    );

    assign cnt_end = (cnt_out == 7'd99);

    led_7s_enc_dec_2d Cnt_7s_Enc (
        .dec_in     (cnt_out),
        .enc_out_0  (HEX0),
        .enc_out_1  (HEX1)
    );

endmodule:wrapper
