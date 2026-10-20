# Private historical candidates retain their explicit board source lists.
if {([info exists ::env(ASRAM_CANDIDATE_CONTEXT)] && $::env(ASRAM_CANDIDATE_CONTEXT) ne "") ||
    ([info exists ::env(DMA_LOAD_CANDIDATE_CONTEXT)] && $::env(DMA_LOAD_CANDIDATE_CONTEXT) ne "")} {
    source [file join [file dirname [info script]] .. versions shared manifests xdc_manifest.tcl]
} else {
    source [file join [file dirname [info script]] s1_inputs.tcl]
}
