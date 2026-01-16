`timescale 1ns/1ps

module rs_enc_tb;
    // Tín hiệu kết nối
    logic clk;
    logic rst_n;
    logic sop;
    logic valid_in;
    logic [9:0] data_in;
    logic valid_out;
    logic [9:0] data_out;
    logic ready;

    // Bộ nhớ để chứa dữ liệu kiểm thử
    logic [9:0] input_mem [0:513];
    logic [9:0] expected_mem [0:543];
    int i, match_count, error_count;

    // Khởi tạo DUT (Device Under Test)
    rs_enc dut (
        .clk(clk),
        .rst_n(rst_n),
        .sop(sop),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .data_out(data_out),
        .ready(ready)
    );

    // Tạo xung Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Mở database wave.shm
        $shm_open("wave.shm");
        
        // A (All): Tất cả tín hiệu.
        // C (Cells): Các kết nối trong module con. 
        // M (Memories): Mảng, memory.
        // T (Transactions): Ghi lại các giao dịch (nếu có).
        $shm_probe("ACMT"); 
    end

    initial begin
        // 1. Đọc dữ liệu từ file hex
        $readmemh("rs_enc_input.hex", input_mem);
        $readmemh("rs_enc_output_exp.hex", expected_mem);

        // 2. Khởi tạo tín hiệu
        rst_n = 0;
        sop = 0;
        valid_in = 0;
        data_in = 0;
        i = 0;
        match_count = 0;
        error_count = 0;

        // 3. Reset hệ thống
        #20 rst_n = 1;
        #10;

        // 4. Đẩy dữ liệu vào Encoder
        wait(ready); // Chờ bộ mã hóa sẵn sàng
        @(posedge clk);
        
        for (i = 0; i < 514; i++) begin
            valid_in = 1;
            data_in = input_mem[i];
            sop = (i == 0); // Bật SOP tại symbol đầu tiên
            @(posedge clk);
            sop = 0;
        end
        
        valid_in = 0;
        data_in = 0;

        // Chờ cho đến khi hoàn thành xả Parity
        wait(ready);
        #100;
        
        $display("Kết quả kiểm tra: %d khớp, %d lỗi", match_count, error_count);
        $finish;
    end

    // 5. Khối kiểm tra dữ liệu đầu ra (Checker)
    int out_cnt = 0;
    always @(posedge clk) begin
        if (valid_out) begin
            if (data_out === expected_mem[out_cnt]) begin
                match_count++;
            end else begin
                $display("LỖI tại symbol %d: Mong đợi %h, Nhận được %h", out_cnt, expected_mem[out_cnt], data_out);
                error_count++;
            end
            out_cnt++;
            if (out_cnt == 544) out_cnt = 0;
        end
    end

endmodule
