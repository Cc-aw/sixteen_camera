###############################################################################
# CH4 OV7670 on ATK-FMC-EXTIO FMC2 / CAM3 physical-neat mapping, Bank 68
# External camera signals are translated between 3.3 V and FMC VADJ 1.8 V.
###############################################################################

set_property PACKAGE_PIN T34 [get_ports {cam_data[0]}]
set_property PACKAGE_PIN T35 [get_ports {cam_data[1]}]
set_property PACKAGE_PIN M37 [get_ports {cam_data[2]}]
set_property PACKAGE_PIN L38 [get_ports {cam_data[3]}]
set_property PACKAGE_PIN U35 [get_ports {cam_data[4]}]
set_property PACKAGE_PIN T36 [get_ports {cam_data[5]}]
set_property PACKAGE_PIN T30 [get_ports {cam_data[6]}]
set_property PACKAGE_PIN T31 [get_ports {cam_data[7]}]
set_property PACKAGE_PIN Y32 [get_ports cam_vsync]
set_property PACKAGE_PIN V33 [get_ports cam_href]
set_property PACKAGE_PIN T33 [get_ports cam_pclk]

set_property PACKAGE_PIN R33 [get_ports cam_xclk]
set_property PACKAGE_PIN V34 [get_ports cam_scl]
set_property PACKAGE_PIN W32 [get_ports cam_sda]
set_property PACKAGE_PIN R34 [get_ports cam_rst_n]
set_property PACKAGE_PIN V32 [get_ports cam_pwdn]

set_property IOSTANDARD LVCMOS18 [get_ports {cam_data[*]}]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {cam_vsync cam_href cam_pclk cam_xclk cam_scl cam_sda \
                cam_rst_n cam_pwdn}]

set_property DRIVE 8 [get_ports {cam_xclk cam_scl cam_rst_n cam_pwdn}]
set_property SLEW SLOW [get_ports {cam_xclk cam_scl cam_rst_n cam_pwdn}]
set_property PULLUP true [get_ports cam_sda]

# The observed sensor PCLK is about 29.2 MHz.  Use the P side of LA00_CC for
# this single-ended input, constrain it to 40 MHz, and place its explicit
# BUFGCE in the Bank 68 clock region for fully dedicated clock routing.
create_clock -name ov7670_pclk -period 25.000 [get_ports cam_pclk]
set_property LOC BUFGCE_X0Y192 [get_cells u_ov7670_pclk_bufg]
create_generated_clock -name ov7670_xclk \
    -source [get_pins -hierarchical -filter \
        {NAME =~ */u_ov7670_ctrl/sys_clk_reg/C}] \
    -divide_by 2 [get_ports cam_xclk]
