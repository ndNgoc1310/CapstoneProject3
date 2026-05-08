/*
* Module     : `uart_core`
* Description: UART core module, provide directly full control over UART
*              operation including TX and RX.
* Language   : SystemVerilog
* Version    : 0.0.1
* Last update: 2026-03-16 11:48
* Author     : wonk.ptn (wonk.ptn@gmail.com)
*/

`timescale 1ns/1ps
module uart_core (
    input  logic        i_clk               ,
    input  logic        i_rst_n             ,

    input  logic        i_bclk_en           ,
    input  logic [15:0] i_baud_divisor      ,

    input  logic        i_parity_en         ,
    input  logic        i_even_parity       ,

    input  logic        i_dbg_lloopback     ,
    input  logic        i_dbg_sloopback     ,

    input  logic        i_tx_en             ,
    input  logic [7:0]  i_tx_data           ,
    input  logic        i_tx_wren           ,
    output logic        o_tx_idle           ,
    output logic        o_tx_done           ,
    input  logic        i_tx_fifo_clr       ,
    output logic        o_tx_fifo_empty     ,
    output logic        o_tx_fifo_full      ,
    output logic [5:0]  o_tx_fifo_level     ,

    input  logic        i_rx_en             ,
    input  logic        i_rx_rden           ,
    output logic [7:0]  o_rx_data           ,
    output logic        o_rx_idle           ,
    output logic        o_rx_done           ,
    input  logic        i_rx_fifo_clr       ,
    output logic        o_rx_fifo_empty     ,
    output logic        o_rx_fifo_full      ,
    output logic [5:0]  o_rx_fifo_level     ,
    output logic        o_rx_frame_error    ,
    output logic        o_rx_parity_error   ,
    output logic        o_rx_data_is_zero   ,

    output logic        o_tx                ,
    input  logic        i_rx
    );

    logic sample_clk;
    logic uart_tx_out;
    logic uart_rx_in ;

    always_comb begin: blk_loopback
        o_tx = (i_dbg_lloopback) ? i_rx : uart_tx_out;
        case ({i_dbg_lloopback, i_dbg_sloopback})
            2'b11  : uart_rx_in = 1'b1;
            2'b10  : uart_rx_in = 1'b1;
            2'b01  : uart_rx_in = uart_tx_out;
            2'b00  : uart_rx_in = i_rx;
            default: uart_rx_in = 1'b1;
        endcase
    end

    uart_baud_gen baud_clk_gen (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_en        (i_bclk_en),
        .i_divisor   (i_baud_divisor),
        .o_sample_clk(sample_clk)
        );

    uart_tx uart_tx (
        .i_clk        (i_clk            ),
        .i_sample_clk (sample_clk       ),
        .i_rst_n      (i_rst_n          ),
        .i_tx_en      (i_tx_en          ),
        .i_wr_en      (i_tx_wren        ),
        .i_wr_data    (i_tx_data        ),
        .i_parity_en  (i_parity_en      ),
        .i_even_parity(i_even_parity    ),
        .i_fifo_clr   (i_tx_fifo_clr    ),
        .o_fifo_full  (o_tx_fifo_full   ),
        .o_fifo_empty (o_tx_fifo_empty  ),
        .o_fifo_len   (o_tx_fifo_level  ),
        .o_ready      (o_tx_idle        ),
        .o_done       (o_tx_done        ),
        .o_tx         (uart_tx_out      )
    );

    uart_rx uart_rx (
        .i_clk         (i_clk               ),
        .i_sample_clk  (sample_clk          ),
        .i_rst_n       (i_rst_n             ),
        .i_fifo_clr    (i_rx_fifo_clr       ),
        .i_rx_en       (i_rx_en             ),
        .i_rx          (uart_rx_in          ),
        .i_parity_en   (i_parity_en         ),
        .i_even_parity (i_even_parity       ),
        .i_rd_en       (i_rx_rden           ),
        .o_rd_data     (o_rx_data           ),
        .o_frame_error (o_rx_frame_error    ),
        .o_parity_error(o_rx_parity_error   ),
        .o_data_zero   (o_rx_data_is_zero   ),
        .o_fifo_full   (o_rx_fifo_full      ),
        .o_fifo_empty  (o_rx_fifo_empty     ),
        .o_fifo_len    (o_rx_fifo_level     ),
        .o_done        (o_rx_done           ),
        .o_idle        (o_rx_idle           )
    );

endmodule : uart_core

module uart_adder #(parameter int WIDTH = 32) (
    input  logic [WIDTH-1:0] i_a   ,
    input  logic [WIDTH-1:0] i_b   ,
    input  logic             i_cin ,
    output logic [WIDTH-1:0] o_sum ,
    output logic             o_cout
    );
    logic [WIDTH:0] sum_tmp;
    always_comb begin : proc_add
        sum_tmp = i_a + i_b + {{WIDTH-1{1'b0}},i_cin};
        o_sum   = sum_tmp[WIDTH-1:0]               ;
        o_cout  = sum_tmp[WIDTH]                   ;
    end
endmodule: uart_adder

`timescale 1ns/1ps
module uart_async_fifo #(parameter int WIDTH = 8) (
    input  logic             i_wr_clk ,
    input  logic             i_rd_clk ,
    input  logic             i_rst_n  ,
    input  logic             i_clr    ,
    input  logic             i_wr_en  ,
    input  logic             i_rd_en  ,
    input  logic [WIDTH-1:0] i_wr_data,
    output logic [WIDTH-1:0] o_rd_data,
    output logic             o_full   ,
    output logic             o_empty  ,
    output logic [5:0]       o_len
    );

    logic full;
    logic empty;

    logic             mem_wr_en  ;
    logic             mem_rd_en  ;
    logic [WIDTH-1:0] mem_wr_data;
    logic [WIDTH-1:0] mem_rd_data;
    logic [4:0]       mem_wr_addr;
    logic [4:0]       mem_rd_addr;

    logic [5:0] wr_count;
    logic [5:0] rd_count;
    logic [5:0] wr_count_next;
    logic [5:0] rd_count_next;

    logic wr_allow;
    logic rd_allow;

    always_comb begin : proc_logic
        wr_count_next = wr_count + 6'd1;
        rd_count_next = rd_count + 6'd1;
        mem_wr_addr   = wr_count[4:0];
        mem_rd_addr   = rd_count[4:0];
        full          = (wr_count[5] ^ rd_count[5]) & ~|(wr_count[4:0] ^ rd_count[4:0]);
        empty         = ~|(wr_count ^ rd_count);
        wr_allow      = i_wr_en & ~full;
        rd_allow      = i_rd_en & ~empty;
        mem_wr_en     = wr_allow;
        mem_rd_en     = rd_allow;
        o_len         = wr_count - rd_count;
        mem_wr_data   = i_wr_data;
        o_rd_data     = mem_rd_data;
        // notempty      = ~full & ~empty;
    end

    assign o_full  = full;
    assign o_empty = empty;

    always @(posedge i_wr_clk, negedge i_rst_n) begin : proc_write_pointer
        if (~i_rst_n) wr_count <= {6{1'b0}};
        else begin
            if      (i_clr   ) wr_count <= {6{1'b0}};
            else if (wr_allow) wr_count <= wr_count_next;
            else               wr_count <= wr_count;
        end
    end

    always @(posedge i_rd_clk, negedge i_rst_n) begin : proc_read_pointer
        if (~i_rst_n) rd_count <= {6{1'b0}};
        else begin
            if      (i_clr   ) rd_count <= {6{1'b0}};
            else if (rd_allow) rd_count <= rd_count_next;
            else               rd_count <= rd_count;
        end
    end

    uart_sram #(WIDTH) fifo_mem (
        .i_wr_clk (i_wr_clk   ),
        .i_wr_addr(mem_wr_addr),
        .i_wr_en  (mem_wr_en  ),
        .i_wr_data(mem_wr_data),
        .i_rd_clk (i_rd_clk   ),
        .i_rd_addr(mem_rd_addr),
        .i_rd_en  (mem_rd_en  ),
        .o_rd_data(mem_rd_data),
        .i_rstn   (i_rst_n    )
    );

endmodule: uart_async_fifo

`define DEFAULT_WIDTH 16

module uart_baud_gen #(parameter int WIDTH = `DEFAULT_WIDTH) (
    input  logic             i_clk       ,
    input  logic             i_rst_n     ,
    input  logic             i_en        ,
    input  logic [WIDTH-1:0] i_divisor   ,
    output logic             o_sample_clk
    );

    logic [WIDTH-1:0]      counter_rst_val    ;     // down counter value when reset
    logic [WIDTH-1:0]      counter_cur_val    ;     // current down counter value
    logic [WIDTH-1:0]      counter_tmp_val    ;     // current down counter value
    logic [WIDTH-1:0]      counter_new_val    ;     // new down counter value
    logic [1:0][WIDTH-1:0] counter_sources    ;
    logic [1:0][WIDTH-1:0] counter_rst_sources;
    logic                  counter_sources_sel;
    logic                  counter_rst_val_sel;
    logic                  counter_en         ;
    logic                  counter_overflow   ;

    localparam logic [WIDTH-1:0] DEFAULTDIVISOR = 16'hFFE5;


    assign counter_rst_sources[0] = DEFAULTDIVISOR;
    assign counter_rst_sources[1] = i_divisor        ;
    assign counter_rst_val_sel    = |i_divisor;
    uart_mux #(.WIDTH(WIDTH), .NUM_INPUT(2)) counter_val_rst_mux (
        .sel  (counter_rst_val_sel),
        .i_mux(counter_rst_sources),
        .o_mux(counter_rst_val    )
    );


    assign counter_sources[0]  = counter_rst_val ;
    assign counter_sources[1]  = counter_tmp_val ;
    assign counter_sources_sel = ~counter_overflow & |counter_cur_val;
    uart_mux #(.WIDTH(WIDTH), .NUM_INPUT(2)) counter_sources_mux (
        .sel  (counter_sources_sel),
        .i_mux(counter_sources    ),
        .o_mux(counter_new_val    )
    );

    uart_adder #(.WIDTH(16)) counter_adder (
        .i_a   (counter_cur_val ),
        .i_b   (16'h0001        ),
        .i_cin ('0              ),
        .o_sum (counter_tmp_val ),
        .o_cout(counter_overflow)
    );

    assign counter_en = i_en;
    uart_register #(.WIDTH(WIDTH)) counter (
        .i_rst_n(i_rst_n        ),
        .i_clk  (i_clk          ),
        .i_en   (counter_en     ),
        .i_d    (counter_new_val),
        .o_q    (counter_cur_val)
    );

    uart_register #(.WIDTH(1)) sample_clk_buffer (
        .i_rst_n(i_rst_n      ),
        .i_clk  (i_clk        ),
        .i_en   (i_en         ),
        .i_d    (counter_overflow),
        .o_q    (o_sample_clk )
    );


endmodule: uart_baud_gen

module uart_frame_check (
    input  logic [10:0] i_data        ,
    input  logic        i_parity_en   ,
    input  logic        i_even_parity ,
    output logic        o_error_frame ,
    output logic        o_error_parity,
    output logic [7:0]  o_data
    );

    logic       start_bit ;
    logic [7:0] data      ;
    logic       parity_bit;
    logic       stop_bit  ;

    // logic             mux_sel;
    // logic [1:0][10:0] mux_in ;
    // logic      [10:0] mux_out;
    // mux #(.WIDTH(11), .NUM_INPUT(2)) input_mux (
    //     .sel  (mux_sel),
    //     .i_mux(mux_in ),
    //     .o_mux(mux_out)
    // );

    // [ START | data | PARITY | STOP ]
    always_comb begin : proc_signals
        // mux_in[0]      = {i_data[9:0], '0}          ;
        // mux_in[1]      = {i_data}                   ;
        // mux_sel        =  i_parity_en               ;
        start_bit      =  (i_parity_en) ? i_data[1]   : i_data[0]  ;
        data           =  (i_parity_en) ? i_data[8:1] : i_data[9:2];
        parity_bit     =  (i_parity_en) ? i_data[9]   : '1         ;
        stop_bit       =  i_data[10];
        o_data         =  data      ;
        o_error_frame  =  ~stop_bit ;
        o_error_parity =  i_parity_en & (~i_even_parity ^ parity_bit ^ (^data));
    end

endmodule : uart_frame_check

module uart_frame_gen (
    input  logic [7:0]  i_data       ,
    input  logic        i_parity_en  ,
    input  logic        i_even_parity,
    output logic [10:0] o_data
    );

    logic  start_bit;
    logic parity_bit;
    always_comb begin
        start_bit  = '0;
        parity_bit = (i_parity_en) ? (^i_data) ^ (~i_even_parity) : '1;
        o_data     = {'1, parity_bit, i_data, start_bit};
    end

endmodule: uart_frame_gen

module uart_mux #(
        parameter int WIDTH     = 32,
        parameter int NUM_INPUT = 2
    )(
        input  logic [$clog2(NUM_INPUT)-1:0]    sel   ,
        input  logic [NUM_INPUT-1:0][WIDTH-1:0] i_mux ,
        output logic [WIDTH-1:0]                o_mux
    );

    always_comb begin : proc_mux
        o_mux = i_mux[sel];
    end
endmodule: uart_mux

module uart_piso #(parameter int WIDTH = 16) (
    input  logic             i_clk      ,
    input  logic             i_rst_n    ,
    input  logic [WIDTH-1:0] i_data     ,
    input  logic             i_wr_en    ,
    input  logic             i_shift_en ,
    output logic             o_data
    );

    logic                  buffer_en ;
    logic [WIDTH-1:0]      buffer_in ;
    logic [WIDTH-1:0]      buffer_out;
    logic [1:0][WIDTH-1:0] buffer_in_mux;
    logic                  buffer_in_sel;

    always_comb begin : proc_signals
        buffer_in_mux[0] = i_data;
        buffer_in_mux[1] = {1'b0,buffer_out[WIDTH-1:1]};
        buffer_in_sel    = ~i_wr_en & i_shift_en;
        buffer_en        =  i_wr_en | i_shift_en;
        o_data           =  buffer_out[0];
    end

    uart_mux #(.WIDTH(WIDTH), .NUM_INPUT(2)) buffer_input_multiplexer (
        .sel  ( buffer_in_sel ),
        .i_mux( buffer_in_mux ),
        .o_mux( buffer_in     )
    );

    uart_register #(.WIDTH(WIDTH)) buffer (
        .i_clk  ( i_clk      ),
        .i_rst_n( i_rst_n    ),
        .i_en   ( buffer_en  ),
        .i_d    ( buffer_in  ),
        .o_q    ( buffer_out )
    );

endmodule : uart_piso

module uart_posi #(parameter int WIDTH = 16) (
    input  logic             i_clk     ,
    input  logic             i_rst_n   ,
    input  logic             i_data    ,
    input  logic             i_shift_en,
    output logic [WIDTH-1:0] o_data
    );

    logic             buffer_en ;
    logic [WIDTH-1:0] buffer_in ;
    logic [WIDTH-1:0] buffer_out;

    always_comb begin: proc_signals
        buffer_in = {i_data, buffer_out[WIDTH-1:1]};
        buffer_en = i_shift_en;
        o_data    = buffer_out;
    end
    uart_register #(.WIDTH(WIDTH)) buffer (
        .i_clk  ( i_clk      ),
        .i_rst_n( i_rst_n    ),
        .i_en   ( buffer_en  ),
        .i_d    ( buffer_in  ),
        .o_q    ( buffer_out )
    );

