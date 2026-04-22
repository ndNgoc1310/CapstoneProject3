module led_7s_enc_hex_1d (
	input   logic [3:0] hex_in,
	output  logic [6:0] enc_out
);

	always_comb begin
		case (hex_in)
			4'h0:		enc_out = 7'b100_0000;	// 0x40
			4'h1:		enc_out = 7'b111_1001;	// 0x79
			4'h2:		enc_out = 7'b010_0100;	// 0x24
			4'h3:		enc_out = 7'b011_0000;	// 0x30
			4'h4:		enc_out = 7'b001_1001;	// 0x19
			4'h5:		enc_out = 7'b001_0010;	// 0x12
			4'h6:		enc_out = 7'b000_0010;	// 0x02
			4'h7:		enc_out = 7'b111_1000;	// 0x78
			4'h8:		enc_out = 7'b000_0000;	// 0x00
			4'h9:		enc_out = 7'b001_0000;	// 0x10
			4'hA:		enc_out = 7'b000_1000;	// 0x08
			4'hB:		enc_out = 7'b000_0011;	// 0x03
			4'hC:		enc_out = 7'b100_0110;	// 0x46
			4'hD:		enc_out = 7'b010_0001;	// 0x21
			4'hE:		enc_out = 7'b000_0110;	// 0x06
			4'hF:		enc_out = 7'b000_1110;	// 0x0E
			default: 	enc_out = 7'b111_1111;	// all segments off

		endcase
	end

endmodule : led_7s_enc_hex_1d

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

endmodule:led_7s_enc_dec_1d

module led_7s_enc_dec_2d (
	input   logic [6:0] dec_in,
	output  logic [6:0] enc_out_0, enc_out_1
);

	logic [3:0] tens, units;

	always_comb begin
		tens = dec_in / 10'd10;
		units = dec_in % 10'd10;
	end

	led_7s_enc_dec_1d Enc_0 (
		.dec_in		(units),
		.enc_out	(enc_out_0)
	);

	led_7s_enc_dec_1d Enc_1 (
		.dec_in		(tens),
		.enc_out	(enc_out_1)
	);

endmodule:led_7s_enc_dec_2d

module led_7s_enc_dec_3d (
	input   logic [9:0] dec_in,
	output  logic [6:0] enc_out_0, enc_out_1, enc_out_2
);

	logic [3:0] hundreds, tens, units;

	always_comb begin
		hundreds = dec_in / 10'd100;
		tens = (dec_in % 10'd100) / 10'd10;
		units = dec_in % 10'd10;
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

endmodule:led_7s_enc_dec_3d

module led_7s_enc_pass_fail
(
	input   logic 		pass,
	output  logic [6:0] enc_out_0, enc_out_1, enc_out_2, enc_out_3	
);

	always_comb begin
		if (pass) begin
			enc_out_0 = 7'b001_0010;	// 0x12 (S)
			enc_out_1 = 7'b001_0010;	// 0x12 (S)
			enc_out_2 = 7'b000_1000;	// 0x08 (A)
			enc_out_3 = 7'b000_1100;	// 0x0C (P)
		end else begin
			enc_out_0 = 7'b100_0111;	// 0x47 (L)
			enc_out_1 = 7'b100_1111;	// 0x4F (I)
			enc_out_2 = 7'b000_1000;	// 0x08 (A)
			enc_out_3 = 7'b000_1110;	// 0x0E (F)		
		end
	end
endmodule:led_7s_enc_pass_fail

module led_7s_enc_ps_fl
(
	input   logic 		pass,
	output  logic [6:0] enc_out_0, enc_out_1
);

	always_comb begin
		if (pass) begin
			enc_out_0 = 7'b001_0010;	// 0x12 (S)
			enc_out_1 = 7'b000_1100;	// 0x0C (P)
		end else begin
			enc_out_0 = 7'b100_0111;	// 0x47 (L)
			enc_out_1 = 7'b000_1110;	// 0x0E (F)		
		end
	end
endmodule:led_7s_enc_ps_fl
