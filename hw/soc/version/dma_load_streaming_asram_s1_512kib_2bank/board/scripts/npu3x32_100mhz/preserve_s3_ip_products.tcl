# scripts_only can invalidate the BD auto clock/width converter products.
# Preserve local products only while their complete XCI is byte-identical.
# These are inherited vendor IPs; no SoC netlist/checkpoint is reused.
proc s3_ip_products {mode root} {
    foreach ip {design_1_auto_cc_0 design_1_auto_us_0 design_1_auto_us_1} {
        set gen [file join $root prj sixteen_camera.gen sources_1 bd design_1 ip $ip]
        set xci [file join $root prj sixteen_camera.srcs sources_1 bd design_1 ip $ip ${ip}.xci]
        set saved [file join $root build s3_ip_products $ip]
        set names [list ${ip}.dcp ${ip}_stub.v ${ip}_stub.vhdl ${ip}_sim_netlist.v ${ip}_sim_netlist.vhdl]
        if {$mode eq "snapshot"} {
            set complete 1
            foreach name $names {if {![file isfile [file join $gen $name]]} {set complete 0}}
            if {$complete} {
                file mkdir $saved
                file copy -force $xci [file join $saved ${ip}.xci]
                foreach name $names {file copy -force [file join $gen $name] [file join $saved $name]}
            }
        } elseif {[file isfile [file join $saved ${ip}.xci]]} {
            set fd [open $xci rb]; set now [read $fd]; close $fd
            set fd [open [file join $saved ${ip}.xci] rb]; set original [read $fd]; close $fd
            if {$now eq $original} {
                foreach name $names {
                    if {![file isfile [file join $gen $name]]} {
                        file copy [file join $saved $name] [file join $gen $name]
                    }
                }
            }
        }
    }
}
