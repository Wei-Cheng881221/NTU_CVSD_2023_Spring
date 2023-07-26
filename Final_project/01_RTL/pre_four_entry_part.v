module pre_four_entry_part(
    input i_clk,
    input i_reset,
    input [19:0] e_4,
    input [19:0] e_3,
    input [19:0] e_2,
    input [19:0] e_1,
    input en,
    output [9:0]out
);
// reg signed [39:0] e_im[3:0];
// reg signed [39:0] e_re[3:0];
reg  [9:0] e_im[3:0];
reg  [9:0] e_re[3:0];
reg [12:0] out_r;
assign out = out_r[11:2];
// reg [19:0] s0[0:3];
integer i;
// always @(posedge i_clk or posedge i_reset)begin
//     if(i_reset)begin
//         for (i = 0 ; i < 4 ; i = i + 1)begin
//             s0[i] <= 0;
//         end
//     end
//     else if(en)begin
//         s0[3] <= e_4;
//         s0[2] <= e_3;
//         s0[1] <= e_2;
//         s0[0] <= e_1;
//     end
// end




always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        for (i = 0 ; i < 4 ; i = i + 1)begin
            e_im[i] <= 0;
            e_re[i] <= 0;
        end
    end
    else if (en) begin
        // for (i = 0 ; i < 4 ; i = i + 1)begin
        //     e_im[i] <= (s0[i][19])?~s0[i][19:10]+1:s0[i][19:10];
        //     e_re[i] <= (s0[i][9])?~s0[i][9:0]+1:s0[i][9:0];
        // end
        e_im[0] <= (e_1[19])?~e_1[19:10]+1:e_1[19:10];
        e_re[0] <= (e_1[9] )?~e_1[9:0]+1:  e_1[9:0];
        e_im[1] <= (e_2[19])?~e_2[19:10]+1:e_2[19:10];
        e_re[1] <= (e_2[9] )?~e_2[9:0]+1:  e_2[9:0];
        e_im[2] <= (e_3[19])?~e_3[19:10]+1:e_3[19:10];
        e_re[2] <= (e_3[9] )?~e_3[9:0]+1:  e_3[9:0];
        e_im[3] <= (e_4[19])?~e_4[19:10]+1:e_4[19:10];
        e_re[3] <= (e_4[9] )?~e_4[9:0]+1:  e_4[9:0];

    end
end
always @(posedge i_clk or posedge i_reset)begin
    if(i_reset)begin
        out_r <= 0;
    end
    else if (en) begin
        // out_r <= (((e_im[3][35:16] + e_re[3][35:16]) + (e_im[2][35:16] + e_re[2][35:16]))
        //          +((e_im[1][35:16] + e_re[1][35:16]) + (e_im[0][35:16] + e_re[0][35:16])));
        out_r <= (((e_im[3] + e_re[3]) + (e_im[2] + e_re[2]))
                 +((e_im[1] + e_re[1]) + (e_im[0] + e_re[0])));
    end
end
endmodule