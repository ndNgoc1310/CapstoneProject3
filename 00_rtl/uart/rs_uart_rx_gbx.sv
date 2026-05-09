module rs_uart_rx_gbx
(
    input logic         clk, rst_n,
    input logic         rs_sel,
    input logic         uart_rx_vld,
    input logic [7:0]   uart_rx_dat,

    output logic        gbx_rx_vld,
    output logic [9:0]  gbx_rx_dat,
    output logic        gbx_rx_err
);

// Local var

    logic [9:0]     byte_target;
    logic           uart_rx_vld_prv;
    logic           uart_vld_flg;

    logic           buf_en;
    logic           buf_sel;
    logic [15:0]    buf_dat;

    logic           gbx_sel;
    logic           gbx_vld;
    logic [9:0]     gbx_dat;

    logic           cnt_bit_incr;
    logic           cnt_bit_decr;
    logic [4:0]     cnt_bit_dat;
    logic           bit_ge_10;

    logic           cnt_byte_en;
    logic           cnt_byte_clr;
    logic [9:0]     cnt_byte_dat;
    logic           byte_final;

    logic           gbx_err;

// Global var assignment
    assign gbx_rx_vld = gbx_vld;
    assign gbx_rx_dat = gbx_dat;
    assign gbx_rx_err = gbx_err;

//--- 1. FSM ---
    typedef enum logic [2:0] {
        IDLE,
        GET,
        LOAD,
        LOAD_FINAL,
        ERROR
    } state_t;

    state_t state_cur, state_nxt;

    always_comb begin
        case (state_cur)
            IDLE: begin
                buf_en          = 1'b0;
                buf_sel         = 1'b0;
                gbx_sel         = 1'b0;
                gbx_vld         = 1'b0;
                cnt_bit_incr    = uart_vld_flg ? 1'b1 : 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_byte_en     = uart_vld_flg ? 1'b1 : 1'b0;
                cnt_byte_clr    = 1'b0;
                gbx_err         = 1'b0;
            end

            GET: begin
                buf_en          = 1'b1;
                buf_sel         = 1'b0;
                gbx_sel         = 1'b0;
                gbx_vld         = 1'b0;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_byte_en     = 1'b0;
                cnt_byte_clr    = 1'b0;
                gbx_err         = 1'b0;
            end

            LOAD: begin
                buf_en          = 1'b1;
                buf_sel         = 1'b1;
                gbx_sel         = 1'b0;
                gbx_vld         = 1'b1;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b1;
                cnt_byte_en     = 1'b0;
                cnt_byte_clr    = (rs_sel & byte_final) ? 1'b1 : 1'b0;
                gbx_err         = 1'b0;
            end

            LOAD_FINAL: begin
                buf_en          = 1'b1;
                buf_sel         = 1'b1;
                gbx_sel         = 1'b1;
                gbx_vld         = 1'b1;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b1;
                cnt_byte_en     = 1'b0;
                cnt_byte_clr    = 1'b1;
                gbx_err         = 1'b0;
            end

            ERROR: begin
                buf_en          = 1'b0;
                buf_sel         = 1'b0;
                gbx_sel         = 1'b0;
                gbx_vld         = 1'b0;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_byte_en     = 1'b0;
                cnt_byte_clr    = 1'b0;
                gbx_err         = 1'b1;
            end

            default: begin
                buf_en          = 1'b0;
                buf_sel         = 1'b0;
                gbx_sel         = 1'b0;
                gbx_vld         = 1'b0;
                cnt_bit_incr    = 1'b0;
                cnt_bit_decr    = 1'b0;
                cnt_byte_en     = 1'b0;
                cnt_byte_clr    = 1'b0;
                gbx_err         = 1'b1;
            end
        endcase
    end

    always_comb begin
        case (state_cur)
            IDLE: begin
                if (uart_vld_flg)   state_nxt = GET;
                else                state_nxt = IDLE;
            end

            GET: begin
                if (bit_ge_10 | byte_final) state_nxt = LOAD;
                else                        state_nxt = IDLE;
            end

            LOAD: begin
                if (uart_vld_flg)               state_nxt = ERROR;
                else if (byte_final & ~rs_sel)  state_nxt = LOAD_FINAL;
                else                            state_nxt = IDLE;
            end

            LOAD_FINAL: begin
                state_nxt = IDLE;
            end

            ERROR: begin
                state_nxt = IDLE;
            end

            default: begin
                state_nxt = ERROR;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) state_cur   <= IDLE;    
        else        state_cur   <= state_nxt; 
    end

//--- 2. Bit Counter ---
    logic [4:0] cnt_bit_dat_nxt;
    always_comb begin
        if (cnt_bit_incr)                   cnt_bit_dat_nxt = cnt_bit_dat + 5'd8; 
        else if (cnt_bit_decr & ~gbx_sel)   cnt_bit_dat_nxt = cnt_bit_dat - 5'd10;
        else if (cnt_bit_decr & gbx_sel)    cnt_bit_dat_nxt = cnt_bit_dat - 5'd6;
        else                                cnt_bit_dat_nxt = cnt_bit_dat;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) cnt_bit_dat <= 5'd0;   
        else        cnt_bit_dat <= cnt_bit_dat_nxt;
    end

    assign bit_ge_10    = (cnt_bit_dat >= 16'd10);

//--- 3. Byte Counter ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                 cnt_byte_dat <= 10'd0;   
        else if (cnt_byte_clr)      cnt_byte_dat <= 10'd0;   
        else if (cnt_byte_en)       cnt_byte_dat <= cnt_byte_dat + 10'd1; 
        else                        cnt_byte_dat <= cnt_byte_dat;
    end

    assign byte_target  = rs_sel ? 10'd680 : 10'd642;
    assign byte_final   = (cnt_byte_dat == byte_target);

//--- 4. UART Valid Falling Edge Detection ---
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) uart_rx_vld_prv <= 1'b0;
        else        uart_rx_vld_prv <= uart_rx_vld;
    end
    assign uart_vld_flg = ~uart_rx_vld & uart_rx_vld_prv;

//--- 5. Buffer ---
    logic [15:0] buf_shf;
    assign buf_shf = 16'('d16 + 'd10 - cnt_bit_dat);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n)             buf_dat <= '0;
        else begin
            if (buf_en) begin
                if (~buf_sel)   buf_dat <= (buf_dat << 8) | uart_rx_dat;
                else            buf_dat <= (buf_dat << buf_shf) >> buf_shf;
            end
        end
    end

//--- 6. Gearbox Ouput --- 
    logic [15:0] buf_dat_shf;
    assign buf_dat_shf = buf_dat >> (cnt_bit_dat - 10);

    always_comb begin
        if (~gbx_sel)   gbx_dat = buf_dat_shf[9:0];
        else            gbx_dat = {buf_dat[5:0], 4'b0};
    end

endmodule: rs_uart_rx_gbx
