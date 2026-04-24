`timescale 1ns / 1ps
// =========================================================
// Testbench for Reed-Solomon Encoder (rs_enc)
// Simulator: Cadence Xcelium
// Location: 01_tb/fec/rs_enc/rs_enc_tb.sv
// Function: Parallel Stimulus & Auto-checking (Fork-Join)
// =========================================================

module rs_enc_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH    = 10;
    parameter NSYM     = 30;
    parameter MSG_LEN  = 514;
    parameter CW_LEN   = 544;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    logic             sop_in;
    logic             vld_in;
    logic [WIDTH-1:0] dat_in;

    // DUT Outputs
    logic             sop_out;
    logic             vld_out;
    logic [WIDTH-1:0] dat_out;
    logic             sys_rdy;
    logic             sys_err;

    // File descriptors & Verification variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        
    int mismatch;       
    
    // Arrays for storing test vectors
    logic [WIDTH-1:0] in_array  [0:MSG_LEN-1];
    logic [WIDTH-1:0] exp_array [0:CW_LEN-1];

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_enc #(
        .WIDTH(WIDTH),
        .NSYM(NSYM)
    ) DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (sop_in),
        .vld_in   (vld_in),
        .dat_in    (dat_in),
        .sop_out    (sop_out),
        .vld_out  (vld_out),
        .dat_out   (dat_out),
        .sys_rdy      (sys_rdy),
        .sys_err      (sys_err)
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
        in_fd  = $fopen("rs_dec_enc_in.hex", "r");
        exp_fd = $fopen("rs_dec_enc_out_exp.hex", "r");
        log_fd = $fopen("enc_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("FATAL ERROR: Khong the mo cac file I/O (.hex) hoac file log.");
            $finish;
        end

        $display("--- BAT DAU MO PHONG REED-SOLOMON ENCODER ---");
        $fdisplay(log_fd, "--- ENCODER SIMULATION LOG ---");

        // Đợi hệ thống thoát Reset
        wait(rst_n == 1'b1);
        @(posedge clk); 

        // Vòng lặp đọc và xử lý từng Testcase
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // Đọc 514 symbol gói tin Message
            for (int i = 0; i < MSG_LEN; i++) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                in_array[i] = tmp_val;
            end
            
            // Đọc 544 symbol Codeword kỳ vọng
            for (int i = 0; i < CW_LEN; i++) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_array[i] = tmp_val;
            end

            if ($feof(in_fd) || $feof(exp_fd)) break; 
            
            test_idx++;
            mismatch = 0;

            // Chờ module sẵn sàng nhận gói tin mới
            wait(sys_rdy == 1'b1);
            @(posedge clk);

            // =========================================================
            // THỰC THI PARALLEL STIMULUS & CHECKING (FORK-JOIN)
            // =========================================================
            fork
                // -----------------------------------------------------
                // THREAD 1: BƠM DỮ LIỆU (STIMULUS)
                // -----------------------------------------------------
                begin
                    for (int c = 0; c < MSG_LEN; c++) begin
                        vld_in <= 1'b1;
                        dat_in  <= in_array[c];
                        sop_in   <= (c == 0) ? 1'b1 : 1'b0;
                        @(posedge clk);
                    end
                    // Kết thúc bơm 514 nhịp
                    vld_in <= 1'b0;
                    sop_in   <= 1'b0;
                    dat_in  <= '0;
                end

                // -----------------------------------------------------
                // THREAD 2: QUÁ TRÌNH CHỜ VÀ SO SÁNH (CHECKER)
                // -----------------------------------------------------
                begin
                    for (int c = 0; c < CW_LEN; c++) begin
                        // Đợi cờ báo hiệu data ra hoặc cờ báo lỗi
                        wait(vld_out == 1'b1 || sys_err == 1'b1);

                        if (sys_err == 1'b1) begin
                            mismatch = 1;
                            $display("[%0t]   \033[1;31m[FSM ERROR]\033[0m DUT asserted sys_err flag at cycle %0d", $time, c);
                            $fdisplay(log_fd, "[%0t]   [FSM ERROR] DUT asserted sys_err flag at cycle %0d", $time, c);
                            break; // Thoát vòng lặp checker ngay lập tức
                        end

                        if (vld_out == 1'b1) begin
                            #1; // Delay nhẹ để tín hiệu Data và SOP tổ hợp ổn định
                            
                            // Check Data
                            if (dat_out !== exp_array[c]) begin
                                mismatch = 1;
                                $display("  \033[1;31m[MISMATCH]\033[0m Cycle %0d | Exp Data = %x, Act Data = %x", 
                                         c, exp_array[c], dat_out);
                                $fdisplay(log_fd, "  [MISMATCH] Cycle %0d | Exp Data = %x, Act Data = %x", 
                                         c, exp_array[c], dat_out);
                            end
                            
                            // Check SOP Out
                            if (sop_out !== ((c == 0) ? 1'b1 : 1'b0)) begin
                                mismatch = 1;
                                $display("  \033[1;31m[SOP ERROR]\033[0m Cycle %0d | Exp SOP = %b, Act SOP = %b", 
                                         c, (c == 0) ? 1'b1 : 1'b0, sop_out);
                                $fdisplay(log_fd, "  [SOP ERROR] Cycle %0d | Exp SOP = %b, Act SOP = %b", 
                                         c, (c == 0) ? 1'b1 : 1'b0, sop_out);
                            end
                        end
                        
                        // Chờ qua nhịp clock này để đánh giá nhịp tiếp theo
                        @(posedge clk);
                    end
                end
            join

            // =========================================================
            // TỔNG KẾT TESTCASE SAU KHI FORK-JOIN HOÀN THÀNH
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

            // Nếu FSM dính lỗi, cần chờ nó tự động xả và reset về state READY
            if (sys_err == 1'b1) begin
                wait(sys_rdy == 1'b1);
                @(posedge clk);
            end
        end

        // ---------------------------------------------------------
        // 7. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   ENCODER SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Cases : %0d", test_idx);
        $display("   Passed      : %0d", pass_cnt);
        $display("   Failed      : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   ENCODER SIMULATION COMPLETED");
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

endmodule: rs_enc_tb
