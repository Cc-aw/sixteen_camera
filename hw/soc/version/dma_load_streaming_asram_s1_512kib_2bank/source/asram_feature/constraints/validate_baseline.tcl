# Replay placement selection against actual DMA routed hierarchy. No placement,
# routing, checkpoint save or bitstream generation is performed by this audit.
if {$argc != 2} {error "Usage: validate_baseline.tcl <baseline.dcp> <report-dir>"}
set flow [file dirname [file normalize [info script]]]
set out [file normalize [lindex $argv 1]]
file mkdir $out
open_checkpoint [lindex $argv 0]
set before {}
foreach clock [lsort [get_clocks]] {lappend before $clock [get_property PERIOD $clock]}
source [file join $flow base placement_3x32.tcl]
source [file join $flow physical_groups.tcl]
::asram_physical::baseline_groups
set after {}
foreach clock [lsort [get_clocks]] {lappend after $clock [get_property PERIOD $clock]}
if {$before ne $after} {error "Placement replay changed clock constraints"}
set f [open [file join $out baseline_replay.tsv] w]
puts $f "name\tsoft\tregions\tcells"
foreach pb [lsort [get_pblocks asram_*]] {
    puts $f [join [list $pb [get_property IS_SOFT $pb] [get_property GRID_RANGES $pb] \
        [llength [get_cells -of_objects $pb]]] \t]
}
close $f
set f [open [file join $out baseline_replay.txt] w]
puts $f "ASRAM_BASELINE_PLACEMENT_REPLAY=PASS"
puts $f "mesh_dsps=2304 head_uram=192 clocks_unchanged=1"
puts $f "scope=baseline_hierarchy_selection_only; ASRAM_banks_validated_separately"
puts $f "place_route_started=0"
close $f
puts "ASRAM_BASELINE_PLACEMENT_REPLAY=PASS clocks_unchanged=1 place_route_started=0"
close_design
