module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	
	output [ ADDR_W-1 : 0 ] o_i_addr,	//output pc counter
	input  [ INST_W-1 : 0 ] i_i_inst,	//get the instruction

	output                  o_d_we,		//output data write enable
	output [ ADDR_W-1 : 0 ] o_d_addr,	//output data address
	output [ DATA_W-1 : 0 ] o_d_wdata,	//output data from memory
	input  [ DATA_W-1 : 0 ] i_d_rdata,	//input  data from memory
	
	output [        1 : 0 ] o_status,		//output check status
	output                  o_status_valid	//status valid to check
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

reg [        1 : 0 ] o_status_w	, o_status_r;
//reg           		 o_status_valid_w, o_status_valid_r; 

reg [ ADDR_W-1 : 0 ] o_i_addr_w, o_i_addr_r; 

reg 				 o_d_we_w, o_d_we_r;
reg [ ADDR_W-1 : 0 ] o_d_addr_w, o_d_addr_r;
reg [ DATA_W-1 : 0 ] o_d_wdata_w, o_d_wdata_r;

//====== reg =====
reg 	[DATA_W-1:0]	my_reg [DATA_W-1:0] ;
integer			 		i;						//initialize

reg 		[DATA_W-1:0] u_compute_temp;
reg signed	[DATA_W-1:0] compute_temp;

reg 					 unsigned_overflow;
wire 		[DATA_W-1:0] u_tmp1, u_tmp2, u_tmp1_2;
wire signed [DATA_W-1:0] tmp1, tmp2, tmp1_2;

//===== instruction =====
wire 	[ 5:0]   opcode;
wire 	[ 4:0]	 both_type_addr_2, r_type_addr_3, r_type_addr_1, i_type_addr_1;
wire	[15:0]   i_type_imme;
reg  	[ 1:0] 	 inst_type;		//0 is r; 1 is i; 2 is i that may change pc; 3 is others

//===== state =====
//wire 	overflow;
//wire 	eof;
reg		first;
reg [2:0] C_State;
reg [2:0] N_State;

localparam  State_Idle = 3'd0, State_Fetch = 3'd1, State_Decode = 3'd2, State_ALU = 3'd3,
State_Load = 3'd4, State_Write = 3'd5, State_End = 3'd6, State_Extra = 3'd7;

//=====debug=====
reg up;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

assign o_status 	  = o_status_r;
assign o_status_valid = ~first && (N_State == State_Idle || C_State == State_End); 

assign o_i_addr   	  = o_i_addr_r;

assign o_d_we 		  = o_d_we_r;
assign o_d_addr 	  = o_d_addr_r;
assign o_d_wdata 	  = o_d_wdata_r;


assign opcode = i_i_inst[31:26];
assign both_type_addr_2 = i_i_inst[25:21];
assign r_type_addr_3 = i_i_inst[20:16];			//R read I write
assign r_type_addr_1 = i_i_inst[15:11];			//R write

assign i_type_addr_1 = i_i_inst[20:16];
assign i_type_imme = i_i_inst[15:0];

