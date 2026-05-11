module rs_uart_tx_gbx
(
    input logic         clk, rst_n,
    input logic         buf_tx_vld,
    input logic [9:0]   buf_tx_dat,
    input logic         uart_tx_empty,

    output logic        gbx_tx_vld,
    output logic [7:0]  gbx_tx_dat,
    output logic        gbx_tx_done,
    output logic        gbx_tx_end,
    output logic        gbx_tx_err
);

// Local Var
    logic           buf_vld;
    logic [9:0]     buf_dat;

    logic           uart_empty_prv;
    logic           uart_empty_flg;

    logic           uart_empty;

    logic           gbx_vld;
    logic [9:0]     gbx_dat;
    logic           gbx_done;
    logic           gbx_end;
    logic           gbx_err;

    logic           reg_en;
    logic           reg_sel;
    logic [15:0]    reg_dat;

    logic           cnt_bit_incr;
    logic           cnt_bit_decr;
    logic [4:0]     cnt_bit_dat;
    logic           cnt_is_16;

    logic           cnt_sym_en;
    logic           cnt_sym_clr;
    logic [9:0]     cnt_sym_dat;
    logic           sym_final;

// Global Var Assignment
    assign buf_vld = buf_tx_vld;
    assign buf_dat = buf_tx_dat;

    assign uart_empty = uart_tx_empty;

    assign gbx_tx_vld = gbx_vld;
    assign gbx_tx_dat = gbx_dat;
    assign gbx_tx_done = gbx_done;
    assign gbx_tx_end = cnt_sym_clr;
    assign gbx_tx_err = gbx_err;

//--- 1. FSM ---
    typedef enum logic [1:0] {
        READY1,
        LOAD1,
        READY2,
        LOAD2
    } state_t;

    state_t state_cur, state_nxt;

    always_comb begin
        case (state_cur)
            READY1: begin
                reg_en          = (uart_empty & buf_vld) ? 1'b1 : 1'b0;
                reg_sel         = 1'b0;
                cnt_bit_incr    = (uart_empty & buf_vld) ? 1'b1 : 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_sym_en      = (uart_empty & buf_vld) ? 1'b1 : 1'b0;
                cnt_sym_clr     = 1'b0;
                gbx_vld         = 1'b0;
                gbx_done        = 1'b0;
                gbx_err         = 1'b0;
            end

            READY2: begin
                reg_en          = (uart_empty_flg & buf_vld) ? 1'b1 : 1'b0;
                reg_sel         = 1'b0;
                cnt_bit_incr    = (uart_empty_flg & buf_vld) ? 1'b1 : 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_sym_en      = (uart_empty_flg & buf_vld) ? 1'b1 : 1'b0;
                cnt_sym_clr     = 1'b0;
                gbx_vld         = 1'b0;
                gbx_done        = 1'b0;
                gbx_err         = 1'b0;
            end

            LOAD1: begin
                reg_en          = 1'b1;
                reg_sel         = 1'b1;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b1;
                cnt_sym_en      = 1'b0;
                cnt_sym_clr     = 1'b0;
                gbx_vld         = 1'b1;
                gbx_done        = cnt_is_16 ? 1'b0 : 1'b1;
                gbx_err         = 1'b0;
            end

            LOAD2: begin
                reg_en          = uart_empty_flg ? 1'b1 : 1'b0;
                reg_sel         = uart_empty_flg ? 1'b1 : 1'b0;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = uart_empty_flg ? 1'b1 : 1'b0;
                cnt_sym_en      = 1'b0;
                cnt_sym_clr     = (uart_empty_flg & sym_final) ? 1'b1 : 1'b0;
                gbx_vld         = uart_empty_flg ? 1'b1 : 1'b0;
                gbx_done        = uart_empty_flg ? 1'b1 : 1'b0;
                gbx_err         = 1'b0;           
            end

            default: begin
                reg_en          = 1'b0;
                reg_sel         = 1'b0;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_sym_en      = 1'b0;
                cnt_sym_clr     = 1'b0;
                gbx_vld         = 1'b0;
                gbx_done        = 1'b0;
                gbx_err         = 1'b1;
            end
        endcase
    end

    always_comb begin
        case (state_cur)
            READY1: begin
                if (uart_empty & buf_vld)   state_nxt = LOAD1;
                else                        state_nxt = READY1;
            end

            READY2: begin
                if (uart_empty_flg & buf_vld)   state_nxt = LOAD1;
                else                            state_nxt = READY2;
            end

            LOAD1: begin
                if (cnt_is_16)  state_nxt = LOAD2;
                else            state_nxt = READY2;
            end

            LOAD2: begin
                if (uart_empty_flg) state_nxt = READY2;
                else                state_nxt = LOAD2;
            end

            default: begin
                state_nxt = READY2;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) state_cur   <= READY1;    
        else        state_cur   <= state_nxt; 
    end

//--- 2. Bit Counter ---
    logic [4:0] cnt_bit_dat_nxt;
    always_comb begin
        if (cnt_bit_incr & cnt_bit_decr)    cnt_bit_dat_nxt = cnt_bit_dat + 5'd2; 
        else if (cnt_bit_incr)              cnt_bit_dat_nxt = cnt_bit_dat + 5'd10; 
        else if (cnt_bit_decr)              cnt_bit_dat_nxt = cnt_bit_dat - 5'd8;
        else                                cnt_bit_dat_nxt = cnt_bit_dat;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) cnt_bit_dat <= 5'd0;   
        else        cnt_bit_dat <= cnt_bit_dat_nxt;
    end

    assign cnt_is_16 = (cnt_bit_dat == 5'd16);

//--- 3. Symbol Counter ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)             cnt_sym_dat <= 10'd0;   
        else if (cnt_sym_clr)   cnt_sym_dat <= 10'd0;   
        else if (cnt_sym_en)    cnt_sym_dat <= cnt_sym_dat + 10'd1; 
        else                    cnt_sym_dat <= cnt_sym_dat;
    end

    assign sym_final   = (cnt_sym_dat == 10'd544);

//--- 4. UART Empty Raising Edge Detection ---
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) uart_empty_prv <= 1'b0;
        else        uart_empty_prv <= uart_empty;
    end
    assign uart_empty_flg = uart_empty & ~uart_empty_prv;


//--- 5. Register (Buffer) ---
    logic [15:0] reg_shf;
    assign reg_shf = 16'('d16 + 'd8 - cnt_bit_dat);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n)             reg_dat <= '0;
        else begin
            if (reg_en) begin
                if (~reg_sel)   reg_dat <= (reg_dat << 10) | buf_dat;
                else            reg_dat <= (reg_dat << reg_shf) >> reg_shf;
            end
        end
    end

//--- 6. Gearbox Ouput --- 
    logic [15:0] reg_dat_shf;
    assign reg_dat_shf  = reg_dat >> (cnt_bit_dat - 8);
    assign gbx_dat      = reg_dat_shf[7:0];

endmodule: rs_uart_tx_gbx
