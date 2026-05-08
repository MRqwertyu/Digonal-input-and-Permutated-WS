# 2026-05-08T11:31:07.083621200
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "zybo_platfor",hw_design = "$COMPONENT_LOCATION/../../soc_design_wrapper.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",generate_dtb = False,advanced_options = advanced_options,compiler = "gcc")

platform = client.get_component(name="zybo_platfor")
status = platform.build()

comp = client.create_app_component(name="accelerator_app",platform = "$COMPONENT_LOCATION/../zybo_platfor/export/zybo_platfor/zybo_platfor.xpfm",domain = "standalone_ps7_cortexa9_0")

status = platform.build()

comp = client.get_component(name="accelerator_app")
comp.build()

