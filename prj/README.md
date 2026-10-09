# Vivado project

`sixteen_camera.xpr` is the board-level integration project. Source membership
is reconciled with `../config/manifests/*_manifest.tcl` by `../setup_vivado.tcl`.
The checked-in SoC selection is the dual16 integration example.
`create_design_1.tcl` and the checked-in block design define the DDR platform.

Run `make check` from the repository root before opening the project. After
selecting another SoC, source `setup_vivado.tcl` again to reconcile membership.
Transient `*.runs`, `*.cache`, `*.gen` and other Vivado output directories are
build products; production inputs are defined by the manifests.
