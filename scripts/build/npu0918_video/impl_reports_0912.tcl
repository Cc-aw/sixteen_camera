proc legal_route {} {
  set text [report_route_status -return_string]
  set routable -1; set complete -2; set errors 0
  regexp {# of routable nets[^:]*:[[:space:]]*([0-9]+)} $text -> routable
  regexp {# of fully routed nets[^:]*:[[:space:]]*([0-9]+)} $text -> complete
  regexp {# of nets with routing errors[^:]*:[[:space:]]*([0-9]+)} $text -> errors
  return [expr {$errors == 0 && $routable > 0 && $complete == $routable}]
}

proc timing_metrics {} {
  set text [report_timing_summary -delay_type min_max -return_string]
  if {![regexp -line {^[ \t]*(-?[0-9]+\.[0-9]+)[ \t]+(-?[0-9]+\.[0-9]+)[ \t]+[0-9]+[ \t]+[0-9]+[ \t]+(-?[0-9]+\.[0-9]+)[ \t]+(-?[0-9]+\.[0-9]+)} $text -> wns tns whs ths]} {
    error "Could not parse full-design timing metrics"
  }
  return [list $wns $tns $whs $ths]
}

proc write_timing {results tag} {
  set text [report_timing_summary -delay_type min_max -return_string]
  set fd [open [file join $results ${tag}_timing.rpt] w]
  puts -nonewline $fd $text; close $fd
  puts "P0912_METRICS tag=$tag values=[timing_metrics]"
}

proc placed_resource_gate {results tag} {
  set text [report_utilization -return_string]
  set fd [open [file join $results ${tag}_utilization.rpt] w]
  puts -nonewline $fd $text; close $fd
  set marker [string first "SLR CLB Logic and Dedicated Block Utilization" $text]
  if {$marker < 0} { error "Could not find per-SLR utilization table" }
  set tail [string range $text $marker end]
  set violations {}
  foreach row {CLB {Block RAM Tile} URAM DSPs} limit {95.0 85.0 80.0 95.0} {
    # The SLR table has four absolute counts followed by four percentages.
    # Match all eight fields, rather than the earlier global-utilization row.
    # Vivado prints a nonzero-but-tiny percentage as "<0.01", so every
    # percentage field has to accept an optional leading "<".
    set pattern [format {\|[[:space:]]*%s[[:space:]]*\|[[:space:]]*[0-9.]+[[:space:]]*\|[[:space:]]*[0-9.]+[[:space:]]*\|[[:space:]]*[0-9.]+[[:space:]]*\|[[:space:]]*[0-9.]+[[:space:]]*\|[[:space:]]*(<?[0-9.]+)[[:space:]]*\|[[:space:]]*(<?[0-9.]+)[[:space:]]*\|[[:space:]]*(<?[0-9.]+)[[:space:]]*\|[[:space:]]*(<?[0-9.]+)[[:space:]]*\|} $row]
    if {![regexp $pattern $tail -> p0 p1 p2 p3]} { error "Could not parse per-SLR $row utilization" }
    puts "P0912_SLR_RESOURCE tag=$tag type=$row percent=$p0,$p1,$p2,$p3 limit=$limit"
    foreach p [list $p0 $p1 $p2 $p3] {
      # "<0.01" is below every gate; comparing it as a string would not be.
      if {[string index $p 0] eq "<"} { continue }
      if {$p > $limit} { lappend violations "$row $p > $limit" }
    }
  }
  # 四类资源全部量完再报。一轮 place 要一个多小时，不能因为 CLB 先超限就
  # 把 BRAM/URAM/DSP 的读数一起丢掉——下一轮调 floorplan 正需要它们。
  if {[llength $violations] == 0} { return }

  # 默认只告警不中断。95% 这条线是"布线延迟能健康"的目标值，不是可布线性
  # 的判据：0906 在 77.46/99.16/99.06/69.74 下 route 合法（WNS −7.347），
  # 0910 在 79.92/98.94/99.62/62.88 下失败，最高只差 0.46 个百分点——用它
  # 当硬闸是过度推断。而且现在 route 合法就一定出 bitstream，跑完能拿到可
  # 上板的比特流和完整报告，中途退出反而什么都没有。
  # 需要快速迭代 floorplan 时设 RESOURCE_GATE=enforce 换回提前退出。
  set mode warn
  if {[info exists ::env(RESOURCE_GATE)] && $::env(RESOURCE_GATE) ne ""} {
    set mode $::env(RESOURCE_GATE)
  }
  set summary "$tag exceeds the early-route target: [join $violations {; }]"
  if {$mode eq "enforce"} {
    error $summary
  }
  puts "WARN_P0912_RESOURCE_GATE=$summary (continuing; set RESOURCE_GATE=enforce to stop here)"
}

proc accepted {m} {
  lassign $m wns tns whs ths
  return [expr {$wns >= -2.0 && $tns >= -2.0 && $whs >= 0.0 && $ths >= 0.0}]
}

proc better {candidate baseline} {
  lassign $candidate cw ct cwh cth
  lassign $baseline bw bt bwh bth
  if {$cwh < 0.0 || $cth < 0.0} { return 0 }
  if {$bwh < 0.0 || $bth < 0.0} { return 1 }
  # Prefer WNS unless the two candidates are within 0.10 ns, where reducing
  # the enormous failing-endpoint population (TNS) has greater value.
  if {$cw > $bw + 0.10} { return 1 }
  if {$bw > $cw + 0.10} { return 0 }
  return [expr {$ct > $bt || ($ct == $bt && $cw > $bw)}]
}
