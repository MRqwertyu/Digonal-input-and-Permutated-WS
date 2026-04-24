# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ACC_BW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAX_TILES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MEM_FILE_A" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MEM_FILE_B" -parent ${Page_0}
  ipgui::add_param $IPINST -name "N" -parent ${Page_0}


}

proc update_PARAM_VALUE.ACC_BW { PARAM_VALUE.ACC_BW } {
	# Procedure called to update ACC_BW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACC_BW { PARAM_VALUE.ACC_BW } {
	# Procedure called to validate ACC_BW
	return true
}

proc update_PARAM_VALUE.BW { PARAM_VALUE.BW } {
	# Procedure called to update BW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BW { PARAM_VALUE.BW } {
	# Procedure called to validate BW
	return true
}

proc update_PARAM_VALUE.MAX_TILES { PARAM_VALUE.MAX_TILES } {
	# Procedure called to update MAX_TILES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAX_TILES { PARAM_VALUE.MAX_TILES } {
	# Procedure called to validate MAX_TILES
	return true
}

proc update_PARAM_VALUE.MEM_FILE_A { PARAM_VALUE.MEM_FILE_A } {
	# Procedure called to update MEM_FILE_A when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEM_FILE_A { PARAM_VALUE.MEM_FILE_A } {
	# Procedure called to validate MEM_FILE_A
	return true
}

proc update_PARAM_VALUE.MEM_FILE_B { PARAM_VALUE.MEM_FILE_B } {
	# Procedure called to update MEM_FILE_B when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEM_FILE_B { PARAM_VALUE.MEM_FILE_B } {
	# Procedure called to validate MEM_FILE_B
	return true
}

proc update_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to update N when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to validate N
	return true
}


proc update_MODELPARAM_VALUE.N { MODELPARAM_VALUE.N PARAM_VALUE.N } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N}] ${MODELPARAM_VALUE.N}
}

proc update_MODELPARAM_VALUE.BW { MODELPARAM_VALUE.BW PARAM_VALUE.BW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BW}] ${MODELPARAM_VALUE.BW}
}

proc update_MODELPARAM_VALUE.ACC_BW { MODELPARAM_VALUE.ACC_BW PARAM_VALUE.ACC_BW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACC_BW}] ${MODELPARAM_VALUE.ACC_BW}
}

proc update_MODELPARAM_VALUE.MAX_TILES { MODELPARAM_VALUE.MAX_TILES PARAM_VALUE.MAX_TILES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAX_TILES}] ${MODELPARAM_VALUE.MAX_TILES}
}

proc update_MODELPARAM_VALUE.MEM_FILE_A { MODELPARAM_VALUE.MEM_FILE_A PARAM_VALUE.MEM_FILE_A } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEM_FILE_A}] ${MODELPARAM_VALUE.MEM_FILE_A}
}

proc update_MODELPARAM_VALUE.MEM_FILE_B { MODELPARAM_VALUE.MEM_FILE_B PARAM_VALUE.MEM_FILE_B } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEM_FILE_B}] ${MODELPARAM_VALUE.MEM_FILE_B}
}

