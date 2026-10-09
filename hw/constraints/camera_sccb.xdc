# The reference camera RTL actively drives SCCB high.  SDA remains bidirectional
# for ACK/read cycles, so provide an FPGA-side pull-up for the AXI IIC version.
set_property PULLUP true [get_ports cam_sda]
