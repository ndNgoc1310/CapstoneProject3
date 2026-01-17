`timescale 1ns/1ps

module rs_dec_kes_tb;

    // --- Parameters ---
    localparam T = 15;

    // --- Signals ---
    logic clk;
    logic rst_n;
    logic start;
    logic [9:0] syndromes_in [29:0];
    
    logic done;
    logic [9:0] lambda [15:0];
    logic [9:0] omega [15:0];

    // --- Test Data ---
    logic [9:0] syn_mem [0:29];
    logic [9:0] exp_mem [0:31]; // 16 Lambda + 16 Omega
    
    // --- DUT ---
    rs_dec_kes dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .syndromes_in(syndromes_in),
        .done(done),
        .lambda(lambda),
        .omega(omega)
    );

    // --- Clock ---
    initial clk = 0;
    always #5 clk = ~clk;
    
    // --- Dump Waveform ---
    initial begin
        $shm_open("waves.shm");
        $shm_probe("ACMT");
    end

    // --- Main Test ---
    int err_cnt = 0;
    
    initial begin
        // 1. Load Vectors
        $readmemh("rs_dec_kes_input.hex", syn_mem);
        $readmemh("rs_dec_kes_output_exp.hex", exp_mem);
        
        // 2. Init
        rst_n = 0;
        start = 0;
        // Load syndromes to input array
        for (int i=0; i<30; i++) syndromes_in[i] = 10'd0;
        
        #20 rst_n = 1;
        #10;
        
        // 3. Drive Input
        $display("--- LOADING SYNDROMES ---");
        for (int i=0; i<30; i++) begin
            syndromes_in[i] = syn_mem[i];
            $display("S[%0d] = %h", i, syn_mem[i]);
        end
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // 4. Wait for Done
        wait(done);
        @(negedge clk); // Check at falling edge
        
        // 5. Compare Results
        $display("\n--- CHECKING LAMBDA ---");
        for (int i=0; i<=T; i++) begin
            if (lambda[i] !== exp_mem[i]) begin
                $display("[FAIL] Lambda[%0d]: Exp=%h, Act=%h", i, exp_mem[i], lambda[i]);
                err_cnt++;
            end else begin
                $display("[PASS] Lambda[%0d]: %h", i, lambda[i]);
            end
        end

        $display("\n--- CHECKING OMEGA ---");
        for (int i=0; i<=T; i++) begin
            // Omega stored from index 16 to 31 in expected file
            if (omega[i] !== exp_mem[i+16]) begin
                $display("[FAIL] Omega[%0d]: Exp=%h, Act=%h", i, exp_mem[i+16], omega[i]);
                err_cnt++;
            end else begin
                $display("[PASS] Omega[%0d]: %h", i, omega[i]);
            end
        end
        
        if (err_cnt == 0) 
            $display("\n>> KES VERIFICATION PASSED! <<");
        else 
            $display("\n>> KES FAILED with %0d errors <<", err_cnt);
            
        #100 $finish;
    end

endmodule
