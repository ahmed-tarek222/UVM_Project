#############################################################################
# FIFO UVM project - QuestaSim run script
# Usage (from this directory):  vsim -do run.do     or in the GUI:  do run.do
#############################################################################
quit -sim
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
file mkdir reports

#---------------------------------------------------------------------------
# Locate the UVM sources shipped with the simulator (or use $UVM_HOME)
#---------------------------------------------------------------------------
set UVM_SRC ""
if {[info exists env(UVM_HOME)] && [file exists $env(UVM_HOME)/src/uvm_macros.svh]} {
  set UVM_SRC $env(UVM_HOME)/src
} else {
  set tool_bin [file dirname [info nameofexecutable]]
  if {[info exists env(MODEL_TECH)]} { set tool_bin $env(MODEL_TECH) }
  set tool_root [file dirname $tool_bin]
  foreach v {uvm-1.1d uvm-1.2} {
    if {[file exists $tool_root/verilog_src/$v/src/uvm_macros.svh]} {
      set UVM_SRC $tool_root/verilog_src/$v/src
      break
    }
  }
}
if {$UVM_SRC ne ""} {
  echo "Using UVM sources: $UVM_SRC"
  vlog -sv +incdir+$UVM_SRC +define+UVM_NO_DPI $UVM_SRC/uvm_pkg.sv
  set UVM_INC +incdir+$UVM_SRC
} else {
  echo "UVM sources not found - using the simulator built-in UVM package"
  set UVM_INC ""
}

#---------------------------------------------------------------------------
# Compile: design with code coverage, testbench without
#---------------------------------------------------------------------------
vlog -sv +cover=bcesft FIFO.sv
vlog -sv {*}$UVM_INC +define+UVM_NO_DPI -f src_files.list

#---------------------------------------------------------------------------
# Simulate
#---------------------------------------------------------------------------
vsim -voptargs=+acc work.FIFO_top -classdebug -coverage -assertdebug -onfinish stop +UVM_NO_RELNOTES +UVM_VERBOSITY=UVM_LOW

add wave -divider "Interface"
add wave -radix unsigned /FIFO_top/clk
add wave -radix unsigned /FIFO_top/FIFOif/rst_n
add wave -radix unsigned /FIFO_top/FIFOif/wr_en
add wave -radix unsigned /FIFO_top/FIFOif/rd_en
add wave -radix hex      /FIFO_top/FIFOif/data_in
add wave -radix hex      /FIFO_top/FIFOif/data_out
add wave -radix unsigned /FIFO_top/FIFOif/wr_ack
add wave -radix unsigned /FIFO_top/FIFOif/full
add wave -radix unsigned /FIFO_top/FIFOif/almostfull
add wave -radix unsigned /FIFO_top/FIFOif/empty
add wave -radix unsigned /FIFO_top/FIFOif/almostempty
add wave -radix unsigned /FIFO_top/FIFOif/overflow
add wave -radix unsigned /FIFO_top/FIFOif/underflow
add wave -divider "DUT internals"
add wave -radix unsigned /FIFO_top/DUT/wr_ptr
add wave -radix unsigned /FIFO_top/DUT/rd_ptr
add wave -radix unsigned /FIFO_top/DUT/count
add wave -radix hex      /FIFO_top/DUT/mem
add wave -divider "Assertions"
add wave /FIFO_top/DUT/FIFO_sva_inst/ap_wr_ack
add wave /FIFO_top/DUT/FIFO_sva_inst/ap_overflow
add wave /FIFO_top/DUT/FIFO_sva_inst/ap_underflow
add wave /FIFO_top/DUT/FIFO_sva_inst/ap_count_wr_rd_full
add wave /FIFO_top/DUT/FIFO_sva_inst/ap_count_wr_rd_empty

coverage save -onexit reports/FIFO.ucdb
run -all

#---------------------------------------------------------------------------
# Reports
#---------------------------------------------------------------------------
coverage save reports/FIFO.ucdb
vcover report reports/FIFO.ucdb -details -annotate -all  -output reports/code_coverage_rpt.txt
vcover report reports/FIFO.ucdb -cvg -details            -output reports/functional_coverage_rpt.txt
vcover report reports/FIFO.ucdb -assert -details         -output reports/assertion_rpt.txt
coverage report -detail -directive -comments             -output reports/sequential_coverage_rpt.txt
echo "Reports written to ./reports"
wave zoom full
