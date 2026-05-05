## This file is a customized .xdc for the Zybo Z7 Rev. B for the DiP ASIC Accelerator

## Clock signal (Sysclk is 125MHz, but we constrain to 1GHz / 1.0ns for ASIC power estimation)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 4.000 -waveform {0.000 2.000} [get_ports { clk }];


### Switches (On-board)
# SW0: Used for Active-Low Reset (UP = Run, DOWN = Reset)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

# Zybo Z7 Slide Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[0] }]; # Switch 0
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[1] }]; # Switch 1
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[2] }]; # Switch 2
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[3] }]; # Switch 3

## Buttons
# BTN0: Used for Start signal
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { start }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]


## LEDs
# LED0: Busy flag
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { busy }]; #IO_L23P_T3_35 Sch=led[0]

# LED1: Done flag
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { done }]; #IO_L23N_T3_35 Sch=led[1]

# LED2: Result Valid flag
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { result_valid }]; #IO_0_35 Sch=led[2]