endmodule : uart_posi

module uart_register #(
    parameter int WIDTH = 32
    )(
        input  logic                 i_rst_n,
        input  logic                 i_clk  ,
        input  logic                 i_en   ,
        input  logic [WIDTH - 1 : 0] i_d    ,
        output logic [WIDTH - 1 : 0] o_q
    );

    always_ff@(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n)  begin o_q <= 0  ; end
        else if(i_en) begin o_q <= i_d; end
        else          begin o_q <= o_q; end
    end
endmodule

`timescale 1ns/1ps
module uart_rx (
    input  logic       i_clk         ,
    input  logic       i_sample_clk  ,
    input  logic       i_rst_n       ,
    input  logic       i_fifo_clr    ,
    input  logic       i_rx_en       ,
    input  logic       i_rx          ,
    input  logic       i_parity_en   ,
    input  logic       i_even_parity ,
    input  logic       i_rd_en       ,
    output logic [7:0] o_rd_data     ,
    output logic       o_frame_error ,
    output logic       o_parity_error,
    output logic       o_data_zero   ,
    output logic       o_fifo_full   ,
    output logic       o_fifo_empty  ,
    output logic [5:0] o_fifo_len    ,
    output logic       o_done        ,
    output logic       o_idle
    );

    logic  buffer_stack_in_0 ;
    logic  buffer_stack_out_0;
    logic  buffer_stack_in_1 ;
    logic  buffer_stack_out_1;
    logic  buffer_stack_en ;
    assign buffer_stack_in_0 = i_rx;
    assign buffer_stack_in_1 = buffer_stack_out_0;
    uart_register #(.WIDTH(1)) rx_in_buffer_0 (
        .i_rst_n(i_rst_n           ),
        .i_clk  (i_sample_clk      ),
        .i_en   (buffer_stack_en   ),
        .i_d    (buffer_stack_in_0 ),
        .o_q    (buffer_stack_out_0)
    );
    uart_register #(.WIDTH(1)) rx_in_buffer_1 (
        .i_rst_n(i_rst_n           ),
        .i_clk  (i_sample_clk      ),
        .i_en   (buffer_stack_en   ),
        .i_d    (buffer_stack_in_1 ),
        .o_q    (buffer_stack_out_1)
    );

    logic [10:0] posi_data_out;
    logic        posi_data_in ;
    logic        posi_shift_en;
    assign       posi_data_in = buffer_stack_out_1;
    uart_posi #(.WIDTH(11)) serial_shift_register (
        .i_clk     (i_sample_clk ),
        .i_rst_n   (i_rst_n      ),
        .i_data    (posi_data_in ),
        .i_shift_en(posi_shift_en),
        .o_data    (posi_data_out)
    );

    logic       error_frame ;
    logic       error_parity;
    logic [7:0] frame_data  ;
    uart_frame_check frame_check (
        .i_data        (posi_data_out),
        .i_parity_en   (i_parity_en  ),
        .i_even_parity (i_even_parity),
        .o_error_frame (error_frame  ),
        .o_error_parity(error_parity ),
        .o_data        (frame_data   )
    );

    logic       fifo_wr_en  ;
    logic       fifo_rd_en  ;
    logic [9:0] fifo_wr_data;
    logic [9:0] fifo_rd_data;
    logic       fifo_clr    ;
    logic       fifo_empty  ;
    logic       fifo_full   ;
    logic [5:0] fifo_len    ;
    uart_async_fifo #(.WIDTH(10)) asynchronous_fifo (
        .i_wr_clk (i_sample_clk),
        .i_rd_clk (i_clk       ),
        .i_rst_n  (i_rst_n     ),
        .i_clr    (fifo_clr    ),
        .i_wr_en  (fifo_wr_en  ),
        .i_rd_en  (fifo_rd_en  ),
        .i_wr_data(fifo_wr_data),
        .o_rd_data(fifo_rd_data),
        .o_full   (fifo_full   ),
        .o_empty  (fifo_empty  ),
        .o_len    (fifo_len    )
    );


    logic  rx_bit;
    assign rx_bit = buffer_stack_out_1;

    logic [3:0] bit_count;
    logic [3:0] clk_count;
    logic [3:0] bit_count_next;
    logic [3:0] clk_count_next;
    logic bit_count_en;
    logic clk_count_en;
    logic bit_count_rst;
    logic clk_count_rst;

    assign bit_count_next = (bit_count_rst) ? bit_count + 4'h1 : 4'h0;
    assign clk_count_next = (clk_count_rst) ? clk_count + 4'h1 : 4'h0;

    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_bit_counter
        if (~i_rst_n) begin
            bit_count <= 0;
        end
        else if (bit_count_en | ~bit_count_rst) bit_count <= bit_count_next;
    end

    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_clk_counter
        if (~i_rst_n) begin
            clk_count <= 0;
        end
        else if (clk_count_en | ~clk_count_rst) clk_count <= clk_count_next;
    end

    typedef enum logic [2:0] {
        INIT,
        IDLE,
        CHECK_START,
        VERIFY_START,
        WAIT_SAMPLE,
        END_SAMPLE,
        WRITE_BACK
    } state_t ;

    state_t curr_state;
    state_t next_state;

    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_update_state
        if (~i_rst_n) curr_state <= INIT      ;
        else          curr_state <= next_state;
    end

    always_comb begin : proc_get_next_state
        case (curr_state)
            INIT         : next_state =  (clk_count == 4'h2) ? IDLE         : INIT        ;
            IDLE         : next_state =  (~rx_bit & i_rx_en) ? CHECK_START  : IDLE        ;
            CHECK_START  : next_state =  (clk_count == 4'h5) ? VERIFY_START : CHECK_START ;
            VERIFY_START : next_state =  (rx_bit) ? IDLE :
                                         (clk_count == 4'h8) ? WAIT_SAMPLE  : VERIFY_START;
            WAIT_SAMPLE  : next_state =  (clk_count == 4'h7) ? END_SAMPLE   : WAIT_SAMPLE ;
            END_SAMPLE   : next_state =   i_parity_en ?
                                        ((bit_count == 4'hB) ?
                                        ((clk_count == 4'hD) ? WRITE_BACK  : END_SAMPLE) :
                                        ((clk_count == 4'hF) ? WAIT_SAMPLE : END_SAMPLE)):
                                        ((bit_count == 4'hA) ?
                                        ((clk_count == 4'hD) ? WRITE_BACK  : END_SAMPLE) :
                                        ((clk_count == 4'hF) ? WAIT_SAMPLE : END_SAMPLE));
            WRITE_BACK   : next_state =  (error_frame & ~rx_bit) ? WRITE_BACK : IDLE     ;
            default      : next_state =  IDLE;
        endcase
    end

    always_comb begin : proc_signals
        clk_count_en    =  (curr_state == IDLE         && rx_bit) ? '0 : '1;
        bit_count_en    = ((curr_state == VERIFY_START && ~rx_bit && clk_count == 4'h8) ||
                           (curr_state == WAIT_SAMPLE  && clk_count == 4'h7)) ? '1 : '0;
        clk_count_rst   = (curr_state == IDLE) ? '0 : '1;
        bit_count_rst   = (curr_state == IDLE) ? '0 : '1;
        posi_shift_en   = ((curr_state == VERIFY_START && ~rx_bit && clk_count == 4'h8) ||
                           (curr_state == WAIT_SAMPLE  && clk_count == 4'h7)) ? '1 : '0;

        buffer_stack_en = '1;
        fifo_wr_data    = {error_parity,error_frame,frame_data};
        fifo_wr_en      = (curr_state == WRITE_BACK) ? (~fifo_full) : '0;
        fifo_rd_en      = i_rd_en;
        fifo_clr        = i_fifo_clr;
        o_rd_data       = fifo_rd_data[7:0];
        o_fifo_full     = fifo_full;
        o_fifo_empty    = fifo_empty;
        o_fifo_len      = fifo_len;
        o_done          = (curr_state == WRITE_BACK && next_state == IDLE) ? '1 : '0;
        o_idle          = (curr_state == IDLE) ? 1'b1 : 1'b0;
        o_frame_error   = fifo_rd_data[8];
        o_parity_error  = fifo_rd_data[9];
        o_data_zero     = ~|frame_data;
    end

endmodule : uart_rx

module uart_sram #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 32
) (
    input  logic                     i_rstn   ,
    input  logic                     i_wr_clk ,
    input  logic                     i_wr_en  ,
    input  logic [$clog2(DEPTH)-1:0] i_wr_addr,
    input  logic [        WIDTH-1:0] i_wr_data,
    input  logic                     i_rd_clk ,
    input  logic                     i_rd_en  ,
    input  logic [$clog2(DEPTH)-1:0] i_rd_addr,
    output logic [        WIDTH-1:0] o_rd_data
);

logic [31:0][WIDTH-1:0] mem;

always_ff @(posedge i_wr_clk, negedge i_rstn) begin: proc_write
    if (~i_rstn)      begin mem <= '0                  ; end
    else if (i_wr_en) begin mem[i_wr_addr] <= i_wr_data; end
    else              begin mem <= mem                 ; end
end

always_ff @(posedge i_rd_clk, negedge i_rstn) begin: proc_read
    if (~i_rstn)      begin o_rd_data <= '0            ; end
    else if (i_rd_en) begin o_rd_data <= mem[i_rd_addr]; end
    else              begin o_rd_data <= o_rd_data     ; end
end

endmodule: uart_sram

`timescale 1ns/1ns
module uart_tx (
    input  logic       i_clk        ,
    input  logic       i_sample_clk ,
    input  logic       i_rst_n      ,
    input  logic       i_tx_en      ,
    // input  logic       i_cts        ,
    // input  logic       i_autoflow   ,
    input  logic       i_wr_en      ,
    input  logic [7:0] i_wr_data    ,
    input  logic       i_parity_en  ,
    input  logic       i_even_parity,
    input  logic       i_fifo_clr   ,
    output logic       o_fifo_full  ,
    output logic       o_fifo_empty ,
    output logic [5:0] o_fifo_len   ,
    output logic       o_ready      ,
    output logic       o_done       ,
    output logic       o_tx
    );

    logic       fifo_wr_en  ;
    logic       fifo_rd_en  ;
    logic [7:0] fifo_wr_data;
    logic [7:0] fifo_rd_data;
    logic       fifo_empty  ;
    logic       fifo_full   ;
    logic [5:0] fifo_len    ;
    // sync_fifo #(.WIDTH(8), .ENTRIES(16)) synchronous_fifo (
    //     .i_clk       (i_clk       ),
    //     .i_rst_n     (i_rst_n     ),
    //     .i_wr_en     (fifo_wr_en  ),
    //     .i_rd_en     (fifo_rd_en  ),
    //     .i_wr_data   (fifo_wr_data),
    //     .o_rd_data   (fifo_rd_data),
    //     .o_full      (fifo_full   ),
    //     .o_afull     (),
    //     .o_empty     (fifo_empty  ),
    //     .o_aempty    (),
    //     .o_len       (),
    //     .o_data_valid()
    // );

    uart_async_fifo asynchronous_fifo (
        .i_wr_clk (i_clk       ),
        .i_rd_clk (i_sample_clk),
        .i_rst_n  (i_rst_n     ),
        .i_clr    (i_fifo_clr  ),
        .i_wr_en  (fifo_wr_en  ),
        .i_rd_en  (fifo_rd_en  ),
        .i_wr_data(fifo_wr_data),
        .o_rd_data(fifo_rd_data),
        .o_full   (fifo_full   ),
        .o_empty  (fifo_empty  ),
        .o_len    (fifo_len    )
    );

    logic [10:0] tx_data;
    uart_frame_gen frame_gen (
        .i_data       (fifo_rd_data ),
        .i_parity_en  (i_parity_en  ),
        .i_even_parity(i_even_parity),
        .o_data       (tx_data      )
    );

    logic [10:0] piso_data_in ;
    logic        piso_data_out;
    logic        piso_wr_en   ;
    logic        piso_init    ;
    logic        piso_shift_en;
    assign       piso_data_in = tx_data | {11{piso_init}};
    uart_piso #(.WIDTH(11)) serial_shift_register (
        .i_clk     (i_sample_clk ),
        .i_rst_n   (i_rst_n      ),
        .i_data    (piso_data_in ),
        .i_wr_en   (piso_wr_en   ),
        .i_shift_en(piso_shift_en),
        .o_data    (piso_data_out)
    );

    logic            tx_mux_sel;
    logic [1:0][0:0] tx_mux_in;
    logic            tx_mux_out;
    assign tx_mux_in[0] = '1;
    assign tx_mux_in[1] = piso_data_out;
    assign o_tx         = tx_mux_out;
    uart_mux #(.WIDTH(1)) tx_mux (
        .sel  (tx_mux_sel),
        .i_mux(tx_mux_in ),
        .o_mux(tx_mux_out)
    );

    logic [3:0] bit_count;
    logic [3:0] clk_count;
    logic [3:0] bit_count_next;
    logic [3:0] clk_count_next;
    logic       bit_count_en;
    logic       clk_count_en;
    logic       bit_count_rst;
    logic       clk_count_rst;

    assign bit_count_next = 4'((bit_count_rst) ? bit_count + 4'h1 : 0);
    assign clk_count_next = 4'((clk_count_rst) ? clk_count + 4'h1 : 0);

    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_bit_counter
        if (~i_rst_n) begin
            bit_count <= 0;
        end
        else if (bit_count_en | ~bit_count_rst) bit_count <= bit_count_next;
    end

    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_clk_counter
        if (~i_rst_n) begin
            clk_count <= 0;
        end
        else if (clk_count_en | ~clk_count_rst) clk_count <= clk_count_next;
    end

    /* verilator lint_off UNOPTFLAT */
    typedef enum logic [2:0] {
        INIT ,
        IDLE ,
        GET  ,
        PUSH ,
        WAIT ,
        SHIFT
    } state_t;
    state_t curr_state;
    state_t next_state;
    always_ff @(posedge i_sample_clk, negedge i_rst_n) begin : proc_update_state
        if (~i_rst_n) curr_state <= INIT      ;
        else          curr_state <= next_state;
    end
    /* verilator lint_on UNOPTFLAT */

    logic tx_enable;
    logic tx_end;
    always_comb begin: proc_get_next_state
        case (curr_state)
            INIT       : next_state = IDLE                              ;
            IDLE       : next_state = (tx_enable) ? GET : IDLE          ;
            GET        : next_state = PUSH                              ;
            PUSH       : next_state = WAIT                              ;
            WAIT       : next_state =  (tx_end) ?
                                      ((clk_count == 4'hE) ? IDLE  : WAIT):
                                      ((clk_count == 4'hF) ? SHIFT : WAIT);
            SHIFT      : next_state = WAIT;
            default    : next_state = IDLE                              ;
        endcase
    end

    always_comb begin : proc_signals
        piso_init      = (curr_state == INIT) ? '1 : '0;
        piso_wr_en     = (curr_state == INIT && next_state == IDLE || next_state == GET || next_state == PUSH) ? '1 : '0;
        piso_shift_en  = (next_state == SHIFT) ? '1 : '0;
        fifo_wr_en     =  i_wr_en;
        fifo_wr_data   =  i_wr_data;
        fifo_rd_en     = (next_state == GET  ) ? '1 : '0;
        tx_enable      = ~fifo_empty & i_tx_en;
        tx_end         = (i_parity_en) ? ~|(4'hB ^ bit_count) : ~|(4'hA ^ bit_count);
        bit_count_en   = (next_state == GET || next_state == SHIFT) ? '1 : '0;
        bit_count_rst  = (next_state == IDLE) ? '0 : '1;
        clk_count_en   = (curr_state == INIT || curr_state == IDLE) ? '0 : '1;
        clk_count_rst  = (clk_count  == 4'hF ) ? '0 : '1;
        tx_mux_sel     = (curr_state == INIT) ? '0 : '1;
        o_done         = (curr_state == WAIT && next_state == IDLE) ? '1 : '0;
        o_ready        = (curr_state == IDLE ) ? '1 : '0;
        o_fifo_full    =  fifo_full ;
        o_fifo_empty   =  fifo_empty;
        o_fifo_len     =  fifo_len  ;
    end

endmodule: uart_tx
