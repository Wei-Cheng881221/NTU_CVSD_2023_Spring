`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define RST_DELAY   2
`define MAX_CYCLE   120000
`define PAT_NUM 	1024

`ifdef p0
    `define Inst "../00_TESTBED/PATTERN/p0/inst.dat"
	`define Data "../00_TESTBED/PATTERN/p0/data.dat"
	`define Stat "../00_TESTBED/PATTERN/p0/status.dat"
`elsif p1
	`define Inst "../00_TESTBED/PATTERN/p1/inst.dat"
	`define Data "../00_TESTBED/PATTERN/p1/data.dat"
	`define Stat "../00_TESTBED/PATTERN/p1/status.dat"
`endif

module testbed;

	reg clk = 0;
	reg rst_n = 1;
	wire [ 31 : 0 ] imem_addr;
	wire [ 31 : 0 ] imem_inst;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  1 : 0 ] mips_status;
	wire            mips_status_valid;
	
	// my reg and wire
	integer 		i, j, error_cnt;
	reg  			error;

	reg  [  1 : 0 ] output_status  [ 1023 : 0 ];
	// reg  [ 31 : 0 ] output_data	   [   63 : 0 ];
	reg  [  1 : 0 ] pattern_status [ 1023 : 0 ];
	reg  [ 31 : 0 ] pattern_data   [   63 : 0 ];

	reg  [ 31 : 0 ] instruct_save  [ 1023 : 0 ];

	initial begin
		$readmemb (`Inst, u_inst_mem.mem_r);
		$readmemb (`Data, pattern_data);
		$readmemb (`Stat, pattern_status);
	end

	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_i_addr(imem_addr),
		.i_i_inst(imem_inst),
		.o_d_we(dmem_we),
		.o_d_addr(dmem_addr),
		.o_d_wdata(dmem_wdata),
		.i_d_rdata(dmem_rdata),
		.o_status(mips_status),
		.o_status_valid(mips_status_valid)
	);

	inst_mem  u_inst_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_addr(imem_addr),
		.o_inst(imem_inst)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_we),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

	initial clk = 0;
    always #(`CYCLE/2.0) clk = ~clk; 

    initial begin
       $fsdbDumpfile("alu.fsdb");
       $fsdbDumpvars(0, testbed, "+mda");
	   //$fsdbDumpvars;
    end

	initial begin
        i         = 0;
        rst_n     = 1;
        error 	  = 0;
		error_cnt = 0;
		reset;

		// save the operation output
		// end the process is eof or overflow
        while (i < `PAT_NUM && !error) begin
            @(negedge clk);
	        if (mips_status_valid) begin
				output_status[i] = mips_status;
				instruct_save[i] = imem_inst;
				$display (
					"Test[%d]: Pattern=%b, Output=%b, instruction = %b", 
					i, pattern_status[i], mips_status, imem_inst
				);
				if(mips_status == 2'd2 || mips_status == 2'd3) begin
					// error happens
					error = 1;
				end
            	i = i + 1;	//count where end
	        end
        end
		$display ("\n");
		//status
		for(j = 0; j < i; j= j + 1) begin
			if(output_status[j] != pattern_status[j]) begin
				error_cnt = error_cnt + 1;
				$display (
					"Test[%d]: Error PATTERN! Pattern=%b, Output=%b, instruction = %b", 
					j, pattern_status[j], output_status[j], instruct_save[j]
				);
			end
		end

		//data
		//u_data_mem.mem_r api given by TA
		for(j = 0; j < i; j= j + 1) begin
			if(u_data_mem.mem_r[j] != pattern_data[j]) begin
				error_cnt = error_cnt + 1; //why no ++ QQ
				$display (
					"Test[%d]: Error DATA! Pattern=%b, Output=%b", 
					j, pattern_data[j], u_data_mem.mem_r[j]
				);
			end
		end

        $display("Pattern: ", `Inst);

        if(error_cnt == 0) begin
            $display("----------------------------------------------");
            $display("-                 ALL PASS!                  -");
            $display("----------------------------------------------");
        end else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total error: %d                      ", error_cnt);
            $display("----------------------------------------------");
        end
        # ( 2 * `CYCLE);
        $finish;
    end

    initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("----------------------------------------------");
        $display("Latency of your design is over 120000 cycles!!");
        $display("----------------------------------------------");
        $finish;
    end

    task reset; begin
        # ( 0.25 * `CYCLE);
        rst_n = 0;    
        # ((`RST_DELAY) * `CYCLE);
        rst_n = 1;    
    end endtask
endmodule



