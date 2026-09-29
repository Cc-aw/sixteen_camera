set flow [file dirname [file normalize [info script]]]
source [file join $flow impl_reports_0918.tcl]
set baseline [parse_timing_0918 { -0.668 -2065.340 1200 3000000 0.009 0.000 0 3000000 }]
if {[target_met_0918 $baseline]} { error "0917 result incorrectly accepted" }

set pass $baseline
foreach {key value} {WNS 0.001 TNS 0.000 WHS 0.001 THS 0.000 HOLD_FAIL 0} {
  dict set pass $key $value
}
if {![target_met_0918 $pass]} { error "Positive-WNS, zero-TNS result rejected" }

foreach {key value} {WNS 0.000 TNS -0.001 WHS -0.001 THS -0.001 HOLD_FAIL 1} {
  set fail $pass
  dict set fail $key $value
  if {[target_met_0918 $fail]} { error "Invalid $key accepted" }
}

set better_wns $baseline
dict set better_wns WNS -0.600
if {![better_0918 $better_wns $baseline]} { error "Meaningful WNS improvement rejected" }
set better_tns $baseline
dict set better_tns WNS -0.660
dict set better_tns TNS -1000.000
if {![better_0918 $better_tns $baseline]} { error "TNS tie breaker rejected" }
if {![better_0918 $pass $better_wns]} { error "Closed candidate must beat violating candidate" }

puts "NPU_0918_TIMING_GATE=PASS"

# Exercise the placement selection without launching Vivado or synthesis.
set mock_rocket top/u_control_soc/u_rocket/dut/tile
set mock_dsps {top/u_video_pipeline/other_DSP}
foreach inst {applyOrElse applyOrElse_1 applyOrElse_2} {
    for {set r 0} {$r < 64} {incr r} {
        for {set c 0} {$c < 8} {incr c} {
            set count [expr {($r+$c)%2 ? 4 : 8}]
            for {set d 0} {$d < $count} {incr d} {
                lappend mock_dsps $mock_rocket/$inst/ex_controller/mesh/mesh/mesh_${r}_${c}/lane$d
            }
        }
    }
}
set mock_period 10.0
proc get_cells {args} {
    if {[lindex $args end] eq "REF_NAME == RocketTile"} { return $::mock_rocket }
    return $::mock_dsps
}
proc get_pins {args} {
    if {[lsearch -exact $args -of_objects] < 0} {
        error "Clock audit must query input objects, not an RTL port name"
    }
    return renamed_clock_pin
}
set mock_clocks soc_clock
proc get_clocks {args} { return $::mock_clocks }
proc get_property {prop object} {
    if {$prop eq "PERIOD"} { return $::mock_period }
    return $object
}
proc get_pblocks {args} { return [lindex $args end] }
proc create_pblock {args} {}
proc set_property {args} {}
proc resize_pblock {block flag slr} { dict set ::blocks $block $slr }
proc add_cells_to_pblock {block cells} {
    dict incr ::slr_counts [dict get $::blocks $block] [llength $cells]
    foreach cell $cells {
        if {[dict exists $::seen $cell]} { error "DSP assigned twice" }
        dict set ::seen $cell 1
    }
}
set blocks {};set slr_counts {};set seen {}
source [file join $flow placement_0918_video.tcl]
foreach slr {SLR0 SLR1 SLR2 SLR3} expected {2688 1152 2688 2688} {
    if {[dict get $slr_counts $slr] != $expected} { error "Wrong DSP split for $slr" }
}
if {[dict size $seen] != 9216} { error "Wrong total constrained DSPs" }
set mock_period 4.0
if {![catch {source [file join $flow placement_0918_video.tcl]} msg] ||
    ![string match *100*MHz* $msg]} { error "250 MHz configuration accepted" }
set mock_period 10.0
set mock_clocks {}
if {![catch {source [file join $flow placement_0918_video.tcl]} msg] ||
    ![string match *unconstrained* $msg]} { error "Unconstrained clock accepted" }
set mock_clocks soc_clock
set mock_dsps [lrange $mock_dsps 0 end-1]
if {![catch {source [file join $flow placement_0918_video.tcl]} msg] ||
    ![string match *Expected*DSPs* $msg]} { error "Broken mesh accepted" }
puts "NPU0918_VIDEO_FLOW_TEST=PASS split=56/24/56/56 invalid_clock_and_mesh_rejected"
