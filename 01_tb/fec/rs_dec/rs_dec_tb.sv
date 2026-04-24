`timescale 1ns / 1ps
// =========================================================
// Module: rs_dec_tb.sv
// Function: Top-Level Testbench for Reed-Solomon Decoder
// Simulator: Cadence Xcelium
// Path: 01_tb/fec/rs_dec/rs_dec_tb.sv
// =========================================================

module rs_dec_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    parameter NSYM  = 30;
    parameter ORDER = 15;
    parameter K     = 544; // Codeword length

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

    // Verification Variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        
    bit mismatch;       
    
    // Arrays for storing test vectors (1 Packet = 544 Symbols)
    logic [WIDTH-1:0] in_array  [0:K-1];
    logic [WIDTH-1:0] exp_array [0:K-1];

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec #(
        .WIDTH(WIDTH),
        .NSYM(NSYM),
        .ORDER(ORDER),
        .K(K)
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
    // 3. CLOCK GENERATION & RESET
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100MHz (T=10ns)
    end

    initial begin
        rst_n = 1'b0;
        #100;
        rst_n = 1'b1;
    end

    // ---------------------------------------------------------
    // 4. CADENCE XCELIUM DUMPING & WATCHDOG
    // ---------------------------------------------------------
    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACM");
    end

    initial begin
        #5000000; // 5ms Watchdog
        $display("\n[%0t] \033[1;31mFATAL: Watchdog Timer Triggered!\033[0m", $time);
        $finish;
    end

    // ---------------------------------------------------------
    // 5. MAIN STIMULUS & CHECKING LOOP
    // ---------------------------------------------------------
    initial begin
        // Initialize Inputs
        sop_in   = 1'b0;
        vld_in = 1'b0;
        dat_in  = '0;

        // Open Hex and Log Files
        in_fd  = $fopen("rs_dec_in.hex", "r");
        exp_fd = $fopen("rs_dec_out_exp.hex", "r");
        log_fd = $fopen("rs_dec_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("ERROR: Cannot open hex files or log file.");
            $finish;
        end

        $display("--- RS DECODER SYSTEM-LEVEL SIMULATION START ---");
        $fdisplay(log_fd, "--- RS DECODER SIMULATION LOG ---");

        wait(rst_n == 1'b1);
        @(posedge clk);

        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // Đọc mảng Input và Expected từ file
            for (int i = 0; i < K; i++) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                in_array[i] = tmp_val;
            end
            for (int i = 0; i < K; i++) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_array[i] = tmp_val;
            end

            if ($feof(in_fd)) break;

            test_idx++;
            mismatch = 0;

            // Chờ DUT sẵn sàng nhận gói tin mới
            wait(sys_rdy == 1'b1);
            @(posedge clk);

            // =====================================================
            // THỰC THI SONG SONG (FORK-JOIN)
            // =====================================================
            fork
                // THREAD 1: BƠM DỮ LIỆU (STIMULUS)
                begin
                    for (int c = 0; c < K; c++) begin
                        vld_in <= 1'b1;
                        dat_in  <= in_array[c];
                        sop_in   <= (c == 0);
                        @(posedge clk);
                    end
                    vld_in <= 1'b0;
                    sop_in   <= 1'b0;
                    dat_in  <= '0;
                end

                // THREAD 2: QUÁ TRÌNH CHỜ VÀ SO SÁNH (CHECKER)
                begin
                    for (int c = 0; c < K; c++) begin
                        // Đợi vld_out từ Pipeline xả ra hoặc cờ báo lỗi
                        wait(vld_out == 1'b1 || sys_err == 1'b1);

                        if (sys_err == 1'b1) begin
                            mismatch = 1;
                            $display("[%0t]   \033[1;31m[ERROR]\033[0m Testcase %0d: FSM Asserted Error Flag!", $time, test_idx);
                            $fdisplay(log_fd, "[%0t]   [ERROR] Testcase %0d: FSM Asserted Error Flag!", $time, test_idx);
                            break; 
                        end

                        if (vld_out == 1'b1) begin
                            #1; // Để tín hiệu tổ hợp ổn định

                            // Kiểm tra dữ liệu
                            // Đảo chiều index để khớp với dữ liệu xuất ngược từ LIFO (c_0 -> c_543)
                            if (dat_out !== exp_array[K - 1 - c]) begin
                                mismatch = 1;
                                $display("[%0t]   \033[1;31m[DATA MISMATCH]\033[0m Case %0d | Symbol %0d | Exp: %x, Act: %x", 
                                    $time, test_idx, K - 1 - c, exp_array[K - 1 - c], dat_out);
                                $fdisplay(log_fd, "[%0t]   [DATA MISMATCH] Case %0d | Symbol %0d | Exp: %x, Act: %x", 
                                    $time, test_idx, K - 1 - c, exp_array[K - 1 - c], dat_out);
                            end

                            // Kiểm tra tín hiệu SOP
                            if (sop_out !== (c == 0)) begin
                                mismatch = 1;
                                $display("[%0t]   \033[1;31m[SOP MISMATCH]\033[0m Case %0d | Symbol %0d | Exp: %b, Act: %b", 
                                         $time, test_idx, c, (c == 0), sop_out);
                                $fdisplay(log_fd, "[%0t]   [SOP MISMATCH] Case %0d | Symbol %0d | Exp: %b, Act: %b", 
                                          $time, test_idx, c, (c == 0), sop_out);
                            end
                        end
                        @(posedge clk); // Chuyển nhịp để check symbol tiếp theo
                    end
                end
            join

            // Tổng kết Testcase
            if (mismatch) begin
                fail_cnt++;
                $display("[%0t] Testcase %0d: \033[1;31mFAIL\033[0m", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL", $time, test_idx);
            end else begin
                pass_cnt++;
                $display("[%0t] Testcase %0d: \033[1;32mPASS\033[0m", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: PASS", $time, test_idx);
            end

            // Phục hồi FSM nếu có lỗi trước khi qua testcase mới
            if (sys_err == 1'b1) begin
                wait(sys_rdy == 1'b1);
                @(posedge clk);
            end
        end

        // ---------------------------------------------------------
        // 6. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   RS DECODER SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Testcases : %0d", test_idx);
        $display("   Passed          : %0d", pass_cnt);
        $display("   Failed          : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   RS DECODER SIMULATION COMPLETED");
        $fdisplay(log_fd, "=============================================");
        $fdisplay(log_fd, "   Total Testcases : %0d", test_idx);
        $fdisplay(log_fd, "   Passed          : %0d", pass_cnt);
        $fdisplay(log_fd, "   Failed          : %0d", fail_cnt);
        $fdisplay(log_fd, "=============================================\n");

        $fclose(in_fd);
        $fclose(exp_fd);
        $fclose(log_fd);
        $finish;
    end

endmodule
