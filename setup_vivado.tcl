# One-step registration of the repository sources in the currently open
# Vivado project.  The project name and location are intentionally irrelevant:
# all repository paths are resolved relative to this script.
#
# Usage from the Vivado Tcl console:
#   source /path/to/repository/setup_vivado.tcl
#
# The script is idempotent.  Individual source/IP/constraint failures are
# collected and reported instead of aborting the remaining setup steps.

namespace eval ::sixteen_camera_setup {
    variable repo_root [file dirname [file normalize [info script]]]
    variable added
    variable existing
    variable failed
    variable failure_details {}
    variable bd_status "NOT_RUN"
    variable wrapper_status "NOT_RUN"

    foreach category {RTL SOC IP XDC} {
        set added($category) 0
        set existing($category) 0
        set failed($category) 0
    }
}

proc ::sixteen_camera_setup::record_failure {category item message} {
    variable failed
    variable failure_details
    incr failed($category)
    lappend failure_details [list $category $item $message]
    puts "${category}_WARN: $item : $message"
}

proc ::sixteen_camera_setup::collect_hdl_files {directory} {
    set result {}
    if {![file isdirectory $directory]} {
        return $result
    }
    foreach entry [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $entry]} {
            set result [concat $result [collect_hdl_files $entry]]
        } else {
            set extension [string tolower [file extension $entry]]
            if {[lsearch -exact {.v .sv .vh .svh .vhd .vhdl .mif .mem} \
                                $extension] >= 0} {
                lappend result [file normalize $entry]
            }
        }
    }
    return $result
}

proc ::sixteen_camera_setup::project_has_file {path} {
    set normalized [file normalize $path]
    if {[llength [get_files -all -quiet $normalized]] != 0} {
        return 1
    }

    # Some generated/project-relative files are returned through Vivado path
    # variables.  Limit the fallback to matching basenames; scanning every
    # project file for every added SoC module makes clean setup unnecessarily
    # quadratic.
    set basename [file tail $normalized]
    foreach object [get_files -all -quiet */$basename] {
        if {[catch {set name [get_property NAME $object]}]} {
            continue
        }
        if {[catch {set object_path [file normalize $name]}]} {
            continue
        }
        if {$object_path eq $normalized} {
            return 1
        }
    }
    return 0
}

proc ::sixteen_camera_setup::safe_add_file {category fileset path} {
    variable added
    variable existing

    if {![file exists $path]} {
        record_failure $category $path "file does not exist"
        return 0
    }

    set normalized [file normalize $path]
    if {[project_has_file $normalized]} {
        incr existing($category)
        return 1
    }

    if {[catch {
        add_files -fileset $fileset -norecurse $normalized
    } message]} {
        record_failure $category $normalized $message
        return 0
    }

    incr added($category)
    return 1
}

proc ::sixteen_camera_setup::safe_generate_ip {xci_path} {
    variable failed
    set ip_name [file rootname [file tail $xci_path]]
    set ip_object [get_ips -quiet $ip_name]
    if {[llength $ip_object] == 0} {
        record_failure IP $xci_path "XCI was added but IP object $ip_name is unavailable"
        return 0
    }

    if {![catch {set locked [get_property IS_LOCKED $ip_object]}] && $locked} {
        record_failure IP $xci_path "IP is locked; automatic upgrade is disabled"
        return 0
    }

    if {[catch {generate_target all $ip_object} message]} {
        record_failure IP $xci_path "generate_target failed: $message"
        return 0
    }
    return 1
}

proc ::sixteen_camera_setup::setup_bd {} {
    variable repo_root
    variable bd_status
    variable wrapper_status

    set bd_name design_1
    set bd_script [file join $repo_root prj create_design_1.tcl]
    set bd_files [get_files -all -quiet */${bd_name}.bd]

    if {[llength $bd_files] == 0} {
        if {![file exists $bd_script]} {
            set bd_status "FAILED: missing $bd_script"
            puts "BD_WARN: $bd_status"
            return
        }
        if {[catch {source $bd_script} message]} {
            set bd_status "FAILED: $message"
            puts "BD_WARN: create script failed: $message"
            return
        }
        set bd_files [get_files -all -quiet */${bd_name}.bd]
    }

    if {[llength $bd_files] != 1} {
        set bd_status "FAILED: expected one ${bd_name}.bd, found [llength $bd_files]"
        puts "BD_WARN: $bd_status"
        return
    }

    set bd_file [lindex $bd_files 0]
    if {[catch {
        open_bd_design $bd_file
        validate_bd_design
        save_bd_design
        generate_target all $bd_file
    } message]} {
        set bd_status "FAILED: $message"
        puts "BD_WARN: validate/generate failed: $message"
        return
    }
    set bd_status "OK"

    set wrapper_objects [get_files -all -quiet */${bd_name}_wrapper.v]
    if {[llength $wrapper_objects] == 0} {
        if {[catch {set wrapper_paths [make_wrapper -files $bd_file -top]} \
                   message]} {
            set wrapper_status "FAILED: $message"
            puts "WRAPPER_WARN: make_wrapper failed: $message"
            return
        }
        foreach wrapper_path $wrapper_paths {
            if {![project_has_file $wrapper_path]} {
                if {[catch {
                    add_files -fileset sources_1 -norecurse \
                        [file normalize $wrapper_path]
                } message]} {
                    set wrapper_status "FAILED: $message"
                    puts "WRAPPER_WARN: add_files failed: $message"
                    return
                }
            }
        }
    }
    set wrapper_status "OK"
}

