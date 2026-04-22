module led_7s_enc_hex_1d (
	input   logic [3:0] hex_in,
	output  logic [6:0] enc_out
);

	always @(*) begin
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

endmodule : led_7s_enc_dec_1d

module led_7s_enc_dec_2d (
	input   logic [6:0] dec_in,
	output  logic [6:0] enc_out_0,
	output  logic [6:0] enc_out_1
);

	logic [3:0] dec_in_0;

	always_comb begin
		case (dec_in)
			7'd0, 7'd1, 7'd2, 7'd3, 7'd4, 7'd5, 7'd6, 7'd7, 7'd8, 7'd9: begin
				dec_in_0 = dec_in[3:0];
				enc_out_1 = 7'b100_0000;
			end

			7'd10, 7'd11, 7'd12, 7'd13, 7'd14, 7'd15, 7'd16, 7'd17, 7'd18, 7'd19: begin
				dec_in_0 = dec_in[3:0] - 7'd10;
				enc_out_1 = 7'b111_1001;
			end

			7'd20, 7'd21, 7'd22, 7'd23, 7'd24, 7'd25, 7'd26, 7'd27, 7'd28, 7'd29: begin
				dec_in_0 = dec_in[3:0] - 7'd20;
				enc_out_1 = 7'b010_0100;
			end

			7'd30, 7'd31, 7'd32, 7'd33, 7'd34, 7'd35, 7'd36, 7'd37, 7'd38, 7'd39: begin
				dec_in_0 = dec_in[3:0] - 7'd30;
				enc_out_1 = 7'b011_0000;
			end

			7'd40, 7'd41, 7'd42, 7'd43, 7'd44, 7'd45, 7'd46, 7'd47, 7'd48, 7'd49: begin
				dec_in_0 = dec_in[3:0] - 7'd40;
				enc_out_1 = 7'b001_1001;
			end

			7'd50, 7'd51, 7'd52, 7'd53, 7'd54, 7'd55, 7'd56, 7'd57, 7'd58, 7'd59: begin
				dec_in_0 = dec_in[3:0] - 7'd50;
				enc_out_1 = 7'b001_0010;
			end

			7'd60, 7'd61, 7'd62, 7'd63, 7'd64, 7'd65, 7'd66, 7'd67, 7'd68, 7'd69: begin
				dec_in_0 = dec_in[3:0] - 7'd60;
				enc_out_1 = 7'b000_0010;
			end

			7'd70, 7'd71, 7'd72, 7'd73, 7'd74, 7'd75, 7'd76, 7'd77, 7'd78, 7'd79: begin
				dec_in_0 = dec_in[3:0] - 7'd70;
				enc_out_1 = 7'b111_1000;
			end

			7'd80, 7'd81, 7'd82, 7'd83, 7'd84, 7'd85, 7'd86, 7'd87, 7'd88, 7'd89: begin
				dec_in_0 = dec_in[3:0] - 7'd80;
				enc_out_1 = 7'b000_0000;
			end

			7'd90, 7'd91, 7'd92, 7'd93, 7'd94, 7'd95, 7'd96, 7'd97, 7'd98, 7'd99: begin
				dec_in_0 = dec_in[3:0] - 7'd90;
				enc_out_1 = 7'b001_0000;
			end
		endcase
	end

	led_7s_enc_dec_1d Enc_0 (
		.dec_in		(dec_in_0),
		.enc_out	(enc_out_0)
	);

endmodule : led_7s_enc_dec_2d
