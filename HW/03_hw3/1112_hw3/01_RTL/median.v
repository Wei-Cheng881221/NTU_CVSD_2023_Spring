module median(
    input i_clk,
    input i_rst_n,
    input [7:0] data_in_1, input [7:0] data_in_2, input [7:0] data_in_3,
    input [7:0] data_in_4, input [7:0] data_in_5, input [7:0] data_in_6,
    input [7:0] data_in_7, input [7:0] data_in_8, input [7:0] data_in_9,
    output [7:0] med_med
);
reg [7:0] med_med_r;
wire [7:0] med_med_w;
wire [7:0] max_data1, mid_data1, min_data1, 
           max_data2, mid_data2, min_data2,
           max_data3, mid_data3, min_data3;

wire [7:0] max_min, mid_mid, min_max;

wire [7:0] no_use;

median_sort ms1(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(data_in_1), .data_2(data_in_2), .data_3(data_in_3), .data_max(max_data1), .data_mid(mid_data1), .data_min(min_data1));
median_sort ms2(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(data_in_4), .data_2(data_in_5), .data_3(data_in_6), .data_max(max_data2), .data_mid(mid_data2), .data_min(min_data2));
median_sort ms3(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(data_in_7), .data_2(data_in_8), .data_3(data_in_9), .data_max(max_data3), .data_mid(mid_data3), .data_min(min_data3));

median_sort ms4(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(max_data1), .data_2(max_data2), .data_3(max_data3), .data_max(), .data_mid(), .data_min(max_min));
median_sort ms5(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(mid_data1), .data_2(mid_data2), .data_3(mid_data3), .data_max(), .data_mid(mid_mid), .data_min());
median_sort ms6(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(min_data1), .data_2(min_data2), .data_3(min_data3), .data_max(min_max), .data_mid(), .data_min());

median_sort mm1(.i_clk(i_clk), .i_rst_n(i_rst_n), .data_1(max_min), .data_2(mid_mid), .data_3(min_max), .data_max(), .data_mid(med_med), .data_min());


endmodule


module median_sort(
    input i_clk,
    input i_rst_n,
    input [7:0] data_1, data_2, data_3,
    output [7:0] data_max, data_mid, data_min
);

reg  [7:0] data_max_r, data_mid_r, data_min_r;
reg  [7:0] data_max_w, data_mid_w, data_min_w;

always@(*)begin
    if(data_1 >= data_2 && data_1 >= data_3)
        data_max_w = data_1;
    else if(data_2 >= data_1 && data_2 >= data_3)
        data_max_w = data_2;
    else//(data_3 >= data_1 && data_3 >= data_2)
        data_max_w = data_3;
    //get the mid value
    if((data_1 >= data_2 && data_1 <= data_3) || (data_1 >= data_3 && data_1 <= data_2))
        data_mid_w = data_1;
    else if((data_2 >= data_1 && data_2 <= data_3) || (data_2 >= data_3 && data_2 <= data_1))
        data_mid_w = data_2;
    else//((data_3 >= data_1 && data_3 <= data_2) || (data_3 >= data_2 && data_3 <= data_1))
        data_mid_w = data_3;
    //get the min value
    if(data_1 <= data_2 && data_1 <= data_3)
        data_min_w = data_1;
    else if(data_2 <= data_1 && data_2 <= data_3)
        data_min_w = data_2;
    else//(data_3 <= data_1 && data_3 <= data_2)
        data_min_w = data_3;
end

// always @(posedge i_clk or negedge i_rst_n) begin
//     if(!i_rst_n) begin
//         data_max_w <= 0;
//         data_mid_w <= 0;
//         data_min_w <= 0;
//     end
//     else begin
//         // get max
//         if(data_1 >= data_2 && data_1 >= data_3)
//             data_max_w <= data_1;
//         else if(data_2 >= data_1 && data_2 >= data_3)
//             data_max_w <= data_2; 
//         else//(data_3 >= data_1 && data_3 >= data_2)
//             data_max_w <= data_3;

//         // get mid
//         if((data_1 >= data_2 && data_1 <= data_3) || (data_1 >= data_3 && data_1 <= data_2))
//             data_mid_w <= data_1;
//         else if((data_2 >= data_1 && data_2 <= data_3) || (data_2 >= data_3 && data_2 <= data_1))
//             data_mid_w <= data_2;
//         else//((data_3 >= data_1 && data_3 <= data_2) || (data_3 >= data_2 && data_3 <= data_1))
//             data_mid_w <= data_3;

//         // get min
//         if(data_1 <= data_2 && data_1 <= data_3)
//             data_min_w <= data_1;
//         else if(data_2 <= data_1 && data_2 <= data_3)
//             data_min_w <= data_2;
//         else//(data_3 <= data_1 && data_3 <= data_2)
//             data_min_w <= data_3;
//     end
// end

assign data_max = data_max_r;
assign data_mid = data_mid_r;
assign data_min = data_min_r;

always@(posedge i_clk)begin
    data_max_r <= data_max_w;
    data_mid_r <= data_mid_w;
    data_min_r <= data_min_w;
end

endmodule