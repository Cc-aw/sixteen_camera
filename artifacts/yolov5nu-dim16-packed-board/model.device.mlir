module attributes {gemcc.workspace_bytes = 31800256 : i64, gemcc.memory_plan = "{\"version\":1,\"kind\":\"gemcc-memory-plan\",\"workspace_bytes\":31800256,\"alignment\":64,\"buffers\":[{\"name\":\"/model.24/Add_output_0\",\"space\":\"host\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"/model.24/Div_output_0\",\"space\":\"host\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"/model.24/Gather_output_0\",\"space\":\"host\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"/model.24/Mul_1_output_0\",\"space\":\"host\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"/model.24/Mul_output_0\",\"space\":\"host\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"/model.24/Shape_output_0\",\"space\":\"host\",\"nbytes\":24,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":null,\"note\":\"control/shape, not a DDR activation\"},{\"name\":\"model.0.conv.bias\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":0,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.0.conv.weight\",\"space\":\"constants\",\"nbytes\":6912,\"alignment\":64,\"birth\":-1,\"death\":0,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":3,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.1.conv.weight\",\"space\":\"constants\",\"nbytes\":18432,\"alignment\":64,\"birth\":-1,\"death\":3,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.10.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":114,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.10.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":114,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":120,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":120,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":129,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":129,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":133,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":133,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":123,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":123,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":126,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.13.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":126,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.14.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":136,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.14.conv.weight\",\"space\":\"constants\",\"nbytes\":32768,\"alignment\":64,\"birth\":-1,\"death\":136,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":142,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":142,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":151,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":151,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":155,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":155,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":145,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":4096,\"alignment\":64,\"birth\":-1,\"death\":145,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":148,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.17.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":36864,\"alignment\":64,\"birth\":-1,\"death\":148,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.18.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":158,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.18.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":158,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":6,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":2048,\"alignment\":64,\"birth\":-1,\"death\":6,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":16,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":2048,\"alignment\":64,\"birth\":-1,\"death\":16,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":20,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":4096,\"alignment\":64,\"birth\":-1,\"death\":20,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":9,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":1024,\"alignment\":64,\"birth\":-1,\"death\":9,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":12,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.2.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":9216,\"alignment\":64,\"birth\":-1,\"death\":12,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":162,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":32768,\"alignment\":64,\"birth\":-1,\"death\":162,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":171,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":32768,\"alignment\":64,\"birth\":-1,\"death\":171,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":175,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":175,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":165,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":165,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":168,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.20.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":168,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.21.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":178,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.21.conv.weight\",\"space\":\"constants\",\"nbytes\":589824,\"alignment\":64,\"birth\":-1,\"death\":178,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":182,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":182,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":191,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":191,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":1024,\"alignment\":64,\"birth\":-1,\"death\":195,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":262144,\"alignment\":64,\"birth\":-1,\"death\":195,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":185,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":185,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":188,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.23.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":589824,\"alignment\":64,\"birth\":-1,\"death\":188,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.0.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":198,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.0.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":198,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":201,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.1.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":201,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.2.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":204,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.0.2.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":204,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.0.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":209,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.0.conv.weight\",\"space\":\"constants\",\"nbytes\":294912,\"alignment\":64,\"birth\":-1,\"death\":209,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":212,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.1.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":212,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.2.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":215,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.1.2.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":215,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.0.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":217,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.0.conv.weight\",\"space\":\"constants\",\"nbytes\":589824,\"alignment\":64,\"birth\":-1,\"death\":217,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":220,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.1.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":220,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.2.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":223,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv2.2.2.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":223,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.0.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":226,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.0.conv.weight\",\"space\":\"constants\",\"nbytes\":184320,\"alignment\":64,\"birth\":-1,\"death\":226,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.1.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":229,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.1.conv.weight\",\"space\":\"constants\",\"nbytes\":230400,\"alignment\":64,\"birth\":-1,\"death\":229,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.2.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":232,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.0.2.weight\",\"space\":\"constants\",\"nbytes\":25600,\"alignment\":64,\"birth\":-1,\"death\":232,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.0.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":237,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.0.conv.weight\",\"space\":\"constants\",\"nbytes\":368640,\"alignment\":64,\"birth\":-1,\"death\":237,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.1.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":240,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.1.conv.weight\",\"space\":\"constants\",\"nbytes\":230400,\"alignment\":64,\"birth\":-1,\"death\":240,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.2.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":243,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.1.2.weight\",\"space\":\"constants\",\"nbytes\":25600,\"alignment\":64,\"birth\":-1,\"death\":243,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.0.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":245,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.0.conv.weight\",\"space\":\"constants\",\"nbytes\":737280,\"alignment\":64,\"birth\":-1,\"death\":245,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.1.conv.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":248,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.1.conv.weight\",\"space\":\"constants\",\"nbytes\":230400,\"alignment\":64,\"birth\":-1,\"death\":248,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.2.bias\",\"space\":\"constants\",\"nbytes\":320,\"alignment\":64,\"birth\":-1,\"death\":251,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.cv3.2.2.weight\",\"space\":\"constants\",\"nbytes\":25600,\"alignment\":64,\"birth\":-1,\"death\":251,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.24.dfl.conv.weight\",\"space\":\"constants\",\"nbytes\":64,\"alignment\":64,\"birth\":-1,\"death\":258,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.3.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":23,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.3.conv.weight\",\"space\":\"constants\",\"nbytes\":73728,\"alignment\":64,\"birth\":-1,\"death\":23,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":26,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":8192,\"alignment\":64,\"birth\":-1,\"death\":26,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":43,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":8192,\"alignment\":64,\"birth\":-1,\"death\":43,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":47,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":47,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":29,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":4096,\"alignment\":64,\"birth\":-1,\"death\":29,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":32,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":36864,\"alignment\":64,\"birth\":-1,\"death\":32,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.1.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":36,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.1.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":4096,\"alignment\":64,\"birth\":-1,\"death\":36,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.1.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":128,\"alignment\":64,\"birth\":-1,\"death\":39,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.4.m.1.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":36864,\"alignment\":64,\"birth\":-1,\"death\":39,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.5.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":50,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.5.conv.weight\",\"space\":\"constants\",\"nbytes\":294912,\"alignment\":64,\"birth\":-1,\"death\":50,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":53,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":32768,\"alignment\":64,\"birth\":-1,\"death\":53,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":77,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":32768,\"alignment\":64,\"birth\":-1,\"death\":77,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":81,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":81,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":56,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":56,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":59,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":59,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.1.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":63,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.1.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":63,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.1.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":66,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.1.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":66,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.2.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":70,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.2.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":16384,\"alignment\":64,\"birth\":-1,\"death\":70,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.2.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":256,\"alignment\":64,\"birth\":-1,\"death\":73,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.6.m.2.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":147456,\"alignment\":64,\"birth\":-1,\"death\":73,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.7.conv.bias\",\"space\":\"constants\",\"nbytes\":1024,\"alignment\":64,\"birth\":-1,\"death\":84,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.7.conv.weight\",\"space\":\"constants\",\"nbytes\":1179648,\"alignment\":64,\"birth\":-1,\"death\":84,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":87,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":87,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":97,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":97,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv3.conv.bias\",\"space\":\"constants\",\"nbytes\":1024,\"alignment\":64,\"birth\":-1,\"death\":101,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.cv3.conv.weight\",\"space\":\"constants\",\"nbytes\":262144,\"alignment\":64,\"birth\":-1,\"death\":101,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.m.0.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":90,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.m.0.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":65536,\"alignment\":64,\"birth\":-1,\"death\":90,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.m.0.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":93,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.8.m.0.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":589824,\"alignment\":64,\"birth\":-1,\"death\":93,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.9.cv1.conv.bias\",\"space\":\"constants\",\"nbytes\":512,\"alignment\":64,\"birth\":-1,\"death\":104,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.9.cv1.conv.weight\",\"space\":\"constants\",\"nbytes\":131072,\"alignment\":64,\"birth\":-1,\"death\":104,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.9.cv2.conv.bias\",\"space\":\"constants\",\"nbytes\":1024,\"alignment\":64,\"birth\":-1,\"death\":111,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"model.9.cv2.conv.weight\",\"space\":\"constants\",\"nbytes\":524288,\"alignment\":64,\"birth\":-1,\"death\":111,\"ddr_offset\":null,\"note\":\"packed in constants.bin\"},{\"name\":\"/model.24/Constant_10_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":0,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_11_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":64,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_8_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":128,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_9_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":-1,\"death\":-1,\"ddr_offset\":192,\"note\":\"activation/workspace\"},{\"name\":\"images\",\"space\":\"ddr\",\"nbytes\":921600,\"alignment\":64,\"birth\":-1,\"death\":0,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":4915200,\"alignment\":64,\"birth\":0,\"death\":2,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":4915200,\"alignment\":64,\"birth\":1,\"death\":2,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":2,\"death\":3,\"ddr_offset\":10752256,\"note\":\"activation/workspace\"},{\"name\":\"/model.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":2457600,\"alignment\":64,\"birth\":3,\"death\":5,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":2457600,\"alignment\":64,\"birth\":4,\"death\":5,\"ddr_offset\":3379456,\"note\":\"activation/workspace\"},{\"name\":\"/model.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":5,\"death\":16,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":6,\"death\":8,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":7,\"death\":8,\"ddr_offset\":7065856,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":8,\"death\":15,\"ddr_offset\":614656,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":9,\"death\":11,\"ddr_offset\":8294656,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":10,\"death\":11,\"ddr_offset\":9523456,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":11,\"death\":12,\"ddr_offset\":10752256,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":12,\"death\":14,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":13,\"death\":14,\"ddr_offset\":2150656,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":14,\"death\":15,\"ddr_offset\":11059456,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/m/m.0/Add_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":15,\"death\":19,\"ddr_offset\":11366656,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":16,\"death\":18,\"ddr_offset\":3379456,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":17,\"death\":18,\"ddr_offset\":4608256,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":18,\"death\":19,\"ddr_offset\":11673856,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":19,\"death\":20,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":2457600,\"alignment\":64,\"birth\":20,\"death\":22,\"ddr_offset\":11981056,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":2457600,\"alignment\":64,\"birth\":21,\"death\":22,\"ddr_offset\":14438656,\"note\":\"activation/workspace\"},{\"name\":\"/model.2/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":22,\"death\":23,\"ddr_offset\":6451456,\"note\":\"activation/workspace\"},{\"name\":\"/model.3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":23,\"death\":25,\"ddr_offset\":7065856,\"note\":\"activation/workspace\"},{\"name\":\"/model.3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":24,\"death\":25,\"ddr_offset\":8294656,\"note\":\"activation/workspace\"},{\"name\":\"/model.3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":25,\"death\":43,\"ddr_offset\":9523456,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":26,\"death\":28,\"ddr_offset\":9830656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":27,\"death\":28,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":28,\"death\":35,\"ddr_offset\":10445056,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":29,\"death\":31,\"ddr_offset\":1536256,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":30,\"death\":31,\"ddr_offset\":2150656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":31,\"death\":32,\"ddr_offset\":10598656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":32,\"death\":34,\"ddr_offset\":2765056,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":33,\"death\":34,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":34,\"death\":35,\"ddr_offset\":10752256,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.0/Add_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":35,\"death\":42,\"ddr_offset\":10905856,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":36,\"death\":38,\"ddr_offset\":3379456,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":37,\"death\":38,\"ddr_offset\":3993856,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":38,\"death\":39,\"ddr_offset\":614656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":39,\"death\":41,\"ddr_offset\":4608256,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":40,\"death\":41,\"ddr_offset\":5222656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":41,\"death\":42,\"ddr_offset\":768256,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/m/m.1/Add_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":42,\"death\":46,\"ddr_offset\":11059456,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":43,\"death\":45,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":44,\"death\":45,\"ddr_offset\":11981056,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":45,\"death\":46,\"ddr_offset\":11213056,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":46,\"death\":47,\"ddr_offset\":11366656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":47,\"death\":49,\"ddr_offset\":12595456,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":48,\"death\":49,\"ddr_offset\":14438656,\"note\":\"activation/workspace\"},{\"name\":\"/model.4/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":49,\"death\":141,\"ddr_offset\":11673856,\"note\":\"activation/workspace\"},{\"name\":\"/model.5/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":50,\"death\":52,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.5/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":51,\"death\":52,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.5/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":52,\"death\":77,\"ddr_offset\":16281856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":53,\"death\":55,\"ddr_offset\":16435456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":54,\"death\":55,\"ddr_offset\":6451456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":55,\"death\":62,\"ddr_offset\":16742656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":56,\"death\":58,\"ddr_offset\":6758656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":57,\"death\":58,\"ddr_offset\":7065856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":58,\"death\":59,\"ddr_offset\":16819456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":59,\"death\":61,\"ddr_offset\":7373056,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":60,\"death\":61,\"ddr_offset\":7680256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":61,\"death\":62,\"ddr_offset\":7987456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.0/Add_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":62,\"death\":69,\"ddr_offset\":8064256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":63,\"death\":65,\"ddr_offset\":8294656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":64,\"death\":65,\"ddr_offset\":8601856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":65,\"death\":66,\"ddr_offset\":8141056,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":66,\"death\":68,\"ddr_offset\":8909056,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":67,\"death\":68,\"ddr_offset\":9216256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":68,\"death\":69,\"ddr_offset\":8217856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.1/Add_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":69,\"death\":76,\"ddr_offset\":9830656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":70,\"death\":72,\"ddr_offset\":9907456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":71,\"death\":72,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":72,\"death\":73,\"ddr_offset\":10214656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":73,\"death\":75,\"ddr_offset\":1229056,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":74,\"death\":75,\"ddr_offset\":1536256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":75,\"death\":76,\"ddr_offset\":10291456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/m/m.2/Add_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":76,\"death\":80,\"ddr_offset\":10368256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":77,\"death\":79,\"ddr_offset\":1843456,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":78,\"death\":79,\"ddr_offset\":2150656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":79,\"death\":80,\"ddr_offset\":2457856,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":80,\"death\":81,\"ddr_offset\":2534656,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":81,\"death\":83,\"ddr_offset\":2765056,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":82,\"death\":83,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.6/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":83,\"death\":119,\"ddr_offset\":10598656,\"note\":\"activation/workspace\"},{\"name\":\"/model.7/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":84,\"death\":86,\"ddr_offset\":3379456,\"note\":\"activation/workspace\"},{\"name\":\"/model.7/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":85,\"death\":86,\"ddr_offset\":3686656,\"note\":\"activation/workspace\"},{\"name\":\"/model.7/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":86,\"death\":97,\"ddr_offset\":2688256,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":87,\"death\":89,\"ddr_offset\":10445056,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":88,\"death\":89,\"ddr_offset\":10752256,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":89,\"death\":96,\"ddr_offset\":3993856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":90,\"death\":92,\"ddr_offset\":4032256,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":91,\"death\":92,\"ddr_offset\":4185856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":92,\"death\":93,\"ddr_offset\":4339456,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":93,\"death\":95,\"ddr_offset\":4377856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":94,\"death\":95,\"ddr_offset\":614656,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":95,\"death\":96,\"ddr_offset\":4531456,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/m/m.0/Add_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":96,\"death\":100,\"ddr_offset\":4569856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":97,\"death\":99,\"ddr_offset\":4608256,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":98,\"death\":99,\"ddr_offset\":4761856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":99,\"death\":100,\"ddr_offset\":4915456,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":100,\"death\":101,\"ddr_offset\":4953856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":101,\"death\":103,\"ddr_offset\":5222656,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":102,\"death\":103,\"ddr_offset\":5529856,\"note\":\"activation/workspace\"},{\"name\":\"/model.8/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":103,\"death\":104,\"ddr_offset\":5030656,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":104,\"death\":106,\"ddr_offset\":10905856,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":105,\"death\":106,\"ddr_offset\":768256,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":106,\"death\":110,\"ddr_offset\":5107456,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/m/MaxPool_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":107,\"death\":110,\"ddr_offset\":5145856,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/m_1/MaxPool_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":108,\"death\":110,\"ddr_offset\":5184256,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/m_2/MaxPool_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":109,\"death\":110,\"ddr_offset\":9523456,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":110,\"death\":111,\"ddr_offset\":9561856,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":111,\"death\":113,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":112,\"death\":113,\"ddr_offset\":6144256,\"note\":\"activation/workspace\"},{\"name\":\"/model.9/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":113,\"death\":114,\"ddr_offset\":9715456,\"note\":\"activation/workspace\"},{\"name\":\"/model.10/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":114,\"death\":116,\"ddr_offset\":11981056,\"note\":\"activation/workspace\"},{\"name\":\"/model.10/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":115,\"death\":116,\"ddr_offset\":12134656,\"note\":\"activation/workspace\"},{\"name\":\"/model.10/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":116,\"death\":181,\"ddr_offset\":9792256,\"note\":\"activation/workspace\"},{\"name\":\"/model.11/Constant_output_0\",\"space\":\"ddr\",\"nbytes\":16,\"alignment\":64,\"birth\":117,\"death\":118,\"ddr_offset\":0,\"note\":\"activation/workspace\"},{\"name\":\"/model.11/Resize_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":118,\"death\":119,\"ddr_offset\":12288256,\"note\":\"activation/workspace\"},{\"name\":\"/model.12/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":119,\"death\":129,\"ddr_offset\":11366656,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":120,\"death\":122,\"ddr_offset\":12595456,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":121,\"death\":122,\"ddr_offset\":12902656,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":122,\"death\":123,\"ddr_offset\":12441856,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":123,\"death\":125,\"ddr_offset\":13209856,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":124,\"death\":125,\"ddr_offset\":13517056,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":125,\"death\":126,\"ddr_offset\":12518656,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":126,\"death\":128,\"ddr_offset\":14438656,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":127,\"death\":128,\"ddr_offset\":14745856,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":128,\"death\":132,\"ddr_offset\":11059456,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":129,\"death\":131,\"ddr_offset\":15053056,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":130,\"death\":131,\"ddr_offset\":15360256,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":131,\"death\":132,\"ddr_offset\":11136256,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":132,\"death\":133,\"ddr_offset\":11213056,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":133,\"death\":135,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":134,\"death\":135,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.13/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":135,\"death\":136,\"ddr_offset\":16435456,\"note\":\"activation/workspace\"},{\"name\":\"/model.14/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":136,\"death\":138,\"ddr_offset\":6451456,\"note\":\"activation/workspace\"},{\"name\":\"/model.14/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":137,\"death\":138,\"ddr_offset\":6758656,\"note\":\"activation/workspace\"},{\"name\":\"/model.14/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":138,\"death\":161,\"ddr_offset\":16589056,\"note\":\"activation/workspace\"},{\"name\":\"/model.15/Constant_output_0\",\"space\":\"ddr\",\"nbytes\":16,\"alignment\":64,\"birth\":139,\"death\":140,\"ddr_offset\":64,\"note\":\"activation/workspace\"},{\"name\":\"/model.15/Resize_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":140,\"death\":141,\"ddr_offset\":7065856,\"note\":\"activation/workspace\"},{\"name\":\"/model.16/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":141,\"death\":151,\"ddr_offset\":2765056,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":142,\"death\":144,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":143,\"death\":144,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":144,\"death\":145,\"ddr_offset\":7373056,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":145,\"death\":147,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":146,\"death\":147,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":147,\"death\":148,\"ddr_offset\":7526656,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":148,\"death\":150,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":149,\"death\":150,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":150,\"death\":154,\"ddr_offset\":7680256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":151,\"death\":153,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":152,\"death\":153,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":153,\"death\":154,\"ddr_offset\":7833856,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":154,\"death\":155,\"ddr_offset\":8294656,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":155,\"death\":157,\"ddr_offset\":16896256,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":156,\"death\":157,\"ddr_offset\":18125056,\"note\":\"activation/workspace\"},{\"name\":\"/model.17/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":157,\"death\":226,\"ddr_offset\":8601856,\"note\":\"activation/workspace\"},{\"name\":\"/model.18/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":158,\"death\":160,\"ddr_offset\":8909056,\"note\":\"activation/workspace\"},{\"name\":\"/model.18/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":159,\"death\":160,\"ddr_offset\":9216256,\"note\":\"activation/workspace\"},{\"name\":\"/model.18/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":160,\"death\":161,\"ddr_offset\":16665856,\"note\":\"activation/workspace\"},{\"name\":\"/model.19/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":161,\"death\":171,\"ddr_offset\":9907456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":162,\"death\":164,\"ddr_offset\":921856,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":163,\"death\":164,\"ddr_offset\":1229056,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":164,\"death\":165,\"ddr_offset\":16819456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":165,\"death\":167,\"ddr_offset\":1536256,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":166,\"death\":167,\"ddr_offset\":1843456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":167,\"death\":168,\"ddr_offset\":16742656,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":168,\"death\":170,\"ddr_offset\":2150656,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":169,\"death\":170,\"ddr_offset\":3379456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":170,\"death\":174,\"ddr_offset\":7987456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":171,\"death\":173,\"ddr_offset\":3686656,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":172,\"death\":173,\"ddr_offset\":5222656,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":173,\"death\":174,\"ddr_offset\":8141056,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":174,\"death\":175,\"ddr_offset\":10061056,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":175,\"death\":177,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":614400,\"alignment\":64,\"birth\":176,\"death\":177,\"ddr_offset\":2765056,\"note\":\"activation/workspace\"},{\"name\":\"/model.20/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":177,\"death\":237,\"ddr_offset\":16281856,\"note\":\"activation/workspace\"},{\"name\":\"/model.21/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":178,\"death\":180,\"ddr_offset\":2534656,\"note\":\"activation/workspace\"},{\"name\":\"/model.21/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":179,\"death\":180,\"ddr_offset\":10445056,\"note\":\"activation/workspace\"},{\"name\":\"/model.21/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":180,\"death\":181,\"ddr_offset\":8064256,\"note\":\"activation/workspace\"},{\"name\":\"/model.22/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":181,\"death\":191,\"ddr_offset\":8217856,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":182,\"death\":184,\"ddr_offset\":10752256,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":183,\"death\":184,\"ddr_offset\":4032256,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":184,\"death\":185,\"ddr_offset\":8102656,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":185,\"death\":187,\"ddr_offset\":4185856,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":186,\"death\":187,\"ddr_offset\":4377856,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":187,\"death\":188,\"ddr_offset\":10214656,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":188,\"death\":190,\"ddr_offset\":614656,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":189,\"death\":190,\"ddr_offset\":4608256,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/m/m.0/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":190,\"death\":194,\"ddr_offset\":10253056,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv2/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":191,\"death\":193,\"ddr_offset\":4761856,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv2/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":153600,\"alignment\":64,\"birth\":192,\"death\":193,\"ddr_offset\":5529856,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv2/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":38400,\"alignment\":64,\"birth\":193,\"death\":194,\"ddr_offset\":9830656,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":194,\"death\":195,\"ddr_offset\":10291456,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv3/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":195,\"death\":197,\"ddr_offset\":5837056,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv3/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":196,\"death\":197,\"ddr_offset\":6144256,\"note\":\"activation/workspace\"},{\"name\":\"/model.23/cv3/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":197,\"death\":245,\"ddr_offset\":10368256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":198,\"death\":200,\"ddr_offset\":16896256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":199,\"death\":200,\"ddr_offset\":18125056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":200,\"death\":201,\"ddr_offset\":12595456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":201,\"death\":203,\"ddr_offset\":16896256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":202,\"death\":203,\"ddr_offset\":18125056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":203,\"death\":204,\"ddr_offset\":12902656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.0/cv2.0.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":204,\"death\":208,\"ddr_offset\":16896256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":205,\"death\":208,\"ddr_offset\":128,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_1_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":206,\"death\":216,\"ddr_offset\":192,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_2_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":207,\"death\":224,\"ddr_offset\":9869056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_output_0\",\"space\":\"ddr\",\"nbytes\":1228800,\"alignment\":64,\"birth\":208,\"death\":225,\"ddr_offset\":18125056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":209,\"death\":211,\"ddr_offset\":13209856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":210,\"death\":211,\"ddr_offset\":13517056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":211,\"death\":212,\"ddr_offset\":2457856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":212,\"death\":214,\"ddr_offset\":14438656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":213,\"death\":214,\"ddr_offset\":14745856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":214,\"death\":215,\"ddr_offset\":2688256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.1/cv2.1.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":215,\"death\":216,\"ddr_offset\":11366656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_1_output_0\",\"space\":\"ddr\",\"nbytes\":307200,\"alignment\":64,\"birth\":216,\"death\":225,\"ddr_offset\":15053056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":217,\"death\":219,\"ddr_offset\":4953856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":218,\"death\":219,\"ddr_offset\":5683456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":19200,\"alignment\":64,\"birth\":219,\"death\":220,\"ddr_offset\":9869120,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":220,\"death\":222,\"ddr_offset\":5760256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":221,\"death\":222,\"ddr_offset\":5030656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":19200,\"alignment\":64,\"birth\":222,\"death\":223,\"ddr_offset\":4339456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv2.2/cv2.2.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":223,\"death\":224,\"ddr_offset\":10905856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_2_output_0\",\"space\":\"ddr\",\"nbytes\":76800,\"alignment\":64,\"birth\":224,\"death\":225,\"ddr_offset\":10982656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Concat_output_0\",\"space\":\"ddr\",\"nbytes\":1612800,\"alignment\":64,\"birth\":225,\"death\":255,\"ddr_offset\":19353856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":226,\"death\":228,\"ddr_offset\":20966656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":227,\"death\":228,\"ddr_offset\":22502656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":228,\"death\":229,\"ddr_offset\":256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":229,\"death\":231,\"ddr_offset\":20966656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":230,\"death\":231,\"ddr_offset\":22502656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":231,\"death\":232,\"ddr_offset\":13824256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.0/cv3.0.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":232,\"death\":236,\"ddr_offset\":20966656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_3_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":233,\"death\":236,\"ddr_offset\":9888320,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_4_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":234,\"death\":244,\"ddr_offset\":9888384,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_5_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":235,\"death\":252,\"ddr_offset\":9888448,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_3_output_0\",\"space\":\"ddr\",\"nbytes\":1536000,\"alignment\":64,\"birth\":236,\"death\":253,\"ddr_offset\":22502656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":237,\"death\":239,\"ddr_offset\":15667456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":238,\"death\":239,\"ddr_offset\":2765056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":239,\"death\":240,\"ddr_offset\":768256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":240,\"death\":242,\"ddr_offset\":16896256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":241,\"death\":242,\"ddr_offset\":17280256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":242,\"death\":243,\"ddr_offset\":9561856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.1/cv3.1.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":243,\"death\":244,\"ddr_offset\":17664256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_4_output_0\",\"space\":\"ddr\",\"nbytes\":384000,\"alignment\":64,\"birth\":244,\"death\":253,\"ddr_offset\":18125056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.0/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":245,\"death\":247,\"ddr_offset\":11981056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.0/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":246,\"death\":247,\"ddr_offset\":12134656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.0/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":24000,\"alignment\":64,\"birth\":247,\"death\":248,\"ddr_offset\":3993856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.1/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":248,\"death\":250,\"ddr_offset\":10598656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.1/act/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":249,\"death\":250,\"ddr_offset\":12288256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.1/act/Mul_output_0\",\"space\":\"ddr\",\"nbytes\":24000,\"alignment\":64,\"birth\":250,\"death\":251,\"ddr_offset\":4531456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/cv3.2/cv3.2.2/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":251,\"death\":252,\"ddr_offset\":15360256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Reshape_5_output_0\",\"space\":\"ddr\",\"nbytes\":96000,\"alignment\":64,\"birth\":252,\"death\":253,\"ddr_offset\":15456256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Concat_1_output_0\",\"space\":\"ddr\",\"nbytes\":2016000,\"alignment\":64,\"birth\":253,\"death\":276,\"ddr_offset\":24038656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Constant_output_0\",\"space\":\"ddr\",\"nbytes\":32,\"alignment\":64,\"birth\":254,\"death\":255,\"ddr_offset\":9888512,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Reshape_output_0\",\"space\":\"ddr\",\"nbytes\":1612800,\"alignment\":64,\"birth\":255,\"death\":256,\"ddr_offset\":26054656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Transpose_output_0\",\"space\":\"ddr\",\"nbytes\":1612800,\"alignment\":64,\"birth\":256,\"death\":257,\"ddr_offset\":19353856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Softmax_output_0\",\"space\":\"ddr\",\"nbytes\":1612800,\"alignment\":64,\"birth\":257,\"death\":258,\"ddr_offset\":26054656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/conv/Conv_output_0\",\"space\":\"ddr\",\"nbytes\":100800,\"alignment\":64,\"birth\":258,\"death\":260,\"ddr_offset\":15552256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Constant_1_output_0\",\"space\":\"ddr\",\"nbytes\":24,\"alignment\":64,\"birth\":259,\"death\":260,\"ddr_offset\":9888576,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/dfl/Reshape_1_output_0\",\"space\":\"ddr\",\"nbytes\":100800,\"alignment\":64,\"birth\":260,\"death\":264,\"ddr_offset\":11213056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_6_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":261,\"death\":261,\"ddr_offset\":9888640,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_7_output_0\",\"space\":\"ddr\",\"nbytes\":8,\"alignment\":64,\"birth\":262,\"death\":262,\"ddr_offset\":9888704,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Slice_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":263,\"death\":266,\"ddr_offset\":864256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Slice_1_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":264,\"death\":268,\"ddr_offset\":9657856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_12_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":265,\"death\":266,\"ddr_offset\":9715456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Sub_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":266,\"death\":272,\"ddr_offset\":12077056,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_13_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":267,\"death\":268,\"ddr_offset\":12230656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Add_1_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":268,\"death\":272,\"ddr_offset\":10694656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Add_2_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":269,\"death\":271,\"ddr_offset\":12384256,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_14_output_0\",\"space\":\"ddr\",\"nbytes\":4,\"alignment\":64,\"birth\":270,\"death\":271,\"ddr_offset\":9888768,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Div_1_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":271,\"death\":273,\"ddr_offset\":12441856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Sub_1_output_0\",\"space\":\"ddr\",\"nbytes\":50400,\"alignment\":64,\"birth\":272,\"death\":273,\"ddr_offset\":12518656,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Concat_2_output_0\",\"space\":\"ddr\",\"nbytes\":100800,\"alignment\":64,\"birth\":273,\"death\":275,\"ddr_offset\":16435456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Constant_15_output_0\",\"space\":\"ddr\",\"nbytes\":25200,\"alignment\":64,\"birth\":274,\"death\":275,\"ddr_offset\":4569856,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Mul_2_output_0\",\"space\":\"ddr\",\"nbytes\":100800,\"alignment\":64,\"birth\":275,\"death\":277,\"ddr_offset\":6451456,\"note\":\"activation/workspace\"},{\"name\":\"/model.24/Sigmoid_output_0\",\"space\":\"ddr\",\"nbytes\":2016000,\"alignment\":64,\"birth\":276,\"death\":277,\"ddr_offset\":27667456,\"note\":\"activation/workspace\"},{\"name\":\"output0\",\"space\":\"ddr\",\"nbytes\":2116800,\"alignment\":64,\"birth\":277,\"death\":278,\"ddr_offset\":29683456,\"note\":\"activation/workspace\"},{\"name\":\"gemmini_scratchpad\",\"space\":\"scratchpad\",\"nbytes\":0,\"alignment\":64,\"birth\":-1,\"death\":278,\"ddr_offset\":null,\"note\":\"on-chip; not a DDR strategy\"},{\"name\":\"gemmini_accumulator\",\"space\":\"accumulator\",\"nbytes\":0,\"alignment\":64,\"birth\":-1,\"death\":278,\"ddr_offset\":null,\"note\":\"on-chip; not a DDR strategy\"}]}"} {
  func.func private @buddy_rvv_copy_rows_i8(i64, i64, i64, i64, i64, i64)
  func.func private @buddy_rvv_memset_i8(i64, i64, i64)
  func.func private @buddy_rvv_memcpy_i8(i64, i64, i64)
  memref.global "private" constant @__constant_1xi32 : memref<1xi32> = dense<0> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_257 : memref<1x1x1x1xf32> = dense<0.00288073183> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_256 : memref<1x1x1x1xf32> = dense<0.00151217566> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_255 : memref<1x1x1x1xf32> = dense<5.2070775> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_254 : memref<1x1x1x1xf32> = dense<5.703000e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_253 : memref<1x1x1x1xf32> = dense<0.00686204992> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_252 : memref<1x1x1x1xf32> = dense<1.14747286> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_251 : memref<1x1x1x1xf32> = dense<0.0475858524> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_250 : memref<1x1x1x1xf32> = dense<4.50051331E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_249 : memref<1x1x1x1xf32> = dense<3.32224584> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_248 : memref<1x1x1x1xf32> = dense<0.0180469286> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_247 : memref<1x1x1x1xf32> = dense<8.82133085E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_246 : memref<1x1x1x1xf32> = dense<6.16502953> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_245 : memref<1x1x1x1xf32> = dense<0.0068890308> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_244 : memref<1x1x1x1xf32> = dense<0.00145326788> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_243 : memref<1x1x1x1xf32> = dense<4.62957716> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_242 : memref<1x1x1x1xi32> = dense<119876> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_241 : memref<1x1x1x1xi32> = dense<16> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_240 : memref<1x1x1x1xi32> = dense<86024> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_239 : memref<1x1x1x1xi32> = dense<-128> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_238 : memref<1x1x1x1xi32> = dense<127> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_237 : memref<1x1x1x1xf32> = dense<0.0373886824> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_236 : memref<1x1x1x1xf32> = dense<2.33338523> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_235 : memref<1x1x1x1xi32> = dense<58432> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_234 : memref<1x1x1x1xi32> = dense<152175> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_233 : memref<1x1x1x1xf32> = dense<8.487220e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_232 : memref<1x1x1x1xf32> = dense<0.00107590214> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_231 : memref<1x1x1x1xf32> = dense<6.4917078> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_230 : memref<1x1x1x1xf32> = dense<0.00754241226> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_229 : memref<1x1x1x1xf32> = dense<5.31277445E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_228 : memref<1x1x1x1xf32> = dense<11.8159323> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_227 : memref<1x1x1x1xf32> = dense<0.0151615953> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_226 : memref<1x1x1x1xf32> = dense<1.90971798E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_225 : memref<1x1x1x1xf32> = dense<15.7156057> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_224 : memref<1x1x1x1xf32> = dense<1.479830e-02> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_223 : memref<1x1x1x1xf32> = dense<2.73298618E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_222 : memref<1x1x1x1xf32> = dense<18.5029144> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_221 : memref<1x1x1x1xf32> = dense<0.00458907802> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_220 : memref<1x1x1x1xf32> = dense<3.77716817E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_219 : memref<1x1x1x1xf32> = dense<22.1751671> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_218 : memref<1x1x1x1xi32> = dense<86932> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_217 : memref<1x1x1x1xi32> = dense<61609> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_216 : memref<1x1x1x1xf32> = dense<0.0162679348> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_215 : memref<1x1x1x1xf32> = dense<3.14696459E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_214 : memref<1x1x1x1xf32> = dense<16.2107983> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_213 : memref<1x1x1x1xf32> = dense<0.00380956917> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_212 : memref<1x1x1x1xf32> = dense<7.64760188E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_211 : memref<1x1x1x1xf32> = dense<10.4267635> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_210 : memref<1x1x1x1xi32> = dense<39320> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_209 : memref<1x1x1x1xi32> = dense<78613> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_208 : memref<1x1x1x1xf32> = dense<0.0120223034> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_207 : memref<1x1x1x1xf32> = dense<9.20053672> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_206 : memref<1x1x1x1xi32> = dense<53949> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_205 : memref<1x1x1x1xi32> = dense<73339> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_204 : memref<1x1x1x1xf32> = dense<0.0150127029> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_203 : memref<1x1x1x1xf32> = dense<4.9095531E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_202 : memref<1x1x1x1xf32> = dense<16.0323334> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_201 : memref<1x1x1x1xf32> = dense<0.0122586582> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_200 : memref<1x1x1x1xf32> = dense<3.95768555E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_199 : memref<1x1x1x1xf32> = dense<9.813340e+00> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_198 : memref<1x1x1x1xf32> = dense<0.0189360213> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_197 : memref<1x1x1x1xf32> = dense<9.96137532E-5> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_196 : memref<1x1x1x1xf32> = dense<25.7426586> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_195 : memref<1x1x1x1xf32> = dense<0.0145288706> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_194 : memref<1x1x1x1xf32> = dense<3.475954E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_193 : memref<1x1x1x1xf32> = dense<18.4688377> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_192 : memref<1x1x1x1xf32> = dense<0.00607879459> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_191 : memref<1x1x1x1xf32> = dense<1.8168152E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_190 : memref<1x1x1x1xf32> = dense<2.804900e+01> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_189 : memref<1x1x1x1xi32> = dense<110335> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_188 : memref<1x1x1x1xi32> = dense<101262> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_187 : memref<1x1x1x1xf32> = dense<0.00671094796> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_186 : memref<1x1x1x1xf32> = dense<3.88108398E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_185 : memref<1x1x1x1xf32> = dense<20.2499313> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_184 : memref<1x1x1x1xf32> = dense<0.00729554053> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_183 : memref<1x1x1x1xf32> = dense<4.579670e-04> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_182 : memref<1x1x1x1xf32> = dense<17.0134296> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_181 : memref<1x1x1x1xi32> = dense<25999> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_180 : memref<1x1x1x1xi32> = dense<66229> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_179 : memref<1x1x1x1xf32> = dense<0.0123461829> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_178 : memref<1x1x1x1xf32> = dense<3.37153353E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_177 : memref<1x1x1x1xf32> = dense<19.6601658> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_176 : memref<1x1x1x1xf32> = dense<0.00430227118> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_175 : memref<1x1x1x1xf32> = dense<8.47681367E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_174 : memref<1x1x1x1xf32> = dense<8.63794327> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_173 : memref<1x1x1x1xi32> = dense<50910> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_172 : memref<1x1x1x1xi32> = dense<101333> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_171 : memref<1x1x1x1xf32> = dense<0.00847221724> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_170 : memref<1x1x1x1xf32> = dense<9.28887557> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_169 : memref<1x1x1x1xi32> = dense<45579> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_168 : memref<1x1x1x1xf32> = dense<0.00620856694> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_167 : memref<1x1x1x1xf32> = dense<7.22016848E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_166 : memref<1x1x1x1xf32> = dense<10.905489> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_165 : memref<1x1x1x1xf32> = dense<0.00459722057> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_164 : memref<1x1x1x1xf32> = dense<6.92418544E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_163 : memref<1x1x1x1xf32> = dense<11.3715963> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_162 : memref<1x1x1x1xf32> = dense<0.00715792737> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_161 : memref<1x1x1x1xf32> = dense<3.85764521E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_160 : memref<1x1x1x1xf32> = dense<20.3715038> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_159 : memref<1x1x1x1xf32> = dense<0.0129372664> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_158 : memref<1x1x1x1xf32> = dense<8.35974759E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_157 : memref<1x1x1x1xf32> = dense<9.418950e+00> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_156 : memref<1x1x1x1xf32> = dense<0.003725769> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_155 : memref<1x1x1x1xf32> = dense<8.29692464E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_154 : memref<1x1x1x1xf32> = dense<9.3348627> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_153 : memref<1x1x1x1xi32> = dense<30531> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_152 : memref<1x1x1x1xi32> = dense<66627> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_151 : memref<1x1x1x1xf32> = dense<0.0122155221> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_150 : memref<1x1x1x1xf32> = dense<13.2879763> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_149 : memref<1x1x1x1xi32> = dense<46806> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_148 : memref<1x1x1x1xf32> = dense<0.0109014092> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_147 : memref<1x1x1x1xf32> = dense<5.51108562E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_146 : memref<1x1x1x1xf32> = dense<11.3165159> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_145 : memref<1x1x1x1xf32> = dense<0.00621239562> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_144 : memref<1x1x1x1xf32> = dense<4.45070211E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_143 : memref<1x1x1x1xf32> = dense<17.678215> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_142 : memref<1x1x1x1xf32> = dense<8.516760e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_141 : memref<1x1x1x1xf32> = dense<3.88529152E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_140 : memref<1x1x1x1xf32> = dense<18.3486519> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_139 : memref<1x1x1x1xf32> = dense<0.00958314538> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_138 : memref<1x1x1x1xf32> = dense<5.20346279E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_137 : memref<1x1x1x1xf32> = dense<15.1288424> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_136 : memref<1x1x1x1xi32> = dense<47231> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_135 : memref<1x1x1x1xi32> = dense<65537> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_134 : memref<1x1x1x1xf32> = dense<0.0254192129> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_133 : memref<1x1x1x1xf32> = dense<2.77157931E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_132 : memref<1x1x1x1xf32> = dense<19.0208664> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_131 : memref<1x1x1x1xf32> = dense<0.00802434888> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_130 : memref<1x1x1x1xf32> = dense<3.3741878E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_129 : memref<1x1x1x1xf32> = dense<20.3466301> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_128 : memref<1x1x1x1xf32> = dense<0.00396349095> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_127 : memref<1x1x1x1xf32> = dense<3.33906384E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_126 : memref<1x1x1x1xf32> = dense<23.4764938> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_125 : memref<1x1x1x1xf32> = dense<0.0107464846> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_124 : memref<1x1x1x1xf32> = dense<14.9673128> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_123 : memref<1x1x1x1xi32> = dense<65829> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_122 : memref<1x1x1x1xi32> = dense<103254> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_121 : memref<1x1x1x1xf32> = dense<9.169820e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_120 : memref<1x1x1x1xf32> = dense<3.79452569E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_119 : memref<1x1x1x1xf32> = dense<15.4127302> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_118 : memref<1x1x1x1xf32> = dense<5.732980e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_117 : memref<1x1x1x1xf32> = dense<2.9983971E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_116 : memref<1x1x1x1xf32> = dense<25.0770168> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_115 : memref<1x1x1x1xi32> = dense<40025> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_114 : memref<1x1x1x1xi32> = dense<65560> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_113 : memref<1x1x1x1xf32> = dense<8.340900e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_112 : memref<1x1x1x1xf32> = dense<2.409260e-04> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_111 : memref<1x1x1x1xf32> = dense<20.5571404> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_110 : memref<1x1x1x1xf32> = dense<0.0178376455> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_109 : memref<1x1x1x1xf32> = dense<2.885320e-04> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_108 : memref<1x1x1x1xf32> = dense<21.9819336> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_107 : memref<1x1x1x1xf32> = dense<0.007817436> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_106 : memref<1x1x1x1xf32> = dense<2.46106938E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_105 : memref<1x1x1x1xf32> = dense<22.5425873> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_104 : memref<1x1x1x1xf32> = dense<0.00953922048> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_103 : memref<1x1x1x1xf32> = dense<37.4880905> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_102 : memref<1x1x1x1xi32> = dense<93014> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_101 : memref<1x1x1x1xi32> = dense<55932> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_100 : memref<1x1x1x1xf32> = dense<0.0133869769> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_99 : memref<1x1x1x1xf32> = dense<2.29190773E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_98 : memref<1x1x1x1xf32> = dense<17.89324> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_97 : memref<1x1x1x1xf32> = dense<0.00338776759> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_96 : memref<1x1x1x1xf32> = dense<3.87256674E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_95 : memref<1x1x1x1xf32> = dense<18.74473> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_94 : memref<1x1x1x1xi32> = dense<71088> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_93 : memref<1x1x1x1xi32> = dense<53138> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_92 : memref<1x1x1x1xf32> = dense<0.00869756192> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_91 : memref<1x1x1x1xf32> = dense<4.09246713E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_90 : memref<1x1x1x1xf32> = dense<16.8264713> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_89 : memref<1x1x1x1xf32> = dense<0.0079792682> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_88 : memref<1x1x1x1xf32> = dense<3.446150e-04> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_87 : memref<1x1x1x1xf32> = dense<18.4147568> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_86 : memref<1x1x1x1xf32> = dense<0.0050264271> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_85 : memref<1x1x1x1xf32> = dense<4.18305572E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_84 : memref<1x1x1x1xf32> = dense<16.9908028> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_83 : memref<1x1x1x1xf32> = dense<0.00879147648> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_82 : memref<1x1x1x1xf32> = dense<25.1426163> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_81 : memref<1x1x1x1xi32> = dense<72605> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_80 : memref<1x1x1x1xi32> = dense<49065> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_79 : memref<1x1x1x1xf32> = dense<0.0108789504> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_78 : memref<1x1x1x1xf32> = dense<4.42717166E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_77 : memref<1x1x1x1xf32> = dense<12.0136404> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_76 : memref<1x1x1x1xf32> = dense<0.0048789829> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_75 : memref<1x1x1x1xf32> = dense<11.0415249> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_74 : memref<1x1x1x1xi32> = dense<89816> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_73 : memref<1x1x1x1xi32> = dense<65551> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_72 : memref<1x1x1x1xf32> = dense<0.0125225503> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_71 : memref<1x1x1x1xf32> = dense<5.61099325E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_70 : memref<1x1x1x1xf32> = dense<10.667697> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_69 : memref<1x1x1x1xf32> = dense<0.00973275303> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_68 : memref<1x1x1x1xf32> = dense<5.583310e-04> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_67 : memref<1x1x1x1xf32> = dense<12.1606197> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_66 : memref<1x1x1x1xf32> = dense<0.00472895242> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_65 : memref<1x1x1x1xf32> = dense<5.42587542E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_64 : memref<1x1x1x1xf32> = dense<12.8210926> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_63 : memref<1x1x1x1xf32> = dense<0.00609090552> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_62 : memref<1x1x1x1xf32> = dense<15.6661739> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32_61 : memref<1x1x1x1xi32> = dense<74179> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xi32 : memref<1x1x1x1xi32> = dense<60708> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_60 : memref<1x1x1x1xf32> = dense<0.0181710888> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_59 : memref<1x1x1x1xf32> = dense<4.73392225E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_58 : memref<1x1x1x1xf32> = dense<7.38426685> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_57 : memref<1x1x1x1xf32> = dense<0.00989972334> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_56 : memref<1x1x1x1xf32> = dense<2.97596853E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_55 : memref<1x1x1x1xf32> = dense<12.3325214> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_54 : memref<1x1x1x1xf32> = dense<0.00611394271> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_53 : memref<1x1x1x1xf32> = dense<0.00213001156> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_52 : memref<1x1x1x1xf32> = dense<3.69670081> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_51 : memref<1x1x1x1xf32> = dense<0.005432026> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_50 : memref<1x1x1x1xf32> = dense<0.135844663> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_49 : memref<1x1x1x1xf32> = dense<0.0153491423> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_48 : memref<1x1x1x1xf32> = dense<3.95502779E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_47 : memref<1x1x1x1xf32> = dense<11.7519951> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_46 : memref<1x1x1x1xf32> = dense<7.832830e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_45 : memref<1x1x1x1xf32> = dense<0.0014124281> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_44 : memref<1x1x1x1xf32> = dense<5.57480812> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_43 : memref<1x1x1x1xf32> = dense<0.00581856817> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_42 : memref<1x1x1x1xf32> = dense<0.0954148918> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_41 : memref<1x1x1x1xf32> = dense<8.036410e-03> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_40 : memref<1x1x1x1xf32> = dense<5.28013043E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_39 : memref<1x1x1x1xf32> = dense<8.32852458> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_38 : memref<1x1x1x1xf32> = dense<0.00592346117> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_37 : memref<1x1x1x1xf32> = dense<0.00160745252> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_36 : memref<1x1x1x1xf32> = dense<4.8984437> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_35 : memref<1x1x1x1xf32> = dense<0.00600688718> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_34 : memref<1x1x1x1xf32> = dense<0.104074538> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_33 : memref<1x1x1xf32> = dense<0.702382326> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_32 : memref<1x1x1xf32> = dense<7.661290e-01> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_31 : memref<1x1x1x1xf32> = dense<0.0071694795> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_30 : memref<1x1x1x1xf32> = dense<3.36615805E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_29 : memref<1x1x1x1xf32> = dense<15.0777407> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_28 : memref<1x1x1x1xf32> = dense<0.00637654448> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_27 : memref<1x1x1x1xf32> = dense<0.00200135214> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_26 : memref<1x1x1x1xf32> = dense<3.93434811> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_25 : memref<1x1x1x1xf32> = dense<0.00252736034> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_24 : memref<1x1x1x1xf32> = dense<0.211888283> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_23 : memref<1x1x1x1xf32> = dense<0.00700604171> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_22 : memref<1x1x1x1xf32> = dense<4.25516366E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_21 : memref<1x1x1x1xf32> = dense<14.0195532> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_20 : memref<1x1x1x1xf32> = dense<0.0068566585> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_19 : memref<1x1x1x1xf32> = dense<0.00468618935> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_18 : memref<1x1x1x1xf32> = dense<1.68025982> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_17 : memref<1x1x1x1xf32> = dense<0.00488613872> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_16 : memref<1x1x1x1xf32> = dense<0.314697564> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_15 : memref<1x1x1x1xf32> = dense<0.00787081196> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_14 : memref<1x1x1x1xf32> = dense<4.57801943E-4> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_13 : memref<1x1x1x1xf32> = dense<11.8411112> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_12 : memref<1x1x1x1xf32> = dense<0.00632192567> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_11 : memref<1x1x1x1xf32> = dense<0.00381394778> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_10 : memref<1x1x1x1xf32> = dense<2.06453156> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_9 : memref<1x1x1x1xf32> = dense<0.00431937352> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_8 : memref<1x1x1x1xf32> = dense<0.406570375> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_7 : memref<1x1x1xf32> = dense<0.521160185> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_6 : memref<1x1x1xf32> = dense<0.774029731> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_5 : memref<1x1x1x1xf32> = dense<133.172363> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_4 : memref<1x1x1x1xf32> = dense<0.11811024> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32_3 : memref<1x1x1x1xf32> = dense<0.00859712064> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1x1xf32 : memref<1x1x1x1xf32> = dense<0.103162147> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_2 : memref<1x1x1xf32> = dense<0.497813642> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_1 : memref<1x1x1xf32> = dense<0.516002178> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32_0 : memref<1x1x1xf32> = dense<0.293548733> {alignment = 64 : i64}
  memref.global "private" constant @__constant_1x1x1xf32 : memref<1x1x1xf32> = dense<0.0014061142> {alignment = 64 : i64}
  func.func @forward(%arg0: tensor<1x480x640x3xi8>, %arg1: tensor<108x16xi8>, %arg2: tensor<16xi32>, %arg3: tensor<144x32xi8>, %arg4: tensor<32xi32>, %arg5: tensor<32x16xi8>, %arg6: tensor<19200x16xi32>, %arg7: tensor<16x16xi8>, %arg8: tensor<19200x16xi32>, %arg9: tensor<144x16xi8>, %arg10: tensor<16xi32>, %arg11: tensor<32x16xi8>, %arg12: tensor<19200x16xi32>, %arg13: tensor<32x32xi8>, %arg14: tensor<19200x32xi32>, %arg15: tensor<288x64xi8>, %arg16: tensor<64xi32>, %arg17: tensor<64x32xi8>, %arg18: tensor<4800x32xi32>, %arg19: tensor<32x32xi8>, %arg20: tensor<4800x32xi32>, %arg21: tensor<288x32xi8>, %arg22: tensor<32xi32>, %arg23: tensor<32x32xi8>, %arg24: tensor<4800x32xi32>, %arg25: tensor<288x32xi8>, %arg26: tensor<32xi32>, %arg27: tensor<64x32xi8>, %arg28: tensor<4800x32xi32>, %arg29: tensor<64x64xi8>, %arg30: tensor<4800x64xi32>, %arg31: tensor<576x128xi8>, %arg32: tensor<128xi32>, %arg33: tensor<128x64xi8>, %arg34: tensor<1200x64xi32>, %arg35: tensor<64x64xi8>, %arg36: tensor<1200x64xi32>, %arg37: tensor<576x64xi8>, %arg38: tensor<64xi32>, %arg39: tensor<64x64xi8>, %arg40: tensor<1200x64xi32>, %arg41: tensor<576x64xi8>, %arg42: tensor<64xi32>, %arg43: tensor<64x64xi8>, %arg44: tensor<1200x64xi32>, %arg45: tensor<576x64xi8>, %arg46: tensor<64xi32>, %arg47: tensor<128x64xi8>, %arg48: tensor<1200x64xi32>, %arg49: tensor<128x128xi8>, %arg50: tensor<1200x128xi32>, %arg51: tensor<1152x256xi8>, %arg52: tensor<256xi32>, %arg53: tensor<256x128xi8>, %arg54: tensor<304x128xi32>, %arg55: tensor<128x128xi8>, %arg56: tensor<304x128xi32>, %arg57: tensor<1152x128xi8>, %arg58: tensor<128xi32>, %arg59: tensor<256x128xi8>, %arg60: tensor<304x128xi32>, %arg61: tensor<256x256xi8>, %arg62: tensor<304x256xi32>, %arg63: tensor<256x128xi8>, %arg64: tensor<304x128xi32>, %arg65: tensor<512x256xi8>, %arg66: tensor<304x256xi32>, %arg67: tensor<256x128xi8>, %arg68: tensor<304x128xi32>, %arg69: tensor<4xf32>, %arg70: tensor<256x64xi8>, %arg71: tensor<1200x64xi32>, %arg72: tensor<64x64xi8>, %arg73: tensor<1200x64xi32>, %arg74: tensor<576x64xi8>, %arg75: tensor<64xi32>, %arg76: tensor<256x64xi8>, %arg77: tensor<1200x64xi32>, %arg78: tensor<128x128xi8>, %arg79: tensor<1200x128xi32>, %arg80: tensor<128x64xi8>, %arg81: tensor<1200x64xi32>, %arg82: tensor<4xf32>, %arg83: tensor<128x32xi8>, %arg84: tensor<4800x32xi32>, %arg85: tensor<32x32xi8>, %arg86: tensor<4800x32xi32>, %arg87: tensor<288x32xi8>, %arg88: tensor<32xi32>, %arg89: tensor<128x32xi8>, %arg90: tensor<4800x32xi32>, %arg91: tensor<64x64xi8>, %arg92: tensor<4800x64xi32>, %arg93: tensor<576x64xi8>, %arg94: tensor<64xi32>, %arg95: tensor<128x64xi8>, %arg96: tensor<1200x64xi32>, %arg97: tensor<64x64xi8>, %arg98: tensor<1200x64xi32>, %arg99: tensor<576x64xi8>, %arg100: tensor<64xi32>, %arg101: tensor<128x64xi8>, %arg102: tensor<1200x64xi32>, %arg103: tensor<128x128xi8>, %arg104: tensor<1200x128xi32>, %arg105: tensor<1152x128xi8>, %arg106: tensor<128xi32>, %arg107: tensor<256x128xi8>, %arg108: tensor<304x128xi32>, %arg109: tensor<128x128xi8>, %arg110: tensor<304x128xi32>, %arg111: tensor<1152x128xi8>, %arg112: tensor<128xi32>, %arg113: tensor<256x128xi8>, %arg114: tensor<304x128xi32>, %arg115: tensor<256x256xi8>, %arg116: tensor<304x256xi32>, %arg117: tensor<576x64xi8>, %arg118: tensor<64xi32>, %arg119: tensor<576x64xi8>, %arg120: tensor<64xi32>, %arg121: tensor<64x64xi8>, %arg122: tensor<4800x64xi32>, %arg123: tensor<3xi64>, %arg124: tensor<1152x64xi8>, %arg125: tensor<64xi32>, %arg126: tensor<576x64xi8>, %arg127: tensor<64xi32>, %arg128: tensor<64x64xi8>, %arg129: tensor<1200x64xi32>, %arg130: tensor<3xi64>, %arg131: tensor<2304x64xi8>, %arg132: tensor<64xi32>, %arg133: tensor<576x64xi8>, %arg134: tensor<64xi32>, %arg135: tensor<64x64xi8>, %arg136: tensor<304x64xi32>, %arg137: tensor<3xi64>, %arg138: tensor<576x80xi8>, %arg139: tensor<80xi32>, %arg140: tensor<720x80xi8>, %arg141: tensor<80xi32>, %arg142: tensor<80x80xi8>, %arg143: tensor<4800x80xi32>, %arg144: tensor<3xi64>, %arg145: tensor<1152x80xi8>, %arg146: tensor<80xi32>, %arg147: tensor<720x80xi8>, %arg148: tensor<80xi32>, %arg149: tensor<80x80xi8>, %arg150: tensor<1200x80xi32>, %arg151: tensor<3xi64>, %arg152: tensor<2304x80xi8>, %arg153: tensor<80xi32>, %arg154: tensor<720x80xi8>, %arg155: tensor<80xi32>, %arg156: tensor<80x80xi8>, %arg157: tensor<304x80xi32>, %arg158: tensor<3xi64>, %arg159: tensor<4xi64>, %arg160: tensor<1x16x1x1xf32>, %arg161: tensor<3xi64>, %arg162: tensor<1x2x6300xf32>, %arg163: tensor<1x2x6300xf32>, %arg164: tensor<f32>, %arg165: tensor<1x6300xf32>) -> tensor<1x84x6300xf32> {
    %c2 = arith.constant 2 : index
    %c4800 = arith.constant 4800 : index
    %c300 = arith.constant 300 : index
    %c1200 = arith.constant 1200 : index
    %c512 = arith.constant 512 : index
    %c5 = arith.constant 5 : index
    %c24 = arith.constant 24 : index
    %c19 = arith.constant 19 : index
    %c22 = arith.constant 22 : index
    %c17 = arith.constant 17 : index
    %c256 = arith.constant 256 : index
    %c41 = arith.constant 41 : index
    %c31 = arith.constant 31 : index
    %c42 = arith.constant 42 : index
    %c128 = arith.constant 128 : index
    %c81 = arith.constant 81 : index
    %c61 = arith.constant 61 : index
    %c82 = arith.constant 82 : index
    %c62 = arith.constant 62 : index
    %c161 = arith.constant 161 : index
    %c121 = arith.constant 121 : index
    %c162 = arith.constant 162 : index
    %c122 = arith.constant 122 : index
    %c32 = arith.constant 32 : index
    %c160 = arith.constant 160 : index
    %c120 = arith.constant 120 : index
    %c321 = arith.constant 321 : index
    %c241 = arith.constant 241 : index
    %c320 = arith.constant 320 : index
    %c240 = arith.constant 240 : index
    %c3 = arith.constant 3 : index
    %c644 = arith.constant 644 : index
    %c484 = arith.constant 484 : index
    %c6300 = arith.constant 6300 : index
    %c4 = arith.constant 4 : index
    %c6300_i64 = arith.constant 6300 : i64
    %c4_i64 = arith.constant 4 : i64
    %c24000_i64 = arith.constant 24000 : i64
    %cst = arith.constant 0.00381394778 : f32
    %cst_0 = arith.constant 4.57801943E-4 : f32
    %c96000_i64 = arith.constant 96000 : i64
    %cst_1 = arith.constant 0.00468618935 : f32
    %cst_2 = arith.constant 4.25516366E-4 : f32
    %c384000_i64 = arith.constant 384000 : i64
    %cst_3 = arith.constant 0.00200135214 : f32
    %cst_4 = arith.constant 3.36615805E-4 : f32
    %c20 = arith.constant 20 : index
    %c15 = arith.constant 15 : index
    %cst_5 = arith.constant 0.00160745252 : f32
    %cst_6 = arith.constant 5.28013043E-4 : f32
    %c40 = arith.constant 40 : index
    %c30 = arith.constant 30 : index
    %cst_7 = arith.constant 0.0014124281 : f32
    %cst_8 = arith.constant 3.95502779E-4 : f32
    %c80 = arith.constant 80 : index
    %c60 = arith.constant 60 : index
    %cst_9 = arith.constant 0.00213001156 : f32
    %cst_10 = arith.constant 2.97596853E-4 : f32
    %cst_11 = arith.constant 4.73392225E-4 : f32
    %cst_12 = arith.constant 5.42587542E-4 : f32
    %cst_13 = arith.constant 5.583310e-04 : f32
    %cst_14 = arith.constant 5.61099325E-4 : f32
    %cst_15 = arith.constant 4.42717166E-4 : f32
    %cst_16 = arith.constant 4.18305572E-4 : f32
    %cst_17 = arith.constant 3.446150e-04 : f32
    %cst_18 = arith.constant 4.09246713E-4 : f32
    %cst_19 = arith.constant 3.87256674E-4 : f32
    %cst_20 = arith.constant 2.29190773E-4 : f32
    %cst_21 = arith.constant 2.46106938E-4 : f32
    %cst_22 = arith.constant 2.885320e-04 : f32
    %cst_23 = arith.constant 2.409260e-04 : f32
    %cst_24 = arith.constant 2.9983971E-4 : f32
    %cst_25 = arith.constant 3.79452569E-4 : f32
    %cst_26 = arith.constant 3.33906384E-4 : f32
    %cst_27 = arith.constant 3.3741878E-4 : f32
    %cst_28 = arith.constant 2.77157931E-4 : f32
    %cst_29 = arith.constant 5.20346279E-4 : f32
    %cst_30 = arith.constant 3.88529152E-4 : f32
    %c2048_i64 = arith.constant 2048 : i64
    %cst_31 = arith.constant 4.45070211E-4 : f32
    %cst_32 = arith.constant 5.51108562E-4 : f32
    %cst_33 = arith.constant 8.29692464E-4 : f32
    %cst_34 = arith.constant 8.35974759E-4 : f32
    %c512_i64 = arith.constant 512 : i64
    %c38400_i64 = arith.constant 38400 : i64
    %cst_35 = arith.constant 3.85764521E-4 : f32
    %c300_i64 = arith.constant 300 : i64
    %c1024_i64 = arith.constant 1024 : i64
    %cst_36 = arith.constant 6.92418544E-4 : f32
    %c256_i64 = arith.constant 256 : i64
    %c20_i64 = arith.constant 20 : i64
    %c15_i64 = arith.constant 15 : i64
    %cst_37 = arith.constant 7.22016848E-4 : f32
    %cst_38 = arith.constant 8.47681367E-4 : f32
    %cst_39 = arith.constant 3.37153353E-4 : f32
    %cst_40 = arith.constant 4.579670e-04 : f32
    %cst_41 = arith.constant 3.88108398E-4 : f32
    %cst_42 = arith.constant 1.8168152E-4 : f32
    %cst_43 = arith.constant 3.475954E-4 : f32
    %c76800_i64 = arith.constant 76800 : i64
    %cst_44 = arith.constant 9.96137532E-5 : f32
    %c1200_i64 = arith.constant 1200 : i64
    %cst_45 = arith.constant 3.95768555E-4 : f32
    %c128_i64 = arith.constant 128 : i64
    %c40_i64 = arith.constant 40 : i64
    %c30_i64 = arith.constant 30 : i64
    %cst_46 = arith.constant 4.9095531E-4 : f32
    %cst_47 = arith.constant 7.64760188E-4 : f32
    %cst_48 = arith.constant 3.14696459E-4 : f32
    %cst_49 = arith.constant 3.77716817E-4 : f32
    %cst_50 = arith.constant 2.73298618E-4 : f32
    %c153600_i64 = arith.constant 153600 : i64
    %cst_51 = arith.constant 1.90971798E-4 : f32
    %c4800_i64 = arith.constant 4800 : i64
    %cst_52 = arith.constant 5.31277445E-4 : f32
    %c64_i64 = arith.constant 64 : i64
    %c80_i64 = arith.constant 80 : i64
    %c60_i64 = arith.constant 60 : i64
    %c64 = arith.constant 64 : index
    %cst_53 = arith.constant 0.00107590214 : f32
    %cst_54 = arith.constant 0.00145326788 : f32
    %cst_55 = arith.constant 8.82133085E-4 : f32
    %c307200_i64 = arith.constant 307200 : i64
    %cst_56 = arith.constant 4.50051331E-4 : f32
    %c19200_i64 = arith.constant 19200 : i64
    %c0_i64 = arith.constant 0 : i64
    %c614400_i64 = arith.constant 614400 : i64
    %cst_57 = arith.constant 0.00686204992 : f32
    %c32_i64 = arith.constant 32 : i64
    %c3_i64 = arith.constant 3 : i64
    %c160_i64 = arith.constant 160 : i64
    %c120_i64 = arith.constant 120 : i64
    %c-128_i32 = arith.constant -128 : i32
    %c127_i32 = arith.constant 127 : i32
    %cst_58 = arith.constant -5.000000e-01 : f32
    %cst_59 = arith.constant 5.000000e-01 : f32
    %cst_60 = arith.constant 0.00151217566 : f32
    %c16_i64 = arith.constant 16 : i64
    %c1_i64 = arith.constant 1 : i64
    %c6_i64 = arith.constant 6 : i64
    %c320_i64 = arith.constant 320 : i64
    %c240_i64 = arith.constant 240 : i64
    %c1 = arith.constant 1 : index
    %c16 = arith.constant 16 : index
    %c0_i8 = arith.constant 0 : i8
    %c-128_i8 = arith.constant -128 : i8
    %cst_61 = arith.constant 1.000000e+00 : f32
    %cst_62 = arith.constant -1.280000e+02 : f32
    %cst_63 = arith.constant 1.270000e+02 : f32
    %c0 = arith.constant 0 : index
    %c0_i32 = arith.constant 0 : i32
    %c14_i32 = arith.constant 14 : i32
    %c19_i32 = arith.constant 19 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c29_i32 = arith.constant 29 : i32
    %c39_i32 = arith.constant 39 : i32
    %cst_64 = arith.constant 0.000000e+00 : f32
    %cst_65 = arith.constant -1.270000e+02 : f32
    %0 = bufferization.to_buffer %arg165 : tensor<1x6300xf32> to memref<1x6300xf32>
    %1 = bufferization.to_buffer %arg164 : tensor<f32> to memref<f32>
    %2 = bufferization.to_buffer %arg163 : tensor<1x2x6300xf32> to memref<1x2x6300xf32>
    %3 = bufferization.to_buffer %arg162 : tensor<1x2x6300xf32> to memref<1x2x6300xf32>
    %4 = bufferization.to_buffer %arg160 : tensor<1x16x1x1xf32> to memref<1x16x1x1xf32>
    %5 = bufferization.to_buffer %arg157 : tensor<304x80xi32> to memref<304x80xi32>
    %6 = bufferization.to_buffer %arg156 : tensor<80x80xi8> to memref<80x80xi8>
    %7 = bufferization.to_buffer %arg155 : tensor<80xi32> to memref<80xi32>
    %8 = bufferization.to_buffer %arg154 : tensor<720x80xi8> to memref<720x80xi8>
    %9 = bufferization.to_buffer %arg153 : tensor<80xi32> to memref<80xi32>
    %10 = bufferization.to_buffer %arg152 : tensor<2304x80xi8> to memref<2304x80xi8>
    %11 = bufferization.to_buffer %arg150 : tensor<1200x80xi32> to memref<1200x80xi32>
    %12 = bufferization.to_buffer %arg149 : tensor<80x80xi8> to memref<80x80xi8>
    %13 = bufferization.to_buffer %arg148 : tensor<80xi32> to memref<80xi32>
    %14 = bufferization.to_buffer %arg147 : tensor<720x80xi8> to memref<720x80xi8>
    %15 = bufferization.to_buffer %arg146 : tensor<80xi32> to memref<80xi32>
    %16 = bufferization.to_buffer %arg145 : tensor<1152x80xi8> to memref<1152x80xi8>
    %17 = bufferization.to_buffer %arg143 : tensor<4800x80xi32> to memref<4800x80xi32>
    %18 = bufferization.to_buffer %arg142 : tensor<80x80xi8> to memref<80x80xi8>
    %19 = bufferization.to_buffer %arg141 : tensor<80xi32> to memref<80xi32>
    %20 = bufferization.to_buffer %arg140 : tensor<720x80xi8> to memref<720x80xi8>
    %21 = bufferization.to_buffer %arg139 : tensor<80xi32> to memref<80xi32>
    %22 = bufferization.to_buffer %arg138 : tensor<576x80xi8> to memref<576x80xi8>
    %23 = bufferization.to_buffer %arg136 : tensor<304x64xi32> to memref<304x64xi32>
    %24 = bufferization.to_buffer %arg135 : tensor<64x64xi8> to memref<64x64xi8>
    %25 = bufferization.to_buffer %arg134 : tensor<64xi32> to memref<64xi32>
    %26 = bufferization.to_buffer %arg133 : tensor<576x64xi8> to memref<576x64xi8>
    %27 = bufferization.to_buffer %arg132 : tensor<64xi32> to memref<64xi32>
    %28 = bufferization.to_buffer %arg131 : tensor<2304x64xi8> to memref<2304x64xi8>
    %29 = bufferization.to_buffer %arg129 : tensor<1200x64xi32> to memref<1200x64xi32>
    %30 = bufferization.to_buffer %arg128 : tensor<64x64xi8> to memref<64x64xi8>
    %31 = bufferization.to_buffer %arg127 : tensor<64xi32> to memref<64xi32>
    %32 = bufferization.to_buffer %arg126 : tensor<576x64xi8> to memref<576x64xi8>
    %33 = bufferization.to_buffer %arg125 : tensor<64xi32> to memref<64xi32>
    %34 = bufferization.to_buffer %arg124 : tensor<1152x64xi8> to memref<1152x64xi8>
    %35 = bufferization.to_buffer %arg122 : tensor<4800x64xi32> to memref<4800x64xi32>
    %36 = bufferization.to_buffer %arg121 : tensor<64x64xi8> to memref<64x64xi8>
    %37 = bufferization.to_buffer %arg120 : tensor<64xi32> to memref<64xi32>
    %38 = bufferization.to_buffer %arg119 : tensor<576x64xi8> to memref<576x64xi8>
    %39 = bufferization.to_buffer %arg118 : tensor<64xi32> to memref<64xi32>
    %40 = bufferization.to_buffer %arg117 : tensor<576x64xi8> to memref<576x64xi8>
    %41 = bufferization.to_buffer %arg116 : tensor<304x256xi32> to memref<304x256xi32>
    %42 = bufferization.to_buffer %arg115 : tensor<256x256xi8> to memref<256x256xi8>
    %43 = bufferization.to_buffer %arg114 : tensor<304x128xi32> to memref<304x128xi32>
    %44 = bufferization.to_buffer %arg113 : tensor<256x128xi8> to memref<256x128xi8>
    %45 = bufferization.to_buffer %arg112 : tensor<128xi32> to memref<128xi32>
    %46 = bufferization.to_buffer %arg111 : tensor<1152x128xi8> to memref<1152x128xi8>
    %47 = bufferization.to_buffer %arg110 : tensor<304x128xi32> to memref<304x128xi32>
    %48 = bufferization.to_buffer %arg109 : tensor<128x128xi8> to memref<128x128xi8>
    %49 = bufferization.to_buffer %arg108 : tensor<304x128xi32> to memref<304x128xi32>
    %50 = bufferization.to_buffer %arg107 : tensor<256x128xi8> to memref<256x128xi8>
    %51 = bufferization.to_buffer %arg106 : tensor<128xi32> to memref<128xi32>
    %52 = bufferization.to_buffer %arg105 : tensor<1152x128xi8> to memref<1152x128xi8>
    %53 = bufferization.to_buffer %arg104 : tensor<1200x128xi32> to memref<1200x128xi32>
    %54 = bufferization.to_buffer %arg103 : tensor<128x128xi8> to memref<128x128xi8>
    %55 = bufferization.to_buffer %arg102 : tensor<1200x64xi32> to memref<1200x64xi32>
    %56 = bufferization.to_buffer %arg101 : tensor<128x64xi8> to memref<128x64xi8>
    %57 = bufferization.to_buffer %arg100 : tensor<64xi32> to memref<64xi32>
    %58 = bufferization.to_buffer %arg99 : tensor<576x64xi8> to memref<576x64xi8>
    %59 = bufferization.to_buffer %arg98 : tensor<1200x64xi32> to memref<1200x64xi32>
    %60 = bufferization.to_buffer %arg97 : tensor<64x64xi8> to memref<64x64xi8>
    %61 = bufferization.to_buffer %arg96 : tensor<1200x64xi32> to memref<1200x64xi32>
    %62 = bufferization.to_buffer %arg95 : tensor<128x64xi8> to memref<128x64xi8>
    %63 = bufferization.to_buffer %arg94 : tensor<64xi32> to memref<64xi32>
    %64 = bufferization.to_buffer %arg93 : tensor<576x64xi8> to memref<576x64xi8>
    %65 = bufferization.to_buffer %arg92 : tensor<4800x64xi32> to memref<4800x64xi32>
    %66 = bufferization.to_buffer %arg91 : tensor<64x64xi8> to memref<64x64xi8>
    %67 = bufferization.to_buffer %arg90 : tensor<4800x32xi32> to memref<4800x32xi32>
    %68 = bufferization.to_buffer %arg89 : tensor<128x32xi8> to memref<128x32xi8>
    %69 = bufferization.to_buffer %arg88 : tensor<32xi32> to memref<32xi32>
    %70 = bufferization.to_buffer %arg87 : tensor<288x32xi8> to memref<288x32xi8>
    %71 = bufferization.to_buffer %arg86 : tensor<4800x32xi32> to memref<4800x32xi32>
    %72 = bufferization.to_buffer %arg85 : tensor<32x32xi8> to memref<32x32xi8>
    %73 = bufferization.to_buffer %arg84 : tensor<4800x32xi32> to memref<4800x32xi32>
    %74 = bufferization.to_buffer %arg83 : tensor<128x32xi8> to memref<128x32xi8>
    %75 = bufferization.to_buffer %arg81 : tensor<1200x64xi32> to memref<1200x64xi32>
    %76 = bufferization.to_buffer %arg80 : tensor<128x64xi8> to memref<128x64xi8>
    %77 = bufferization.to_buffer %arg79 : tensor<1200x128xi32> to memref<1200x128xi32>
    %78 = bufferization.to_buffer %arg78 : tensor<128x128xi8> to memref<128x128xi8>
    %79 = bufferization.to_buffer %arg77 : tensor<1200x64xi32> to memref<1200x64xi32>
    %80 = bufferization.to_buffer %arg76 : tensor<256x64xi8> to memref<256x64xi8>
    %81 = bufferization.to_buffer %arg75 : tensor<64xi32> to memref<64xi32>
    %82 = bufferization.to_buffer %arg74 : tensor<576x64xi8> to memref<576x64xi8>
    %83 = bufferization.to_buffer %arg73 : tensor<1200x64xi32> to memref<1200x64xi32>
    %84 = bufferization.to_buffer %arg72 : tensor<64x64xi8> to memref<64x64xi8>
    %85 = bufferization.to_buffer %arg71 : tensor<1200x64xi32> to memref<1200x64xi32>
    %86 = bufferization.to_buffer %arg70 : tensor<256x64xi8> to memref<256x64xi8>
    %87 = bufferization.to_buffer %arg68 : tensor<304x128xi32> to memref<304x128xi32>
    %88 = bufferization.to_buffer %arg67 : tensor<256x128xi8> to memref<256x128xi8>
    %89 = bufferization.to_buffer %arg66 : tensor<304x256xi32> to memref<304x256xi32>
    %90 = bufferization.to_buffer %arg65 : tensor<512x256xi8> to memref<512x256xi8>
    %91 = bufferization.to_buffer %arg64 : tensor<304x128xi32> to memref<304x128xi32>
    %92 = bufferization.to_buffer %arg63 : tensor<256x128xi8> to memref<256x128xi8>
    %93 = bufferization.to_buffer %arg62 : tensor<304x256xi32> to memref<304x256xi32>
    %94 = bufferization.to_buffer %arg61 : tensor<256x256xi8> to memref<256x256xi8>
    %95 = bufferization.to_buffer %arg60 : tensor<304x128xi32> to memref<304x128xi32>
    %96 = bufferization.to_buffer %arg59 : tensor<256x128xi8> to memref<256x128xi8>
    %97 = bufferization.to_buffer %arg58 : tensor<128xi32> to memref<128xi32>
    %98 = bufferization.to_buffer %arg57 : tensor<1152x128xi8> to memref<1152x128xi8>
    %99 = bufferization.to_buffer %arg56 : tensor<304x128xi32> to memref<304x128xi32>
    %100 = bufferization.to_buffer %arg55 : tensor<128x128xi8> to memref<128x128xi8>
    %101 = bufferization.to_buffer %arg54 : tensor<304x128xi32> to memref<304x128xi32>
    %102 = bufferization.to_buffer %arg53 : tensor<256x128xi8> to memref<256x128xi8>
    %103 = bufferization.to_buffer %arg52 : tensor<256xi32> to memref<256xi32>
    %104 = bufferization.to_buffer %arg51 : tensor<1152x256xi8> to memref<1152x256xi8>
    %105 = bufferization.to_buffer %arg50 : tensor<1200x128xi32> to memref<1200x128xi32>
    %106 = bufferization.to_buffer %arg49 : tensor<128x128xi8> to memref<128x128xi8>
    %107 = bufferization.to_buffer %arg48 : tensor<1200x64xi32> to memref<1200x64xi32>
    %108 = bufferization.to_buffer %arg47 : tensor<128x64xi8> to memref<128x64xi8>
    %109 = bufferization.to_buffer %arg46 : tensor<64xi32> to memref<64xi32>
    %110 = bufferization.to_buffer %arg45 : tensor<576x64xi8> to memref<576x64xi8>
    %111 = bufferization.to_buffer %arg44 : tensor<1200x64xi32> to memref<1200x64xi32>
    %112 = bufferization.to_buffer %arg43 : tensor<64x64xi8> to memref<64x64xi8>
    %113 = bufferization.to_buffer %arg42 : tensor<64xi32> to memref<64xi32>
    %114 = bufferization.to_buffer %arg41 : tensor<576x64xi8> to memref<576x64xi8>
    %115 = bufferization.to_buffer %arg40 : tensor<1200x64xi32> to memref<1200x64xi32>
    %116 = bufferization.to_buffer %arg39 : tensor<64x64xi8> to memref<64x64xi8>
    %117 = bufferization.to_buffer %arg38 : tensor<64xi32> to memref<64xi32>
    %118 = bufferization.to_buffer %arg37 : tensor<576x64xi8> to memref<576x64xi8>
    %119 = bufferization.to_buffer %arg36 : tensor<1200x64xi32> to memref<1200x64xi32>
    %120 = bufferization.to_buffer %arg35 : tensor<64x64xi8> to memref<64x64xi8>
    %121 = bufferization.to_buffer %arg34 : tensor<1200x64xi32> to memref<1200x64xi32>
    %122 = bufferization.to_buffer %arg33 : tensor<128x64xi8> to memref<128x64xi8>
    %123 = bufferization.to_buffer %arg32 : tensor<128xi32> to memref<128xi32>
    %124 = bufferization.to_buffer %arg31 : tensor<576x128xi8> to memref<576x128xi8>
    %125 = bufferization.to_buffer %arg30 : tensor<4800x64xi32> to memref<4800x64xi32>
    %126 = bufferization.to_buffer %arg29 : tensor<64x64xi8> to memref<64x64xi8>
    %127 = bufferization.to_buffer %arg28 : tensor<4800x32xi32> to memref<4800x32xi32>
    %128 = bufferization.to_buffer %arg27 : tensor<64x32xi8> to memref<64x32xi8>
    %129 = bufferization.to_buffer %arg26 : tensor<32xi32> to memref<32xi32>
    %130 = bufferization.to_buffer %arg25 : tensor<288x32xi8> to memref<288x32xi8>
    %131 = bufferization.to_buffer %arg24 : tensor<4800x32xi32> to memref<4800x32xi32>
    %132 = bufferization.to_buffer %arg23 : tensor<32x32xi8> to memref<32x32xi8>
    %133 = bufferization.to_buffer %arg22 : tensor<32xi32> to memref<32xi32>
    %134 = bufferization.to_buffer %arg21 : tensor<288x32xi8> to memref<288x32xi8>
    %135 = bufferization.to_buffer %arg20 : tensor<4800x32xi32> to memref<4800x32xi32>
    %136 = bufferization.to_buffer %arg19 : tensor<32x32xi8> to memref<32x32xi8>
    %137 = bufferization.to_buffer %arg18 : tensor<4800x32xi32> to memref<4800x32xi32>
    %138 = bufferization.to_buffer %arg17 : tensor<64x32xi8> to memref<64x32xi8>
    %139 = bufferization.to_buffer %arg16 : tensor<64xi32> to memref<64xi32>
    %140 = bufferization.to_buffer %arg15 : tensor<288x64xi8> to memref<288x64xi8>
    %141 = bufferization.to_buffer %arg14 : tensor<19200x32xi32> to memref<19200x32xi32>
    %142 = bufferization.to_buffer %arg13 : tensor<32x32xi8> to memref<32x32xi8>
    %143 = bufferization.to_buffer %arg12 : tensor<19200x16xi32> to memref<19200x16xi32>
    %144 = bufferization.to_buffer %arg11 : tensor<32x16xi8> to memref<32x16xi8>
    %145 = bufferization.to_buffer %arg10 : tensor<16xi32> to memref<16xi32>
    %146 = bufferization.to_buffer %arg9 : tensor<144x16xi8> to memref<144x16xi8>
    %147 = bufferization.to_buffer %arg8 : tensor<19200x16xi32> to memref<19200x16xi32>
    %148 = bufferization.to_buffer %arg7 : tensor<16x16xi8> to memref<16x16xi8>
    %149 = bufferization.to_buffer %arg6 : tensor<19200x16xi32> to memref<19200x16xi32>
    %150 = bufferization.to_buffer %arg5 : tensor<32x16xi8> to memref<32x16xi8>
    %151 = bufferization.to_buffer %arg4 : tensor<32xi32> to memref<32xi32>
    %152 = bufferization.to_buffer %arg3 : tensor<144x32xi8> to memref<144x32xi8>
    %153 = bufferization.to_buffer %arg2 : tensor<16xi32> to memref<16xi32>
    %154 = bufferization.to_buffer %arg1 : tensor<108x16xi8> to memref<108x16xi8>
    %155 = bufferization.to_buffer %arg0 : tensor<1x480x640x3xi8> to memref<1x480x640x3xi8>
    %156 = memref.get_global @__constant_1x1x1xf32 : memref<1x1x1xf32>
    %157 = memref.get_global @__constant_1x1x1xf32_0 : memref<1x1x1xf32>
    %158 = memref.get_global @__constant_1x1x1xf32_1 : memref<1x1x1xf32>
    %159 = memref.get_global @__constant_1x1x1xf32_2 : memref<1x1x1xf32>
    %160 = memref.get_global @__constant_1x1x1x1xf32 : memref<1x1x1x1xf32>
    %161 = memref.get_global @__constant_1x1x1x1xf32_4 : memref<1x1x1x1xf32>
    %162 = memref.get_global @__constant_1x1x1x1xf32_5 : memref<1x1x1x1xf32>
    %163 = memref.get_global @__constant_1x1x1xf32_6 : memref<1x1x1xf32>
    %164 = memref.get_global @__constant_1x1x1xf32_7 : memref<1x1x1xf32>
    %165 = memref.get_global @__constant_1x1x1x1xf32_8 : memref<1x1x1x1xf32>
    %166 = memref.get_global @__constant_1x1x1x1xf32_10 : memref<1x1x1x1xf32>
    %167 = memref.get_global @__constant_1x1x1x1xf32_13 : memref<1x1x1x1xf32>
    %168 = memref.get_global @__constant_1x1x1x1xf32_16 : memref<1x1x1x1xf32>
    %169 = memref.get_global @__constant_1x1x1x1xf32_18 : memref<1x1x1x1xf32>
    %170 = memref.get_global @__constant_1x1x1x1xf32_21 : memref<1x1x1x1xf32>
    %171 = memref.get_global @__constant_1x1x1x1xf32_24 : memref<1x1x1x1xf32>
    %172 = memref.get_global @__constant_1x1x1x1xf32_26 : memref<1x1x1x1xf32>
    %173 = memref.get_global @__constant_1x1x1x1xf32_29 : memref<1x1x1x1xf32>
    %174 = memref.get_global @__constant_1x1x1xf32_32 : memref<1x1x1xf32>
    %175 = memref.get_global @__constant_1x1x1xf32_33 : memref<1x1x1xf32>
    %176 = memref.get_global @__constant_1x1x1x1xf32_34 : memref<1x1x1x1xf32>
    %177 = memref.get_global @__constant_1x1x1x1xf32_36 : memref<1x1x1x1xf32>
    %178 = memref.get_global @__constant_1x1x1x1xf32_39 : memref<1x1x1x1xf32>
    %179 = memref.get_global @__constant_1x1x1x1xf32_42 : memref<1x1x1x1xf32>
    %180 = memref.get_global @__constant_1x1x1x1xf32_44 : memref<1x1x1x1xf32>
    %181 = memref.get_global @__constant_1x1x1x1xf32_47 : memref<1x1x1x1xf32>
    %182 = memref.get_global @__constant_1x1x1x1xf32_50 : memref<1x1x1x1xf32>
    %183 = memref.get_global @__constant_1x1x1x1xf32_52 : memref<1x1x1x1xf32>
    %184 = memref.get_global @__constant_1x1x1x1xf32_55 : memref<1x1x1x1xf32>
    %185 = memref.get_global @__constant_1x1x1x1xf32_58 : memref<1x1x1x1xf32>
    %186 = memref.get_global @__constant_1x1x1x1xi32 : memref<1x1x1x1xi32>
    %187 = memref.get_global @__constant_1x1x1x1xi32_61 : memref<1x1x1x1xi32>
    %188 = memref.get_global @__constant_1x1x1x1xf32_62 : memref<1x1x1x1xf32>
    %189 = memref.get_global @__constant_1x1x1x1xf32_64 : memref<1x1x1x1xf32>
    %190 = memref.get_global @__constant_1x1x1x1xf32_67 : memref<1x1x1x1xf32>
    %191 = memref.get_global @__constant_1x1x1x1xf32_70 : memref<1x1x1x1xf32>
    %192 = memref.get_global @__constant_1x1x1x1xi32_73 : memref<1x1x1x1xi32>
    %193 = memref.get_global @__constant_1x1x1x1xi32_74 : memref<1x1x1x1xi32>
    %194 = memref.get_global @__constant_1x1x1x1xf32_75 : memref<1x1x1x1xf32>
    %195 = memref.get_global @__constant_1x1x1x1xf32_77 : memref<1x1x1x1xf32>
    %196 = memref.get_global @__constant_1x1x1x1xi32_80 : memref<1x1x1x1xi32>
    %197 = memref.get_global @__constant_1x1x1x1xi32_81 : memref<1x1x1x1xi32>
    %198 = memref.get_global @__constant_1x1x1x1xf32_82 : memref<1x1x1x1xf32>
    %199 = memref.get_global @__constant_1x1x1x1xf32_84 : memref<1x1x1x1xf32>
    %200 = memref.get_global @__constant_1x1x1x1xf32_87 : memref<1x1x1x1xf32>
    %201 = memref.get_global @__constant_1x1x1x1xf32_90 : memref<1x1x1x1xf32>
    %202 = memref.get_global @__constant_1x1x1x1xi32_93 : memref<1x1x1x1xi32>
    %203 = memref.get_global @__constant_1x1x1x1xi32_94 : memref<1x1x1x1xi32>
    %204 = memref.get_global @__constant_1x1x1x1xf32_95 : memref<1x1x1x1xf32>
    %205 = memref.get_global @__constant_1x1x1x1xf32_98 : memref<1x1x1x1xf32>
    %206 = memref.get_global @__constant_1x1x1x1xi32_101 : memref<1x1x1x1xi32>
    %207 = memref.get_global @__constant_1x1x1x1xi32_102 : memref<1x1x1x1xi32>
    %208 = memref.get_global @__constant_1x1x1x1xf32_103 : memref<1x1x1x1xf32>
    %209 = memref.get_global @__constant_1x1x1x1xf32_105 : memref<1x1x1x1xf32>
    %210 = memref.get_global @__constant_1x1x1x1xf32_108 : memref<1x1x1x1xf32>
    %211 = memref.get_global @__constant_1x1x1x1xf32_111 : memref<1x1x1x1xf32>
    %212 = memref.get_global @__constant_1x1x1x1xi32_114 : memref<1x1x1x1xi32>
    %213 = memref.get_global @__constant_1x1x1x1xi32_115 : memref<1x1x1x1xi32>
    %214 = memref.get_global @__constant_1x1x1x1xf32_116 : memref<1x1x1x1xf32>
    %215 = memref.get_global @__constant_1x1x1x1xf32_119 : memref<1x1x1x1xf32>
    %216 = memref.get_global @__constant_1x1x1x1xi32_122 : memref<1x1x1x1xi32>
    %217 = memref.get_global @__constant_1x1x1x1xi32_123 : memref<1x1x1x1xi32>
    %218 = memref.get_global @__constant_1x1x1x1xf32_124 : memref<1x1x1x1xf32>
    %219 = memref.get_global @__constant_1x1x1x1xf32_126 : memref<1x1x1x1xf32>
    %220 = memref.get_global @__constant_1x1x1x1xf32_129 : memref<1x1x1x1xf32>
    %221 = memref.get_global @__constant_1x1x1x1xf32_132 : memref<1x1x1x1xf32>
    %222 = memref.get_global @__constant_1x1x1x1xi32_135 : memref<1x1x1x1xi32>
    %223 = memref.get_global @__constant_1x1x1x1xi32_136 : memref<1x1x1x1xi32>
    %224 = memref.get_global @__constant_1x1x1x1xf32_137 : memref<1x1x1x1xf32>
    %225 = memref.get_global @__constant_1x1x1x1xf32_140 : memref<1x1x1x1xf32>
    %226 = memref.get_global @__constant_1x1x1x1xf32_143 : memref<1x1x1x1xf32>
    %227 = memref.get_global @__constant_1x1x1x1xf32_146 : memref<1x1x1x1xf32>
    %228 = memref.get_global @__constant_1x1x1x1xi32_149 : memref<1x1x1x1xi32>
    %229 = memref.get_global @__constant_1x1x1x1xf32_150 : memref<1x1x1x1xf32>
    %230 = memref.get_global @__constant_1x1x1x1xi32_152 : memref<1x1x1x1xi32>
    %231 = memref.get_global @__constant_1x1x1x1xi32_153 : memref<1x1x1x1xi32>
    %232 = memref.get_global @__constant_1x1x1x1xf32_154 : memref<1x1x1x1xf32>
    %233 = memref.get_global @__constant_1x1x1x1xf32_157 : memref<1x1x1x1xf32>
    %234 = memref.get_global @__constant_1x1x1x1xf32_160 : memref<1x1x1x1xf32>
    %235 = memref.get_global @__constant_1x1x1x1xf32_163 : memref<1x1x1x1xf32>
    %236 = memref.get_global @__constant_1x1x1x1xf32_166 : memref<1x1x1x1xf32>
    %237 = memref.get_global @__constant_1x1x1x1xi32_169 : memref<1x1x1x1xi32>
    %238 = memref.get_global @__constant_1x1x1x1xf32_170 : memref<1x1x1x1xf32>
    %239 = memref.get_global @__constant_1x1x1x1xi32_172 : memref<1x1x1x1xi32>
    %240 = memref.get_global @__constant_1x1x1x1xi32_173 : memref<1x1x1x1xi32>
    %241 = memref.get_global @__constant_1x1x1x1xf32_174 : memref<1x1x1x1xf32>
    %242 = memref.get_global @__constant_1x1x1x1xf32_177 : memref<1x1x1x1xf32>
    %243 = memref.get_global @__constant_1x1x1x1xi32_180 : memref<1x1x1x1xi32>
    %244 = memref.get_global @__constant_1x1x1x1xi32_181 : memref<1x1x1x1xi32>
    %245 = memref.get_global @__constant_1x1x1x1xf32_182 : memref<1x1x1x1xf32>
    %246 = memref.get_global @__constant_1x1x1x1xf32_185 : memref<1x1x1x1xf32>
    %247 = memref.get_global @__constant_1x1x1x1xi32_188 : memref<1x1x1x1xi32>
    %248 = memref.get_global @__constant_1x1x1x1xi32_189 : memref<1x1x1x1xi32>
    %249 = memref.get_global @__constant_1x1x1x1xf32_190 : memref<1x1x1x1xf32>
    %250 = memref.get_global @__constant_1x1x1x1xf32_193 : memref<1x1x1x1xf32>
    %251 = memref.get_global @__constant_1x1x1x1xf32_196 : memref<1x1x1x1xf32>
    %252 = memref.get_global @__constant_1x1x1x1xf32_199 : memref<1x1x1x1xf32>
    %253 = memref.get_global @__constant_1x1x1x1xf32_202 : memref<1x1x1x1xf32>
    %254 = memref.get_global @__constant_1x1x1x1xi32_205 : memref<1x1x1x1xi32>
    %255 = memref.get_global @__constant_1x1x1x1xi32_206 : memref<1x1x1x1xi32>
    %256 = memref.get_global @__constant_1x1x1x1xf32_207 : memref<1x1x1x1xf32>
    %257 = memref.get_global @__constant_1x1x1x1xi32_209 : memref<1x1x1x1xi32>
    %258 = memref.get_global @__constant_1x1x1x1xi32_210 : memref<1x1x1x1xi32>
    %259 = memref.get_global @__constant_1x1x1x1xf32_211 : memref<1x1x1x1xf32>
    %260 = memref.get_global @__constant_1x1x1x1xf32_214 : memref<1x1x1x1xf32>
    %261 = memref.get_global @__constant_1x1x1x1xi32_217 : memref<1x1x1x1xi32>
    %262 = memref.get_global @__constant_1x1x1x1xi32_218 : memref<1x1x1x1xi32>
    %263 = memref.get_global @__constant_1x1x1x1xf32_219 : memref<1x1x1x1xf32>
    %264 = memref.get_global @__constant_1x1x1x1xf32_222 : memref<1x1x1x1xf32>
    %265 = memref.get_global @__constant_1x1x1x1xf32_225 : memref<1x1x1x1xf32>
    %266 = memref.get_global @__constant_1x1x1x1xf32_228 : memref<1x1x1x1xf32>
    %267 = memref.get_global @__constant_1x1x1x1xf32_231 : memref<1x1x1x1xf32>
    %268 = memref.get_global @__constant_1x1x1x1xi32_234 : memref<1x1x1x1xi32>
    %269 = memref.get_global @__constant_1x1x1x1xi32_235 : memref<1x1x1x1xi32>
    %270 = memref.get_global @__constant_1x1x1x1xf32_236 : memref<1x1x1x1xf32>
    %271 = memref.get_global @__constant_1x1x1x1xi32_238 : memref<1x1x1x1xi32>
    %272 = memref.get_global @__constant_1x1x1x1xi32_239 : memref<1x1x1x1xi32>
    %273 = memref.get_global @__constant_1x1x1x1xi32_240 : memref<1x1x1x1xi32>
    %274 = memref.get_global @__constant_1x1x1x1xi32_241 : memref<1x1x1x1xi32>
    %275 = memref.get_global @__constant_1x1x1x1xi32_242 : memref<1x1x1x1xi32>
    %276 = memref.get_global @__constant_1x1x1x1xf32_243 : memref<1x1x1x1xf32>
    %277 = memref.get_global @__constant_1x1x1x1xf32_246 : memref<1x1x1x1xf32>
    %278 = memref.get_global @__constant_1x1x1x1xf32_249 : memref<1x1x1x1xf32>
    %279 = memref.get_global @__constant_1x1x1x1xf32_252 : memref<1x1x1x1xf32>
    %280 = memref.get_global @__constant_1x1x1x1xf32_255 : memref<1x1x1x1xf32>
    %281 = memref.get_global @__constant_1xi32 : memref<1xi32>
    %alloc = memref.alloc() {alignment = 64 : i64} : memref<1x484x644x3xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c484 step %c1 {
        scf.for %arg168 = %c0 to %c644 step %c1 {
          scf.for %arg169 = %c0 to %c3 step %c1 {
            memref.store %c0_i8, %alloc[%arg166, %arg167, %arg168, %arg169] : memref<1x484x644x3xi8>
          }
        }
      }
    }
    %subview = memref.subview %alloc[0, 2, 2, 0] [1, 480, 640, 3] [1, 1, 1, 1] : memref<1x484x644x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    memref.copy %155, %subview : memref<1x480x640x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    %alloc_66 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c240 step %c1 {
        scf.for %arg168 = %c0 to %c320 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %153[%arg169] : memref<16xi32>
            memref.store %646, %alloc_66[%arg166, %arg167, %arg168, %arg169] : memref<1x240x320x16xi32>
          }
        }
      }
    }
    %alloc_67 = memref.alloc() {alignment = 64 : i64} : memref<76800x16xi8>
    gemmini.tile_conv %alloc %154 %153 %alloc_67 %c240_i64 %c320_i64 %c6_i64 {scale = 0.00288073183 : f32, stride = 2 : i64} : memref<1x484x644x3xi8> memref<108x16xi8> memref<16xi32> memref<76800x16xi8> i64 i64 i64
    %alloc_68 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xf32>
    %intptr = memref.extract_aligned_pointer_as_index %alloc_68 : memref<1x240x320x16xf32> -> index
    %intptr_69 = memref.extract_aligned_pointer_as_index %alloc_67 : memref<76800x16xi8> -> index
    %282 = arith.index_cast %intptr : index to i64
    %283 = arith.index_cast %intptr_69 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%282, %283, %c1_i64, %c240_i64, %c320_i64, %c16_i64, %cst_60) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_67 : memref<76800x16xi8>
    %alloc_70 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c240 step %c1 {
          scf.for %arg169 = %c0 to %c320 step %c1 {
            %646 = memref.load %alloc_68[%arg166, %arg168, %arg169, %arg167] : memref<1x240x320x16xf32>
            memref.store %646, %alloc_70[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_71 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    memref.copy %alloc_70, %alloc_71 : memref<1x16x240x320xf32> to memref<1x16x240x320xf32>
    %alloc_72 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c240 step %c1 {
          scf.for %arg169 = %c0 to %c320 step %c1 {
            %646 = memref.load %alloc_71[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
            %647 = memref.load %280[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_72[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_73 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c240 step %c1 {
          scf.for %arg169 = %c0 to %c320 step %c1 {
            %646 = memref.load %alloc_72[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_73[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_74 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c240 step %c1 {
          scf.for %arg169 = %c0 to %c320 step %c1 {
            %646 = memref.load %alloc_73[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_74[%arg166, %arg167, %arg168, %arg169] : memref<1x16x240x320xi8>
          }
        }
      }
    }
    %alloc_75 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c240 step %c1 {
        scf.for %arg168 = %c0 to %c320 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_74[%arg166, %arg169, %arg167, %arg168] : memref<1x16x240x320xi8>
            memref.store %646, %alloc_75[%arg166, %arg167, %arg168, %arg169] : memref<1x240x320x16xi8>
          }
        }
      }
    }
    %alloc_76 = memref.alloc() {alignment = 64 : i64} : memref<1x241x321x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c241 step %c1 {
        scf.for %arg168 = %c0 to %c321 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            memref.store %c0_i8, %alloc_76[%arg166, %arg167, %arg168, %arg169] : memref<1x241x321x16xi8>
          }
        }
      }
    }
    %subview_77 = memref.subview %alloc_76[0, 1, 1, 0] [1, 240, 320, 16] [1, 1, 1, 1] : memref<1x241x321x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    memref.copy %alloc_75, %subview_77 : memref<1x240x320x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    %alloc_78 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %151[%arg169] : memref<32xi32>
            memref.store %646, %alloc_78[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x32xi32>
          }
        }
      }
    }
    %alloc_79 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    gemmini.tile_conv %alloc_76 %152 %151 %alloc_79 %c120_i64 %c160_i64 %c3_i64 {scale = 5.703000e-03 : f32, stride = 2 : i64} : memref<1x241x321x16xi8> memref<144x32xi8> memref<32xi32> memref<19200x32xi8> i64 i64 i64
    %alloc_80 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    %intptr_81 = memref.extract_aligned_pointer_as_index %alloc_80 : memref<1x120x160x32xf32> -> index
    %intptr_82 = memref.extract_aligned_pointer_as_index %alloc_79 : memref<19200x32xi8> -> index
    %284 = arith.index_cast %intptr_81 : index to i64
    %285 = arith.index_cast %intptr_82 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%284, %285, %c1_i64, %c120_i64, %c160_i64, %c32_i64, %cst_57) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_79 : memref<19200x32xi8>
    %alloc_83 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_80[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x32xf32>
            memref.store %646, %alloc_83[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_84 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    memref.copy %alloc_83, %alloc_84 : memref<1x32x120x160xf32> to memref<1x32x120x160xf32>
    %alloc_85 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_84[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = memref.load %279[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_85[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_86 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_85[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_86[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_87 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_86[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_87[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xi8>
          }
        }
      }
    }
    %alloc_88 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_87[%arg166, %arg169, %arg167, %arg168] : memref<1x32x120x160xi8>
            memref.store %646, %alloc_88[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_89 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_90 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_91 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_92 = memref.extract_aligned_pointer_as_index %alloc_88 : memref<1x120x160x32xi8> -> index
    %286 = arith.index_cast %intptr_92 : index to i64
    %intptr_93 = memref.extract_aligned_pointer_as_index %alloc_90 : memref<19200x32xi8> -> index
    %287 = arith.index_cast %intptr_93 : index to i64
    %intptr_94 = memref.extract_aligned_pointer_as_index %alloc_91 : memref<19200x16xi8> -> index
    %288 = arith.index_cast %intptr_94 : index to i64
    %intptr_95 = memref.extract_aligned_pointer_as_index %alloc_89 : memref<19200x16xi8> -> index
    %289 = arith.index_cast %intptr_95 : index to i64
    call @buddy_rvv_memcpy_i8(%287, %286, %c614400_i64) : (i64, i64, i64) -> ()
    %290 = arith.addi %287, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%290, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_90 %150 %alloc_91 %149 {accScale = 0.0475858524 : f32} : memref<19200x32xi8> memref<32x16xi8> memref<19200x16xi8> memref<19200x16xi32>
    call @buddy_rvv_copy_rows_i8(%289, %288, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_90 : memref<19200x32xi8>
    memref.dealloc %alloc_91 : memref<19200x16xi8>
    %alloc_96 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_97 = memref.extract_aligned_pointer_as_index %alloc_96 : memref<1x120x160x16xf32> -> index
    %intptr_98 = memref.extract_aligned_pointer_as_index %alloc_89 : memref<19200x16xi8> -> index
    %291 = arith.index_cast %intptr_97 : index to i64
    %292 = arith.index_cast %intptr_98 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%291, %292, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_56) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_89 : memref<19200x16xi8>
    %alloc_99 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_96[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x16xf32>
            memref.store %646, %alloc_99[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_100 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_99, %alloc_100 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_101 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_100[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = memref.load %278[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_101[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_102 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_101[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_102[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_103 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_102[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_103[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_104 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_103[%arg166, %arg169, %arg167, %arg168] : memref<1x16x120x160xi8>
            memref.store %646, %alloc_104[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x16xi8>
          }
        }
      }
    }
    %alloc_105 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_106 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_107 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_108 = memref.extract_aligned_pointer_as_index %alloc_104 : memref<1x120x160x16xi8> -> index
    %293 = arith.index_cast %intptr_108 : index to i64
    %intptr_109 = memref.extract_aligned_pointer_as_index %alloc_106 : memref<19200x16xi8> -> index
    %294 = arith.index_cast %intptr_109 : index to i64
    %intptr_110 = memref.extract_aligned_pointer_as_index %alloc_107 : memref<19200x16xi8> -> index
    %295 = arith.index_cast %intptr_110 : index to i64
    %intptr_111 = memref.extract_aligned_pointer_as_index %alloc_105 : memref<19200x16xi8> -> index
    %296 = arith.index_cast %intptr_111 : index to i64
    call @buddy_rvv_memcpy_i8(%294, %293, %c307200_i64) : (i64, i64, i64) -> ()
    %297 = arith.addi %294, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%297, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_106 %148 %alloc_107 %147 {accScale = 0.0180469286 : f32} : memref<19200x16xi8> memref<16x16xi8> memref<19200x16xi8> memref<19200x16xi32>
    call @buddy_rvv_copy_rows_i8(%296, %295, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_106 : memref<19200x16xi8>
    memref.dealloc %alloc_107 : memref<19200x16xi8>
    %alloc_112 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_113 = memref.extract_aligned_pointer_as_index %alloc_112 : memref<1x120x160x16xf32> -> index
    %intptr_114 = memref.extract_aligned_pointer_as_index %alloc_105 : memref<19200x16xi8> -> index
    %298 = arith.index_cast %intptr_113 : index to i64
    %299 = arith.index_cast %intptr_114 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%298, %299, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_55) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_105 : memref<19200x16xi8>
    %alloc_115 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_112[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x16xf32>
            memref.store %646, %alloc_115[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_116 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_115, %alloc_116 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_117 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_116[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = memref.load %277[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_117[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_118 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_117[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_118[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_119 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_118[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_119[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_120 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_119[%arg166, %arg169, %arg167, %arg168] : memref<1x16x120x160xi8>
            memref.store %646, %alloc_120[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x16xi8>
          }
        }
      }
    }
    %alloc_121 = memref.alloc() {alignment = 64 : i64} : memref<1x122x162x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c122 step %c1 {
        scf.for %arg168 = %c0 to %c162 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            memref.store %c0_i8, %alloc_121[%arg166, %arg167, %arg168, %arg169] : memref<1x122x162x16xi8>
          }
        }
      }
    }
    %subview_122 = memref.subview %alloc_121[0, 1, 1, 0] [1, 120, 160, 16] [1, 1, 1, 1] : memref<1x122x162x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    memref.copy %alloc_120, %subview_122 : memref<1x120x160x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    %alloc_123 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %145[%arg169] : memref<16xi32>
            memref.store %646, %alloc_123[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x16xi32>
          }
        }
      }
    }
    %alloc_124 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    gemmini.tile_conv %alloc_121 %146 %145 %alloc_124 %c120_i64 %c160_i64 %c3_i64 {scale = 0.0068890308 : f32} : memref<1x122x162x16xi8> memref<144x16xi8> memref<16xi32> memref<19200x16xi8> i64 i64 i64
    %alloc_125 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_126 = memref.extract_aligned_pointer_as_index %alloc_125 : memref<1x120x160x16xf32> -> index
    %intptr_127 = memref.extract_aligned_pointer_as_index %alloc_124 : memref<19200x16xi8> -> index
    %300 = arith.index_cast %intptr_126 : index to i64
    %301 = arith.index_cast %intptr_127 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%300, %301, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_54) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_124 : memref<19200x16xi8>
    %alloc_128 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_125[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x16xf32>
            memref.store %646, %alloc_128[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_129 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_128, %alloc_129 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_130 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_129[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = memref.load %276[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_130[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_131 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_130[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_131[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_132 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_131[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_132[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_133 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_103[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_133[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_134 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_133[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %275[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_134[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_135 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_134[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_135[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_136 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_132[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_136[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_137 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_136[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %273[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_137[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_138 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_137[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_138[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_139 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_135[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %alloc_138[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_139[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_140 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_139[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_140[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_141 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_140[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_141[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_142 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_141[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_142[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_143 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_87[%arg166, %arg169, %arg167, %arg168] : memref<1x32x120x160xi8>
            memref.store %646, %alloc_143[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_144 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_145 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_146 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_147 = memref.extract_aligned_pointer_as_index %alloc_143 : memref<1x120x160x32xi8> -> index
    %302 = arith.index_cast %intptr_147 : index to i64
    %intptr_148 = memref.extract_aligned_pointer_as_index %alloc_145 : memref<19200x32xi8> -> index
    %303 = arith.index_cast %intptr_148 : index to i64
    %intptr_149 = memref.extract_aligned_pointer_as_index %alloc_146 : memref<19200x16xi8> -> index
    %304 = arith.index_cast %intptr_149 : index to i64
    %intptr_150 = memref.extract_aligned_pointer_as_index %alloc_144 : memref<19200x16xi8> -> index
    %305 = arith.index_cast %intptr_150 : index to i64
    call @buddy_rvv_memcpy_i8(%303, %302, %c614400_i64) : (i64, i64, i64) -> ()
    %306 = arith.addi %303, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%306, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_145 %144 %alloc_146 %143 {accScale = 0.0373886824 : f32} : memref<19200x32xi8> memref<32x16xi8> memref<19200x16xi8> memref<19200x16xi32>
    call @buddy_rvv_copy_rows_i8(%305, %304, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_145 : memref<19200x32xi8>
    memref.dealloc %alloc_146 : memref<19200x16xi8>
    %alloc_151 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_152 = memref.extract_aligned_pointer_as_index %alloc_151 : memref<1x120x160x16xf32> -> index
    %intptr_153 = memref.extract_aligned_pointer_as_index %alloc_144 : memref<19200x16xi8> -> index
    %307 = arith.index_cast %intptr_152 : index to i64
    %308 = arith.index_cast %intptr_153 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%307, %308, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_54) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_144 : memref<19200x16xi8>
    %alloc_154 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_151[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x16xf32>
            memref.store %646, %alloc_154[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_155 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_154, %alloc_155 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_156 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_155[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = memref.load %270[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_156[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_157 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_156[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_157[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_158 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_157[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_158[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_159 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_142[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_159[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_160 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_159[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %269[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_160[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_161 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_160[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_161[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_162 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_161[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_162[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_163 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_162[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_163[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_164 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_163[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_164[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_165 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_158[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_165[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_166 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_165[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %268[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_166[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_167 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_166[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_167[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_168 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_167[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_168[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_169 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_168[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_169[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_170 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_169[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_170[%arg166, %arg167, %arg168, %arg169] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_171 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    %subview_172 = memref.subview %alloc_171[0, 0, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    memref.copy %alloc_164, %subview_172 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    %subview_173 = memref.subview %alloc_171[0, 16, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    memref.copy %alloc_170, %subview_173 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    %alloc_174 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_171[%arg166, %arg169, %arg167, %arg168] : memref<1x32x120x160xi8>
            memref.store %646, %alloc_174[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_175 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_176 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_177 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %intptr_178 = memref.extract_aligned_pointer_as_index %alloc_174 : memref<1x120x160x32xi8> -> index
    %309 = arith.index_cast %intptr_178 : index to i64
    %intptr_179 = memref.extract_aligned_pointer_as_index %alloc_176 : memref<19200x32xi8> -> index
    %310 = arith.index_cast %intptr_179 : index to i64
    %intptr_180 = memref.extract_aligned_pointer_as_index %alloc_177 : memref<19200x32xi8> -> index
    %311 = arith.index_cast %intptr_180 : index to i64
    %intptr_181 = memref.extract_aligned_pointer_as_index %alloc_175 : memref<19200x32xi8> -> index
    %312 = arith.index_cast %intptr_181 : index to i64
    call @buddy_rvv_memcpy_i8(%310, %309, %c614400_i64) : (i64, i64, i64) -> ()
    %313 = arith.addi %310, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%313, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_176 %142 %alloc_177 %141 {accScale = 8.487220e-03 : f32} : memref<19200x32xi8> memref<32x32xi8> memref<19200x32xi8> memref<19200x32xi32>
    call @buddy_rvv_copy_rows_i8(%312, %311, %c19200_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_176 : memref<19200x32xi8>
    memref.dealloc %alloc_177 : memref<19200x32xi8>
    %alloc_182 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    %intptr_183 = memref.extract_aligned_pointer_as_index %alloc_182 : memref<1x120x160x32xf32> -> index
    %intptr_184 = memref.extract_aligned_pointer_as_index %alloc_175 : memref<19200x32xi8> -> index
    %314 = arith.index_cast %intptr_183 : index to i64
    %315 = arith.index_cast %intptr_184 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%314, %315, %c1_i64, %c120_i64, %c160_i64, %c32_i64, %cst_53) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_175 : memref<19200x32xi8>
    %alloc_185 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_182[%arg166, %arg168, %arg169, %arg167] : memref<1x120x160x32xf32>
            memref.store %646, %alloc_185[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_186 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    memref.copy %alloc_185, %alloc_186 : memref<1x32x120x160xf32> to memref<1x32x120x160xf32>
    %alloc_187 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_186[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = memref.load %267[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_187[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_188 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_187[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_188[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_189 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c120 step %c1 {
          scf.for %arg169 = %c0 to %c160 step %c1 {
            %646 = memref.load %alloc_188[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_189[%arg166, %arg167, %arg168, %arg169] : memref<1x32x120x160xi8>
          }
        }
      }
    }
    %alloc_190 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c120 step %c1 {
        scf.for %arg168 = %c0 to %c160 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_189[%arg166, %arg169, %arg167, %arg168] : memref<1x32x120x160xi8>
            memref.store %646, %alloc_190[%arg166, %arg167, %arg168, %arg169] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_191 = memref.alloc() {alignment = 64 : i64} : memref<1x121x161x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c121 step %c1 {
        scf.for %arg168 = %c0 to %c161 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_191[%arg166, %arg167, %arg168, %arg169] : memref<1x121x161x32xi8>
          }
        }
      }
    }
    %subview_192 = memref.subview %alloc_191[0, 1, 1, 0] [1, 120, 160, 32] [1, 1, 1, 1] : memref<1x121x161x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    memref.copy %alloc_190, %subview_192 : memref<1x120x160x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    %alloc_193 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %139[%arg169] : memref<64xi32>
            memref.store %646, %alloc_193[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_194 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    gemmini.tile_conv %alloc_191 %140 %139 %alloc_194 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00754241226 : f32, stride = 2 : i64} : memref<1x121x161x32xi8> memref<288x64xi8> memref<64xi32> memref<4800x64xi8> i64 i64 i64
    %alloc_195 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_196 = memref.extract_aligned_pointer_as_index %alloc_195 : memref<1x60x80x64xf32> -> index
    %intptr_197 = memref.extract_aligned_pointer_as_index %alloc_194 : memref<4800x64xi8> -> index
    %316 = arith.index_cast %intptr_196 : index to i64
    %317 = arith.index_cast %intptr_197 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%316, %317, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_52) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_194 : memref<4800x64xi8>
    %alloc_198 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_195[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_198[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_199 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_198, %alloc_199 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_200 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_199[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = memref.load %266[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_200[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_201 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_200[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_201[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_202 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_201[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_202[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_203 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_202[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_203[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_204 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_205 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_206 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_207 = memref.extract_aligned_pointer_as_index %alloc_203 : memref<1x60x80x64xi8> -> index
    %318 = arith.index_cast %intptr_207 : index to i64
    %intptr_208 = memref.extract_aligned_pointer_as_index %alloc_205 : memref<4800x64xi8> -> index
    %319 = arith.index_cast %intptr_208 : index to i64
    %intptr_209 = memref.extract_aligned_pointer_as_index %alloc_206 : memref<4800x32xi8> -> index
    %320 = arith.index_cast %intptr_209 : index to i64
    %intptr_210 = memref.extract_aligned_pointer_as_index %alloc_204 : memref<4800x32xi8> -> index
    %321 = arith.index_cast %intptr_210 : index to i64
    call @buddy_rvv_memcpy_i8(%319, %318, %c307200_i64) : (i64, i64, i64) -> ()
    %322 = arith.addi %319, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%322, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_205 %138 %alloc_206 %137 {accScale = 0.0151615953 : f32} : memref<4800x64xi8> memref<64x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%321, %320, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_205 : memref<4800x64xi8>
    memref.dealloc %alloc_206 : memref<4800x32xi8>
    %alloc_211 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_212 = memref.extract_aligned_pointer_as_index %alloc_211 : memref<1x60x80x32xf32> -> index
    %intptr_213 = memref.extract_aligned_pointer_as_index %alloc_204 : memref<4800x32xi8> -> index
    %323 = arith.index_cast %intptr_212 : index to i64
    %324 = arith.index_cast %intptr_213 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%323, %324, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_51) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_204 : memref<4800x32xi8>
    %alloc_214 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_211[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_214[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_215 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_214, %alloc_215 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_216 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_215[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %265[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_216[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_217 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_216[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_217[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_218 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_217[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_218[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_219 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_218[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_219[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_220 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_221 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_222 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_223 = memref.extract_aligned_pointer_as_index %alloc_219 : memref<1x60x80x32xi8> -> index
    %325 = arith.index_cast %intptr_223 : index to i64
    %intptr_224 = memref.extract_aligned_pointer_as_index %alloc_221 : memref<4800x32xi8> -> index
    %326 = arith.index_cast %intptr_224 : index to i64
    %intptr_225 = memref.extract_aligned_pointer_as_index %alloc_222 : memref<4800x32xi8> -> index
    %327 = arith.index_cast %intptr_225 : index to i64
    %intptr_226 = memref.extract_aligned_pointer_as_index %alloc_220 : memref<4800x32xi8> -> index
    %328 = arith.index_cast %intptr_226 : index to i64
    call @buddy_rvv_memcpy_i8(%326, %325, %c153600_i64) : (i64, i64, i64) -> ()
    %329 = arith.addi %326, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%329, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_221 %136 %alloc_222 %135 {accScale = 1.479830e-02 : f32} : memref<4800x32xi8> memref<32x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%328, %327, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_221 : memref<4800x32xi8>
    memref.dealloc %alloc_222 : memref<4800x32xi8>
    %alloc_227 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_228 = memref.extract_aligned_pointer_as_index %alloc_227 : memref<1x60x80x32xf32> -> index
    %intptr_229 = memref.extract_aligned_pointer_as_index %alloc_220 : memref<4800x32xi8> -> index
    %330 = arith.index_cast %intptr_228 : index to i64
    %331 = arith.index_cast %intptr_229 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%330, %331, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_50) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_220 : memref<4800x32xi8>
    %alloc_230 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_227[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_230[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_231 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_230, %alloc_231 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_232 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_231[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %264[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_232[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_233 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_232[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_233[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_234 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_233[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_234[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_235 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_234[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_235[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_236 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_236[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_237 = memref.subview %alloc_236[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_235, %subview_237 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_238 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %133[%arg169] : memref<32xi32>
            memref.store %646, %alloc_238[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_239 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    gemmini.tile_conv %alloc_236 %134 %133 %alloc_239 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00458907802 : f32} : memref<1x62x82x32xi8> memref<288x32xi8> memref<32xi32> memref<4800x32xi8> i64 i64 i64
    %alloc_240 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_241 = memref.extract_aligned_pointer_as_index %alloc_240 : memref<1x60x80x32xf32> -> index
    %intptr_242 = memref.extract_aligned_pointer_as_index %alloc_239 : memref<4800x32xi8> -> index
    %332 = arith.index_cast %intptr_241 : index to i64
    %333 = arith.index_cast %intptr_242 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%332, %333, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_49) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_239 : memref<4800x32xi8>
    %alloc_243 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_240[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_243[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_244 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_243, %alloc_244 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_245 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_244[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %263[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_245[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_246 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_245[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_246[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_247 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_246[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_247[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_248 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_218[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_248[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_249 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_248[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %262[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_249[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_250 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_249[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_250[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_251 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_247[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_251[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_252 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_251[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %261[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_252[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_253 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_252[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_253[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_254 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_250[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %alloc_253[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_254[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_255 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_254[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_255[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_256 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_255[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_256[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_257 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_256[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_257[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_258 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_257[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_258[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_259 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_260 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_261 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_262 = memref.extract_aligned_pointer_as_index %alloc_258 : memref<1x60x80x32xi8> -> index
    %334 = arith.index_cast %intptr_262 : index to i64
    %intptr_263 = memref.extract_aligned_pointer_as_index %alloc_260 : memref<4800x32xi8> -> index
    %335 = arith.index_cast %intptr_263 : index to i64
    %intptr_264 = memref.extract_aligned_pointer_as_index %alloc_261 : memref<4800x32xi8> -> index
    %336 = arith.index_cast %intptr_264 : index to i64
    %intptr_265 = memref.extract_aligned_pointer_as_index %alloc_259 : memref<4800x32xi8> -> index
    %337 = arith.index_cast %intptr_265 : index to i64
    call @buddy_rvv_memcpy_i8(%335, %334, %c153600_i64) : (i64, i64, i64) -> ()
    %338 = arith.addi %335, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%338, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_260 %132 %alloc_261 %131 {accScale = 0.0162679348 : f32} : memref<4800x32xi8> memref<32x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%337, %336, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_260 : memref<4800x32xi8>
    memref.dealloc %alloc_261 : memref<4800x32xi8>
    %alloc_266 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_267 = memref.extract_aligned_pointer_as_index %alloc_266 : memref<1x60x80x32xf32> -> index
    %intptr_268 = memref.extract_aligned_pointer_as_index %alloc_259 : memref<4800x32xi8> -> index
    %339 = arith.index_cast %intptr_267 : index to i64
    %340 = arith.index_cast %intptr_268 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%339, %340, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_48) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_259 : memref<4800x32xi8>
    %alloc_269 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_266[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_269[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_270 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_269, %alloc_270 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_271 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_270[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %260[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_271[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_272 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_271[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_272[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_273 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_272[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_273[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_274 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_273[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_274[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_275 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_275[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_276 = memref.subview %alloc_275[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_274, %subview_276 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_277 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %129[%arg169] : memref<32xi32>
            memref.store %646, %alloc_277[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_278 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    gemmini.tile_conv %alloc_275 %130 %129 %alloc_278 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00380956917 : f32} : memref<1x62x82x32xi8> memref<288x32xi8> memref<32xi32> memref<4800x32xi8> i64 i64 i64
    %alloc_279 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_280 = memref.extract_aligned_pointer_as_index %alloc_279 : memref<1x60x80x32xf32> -> index
    %intptr_281 = memref.extract_aligned_pointer_as_index %alloc_278 : memref<4800x32xi8> -> index
    %341 = arith.index_cast %intptr_280 : index to i64
    %342 = arith.index_cast %intptr_281 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%341, %342, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_47) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_278 : memref<4800x32xi8>
    %alloc_282 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_279[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_282[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_283 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_282, %alloc_283 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_284 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_283[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %259[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_284[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_285 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_284[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_285[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_286 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_285[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_286[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_287 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_257[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_287[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_288 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_287[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %258[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_288[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_289 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_288[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_289[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_290 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_286[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_290[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_291 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_290[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %257[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_291[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_292 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_291[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_292[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_293 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_289[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %alloc_292[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_293[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_294 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_293[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_294[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_295 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_294[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_295[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_296 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_295[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_296[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_297 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_202[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_297[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_298 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_299 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_300 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_301 = memref.extract_aligned_pointer_as_index %alloc_297 : memref<1x60x80x64xi8> -> index
    %343 = arith.index_cast %intptr_301 : index to i64
    %intptr_302 = memref.extract_aligned_pointer_as_index %alloc_299 : memref<4800x64xi8> -> index
    %344 = arith.index_cast %intptr_302 : index to i64
    %intptr_303 = memref.extract_aligned_pointer_as_index %alloc_300 : memref<4800x32xi8> -> index
    %345 = arith.index_cast %intptr_303 : index to i64
    %intptr_304 = memref.extract_aligned_pointer_as_index %alloc_298 : memref<4800x32xi8> -> index
    %346 = arith.index_cast %intptr_304 : index to i64
    call @buddy_rvv_memcpy_i8(%344, %343, %c307200_i64) : (i64, i64, i64) -> ()
    %347 = arith.addi %344, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%347, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_299 %128 %alloc_300 %127 {accScale = 0.0120223034 : f32} : memref<4800x64xi8> memref<64x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%346, %345, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_299 : memref<4800x64xi8>
    memref.dealloc %alloc_300 : memref<4800x32xi8>
    %alloc_305 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_306 = memref.extract_aligned_pointer_as_index %alloc_305 : memref<1x60x80x32xf32> -> index
    %intptr_307 = memref.extract_aligned_pointer_as_index %alloc_298 : memref<4800x32xi8> -> index
    %348 = arith.index_cast %intptr_306 : index to i64
    %349 = arith.index_cast %intptr_307 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%348, %349, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_47) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_298 : memref<4800x32xi8>
    %alloc_308 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_305[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_308[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_309 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_308, %alloc_309 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_310 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_309[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %256[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_310[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_311 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_310[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_311[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_312 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_311[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_312[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_313 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_296[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_313[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_314 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_313[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %255[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_314[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_315 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_314[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_315[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_316 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_315[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_316[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_317 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_316[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_317[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_318 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_317[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_318[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_319 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_312[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_319[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_320 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_319[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %254[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_320[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_321 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_320[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_321[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_322 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_321[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_322[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_323 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_322[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_323[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_324 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_323[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_324[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_325 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_326 = memref.subview %alloc_325[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_318, %subview_326 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_327 = memref.subview %alloc_325[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_324, %subview_327 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_328 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_325[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_328[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_329 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_330 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_331 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_332 = memref.extract_aligned_pointer_as_index %alloc_328 : memref<1x60x80x64xi8> -> index
    %350 = arith.index_cast %intptr_332 : index to i64
    %intptr_333 = memref.extract_aligned_pointer_as_index %alloc_330 : memref<4800x64xi8> -> index
    %351 = arith.index_cast %intptr_333 : index to i64
    %intptr_334 = memref.extract_aligned_pointer_as_index %alloc_331 : memref<4800x64xi8> -> index
    %352 = arith.index_cast %intptr_334 : index to i64
    %intptr_335 = memref.extract_aligned_pointer_as_index %alloc_329 : memref<4800x64xi8> -> index
    %353 = arith.index_cast %intptr_335 : index to i64
    call @buddy_rvv_memcpy_i8(%351, %350, %c307200_i64) : (i64, i64, i64) -> ()
    %354 = arith.addi %351, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%354, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_330 %126 %alloc_331 %125 {accScale = 0.0150127029 : f32} : memref<4800x64xi8> memref<64x64xi8> memref<4800x64xi8> memref<4800x64xi32>
    call @buddy_rvv_copy_rows_i8(%353, %352, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_330 : memref<4800x64xi8>
    memref.dealloc %alloc_331 : memref<4800x64xi8>
    %alloc_336 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_337 = memref.extract_aligned_pointer_as_index %alloc_336 : memref<1x60x80x64xf32> -> index
    %intptr_338 = memref.extract_aligned_pointer_as_index %alloc_329 : memref<4800x64xi8> -> index
    %355 = arith.index_cast %intptr_337 : index to i64
    %356 = arith.index_cast %intptr_338 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%355, %356, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_46) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_329 : memref<4800x64xi8>
    %alloc_339 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_336[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_339[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_340 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_339, %alloc_340 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_341 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_340[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = memref.load %253[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_341[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_342 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_341[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_342[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_343 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_342[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_343[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_344 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_343[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_344[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_345 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c61 step %c1 {
        scf.for %arg168 = %c0 to %c81 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_345[%arg166, %arg167, %arg168, %arg169] : memref<1x61x81x64xi8>
          }
        }
      }
    }
    %subview_346 = memref.subview %alloc_345[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_344, %subview_346 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_347 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %123[%arg169] : memref<128xi32>
            memref.store %646, %alloc_347[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi32>
          }
        }
      }
    }
    %alloc_348 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    gemmini.tile_conv %alloc_345 %124 %123 %alloc_348 %c30_i64 %c40_i64 %c3_i64 {scale = 0.0122586582 : f32, stride = 2 : i64} : memref<1x61x81x64xi8> memref<576x128xi8> memref<128xi32> memref<1200x128xi8> i64 i64 i64
    %alloc_349 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_350 = memref.extract_aligned_pointer_as_index %alloc_349 : memref<1x30x40x128xf32> -> index
    %intptr_351 = memref.extract_aligned_pointer_as_index %alloc_348 : memref<1200x128xi8> -> index
    %357 = arith.index_cast %intptr_350 : index to i64
    %358 = arith.index_cast %intptr_351 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%357, %358, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_45) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_348 : memref<1200x128xi8>
    %alloc_352 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_349[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x128xf32>
            memref.store %646, %alloc_352[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_353 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_352, %alloc_353 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_354 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_353[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = memref.load %252[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_354[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_355 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_354[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_355[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_356 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_355[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_356[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_357 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_356[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_357[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_358 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_359 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_360 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_361 = memref.extract_aligned_pointer_as_index %alloc_357 : memref<1x30x40x128xi8> -> index
    %359 = arith.index_cast %intptr_361 : index to i64
    %intptr_362 = memref.extract_aligned_pointer_as_index %alloc_359 : memref<1200x128xi8> -> index
    %360 = arith.index_cast %intptr_362 : index to i64
    %intptr_363 = memref.extract_aligned_pointer_as_index %alloc_360 : memref<1200x64xi8> -> index
    %361 = arith.index_cast %intptr_363 : index to i64
    %intptr_364 = memref.extract_aligned_pointer_as_index %alloc_358 : memref<1200x64xi8> -> index
    %362 = arith.index_cast %intptr_364 : index to i64
    call @buddy_rvv_memcpy_i8(%360, %359, %c153600_i64) : (i64, i64, i64) -> ()
    %363 = arith.addi %360, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%363, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_359 %122 %alloc_360 %121 {accScale = 0.0189360213 : f32} : memref<1200x128xi8> memref<128x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%362, %361, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_359 : memref<1200x128xi8>
    memref.dealloc %alloc_360 : memref<1200x64xi8>
    %alloc_365 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_366 = memref.extract_aligned_pointer_as_index %alloc_365 : memref<1x30x40x64xf32> -> index
    %intptr_367 = memref.extract_aligned_pointer_as_index %alloc_358 : memref<1200x64xi8> -> index
    %364 = arith.index_cast %intptr_366 : index to i64
    %365 = arith.index_cast %intptr_367 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%364, %365, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_44) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_358 : memref<1200x64xi8>
    %alloc_368 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_365[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_368[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_369 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_368, %alloc_369 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_370 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_369[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %251[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_370[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_371 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_370[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_371[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_372 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_371[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_372[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_373 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_372[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_373[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_374 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_375 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_376 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_377 = memref.extract_aligned_pointer_as_index %alloc_373 : memref<1x30x40x64xi8> -> index
    %366 = arith.index_cast %intptr_377 : index to i64
    %intptr_378 = memref.extract_aligned_pointer_as_index %alloc_375 : memref<1200x64xi8> -> index
    %367 = arith.index_cast %intptr_378 : index to i64
    %intptr_379 = memref.extract_aligned_pointer_as_index %alloc_376 : memref<1200x64xi8> -> index
    %368 = arith.index_cast %intptr_379 : index to i64
    %intptr_380 = memref.extract_aligned_pointer_as_index %alloc_374 : memref<1200x64xi8> -> index
    %369 = arith.index_cast %intptr_380 : index to i64
    call @buddy_rvv_memcpy_i8(%367, %366, %c76800_i64) : (i64, i64, i64) -> ()
    %370 = arith.addi %367, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%370, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_375 %120 %alloc_376 %119 {accScale = 0.0145288706 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%369, %368, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_375 : memref<1200x64xi8>
    memref.dealloc %alloc_376 : memref<1200x64xi8>
    %alloc_381 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_382 = memref.extract_aligned_pointer_as_index %alloc_381 : memref<1x30x40x64xf32> -> index
    %intptr_383 = memref.extract_aligned_pointer_as_index %alloc_374 : memref<1200x64xi8> -> index
    %371 = arith.index_cast %intptr_382 : index to i64
    %372 = arith.index_cast %intptr_383 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%371, %372, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_43) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_374 : memref<1200x64xi8>
    %alloc_384 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_381[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_384[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_385 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_384, %alloc_385 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_386 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_385[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %250[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_386[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_387 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_386[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_387[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_388 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_387[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_388[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_389 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_388[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_389[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_390 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_390[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_391 = memref.subview %alloc_390[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_389, %subview_391 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_392 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %117[%arg169] : memref<64xi32>
            memref.store %646, %alloc_392[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_393 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_390 %118 %117 %alloc_393 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00607879459 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_394 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_395 = memref.extract_aligned_pointer_as_index %alloc_394 : memref<1x30x40x64xf32> -> index
    %intptr_396 = memref.extract_aligned_pointer_as_index %alloc_393 : memref<1200x64xi8> -> index
    %373 = arith.index_cast %intptr_395 : index to i64
    %374 = arith.index_cast %intptr_396 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%373, %374, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_42) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_393 : memref<1200x64xi8>
    %alloc_397 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_394[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_397[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_398 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_397, %alloc_398 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_399 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_398[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %249[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_399[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_400 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_399[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_400[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_401 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_400[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_401[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_402 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_372[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_402[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_403 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_402[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %248[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_403[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_404 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_403[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_404[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_405 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_401[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_405[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_406 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_405[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %247[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_406[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_407 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_406[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_407[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_408 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_404[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %alloc_407[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_408[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_409 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_408[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_409[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_410 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_409[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_410[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_411 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_410[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_411[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_412 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_411[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_412[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_413 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_414 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_415 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_416 = memref.extract_aligned_pointer_as_index %alloc_412 : memref<1x30x40x64xi8> -> index
    %375 = arith.index_cast %intptr_416 : index to i64
    %intptr_417 = memref.extract_aligned_pointer_as_index %alloc_414 : memref<1200x64xi8> -> index
    %376 = arith.index_cast %intptr_417 : index to i64
    %intptr_418 = memref.extract_aligned_pointer_as_index %alloc_415 : memref<1200x64xi8> -> index
    %377 = arith.index_cast %intptr_418 : index to i64
    %intptr_419 = memref.extract_aligned_pointer_as_index %alloc_413 : memref<1200x64xi8> -> index
    %378 = arith.index_cast %intptr_419 : index to i64
    call @buddy_rvv_memcpy_i8(%376, %375, %c76800_i64) : (i64, i64, i64) -> ()
    %379 = arith.addi %376, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%379, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_414 %116 %alloc_415 %115 {accScale = 0.00671094796 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%378, %377, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_414 : memref<1200x64xi8>
    memref.dealloc %alloc_415 : memref<1200x64xi8>
    %alloc_420 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_421 = memref.extract_aligned_pointer_as_index %alloc_420 : memref<1x30x40x64xf32> -> index
    %intptr_422 = memref.extract_aligned_pointer_as_index %alloc_413 : memref<1200x64xi8> -> index
    %380 = arith.index_cast %intptr_421 : index to i64
    %381 = arith.index_cast %intptr_422 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%380, %381, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_41) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_413 : memref<1200x64xi8>
    %alloc_423 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_420[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_423[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_424 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_423, %alloc_424 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_425 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_424[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %246[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_425[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_426 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_425[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_426[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_427 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_426[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_427[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_428 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_427[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_428[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_429 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_429[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_430 = memref.subview %alloc_429[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_428, %subview_430 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_431 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %113[%arg169] : memref<64xi32>
            memref.store %646, %alloc_431[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_432 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_429 %114 %113 %alloc_432 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00729554053 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_433 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_434 = memref.extract_aligned_pointer_as_index %alloc_433 : memref<1x30x40x64xf32> -> index
    %intptr_435 = memref.extract_aligned_pointer_as_index %alloc_432 : memref<1200x64xi8> -> index
    %382 = arith.index_cast %intptr_434 : index to i64
    %383 = arith.index_cast %intptr_435 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%382, %383, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_40) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_432 : memref<1200x64xi8>
    %alloc_436 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_433[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_436[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_437 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_436, %alloc_437 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_438 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_437[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %245[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_438[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_439 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_438[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_439[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_440 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_439[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_440[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_441 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_411[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_441[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_442 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_441[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %244[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_442[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_443 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_442[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_443[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_444 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_440[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_444[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_445 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_444[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %243[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_445[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_446 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_445[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_446[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_447 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_443[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %alloc_446[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_447[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_448 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_447[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_448[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_449 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_448[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_449[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_450 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_449[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_450[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_451 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_450[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_451[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_452 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_453 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_454 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_455 = memref.extract_aligned_pointer_as_index %alloc_451 : memref<1x30x40x64xi8> -> index
    %384 = arith.index_cast %intptr_455 : index to i64
    %intptr_456 = memref.extract_aligned_pointer_as_index %alloc_453 : memref<1200x64xi8> -> index
    %385 = arith.index_cast %intptr_456 : index to i64
    %intptr_457 = memref.extract_aligned_pointer_as_index %alloc_454 : memref<1200x64xi8> -> index
    %386 = arith.index_cast %intptr_457 : index to i64
    %intptr_458 = memref.extract_aligned_pointer_as_index %alloc_452 : memref<1200x64xi8> -> index
    %387 = arith.index_cast %intptr_458 : index to i64
    call @buddy_rvv_memcpy_i8(%385, %384, %c76800_i64) : (i64, i64, i64) -> ()
    %388 = arith.addi %385, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%388, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_453 %112 %alloc_454 %111 {accScale = 0.0123461829 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%387, %386, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_453 : memref<1200x64xi8>
    memref.dealloc %alloc_454 : memref<1200x64xi8>
    %alloc_459 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_460 = memref.extract_aligned_pointer_as_index %alloc_459 : memref<1x30x40x64xf32> -> index
    %intptr_461 = memref.extract_aligned_pointer_as_index %alloc_452 : memref<1200x64xi8> -> index
    %389 = arith.index_cast %intptr_460 : index to i64
    %390 = arith.index_cast %intptr_461 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%389, %390, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_39) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_452 : memref<1200x64xi8>
    %alloc_462 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_459[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_462[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_463 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_462, %alloc_463 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_464 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_463[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %242[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_464[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_465 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_464[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_465[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_466 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_465[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_466[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_467 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_466[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_467[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_468 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_468[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_469 = memref.subview %alloc_468[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_467, %subview_469 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_470 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %109[%arg169] : memref<64xi32>
            memref.store %646, %alloc_470[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_471 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_468 %110 %109 %alloc_471 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00430227118 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_472 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_473 = memref.extract_aligned_pointer_as_index %alloc_472 : memref<1x30x40x64xf32> -> index
    %intptr_474 = memref.extract_aligned_pointer_as_index %alloc_471 : memref<1200x64xi8> -> index
    %391 = arith.index_cast %intptr_473 : index to i64
    %392 = arith.index_cast %intptr_474 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%391, %392, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_38) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_471 : memref<1200x64xi8>
    %alloc_475 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_472[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_475[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_476 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_475, %alloc_476 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_477 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_476[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %241[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_477[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_478 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_477[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_478[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_479 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_478[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_479[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_480 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_450[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_480[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_481 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_480[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %240[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_481[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_482 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_481[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_482[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_483 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_479[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_483[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_484 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_483[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %239[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_484[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_485 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_484[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_485[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_486 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_482[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %alloc_485[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_486[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_487 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_486[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_487[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_488 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_487[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_488[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_489 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_488[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_489[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_490 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_356[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_490[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_491 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_492 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_493 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_494 = memref.extract_aligned_pointer_as_index %alloc_490 : memref<1x30x40x128xi8> -> index
    %393 = arith.index_cast %intptr_494 : index to i64
    %intptr_495 = memref.extract_aligned_pointer_as_index %alloc_492 : memref<1200x128xi8> -> index
    %394 = arith.index_cast %intptr_495 : index to i64
    %intptr_496 = memref.extract_aligned_pointer_as_index %alloc_493 : memref<1200x64xi8> -> index
    %395 = arith.index_cast %intptr_496 : index to i64
    %intptr_497 = memref.extract_aligned_pointer_as_index %alloc_491 : memref<1200x64xi8> -> index
    %396 = arith.index_cast %intptr_497 : index to i64
    call @buddy_rvv_memcpy_i8(%394, %393, %c153600_i64) : (i64, i64, i64) -> ()
    %397 = arith.addi %394, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%397, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_492 %108 %alloc_493 %107 {accScale = 0.00847221724 : f32} : memref<1200x128xi8> memref<128x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%396, %395, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_492 : memref<1200x128xi8>
    memref.dealloc %alloc_493 : memref<1200x64xi8>
    %alloc_498 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_499 = memref.extract_aligned_pointer_as_index %alloc_498 : memref<1x30x40x64xf32> -> index
    %intptr_500 = memref.extract_aligned_pointer_as_index %alloc_491 : memref<1200x64xi8> -> index
    %398 = arith.index_cast %intptr_499 : index to i64
    %399 = arith.index_cast %intptr_500 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%398, %399, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_38) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_491 : memref<1200x64xi8>
    %alloc_501 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_498[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_501[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_502 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_501, %alloc_502 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_503 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_502[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %238[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_503[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_504 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_503[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_504[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_505 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_504[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_505[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_506 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_489[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_506[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_507 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_506[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %237[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_507[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_508 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_507[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_508[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_509 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_508[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_509[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_510 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_509[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_510[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_511 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_510[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_511[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_512 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_505[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_512[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_513 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_512[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_513[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_514 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_513[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_514[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_515 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_514[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_515[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_516 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_517 = memref.subview %alloc_516[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_511, %subview_517 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_518 = memref.subview %alloc_516[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_515, %subview_518 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_519 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_516[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_519[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_520 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_521 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_522 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_523 = memref.extract_aligned_pointer_as_index %alloc_519 : memref<1x30x40x128xi8> -> index
    %400 = arith.index_cast %intptr_523 : index to i64
    %intptr_524 = memref.extract_aligned_pointer_as_index %alloc_521 : memref<1200x128xi8> -> index
    %401 = arith.index_cast %intptr_524 : index to i64
    %intptr_525 = memref.extract_aligned_pointer_as_index %alloc_522 : memref<1200x128xi8> -> index
    %402 = arith.index_cast %intptr_525 : index to i64
    %intptr_526 = memref.extract_aligned_pointer_as_index %alloc_520 : memref<1200x128xi8> -> index
    %403 = arith.index_cast %intptr_526 : index to i64
    call @buddy_rvv_memcpy_i8(%401, %400, %c153600_i64) : (i64, i64, i64) -> ()
    %404 = arith.addi %401, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%404, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_521 %106 %alloc_522 %105 {accScale = 0.00620856694 : f32} : memref<1200x128xi8> memref<128x128xi8> memref<1200x128xi8> memref<1200x128xi32>
    call @buddy_rvv_copy_rows_i8(%403, %402, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_521 : memref<1200x128xi8>
    memref.dealloc %alloc_522 : memref<1200x128xi8>
    %alloc_527 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_528 = memref.extract_aligned_pointer_as_index %alloc_527 : memref<1x30x40x128xf32> -> index
    %intptr_529 = memref.extract_aligned_pointer_as_index %alloc_520 : memref<1200x128xi8> -> index
    %405 = arith.index_cast %intptr_528 : index to i64
    %406 = arith.index_cast %intptr_529 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%405, %406, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_37) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_520 : memref<1200x128xi8>
    %alloc_530 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_527[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x128xf32>
            memref.store %646, %alloc_530[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_531 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_530, %alloc_531 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_532 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_531[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = memref.load %236[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_532[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_533 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_532[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_533[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_534 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_533[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_534[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_535 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_534[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_535[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_536 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c31 step %c1 {
        scf.for %arg168 = %c0 to %c41 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_536[%arg166, %arg167, %arg168, %arg169] : memref<1x31x41x128xi8>
          }
        }
      }
    }
    %subview_537 = memref.subview %alloc_536[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_535, %subview_537 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_538 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %103[%arg169] : memref<256xi32>
            memref.store %646, %alloc_538[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi32>
          }
        }
      }
    }
    %alloc_539 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    gemmini.tile_conv %alloc_536 %104 %103 %alloc_539 %c15_i64 %c20_i64 %c3_i64 {scale = 0.00459722057 : f32, stride = 2 : i64} : memref<1x31x41x128xi8> memref<1152x256xi8> memref<256xi32> memref<300x256xi8> i64 i64 i64
    %alloc_540 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_541 = memref.extract_aligned_pointer_as_index %alloc_540 : memref<1x15x20x256xf32> -> index
    %intptr_542 = memref.extract_aligned_pointer_as_index %alloc_539 : memref<300x256xi8> -> index
    %407 = arith.index_cast %intptr_541 : index to i64
    %408 = arith.index_cast %intptr_542 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%407, %408, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_36) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_539 : memref<300x256xi8>
    %alloc_543 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_540[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x256xf32>
            memref.store %646, %alloc_543[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_544 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_543, %alloc_544 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_545 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_544[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = memref.load %235[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_545[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_546 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_545[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_546[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_547 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_546[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_547[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_548 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_547[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_548[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_549 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_550 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_551 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_552 = memref.extract_aligned_pointer_as_index %alloc_548 : memref<1x15x20x256xi8> -> index
    %409 = arith.index_cast %intptr_552 : index to i64
    %intptr_553 = memref.extract_aligned_pointer_as_index %alloc_550 : memref<304x256xi8> -> index
    %410 = arith.index_cast %intptr_553 : index to i64
    %intptr_554 = memref.extract_aligned_pointer_as_index %alloc_551 : memref<304x128xi8> -> index
    %411 = arith.index_cast %intptr_554 : index to i64
    %intptr_555 = memref.extract_aligned_pointer_as_index %alloc_549 : memref<300x128xi8> -> index
    %412 = arith.index_cast %intptr_555 : index to i64
    call @buddy_rvv_memcpy_i8(%410, %409, %c76800_i64) : (i64, i64, i64) -> ()
    %413 = arith.addi %410, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%413, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_550 %102 %alloc_551 %101 {accScale = 0.00715792737 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%412, %411, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_550 : memref<304x256xi8>
    memref.dealloc %alloc_551 : memref<304x128xi8>
    %alloc_556 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_557 = memref.extract_aligned_pointer_as_index %alloc_556 : memref<1x15x20x128xf32> -> index
    %intptr_558 = memref.extract_aligned_pointer_as_index %alloc_549 : memref<300x128xi8> -> index
    %414 = arith.index_cast %intptr_557 : index to i64
    %415 = arith.index_cast %intptr_558 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%414, %415, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_35) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_549 : memref<300x128xi8>
    %alloc_559 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_556[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_559[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_560 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_559, %alloc_560 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_561 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_560[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %234[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_561[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_562 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_561[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_562[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_563 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_562[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_563[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_564 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_563[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_564[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_565 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_566 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %alloc_567 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_568 = memref.extract_aligned_pointer_as_index %alloc_564 : memref<1x15x20x128xi8> -> index
    %416 = arith.index_cast %intptr_568 : index to i64
    %intptr_569 = memref.extract_aligned_pointer_as_index %alloc_566 : memref<304x128xi8> -> index
    %417 = arith.index_cast %intptr_569 : index to i64
    %intptr_570 = memref.extract_aligned_pointer_as_index %alloc_567 : memref<304x128xi8> -> index
    %418 = arith.index_cast %intptr_570 : index to i64
    %intptr_571 = memref.extract_aligned_pointer_as_index %alloc_565 : memref<300x128xi8> -> index
    %419 = arith.index_cast %intptr_571 : index to i64
    call @buddy_rvv_memcpy_i8(%417, %416, %c38400_i64) : (i64, i64, i64) -> ()
    %420 = arith.addi %417, %c38400_i64 : i64
    call @buddy_rvv_memset_i8(%420, %c0_i64, %c512_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_566 %100 %alloc_567 %99 {accScale = 0.0129372664 : f32} : memref<304x128xi8> memref<128x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%419, %418, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_566 : memref<304x128xi8>
    memref.dealloc %alloc_567 : memref<304x128xi8>
    %alloc_572 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_573 = memref.extract_aligned_pointer_as_index %alloc_572 : memref<1x15x20x128xf32> -> index
    %intptr_574 = memref.extract_aligned_pointer_as_index %alloc_565 : memref<300x128xi8> -> index
    %421 = arith.index_cast %intptr_573 : index to i64
    %422 = arith.index_cast %intptr_574 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%421, %422, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_34) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_565 : memref<300x128xi8>
    %alloc_575 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_572[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_575[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_576 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_575, %alloc_576 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_577 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_576[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %233[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_577[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_578 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_577[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_578[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_579 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_578[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_579[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_580 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_579[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_580[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_581 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_581[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x128xi8>
          }
        }
      }
    }
    %subview_582 = memref.subview %alloc_581[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_580, %subview_582 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_583 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %97[%arg169] : memref<128xi32>
            memref.store %646, %alloc_583[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_584 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    gemmini.tile_conv %alloc_581 %98 %97 %alloc_584 %c15_i64 %c20_i64 %c3_i64 {scale = 0.003725769 : f32} : memref<1x17x22x128xi8> memref<1152x128xi8> memref<128xi32> memref<300x128xi8> i64 i64 i64
    %alloc_585 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_586 = memref.extract_aligned_pointer_as_index %alloc_585 : memref<1x15x20x128xf32> -> index
    %intptr_587 = memref.extract_aligned_pointer_as_index %alloc_584 : memref<300x128xi8> -> index
    %423 = arith.index_cast %intptr_586 : index to i64
    %424 = arith.index_cast %intptr_587 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%423, %424, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_33) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_584 : memref<300x128xi8>
    %alloc_588 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_585[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_588[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_589 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_588, %alloc_589 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_590 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_589[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %232[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_590[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_591 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_590[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_591[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_592 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_591[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_592[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_593 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_563[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_593[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_594 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_593[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %231[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_594[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_595 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_594[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_595[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_596 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_592[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_596[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_597 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_596[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %230[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_597[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_598 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_597[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_598[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_599 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_595[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %alloc_598[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %648 = arith.addi %646, %647 : i32
            memref.store %648, %alloc_599[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_600 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_599[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_600[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_601 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_600[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_601[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_602 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_601[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_602[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_603 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_547[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_603[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_604 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_605 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_606 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_607 = memref.extract_aligned_pointer_as_index %alloc_603 : memref<1x15x20x256xi8> -> index
    %425 = arith.index_cast %intptr_607 : index to i64
    %intptr_608 = memref.extract_aligned_pointer_as_index %alloc_605 : memref<304x256xi8> -> index
    %426 = arith.index_cast %intptr_608 : index to i64
    %intptr_609 = memref.extract_aligned_pointer_as_index %alloc_606 : memref<304x128xi8> -> index
    %427 = arith.index_cast %intptr_609 : index to i64
    %intptr_610 = memref.extract_aligned_pointer_as_index %alloc_604 : memref<300x128xi8> -> index
    %428 = arith.index_cast %intptr_610 : index to i64
    call @buddy_rvv_memcpy_i8(%426, %425, %c76800_i64) : (i64, i64, i64) -> ()
    %429 = arith.addi %426, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%429, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_605 %96 %alloc_606 %95 {accScale = 0.0122155221 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%428, %427, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_605 : memref<304x256xi8>
    memref.dealloc %alloc_606 : memref<304x128xi8>
    %alloc_611 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_612 = memref.extract_aligned_pointer_as_index %alloc_611 : memref<1x15x20x128xf32> -> index
    %intptr_613 = memref.extract_aligned_pointer_as_index %alloc_604 : memref<300x128xi8> -> index
    %430 = arith.index_cast %intptr_612 : index to i64
    %431 = arith.index_cast %intptr_613 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%430, %431, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_33) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_604 : memref<300x128xi8>
    %alloc_614 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_611[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_614[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_615 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_614, %alloc_615 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_616 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_615[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %229[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_616[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_617 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_616[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_617[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_618 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_617[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_618[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_619 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_602[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_619[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_620 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_619[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_620[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_621 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_620[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_621[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_622 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_621[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_622[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_623 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_618[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_623[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_624 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_623[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %228[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_624[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_625 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_624[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_625[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_626 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_625[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_626[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_627 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_626[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_627[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_628 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_627[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_628[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_629 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_630 = memref.subview %alloc_629[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_622, %subview_630 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_631 = memref.subview %alloc_629[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_628, %subview_631 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_632 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_629[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_632[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_633 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_634 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_635 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_636 = memref.extract_aligned_pointer_as_index %alloc_632 : memref<1x15x20x256xi8> -> index
    %432 = arith.index_cast %intptr_636 : index to i64
    %intptr_637 = memref.extract_aligned_pointer_as_index %alloc_634 : memref<304x256xi8> -> index
    %433 = arith.index_cast %intptr_637 : index to i64
    %intptr_638 = memref.extract_aligned_pointer_as_index %alloc_635 : memref<304x256xi8> -> index
    %434 = arith.index_cast %intptr_638 : index to i64
    %intptr_639 = memref.extract_aligned_pointer_as_index %alloc_633 : memref<300x256xi8> -> index
    %435 = arith.index_cast %intptr_639 : index to i64
    call @buddy_rvv_memcpy_i8(%433, %432, %c76800_i64) : (i64, i64, i64) -> ()
    %436 = arith.addi %433, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%436, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_634 %94 %alloc_635 %93 {accScale = 0.0109014092 : f32} : memref<304x256xi8> memref<256x256xi8> memref<304x256xi8> memref<304x256xi32>
    call @buddy_rvv_copy_rows_i8(%435, %434, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_634 : memref<304x256xi8>
    memref.dealloc %alloc_635 : memref<304x256xi8>
    %alloc_640 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_641 = memref.extract_aligned_pointer_as_index %alloc_640 : memref<1x15x20x256xf32> -> index
    %intptr_642 = memref.extract_aligned_pointer_as_index %alloc_633 : memref<300x256xi8> -> index
    %437 = arith.index_cast %intptr_641 : index to i64
    %438 = arith.index_cast %intptr_642 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%437, %438, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_32) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_633 : memref<300x256xi8>
    %alloc_643 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_640[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x256xf32>
            memref.store %646, %alloc_643[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_644 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_643, %alloc_644 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_645 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_644[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = memref.load %227[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_645[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_646 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_645[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_646[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_647 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_646[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_647[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_648 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_647[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_648[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_649 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_650 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_651 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_652 = memref.extract_aligned_pointer_as_index %alloc_648 : memref<1x15x20x256xi8> -> index
    %439 = arith.index_cast %intptr_652 : index to i64
    %intptr_653 = memref.extract_aligned_pointer_as_index %alloc_650 : memref<304x256xi8> -> index
    %440 = arith.index_cast %intptr_653 : index to i64
    %intptr_654 = memref.extract_aligned_pointer_as_index %alloc_651 : memref<304x128xi8> -> index
    %441 = arith.index_cast %intptr_654 : index to i64
    %intptr_655 = memref.extract_aligned_pointer_as_index %alloc_649 : memref<300x128xi8> -> index
    %442 = arith.index_cast %intptr_655 : index to i64
    call @buddy_rvv_memcpy_i8(%440, %439, %c76800_i64) : (i64, i64, i64) -> ()
    %443 = arith.addi %440, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%443, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_650 %92 %alloc_651 %91 {accScale = 0.00621239562 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%442, %441, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_650 : memref<304x256xi8>
    memref.dealloc %alloc_651 : memref<304x128xi8>
    %alloc_656 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_657 = memref.extract_aligned_pointer_as_index %alloc_656 : memref<1x15x20x128xf32> -> index
    %intptr_658 = memref.extract_aligned_pointer_as_index %alloc_649 : memref<300x128xi8> -> index
    %444 = arith.index_cast %intptr_657 : index to i64
    %445 = arith.index_cast %intptr_658 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%444, %445, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_31) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_649 : memref<300x128xi8>
    %alloc_659 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_656[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_659[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_660 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_659, %alloc_660 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_661 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_660[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %226[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_661[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_662 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_661[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_662[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_663 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_662[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_663[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_664 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_663[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_664[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_665 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c19 step %c1 {
        scf.for %arg168 = %c0 to %c24 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_665[%arg166, %arg167, %arg168, %arg169] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_666 = memref.subview %alloc_665[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_664, %subview_666 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_667 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_667[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            scf.for %arg170 = %c0 to %c5 step %c1 {
              scf.for %arg171 = %c0 to %c5 step %c1 {
                %646 = arith.addi %arg167, %arg170 : index
                %647 = arith.addi %arg168, %arg171 : index
                %648 = memref.load %alloc_665[%arg166, %646, %647, %arg169] : memref<1x19x24x128xi8>
                %649 = memref.load %alloc_667[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
                %650 = arith.maxsi %649, %648 : i8
                memref.store %650, %alloc_667[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_668 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_667[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xi8>
            memref.store %646, %alloc_668[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_669 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c19 step %c1 {
        scf.for %arg168 = %c0 to %c24 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_669[%arg166, %arg167, %arg168, %arg169] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_670 = memref.subview %alloc_669[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_667, %subview_670 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_671 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_671[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            scf.for %arg170 = %c0 to %c5 step %c1 {
              scf.for %arg171 = %c0 to %c5 step %c1 {
                %646 = arith.addi %arg167, %arg170 : index
                %647 = arith.addi %arg168, %arg171 : index
                %648 = memref.load %alloc_669[%arg166, %646, %647, %arg169] : memref<1x19x24x128xi8>
                %649 = memref.load %alloc_671[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
                %650 = arith.maxsi %649, %648 : i8
                memref.store %650, %alloc_671[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_672 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_671[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xi8>
            memref.store %646, %alloc_672[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_673 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c19 step %c1 {
        scf.for %arg168 = %c0 to %c24 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_673[%arg166, %arg167, %arg168, %arg169] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_674 = memref.subview %alloc_673[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_671, %subview_674 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_675 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_675[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            scf.for %arg170 = %c0 to %c5 step %c1 {
              scf.for %arg171 = %c0 to %c5 step %c1 {
                %646 = arith.addi %arg167, %arg170 : index
                %647 = arith.addi %arg168, %arg171 : index
                %648 = memref.load %alloc_673[%arg166, %646, %647, %arg169] : memref<1x19x24x128xi8>
                %649 = memref.load %alloc_675[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
                %650 = arith.maxsi %649, %648 : i8
                memref.store %650, %alloc_675[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_676 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_675[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xi8>
            memref.store %646, %alloc_676[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_677 = memref.alloc() {alignment = 64 : i64} : memref<1x512x15x20xi8>
    %subview_678 = memref.subview %alloc_677[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    memref.copy %alloc_663, %subview_678 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    %subview_679 = memref.subview %alloc_677[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_668, %subview_679 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    %subview_680 = memref.subview %alloc_677[0, 256, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    memref.copy %alloc_672, %subview_680 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    %subview_681 = memref.subview %alloc_677[0, 384, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    memref.copy %alloc_676, %subview_681 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    %alloc_682 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x512xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c512 step %c1 {
            %646 = memref.load %alloc_677[%arg166, %arg169, %arg167, %arg168] : memref<1x512x15x20xi8>
            memref.store %646, %alloc_682[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x512xi8>
          }
        }
      }
    }
    %alloc_683 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_684 = memref.alloc() {alignment = 64 : i64} : memref<304x512xi8>
    %alloc_685 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_686 = memref.extract_aligned_pointer_as_index %alloc_682 : memref<1x15x20x512xi8> -> index
    %446 = arith.index_cast %intptr_686 : index to i64
    %intptr_687 = memref.extract_aligned_pointer_as_index %alloc_684 : memref<304x512xi8> -> index
    %447 = arith.index_cast %intptr_687 : index to i64
    %intptr_688 = memref.extract_aligned_pointer_as_index %alloc_685 : memref<304x256xi8> -> index
    %448 = arith.index_cast %intptr_688 : index to i64
    %intptr_689 = memref.extract_aligned_pointer_as_index %alloc_683 : memref<300x256xi8> -> index
    %449 = arith.index_cast %intptr_689 : index to i64
    call @buddy_rvv_memcpy_i8(%447, %446, %c153600_i64) : (i64, i64, i64) -> ()
    %450 = arith.addi %447, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%450, %c0_i64, %c2048_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_684 %90 %alloc_685 %89 {accScale = 8.516760e-03 : f32} : memref<304x512xi8> memref<512x256xi8> memref<304x256xi8> memref<304x256xi32>
    call @buddy_rvv_copy_rows_i8(%449, %448, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_684 : memref<304x512xi8>
    memref.dealloc %alloc_685 : memref<304x256xi8>
    %alloc_690 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_691 = memref.extract_aligned_pointer_as_index %alloc_690 : memref<1x15x20x256xf32> -> index
    %intptr_692 = memref.extract_aligned_pointer_as_index %alloc_683 : memref<300x256xi8> -> index
    %451 = arith.index_cast %intptr_691 : index to i64
    %452 = arith.index_cast %intptr_692 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%451, %452, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_30) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_683 : memref<300x256xi8>
    %alloc_693 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_690[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x256xf32>
            memref.store %646, %alloc_693[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_694 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_693, %alloc_694 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_695 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_694[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = memref.load %225[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_695[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_696 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_695[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_696[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_697 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_696[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_697[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_698 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_697[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_698[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_699 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_700 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_701 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_702 = memref.extract_aligned_pointer_as_index %alloc_698 : memref<1x15x20x256xi8> -> index
    %453 = arith.index_cast %intptr_702 : index to i64
    %intptr_703 = memref.extract_aligned_pointer_as_index %alloc_700 : memref<304x256xi8> -> index
    %454 = arith.index_cast %intptr_703 : index to i64
    %intptr_704 = memref.extract_aligned_pointer_as_index %alloc_701 : memref<304x128xi8> -> index
    %455 = arith.index_cast %intptr_704 : index to i64
    %intptr_705 = memref.extract_aligned_pointer_as_index %alloc_699 : memref<300x128xi8> -> index
    %456 = arith.index_cast %intptr_705 : index to i64
    call @buddy_rvv_memcpy_i8(%454, %453, %c76800_i64) : (i64, i64, i64) -> ()
    %457 = arith.addi %454, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%457, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_700 %88 %alloc_701 %87 {accScale = 0.00958314538 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%456, %455, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_700 : memref<304x256xi8>
    memref.dealloc %alloc_701 : memref<304x128xi8>
    %alloc_706 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_707 = memref.extract_aligned_pointer_as_index %alloc_706 : memref<1x15x20x128xf32> -> index
    %intptr_708 = memref.extract_aligned_pointer_as_index %alloc_699 : memref<300x128xi8> -> index
    %458 = arith.index_cast %intptr_707 : index to i64
    %459 = arith.index_cast %intptr_708 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%458, %459, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_29) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_699 : memref<300x128xi8>
    %alloc_709 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_706[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_709[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_710 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_709, %alloc_710 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_711 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_710[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %224[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_711[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_712 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_711[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_712[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_713 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_712[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_713[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_714 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_713[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_714[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_715 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = arith.index_cast %arg167 : index to i32
            %647 = arith.index_cast %arg168 : index to i32
            %648 = arith.divsi %646, %c2_i32 : i32
            %649 = arith.muli %648, %c2_i32 : i32
            %650 = arith.subi %646, %649 : i32
            %651 = arith.divsi %647, %c2_i32 : i32
            %652 = arith.muli %651, %c2_i32 : i32
            %653 = arith.subi %647, %652 : i32
            %654 = arith.shli %650, %c1_i32 : i32
            %655 = arith.cmpi sge, %654, %c2_i32 : i32
            %656 = arith.extui %655 : i1 to i32
            %657 = arith.addi %648, %656 : i32
            %658 = arith.maxsi %657, %c0_i32 : i32
            %659 = arith.minsi %658, %c14_i32 : i32
            %660 = arith.index_cast %659 : i32 to index
            %661 = arith.shli %653, %c1_i32 : i32
            %662 = arith.cmpi sge, %661, %c2_i32 : i32
            %663 = arith.extui %662 : i1 to i32
            %664 = arith.addi %651, %663 : i32
            %665 = arith.maxsi %664, %c0_i32 : i32
            %666 = arith.minsi %665, %c19_i32 : i32
            %667 = arith.index_cast %666 : i32 to index
            %668 = memref.load %alloc_714[%c0, %660, %667, %arg169] : memref<1x15x20x128xi8>
            memref.store %668, %alloc_715[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_716 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_715[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x128xi8>
            memref.store %646, %alloc_716[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_717 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_716[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_717[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_718 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_717[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %223[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_718[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_719 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_718[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_719[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_720 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_719[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_720[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_721 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_720[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_721[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_722 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_721[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_722[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_723 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_534[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_723[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_724 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_723[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %222[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_724[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_725 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_724[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_725[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_726 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_725[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_726[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_727 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_726[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_727[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_728 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_727[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_728[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_729 = memref.alloc() {alignment = 64 : i64} : memref<1x256x30x40xi8>
    %subview_730 = memref.subview %alloc_729[0, 0, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    memref.copy %alloc_722, %subview_730 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    %subview_731 = memref.subview %alloc_729[0, 128, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    memref.copy %alloc_728, %subview_731 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    %alloc_732 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_729[%arg166, %arg169, %arg167, %arg168] : memref<1x256x30x40xi8>
            memref.store %646, %alloc_732[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x256xi8>
          }
        }
      }
    }
    %alloc_733 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_734 = memref.alloc() {alignment = 64 : i64} : memref<1200x256xi8>
    %alloc_735 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_736 = memref.extract_aligned_pointer_as_index %alloc_732 : memref<1x30x40x256xi8> -> index
    %460 = arith.index_cast %intptr_736 : index to i64
    %intptr_737 = memref.extract_aligned_pointer_as_index %alloc_734 : memref<1200x256xi8> -> index
    %461 = arith.index_cast %intptr_737 : index to i64
    %intptr_738 = memref.extract_aligned_pointer_as_index %alloc_735 : memref<1200x64xi8> -> index
    %462 = arith.index_cast %intptr_738 : index to i64
    %intptr_739 = memref.extract_aligned_pointer_as_index %alloc_733 : memref<1200x64xi8> -> index
    %463 = arith.index_cast %intptr_739 : index to i64
    call @buddy_rvv_memcpy_i8(%461, %460, %c307200_i64) : (i64, i64, i64) -> ()
    %464 = arith.addi %461, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%464, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_734 %86 %alloc_735 %85 {accScale = 0.0254192129 : f32} : memref<1200x256xi8> memref<256x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%463, %462, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_734 : memref<1200x256xi8>
    memref.dealloc %alloc_735 : memref<1200x64xi8>
    %alloc_740 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_741 = memref.extract_aligned_pointer_as_index %alloc_740 : memref<1x30x40x64xf32> -> index
    %intptr_742 = memref.extract_aligned_pointer_as_index %alloc_733 : memref<1200x64xi8> -> index
    %465 = arith.index_cast %intptr_741 : index to i64
    %466 = arith.index_cast %intptr_742 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%465, %466, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_28) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_733 : memref<1200x64xi8>
    %alloc_743 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_740[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_743[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_744 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_743, %alloc_744 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_745 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_744[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %221[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_745[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_746 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_745[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_746[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_747 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_746[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_747[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_748 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_747[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_748[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_749 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_750 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_751 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_752 = memref.extract_aligned_pointer_as_index %alloc_748 : memref<1x30x40x64xi8> -> index
    %467 = arith.index_cast %intptr_752 : index to i64
    %intptr_753 = memref.extract_aligned_pointer_as_index %alloc_750 : memref<1200x64xi8> -> index
    %468 = arith.index_cast %intptr_753 : index to i64
    %intptr_754 = memref.extract_aligned_pointer_as_index %alloc_751 : memref<1200x64xi8> -> index
    %469 = arith.index_cast %intptr_754 : index to i64
    %intptr_755 = memref.extract_aligned_pointer_as_index %alloc_749 : memref<1200x64xi8> -> index
    %470 = arith.index_cast %intptr_755 : index to i64
    call @buddy_rvv_memcpy_i8(%468, %467, %c76800_i64) : (i64, i64, i64) -> ()
    %471 = arith.addi %468, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%471, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_750 %84 %alloc_751 %83 {accScale = 0.00802434888 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%470, %469, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_750 : memref<1200x64xi8>
    memref.dealloc %alloc_751 : memref<1200x64xi8>
    %alloc_756 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_757 = memref.extract_aligned_pointer_as_index %alloc_756 : memref<1x30x40x64xf32> -> index
    %intptr_758 = memref.extract_aligned_pointer_as_index %alloc_749 : memref<1200x64xi8> -> index
    %472 = arith.index_cast %intptr_757 : index to i64
    %473 = arith.index_cast %intptr_758 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%472, %473, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_27) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_749 : memref<1200x64xi8>
    %alloc_759 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_756[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_759[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_760 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_759, %alloc_760 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_761 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_760[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %220[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_761[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_762 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_761[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_762[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_763 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_762[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_763[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_764 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_763[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_764[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_765 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_765[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_766 = memref.subview %alloc_765[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_764, %subview_766 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_767 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %81[%arg169] : memref<64xi32>
            memref.store %646, %alloc_767[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_768 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_765 %82 %81 %alloc_768 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00396349095 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_769 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_770 = memref.extract_aligned_pointer_as_index %alloc_769 : memref<1x30x40x64xf32> -> index
    %intptr_771 = memref.extract_aligned_pointer_as_index %alloc_768 : memref<1200x64xi8> -> index
    %474 = arith.index_cast %intptr_770 : index to i64
    %475 = arith.index_cast %intptr_771 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%474, %475, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_26) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_768 : memref<1200x64xi8>
    %alloc_772 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_769[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_772[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_773 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_772, %alloc_773 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_774 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_773[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %219[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_774[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_775 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_774[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_775[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_776 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_775[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_776[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_777 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_729[%arg166, %arg169, %arg167, %arg168] : memref<1x256x30x40xi8>
            memref.store %646, %alloc_777[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x256xi8>
          }
        }
      }
    }
    %alloc_778 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_779 = memref.alloc() {alignment = 64 : i64} : memref<1200x256xi8>
    %alloc_780 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_781 = memref.extract_aligned_pointer_as_index %alloc_777 : memref<1x30x40x256xi8> -> index
    %476 = arith.index_cast %intptr_781 : index to i64
    %intptr_782 = memref.extract_aligned_pointer_as_index %alloc_779 : memref<1200x256xi8> -> index
    %477 = arith.index_cast %intptr_782 : index to i64
    %intptr_783 = memref.extract_aligned_pointer_as_index %alloc_780 : memref<1200x64xi8> -> index
    %478 = arith.index_cast %intptr_783 : index to i64
    %intptr_784 = memref.extract_aligned_pointer_as_index %alloc_778 : memref<1200x64xi8> -> index
    %479 = arith.index_cast %intptr_784 : index to i64
    call @buddy_rvv_memcpy_i8(%477, %476, %c307200_i64) : (i64, i64, i64) -> ()
    %480 = arith.addi %477, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%480, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_779 %80 %alloc_780 %79 {accScale = 0.0107464846 : f32} : memref<1200x256xi8> memref<256x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%479, %478, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_779 : memref<1200x256xi8>
    memref.dealloc %alloc_780 : memref<1200x64xi8>
    %alloc_785 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_786 = memref.extract_aligned_pointer_as_index %alloc_785 : memref<1x30x40x64xf32> -> index
    %intptr_787 = memref.extract_aligned_pointer_as_index %alloc_778 : memref<1200x64xi8> -> index
    %481 = arith.index_cast %intptr_786 : index to i64
    %482 = arith.index_cast %intptr_787 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%481, %482, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_26) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_778 : memref<1200x64xi8>
    %alloc_788 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_785[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_788[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_789 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_788, %alloc_789 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_790 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_789[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %218[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_790[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_791 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_790[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_791[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_792 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_791[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_792[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_793 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_776[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_793[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_794 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_793[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %217[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_794[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_795 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_794[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_795[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_796 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_795[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_796[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_797 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_796[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_797[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_798 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_797[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_798[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_799 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_792[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_799[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_800 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_799[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %216[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_800[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_801 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_800[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_801[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_802 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_801[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_802[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_803 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_802[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_803[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_804 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_803[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_804[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_805 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_806 = memref.subview %alloc_805[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_798, %subview_806 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_807 = memref.subview %alloc_805[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_804, %subview_807 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_808 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_805[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_808[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_809 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_810 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_811 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_812 = memref.extract_aligned_pointer_as_index %alloc_808 : memref<1x30x40x128xi8> -> index
    %483 = arith.index_cast %intptr_812 : index to i64
    %intptr_813 = memref.extract_aligned_pointer_as_index %alloc_810 : memref<1200x128xi8> -> index
    %484 = arith.index_cast %intptr_813 : index to i64
    %intptr_814 = memref.extract_aligned_pointer_as_index %alloc_811 : memref<1200x128xi8> -> index
    %485 = arith.index_cast %intptr_814 : index to i64
    %intptr_815 = memref.extract_aligned_pointer_as_index %alloc_809 : memref<1200x128xi8> -> index
    %486 = arith.index_cast %intptr_815 : index to i64
    call @buddy_rvv_memcpy_i8(%484, %483, %c153600_i64) : (i64, i64, i64) -> ()
    %487 = arith.addi %484, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%487, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_810 %78 %alloc_811 %77 {accScale = 9.169820e-03 : f32} : memref<1200x128xi8> memref<128x128xi8> memref<1200x128xi8> memref<1200x128xi32>
    call @buddy_rvv_copy_rows_i8(%486, %485, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_810 : memref<1200x128xi8>
    memref.dealloc %alloc_811 : memref<1200x128xi8>
    %alloc_816 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_817 = memref.extract_aligned_pointer_as_index %alloc_816 : memref<1x30x40x128xf32> -> index
    %intptr_818 = memref.extract_aligned_pointer_as_index %alloc_809 : memref<1200x128xi8> -> index
    %488 = arith.index_cast %intptr_817 : index to i64
    %489 = arith.index_cast %intptr_818 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%488, %489, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_25) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_809 : memref<1200x128xi8>
    %alloc_819 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_816[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x128xf32>
            memref.store %646, %alloc_819[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_820 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_819, %alloc_820 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_821 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_820[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = memref.load %215[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_821[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_822 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_821[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_822[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_823 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_822[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_823[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_824 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_823[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_824[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_825 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_826 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_827 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_828 = memref.extract_aligned_pointer_as_index %alloc_824 : memref<1x30x40x128xi8> -> index
    %490 = arith.index_cast %intptr_828 : index to i64
    %intptr_829 = memref.extract_aligned_pointer_as_index %alloc_826 : memref<1200x128xi8> -> index
    %491 = arith.index_cast %intptr_829 : index to i64
    %intptr_830 = memref.extract_aligned_pointer_as_index %alloc_827 : memref<1200x64xi8> -> index
    %492 = arith.index_cast %intptr_830 : index to i64
    %intptr_831 = memref.extract_aligned_pointer_as_index %alloc_825 : memref<1200x64xi8> -> index
    %493 = arith.index_cast %intptr_831 : index to i64
    call @buddy_rvv_memcpy_i8(%491, %490, %c153600_i64) : (i64, i64, i64) -> ()
    %494 = arith.addi %491, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%494, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_826 %76 %alloc_827 %75 {accScale = 5.732980e-03 : f32} : memref<1200x128xi8> memref<128x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%493, %492, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_826 : memref<1200x128xi8>
    memref.dealloc %alloc_827 : memref<1200x64xi8>
    %alloc_832 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_833 = memref.extract_aligned_pointer_as_index %alloc_832 : memref<1x30x40x64xf32> -> index
    %intptr_834 = memref.extract_aligned_pointer_as_index %alloc_825 : memref<1200x64xi8> -> index
    %495 = arith.index_cast %intptr_833 : index to i64
    %496 = arith.index_cast %intptr_834 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%495, %496, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_24) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_825 : memref<1200x64xi8>
    %alloc_835 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_832[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_835[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_836 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_835, %alloc_836 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_837 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_836[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %214[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_837[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_838 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_837[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_838[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_839 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_838[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_839[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_840 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_839[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_840[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_841 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = arith.index_cast %arg167 : index to i32
            %647 = arith.index_cast %arg168 : index to i32
            %648 = arith.divsi %646, %c2_i32 : i32
            %649 = arith.muli %648, %c2_i32 : i32
            %650 = arith.subi %646, %649 : i32
            %651 = arith.divsi %647, %c2_i32 : i32
            %652 = arith.muli %651, %c2_i32 : i32
            %653 = arith.subi %647, %652 : i32
            %654 = arith.shli %650, %c1_i32 : i32
            %655 = arith.cmpi sge, %654, %c2_i32 : i32
            %656 = arith.extui %655 : i1 to i32
            %657 = arith.addi %648, %656 : i32
            %658 = arith.maxsi %657, %c0_i32 : i32
            %659 = arith.minsi %658, %c29_i32 : i32
            %660 = arith.index_cast %659 : i32 to index
            %661 = arith.shli %653, %c1_i32 : i32
            %662 = arith.cmpi sge, %661, %c2_i32 : i32
            %663 = arith.extui %662 : i1 to i32
            %664 = arith.addi %651, %663 : i32
            %665 = arith.maxsi %664, %c0_i32 : i32
            %666 = arith.minsi %665, %c39_i32 : i32
            %667 = arith.index_cast %666 : i32 to index
            %668 = memref.load %alloc_840[%c0, %660, %667, %arg169] : memref<1x30x40x64xi8>
            memref.store %668, %alloc_841[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_842 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_841[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xi8>
            memref.store %646, %alloc_842[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_843 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_842[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_843[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_844 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_843[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %213[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_844[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_845 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_844[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_845[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_846 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_845[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_846[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_847 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_846[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_847[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_848 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_847[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_848[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_849 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_343[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_849[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_850 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_849[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %212[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_850[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_851 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_850[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_851[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_852 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_851[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_852[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_853 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_852[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_853[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_854 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_853[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_854[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_855 = memref.alloc() {alignment = 64 : i64} : memref<1x128x60x80xi8>
    %subview_856 = memref.subview %alloc_855[0, 0, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    memref.copy %alloc_848, %subview_856 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    %subview_857 = memref.subview %alloc_855[0, 64, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    memref.copy %alloc_854, %subview_857 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    %alloc_858 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_855[%arg166, %arg169, %arg167, %arg168] : memref<1x128x60x80xi8>
            memref.store %646, %alloc_858[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x128xi8>
          }
        }
      }
    }
    %alloc_859 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_860 = memref.alloc() {alignment = 64 : i64} : memref<4800x128xi8>
    %alloc_861 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_862 = memref.extract_aligned_pointer_as_index %alloc_858 : memref<1x60x80x128xi8> -> index
    %497 = arith.index_cast %intptr_862 : index to i64
    %intptr_863 = memref.extract_aligned_pointer_as_index %alloc_860 : memref<4800x128xi8> -> index
    %498 = arith.index_cast %intptr_863 : index to i64
    %intptr_864 = memref.extract_aligned_pointer_as_index %alloc_861 : memref<4800x32xi8> -> index
    %499 = arith.index_cast %intptr_864 : index to i64
    %intptr_865 = memref.extract_aligned_pointer_as_index %alloc_859 : memref<4800x32xi8> -> index
    %500 = arith.index_cast %intptr_865 : index to i64
    call @buddy_rvv_memcpy_i8(%498, %497, %c614400_i64) : (i64, i64, i64) -> ()
    %501 = arith.addi %498, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%501, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_860 %74 %alloc_861 %73 {accScale = 8.340900e-03 : f32} : memref<4800x128xi8> memref<128x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%500, %499, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_860 : memref<4800x128xi8>
    memref.dealloc %alloc_861 : memref<4800x32xi8>
    %alloc_866 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_867 = memref.extract_aligned_pointer_as_index %alloc_866 : memref<1x60x80x32xf32> -> index
    %intptr_868 = memref.extract_aligned_pointer_as_index %alloc_859 : memref<4800x32xi8> -> index
    %502 = arith.index_cast %intptr_867 : index to i64
    %503 = arith.index_cast %intptr_868 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%502, %503, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_23) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_859 : memref<4800x32xi8>
    %alloc_869 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_866[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_869[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_870 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_869, %alloc_870 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_871 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_870[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %211[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_871[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_872 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_871[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_872[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_873 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_872[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_873[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_874 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_873[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_874[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_875 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_876 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_877 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_878 = memref.extract_aligned_pointer_as_index %alloc_874 : memref<1x60x80x32xi8> -> index
    %504 = arith.index_cast %intptr_878 : index to i64
    %intptr_879 = memref.extract_aligned_pointer_as_index %alloc_876 : memref<4800x32xi8> -> index
    %505 = arith.index_cast %intptr_879 : index to i64
    %intptr_880 = memref.extract_aligned_pointer_as_index %alloc_877 : memref<4800x32xi8> -> index
    %506 = arith.index_cast %intptr_880 : index to i64
    %intptr_881 = memref.extract_aligned_pointer_as_index %alloc_875 : memref<4800x32xi8> -> index
    %507 = arith.index_cast %intptr_881 : index to i64
    call @buddy_rvv_memcpy_i8(%505, %504, %c153600_i64) : (i64, i64, i64) -> ()
    %508 = arith.addi %505, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%508, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_876 %72 %alloc_877 %71 {accScale = 0.0178376455 : f32} : memref<4800x32xi8> memref<32x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%507, %506, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_876 : memref<4800x32xi8>
    memref.dealloc %alloc_877 : memref<4800x32xi8>
    %alloc_882 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_883 = memref.extract_aligned_pointer_as_index %alloc_882 : memref<1x60x80x32xf32> -> index
    %intptr_884 = memref.extract_aligned_pointer_as_index %alloc_875 : memref<4800x32xi8> -> index
    %509 = arith.index_cast %intptr_883 : index to i64
    %510 = arith.index_cast %intptr_884 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%509, %510, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_22) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_875 : memref<4800x32xi8>
    %alloc_885 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_882[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_885[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_886 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_885, %alloc_886 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_887 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_886[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %210[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_887[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_888 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_887[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_888[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_889 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_888[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_889[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_890 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %alloc_889[%arg166, %arg169, %arg167, %arg168] : memref<1x32x60x80xi8>
            memref.store %646, %alloc_890[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_891 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_891[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_892 = memref.subview %alloc_891[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_890, %subview_892 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_893 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c32 step %c1 {
            %646 = memref.load %69[%arg169] : memref<32xi32>
            memref.store %646, %alloc_893[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_894 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    gemmini.tile_conv %alloc_891 %70 %69 %alloc_894 %c60_i64 %c80_i64 %c3_i64 {scale = 0.007817436 : f32} : memref<1x62x82x32xi8> memref<288x32xi8> memref<32xi32> memref<4800x32xi8> i64 i64 i64
    %alloc_895 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_896 = memref.extract_aligned_pointer_as_index %alloc_895 : memref<1x60x80x32xf32> -> index
    %intptr_897 = memref.extract_aligned_pointer_as_index %alloc_894 : memref<4800x32xi8> -> index
    %511 = arith.index_cast %intptr_896 : index to i64
    %512 = arith.index_cast %intptr_897 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%511, %512, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_21) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_894 : memref<4800x32xi8>
    %alloc_898 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_895[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_898[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_899 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_898, %alloc_899 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_900 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_899[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %209[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_900[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_901 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_900[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_901[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_902 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_901[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_902[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_903 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_855[%arg166, %arg169, %arg167, %arg168] : memref<1x128x60x80xi8>
            memref.store %646, %alloc_903[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x128xi8>
          }
        }
      }
    }
    %alloc_904 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_905 = memref.alloc() {alignment = 64 : i64} : memref<4800x128xi8>
    %alloc_906 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_907 = memref.extract_aligned_pointer_as_index %alloc_903 : memref<1x60x80x128xi8> -> index
    %513 = arith.index_cast %intptr_907 : index to i64
    %intptr_908 = memref.extract_aligned_pointer_as_index %alloc_905 : memref<4800x128xi8> -> index
    %514 = arith.index_cast %intptr_908 : index to i64
    %intptr_909 = memref.extract_aligned_pointer_as_index %alloc_906 : memref<4800x32xi8> -> index
    %515 = arith.index_cast %intptr_909 : index to i64
    %intptr_910 = memref.extract_aligned_pointer_as_index %alloc_904 : memref<4800x32xi8> -> index
    %516 = arith.index_cast %intptr_910 : index to i64
    call @buddy_rvv_memcpy_i8(%514, %513, %c614400_i64) : (i64, i64, i64) -> ()
    %517 = arith.addi %514, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%517, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_905 %68 %alloc_906 %67 {accScale = 0.00953922048 : f32} : memref<4800x128xi8> memref<128x32xi8> memref<4800x32xi8> memref<4800x32xi32>
    call @buddy_rvv_copy_rows_i8(%516, %515, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_905 : memref<4800x128xi8>
    memref.dealloc %alloc_906 : memref<4800x32xi8>
    %alloc_911 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_912 = memref.extract_aligned_pointer_as_index %alloc_911 : memref<1x60x80x32xf32> -> index
    %intptr_913 = memref.extract_aligned_pointer_as_index %alloc_904 : memref<4800x32xi8> -> index
    %518 = arith.index_cast %intptr_912 : index to i64
    %519 = arith.index_cast %intptr_913 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%518, %519, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_21) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_904 : memref<4800x32xi8>
    %alloc_914 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_911[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x32xf32>
            memref.store %646, %alloc_914[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_915 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_914, %alloc_915 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_916 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_915[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = memref.load %208[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_916[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_917 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_916[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_917[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_918 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_917[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_918[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_919 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_902[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_919[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_920 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_919[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %207[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_920[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_921 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_920[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_921[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_922 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_921[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_922[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_923 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_922[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_923[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_924 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_923[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_924[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_925 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_918[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_925[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_926 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_925[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %206[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_926[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_927 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_926[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_927[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_928 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_927[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_928[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_929 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_928[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_929[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_930 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_929[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_930[%arg166, %arg167, %arg168, %arg169] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_931 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_932 = memref.subview %alloc_931[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_924, %subview_932 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_933 = memref.subview %alloc_931[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_930, %subview_933 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_934 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_931[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_934[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_935 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_936 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_937 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_938 = memref.extract_aligned_pointer_as_index %alloc_934 : memref<1x60x80x64xi8> -> index
    %520 = arith.index_cast %intptr_938 : index to i64
    %intptr_939 = memref.extract_aligned_pointer_as_index %alloc_936 : memref<4800x64xi8> -> index
    %521 = arith.index_cast %intptr_939 : index to i64
    %intptr_940 = memref.extract_aligned_pointer_as_index %alloc_937 : memref<4800x64xi8> -> index
    %522 = arith.index_cast %intptr_940 : index to i64
    %intptr_941 = memref.extract_aligned_pointer_as_index %alloc_935 : memref<4800x64xi8> -> index
    %523 = arith.index_cast %intptr_941 : index to i64
    call @buddy_rvv_memcpy_i8(%521, %520, %c307200_i64) : (i64, i64, i64) -> ()
    %524 = arith.addi %521, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%524, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_936 %66 %alloc_937 %65 {accScale = 0.0133869769 : f32} : memref<4800x64xi8> memref<64x64xi8> memref<4800x64xi8> memref<4800x64xi32>
    call @buddy_rvv_copy_rows_i8(%523, %522, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_936 : memref<4800x64xi8>
    memref.dealloc %alloc_937 : memref<4800x64xi8>
    %alloc_942 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_943 = memref.extract_aligned_pointer_as_index %alloc_942 : memref<1x60x80x64xf32> -> index
    %intptr_944 = memref.extract_aligned_pointer_as_index %alloc_935 : memref<4800x64xi8> -> index
    %525 = arith.index_cast %intptr_943 : index to i64
    %526 = arith.index_cast %intptr_944 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%525, %526, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_20) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_935 : memref<4800x64xi8>
    %alloc_945 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_942[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_945[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_946 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_945, %alloc_946 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_947 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_946[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = memref.load %205[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_947[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_948 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_947[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_948[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_949 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_948[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_949[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_950 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_949[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_950[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_951 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c61 step %c1 {
        scf.for %arg168 = %c0 to %c81 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_951[%arg166, %arg167, %arg168, %arg169] : memref<1x61x81x64xi8>
          }
        }
      }
    }
    %subview_952 = memref.subview %alloc_951[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_950, %subview_952 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_953 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %63[%arg169] : memref<64xi32>
            memref.store %646, %alloc_953[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_954 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_951 %64 %63 %alloc_954 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00338776759 : f32, stride = 2 : i64} : memref<1x61x81x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_955 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_956 = memref.extract_aligned_pointer_as_index %alloc_955 : memref<1x30x40x64xf32> -> index
    %intptr_957 = memref.extract_aligned_pointer_as_index %alloc_954 : memref<1200x64xi8> -> index
    %527 = arith.index_cast %intptr_956 : index to i64
    %528 = arith.index_cast %intptr_957 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%527, %528, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_19) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_954 : memref<1200x64xi8>
    %alloc_958 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_955[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_958[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_959 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_958, %alloc_959 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_960 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_959[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %204[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_960[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_961 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_960[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_961[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_962 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_961[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_962[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_963 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_962[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_963[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_964 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_963[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %203[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_964[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_965 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_964[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_965[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_966 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_965[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_966[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_967 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_966[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_967[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_968 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_967[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_968[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_969 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_839[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_969[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_970 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_969[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %202[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_970[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_971 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_970[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_971[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_972 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_971[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_972[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_973 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_972[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_973[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_974 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_973[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_974[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_975 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_976 = memref.subview %alloc_975[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_968, %subview_976 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_977 = memref.subview %alloc_975[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_974, %subview_977 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_978 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_975[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_978[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_979 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_980 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_981 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_982 = memref.extract_aligned_pointer_as_index %alloc_978 : memref<1x30x40x128xi8> -> index
    %529 = arith.index_cast %intptr_982 : index to i64
    %intptr_983 = memref.extract_aligned_pointer_as_index %alloc_980 : memref<1200x128xi8> -> index
    %530 = arith.index_cast %intptr_983 : index to i64
    %intptr_984 = memref.extract_aligned_pointer_as_index %alloc_981 : memref<1200x64xi8> -> index
    %531 = arith.index_cast %intptr_984 : index to i64
    %intptr_985 = memref.extract_aligned_pointer_as_index %alloc_979 : memref<1200x64xi8> -> index
    %532 = arith.index_cast %intptr_985 : index to i64
    call @buddy_rvv_memcpy_i8(%530, %529, %c153600_i64) : (i64, i64, i64) -> ()
    %533 = arith.addi %530, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%533, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_980 %62 %alloc_981 %61 {accScale = 0.00869756192 : f32} : memref<1200x128xi8> memref<128x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%532, %531, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_980 : memref<1200x128xi8>
    memref.dealloc %alloc_981 : memref<1200x64xi8>
    %alloc_986 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_987 = memref.extract_aligned_pointer_as_index %alloc_986 : memref<1x30x40x64xf32> -> index
    %intptr_988 = memref.extract_aligned_pointer_as_index %alloc_979 : memref<1200x64xi8> -> index
    %534 = arith.index_cast %intptr_987 : index to i64
    %535 = arith.index_cast %intptr_988 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%534, %535, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_18) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_979 : memref<1200x64xi8>
    %alloc_989 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_986[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_989[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_990 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_989, %alloc_990 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_991 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_990[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %201[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_991[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_992 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_991[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_992[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_993 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_992[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_993[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_994 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_993[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_994[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_995 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_996 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_997 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_998 = memref.extract_aligned_pointer_as_index %alloc_994 : memref<1x30x40x64xi8> -> index
    %536 = arith.index_cast %intptr_998 : index to i64
    %intptr_999 = memref.extract_aligned_pointer_as_index %alloc_996 : memref<1200x64xi8> -> index
    %537 = arith.index_cast %intptr_999 : index to i64
    %intptr_1000 = memref.extract_aligned_pointer_as_index %alloc_997 : memref<1200x64xi8> -> index
    %538 = arith.index_cast %intptr_1000 : index to i64
    %intptr_1001 = memref.extract_aligned_pointer_as_index %alloc_995 : memref<1200x64xi8> -> index
    %539 = arith.index_cast %intptr_1001 : index to i64
    call @buddy_rvv_memcpy_i8(%537, %536, %c76800_i64) : (i64, i64, i64) -> ()
    %540 = arith.addi %537, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%540, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_996 %60 %alloc_997 %59 {accScale = 0.0079792682 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%539, %538, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_996 : memref<1200x64xi8>
    memref.dealloc %alloc_997 : memref<1200x64xi8>
    %alloc_1002 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1003 = memref.extract_aligned_pointer_as_index %alloc_1002 : memref<1x30x40x64xf32> -> index
    %intptr_1004 = memref.extract_aligned_pointer_as_index %alloc_995 : memref<1200x64xi8> -> index
    %541 = arith.index_cast %intptr_1003 : index to i64
    %542 = arith.index_cast %intptr_1004 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%541, %542, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_17) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_995 : memref<1200x64xi8>
    %alloc_1005 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1002[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1005[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1006 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1005, %alloc_1006 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1007 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1006[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %200[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1007[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1008 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1007[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1008[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1009 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1008[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1009[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1010 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1009[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_1010[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1011 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1011[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_1012 = memref.subview %alloc_1011[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_1010, %subview_1012 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_1013 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %57[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1013[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_1014 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_1011 %58 %57 %alloc_1014 %c30_i64 %c40_i64 %c3_i64 {scale = 0.0050264271 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_1015 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1016 = memref.extract_aligned_pointer_as_index %alloc_1015 : memref<1x30x40x64xf32> -> index
    %intptr_1017 = memref.extract_aligned_pointer_as_index %alloc_1014 : memref<1200x64xi8> -> index
    %543 = arith.index_cast %intptr_1016 : index to i64
    %544 = arith.index_cast %intptr_1017 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%543, %544, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_16) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1014 : memref<1200x64xi8>
    %alloc_1018 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1015[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1018[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1019 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1018, %alloc_1019 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1020 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1019[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %199[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1020[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1021 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1020[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1021[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1022 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1021[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1022[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1023 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_975[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_1023[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1024 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1025 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1026 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1027 = memref.extract_aligned_pointer_as_index %alloc_1023 : memref<1x30x40x128xi8> -> index
    %545 = arith.index_cast %intptr_1027 : index to i64
    %intptr_1028 = memref.extract_aligned_pointer_as_index %alloc_1025 : memref<1200x128xi8> -> index
    %546 = arith.index_cast %intptr_1028 : index to i64
    %intptr_1029 = memref.extract_aligned_pointer_as_index %alloc_1026 : memref<1200x64xi8> -> index
    %547 = arith.index_cast %intptr_1029 : index to i64
    %intptr_1030 = memref.extract_aligned_pointer_as_index %alloc_1024 : memref<1200x64xi8> -> index
    %548 = arith.index_cast %intptr_1030 : index to i64
    call @buddy_rvv_memcpy_i8(%546, %545, %c153600_i64) : (i64, i64, i64) -> ()
    %549 = arith.addi %546, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%549, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1025 %56 %alloc_1026 %55 {accScale = 0.00879147648 : f32} : memref<1200x128xi8> memref<128x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%548, %547, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1025 : memref<1200x128xi8>
    memref.dealloc %alloc_1026 : memref<1200x64xi8>
    %alloc_1031 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1032 = memref.extract_aligned_pointer_as_index %alloc_1031 : memref<1x30x40x64xf32> -> index
    %intptr_1033 = memref.extract_aligned_pointer_as_index %alloc_1024 : memref<1200x64xi8> -> index
    %550 = arith.index_cast %intptr_1032 : index to i64
    %551 = arith.index_cast %intptr_1033 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%550, %551, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_16) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1024 : memref<1200x64xi8>
    %alloc_1034 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1031[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1034[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1035 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1034, %alloc_1035 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1036 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1035[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %198[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1036[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1037 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1036[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1037[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1038 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1037[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1038[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1039 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1022[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1039[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1040 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1039[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %197[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1040[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1041 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1040[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1041[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1042 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1041[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1042[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1043 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1042[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1043[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1044 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1043[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1044[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1045 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1038[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1045[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1046 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1045[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %196[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1046[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1047 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1046[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1047[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1048 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1047[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1048[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1049 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1048[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1049[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1050 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1049[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1050[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1051 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_1052 = memref.subview %alloc_1051[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_1044, %subview_1052 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_1053 = memref.subview %alloc_1051[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_1050, %subview_1053 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_1054 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1051[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_1054[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1055 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1056 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1057 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_1058 = memref.extract_aligned_pointer_as_index %alloc_1054 : memref<1x30x40x128xi8> -> index
    %552 = arith.index_cast %intptr_1058 : index to i64
    %intptr_1059 = memref.extract_aligned_pointer_as_index %alloc_1056 : memref<1200x128xi8> -> index
    %553 = arith.index_cast %intptr_1059 : index to i64
    %intptr_1060 = memref.extract_aligned_pointer_as_index %alloc_1057 : memref<1200x128xi8> -> index
    %554 = arith.index_cast %intptr_1060 : index to i64
    %intptr_1061 = memref.extract_aligned_pointer_as_index %alloc_1055 : memref<1200x128xi8> -> index
    %555 = arith.index_cast %intptr_1061 : index to i64
    call @buddy_rvv_memcpy_i8(%553, %552, %c153600_i64) : (i64, i64, i64) -> ()
    %556 = arith.addi %553, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%556, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1056 %54 %alloc_1057 %53 {accScale = 0.0108789504 : f32} : memref<1200x128xi8> memref<128x128xi8> memref<1200x128xi8> memref<1200x128xi32>
    call @buddy_rvv_copy_rows_i8(%555, %554, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1056 : memref<1200x128xi8>
    memref.dealloc %alloc_1057 : memref<1200x128xi8>
    %alloc_1062 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_1063 = memref.extract_aligned_pointer_as_index %alloc_1062 : memref<1x30x40x128xf32> -> index
    %intptr_1064 = memref.extract_aligned_pointer_as_index %alloc_1055 : memref<1200x128xi8> -> index
    %557 = arith.index_cast %intptr_1063 : index to i64
    %558 = arith.index_cast %intptr_1064 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%557, %558, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_15) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1055 : memref<1200x128xi8>
    %alloc_1065 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1062[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x128xf32>
            memref.store %646, %alloc_1065[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1066 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_1065, %alloc_1066 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_1067 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1066[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = memref.load %195[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1067[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1068 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1067[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1068[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1069 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1068[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1069[%arg166, %arg167, %arg168, %arg169] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1070 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1069[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_1070[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1071 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c31 step %c1 {
        scf.for %arg168 = %c0 to %c41 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1071[%arg166, %arg167, %arg168, %arg169] : memref<1x31x41x128xi8>
          }
        }
      }
    }
    %subview_1072 = memref.subview %alloc_1071[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_1070, %subview_1072 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_1073 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %51[%arg169] : memref<128xi32>
            memref.store %646, %alloc_1073[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_1074 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    gemmini.tile_conv %alloc_1071 %52 %51 %alloc_1074 %c15_i64 %c20_i64 %c3_i64 {scale = 0.0048789829 : f32, stride = 2 : i64} : memref<1x31x41x128xi8> memref<1152x128xi8> memref<128xi32> memref<300x128xi8> i64 i64 i64
    %alloc_1075 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1076 = memref.extract_aligned_pointer_as_index %alloc_1075 : memref<1x15x20x128xf32> -> index
    %intptr_1077 = memref.extract_aligned_pointer_as_index %alloc_1074 : memref<300x128xi8> -> index
    %559 = arith.index_cast %intptr_1076 : index to i64
    %560 = arith.index_cast %intptr_1077 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%559, %560, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_29) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1074 : memref<300x128xi8>
    %alloc_1078 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1075[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_1078[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1079 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1078, %alloc_1079 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1080 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1079[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %194[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1080[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1081 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1080[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1081[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1082 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1081[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1082[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1083 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1082[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1083[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1084 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1083[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %193[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1084[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1085 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1084[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1085[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1086 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1085[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1086[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1087 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1086[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1087[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1088 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1087[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1088[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1089 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_713[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1089[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1090 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1089[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %192[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1090[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1091 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1090[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1091[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1092 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1091[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1092[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1093 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1092[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1093[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1094 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1093[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1094[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1095 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_1096 = memref.subview %alloc_1095[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_1088, %subview_1096 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_1097 = memref.subview %alloc_1095[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_1094, %subview_1097 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_1098 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_1095[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_1098[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1099 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1100 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1101 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1102 = memref.extract_aligned_pointer_as_index %alloc_1098 : memref<1x15x20x256xi8> -> index
    %561 = arith.index_cast %intptr_1102 : index to i64
    %intptr_1103 = memref.extract_aligned_pointer_as_index %alloc_1100 : memref<304x256xi8> -> index
    %562 = arith.index_cast %intptr_1103 : index to i64
    %intptr_1104 = memref.extract_aligned_pointer_as_index %alloc_1101 : memref<304x128xi8> -> index
    %563 = arith.index_cast %intptr_1104 : index to i64
    %intptr_1105 = memref.extract_aligned_pointer_as_index %alloc_1099 : memref<300x128xi8> -> index
    %564 = arith.index_cast %intptr_1105 : index to i64
    call @buddy_rvv_memcpy_i8(%562, %561, %c76800_i64) : (i64, i64, i64) -> ()
    %565 = arith.addi %562, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%565, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1100 %50 %alloc_1101 %49 {accScale = 0.0125225503 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%564, %563, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1100 : memref<304x256xi8>
    memref.dealloc %alloc_1101 : memref<304x128xi8>
    %alloc_1106 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1107 = memref.extract_aligned_pointer_as_index %alloc_1106 : memref<1x15x20x128xf32> -> index
    %intptr_1108 = memref.extract_aligned_pointer_as_index %alloc_1099 : memref<300x128xi8> -> index
    %566 = arith.index_cast %intptr_1107 : index to i64
    %567 = arith.index_cast %intptr_1108 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%566, %567, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_14) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1099 : memref<300x128xi8>
    %alloc_1109 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1106[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_1109[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1110 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1109, %alloc_1110 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1111 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1110[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %191[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1111[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1112 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1111[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1112[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1113 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1112[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1113[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1114 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1113[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_1114[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1115 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1116 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %alloc_1117 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1118 = memref.extract_aligned_pointer_as_index %alloc_1114 : memref<1x15x20x128xi8> -> index
    %568 = arith.index_cast %intptr_1118 : index to i64
    %intptr_1119 = memref.extract_aligned_pointer_as_index %alloc_1116 : memref<304x128xi8> -> index
    %569 = arith.index_cast %intptr_1119 : index to i64
    %intptr_1120 = memref.extract_aligned_pointer_as_index %alloc_1117 : memref<304x128xi8> -> index
    %570 = arith.index_cast %intptr_1120 : index to i64
    %intptr_1121 = memref.extract_aligned_pointer_as_index %alloc_1115 : memref<300x128xi8> -> index
    %571 = arith.index_cast %intptr_1121 : index to i64
    call @buddy_rvv_memcpy_i8(%569, %568, %c38400_i64) : (i64, i64, i64) -> ()
    %572 = arith.addi %569, %c38400_i64 : i64
    call @buddy_rvv_memset_i8(%572, %c0_i64, %c512_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1116 %48 %alloc_1117 %47 {accScale = 0.00973275303 : f32} : memref<304x128xi8> memref<128x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%571, %570, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1116 : memref<304x128xi8>
    memref.dealloc %alloc_1117 : memref<304x128xi8>
    %alloc_1122 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1123 = memref.extract_aligned_pointer_as_index %alloc_1122 : memref<1x15x20x128xf32> -> index
    %intptr_1124 = memref.extract_aligned_pointer_as_index %alloc_1115 : memref<300x128xi8> -> index
    %573 = arith.index_cast %intptr_1123 : index to i64
    %574 = arith.index_cast %intptr_1124 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%573, %574, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_13) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1115 : memref<300x128xi8>
    %alloc_1125 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1122[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_1125[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1126 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1125, %alloc_1126 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1127 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1126[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %190[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1127[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1128 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1127[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1128[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1129 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1128[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1129[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1130 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1129[%arg166, %arg169, %arg167, %arg168] : memref<1x128x15x20xi8>
            memref.store %646, %alloc_1130[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1131 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1131[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x128xi8>
          }
        }
      }
    }
    %subview_1132 = memref.subview %alloc_1131[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_1130, %subview_1132 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_1133 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %45[%arg169] : memref<128xi32>
            memref.store %646, %alloc_1133[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_1134 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    gemmini.tile_conv %alloc_1131 %46 %45 %alloc_1134 %c15_i64 %c20_i64 %c3_i64 {scale = 0.00472895242 : f32} : memref<1x17x22x128xi8> memref<1152x128xi8> memref<128xi32> memref<300x128xi8> i64 i64 i64
    %alloc_1135 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1136 = memref.extract_aligned_pointer_as_index %alloc_1135 : memref<1x15x20x128xf32> -> index
    %intptr_1137 = memref.extract_aligned_pointer_as_index %alloc_1134 : memref<300x128xi8> -> index
    %575 = arith.index_cast %intptr_1136 : index to i64
    %576 = arith.index_cast %intptr_1137 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%575, %576, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_12) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1134 : memref<300x128xi8>
    %alloc_1138 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1135[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_1138[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1139 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1138, %alloc_1139 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1140 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1139[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %189[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1140[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1141 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1140[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1141[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1142 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1141[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1142[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1143 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_1095[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_1143[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1144 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1145 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1146 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1147 = memref.extract_aligned_pointer_as_index %alloc_1143 : memref<1x15x20x256xi8> -> index
    %577 = arith.index_cast %intptr_1147 : index to i64
    %intptr_1148 = memref.extract_aligned_pointer_as_index %alloc_1145 : memref<304x256xi8> -> index
    %578 = arith.index_cast %intptr_1148 : index to i64
    %intptr_1149 = memref.extract_aligned_pointer_as_index %alloc_1146 : memref<304x128xi8> -> index
    %579 = arith.index_cast %intptr_1149 : index to i64
    %intptr_1150 = memref.extract_aligned_pointer_as_index %alloc_1144 : memref<300x128xi8> -> index
    %580 = arith.index_cast %intptr_1150 : index to i64
    call @buddy_rvv_memcpy_i8(%578, %577, %c76800_i64) : (i64, i64, i64) -> ()
    %581 = arith.addi %578, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%581, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1145 %44 %alloc_1146 %43 {accScale = 0.00609090552 : f32} : memref<304x256xi8> memref<256x128xi8> memref<304x128xi8> memref<304x128xi32>
    call @buddy_rvv_copy_rows_i8(%580, %579, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1145 : memref<304x256xi8>
    memref.dealloc %alloc_1146 : memref<304x128xi8>
    %alloc_1151 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1152 = memref.extract_aligned_pointer_as_index %alloc_1151 : memref<1x15x20x128xf32> -> index
    %intptr_1153 = memref.extract_aligned_pointer_as_index %alloc_1144 : memref<300x128xi8> -> index
    %582 = arith.index_cast %intptr_1152 : index to i64
    %583 = arith.index_cast %intptr_1153 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%582, %583, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_12) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1144 : memref<300x128xi8>
    %alloc_1154 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1151[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x128xf32>
            memref.store %646, %alloc_1154[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1155 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1154, %alloc_1155 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1156 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1155[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = memref.load %188[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1156[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1157 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1156[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1157[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1158 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1157[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1158[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1159 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1142[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1159[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1160 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1159[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %187[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1160[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1161 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1160[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1161[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1162 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1161[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1162[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1163 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1162[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1163[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1164 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1163[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1164[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1165 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1158[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
            %647 = arith.extsi %646 : i8 to i32
            memref.store %647, %alloc_1165[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1166 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1165[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %186[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.muli %646, %647 : i32
            memref.store %648, %alloc_1166[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1167 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1166[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %274[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.shrsi %646, %647 : i32
            memref.store %648, %alloc_1167[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1168 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1167[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %272[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.maxsi %646, %647 : i32
            memref.store %648, %alloc_1168[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1169 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1168[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = memref.load %271[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %648 = arith.minsi %646, %647 : i32
            memref.store %648, %alloc_1169[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1170 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c128 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1169[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi32>
            %647 = arith.trunci %646 : i32 to i8
            memref.store %647, %alloc_1170[%arg166, %arg167, %arg168, %arg169] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1171 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_1172 = memref.subview %alloc_1171[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_1164, %subview_1172 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_1173 = memref.subview %alloc_1171[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_1170, %subview_1173 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_1174 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_1171[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_1174[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1175 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_1176 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1177 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_1178 = memref.extract_aligned_pointer_as_index %alloc_1174 : memref<1x15x20x256xi8> -> index
    %584 = arith.index_cast %intptr_1178 : index to i64
    %intptr_1179 = memref.extract_aligned_pointer_as_index %alloc_1176 : memref<304x256xi8> -> index
    %585 = arith.index_cast %intptr_1179 : index to i64
    %intptr_1180 = memref.extract_aligned_pointer_as_index %alloc_1177 : memref<304x256xi8> -> index
    %586 = arith.index_cast %intptr_1180 : index to i64
    %intptr_1181 = memref.extract_aligned_pointer_as_index %alloc_1175 : memref<300x256xi8> -> index
    %587 = arith.index_cast %intptr_1181 : index to i64
    call @buddy_rvv_memcpy_i8(%585, %584, %c76800_i64) : (i64, i64, i64) -> ()
    %588 = arith.addi %585, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%588, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1176 %42 %alloc_1177 %41 {accScale = 0.0181710888 : f32} : memref<304x256xi8> memref<256x256xi8> memref<304x256xi8> memref<304x256xi32>
    call @buddy_rvv_copy_rows_i8(%587, %586, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1176 : memref<304x256xi8>
    memref.dealloc %alloc_1177 : memref<304x256xi8>
    %alloc_1182 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_1183 = memref.extract_aligned_pointer_as_index %alloc_1182 : memref<1x15x20x256xf32> -> index
    %intptr_1184 = memref.extract_aligned_pointer_as_index %alloc_1175 : memref<300x256xi8> -> index
    %589 = arith.index_cast %intptr_1183 : index to i64
    %590 = arith.index_cast %intptr_1184 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%589, %590, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_11) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1175 : memref<300x256xi8>
    %alloc_1185 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1182[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x256xf32>
            memref.store %646, %alloc_1185[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1186 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_1185, %alloc_1186 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_1187 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1186[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = memref.load %185[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1187[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1188 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1187[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1188[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1189 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c256 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1188[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1189[%arg166, %arg167, %arg168, %arg169] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_1190 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_949[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_1190[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_1191 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1191[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_1192 = memref.subview %alloc_1191[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1190, %subview_1192 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1193 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %39[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1193[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_1194 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    gemmini.tile_conv %alloc_1191 %40 %39 %alloc_1194 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00989972334 : f32} : memref<1x62x82x64xi8> memref<576x64xi8> memref<64xi32> memref<4800x64xi8> i64 i64 i64
    %alloc_1195 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_1196 = memref.extract_aligned_pointer_as_index %alloc_1195 : memref<1x60x80x64xf32> -> index
    %intptr_1197 = memref.extract_aligned_pointer_as_index %alloc_1194 : memref<4800x64xi8> -> index
    %591 = arith.index_cast %intptr_1196 : index to i64
    %592 = arith.index_cast %intptr_1197 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%591, %592, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_10) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1194 : memref<4800x64xi8>
    %alloc_1198 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1195[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_1198[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1199 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_1198, %alloc_1199 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_1200 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1199[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = memref.load %184[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1200[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1201 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1200[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1201[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1202 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1201[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1202[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_1203 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1202[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_1203[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_1204 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1204[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_1205 = memref.subview %alloc_1204[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1203, %subview_1205 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1206 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %37[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1206[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_1207 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    gemmini.tile_conv %alloc_1204 %38 %37 %alloc_1207 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00611394271 : f32} : memref<1x62x82x64xi8> memref<576x64xi8> memref<64xi32> memref<4800x64xi8> i64 i64 i64
    %alloc_1208 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_1209 = memref.extract_aligned_pointer_as_index %alloc_1208 : memref<1x60x80x64xf32> -> index
    %intptr_1210 = memref.extract_aligned_pointer_as_index %alloc_1207 : memref<4800x64xi8> -> index
    %593 = arith.index_cast %intptr_1209 : index to i64
    %594 = arith.index_cast %intptr_1210 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%593, %594, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_9) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1207 : memref<4800x64xi8>
    %alloc_1211 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1208[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_1211[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1212 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_1211, %alloc_1212 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_1213 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1212[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = memref.load %183[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1213[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1214 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1213[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1214[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_1215 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1214[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1215[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_1216 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1215[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_1216[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_1217 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    %alloc_1218 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_1219 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_1220 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_1221 = memref.extract_aligned_pointer_as_index %alloc_1216 : memref<1x60x80x64xi8> -> index
    %595 = arith.index_cast %intptr_1221 : index to i64
    %intptr_1222 = memref.extract_aligned_pointer_as_index %alloc_1219 : memref<4800x64xi8> -> index
    %596 = arith.index_cast %intptr_1222 : index to i64
    %intptr_1223 = memref.extract_aligned_pointer_as_index %alloc_1220 : memref<4800x64xi8> -> index
    %597 = arith.index_cast %intptr_1223 : index to i64
    %intptr_1224 = memref.extract_aligned_pointer_as_index %alloc_1218 : memref<4800x64xi8> -> index
    %598 = arith.index_cast %intptr_1224 : index to i64
    call @buddy_rvv_memcpy_i8(%596, %595, %c307200_i64) : (i64, i64, i64) -> ()
    %599 = arith.addi %596, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%599, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1219 %36 %alloc_1220 %35 {accScale = 0.005432026 : f32} : memref<4800x64xi8> memref<64x64xi8> memref<4800x64xi8> memref<4800x64xi32>
    call @buddy_rvv_copy_rows_i8(%598, %597, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1219 : memref<4800x64xi8>
    memref.dealloc %alloc_1220 : memref<4800x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = arith.muli %arg166, %c60 : index
            %647 = arith.muli %646, %c80 : index
            %648 = arith.muli %arg167, %c80 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1218[%650, %arg169] : memref<4800x64xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1217[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1218 : memref<4800x64xi8>
    %alloc_1225 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1217[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1225[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xf32>
          }
        }
      }
    }
    %alloc_1226 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    memref.copy %alloc_1225, %alloc_1226 : memref<1x60x80x64xf32> to memref<1x60x80x64xf32>
    %alloc_1227 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1226[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xf32>
            %647 = memref.load %182[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1227[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xf32>
          }
        }
      }
    }
    %alloc_1228 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1227[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x64xf32>
            memref.store %646, %alloc_1228[%arg166, %arg167, %arg168, %arg169] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %collapse_shape = memref.collapse_shape %alloc_1228 [[0], [1], [2, 3]] : memref<1x64x60x80xf32> into memref<1x64x4800xf32>
    %alloc_1229 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1069[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_1229[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1230 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1230[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x128xi8>
          }
        }
      }
    }
    %subview_1231 = memref.subview %alloc_1230[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_1229, %subview_1231 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_1232 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %33[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1232[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_1233 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_1230 %34 %33 %alloc_1233 %c30_i64 %c40_i64 %c3_i64 {scale = 0.0153491423 : f32} : memref<1x32x42x128xi8> memref<1152x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_1234 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1235 = memref.extract_aligned_pointer_as_index %alloc_1234 : memref<1x30x40x64xf32> -> index
    %intptr_1236 = memref.extract_aligned_pointer_as_index %alloc_1233 : memref<1200x64xi8> -> index
    %600 = arith.index_cast %intptr_1235 : index to i64
    %601 = arith.index_cast %intptr_1236 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%600, %601, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_8) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1233 : memref<1200x64xi8>
    %alloc_1237 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1234[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1237[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1238 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1237, %alloc_1238 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1239 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1238[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %181[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1239[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1240 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1239[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1240[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1241 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1240[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1241[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1242 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1241[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_1242[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1243 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1243[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_1244 = memref.subview %alloc_1243[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_1242, %subview_1244 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_1245 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %31[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1245[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_1246 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    gemmini.tile_conv %alloc_1243 %32 %31 %alloc_1246 %c30_i64 %c40_i64 %c3_i64 {scale = 7.832830e-03 : f32} : memref<1x32x42x64xi8> memref<576x64xi8> memref<64xi32> memref<1200x64xi8> i64 i64 i64
    %alloc_1247 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1248 = memref.extract_aligned_pointer_as_index %alloc_1247 : memref<1x30x40x64xf32> -> index
    %intptr_1249 = memref.extract_aligned_pointer_as_index %alloc_1246 : memref<1200x64xi8> -> index
    %602 = arith.index_cast %intptr_1248 : index to i64
    %603 = arith.index_cast %intptr_1249 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%602, %603, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_7) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1246 : memref<1200x64xi8>
    %alloc_1250 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1247[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1250[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1251 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1250, %alloc_1251 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1252 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1251[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = memref.load %180[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1252[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1253 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1252[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1253[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1254 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1253[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1254[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1255 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1254[%arg166, %arg169, %arg167, %arg168] : memref<1x64x30x40xi8>
            memref.store %646, %alloc_1255[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1256 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    %alloc_1257 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1258 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1259 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1260 = memref.extract_aligned_pointer_as_index %alloc_1255 : memref<1x30x40x64xi8> -> index
    %604 = arith.index_cast %intptr_1260 : index to i64
    %intptr_1261 = memref.extract_aligned_pointer_as_index %alloc_1258 : memref<1200x64xi8> -> index
    %605 = arith.index_cast %intptr_1261 : index to i64
    %intptr_1262 = memref.extract_aligned_pointer_as_index %alloc_1259 : memref<1200x64xi8> -> index
    %606 = arith.index_cast %intptr_1262 : index to i64
    %intptr_1263 = memref.extract_aligned_pointer_as_index %alloc_1257 : memref<1200x64xi8> -> index
    %607 = arith.index_cast %intptr_1263 : index to i64
    call @buddy_rvv_memcpy_i8(%605, %604, %c76800_i64) : (i64, i64, i64) -> ()
    %608 = arith.addi %605, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%608, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1258 %30 %alloc_1259 %29 {accScale = 0.00581856817 : f32} : memref<1200x64xi8> memref<64x64xi8> memref<1200x64xi8> memref<1200x64xi32>
    call @buddy_rvv_copy_rows_i8(%607, %606, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1258 : memref<1200x64xi8>
    memref.dealloc %alloc_1259 : memref<1200x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = arith.muli %arg166, %c30 : index
            %647 = arith.muli %646, %c40 : index
            %648 = arith.muli %arg167, %c40 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1257[%650, %arg169] : memref<1200x64xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1256[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1257 : memref<1200x64xi8>
    %alloc_1264 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1256[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1264[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xf32>
          }
        }
      }
    }
    %alloc_1265 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    memref.copy %alloc_1264, %alloc_1265 : memref<1x30x40x64xf32> to memref<1x30x40x64xf32>
    %alloc_1266 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1265[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xf32>
            %647 = memref.load %179[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1266[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x64xf32>
          }
        }
      }
    }
    %alloc_1267 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1266[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x64xf32>
            memref.store %646, %alloc_1267[%arg166, %arg167, %arg168, %arg169] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %collapse_shape_1268 = memref.collapse_shape %alloc_1267 [[0], [1], [2, 3]] : memref<1x64x30x40xf32> into memref<1x64x1200xf32>
    %alloc_1269 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_1189[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_1269[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1270 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            memref.store %c0_i8, %alloc_1270[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x256xi8>
          }
        }
      }
    }
    %subview_1271 = memref.subview %alloc_1270[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_1269, %subview_1271 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_1272 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %27[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1272[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    %alloc_1273 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    gemmini.tile_conv %alloc_1270 %28 %27 %alloc_1273 %c15_i64 %c20_i64 %c3_i64 {scale = 8.036410e-03 : f32} : memref<1x17x22x256xi8> memref<2304x64xi8> memref<64xi32> memref<300x64xi8> i64 i64 i64
    %alloc_1274 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    %intptr_1275 = memref.extract_aligned_pointer_as_index %alloc_1274 : memref<1x15x20x64xf32> -> index
    %intptr_1276 = memref.extract_aligned_pointer_as_index %alloc_1273 : memref<300x64xi8> -> index
    %609 = arith.index_cast %intptr_1275 : index to i64
    %610 = arith.index_cast %intptr_1276 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%609, %610, %c1_i64, %c15_i64, %c20_i64, %c64_i64, %cst_6) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1273 : memref<300x64xi8>
    %alloc_1277 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1274[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x64xf32>
            memref.store %646, %alloc_1277[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1278 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    memref.copy %alloc_1277, %alloc_1278 : memref<1x64x15x20xf32> to memref<1x64x15x20xf32>
    %alloc_1279 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1278[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = memref.load %178[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1279[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1280 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1279[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1280[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1281 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1280[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1281[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xi8>
          }
        }
      }
    }
    %alloc_1282 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1281[%arg166, %arg169, %arg167, %arg168] : memref<1x64x15x20xi8>
            memref.store %646, %alloc_1282[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi8>
          }
        }
      }
    }
    %alloc_1283 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1283[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x64xi8>
          }
        }
      }
    }
    %subview_1284 = memref.subview %alloc_1283[0, 1, 1, 0] [1, 15, 20, 64] [1, 1, 1, 1] : memref<1x17x22x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    memref.copy %alloc_1282, %subview_1284 : memref<1x15x20x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    %alloc_1285 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %25[%arg169] : memref<64xi32>
            memref.store %646, %alloc_1285[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    %alloc_1286 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    gemmini.tile_conv %alloc_1283 %26 %25 %alloc_1286 %c15_i64 %c20_i64 %c3_i64 {scale = 0.00592346117 : f32} : memref<1x17x22x64xi8> memref<576x64xi8> memref<64xi32> memref<300x64xi8> i64 i64 i64
    %alloc_1287 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    %intptr_1288 = memref.extract_aligned_pointer_as_index %alloc_1287 : memref<1x15x20x64xf32> -> index
    %intptr_1289 = memref.extract_aligned_pointer_as_index %alloc_1286 : memref<300x64xi8> -> index
    %611 = arith.index_cast %intptr_1288 : index to i64
    %612 = arith.index_cast %intptr_1289 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%611, %612, %c1_i64, %c15_i64, %c20_i64, %c64_i64, %cst_5) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1286 : memref<300x64xi8>
    %alloc_1290 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1287[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x64xf32>
            memref.store %646, %alloc_1290[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1291 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    memref.copy %alloc_1290, %alloc_1291 : memref<1x64x15x20xf32> to memref<1x64x15x20xf32>
    %alloc_1292 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1291[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = memref.load %177[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1292[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1293 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1292[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1293[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_1294 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1293[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1294[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xi8>
          }
        }
      }
    }
    %alloc_1295 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1294[%arg166, %arg169, %arg167, %arg168] : memref<1x64x15x20xi8>
            memref.store %646, %alloc_1295[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi8>
          }
        }
      }
    }
    %alloc_1296 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    %alloc_1297 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    %alloc_1298 = memref.alloc() {alignment = 64 : i64} : memref<304x64xi8>
    %alloc_1299 = memref.alloc() {alignment = 64 : i64} : memref<304x64xi8>
    %intptr_1300 = memref.extract_aligned_pointer_as_index %alloc_1295 : memref<1x15x20x64xi8> -> index
    %613 = arith.index_cast %intptr_1300 : index to i64
    %intptr_1301 = memref.extract_aligned_pointer_as_index %alloc_1298 : memref<304x64xi8> -> index
    %614 = arith.index_cast %intptr_1301 : index to i64
    %intptr_1302 = memref.extract_aligned_pointer_as_index %alloc_1299 : memref<304x64xi8> -> index
    %615 = arith.index_cast %intptr_1302 : index to i64
    %intptr_1303 = memref.extract_aligned_pointer_as_index %alloc_1297 : memref<300x64xi8> -> index
    %616 = arith.index_cast %intptr_1303 : index to i64
    call @buddy_rvv_memcpy_i8(%614, %613, %c19200_i64) : (i64, i64, i64) -> ()
    %617 = arith.addi %614, %c19200_i64 : i64
    call @buddy_rvv_memset_i8(%617, %c0_i64, %c256_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1298 %24 %alloc_1299 %23 {accScale = 0.00600688718 : f32} : memref<304x64xi8> memref<64x64xi8> memref<304x64xi8> memref<304x64xi32>
    call @buddy_rvv_copy_rows_i8(%616, %615, %c300_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1298 : memref<304x64xi8>
    memref.dealloc %alloc_1299 : memref<304x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = arith.muli %arg166, %c15 : index
            %647 = arith.muli %646, %c20 : index
            %648 = arith.muli %arg167, %c20 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1297[%650, %arg169] : memref<300x64xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1296[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1297 : memref<300x64xi8>
    %alloc_1304 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1296[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1304[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xf32>
          }
        }
      }
    }
    %alloc_1305 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    memref.copy %alloc_1304, %alloc_1305 : memref<1x15x20x64xf32> to memref<1x15x20x64xf32>
    %alloc_1306 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_1305[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xf32>
            %647 = memref.load %176[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1306[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x64xf32>
          }
        }
      }
    }
    %alloc_1307 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1306[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x64xf32>
            memref.store %646, %alloc_1307[%arg166, %arg167, %arg168, %arg169] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %collapse_shape_1308 = memref.collapse_shape %alloc_1307 [[0], [1], [2, 3]] : memref<1x64x15x20xf32> into memref<1x64x300xf32>
    %alloc_1309 = memref.alloc() {alignment = 64 : i64} : memref<1x64x1200xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c1200 step %c1 {
          %646 = memref.load %collapse_shape_1268[%arg166, %arg167, %arg168] : memref<1x64x1200xf32>
          %647 = memref.load %175[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1309[%arg166, %arg167, %arg168] : memref<1x64x1200xf32>
        }
      }
    }
    %alloc_1310 = memref.alloc() {alignment = 64 : i64} : memref<1x64x300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c64 step %c1 {
        scf.for %arg168 = %c0 to %c300 step %c1 {
          %646 = memref.load %collapse_shape_1308[%arg166, %arg167, %arg168] : memref<1x64x300xf32>
          %647 = memref.load %174[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1310[%arg166, %arg167, %arg168] : memref<1x64x300xf32>
        }
      }
    }
    %alloc_1311 = memref.alloc() {alignment = 64 : i64} : memref<1x64x6300xf32>
    %subview_1312 = memref.subview %alloc_1311[0, 0, 0] [1, 64, 4800] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    memref.copy %collapse_shape, %subview_1312 : memref<1x64x4800xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    %subview_1313 = memref.subview %alloc_1311[0, 0, 4800] [1, 64, 1200] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    memref.copy %alloc_1309, %subview_1313 : memref<1x64x1200xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    %subview_1314 = memref.subview %alloc_1311[0, 0, 6000] [1, 64, 300] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    memref.copy %alloc_1310, %subview_1314 : memref<1x64x300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    %alloc_1315 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            %646 = memref.load %alloc_949[%arg166, %arg169, %arg167, %arg168] : memref<1x64x60x80xi8>
            memref.store %646, %alloc_1315[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_1316 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1316[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_1317 = memref.subview %alloc_1316[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1315, %subview_1317 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1318 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %21[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1318[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    %alloc_1319 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    gemmini.tile_conv %alloc_1316 %22 %21 %alloc_1319 %c60_i64 %c80_i64 %c3_i64 {scale = 0.0071694795 : f32} : memref<1x62x82x64xi8> memref<576x80xi8> memref<80xi32> memref<4800x80xi8> i64 i64 i64
    %alloc_1320 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    %intptr_1321 = memref.extract_aligned_pointer_as_index %alloc_1320 : memref<1x60x80x80xf32> -> index
    %intptr_1322 = memref.extract_aligned_pointer_as_index %alloc_1319 : memref<4800x80xi8> -> index
    %618 = arith.index_cast %intptr_1321 : index to i64
    %619 = arith.index_cast %intptr_1322 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%618, %619, %c1_i64, %c60_i64, %c80_i64, %c80_i64, %cst_4) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1319 : memref<4800x80xi8>
    %alloc_1323 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1320[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x80xf32>
            memref.store %646, %alloc_1323[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1324 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    memref.copy %alloc_1323, %alloc_1324 : memref<1x80x60x80xf32> to memref<1x80x60x80xf32>
    %alloc_1325 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1324[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = memref.load %173[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1325[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1326 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1325[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1326[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1327 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1326[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1327[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xi8>
          }
        }
      }
    }
    %alloc_1328 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1327[%arg166, %arg169, %arg167, %arg168] : memref<1x80x60x80xi8>
            memref.store %646, %alloc_1328[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi8>
          }
        }
      }
    }
    %alloc_1329 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c62 step %c1 {
        scf.for %arg168 = %c0 to %c82 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_1329[%arg166, %arg167, %arg168, %arg169] : memref<1x62x82x80xi8>
          }
        }
      }
    }
    %subview_1330 = memref.subview %alloc_1329[0, 1, 1, 0] [1, 60, 80, 80] [1, 1, 1, 1] : memref<1x62x82x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    memref.copy %alloc_1328, %subview_1330 : memref<1x60x80x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    %alloc_1331 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %19[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1331[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    %alloc_1332 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    gemmini.tile_conv %alloc_1329 %20 %19 %alloc_1332 %c60_i64 %c80_i64 %c3_i64 {scale = 0.00637654448 : f32} : memref<1x62x82x80xi8> memref<720x80xi8> memref<80xi32> memref<4800x80xi8> i64 i64 i64
    %alloc_1333 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    %intptr_1334 = memref.extract_aligned_pointer_as_index %alloc_1333 : memref<1x60x80x80xf32> -> index
    %intptr_1335 = memref.extract_aligned_pointer_as_index %alloc_1332 : memref<4800x80xi8> -> index
    %620 = arith.index_cast %intptr_1334 : index to i64
    %621 = arith.index_cast %intptr_1335 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%620, %621, %c1_i64, %c60_i64, %c80_i64, %c80_i64, %cst_3) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1332 : memref<4800x80xi8>
    %alloc_1336 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1333[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x80xf32>
            memref.store %646, %alloc_1336[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1337 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    memref.copy %alloc_1336, %alloc_1337 : memref<1x80x60x80xf32> to memref<1x80x60x80xf32>
    %alloc_1338 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1337[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = memref.load %172[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1338[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1339 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1338[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1339[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_1340 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1339[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1340[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xi8>
          }
        }
      }
    }
    %alloc_1341 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1340[%arg166, %arg169, %arg167, %arg168] : memref<1x80x60x80xi8>
            memref.store %646, %alloc_1341[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi8>
          }
        }
      }
    }
    %alloc_1342 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    %alloc_1343 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %alloc_1344 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %alloc_1345 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %intptr_1346 = memref.extract_aligned_pointer_as_index %alloc_1341 : memref<1x60x80x80xi8> -> index
    %622 = arith.index_cast %intptr_1346 : index to i64
    %intptr_1347 = memref.extract_aligned_pointer_as_index %alloc_1344 : memref<4800x80xi8> -> index
    %623 = arith.index_cast %intptr_1347 : index to i64
    %intptr_1348 = memref.extract_aligned_pointer_as_index %alloc_1345 : memref<4800x80xi8> -> index
    %624 = arith.index_cast %intptr_1348 : index to i64
    %intptr_1349 = memref.extract_aligned_pointer_as_index %alloc_1343 : memref<4800x80xi8> -> index
    %625 = arith.index_cast %intptr_1349 : index to i64
    call @buddy_rvv_memcpy_i8(%623, %622, %c384000_i64) : (i64, i64, i64) -> ()
    %626 = arith.addi %623, %c384000_i64 : i64
    call @buddy_rvv_memset_i8(%626, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1344 %18 %alloc_1345 %17 {accScale = 0.00252736034 : f32} : memref<4800x80xi8> memref<80x80xi8> memref<4800x80xi8> memref<4800x80xi32>
    call @buddy_rvv_copy_rows_i8(%625, %624, %c4800_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1344 : memref<4800x80xi8>
    memref.dealloc %alloc_1345 : memref<4800x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = arith.muli %arg166, %c60 : index
            %647 = arith.muli %646, %c80 : index
            %648 = arith.muli %arg167, %c80 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1343[%650, %arg169] : memref<4800x80xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1342[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1343 : memref<4800x80xi8>
    %alloc_1350 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1342[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1350[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xf32>
          }
        }
      }
    }
    %alloc_1351 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    memref.copy %alloc_1350, %alloc_1351 : memref<1x60x80x80xf32> to memref<1x60x80x80xf32>
    %alloc_1352 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c60 step %c1 {
        scf.for %arg168 = %c0 to %c80 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1351[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xf32>
            %647 = memref.load %171[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1352[%arg166, %arg167, %arg168, %arg169] : memref<1x60x80x80xf32>
          }
        }
      }
    }
    %alloc_1353 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c60 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1352[%arg166, %arg168, %arg169, %arg167] : memref<1x60x80x80xf32>
            memref.store %646, %alloc_1353[%arg166, %arg167, %arg168, %arg169] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %collapse_shape_1354 = memref.collapse_shape %alloc_1353 [[0], [1], [2, 3]] : memref<1x80x60x80xf32> into memref<1x80x4800xf32>
    %alloc_1355 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            %646 = memref.load %alloc_1069[%arg166, %arg169, %arg167, %arg168] : memref<1x128x30x40xi8>
            memref.store %646, %alloc_1355[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1356 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1356[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x128xi8>
          }
        }
      }
    }
    %subview_1357 = memref.subview %alloc_1356[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_1355, %subview_1357 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_1358 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %15[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1358[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    %alloc_1359 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    gemmini.tile_conv %alloc_1356 %16 %15 %alloc_1359 %c30_i64 %c40_i64 %c3_i64 {scale = 0.00700604171 : f32} : memref<1x32x42x128xi8> memref<1152x80xi8> memref<80xi32> memref<1200x80xi8> i64 i64 i64
    %alloc_1360 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    %intptr_1361 = memref.extract_aligned_pointer_as_index %alloc_1360 : memref<1x30x40x80xf32> -> index
    %intptr_1362 = memref.extract_aligned_pointer_as_index %alloc_1359 : memref<1200x80xi8> -> index
    %627 = arith.index_cast %intptr_1361 : index to i64
    %628 = arith.index_cast %intptr_1362 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%627, %628, %c1_i64, %c30_i64, %c40_i64, %c80_i64, %cst_2) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1359 : memref<1200x80xi8>
    %alloc_1363 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1360[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x80xf32>
            memref.store %646, %alloc_1363[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1364 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    memref.copy %alloc_1363, %alloc_1364 : memref<1x80x30x40xf32> to memref<1x80x30x40xf32>
    %alloc_1365 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1364[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = memref.load %170[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1365[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1366 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1365[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1366[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1367 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1366[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1367[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xi8>
          }
        }
      }
    }
    %alloc_1368 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1367[%arg166, %arg169, %arg167, %arg168] : memref<1x80x30x40xi8>
            memref.store %646, %alloc_1368[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi8>
          }
        }
      }
    }
    %alloc_1369 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c32 step %c1 {
        scf.for %arg168 = %c0 to %c42 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_1369[%arg166, %arg167, %arg168, %arg169] : memref<1x32x42x80xi8>
          }
        }
      }
    }
    %subview_1370 = memref.subview %alloc_1369[0, 1, 1, 0] [1, 30, 40, 80] [1, 1, 1, 1] : memref<1x32x42x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    memref.copy %alloc_1368, %subview_1370 : memref<1x30x40x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    %alloc_1371 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %13[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1371[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    %alloc_1372 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    gemmini.tile_conv %alloc_1369 %14 %13 %alloc_1372 %c30_i64 %c40_i64 %c3_i64 {scale = 0.0068566585 : f32} : memref<1x32x42x80xi8> memref<720x80xi8> memref<80xi32> memref<1200x80xi8> i64 i64 i64
    %alloc_1373 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    %intptr_1374 = memref.extract_aligned_pointer_as_index %alloc_1373 : memref<1x30x40x80xf32> -> index
    %intptr_1375 = memref.extract_aligned_pointer_as_index %alloc_1372 : memref<1200x80xi8> -> index
    %629 = arith.index_cast %intptr_1374 : index to i64
    %630 = arith.index_cast %intptr_1375 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%629, %630, %c1_i64, %c30_i64, %c40_i64, %c80_i64, %cst_1) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1372 : memref<1200x80xi8>
    %alloc_1376 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1373[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x80xf32>
            memref.store %646, %alloc_1376[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1377 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    memref.copy %alloc_1376, %alloc_1377 : memref<1x80x30x40xf32> to memref<1x80x30x40xf32>
    %alloc_1378 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1377[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = memref.load %169[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1378[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1379 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1378[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1379[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_1380 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1379[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1380[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xi8>
          }
        }
      }
    }
    %alloc_1381 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1380[%arg166, %arg169, %arg167, %arg168] : memref<1x80x30x40xi8>
            memref.store %646, %alloc_1381[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi8>
          }
        }
      }
    }
    %alloc_1382 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    %alloc_1383 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %alloc_1384 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %alloc_1385 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %intptr_1386 = memref.extract_aligned_pointer_as_index %alloc_1381 : memref<1x30x40x80xi8> -> index
    %631 = arith.index_cast %intptr_1386 : index to i64
    %intptr_1387 = memref.extract_aligned_pointer_as_index %alloc_1384 : memref<1200x80xi8> -> index
    %632 = arith.index_cast %intptr_1387 : index to i64
    %intptr_1388 = memref.extract_aligned_pointer_as_index %alloc_1385 : memref<1200x80xi8> -> index
    %633 = arith.index_cast %intptr_1388 : index to i64
    %intptr_1389 = memref.extract_aligned_pointer_as_index %alloc_1383 : memref<1200x80xi8> -> index
    %634 = arith.index_cast %intptr_1389 : index to i64
    call @buddy_rvv_memcpy_i8(%632, %631, %c96000_i64) : (i64, i64, i64) -> ()
    %635 = arith.addi %632, %c96000_i64 : i64
    call @buddy_rvv_memset_i8(%635, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1384 %12 %alloc_1385 %11 {accScale = 0.00488613872 : f32} : memref<1200x80xi8> memref<80x80xi8> memref<1200x80xi8> memref<1200x80xi32>
    call @buddy_rvv_copy_rows_i8(%634, %633, %c1200_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1384 : memref<1200x80xi8>
    memref.dealloc %alloc_1385 : memref<1200x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = arith.muli %arg166, %c30 : index
            %647 = arith.muli %646, %c40 : index
            %648 = arith.muli %arg167, %c40 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1383[%650, %arg169] : memref<1200x80xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1382[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1383 : memref<1200x80xi8>
    %alloc_1390 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1382[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1390[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xf32>
          }
        }
      }
    }
    %alloc_1391 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    memref.copy %alloc_1390, %alloc_1391 : memref<1x30x40x80xf32> to memref<1x30x40x80xf32>
    %alloc_1392 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c30 step %c1 {
        scf.for %arg168 = %c0 to %c40 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1391[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xf32>
            %647 = memref.load %168[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1392[%arg166, %arg167, %arg168, %arg169] : memref<1x30x40x80xf32>
          }
        }
      }
    }
    %alloc_1393 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c30 step %c1 {
          scf.for %arg169 = %c0 to %c40 step %c1 {
            %646 = memref.load %alloc_1392[%arg166, %arg168, %arg169, %arg167] : memref<1x30x40x80xf32>
            memref.store %646, %alloc_1393[%arg166, %arg167, %arg168, %arg169] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %collapse_shape_1394 = memref.collapse_shape %alloc_1393 [[0], [1], [2, 3]] : memref<1x80x30x40xf32> into memref<1x80x1200xf32>
    %alloc_1395 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            %646 = memref.load %alloc_1189[%arg166, %arg169, %arg167, %arg168] : memref<1x256x15x20xi8>
            memref.store %646, %alloc_1395[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1396 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c256 step %c1 {
            memref.store %c0_i8, %alloc_1396[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x256xi8>
          }
        }
      }
    }
    %subview_1397 = memref.subview %alloc_1396[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_1395, %subview_1397 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_1398 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %9[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1398[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    %alloc_1399 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    gemmini.tile_conv %alloc_1396 %10 %9 %alloc_1399 %c15_i64 %c20_i64 %c3_i64 {scale = 0.00787081196 : f32} : memref<1x17x22x256xi8> memref<2304x80xi8> memref<80xi32> memref<300x80xi8> i64 i64 i64
    %alloc_1400 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    %intptr_1401 = memref.extract_aligned_pointer_as_index %alloc_1400 : memref<1x15x20x80xf32> -> index
    %intptr_1402 = memref.extract_aligned_pointer_as_index %alloc_1399 : memref<300x80xi8> -> index
    %636 = arith.index_cast %intptr_1401 : index to i64
    %637 = arith.index_cast %intptr_1402 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%636, %637, %c1_i64, %c15_i64, %c20_i64, %c80_i64, %cst_0) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1399 : memref<300x80xi8>
    %alloc_1403 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1400[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x80xf32>
            memref.store %646, %alloc_1403[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1404 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    memref.copy %alloc_1403, %alloc_1404 : memref<1x80x15x20xf32> to memref<1x80x15x20xf32>
    %alloc_1405 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1404[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = memref.load %167[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1405[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1406 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1405[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1406[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1407 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1406[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1407[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xi8>
          }
        }
      }
    }
    %alloc_1408 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1407[%arg166, %arg169, %arg167, %arg168] : memref<1x80x15x20xi8>
            memref.store %646, %alloc_1408[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi8>
          }
        }
      }
    }
    %alloc_1409 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c17 step %c1 {
        scf.for %arg168 = %c0 to %c22 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_1409[%arg166, %arg167, %arg168, %arg169] : memref<1x17x22x80xi8>
          }
        }
      }
    }
    %subview_1410 = memref.subview %alloc_1409[0, 1, 1, 0] [1, 15, 20, 80] [1, 1, 1, 1] : memref<1x17x22x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    memref.copy %alloc_1408, %subview_1410 : memref<1x15x20x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    %alloc_1411 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %7[%arg169] : memref<80xi32>
            memref.store %646, %alloc_1411[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    %alloc_1412 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    gemmini.tile_conv %alloc_1409 %8 %7 %alloc_1412 %c15_i64 %c20_i64 %c3_i64 {scale = 0.00632192567 : f32} : memref<1x17x22x80xi8> memref<720x80xi8> memref<80xi32> memref<300x80xi8> i64 i64 i64
    %alloc_1413 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    %intptr_1414 = memref.extract_aligned_pointer_as_index %alloc_1413 : memref<1x15x20x80xf32> -> index
    %intptr_1415 = memref.extract_aligned_pointer_as_index %alloc_1412 : memref<300x80xi8> -> index
    %638 = arith.index_cast %intptr_1414 : index to i64
    %639 = arith.index_cast %intptr_1415 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%638, %639, %c1_i64, %c15_i64, %c20_i64, %c80_i64, %cst) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1412 : memref<300x80xi8>
    %alloc_1416 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1413[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x80xf32>
            memref.store %646, %alloc_1416[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1417 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    memref.copy %alloc_1416, %alloc_1417 : memref<1x80x15x20xf32> to memref<1x80x15x20xf32>
    %alloc_1418 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1417[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = memref.load %166[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1418[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1419 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1418[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1419[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_1420 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1419[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1420[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xi8>
          }
        }
      }
    }
    %alloc_1421 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1420[%arg166, %arg169, %arg167, %arg168] : memref<1x80x15x20xi8>
            memref.store %646, %alloc_1421[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi8>
          }
        }
      }
    }
    %alloc_1422 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    %alloc_1423 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    %alloc_1424 = memref.alloc() {alignment = 64 : i64} : memref<304x80xi8>
    %alloc_1425 = memref.alloc() {alignment = 64 : i64} : memref<304x80xi8>
    %intptr_1426 = memref.extract_aligned_pointer_as_index %alloc_1421 : memref<1x15x20x80xi8> -> index
    %640 = arith.index_cast %intptr_1426 : index to i64
    %intptr_1427 = memref.extract_aligned_pointer_as_index %alloc_1424 : memref<304x80xi8> -> index
    %641 = arith.index_cast %intptr_1427 : index to i64
    %intptr_1428 = memref.extract_aligned_pointer_as_index %alloc_1425 : memref<304x80xi8> -> index
    %642 = arith.index_cast %intptr_1428 : index to i64
    %intptr_1429 = memref.extract_aligned_pointer_as_index %alloc_1423 : memref<300x80xi8> -> index
    %643 = arith.index_cast %intptr_1429 : index to i64
    call @buddy_rvv_memcpy_i8(%641, %640, %c24000_i64) : (i64, i64, i64) -> ()
    %644 = arith.addi %641, %c24000_i64 : i64
    call @buddy_rvv_memset_i8(%644, %c0_i64, %c320_i64) : (i64, i64, i64) -> ()
    gemmini.tile_matmul %alloc_1424 %6 %alloc_1425 %5 {accScale = 0.00431937352 : f32} : memref<304x80xi8> memref<80x80xi8> memref<304x80xi8> memref<304x80xi32>
    call @buddy_rvv_copy_rows_i8(%643, %642, %c300_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1424 : memref<304x80xi8>
    memref.dealloc %alloc_1425 : memref<304x80xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = arith.muli %arg166, %c15 : index
            %647 = arith.muli %646, %c20 : index
            %648 = arith.muli %arg167, %c20 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1423[%650, %arg169] : memref<300x80xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1422[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1423 : memref<300x80xi8>
    %alloc_1430 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1422[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1430[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xf32>
          }
        }
      }
    }
    %alloc_1431 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    memref.copy %alloc_1430, %alloc_1431 : memref<1x15x20x80xf32> to memref<1x15x20x80xf32>
    %alloc_1432 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c15 step %c1 {
        scf.for %arg168 = %c0 to %c20 step %c1 {
          scf.for %arg169 = %c0 to %c80 step %c1 {
            %646 = memref.load %alloc_1431[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xf32>
            %647 = memref.load %165[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1432[%arg166, %arg167, %arg168, %arg169] : memref<1x15x20x80xf32>
          }
        }
      }
    }
    %alloc_1433 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c15 step %c1 {
          scf.for %arg169 = %c0 to %c20 step %c1 {
            %646 = memref.load %alloc_1432[%arg166, %arg168, %arg169, %arg167] : memref<1x15x20x80xf32>
            memref.store %646, %alloc_1433[%arg166, %arg167, %arg168, %arg169] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %collapse_shape_1434 = memref.collapse_shape %alloc_1433 [[0], [1], [2, 3]] : memref<1x80x15x20xf32> into memref<1x80x300xf32>
    %alloc_1435 = memref.alloc() {alignment = 64 : i64} : memref<1x80x4800xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c4800 step %c1 {
          %646 = memref.load %collapse_shape_1354[%arg166, %arg167, %arg168] : memref<1x80x4800xf32>
          %647 = memref.load %164[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1435[%arg166, %arg167, %arg168] : memref<1x80x4800xf32>
        }
      }
    }
    %alloc_1436 = memref.alloc() {alignment = 64 : i64} : memref<1x80x1200xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c1200 step %c1 {
          %646 = memref.load %collapse_shape_1394[%arg166, %arg167, %arg168] : memref<1x80x1200xf32>
          %647 = memref.load %163[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1436[%arg166, %arg167, %arg168] : memref<1x80x1200xf32>
        }
      }
    }
    %alloc_1437 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    %subview_1438 = memref.subview %alloc_1437[0, 0, 0] [1, 80, 4800] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    memref.copy %alloc_1435, %subview_1438 : memref<1x80x4800xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    %subview_1439 = memref.subview %alloc_1437[0, 0, 4800] [1, 80, 1200] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    memref.copy %alloc_1436, %subview_1439 : memref<1x80x1200xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    %subview_1440 = memref.subview %alloc_1437[0, 0, 6000] [1, 80, 300] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    memref.copy %collapse_shape_1434, %subview_1440 : memref<1x80x300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    %expand_shape = memref.expand_shape %alloc_1311 [[0], [1, 2], [3]] output_shape [1, 4, 16, 6300] : memref<1x64x6300xf32> into memref<1x4x16x6300xf32>
    %alloc_1441 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c4 step %c1 {
          scf.for %arg169 = %c0 to %c6300 step %c1 {
            %646 = memref.load %expand_shape[%arg166, %arg168, %arg167, %arg169] : memref<1x4x16x6300xf32>
            memref.store %646, %alloc_1441[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_1442 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c4 step %c1 {
          scf.for %arg169 = %c0 to %c6300 step %c1 {
            %646 = memref.load %alloc_1441[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
            %647 = math.exp %646 : f32
            memref.store %647, %alloc_1442[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_1443 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          memref.store %cst_64, %alloc_1443[%arg166, %arg167, %arg168] : memref<1x4x6300xf32>
        }
      }
    }
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c4 step %c1 {
          scf.for %arg169 = %c0 to %c6300 step %c1 {
            %646 = memref.load %alloc_1442[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
            %647 = memref.load %alloc_1443[%arg166, %arg168, %arg169] : memref<1x4x6300xf32>
            %648 = arith.addf %646, %647 : f32
            memref.store %648, %alloc_1443[%arg166, %arg168, %arg169] : memref<1x4x6300xf32>
          }
        }
      }
    }
    %expand_shape_1444 = memref.expand_shape %alloc_1443 [[0], [1, 2], [3]] output_shape [1, 1, 4, 6300] : memref<1x4x6300xf32> into memref<1x1x4x6300xf32>
    %alloc_1445 = memref.alloc() {alignment = 64 : i64} : memref<1x1x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c4 step %c1 {
          scf.for %arg169 = %c0 to %c6300 step %c1 {
            %646 = memref.load %expand_shape_1444[%arg166, %arg167, %arg168, %arg169] : memref<1x1x4x6300xf32>
            %647 = arith.divf %cst_61, %646 : f32
            memref.store %647, %alloc_1445[%arg166, %arg167, %arg168, %arg169] : memref<1x1x4x6300xf32>
          }
        }
      }
    }
    %alloc_1446 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c16 step %c1 {
        scf.for %arg168 = %c0 to %c4 step %c1 {
          scf.for %arg169 = %c0 to %c6300 step %c1 {
            %646 = memref.load %alloc_1442[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
            %647 = memref.load %alloc_1445[%arg166, %c0, %arg168, %arg169] : memref<1x1x4x6300xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1446[%arg166, %arg167, %arg168, %arg169] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_1447 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1446[%arg166, %arg169, %arg167, %arg168] : memref<1x16x4x6300xf32>
            memref.store %646, %alloc_1447[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %collapse_shape_1448 = memref.collapse_shape %4 [[0], [1, 2, 3]] : memref<1x16x1x1xf32> into memref<1x16xf32>
    %expand_shape_1449 = memref.expand_shape %collapse_shape_1448 [[0, 1, 2], [3]] output_shape [1, 1, 1, 16] : memref<1x16xf32> into memref<1x1x1x16xf32>
    %alloc_1450 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1447[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
            %647 = memref.load %162[%arg166, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1450[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %alloc_1451 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1450[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_62 : f32
            memref.store %648, %alloc_1451[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %alloc_1452 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1451[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1452[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x16xi8>
          }
        }
      }
    }
    %alloc_1453 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c1 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %expand_shape_1449[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xf32>
            %647 = memref.load %161[%arg166, %arg167, %arg168, %c0] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1453[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xf32>
          }
        }
      }
    }
    %alloc_1454 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c1 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1453[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xf32>
            %647 = arith.minimumf %646, %cst_63 : f32
            %648 = arith.maximumf %647, %cst_65 : f32
            memref.store %648, %alloc_1454[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xf32>
          }
        }
      }
    }
    %alloc_1455 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c1 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = memref.load %alloc_1454[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xf32>
            %647 = arith.cmpf olt, %646, %cst_64 : f32
            %648 = arith.select %647, %cst_58, %cst_59 : f32
            %649 = arith.addf %646, %648 : f32
            %650 = arith.fptosi %649 : f32 to i32
            %651 = arith.maxsi %650, %c-128_i32 : i32
            %652 = arith.minsi %651, %c127_i32 : i32
            %653 = arith.trunci %652 : i32 to i8
            memref.store %653, %alloc_1455[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xi8>
          }
        }
      }
    }
    %alloc_1456 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xi32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c1 step %c1 {
            %646 = memref.load %281[%c0] : memref<1xi32>
            memref.store %646, %alloc_1456[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xi32>
          }
        }
      }
    }
    %alloc_1457 = memref.alloc() {alignment = 64 : i64} : memref<16x1xi8>
    %alloc_1458 = memref.alloc() {alignment = 64 : i64} : memref<25200x1xi8>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c1 step %c1 {
          scf.for %arg169 = %c0 to %c16 step %c1 {
            %646 = arith.muli %arg167, %c16 : index
            %647 = arith.muli %arg168, %c16 : index
            %648 = arith.addi %646, %647 : index
            %649 = arith.addi %648, %arg169 : index
            %650 = memref.load %alloc_1455[%arg166, %arg167, %arg168, %arg169] : memref<1x1x1x16xi8>
            memref.store %650, %alloc_1457[%649, %arg166] : memref<16x1xi8>
          }
        }
      }
    }
    gemmini.tile_conv %alloc_1452 %alloc_1457 %281 %alloc_1458 %c4_i64 %c6300_i64 %c1_i64 {scale = 0.00859712064 : f32} : memref<1x4x6300x16xi8> memref<16x1xi8> memref<1xi32> memref<25200x1xi8> i64 i64 i64
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c1 step %c1 {
            %646 = arith.muli %arg166, %c4 : index
            %647 = arith.muli %646, %c6300 : index
            %648 = arith.muli %arg167, %c6300 : index
            %649 = arith.addi %647, %648 : index
            %650 = arith.addi %649, %arg168 : index
            %651 = memref.load %alloc_1458[%650, %arg169] : memref<25200x1xi8>
            %652 = arith.extsi %651 : i8 to i32
            memref.store %652, %alloc_1456[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_1458 : memref<25200x1xi8>
    memref.dealloc %alloc_1457 : memref<16x1xi8>
    %alloc_1459 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c1 step %c1 {
            %646 = memref.load %alloc_1456[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xi32>
            %647 = arith.sitofp %646 : i32 to f32
            memref.store %647, %alloc_1459[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xf32>
          }
        }
      }
    }
    %alloc_1460 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    memref.copy %alloc_1459, %alloc_1460 : memref<1x4x6300x1xf32> to memref<1x4x6300x1xf32>
    %alloc_1461 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          scf.for %arg169 = %c0 to %c1 step %c1 {
            %646 = memref.load %alloc_1460[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xf32>
            %647 = memref.load %160[%arg166, %c0, %c0, %arg169] : memref<1x1x1x1xf32>
            %648 = arith.mulf %646, %647 : f32
            memref.store %648, %alloc_1461[%arg166, %arg167, %arg168, %arg169] : memref<1x4x6300x1xf32>
          }
        }
      }
    }
    %collapse_shape_1462 = memref.collapse_shape %alloc_1461 [[0], [1], [2, 3]] : memref<1x4x6300x1xf32> into memref<1x4x6300xf32>
    %subview_1463 = memref.subview %collapse_shape_1462[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_1464 = memref.subview %collapse_shape_1462[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %alloc_1465 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %3[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %subview_1463[%arg166, %arg167, %arg168] : memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
          %648 = arith.subf %646, %647 : f32
          memref.store %648, %alloc_1465[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1466 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %2[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %subview_1464[%arg166, %arg167, %arg168] : memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
          %648 = arith.addf %646, %647 : f32
          memref.store %648, %alloc_1466[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1467 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1465[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %159[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1467[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1468 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1466[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %158[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1468[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1469 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1467[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %alloc_1468[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %648 = arith.addf %646, %647 : f32
          memref.store %648, %alloc_1469[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %expand_shape_1470 = memref.expand_shape %1 [] output_shape [1, 1, 1] : memref<f32> into memref<1x1x1xf32>
    %alloc_1471 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c1 step %c1 {
        scf.for %arg168 = %c0 to %c1 step %c1 {
          %646 = memref.load %expand_shape_1470[%arg166, %arg167, %arg168] : memref<1x1x1xf32>
          %647 = arith.divf %cst_61, %646 : f32
          memref.store %647, %alloc_1471[%arg166, %arg167, %arg168] : memref<1x1x1xf32>
        }
      }
    }
    %alloc_1472 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1469[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %alloc_1471[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1472[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1473 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1466[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %alloc_1465[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %648 = arith.subf %646, %647 : f32
          memref.store %648, %alloc_1473[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1474 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c2 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1473[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
          %647 = memref.load %157[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1474[%arg166, %arg167, %arg168] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_1475 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    %subview_1476 = memref.subview %alloc_1475[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    memref.copy %alloc_1472, %subview_1476 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_1477 = memref.subview %alloc_1475[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    memref.copy %alloc_1474, %subview_1477 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %expand_shape_1478 = memref.expand_shape %0 [[0, 1], [2]] output_shape [1, 1, 6300] : memref<1x6300xf32> into memref<1x1x6300xf32>
    %alloc_1479 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c4 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1475[%arg166, %arg167, %arg168] : memref<1x4x6300xf32>
          %647 = memref.load %expand_shape_1478[%arg166, %c0, %arg168] : memref<1x1x6300xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1479[%arg166, %arg167, %arg168] : memref<1x4x6300xf32>
        }
      }
    }
    %alloc_1480 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1437[%arg166, %arg167, %arg168] : memref<1x80x6300xf32>
          %647 = arith.negf %646 : f32
          %648 = math.exp %647 : f32
          %649 = arith.addf %648, %cst_61 : f32
          %650 = arith.divf %cst_61, %649 : f32
          memref.store %650, %alloc_1480[%arg166, %arg167, %arg168] : memref<1x80x6300xf32>
        }
      }
    }
    %alloc_1481 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    scf.for %arg166 = %c0 to %c1 step %c1 {
      scf.for %arg167 = %c0 to %c80 step %c1 {
        scf.for %arg168 = %c0 to %c6300 step %c1 {
          %646 = memref.load %alloc_1480[%arg166, %arg167, %arg168] : memref<1x80x6300xf32>
          %647 = memref.load %156[%arg166, %c0, %c0] : memref<1x1x1xf32>
          %648 = arith.mulf %646, %647 : f32
          memref.store %648, %alloc_1481[%arg166, %arg167, %arg168] : memref<1x80x6300xf32>
        }
      }
    }
    %alloc_1482 = memref.alloc() {alignment = 64 : i64} : memref<1x84x6300xf32>
    %subview_1483 = memref.subview %alloc_1482[0, 0, 0] [1, 4, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    memref.copy %alloc_1479, %subview_1483 : memref<1x4x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    %subview_1484 = memref.subview %alloc_1482[0, 4, 0] [1, 80, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    memref.copy %alloc_1481, %subview_1484 : memref<1x80x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    %645 = bufferization.to_tensor %alloc_1482 : memref<1x84x6300xf32> to tensor<1x84x6300xf32>
    return %645 : tensor<1x84x6300xf32>
  }
  func.func private @buddy_int8_silu_dequant_nhwc(i64, i64, i64, i64, i64, i64, f32)
}

