module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,

	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// ---------------------------------------------------------------------------
// opcode
// ---------------------------------------------------------------------------
localparam OP_LOAD    = 4'b0000;
localparam OP_RIGHT   = 4'b0001;
localparam OP_LEFT    = 4'b0010;
localparam OP_UP      = 4'b0011;
localparam OP_DOWN    = 4'b0100;
localparam OP_CN_REDU = 4'b0101;	//Reduce the channel depth
localparam OP_CN_INCR = 4'b0110;	//Increase the channel depth
localparam OP_DIS     = 4'b0111;	//Output the pixels in the display region
localparam OP_CONV    = 4'b1000;	//Perform convolution
localparam OP_MED_FIL = 4'b1001;	//Median filter
localparam OP_HWT	  = 4'b1010;	//Haar wavelet transform

// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------
localparam State_IDLE    = 4'b0000;
localparam State_READY   = 4'b0001;
localparam State_READY_F = 4'b0010;
localparam State_OP      = 4'b0011;
localparam State_LOAD    = 4'b0100;
localparam State_OP_FIN  = 4'b0101;
localparam State_DIS	 = 4'b0110;
localparam State_DIS2	 = 4'b0111;
localparam State_CONV	 = 4'b1000;
localparam State_CONV2	 = 4'b1001;
localparam State_MED	 = 4'b1011;
localparam State_HWT	 = 4'b1100;
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
// reg o_in_ready_r, o_in_ready_w;
reg o_out_valid_r, o_out_valid_w;
reg [13:0] o_out_data_r;
// wire [13:0] o_out_data_w;
reg o_op_ready_r, o_op_ready_w;

reg [7:0] i_in_data_save;
reg 	  i_op_valid_save;
reg [3:0] op, i_op_mode_save;

reg [3:0] State_C, State_N;

reg [11:0] sram_addr;
wire [7:0] sram_output;
wire 	   sram_wen;

reg [5:0] depth_counter;
reg [2:0] col_counter, row_counter;
reg [1:0] four_counter; // for display & HWT
reg [2:0] eight_counter, eight_counter_1, eight_counter_2; // for HWT
reg [4:0] nine_counter, nine_counter_1, nine_counter_2, nine_counter_3, nine_counter_4, nine_counter_5;	//for conv & median filter

reg [2:0] origin_col, origin_row;
reg [5:0] origin_dep;

reg [16:0] con_add;
reg [7:0] med_save [8:0];

//wire [7:0] med_save_sort [8:0];
wire [7:0] med_med;
median med1(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_in_1(med_save[0]), .data_in_2(med_save[1]), .data_in_3(med_save[2]),
						   					  .data_in_4(med_save[3]), .data_in_5(med_save[4]), .data_in_6(med_save[5]),
											  .data_in_7(med_save[6]), .data_in_8(med_save[7]), .data_in_9(med_save[8]), .med_med(med_med));

reg signed  [13:0] HWT_save   [3:0];
wire signed [13:0] HWT_output [3:0];
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_in_ready = 1'b1;
assign o_out_data = o_out_data_r;
assign o_out_valid = o_out_valid_r;
assign o_op_ready = o_op_ready_r;

assign HWT_output[0] = (HWT_save[0] + HWT_save[1] + HWT_save[2] + HWT_save[3]);
assign HWT_output[1] = (HWT_save[0] - HWT_save[1] + HWT_save[2] - HWT_save[3]);
assign HWT_output[2] = (HWT_save[0] + HWT_save[1] - HWT_save[2] - HWT_save[3]);
assign HWT_output[3] = (HWT_save[0] - HWT_save[1] - HWT_save[2] + HWT_save[3]);



//coordinate shift
wire [2:0] ori_R, ori_L, ori_D, ori_U;

