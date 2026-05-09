`timescale 1ns/1ps

module uart_core_rx_tb;

    // Parameters
    parameter CLK_PERIOD = 20; // 50MHz
    parameter BAUD_RATE  = 115200;
    parameter BIT_TIME   = 1000000000 / BAUD_RATE; // ~8681ns
    parameter TARGET_CHAR = 8'h62; // ASCII 'b'

    // DUT Inputs
    logic        i_clk;
    logic        i_rst_n;
    logic        i_bclk_en;
    logic [15:0] i_baud_divisor;
    logic        i_parity_en;
    logic        i_even_parity;
    logic        i_dbg_lloopback;
    logic        i_dbg_sloopback;
    logic        i_tx_en;
    logic [7:0]  i_tx_data;
    logic        i_tx_wren;
    logic        i_tx_fifo_clr;
    logic        i_rx_en;
    logic        i_rx_rden;
    logic        i_rx_fifo_clr;
    logic        i_rx; // Serial input from PC

    // DUT Outputs
    logic        o_tx_idle;
    logic        o_tx_done;
    logic        o_tx_fifo_empty;
    logic        o_tx_fifo_full;
    logic [5:0]  o_tx_fifo_level;
    logic [7:0]  o_rx_data;
    logic        o_rx_idle;
    logic        o_rx_done;
    logic        o_rx_fifo_empty;
    logic        o_rx_fifo_full;
    logic [5:0]  o_rx_fifo_level;
    logic        o_rx_frame_error;
    logic        o_rx_parity_error;
    logic        o_rx_data_is_zero;
    logic        o_tx; // Serial output (ignored)

    // Biến phụ trợ phục vụ giám sát Waveform
    logic        baud_clk;

    // DUT Instantiation
    uart_core dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_bclk_en(i_bclk_en),
        .i_baud_divisor(i_baud_divisor),
        .i_parity_en(i_parity_en),
        .i_even_parity(i_even_parity),
        .i_dbg_lloopback(i_dbg_lloopback),
        .i_dbg_sloopback(i_dbg_sloopback),
        .i_tx_en(i_tx_en),
        .i_tx_data(i_tx_data),
        .i_tx_wren(i_tx_wren),
        .o_tx_idle(o_tx_idle),
        .o_tx_done(o_tx_done),
        .i_tx_fifo_clr(i_tx_fifo_clr),
        .o_tx_fifo_empty(o_tx_fifo_empty),
        .o_tx_fifo_full(o_tx_fifo_full),
        .o_tx_fifo_level(o_tx_fifo_level),
        .i_rx_en(i_rx_en),
        .i_rx_rden(i_rx_rden),
        .o_rx_data(o_rx_data),
        .o_rx_idle(o_rx_idle),
        .o_rx_done(o_rx_done),
        .i_rx_fifo_clr(i_rx_fifo_clr),
        .o_rx_fifo_empty(o_rx_fifo_empty),
        .o_rx_fifo_full(o_rx_fifo_full),
        .o_rx_fifo_level(o_rx_fifo_level),
        .o_rx_frame_error(o_rx_frame_error),
        .o_rx_parity_error(o_rx_parity_error),
        .o_rx_data_is_zero(o_rx_data_is_zero),
        .o_tx(o_tx),
        .i_rx(i_rx)
    );

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CLK_PERIOD / 2) i_clk = ~i_clk;
    end

    // Baud Clock Generation for Waveform Tracking
    initial begin
        baud_clk = 0;
        forever #(BIT_TIME / 2) baud_clk = ~baud_clk;
    end

    // Waveform Dumping
    initial begin
        $shm_open("waves.shm"); 
        $shm_probe("ACM"); 
    end

    // Agent/Driver Task: UART TX Emulator (LSB first)
    task send_uart_byte(input logic [7:0] tx_data);
        integer i;
        begin
            i_rx = 1'b0; // Start bit
            #(BIT_TIME);
            for (i = 0; i < 8; i++) begin
                i_rx = tx_data[i];
                #(BIT_TIME);
            end
            i_rx = 1'b1; // Stop bit
            #(BIT_TIME);
            
            // Wait extra time between bytes to simulate inter-byte delay
            #(BIT_TIME * 2); 
        end
    endtask

    // Sequence (Stimulus Execution)
    initial begin
        // 1. Initialize Inputs
        i_rst_n         = 0;
        i_bclk_en       = 1;
        i_baud_divisor  = -16'd27; // 50MHz / (115200 * 16)
        i_parity_en     = 0;
        i_even_parity   = 0;
        i_dbg_lloopback = 0;
        i_dbg_sloopback = 0;
        i_tx_en         = 0;
        i_tx_data       = 0;
        i_tx_wren       = 0;
        i_tx_fifo_clr   = 0;
        i_rx_en         = 1;
        i_rx_rden       = 0;
        i_rx_fifo_clr   = 0;
        i_rx            = 1; // Line idle state is high

        // 2. Hardware Reset
        #(CLK_PERIOD * 10);
        i_rst_n = 1;
        #(CLK_PERIOD * 10);

        // =================================================================
        // SCENARIO 1: Evaluate FIFO accumulation and behavior (rden = 0)
        // =================================================================
        $display("[%0t] SCENARIO 1: Accumulate FIFO", $time);
        send_uart_byte(TARGET_CHAR);
        send_uart_byte(TARGET_CHAR);
        send_uart_byte(TARGET_CHAR);
        
        // Wait to observe o_rx_done pulse and o_rx_fifo_level increase
        #(CLK_PERIOD * 100);

        // =================================================================
        // SCENARIO 2: Evaluate i_rx_fifo_clr logic
        // =================================================================
        $display("[%0t] SCENARIO 2: Clear FIFO", $time);
        @(posedge i_clk);
        i_rx_fifo_clr = 1;
        @(posedge i_clk);
        i_rx_fifo_clr = 0;
        
        // Wait to observe o_rx_fifo_empty asserting and level dropping to 0
        #(CLK_PERIOD * 50);

        // =================================================================
        // SCENARIO 3: Evaluate controlled read (rden pulse)
        // =================================================================
        $display("[%0t] SCENARIO 3: Controlled Read", $time);
        send_uart_byte(TARGET_CHAR);
        send_uart_byte(8'h41); // Send 'A' to verify data change
        
        // Pulse rden to read first byte
        @(posedge i_clk);
        i_rx_rden = 1;
        @(posedge i_clk);
        i_rx_rden = 0;
        
        // Pulse rden to read second byte
        #(CLK_PERIOD * 10);
        @(posedge i_clk);
        i_rx_rden = 1;
        @(posedge i_clk);
        i_rx_rden = 0;

        // =================================================================
        // SCENARIO 4: Simulate continuous 642 bytes stream with constant read
        // =================================================================
        $display("[%0t] SCENARIO 4: Continuous 642 bytes stream", $time);
        
        // Clear FIFO before mass transfer
        @(posedge i_clk);
        i_rx_fifo_clr = 1;
        @(posedge i_clk);
        i_rx_fifo_clr = 0;

        // Tie rden high. When data enters FIFO, it will be immediately presented
        // on o_rx_data at the next clock cycle.
        i_rx_rden = 1; 

        for (integer k = 0; k < 642; k++) begin
            send_uart_byte(TARGET_CHAR);
        end

        // Wait to ensure all bits are flushed
        #(BIT_TIME * 10);
        
        $display("[%0t] Testbench Completed.", $time);
        $finish;
    end

endmodule