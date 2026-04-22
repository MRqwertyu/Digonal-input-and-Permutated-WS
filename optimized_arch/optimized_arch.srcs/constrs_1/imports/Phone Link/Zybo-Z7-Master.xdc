## This file is a customized .xdc for the Zybo Z7 Rev. B for the DiP ASIC Accelerator

## Clock signal (Sysclk is 125MHz, but we constrain to 1GHz / 1.0ns for ASIC power estimation)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0.000 4.000} [get_ports { clk }];


### Switches
# SW0: Used for Active-Low Reset (UP = Run, DOWN = Reset)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

# SW1, SW2, SW3: Used for the lowest 3 bits of num_tiles (Allows 0 to 7 tiles)
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[0] }]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[1] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { num_tiles[2] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]


## Buttons
# BTN0: Used for Start signal
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { start }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]
#set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L24N_T3_34 Sch=btn[1]
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]
#set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; #IO_L7P_T1_34 Sch=btn[3]


## LEDs
# LED0: Busy flag
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { busy }]; #IO_L23P_T3_35 Sch=led[0]

# LED1: Done flag
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { done }]; #IO_L23N_T3_35 Sch=led[1]

# LED2: Result Valid flag
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { result_valid }]; #IO_0_35 Sch=led[2]

#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]

## (All other unused constraints like Audio, HDMI, etc., can remain commented out below this line)