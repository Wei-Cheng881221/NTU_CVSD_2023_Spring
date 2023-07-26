module alu #(
    parameter INT_W  = 4,
    parameter FRAC_W = 6,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,  //active low
    input                     i_valid,  //high if signal is resdy
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,   
    output                    o_valid,  //high if ready to output
    output       [DATA_W-1:0] o_data
); // Do not modify
    
// ---------------------------------------------------------------------------

// Wires and Registers
// ---------------------------------------------------------------------------
reg [DATA_W-1:0] o_data_w, o_data_r;
reg              o_valid_w, o_valid_r;
// ---- Add your own wires and registers here if needed ---- //

reg [DATA_W-1:0] data_a_save, data_b_save;
reg [INST_W-1:0] i_inst_save;

reg add; //1 for add 0 for minus



wire [DATA_W-1:0] temp_result;
wire [DATA_W-1:0] temp_result_mul;
wire [DATA_W-1:0] temp_result_mac;
wire [DATA_W-1:0] temp_result_tanh;
wire [DATA_W-1:0] data_a_save_rev;
wire [3:0] cnt1_r;
wire [DATA_W-1:0] temp_result_rsl;
wire [9:0] zerocnt_head, zerocnt_trail;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------

assign o_valid = o_valid_r;
assign o_data = o_data_r;

// ---- Add your own wire data assignments here if needed ---- //

signed_addition_with_saturation add1(
                .result(temp_result),
                .add(add),
                .a(data_a_save),
                .b(data_b_save)
            );

signed_multiplication_with_saturation mul1(
                .result(temp_result_mul),
                .a(data_a_save),
                .b(data_b_save)
            );

MAC mac1(
                .result(temp_result_mac),
                .a(data_a_save),
                .b(data_b_save),
                .o_data(o_data_r)
            );

Tanh t1(
                .result(temp_result_tanh),
                .a(data_a_save)
            );

reverse_bits rev1(
                .output_bits(data_a_save_rev),
                .input_bits(data_a_save)
            );

count_ones cnt1(
                .ones_count(cnt1_r),
                .input_num(data_a_save)
            );

rotate_shift_left rsl(
                .data_a_save(data_a_save),
                .data_b_save(data_b_save),
                .result(temp_result_rsl)
            );

count_last_zero clz1(
                .data_a_save(data_a_save),
                .result(zerocnt_trail)
            );

count_last_zero clz2(
                .data_a_save(data_a_save_rev),
                .result(zerocnt_head)
            );

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

always@(*) begin
    case (i_inst_save)
        // 4 bits integer + 6 bits fraction
        4'b0000: begin  //signed add                    //pass
            o_data_w = temp_result;
        end
        4'b0001: begin  //signed sub                    //pass
            o_data_w = temp_result;
        end
        4'b0010: begin  //signed mul                    //pass
            o_data_w = temp_result_mul;
        end
        4'b0011: begin  //MAC                           //
            o_data_w = temp_result_mac;
        end
        4'b0100: begin  //Tanh                          //pass
            o_data_w = temp_result_tanh;
        end
        // 10 bit
        4'b0101: begin  //bitwise OR                    //pass
            o_data_w = data_a_save | ~data_b_save;
        end
        4'b0110: begin  //Count Leading Zero            //pass
            o_data_w = zerocnt_head;
        end
        4'b0111: begin  //Count Trailing Zero           //pass
            o_data_w = zerocnt_trail;
        end
        4'b1000: begin  //Count number of 1             //pass
            o_data_w = cnt1_r;
        end
        4'b1001: begin  //Rotation Left                 //pass
            o_data_w = temp_result_rsl;
        end
        default: begin  //do nothing
            o_data_w = o_data_w;
        end
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_data_r <= 0;
        o_valid_r <= 0;
    end else begin
        if(i_valid) begin
            o_data_r <= o_data_w;
        end
        if(i_valid) begin
            o_valid_r <= 1'b1;
        end else begin
            o_valid_r <= 1'b0;
        end
    end
end

