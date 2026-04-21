module rs_dec_chien
#(
    WIDTH = 10,
    ORDER = 15,
    CNT_WIDTH = 10
)
(
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input logic [WIDTH-1:0] lam_in [ORDER:0],
    input logic [WIDTH-1:0] ome_in [ORDER:0],

    output logic err_flg,
    output logic [WIDTH-1:0] l_val_der,
    output logic [WIDTH-1:0] o_val,
    output logic valid_out,
    output logic ready,
    output logic error
);

    // Internal signals
    logic cnt_end;
    logic init;
    logic reg_en;
    logic cnt_en;


    // --- Submodules ---
    rs_dec_chien_lam #(.WIDTH(WIDTH), .ORDER(ORDER)) CHIEN_LAM (
        .clk        (clk),
        .rst_n      (rst_n),
        .init       (init),
        .reg_en     (reg_en),
        .lam_in     (lam_in),

        .err_flg    (err_flg),
        .l_val_der  (l_val_der)
    );

    rs_dec_chien_ome #(.WIDTH(WIDTH), .ORDER(ORDER)) CHIEN_OME (
        .clk        (clk),
        .rst_n      (rst_n),
        .init       (init),
        .reg_en     (reg_en),
        .ome_in     (ome_in),

        .o_val      (o_val)
    );

    rs_dec_chien_cnt #(.CNT_WIDTH(CNT_WIDTH), .ORDER(ORDER)) CHIEN_CNT (
        .clk        (clk),
        .rst_n      (rst_n),
        .init       (init),
        .cnt_en     (cnt_en),

        .cnt_end    (cnt_end)
    );

    rs_dec_chien_ctrl CHIEN_CTRL (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),
        .cnt_end    (cnt_end),

        .init       (init),
        .reg_en     (reg_en),
        .cnt_en     (cnt_en),
        .valid_out  (valid_out),
        .ready      (ready),
        .error      (error)
    );


endmodule:rs_dec_chien

// --------------------------------------------------------------

module rs_dec_chien_lam
#(
    WIDTH = 10,
    ORDER = 15
)
(
    input logic clk,
    input logic rst_n,
    input logic init,
    input logic reg_en,
    input logic [WIDTH-1:0] lam_in [ORDER:0],

    output logic err_flg,
    output logic [WIDTH-1:0] l_val_der
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] l_val_in [ORDER:0];
    logic [WIDTH-1:0] l_val_out [ORDER:0];
    logic [WIDTH-1:0] l_val_out_mul [ORDER:0];
    logic [WIDTH-1:0] l_val_der_in [(ORDER+1)/2-1:0];
    logic [WIDTH-1:0] l_val;

    // --- 1.
    genvar i;
    generate
        for (i = 0; i < ORDER+1; i = i + 1) begin : GEN_CHIEN_LAM
            mux_2_nb #(.WIDTH(WIDTH)) L_Val_Mux (
                .d0 (l_val_out_mul[i]),
                .d1 (lam_in[i]),
                .s  (init),
                .y  (l_val_in[i])
            );

            flop_r_nb #(.WIDTH(WIDTH)) L_Val_Reg (
                .clk    (clk),
                .rst_n  (rst_n),
                .en     (reg_en),
                .d      (l_val_in[i]),
                .q      (l_val_out[i])
            );
        end
    endgenerate

    assign l_val_out_mul[0] = l_val_out[0];
    gf_mul_const_alpha1  u1  (.a(l_val_out[1]),  .p(l_val_out_mul[1]));
    gf_mul_const_alpha2  u2  (.a(l_val_out[2]),  .p(l_val_out_mul[2]));
    gf_mul_const_alpha3  u3  (.a(l_val_out[3]),  .p(l_val_out_mul[3]));
    gf_mul_const_alpha4  u4  (.a(l_val_out[4]),  .p(l_val_out_mul[4]));
    gf_mul_const_alpha5  u5  (.a(l_val_out[5]),  .p(l_val_out_mul[5]));
    gf_mul_const_alpha6  u6  (.a(l_val_out[6]),  .p(l_val_out_mul[6]));
    gf_mul_const_alpha7  u7  (.a(l_val_out[7]),  .p(l_val_out_mul[7]));
    gf_mul_const_alpha8  u8  (.a(l_val_out[8]),  .p(l_val_out_mul[8]));
    gf_mul_const_alpha9  u9  (.a(l_val_out[9]),  .p(l_val_out_mul[9]));
    gf_mul_const_alpha10 u10 (.a(l_val_out[10]), .p(l_val_out_mul[10]));
    gf_mul_const_alpha11 u11 (.a(l_val_out[11]), .p(l_val_out_mul[11]));
    gf_mul_const_alpha12 u12 (.a(l_val_out[12]), .p(l_val_out_mul[12]));
    gf_mul_const_alpha13 u13 (.a(l_val_out[13]), .p(l_val_out_mul[13]));
    gf_mul_const_alpha14 u14 (.a(l_val_out[14]), .p(l_val_out_mul[14]));
    gf_mul_const_alpha15 u15 (.a(l_val_out[15]), .p(l_val_out_mul[15]));

    // --- 2.
    xor_tree_nb #(.WIDTH(WIDTH), .N(ORDER+1)) L_Val_Xor (
        .in     (l_val_out),
        .out    (l_val)
    );

    assign err_flg = ~|l_val;

    // --- 3.

    genvar j;
    generate 
        for (j = 0; j < (ORDER+1)/2; j = j + 1) begin : GEN_CHIEN_LAM_DER_IN
            assign l_val_der_in[j] = l_val_out[2*j+1];
        end
    endgenerate

    xor_tree_nb #(.WIDTH(WIDTH), .N((ORDER+1)/2)) L_Val_Der_Xor (
        .in     (l_val_der_in),
        .out    (l_val_der)
    );

