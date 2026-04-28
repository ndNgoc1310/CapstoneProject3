`timescale 1ns / 1ps
// =====================================================================
// Module: uart_tx.sv
// Chức năng: MUX chọn nguồn (Encoder/Decoder) -> Đệm FIFO 10-bit -> 
//            Gearbox (Tách 4 symbol 10-bit thành 5 byte 8-bit) -> UART TX
// Tương thích: Mạch RS(544, 514) GF(2^10)
// =====================================================================

module uart_tx #(
    parameter CLK_FREQ   = 50_000_000, // Tần số thạch anh trên DE10 (50 MHz)
    parameter BAUD_RATE  = 115200,     // Tốc độ Baud của Hercules
    parameter WIDTH      = 10,         // Độ rộng symbol từ RS Codec GF(2^10)
    parameter FIFO_DEPTH = 1024        // Đủ chứa 1 gói 544 symbols
)(
    input  logic             clk,
    input  logic             rst_n,

    // ==========================================
    // 1. Tín hiệu cấu hình chế độ
    // ==========================================
    input  logic             mode,        // 0 = Chọn luồng từ Encoder, 1 = Chọn luồng từ Decoder

    // ==========================================
    // 2. Giao tiếp với RS Encoder (Khớp với enc_*_out trong top.sv)
    // ==========================================
    input  logic             enc_valid_out, // Cờ báo symbol 10-bit hợp lệ từ Encoder
    input  logic [WIDTH-1:0] enc_data_out,  // Symbol 10-bit từ Encoder

    // ==========================================
    // 3. Giao tiếp với RS Decoder (Khớp với dec_*_out trong top.sv)
    // ==========================================
    input  logic             dec_valid_out, // Cờ báo symbol 10-bit hợp lệ từ Decoder
    input  logic [WIDTH-1:0] dec_data_out,  // Symbol 10-bit từ Decoder

    // ==========================================
    // 4. Giao tiếp Vật lý UART TX
    // ==========================================
    output logic             txd,         // Dây truyền dữ liệu nối lên máy tính
    output logic             tx_busy      // (Tùy chọn) Báo hiệu đang bận truyền
);

    localparam PRESCALE = CLK_FREQ / BAUD_RATE;

    // =================================================================
    // KHỐI 1: MULTIPLEXER (CHỌN NGUỒN DỮ LIỆU)
    // Chức năng: Dựa vào tín hiệu `mode` để quyết định lấy dữ liệu từ đâu
    // =================================================================
    logic             codec_valid;
    logic [WIDTH-1:0] codec_data;

    // Toán tử 3 ngôi: Nếu mode == 0 thì lấy enc, ngược lại lấy dec
    assign codec_valid = (mode == 1'b0) ? enc_valid_out : dec_valid_out;
    assign codec_data  = (mode == 1'b0) ? enc_data_out  : dec_data_out;

    // =================================================================
    // KHỐI 2: SYNCHRONOUS FIFO (Bộ đệm chống tràn)
    // Chức năng: RS Codec nhả 544 symbol ở tốc độ 50MHz, UART truyền ở 115200bps.
    // Phải có FIFO để hứng trọn 544 symbol này rồi từ từ truyền đi.
    // =================================================================
    logic [WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [$clog2(FIFO_DEPTH):0]   fifo_count;
    
    logic fifo_empty, fifo_full;
    logic fifo_rd_en; // Lệnh rút data từ FIFO
    logic [WIDTH-1:0] fifo_q; // Data đầu ra của FIFO

    assign fifo_full  = (fifo_count == FIFO_DEPTH);
    assign fifo_empty = (fifo_count == 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr     <= 0;
            rd_ptr     <= 0;
            fifo_count <= 0;
            fifo_q     <= 0;
        end else begin
            // GHI VÀO FIFO khi luồng dữ liệu được chọn có data hợp lệ
            if (codec_valid && !fifo_full) begin
                fifo_mem[wr_ptr] <= codec_data;
                wr_ptr           <= wr_ptr + 1;
            end
            
            // ĐỌC TỪ FIFO khi Gearbox yêu cầu
            if (fifo_rd_en && !fifo_empty) begin
                fifo_q <= fifo_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end

            // Quản lý biến đếm số lượng để không bị xung đột (Race condition)
            case ({codec_valid && !fifo_full, fifo_rd_en && !fifo_empty})
                2'b10: fifo_count <= fifo_count + 1; // Chỉ ghi
                2'b01: fifo_count <= fifo_count - 1; // Chỉ đọc
                // 2'b11: ghi và đọc đồng thời -> count giữ nguyên
                // 2'b00: không làm gì -> count giữ nguyên
            endcase
        end
    end

    // =================================================================
    // KHỐI 3: GEARBOX (UN-PACKER 10-bit -> 8-bit)
    // Chức năng: Rút symbol 10-bit từ FIFO, dùng thanh ghi trượt để cắt thành 8-bit.
    // =================================================================
    
    logic [19:0] buffer;       // Thùng chứa bit (tối đa có thể giữ 18 bit)
    logic [4:0]  bit_count;    // Số lượng bit đang có sẵn trong thùng
    logic        reading_fifo; // Cờ báo hiệu nhịp trước vừa ra lệnh đọc FIFO
    
    logic [7:0]  tx_tdata;     // Dữ liệu 8-bit đã cắt xong, chuẩn bị đẩy sang UART
    logic        tx_tvalid;    // Lệnh yêu cầu UART truyền dữ liệu đi
    logic        tx_tready;    // Phản hồi từ UART báo đang rảnh

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer       <= '0;
            bit_count    <= '0;
            fifo_rd_en   <= 1'b0;
            reading_fifo <= 1'b0;
            tx_tvalid    <= 1'b0;
            tx_tdata     <= '0;
        end else begin
            tx_tvalid  <= 1'b0;  // Mặc định hạ Valid để tạo thành xung
            fifo_rd_en <= 1'b0;  // Mặc định hạ lệnh đọc FIFO

            // BƯỚC 1: Xử lý dữ liệu vừa rút từ FIFO ở nhịp Clock trước
            if (reading_fifo) begin
                // Mặt nạ (mask) giúp giữ lại các bit cũ trong thùng, tránh bị đè dữ liệu rác
                automatic logic [19:0] mask = (1 << bit_count) - 1;
                
                // Dịch các bit cũ lên cao 10 ô, ghép 10 bit mới từ FIFO vào phần thấp
                buffer <= ((buffer & mask) << 10) | fifo_q;
                bit_count <= bit_count + 10; // Tổng số bit tăng thêm 10
                
                reading_fifo <= 1'b0; // Đã chốt xong hàng
            end 
            
            // BƯỚC 2: Nếu thùng có từ 8 bit trở lên VÀ mạch UART truyền đang rảnh rỗi
            else if (bit_count >= 8) begin
                if (tx_tready && !tx_tvalid) begin
                    // Cắt lấy 8 bit CỔ NHẤT (nằm ở vị trí cao nhất) để xuất ra UART
                    tx_tdata  <= (buffer >> (bit_count - 8)) & 8'hFF;
                    tx_tvalid <= 1'b1; // Ra lệnh cho mạch UART TX truyền byte này đi
                    
                    // Trừ đi 8 bit đã xuất. Các bit thừa còn lại vẫn yên vị trong buffer
                    bit_count <= bit_count - 8; 
                end
            end 
            
            // BƯỚC 3: Nếu thùng không đủ 8 bit, ra lệnh xin thêm 1 symbol 10-bit từ FIFO
            else if (!fifo_empty && !fifo_rd_en) begin
                fifo_rd_en   <= 1'b1;
                reading_fifo <= 1'b1; // Đánh dấu để nhịp sau biết có hàng mới vào
            end
        end
    end

    // =================================================================
    // KHỐI 4: UART PHYSICAL TRANSMITTER (Tham khảo Alex Forencich)
    // Chức năng: Nhận byte 8-bit, nén lại cùng Start bit, Stop bit và bắn ra cáp UART
    // =================================================================
    
    logic [15:0] prescale_cnt; // Đồng hồ đếm ngược Baud Rate
    logic [3:0]  tx_bit_cnt;   // Đếm số lượng bit đã truyền
    logic [8:0]  tx_shift_reg; // Băng đạn chứa 8 bit data và 1 bit Stop

    // Báo bận khi vẫn còn bit đang truyền
    assign tx_busy = (tx_bit_cnt != 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_cnt <= 0;
            tx_bit_cnt   <= 0;
            tx_tready    <= 0;
            txd          <= 1'b1; // Cáp UART khi rảnh rỗi luôn giữ ở mức CAO (1)
            tx_shift_reg <= 0;
        end else begin
            if (prescale_cnt > 0) begin
                // Tạo khoảng thời gian trễ giữa các bit để đạt tốc độ 115200bps
                prescale_cnt <= prescale_cnt - 1;
            end else if (tx_bit_cnt == 0) begin
                // Mạch UART rảnh rỗi, phát tín hiệu Ready lên báo cho Gearbox biết
                tx_tready <= 1'b1;
                txd       <= 1'b1; 
                
                // Nếu Gearbox gửi tín hiệu Valid kèm Data
                if (tx_tvalid && tx_tready) begin
                    tx_tready    <= 1'b0; // Báo bận
                    prescale_cnt <= PRESCALE - 1;
                    tx_bit_cnt   <= 10;   // Bắt đầu quy trình truyền 10 nhịp (1 Start, 8 Data, 1 Stop)
                    
                    txd          <= 1'b0; // Kéo đường dây xuống mức 0 để làm Start Bit
                    tx_shift_reg <= {1'b1, tx_tdata}; // Nạp 8-bit Data và 1-bit Stop vào băng đạn
                end
            end else begin
                // Đang trong tiến trình bắn từng bit
                tx_bit_cnt   <= tx_bit_cnt - 1;
                prescale_cnt <= PRESCALE - 1; // Nạp lại đồng hồ đếm ngược
                
                // Bắn bit thấp nhất (LSB) ra cáp truyền
                txd          <= tx_shift_reg[0];
                
                // Trượt băng đạn sang phải, bù đắp số 1 vào đầu để kết thúc bằng Stop bit an toàn
                tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
            end
        end
    end

endmodule: uart_tx
