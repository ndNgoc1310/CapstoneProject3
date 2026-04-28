`timescale 1ns / 1ps
// =====================================================================
// Module: uart_rx.sv
// Chức năng: Nhận UART 8-bit -> Đệm FIFO -> Gearbox (Gộp 5 byte thành 4 symbol 10-bit)
// Tương thích: Mạch RS(544, 514) GF(2^10)
// =====================================================================

module uart_rx #(
    parameter CLK_FREQ   = 50_000_000, // Tần số thạch anh trên DE10 (50 MHz)
    parameter BAUD_RATE  = 115200,     // Tốc độ Baud của Hercules
    parameter WIDTH      = 10,         // Độ rộng symbol của RS Codec GF(2^10)
    parameter FIFO_DEPTH = 1024        // Đủ Lớn để chứa 1 gói 680 bytes
)(
    input  logic             clk,
    input  logic             rst_n,

    // 1. Giao tiếp Vật lý UART
    input  logic             rxd,

    // 2. Tín hiệu cấu hình chế độ
    input  logic             mode,        // 0 = Encoder (642 bytes), 1 = Decoder (680 bytes)

    // 3. Giao tiếp với RS Codec (Khớp với top.sv: enc_*_in hoặc dec_*_in)
    input  logic             codec_ready, // Codec đã sẵn sàng nhận dữ liệu chưa?
    output logic             codec_sop,   // Cờ báo hiệu Symbol đầu tiên
    output logic             codec_valid, // Cờ báo dữ liệu hợp lệ
    output logic [WIDTH-1:0] codec_data   // Dữ liệu 10-bit đã được gộp (Bit-packed)
);

    // =================================================================
    // KHỐI 1: UART PHYSICAL RECEIVER (Tham khảo: Alex Forencich)
    // Chức năng: Lấy mẫu vượt tốc (Oversampling) để nhận 8-bit an toàn
    // =================================================================
    localparam PRESCALE = CLK_FREQ / BAUD_RATE;

    // Synchronizer 3 cấp chống Metastability
    logic [2:0] rxd_sync_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rxd_sync_reg <= 3'b111;
        else        rxd_sync_reg <= {rxd_sync_reg[1:0], rxd};
    end
    logic rxd_sync;
    assign rxd_sync = rxd_sync_reg[2];

    logic [15:0] prescale_cnt;
    logic [3:0]  rx_bit_cnt;
    logic [7:0]  rx_shift_reg;
    logic [7:0]  rx_tdata;  
    logic        rx_tvalid; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_bit_cnt   <= 4'd0;
            prescale_cnt <= 16'd0;
            rx_tvalid    <= 1'b0;
            rx_shift_reg <= 8'd0;
            rx_tdata     <= 8'd0;
        end else begin
            rx_tvalid <= 1'b0; 
            if (prescale_cnt > 16'd0) begin
                prescale_cnt <= prescale_cnt - 16'd1;
            end else if (rx_bit_cnt > 4'd0) begin
                if (rx_bit_cnt > 4'd9) begin
                    if (!rxd_sync) begin
                        rx_bit_cnt   <= rx_bit_cnt - 4'd1;
                        prescale_cnt <= (16)'(PRESCALE - 1);
                    end else begin
                        rx_bit_cnt <= 'd0;
                    end
                end else if (rx_bit_cnt > 4'd1) begin
                    rx_bit_cnt   <= rx_bit_cnt - 4'd1;
                    prescale_cnt <= (16)'(PRESCALE - 1);
                    rx_shift_reg <= {rxd_sync, rx_shift_reg[7:1]};
                end else if (rx_bit_cnt == 4'd1) begin
                    rx_bit_cnt <= 4'd0;
                    if (rxd_sync) begin 
                        rx_tdata  <= rx_shift_reg;
                        rx_tvalid <= 1'b1; 
                    end
                end
            end else begin
                if (!rxd_sync) begin 
                    rx_bit_cnt   <= 4'd10; 
                    prescale_cnt <= (16)'((PRESCALE / 2) - 1); 
                end
            end
        end
    end

    // =================================================================
    // KHỐI 2: SYNCHRONOUS FIFO
    // Chức năng: Đệm các byte nhận được từ UART
    // =================================================================
    logic [7:0] fifo_mem [0:FIFO_DEPTH-1];
    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [$clog2(FIFO_DEPTH):0]   fifo_count;
    logic fifo_full, fifo_empty, fifo_rd_en;
    
    assign fifo_full  = (fifo_count == ($clog2(FIFO_DEPTH))'(FIFO_DEPTH));
    assign fifo_empty = (fifo_count == 1'b0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr     <= ($clog2(FIFO_DEPTH))'('d0);
            rd_ptr     <= ($clog2(FIFO_DEPTH))'('d0);
            fifo_count <= ($clog2(FIFO_DEPTH))'('d0);
        end else begin
            case ({rx_tvalid && !fifo_full, fifo_rd_en})
                2'b10: begin // Ghi
                    fifo_mem[wr_ptr] <= rx_tdata;
                    wr_ptr           <= wr_ptr + ($clog2(FIFO_DEPTH))'('d1);
                    fifo_count       <= fifo_count + ($clog2(FIFO_DEPTH))'('d1);
                end
                2'b01: begin // Đọc
                    rd_ptr           <= rd_ptr + ($clog2(FIFO_DEPTH))'('d1);
                    fifo_count       <= fifo_count - ($clog2(FIFO_DEPTH))'('d1);
                end
                2'b11: begin // Ghi và Đọc
                    fifo_mem[wr_ptr] <= rx_tdata;
                    wr_ptr           <= wr_ptr + ($clog2(FIFO_DEPTH))'('d1);
                    rd_ptr           <= rd_ptr + ($clog2(FIFO_DEPTH))'('d1);
                end
            endcase
        end
    end

    // =================================================================
    // KHỐI 3: GEARBOX (BIT-PACKING) & SOP GENERATOR
    // Chức năng: Chuyển đổi 5 byte (8-bit) thành 4 symbol (10-bit)
    // =================================================================
    
    // Quy định số lượng byte cần nhận từ Hercules
    logic [9:0] target_bytes;
    assign target_bytes = (mode == 1'b0) ? 10'd642 : 10'd680;

    // Các biến cho Hộp số (Gearbox)
    logic [15:0] buffer;       // Thanh ghi trượt chứa bit dư thừa (tối đa 16 bit)
    logic [4:0]  bit_count;    // Theo dõi số bit hợp lệ đang có trong `buffer`
    logic [9:0]  in_byte_cnt;  // Đếm số byte (8-bit) đã rút ra từ FIFO
    logic [9:0]  out_sym_cnt;  // Đếm số symbol (10-bit) đã bơm vào Codec

    // Khai báo biến logic tổ hợp (Combinational) bên ngoài khối always_ff
    logic [15:0] next_buffer;
    logic [4:0]  next_bit_count;

    // Tính toán trước giá trị tiếp theo
    assign next_buffer = (buffer << 8) | fifo_mem[rd_ptr];
    assign next_bit_count = bit_count + 8;

    // Điều kiện rút FIFO: Không rỗng + Codec sẵn sàng + Chưa rút đủ số byte của gói
    assign fifo_rd_en = !fifo_empty && codec_ready && (in_byte_cnt < target_bytes);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer      <= '0;
            bit_count   <= '0;
            in_byte_cnt <= '0;
            out_sym_cnt <= '0;
            codec_valid <= 1'b0;
            codec_sop   <= 1'b0;
            codec_data  <= '0;
        end else begin
            codec_valid <= 1'b0; // Mặc định hạ valid
            codec_sop   <= 1'b0; // Mặc định hạ SOP

            // TRƯỜNG HỢP 1: Đang rút byte từ FIFO để ghép bit
            if (fifo_rd_en) begin
                in_byte_cnt <= in_byte_cnt + 1'b1;

                // Nếu số bit gom được >= 10, ta có đủ 1 symbol để xuất
                if (next_bit_count >= 10) begin
                    codec_valid <= 1'b1;
                    codec_sop   <= (out_sym_cnt == 0); // Kích SOP nếu là symbol đầu tiên
                    
                    // Cắt lấy đúng 10 bit cao nhất trong mảng bit đang có
                    // Cú pháp '-: 10' nghĩa là lấy từ vị trí (next_bit_count-1) lùi xuống 10 bit
                    codec_data  <= next_buffer[next_bit_count-1 -: 10]; 
                    
                    out_sym_cnt <= out_sym_cnt + 1'b1;
                    bit_count   <= next_bit_count - 10; // Trừ đi 10 bit đã dùng
                    buffer      <= next_buffer;         // Lưu các bit thừa còn lại cho lần sau
                end else begin
                    // Chưa đủ 10 bit, tiếp tục cất đi chờ byte tiếp theo
                    bit_count   <= next_bit_count;
                    buffer      <= next_buffer;
                end
            end 
            
            // TRƯỜNG HỢP 2: Đã rút đủ byte của gói tin, tiến hành FLUSH (Chèn Zero-padding)
            // (Chỉ xảy ra ở Mode Encoder vì byte thứ 641 và 642 sẽ dư ra 6 bit)
            else if (in_byte_cnt == target_bytes) begin
                if (bit_count > 0 && codec_ready) begin
                    // Bơm nốt các bit thừa cuối cùng
                    codec_valid <= 1'b1;
                    codec_sop   <= (out_sym_cnt == 0);
                    
                    // Dịch trái các bit thừa để phần đệm '0' nằm ở phía LSB (Zero-padding)
                    codec_data  <= (buffer << (10 - bit_count)) & 10'h3FF;
                    
                    // Dọn dẹp sổ tay chuẩn bị cho gói tin tiếp theo
                    out_sym_cnt <= 0;
                    in_byte_cnt <= 0;
                    bit_count   <= 0;
                end 
                else if (bit_count == 0) begin
                    // Mode Decoder (680 bytes) chia hết hoàn toàn (544 symbols), không dư bit nào
                    // Trực tiếp dọn sổ tay chuẩn bị cho gói mới
                    out_sym_cnt <= 0;
                    in_byte_cnt <= 0;
                end
            end
        end
    end

endmodule: uart_rx
