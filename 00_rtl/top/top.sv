// =========================================================
// Project: Reed-Solomon Codec Demo on DE10-Standard
// Module: top.sv
// Function: End-to-end RS(544, 514) Demo with Error Injection
// =========================================================

module top #(
    parameter WIDTH = 10,
    parameter NSYM  = 30,
    parameter ORDER = 15,
    parameter K     = 544  // Codeword length (N)
) (
    input  logic        clk,        // Tín hiệu clock
    input  logic        rst_n,      // Tín hiệu reset, active low
    input  logic        start_demo, // Xung kích hoạt chạy 1 gói tin
    input  logic [2:0]  demo_sel,   // 00: 0 lỗi, 01: 5 lỗi, 10: 15 lỗi, 11: 16 lỗi
    output logic [9:0]  injected_err_cnt,
    output logic [9:0]  corrected_err_cnt,
    output logic        ready,
    output logic        error,
    output logic        demo_done,
    output logic        demo_success,
    output logic        demo_fail
);

    // ---------------------------------------------------------
    // 1. BLOCK 1: Message ROM & ROM_Ctrl
    // ---------------------------------------------------------
    (* ram_init_file = "message.mif" *) logic [WIDTH-1:0] msg_rom [0:513];
    
    logic [9:0]         msg_ptr;
    logic               msg_valid;
    logic [WIDTH-1:0]   msg_data;
    logic               msg_sop;

    enum logic {IDLE, SEND} state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state       <= IDLE;
            msg_ptr     <= '0;
            msg_valid   <= 1'b0;
            msg_sop     <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    msg_ptr <= '0;
                    if (start_demo) state <= SEND;
                end
                SEND: begin
                    msg_valid <= 1'b1;
                    msg_sop   <= (msg_ptr == 0);
                    msg_ptr   <= msg_ptr + 1'b1;
                    if (msg_ptr == 513) begin
                        state <= IDLE;
                    end
                end
            endcase
            // De-assert valid when returning to IDLE
            if (state == IDLE && !start_demo) msg_valid <= 1'b0;
        end
    end
    assign msg_data = msg_rom[msg_ptr];

    // ---------------------------------------------------------
    // 2. BLOCK 2: RS Encoder Instantiation
    // ---------------------------------------------------------
    logic [WIDTH-1:0]   enc_data;
    logic               enc_valid;
    logic               enc_sop;
    logic               enc_ready;
    logic               enc_error;

    rs_enc #(.WIDTH(WIDTH), .NSYM(NSYM)) u_rs_enc (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (msg_sop),
        .val_in     (msg_valid),
        .data_in    (msg_data),

        .data_out   (enc_data),
        .val_out    (enc_valid),
        .sop_out    (enc_sop),
        .ready      (enc_ready),
        .error      (enc_error)
    );

    // ---------------------------------------------------------
    // 3. BLOCK 3: Error Injector
    // ---------------------------------------------------------
    logic [9:0]       inj_cnt;
    logic [WIDTH-1:0] err_mask;
    logic [WIDTH-1:0] corrupted_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) inj_cnt <= '0;
        else if (enc_valid) inj_cnt <= (enc_sop) ? 10'd1 : inj_cnt + 1'b1;
        else inj_cnt <= '0;
    end

    always_comb begin
        err_mask = '0;
        injected_err_cnt = '0;
        case (demo_sel)
            3'b001: begin 
                injected_err_cnt = 5;
                if (inj_cnt == 10 || inj_cnt == 20 || inj_cnt == 30 || inj_cnt == 40 || inj_cnt == 50) 
                    err_mask = 10'h3FF;
            end
            3'b010: begin
                injected_err_cnt = 15;
                if (inj_cnt >= 100 && inj_cnt <= 114) err_mask = 10'h3FF;
            end
            3'b011: begin
                injected_err_cnt = 16;
                if (inj_cnt >= 100 && inj_cnt <= 115) err_mask = 10'h3FF;
            end
            default: injected_err_cnt = 0;
        endcase
    end

    assign corrupted_data = enc_data ^ err_mask;

    // ---------------------------------------------------------
    // 4. BLOCK 4: RS Decoder Instantiation
    // ---------------------------------------------------------
    logic [WIDTH-1:0]   dec_data;
    logic               dec_valid;
    logic               dec_sop;
    logic               dec_ready;
    logic               dec_error;

    rs_dec #(.WIDTH(WIDTH), .NSYM(NSYM), .ORDER(ORDER), .K(K)) u_rs_dec (
        .clk        (clk),
        .rst_n      (rst_n),
        .sop_in     (enc_sop),
        .valid_in   (enc_valid),     
        .data_in    (corrupted_data),
        .sop_out    (dec_sop),
        .valid_out  (dec_valid),
        .data_out   (dec_data),
        .ready      (dec_ready),
        .error      (dec_error)
    );

    // ---------------------------------------------------------
    // 5. BLOCK 5: Result Analyzer (RAM Buffer & Comparator)
    // ---------------------------------------------------------
    logic [WIDTH-1:0] cmp_ram [0:543];
    logic [9:0]       wr_ptr, rd_ptr;
    logic [WIDTH-1:0] ram_data_out;
    logic [WIDTH-1:0] dec_data_q;
    logic             dec_valid_q;

    // Logic ghi RAM (Lưu codeword bị lỗi để so sánh)
    always_ff @(posedge clk) begin
        if (!rst_n) wr_ptr <= '0;
        else if (enc_valid) begin
            cmp_ram[wr_ptr] <= corrupted_data;
            wr_ptr <= (enc_sop) ? 10'd1 : wr_ptr + 1'b1;
        end else wr_ptr <= '0;
    end

    // Logic đọc RAM (Đọc ngược từ 543 về 0)
    always_ff @(posedge clk) begin
        if (!rst_n) rd_ptr <= 10'd543;
        else if (dec_valid) begin
            rd_ptr <= (dec_sop) ? 10'd542 : rd_ptr - 1'b1;
        end else rd_ptr <= 10'd543;
    end

    // assign ram_data_out = cmp_ram[rd_ptr];

    always_ff @(posedge clk) begin
        if (dec_valid) begin
            ram_data_out <= cmp_ram[rd_ptr];
        end
    end

    // Delay 1 nhịp để khớp độ trễ RAM
    always_ff @(posedge clk) begin
        dec_data_q  <= dec_data;
        dec_valid_q <= dec_valid;
    end

    // So sánh và đếm lỗi đã sửa
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || start_demo) begin
            corrected_err_cnt <= '0;
        end else if (dec_valid_q) begin
            // Nếu dữ liệu sau decode khác dữ liệu corrupted nạp vào RAM -> Đã sửa lỗi
            if (dec_data_q != ram_data_out) begin
                corrected_err_cnt <= corrected_err_cnt + 1'b1;
            end
        end
    end

    // Chốt trạng thái Demo
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            demo_done    <= 1'b0;
            demo_success <= 1'b0;
            demo_fail    <= 1'b0;
        end else if (start_demo) begin
            demo_done    <= 1'b0;
            demo_success <= 1'b0;
            demo_fail    <= 1'b0;
        end else if (dec_valid_q == 1'b0 && dec_valid == 1'b1) begin // Start of output
             demo_done <= 1'b0;
        end else if (dec_valid_q == 1'b1 && dec_valid == 1'b0) begin // Falling edge
            demo_done    <= 1'b1;
            demo_fail    <= dec_error;
            demo_success <= !dec_error;
        end
    end

    assign error = enc_error | dec_error;
    assign ready = enc_ready & dec_ready;

endmodule:top
