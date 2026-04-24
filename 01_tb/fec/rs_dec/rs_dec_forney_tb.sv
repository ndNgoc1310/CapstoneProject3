`timescale 1ns / 1ps
// =========================================================
// Testbench for Forney Evaluator (rs_dec_forney)
// Simulator: Cadence Xcelium
// Location: 01_tb/fec/rs_dec/rs_dec_forney_tb.sv
// Function: Cycle-accurate checking for combinational logic
// =========================================================

module rs_dec_forney_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    
    // Virtual Clock (100MHz)
    logic clk;

    // DUT Signals
    logic       err_flg;
    logic [9:0] l_val_der;
    logic [9:0] o_val;
    logic [9:0] err_mag;

    // Golden Model / Expected Signals
    logic [9:0] exp_err_mag;

    // Verification Variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_flg, tmp_l, tmp_o, tmp_mag; // Temporary buffers for fscanf

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec_forney #(
        .WIDTH(WIDTH)
    ) DUT (
        .err_flg   (err_flg),
        .l_val_der (l_val_der),
        .o_val     (o_val),
        .err_mag   (err_mag)
    );

    // ---------------------------------------------------------
    // 3. CLOCK GENERATION & WAVEFORM DUMP
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Period = 10ns
    end

    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACM"); // Probe All, Compressing, Memories
    end

    // ---------------------------------------------------------
    // 4. WATCHDOG TIMER (Timeout after 5ms)
    // ---------------------------------------------------------
    initial begin
        #5000000;
        $display("\n[%0t] FATAL ERROR: Watchdog Timer Triggered!", $time);
        $finish;
    end

    // ---------------------------------------------------------
    // 5. STIMULUS & AUTO-CHECKING
    // ---------------------------------------------------------
    initial begin
        // Khởi tạo giá trị ban đầu
        err_flg   = 0;
        l_val_der = 0;
        o_val     = 0;

        // Mở file hex và log
        in_fd  = $fopen("rs_dec_forney_in.hex", "r");
        exp_fd = $fopen("rs_dec_forney_out_exp.hex", "r");
        log_fd = $fopen("forney_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("ERROR: Khong the mo file input/output hex hoac log file.");
            $finish;
        end

        $fdisplay(log_fd, "--- FORNEY EVALUATOR SIMULATION LOG ---");
        $display("--- Bat dau mo phong rs_dec_forney ---");

        // Vòng lặp chính đọc dữ liệu từ file
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            @(posedge clk);
            
            // Đọc Input (err_flg l_val_der o_val)
            if ($fscanf(in_fd, "%x %x %x\n", tmp_flg, tmp_l, tmp_o) == 3) begin
                err_flg   <= tmp_flg[0];
                l_val_der <= tmp_l[9:0];
                o_val     <= tmp_o[9:0];
            end

            // Đọc Expected Output (err_mag)
            if ($fscanf(exp_fd, "%x\n", tmp_mag) == 1) begin
                exp_err_mag = tmp_mag[9:0];
            end else begin
                break; // Thoát nếu không đọc đủ cặp dữ liệu
            end

            // Trễ 2ns để mạch tổ hợp cập nhật ngõ ra err_mag
            #2; 
            test_idx++;

            // So sánh Actual và Expected
            if (err_mag === exp_err_mag) begin
                pass_cnt++;
                $fdisplay(log_fd, "[PASS] Case %0d: In(%b, %h, %h) | Out(%h)", 
                          test_idx, err_flg, l_val_der, o_val, err_mag);
            end else begin
                fail_cnt++;
                // In terminal bằng màu đỏ (ANSI code) để dễ nhận diện lỗi
                $display("\033[1;31m[FAIL] Time %0t | Case %0d: In(%b, %h, %h) | Exp: %h | Act: %h\033[0m", 
                         $time, test_idx, err_flg, l_val_der, o_val, exp_err_mag, err_mag);
                $fdisplay(log_fd, "[FAIL] Time %0t | Case %0d: In(%b, %h, %h) | Exp: %h | Act: %h", 
                         $time, test_idx, err_flg, l_val_der, o_val, exp_err_mag, err_mag);
            end
        end

        // ---------------------------------------------------------
        // 6. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   FORNEY SIMULATION COMPLETED");
        $display("   Total Cases : %0d", test_idx);
        $display("   Passed      : %0d", pass_cnt);
        $display("   Failed      : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   FORNEY SIMULATION COMPLETED");
        $fdisplay(log_fd, "   Total Cases : %0d", test_idx);
        $fdisplay(log_fd, "   Passed      : %0d", pass_cnt);
        $fdisplay(log_fd, "   Failed      : %0d", fail_cnt);
        $fdisplay(log_fd, "=============================================\n");

        $fclose(in_fd);
        $fclose(exp_fd);
        $fclose(log_fd);
        $finish;
    end

endmodule: rs_dec_forney_tb
