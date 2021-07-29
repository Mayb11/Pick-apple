transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1 {C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1/Apple_pick.v}
vlog -vlog01compat -work work +incdir+C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1 {C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1/LT24Display.v}

vlog -vlog01compat -work work +incdir+C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1 {C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1/Apple_pick_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  Apple_pick_tb

do C:/Users/haozhe/Desktop/MSC/ELEC5566M/Github/ELEC5566M-MiniProject-haozhe1/../ELEC5566M-Resources/simulation/load_sim.tcl
