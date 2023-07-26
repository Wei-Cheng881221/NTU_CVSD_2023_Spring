module ml_demodulator(
    input i_clk,
    input i_reset,
    input i_trig,
    input [159:0] i_y_hat,
    input [319:0] i_r,
    input i_rd_rdy,
    output o_rd_vld,
    output [7:0] o_llr,
    output o_hard_bit
);
parameter IDLE      = 1'd0;
parameter EX        = 1'd1;
parameter LOG2      = 10'b0000101101;
parameter N_LOG2    = 10'b1111010010;
integer i,k;
reg         cur_state,nx_state;
reg [5:0]   counter_64;


//output
reg     [7:0]   output_buffer_array[0:255];
reg     [7:0]   output_buffer_addr_read;
reg     [7:0]   output_buffer_addr_write;
wire [2:0] min_idx;
wire [9:0] cur_ans;
reg [7:0] min_idx_r;
reg [9:0] best_ans;
// sram
reg     [7:0]   output_buffer;
wire            write_en;
//  demodulate
wire [19:0]  s[0:3];
wire [9:0]  y_im[0:3],y_re[0:3];
wire [9:0]  r44_re,r34_im,r34_re,r24_im,r24_re,r14_im,r14_re,r33_re,r23_im,r23_re,r13_im,r13_re,r22_re,r12_im,r12_re,r11_re;
//  calculate all possible
wire [9:0]  tmp8_possible[0:7];
reg [7:0]  counter_index[0:7];
// y and r
assign y_im[3] = i_y_hat[159:150];
assign y_re[3] = i_y_hat[139:130];
assign y_im[2] = i_y_hat[119:110];
assign y_re[2] = i_y_hat[99:90];
assign y_im[1] = i_y_hat[79:70];
assign y_re[1] = i_y_hat[59:50];
assign y_im[0] = i_y_hat[39:30];
assign y_re[0] = i_y_hat[19:10];
assign r44_re = i_r[319:310];
assign r34_im = i_r[299:290];
assign r34_re = i_r[279:270];
assign r24_im = i_r[259:250];
assign r24_re = i_r[239:230];
assign r14_im = i_r[219:210];
assign r14_re = i_r[199:190];
assign r33_re = i_r[179:170];
assign r23_im = i_r[159:150];
assign r23_re = i_r[139:130];
assign r13_im = i_r[119:110];
assign r13_re = i_r[99:90];
assign r22_re = i_r[79:70];
assign r12_im = i_r[59:50];
assign r12_re = i_r[39:30];
assign r11_re = i_r[19:10];
//  sram output
assign  write_en        = (cur_state == EX && counter_64 == 41);
assign  o_hard_bit      = output_buffer_array[output_buffer_addr_read][7];
assign  o_llr           = output_buffer_array[output_buffer_addr_read];
assign  o_rd_vld          = (output_buffer > 0);
//output
reg [19:0] r11s [3:0];
reg [19:0] r12s [3:0];
reg [19:0] r22s [3:0];
reg [19:0] r13s [3:0];
reg [19:0] r23s [3:0];
reg [19:0] r33s [3:0];
reg [19:0] r14s [3:0];
reg [19:0] r24s [3:0];
reg [19:0] r34s [3:0];
reg [19:0] r44s [3:0];
genvar j;
// parameter s
assign  s[0] = {LOG2,LOG2};     // (0,0)
assign  s[1] = {N_LOG2,LOG2};   // (0,1)
assign  s[2] = {LOG2,N_LOG2};   // (1,0)
assign  s[3] = {N_LOG2,N_LOG2}; // (1,1)
//  calculate all possible
// assign counter_index[0] = {counter_64-1,3'b000} ;
// assign counter_index[1] = {counter_64-1,3'b000} + 1;
// assign counter_index[2] = {counter_64-1,3'b000} + 2;
// assign counter_index[3] = {counter_64-1,3'b000} + 3;
// assign counter_index[4] = {counter_64-1,3'b000} + 4;
// assign counter_index[5] = {counter_64-1,3'b000} + 5;
// assign counter_index[6] = {counter_64-1,3'b000} + 6;
// assign counter_index[7] = {counter_64-1,3'b000} + 7;


