
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.



 #xpm_cdc sync paths
# set_false_path -to [get_pins -of [get_cells -hierarchical -filter {name=~*syncstages_ff_reg[0]}] -filter {REF_PIN_NAME == D}]
# set_false_path -to [get_cells -hierarchical *syncstages_ff_reg[0]*]
# set_false_path -to [get_pins -of [get_cells -hierarchical -filter {name=~*syncstages_ff_reg[*]}] -filter {REF_PIN_NAME == CLR}]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {name=~*arststages_ff_reg[*]}] -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *gt_usrclk_source_inst/*gtwiz_userclk_tx_active_*_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *gt_usrclk_source_inst/*gtwiz_userclk_rx_active_*_reg}]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *gt_usrclk_source_inst/*GT0_RX_MMCM_CLKOUT1_ODDR_INST}] -filter {REF_PIN_NAME=~D*}]

#set_false_path -from [get_cells -hierarchical -filter {NAME =~*DRP_Config_Reg_reg[*]}] -to [get_cells -hierarchical -filter {NAME =~*DRPDI_reg[*]}]
#set_false_path -from [get_cells -hierarchical -filter {NAME =~*DRP_Config_Reg_reg[*]}] -to [get_cells -hierarchical -filter {NAME =~*DRPADDR_reg[*]}]
#set_false_path -from [get_cells -hierarchical -filter {NAME =~*DRP_Config_Reg_reg[*]}] -to [get_cells -hierarchical -filter {NAME =~*DRPEN_reg}]
#set_false_path -from [get_cells -hierarchical -filter {NAME =~*DRP_Config_Reg_reg[*]}] -to [get_cells -hierarchical -filter {NAME =~*DRPWE_reg}]


set_false_path -from [get_cells -hierarchical -filter {name=~*/clock_detector_inst/clk_tx_freq_rst_reg && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hierarchical -filter {name=~*/clock_detector_inst/clk_rx_freq_rst_reg && IS_SEQUENTIAL}]





 	

          

create_waiver -type CDC -id CDC-13 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hier -filter {name=~ *vid_phy_controller*vid_phy_axi4lite_inst/slv_reg_0x158_reg[0]}] -filter {REF_PIN_NAME==C}]  -to [get_pins -of [get_cells -hier -filter {name=~ *gt_usrclk_source_inst/rx_mmcm.GT0_RX_MMCM_CLKOUT1_ODDR_INST}] -filter {REF_PIN_NAME==D[1]}]  -user "vid_phy_controller"


create_waiver -type CDC -id CDC-10 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hier -filter {name =~ *gt_wrapper_inst/inst/gen_gtwizard_gthe4_top.my_ip_gtwrapper_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_cpll_cal_gthe4.gen_cpll_cal_inst[0].gen_inst_cpll_cal.gtwizard_ultrascale*gthe4_cpll_cal_inst/gtwizard_ultrascale*gthe4_cpll_cal_rx_i/gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hier -filter {name =~ *gthe4_cpll_cal_rx_i/gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==D}]  -user "vid_phy_controller"


create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*xpm_array_single_rxpmaresetdone_b*_inst/syncstages_ff_reg[0]}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"  


create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*xpm_array_single_rxpmaresetdone_b*_inst/syncstages_ff_reg[0]}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"  


create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*xpm_array_single_rxpmaresetdone_b*_inst/syncstages_ff_reg[0]}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"  


create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gen_cal_rx_en.mask_user_in_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*xpm_array_single_rxpmaresetdone_b*_inst/syncstages_ff_reg[0]}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"  

 


create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *cfg_phy_mem_map_control_b0_reg[30]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*reset_synchronizer_resetin_rx_inst/rst_in_meta_reg}] -filter {REF_PIN_NAME==PRE}] -user "Video_Phy_Controller"  

