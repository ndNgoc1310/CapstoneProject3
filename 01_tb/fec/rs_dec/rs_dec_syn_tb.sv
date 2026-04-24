`timescale 1ns / 1ps
// =========================================================
// Testbench for Syndrome Calculator (rs_dec_syn)
// Simulator: Cadence Xcelium
// Location: 01_tb/fec/rs_dec/rs_dec_syn_tb.sv
// Function: Burst FSM Stimulus & Auto-checking
// =========================================================

module rs_dec_syn_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    parameter NSYM  = 30;
    parameter PACKET_SIZE = 544;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    logic             sop_in;
    logic             vld_in;
    logic [WIDTH-1:0] dat_in;

    // DUT Outputs
    logic             vld_out;
    logic             sys_rdy;
    logic             sys_err;
    // Unpacked Array matching DUT exactly
    logic [WIDTH-1:0] syn_out [NSYM-1:0];

    // File descriptors & Verification variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        
    int mismatch;       
    
    // Arrays for storing test vectors
    logic [WIDTH-1:0] in_array  [0:PACKET_SIZE-1];
    logic [WIDTH-1:0] exp_array [0:NSYM-1];

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec_syn #(
        .WIDTH(WIDTH),
        .NSYM(NSYM)
    ) DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .vld_in   (vld_in),
        .dat_in    (dat_in),
        .vld_out  (vld_out),
        .sys_rdy      (sys_rdy),
        .sys_err      (sys_err),
        .syn_out    (syn_out)
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
        #2000000; // Timeout sau 2ms (đủ thời gian cho >100 cases)
        $display("\n[%0t] \033[1;31mFATAL ERROR: Watchdog Timer Triggered!\033[0m", $time);
        $display("Simulation is stuck (FSM hang). Dumping waveforms and terminating.");
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
        // Khởi tạo tín hiệu mặc định
        sop_in   = 1'b0;
        vld_in = 1'b0;
        dat_in  = '0;

        // Mở file Test Vectors và Log
        in_fd  = $fopen("rs_dec_syn_in.hex", "r");
        exp_fd = $fopen("rs_dec_syn_out_exp.hex", "r");
        log_fd = $fopen("syn_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("FATAL ERROR: Khong the mo cac file I/O (.hex) hoac file log.");
            $finish;
        end

        $display("--- BAT DAU MO PHONG SYNDROME CALCULATOR ---");
        $fdisplay(log_fd, "--- SYNDROME CALCULATOR SIMULATION LOG ---");

        // Đợi hệ thống thoát Reset
        wait(rst_n == 1'b1);
        @(posedge clk); 

        // Vòng lặp đọc và xử lý từng Testcase
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // Đọc 544 symbol gói tin R(x)
            for (int i = 0; i < PACKET_SIZE; i++) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                in_array[i] = tmp_val;
            end
            
            // Đọc 30 giá trị Syndrome kỳ vọng (Từ S_29 lùi về S_0)
            for (int i = 0; i < NSYM; i++) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_array[i] = tmp_val;
            end

            if ($feof(in_fd) || $feof(exp_fd)) break; 
            
            test_idx++;
            mismatch = 0;

            // =========================================================
            // QUÁ TRÌNH BƠM DỮ LIỆU VÀ SO SÁNH (CHẠY SONG SONG)
            // =========================================================
            // Chờ module sẵn sàng nhận gói tin mới
            wait(sys_rdy == 1'b1);
            @(posedge clk);
            
            mismatch = 0; // Đặt lại cờ lỗi cho mỗi test case

            fork
                // --- THREAD 1: BƠM DỮ LIỆU (STIMULUS) ---
                begin
                    for (int c = 0; c < PACKET_SIZE; c++) begin
                        vld_in <= 1'b1;
                        dat_in <= in_array[c];
                        sop_in <= (c == 0) ? 1'b1 : 1'b0;
                        @(posedge clk);
                    end
                    // Kết thúc bơm gói tin
                    vld_in <= 1'b0;
                    sop_in <= 1'b0;
                    dat_in <= '0;
                end

                // --- THREAD 2: ĐÓN KẾT QUẢ (CHECKER) ---
                begin
                    wait(vld_out == 1'b1 || sys_err == 1'b1);

                    // Xử lý nếu FSM nảy cờ lỗi
                    if (sys_err == 1'b1) begin
                        $display("[%0t] Testcase %0d: \033[1;31mFAIL\033[0m (FSM Error Asserted!)", $time, test_idx);
                        $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL (FSM Error Asserted!)", $time, test_idx);
                        fail_cnt++;
                        mismatch = 1;
                    end else begin
                        // Đợi 1ns sau sườn Clock để tín hiệu tổ hợp xuất ra Data hoàn chỉnh
                        #1;

                        // Kiểm tra toàn bộ 30 mảng giá trị Syndrome
                        for (int i = 0; i < NSYM; i++) begin
                            if (syn_out[i] !== exp_array[NSYM - 1 - i]) begin
                                mismatch = 1;
                                $display("  [MISMATCH] S%0d | Exp = %x, Act = %x", i, exp_array[NSYM - 1 - i], syn_out[i]);
                                $fdisplay(log_fd, "  [MISMATCH] S%0d | Exp = %x, Act = %x", i, exp_array[NSYM - 1 - i], syn_out[i]);
                            end
                        end
                        
                        // Ghi nhận Pass/Fail
                        if (mismatch) begin
                            fail_cnt++;
                            $display("[%0t] Testcase %0d: \033[1;31mFAIL\033[0m", $time, test_idx);
                            $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL", $time, test_idx);
                        end else begin
                            pass_cnt++;
                            $display("[%0t] Testcase %0d: \033[1;32mPASS\033[0m", $time, test_idx);
                            $fdisplay(log_fd, "[%0t] Testcase %0d: PASS", $time, test_idx);
                        end
                    end
                end
            join
            
            // Đợi FSM reset lại state IDLE nếu bị lỗi
            if (sys_err == 1'b1) begin
                wait(sys_rdy == 1'b1);
                continue;
            end

        end

        // ---------------------------------------------------------
        // 7. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   SYNDROME SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Cases : %0d", test_idx);
        $display("   Passed      : %0d", pass_cnt);
        $display("   Failed      : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   SYNDROME SIMULATION COMPLETED");
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

endmodule: rs_dec_syn_tb
