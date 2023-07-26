`timescale  1ns/1ps
// `define SDFFILE     "./ml_demodulator_syn.sdf"
// `define SDFFILE     "../02_SYN/Netlist/ml_demodulator_syn.sdf"
`define SDFFILE     "../04_APR/ml_demodulator_pr.sdf"
`define CYCLE       14.5
`define RST_DELAY   2
`define DEL         1
`define PAT_NUM     1000
`define End_CYCLE   1000000

`ifdef p1
    `define SNR_HB      "../00_TESTBED/PATTERN/packet1/SNR10dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_y_hat.dat"
    `define ERROR_THR   120
`elsif p2
    `define SNR_HB      "../00_TESTBED/PATTERN/packet2/SNR10dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet2/SNR10dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet2/SNR10dB_pat_y_hat.dat"
    `define ERROR_THR   120
`elsif p3
    `define SNR_HB      "../00_TESTBED/PATTERN/packet3/SNR10dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet3/SNR10dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet3/SNR10dB_pat_y_hat.dat"
    `define ERROR_THR   120
`elsif p4
    `define SNR_HB      "../00_TESTBED/PATTERN/packet4/SNR15dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet4/SNR15dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet4/SNR15dB_pat_y_hat.dat"
    `define ERROR_THR   10
`elsif p5
    `define SNR_HB      "../00_TESTBED/PATTERN/packet5/SNR15dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet5/SNR15dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet5/SNR15dB_pat_y_hat.dat"
    `define ERROR_THR   10
`elsif p6
    `define SNR_HB      "../00_TESTBED/PATTERN/packet6/SNR15dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet6/SNR15dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet6/SNR15dB_pat_y_hat.dat"
    `define ERROR_THR   10
`else
    `define SNR_HB      "../00_TESTBED/PATTERN/packet1/SNR10dB_hb.dat"
    `define SNR_PAT_R   "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_r.dat"
    `define SNR_PAT_Y   "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_y_hat.dat"
    `define ERROR_THR   120
`endif



