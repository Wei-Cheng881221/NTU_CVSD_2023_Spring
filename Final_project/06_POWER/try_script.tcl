## PrimeTime Script
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../04_APR/ml_demodulator_pr.v
current_design ml_demodulator
link

# ===== modified to your max clock freq ===== #
create_clock -period 14.5 [get_ports i_clk]
set_propagated_clock      [get_clock i_clk]
# ===== active window ===== #
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p1.fsdb
 
update_power
report_power 
report_power -verbose > try_active_p1.power
#################
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p2.fsdb
 
update_power
report_power 
report_power -verbose > try_active_p2.power
#################
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p3.fsdb

update_power
report_power 
report_power -verbose > try_active_p3.power
#################
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p4.fsdb

update_power
report_power 
report_power -verbose > try_active_p4.power
#################
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p5.fsdb

update_power
report_power 
report_power -verbose > try_active_p5.power
#################
read_fsdb  -strip_path test/u_ml_demodulator ../05_POST/ml_demodulator_p6.fsdb

update_power
report_power 
report_power -verbose > try_active_p6.power

exit