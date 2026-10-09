# Create the OOC runs required by a source-only working project.
foreach xci $sc_ip_files {
    set ip [get_ips [file rootname [file tail $xci]]]
    set run_name "${ip}_synth_1"
    if {[llength [get_runs -quiet $run_name]] == 0} {
        create_ip_run $ip
    }
}
# BD-owned cores must be generated through the block design, not separately.
foreach bd [get_files -quiet */design_1.bd] {
    create_ip_run $bd
}
set sc_ip_runs [get_runs -quiet -filter {IS_SYNTHESIS && NAME != "synth_1"}]
puts "IP_SYNTHESIS_RUNS=[llength $sc_ip_runs]"
