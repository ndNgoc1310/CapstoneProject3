`timescale 1ns/1ps

module rs_dec_syn_tb;

    // --- Signals ---
    logic clk;
    logic rst_n;
    logic sop;
    logic valid_in;
    logic [9:0] data_in;
    logic valid_out;
    logic [9:0] syndromes [29:0]; // Output từ DUT

    // --- Test Data Memories ---
    logic [9:0] rx_mem [0:543];         // Input codeword (544 symbols)
    logic [9:0] exp_syn_mem [0:29];     // Expected syndromes (30 symbols)

    // --- Variables ---
    int i;
    int error_count = 0;

    // --- Instantiate DUT ---
    rs_dec_syn dut (
        .clk(clk),
        .rst_n(rst_n),
        .sop(sop),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .syndromes(syndromes)
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
        // 1. Load Test Vectors
        $readmemh("rs_dec_syn_input.hex", rx_mem);
        $readmemh("rs_dec_output_exp.hex", exp_syn_mem);
        
        // 2. Initialize
        rst_n = 0;
        sop = 0;
        valid_in = 0;
        data_in = 0;
        
        #20 rst_n = 1;
        #10;

        $display("--- BẮT ĐẦU MÔ PHỎNG SYNDROME CALC ---");

        // 3. Drive Input Data
        // Gửi 544 symbols liên tục
        for (i = 0; i < 544; i++) begin
            @(posedge clk);
            valid_in = 1;
            data_in = rx_mem[i];
            
            // SOP chỉ bật ở symbol đầu tiên
            if (i == 0) sop = 1;
            else sop = 0;
        end

        // 4. Kết thúc gói tin
        @(posedge clk);
        valid_in = 0;
        data_in = 0;
        sop = 0;

        // 5. Chờ kết quả (valid_out)
        // DUT sẽ bật valid_out ngay khi nhận đủ 544 symbol (hoặc sau 1 clock tùy logic)
        wait(valid_out);
        @(negedge clk); // Kiểm tra tại sườn xuống để ổn định

        // 6. So sánh kết quả
        $display("--- KIỂM TRA KẾT QUẢ ---");
        for (int k = 0; k < 30; k++) begin
            if (syndromes[k] !== exp_syn_mem[k]) begin
                $display("[FAIL] Syndrome S%0d: Exp = %h, Act = %h", k, exp_syn_mem[k], syndromes[k]);
                error_count++;
            end else begin
                $display("[PASS] Syndrome S%0d: %h", k, syndromes[k]);
            end
        end

        if (error_count == 0) 
            $display(">> TẤT CẢ SYNDROME CHÍNH XÁC! <<");
        else 
            $display(">> CÓ %0d LỖI XẢY RA <<", error_count);

        #100 $finish;
    end

endmodule
