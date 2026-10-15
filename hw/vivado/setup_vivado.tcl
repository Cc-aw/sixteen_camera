# One-step registration of the repository sources in the currently open
# Vivado project.  The project name and location are intentionally irrelevant:
# all repository paths are resolved relative to this script.
#
# Usage from the Vivado Tcl console:
#   source /path/to/repository/hw/vivado/setup_vivado.tcl
#
# The script is idempotent.  Individual source/IP/constraint failures are
# collected and reported instead of aborting the remaining setup steps.

namespace eval ::sixteen_camera_setup {
    variable repo_root [file dirname [file dirname [file dirname [file normalize [info script]]]]]
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

proc ::sixteen_camera_setup::collect_hdl_files {directory extensions} {
    set result {}
    if {![file isdirectory $directory]} {
        return $result
    }
    foreach entry [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $entry]} {
            set result [concat $result [collect_hdl_files $entry $extensions]]
        } else {
            set extension [string tolower [file extension $entry]]
            if {[lsearch -exact $extensions $extension] >= 0} {
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
    if {[info exists ::sc_generate_synth_checkpoint]} {
        set_property GENERATE_SYNTH_CHECKPOINT $::sc_generate_synth_checkpoint \
            [get_files -all -quiet [file normalize $xci_path]]
    }
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
    set bd_script [file join $repo_root hw vivado create_design_1.tcl]
    if {$::SOC_MEMORY_PARALLEL_V3} {
        set bd_script [file join $repo_root hw vivado create_design_1_v3.tcl]
    }
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
        if {[info exists ::sc_bd_checkpoint_mode]} {
            set_property SYNTH_CHECKPOINT_MODE $::sc_bd_checkpoint_mode $bd_file
        }
        open_bd_design $bd_file
        if {$::SOC_MEMORY_PARALLEL_V3} {
            foreach {property expected} {DATA_WIDTH 512 ID_WIDTH 2 NUM_READ_OUTSTANDING 32 NUM_WRITE_OUTSTANDING 32} {
                if {[get_property CONFIG.$property [get_bd_intf_ports S00_AXI]] != $expected} {
                    error "DDR BD is incompatible with V3 ($property); rebuild in a new VIVADO_PROJECT"
                }
            }
            if {[llength [get_bd_cells -quiet u_mig_perf]] != 1 ||
                [get_property MODE [get_bd_intf_pins u_mig_perf/S_AXI]] ne "Monitor"} {
                error "V3 requires the passive MIG Monitor interface"
            }
            # Existing projects must consume the repaired full-throughput
            # boundary too; reopening an old BD otherwise retains mode 7.
            set slice [get_bd_cells -quiet m00_full_regslice]
            if {[llength $slice] != 1} {error "V3 requires one final DDR register slice"}
            foreach channel {AW W B AR R} {
                if {[get_property CONFIG.REG_$channel $slice] != 1} {
                    set_property CONFIG.REG_$channel 1 $slice
                    puts "V3_DDR_SLICE_UPDATED channel=$channel mode=1"
                }
            }
        } elseif {[get_property CONFIG.DATA_WIDTH [get_bd_intf_ports S00_AXI]] != 256} {
            error "DDR BD is incompatible with this SoC; use a matching VIVADO_PROJECT"
        }
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

# Hand-written synthesis RTL is an explicit whitelist. XCI and generated SoC
# collateral are registered in their own phases below.
set sc_rtl_manifest [file join $sc_repo_root hw manifests rtl_manifest.tcl]
if {![file exists $sc_rtl_manifest]} {
    error "Missing production RTL manifest: $sc_rtl_manifest"
}
unset -nocomplain RTL_SOURCES
source $sc_rtl_manifest
if {![info exists RTL_SOURCES] || [llength $RTL_SOURCES] == 0} {
    error "Production RTL manifest is empty: $sc_rtl_manifest"
}
set sc_rtl_files {}
foreach relative_path $RTL_SOURCES {
    lappend sc_rtl_files [file normalize [file join $sc_repo_root $relative_path]]
}

# Remove stale hand-written/imported RTL entries retained by an older project.
# This makes membership in the manifest authoritative without touching IP or
# generated SoC collateral.
set sc_rtl_roots [list \
    [file normalize [file join $sc_repo_root hw rtl common]] \
    [file normalize [file join $sc_repo_root hw rtl interfaces]] \
    [file normalize [file join $sc_repo_root hw rtl bus]] \
    [file normalize [file join $sc_repo_root hw rtl control]] \
    [file normalize [file join $sc_repo_root hw rtl memory]] \
    [file normalize [file join $sc_repo_root hw rtl si5338]] \
    [file normalize [file join $sc_repo_root hw rtl video]] \
    [file normalize [file join $sc_repo_root hw rtl ai]]]
set sc_imported_rtl_marker "/hw/vivado/sixteen_camera.srcs/sources_1/imports/hw/rtl/"
foreach sc_file [get_files -quiet -of_objects [get_filesets sources_1]] {
    if {[catch {set sc_name [file normalize [get_property NAME $sc_file]]}]} {
        continue
    }
    set sc_is_handwritten 0
    foreach sc_root $sc_rtl_roots {
        if {[string first "${sc_root}/" $sc_name] == 0} {
            set sc_is_handwritten 1
            break
        }
    }
    if {[string first $sc_imported_rtl_marker $sc_name] >= 0} {
        set sc_is_handwritten 1
    }
    if {$sc_is_handwritten && [lsearch -exact $sc_rtl_files $sc_name] < 0} {
        remove_files $sc_file
    }
}

foreach path [lsort -unique $sc_rtl_files] {
    ::sixteen_camera_setup::safe_add_file RTL sources_1 $path
}

# The selected Rocket configuration is generated as one collateral unit.
source [file join $sc_repo_root hw manifests soc_manifest.tcl]
set sc_soc_config $SOC_CONFIG
set sc_soc_dir [file normalize [file join $sc_repo_root $SOC_COLLATERAL_DIR]]
set sc_defines [get_property verilog_define [get_filesets sources_1]]
set sc_defines [lsearch -all -inline -not -exact $sc_defines SOC_TENSOR_INGRESS]
if {$SOC_TENSOR_INGRESS} { lappend sc_defines SOC_TENSOR_INGRESS }
set sc_defines [lsearch -all -inline -not -exact $sc_defines SOC_MEMORY_PARALLEL_V3]
if {$SOC_MEMORY_PARALLEL_V3} { lappend sc_defines SOC_MEMORY_PARALLEL_V3 }
set_property verilog_define $sc_defines [get_filesets sources_1]

# The checked-in project can retain source entries from an earlier SoC switch.
# Keeping two generated Chipyard collateral trees in one source set silently
# overwrites common module definitions and makes the selected debug/JTAG
# implementation ambiguous.  Remove only stale project entries; the generated
# files on disk remain untouched.
set sc_soc_marker "/hw/soc/"
set sc_legacy_soc_marker "/hw/rtl/soc/"
set sc_selected_soc_marker "/hw/soc/${sc_soc_config}/"
set sc_stale_soc_files {}
foreach sc_file [get_files -quiet -of_objects [get_filesets sources_1]] {
    if {[catch {set sc_file_name [file normalize [get_property NAME $sc_file]]}]} {
        continue
    }
    # Match both repository-linked sources and copies below a Vivado imports
    # directory. Imported files do not begin with sc_soc_root.
    if {([string first $sc_soc_marker $sc_file_name] >= 0 || \
         [string first $sc_legacy_soc_marker $sc_file_name] >= 0) && \
        ([string first $sc_selected_soc_marker $sc_file_name] < 0 || \
         ![file exists $sc_file_name])} {
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

set sc_soc_files [::sixteen_camera_setup::collect_hdl_files \
    $sc_soc_dir $SOC_HDL_EXTENSIONS]
if {[llength $sc_soc_files] == 0} {
    ::sixteen_camera_setup::record_failure SOC $sc_soc_dir \
        "no generated collateral files found"
} else {
    foreach path [lsort -unique $sc_soc_files] {
        ::sixteen_camera_setup::safe_add_file SOC sources_1 $path
    }
}

# Create only the standalone IPs in the production manifest. Their generated
# files belong to Vivado; no source snapshot or output directory is required.
source [file join $sc_repo_root hw manifests ip_manifest.tcl]
set sc_ip_files {}
foreach relative_path $IP_SOURCES {
    set sc_ip_script [file join $sc_repo_root $relative_path]
    set sc_ip_name [file rootname [file tail $relative_path]]
    set sc_ip_existed [expr {[llength [get_ips -quiet $sc_ip_name]] != 0}]
    if {[catch {source $sc_ip_script} message]} {
        ::sixteen_camera_setup::record_failure IP $relative_path $message
        continue
    }
    set sc_ip_path [get_property IP_FILE [get_ips $sc_ip_name]]
    lappend sc_ip_files $sc_ip_path
    if {$sc_ip_existed} {
        incr ::sixteen_camera_setup::existing(IP)
    } else {
        incr ::sixteen_camera_setup::added(IP)
    }
    ::sixteen_camera_setup::safe_generate_ip $sc_ip_path
}

# Recreate the DDR block design when absent, otherwise validate and reuse it.
::sixteen_camera_setup::setup_bd

# Active baseline constraints only; archived pinout alternatives are omitted.
source [file join $sc_repo_root hw manifests xdc_manifest.tcl]
foreach relative_path $XDC_SOURCES {
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

set sc_compile_filesets {sources_1}
if {![info exists sc_batch_setup] || !$sc_batch_setup} {
    lappend sc_compile_filesets sim_1
}
foreach fileset $sc_compile_filesets {
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

# GUI setup and batch implementation use the same selected flow.
source [file join $sc_repo_root tools build default_video_run_settings.tcl]
apply_default_video_run_settings
if {$SOC_BITSTREAM_FLOW eq "triple32_v3"} {
    source [file join $sc_repo_root tools build triple32_v3 run_settings.tcl]
    apply_triple32_v3_run_settings
}
