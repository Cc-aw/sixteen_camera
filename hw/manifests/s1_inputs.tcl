# Map the selected S1 package's frozen lists to repository-relative paths.
set s1_repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set S1_DIRECTORY hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank
source [file join $s1_repo $S1_DIRECTORY manifests donor rtl_manifest.tcl]
set s1_rtl {}
foreach name $RTL_SOURCES {lappend s1_rtl [file join $S1_DIRECTORY board $name]}
set RTL_SOURCES $s1_rtl
source [file join $s1_repo $S1_DIRECTORY manifests donor xdc_manifest.tcl]
set s1_xdc {}
foreach name $XDC_SOURCES {lappend s1_xdc [file join $S1_DIRECTORY board $name]}
set XDC_SOURCES $s1_xdc
set IP_SOURCES {}
foreach path [lsort [glob -directory [file join $s1_repo $S1_DIRECTORY board ip config] *.json]] {
    lappend IP_SOURCES [file join $S1_DIRECTORY board ip config [file tail $path]]
}
