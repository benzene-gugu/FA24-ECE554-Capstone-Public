set_global_assignment -entity "PLLsys_vga" -library "lib_PLLsys_vga" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PLLsys_vga" -library "lib_PLLsys_vga" -name IP_TOOL_VERSION "22.1"
set_global_assignment -entity "PLLsys_vga" -library "lib_PLLsys_vga" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PLLsys_vga" -name SPD_FILE [file join $::quartus(sip_path) "PLLsys_vga.spd"]

set_global_assignment -library "lib_PLLsys_vga" -name MISC_FILE [file join $::quartus(sip_path) "PLLsys_vga_sim/PLLsys_vga.vo"]
