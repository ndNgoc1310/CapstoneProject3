module rs_uart_rx_gbx
(
    input logic         uart_rx_vld,
    input logic [7:0]   uart_rx_dat,
    output logic        gbx_rx_vld,
    output logic [9:0]  gbx_rx_dat
);

    logic           buf_en;
    logic           buf_sel;
    logic [15:0]    buf_dat_in, buf_dat_out;

    logic           gbx_sel;
    logic           gbx_vld;
    logic [9:0]     gbx_dat;

    logic           cnt_bit_en;
    logic [3:0]     bit_cnt_in, bit_cnt_out;

    logic           bit_cnt_en;
    logic [9:0]     byte_cnt_in, byte_cnt_out;


endmodule: rs_uart_rx_gbx