set sc_project [current_project -quiet]
if {$sc_project eq ""} {
    puts "SETUP_ERROR: no Vivado project is open"
    puts "PROJECT_SETUP=FAILED"
    return
}

set sc_repo_root $::sixteen_camera_setup::repo_root
set sc_project_name [get_property NAME $sc_project]
set sc_project_part [get_property PART $sc_project]
set sc_expected_part xcvu13p-fhga2104-2-i
set sc_expected_vivado 2023.2

puts "PROJECT_NAME=$sc_project_name"
puts "PROJECT_PART=$sc_project_part"
puts "REPO_ROOT=$sc_repo_root"

if {[string first $sc_expected_vivado [version -short]] < 0} {
    puts "ENV_WARN: expected Vivado $sc_expected_vivado, running [version -short]"
}
if {$sc_project_part ne $sc_expected_part} {
    puts "ENV_WARN: expected part $sc_expected_part, project uses $sc_project_part"
}

foreach command {
    {set_property target_language Verilog [current_project]}
    {set_property simulator_language Mixed [current_project]}
    {update_ip_catalog}
} {
    if {[catch {uplevel #0 $command} message]} {
        puts "PROJECT_WARN: $message"
    }
}

# Hand-written synthesis RTL.  Deliberately exclude rtl/ip and rtl/soc here:
# XCI and generated SoC collateral are registered in their own phases.
set sc_rtl_files {}
foreach subdir {
    rtl/interfaces
    rtl/bus
    rtl/control
    rtl/memory
    rtl/si5338
    rtl/video
    rtl/ai
} {
    set sc_rtl_files [concat $sc_rtl_files \
        [::sixteen_camera_setup::collect_hdl_files \
            [file join $sc_repo_root $subdir]]]
}
lappend sc_rtl_files [file join $sc_repo_root rtl top_wrapper.sv]

foreach path [lsort -unique $sc_rtl_files] {
    ::sixteen_camera_setup::safe_add_file RTL sources_1 $path
}

# The selected Rocket configuration is generated as one collateral unit.  All
# Verilog/SystemVerilog/memory files in this one directory belong together.
# Keep this aligned with control_soc_subsystem, which instantiates the video
# Rocket MyBoardFPGATestHarness used by the non-Gemmini timing baseline.
set sc_soc_config \
    chipyard.fpga.myboard.MyBoardFPGATestHarness.SmallRocketVideoDDR256MyBoardConfig
set sc_soc_dir [file normalize [file join $sc_repo_root rtl soc \
    $sc_soc_config gen-collateral]]

# The checked-in project can retain source entries from an earlier SoC switch.
# Keeping two generated Chipyard collateral trees in one source set silently
# overwrites common module definitions and makes the selected debug/JTAG
# implementation ambiguous.  Remove only stale project entries; the generated
# files on disk remain untouched.
set sc_soc_root [file normalize [file join $sc_repo_root rtl soc]]
set sc_soc_marker "/rtl/soc/"
set sc_selected_soc_marker "/rtl/soc/${sc_soc_config}/"
set sc_stale_soc_files {}
foreach sc_file [get_files -quiet -of_objects [get_filesets sources_1]] {
    if {[catch {set sc_file_name [file normalize [get_property NAME $sc_file]]}]} {
        continue
    }
    # Match both repository-linked sources and copies below a Vivado imports
    # directory. Imported files do not begin with sc_soc_root.
    if {[string first $sc_soc_marker $sc_file_name] >= 0 && \
        [string first $sc_selected_soc_marker $sc_file_name] < 0} {
        lappend sc_stale_soc_files $sc_file
    }
}
if {[llength $sc_stale_soc_files] != 0} {
    if {[catch {
        remove_files -fileset sources_1 $sc_stale_soc_files
    } message]} {
        puts "SOC_WARN: could not remove stale collateral: $message"
    } else {
        puts "SOC_REMOVED_STALE=[llength $sc_stale_soc_files]"
    }
}

set sc_soc_files [::sixteen_camera_setup::collect_hdl_files $sc_soc_dir]
if {[llength $sc_soc_files] == 0} {
    ::sixteen_camera_setup::record_failure SOC $sc_soc_dir \
        "no generated collateral files found"
} else {
    foreach path [lsort -unique $sc_soc_files] {
        ::sixteen_camera_setup::safe_add_file SOC sources_1 $path
    }
}

# Only the standalone IPs used by the current top-level baseline are added.
set sc_ip_paths {
    rtl/ip/axi_gpio_0/axi_gpio_0.xci
    rtl/ip/axi_iic_0/axi_iic_0.xci
    rtl/ip/clk_wiz_ov7670/clk_wiz_ov7670.xci
    rtl/ip/rx_axis_reg_slice/rx_axis_reg_slice.xci
    rtl/ip/tx_axis_reg_slice/tx_axis_reg_slice.xci
    rtl/ip/tx_refclk_bufg/tx_refclk_bufg.xci
    rtl/ip/tx_refclk_ibuf/tx_refclk_ibuf.xci
    rtl/ip/v_hdmi_rx_ss_0/v_hdmi_rx_ss_0.xci
    rtl/ip/v_hdmi_tx_ss_0/v_hdmi_tx_ss_0.xci
    rtl/ip/vid_phy_controller_0/vid_phy_controller_0.xci
}
foreach relative_path $sc_ip_paths {
    set path [file join $sc_repo_root $relative_path]
    if {[::sixteen_camera_setup::safe_add_file IP sources_1 $path]} {
        ::sixteen_camera_setup::safe_generate_ip $path
    }
}

# Recreate the DDR block design when absent, otherwise validate and reuse it.
::sixteen_camera_setup::setup_bd

# Active baseline constraints only; archived pinout alternatives are omitted.
set sc_xdc_paths {
    xdc/clk.xdc
    xdc/ddr.xdc
    xdc/hdmi_tx.xdc
    xdc/mipi.xdc
    xdc/camera_sccb.xdc
    xdc/vu13p_ov7670_8ch_fmc1_fmc2_j2_cam3_legacy_v3.xdc
}
foreach relative_path $sc_xdc_paths {
    set path [file join $sc_repo_root $relative_path]
    if {[::sixteen_camera_setup::safe_add_file XDC constrs_1 $path]} {
        set object [get_files -all -quiet [file normalize $path]]
        if {[llength $object] != 0} {
            catch {set_property USED_IN_SYNTHESIS true $object}
            catch {set_property USED_IN_IMPLEMENTATION true $object}
            catch {set_property PROCESSING_ORDER NORMAL $object}
        }
    }
}

set sc_top_status "OK"
if {[llength [get_files -all -quiet */top_wrapper.sv]] == 0} {
    set sc_top_status "FAILED: top_wrapper.sv is not registered"
    puts "TOP_WARN: $sc_top_status"
} else {
    if {[catch {
        set_property top top_wrapper [get_filesets sources_1]
        if {[llength [get_filesets -quiet sim_1]] != 0} {
            set_property top top_wrapper [get_filesets sim_1]
        }
    } message]} {
        set sc_top_status "FAILED: $message"
        puts "TOP_WARN: $sc_top_status"
    }
}

foreach fileset {sources_1 sim_1} {
    if {[llength [get_filesets -quiet $fileset]] != 0} {
        if {[catch {update_compile_order -fileset $fileset} message]} {
            puts "COMPILE_ORDER_WARN: $fileset : $message"
        }
    }
}

set sc_total_failed 0
foreach category {RTL SOC IP XDC} {
    incr sc_total_failed $::sixteen_camera_setup::failed($category)
    puts "${category}_ADDED=$::sixteen_camera_setup::added($category)"
    puts "${category}_EXISTING=$::sixteen_camera_setup::existing($category)"
    puts "${category}_FAILED=$::sixteen_camera_setup::failed($category)"
}
puts "BD_STATUS=$::sixteen_camera_setup::bd_status"
puts "WRAPPER_STATUS=$::sixteen_camera_setup::wrapper_status"
puts "TOP_STATUS=$sc_top_status"

if {[llength $::sixteen_camera_setup::failure_details] != 0} {
    puts "FAILURE_DETAILS_BEGIN"
    foreach detail $::sixteen_camera_setup::failure_details {
        puts "  [lindex $detail 0]: [lindex $detail 1] : [lindex $detail 2]"
    }
    puts "FAILURE_DETAILS_END"
}

if {$sc_total_failed == 0 &&
    $::sixteen_camera_setup::bd_status eq "OK" &&
    $::sixteen_camera_setup::wrapper_status eq "OK" &&
    $sc_top_status eq "OK"} {
    puts "PROJECT_SETUP=PASS"
} else {
    puts "PROJECT_SETUP=PARTIAL"
}
