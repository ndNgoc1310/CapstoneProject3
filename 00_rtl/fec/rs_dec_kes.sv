// rs_dec_kes.sv

module rs_dec_kes
#(
    parameter WIDTH = 10,
    parameter ORDER = 15,
    parameter NSYM = 30,
    parameter CNT_WIDTH = 5
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             vld_in,
    input logic [WIDTH-1:0] syn_in [NSYM-1:0],

    output logic                    vld_out,
    output logic                    sys_rdy,
    output logic                    sys_err,
    output logic [WIDTH-1:0]        lam_out [ORDER:0],
    output logic [WIDTH-1:0]        ome_out [ORDER:0],
    output logic [CNT_WIDTH-1:0]    len_out
);

    // Internal signals
    logic [WIDTH-1:0]   syn_wdw [ORDER:0];
    logic [WIDTH-1:0]   dis_out;
    logic [WIDTH-1:0]   gam_out;
    logic               delta;
    logic               cnt_end;
    logic               init;
    logic               reg_en;

    // --- Submodule Instantiations ---
    rs_dec_kes_lam #(.WIDTH(WIDTH), .ORDER(ORDER)) Lam_Dpath (
        .clk        (clk),
        .rst_n      (rst_n),
        .delta      (delta),
        .init       (init),
        .reg_en     (reg_en),
        .dis_out    (dis_out),
        .gam_out    (gam_out),

        .lam_out    (lam_out)
    );

    rs_dec_kes_ome #(.WIDTH(WIDTH), .ORDER(ORDER), .NSYM(NSYM)) Ome_Dpath (
        .clk        (clk),
        .rst_n      (rst_n),
        .delta      (delta),
        .init       (init),
        .reg_en     (reg_en),
        .dis_out    (dis_out),
        .gam_out    (gam_out),
        .syn_in     (syn_in),

        .ome_out    (ome_out)
    );

    rs_dec_kes_wdw #(.WIDTH(WIDTH), .ORDER(ORDER), .NSYM(NSYM)) Syn_Wdw (
        .clk        (clk),
        .rst_n      (rst_n),
        .init       (init),
        .reg_en     (reg_en),
        .syn_in     (syn_in),

        .syn_wdw    (syn_wdw)
    );

    rs_dec_kes_dis #(.WIDTH(WIDTH), .ORDER(ORDER)) Dis_Calc (
        .lam_out    (lam_out),
        .syn_wdw    (syn_wdw),

        .dis_out    (dis_out)
    );

    rs_dec_kes_gam #(.WIDTH(WIDTH)) Gam_Dpath (
        .clk        (clk),
        .rst_n      (rst_n),
        .delta      (delta),
        .init       (init),
        .dis_out    (dis_out),

        .gam_out    (gam_out)
    );

    rs_dec_kes_br #(.WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH)) Br_Unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .init       (init),
        .reg_en     (reg_en),
        .dis_out    (dis_out),

        .len_out    (len_out),
        .delta      (delta),
        .cnt_end    (cnt_end)
    );

    rs_dec_kes_ctrl Ctrl_Unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .vld_in     (vld_in),
        .cnt_end    (cnt_end),

        .init       (init),
        .reg_en     (reg_en),
        .vld_out    (vld_out),
        .sys_rdy    (sys_rdy),
        .sys_err    (sys_err)
    );

endmodule: rs_dec_kes

// ------------------------------------------

module rs_dec_kes_lam 
#(
    parameter WIDTH = 10,
    parameter ORDER = 15
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             delta,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] dis_out,
    input logic [WIDTH-1:0] gam_out,

    output logic [WIDTH-1:0]    lam_out [ORDER:0]
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] l_aux_out [ORDER:0];

    genvar i;
    generate
        for (i=0; i<ORDER+1; i++) begin : LAM_PE_GEN
            rs_dec_kes_lam_pe_i Lam_PE (
                .clk            (clk),
                .rst_n          (rst_n),
                .delta          (delta),
                .init           (init),
                .reg_en         (reg_en),
                .dis_out        (dis_out),
                .gam_out        (gam_out),
                .lam_out_prv    (i == 0 ? WIDTH'('d0) : lam_out[i-1]),
                .l_aux_out_prv  (i == 0 ? WIDTH'('d0) : l_aux_out[i-1]),
                .is_pe_0        (i == 0),
                .is_pe_1        (i == 1),

                .lam_out        (lam_out[i]),
                .l_aux_out      (l_aux_out[i])
            );
        end
    endgenerate

endmodule: rs_dec_kes_lam

// ------------------------------------------

