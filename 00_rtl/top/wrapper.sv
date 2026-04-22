module wrapper
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15,
    parameter K = 544
)
(
    input  logic        CLOCK_50,
    input  logic [9:0]  SW,
    input  logic [3:0]  KEY,

    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR
);

    // Internal Signals
    logic       clk;
    logic       rst_n;
    logic       start_demo;
    logic [2:0] demo_sel;

    logic [9:0] injected_err_cnt;
    logic [9:0] corrected_err_cnt;
    logic       demo_done;
    logic       demo_success;
    logic       demo_fail;

    // --- 1. 
    assign clk          = CLOCK_50;
    assign rst_n        = KEY[0];
    assign start_demo   = KEY[1];
    assign demo_sel     = SW[2:0];

    assign LEDR[2:0]    = demo_sel;
    assign LEDR[9]      = demo_done;
    assign LEDR[8]      = demo_success;
    assign LEDR[7]      = demo_fail;
    assign LEDR[6:3]    = 'b0;   

    led_7s_enc_dec_3d Inj_Err_Cnt_7s_Enc (
        .dec_in     (injected_err_cnt),
        .enc_out_0  (HEX0),
        .enc_out_1  (HEX1),
        .enc_out_2  (HEX2)
    );    

    led_7s_enc_dec_3d Cor_Err_Cnt_7s_Enc (
        .dec_in     (corrected_err_cnt),
        .enc_out_0  (HEX3),
        .enc_out_1  (HEX4),
        .enc_out_2  (HEX5)
    );    

    // --- 2. Top Module ---
    top #(.WIDTH(WIDTH), .NSYM(NSYM), .ORDER(ORDER), .K(K)) top (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_demo     (start_demo),
        .demo_sel       (demo_sel),
        .injected_err_cnt   (injected_err_cnt),
        .corrected_err_cnt  (corrected_err_cnt),
        .demo_done      (demo_done),
        .demo_success   (demo_success),
        .demo_fail      (demo_fail)
    );


    // --- Library of module instantiations for demo ---
        // logic [6:0] cnt_out, cnt_in, cnt_nxt;
        // logic cnt_end;
        // logic [25:0] cnt_itrvl_out, cnt_itrvl_in, cnt_itrvl_nxt;
        // logic itvrl_end;

        // flop_r_nb #(.WIDTH(26)) Cnt_Itrvl_Reg (
        //     .clk    (clk),
        //     .rst_n  (rst_n),
        //     .en     (1'b1),
        //     .d      (cnt_itrvl_in),
        //     .q      (cnt_itrvl_out)
        // );

        // add_sub_nb #(.WIDTH(26)) Cnt_Itrvl_Add (
        //     .a      (cnt_itrvl_out),
        //     .b      (26'd1),
        //     .cin    (1'b0),
        //     .sum    (cnt_itrvl_nxt),
        //     .cout   ()
        // );

        // mux_2_nb #(.WIDTH(26)) Cnt_Itrvl_Mux (
        //     .d0     (cnt_itrvl_nxt),
        //     .d1     (26'd0),
        //     .s      (itvrl_end),
        //     .y      (cnt_itrvl_in)
        // );

        // assign itvrl_end = (cnt_itrvl_out == 26'd50000000);

        // flop_r_nb #(.WIDTH(7)) Cnt_Reg (
        //     .clk    (clk),
        //     .rst_n  (rst_n),
        //     .en     (itvrl_end),
        //     .d      (cnt_in),
        //     .q      (cnt_out)
        // );

        // add_sub_nb #(.WIDTH(7)) Cnt_Add (
        //     .a      (cnt_out),
        //     .b      (7'd1),
        //     .cin    (1'b0),
        //     .sum    (cnt_nxt),
        //     .cout   ()
        // );

        // mux_2_nb #(.WIDTH(7)) Cnt_Mux (
        //     .d0     (cnt_nxt),
        //     .d1     (7'd0),
        //     .s      (cnt_end),
        //     .y      (cnt_in)
        // );

        // assign cnt_end = (cnt_out == 7'd99);

        // led_7s_enc_dec_2d Cnt_7s_Enc (
        //     .dec_in     (cnt_out),
        //     .enc_out_0  (HEX0),
        //     .enc_out_1  (HEX1)
        // );

        // led_7s_enc_pass_fail Pass_Fail_7s_Enc (
        //     .pass       (start_demo),
        //     .enc_out_0  (HEX2),
        //     .enc_out_1  (HEX3),
        //     .enc_out_2  (HEX4),
        //     .enc_out_3  (HEX5)
        // );

        // led_7s_enc_dec_2d Sw_7s_Enc (
        //     .dec_in     (demo_sel[6:0]),
        //     .enc_out_0  (HEX0),
        //     .enc_out_1  (HEX1)
        // );    

        // assign LEDR = demo_sel;
    // -------------------------------------------------

endmodule:wrapper
