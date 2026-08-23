###############################################################################

###############################################################################
# Board clock and reset
###############################################################################

create_clock -period 40.000 [get_ports clk_25m]

set_property IOSTANDARD LVCMOS18 [get_ports clk_25m]
set_property PACKAGE_PIN AM33 [get_ports clk_25m]

set_property IOSTANDARD LVCMOS18 [get_ports sys_rstn]
set_property PACKAGE_PIN AM24 [get_ports sys_rstn]

# set_property IOSTANDARD LVCMOS18 [get_ports conf_done1]
# set_property IOSTANDARD LVCMOS18 [get_ports conf_done2]
set_property IOSTANDARD LVCMOS18 [get_ports si5338_scl1]
set_property IOSTANDARD LVCMOS18 [get_ports si5338_scl2]
set_property IOSTANDARD LVCMOS18 [get_ports si5338_sda1]
set_property IOSTANDARD LVCMOS18 [get_ports si5338_sda2]

# set_property PACKAGE_PIN AL24 [get_ports conf_done1]
# set_property PACKAGE_PIN AL21 [get_ports conf_done2]
set_property PACKAGE_PIN AP38 [get_ports si5338_scl1]
set_property PACKAGE_PIN AT35 [get_ports si5338_scl2]
set_property PACKAGE_PIN AR38 [get_ports si5338_sda1]
set_property PACKAGE_PIN AT36 [get_ports si5338_sda2]

create_clock -period 10.000 -name clk_100m_p [get_ports clk_100m_p]

# Chipyard exposes its RISC-V JTAG TAP through Xilinx USER4 BSCAN.  The
# generated JTAGTUNNEL contains state and edge counters clocked directly from
# BSCANE2/INTERNAL_TCK, followed by a BUFGCE for the inner TAP.  Without a
# clock on this root Vivado leaves the complete tunnel untimed; a harmless
# full-design reroute can then create same-edge SHIFT-to-counter hold failures
# and corrupt DTMCS scans.  OpenOCD normally runs this tunnel at 15 MHz.
create_clock -name rocket_bscan_tck -period 66.667 \
    -waveform {0.000 33.333} \
    [get_pins -hierarchical -filter \
        {NAME =~ */inst_jtag_tunnel/bscane2/INTERNAL_TCK}]

# The Rocket debug transport crosses between JTAG TCK and the 100 MHz SoC
# clock through generated asynchronous queues and reset synchronizers.  Keep
# those CDC paths asynchronous while fully timing every path contained inside
# the BSCAN/JTAG domain itself.
set_clock_groups -asynchronous \
    -group [get_clocks rocket_bscan_tck] \
    -group [get_clocks clk_100m_p]

set_property PACKAGE_PIN AY24 [get_ports clk_100m_p]
set_property PACKAGE_PIN AY23 [get_ports clk_100m_n]
set_property IOSTANDARD LVDS [get_ports clk_100m_p]
set_property IOSTANDARD LVDS [get_ports clk_100m_n]

# Rocket UART, 115200 baud at the configured 100 MHz SoC clock.
set_property PACKAGE_PIN AJ31 [get_ports uart_rxd]
set_property PACKAGE_PIN AL31 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS18 [get_ports {uart_rxd uart_txd}]

 # DDR calibration status crosses asynchronously into the 100 MHz SoC domain.
set_false_path -to [get_pins {u_control_soc/ddr_calib_sync_reg[0]/D}]

set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ */u_video_framebuffer/u_control/ack_sync_1_reg/D}]

# These are asynchronous-assert/synchronous-release reset synchronizers.
# Their CLR pins intentionally accept reset assertion from another clock
# domain; timing the recovery/removal arc to the asynchronous source would
# report the reset transition rather than the synchronized release path.
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ *u_camera_cdc/ddr_resetn_cam_sync_reg*/CLR}]

# The functional oversampling receiver treats every DVP signal, including
# PCLK, as asynchronous data into a 300 MHz IOB register.  Only the pad to the
# first IOB stage is excluded; all IOB-to-second-stage and 300 MHz functional
# paths remain fully timed.
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ *dvp_data_iob_reg*/D || \
     NAME =~ *dvp_href_iob_reg/D || \
     NAME =~ *dvp_vsync_iob_reg/D || \
     NAME =~ *dvp_pclk_iob_reg/D}]

# The raw DVP and output-pad probes are sampled through explicit two-stage
# synchronizers in the 100 MHz diagnostic domain.  Time only the second stage;
# the asynchronous source-to-first-stage arcs are CDC paths by construction.
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ *sample_sync_1_reg*/D}]
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ *pad_sync_1_reg*/D}]

# Camera control and diagnostic requests cross into the 300 MHz capture domain
# through explicit two-stage synchronizers.  Only their first-stage D pins are
# asynchronous; the second stage remains normally timed so placement still
# maximizes synchronizer resolution time.  Keep these endpoint-specific rather
# than declaring the complete 24/100/300 MHz clock domains asynchronous.
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ */capture_enable_sync1_reg/D || \
     NAME =~ */recovery_sample_offset_sync1_reg*/D || \
     NAME =~ */diag_clear_video_sync1_reg/D || \
     NAME =~ */stats_snapshot_video_sync1_reg/D || \
     NAME =~ *u_camera_cdc/diag_clear_sync1_reg/D || \
     NAME =~ *u_camera_stream/diag_clear_sync1_reg/D}]

# Each OV7670 frontend publishes a 32-bit geometry snapshot together with a
# toggle. The source values change only once per completed frame and remain
# stable while the toggle passes through two AXI-clock synchronizer stages;
# the destination waits one additional AXI clock before consuming the bus.
# Suppress the meaningless asynchronous clock-phase setup/hold checks only at
# each first-stage synchronizer. ASYNC_REG placement keeps both stages local;
# the frame-long source stability and delayed toggle capture provide the
# bundled-data settling interval.
set_false_path \
    -to [get_pins -hierarchical -filter \
        {NAME =~ */geometry_data_sync1_reg*/D || \
         NAME =~ */geometry_toggle_sync1_reg/D}]

# The framebuffer control interface uses a bundled-data request/acknowledge
# CDC. Configuration registers are held unchanged while cfg_request_toggle
# differs from the returned acknowledgement.  The request passes through two
# UI-clock synchronizer stages, so keep an explicit 10 ns propagation budget
# for the bundled data rather than applying the unrelated 100 MHz to 300 MHz
# setup relationship.
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ */u_video_framebuffer/u_manager/cfg_sync_1_reg/D}]
set_false_path -to [get_pins -hierarchical -filter \
    {NAME =~ */u_video_framebuffer/u_manager/select_sync_1_reg*/D}]
set_max_delay -datapath_only 10.000 \
    -from [get_cells -hierarchical -filter \
        {NAME =~ */u_video_framebuffer/u_control/cfg_*_reg*}] \
    -to [get_cells -hierarchical -filter \
        {NAME =~ */u_video_framebuffer/u_manager/*}]

# OV7670 controller diagnostics are asynchronous snapshots transferred by
# u_ctrl_diag_cdc into the AXI-Lite clock domain. Physical optimization may
# replicate and rename the XPM stages, so constrain the source clock and the
# diagnostic readback endpoints instead of depending on generated cell names.
set_false_path \
    -from [get_clocks clk_out1_clk_wiz_ov7670] \
    -to [get_pins -hierarchical -filter \
        {NAME =~ */u_diagnostics/rdata_reg*/D}]
