# LEDs (LED0-LED2) for Status Flags
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { busy_0 }]; 
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { done_0 }]; 
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { result_valid_0 }];