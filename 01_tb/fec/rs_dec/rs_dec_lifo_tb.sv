`timescale 1ns / 1ps
// =========================================================
// Testbench for LIFO Buffer (rs_dec_lifo)
// Simulator: Cadence Xcelium
// Location: 01_tb/fec/rs_dec/rs_dec_lifo_tb.sv
// Function: Auto-checking Push/Pop operations with Read Latency
// =========================================================

module rs_dec_lifo_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    parameter PACKET_SIZE = 544;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    logic             push_sop;
    logic             push_en;
    logic [WIDTH-1:0] dat_in;
    logic             pop_sop;
    logic             pop_en;

    // DUT Outputs
    logic             vld_out;
    logic [WIDTH-1:0] dat_out;

    // File descriptors & Verification variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        
    int mismatch;       
    
    // Arrays for storing test vectors (1 Packet = 544 Symbols)
    logic [WIDTH-1:0] in_array  [0:PACKET_SIZE-1];
    logic [WIDTH-1:0] exp_array [0:PACKET_SIZE-1];

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec_lifo #(
        .WIDTH(WIDTH),
        .K(PACKET_SIZE)
    ) DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .push_sop   (push_sop),
        .push_en    (push_en),
        .dat_in    (dat_in),
        .pop_sop    (pop_sop),
        .pop_en     (pop_en),
        .vld_out  (vld_out),
        .dat_out   (dat_out)
    );

    // ---------------------------------------------------------
    // 3. CLOCK & RESET GENERATION
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100MHz Clock (T=10ns)
    end

    initial begin
        rst_n = 1'b0;
        #23; 
        rst_n = 1'b1;
    end

    // ---------------------------------------------------------
    // 4. WATCHDOG TIMER (ANTI-DEADLOCK)
    // ---------------------------------------------------------
    initial begin
        #2000000; // Timeout sau 2ms
        $display("\n[%0t] \033[1;31mFATAL ERROR: Watchdog Timer Triggered!\033[0m", $time);
        $display("Simulation is stuck. Dumping waveforms and terminating.");
        $finish;
    end

    // ---------------------------------------------------------
    // 5. CADENCE XCELIUM SHM DUMPING
    // ---------------------------------------------------------
    initial begin
        $shm_open("waves.shm"); 
        $shm_probe("ACM");       
    end

    // ---------------------------------------------------------
    // 6. MAIN STIMULUS & AUTO-CHECKING
    // ---------------------------------------------------------
    initial begin
        // Khởi tạo tín hiệu mặc định (Default States)
        push_sop = 1'b0;
        push_en  = 1'b0;
        dat_in  = '0;
        pop_sop  = 1'b0;
        pop_en   = 1'b0;

        // Mở file Test Vectors và Log
        in_fd  = $fopen("rs_dec_lifo_in.hex", "r");
        exp_fd = $fopen("rs_dec_lifo_out_exp.hex", "r");
        log_fd = $fopen("lifo_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("ERROR: Khong the mo cac file I/O (.hex) hoac file log.");
            $finish;
        end

        $display("--- BAT DAU MO PHONG LIFO BUFFER ---");
        $fdisplay(log_fd, "--- LIFO SIMULATION LOG ---");

        // Đợi hệ thống thoát Reset
        wait(rst_n == 1'b1);
        @(posedge clk); 

        // Vòng lặp đọc và xử lý từng Testcase
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // Đọc 544 giá trị Input
            for (int i = 0; i < PACKET_SIZE; i++) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                in_array[i] = tmp_val;
            end
            
            // Đọc 544 giá trị Expected Output
            for (int i = 0; i < PACKET_SIZE; i++) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_array[i] = tmp_val;
            end

            if ($feof(in_fd) || $feof(exp_fd)) break; 
            
            test_idx++;
            mismatch = 0;

            // =========================================================
            // PHASE 1: QUÁ TRÌNH GHI (PUSH)
            // =========================================================
            for (int c = 0; c < PACKET_SIZE; c++) begin
                @(posedge clk);
                push_en  <= 1'b1;
                push_sop <= (c == 0) ? 1'b1 : 1'b0;
                dat_in  <= in_array[c];
            end
            
            // Kết thúc ghi gói tin
            @(posedge clk);
            push_en  <= 1'b0;
            push_sop <= 1'b0;
            dat_in  <= '0;

            // Nghỉ 2 nhịp clock để mô phỏng độ trễ thực tế giữa các block
            #20; 

            // =========================================================
            // PHASE 2: QUÁ TRÌNH ĐỌC (POP) VÀ SO SÁNH (CHECKING)
            // =========================================================
            // Vòng lặp chạy tới PACKET_SIZE (544) để kịp check dữ liệu của nhịp 543 bị trễ
            for (int c = 0; c <= PACKET_SIZE; c++) begin
                @(posedge clk);
                
                // 1. Cấp tín hiệu Đọc (Drive Pop Signals) cho nhịp c
                if (c < PACKET_SIZE) begin
                    pop_en  <= 1'b1;
                    pop_sop <= (c == 0) ? 1'b1 : 1'b0;
                end else begin
                    // Đã phát đủ 544 lệnh đọc, tắt tín hiệu điều khiển
                    pop_en  <= 1'b0;
                    pop_sop <= 1'b0;
                end

                // 2. Chờ điện áp ổn định sau sườn Clock
                #1; 
                
                // 3. Kiểm tra dữ liệu bị trễ 1 nhịp (Read Latency = 1)
                // Dữ liệu đọc ở nhịp c-1 sẽ xuất hiện trên đường dat_out tại nhịp c
                if (c > 0) begin
                    if (dat_out !== exp_array[c-1] || vld_out !== 1'b1) begin
                        mismatch = 1;
                        $display("\033[1;31m[FAIL]\033[0m Test %0d | Cycle %0d: Exp = %x, Act = %x (Valid = %b)", 
                                 test_idx, c-1, exp_array[c-1], dat_out, vld_out);
                        $fdisplay(log_fd, "[FAIL] Test %0d | Cycle %0d: Exp = %x, Act = %x (Valid = %b)", 
                                 test_idx, c-1, exp_array[c-1], dat_out, vld_out);
                    end
                end
            end

            // =========================================================
            // TỔNG KẾT TESTCASE
            // =========================================================
            if (mismatch) begin
                fail_cnt++;
                $display("[%0t] Testcase %0d: \033[1;31mFAIL\033[0m", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL", $time, test_idx);
            end else begin
                pass_cnt++;
                $display("[%0t] Testcase %0d: \033[1;32mPASS\033[0m", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: PASS", $time, test_idx);
            end

            // Nghỉ 1 nhịp clock trước khi nạp Testcase tiếp theo
            @(posedge clk);
            pop_en <= 1'b0;
        end

        // ---------------------------------------------------------
        // 7. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   LIFO BUFFER SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Cases : %0d", test_idx);
        $display("   Passed      : %0d", pass_cnt);
        $display("   Failed      : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   LIFO BUFFER SIMULATION COMPLETED");
        $fdisplay(log_fd, "=============================================");
        $fdisplay(log_fd, "   Total Cases : %0d", test_idx);
        $fdisplay(log_fd, "   Passed      : %0d", pass_cnt);
        $fdisplay(log_fd, "   Failed      : %0d", fail_cnt);
        $fdisplay(log_fd, "=============================================\n");

        // Dọn dẹp tài nguyên
        $fclose(in_fd);
        $fclose(exp_fd);
        $fclose(log_fd);
        $finish;
    end

endmodule: rs_dec_lifo_tb
