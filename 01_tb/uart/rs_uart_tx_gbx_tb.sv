`timescale 1ns/1ps

module rs_uart_tx_gbx_tb;

    // ==========================================
    // Parameters
    // ==========================================
    parameter CLK_PERIOD = 20; // 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8680.5 ns

    // ==========================================
    // System Signals
    // ==========================================
    logic clk;
    logic rst_n;
    logic baud_clk;

    // Buffer Input Signals
    logic       rs_tx_vld;
    logic [9:0] rs_tx_dat;

    // Interconnect: Buffer -> Gearbox
    logic       buf_tx_vld;
    logic [9:0] buf_tx_dat;
    logic       buf_tx_err;
    logic       gbx_tx_rdy;

    // Interconnect: Gearbox -> UART Core
    logic       gbx_tx_vld;
    logic [7:0] gbx_tx_dat;
    logic       gbx_tx_err;

    // Interconnect: UART Core -> Gearbox
    logic       uart_tx_done;
    logic       uart_tx_idle;
    logic       uart_tx_out;

    // TB Kickstart Multiplexer
    logic       tb_kick_wren;
    logic [7:0] tb_kick_data;
    logic       core_tx_wren;
    logic [7:0] core_tx_data;

    integer     bytes_transmitted;

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
    // Multiplexer for Deadlock Kickstart
    // ==========================================
    assign core_tx_wren = gbx_tx_vld | tb_kick_wren;
    assign core_tx_data = tb_kick_wren ? tb_kick_data : gbx_tx_dat;

    // ==========================================
    // Instantiation: TX Buffer
    // ==========================================
    rs_uart_tx_buf u_buf (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs_tx_vld  (rs_tx_vld),
        .rs_tx_dat  (rs_tx_dat),
        .gbx_tx_done(gbx_tx_done),
        .buf_tx_vld (buf_tx_vld),
        .buf_tx_dat (buf_tx_dat),
        .buf_tx_err (buf_tx_err)
    );

    // ==========================================
    // Instantiation: TX Gearbox
    // ==========================================
    rs_uart_tx_gbx u_gbx (
        .clk          (clk),
        .rst_n        (rst_n),
        .buf_tx_vld   (buf_tx_vld),
        .buf_tx_dat   (buf_tx_dat),
        .uart_tx_done (uart_tx_done),
        .gbx_tx_vld   (gbx_tx_vld),
        .gbx_tx_dat   (gbx_tx_dat),
        .gbx_tx_done  (gbx_tx_done),
        .gbx_tx_err   (gbx_tx_err)
    );

    // ==========================================
    // Instantiation: UART Core (TX)
    // ==========================================
    uart_core u_uart (
        .i_clk             (clk),
        .i_rst_n           (rst_n),
        .i_bclk_en         (1'b1),
        .i_baud_divisor    (-16'd27),
        .i_parity_en       (1'b0),
        .i_even_parity     (1'b0),
        .i_dbg_lloopback   (1'b0),
        .i_dbg_sloopback   (1'b0),
        
        // TX Ports
        .i_tx_en           (1'b1), // Luôn enable để UART tự động rút FIFO
        .i_tx_data         (core_tx_data),
        .i_tx_wren         (core_tx_wren),
        .i_tx_fifo_clr     (~rst_n),
        .o_tx_idle         (uart_tx_idle),
        .o_tx_done         (uart_tx_done),
        .o_tx              (uart_tx_out),
        .o_tx_fifo_empty   (),
        .o_tx_fifo_full    (),
        .o_tx_fifo_level   (),

        // RX Ports (Tied off)
        .i_rx_en           (1'b0),
        .i_rx_rden         (1'b0),
        .i_rx_fifo_clr     (1'b0),
        .i_rx              (1'b1),
        .o_rx_data         (),
        .o_rx_idle         (),
        .o_rx_done         (),
        .o_rx_fifo_empty   (),
        .o_rx_fifo_full    (),
        .o_rx_fifo_level   (),
        .o_rx_frame_error  (),
        .o_rx_parity_error (),
        .o_rx_data_is_zero ()
    );

    // ==========================================
    // Tasks
    // ==========================================
    task burst_feed(input int count);
        begin
            for (int i = 0; i < count; i++) begin
                @(posedge clk);
                rs_tx_vld <= 1'b1;
                rs_tx_dat <= (i % 2 == 0) ? 10'h3FF : 10'h000;
            end
            @(posedge clk);
            rs_tx_vld <= 1'b0;
            rs_tx_dat <= 10'd0;
        end
    endtask

    // Monitor TX Count
    logic uart_tx_done_prv;
    logic uart_tx_done_edge;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) uart_tx_done_prv <= 1'b0;
        else        uart_tx_done_prv <= uart_tx_done;
    end

    // Phát hiện sườn lên (0 -> 1)
    assign uart_tx_done_edge = uart_tx_done & ~uart_tx_done_prv;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) bytes_transmitted <= 0;
        else if (uart_tx_done_edge) bytes_transmitted <= bytes_transmitted + 1;
    end

    // ==========================================
    // Main Test Sequence
    // ==========================================
    initial begin
        rst_n        <= 1'b0;
        rs_tx_vld    <= 1'b0;
        rs_tx_dat    <= 10'd0;
        tb_kick_wren <= 1'b0;
        tb_kick_data <= 8'h00;

        #(CLK_PERIOD * 10);
        rst_n <= 1'b1;
        #(CLK_PERIOD * 10);

        $display("---------------------------------------------------------");
        $display("[%0t] STARTING INTEGRATION TEST (RS_BUF -> GBX -> UART)", $time);
        
        // -------------------------------------------------------------
        // DEADLOCK KICKSTART:
        // Mồi 1 byte rác vào UART để ép UART truyền và tạo ra sườn xuống 
        // của uart_tx_done. Nếu không có bước này, GBX sẽ kẹt ở trạng 
        // thái READY vĩnh viễn.
        // -------------------------------------------------------------
        $display("[%0t] KICKSTART: Sending dummy byte to force o_tx_done", $time);
        @(posedge clk);
        tb_kick_wren <= 1'b1;
        tb_kick_data <= 8'hFF;
        @(posedge clk);
        tb_kick_wren <= 1'b0;

        // Nạp burst 544 symbol vào Buffer
        $display("[%0t] Nạp chuỗi 544 symbols vào Buffer...", $time);
        burst_feed(544);

        // Đợi cho đến khi truyền xong 680 byte thực tế + 1 byte mồi = 681 bytes
        wait(bytes_transmitted == 681);
        
        // Đợi thêm vài bit time cho UART hoàn tất tín hiệu idle
        #(BIT_TIME * 10);

        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

    // ==========================================
    // Watchdog Timer (Timeout Guard)
    // ==========================================
    initial begin
        // Giới hạn thời gian mô phỏng ở mức 1500 UART frames
        #(BIT_TIME * 15000); 
        
        $display("---------------------------------------------------------");
        $display("[%0t] FATAL ERROR: SIMULATION TIMEOUT REACHED!", $time);
        $display("Hệ thống bị treo (Deadlock/Infinite Loop). Ngắt mô phỏng để dump waveform.");
        $display("---------------------------------------------------------");
        
        $finish;
    end

endmodule
