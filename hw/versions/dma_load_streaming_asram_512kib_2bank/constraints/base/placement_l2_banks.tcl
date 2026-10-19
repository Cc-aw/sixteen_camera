# Soft locality only. This does not constrain routing or relax timing.
set memory_v3_l2_guide_count 0
foreach {index slr} {0 SLR0 1 SLR2 2 SLR1 3 SLR3} {
    set bank inclusive_cache_bank_sched
    if {$index > 0} {append bank _$index}
    set bank_cell [get_cells -hier -quiet -filter "NAME =~ */coh_wrapper/l2/$bank"]
    if {$index >= 2 && [llength $bank_cell] == 0} {continue}
    if {[llength $bank_cell] != 1} {error "Expected one L2 bank hierarchy: $bank"}
    incr memory_v3_l2_guide_count
    set label memory_v3_l2_bank${index}_[string tolower $slr]
    set_property USER_SLR_ASSIGNMENT $slr $bank_cell
    if {![llength [get_pblocks -quiet $label]]} {create_pblock $label}
    resize_pblock [get_pblocks $label] -add $slr
    set_property IS_SOFT true [get_pblocks $label]
    set_property CONTAIN_ROUTING false [get_pblocks $label]
    add_cells_to_pblock [get_pblocks $label] $bank_cell
    puts "MEMORY_V3_L2_BANK_GUIDE bank=$bank slr=$slr soft=true"
}
if {$memory_v3_l2_guide_count ni {2 4}} {error "Expected two or four guided L2 banks"}