create_waiver -type CDC -id CDC-10 -internal -scope -desc "CDC-10 waiver" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *cfg_phy_mem_map_control_b0_reg[30]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~*reset_synchronizer_resetin_tx_inst/rst_in_meta_reg}] -filter {REF_PIN_NAME==PRE}] -user "Video_Phy_Controller"

create_waiver -type CDC -id CDC-11 -internal -scope -desc "waiver for cdc-11" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gt3_txresetfsm_i/tx_fsm_reset_done_int_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ *gt3_txresetfsm_i/sync_tx_fsm_reset_done_int/data_sync_reg1}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"


create_waiver -type CDC -id CDC-11 -internal -scope -desc "waiver for cdc-11" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gt3_txresetfsm_i/tx_fsm_reset_done_int_reg}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ *TX_TMDSCLK_PATGEN_INST/RESET_IN_SYNC_INST/syncstages_ff_reg[0]}] -filter {REF_PIN_NAME==D}] -user "Video_Phy_Controller"   
    

create_waiver -type CDC -id CDC-13 -internal -scope -desc "waiver for cdc-13" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *xpm_array_single_DRU_CTRL_en*_inst/syncstages_ff_reg[2]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ *dru_b0gt*_inst/NIDRU_INST/Inst_dru/fnidru_1.Inst_pd/multOp}] -filter {REF_PIN_NAME==CEP}] -user "Video_Phy_Controller" 



#######  waivers for CDC-1   #########
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *xpm_array_single_DRU_CTRL_en*_inst/syncstages_ff_reg[*]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ */NIDRU_INST/*}] -filter {REF_PIN_NAME==D}] -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *xpm_array_single_DRU_CTRL_en*_inst/syncstages_ff_reg[*]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ */NIDRU_INST/*}] -filter {REF_PIN_NAME==CE}] -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *xpm_array_single_DRU_CTRL_in_sync_inst/syncstages_ff_reg[*][*]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ */NIDRU_INST/*}] -filter {REF_PIN_NAME==D}] -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *xpm_array_single_DRU_CTRL_in_sync_inst/syncstages_ff_reg[*][*]}] -filter {REF_PIN_NAME==C}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ */NIDRU_INST/*}] -filter {REF_PIN_NAME==CE}] -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gt_wrapper_inst/U0/my_ip_gtwrapper_i/gt*_my_ip_gtwrapper_i/gtpe2_i}] -filter {REF_PIN_NAME==RXUSRCLK2}] -to [get_pins -of [get_cells -hierarchical -filter {name=~ */NIDRU_INST/*}] -filter {REF_PIN_NAME==D}] -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gt_wrapper_inst/inst/gen_gtwizard_gt*_top.my_ip_gtwrapper_gtwizard_gt*_inst/gen_gtwizard_gt*.gen_channel_container[*].gen_enabled_channel.gt*_channel_wrapper_inst/channel_inst/gt*_channel_gen.gen_gt*_channel_inst[*].GT*_CHANNEL_PRIM_INST}] -filter {REF_PIN_NAME==RXUSRCLK2}]  -to [get_pins -of [get_cells -hierarchical -filter {name=~ *rx_sym_err_ch_gt*_reg[*]}] -filter {REF_PIN_NAME==D}]  -user "Vid_Phy_Controller"
create_waiver -type CDC -id CDC-1 -internal -scope -desc "waiver for cdc" -from [get_pins -of [get_cells -hierarchical -filter {name=~ *gt_wrapper_inst/inst/gen_gtwizard_gt*_top.my_ip_gtwrapper_gtwizard_gt*_inst/gen_gtwizard_gt*.gen_channel_container[*].gen_enabled_channel.gt*_channel_wrapper_inst/channel_inst/gt*_channel_gen.gen_gt*_channel_inst[*].GT*_CHANNEL_PRIM_INST}] -filter {REF_PIN_NAME==RXUSRCLK2}]  -to [get_pins -of [get_cells -hierarchical -filter {name=~ *rx_sym_err_ch_gt*_reg[*]}] -filter {REF_PIN_NAME==CE}]  -user "Vid_Phy_Controller"