always@(negedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        data_a_save <= 0;
        data_b_save <= 0;
        i_inst_save <= 0;
        add <= 0;
    end
    else if(i_valid) begin
        data_a_save <= i_data_a;
        data_b_save <= i_data_b;
        i_inst_save <= i_inst;
        add <= ~i_inst[0];
    end
end

endmodule

module signed_addition_with_saturation(
    input signed [9:0] a,
    input signed [9:0] b,
    input add,
    output reg signed [9:0] result
);

    reg signed [10:0] temp_result;

    always @(*) begin
        if(add) begin
            temp_result = a + b;
        end else begin
            temp_result = a - b;
        end
        if (temp_result > 511) begin
            result = 511;
        end else if (temp_result < -512) begin
            result = -512;
        end else begin
            result = $signed(temp_result[9:0]);
        end
    end

endmodule

module signed_multiplication_with_saturation(
    input signed [9:0] a,
    input signed [9:0] b,
    output reg signed [9:0] result
);

    reg signed [19:0] temp_result;
    reg signed [19:0] temp_result_add;
    
    always @(*) begin
        temp_result = $signed(a) * $signed(b);
        temp_result_add = $signed(temp_result) - $signed(6'b100000);
        if (temp_result_add > 32767) begin
            result = 511;
        end else if (temp_result_add <= -32768) begin
            result = -512;
        end else begin
            result = temp_result_add[15:6];
        end
    end

endmodule

module MAC(
    input signed [9:0] a,
    input signed [9:0] b,
    input signed [9:0] o_data,
    output reg signed [9:0] result
);
    reg signed [21:0] temp_mul;
    reg signed [21:0] temp_mul_add;
    always@(*) begin
        temp_mul = $signed(a) * $signed(b);
        temp_mul_add = temp_mul + $signed({o_data, 6'b100000});
        if (temp_mul_add > 32767) begin
            result = 511;
        end else if (temp_mul_add <= -32768) begin
            result = -512;
        end else begin
            result = temp_mul_add[15:6];
        end
    end
endmodule

module Tanh(
    input signed [9:0] a,
    output reg signed [9:0] result
);
    wire [10:0] slp2, slp4;
    
    assign slp2 = {a[9], a} - 32;
    assign slp4 = {a[9], a} + 32;
    
    always@(*) begin
        if(a <= -96) begin
            result = 10'b1111000000;
        end else if( a > -96 && a <= -32 ) begin
            result = $signed(slp2[10:1]) - $signed(slp2[0]);
        end else if ( a > -32 && a <= 32 ) begin
            result = a;
        end else if( a > 32 && a <= 96 ) begin
            result = $signed(slp4[10:1]) - $signed(slp4[0]);
        end else begin
            result = 10'b0001000000;
        end
    end
endmodule

module reverse_bits(
    input [9:0] input_bits,
    output [9:0] output_bits
);

    reg [9:0] reversed_bits;

    integer i;
    always @(*) begin
        for (i = 0; i < 10; i = i + 1) begin
            reversed_bits[i] = input_bits[9 - i];
        end
    end

    assign output_bits = reversed_bits;

endmodule

module count_ones (
  input [9:0] input_num,
  output reg [3:0] ones_count
);

  integer i;
  
  always @(*) begin
    ones_count = 0;
    for (i = 0; i < 10; i = i + 1) begin
      if (input_num[i] == 1) begin
        ones_count = ones_count + 1;    //OK?
      end
    end
  end

endmodule

module rotate_shift_left (
  input [9:0] data_a_save,
  input [9:0] data_b_save,
  output reg [9:0] result
);
    reg [19:0] double_a;
    reg [19:0] double_a_shift;
    always @(*) begin
        double_a = {data_a_save, data_a_save};
        double_a_shift = double_a << data_b_save;
        result = double_a_shift[19:10];
    end

endmodule

module count_last_zero (
  input [9:0] data_a_save,
  output reg [9:0] result
);
    
    always@(*) begin
        //$display("%b", data_a_save);
        casez(data_a_save)
            10'bzzzzzzzzz1: result = 0;
            10'bzzzzzzzz10: result = 1;
            10'bzzzzzzz100: result = 2;
            10'bzzzzzz1000: result = 3;
            10'bzzzzz10000: result = 4;
            10'bzzzz100000: result = 5;
            10'bzzz1000000: result = 6;
            10'bzz10000000: result = 7;
            10'bz100000000: result = 8;
            10'b1000000000: result = 9;
            10'b0000000000: result = 10;
            default : result = 11;
        endcase

    end
endmodule
