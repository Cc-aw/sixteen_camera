source [file join [file dirname [file normalize [info script]]] impl_reports_0912.tcl]

proc check_source_slr_hints_0918 {} {
  set rockets [get_cells -hier -quiet -filter {REF_NAME == RocketTile}]
  if {[llength $rockets] != 1} { error "Expected one RocketTile for the 0918 SLR audit" }
  set root [get_property NAME $rockets]
  foreach instance {applyOrElse applyOrElse_1 applyOrElse_2} expected {SLR0 SLR2 SLR3} {
    set cell [get_cells -quiet ${root}/${instance}/spad]
    if {[llength $cell] != 1} { error "Missing preserved Scratchpad hierarchy for $instance" }
    set hint [get_property USER_SLR_ASSIGNMENT $cell]
    if {$hint ne $expected} { error "Lost Scala SLR hint: $instance expected $expected, found '$hint'" }
    puts "NPU0918_SOURCE_SLR_HINT instance=$instance value=$hint"
  }
}

proc parse_timing_0918 {text} {
  set pattern {^[ \t]*(-?[0-9]+\.[0-9]+)[ \t]+(-?[0-9]+\.[0-9]+)[ \t]+([0-9]+)[ \t]+([0-9]+)[ \t]+(-?[0-9]+\.[0-9]+)[ \t]+(-?[0-9]+\.[0-9]+)[ \t]+([0-9]+)[ \t]+([0-9]+)}
  if {![regexp -line $pattern $text -> wns tns sf st whs ths hf ht]} {
    error "Cannot parse the full-design timing summary"
  }
  return [dict create WNS $wns TNS $tns SETUP_FAIL $sf SETUP_TOTAL $st \
    WHS $whs THS $ths HOLD_FAIL $hf HOLD_TOTAL $ht]
}

proc hold_clean_0918 {m} {
  return [expr {[dict get $m WHS] >= 0 && [dict get $m THS] == 0 && [dict get $m HOLD_FAIL] == 0}]
}

proc target_met_0918 {m} {
  return [expr {[hold_clean_0918 $m] && [dict get $m WNS] > 0.0 && [dict get $m TNS] == 0.0}]
}

# Legality is checked by the caller. Among legal candidates, never trade away
# clean hold or the acceptance target. Before setup closure, improve WNS first
# outside a small reporting-noise band, then use TNS as the tie breaker.
proc better_0918 {candidate previous} {
  set ch [hold_clean_0918 $candidate]
  set ph [hold_clean_0918 $previous]
  if {$ch != $ph} { return $ch }
  if {!$ch} {
    set cf [dict get $candidate HOLD_FAIL]
    set pf [dict get $previous HOLD_FAIL]
    if {$cf != $pf} { return [expr {$cf < $pf}] }
    set ct [dict get $candidate THS]
    set pt [dict get $previous THS]
    if {$ct != $pt} { return [expr {$ct > $pt}] }
    return [expr {[dict get $candidate WHS] > [dict get $previous WHS]}]
  }
  set ct [target_met_0918 $candidate]
  set pt [target_met_0918 $previous]
  if {$ct != $pt} { return $ct }
  set cw [dict get $candidate WNS]
  set pw [dict get $previous WNS]
  if {$cw > $pw + 0.02} { return 1 }
  if {$pw > $cw + 0.02} { return 0 }
  return [expr {[dict get $candidate TNS] > [dict get $previous TNS]}]
}

proc report_stage_0918 {results tag} {
  set summary [report_timing_summary -delay_type min_max -max_paths 3 -return_string]
  set fd [open [file join $results ${tag}_timing.rpt] w]
  puts -nonewline $fd $summary
  close $fd
  report_route_status -file [file join $results ${tag}_route_status.rpt]
  set m [parse_timing_0918 $summary]
  puts "NPU0918_METRICS tag=$tag WNS=[dict get $m WNS] TNS=[dict get $m TNS] WHS=[dict get $m WHS] THS=[dict get $m THS] HOLD_FAIL=[dict get $m HOLD_FAIL]"
  return $m
}

proc repair_hold_0918 {results tag} {
  set m [report_stage_0918 $results ${tag}_before]
  if {[hold_clean_0918 $m]} { return $m }
  set best_metrics $m
  set best_checkpoint [file join $results ${tag}_before.dcp]
  write_checkpoint -force $best_checkpoint
  foreach option {-sll_reg_hold_fix -aggressive_hold_fix} step {sll general} {
    set failed [catch {phys_opt_design $option} message]
    puts "NPU0918_HOLD_OPERATION option=$option failed=$failed message=$message"
    if {![legal_route]} {
      set route_failed [catch {route_design -directive Default -tns_cleanup} route_message]
      puts "NPU0918_HOLD_REROUTE directive=Default failed=$route_failed message=$route_message"
    }
    set m [report_stage_0918 $results ${tag}_${step}]
    set checkpoint [file join $results ${tag}_${step}.dcp]
    write_checkpoint -force $checkpoint
    if {[legal_route] && [better_0918 $m $best_metrics]} {
      set best_checkpoint $checkpoint
      set best_metrics $m
    }
    if {[legal_route] && [hold_clean_0918 $m]} { break }
    close_design
    open_checkpoint $best_checkpoint
  }
  close_design
  open_checkpoint $best_checkpoint
  return $best_metrics
}