endmodule:rs_dec_chien_lam

// --------------------------------------------------------------

module rs_dec_chien_ome
#(
    WIDTH = 10,
    ORDER = 15
)
(
    input logic clk,
    input logic rst_n,
    input logic init,
    input logic reg_en,
    input logic [WIDTH-1:0] ome_in [ORDER:0],

    output logic [WIDTH-1:0] o_val
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] o_val_in [ORDER:0];
    logic [WIDTH-1:0] o_val_out [ORDER:0];
    logic [WIDTH-1:0] o_val_out_mul [ORDER:0];

    // --- 1.
    genvar i;
    generate
        for (i = 0; i < ORDER+1; i = i + 1) begin : GEN_CHIEN_LAM
            mux_2_nb #(.WIDTH(WIDTH)) O_Val_Mux (
                .d0 (o_val_out_mul[i]),
                .d1 (ome_in[i]),
                .s  (init),
                .y  (o_val_in[i])
            );

            flop_r_nb #(.WIDTH(WIDTH)) O_Val_Reg (
                .clk    (clk),
                .rst_n  (rst_n),
                .en     (reg_en),
                .d      (o_val_in[i]),
                .q      (o_val_out[i])
            );
        end
    endgenerate

    assign o_val_out_mul[0] = o_val_out[0];
    gf_mul_const_alpha1  u1  (.a(o_val_out[1]),  .p(o_val_out_mul[1]));
    gf_mul_const_alpha2  u2  (.a(o_val_out[2]),  .p(o_val_out_mul[2]));
    gf_mul_const_alpha3  u3  (.a(o_val_out[3]),  .p(o_val_out_mul[3]));
    gf_mul_const_alpha4  u4  (.a(o_val_out[4]),  .p(o_val_out_mul[4]));
    gf_mul_const_alpha5  u5  (.a(o_val_out[5]),  .p(o_val_out_mul[5]));
    gf_mul_const_alpha6  u6  (.a(o_val_out[6]),  .p(o_val_out_mul[6]));
    gf_mul_const_alpha7  u7  (.a(o_val_out[7]),  .p(o_val_out_mul[7]));
    gf_mul_const_alpha8  u8  (.a(o_val_out[8]),  .p(o_val_out_mul[8]));
    gf_mul_const_alpha9  u9  (.a(o_val_out[9]),  .p(o_val_out_mul[9]));
    gf_mul_const_alpha10 u10 (.a(o_val_out[10]), .p(o_val_out_mul[10]));
    gf_mul_const_alpha11 u11 (.a(o_val_out[11]), .p(o_val_out_mul[11]));
    gf_mul_const_alpha12 u12 (.a(o_val_out[12]), .p(o_val_out_mul[12]));
    gf_mul_const_alpha13 u13 (.a(o_val_out[13]), .p(o_val_out_mul[13]));
    gf_mul_const_alpha14 u14 (.a(o_val_out[14]), .p(o_val_out_mul[14]));
    gf_mul_const_alpha15 u15 (.a(o_val_out[15]), .p(o_val_out_mul[15]));

    // --- 2.
    xor_tree_nb #(.WIDTH(WIDTH), .N(ORDER+1)) O_Val_Xor (
        .in     (o_val_out),
        .out    (o_val)
    );

