`timescale 1ns/1ps

module uart_core_tx_tb;

    // ==========================================
    // Parameters
    // ==========================================
    parameter CLK_PERIOD = 20; // 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8680.5 ns

    // ==========================================
    // Signals
    // ==========================================
    logic        clk;
    logic        rst_n;
    logic        baud_clk;

    // TX Control & Data
    logic        i_tx_en;
    logic        i_tx_wren;
    logic [7:0]  i_tx_data;
    logic        i_tx_fifo_clr;

    // TX Status Outputs
    logic        o_tx_idle;
    logic        o_tx_done;
    logic        o_tx_fifo_empty;
    logic        o_tx_fifo_full;
    logic [5:0]  o_tx_fifo_level;
    logic        o_tx;

    // RX Signals (Tied off / Unused in this test)
    logic        i_rx_en;
    logic        i_rx_rden;
    logic        i_rx_fifo_clr;
    logic        i_rx;
    logic [7:0]  o_rx_data;
    logic        o_rx_idle;
    logic        o_rx_done;
    logic        o_rx_fifo_empty;
    logic        o_rx_fifo_full;
    logic [5:0]  o_rx_fifo_level;
    logic        o_rx_frame_error;
    logic        o_rx_parity_error;
    logic        o_rx_data_is_zero;

    // ==========================================
    // Clock Generation
    // ==========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        baud_clk = 0;
        forever #(BIT_TIME / 2) baud_clk = ~baud_clk;
    end

    // ==========================================
    // Waveform Dump
    // ==========================================
    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACM");
    end

    // ==========================================
    // DUT Instantiation
    // ==========================================
    uart_core dut (
        .i_clk               (clk),
        .i_rst_n             (rst_n),
        .i_bclk_en           (1'b1),
        .i_baud_divisor      (-16'd27), // 50MHz / (115200 * 16) = 27.12
        .i_parity_en         (1'b0),
        .i_even_parity       (1'b0),
        .i_dbg_lloopback     (1'b0),
        .i_dbg_sloopback     (1'b0),
        
        // TX Ports
        .i_tx_en             (i_tx_en),
        .i_tx_data           (i_tx_data),
        .i_tx_wren           (i_tx_wren),
        .o_tx_idle           (o_tx_idle),
        .o_tx_done           (o_tx_done),
        .i_tx_fifo_clr       (i_tx_fifo_clr),
        .o_tx_fifo_empty     (o_tx_fifo_empty),
        .o_tx_fifo_full      (o_tx_fifo_full),
        .o_tx_fifo_level     (o_tx_fifo_level),
        .o_tx                (o_tx),

        // RX Ports (Tied off)
        .i_rx_en             (i_rx_en),
        .i_rx_rden           (i_rx_rden),
        .i_rx_fifo_clr       (i_rx_fifo_clr),
        .i_rx                (i_rx),
        .o_rx_data           (o_rx_data),
        .o_rx_idle           (o_rx_idle),
        .o_rx_done           (o_rx_done),
        .o_rx_fifo_empty     (o_rx_fifo_empty),
        .o_rx_fifo_full      (o_rx_fifo_full),
        .o_rx_fifo_level     (o_rx_fifo_level),
        .o_rx_frame_error    (o_rx_frame_error),
        .o_rx_parity_error   (o_rx_parity_error),
        .o_rx_data_is_zero   (o_rx_data_is_zero)
    );

    // ==========================================
    // Tasks
    // ==========================================
    task write_tx_fifo(input logic [7:0] data);
        begin
            @(posedge clk);
            i_tx_wren <= 1'b1;
            i_tx_data <= data;
            @(posedge clk);
            i_tx_wren <= 1'b0;
        end
    endtask

    // ==========================================
    // Test Sequence
    // ==========================================
    initial begin
        // 1. Initialize
        rst_n         <= 1'b0;
        i_tx_en       <= 1'b0;
        i_tx_wren     <= 1'b0;
        i_tx_data     <= 8'h00;
        i_tx_fifo_clr <= 1'b0;
        i_rx_en       <= 1'b0;
        i_rx_rden     <= 1'b0;
        i_rx_fifo_clr <= 1'b0;
        i_rx          <= 1'b1;

        #(CLK_PERIOD * 10);
        rst_n <= 1'b1;
        #(CLK_PERIOD * 10);

        $display("---------------------------------------------------------");
        $display("[%0t] SCENARIO 1: Nạp FIFO trước, sau đó bật i_tx_en", $time);
        $display("---------------------------------------------------------");
        
        // Nạp 3 bytes vào FIFO khi i_tx_en = 0
        write_tx_fifo(8'h41); // 'A'
        write_tx_fifo(8'h42); // 'B'
        write_tx_fifo(8'h43); // 'C'
        
        #(CLK_PERIOD * 5);
        $display("[%0t] FIFO Level hiện tại: %0d", $time, o_tx_fifo_level);
        
        // Bật transmit enable
        @(posedge clk);
        i_tx_en <= 1'b1;
        
        // Giám sát quá trình truyền và o_tx_done
        while (!o_tx_fifo_empty || !o_tx_idle) begin
            @(posedge clk);
            if (o_tx_done) begin
                $display("[%0t] PULSE: o_tx_done kích hoạt (Hoàn tất 1 byte) | Mức FIFO còn: %0d", $time, o_tx_fifo_level);
            end
        end
        
        #(BIT_TIME * 2);

        $display("---------------------------------------------------------");
        $display("[%0t] SCENARIO 2: Vừa truyền vừa nạp (i_tx_en luôn bật)", $time);
        $display("---------------------------------------------------------");
        
        // Ghi byte 1
        write_tx_fifo(8'h44); // 'D'
        
        // Đợi 5 bit time rồi ghi tiếp byte 2 (giả lập ghi khi đang truyền dở byte 1)
        #(BIT_TIME * 5);
        write_tx_fifo(8'h45); // 'E'
        
        while (!o_tx_fifo_empty || !o_tx_idle) begin
            @(posedge clk);
            if (o_tx_done) begin
                $display("[%0t] PULSE: o_tx_done kích hoạt (Hoàn tất 1 byte) | Mức FIFO còn: %0d", $time, o_tx_fifo_level);
            end
        end

        #(BIT_TIME * 5);
        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule
