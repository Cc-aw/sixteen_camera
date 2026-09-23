# Vivado project

`sixteen_camera.xpr` is the checked-in project entry point. Source membership
is reconciled with `../build/*_manifest.tcl` by `../setup_vivado.tcl`.
`create_design_1.tcl` and the checked-in block design define the DDR platform.

Transient `*.runs`, `*.cache`, `*.gen` and other Vivado output directories are
not authoritative repository sources. Run the manifest check before opening
the project; do not add legacy RTL or an archived SoC collateral tree directly
to `sources_1`.
