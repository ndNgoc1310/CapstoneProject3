`timescale 1ns / 1ps
// =====================================================================
// Module: wrapper_uart (Top-level)
// Chức năng: Nối dây các module con theo phong cách Structural
// =====================================================================

module wrapper_uart (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,     
    input  logic [9:0]  SW,      
    
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0]  LEDR,
    
    inout  wire  [35:0] GPIO 
);

// ==========================================
// Vars
// ==========================================

    // I/O
    logic       clk;
    logic       rst_n; 
    logic       rs_sel;
    logic [1:0] disp_mode;

    logic [9:0] corr_cnt;
    logic [9:0] disp_idx;

    logic [9:0] rd_dec_pos;
    logic [9:0] rd_dec_mag;

    logic       enc_err_led;
    logic       dec_err_led;
    logic [6:0] hex_led [5:0];

    // UART Core
    logic       uart_rx_en;
    logic       uart_rx_rden;
    logic [7:0] uart_rx_dat;
    logic       uart_rx_done;
    logic       uart_rx;

    logic       uart_tx_wren;
    logic [7:0] uart_tx_dat;
    logic       uart_tx_done;
    logic       uart_tx;

    // RX Gearbox
    logic       gbx_rx_vld;
    logic [9:0] gbx_rx_dat;
    logic       gbx_rx_end;

    // RX Buffer 
    logic       buf_rx_sop;
    logic       buf_rx_vld;
    logic [9:0] buf_rx_dat;

    // TX Buffer
    logic       rs_tx_vld;
    logic [9:0] rs_tx_dat;
    logic       buf_tx_vld;
    logic [9:0] buf_tx_dat;

    // TX Gearbox
    logic       gbx_tx_vld;
    logic [7:0] gbx_tx_dat;
    logic       gbx_tx_done;
    logic       gbx_tx_end;

    // RS Codec
    logic       enc_sop;
    logic       enc_vld;
    logic [9:0] enc_dat;
    logic       enc_rdy;
    logic       enc_err;

    logic       dec_sop;
    logic       dec_vld;
    logic [9:0] dec_dat;
    logic       dec_rdy;
    logic       dec_err;
    logic [9:0] dec_err_mag;
    logic       dec_err_flg;

// ==========================================
// Var Assignments
// ==========================================

    // I/O
    assign clk          = CLOCK_50;
    assign rst_n        = KEY[0];
    assign rs_sel       = SW[9];
    assign disp_mode    = SW[4:3];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_err_led <= 0;
            dec_err_led <= 0;
        end else begin
            if (enc_sop | enc_err) enc_err_led <= enc_err;
            if (dec_sop | dec_err) dec_err_led <= dec_err;
        end
    end

    assign LEDR[0] = enc_err_led;
    assign LEDR[1] = dec_err_led;
    assign LEDR[2] = 1'b0;
    assign LEDR[3] = SW[3];
    assign LEDR[4] = SW[4];
    assign LEDR[5] = 1'b0;
    assign LEDR[6] = 1'b0;
    assign LEDR[7] = 1'b0;
    assign LEDR[8] = 1'b0;
    assign LEDR[9] = SW[9];

    assign HEX0 = hex[0];
    assign HEX1 = hex[1];
    assign HEX2 = hex[2];
    assign HEX3 = hex[3];
    assign HEX4 = hex[4];
    assign HEX5 = hex[5];

    // RX UART Control
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         uart_rx_en <= 1'b1;         uart_rx_rden <= 1'b1;  
        else if (gbx_rx_end | gbx_tx_end)   uart_rx_en <= ~uart_rx_en;  uart_rx_rden <= ~uart_rx_rden;  
    end

    assign uart_tx_wren = gbx_tx_vld;
    assign uart_tx_dat = gbx_tx_dat;

    // TX Buffer Selection of RS Codec Ouputs
    assign rs_tx_vld = (rs_sel == 1'b0) ? enc_vld : dec_vld;
    assign rs_tx_dat = (rs_sel == 1'b0) ? enc_dat : dec_dat;

// ==========================================
// MODULE INSTANTIATIONS 
// ==========================================

    // 1. Lõi UART
    uart_core uart_core (
        .i_clk              (clk),
        .i_rst_n            (rst_n),
        .i_bclk_en          (1'b1),
        .i_baud_divisor     (-16'd27), 
        .i_parity_en        (1'b0),
        .i_even_parity      (1'b0),
        .i_dbg_lloopback    (1'b0),
        .i_dbg_sloopback    (1'b0),
        
        .i_tx_en            (1'b1),
        .i_tx_wren          (uart_tx_wren),
        .i_tx_data          (uart_tx_dat),
        .o_tx_idle          (),
        .o_tx_done          (uart_tx_done),
        .i_tx_fifo_clr      (~rst_n),
        .o_tx_fifo_empty    (),
        .o_tx_fifo_full     (),
        .o_tx_fifo_level    (),
        
        .i_rx_en            (uart_rx_en),
        .i_rx_rden          (uart_rx_rden), 
        .o_rx_data          (uart_rx_dat),
        .o_rx_idle          (),
        .o_rx_done          (uart_rx_done),
        .i_rx_fifo_clr      (~rst_n),
        .o_rx_fifo_empty    (),
        .o_rx_fifo_full     (),
        .o_rx_fifo_level    (),
        .o_rx_frame_error   (),
        .o_rx_parity_error  (),
        .o_rx_data_is_zero  (),
        
        .o_tx               (uart_tx),
        .i_rx               (uart_rx)
    );

    // 2. RX Gearbox
    rs_uart_rx_gbx rs_uart_rx_gbx (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs_sel         (rs_sel),
        
        .uart_rx_done   (uart_rx_done),
        .uart_rx_dat    (uart_rx_dat),

        .gbx_rx_vld     (gbx_rx_vld),
        .gbx_rx_dat     (gbx_rx_dat),
        .gbx_rx_end     (gbx_rx_end),
        .gbx_rx_err     ()
    );

    // 3. RX Buffer
    rs_uart_rx_buf rs_uart_rx_buf (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs_sel         (rs_sel),

        .gbx_rx_vld     (gbx_rx_vld),
        .gbx_rx_dat     (gbx_rx_dat),

        .buf_rx_sop     (buf_rx_sop),
        .buf_rx_vld     (buf_rx_vld),
        .buf_rx_dat     (buf_rx_dat),
        .buf_rx_err     ()
    );

    // 4. Lõi Reed-Solomon
    top #(.WIDTH(10), .NSYM(30), .ORDER(15), .K(544)) rs_codec (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // Encoder
        .enc_sop_in         ((rs_sel == 1'b0) ? buf_rx_sop : 1'b0),
        .enc_vld_in         ((rs_sel == 1'b0) ? buf_rx_vld : 1'b0),
        .enc_dat_in         ((rs_sel == 1'b0) ? buf_rx_dat : 10'b0),

        .enc_sop_out        (enc_sop),
        .enc_vld_out        (enc_vld),
        .enc_dat_out        (enc_dat),
        .enc_rdy            (enc_rdy),
        .enc_err            (enc_err),
        
        // Decoder
        .dec_sop_in         ((rs_sel == 1'b1) ? buf_rx_sop : 1'b0),
        .dec_vld_in         ((rs_sel == 1'b1) ? buf_rx_vld : 1'b0),
        .dec_dat_in         ((rs_sel == 1'b1) ? buf_rx_dat : 10'b0),
        .dec_sop_out        (dec_sop),
        .dec_vld_out        (dec_vld),
        .dec_dat_out        (dec_dat),
        .dec_rdy            (dec_rdy),
        .dec_err            (dec_err),
        .dec_err_flg_out    (dec_err_flg),
        .dec_err_mag_out    (dec_err_mag)
    );

    // 5. TX Buffer
    rs_uart_tx_buf rs_uart_tx_buf (
        .clk            (clk),
        .rst_n          (rst_n),

        .rs_tx_vld      (rs_tx_vld),
        .rs_tx_dat      (rs_tx_dat),

        .gbx_tx_done    (gbx_tx_done),

        .buf_tx_vld     (buf_tx_vld),
        .buf_tx_dat     (buf_tx_dat),
        .buf_tx_err     ()
    );

    // 6. TX Gearbox
    rs_uart_tx_gbx rs_uart_tx_gbx (
        .clk            (clk),
        .rst_n          (rst_n),

        .buf_tx_vld     (buf_tx_vld),
        .buf_tx_dat     (buf_tx_dat),   

        .uart_tx_done   (uart_tx_done),    

        .gbx_tx_vld     (gbx_tx_vld),
        .gbx_tx_dat     (gbx_tx_dat),
        .gbx_tx_done    (gbx_tx_done),
        .gbx_tx_end     (gbx_tx_end),
        .gbx_tx_err     ()
    );

// ==========================================
// I/O MODULES 
// ==========================================
    dec_err_track_ram u_err_track (
        .clk            (clk),
        .rst_n          (rst_n),
        .dec_vld        (dec_vld),
        .dec_sop        (dec_sop),
        .dec_err_flg    (dec_err_flg),
        .dec_err_mag    (dec_err_mag),
        .rd_addr        (disp_idx),
        .corr_cnt       (corr_cnt),
        .rd_pos         (rd_dec_pos),
        .rd_mag         (rd_dec_mag)
    );

    disp_key_ctrl u_key_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .disp_mode  (disp_mode),
        .inj_cnt    (corr_cnt),
        .key_nxt    (KEY[2]),
        .key_prv    (KEY[3]),
        .disp_idx   (disp_idx)
    );

    hex_mux u_hex_mux (
        .disp_mode  (disp_mode),
        .inj_cnt    (10'd0), 
        .corr_cnt   (corr_cnt),
        .rd_inj_pos (10'd0),
        .rd_inj_mag (10'd0),
        .rd_dec_pos (rd_dec_pos),
        .rd_dec_mag (rd_dec_mag),
        .hex0       (hex[0]), 
        .hex1       (hex[1]), 
        .hex2       (hex[2]),
        .hex3       (hex[3]), 
        .hex4       (hex[4]), 
        .hex5       (hex[5])
    );

endmodule: wrapper_uart

// =========================================================
// FPGA I/O Modules
// =========================================================
module dec_err_track_ram (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        dec_vld,
    input  logic        dec_sop,
    input  logic        dec_err_flg,
    input  logic [9:0]  dec_err_mag,
    input  logic [9:0]  rd_addr,
    
    output logic [9:0]  corr_cnt,
    output logic [9:0]  rd_pos,
    output logic [9:0]  rd_mag
);
    logic [9:0] dec_sym_cnt;
    logic [9:0] dec_pos_mem [0:543];
    logic [9:0] dec_mag_mem [0:543];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dec_sym_cnt <= '0;
            corr_cnt <= '0;
        end else if (dec_vld) begin 
            if (dec_sop) begin
                dec_sym_cnt <= 10'd1;
                if (dec_err_flg) begin
                    dec_pos_mem[0]  <= 10'd543; 
                    dec_mag_mem[0]  <= dec_err_mag;
                    corr_cnt <= 10'd1;
                end else begin
                    corr_cnt <= 10'd0;
                end
            end else begin
                dec_sym_cnt <= dec_sym_cnt + 10'd1;
                if (dec_err_flg) begin
                    dec_pos_mem[corr_cnt]    <= 10'd543 - dec_sym_cnt;
                    dec_mag_mem[corr_cnt]    <= dec_err_mag;
                    corr_cnt                 <= corr_cnt + 10'd1;
                end
            end

            rd_pos <= dec_pos_mem[rev_rd_addr];
            rd_mag <= dec_mag_mem[rev_rd_addr];
        end
    end

    logic [9:0] rev_rd_addr;
    assign rev_rd_addr = (corr_cnt > 0) ? (corr_cnt - 10'd1 - rd_addr) : 10'd0;

endmodule: dec_err_track_ram

module disp_key_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  disp_mode,
    input  logic [9:0]  inj_cnt,
    input  logic        key_nxt,
    input  logic        key_prv,
    
    output logic [9:0]  disp_idx
);
    logic [18:0] tick_cnt;
    logic tick_10ms;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tick_cnt    <= 0;
            tick_10ms   <= 0;
        end else begin
            if (tick_cnt == 19'd500_000) begin
                tick_cnt    <= 0;
                tick_10ms   <= 1'b1;
            end else begin
                tick_cnt    <= tick_cnt + 19'd1;
                tick_10ms   <= 1'b0;
            end
        end
    end

    logic key_nxt_debounced, key_prv_debounced;
    logic key_nxt_d, key_prv_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            key_nxt_debounced <= 1'b1;
            key_prv_debounced <= 1'b1;
        end else if (tick_10ms) begin
            key_nxt_debounced <= key_nxt;
            key_prv_debounced <= key_prv;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            key_nxt_d <= 1'b1;
            key_prv_d <= 1'b1;
        end else begin
            key_nxt_d <= key_nxt_debounced;
            key_prv_d <= key_prv_debounced;
        end
    end

    wire next_pressed = ~key_nxt_debounced & key_nxt_d;
    wire prev_pressed = ~key_prv_debounced & key_prv_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            disp_idx <= 10'd0;
        end else begin
            if (disp_mode != 2'b00 && inj_cnt > 0) begin
                if (next_pressed) begin
                    if (disp_idx < inj_cnt - 10'd1) disp_idx <= disp_idx + 10'd1;
                    else disp_idx <= 10'd0;
                end 
                else if (prev_pressed) begin
                    if (disp_idx > 0) disp_idx <= disp_idx - 10'd1;
                    else disp_idx <= inj_cnt - 10'd1;
                end
            end else begin
                disp_idx <= 10'd0;
            end
        end
    end
endmodule: disp_key_ctrl

module hex_mux (
    input  logic [1:0] disp_mode,
    input  logic [9:0] inj_cnt,
    input  logic [9:0] corr_cnt,
    input  logic [9:0] rd_inj_pos,
    input  logic [9:0] rd_inj_mag,
    input  logic [9:0] rd_dec_pos,
    input  logic [9:0] rd_dec_mag,
    
    output logic [6:0] hex0, hex1, hex2, hex3, hex4, hex5
);
    logic [9:0] hex_left_val, hex_right_val;
    
    always_comb begin
        case (disp_mode)
            2'b00: begin 
                hex_left_val  = inj_cnt;
                hex_right_val = corr_cnt;
            end
            2'b01: begin 
                hex_left_val  = (inj_cnt > 0) ? rd_inj_pos : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_pos : 10'd0;
            end
            2'b10: begin 
                hex_left_val  = (inj_cnt > 0) ? rd_inj_mag : 10'd0;
                hex_right_val = (corr_cnt > 0) ? rd_dec_mag : 10'd0;
            end
            default: begin
                hex_left_val  = '0;
                hex_right_val = '0;
            end
        endcase
    end

    led_7s_enc_dec_3d Display_Left (
        .dec_in    (hex_left_val),
        .enc_out_0 (hex3),
        .enc_out_1 (hex4),
        .enc_out_2 (hex5)
    );
    
    led_7s_enc_dec_3d Display_Right (
        .dec_in    (hex_right_val),
        .enc_out_0 (hex0),
        .enc_out_1 (hex1),
        .enc_out_2 (hex2)
    );
endmodule: hex_mux

module led_7s_enc_dec_1d (
	input   logic [3:0] dec_in,
	output  logic [6:0] enc_out
);

	always_comb begin
		case (dec_in)
			4'd0:		enc_out = 7'b100_0000;	// 0x40
			4'd1:		enc_out = 7'b111_1001;	// 0x79
			4'd2:		enc_out = 7'b010_0100;	// 0x24
			4'd3:		enc_out = 7'b011_0000;	// 0x30
			4'd4:		enc_out = 7'b001_1001;	// 0x19
			4'd5:		enc_out = 7'b001_0010;	// 0x12
			4'd6:		enc_out = 7'b000_0010;	// 0x02
			4'd7:		enc_out = 7'b111_1000;	// 0x78
			4'd8:		enc_out = 7'b000_0000;	// 0x00
			4'd9:		enc_out = 7'b001_0000;	// 0x10
			default:	enc_out = 7'b111_1111;	// all segments off
		endcase
	end

endmodule: led_7s_enc_dec_1d

module led_7s_enc_dec_3d (
	input   logic [9:0] dec_in,
	output  logic [6:0] enc_out_0, enc_out_1, enc_out_2
);

	logic [3:0] hundreds, tens, units;

	always_comb begin
		hundreds = (4)'(dec_in / 10'd100);
		tens = (4)'((dec_in % 10'd100) / 10'd10);
		units = (4)'(dec_in % 10'd10);
	end

	led_7s_enc_dec_1d Enc_0 (
		.dec_in		(units),
		.enc_out	(enc_out_0)
	);

	led_7s_enc_dec_1d Enc_1 (
		.dec_in		(tens),
		.enc_out	(enc_out_1)
	);

	led_7s_enc_dec_1d Enc_2 (
		.dec_in		(hundreds),
		.enc_out	(enc_out_2)
	);

endmodule: led_7s_enc_dec_3d
