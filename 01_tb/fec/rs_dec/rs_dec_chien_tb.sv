`timescale 1ns/1ps

module rs_dec_chien_tb;
    logic clk, rst_n, start;
    
    // Lưu ý: Độ rộng mảng phải khớp với RTL sinh ra (P=16 -> [0:15])
    logic [9:0] lam_in [0:15];
    logic [9:0] omg_in [0:15];
    
    logic valid_out, done;
    logic [9:0] error_val [0:15]; // Sửa tên tín hiệu cho khớp với module (error_val thay vì err_val)
    logic [9:0] error_pos [0:15]; 

    // Memory
    logic [9:0] exp_err [0:543];
    int err_cnt = 0;
    int word_cnt = 0;

    // Instantiate DUT
    // Lưu ý: Tên port phải khớp với file rs_dec_chien.sv được sinh ra
    rs_dec_chien dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .lam_in(lam_in), 
        .omg_in(omg_in),
        .valid_out(valid_out),
        .done(done),
        .error_val(error_val),
        .error_pos(error_pos)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // 1. Load dữ liệu
        $readmemh("lambda_in.hex", lam_in);
        $readmemh("omega_in.hex", omg_in);
        $readmemh("error_out_exp.hex", exp_err);
        
        // 2. Reset
        rst_n = 0; start = 0;
        #20 rst_n = 1;

        // 3. Tạo xung Start
        @(posedge clk); start = 1;
        @(posedge clk); start = 0;
        
        wait(done);
        #100;
        
        if (err_cnt == 0) $display(">> CHIEN SEARCH PASSED! <<");
        else $display(">> FAILED: %0d errors", err_cnt);
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out) begin
            for (int i=0; i<16; i++) begin
                int idx; 
                idx = word_cnt * 16 + i; 
                
                if (idx < 544) begin
                    // Kiểm tra giá trị lỗi
                    if (error_val[i] !== exp_err[idx]) begin
                        $display("Error at Idx %0d: Exp=%h Act=%h", idx, exp_err[idx], error_val[i]);
                        err_cnt++;
                    end
                end
            end
            word_cnt++;
        end
    end
endmodule