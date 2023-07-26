module mimi(
    input   i_clk,
    input   i_reset,
    input   en,
    input   [10*8-1:0]  data_in_flatten,
    output  [9:0]  min_v,
    output  [2:0]  min_idx
);
wire [9:0] data_in [0:7];
wire [9:0] s1[0:3];
wire [9:0] s2[0:1];
wire [2:0] s1_m_i[0:3];
wire [2:0] s2_m_i[0:1];
generate
    genvar i;
    for(i = 0 ; i < 8 ; i = i + 1)begin:loop_unflatten
        assign data_in[i] = data_in_flatten[10*i + 9 : 10*i];
    end
endgenerate
// stage 1,
merge u_merge_s1_0(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(data_in[0]),
    .s_v2(data_in[1]),
    .i_1(3'd0),
    .i_2(3'd1),
    .m_i(s1_m_i[0]),
    .min(s1[0])
);
merge u_merge_s1_1(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(data_in[2]),
    .s_v2(data_in[3]),
    .i_1(3'd2),
    .i_2(3'd3),
    .m_i (s1_m_i[1]),
    .min(s1[1])
);
merge u_merge_s1_2(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(data_in[4]),
    .s_v2(data_in[5]),
    .i_1(3'd4),
    .i_2(3'd5),
    .m_i (s1_m_i[2]),
    .min(s1[2])
);
merge u_merge_s1_3(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(data_in[6]),
    .s_v2(data_in[7]),
    .i_1(3'd6),
    .i_2(3'd7),
    .m_i (s1_m_i[3]),
    .min(s1[3])
);
// stage 2 
merge u_merge_s2_0(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(s1[0]),
    .s_v2(s1[1]),
    .i_1(s1_m_i[0]),
    .i_2(s1_m_i[1]),
    .m_i (s2_m_i[0]),
    .min(s2[0])
);
merge u_merge_s2_1(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(s1[2]),
    .s_v2(s1[3]),
    .i_1(s1_m_i[2]),
    .i_2(s1_m_i[3]),
    .m_i (s2_m_i[1]),
    .min(s2[1])
);
// stage 3
merge u_merge_s3_0(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .en(en),
    .s_v1(s2[0]),
    .s_v2(s2[1]),
    .i_1(s2_m_i[0]),
    .i_2(s2_m_i[1]),
    .m_i (min_idx),
    .min(min_v)
);


endmodule
module merge(
input i_clk,
input i_reset,
input en,
input [9:0] s_v1,
input [9:0] s_v2,
input [2:0] i_1,
input [2:0] i_2,
output reg [2:0] m_i,
output reg [9:0] min
);
always@(posedge i_clk or posedge i_reset)
begin
    if(i_reset)begin
        m_i <= 0;
        min <= 0;
    end
    else if(en) begin
        if(s_v1 < s_v2) begin
            m_i <= i_1;
            min <= s_v1;
        end
        else begin
            m_i <= i_2;
            min <= s_v2;
        end
    end
end
endmodule