module rs_dec_kes_ome 
#(
    parameter WIDTH = 10,
    parameter NSYM = 30,
    parameter ORDER = 15
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             delta,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] dis_out,
    input logic [WIDTH-1:0] gam_out,
    input logic [WIDTH-1:0] syn_in [NSYM-1:0],

    output logic [WIDTH-1:0]    ome_out [ORDER:0]
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] o_aux_out [ORDER:0];

    genvar i;
    generate
        for (i=0; i<ORDER+1; i++) begin : LAM_PE_GEN
            rs_dec_kes_ome_pe_i Ome_PE (
                .clk            (clk),
                .rst_n          (rst_n),
                .delta          (delta),
                .init           (init),
                .reg_en         (reg_en),
                .dis_out        (dis_out),
                .gam_out        (gam_out),
                .syn_in         (syn_in[i]),
                .syn_in_prv     (i == 0 ? WIDTH'('d0) : syn_in[i-1]),
                .ome_out_prv    (i == 0 ? WIDTH'('b0) : ome_out[i-1]),
                .o_aux_out_prv  (i == 0 ? WIDTH'('b0) : o_aux_out[i-1]),
                .is_pe_0        (i == 0),

                .ome_out        (ome_out[i]),
                .o_aux_out      (o_aux_out[i])
            );
        end
    endgenerate

endmodule: rs_dec_kes_ome

// ------------------------------------------

module rs_dec_kes_gam 
#(
    parameter WIDTH = 10
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             delta,
    input logic             init,
    input logic [WIDTH-1:0] dis_out,

    output logic [WIDTH-1:0]    gam_out
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] gam_in;

    mux_2_nb #(.WIDTH(WIDTH)) Gam_Mux (
        .d0 (dis_out),
        .d1 (WIDTH'('d1)),
        .s  (init),
        .y  (gam_in)
    );

    flop_r_nb #(.WIDTH(WIDTH)) Gam_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (init | delta), 
        .d      (gam_in),
        .q      (gam_out)
    );

endmodule: rs_dec_kes_gam

// ------------------------------------------

module rs_dec_kes_wdw 
#(
    parameter WIDTH = 10,
    parameter ORDER = 15,
    parameter NSYM = 30
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] syn_in [NSYM-1:0],

    output logic [WIDTH-1:0]    syn_wdw [ORDER:0]
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] syn_buf_in [NSYM-1:0];
    logic [WIDTH-1:0] syn_buf_out [NSYM-1:0];   
    logic [WIDTH-1:0] syn_wdw_in [ORDER:0];
    logic [WIDTH-1:0] syn_wdw_out [ORDER:0];

    // --- 1.
    genvar i;
    generate
        for (i=0; i<NSYM; i++) begin : SYN_BUF_GEN
            mux_2_nb #(.WIDTH(WIDTH)) Buf_Mux (
                .d0 (i == (NSYM - 1) ? WIDTH'('d0) : syn_buf_out[i+1]),
                .d1 (syn_in[i]),
                .s  (init),
                .y  (syn_buf_in[i])
            );

            flop_r_nb #(.WIDTH(WIDTH)) Buf_Reg (
                .clk    (clk),
                .rst_n  (rst_n),
                .en     (reg_en),
                .d      (syn_buf_in[i]),
                .q      (syn_buf_out[i])
            );
        end
    endgenerate

    // --- 2.
    genvar j;
    generate
        for (j=0; j<ORDER+1; j++) begin : SYN_WDW_GEN
            if (j == 0) begin
                mux_2_nb #(.WIDTH(WIDTH)) Wdw_Mux (
                    .d0 (syn_buf_out[1]),
                    .d1 (syn_in[0]),
                    .s  (init),
                    .y  (syn_wdw_in[0])
                );
            end
            else begin
                mux_2_nb #(.WIDTH(WIDTH)) Wdw_Mux (
                    .d0 (syn_wdw_out[j-1]),
                    .d1 (WIDTH'('d0)),
                    .s  (init),
                    .y  (syn_wdw_in[j])
                );
            end

            flop_r_nb #(.WIDTH(WIDTH)) Wdw_Reg (
                .clk    (clk),
                .rst_n  (rst_n),
                .en     (reg_en),
                .d      (syn_wdw_in[j]),
                .q      (syn_wdw_out[j])
            );
        end
    endgenerate

    assign syn_wdw = syn_wdw_out;

endmodule: rs_dec_kes_wdw

// ------------------------------------------