assign tmp1 = my_reg[both_type_addr_2];
assign tmp2 = (inst_type == 0) ? my_reg[r_type_addr_3] : (i_type_imme[15]) ? {16'hffff, i_type_imme} : i_type_imme;

assign u_tmp1 = my_reg[both_type_addr_2];
assign u_tmp2 = (inst_type == 0) ? my_reg[r_type_addr_3] : i_type_imme;

assign tmp1_2 = tmp1 + tmp2;
assign u_tmp1_2 = u_tmp1 + u_tmp2;
// ---------------------------------------------------------------------------
// Finite State machine start

always @(C_State) begin :COMB
	//N_State = C_State;
	case(C_State)
		State_Idle:begin
			if(~first && inst_type == 2'd2) begin
				N_State = (o_i_addr_w > 32'd1023)? State_End : State_Extra;
			end else begin
				N_State = State_Fetch;
			end
		end
		State_Extra:begin
			N_State = State_Fetch;
		end
		State_Fetch:begin	//opcode change here
			// if()
			// 	N_State = State_End;
			// else
			N_State = State_Decode;
		end
		State_Decode:begin
			case (opcode)
				`OP_ADD  : begin	// signed overflow check
					if( (~tmp1[31] & ~tmp2[31] & compute_temp[31]) || ( tmp1[31] & tmp2[31] & ~compute_temp[31] )) 
						N_State = State_End;
					else 
						N_State = State_ALU;
				end
				`OP_SUB  : begin	// signed overflow check
					up = 1;
					if( (tmp1[31] & ~tmp2[31] & ~compute_temp[31]) || ( ~tmp1[31] & ~tmp2[31] & compute_temp[31] )) 
						N_State = State_End;
					else 
						N_State = State_ALU;
				end
				`OP_ADDU : N_State = (unsigned_overflow)? State_End : State_ALU;
				`OP_SUBU : N_State = (u_tmp1 < u_tmp2)? State_End : State_ALU;
				`OP_ADDI : begin	// signed overflow check
					if( (~tmp1[31] & ~tmp2[31] & compute_temp[31]) || ( tmp1[31] & tmp2[31] & ~compute_temp[31] )) 
						N_State = State_End;
					else 
						N_State = State_ALU;
				end
				`OP_LW   : begin
					N_State = ((tmp1 + tmp2) > 32'd255)? State_End : State_Load;
					
				end
				`OP_SW   : N_State = ((tmp1 + tmp2) > 32'd255)? State_End : State_Load;
				// `OP_AND  : 
				// `OP_OR   : 
				// `OP_XOR  : 
				`OP_BEQ  : N_State = State_Idle;
				`OP_BNE  : N_State = State_Idle;
				// `OP_SLT  : 
				// `OP_SLL  : 
				// `OP_SRL  : 
				`OP_BLT  : N_State = State_Idle;
				`OP_BGE  : N_State = State_Idle;
				`OP_BLTU : N_State = State_Idle;
				`OP_BGEU : N_State = State_Idle;
				`OP_EOF  : N_State = State_End;
				default  : N_State = State_ALU;
			endcase
		end
		State_ALU:begin
			// if(overflow)
			// 	N_State = State_End;
			// else
			N_State = State_Idle;
		end
		State_Load:begin
			// if(overflow)
			// 	N_State = State_End;
			// else
			N_State = State_Write;
		end
		State_Write:begin
			// if(overflow)
			// 	N_State = State_End;
			// else
			N_State = State_Idle;
		end
		State_End:begin
			N_State = State_End;   
		end
	endcase
end

always @(posedge i_clk or negedge i_rst_n) begin :SEQ
	if(!i_rst_n) begin
		first <= 1;
		C_State <= State_Idle;
	end
	else begin
		if(first && C_State == State_Idle) first <= 0;
		C_State <= N_State;
	end
end
// Finite State machine end
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

//
always @(*) begin
	case(opcode)
		`OP_ADD  : inst_type = 2'd0	;//0
		`OP_SUB  : inst_type = 2'd0	;//1
		`OP_ADDU : inst_type = 2'd0	;//2
		`OP_SUBU : inst_type = 2'd0	;//3
		`OP_ADDI : inst_type = 2'd1	;//4
		`OP_LW   : inst_type = 2'd1	;//5
		`OP_SW   : inst_type = 2'd1	;//6
		`OP_AND  : inst_type = 2'd0	;//7
		`OP_OR   : inst_type = 2'd0	;//8
		`OP_XOR  : inst_type = 2'd0	;//9
		`OP_BEQ  : inst_type = 2'd2	;//10
		`OP_BNE  : inst_type = 2'd2	;//11
		`OP_SLT  : inst_type = 2'd0	;//12
		`OP_SLL  : inst_type = 2'd0	;//13
		`OP_SRL  : inst_type = 2'd0	;//14
		`OP_BLT  : inst_type = 2'd2	;//15
		`OP_BGE  : inst_type = 2'd2	;//16
		`OP_BLTU : inst_type = 2'd2	;//17
		`OP_BGEU : inst_type = 2'd2	;//18
		`OP_EOF  : inst_type = 2'd3	;//19
		default  : inst_type = 2'd3 ;
	endcase
end

// branch I type
always @(*) begin
	case(opcode)
		`OP_BEQ : o_i_addr_w = (my_reg[i_type_addr_1] == my_reg[both_type_addr_2])? o_i_addr + i_type_imme : o_i_addr + 4;
		`OP_BNE : o_i_addr_w = (my_reg[i_type_addr_1] != my_reg[both_type_addr_2])? o_i_addr + i_type_imme : o_i_addr + 4;
		`OP_BLT : o_i_addr_w = ($signed(my_reg[i_type_addr_1]) <  $signed(my_reg[both_type_addr_2]))? o_i_addr + i_type_imme : o_i_addr + 4;
		`OP_BGE : o_i_addr_w = ($signed(my_reg[i_type_addr_1]) >= $signed(my_reg[both_type_addr_2]))? o_i_addr + i_type_imme : o_i_addr + 4;
		`OP_BLTU: o_i_addr_w = (my_reg[i_type_addr_1] <  my_reg[both_type_addr_2])? o_i_addr + i_type_imme : o_i_addr + 4;
		`OP_BGEU: o_i_addr_w = (my_reg[i_type_addr_1] >= my_reg[both_type_addr_2])? o_i_addr + i_type_imme : o_i_addr + 4;
		default : o_i_addr_w = o_i_addr + 4;
	endcase
end

always @(*) begin
	if(opcode == `OP_EOF) o_status_w = `MIPS_END;
	else if(N_State == State_End) begin
		o_status_w = `MIPS_OVERFLOW;
	end else if(inst_type == 0) o_status_w = `R_TYPE_SUCCESS;
	else  o_status_w = `I_TYPE_SUCCESS;

end

always @(*) begin
	if(opcode == `OP_SW || opcode == `OP_LW) begin
		o_d_addr_w = tmp1+tmp2;
	end
	else o_d_addr_w = 0;
end

//reg
always @(*) begin
	case (opcode)
		`OP_ADD  : compute_temp = tmp1 + tmp2;
		`OP_SUB  : compute_temp = tmp1 - tmp2;
		`OP_ADDU : {unsigned_overflow, compute_temp} = u_tmp1 + u_tmp2;
		`OP_SUBU : compute_temp = u_tmp1 - u_tmp2;
		`OP_ADDI : compute_temp = tmp1 + tmp2;
		`OP_LW   : compute_temp = i_d_rdata;
		// `OP_SW   : compute_temp = 
		`OP_AND  : compute_temp = tmp1 & tmp2;
		`OP_OR   : compute_temp = tmp1 | tmp2;
		`OP_XOR  : compute_temp = tmp1 ^ tmp2;
		// `OP_BEQ  : compute_temp = 
		// `OP_BNE  : compute_temp = 
		`OP_SLT  : compute_temp = ($signed(tmp1) < $signed(tmp2))? 1 : 0;
		// >>  logical
		// >>> arithmetic
		`OP_SLL  : compute_temp = u_tmp1 << u_tmp2;
		`OP_SRL  : compute_temp = u_tmp1 >> u_tmp2;
		// `OP_BLT  : compute_temp = 
		// `OP_BGE  : compute_temp = 
		// `OP_BLTU : compute_temp = 
		// `OP_BGEU : compute_temp = 
		// `OP_EOF  : compute_temp = 
		default: compute_temp = 0;
	endcase
end

// ---------------------------------------------------------------------------
// Sequentialo_d_wdata_r Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

// status output
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
		o_status_r <= 0;
        //o_status_valid_r <= 0;
    end else begin
        o_status_r <= o_status_w;
        //o_status_valid_r <= o_status_valid_w;
    end
end

//instruction fetch
always@(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        o_i_addr_r <= 0;
    end else begin
        if(N_State == State_Idle && ~first) begin
			o_i_addr_r <= o_i_addr_w;
		end
    end
end

//reg
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for(i = 0; i < 32; i = i + 1) begin
			my_reg[i] <= 0;
		end
    end else if(C_State == State_ALU) begin
			if(inst_type == 0  && opcode != `OP_LW && opcode != `OP_SW) my_reg[r_type_addr_1] <= compute_temp;
			// else if(inst_type == 1) my_reg[i_type_addr_1] <= compute_temp;
			else if(inst_type == 1 && opcode != `OP_SW) my_reg[i_type_addr_1] <= compute_temp;
	end else if(C_State == State_Load && opcode == `OP_LW) my_reg[i_type_addr_1] <= compute_temp;
end

//memory
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) o_d_addr_r <= 0;
	else if( N_State == State_Decode) o_d_addr_r <= o_d_addr_w[7:0];
end

always @( posedge i_clk or negedge i_rst_n ) begin
	if( !i_rst_n ) begin
		o_d_wdata_r <= 0;
		o_d_we_r <= 0;
	end
	else if( N_State == State_Decode && opcode == `OP_SW )begin
		o_d_wdata_r <= my_reg[i_type_addr_1];
		o_d_we_r <= 1;
	end
	else begin
		o_d_wdata_r <= 0;
		o_d_we_r <= 0;
	end
end

endmodule