
# This constraints file contains default clock frequencies to be used during out-of-context flows such as
# OOC Synthesis and Hierarchical Designs. For best results the frequencies should be modified
# to match the target frequencies. 
# This constraints file is not used in normal top-down synthesis (the default flow of Vivado)

#Project Device Family : virtexuplus
#Project Device SpeedGrade : -2
#Project Device PPC : 2


set clock_period 3.333

create_clock -name s_axi_cpu_aclk -period 10.0 [get_ports s_axi_cpu_aclk]
create_clock -name s_axis_audio_aclk -period 10.0 [get_ports s_axis_audio_aclk]
create_clock -name link_clk -period $clock_period [get_ports link_clk]
create_clock -name video_clk -period $clock_period [get_ports video_clk]
create_clock -name s_axis_video_aclk -period $clock_period [get_ports s_axis_video_aclk]




