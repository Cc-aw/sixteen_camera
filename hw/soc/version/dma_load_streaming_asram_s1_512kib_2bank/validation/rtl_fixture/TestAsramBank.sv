module TestAsramBank #(parameter ID=0)(
input wire clock,reset,
input wire [2:0] service_opcode,
input wire service_valid,
output wire service_ready,
input wire [29:0] service_address,
input wire [255:0] service_data,
output wire service_response,
output wire [255:0] service_result,
output wire service_error,
output wire [6:0] pending_dma,pending_service,
output wire [63:0] accepted,retired,gets,puts,denied,
output wire  s_a_ready,
input wire  s_a_valid,
input wire [2:0] s_a_bits_opcode,
input wire [2:0] s_a_bits_param,
input wire [2:0] s_a_bits_size,
input wire [5:0] s_a_bits_source,
input wire [29:0] s_a_bits_address,
input wire [31:0] s_a_bits_mask,
input wire [255:0] s_a_bits_data,
input wire  s_a_bits_corrupt,
input wire  s_d_ready,
output wire  s_d_valid,
output wire [2:0] s_d_bits_opcode,
output wire [1:0] s_d_bits_param,
output wire [2:0] s_d_bits_size,
output wire [5:0] s_d_bits_source,
output wire  s_d_bits_sink,
output wire  s_d_bits_denied,
output wire [255:0] s_d_bits_data,
output wire  s_d_bits_corrupt);
wire [63:0] put_full,put_partial;assign puts=put_full+put_partial;
generate
if(ID==0)begin:b0
ActivationSramTL bank(.clock(clock),.reset(reset),.auto_port_in_1_a_ready(service_ready),.auto_port_in_1_a_valid(service_valid),.auto_port_in_1_a_bits_opcode(service_opcode),.auto_port_in_1_a_bits_param('0),.auto_port_in_1_a_bits_size(3'd5),.auto_port_in_1_a_bits_source(6'd31),.auto_port_in_1_a_bits_address(service_address),.auto_port_in_1_a_bits_mask(32'hffffffff),.auto_port_in_1_a_bits_data(service_data),.auto_port_in_1_a_bits_corrupt('0),.auto_port_in_1_d_ready(1'b1),.auto_port_in_1_d_valid(service_response),.auto_port_in_1_d_bits_opcode(),.auto_port_in_1_d_bits_param(),.auto_port_in_1_d_bits_size(),.auto_port_in_1_d_bits_source(),.auto_port_in_1_d_bits_sink(),.auto_port_in_1_d_bits_denied(service_error),.auto_port_in_1_d_bits_data(service_result),.auto_port_in_1_d_bits_corrupt(),.auto_port_in_0_a_ready(s_a_ready),.auto_port_in_0_a_valid(s_a_valid),.auto_port_in_0_a_bits_opcode(s_a_bits_opcode),.auto_port_in_0_a_bits_param(s_a_bits_param),.auto_port_in_0_a_bits_size(s_a_bits_size),.auto_port_in_0_a_bits_source(s_a_bits_source),.auto_port_in_0_a_bits_address(s_a_bits_address),.auto_port_in_0_a_bits_mask(s_a_bits_mask),.auto_port_in_0_a_bits_data(s_a_bits_data),.auto_port_in_0_a_bits_corrupt(s_a_bits_corrupt),.auto_port_in_0_d_ready(s_d_ready),.auto_port_in_0_d_valid(s_d_valid),.auto_port_in_0_d_bits_opcode(s_d_bits_opcode),.auto_port_in_0_d_bits_param(s_d_bits_param),.auto_port_in_0_d_bits_size(s_d_bits_size),.auto_port_in_0_d_bits_source(s_d_bits_source),.auto_port_in_0_d_bits_sink(s_d_bits_sink),.auto_port_in_0_d_bits_denied(s_d_bits_denied),.auto_port_in_0_d_bits_data(s_d_bits_data),.auto_port_in_0_d_bits_corrupt(s_d_bits_corrupt),.clear(1'b0),.counters_0_0(accepted),.counters_0_1(retired),.counters_0_2(gets),.counters_0_3(put_full),.counters_0_4(put_partial),.counters_0_5(),.counters_0_6(),.counters_0_7(),.counters_0_8(),.counters_0_9(),.counters_0_10(),.counters_0_11(),.counters_0_12(),.counters_0_13(),.counters_0_14(),.counters_0_15(denied),.counters_0_16(),.counters_0_17(),.counters_0_18(),.counters_0_19(),.counters_1_0(),.counters_1_1(),.counters_1_2(),.counters_1_3(),.counters_1_4(),.counters_1_5(),.counters_1_6(),.counters_1_7(),.counters_1_8(),.counters_1_9(),.counters_1_10(),.counters_1_11(),.counters_1_12(),.counters_1_13(),.counters_1_14(),.counters_1_15(),.counters_1_16(),.counters_1_17(),.counters_1_18(),.counters_1_19(),.outstanding_0(pending_dma),.outstanding_1(pending_service));
end else if(ID==1)begin:b1
ActivationSramTL_1 bank(.clock(clock),.reset(reset),.auto_port_in_1_a_ready(service_ready),.auto_port_in_1_a_valid(service_valid),.auto_port_in_1_a_bits_opcode(service_opcode),.auto_port_in_1_a_bits_param('0),.auto_port_in_1_a_bits_size(3'd5),.auto_port_in_1_a_bits_source(6'd31),.auto_port_in_1_a_bits_address(service_address),.auto_port_in_1_a_bits_mask(32'hffffffff),.auto_port_in_1_a_bits_data(service_data),.auto_port_in_1_a_bits_corrupt('0),.auto_port_in_1_d_ready(1'b1),.auto_port_in_1_d_valid(service_response),.auto_port_in_1_d_bits_opcode(),.auto_port_in_1_d_bits_param(),.auto_port_in_1_d_bits_size(),.auto_port_in_1_d_bits_source(),.auto_port_in_1_d_bits_sink(),.auto_port_in_1_d_bits_denied(service_error),.auto_port_in_1_d_bits_data(service_result),.auto_port_in_1_d_bits_corrupt(),.auto_port_in_0_a_ready(s_a_ready),.auto_port_in_0_a_valid(s_a_valid),.auto_port_in_0_a_bits_opcode(s_a_bits_opcode),.auto_port_in_0_a_bits_param(s_a_bits_param),.auto_port_in_0_a_bits_size(s_a_bits_size),.auto_port_in_0_a_bits_source(s_a_bits_source),.auto_port_in_0_a_bits_address(s_a_bits_address),.auto_port_in_0_a_bits_mask(s_a_bits_mask),.auto_port_in_0_a_bits_data(s_a_bits_data),.auto_port_in_0_a_bits_corrupt(s_a_bits_corrupt),.auto_port_in_0_d_ready(s_d_ready),.auto_port_in_0_d_valid(s_d_valid),.auto_port_in_0_d_bits_opcode(s_d_bits_opcode),.auto_port_in_0_d_bits_param(s_d_bits_param),.auto_port_in_0_d_bits_size(s_d_bits_size),.auto_port_in_0_d_bits_source(s_d_bits_source),.auto_port_in_0_d_bits_sink(s_d_bits_sink),.auto_port_in_0_d_bits_denied(s_d_bits_denied),.auto_port_in_0_d_bits_data(s_d_bits_data),.auto_port_in_0_d_bits_corrupt(s_d_bits_corrupt),.clear(1'b0),.counters_0_0(accepted),.counters_0_1(retired),.counters_0_2(gets),.counters_0_3(put_full),.counters_0_4(put_partial),.counters_0_5(),.counters_0_6(),.counters_0_7(),.counters_0_8(),.counters_0_9(),.counters_0_10(),.counters_0_11(),.counters_0_12(),.counters_0_13(),.counters_0_14(),.counters_0_15(denied),.counters_0_16(),.counters_0_17(),.counters_0_18(),.counters_0_19(),.counters_1_0(),.counters_1_1(),.counters_1_2(),.counters_1_3(),.counters_1_4(),.counters_1_5(),.counters_1_6(),.counters_1_7(),.counters_1_8(),.counters_1_9(),.counters_1_10(),.counters_1_11(),.counters_1_12(),.counters_1_13(),.counters_1_14(),.counters_1_15(),.counters_1_16(),.counters_1_17(),.counters_1_18(),.counters_1_19(),.outstanding_0(pending_dma),.outstanding_1(pending_service));
end else if(ID==2)begin:b2
ActivationSramTL_2 bank(.clock(clock),.reset(reset),.auto_port_in_1_a_ready(service_ready),.auto_port_in_1_a_valid(service_valid),.auto_port_in_1_a_bits_opcode(service_opcode),.auto_port_in_1_a_bits_param('0),.auto_port_in_1_a_bits_size(3'd5),.auto_port_in_1_a_bits_source(6'd31),.auto_port_in_1_a_bits_address(service_address),.auto_port_in_1_a_bits_mask(32'hffffffff),.auto_port_in_1_a_bits_data(service_data),.auto_port_in_1_a_bits_corrupt('0),.auto_port_in_1_d_ready(1'b1),.auto_port_in_1_d_valid(service_response),.auto_port_in_1_d_bits_opcode(),.auto_port_in_1_d_bits_param(),.auto_port_in_1_d_bits_size(),.auto_port_in_1_d_bits_source(),.auto_port_in_1_d_bits_sink(),.auto_port_in_1_d_bits_denied(service_error),.auto_port_in_1_d_bits_data(service_result),.auto_port_in_1_d_bits_corrupt(),.auto_port_in_0_a_ready(s_a_ready),.auto_port_in_0_a_valid(s_a_valid),.auto_port_in_0_a_bits_opcode(s_a_bits_opcode),.auto_port_in_0_a_bits_param(s_a_bits_param),.auto_port_in_0_a_bits_size(s_a_bits_size),.auto_port_in_0_a_bits_source(s_a_bits_source),.auto_port_in_0_a_bits_address(s_a_bits_address),.auto_port_in_0_a_bits_mask(s_a_bits_mask),.auto_port_in_0_a_bits_data(s_a_bits_data),.auto_port_in_0_a_bits_corrupt(s_a_bits_corrupt),.auto_port_in_0_d_ready(s_d_ready),.auto_port_in_0_d_valid(s_d_valid),.auto_port_in_0_d_bits_opcode(s_d_bits_opcode),.auto_port_in_0_d_bits_param(s_d_bits_param),.auto_port_in_0_d_bits_size(s_d_bits_size),.auto_port_in_0_d_bits_source(s_d_bits_source),.auto_port_in_0_d_bits_sink(s_d_bits_sink),.auto_port_in_0_d_bits_denied(s_d_bits_denied),.auto_port_in_0_d_bits_data(s_d_bits_data),.auto_port_in_0_d_bits_corrupt(s_d_bits_corrupt),.clear(1'b0),.counters_0_0(accepted),.counters_0_1(retired),.counters_0_2(gets),.counters_0_3(put_full),.counters_0_4(put_partial),.counters_0_5(),.counters_0_6(),.counters_0_7(),.counters_0_8(),.counters_0_9(),.counters_0_10(),.counters_0_11(),.counters_0_12(),.counters_0_13(),.counters_0_14(),.counters_0_15(denied),.counters_0_16(),.counters_0_17(),.counters_0_18(),.counters_0_19(),.counters_1_0(),.counters_1_1(),.counters_1_2(),.counters_1_3(),.counters_1_4(),.counters_1_5(),.counters_1_6(),.counters_1_7(),.counters_1_8(),.counters_1_9(),.counters_1_10(),.counters_1_11(),.counters_1_12(),.counters_1_13(),.counters_1_14(),.counters_1_15(),.counters_1_16(),.counters_1_17(),.counters_1_18(),.counters_1_19(),.outstanding_0(pending_dma),.outstanding_1(pending_service));
end
endgenerate
endmodule