module test;
    reg         clk;
    reg         rst;
    reg         trig;
    reg         rd_rdy;
    reg         ans_wrong;
    reg [9:0]   random_index;
    reg [159:0] y_hat;
    reg [319:0] r;
    wire        rd_vld;
    wire        hard_bit;
    wire  [7:0] llr;

    reg [159:0] y_hat_mem   [0:999];
    reg [319:0] r_mem       [0:999];
    reg         hb_mem      [0:7999];
    reg         hb_out      [0:7999];
    reg [7:0]   llr_out     [0:7999];
    reg [159:0] y_hat_tem;
    reg [319:0] r_tem;
    reg over, over1, over2;
    integer i,j,cycle_count,x,error,ans_count,rd_rdy_count,counter_640,k,seed;
    reg mode;
    reg rd_rdy_tmp;
    


    // Write out waveform file
    initial begin
        seed = 525;
        // $fsdbDumpfile("ml_demodulator.fsdb");
        `ifdef p1
        $fsdbDumpfile("ml_demodulator_p1.fsdb");
        `elsif p2
        $fsdbDumpfile("ml_demodulator_p2.fsdb");
        `elsif p3
        $fsdbDumpfile("ml_demodulator_p3.fsdb");
        `elsif p4
        $fsdbDumpfile("ml_demodulator_p4.fsdb");
        `elsif p5
        $fsdbDumpfile("ml_demodulator_p5.fsdb");
        `elsif p6
        $fsdbDumpfile("ml_demodulator_p6.fsdb");
        `else
        $fsdbDumpfile("ml_demodulator_p1.fsdb");
        `endif
      $fsdbDumpvars(0, "+mda");
    end

    ml_demodulator u_ml_demodulator(
        .i_clk(clk),
        .i_reset(rst),
        .i_trig(trig),
        .i_rd_rdy(rd_rdy),
        .i_y_hat(y_hat),
        .i_r(r),
        .o_rd_vld(rd_vld),
        .o_hard_bit(hard_bit),
        .o_llr(llr)
    );

        // For gate-level simulation only
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_ml_demodulator);
        initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
    `endif
    // Read in test pattern and golden pattern
    initial $readmemh(`SNR_PAT_Y,   y_hat_mem );
    initial $readmemh(`SNR_PAT_R,   r_mem     );
    initial $readmemh(`SNR_HB,      hb_mem    );
    //  time
    initial begin
        @(negedge clk);
        while (1) begin
            cycle_count = cycle_count + 1;
            @(negedge clk);
        end
    end
    // Clock generation
    initial clk = 1'b0;
    always begin #(`CYCLE/2) clk = ~clk; end
    
    initial begin
        trig        = 0;
        rst         = 0;
        i           = 0;    //  i th y,r
        j           = 0;    //  64 cycle counter
        cycle_count = 0;    
        x           = 0;    // hard_bit counter
        ans_count   = 0;
        error       = 0;
        k           = 0;
        counter_640  = 0;
        rd_rdy_count = 0;
        mode        = 0;
    end

    initial begin
        # ( 1 * `CYCLE)                  rst = 1;
        # ((`RST_DELAY - 0.25) * `CYCLE)    rst = 0;
        // # (({$random(seed)} % 5) * `CYCLE);
        while( i < `PAT_NUM )begin
            @(posedge clk);
            # `DEL
            if(j % 64 == 0)begin
                trig    = 1;
                y_hat   = y_hat_mem[i];
                r       = r_mem[i];
                i       = i + 1;
            end
            else trig = 0;
            j = j + 1;
        end
        @(posedge clk);
        # `DEL
        trig = 0;
        over1 = 1;
    end

    
    
    initial begin
        # ( 0.25 * `CYCLE);
        # ((`RST_DELAY - 0.25) * `CYCLE);
        while(1)begin
            @(posedge clk);
            # `DEL
            if(rd_rdy_count < 128)begin
                if( 128 - rd_rdy_count == 640 - counter_640)begin
                    rd_rdy = 1;
                    rd_rdy_count = rd_rdy_count + 1;
                end
                else begin
                    rd_rdy_tmp = {$random(seed)} % 2 ;
                    rd_rdy = rd_rdy_tmp;
                    rd_rdy_count = rd_rdy_count + rd_rdy_tmp;
                end
            end
            else 
                rd_rdy = 0;
            // if(mode)begin
            //     if(counter_640 > 511)begin
            //         rd_rdy = 1;
            //     end
            //     else rd_rdy = 0;
            // end
            // else begin
            //     if(counter_640 < 128)begin
            //         rd_rdy = 1;
            //     end
            //     else rd_rdy = 0;
            // end
            counter_640 = counter_640 + 1;
            if(counter_640 == 640)begin
                rd_rdy_count = 0;
                counter_640  = 0;
                mode = ~mode;
            end
        end
    end

initial begin
    # ( 0.25 * `CYCLE);
    # ((`RST_DELAY - 0.25) * `CYCLE);
    while(1)begin
        @(posedge clk);
        # (`CYCLE - `DEL);
        // detect answer
        if(rd_vld  && rd_rdy)begin
            hb_out[x]   = hard_bit;
            llr_out[x]  = llr;
            x = x + 1;
        end
        if(x == 8000)over2 = 1;
    end
end

    always @(*)begin
        over = over1 && over2;
    end

    initial begin
      @(posedge over);
      for (ans_count = 0 ; ans_count < 1000 ; ans_count = ans_count + 1 )begin
        ans_wrong = 0;
        for( k = 0 ; k < 8 ; k = k + 1 )begin
            if(llr_out[8 * ans_count + k] === 0 )begin
                $display("Error!!! LLR == 0 in [%d]:[%d]",ans_count,k);
                ans_wrong = 1;
            end
            if(hb_out[8 * ans_count + k] !== hb_mem[8 * ans_count + k]) begin
                $display("hb_out Error!Yours = [%d],ans = [%d] in [%d]:[%d]",hb_out[8 * ans_count + k],hb_mem[8 * ans_count + k],ans_count,k);
                ans_wrong = 1;
            end
        end
        if(ans_wrong)error = error + 1 ;
      end
      $display("\n");
      if (error < `ERROR_THR)  begin
            $display("-------------------------PASS------------------------");
            $display("Total error           :   %3d", error);
            $display("Error Threshold is    :   %3d",`ERROR_THR);
            $display("Congratulations! Total error is less than threshold!");
            $display("Total cycle_count     :   %3d", cycle_count);
            $display("Total cost time: %10.2f ns", cycle_count*(`CYCLE));
            $display("-------------------------PASS------------------------\n");
        end
        else begin
            $display("-------------------------Fail------------------------");
            $display("Total error:   %3d \n", error);
            $display("Error Threshold is :   %3d \n", `ERROR_THR);
            $display("Total cycle_count     :   %3d", cycle_count);
            $display("-------------------------Fail------------------------");
        end

      #(`CYCLE/2); $finish;
    end


    initial begin
        #(`End_CYCLE*(`CYCLE));
        $display(x);
        $display("-----------------------------------------------------\n");
        $display("Error!!! There is something wrong with your code ...!\n");
        $display("Exceed the max cycle ...............................!\n");
        $display("------The test result is .....FAIL ------------------\n");
        $display("-----------------------------------------------------\n");
        $finish;
    end
endmodule