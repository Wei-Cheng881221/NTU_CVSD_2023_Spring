`include "define.v"
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [3:0]   fn_sel;
output reg         busy;
output reg         valid;
output reg [127:0] iot_out;

//////////////////////
// declare parameters
reg [1:0] State_C, State_N;
// reg [7:0] iot_in_stable;

reg [3:0] iot_in_cycle;
reg [2:0] data_round;

reg [7:0] iot_in_save [15:0];     // for read in
reg [7:0] iot_out_pre [15:0];     // for output

reg [7:0] T2_L2 [15:0];           // for T2 & L2

wire [2:0] extra_w;               // for AVG
reg  [2:0] extra_r;
// reg [130:0] iot_out_big;          

reg success;                      // for Extract Exclude

reg first;                        // for PMax PMin

wire [127:0] iot_in_save_all = {iot_in_save[15], iot_in_save[14], iot_in_save[13], iot_in_save[12],
                        iot_in_save[11], iot_in_save[10], iot_in_save[ 9], iot_in_save[ 8],
                        iot_in_save[ 7], iot_in_save[ 6], iot_in_save[ 5], iot_in_save[ 4],
                        iot_in_save[ 3], iot_in_save[ 2], iot_in_save[ 1], iot_in_save[ 0]};

wire [127:0] iot_out_pre_all = {iot_out_pre[15], iot_out_pre[14], iot_out_pre[13], iot_out_pre[12],
                        iot_out_pre[11], iot_out_pre[10], iot_out_pre[ 9], iot_out_pre[ 8],
                        iot_out_pre[ 7], iot_out_pre[ 6], iot_out_pre[ 5], iot_out_pre[ 4],
                        iot_out_pre[ 3], iot_out_pre[ 2], iot_out_pre[ 1], iot_out_pre[ 0]};

wire [127:0] iot_out_pre_al2 = {T2_L2[15], T2_L2[14], T2_L2[13], T2_L2[12],
                                T2_L2[11], T2_L2[10], T2_L2[ 9], T2_L2[ 8],
                                T2_L2[ 7], T2_L2[ 6], T2_L2[ 5], T2_L2[ 4],
                                T2_L2[ 3], T2_L2[ 2], T2_L2[ 1], T2_L2[ 0]};

integer i; // for initialize iot_in_save

assign extra_w = extra_r;
// End of parameters
//////////////////////

//////////////////////
// Read Inputs
//total 96 data, 1 data 128 bits, need 16 cycle to input
always@(posedge clk or posedge rst) begin   //count the 16 round of input for 1 data
    if(rst) begin
        iot_in_cycle <= 0;
    end
    else begin
        if(State_C == `State_PROC) iot_in_cycle <= 0;
        else if(in_en == 1'd1 && iot_in_cycle < 15) iot_in_cycle <= iot_in_cycle + 1;
        else iot_in_cycle <= 0;
    end
end

always@(posedge clk or posedge rst) begin   //count the data amount
    if(rst) begin
        data_round <= 0;
    end
    else begin
        if(data_round == 7 && iot_in_cycle == 15) data_round <= 0;
        else if(iot_in_cycle == 15) data_round <= data_round + 1;
    end
end

// End of Inputs
//////////////////////

//////////////////////
// Set Outputs

reg out_2;  //for T2MAX & L2MIN
always @(*) begin
    if(fn_sel == `OP_T2MAX || fn_sel == `OP_L2MIN) begin
        iot_out = (out_2)? iot_out_pre_all:iot_out_pre_al2;
    end
    // else if(fn_sel == `OP_AVG) iot_out = (iot_out_big >> 3);
    else if(fn_sel == `OP_AVG) iot_out = ({extra_w, iot_out_pre_all} >> 3);
    else iot_out = iot_out_pre_all;
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        valid <= 0;
        busy  <= 0;
        out_2 <= 0;
    end
    else begin
        if(iot_in_cycle == 14) busy <= 1;
        else busy <= 0;
        case(fn_sel)
        `OP_MAX, `OP_MIN, `OP_AVG: begin
            if(State_C == `State_PROC && data_round == 0) valid <=1;
            else valid <= 0;
        end
        `OP_T2MAX, `OP_L2MIN: begin
            if(State_C == `State_PROC && data_round == 0) begin 
                valid <= 1;
                out_2 <= 1;
            end
            else if(out_2) begin 
                out_2 <= 0;
                valid <= 1;
            end
            else valid <= 0;
        end
        `OP_EXTRACT, `OP_EXCLUDE: begin
            if(success) valid <= 1;
            else valid <= 0;
        end
        `OP_PMAX, `OP_PMIN: begin
            if(data_round == 0 && first && State_C == `State_PROC) valid <= 1;
            else if(success && !first) valid <= 1;
            else valid <= 0;
        end
        default: begin
            valid <= 0;
        end 
        endcase
    end
end

// End of Outputs
//////////////////////

//////////////////////
// FSM Start
always@(posedge clk or posedge rst) begin
    if(rst) State_C <= `State_IDLE;
    else State_C <= State_N;
end

always@(*) begin
    State_N = State_C;
    case(State_C)
    `State_IDLE: begin
        if(in_en == 1'd1) State_N = `State_LOAD;
    end
    `State_LOAD: begin
        if(iot_in_cycle == 15) State_N = `State_PROC;
    end
    `State_PROC: begin
        State_N = `State_LOAD;
    end
    endcase
end

// FSM End
//////////////////////

//////////////////////
// Logic Start

always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i = 0; i < 16; i=i+1) begin
            iot_in_save[i] <= 0;
            iot_out_pre[i] <= 0;
        end
        // iot_out_big <= 0;
        extra_r <= 0;
        success <= 0;
        first <= 1;
    end
    else begin
        case (fn_sel)
        `OP_MAX : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                if(data_round == 0) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 0;
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(iot_in_save_all > iot_out_pre_all) begin
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_MIN : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                if(data_round == 0) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 8'b11111111;
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(iot_in_save_all < iot_out_pre_all) begin
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_T2MAX : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                if(data_round == 0) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 0;
                    if(iot_in_cycle == 1) begin
                        for (i=0;i<16;i=i+1) begin
                            T2_L2[i] <= 0;
                        end
                    end
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(iot_in_save_all > iot_out_pre_all) begin
                    for (i=0;i<16;i=i+1) begin
                        T2_L2[i] <= iot_out_pre[i];
                    end
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
                else if(iot_in_save_all > iot_out_pre_al2) begin
                    for (i=0;i<16;i=i+1) begin
                        T2_L2[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_L2MIN : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                if(data_round == 0) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 8'b11111111;
                    if(iot_in_cycle == 1) begin
                        for (i=0;i<16;i=i+1) begin
                            T2_L2[i] <= 8'b11111111;
                        end
                    end
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(iot_in_save_all < iot_out_pre_all) begin
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                    for (i=0;i<16;i=i+1) begin
                        T2_L2[i] <= iot_out_pre[i];
                    end
                end
                else if(iot_in_save_all < iot_out_pre_al2) begin
                    for (i=0;i<16;i=i+1) begin
                        T2_L2[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_AVG : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                // if(data_round == 0) iot_out_big <= 0;
                if(data_round == 0) begin
                    extra_r <= 0;
                    for(i = 0; i < 16; i=i+1) begin
                        iot_out_pre[i] <= 0;
                    end
                end
                iot_in_save[iot_in_cycle] <= iot_in;
            end
            else if(State_C == `State_PROC) begin
                {extra_r, iot_out_pre[15], iot_out_pre[14], iot_out_pre[13], iot_out_pre[12],
                          iot_out_pre[11], iot_out_pre[10], iot_out_pre[ 9], iot_out_pre[ 8],
                          iot_out_pre[ 7], iot_out_pre[ 6], iot_out_pre[ 5], iot_out_pre[ 4],
                          iot_out_pre[ 3], iot_out_pre[ 2], iot_out_pre[ 1], iot_out_pre[ 0]} <= {extra_r, iot_out_pre_all} + {3'b000, iot_in_save_all};
            end
        end
        `OP_EXTRACT : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                iot_in_save[iot_in_cycle] <= iot_in;
                success <= 0;
            end
            else if(State_C == `State_PROC) begin
                if((iot_in_save_all < `EXTRACT_HIGH) && (iot_in_save_all > `EXTRACT_LOW)) begin
                    success <= 1; 
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_EXCLUDE : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                iot_in_save[iot_in_cycle] <= iot_in;
                success <= 0;
            end
            else if(State_C == `State_PROC) begin
                if((iot_in_save_all < `EXCLUDE_LOW) || (iot_in_save_all > `EXCLUDE_HIGH)) begin
                    success <= 1; 
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_PMAX : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                success <= 0;
                if(data_round == 0 && first) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 0;
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(first && data_round == 0) first <= 0;
                if(iot_in_save_all > iot_out_pre_all) begin
                    if(!first) success <= 1;
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        `OP_PMIN : begin
            if(State_C == `State_LOAD || State_C == `State_IDLE) begin
                success <= 0;
                if(data_round == 0 && first) begin
                    iot_out_pre[iot_in_cycle] <= iot_in;
                    iot_in_save[iot_in_cycle] <= 8'b11111111;
                end
                else begin
                    iot_in_save[iot_in_cycle] <= iot_in;
                end
            end
            else if(State_C == `State_PROC) begin
                if(first && data_round == 0) first <= 0;
                if(iot_in_save_all < iot_out_pre_all) begin
                    if(!first) success <= 1;
                    for (i=0;i<16;i=i+1) begin
                        iot_out_pre[i] <= iot_in_save[i];
                    end
                end
            end
        end
        default: begin
            
        end
        endcase
    end
end

// Logic End
//////////////////////

endmodule