endmodule:rs_dec_chien_ome

// --------------------------------------------------------------

module rs_dec_chien_cnt
#(
    CNT_WIDTH = 10,
    ORDER = 15
)
(
    input logic clk,
    input logic rst_n,
    input logic init,
    input logic cnt_en,

    output logic cnt_end    
);

    // Internal signals
    logic [CNT_WIDTH-1:0] cnt_in;
    logic [CNT_WIDTH-1:0] cnt_out;
    logic [CNT_WIDTH-1:0] cnt_nxt;

    // --- 1.
    add_sub_nb #(.WIDTH(CNT_WIDTH)) Cnt_Add (
        .a      (cnt_out),
        .b      (CNT_WIDTH'('d1)),
        .cin    (1'b0),
        .sum    (cnt_nxt),
        .cout   ()
    );

    mux_2_nb #(.WIDTH(CNT_WIDTH)) Cnt_Mux (
        .d0 (cnt_nxt),
        .d1 (CNT_WIDTH'('d0)),
        .s  (init),
        .y  (cnt_in)
    );

    flop_r_nb #(.WIDTH(CNT_WIDTH)) Cnt_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (cnt_en),
        .d      (cnt_in),
        .q      (cnt_out)
    );

    // --- 2.
    assign cnt_end = &{cnt_out[9], cnt_out[4:0]};

endmodule:rs_dec_chien_cnt

// --------------------------------------------------------------

module rs_dec_chien_ctrl
(
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input logic cnt_end,

    output logic init,
    output logic reg_en,
    output logic cnt_en,
    output logic valid_out,
    output logic ready,
    output logic error
);

    // Định nghĩa các trạng thái của FSM
    typedef enum logic [2:0] {
        IDLE,   
        INIT,   
        CALC,   
        DONE,   
        ERROR   
    } state_t;

    state_t state_current, state_next; 

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_current)
            IDLE: begin
                init        = 1'b0;
                reg_en      = 1'b0;
                cnt_en      = 1'b0;
                valid_out   = 1'b0;
                ready       = 1'b1;  
                error       = 1'b0; 
            end

            INIT: begin
                init        = 1'b1;
                reg_en      = 1'b1;
                cnt_en      = 1'b1;
                valid_out   = 1'b0;
                ready       = 1'b0;  
                error       = 1'b0; 
            end

            CALC: begin
                init        = 1'b0;
                reg_en      = 1'b1;
                cnt_en      = 1'b1;
                valid_out   = 1'b1;
                ready       = 1'b0;  
                error       = 1'b0; 
            end

            DONE: begin
                init        = 1'b0;
                reg_en      = 1'b0;
                cnt_en      = 1'b0;
                valid_out   = 1'b0; 
                ready       = 1'b1;  
                error       = 1'b0; 
            end

            ERROR: begin
                init        = 1'b0;
                reg_en      = 1'b0;
                cnt_en      = 1'b0;
                valid_out   = 1'b0; 
                ready       = 1'b1;  
                error       = 1'b1; 
            end

            default: begin
                init        = 1'b0;
                reg_en      = 1'b0;
                cnt_en      = 1'b0;
                valid_out   = 1'b0; 
                ready       = 1'b1;  
                error       = 1'b1; 
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (state_current)
                IDLE: begin
                    if (valid_in)   state_next = INIT;
                    else            state_next = IDLE;
                end

                INIT: begin
                    if (~valid_in)  state_next = CALC;
                    else            state_next = ERROR;
                end

                CALC: begin
                    if (~valid_in & cnt_end)        state_next = DONE;
                    else if (~valid_in & ~cnt_end)  state_next = CALC;
                    else                            state_next = ERROR;
                end

                DONE: begin
                    if (valid_in)   state_next = INIT;
                    else            state_next = IDLE;
                end

                ERROR: begin
                    if (valid_in)   state_next = INIT;
                    else            state_next = IDLE;
                end

                default: begin
                    state_next = ERROR;
                end
        endcase
    end    

    // --- 3. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_current <= IDLE;  
        end
        else begin
            state_current <= state_next;   
        end
    end    
    
endmodule:rs_dec_chien_ctrl

