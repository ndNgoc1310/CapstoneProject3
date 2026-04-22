`timescale 1ns / 1ps
// =========================================================
// Testbench for Chien Search & Forney Evaluator (rs_dec_chien)
// Simulator: Cadence Xcelium
// Cycle-accurate Auto-checking with Python Golden Vectors
// =========================================================

module rs_dec_chien_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    parameter ORDER = 15;
    parameter CYCLES = 544; // Số nhịp clock cần kiểm tra cho 1 block

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    // Lưu ý: Dùng 2D Packed Array để tương thích 100% với Xcelium
    logic valid_in;
    logic [ORDER:0][WIDTH-1:0] lam_in;
    logic [ORDER:0][WIDTH-1:0] ome_in;

    // DUT Outputs
    logic err_flg;
    logic [WIDTH-1:0] l_val_der;
    logic [WIDTH-1:0] o_val;
    logic sop_out;
    logic valid_out;
    logic ready;
    logic error;

    // File descriptors & Verification variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        // Biến tạm để đọc hex
    int mismatch;       // Cờ đánh dấu fail trong 1 testcase
    
    // Expected Output Array (Cycle-by-cycle)
    logic [20:0] exp_data_array [0:CYCLES-1];
    
    // Variables for extracting expected fields
    logic       exp_err_flg;
    logic [9:0] exp_l_val_der;
    logic [9:0] exp_o_val;

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec_chien #(
        .WIDTH(WIDTH),
        .ORDER(ORDER),
        .CNT_WIDTH(10)
    ) DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),
        .lam_in     (lam_in),
        .ome_in     (ome_in),
        .err_flg    (err_flg),
        .l_val_der  (l_val_der),
        .o_val      (o_val),
        .sop_out    (sop_out),
        .valid_out  (valid_out),
        .ready      (ready),
        .error      (error)
    );

    // ---------------------------------------------------------
    // 3. CLOCK & RESET GENERATION
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100MHz Clock
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
        #500000; // Timeout sau 500us
        $display("\n[%0t] FATAL ERROR: Watchdog Timer Triggered!", $time);
        $display("FSM is likely stuck. Dumping waveforms and terminating.");
        $finish;
    end

    // ---------------------------------------------------------
    // 5. CADENCE XCELIUM SHM DUMPING
    // ---------------------------------------------------------
    initial begin
        $shm_open("waves.shm"); 
        $shm_probe("AC");       
    end

    // ---------------------------------------------------------
    // 6. MAIN STIMULUS & CHECKING (CYCLE-ACCURATE)
    // ---------------------------------------------------------
    initial begin
        // Init signals
        valid_in = 1'b0;
        lam_in = '0;
        ome_in = '0;

        // Open Files
        in_fd  = $fopen("rs_dec_chien_in.hex", "r");
        exp_fd = $fopen("rs_dec_chien_out_exp.hex", "r");
        log_fd = $fopen("chien_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("ERROR: Failed to open I/O Hex files or Log file.");
            $finish;
        end

        // Wait for Reset to complete
        wait(rst_n == 1'b1);
        @(posedge clk); 

        // Read line-by-line until EOF
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // --- A. Read Inputs (32 values per line) ---
            // 1. Lam_15 down to Lam_0
            for (int i = ORDER; i >= 0; i--) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                lam_in[i] = tmp_val;
            end
            // 2. Ome_15 down to Ome_0
            for (int i = ORDER; i >= 0; i--) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                ome_in[i] = tmp_val;
            end

            // --- B. Read Expected Outputs (544 values per line) ---
            for (int i = 0; i < CYCLES; i++) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_data_array[i] = tmp_val;
            end

            // Safe break if EOF reached abruptly
            if ($feof(in_fd) || $feof(exp_fd)) break; 
            
            test_idx++;
            mismatch = 0;

            // --- C. FSM Protocol (Driving) ---
            wait(ready == 1'b1);
            @(posedge clk); 

            // Pulse valid_in for exactly 1 cycle
            valid_in <= 1'b1;
            @(posedge clk);
            valid_in <= 1'b0;

            // --- D. FSM Protocol (Catching & Checking) ---
            wait(valid_out == 1'b1 || error == 1'b1);

            if (error == 1'b1) begin
                $display("[%0t] Testcase %0d: FAIL (FSM Error asserted)", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL (FSM Error asserted)", $time, test_idx);
                fail_cnt++;
                wait(ready == 1'b1);
                continue; 
            end

            // Đã nhận valid_out == 1, dịch nhẹ 1ns để đọc tín hiệu ổn định sau sườn Clock
            #1; 

            // Vòng lặp kiểm tra 544 nhịp Clock
            for (int c = 0; c < CYCLES; c++) begin
                
                // Giải mã Expected Values từ mảng 21-bit
                exp_err_flg   = exp_data_array[c][20];
                exp_l_val_der = exp_data_array[c][19:10];
                exp_o_val     = exp_data_array[c][9:0];

                // So sánh
                if (err_flg !== exp_err_flg || l_val_der !== exp_l_val_der || o_val !== exp_o_val) begin
                    mismatch = 1;
                    $display("  [MISMATCH] Cycle %0d | Exp: err=%b l_der=%x o_val=%x | Act: err=%b l_der=%x o_val=%x", 
                              c, exp_err_flg, exp_l_val_der, exp_o_val, err_flg, l_val_der, o_val);
                    $fdisplay(log_fd, "  [MISMATCH] Cycle %0d | Exp: err=%b l_der=%x o_val=%x | Act: err=%b l_der=%x o_val=%x", 
                              c, exp_err_flg, exp_l_val_der, exp_o_val, err_flg, l_val_der, o_val);
                end

                // Đợi nhịp Clock tiếp theo (trừ vòng lặp cuối cùng)
                if (c < CYCLES - 1) begin
                    @(posedge clk); 
                    #1; // Re-align to evaluation edge
                end
            end

            // Logging Verdict
            if (mismatch) begin
                fail_cnt++;
                $display("[%0t] Testcase %0d: FAIL", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL", $time, test_idx);
            end else begin
                pass_cnt++;
                $display("[%0t] Testcase %0d: PASS", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: PASS", $time, test_idx);
            end

            // Chờ mạch nhả valid_out và quay về IDLE/READY trước khi test case tiếp theo
            wait(valid_out == 1'b0);
            @(posedge clk); 
        end

        // ---------------------------------------------------------
        // 7. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   CHIEN SEARCH SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Testcases : %0d", test_idx);
        $display("   Passed          : %0d", pass_cnt);
        $display("   Failed          : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   CHIEN SEARCH SIMULATION COMPLETED");
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

endmodule:rs_dec_chien_tb
