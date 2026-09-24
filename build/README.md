# Production source manifests

`rtl_manifest.tcl` is the whitelist for hand-written synthesis RTL. The IP,
SoC and XDC manifests select their corresponding production inputs. The
archived `legacy/` tree and alternative generated SoC collateral are not
included in the project.

Before opening Vivado, run `tclsh scripts/check_production_manifest.tcl`.
Then open `prj/sixteen_camera.xpr` and source `setup_vivado.tcl` to reconcile
the project with these manifests. A lightweight top-level RTL elaboration is
available through `scripts/check_tensor_production_elaboration.tcl`; it does
not run implementation or bitstream generation.
