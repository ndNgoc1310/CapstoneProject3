`timescale 1ns/1ps

module wrapper_uart_tb;

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
    logic rs_sel;

    // ==========================================
    // Local Variables (Tham khảo wrapper_uart)
    // ==========================================
    // UART Core
    logic       uart_rx_en;
    logic       uart_rx_rden;
    logic [7:0] uart_rx_dat;
    logic       uart_rx_empty;
    logic       uart_rx_serial;

    logic       uart_tx_en;
    logic       uart_tx_wren;
    logic [7:0] uart_tx_dat;
    logic       uart_tx_empty;
    logic       uart_tx_serial;

    // RX Gearbox -> RX Buffer
    logic       gbx_rx_vld;
    logic [9:0] gbx_rx_dat;
    logic       gbx_rx_end;

    // RX Buffer -> RS Codec
    logic       buf_rx_sop;
    logic       buf_rx_vld;
    logic [9:0] buf_rx_dat;

    // RS Codec -> TX Buffer
    logic       rs_tx_vld;
    logic [9:0] rs_tx_dat;

    // TX Buffer -> TX Gearbox
    logic       buf_tx_vld;
    logic [9:0] buf_tx_dat;

    // TX Gearbox -> UART TX
    logic       gbx_tx_vld;
    logic [7:0] gbx_tx_dat;
    logic       gbx_tx_done;
    logic       gbx_tx_end;

    // RS Codec (Top) Signals
    logic       enc_sop, enc_vld, enc_rdy, enc_err;
    logic [9:0] enc_dat;
    logic       dec_sop, dec_vld, dec_rdy, dec_err, dec_err_flg;
    logic [9:0] dec_dat, dec_err_mag;

    // ==========================================
    // Testbench Variables & Queues
    // ==========================================
    logic [7:0] encoded_data_queue [$]; // Queue lưu trữ 680 byte Output từ tình huống 1
    logic       gbx_tx_byte_count_rst;
    integer     gbx_tx_byte_count;      // Bộ đếm giám sát số byte GBX TX đã xuất ra

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
    // Watchdog Timer (Tránh kẹt vĩnh viễn)
    // ==========================================
    initial begin
        #(BIT_TIME * 50000); 
        $display("\n[%0t] FATAL: SIMULATION TIMEOUT!", $time);
        $display("Hệ thống bị treo. Tiến hành đóng giả lập để lưu waveform.");
        $finish;
    end

    // ==========================================
    // Mux Assignments & Toggling Logic
    // ==========================================
    assign uart_tx_wren = gbx_tx_vld;
    assign uart_tx_dat  = gbx_tx_dat;

    assign rs_tx_vld = (rs_sel == 1'b0) ? enc_vld : dec_vld;
    assign rs_tx_dat = (rs_sel == 1'b0) ? enc_dat : dec_dat;

    // --- UART RX Control Logic theo đúng yêu cầu ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            uart_rx_en   <= 1'b1;
            uart_rx_rden <= 1'b1;  
        end else if (gbx_rx_end) begin 
            // Nhận đủ -> Tắt RX tránh nhiễu
            uart_rx_en   <= 1'b0;  
            uart_rx_rden <= 1'b0;
        end else if (gbx_tx_end) begin 
            // Xử lý và mồi truyền xong -> Mở lại RX
            uart_rx_en   <= 1'b1;  
            uart_rx_rden <= 1'b1;
        end
    end

    // --- Data Capture Monitor (Bắt data trực tiếp từ gbx xuất cho uart) ---
    always_ff @(posedge clk or posedge gbx_tx_byte_count_rst) begin
        if (gbx_tx_byte_count_rst) begin
            gbx_tx_byte_count <= 0;
        end else begin
            if (gbx_tx_vld) begin
                gbx_tx_byte_count <= gbx_tx_byte_count + 1;
                // Nếu đang ở Encode (Tình huống 1), lưu kết quả lại
                if (rs_sel == 1'b0) begin
                    encoded_data_queue.push_back(gbx_tx_dat);
                end
            end
        end
    end

    // ==========================================
    // MODULE INSTANTIATIONS 
    // ==========================================

    // 1. Lõi UART
    uart_core uart_core (
        .i_clk              (clk),
        .i_rst_n            (rst_n),
        .i_bclk_en          (1'b1),
        .i_baud_divisor     (-16'd27), 
        .i_parity_en        (1'b0),
        .i_even_parity      (1'b0),
        .i_dbg_lloopback    (1'b0),
        .i_dbg_sloopback    (1'b0),
        
        .i_tx_en            (1'b1), // Enable cứng để tự động TX
        .i_tx_wren          (uart_tx_wren),
        .i_tx_data          (uart_tx_dat),
        .o_tx_idle          (),
        .o_tx_done          (),
        .i_tx_fifo_clr      (~rst_n),
        .o_tx_fifo_empty    (uart_tx_empty),
        .o_tx_fifo_full     (),
        .o_tx_fifo_level    (),
        
        .i_rx_en            (uart_rx_en),
        .i_rx_rden          (uart_rx_rden), 
        .o_rx_data          (uart_rx_dat),
        .o_rx_idle          (),
        .o_rx_done          (),
        .i_rx_fifo_clr      (~rst_n),
        .o_rx_fifo_empty    (uart_rx_empty),
        .o_rx_fifo_full     (),
        .o_rx_fifo_level    (),
        .o_rx_frame_error   (),
        .o_rx_parity_error  (),
        .o_rx_data_is_zero  (),
        
        .o_tx               (uart_tx_serial),
        .i_rx               (uart_rx_serial)
    );

    // 2. RX Gearbox
    rs_uart_rx_gbx rs_uart_rx_gbx (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs_sel         (rs_sel),
        .uart_rx_empty  (uart_rx_empty),
        .uart_rx_dat    (uart_rx_dat),
        .gbx_rx_vld     (gbx_rx_vld),
        .gbx_rx_dat     (gbx_rx_dat),
        .gbx_rx_end     (gbx_rx_end),
        .gbx_rx_err     ()
    );

    // 3. RX Buffer
    rs_uart_rx_buf rs_uart_rx_buf (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs_sel         (rs_sel),
        .gbx_rx_vld     (gbx_rx_vld),
        .gbx_rx_dat     (gbx_rx_dat),
        .buf_rx_sop     (buf_rx_sop),
        .buf_rx_vld     (buf_rx_vld),
        .buf_rx_dat     (buf_rx_dat),
        .buf_rx_err     ()
    );

    // 4. RS Codec (Top)
    top #(.WIDTH(10), .NSYM(30), .ORDER(15), .K(544)) rs_codec (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // Encoder Interconnect
        .enc_sop_in         ((rs_sel == 1'b0) ? buf_rx_sop : 1'b0),
        .enc_vld_in         ((rs_sel == 1'b0) ? buf_rx_vld : 1'b0),
        .enc_dat_in         ((rs_sel == 1'b0) ? buf_rx_dat : 10'b0),
        .enc_sop_out        (enc_sop),
        .enc_vld_out        (enc_vld),
        .enc_dat_out        (enc_dat),
        .enc_rdy            (enc_rdy),
        .enc_err            (enc_err),
        
        // Decoder Interconnect
        .dec_sop_in         ((rs_sel == 1'b1) ? buf_rx_sop : 1'b0),
        .dec_vld_in         ((rs_sel == 1'b1) ? buf_rx_vld : 1'b0),
        .dec_dat_in         ((rs_sel == 1'b1) ? buf_rx_dat : 10'b0),
        .dec_sop_out        (dec_sop),
        .dec_vld_out        (dec_vld),
        .dec_dat_out        (dec_dat),
        .dec_rdy            (dec_rdy),
        .dec_err            (dec_err),
        .dec_err_flg_out    (dec_err_flg),
        .dec_err_mag_out    (dec_err_mag)
    );

    // 5. TX Buffer
    rs_uart_tx_buf rs_uart_tx_buf (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs_sel         (rs_sel),
        .rs_tx_vld      (rs_tx_vld),
        .rs_tx_dat      (rs_tx_dat),
        .gbx_tx_done    (gbx_tx_done), // Map tín hiệu Done
        .buf_tx_vld     (buf_tx_vld),
        .buf_tx_dat     (buf_tx_dat),
        .buf_tx_err     ()
    );

    // 6. TX Gearbox
    rs_uart_tx_gbx rs_uart_tx_gbx (
        .clk            (clk),
        .rst_n          (rst_n),
        .buf_tx_vld     (buf_tx_vld),
        .buf_tx_dat     (buf_tx_dat),   
        .uart_tx_empty  (uart_tx_empty),    
        .gbx_tx_vld     (gbx_tx_vld),
        .gbx_tx_dat     (gbx_tx_dat),
        .gbx_tx_done    (gbx_tx_done),
        .gbx_tx_end     (gbx_tx_end),
        .gbx_tx_err     ()
    );

    // ==========================================
    // Task: Gửi tín hiệu UART từ PC (Giả lập PC)
    // ==========================================
    task pc_send_uart_byte(input logic [7:0] tx_data);
        integer i;
        begin
            uart_rx_serial = 1'b0; // Start bit
            #(BIT_TIME);
            
            for (i = 0; i < 8; i++) begin
                uart_rx_serial = tx_data[i];
                #(BIT_TIME);
            end
            
            uart_rx_serial = 1'b1; // Stop bit
            #(BIT_TIME);
            #(BIT_TIME * 2);       // Inter-byte gap
        end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================
    integer i;

    initial begin
        // Reset hệ thống
        rst_n          = 1'b0;
        rs_sel         = 1'b0;
        uart_rx_serial = 1'b1;
        gbx_tx_byte_count_rst = 1'b1;
        encoded_data_queue.delete();

        #(CLK_PERIOD * 10);
        rst_n = 1'b1;
        #(CLK_PERIOD * 5);
        gbx_tx_byte_count_rst = 1'b0;
        #(CLK_PERIOD * 5);

        // =========================================================================
        // TÌNH HUỐNG 1: RS_ENC (Encode Mode)
        // =========================================================================
        $display("---------------------------------------------------------");
        $display("[%0t] TÌNH HUỐNG 1: RS_ENC - Gửi 642 bytes xen kẽ 'a' (0x61) và 'b' (0x62)", $time);
        
        rs_sel = 1'b0; 

        // Truyền 642 bytes qua UART giả lập PC
        for (i = 0; i < 642; i++) begin
            pc_send_uart_byte((i % 2 == 0) ? 8'h61 : 8'h62);
        end

        // Chờ Output từ encoder. Khối encoder sẽ tạo ra 544 symbol = 5440 bits = 680 bytes.
        wait (gbx_tx_byte_count == 680);
        $display("[%0t] Encode Hoàn Tất! Đã bắt được %0d bytes trả về.", $time, encoded_data_queue.size());
        
        // Đợi một khoảng thời gian cho Hardware UART TX xả dứt điểm byte cuối ra đường truyền
        #(BIT_TIME * 20);

        // =========================================================================
        // TÌNH HUỐNG 2: RS_DEC (Decode Mode)
        // =========================================================================
        $display("---------------------------------------------------------");
        $display("[%0t] TÌNH HUỐNG 2: RS_DEC - Gửi 680 bytes vừa thu được từ bộ Encode", $time);
        
        // Chuyển Mode và Reset lại biến theo dõi
        rs_sel = 1'b1;

        // Reset toàn hệ thống để xóa sạch pipeline cũ trước khi bơm gói mới
        rst_n = 1'b0;
        gbx_tx_byte_count_rst = 1'b1;
        #(CLK_PERIOD * 10);
        rst_n = 1'b1;
        #(CLK_PERIOD * 5);
        gbx_tx_byte_count_rst = 1'b0;
        #(CLK_PERIOD * 5);

        // Bơm ngược 680 bytes đã hứng từ tình huống 1 vào lại UART RX
        while (encoded_data_queue.size() > 0) begin
            logic [7:0] byte_to_send;
            byte_to_send = encoded_data_queue.pop_front();
            pc_send_uart_byte(byte_to_send);
        end

        // Decoder sẽ giải mã và trả lại payload ban đầu gồm 544 symbol = 5440 bits = 680 bytes
        wait (gbx_tx_byte_count == 680);
        $display("[%0t] Decode Hoàn Tất! Gói tin đã chạy qua toàn bộ pipeline thành công.", $time);

        #(BIT_TIME * 20);
        $display("---------------------------------------------------------");
        $display("[%0t] SIMULATION COMPLETED SUCCESSFULLY", $time);
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule