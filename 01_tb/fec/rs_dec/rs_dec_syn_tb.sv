`timescale 1ns/1ps

module rs_dec_syn_tb;

    // --- Signals ---
    logic clk;
    logic rst_n;
    logic sop_in;
    logic valid_in;
    logic [9:0] data_in;
    logic valid_out;
    logic ready;
    logic error;
    logic [9:0] syn_out [29:0]; // Output từ DUT

    // --- Test Data Memories ---
    logic [9:0] rx_mem [0:543];         // Input codeword (544 symbols)
    logic [9:0] exp_syn_mem [0:29];     // Expected syn_out (30 symbols)

    // --- Variables ---
    int i;
    int error_count = 0;

    // --- Instantiate DUT ---
    rs_dec_syn dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .valid_in   (valid_in),
        .data_in    (data_in),
        .valid_out  (valid_out),
        .ready      (ready),
        .error      (error),
        .syn_out    (syn_out)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Waveform Dump ---
    initial begin
        $shm_open("waves.shm");
        
        // A (All): Tất cả tín hiệu.
        // C (Cells): Các kết nối trong module con. 
        // M (Memories): Mảng, memory.
        // T (Transactions): Ghi lại các giao dịch (nếu có).
        $shm_probe("ACMT"); 
    end

    // --- Main Test Process ---
    initial begin
        // 1. Đọc dữ liệu của golden model từ file hex
        $readmemh("rs_dec_syn_input.hex", rx_mem);
        $readmemh("rs_dec_output_exp.hex", exp_syn_mem);
        
        // 2. Khởi tạo tín hiệu
        rst_n = 0;
        sop_in = 0;
        valid_in = 0;
        data_in = 0;
        
        // 3. Reset DUT
        #20 rst_n = 1;
        #10;

        $display("--- BẮT ĐẦU MÔ PHỎNG SYNDROME CALC ---");

        // 4. Gửi dữ liệu vào DUT
        wait(ready); // Chờ DUT sẵn sàng
        @(posedge clk);

        // Gửi 544 symbols liên tục
        for (i = 0; i < 544; i++) begin
            @(posedge clk);
            valid_in = 1;
            data_in = rx_mem[i];
            
            // sop_in chỉ bật ở symbol đầu tiên
            if (i == 0) sop_in = 1;
            else sop_in = 0;
        end

        // 5. Kết thúc gói tin
        @(posedge clk);
        valid_in = 0;
        data_in = 0;
        sop_in = 0;

        // 6. Chờ kết quả 
        wait(ready);    // 

        // 6. So sánh kết quả
        $display("--- KIỂM TRA KẾT QUẢ ---");
        for (int k = 0; k < 30; k++) begin
            if (syn_out[k] !== exp_syn_mem[k]) begin
                $display("[FAIL] Syndrome S%0d: Exp = %h, Act = %h", k, exp_syn_mem[k], syn_out[k]);
                error_count++;
            end else begin
                $display("[PASS] Syndrome S%0d: %h", k, syn_out[k]);
            end
        end

        // 7. Kết luận số lượng lỗi
        if (error_count == 0) 
            $display(">> TẤT CẢ SYNDROME CHÍNH XÁC! <<");
        else 
            $display(">> CÓ %0d LỖI XẢY RA <<", error_count);

        #100 $finish;
    end

endmodule