module rs_dec_kes_dis 
#(
    parameter WIDTH = 10,
    parameter ORDER = 15
)
(
    input logic [WIDTH-1:0] syn_wdw [ORDER:0],
    input logic [WIDTH-1:0] lam_out [ORDER:0],

    output logic [WIDTH-1:0] dis_out
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] dis_in [ORDER:0];

    genvar i;
    generate
        for (i=0; i<ORDER+1; i++) begin : DIS_GEN
            gf_mul Dis_Mul (
                .a  (lam_out[i]),
                .b  (syn_wdw[i]),
                .p  (dis_in[i])
            );
        end
    endgenerate

    xor_tree_nb #(.WIDTH(WIDTH), .N(ORDER+1)) Dis_Xor (
        .in     (dis_in),
        .out    (dis_out)
    );
    
endmodule: rs_dec_kes_dis

// ------------------------------------------

module rs_dec_kes_br
#(
    parameter WIDTH = 10,
    parameter CNT_WIDTH = 5
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] dis_out,

    output logic [CNT_WIDTH-1:0]    len_out,
    output logic                    delta,
    output logic                    cnt_end
);
    
    // --- Internal Signals ---
    logic [CNT_WIDTH-1:0]   cnt_nxt;
    logic [CNT_WIDTH-1:0]   cnt_in;
    logic [CNT_WIDTH-1:0]   cnt_out;
    logic [CNT_WIDTH-1:0]   len_in;
    logic [CNT_WIDTH-1:0]   len_nxt;
    logic [CNT_WIDTH-1:0]   len_mux;
    logic                   len_ge;
    logic                   len_lte;
    logic                   dis_neq_0;

    // --- 1. 
    add_sub_nb #(.WIDTH(CNT_WIDTH)) Len_Sub (
        .a      (cnt_nxt),
        .b      (len_out),   
        .cin    (1'b1),
        .sum    (len_nxt),
        .cout   ()                      
    );

    mux_2_nb #(.WIDTH(CNT_WIDTH)) Len_Mux_1 (
        .d0 (len_out),
        .d1 (len_nxt), 
        .s  (delta),
        .y  (len_mux)
    );

    and_nb #(.WIDTH(CNT_WIDTH)) Len_Mux_2 (
        .a  (len_mux),
        .b  ({(CNT_WIDTH){~init}}),
        .y  (len_in)
    );

    flop_r_nb #(.WIDTH(CNT_WIDTH)) Len_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (len_in),
        .q      (len_out)
    );

    // --- 2.
    add_sub_nb #(.WIDTH(CNT_WIDTH)) Cnt_Add (
        .a      (cnt_out),
        .b      (CNT_WIDTH'('d1)),   
        .cin    (1'b0),
        .sum    (cnt_nxt),
        .cout   ()                      
    ); 

    and_nb #(.WIDTH(CNT_WIDTH)) Cnt_Mux (
        .a  (cnt_nxt),
        .b  ({(CNT_WIDTH){~init}}),
        .y  (cnt_in)
    );

    flop_r_nb #(.WIDTH(CNT_WIDTH)) Cnt_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (cnt_in),
        .q      (cnt_out)
    );

    // --- 3.
    add_sub_nb #(.WIDTH(CNT_WIDTH+1)) Compare (
        .a      ({1'b0, cnt_out}),  
        .b      ({len_out, 1'b0}),   
        .cin    (1'b1),
        .sum    (),
        .cout   (len_ge)                      
    );
    assign len_lte = ~len_ge; // len_lte = 1 khi cnt_out <= len_out
    assign cnt_end = cnt_out[4] & cnt_out[3] & cnt_out[2] & cnt_out[0]; // Đếm tới 29 rồi chuyển sang state DONE thực hiện chu kỳ cuối cùng, do state INIT (ảo) làm trễ 1 chu kỳ
    assign dis_neq_0 = |dis_out;
    assign delta = dis_neq_0 & len_lte;

endmodule: rs_dec_kes_br

// ------------------------------------------

module rs_dec_kes_ctrl
(
    input logic clk,
    input logic rst_n,
    input logic vld_in,
    input logic cnt_end,

    output logic init,
    output logic reg_en,
    output logic vld_out,
    output logic sys_rdy,
    output logic sys_err
);

    // Định nghĩa các trạng thái của FSM
    typedef enum logic [1:0] {
        IDLE,   
        CALC,   
        DONE,   
        ERROR   
    } state_t;

    state_t state_cur, state_nxt; 

    // --- 1. FSM State Output Logic ---
    always_comb begin
        case (state_cur)
            IDLE: begin
                // Mealy Action: Bắt tín hiệu và nạp data NGAY LẬP TỨC ở nhịp có vld_in, nhưng do tại chu kỳ đầu, init = 1, tức là thanh ghi nạp giá trị khởi tạo, phải đến chu kỳ thứ hai mới thực sự nạp data vào, tổng thể trễ 1 chu kỳ so với các khối khác
                init    = vld_in ? 1'b1 : 1'b0;
                reg_en  = vld_in ? 1'b1 : 1'b0;
                vld_out = 1'b0;
                sys_rdy = vld_in ? 1'b0 : 1'b1;
                sys_err = 1'b0;
            end

            CALC: begin
                init    = 1'b0;
                reg_en  = 1'b1;
                vld_out = 1'b0;
                sys_rdy = 1'b0;  
                sys_err = 1'b0; 
            end

            DONE: begin 
                init    = 1'b0;
                reg_en  = 1'b1; // Giữ enable để reset counter  
                vld_out = 1'b1; 
                sys_rdy = 1'b1;  
                sys_err = 1'b0; 
            end

            ERROR: begin
                // Mealy Action: Bắt tín hiệu và nạp data NGAY LẬP TỨC giống IDLE
                // Nhưng vẫn giữ cờ sys_err = 1 để hệ thống biết nó vừa thoát từ trạng thái lỗi
                init    = vld_in ? 1'b1 : 1'b0;
                reg_en  = vld_in ? 1'b1 : 1'b0;
                vld_out = 1'b0;
                sys_rdy = vld_in ? 1'b0 : 1'b1; 
                sys_err = 1'b1; // Vẫn giữ 1'b1 ở nhịp này
            end

            default: begin // ERROR
                // Mealy Action: Bắt tín hiệu và nạp data NGAY LẬP TỨC giống IDLE
                // Nhưng vẫn giữ cờ sys_err = 1 để hệ thống biết nó vừa thoát từ trạng thái lỗi
                init    = vld_in ? 1'b1 : 1'b0;
                reg_en  = vld_in ? 1'b1 : 1'b0;
                vld_out = 1'b0;
                sys_rdy = vld_in ? 1'b0 : 1'b1; 
                sys_err = 1'b1; // Vẫn giữ 1'b1 ở nhịp này
            end
        endcase
    end

    // --- 2. FSM State Transition Logic ---
    always_comb begin
        case (state_cur)
                IDLE: begin
                    if (vld_in) state_nxt = CALC;
                    else        state_nxt = IDLE;
                end

                CALC: begin
                    if (~vld_in & cnt_end)          state_nxt = DONE;
                    else if (~vld_in & ~cnt_end)    state_nxt = CALC;
                    else                            state_nxt = ERROR;
                end

                DONE: begin
                    if (~vld_in)    state_nxt = IDLE;
                    else            state_nxt = ERROR;
                end

                ERROR: begin
                    if (vld_in) state_nxt = CALC;
                    else        state_nxt = IDLE;
                end

                default: begin
                    state_nxt = ERROR;
                end
        endcase
    end

    // --- 3. FSM State Register Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_cur <= IDLE;  
        end
        else begin
            state_cur <= state_nxt;   
        end
    end    

endmodule: rs_dec_kes_ctrl

// ------------------------------------------

module rs_dec_kes_lam_pe_i 
#(
    parameter WIDTH = 10
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             delta,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] dis_out,
    input logic [WIDTH-1:0] gam_out,
    input logic [WIDTH-1:0] lam_out_prv,
    input logic [WIDTH-1:0] l_aux_out_prv,
    input logic             is_pe_0,
    input logic             is_pe_1,

    output logic [WIDTH-1:0]    lam_out,
    output logic [WIDTH-1:0]    l_aux_out
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] lam_in;
    logic [WIDTH-1:0] lam_new;
    logic [WIDTH-1:0] lam_mul_1;
    logic [WIDTH-1:0] lam_mul_2;
    logic [WIDTH-1:0] lam_mul_xor;
    logic [WIDTH-1:0] l_aux_mux_1;
    logic [WIDTH-1:0] l_aux_mux_2;
    logic [WIDTH-1:0] l_aux_in;

    // --- 1. Lambda Register ---
    mux_2_nb #(.WIDTH(WIDTH)) Lam_Mux (
        .d0 (lam_new),
        .d1 ({(WIDTH-1)'('b0), is_pe_0}),
        .s  (init),
        .y  (lam_in)
    );

    flop_r_nb #(.WIDTH(WIDTH)) Lam_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (lam_in),
        .q      (lam_out)
    );

    // --- 2. New Lambda Calculation ---
    gf_mul Lam_Mul_1 (
        .a  (lam_out),
        .b  (gam_out),
        .p  (lam_mul_1)
    );

    gf_mul Lam_Mul_2 (
        .a  (l_aux_out),
        .b  (dis_out),
        .p  (lam_mul_2)
    );

    xor_nb #(.WIDTH(WIDTH)) Lam_Xor (
        .a  (lam_mul_1),
        .b  (lam_mul_2),
        .y  (lam_mul_xor)
    );

    assign lam_new = is_pe_0 ? lam_mul_1 : lam_mul_xor;

    // --- 3.
    mux_2_nb #(.WIDTH(WIDTH)) L_Aux_Mux_1 (
        .d0 (l_aux_out_prv),
        .d1 (lam_out_prv),
        .s  (delta),
        .y  (l_aux_mux_1)
    );

    mux_2_nb #(.WIDTH(WIDTH)) L_Aux_Mux_2 (
        .d0 (l_aux_mux_1),
        .d1 ({(WIDTH-1)'('b0), is_pe_1}),
        .s  (init),
        .y  (l_aux_mux_2)
    );

    assign l_aux_in = is_pe_0 ? WIDTH'('d0) : l_aux_mux_2;

    flop_r_nb #(.WIDTH(WIDTH)) L_Aux_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (l_aux_in),
        .q      (l_aux_out)
    );

endmodule: rs_dec_kes_lam_pe_i

// ------------------------------------------

module rs_dec_kes_ome_pe_i 
#(
    parameter WIDTH = 10
)
(
    input logic             clk,
    input logic             rst_n,
    input logic             delta,
    input logic             init,
    input logic             reg_en,
    input logic [WIDTH-1:0] dis_out,
    input logic [WIDTH-1:0] gam_out,
    input logic [WIDTH-1:0] ome_out_prv,
    input logic [WIDTH-1:0] o_aux_out_prv,
    input logic [WIDTH-1:0] syn_in,
    input logic [WIDTH-1:0] syn_in_prv,
    input logic             is_pe_0,

    output logic [WIDTH-1:0]    ome_out,
    output logic [WIDTH-1:0]    o_aux_out
);

    // --- Internal Signals ---
    logic [WIDTH-1:0] ome_in;
    logic [WIDTH-1:0] ome_new;
    logic [WIDTH-1:0] ome_mul_1;
    logic [WIDTH-1:0] ome_mul_2;
    logic [WIDTH-1:0] ome_mul_xor;
    logic [WIDTH-1:0] o_aux_mux_1;
    logic [WIDTH-1:0] o_aux_mux_2;
    logic [WIDTH-1:0] o_aux_in;

    // --- 1. Omega Register ---
    mux_2_nb #(.WIDTH(WIDTH)) Ome_Mux (
        .d0 (ome_new),
        .d1 (syn_in),
        .s  (init),
        .y  (ome_in)
    );

    flop_r_nb #(.WIDTH(WIDTH)) Ome_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (ome_in),
        .q      (ome_out)
    );

    // --- 2. New Omega Calculation ---
    gf_mul Ome_Mul_1 (
        .a  (ome_out),
        .b  (gam_out),
        .p  (ome_mul_1)
    );

    gf_mul Ome_Mul_2 (
        .a  (o_aux_out),
        .b  (dis_out),
        .p  (ome_mul_2)
    );

    xor_nb #(.WIDTH(WIDTH)) Ome_Xor (
        .a  (ome_mul_1),
        .b  (ome_mul_2),
        .y  (ome_mul_xor)
    );

    assign ome_new = is_pe_0 ? ome_mul_1 : ome_mul_xor;

    // --- 3.
    mux_2_nb #(.WIDTH(WIDTH)) O_Aux_Mux_1 (
        .d0 (o_aux_out_prv),
        .d1 (ome_out_prv),
        .s  (delta),
        .y  (o_aux_mux_1)
    );

    mux_2_nb #(.WIDTH(WIDTH)) O_Aux_Mux_2 (
        .d0 (o_aux_mux_1),
        .d1 (is_pe_0 ? WIDTH'('d0) : syn_in_prv),
        .s  (init),
        .y  (o_aux_mux_2)
    );

    assign o_aux_in = is_pe_0 ? WIDTH'('d0) : o_aux_mux_2;

    flop_r_nb #(.WIDTH(WIDTH)) O_Aux_Reg (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (reg_en),
        .d      (o_aux_in),
        .q      (o_aux_out)
    );

endmodule: rs_dec_kes_ome_pe_i