assign ori_R = origin_col+1;
assign ori_L = origin_col-1;
assign ori_D = origin_row+1;
assign ori_U = origin_row-1;

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		origin_col <= 0;
		origin_row <= 0;
		origin_dep <= 6'b100000;
	end 
	else if(State_C == State_OP_FIN) begin
		if(op == OP_RIGHT 	  && (origin_col!=6)) origin_col <= ori_R;
		else if(op == OP_LEFT && (origin_col!=0)) origin_col <= ori_L;
		else if(op == OP_DOWN && (origin_row!=6)) origin_row <= ori_D;
		else if(op == OP_UP   && (origin_row!=0)) origin_row <= ori_U;
		else if(op == OP_CN_INCR && (origin_dep != 6'b100000)) origin_dep <= origin_dep << 1;
		else if(op == OP_CN_REDU && (origin_dep != 6'b001000)) origin_dep <= origin_dep >> 1;
	end
	else if(State_C == State_CONV) begin
		if(op == OP_CONV && depth_counter == origin_dep-1 && nine_counter == 8) begin
			case (four_counter)
				0: begin
					origin_col <= ori_R;
				end
				1: begin
					origin_col <= ori_L;
					origin_row <= ori_D;
				end
				2: begin
					origin_col <= ori_R;
				end
				3: begin
					origin_col <= ori_L;
					origin_row <= ori_U;
				end
			endcase
		end
	end
	else if(State_C == State_MED) begin
		if(op == OP_MED_FIL && nine_counter == 10) begin
			case (four_counter)
				0: begin
					origin_col <= ori_R;
				end
				1: begin
					origin_col <= ori_L;
					origin_row <= ori_D;
				end
				2: begin
					origin_col <= ori_R;
				end
				3: begin
					origin_col <= ori_L;
					origin_row <= ori_U;
				end
			endcase
		end
	end
end

//read input and synchronize with posedge
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		i_in_data_save	<= 0;
		i_op_valid_save	<= 0;
		i_op_mode_save	<= 0;
		op 				<= 0;
	end
	else begin
		i_in_data_save  <= i_in_data;
		i_op_valid_save <= i_op_valid;
		i_op_mode_save  <= i_op_mode;
		if(i_op_valid_save) op <= i_op_mode_save;	//update on the next cycle
	end
end



// output

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		o_out_data_r <= 0;
		o_out_valid_r <= 0;
	end
	else begin
		if(op == OP_DIS) o_out_data_r <= {7'b0, sram_output};
		else if(op == OP_CONV) o_out_data_r <= (con_add[16:4]+con_add[3]);
		else if(op == OP_MED_FIL) o_out_data_r <= med_med;
		else if(op == OP_HWT) begin
			case (eight_counter_2)
				4: begin
					o_out_data_r <= {HWT_output[0][13], {$signed(HWT_output[0][13:1]) + HWT_output[0][0]}};
				end
				5: begin
					o_out_data_r <= {HWT_output[1][13], {$signed(HWT_output[1][13:1]) + HWT_output[1][0]}};
				end
				6: begin
					o_out_data_r <= {HWT_output[2][13], {$signed(HWT_output[2][13:1]) + HWT_output[2][0]}};
				end
				7: begin
					o_out_data_r <= {HWT_output[3][13], {$signed(HWT_output[3][13:1]) + HWT_output[3][0]}};
				end
				default: o_out_data_r <= 7'b0;
			endcase
		end
		o_out_valid_r <= o_out_valid_w;

		if(sram_addr != 4095 && op == OP_DIS) o_out_valid_w <= 1'b1;
		else if(op == OP_CONV && nine_counter_2 == 8 && depth_counter == 0) o_out_valid_w <= 1'b1;
		else if(op == OP_MED_FIL && nine_counter_5 == 8) o_out_valid_w <= 1'b1;
		else if(eight_counter_2 > 2 && eight_counter_2 < 7) o_out_valid_w <= 1'b1;
		else o_out_valid_w <= 1'b0;
	end
end


// ---------------------------------------------------------------------------
// SRAM Read and Write
// ---------------------------------------------------------------------------


assign sram_wen = ~(State_C == State_LOAD);

sram_4096x8 sram0(.Q(sram_output), .D(i_in_data_save), .CLK(i_clk), .CEN(1'b0), .WEN(sram_wen), .A(sram_addr));

wire [2:0] row_u, row_d, col_l, col_r;

wire [8:0] con_yes;
reg  [8:0] con_yes_1, con_yes_2;

// display region
assign row_u = origin_row;
assign row_d = origin_row + 1;

assign col_l = origin_col;
assign col_r = origin_col + 1;

always@(*) begin
	row_counter = origin_row;
	col_counter = origin_col;
	if(State_C == State_DIS) begin
		case (four_counter)
			2'b00:begin
				row_counter = row_u;
				col_counter = col_l;
			end
			2'b01:begin
				row_counter = row_u;
				col_counter = col_r;
			end
			2'b10:begin
				row_counter = row_d;
				col_counter = col_l;
			end
			2'b11:begin
				row_counter = row_d;
				col_counter = col_r;
			end
		endcase
	end
	else if(State_C == State_CONV || State_C == State_MED) begin
		case (nine_counter)
			0:begin
				row_counter = (con_yes[0])? origin_row-1: origin_row;
				col_counter = (con_yes[0])? origin_col-1: origin_col;
			end
			1:begin
				row_counter = (con_yes[1])? origin_row-1: origin_row;
				col_counter = (con_yes[1])? origin_col: origin_col;
			end
			2:begin
				row_counter = (con_yes[2])? origin_row-1: origin_row;
				col_counter = (con_yes[2])? origin_col+1: origin_col;
			end
			3:begin
				row_counter = (con_yes[3])? origin_row: origin_row;
				col_counter = (con_yes[3])? origin_col-1: origin_col;
			end
			4:begin
				row_counter = origin_row;
				col_counter = origin_col;
			end
			5:begin
				row_counter = (con_yes[5])? origin_row: origin_row;
				col_counter = (con_yes[5])? origin_col+1: origin_col;
			end
			6:begin
				row_counter = (con_yes[6])? origin_row+1: origin_row;
				col_counter = (con_yes[6])? origin_col-1: origin_col;
			end
			7:begin
				row_counter = (con_yes[7])? origin_row+1: origin_row;
				col_counter = (con_yes[7])? origin_col: origin_col;
			end
			8:begin
				row_counter = (con_yes[8])? origin_row+1: origin_row;
				col_counter = (con_yes[8])? origin_col+1: origin_col;
			end
		endcase
	end
	else if(State_C == State_HWT) begin
		case (eight_counter)
			0:begin
				row_counter = row_u;
				col_counter = col_l;
			end
			1:begin
				row_counter = row_u;
				col_counter = col_r;
			end
			2:begin
				row_counter = row_d;
				col_counter = col_l;
			end
			3:begin
				row_counter = row_d;
				col_counter = col_r;
			end
		endcase
	end
end

//set all counter
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		depth_counter <= 0;
		four_counter <= 0;
		nine_counter <= 0;
		eight_counter <= 0;
	end
	else if(State_C == State_OP) begin
		depth_counter <= 0;
		if(i_op_mode_save == OP_DIS) four_counter <= 0;
		if(i_op_mode_save == OP_CONV || State_C == State_MED) nine_counter <= 0;
	end
	else if(State_C == State_DIS) begin
		if(four_counter == 2'b11) depth_counter <= depth_counter+1;
		four_counter <= four_counter + 1;
	end
	else if(State_C == State_CONV) begin
		if(nine_counter == 8) begin 
			depth_counter <= depth_counter+1;
			nine_counter <= 0;
			if(depth_counter == origin_dep-1) begin
				four_counter <= four_counter + 1;
				depth_counter <= 0;
			end
		end
		else begin
			nine_counter <= nine_counter + 1;
		end
	end
	else if(State_C == State_MED) begin
		if(nine_counter == 10) begin 
			four_counter <= four_counter + 1;
			nine_counter <= 0;
			if(four_counter == 3) begin
				depth_counter <= depth_counter+1;
				four_counter <= 0;
			end
		end
		else begin
			nine_counter <= nine_counter + 1;
		end
	end
	else if(State_C == State_HWT) begin
		eight_counter <= eight_counter + 1;
		if(eight_counter == 7) begin
			depth_counter <= depth_counter+1;
			eight_counter <= 0;
		end
	end
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		nine_counter_1 <= 0;
		nine_counter_2 <= 0;
		nine_counter_3 <= 0;
		nine_counter_4 <= 0;
		nine_counter_5 <= 0;
		eight_counter_1 <= 0;
		eight_counter_2 <= 0;
		con_yes_1 <= 0;
		con_yes_2 <= 0;
	end
	else begin
		nine_counter_1 <= nine_counter;
		nine_counter_2 <= nine_counter_1;
		nine_counter_3 <= nine_counter_2;
		nine_counter_4 <= nine_counter_3;
		nine_counter_5 <= nine_counter_4;
		eight_counter_1 <= eight_counter;
		eight_counter_2 <= eight_counter_1;
		con_yes_1 <= con_yes;
		con_yes_2 <= con_yes_1;
	end
end
integer i;
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		con_add <= 0;
		for(i = 0; i < 9; i=i+1) begin
			med_save[i] <= 0;
		end
		for(i=0; i < 4; i=i+1) begin
			HWT_save[i] <= 0;
		end
	end
	else begin
		if(nine_counter_2 != nine_counter_1 && (op == OP_CONV || op == OP_MED_FIL)) begin
			case (nine_counter_2)
				0: begin
					if(depth_counter == 0) begin
						if(con_yes_2[0]) begin
							con_add <= 0 + (sram_output);
							med_save[0] <= sram_output;
						end
						else begin
							con_add <= 0;
							med_save[0] <= 8'b0;
						end
					end
					else begin
						if(con_yes_2[0]) begin
							con_add <= con_add + (sram_output);
							med_save[0] <= sram_output;
						end
						else begin
							med_save[0] <= 8'b0;
						end
					end
				end
				1: begin
					if(con_yes_2[1]) begin 
						con_add <= con_add + (sram_output << 1);
						med_save[1] <= sram_output;
					end
					else begin
						med_save[1] <= 8'b0;
					end
				end
				2: begin
					if(con_yes_2[2]) begin 
						con_add <= con_add + (sram_output);
						med_save[2] <= sram_output;
					end
					else begin
						med_save[2] <= 8'b0;
					end
				end
				3: begin
					if(con_yes_2[3]) begin 
						con_add <= con_add + (sram_output << 1);
						med_save[3] <= sram_output;
					end
					else begin
						med_save[3] <= 8'b0;
					end
				end
				4: begin	//no need to if
					con_add <= con_add + (sram_output << 2);
					med_save[4] <= sram_output;
				end
				5: begin
					if(con_yes_2[5]) begin 
						con_add <= con_add + (sram_output << 1);
						med_save[5] <= sram_output;
					end
					else begin
						med_save[5] <= 8'b0;
					end
				end
				6: begin
					if(con_yes_2[6]) begin 
						con_add <= con_add + (sram_output);
						med_save[6] <= sram_output;
					end
					else begin
						med_save[6] <= 8'b0;
					end
				end
				7: begin
					if(con_yes_2[7]) begin 
						con_add <= con_add + (sram_output << 1);
						med_save[7] <= sram_output;
					end
					else begin
						med_save[7] <= 8'b0;
					end
				end
				8: begin
					if(con_yes_2[8]) begin 
						con_add <= con_add + (sram_output);
						med_save[8] <= sram_output;
					end
					else begin
						med_save[8] <= 8'b0;
					end
				end
				default : begin
					med_save[8] <= 8'b0;
				end
			endcase
		end
		else if(op == OP_HWT) begin
			case(eight_counter_2)
				0: begin
					HWT_save[0] <= {6'b0, sram_output};
				end
				1: begin
					HWT_save[1] <= {sram_output};
				end
				2: begin
					HWT_save[2] <= {sram_output};
				end
				3: begin
					HWT_save[3] <= {sram_output};
				end
			endcase
		end
	end
end

// convolution region
assign con_yes[0] = !(origin_col == 0 || origin_row == 0);
assign con_yes[1] = !(origin_row == 0);
assign con_yes[2] = !(origin_col == 7 || origin_row == 0);

assign con_yes[3] = !(origin_col == 0);
//assign con_yes[4] = 1'b1;
assign con_yes[5] = !(origin_col == 7);

assign con_yes[6] = !(origin_col == 0 || origin_row == 7);
assign con_yes[7] = !(origin_row == 7);
assign con_yes[8] = !(origin_col == 7 || origin_row == 7);



//set sram addr
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n)					sram_addr <= 4095;
	else if(State_N == State_OP_FIN)	sram_addr <= 4095;
	else if(State_C == State_LOAD)	sram_addr <= sram_addr+1;
	else if(State_C == State_OP && i_op_mode_save == 0)	sram_addr <= 0;
	else if(State_C == State_DIS || State_C == State_CONV || State_C == State_MED || State_C == State_HWT) begin
		sram_addr <= row_counter*8+col_counter+depth_counter*64;
	end
end

// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------

always @(*) begin	//FSM control
	State_N = State_C;
	case(State_C)
	State_IDLE:begin
		State_N = State_READY;	
	end
	State_READY:begin
		State_N = State_READY_F;
	end
	State_READY_F:begin
		State_N = State_OP;
	end
	State_OP:begin
		State_N = State_OP_FIN;
		case(i_op_mode_save)
		OP_LOAD: begin
			State_N = State_LOAD;
		end
		OP_DIS: begin
			State_N = State_DIS;
		end
		OP_CONV: begin
			State_N = State_CONV;
		end
		OP_MED_FIL: begin
			State_N = State_MED;
		end
		OP_HWT: begin
			State_N = State_HWT;
		end
		endcase
	end
	State_LOAD: begin
		if(sram_addr == 2047) State_N = State_OP_FIN;
	end
	State_DIS: begin
		if(depth_counter == origin_dep-1 && four_counter == 2'b11) State_N = State_DIS2;
	end
	State_DIS2: begin
		State_N = State_OP_FIN;
	end
	State_CONV: begin
		if(depth_counter == origin_dep-1 && nine_counter == 8 && four_counter == 2'b11) State_N = State_CONV2;
	end
	State_CONV2: begin
		State_N = State_OP_FIN;
	end
	State_MED: begin
		if(depth_counter == 3 && nine_counter == 10 && four_counter == 2'b11) State_N = State_OP_FIN;
	end
	State_HWT: begin
		if(eight_counter == 7) begin
			if(depth_counter == 3) begin
				State_N = State_OP_FIN;
			end
			else State_N = State_HWT;
		end
	end
	State_OP_FIN: begin
		State_N = State_READY;
	end
	endcase
end

always@(*) begin	//FSM output
	case(State_C)
	State_IDLE : o_op_ready_w = 1'b1;
	State_OP_FIN : o_op_ready_w = 1'b1;
	default : o_op_ready_w = 1'b0;
	endcase
end

always@(posedge i_clk or negedge i_rst_n) begin		//FSM change state
	if(!i_rst_n) begin
		State_C	<= State_IDLE;
		o_op_ready_r <= 0;
	end 
	else begin
		State_C	<= State_N;
		o_op_ready_r <= o_op_ready_w;
	end
end

endmodule