always @(*)begin
    case(cur_state)
        IDLE : begin
            nx_state = (i_reset)?IDLE:
                        (i_trig)?EX:IDLE;
        end
        EX : begin
            nx_state = (i_reset||counter_64 == 62)?IDLE:EX;
        end
    endcase
end

wire en = (counter_64 > 0 && counter_64 < 34 && cur_state == EX);

generate
//  calculate all possible
    for(j = 0 ; j < 8 ; j = j + 1)begin :four_entry_part_block_ddd
        pre_four_entry_part u_pre_four_entry_part (
            i_clk,
            i_reset,
            {y_im[0] - r11s[counter_index[j][7:6]][19:10] - r12s[counter_index[j][5:4]][19:10] - r13s[counter_index[j][3:2]][19:10] - r14s[counter_index[j][1:0]][19:10],y_re[0] - r11s[counter_index[j][7:6]][9:0] - r12s[counter_index[j][5:4]][9:0] - r13s[counter_index[j][3:2]][9:0] - r14s[counter_index[j][1:0]][9:0]},
            {y_im[1] - r22s[counter_index[j][5:4]][19:10] - r23s[counter_index[j][3:2]][19:10] - r24s[counter_index[j][1:0]][19:10],y_re[1] - r22s[counter_index[j][5:4]][9:0] - r23s[counter_index[j][3:2]][9:0] - r24s[counter_index[j][1:0]][9:0]},
            {y_im[2] - r33s[counter_index[j][3:2]][19:10] - r34s[counter_index[j][1:0]][19:10],y_re[2] - r33s[counter_index[j][3:2]][9:0] - r34s[counter_index[j][1:0]][9:0]},
            {y_im[3] - r44s[counter_index[j][1:0]][19:10],y_re[3] - r44s[counter_index[j][1:0]][9:0]},
            en,
            tmp8_possible[j]
    );
    end
endgenerate

