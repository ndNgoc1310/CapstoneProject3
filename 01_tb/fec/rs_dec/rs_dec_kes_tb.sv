`timescale 1ns / 1ps
// =========================================================
// Testbench for Key Equation Solver (rs_dec_kes)
// Simulator: Cadence Xcelium
// Auto-checking with input/expected outputs from Python
// =========================================================

module rs_dec_kes_tb;

    // ---------------------------------------------------------
    // 1. PARAMETERS & SIGNALS
    // ---------------------------------------------------------
    parameter WIDTH = 10;
    parameter ORDER = 15;
    parameter NSYM  = 30;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    logic valid_in;
    logic [WIDTH-1:0] syn_in [NSYM-1:0];

    // DUT Outputs
    logic valid_out;
    logic ready;
    logic error;
    logic [WIDTH-1:0] lam_out [ORDER:0];
    logic [WIDTH-1:0] ome_out [ORDER:0];

    // File descriptors & Verification variables
    int in_fd, exp_fd, log_fd;
    int test_idx = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;
    int tmp_val;        // Temporary variable for fscanf
    int mismatch;       // Flag for comparison
    
    // Expected Output Arrays
    logic [WIDTH-1:0] exp_lam [ORDER:0];
    logic [WIDTH-1:0] exp_ome [ORDER:0];

    // ---------------------------------------------------------
    // 2. DUT INSTANTIATION
    // ---------------------------------------------------------
    rs_dec_kes #(
        .WIDTH(WIDTH),
        .ORDER(ORDER),
        .NSYM(NSYM),
        .CNT_WIDTH(5)
    ) DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),
        .syn_in     (syn_in),
        .valid_out  (valid_out),
        .ready      (ready),
        .error      (error),
        .lam_out    (lam_out),
        .ome_out    (ome_out)
    );

    // ---------------------------------------------------------
    // 3. CLOCK & RESET GENERATION
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100MHz Clock (T = 10ns)
    end

    initial begin
        rst_n = 1'b0;
        #23; // Assert reset for a few cycles (asynchronous assert, synchronous release)
        rst_n = 1'b1;
    end

    // ---------------------------------------------------------
    // 4. WATCHDOG TIMER (ANTI-DEADLOCK)
    // ---------------------------------------------------------
    initial begin
        #500000; // Timeout after 500us
        $display("\n[%0t] FATAL ERROR: Watchdog Timer Triggered!", $time);
        $display("FSM is likely stuck. Dumping waveforms and terminating.");
        $finish;
    end

    // ---------------------------------------------------------
    // 5. CADENCE XCELIUM SHM DUMPING
    // ---------------------------------------------------------
    initial begin
        $shm_open("waves.shm"); // Open database in current directory
        $shm_probe("ACM");       // A = All signals, C = Compress, M = Memories
    end

    // ---------------------------------------------------------
    // 6. MAIN STIMULUS & CHECKING (SELF-CHECKING LOGIC)
    // ---------------------------------------------------------
    initial begin
        // Init signals
        valid_in = 1'b0;
        for (int i = 0; i < NSYM; i++) syn_in[i] = '0;

        // Open Files
        in_fd  = $fopen("rs_dec_kes_in.hex", "r");
        exp_fd = $fopen("rs_dec_kes_out_exp.hex", "r");
        log_fd = $fopen("kes_sim.log", "w");

        if (in_fd == 0 || exp_fd == 0 || log_fd == 0) begin
            $display("ERROR: Failed to open I/O Hex files or Log file.");
            $finish;
        end

        // Wait for Reset to complete
        wait(rst_n == 1'b1);
        @(posedge clk); 

        // Read line-by-line until EOF
        while (!$feof(in_fd) && !$feof(exp_fd)) begin
            
            // --- A. Read Inputs (S_29 down to S_0) ---
            for (int i = NSYM-1; i >= 0; i--) begin
                if ($fscanf(in_fd, "%x", tmp_val) != 1) break;
                syn_in[i] = tmp_val;
            end

            // --- B. Read Expected Outputs ---
            // 1. Lam_15 down to Lam_0
            for (int i = ORDER; i >= 0; i--) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_lam[i] = tmp_val;
            end
            // 2. Ome_15 down to Ome_0
            for (int i = ORDER; i >= 0; i--) begin
                if ($fscanf(exp_fd, "%x", tmp_val) != 1) break;
                exp_ome[i] = tmp_val;
            end

            // Safe break if EOF reached abruptly
            if ($feof(in_fd) || $feof(exp_fd)) break; 
            
            test_idx++;

            // --- C. FSM Protocol (Driving) ---
            // Wait until DUT is ready to accept new data
            wait(ready == 1'b1);
            @(posedge clk); // Align to clock edge

            // Pulse valid_in for exactly 1 cycle
            valid_in <= 1'b1;
            @(posedge clk);
            valid_in <= 1'b0;

            // --- D. FSM Protocol (Catching & Checking) ---
            // Fork-join to catch either valid_out (Success) or error (Fail)
            fork : FSM_WAIT
                begin
                    wait(valid_out == 1'b1);
                    disable FSM_WAIT; // Kill the error-waiting thread
                end
                begin
                    wait(error == 1'b1);
                    disable FSM_WAIT; // Kill the valid-waiting thread
                end
            join

            // Re-align to evaluation edge
            #1; 

            // Case 1: FSM threw an error flag
            if (error == 1'b1) begin
                $display("[%0t] Testcase %0d: FAIL (FSM Error asserted)", $time, test_idx);
                $fdisplay(log_fd, "[%0t] Testcase %0d: FAIL (FSM Error asserted)", $time, test_idx);
                fail_cnt++;
                
                // Wait for FSM to return to IDLE/READY state before injecting next vector
                wait(ready == 1'b1);
                continue; 
            end

            // Case 2: DUT finished calculating, valid_out is high -> Compare arrays
            mismatch = 0;
            
            // Check Lambda values
            for (int i = 0; i <= ORDER; i++) begin
                if (lam_out[i] !== exp_lam[i]) begin
                    mismatch = 1;
                    $display("  [LAMBDA ERROR] Index %0d: Exp = %x, Act = %x", i, exp_lam[i], lam_out[i]);
                    $fdisplay(log_fd, "  [LAMBDA ERROR] Index %0d: Exp = %x, Act = %x", i, exp_lam[i], lam_out[i]);
                end
            end
            
            // Check Omega values
            for (int i = 0; i <= ORDER; i++) begin
                if (ome_out[i] !== exp_ome[i]) begin
                    mismatch = 1;
                    $display("  [OMEGA ERROR] Index %0d: Exp = %x, Act = %x", i, exp_ome[i], ome_out[i]);
                    $fdisplay(log_fd, "  [OMEGA ERROR] Index %0d: Exp = %x, Act = %x", i, exp_ome[i], ome_out[i]);
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

            // Wait 1 cycle before pumping the next case
            @(posedge clk); 
        end

        // ---------------------------------------------------------
        // 7. SUMMARY REPORT
        // ---------------------------------------------------------
        $display("\n=============================================");
        $display("   KES SIMULATION COMPLETED");
        $display("=============================================");
        $display("   Total Testcases : %0d", test_idx);
        $display("   Passed          : %0d", pass_cnt);
        $display("   Failed          : %0d", fail_cnt);
        $display("=============================================\n");

        $fdisplay(log_fd, "\n=============================================");
        $fdisplay(log_fd, "   KES SIMULATION COMPLETED");
        $fdisplay(log_fd, "=============================================");
        $fdisplay(log_fd, "   Total Testcases : %0d", test_idx);
        $fdisplay(log_fd, "   Passed          : %0d", pass_cnt);
        $fdisplay(log_fd, "   Failed          : %0d", fail_cnt);
        $fdisplay(log_fd, "=============================================\n");

        // Close files and finish simulation gracefully
        $fclose(in_fd);
        $fclose(exp_fd);
        $fclose(log_fd);
        $finish;
    end

endmodule : rs_dec_kes_tb
