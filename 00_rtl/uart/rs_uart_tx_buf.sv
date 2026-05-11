module rs_uart_tx_buf
(
    input logic         clk, rst_n,
    input logic         rs_tx_vld,
    input logic [9:0]   rs_tx_dat,
    input logic         gbx_tx_done,

    output logic        buf_tx_vld,
    output logic [9:0]  buf_tx_dat,
    output logic        buf_tx_err
);

// Local Var
    logic           rs_vld;
    logic [9:0]     rs_dat;

    logic           gbx_done;

    logic           buf_vld;
    logic [9:0]     buf_dat;
    logic           buf_err;

    logic           w_en;
    logic           r_en;

    logic [9:0]     w_cnt_dat;
    logic           w_cnt_clr;
    logic           w_cnt_final;

    logic [9:0]     r_cnt_dat;
    logic           r_cnt_clr; 
    logic           r_cnt_final;

// Var Assignment
    assign rs_vld = rs_tx_vld;
    assign rs_dat = rs_tx_dat;

    assign gbx_done = gbx_tx_done;

    assign buf_tx_vld = buf_vld;
    assign buf_tx_dat = buf_dat;
    assign buf_tx_err = buf_err;

// FIFO Memory
    logic [9:0] fifo [1023:0];

//--- 1. FSM ---
    typedef enum logic [1:0] {
        READY,
        LOAD,
        DONE
    } state_t;

    state_t state_cur, state_nxt;

    always_comb begin
        case (state_cur)
            READY: begin
                w_en        = rs_vld ? 1'b1 : 1'b0;
                r_en        = 1'b0;
                w_cnt_clr   = (rs_vld & w_cnt_final) ? 1'b1 : 1'b0;
                r_cnt_clr   = r_cnt_final ? 1'b1 : 1'b0;
                buf_vld     = 1'b0;
                buf_err     = 1'b0;
            end

            LOAD: begin
                w_en        = 1'b0;
                r_en        = 1'b1;
                w_cnt_clr   = 1'b0;
                r_cnt_clr   = 1'b0;
                buf_vld     = 1'b0;
                buf_err     = 1'b0;
            end

            DONE: begin
                w_en        = 1'b0;
                r_en        = 1'b0;
                w_cnt_clr   = 1'b0;
                r_cnt_clr   = 1'b0;
                buf_vld     = 1'b1;
                buf_err     = 1'b0;
            end

            default: begin
                w_en        = 1'b0;
                r_en        = 1'b0;
                w_cnt_clr   = 1'b0;
                r_cnt_clr   = 1'b0;
                buf_vld     = 1'b0;
                buf_err     = 1'b1;
            end
        endcase
    end

    always_comb begin
        case (state_cur)
            READY: begin
                if (rs_vld & w_cnt_final)   state_nxt = LOAD;
                else                        state_nxt = READY;
            end

            LOAD: begin
                state_nxt = DONE;
            end

            DONE: begin
                if (gbx_done & r_cnt_final)         state_nxt = READY;
                else if (gbx_done & ~r_cnt_final)   state_nxt = LOAD;
                else                                state_nxt = DONE;
            end

            default: begin
                state_nxt = READY;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) state_cur   <= READY;    
        else        state_cur   <= state_nxt; 
    end

//--- 2. Write Counter ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)         w_cnt_dat <= 10'd0;   
        else if (w_cnt_clr) w_cnt_dat <= 10'd0;   
        else if (w_en)      w_cnt_dat <= w_cnt_dat + 10'd1; 
        else                w_cnt_dat <= w_cnt_dat;
    end

    assign w_cnt_final = (w_cnt_dat == 10'd544 - 10'd1);

//--- 3. LOAD Counter ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)         r_cnt_dat <= 10'd0;   
        else if (r_cnt_clr) r_cnt_dat <= 10'd0;   
        else if (r_en)      r_cnt_dat <= r_cnt_dat + 10'd1; 
        else                r_cnt_dat <= r_cnt_dat;
    end

    assign r_cnt_final = (r_cnt_dat == 10'd544);

//--- 4. FIFO Memory ---
    always_ff @(posedge clk) begin
        if (w_en)   fifo[w_cnt_dat] <= rs_dat;
        if (r_en)   buf_dat         <= fifo[r_cnt_dat];
    end

endmodule: rs_uart_tx_buf