mimi u_mimi(
    i_clk,
    i_reset,
    (counter_64 > 2  && counter_64 < 37 && cur_state == EX),
    {tmp8_possible[7],tmp8_possible[6],tmp8_possible[5],tmp8_possible[4],tmp8_possible[3],tmp8_possible[2],tmp8_possible[1],tmp8_possible[0]},
    cur_ans,
    min_idx
);
always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        best_ans <= 8'HFF;
        min_idx_r  <= 0;
    end
    else if(i_trig)begin
        best_ans   <= 8'HFF;
        min_idx_r  <= 0;
    end
    else if( counter_64 > 5 && counter_64 < 40 && cur_state == EX ) begin
        if(cur_ans < best_ans)begin
            best_ans <= cur_ans;
            min_idx_r  <= min_idx + {counter_64-6,3'b000};
        end
    end
end

always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        for (i = 0 ; i < 4 ; i = i + 1)begin
            r11s[i] <= 0;
            r12s[i] <= 0;
            r22s[i] <= 0;
            r13s[i] <= 0;
            r23s[i] <= 0;
            r33s[i] <= 0;
            r14s[i] <= 0;
            r24s[i] <= 0;
            r34s[i] <= 0;
            r44s[i] <= 0;
        end
    end
    else if (counter_64 == 0 && cur_state == EX) begin
        for (i = 0 ; i < 4 ; i = i + 1)begin
            r11s[i] <= complex_mul({10'b0   ,r11_re},s[i]);
            r12s[i] <= complex_mul({r12_im     ,r12_re},s[i]);
            r22s[i] <= complex_mul({10'b0   ,r22_re},s[i]);
            r13s[i] <= complex_mul({r13_im     ,r13_re},s[i]);
            r23s[i] <= complex_mul({r23_im     ,r23_re},s[i]);
            r33s[i] <= complex_mul({10'b0   ,r33_re},s[i]);
            r14s[i] <= complex_mul({r14_im     ,r14_re},s[i]);
            r24s[i] <= complex_mul({r24_im     ,r24_re},s[i]);
            r34s[i] <= complex_mul({r34_im     ,r34_re},s[i]);
            r44s[i] <= complex_mul({10'b0   ,r44_re},s[i]);
        end
    end
end
always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        counter_index[0] <= 0;
        counter_index[1] <= 0;
        counter_index[2] <= 0;
        counter_index[3] <= 0;
        counter_index[4] <= 0;
        counter_index[5] <= 0;
        counter_index[6] <= 0;
        counter_index[7] <= 0;
    end
    else if (counter_64 >= 0 && counter_64 <= 31 && cur_state == EX) begin
        counter_index[0] <= {counter_64,3'b000} ;
        counter_index[1] <= {counter_64,3'b000} + 1;
        counter_index[2] <= {counter_64,3'b000} + 2;
        counter_index[3] <= {counter_64,3'b000} + 3;
        counter_index[4] <= {counter_64,3'b000} + 4;
        counter_index[5] <= {counter_64,3'b000} + 5;
        counter_index[6] <= {counter_64,3'b000} + 6;
        counter_index[7] <= {counter_64,3'b000} + 7;
    end
end


always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        output_buffer   <= 0;
        output_buffer_addr_read <= 0;
        output_buffer_addr_write<= 0;
    end
    else if (write_en && o_rd_vld && i_rd_rdy )begin
        output_buffer_array[output_buffer_addr_write] <= (min_idx_r[7])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 1] <= (min_idx_r[6])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 2] <= (min_idx_r[5])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 3] <= (min_idx_r[4])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 4] <= (min_idx_r[3])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 5] <= (min_idx_r[2])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 6] <= (min_idx_r[1])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 7] <= (min_idx_r[0])?8'H80:8'H01;
        output_buffer_addr_write <= output_buffer_addr_write + 8;
        output_buffer_addr_read <= output_buffer_addr_read + 1;
        output_buffer   <= output_buffer + 7;
    end
    else if (write_en) begin
        output_buffer_array[output_buffer_addr_write] <= (min_idx_r[7])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 1] <= (min_idx_r[6])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 2] <= (min_idx_r[5])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 3] <= (min_idx_r[4])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 4] <= (min_idx_r[3])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 5] <= (min_idx_r[2])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 6] <= (min_idx_r[1])?8'H80:8'H01;
        output_buffer_array[output_buffer_addr_write + 7] <= (min_idx_r[0])?8'H80:8'H01;
        output_buffer_addr_write <= output_buffer_addr_write + 8;
        output_buffer   <= output_buffer + 8;
    end
    else if ( o_rd_vld && i_rd_rdy) begin
        output_buffer_addr_read <= output_buffer_addr_read + 1;
        output_buffer   <= output_buffer - 1;
    end
end


always @(posedge i_clk or posedge i_reset )begin
    if(i_reset)begin
        counter_64 <= 0;
    end
    else if (cur_state == EX)begin
        if (counter_64 == 62)begin
            counter_64 <= 0;
        end 
        else begin
            counter_64 <= counter_64 + 1;
        end
    end
end


always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= nx_state;
    end
end

function [19:0]complex_mul;
	input [19:0] m1;
    input [19:0] m2;
    begin:complex_mul_block
        reg signed [19:0]tmp1;
        reg signed [19:0]tmp2;
        // (a+bj)(c+dj)
        // b = m1[39:20]
        // d = m2[39:20]
        // a = m1[19:0]
        // c = m2[19:0]
        // real    = (a*c - b*d)[35:16]
        // im      = (a*d + b*c)[35:16]
        
        tmp1 = $signed(m1[9:0])*$signed(m2[9:0]) - $signed(m1[19:10])*$signed(m2[19:10]);
        tmp2 = $signed(m1[9:0])*$signed(m2[19:10]) + $signed(m1[19:10])*$signed(m2[9:0]);
        complex_mul = {tmp2[15:6],tmp1[15:6]};
	end
endfunction

endmodule
