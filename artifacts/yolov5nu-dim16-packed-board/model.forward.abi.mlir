module attributes {gemcc.memory_plan = "{\22version\22:1,\22kind\22:\22gemcc-memory-plan\22,\22workspace_bytes\22:31800256,\22alignment\22:64,\22buffers\22:[{\22name\22:\22/model.24/Add_output_0\22,\22space\22:\22host\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22/model.24/Div_output_0\22,\22space\22:\22host\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22/model.24/Gather_output_0\22,\22space\22:\22host\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22/model.24/Mul_1_output_0\22,\22space\22:\22host\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22/model.24/Mul_output_0\22,\22space\22:\22host\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22/model.24/Shape_output_0\22,\22space\22:\22host\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:null,\22note\22:\22control/shape, not a DDR activation\22},{\22name\22:\22model.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:0,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:6912,\22alignment\22:64,\22birth\22:-1,\22death\22:0,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:3,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:18432,\22alignment\22:64,\22birth\22:-1,\22death\22:3,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.10.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:114,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.10.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:114,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:120,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:120,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:129,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:129,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:133,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:133,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:123,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:123,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:126,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.13.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:126,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.14.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:136,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.14.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:32768,\22alignment\22:64,\22birth\22:-1,\22death\22:136,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:142,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:142,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:151,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:151,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:155,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:155,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:145,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:4096,\22alignment\22:64,\22birth\22:-1,\22death\22:145,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:148,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.17.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:36864,\22alignment\22:64,\22birth\22:-1,\22death\22:148,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.18.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:158,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.18.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:158,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:6,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:2048,\22alignment\22:64,\22birth\22:-1,\22death\22:6,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:16,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:2048,\22alignment\22:64,\22birth\22:-1,\22death\22:16,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:20,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:4096,\22alignment\22:64,\22birth\22:-1,\22death\22:20,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:9,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:1024,\22alignment\22:64,\22birth\22:-1,\22death\22:9,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:12,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.2.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:9216,\22alignment\22:64,\22birth\22:-1,\22death\22:12,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:162,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:32768,\22alignment\22:64,\22birth\22:-1,\22death\22:162,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:171,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:32768,\22alignment\22:64,\22birth\22:-1,\22death\22:171,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:175,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:175,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:165,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:165,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:168,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.20.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:168,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.21.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:178,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.21.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:589824,\22alignment\22:64,\22birth\22:-1,\22death\22:178,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:182,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:182,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:191,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:191,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:1024,\22alignment\22:64,\22birth\22:-1,\22death\22:195,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:262144,\22alignment\22:64,\22birth\22:-1,\22death\22:195,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:185,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:185,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:188,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.23.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:589824,\22alignment\22:64,\22birth\22:-1,\22death\22:188,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:198,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:198,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:201,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:201,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:204,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.0.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:204,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:209,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:294912,\22alignment\22:64,\22birth\22:-1,\22death\22:209,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:212,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:212,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:215,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.1.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:215,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:217,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:589824,\22alignment\22:64,\22birth\22:-1,\22death\22:217,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:220,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:220,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:223,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv2.2.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:223,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:226,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:184320,\22alignment\22:64,\22birth\22:-1,\22death\22:226,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:229,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:230400,\22alignment\22:64,\22birth\22:-1,\22death\22:229,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:232,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.0.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:25600,\22alignment\22:64,\22birth\22:-1,\22death\22:232,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:237,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:368640,\22alignment\22:64,\22birth\22:-1,\22death\22:237,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:240,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:230400,\22alignment\22:64,\22birth\22:-1,\22death\22:240,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:243,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.1.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:25600,\22alignment\22:64,\22birth\22:-1,\22death\22:243,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.0.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:245,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.0.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:737280,\22alignment\22:64,\22birth\22:-1,\22death\22:245,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:248,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:230400,\22alignment\22:64,\22birth\22:-1,\22death\22:248,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.2.bias\22,\22space\22:\22constants\22,\22nbytes\22:320,\22alignment\22:64,\22birth\22:-1,\22death\22:251,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.cv3.2.2.weight\22,\22space\22:\22constants\22,\22nbytes\22:25600,\22alignment\22:64,\22birth\22:-1,\22death\22:251,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.24.dfl.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:64,\22alignment\22:64,\22birth\22:-1,\22death\22:258,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:23,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:73728,\22alignment\22:64,\22birth\22:-1,\22death\22:23,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:26,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:8192,\22alignment\22:64,\22birth\22:-1,\22death\22:26,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:43,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:8192,\22alignment\22:64,\22birth\22:-1,\22death\22:43,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:47,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:47,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:29,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:4096,\22alignment\22:64,\22birth\22:-1,\22death\22:29,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:32,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:36864,\22alignment\22:64,\22birth\22:-1,\22death\22:32,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.1.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:36,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.1.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:4096,\22alignment\22:64,\22birth\22:-1,\22death\22:36,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.1.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:128,\22alignment\22:64,\22birth\22:-1,\22death\22:39,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.4.m.1.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:36864,\22alignment\22:64,\22birth\22:-1,\22death\22:39,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.5.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:50,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.5.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:294912,\22alignment\22:64,\22birth\22:-1,\22death\22:50,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:53,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:32768,\22alignment\22:64,\22birth\22:-1,\22death\22:53,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:77,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:32768,\22alignment\22:64,\22birth\22:-1,\22death\22:77,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:81,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:81,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:56,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:56,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:59,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:59,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.1.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:63,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.1.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:63,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.1.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:66,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.1.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:66,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.2.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:70,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.2.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:16384,\22alignment\22:64,\22birth\22:-1,\22death\22:70,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.2.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:256,\22alignment\22:64,\22birth\22:-1,\22death\22:73,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.6.m.2.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:147456,\22alignment\22:64,\22birth\22:-1,\22death\22:73,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.7.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:1024,\22alignment\22:64,\22birth\22:-1,\22death\22:84,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.7.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:1179648,\22alignment\22:64,\22birth\22:-1,\22death\22:84,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:87,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:87,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:97,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:97,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv3.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:1024,\22alignment\22:64,\22birth\22:-1,\22death\22:101,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.cv3.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:262144,\22alignment\22:64,\22birth\22:-1,\22death\22:101,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.m.0.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:90,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.m.0.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:65536,\22alignment\22:64,\22birth\22:-1,\22death\22:90,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.m.0.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:93,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.8.m.0.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:589824,\22alignment\22:64,\22birth\22:-1,\22death\22:93,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.9.cv1.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:512,\22alignment\22:64,\22birth\22:-1,\22death\22:104,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.9.cv1.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:131072,\22alignment\22:64,\22birth\22:-1,\22death\22:104,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.9.cv2.conv.bias\22,\22space\22:\22constants\22,\22nbytes\22:1024,\22alignment\22:64,\22birth\22:-1,\22death\22:111,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22model.9.cv2.conv.weight\22,\22space\22:\22constants\22,\22nbytes\22:524288,\22alignment\22:64,\22birth\22:-1,\22death\22:111,\22ddr_offset\22:null,\22note\22:\22packed in constants.bin\22},{\22name\22:\22/model.24/Constant_10_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:0,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_11_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:64,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_8_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:128,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_9_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:-1,\22death\22:-1,\22ddr_offset\22:192,\22note\22:\22activation/workspace\22},{\22name\22:\22images\22,\22space\22:\22ddr\22,\22nbytes\22:921600,\22alignment\22:64,\22birth\22:-1,\22death\22:0,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:4915200,\22alignment\22:64,\22birth\22:0,\22death\22:2,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:4915200,\22alignment\22:64,\22birth\22:1,\22death\22:2,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:2,\22death\22:3,\22ddr_offset\22:10752256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2457600,\22alignment\22:64,\22birth\22:3,\22death\22:5,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2457600,\22alignment\22:64,\22birth\22:4,\22death\22:5,\22ddr_offset\22:3379456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:5,\22death\22:16,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:6,\22death\22:8,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:7,\22death\22:8,\22ddr_offset\22:7065856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:8,\22death\22:15,\22ddr_offset\22:614656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:9,\22death\22:11,\22ddr_offset\22:8294656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:10,\22death\22:11,\22ddr_offset\22:9523456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:11,\22death\22:12,\22ddr_offset\22:10752256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:12,\22death\22:14,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:13,\22death\22:14,\22ddr_offset\22:2150656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:14,\22death\22:15,\22ddr_offset\22:11059456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/m/m.0/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:15,\22death\22:19,\22ddr_offset\22:11366656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:16,\22death\22:18,\22ddr_offset\22:3379456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:17,\22death\22:18,\22ddr_offset\22:4608256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:18,\22death\22:19,\22ddr_offset\22:11673856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:19,\22death\22:20,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2457600,\22alignment\22:64,\22birth\22:20,\22death\22:22,\22ddr_offset\22:11981056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2457600,\22alignment\22:64,\22birth\22:21,\22death\22:22,\22ddr_offset\22:14438656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.2/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:22,\22death\22:23,\22ddr_offset\22:6451456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:23,\22death\22:25,\22ddr_offset\22:7065856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:24,\22death\22:25,\22ddr_offset\22:8294656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:25,\22death\22:43,\22ddr_offset\22:9523456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:26,\22death\22:28,\22ddr_offset\22:9830656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:27,\22death\22:28,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:28,\22death\22:35,\22ddr_offset\22:10445056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:29,\22death\22:31,\22ddr_offset\22:1536256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:30,\22death\22:31,\22ddr_offset\22:2150656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:31,\22death\22:32,\22ddr_offset\22:10598656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:32,\22death\22:34,\22ddr_offset\22:2765056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:33,\22death\22:34,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:34,\22death\22:35,\22ddr_offset\22:10752256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.0/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:35,\22death\22:42,\22ddr_offset\22:10905856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:36,\22death\22:38,\22ddr_offset\22:3379456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:37,\22death\22:38,\22ddr_offset\22:3993856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:38,\22death\22:39,\22ddr_offset\22:614656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:39,\22death\22:41,\22ddr_offset\22:4608256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:40,\22death\22:41,\22ddr_offset\22:5222656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:41,\22death\22:42,\22ddr_offset\22:768256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/m/m.1/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:42,\22death\22:46,\22ddr_offset\22:11059456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:43,\22death\22:45,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:44,\22death\22:45,\22ddr_offset\22:11981056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:45,\22death\22:46,\22ddr_offset\22:11213056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:46,\22death\22:47,\22ddr_offset\22:11366656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:47,\22death\22:49,\22ddr_offset\22:12595456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:48,\22death\22:49,\22ddr_offset\22:14438656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.4/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:49,\22death\22:141,\22ddr_offset\22:11673856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.5/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:50,\22death\22:52,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.5/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:51,\22death\22:52,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.5/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:52,\22death\22:77,\22ddr_offset\22:16281856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:53,\22death\22:55,\22ddr_offset\22:16435456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:54,\22death\22:55,\22ddr_offset\22:6451456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:55,\22death\22:62,\22ddr_offset\22:16742656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:56,\22death\22:58,\22ddr_offset\22:6758656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:57,\22death\22:58,\22ddr_offset\22:7065856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:58,\22death\22:59,\22ddr_offset\22:16819456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:59,\22death\22:61,\22ddr_offset\22:7373056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:60,\22death\22:61,\22ddr_offset\22:7680256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:61,\22death\22:62,\22ddr_offset\22:7987456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.0/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:62,\22death\22:69,\22ddr_offset\22:8064256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:63,\22death\22:65,\22ddr_offset\22:8294656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:64,\22death\22:65,\22ddr_offset\22:8601856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:65,\22death\22:66,\22ddr_offset\22:8141056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:66,\22death\22:68,\22ddr_offset\22:8909056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:67,\22death\22:68,\22ddr_offset\22:9216256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:68,\22death\22:69,\22ddr_offset\22:8217856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.1/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:69,\22death\22:76,\22ddr_offset\22:9830656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:70,\22death\22:72,\22ddr_offset\22:9907456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:71,\22death\22:72,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:72,\22death\22:73,\22ddr_offset\22:10214656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:73,\22death\22:75,\22ddr_offset\22:1229056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:74,\22death\22:75,\22ddr_offset\22:1536256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:75,\22death\22:76,\22ddr_offset\22:10291456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/m/m.2/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:76,\22death\22:80,\22ddr_offset\22:10368256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:77,\22death\22:79,\22ddr_offset\22:1843456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:78,\22death\22:79,\22ddr_offset\22:2150656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:79,\22death\22:80,\22ddr_offset\22:2457856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:80,\22death\22:81,\22ddr_offset\22:2534656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:81,\22death\22:83,\22ddr_offset\22:2765056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:82,\22death\22:83,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.6/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:83,\22death\22:119,\22ddr_offset\22:10598656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.7/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:84,\22death\22:86,\22ddr_offset\22:3379456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.7/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:85,\22death\22:86,\22ddr_offset\22:3686656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.7/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:86,\22death\22:97,\22ddr_offset\22:2688256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:87,\22death\22:89,\22ddr_offset\22:10445056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:88,\22death\22:89,\22ddr_offset\22:10752256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:89,\22death\22:96,\22ddr_offset\22:3993856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:90,\22death\22:92,\22ddr_offset\22:4032256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:91,\22death\22:92,\22ddr_offset\22:4185856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:92,\22death\22:93,\22ddr_offset\22:4339456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:93,\22death\22:95,\22ddr_offset\22:4377856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:94,\22death\22:95,\22ddr_offset\22:614656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:95,\22death\22:96,\22ddr_offset\22:4531456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/m/m.0/Add_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:96,\22death\22:100,\22ddr_offset\22:4569856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:97,\22death\22:99,\22ddr_offset\22:4608256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:98,\22death\22:99,\22ddr_offset\22:4761856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:99,\22death\22:100,\22ddr_offset\22:4915456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:100,\22death\22:101,\22ddr_offset\22:4953856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:101,\22death\22:103,\22ddr_offset\22:5222656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:102,\22death\22:103,\22ddr_offset\22:5529856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.8/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:103,\22death\22:104,\22ddr_offset\22:5030656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:104,\22death\22:106,\22ddr_offset\22:10905856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:105,\22death\22:106,\22ddr_offset\22:768256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:106,\22death\22:110,\22ddr_offset\22:5107456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/m/MaxPool_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:107,\22death\22:110,\22ddr_offset\22:5145856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/m_1/MaxPool_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:108,\22death\22:110,\22ddr_offset\22:5184256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/m_2/MaxPool_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:109,\22death\22:110,\22ddr_offset\22:9523456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:110,\22death\22:111,\22ddr_offset\22:9561856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:111,\22death\22:113,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:112,\22death\22:113,\22ddr_offset\22:6144256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.9/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:113,\22death\22:114,\22ddr_offset\22:9715456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.10/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:114,\22death\22:116,\22ddr_offset\22:11981056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.10/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:115,\22death\22:116,\22ddr_offset\22:12134656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.10/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:116,\22death\22:181,\22ddr_offset\22:9792256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.11/Constant_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:16,\22alignment\22:64,\22birth\22:117,\22death\22:118,\22ddr_offset\22:0,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.11/Resize_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:118,\22death\22:119,\22ddr_offset\22:12288256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.12/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:119,\22death\22:129,\22ddr_offset\22:11366656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:120,\22death\22:122,\22ddr_offset\22:12595456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:121,\22death\22:122,\22ddr_offset\22:12902656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:122,\22death\22:123,\22ddr_offset\22:12441856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:123,\22death\22:125,\22ddr_offset\22:13209856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:124,\22death\22:125,\22ddr_offset\22:13517056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:125,\22death\22:126,\22ddr_offset\22:12518656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:126,\22death\22:128,\22ddr_offset\22:14438656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:127,\22death\22:128,\22ddr_offset\22:14745856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:128,\22death\22:132,\22ddr_offset\22:11059456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:129,\22death\22:131,\22ddr_offset\22:15053056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:130,\22death\22:131,\22ddr_offset\22:15360256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:131,\22death\22:132,\22ddr_offset\22:11136256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:132,\22death\22:133,\22ddr_offset\22:11213056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:133,\22death\22:135,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:134,\22death\22:135,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.13/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:135,\22death\22:136,\22ddr_offset\22:16435456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.14/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:136,\22death\22:138,\22ddr_offset\22:6451456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.14/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:137,\22death\22:138,\22ddr_offset\22:6758656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.14/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:138,\22death\22:161,\22ddr_offset\22:16589056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.15/Constant_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:16,\22alignment\22:64,\22birth\22:139,\22death\22:140,\22ddr_offset\22:64,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.15/Resize_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:140,\22death\22:141,\22ddr_offset\22:7065856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.16/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:141,\22death\22:151,\22ddr_offset\22:2765056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:142,\22death\22:144,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:143,\22death\22:144,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:144,\22death\22:145,\22ddr_offset\22:7373056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:145,\22death\22:147,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:146,\22death\22:147,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:147,\22death\22:148,\22ddr_offset\22:7526656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:148,\22death\22:150,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:149,\22death\22:150,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:150,\22death\22:154,\22ddr_offset\22:7680256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:151,\22death\22:153,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:152,\22death\22:153,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:153,\22death\22:154,\22ddr_offset\22:7833856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:154,\22death\22:155,\22ddr_offset\22:8294656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:155,\22death\22:157,\22ddr_offset\22:16896256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:156,\22death\22:157,\22ddr_offset\22:18125056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.17/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:157,\22death\22:226,\22ddr_offset\22:8601856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.18/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:158,\22death\22:160,\22ddr_offset\22:8909056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.18/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:159,\22death\22:160,\22ddr_offset\22:9216256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.18/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:160,\22death\22:161,\22ddr_offset\22:16665856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.19/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:161,\22death\22:171,\22ddr_offset\22:9907456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:162,\22death\22:164,\22ddr_offset\22:921856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:163,\22death\22:164,\22ddr_offset\22:1229056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:164,\22death\22:165,\22ddr_offset\22:16819456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:165,\22death\22:167,\22ddr_offset\22:1536256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:166,\22death\22:167,\22ddr_offset\22:1843456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:167,\22death\22:168,\22ddr_offset\22:16742656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:168,\22death\22:170,\22ddr_offset\22:2150656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:169,\22death\22:170,\22ddr_offset\22:3379456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:170,\22death\22:174,\22ddr_offset\22:7987456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:171,\22death\22:173,\22ddr_offset\22:3686656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:172,\22death\22:173,\22ddr_offset\22:5222656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:173,\22death\22:174,\22ddr_offset\22:8141056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:174,\22death\22:175,\22ddr_offset\22:10061056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:175,\22death\22:177,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:614400,\22alignment\22:64,\22birth\22:176,\22death\22:177,\22ddr_offset\22:2765056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.20/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:177,\22death\22:237,\22ddr_offset\22:16281856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.21/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:178,\22death\22:180,\22ddr_offset\22:2534656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.21/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:179,\22death\22:180,\22ddr_offset\22:10445056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.21/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:180,\22death\22:181,\22ddr_offset\22:8064256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.22/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:181,\22death\22:191,\22ddr_offset\22:8217856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:182,\22death\22:184,\22ddr_offset\22:10752256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:183,\22death\22:184,\22ddr_offset\22:4032256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:184,\22death\22:185,\22ddr_offset\22:8102656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:185,\22death\22:187,\22ddr_offset\22:4185856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:186,\22death\22:187,\22ddr_offset\22:4377856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:187,\22death\22:188,\22ddr_offset\22:10214656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:188,\22death\22:190,\22ddr_offset\22:614656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:189,\22death\22:190,\22ddr_offset\22:4608256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/m/m.0/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:190,\22death\22:194,\22ddr_offset\22:10253056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv2/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:191,\22death\22:193,\22ddr_offset\22:4761856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv2/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:153600,\22alignment\22:64,\22birth\22:192,\22death\22:193,\22ddr_offset\22:5529856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv2/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:38400,\22alignment\22:64,\22birth\22:193,\22death\22:194,\22ddr_offset\22:9830656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:194,\22death\22:195,\22ddr_offset\22:10291456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv3/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:195,\22death\22:197,\22ddr_offset\22:5837056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv3/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:196,\22death\22:197,\22ddr_offset\22:6144256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.23/cv3/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:197,\22death\22:245,\22ddr_offset\22:10368256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:198,\22death\22:200,\22ddr_offset\22:16896256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:199,\22death\22:200,\22ddr_offset\22:18125056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:200,\22death\22:201,\22ddr_offset\22:12595456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:201,\22death\22:203,\22ddr_offset\22:16896256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:202,\22death\22:203,\22ddr_offset\22:18125056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:203,\22death\22:204,\22ddr_offset\22:12902656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.0/cv2.0.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:204,\22death\22:208,\22ddr_offset\22:16896256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:205,\22death\22:208,\22ddr_offset\22:128,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:206,\22death\22:216,\22ddr_offset\22:192,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_2_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:207,\22death\22:224,\22ddr_offset\22:9869056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1228800,\22alignment\22:64,\22birth\22:208,\22death\22:225,\22ddr_offset\22:18125056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:209,\22death\22:211,\22ddr_offset\22:13209856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:210,\22death\22:211,\22ddr_offset\22:13517056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:211,\22death\22:212,\22ddr_offset\22:2457856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:212,\22death\22:214,\22ddr_offset\22:14438656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:213,\22death\22:214,\22ddr_offset\22:14745856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:214,\22death\22:215,\22ddr_offset\22:2688256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.1/cv2.1.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:215,\22death\22:216,\22ddr_offset\22:11366656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:307200,\22alignment\22:64,\22birth\22:216,\22death\22:225,\22ddr_offset\22:15053056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:217,\22death\22:219,\22ddr_offset\22:4953856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:218,\22death\22:219,\22ddr_offset\22:5683456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:19200,\22alignment\22:64,\22birth\22:219,\22death\22:220,\22ddr_offset\22:9869120,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:220,\22death\22:222,\22ddr_offset\22:5760256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:221,\22death\22:222,\22ddr_offset\22:5030656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:19200,\22alignment\22:64,\22birth\22:222,\22death\22:223,\22ddr_offset\22:4339456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv2.2/cv2.2.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:223,\22death\22:224,\22ddr_offset\22:10905856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_2_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:76800,\22alignment\22:64,\22birth\22:224,\22death\22:225,\22ddr_offset\22:10982656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Concat_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1612800,\22alignment\22:64,\22birth\22:225,\22death\22:255,\22ddr_offset\22:19353856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:226,\22death\22:228,\22ddr_offset\22:20966656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:227,\22death\22:228,\22ddr_offset\22:22502656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:228,\22death\22:229,\22ddr_offset\22:256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:229,\22death\22:231,\22ddr_offset\22:20966656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:230,\22death\22:231,\22ddr_offset\22:22502656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:231,\22death\22:232,\22ddr_offset\22:13824256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.0/cv3.0.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:232,\22death\22:236,\22ddr_offset\22:20966656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_3_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:233,\22death\22:236,\22ddr_offset\22:9888320,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_4_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:234,\22death\22:244,\22ddr_offset\22:9888384,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_5_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:235,\22death\22:252,\22ddr_offset\22:9888448,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_3_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1536000,\22alignment\22:64,\22birth\22:236,\22death\22:253,\22ddr_offset\22:22502656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:237,\22death\22:239,\22ddr_offset\22:15667456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:238,\22death\22:239,\22ddr_offset\22:2765056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:239,\22death\22:240,\22ddr_offset\22:768256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:240,\22death\22:242,\22ddr_offset\22:16896256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:241,\22death\22:242,\22ddr_offset\22:17280256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:242,\22death\22:243,\22ddr_offset\22:9561856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.1/cv3.1.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:243,\22death\22:244,\22ddr_offset\22:17664256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_4_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:384000,\22alignment\22:64,\22birth\22:244,\22death\22:253,\22ddr_offset\22:18125056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.0/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:245,\22death\22:247,\22ddr_offset\22:11981056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.0/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:246,\22death\22:247,\22ddr_offset\22:12134656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.0/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24000,\22alignment\22:64,\22birth\22:247,\22death\22:248,\22ddr_offset\22:3993856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.1/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:248,\22death\22:250,\22ddr_offset\22:10598656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.1/act/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:249,\22death\22:250,\22ddr_offset\22:12288256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.1/act/Mul_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24000,\22alignment\22:64,\22birth\22:250,\22death\22:251,\22ddr_offset\22:4531456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/cv3.2/cv3.2.2/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:251,\22death\22:252,\22ddr_offset\22:15360256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Reshape_5_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:96000,\22alignment\22:64,\22birth\22:252,\22death\22:253,\22ddr_offset\22:15456256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Concat_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2016000,\22alignment\22:64,\22birth\22:253,\22death\22:276,\22ddr_offset\22:24038656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Constant_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:32,\22alignment\22:64,\22birth\22:254,\22death\22:255,\22ddr_offset\22:9888512,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Reshape_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1612800,\22alignment\22:64,\22birth\22:255,\22death\22:256,\22ddr_offset\22:26054656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Transpose_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1612800,\22alignment\22:64,\22birth\22:256,\22death\22:257,\22ddr_offset\22:19353856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Softmax_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:1612800,\22alignment\22:64,\22birth\22:257,\22death\22:258,\22ddr_offset\22:26054656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/conv/Conv_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:100800,\22alignment\22:64,\22birth\22:258,\22death\22:260,\22ddr_offset\22:15552256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Constant_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:24,\22alignment\22:64,\22birth\22:259,\22death\22:260,\22ddr_offset\22:9888576,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/dfl/Reshape_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:100800,\22alignment\22:64,\22birth\22:260,\22death\22:264,\22ddr_offset\22:11213056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_6_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:261,\22death\22:261,\22ddr_offset\22:9888640,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_7_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:8,\22alignment\22:64,\22birth\22:262,\22death\22:262,\22ddr_offset\22:9888704,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Slice_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:263,\22death\22:266,\22ddr_offset\22:864256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Slice_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:264,\22death\22:268,\22ddr_offset\22:9657856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_12_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:265,\22death\22:266,\22ddr_offset\22:9715456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Sub_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:266,\22death\22:272,\22ddr_offset\22:12077056,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_13_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:267,\22death\22:268,\22ddr_offset\22:12230656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Add_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:268,\22death\22:272,\22ddr_offset\22:10694656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Add_2_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:269,\22death\22:271,\22ddr_offset\22:12384256,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_14_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:4,\22alignment\22:64,\22birth\22:270,\22death\22:271,\22ddr_offset\22:9888768,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Div_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:271,\22death\22:273,\22ddr_offset\22:12441856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Sub_1_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:50400,\22alignment\22:64,\22birth\22:272,\22death\22:273,\22ddr_offset\22:12518656,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Concat_2_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:100800,\22alignment\22:64,\22birth\22:273,\22death\22:275,\22ddr_offset\22:16435456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Constant_15_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:25200,\22alignment\22:64,\22birth\22:274,\22death\22:275,\22ddr_offset\22:4569856,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Mul_2_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:100800,\22alignment\22:64,\22birth\22:275,\22death\22:277,\22ddr_offset\22:6451456,\22note\22:\22activation/workspace\22},{\22name\22:\22/model.24/Sigmoid_output_0\22,\22space\22:\22ddr\22,\22nbytes\22:2016000,\22alignment\22:64,\22birth\22:276,\22death\22:277,\22ddr_offset\22:27667456,\22note\22:\22activation/workspace\22},{\22name\22:\22output0\22,\22space\22:\22ddr\22,\22nbytes\22:2116800,\22alignment\22:64,\22birth\22:277,\22death\22:278,\22ddr_offset\22:29683456,\22note\22:\22activation/workspace\22},{\22name\22:\22gemmini_scratchpad\22,\22space\22:\22scratchpad\22,\22nbytes\22:0,\22alignment\22:64,\22birth\22:-1,\22death\22:278,\22ddr_offset\22:null,\22note\22:\22on-chip; not a DDR strategy\22},{\22name\22:\22gemmini_accumulator\22,\22space\22:\22accumulator\22,\22nbytes\22:0,\22alignment\22:64,\22birth\22:-1,\22death\22:278,\22ddr_offset\22:null,\22note\22:\22on-chip; not a DDR strategy\22}]}", gemcc.workspace_bytes = 31800256 : i64} {
  func.func private @gemmini_tiled_matmul_auto(i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64)
  func.func private @gemmini_tiled_conv_auto(i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64)
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
    memref.global constant @fwd_cst_0 : memref<108x16xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_1 : memref<16xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_2 : memref<144x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_3 : memref<32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_4 : memref<32x16xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_5 : memref<19200x16xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_6 : memref<16x16xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_7 : memref<19200x16xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_8 : memref<144x16xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_9 : memref<16xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_10 : memref<32x16xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_11 : memref<19200x16xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_12 : memref<32x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_13 : memref<19200x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_14 : memref<288x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_15 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_16 : memref<64x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_17 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_18 : memref<32x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_19 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_20 : memref<288x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_21 : memref<32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_22 : memref<32x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_23 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_24 : memref<288x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_25 : memref<32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_26 : memref<64x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_27 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_28 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_29 : memref<4800x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_30 : memref<576x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_31 : memref<128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_32 : memref<128x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_33 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_34 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_35 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_36 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_37 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_38 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_39 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_40 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_41 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_42 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_43 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_44 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_45 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_46 : memref<128x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_47 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_48 : memref<128x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_49 : memref<1200x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_50 : memref<1152x256xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_51 : memref<256xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_52 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_53 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_54 : memref<128x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_55 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_56 : memref<1152x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_57 : memref<128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_58 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_59 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_60 : memref<256x256xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_61 : memref<304x256xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_62 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_63 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_64 : memref<512x256xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_65 : memref<304x256xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_66 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_67 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_68 : memref<256x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_69 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_70 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_71 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_72 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_73 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_74 : memref<256x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_75 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_76 : memref<128x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_77 : memref<1200x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_78 : memref<128x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_79 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_80 : memref<128x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_81 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_82 : memref<32x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_83 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_84 : memref<288x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_85 : memref<32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_86 : memref<128x32xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_87 : memref<4800x32xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_88 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_89 : memref<4800x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_90 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_91 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_92 : memref<128x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_93 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_94 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_95 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_96 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_97 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_98 : memref<128x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_99 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_100 : memref<128x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_101 : memref<1200x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_102 : memref<1152x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_103 : memref<128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_104 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_105 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_106 : memref<128x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_107 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_108 : memref<1152x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_109 : memref<128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_110 : memref<256x128xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_111 : memref<304x128xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_112 : memref<256x256xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_113 : memref<304x256xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_114 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_115 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_116 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_117 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_118 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_119 : memref<4800x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_120 : memref<1152x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_121 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_122 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_123 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_124 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_125 : memref<1200x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_126 : memref<2304x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_127 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_128 : memref<576x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_129 : memref<64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_130 : memref<64x64xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_131 : memref<304x64xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_132 : memref<576x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_133 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_134 : memref<720x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_135 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_136 : memref<80x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_137 : memref<4800x80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_138 : memref<1152x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_139 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_140 : memref<720x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_141 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_142 : memref<80x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_143 : memref<1200x80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_144 : memref<2304x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_145 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_146 : memref<720x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_147 : memref<80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_148 : memref<80x80xi8> {alignment = 64 : i64}
  memref.global constant @fwd_cst_149 : memref<304x80xi32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_150 : memref<1x16x1x1xf32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_151 : memref<1x2x6300xf32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_152 : memref<1x2x6300xf32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_153 : memref<f32> {alignment = 64 : i64}
  memref.global constant @fwd_cst_154 : memref<1x6300xf32> {alignment = 64 : i64}
func.func @forward(%arg0: memref<1x480x640x3xi8>, %arg156: memref<1x84x6300xf32>) {
    %fwd_cst_0 = memref.get_global @fwd_cst_0 : memref<108x16xi8>
    %fwd_cst_1 = memref.get_global @fwd_cst_1 : memref<16xi32>
    %fwd_cst_2 = memref.get_global @fwd_cst_2 : memref<144x32xi8>
    %fwd_cst_3 = memref.get_global @fwd_cst_3 : memref<32xi32>
    %fwd_cst_4 = memref.get_global @fwd_cst_4 : memref<32x16xi8>
    %fwd_cst_5 = memref.get_global @fwd_cst_5 : memref<19200x16xi32>
    %fwd_cst_6 = memref.get_global @fwd_cst_6 : memref<16x16xi8>
    %fwd_cst_7 = memref.get_global @fwd_cst_7 : memref<19200x16xi32>
    %fwd_cst_8 = memref.get_global @fwd_cst_8 : memref<144x16xi8>
    %fwd_cst_9 = memref.get_global @fwd_cst_9 : memref<16xi32>
    %fwd_cst_10 = memref.get_global @fwd_cst_10 : memref<32x16xi8>
    %fwd_cst_11 = memref.get_global @fwd_cst_11 : memref<19200x16xi32>
    %fwd_cst_12 = memref.get_global @fwd_cst_12 : memref<32x32xi8>
    %fwd_cst_13 = memref.get_global @fwd_cst_13 : memref<19200x32xi32>
    %fwd_cst_14 = memref.get_global @fwd_cst_14 : memref<288x64xi8>
    %fwd_cst_15 = memref.get_global @fwd_cst_15 : memref<64xi32>
    %fwd_cst_16 = memref.get_global @fwd_cst_16 : memref<64x32xi8>
    %fwd_cst_17 = memref.get_global @fwd_cst_17 : memref<4800x32xi32>
    %fwd_cst_18 = memref.get_global @fwd_cst_18 : memref<32x32xi8>
    %fwd_cst_19 = memref.get_global @fwd_cst_19 : memref<4800x32xi32>
    %fwd_cst_20 = memref.get_global @fwd_cst_20 : memref<288x32xi8>
    %fwd_cst_21 = memref.get_global @fwd_cst_21 : memref<32xi32>
    %fwd_cst_22 = memref.get_global @fwd_cst_22 : memref<32x32xi8>
    %fwd_cst_23 = memref.get_global @fwd_cst_23 : memref<4800x32xi32>
    %fwd_cst_24 = memref.get_global @fwd_cst_24 : memref<288x32xi8>
    %fwd_cst_25 = memref.get_global @fwd_cst_25 : memref<32xi32>
    %fwd_cst_26 = memref.get_global @fwd_cst_26 : memref<64x32xi8>
    %fwd_cst_27 = memref.get_global @fwd_cst_27 : memref<4800x32xi32>
    %fwd_cst_28 = memref.get_global @fwd_cst_28 : memref<64x64xi8>
    %fwd_cst_29 = memref.get_global @fwd_cst_29 : memref<4800x64xi32>
    %fwd_cst_30 = memref.get_global @fwd_cst_30 : memref<576x128xi8>
    %fwd_cst_31 = memref.get_global @fwd_cst_31 : memref<128xi32>
    %fwd_cst_32 = memref.get_global @fwd_cst_32 : memref<128x64xi8>
    %fwd_cst_33 = memref.get_global @fwd_cst_33 : memref<1200x64xi32>
    %fwd_cst_34 = memref.get_global @fwd_cst_34 : memref<64x64xi8>
    %fwd_cst_35 = memref.get_global @fwd_cst_35 : memref<1200x64xi32>
    %fwd_cst_36 = memref.get_global @fwd_cst_36 : memref<576x64xi8>
    %fwd_cst_37 = memref.get_global @fwd_cst_37 : memref<64xi32>
    %fwd_cst_38 = memref.get_global @fwd_cst_38 : memref<64x64xi8>
    %fwd_cst_39 = memref.get_global @fwd_cst_39 : memref<1200x64xi32>
    %fwd_cst_40 = memref.get_global @fwd_cst_40 : memref<576x64xi8>
    %fwd_cst_41 = memref.get_global @fwd_cst_41 : memref<64xi32>
    %fwd_cst_42 = memref.get_global @fwd_cst_42 : memref<64x64xi8>
    %fwd_cst_43 = memref.get_global @fwd_cst_43 : memref<1200x64xi32>
    %fwd_cst_44 = memref.get_global @fwd_cst_44 : memref<576x64xi8>
    %fwd_cst_45 = memref.get_global @fwd_cst_45 : memref<64xi32>
    %fwd_cst_46 = memref.get_global @fwd_cst_46 : memref<128x64xi8>
    %fwd_cst_47 = memref.get_global @fwd_cst_47 : memref<1200x64xi32>
    %fwd_cst_48 = memref.get_global @fwd_cst_48 : memref<128x128xi8>
    %fwd_cst_49 = memref.get_global @fwd_cst_49 : memref<1200x128xi32>
    %fwd_cst_50 = memref.get_global @fwd_cst_50 : memref<1152x256xi8>
    %fwd_cst_51 = memref.get_global @fwd_cst_51 : memref<256xi32>
    %fwd_cst_52 = memref.get_global @fwd_cst_52 : memref<256x128xi8>
    %fwd_cst_53 = memref.get_global @fwd_cst_53 : memref<304x128xi32>
    %fwd_cst_54 = memref.get_global @fwd_cst_54 : memref<128x128xi8>
    %fwd_cst_55 = memref.get_global @fwd_cst_55 : memref<304x128xi32>
    %fwd_cst_56 = memref.get_global @fwd_cst_56 : memref<1152x128xi8>
    %fwd_cst_57 = memref.get_global @fwd_cst_57 : memref<128xi32>
    %fwd_cst_58 = memref.get_global @fwd_cst_58 : memref<256x128xi8>
    %fwd_cst_59 = memref.get_global @fwd_cst_59 : memref<304x128xi32>
    %fwd_cst_60 = memref.get_global @fwd_cst_60 : memref<256x256xi8>
    %fwd_cst_61 = memref.get_global @fwd_cst_61 : memref<304x256xi32>
    %fwd_cst_62 = memref.get_global @fwd_cst_62 : memref<256x128xi8>
    %fwd_cst_63 = memref.get_global @fwd_cst_63 : memref<304x128xi32>
    %fwd_cst_64 = memref.get_global @fwd_cst_64 : memref<512x256xi8>
    %fwd_cst_65 = memref.get_global @fwd_cst_65 : memref<304x256xi32>
    %fwd_cst_66 = memref.get_global @fwd_cst_66 : memref<256x128xi8>
    %fwd_cst_67 = memref.get_global @fwd_cst_67 : memref<304x128xi32>
    %fwd_cst_68 = memref.get_global @fwd_cst_68 : memref<256x64xi8>
    %fwd_cst_69 = memref.get_global @fwd_cst_69 : memref<1200x64xi32>
    %fwd_cst_70 = memref.get_global @fwd_cst_70 : memref<64x64xi8>
    %fwd_cst_71 = memref.get_global @fwd_cst_71 : memref<1200x64xi32>
    %fwd_cst_72 = memref.get_global @fwd_cst_72 : memref<576x64xi8>
    %fwd_cst_73 = memref.get_global @fwd_cst_73 : memref<64xi32>
    %fwd_cst_74 = memref.get_global @fwd_cst_74 : memref<256x64xi8>
    %fwd_cst_75 = memref.get_global @fwd_cst_75 : memref<1200x64xi32>
    %fwd_cst_76 = memref.get_global @fwd_cst_76 : memref<128x128xi8>
    %fwd_cst_77 = memref.get_global @fwd_cst_77 : memref<1200x128xi32>
    %fwd_cst_78 = memref.get_global @fwd_cst_78 : memref<128x64xi8>
    %fwd_cst_79 = memref.get_global @fwd_cst_79 : memref<1200x64xi32>
    %fwd_cst_80 = memref.get_global @fwd_cst_80 : memref<128x32xi8>
    %fwd_cst_81 = memref.get_global @fwd_cst_81 : memref<4800x32xi32>
    %fwd_cst_82 = memref.get_global @fwd_cst_82 : memref<32x32xi8>
    %fwd_cst_83 = memref.get_global @fwd_cst_83 : memref<4800x32xi32>
    %fwd_cst_84 = memref.get_global @fwd_cst_84 : memref<288x32xi8>
    %fwd_cst_85 = memref.get_global @fwd_cst_85 : memref<32xi32>
    %fwd_cst_86 = memref.get_global @fwd_cst_86 : memref<128x32xi8>
    %fwd_cst_87 = memref.get_global @fwd_cst_87 : memref<4800x32xi32>
    %fwd_cst_88 = memref.get_global @fwd_cst_88 : memref<64x64xi8>
    %fwd_cst_89 = memref.get_global @fwd_cst_89 : memref<4800x64xi32>
    %fwd_cst_90 = memref.get_global @fwd_cst_90 : memref<576x64xi8>
    %fwd_cst_91 = memref.get_global @fwd_cst_91 : memref<64xi32>
    %fwd_cst_92 = memref.get_global @fwd_cst_92 : memref<128x64xi8>
    %fwd_cst_93 = memref.get_global @fwd_cst_93 : memref<1200x64xi32>
    %fwd_cst_94 = memref.get_global @fwd_cst_94 : memref<64x64xi8>
    %fwd_cst_95 = memref.get_global @fwd_cst_95 : memref<1200x64xi32>
    %fwd_cst_96 = memref.get_global @fwd_cst_96 : memref<576x64xi8>
    %fwd_cst_97 = memref.get_global @fwd_cst_97 : memref<64xi32>
    %fwd_cst_98 = memref.get_global @fwd_cst_98 : memref<128x64xi8>
    %fwd_cst_99 = memref.get_global @fwd_cst_99 : memref<1200x64xi32>
    %fwd_cst_100 = memref.get_global @fwd_cst_100 : memref<128x128xi8>
    %fwd_cst_101 = memref.get_global @fwd_cst_101 : memref<1200x128xi32>
    %fwd_cst_102 = memref.get_global @fwd_cst_102 : memref<1152x128xi8>
    %fwd_cst_103 = memref.get_global @fwd_cst_103 : memref<128xi32>
    %fwd_cst_104 = memref.get_global @fwd_cst_104 : memref<256x128xi8>
    %fwd_cst_105 = memref.get_global @fwd_cst_105 : memref<304x128xi32>
    %fwd_cst_106 = memref.get_global @fwd_cst_106 : memref<128x128xi8>
    %fwd_cst_107 = memref.get_global @fwd_cst_107 : memref<304x128xi32>
    %fwd_cst_108 = memref.get_global @fwd_cst_108 : memref<1152x128xi8>
    %fwd_cst_109 = memref.get_global @fwd_cst_109 : memref<128xi32>
    %fwd_cst_110 = memref.get_global @fwd_cst_110 : memref<256x128xi8>
    %fwd_cst_111 = memref.get_global @fwd_cst_111 : memref<304x128xi32>
    %fwd_cst_112 = memref.get_global @fwd_cst_112 : memref<256x256xi8>
    %fwd_cst_113 = memref.get_global @fwd_cst_113 : memref<304x256xi32>
    %fwd_cst_114 = memref.get_global @fwd_cst_114 : memref<576x64xi8>
    %fwd_cst_115 = memref.get_global @fwd_cst_115 : memref<64xi32>
    %fwd_cst_116 = memref.get_global @fwd_cst_116 : memref<576x64xi8>
    %fwd_cst_117 = memref.get_global @fwd_cst_117 : memref<64xi32>
    %fwd_cst_118 = memref.get_global @fwd_cst_118 : memref<64x64xi8>
    %fwd_cst_119 = memref.get_global @fwd_cst_119 : memref<4800x64xi32>
    %fwd_cst_120 = memref.get_global @fwd_cst_120 : memref<1152x64xi8>
    %fwd_cst_121 = memref.get_global @fwd_cst_121 : memref<64xi32>
    %fwd_cst_122 = memref.get_global @fwd_cst_122 : memref<576x64xi8>
    %fwd_cst_123 = memref.get_global @fwd_cst_123 : memref<64xi32>
    %fwd_cst_124 = memref.get_global @fwd_cst_124 : memref<64x64xi8>
    %fwd_cst_125 = memref.get_global @fwd_cst_125 : memref<1200x64xi32>
    %fwd_cst_126 = memref.get_global @fwd_cst_126 : memref<2304x64xi8>
    %fwd_cst_127 = memref.get_global @fwd_cst_127 : memref<64xi32>
    %fwd_cst_128 = memref.get_global @fwd_cst_128 : memref<576x64xi8>
    %fwd_cst_129 = memref.get_global @fwd_cst_129 : memref<64xi32>
    %fwd_cst_130 = memref.get_global @fwd_cst_130 : memref<64x64xi8>
    %fwd_cst_131 = memref.get_global @fwd_cst_131 : memref<304x64xi32>
    %fwd_cst_132 = memref.get_global @fwd_cst_132 : memref<576x80xi8>
    %fwd_cst_133 = memref.get_global @fwd_cst_133 : memref<80xi32>
    %fwd_cst_134 = memref.get_global @fwd_cst_134 : memref<720x80xi8>
    %fwd_cst_135 = memref.get_global @fwd_cst_135 : memref<80xi32>
    %fwd_cst_136 = memref.get_global @fwd_cst_136 : memref<80x80xi8>
    %fwd_cst_137 = memref.get_global @fwd_cst_137 : memref<4800x80xi32>
    %fwd_cst_138 = memref.get_global @fwd_cst_138 : memref<1152x80xi8>
    %fwd_cst_139 = memref.get_global @fwd_cst_139 : memref<80xi32>
    %fwd_cst_140 = memref.get_global @fwd_cst_140 : memref<720x80xi8>
    %fwd_cst_141 = memref.get_global @fwd_cst_141 : memref<80xi32>
    %fwd_cst_142 = memref.get_global @fwd_cst_142 : memref<80x80xi8>
    %fwd_cst_143 = memref.get_global @fwd_cst_143 : memref<1200x80xi32>
    %fwd_cst_144 = memref.get_global @fwd_cst_144 : memref<2304x80xi8>
    %fwd_cst_145 = memref.get_global @fwd_cst_145 : memref<80xi32>
    %fwd_cst_146 = memref.get_global @fwd_cst_146 : memref<720x80xi8>
    %fwd_cst_147 = memref.get_global @fwd_cst_147 : memref<80xi32>
    %fwd_cst_148 = memref.get_global @fwd_cst_148 : memref<80x80xi8>
    %fwd_cst_149 = memref.get_global @fwd_cst_149 : memref<304x80xi32>
    %fwd_cst_150 = memref.get_global @fwd_cst_150 : memref<1x16x1x1xf32>
    %fwd_cst_151 = memref.get_global @fwd_cst_151 : memref<1x2x6300xf32>
    %fwd_cst_152 = memref.get_global @fwd_cst_152 : memref<1x2x6300xf32>
    %fwd_cst_153 = memref.get_global @fwd_cst_153 : memref<f32>
    %fwd_cst_154 = memref.get_global @fwd_cst_154 : memref<1x6300xf32>

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
    %0 = memref.get_global @__constant_1x1x1xf32 : memref<1x1x1xf32>
    %1 = memref.get_global @__constant_1x1x1xf32_0 : memref<1x1x1xf32>
    %2 = memref.get_global @__constant_1x1x1xf32_1 : memref<1x1x1xf32>
    %3 = memref.get_global @__constant_1x1x1xf32_2 : memref<1x1x1xf32>
    %4 = memref.get_global @__constant_1x1x1x1xf32 : memref<1x1x1x1xf32>
    %5 = memref.get_global @__constant_1x1x1x1xf32_4 : memref<1x1x1x1xf32>
    %6 = memref.get_global @__constant_1x1x1x1xf32_5 : memref<1x1x1x1xf32>
    %7 = memref.get_global @__constant_1x1x1xf32_6 : memref<1x1x1xf32>
    %8 = memref.get_global @__constant_1x1x1xf32_7 : memref<1x1x1xf32>
    %9 = memref.get_global @__constant_1x1x1x1xf32_8 : memref<1x1x1x1xf32>
    %10 = memref.get_global @__constant_1x1x1x1xf32_10 : memref<1x1x1x1xf32>
    %11 = memref.get_global @__constant_1x1x1x1xf32_13 : memref<1x1x1x1xf32>
    %12 = memref.get_global @__constant_1x1x1x1xf32_16 : memref<1x1x1x1xf32>
    %13 = memref.get_global @__constant_1x1x1x1xf32_18 : memref<1x1x1x1xf32>
    %14 = memref.get_global @__constant_1x1x1x1xf32_21 : memref<1x1x1x1xf32>
    %15 = memref.get_global @__constant_1x1x1x1xf32_24 : memref<1x1x1x1xf32>
    %16 = memref.get_global @__constant_1x1x1x1xf32_26 : memref<1x1x1x1xf32>
    %17 = memref.get_global @__constant_1x1x1x1xf32_29 : memref<1x1x1x1xf32>
    %18 = memref.get_global @__constant_1x1x1xf32_32 : memref<1x1x1xf32>
    %19 = memref.get_global @__constant_1x1x1xf32_33 : memref<1x1x1xf32>
    %20 = memref.get_global @__constant_1x1x1x1xf32_34 : memref<1x1x1x1xf32>
    %21 = memref.get_global @__constant_1x1x1x1xf32_36 : memref<1x1x1x1xf32>
    %22 = memref.get_global @__constant_1x1x1x1xf32_39 : memref<1x1x1x1xf32>
    %23 = memref.get_global @__constant_1x1x1x1xf32_42 : memref<1x1x1x1xf32>
    %24 = memref.get_global @__constant_1x1x1x1xf32_44 : memref<1x1x1x1xf32>
    %25 = memref.get_global @__constant_1x1x1x1xf32_47 : memref<1x1x1x1xf32>
    %26 = memref.get_global @__constant_1x1x1x1xf32_50 : memref<1x1x1x1xf32>
    %27 = memref.get_global @__constant_1x1x1x1xf32_52 : memref<1x1x1x1xf32>
    %28 = memref.get_global @__constant_1x1x1x1xf32_55 : memref<1x1x1x1xf32>
    %29 = memref.get_global @__constant_1x1x1x1xf32_58 : memref<1x1x1x1xf32>
    %30 = memref.get_global @__constant_1x1x1x1xi32 : memref<1x1x1x1xi32>
    %31 = memref.get_global @__constant_1x1x1x1xi32_61 : memref<1x1x1x1xi32>
    %32 = memref.get_global @__constant_1x1x1x1xf32_62 : memref<1x1x1x1xf32>
    %33 = memref.get_global @__constant_1x1x1x1xf32_64 : memref<1x1x1x1xf32>
    %34 = memref.get_global @__constant_1x1x1x1xf32_67 : memref<1x1x1x1xf32>
    %35 = memref.get_global @__constant_1x1x1x1xf32_70 : memref<1x1x1x1xf32>
    %36 = memref.get_global @__constant_1x1x1x1xi32_73 : memref<1x1x1x1xi32>
    %37 = memref.get_global @__constant_1x1x1x1xi32_74 : memref<1x1x1x1xi32>
    %38 = memref.get_global @__constant_1x1x1x1xf32_75 : memref<1x1x1x1xf32>
    %39 = memref.get_global @__constant_1x1x1x1xf32_77 : memref<1x1x1x1xf32>
    %40 = memref.get_global @__constant_1x1x1x1xi32_80 : memref<1x1x1x1xi32>
    %41 = memref.get_global @__constant_1x1x1x1xi32_81 : memref<1x1x1x1xi32>
    %42 = memref.get_global @__constant_1x1x1x1xf32_82 : memref<1x1x1x1xf32>
    %43 = memref.get_global @__constant_1x1x1x1xf32_84 : memref<1x1x1x1xf32>
    %44 = memref.get_global @__constant_1x1x1x1xf32_87 : memref<1x1x1x1xf32>
    %45 = memref.get_global @__constant_1x1x1x1xf32_90 : memref<1x1x1x1xf32>
    %46 = memref.get_global @__constant_1x1x1x1xi32_93 : memref<1x1x1x1xi32>
    %47 = memref.get_global @__constant_1x1x1x1xi32_94 : memref<1x1x1x1xi32>
    %48 = memref.get_global @__constant_1x1x1x1xf32_95 : memref<1x1x1x1xf32>
    %49 = memref.get_global @__constant_1x1x1x1xf32_98 : memref<1x1x1x1xf32>
    %50 = memref.get_global @__constant_1x1x1x1xi32_101 : memref<1x1x1x1xi32>
    %51 = memref.get_global @__constant_1x1x1x1xi32_102 : memref<1x1x1x1xi32>
    %52 = memref.get_global @__constant_1x1x1x1xf32_103 : memref<1x1x1x1xf32>
    %53 = memref.get_global @__constant_1x1x1x1xf32_105 : memref<1x1x1x1xf32>
    %54 = memref.get_global @__constant_1x1x1x1xf32_108 : memref<1x1x1x1xf32>
    %55 = memref.get_global @__constant_1x1x1x1xf32_111 : memref<1x1x1x1xf32>
    %56 = memref.get_global @__constant_1x1x1x1xi32_114 : memref<1x1x1x1xi32>
    %57 = memref.get_global @__constant_1x1x1x1xi32_115 : memref<1x1x1x1xi32>
    %58 = memref.get_global @__constant_1x1x1x1xf32_116 : memref<1x1x1x1xf32>
    %59 = memref.get_global @__constant_1x1x1x1xf32_119 : memref<1x1x1x1xf32>
    %60 = memref.get_global @__constant_1x1x1x1xi32_122 : memref<1x1x1x1xi32>
    %61 = memref.get_global @__constant_1x1x1x1xi32_123 : memref<1x1x1x1xi32>
    %62 = memref.get_global @__constant_1x1x1x1xf32_124 : memref<1x1x1x1xf32>
    %63 = memref.get_global @__constant_1x1x1x1xf32_126 : memref<1x1x1x1xf32>
    %64 = memref.get_global @__constant_1x1x1x1xf32_129 : memref<1x1x1x1xf32>
    %65 = memref.get_global @__constant_1x1x1x1xf32_132 : memref<1x1x1x1xf32>
    %66 = memref.get_global @__constant_1x1x1x1xi32_135 : memref<1x1x1x1xi32>
    %67 = memref.get_global @__constant_1x1x1x1xi32_136 : memref<1x1x1x1xi32>
    %68 = memref.get_global @__constant_1x1x1x1xf32_137 : memref<1x1x1x1xf32>
    %69 = memref.get_global @__constant_1x1x1x1xf32_140 : memref<1x1x1x1xf32>
    %70 = memref.get_global @__constant_1x1x1x1xf32_143 : memref<1x1x1x1xf32>
    %71 = memref.get_global @__constant_1x1x1x1xf32_146 : memref<1x1x1x1xf32>
    %72 = memref.get_global @__constant_1x1x1x1xi32_149 : memref<1x1x1x1xi32>
    %73 = memref.get_global @__constant_1x1x1x1xf32_150 : memref<1x1x1x1xf32>
    %74 = memref.get_global @__constant_1x1x1x1xi32_152 : memref<1x1x1x1xi32>
    %75 = memref.get_global @__constant_1x1x1x1xi32_153 : memref<1x1x1x1xi32>
    %76 = memref.get_global @__constant_1x1x1x1xf32_154 : memref<1x1x1x1xf32>
    %77 = memref.get_global @__constant_1x1x1x1xf32_157 : memref<1x1x1x1xf32>
    %78 = memref.get_global @__constant_1x1x1x1xf32_160 : memref<1x1x1x1xf32>
    %79 = memref.get_global @__constant_1x1x1x1xf32_163 : memref<1x1x1x1xf32>
    %80 = memref.get_global @__constant_1x1x1x1xf32_166 : memref<1x1x1x1xf32>
    %81 = memref.get_global @__constant_1x1x1x1xi32_169 : memref<1x1x1x1xi32>
    %82 = memref.get_global @__constant_1x1x1x1xf32_170 : memref<1x1x1x1xf32>
    %83 = memref.get_global @__constant_1x1x1x1xi32_172 : memref<1x1x1x1xi32>
    %84 = memref.get_global @__constant_1x1x1x1xi32_173 : memref<1x1x1x1xi32>
    %85 = memref.get_global @__constant_1x1x1x1xf32_174 : memref<1x1x1x1xf32>
    %86 = memref.get_global @__constant_1x1x1x1xf32_177 : memref<1x1x1x1xf32>
    %87 = memref.get_global @__constant_1x1x1x1xi32_180 : memref<1x1x1x1xi32>
    %88 = memref.get_global @__constant_1x1x1x1xi32_181 : memref<1x1x1x1xi32>
    %89 = memref.get_global @__constant_1x1x1x1xf32_182 : memref<1x1x1x1xf32>
    %90 = memref.get_global @__constant_1x1x1x1xf32_185 : memref<1x1x1x1xf32>
    %91 = memref.get_global @__constant_1x1x1x1xi32_188 : memref<1x1x1x1xi32>
    %92 = memref.get_global @__constant_1x1x1x1xi32_189 : memref<1x1x1x1xi32>
    %93 = memref.get_global @__constant_1x1x1x1xf32_190 : memref<1x1x1x1xf32>
    %94 = memref.get_global @__constant_1x1x1x1xf32_193 : memref<1x1x1x1xf32>
    %95 = memref.get_global @__constant_1x1x1x1xf32_196 : memref<1x1x1x1xf32>
    %96 = memref.get_global @__constant_1x1x1x1xf32_199 : memref<1x1x1x1xf32>
    %97 = memref.get_global @__constant_1x1x1x1xf32_202 : memref<1x1x1x1xf32>
    %98 = memref.get_global @__constant_1x1x1x1xi32_205 : memref<1x1x1x1xi32>
    %99 = memref.get_global @__constant_1x1x1x1xi32_206 : memref<1x1x1x1xi32>
    %100 = memref.get_global @__constant_1x1x1x1xf32_207 : memref<1x1x1x1xf32>
    %101 = memref.get_global @__constant_1x1x1x1xi32_209 : memref<1x1x1x1xi32>
    %102 = memref.get_global @__constant_1x1x1x1xi32_210 : memref<1x1x1x1xi32>
    %103 = memref.get_global @__constant_1x1x1x1xf32_211 : memref<1x1x1x1xf32>
    %104 = memref.get_global @__constant_1x1x1x1xf32_214 : memref<1x1x1x1xf32>
    %105 = memref.get_global @__constant_1x1x1x1xi32_217 : memref<1x1x1x1xi32>
    %106 = memref.get_global @__constant_1x1x1x1xi32_218 : memref<1x1x1x1xi32>
    %107 = memref.get_global @__constant_1x1x1x1xf32_219 : memref<1x1x1x1xf32>
    %108 = memref.get_global @__constant_1x1x1x1xf32_222 : memref<1x1x1x1xf32>
    %109 = memref.get_global @__constant_1x1x1x1xf32_225 : memref<1x1x1x1xf32>
    %110 = memref.get_global @__constant_1x1x1x1xf32_228 : memref<1x1x1x1xf32>
    %111 = memref.get_global @__constant_1x1x1x1xf32_231 : memref<1x1x1x1xf32>
    %112 = memref.get_global @__constant_1x1x1x1xi32_234 : memref<1x1x1x1xi32>
    %113 = memref.get_global @__constant_1x1x1x1xi32_235 : memref<1x1x1x1xi32>
    %114 = memref.get_global @__constant_1x1x1x1xf32_236 : memref<1x1x1x1xf32>
    %115 = memref.get_global @__constant_1x1x1x1xi32_238 : memref<1x1x1x1xi32>
    %116 = memref.get_global @__constant_1x1x1x1xi32_239 : memref<1x1x1x1xi32>
    %117 = memref.get_global @__constant_1x1x1x1xi32_240 : memref<1x1x1x1xi32>
    %118 = memref.get_global @__constant_1x1x1x1xi32_241 : memref<1x1x1x1xi32>
    %119 = memref.get_global @__constant_1x1x1x1xi32_242 : memref<1x1x1x1xi32>
    %120 = memref.get_global @__constant_1x1x1x1xf32_243 : memref<1x1x1x1xf32>
    %121 = memref.get_global @__constant_1x1x1x1xf32_246 : memref<1x1x1x1xf32>
    %122 = memref.get_global @__constant_1x1x1x1xf32_249 : memref<1x1x1x1xf32>
    %123 = memref.get_global @__constant_1x1x1x1xf32_252 : memref<1x1x1x1xf32>
    %124 = memref.get_global @__constant_1x1x1x1xf32_255 : memref<1x1x1x1xf32>
    %125 = memref.get_global @__constant_1xi32 : memref<1xi32>
    %alloc = memref.alloc() {alignment = 64 : i64} : memref<1x484x644x3xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c484 step %c1 {
        scf.for %arg159 = %c0 to %c644 step %c1 {
          scf.for %arg160 = %c0 to %c3 step %c1 {
            memref.store %c0_i8, %alloc[%arg157, %arg158, %arg159, %arg160] : memref<1x484x644x3xi8>
          }
        }
      }
    }
    %subview = memref.subview %alloc[0, 2, 2, 0] [1, 480, 640, 3] [1, 1, 1, 1] : memref<1x484x644x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    memref.copy %arg0, %subview : memref<1x480x640x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    %alloc_66 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c240 step %c1 {
        scf.for %arg159 = %c0 to %c320 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %fwd_cst_1[%arg160] : memref<16xi32>
            memref.store %793, %alloc_66[%arg157, %arg158, %arg159, %arg160] : memref<1x240x320x16xi32>
          }
        }
      }
    }
    %alloc_67 = memref.alloc() {alignment = 64 : i64} : memref<76800x16xi8>
    %c1_i64_68 = arith.constant 1 : i64
    %c484_i64 = arith.constant 484 : i64
    %c644_i64 = arith.constant 644 : i64
    %c3_i64_69 = arith.constant 3 : i64
    %c16_i64_70 = arith.constant 16 : i64
    %c240_i64_71 = arith.constant 240 : i64
    %c320_i64_72 = arith.constant 320 : i64
    %c2_i64 = arith.constant 2 : i64
    %c1_i64_73 = arith.constant 1 : i64
    %c1_i64_74 = arith.constant 1 : i64
    %c0_i64_75 = arith.constant 0 : i64
    %c6_i64_76 = arith.constant 6 : i64
    %c0_i64_77 = arith.constant 0 : i64
    %c0_i64_78 = arith.constant 0 : i64
    %c0_i64_79 = arith.constant 0 : i64
    %c0_i64_80 = arith.constant 0 : i64
    %c0_i64_81 = arith.constant 0 : i64
    %intptr = memref.extract_aligned_pointer_as_index %alloc : memref<1x484x644x3xi8> -> index
    %126 = arith.index_cast %intptr : index to i64
    %intptr_82 = memref.extract_aligned_pointer_as_index %fwd_cst_0 : memref<108x16xi8> -> index
    %127 = arith.index_cast %intptr_82 : index to i64
    %intptr_83 = memref.extract_aligned_pointer_as_index %fwd_cst_1 : memref<16xi32> -> index
    %128 = arith.index_cast %intptr_83 : index to i64
    %intptr_84 = memref.extract_aligned_pointer_as_index %alloc_67 : memref<76800x16xi8> -> index
    %129 = arith.index_cast %intptr_84 : index to i64
    %c0_i64_85 = arith.constant 0 : i64
    %cst_86 = arith.constant 0.00288073183 : f32
    %c0_i64_87 = arith.constant 0 : i64
    %c0_i64_88 = arith.constant 0 : i64
    %c0_i64_89 = arith.constant 0 : i64
    %c1_i64_90 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_68, %c484_i64, %c644_i64, %c3_i64_69, %c16_i64_70, %c240_i64_71, %c320_i64_72, %c2_i64, %c1_i64_73, %c1_i64_74, %c0_i64_75, %c6_i64_76, %c0_i64_77, %c0_i64_78, %c0_i64_79, %c0_i64_80, %c0_i64_81, %126, %127, %128, %129, %c0_i64_85, %cst_86, %c0_i64_87, %c0_i64_88, %c0_i64_89, %c1_i64_90) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_91 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xf32>
    %intptr_92 = memref.extract_aligned_pointer_as_index %alloc_91 : memref<1x240x320x16xf32> -> index
    %intptr_93 = memref.extract_aligned_pointer_as_index %alloc_67 : memref<76800x16xi8> -> index
    %130 = arith.index_cast %intptr_92 : index to i64
    %131 = arith.index_cast %intptr_93 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%130, %131, %c1_i64, %c240_i64, %c320_i64, %c16_i64, %cst_60) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_67 : memref<76800x16xi8>
    %alloc_94 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c240 step %c1 {
          scf.for %arg160 = %c0 to %c320 step %c1 {
            %793 = memref.load %alloc_91[%arg157, %arg159, %arg160, %arg158] : memref<1x240x320x16xf32>
            memref.store %793, %alloc_94[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_95 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    memref.copy %alloc_94, %alloc_95 : memref<1x16x240x320xf32> to memref<1x16x240x320xf32>
    %alloc_96 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c240 step %c1 {
          scf.for %arg160 = %c0 to %c320 step %c1 {
            %793 = memref.load %alloc_95[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
            %794 = memref.load %124[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_96[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_97 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c240 step %c1 {
          scf.for %arg160 = %c0 to %c320 step %c1 {
            %793 = memref.load %alloc_96[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_97[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
          }
        }
      }
    }
    %alloc_98 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c240 step %c1 {
          scf.for %arg160 = %c0 to %c320 step %c1 {
            %793 = memref.load %alloc_97[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_98[%arg157, %arg158, %arg159, %arg160] : memref<1x16x240x320xi8>
          }
        }
      }
    }
    %alloc_99 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c240 step %c1 {
        scf.for %arg159 = %c0 to %c320 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_98[%arg157, %arg160, %arg158, %arg159] : memref<1x16x240x320xi8>
            memref.store %793, %alloc_99[%arg157, %arg158, %arg159, %arg160] : memref<1x240x320x16xi8>
          }
        }
      }
    }
    %alloc_100 = memref.alloc() {alignment = 64 : i64} : memref<1x241x321x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c241 step %c1 {
        scf.for %arg159 = %c0 to %c321 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            memref.store %c0_i8, %alloc_100[%arg157, %arg158, %arg159, %arg160] : memref<1x241x321x16xi8>
          }
        }
      }
    }
    %subview_101 = memref.subview %alloc_100[0, 1, 1, 0] [1, 240, 320, 16] [1, 1, 1, 1] : memref<1x241x321x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    memref.copy %alloc_99, %subview_101 : memref<1x240x320x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    %alloc_102 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %fwd_cst_3[%arg160] : memref<32xi32>
            memref.store %793, %alloc_102[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x32xi32>
          }
        }
      }
    }
    %alloc_103 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %c1_i64_104 = arith.constant 1 : i64
    %c241_i64 = arith.constant 241 : i64
    %c321_i64 = arith.constant 321 : i64
    %c16_i64_105 = arith.constant 16 : i64
    %c32_i64_106 = arith.constant 32 : i64
    %c120_i64_107 = arith.constant 120 : i64
    %c160_i64_108 = arith.constant 160 : i64
    %c2_i64_109 = arith.constant 2 : i64
    %c1_i64_110 = arith.constant 1 : i64
    %c1_i64_111 = arith.constant 1 : i64
    %c0_i64_112 = arith.constant 0 : i64
    %c3_i64_113 = arith.constant 3 : i64
    %c0_i64_114 = arith.constant 0 : i64
    %c0_i64_115 = arith.constant 0 : i64
    %c0_i64_116 = arith.constant 0 : i64
    %c0_i64_117 = arith.constant 0 : i64
    %c0_i64_118 = arith.constant 0 : i64
    %intptr_119 = memref.extract_aligned_pointer_as_index %alloc_100 : memref<1x241x321x16xi8> -> index
    %132 = arith.index_cast %intptr_119 : index to i64
    %intptr_120 = memref.extract_aligned_pointer_as_index %fwd_cst_2 : memref<144x32xi8> -> index
    %133 = arith.index_cast %intptr_120 : index to i64
    %intptr_121 = memref.extract_aligned_pointer_as_index %fwd_cst_3 : memref<32xi32> -> index
    %134 = arith.index_cast %intptr_121 : index to i64
    %intptr_122 = memref.extract_aligned_pointer_as_index %alloc_103 : memref<19200x32xi8> -> index
    %135 = arith.index_cast %intptr_122 : index to i64
    %c0_i64_123 = arith.constant 0 : i64
    %cst_124 = arith.constant 5.703000e-03 : f32
    %c0_i64_125 = arith.constant 0 : i64
    %c0_i64_126 = arith.constant 0 : i64
    %c0_i64_127 = arith.constant 0 : i64
    %c1_i64_128 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_104, %c241_i64, %c321_i64, %c16_i64_105, %c32_i64_106, %c120_i64_107, %c160_i64_108, %c2_i64_109, %c1_i64_110, %c1_i64_111, %c0_i64_112, %c3_i64_113, %c0_i64_114, %c0_i64_115, %c0_i64_116, %c0_i64_117, %c0_i64_118, %132, %133, %134, %135, %c0_i64_123, %cst_124, %c0_i64_125, %c0_i64_126, %c0_i64_127, %c1_i64_128) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_129 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    %intptr_130 = memref.extract_aligned_pointer_as_index %alloc_129 : memref<1x120x160x32xf32> -> index
    %intptr_131 = memref.extract_aligned_pointer_as_index %alloc_103 : memref<19200x32xi8> -> index
    %136 = arith.index_cast %intptr_130 : index to i64
    %137 = arith.index_cast %intptr_131 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%136, %137, %c1_i64, %c120_i64, %c160_i64, %c32_i64, %cst_57) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_103 : memref<19200x32xi8>
    %alloc_132 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_129[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x32xf32>
            memref.store %793, %alloc_132[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_133 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    memref.copy %alloc_132, %alloc_133 : memref<1x32x120x160xf32> to memref<1x32x120x160xf32>
    %alloc_134 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_133[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = memref.load %123[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_134[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_135 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_134[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_135[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_136 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_135[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_136[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xi8>
          }
        }
      }
    }
    %alloc_137 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_136[%arg157, %arg160, %arg158, %arg159] : memref<1x32x120x160xi8>
            memref.store %793, %alloc_137[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_138 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_139 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_140 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_141 = memref.extract_aligned_pointer_as_index %alloc_137 : memref<1x120x160x32xi8> -> index
    %138 = arith.index_cast %intptr_141 : index to i64
    %intptr_142 = memref.extract_aligned_pointer_as_index %alloc_139 : memref<19200x32xi8> -> index
    %139 = arith.index_cast %intptr_142 : index to i64
    %intptr_143 = memref.extract_aligned_pointer_as_index %alloc_140 : memref<19200x16xi8> -> index
    %140 = arith.index_cast %intptr_143 : index to i64
    %intptr_144 = memref.extract_aligned_pointer_as_index %alloc_138 : memref<19200x16xi8> -> index
    %141 = arith.index_cast %intptr_144 : index to i64
    call @buddy_rvv_memcpy_i8(%139, %138, %c614400_i64) : (i64, i64, i64) -> ()
    %142 = arith.addi %139, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%142, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c19200_i64_145 = arith.constant 19200 : i64
    %c16_i64_146 = arith.constant 16 : i64
    %c32_i64_147 = arith.constant 32 : i64
    %intptr_148 = memref.extract_aligned_pointer_as_index %alloc_139 : memref<19200x32xi8> -> index
    %143 = arith.index_cast %intptr_148 : index to i64
    %intptr_149 = memref.extract_aligned_pointer_as_index %fwd_cst_4 : memref<32x16xi8> -> index
    %144 = arith.index_cast %intptr_149 : index to i64
    %intptr_150 = memref.extract_aligned_pointer_as_index %fwd_cst_5 : memref<19200x16xi32> -> index
    %145 = arith.index_cast %intptr_150 : index to i64
    %intptr_151 = memref.extract_aligned_pointer_as_index %alloc_140 : memref<19200x16xi8> -> index
    %146 = arith.index_cast %intptr_151 : index to i64
    %c32_i64_152 = arith.constant 32 : i64
    %c16_i64_153 = arith.constant 16 : i64
    %c16_i64_154 = arith.constant 16 : i64
    %c16_i64_155 = arith.constant 16 : i64
    %cst_156 = arith.constant 1.000000e+00 : f32
    %cst_157 = arith.constant 1.000000e+00 : f32
    %cst_158 = arith.constant 1.000000e+00 : f32
    %c0_i64_159 = arith.constant 0 : i64
    %cst_160 = arith.constant 0.0475858524 : f32
    %cst_161 = arith.constant 0.000000e+00 : f32
    %c0_i64_162 = arith.constant 0 : i64
    %c0_i64_163 = arith.constant 0 : i64
    %c0_i64_164 = arith.constant 0 : i64
    %c0_i64_165 = arith.constant 0 : i64
    %c0_i64_166 = arith.constant 0 : i64
    %c0_i64_167 = arith.constant 0 : i64
    %c1_i64_168 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c19200_i64_145, %c16_i64_146, %c32_i64_147, %143, %144, %145, %146, %c32_i64_152, %c16_i64_153, %c16_i64_154, %c16_i64_155, %cst_156, %cst_157, %cst_158, %c0_i64_159, %cst_160, %cst_161, %c0_i64_162, %c0_i64_163, %c0_i64_164, %c0_i64_165, %c0_i64_166, %c0_i64_167, %c1_i64_168) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%141, %140, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_139 : memref<19200x32xi8>
    memref.dealloc %alloc_140 : memref<19200x16xi8>
    %alloc_169 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_170 = memref.extract_aligned_pointer_as_index %alloc_169 : memref<1x120x160x16xf32> -> index
    %intptr_171 = memref.extract_aligned_pointer_as_index %alloc_138 : memref<19200x16xi8> -> index
    %147 = arith.index_cast %intptr_170 : index to i64
    %148 = arith.index_cast %intptr_171 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%147, %148, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_56) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_138 : memref<19200x16xi8>
    %alloc_172 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_169[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x16xf32>
            memref.store %793, %alloc_172[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_173 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_172, %alloc_173 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_174 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_173[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = memref.load %122[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_174[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_175 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_174[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_175[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_176 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_175[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_176[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_177 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_176[%arg157, %arg160, %arg158, %arg159] : memref<1x16x120x160xi8>
            memref.store %793, %alloc_177[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x16xi8>
          }
        }
      }
    }
    %alloc_178 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_179 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_180 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_181 = memref.extract_aligned_pointer_as_index %alloc_177 : memref<1x120x160x16xi8> -> index
    %149 = arith.index_cast %intptr_181 : index to i64
    %intptr_182 = memref.extract_aligned_pointer_as_index %alloc_179 : memref<19200x16xi8> -> index
    %150 = arith.index_cast %intptr_182 : index to i64
    %intptr_183 = memref.extract_aligned_pointer_as_index %alloc_180 : memref<19200x16xi8> -> index
    %151 = arith.index_cast %intptr_183 : index to i64
    %intptr_184 = memref.extract_aligned_pointer_as_index %alloc_178 : memref<19200x16xi8> -> index
    %152 = arith.index_cast %intptr_184 : index to i64
    call @buddy_rvv_memcpy_i8(%150, %149, %c307200_i64) : (i64, i64, i64) -> ()
    %153 = arith.addi %150, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%153, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c19200_i64_185 = arith.constant 19200 : i64
    %c16_i64_186 = arith.constant 16 : i64
    %c16_i64_187 = arith.constant 16 : i64
    %intptr_188 = memref.extract_aligned_pointer_as_index %alloc_179 : memref<19200x16xi8> -> index
    %154 = arith.index_cast %intptr_188 : index to i64
    %intptr_189 = memref.extract_aligned_pointer_as_index %fwd_cst_6 : memref<16x16xi8> -> index
    %155 = arith.index_cast %intptr_189 : index to i64
    %intptr_190 = memref.extract_aligned_pointer_as_index %fwd_cst_7 : memref<19200x16xi32> -> index
    %156 = arith.index_cast %intptr_190 : index to i64
    %intptr_191 = memref.extract_aligned_pointer_as_index %alloc_180 : memref<19200x16xi8> -> index
    %157 = arith.index_cast %intptr_191 : index to i64
    %c16_i64_192 = arith.constant 16 : i64
    %c16_i64_193 = arith.constant 16 : i64
    %c16_i64_194 = arith.constant 16 : i64
    %c16_i64_195 = arith.constant 16 : i64
    %cst_196 = arith.constant 1.000000e+00 : f32
    %cst_197 = arith.constant 1.000000e+00 : f32
    %cst_198 = arith.constant 1.000000e+00 : f32
    %c0_i64_199 = arith.constant 0 : i64
    %cst_200 = arith.constant 0.0180469286 : f32
    %cst_201 = arith.constant 0.000000e+00 : f32
    %c0_i64_202 = arith.constant 0 : i64
    %c0_i64_203 = arith.constant 0 : i64
    %c0_i64_204 = arith.constant 0 : i64
    %c0_i64_205 = arith.constant 0 : i64
    %c0_i64_206 = arith.constant 0 : i64
    %c0_i64_207 = arith.constant 0 : i64
    %c1_i64_208 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c19200_i64_185, %c16_i64_186, %c16_i64_187, %154, %155, %156, %157, %c16_i64_192, %c16_i64_193, %c16_i64_194, %c16_i64_195, %cst_196, %cst_197, %cst_198, %c0_i64_199, %cst_200, %cst_201, %c0_i64_202, %c0_i64_203, %c0_i64_204, %c0_i64_205, %c0_i64_206, %c0_i64_207, %c1_i64_208) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%152, %151, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_179 : memref<19200x16xi8>
    memref.dealloc %alloc_180 : memref<19200x16xi8>
    %alloc_209 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_210 = memref.extract_aligned_pointer_as_index %alloc_209 : memref<1x120x160x16xf32> -> index
    %intptr_211 = memref.extract_aligned_pointer_as_index %alloc_178 : memref<19200x16xi8> -> index
    %158 = arith.index_cast %intptr_210 : index to i64
    %159 = arith.index_cast %intptr_211 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%158, %159, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_55) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_178 : memref<19200x16xi8>
    %alloc_212 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_209[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x16xf32>
            memref.store %793, %alloc_212[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_213 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_212, %alloc_213 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_214 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_213[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = memref.load %121[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_214[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_215 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_214[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_215[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_216 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_215[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_216[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_217 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_216[%arg157, %arg160, %arg158, %arg159] : memref<1x16x120x160xi8>
            memref.store %793, %alloc_217[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x16xi8>
          }
        }
      }
    }
    %alloc_218 = memref.alloc() {alignment = 64 : i64} : memref<1x122x162x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c122 step %c1 {
        scf.for %arg159 = %c0 to %c162 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            memref.store %c0_i8, %alloc_218[%arg157, %arg158, %arg159, %arg160] : memref<1x122x162x16xi8>
          }
        }
      }
    }
    %subview_219 = memref.subview %alloc_218[0, 1, 1, 0] [1, 120, 160, 16] [1, 1, 1, 1] : memref<1x122x162x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    memref.copy %alloc_217, %subview_219 : memref<1x120x160x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    %alloc_220 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %fwd_cst_9[%arg160] : memref<16xi32>
            memref.store %793, %alloc_220[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x16xi32>
          }
        }
      }
    }
    %alloc_221 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %c1_i64_222 = arith.constant 1 : i64
    %c122_i64 = arith.constant 122 : i64
    %c162_i64 = arith.constant 162 : i64
    %c16_i64_223 = arith.constant 16 : i64
    %c16_i64_224 = arith.constant 16 : i64
    %c120_i64_225 = arith.constant 120 : i64
    %c160_i64_226 = arith.constant 160 : i64
    %c1_i64_227 = arith.constant 1 : i64
    %c1_i64_228 = arith.constant 1 : i64
    %c1_i64_229 = arith.constant 1 : i64
    %c0_i64_230 = arith.constant 0 : i64
    %c3_i64_231 = arith.constant 3 : i64
    %c0_i64_232 = arith.constant 0 : i64
    %c0_i64_233 = arith.constant 0 : i64
    %c0_i64_234 = arith.constant 0 : i64
    %c0_i64_235 = arith.constant 0 : i64
    %c0_i64_236 = arith.constant 0 : i64
    %intptr_237 = memref.extract_aligned_pointer_as_index %alloc_218 : memref<1x122x162x16xi8> -> index
    %160 = arith.index_cast %intptr_237 : index to i64
    %intptr_238 = memref.extract_aligned_pointer_as_index %fwd_cst_8 : memref<144x16xi8> -> index
    %161 = arith.index_cast %intptr_238 : index to i64
    %intptr_239 = memref.extract_aligned_pointer_as_index %fwd_cst_9 : memref<16xi32> -> index
    %162 = arith.index_cast %intptr_239 : index to i64
    %intptr_240 = memref.extract_aligned_pointer_as_index %alloc_221 : memref<19200x16xi8> -> index
    %163 = arith.index_cast %intptr_240 : index to i64
    %c0_i64_241 = arith.constant 0 : i64
    %cst_242 = arith.constant 0.0068890308 : f32
    %c0_i64_243 = arith.constant 0 : i64
    %c0_i64_244 = arith.constant 0 : i64
    %c0_i64_245 = arith.constant 0 : i64
    %c1_i64_246 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_222, %c122_i64, %c162_i64, %c16_i64_223, %c16_i64_224, %c120_i64_225, %c160_i64_226, %c1_i64_227, %c1_i64_228, %c1_i64_229, %c0_i64_230, %c3_i64_231, %c0_i64_232, %c0_i64_233, %c0_i64_234, %c0_i64_235, %c0_i64_236, %160, %161, %162, %163, %c0_i64_241, %cst_242, %c0_i64_243, %c0_i64_244, %c0_i64_245, %c1_i64_246) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_247 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_248 = memref.extract_aligned_pointer_as_index %alloc_247 : memref<1x120x160x16xf32> -> index
    %intptr_249 = memref.extract_aligned_pointer_as_index %alloc_221 : memref<19200x16xi8> -> index
    %164 = arith.index_cast %intptr_248 : index to i64
    %165 = arith.index_cast %intptr_249 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%164, %165, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_54) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_221 : memref<19200x16xi8>
    %alloc_250 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_247[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x16xf32>
            memref.store %793, %alloc_250[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_251 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_250, %alloc_251 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_252 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_251[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = memref.load %120[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_252[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_253 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_252[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_253[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_254 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_253[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_254[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_255 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_176[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_255[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_256 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_255[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %119[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_256[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_257 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_256[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_257[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_258 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_254[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_258[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_259 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_258[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %117[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_259[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_260 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_259[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_260[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_261 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_257[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %alloc_260[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_261[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_262 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_261[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_262[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_263 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_262[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_263[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_264 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_263[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_264[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_265 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_136[%arg157, %arg160, %arg158, %arg159] : memref<1x32x120x160xi8>
            memref.store %793, %alloc_265[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_266 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %alloc_267 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_268 = memref.alloc() {alignment = 64 : i64} : memref<19200x16xi8>
    %intptr_269 = memref.extract_aligned_pointer_as_index %alloc_265 : memref<1x120x160x32xi8> -> index
    %166 = arith.index_cast %intptr_269 : index to i64
    %intptr_270 = memref.extract_aligned_pointer_as_index %alloc_267 : memref<19200x32xi8> -> index
    %167 = arith.index_cast %intptr_270 : index to i64
    %intptr_271 = memref.extract_aligned_pointer_as_index %alloc_268 : memref<19200x16xi8> -> index
    %168 = arith.index_cast %intptr_271 : index to i64
    %intptr_272 = memref.extract_aligned_pointer_as_index %alloc_266 : memref<19200x16xi8> -> index
    %169 = arith.index_cast %intptr_272 : index to i64
    call @buddy_rvv_memcpy_i8(%167, %166, %c614400_i64) : (i64, i64, i64) -> ()
    %170 = arith.addi %167, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%170, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c19200_i64_273 = arith.constant 19200 : i64
    %c16_i64_274 = arith.constant 16 : i64
    %c32_i64_275 = arith.constant 32 : i64
    %intptr_276 = memref.extract_aligned_pointer_as_index %alloc_267 : memref<19200x32xi8> -> index
    %171 = arith.index_cast %intptr_276 : index to i64
    %intptr_277 = memref.extract_aligned_pointer_as_index %fwd_cst_10 : memref<32x16xi8> -> index
    %172 = arith.index_cast %intptr_277 : index to i64
    %intptr_278 = memref.extract_aligned_pointer_as_index %fwd_cst_11 : memref<19200x16xi32> -> index
    %173 = arith.index_cast %intptr_278 : index to i64
    %intptr_279 = memref.extract_aligned_pointer_as_index %alloc_268 : memref<19200x16xi8> -> index
    %174 = arith.index_cast %intptr_279 : index to i64
    %c32_i64_280 = arith.constant 32 : i64
    %c16_i64_281 = arith.constant 16 : i64
    %c16_i64_282 = arith.constant 16 : i64
    %c16_i64_283 = arith.constant 16 : i64
    %cst_284 = arith.constant 1.000000e+00 : f32
    %cst_285 = arith.constant 1.000000e+00 : f32
    %cst_286 = arith.constant 1.000000e+00 : f32
    %c0_i64_287 = arith.constant 0 : i64
    %cst_288 = arith.constant 0.0373886824 : f32
    %cst_289 = arith.constant 0.000000e+00 : f32
    %c0_i64_290 = arith.constant 0 : i64
    %c0_i64_291 = arith.constant 0 : i64
    %c0_i64_292 = arith.constant 0 : i64
    %c0_i64_293 = arith.constant 0 : i64
    %c0_i64_294 = arith.constant 0 : i64
    %c0_i64_295 = arith.constant 0 : i64
    %c1_i64_296 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c19200_i64_273, %c16_i64_274, %c32_i64_275, %171, %172, %173, %174, %c32_i64_280, %c16_i64_281, %c16_i64_282, %c16_i64_283, %cst_284, %cst_285, %cst_286, %c0_i64_287, %cst_288, %cst_289, %c0_i64_290, %c0_i64_291, %c0_i64_292, %c0_i64_293, %c0_i64_294, %c0_i64_295, %c1_i64_296) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%169, %168, %c19200_i64, %c16_i64, %c16_i64, %c16_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_267 : memref<19200x32xi8>
    memref.dealloc %alloc_268 : memref<19200x16xi8>
    %alloc_297 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    %intptr_298 = memref.extract_aligned_pointer_as_index %alloc_297 : memref<1x120x160x16xf32> -> index
    %intptr_299 = memref.extract_aligned_pointer_as_index %alloc_266 : memref<19200x16xi8> -> index
    %175 = arith.index_cast %intptr_298 : index to i64
    %176 = arith.index_cast %intptr_299 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%175, %176, %c1_i64, %c120_i64, %c160_i64, %c16_i64, %cst_54) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_266 : memref<19200x16xi8>
    %alloc_300 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_297[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x16xf32>
            memref.store %793, %alloc_300[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_301 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    memref.copy %alloc_300, %alloc_301 : memref<1x16x120x160xf32> to memref<1x16x120x160xf32>
    %alloc_302 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_301[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = memref.load %114[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_302[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_303 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_302[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_303[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
          }
        }
      }
    }
    %alloc_304 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_303[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_304[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_305 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_264[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_305[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_306 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_305[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %113[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_306[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_307 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_306[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_307[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_308 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_307[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_308[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_309 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_308[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_309[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_310 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_309[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_310[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_311 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_304[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_311[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_312 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_311[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %112[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_312[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_313 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_312[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_313[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_314 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_313[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_314[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_315 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_314[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_315[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
          }
        }
      }
    }
    %alloc_316 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_315[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_316[%arg157, %arg158, %arg159, %arg160] : memref<1x16x120x160xi8>
          }
        }
      }
    }
    %alloc_317 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    %subview_318 = memref.subview %alloc_317[0, 0, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    memref.copy %alloc_310, %subview_318 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    %subview_319 = memref.subview %alloc_317[0, 16, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    memref.copy %alloc_316, %subview_319 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    %alloc_320 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_317[%arg157, %arg160, %arg158, %arg159] : memref<1x32x120x160xi8>
            memref.store %793, %alloc_320[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_321 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_322 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %alloc_323 = memref.alloc() {alignment = 64 : i64} : memref<19200x32xi8>
    %intptr_324 = memref.extract_aligned_pointer_as_index %alloc_320 : memref<1x120x160x32xi8> -> index
    %177 = arith.index_cast %intptr_324 : index to i64
    %intptr_325 = memref.extract_aligned_pointer_as_index %alloc_322 : memref<19200x32xi8> -> index
    %178 = arith.index_cast %intptr_325 : index to i64
    %intptr_326 = memref.extract_aligned_pointer_as_index %alloc_323 : memref<19200x32xi8> -> index
    %179 = arith.index_cast %intptr_326 : index to i64
    %intptr_327 = memref.extract_aligned_pointer_as_index %alloc_321 : memref<19200x32xi8> -> index
    %180 = arith.index_cast %intptr_327 : index to i64
    call @buddy_rvv_memcpy_i8(%178, %177, %c614400_i64) : (i64, i64, i64) -> ()
    %181 = arith.addi %178, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%181, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c19200_i64_328 = arith.constant 19200 : i64
    %c32_i64_329 = arith.constant 32 : i64
    %c32_i64_330 = arith.constant 32 : i64
    %intptr_331 = memref.extract_aligned_pointer_as_index %alloc_322 : memref<19200x32xi8> -> index
    %182 = arith.index_cast %intptr_331 : index to i64
    %intptr_332 = memref.extract_aligned_pointer_as_index %fwd_cst_12 : memref<32x32xi8> -> index
    %183 = arith.index_cast %intptr_332 : index to i64
    %intptr_333 = memref.extract_aligned_pointer_as_index %fwd_cst_13 : memref<19200x32xi32> -> index
    %184 = arith.index_cast %intptr_333 : index to i64
    %intptr_334 = memref.extract_aligned_pointer_as_index %alloc_323 : memref<19200x32xi8> -> index
    %185 = arith.index_cast %intptr_334 : index to i64
    %c32_i64_335 = arith.constant 32 : i64
    %c32_i64_336 = arith.constant 32 : i64
    %c32_i64_337 = arith.constant 32 : i64
    %c32_i64_338 = arith.constant 32 : i64
    %cst_339 = arith.constant 1.000000e+00 : f32
    %cst_340 = arith.constant 1.000000e+00 : f32
    %cst_341 = arith.constant 1.000000e+00 : f32
    %c0_i64_342 = arith.constant 0 : i64
    %cst_343 = arith.constant 8.487220e-03 : f32
    %cst_344 = arith.constant 0.000000e+00 : f32
    %c0_i64_345 = arith.constant 0 : i64
    %c0_i64_346 = arith.constant 0 : i64
    %c0_i64_347 = arith.constant 0 : i64
    %c0_i64_348 = arith.constant 0 : i64
    %c0_i64_349 = arith.constant 0 : i64
    %c0_i64_350 = arith.constant 0 : i64
    %c1_i64_351 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c19200_i64_328, %c32_i64_329, %c32_i64_330, %182, %183, %184, %185, %c32_i64_335, %c32_i64_336, %c32_i64_337, %c32_i64_338, %cst_339, %cst_340, %cst_341, %c0_i64_342, %cst_343, %cst_344, %c0_i64_345, %c0_i64_346, %c0_i64_347, %c0_i64_348, %c0_i64_349, %c0_i64_350, %c1_i64_351) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%180, %179, %c19200_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_322 : memref<19200x32xi8>
    memref.dealloc %alloc_323 : memref<19200x32xi8>
    %alloc_352 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    %intptr_353 = memref.extract_aligned_pointer_as_index %alloc_352 : memref<1x120x160x32xf32> -> index
    %intptr_354 = memref.extract_aligned_pointer_as_index %alloc_321 : memref<19200x32xi8> -> index
    %186 = arith.index_cast %intptr_353 : index to i64
    %187 = arith.index_cast %intptr_354 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%186, %187, %c1_i64, %c120_i64, %c160_i64, %c32_i64, %cst_53) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_321 : memref<19200x32xi8>
    %alloc_355 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_352[%arg157, %arg159, %arg160, %arg158] : memref<1x120x160x32xf32>
            memref.store %793, %alloc_355[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_356 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    memref.copy %alloc_355, %alloc_356 : memref<1x32x120x160xf32> to memref<1x32x120x160xf32>
    %alloc_357 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_356[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = memref.load %111[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_357[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_358 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_357[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_358[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
          }
        }
      }
    }
    %alloc_359 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c120 step %c1 {
          scf.for %arg160 = %c0 to %c160 step %c1 {
            %793 = memref.load %alloc_358[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_359[%arg157, %arg158, %arg159, %arg160] : memref<1x32x120x160xi8>
          }
        }
      }
    }
    %alloc_360 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c120 step %c1 {
        scf.for %arg159 = %c0 to %c160 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_359[%arg157, %arg160, %arg158, %arg159] : memref<1x32x120x160xi8>
            memref.store %793, %alloc_360[%arg157, %arg158, %arg159, %arg160] : memref<1x120x160x32xi8>
          }
        }
      }
    }
    %alloc_361 = memref.alloc() {alignment = 64 : i64} : memref<1x121x161x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c121 step %c1 {
        scf.for %arg159 = %c0 to %c161 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_361[%arg157, %arg158, %arg159, %arg160] : memref<1x121x161x32xi8>
          }
        }
      }
    }
    %subview_362 = memref.subview %alloc_361[0, 1, 1, 0] [1, 120, 160, 32] [1, 1, 1, 1] : memref<1x121x161x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    memref.copy %alloc_360, %subview_362 : memref<1x120x160x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    %alloc_363 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_15[%arg160] : memref<64xi32>
            memref.store %793, %alloc_363[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_364 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %c1_i64_365 = arith.constant 1 : i64
    %c121_i64 = arith.constant 121 : i64
    %c161_i64 = arith.constant 161 : i64
    %c32_i64_366 = arith.constant 32 : i64
    %c64_i64_367 = arith.constant 64 : i64
    %c60_i64_368 = arith.constant 60 : i64
    %c80_i64_369 = arith.constant 80 : i64
    %c2_i64_370 = arith.constant 2 : i64
    %c1_i64_371 = arith.constant 1 : i64
    %c1_i64_372 = arith.constant 1 : i64
    %c0_i64_373 = arith.constant 0 : i64
    %c3_i64_374 = arith.constant 3 : i64
    %c0_i64_375 = arith.constant 0 : i64
    %c0_i64_376 = arith.constant 0 : i64
    %c0_i64_377 = arith.constant 0 : i64
    %c0_i64_378 = arith.constant 0 : i64
    %c0_i64_379 = arith.constant 0 : i64
    %intptr_380 = memref.extract_aligned_pointer_as_index %alloc_361 : memref<1x121x161x32xi8> -> index
    %188 = arith.index_cast %intptr_380 : index to i64
    %intptr_381 = memref.extract_aligned_pointer_as_index %fwd_cst_14 : memref<288x64xi8> -> index
    %189 = arith.index_cast %intptr_381 : index to i64
    %intptr_382 = memref.extract_aligned_pointer_as_index %fwd_cst_15 : memref<64xi32> -> index
    %190 = arith.index_cast %intptr_382 : index to i64
    %intptr_383 = memref.extract_aligned_pointer_as_index %alloc_364 : memref<4800x64xi8> -> index
    %191 = arith.index_cast %intptr_383 : index to i64
    %c0_i64_384 = arith.constant 0 : i64
    %cst_385 = arith.constant 0.00754241226 : f32
    %c0_i64_386 = arith.constant 0 : i64
    %c0_i64_387 = arith.constant 0 : i64
    %c0_i64_388 = arith.constant 0 : i64
    %c1_i64_389 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_365, %c121_i64, %c161_i64, %c32_i64_366, %c64_i64_367, %c60_i64_368, %c80_i64_369, %c2_i64_370, %c1_i64_371, %c1_i64_372, %c0_i64_373, %c3_i64_374, %c0_i64_375, %c0_i64_376, %c0_i64_377, %c0_i64_378, %c0_i64_379, %188, %189, %190, %191, %c0_i64_384, %cst_385, %c0_i64_386, %c0_i64_387, %c0_i64_388, %c1_i64_389) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_390 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_391 = memref.extract_aligned_pointer_as_index %alloc_390 : memref<1x60x80x64xf32> -> index
    %intptr_392 = memref.extract_aligned_pointer_as_index %alloc_364 : memref<4800x64xi8> -> index
    %192 = arith.index_cast %intptr_391 : index to i64
    %193 = arith.index_cast %intptr_392 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%192, %193, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_52) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_364 : memref<4800x64xi8>
    %alloc_393 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_390[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_393[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_394 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_393, %alloc_394 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_395 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_394[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = memref.load %110[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_395[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_396 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_395[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_396[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_397 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_396[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_397[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_398 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_397[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_398[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_399 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_400 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_401 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_402 = memref.extract_aligned_pointer_as_index %alloc_398 : memref<1x60x80x64xi8> -> index
    %194 = arith.index_cast %intptr_402 : index to i64
    %intptr_403 = memref.extract_aligned_pointer_as_index %alloc_400 : memref<4800x64xi8> -> index
    %195 = arith.index_cast %intptr_403 : index to i64
    %intptr_404 = memref.extract_aligned_pointer_as_index %alloc_401 : memref<4800x32xi8> -> index
    %196 = arith.index_cast %intptr_404 : index to i64
    %intptr_405 = memref.extract_aligned_pointer_as_index %alloc_399 : memref<4800x32xi8> -> index
    %197 = arith.index_cast %intptr_405 : index to i64
    call @buddy_rvv_memcpy_i8(%195, %194, %c307200_i64) : (i64, i64, i64) -> ()
    %198 = arith.addi %195, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%198, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_406 = arith.constant 4800 : i64
    %c32_i64_407 = arith.constant 32 : i64
    %c64_i64_408 = arith.constant 64 : i64
    %intptr_409 = memref.extract_aligned_pointer_as_index %alloc_400 : memref<4800x64xi8> -> index
    %199 = arith.index_cast %intptr_409 : index to i64
    %intptr_410 = memref.extract_aligned_pointer_as_index %fwd_cst_16 : memref<64x32xi8> -> index
    %200 = arith.index_cast %intptr_410 : index to i64
    %intptr_411 = memref.extract_aligned_pointer_as_index %fwd_cst_17 : memref<4800x32xi32> -> index
    %201 = arith.index_cast %intptr_411 : index to i64
    %intptr_412 = memref.extract_aligned_pointer_as_index %alloc_401 : memref<4800x32xi8> -> index
    %202 = arith.index_cast %intptr_412 : index to i64
    %c64_i64_413 = arith.constant 64 : i64
    %c32_i64_414 = arith.constant 32 : i64
    %c32_i64_415 = arith.constant 32 : i64
    %c32_i64_416 = arith.constant 32 : i64
    %cst_417 = arith.constant 1.000000e+00 : f32
    %cst_418 = arith.constant 1.000000e+00 : f32
    %cst_419 = arith.constant 1.000000e+00 : f32
    %c0_i64_420 = arith.constant 0 : i64
    %cst_421 = arith.constant 0.0151615953 : f32
    %cst_422 = arith.constant 0.000000e+00 : f32
    %c0_i64_423 = arith.constant 0 : i64
    %c0_i64_424 = arith.constant 0 : i64
    %c0_i64_425 = arith.constant 0 : i64
    %c0_i64_426 = arith.constant 0 : i64
    %c0_i64_427 = arith.constant 0 : i64
    %c0_i64_428 = arith.constant 0 : i64
    %c1_i64_429 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_406, %c32_i64_407, %c64_i64_408, %199, %200, %201, %202, %c64_i64_413, %c32_i64_414, %c32_i64_415, %c32_i64_416, %cst_417, %cst_418, %cst_419, %c0_i64_420, %cst_421, %cst_422, %c0_i64_423, %c0_i64_424, %c0_i64_425, %c0_i64_426, %c0_i64_427, %c0_i64_428, %c1_i64_429) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%197, %196, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_400 : memref<4800x64xi8>
    memref.dealloc %alloc_401 : memref<4800x32xi8>
    %alloc_430 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_431 = memref.extract_aligned_pointer_as_index %alloc_430 : memref<1x60x80x32xf32> -> index
    %intptr_432 = memref.extract_aligned_pointer_as_index %alloc_399 : memref<4800x32xi8> -> index
    %203 = arith.index_cast %intptr_431 : index to i64
    %204 = arith.index_cast %intptr_432 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%203, %204, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_51) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_399 : memref<4800x32xi8>
    %alloc_433 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_430[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_433[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_434 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_433, %alloc_434 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_435 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_434[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %109[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_435[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_436 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_435[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_436[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_437 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_436[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_437[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_438 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_437[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_438[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_439 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_440 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_441 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_442 = memref.extract_aligned_pointer_as_index %alloc_438 : memref<1x60x80x32xi8> -> index
    %205 = arith.index_cast %intptr_442 : index to i64
    %intptr_443 = memref.extract_aligned_pointer_as_index %alloc_440 : memref<4800x32xi8> -> index
    %206 = arith.index_cast %intptr_443 : index to i64
    %intptr_444 = memref.extract_aligned_pointer_as_index %alloc_441 : memref<4800x32xi8> -> index
    %207 = arith.index_cast %intptr_444 : index to i64
    %intptr_445 = memref.extract_aligned_pointer_as_index %alloc_439 : memref<4800x32xi8> -> index
    %208 = arith.index_cast %intptr_445 : index to i64
    call @buddy_rvv_memcpy_i8(%206, %205, %c153600_i64) : (i64, i64, i64) -> ()
    %209 = arith.addi %206, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%209, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_446 = arith.constant 4800 : i64
    %c32_i64_447 = arith.constant 32 : i64
    %c32_i64_448 = arith.constant 32 : i64
    %intptr_449 = memref.extract_aligned_pointer_as_index %alloc_440 : memref<4800x32xi8> -> index
    %210 = arith.index_cast %intptr_449 : index to i64
    %intptr_450 = memref.extract_aligned_pointer_as_index %fwd_cst_18 : memref<32x32xi8> -> index
    %211 = arith.index_cast %intptr_450 : index to i64
    %intptr_451 = memref.extract_aligned_pointer_as_index %fwd_cst_19 : memref<4800x32xi32> -> index
    %212 = arith.index_cast %intptr_451 : index to i64
    %intptr_452 = memref.extract_aligned_pointer_as_index %alloc_441 : memref<4800x32xi8> -> index
    %213 = arith.index_cast %intptr_452 : index to i64
    %c32_i64_453 = arith.constant 32 : i64
    %c32_i64_454 = arith.constant 32 : i64
    %c32_i64_455 = arith.constant 32 : i64
    %c32_i64_456 = arith.constant 32 : i64
    %cst_457 = arith.constant 1.000000e+00 : f32
    %cst_458 = arith.constant 1.000000e+00 : f32
    %cst_459 = arith.constant 1.000000e+00 : f32
    %c0_i64_460 = arith.constant 0 : i64
    %cst_461 = arith.constant 1.479830e-02 : f32
    %cst_462 = arith.constant 0.000000e+00 : f32
    %c0_i64_463 = arith.constant 0 : i64
    %c0_i64_464 = arith.constant 0 : i64
    %c0_i64_465 = arith.constant 0 : i64
    %c0_i64_466 = arith.constant 0 : i64
    %c0_i64_467 = arith.constant 0 : i64
    %c0_i64_468 = arith.constant 0 : i64
    %c1_i64_469 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_446, %c32_i64_447, %c32_i64_448, %210, %211, %212, %213, %c32_i64_453, %c32_i64_454, %c32_i64_455, %c32_i64_456, %cst_457, %cst_458, %cst_459, %c0_i64_460, %cst_461, %cst_462, %c0_i64_463, %c0_i64_464, %c0_i64_465, %c0_i64_466, %c0_i64_467, %c0_i64_468, %c1_i64_469) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%208, %207, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_440 : memref<4800x32xi8>
    memref.dealloc %alloc_441 : memref<4800x32xi8>
    %alloc_470 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_471 = memref.extract_aligned_pointer_as_index %alloc_470 : memref<1x60x80x32xf32> -> index
    %intptr_472 = memref.extract_aligned_pointer_as_index %alloc_439 : memref<4800x32xi8> -> index
    %214 = arith.index_cast %intptr_471 : index to i64
    %215 = arith.index_cast %intptr_472 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%214, %215, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_50) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_439 : memref<4800x32xi8>
    %alloc_473 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_470[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_473[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_474 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_473, %alloc_474 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_475 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_474[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %108[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_475[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_476 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_475[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_476[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_477 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_476[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_477[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_478 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_477[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_478[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_479 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_479[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_480 = memref.subview %alloc_479[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_478, %subview_480 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_481 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %fwd_cst_21[%arg160] : memref<32xi32>
            memref.store %793, %alloc_481[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_482 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %c1_i64_483 = arith.constant 1 : i64
    %c62_i64 = arith.constant 62 : i64
    %c82_i64 = arith.constant 82 : i64
    %c32_i64_484 = arith.constant 32 : i64
    %c32_i64_485 = arith.constant 32 : i64
    %c60_i64_486 = arith.constant 60 : i64
    %c80_i64_487 = arith.constant 80 : i64
    %c1_i64_488 = arith.constant 1 : i64
    %c1_i64_489 = arith.constant 1 : i64
    %c1_i64_490 = arith.constant 1 : i64
    %c0_i64_491 = arith.constant 0 : i64
    %c3_i64_492 = arith.constant 3 : i64
    %c0_i64_493 = arith.constant 0 : i64
    %c0_i64_494 = arith.constant 0 : i64
    %c0_i64_495 = arith.constant 0 : i64
    %c0_i64_496 = arith.constant 0 : i64
    %c0_i64_497 = arith.constant 0 : i64
    %intptr_498 = memref.extract_aligned_pointer_as_index %alloc_479 : memref<1x62x82x32xi8> -> index
    %216 = arith.index_cast %intptr_498 : index to i64
    %intptr_499 = memref.extract_aligned_pointer_as_index %fwd_cst_20 : memref<288x32xi8> -> index
    %217 = arith.index_cast %intptr_499 : index to i64
    %intptr_500 = memref.extract_aligned_pointer_as_index %fwd_cst_21 : memref<32xi32> -> index
    %218 = arith.index_cast %intptr_500 : index to i64
    %intptr_501 = memref.extract_aligned_pointer_as_index %alloc_482 : memref<4800x32xi8> -> index
    %219 = arith.index_cast %intptr_501 : index to i64
    %c0_i64_502 = arith.constant 0 : i64
    %cst_503 = arith.constant 0.00458907802 : f32
    %c0_i64_504 = arith.constant 0 : i64
    %c0_i64_505 = arith.constant 0 : i64
    %c0_i64_506 = arith.constant 0 : i64
    %c1_i64_507 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_483, %c62_i64, %c82_i64, %c32_i64_484, %c32_i64_485, %c60_i64_486, %c80_i64_487, %c1_i64_488, %c1_i64_489, %c1_i64_490, %c0_i64_491, %c3_i64_492, %c0_i64_493, %c0_i64_494, %c0_i64_495, %c0_i64_496, %c0_i64_497, %216, %217, %218, %219, %c0_i64_502, %cst_503, %c0_i64_504, %c0_i64_505, %c0_i64_506, %c1_i64_507) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_508 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_509 = memref.extract_aligned_pointer_as_index %alloc_508 : memref<1x60x80x32xf32> -> index
    %intptr_510 = memref.extract_aligned_pointer_as_index %alloc_482 : memref<4800x32xi8> -> index
    %220 = arith.index_cast %intptr_509 : index to i64
    %221 = arith.index_cast %intptr_510 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%220, %221, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_49) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_482 : memref<4800x32xi8>
    %alloc_511 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_508[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_511[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_512 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_511, %alloc_512 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_513 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_512[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %107[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_513[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_514 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_513[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_514[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_515 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_514[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_515[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_516 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_437[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_516[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_517 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_516[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %106[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_517[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_518 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_517[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_518[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_519 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_515[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_519[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_520 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_519[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %105[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_520[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_521 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_520[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_521[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_522 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_518[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %alloc_521[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_522[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_523 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_522[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_523[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_524 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_523[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_524[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_525 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_524[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_525[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_526 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_525[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_526[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_527 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_528 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_529 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_530 = memref.extract_aligned_pointer_as_index %alloc_526 : memref<1x60x80x32xi8> -> index
    %222 = arith.index_cast %intptr_530 : index to i64
    %intptr_531 = memref.extract_aligned_pointer_as_index %alloc_528 : memref<4800x32xi8> -> index
    %223 = arith.index_cast %intptr_531 : index to i64
    %intptr_532 = memref.extract_aligned_pointer_as_index %alloc_529 : memref<4800x32xi8> -> index
    %224 = arith.index_cast %intptr_532 : index to i64
    %intptr_533 = memref.extract_aligned_pointer_as_index %alloc_527 : memref<4800x32xi8> -> index
    %225 = arith.index_cast %intptr_533 : index to i64
    call @buddy_rvv_memcpy_i8(%223, %222, %c153600_i64) : (i64, i64, i64) -> ()
    %226 = arith.addi %223, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%226, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_534 = arith.constant 4800 : i64
    %c32_i64_535 = arith.constant 32 : i64
    %c32_i64_536 = arith.constant 32 : i64
    %intptr_537 = memref.extract_aligned_pointer_as_index %alloc_528 : memref<4800x32xi8> -> index
    %227 = arith.index_cast %intptr_537 : index to i64
    %intptr_538 = memref.extract_aligned_pointer_as_index %fwd_cst_22 : memref<32x32xi8> -> index
    %228 = arith.index_cast %intptr_538 : index to i64
    %intptr_539 = memref.extract_aligned_pointer_as_index %fwd_cst_23 : memref<4800x32xi32> -> index
    %229 = arith.index_cast %intptr_539 : index to i64
    %intptr_540 = memref.extract_aligned_pointer_as_index %alloc_529 : memref<4800x32xi8> -> index
    %230 = arith.index_cast %intptr_540 : index to i64
    %c32_i64_541 = arith.constant 32 : i64
    %c32_i64_542 = arith.constant 32 : i64
    %c32_i64_543 = arith.constant 32 : i64
    %c32_i64_544 = arith.constant 32 : i64
    %cst_545 = arith.constant 1.000000e+00 : f32
    %cst_546 = arith.constant 1.000000e+00 : f32
    %cst_547 = arith.constant 1.000000e+00 : f32
    %c0_i64_548 = arith.constant 0 : i64
    %cst_549 = arith.constant 0.0162679348 : f32
    %cst_550 = arith.constant 0.000000e+00 : f32
    %c0_i64_551 = arith.constant 0 : i64
    %c0_i64_552 = arith.constant 0 : i64
    %c0_i64_553 = arith.constant 0 : i64
    %c0_i64_554 = arith.constant 0 : i64
    %c0_i64_555 = arith.constant 0 : i64
    %c0_i64_556 = arith.constant 0 : i64
    %c1_i64_557 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_534, %c32_i64_535, %c32_i64_536, %227, %228, %229, %230, %c32_i64_541, %c32_i64_542, %c32_i64_543, %c32_i64_544, %cst_545, %cst_546, %cst_547, %c0_i64_548, %cst_549, %cst_550, %c0_i64_551, %c0_i64_552, %c0_i64_553, %c0_i64_554, %c0_i64_555, %c0_i64_556, %c1_i64_557) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%225, %224, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_528 : memref<4800x32xi8>
    memref.dealloc %alloc_529 : memref<4800x32xi8>
    %alloc_558 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_559 = memref.extract_aligned_pointer_as_index %alloc_558 : memref<1x60x80x32xf32> -> index
    %intptr_560 = memref.extract_aligned_pointer_as_index %alloc_527 : memref<4800x32xi8> -> index
    %231 = arith.index_cast %intptr_559 : index to i64
    %232 = arith.index_cast %intptr_560 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%231, %232, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_48) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_527 : memref<4800x32xi8>
    %alloc_561 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_558[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_561[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_562 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_561, %alloc_562 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_563 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_562[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %104[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_563[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_564 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_563[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_564[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_565 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_564[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_565[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_566 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_565[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_566[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_567 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_567[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_568 = memref.subview %alloc_567[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_566, %subview_568 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_569 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %fwd_cst_25[%arg160] : memref<32xi32>
            memref.store %793, %alloc_569[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_570 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %c1_i64_571 = arith.constant 1 : i64
    %c62_i64_572 = arith.constant 62 : i64
    %c82_i64_573 = arith.constant 82 : i64
    %c32_i64_574 = arith.constant 32 : i64
    %c32_i64_575 = arith.constant 32 : i64
    %c60_i64_576 = arith.constant 60 : i64
    %c80_i64_577 = arith.constant 80 : i64
    %c1_i64_578 = arith.constant 1 : i64
    %c1_i64_579 = arith.constant 1 : i64
    %c1_i64_580 = arith.constant 1 : i64
    %c0_i64_581 = arith.constant 0 : i64
    %c3_i64_582 = arith.constant 3 : i64
    %c0_i64_583 = arith.constant 0 : i64
    %c0_i64_584 = arith.constant 0 : i64
    %c0_i64_585 = arith.constant 0 : i64
    %c0_i64_586 = arith.constant 0 : i64
    %c0_i64_587 = arith.constant 0 : i64
    %intptr_588 = memref.extract_aligned_pointer_as_index %alloc_567 : memref<1x62x82x32xi8> -> index
    %233 = arith.index_cast %intptr_588 : index to i64
    %intptr_589 = memref.extract_aligned_pointer_as_index %fwd_cst_24 : memref<288x32xi8> -> index
    %234 = arith.index_cast %intptr_589 : index to i64
    %intptr_590 = memref.extract_aligned_pointer_as_index %fwd_cst_25 : memref<32xi32> -> index
    %235 = arith.index_cast %intptr_590 : index to i64
    %intptr_591 = memref.extract_aligned_pointer_as_index %alloc_570 : memref<4800x32xi8> -> index
    %236 = arith.index_cast %intptr_591 : index to i64
    %c0_i64_592 = arith.constant 0 : i64
    %cst_593 = arith.constant 0.00380956917 : f32
    %c0_i64_594 = arith.constant 0 : i64
    %c0_i64_595 = arith.constant 0 : i64
    %c0_i64_596 = arith.constant 0 : i64
    %c1_i64_597 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_571, %c62_i64_572, %c82_i64_573, %c32_i64_574, %c32_i64_575, %c60_i64_576, %c80_i64_577, %c1_i64_578, %c1_i64_579, %c1_i64_580, %c0_i64_581, %c3_i64_582, %c0_i64_583, %c0_i64_584, %c0_i64_585, %c0_i64_586, %c0_i64_587, %233, %234, %235, %236, %c0_i64_592, %cst_593, %c0_i64_594, %c0_i64_595, %c0_i64_596, %c1_i64_597) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_598 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_599 = memref.extract_aligned_pointer_as_index %alloc_598 : memref<1x60x80x32xf32> -> index
    %intptr_600 = memref.extract_aligned_pointer_as_index %alloc_570 : memref<4800x32xi8> -> index
    %237 = arith.index_cast %intptr_599 : index to i64
    %238 = arith.index_cast %intptr_600 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%237, %238, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_47) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_570 : memref<4800x32xi8>
    %alloc_601 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_598[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_601[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_602 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_601, %alloc_602 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_603 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_602[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %103[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_603[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_604 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_603[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_604[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_605 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_604[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_605[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_606 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_525[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_606[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_607 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_606[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %102[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_607[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_608 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_607[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_608[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_609 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_605[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_609[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_610 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_609[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %101[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_610[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_611 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_610[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_611[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_612 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_608[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %alloc_611[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_612[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_613 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_612[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_613[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_614 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_613[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_614[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_615 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_614[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_615[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_616 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_397[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_616[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_617 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_618 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_619 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_620 = memref.extract_aligned_pointer_as_index %alloc_616 : memref<1x60x80x64xi8> -> index
    %239 = arith.index_cast %intptr_620 : index to i64
    %intptr_621 = memref.extract_aligned_pointer_as_index %alloc_618 : memref<4800x64xi8> -> index
    %240 = arith.index_cast %intptr_621 : index to i64
    %intptr_622 = memref.extract_aligned_pointer_as_index %alloc_619 : memref<4800x32xi8> -> index
    %241 = arith.index_cast %intptr_622 : index to i64
    %intptr_623 = memref.extract_aligned_pointer_as_index %alloc_617 : memref<4800x32xi8> -> index
    %242 = arith.index_cast %intptr_623 : index to i64
    call @buddy_rvv_memcpy_i8(%240, %239, %c307200_i64) : (i64, i64, i64) -> ()
    %243 = arith.addi %240, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%243, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_624 = arith.constant 4800 : i64
    %c32_i64_625 = arith.constant 32 : i64
    %c64_i64_626 = arith.constant 64 : i64
    %intptr_627 = memref.extract_aligned_pointer_as_index %alloc_618 : memref<4800x64xi8> -> index
    %244 = arith.index_cast %intptr_627 : index to i64
    %intptr_628 = memref.extract_aligned_pointer_as_index %fwd_cst_26 : memref<64x32xi8> -> index
    %245 = arith.index_cast %intptr_628 : index to i64
    %intptr_629 = memref.extract_aligned_pointer_as_index %fwd_cst_27 : memref<4800x32xi32> -> index
    %246 = arith.index_cast %intptr_629 : index to i64
    %intptr_630 = memref.extract_aligned_pointer_as_index %alloc_619 : memref<4800x32xi8> -> index
    %247 = arith.index_cast %intptr_630 : index to i64
    %c64_i64_631 = arith.constant 64 : i64
    %c32_i64_632 = arith.constant 32 : i64
    %c32_i64_633 = arith.constant 32 : i64
    %c32_i64_634 = arith.constant 32 : i64
    %cst_635 = arith.constant 1.000000e+00 : f32
    %cst_636 = arith.constant 1.000000e+00 : f32
    %cst_637 = arith.constant 1.000000e+00 : f32
    %c0_i64_638 = arith.constant 0 : i64
    %cst_639 = arith.constant 0.0120223034 : f32
    %cst_640 = arith.constant 0.000000e+00 : f32
    %c0_i64_641 = arith.constant 0 : i64
    %c0_i64_642 = arith.constant 0 : i64
    %c0_i64_643 = arith.constant 0 : i64
    %c0_i64_644 = arith.constant 0 : i64
    %c0_i64_645 = arith.constant 0 : i64
    %c0_i64_646 = arith.constant 0 : i64
    %c1_i64_647 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_624, %c32_i64_625, %c64_i64_626, %244, %245, %246, %247, %c64_i64_631, %c32_i64_632, %c32_i64_633, %c32_i64_634, %cst_635, %cst_636, %cst_637, %c0_i64_638, %cst_639, %cst_640, %c0_i64_641, %c0_i64_642, %c0_i64_643, %c0_i64_644, %c0_i64_645, %c0_i64_646, %c1_i64_647) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%242, %241, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_618 : memref<4800x64xi8>
    memref.dealloc %alloc_619 : memref<4800x32xi8>
    %alloc_648 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_649 = memref.extract_aligned_pointer_as_index %alloc_648 : memref<1x60x80x32xf32> -> index
    %intptr_650 = memref.extract_aligned_pointer_as_index %alloc_617 : memref<4800x32xi8> -> index
    %248 = arith.index_cast %intptr_649 : index to i64
    %249 = arith.index_cast %intptr_650 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%248, %249, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_47) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_617 : memref<4800x32xi8>
    %alloc_651 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_648[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_651[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_652 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_651, %alloc_652 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_653 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_652[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %100[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_653[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_654 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_653[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_654[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_655 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_654[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_655[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_656 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_615[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_656[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_657 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_656[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %99[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_657[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_658 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_657[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_658[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_659 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_658[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_659[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_660 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_659[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_660[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_661 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_660[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_661[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_662 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_655[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_662[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_663 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_662[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %98[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_663[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_664 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_663[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_664[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_665 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_664[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_665[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_666 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_665[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_666[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_667 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_666[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_667[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_668 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_669 = memref.subview %alloc_668[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_661, %subview_669 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_670 = memref.subview %alloc_668[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_667, %subview_670 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_671 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_668[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_671[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_672 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_673 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_674 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_675 = memref.extract_aligned_pointer_as_index %alloc_671 : memref<1x60x80x64xi8> -> index
    %250 = arith.index_cast %intptr_675 : index to i64
    %intptr_676 = memref.extract_aligned_pointer_as_index %alloc_673 : memref<4800x64xi8> -> index
    %251 = arith.index_cast %intptr_676 : index to i64
    %intptr_677 = memref.extract_aligned_pointer_as_index %alloc_674 : memref<4800x64xi8> -> index
    %252 = arith.index_cast %intptr_677 : index to i64
    %intptr_678 = memref.extract_aligned_pointer_as_index %alloc_672 : memref<4800x64xi8> -> index
    %253 = arith.index_cast %intptr_678 : index to i64
    call @buddy_rvv_memcpy_i8(%251, %250, %c307200_i64) : (i64, i64, i64) -> ()
    %254 = arith.addi %251, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%254, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_679 = arith.constant 4800 : i64
    %c64_i64_680 = arith.constant 64 : i64
    %c64_i64_681 = arith.constant 64 : i64
    %intptr_682 = memref.extract_aligned_pointer_as_index %alloc_673 : memref<4800x64xi8> -> index
    %255 = arith.index_cast %intptr_682 : index to i64
    %intptr_683 = memref.extract_aligned_pointer_as_index %fwd_cst_28 : memref<64x64xi8> -> index
    %256 = arith.index_cast %intptr_683 : index to i64
    %intptr_684 = memref.extract_aligned_pointer_as_index %fwd_cst_29 : memref<4800x64xi32> -> index
    %257 = arith.index_cast %intptr_684 : index to i64
    %intptr_685 = memref.extract_aligned_pointer_as_index %alloc_674 : memref<4800x64xi8> -> index
    %258 = arith.index_cast %intptr_685 : index to i64
    %c64_i64_686 = arith.constant 64 : i64
    %c64_i64_687 = arith.constant 64 : i64
    %c64_i64_688 = arith.constant 64 : i64
    %c64_i64_689 = arith.constant 64 : i64
    %cst_690 = arith.constant 1.000000e+00 : f32
    %cst_691 = arith.constant 1.000000e+00 : f32
    %cst_692 = arith.constant 1.000000e+00 : f32
    %c0_i64_693 = arith.constant 0 : i64
    %cst_694 = arith.constant 0.0150127029 : f32
    %cst_695 = arith.constant 0.000000e+00 : f32
    %c0_i64_696 = arith.constant 0 : i64
    %c0_i64_697 = arith.constant 0 : i64
    %c0_i64_698 = arith.constant 0 : i64
    %c0_i64_699 = arith.constant 0 : i64
    %c0_i64_700 = arith.constant 0 : i64
    %c0_i64_701 = arith.constant 0 : i64
    %c1_i64_702 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_679, %c64_i64_680, %c64_i64_681, %255, %256, %257, %258, %c64_i64_686, %c64_i64_687, %c64_i64_688, %c64_i64_689, %cst_690, %cst_691, %cst_692, %c0_i64_693, %cst_694, %cst_695, %c0_i64_696, %c0_i64_697, %c0_i64_698, %c0_i64_699, %c0_i64_700, %c0_i64_701, %c1_i64_702) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%253, %252, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_673 : memref<4800x64xi8>
    memref.dealloc %alloc_674 : memref<4800x64xi8>
    %alloc_703 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_704 = memref.extract_aligned_pointer_as_index %alloc_703 : memref<1x60x80x64xf32> -> index
    %intptr_705 = memref.extract_aligned_pointer_as_index %alloc_672 : memref<4800x64xi8> -> index
    %259 = arith.index_cast %intptr_704 : index to i64
    %260 = arith.index_cast %intptr_705 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%259, %260, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_46) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_672 : memref<4800x64xi8>
    %alloc_706 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_703[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_706[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_707 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_706, %alloc_707 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_708 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_707[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = memref.load %97[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_708[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_709 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_708[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_709[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_710 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_709[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_710[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_711 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_710[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_711[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_712 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c61 step %c1 {
        scf.for %arg159 = %c0 to %c81 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_712[%arg157, %arg158, %arg159, %arg160] : memref<1x61x81x64xi8>
          }
        }
      }
    }
    %subview_713 = memref.subview %alloc_712[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_711, %subview_713 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_714 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %fwd_cst_31[%arg160] : memref<128xi32>
            memref.store %793, %alloc_714[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi32>
          }
        }
      }
    }
    %alloc_715 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %c1_i64_716 = arith.constant 1 : i64
    %c61_i64 = arith.constant 61 : i64
    %c81_i64 = arith.constant 81 : i64
    %c64_i64_717 = arith.constant 64 : i64
    %c128_i64_718 = arith.constant 128 : i64
    %c30_i64_719 = arith.constant 30 : i64
    %c40_i64_720 = arith.constant 40 : i64
    %c2_i64_721 = arith.constant 2 : i64
    %c1_i64_722 = arith.constant 1 : i64
    %c1_i64_723 = arith.constant 1 : i64
    %c0_i64_724 = arith.constant 0 : i64
    %c3_i64_725 = arith.constant 3 : i64
    %c0_i64_726 = arith.constant 0 : i64
    %c0_i64_727 = arith.constant 0 : i64
    %c0_i64_728 = arith.constant 0 : i64
    %c0_i64_729 = arith.constant 0 : i64
    %c0_i64_730 = arith.constant 0 : i64
    %intptr_731 = memref.extract_aligned_pointer_as_index %alloc_712 : memref<1x61x81x64xi8> -> index
    %261 = arith.index_cast %intptr_731 : index to i64
    %intptr_732 = memref.extract_aligned_pointer_as_index %fwd_cst_30 : memref<576x128xi8> -> index
    %262 = arith.index_cast %intptr_732 : index to i64
    %intptr_733 = memref.extract_aligned_pointer_as_index %fwd_cst_31 : memref<128xi32> -> index
    %263 = arith.index_cast %intptr_733 : index to i64
    %intptr_734 = memref.extract_aligned_pointer_as_index %alloc_715 : memref<1200x128xi8> -> index
    %264 = arith.index_cast %intptr_734 : index to i64
    %c0_i64_735 = arith.constant 0 : i64
    %cst_736 = arith.constant 0.0122586582 : f32
    %c0_i64_737 = arith.constant 0 : i64
    %c0_i64_738 = arith.constant 0 : i64
    %c0_i64_739 = arith.constant 0 : i64
    %c1_i64_740 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_716, %c61_i64, %c81_i64, %c64_i64_717, %c128_i64_718, %c30_i64_719, %c40_i64_720, %c2_i64_721, %c1_i64_722, %c1_i64_723, %c0_i64_724, %c3_i64_725, %c0_i64_726, %c0_i64_727, %c0_i64_728, %c0_i64_729, %c0_i64_730, %261, %262, %263, %264, %c0_i64_735, %cst_736, %c0_i64_737, %c0_i64_738, %c0_i64_739, %c1_i64_740) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_741 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_742 = memref.extract_aligned_pointer_as_index %alloc_741 : memref<1x30x40x128xf32> -> index
    %intptr_743 = memref.extract_aligned_pointer_as_index %alloc_715 : memref<1200x128xi8> -> index
    %265 = arith.index_cast %intptr_742 : index to i64
    %266 = arith.index_cast %intptr_743 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%265, %266, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_45) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_715 : memref<1200x128xi8>
    %alloc_744 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_741[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x128xf32>
            memref.store %793, %alloc_744[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_745 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_744, %alloc_745 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_746 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_745[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = memref.load %96[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_746[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_747 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_746[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_747[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_748 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_747[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_748[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_749 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_748[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_749[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_750 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_751 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_752 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_753 = memref.extract_aligned_pointer_as_index %alloc_749 : memref<1x30x40x128xi8> -> index
    %267 = arith.index_cast %intptr_753 : index to i64
    %intptr_754 = memref.extract_aligned_pointer_as_index %alloc_751 : memref<1200x128xi8> -> index
    %268 = arith.index_cast %intptr_754 : index to i64
    %intptr_755 = memref.extract_aligned_pointer_as_index %alloc_752 : memref<1200x64xi8> -> index
    %269 = arith.index_cast %intptr_755 : index to i64
    %intptr_756 = memref.extract_aligned_pointer_as_index %alloc_750 : memref<1200x64xi8> -> index
    %270 = arith.index_cast %intptr_756 : index to i64
    call @buddy_rvv_memcpy_i8(%268, %267, %c153600_i64) : (i64, i64, i64) -> ()
    %271 = arith.addi %268, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%271, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_757 = arith.constant 1200 : i64
    %c64_i64_758 = arith.constant 64 : i64
    %c128_i64_759 = arith.constant 128 : i64
    %intptr_760 = memref.extract_aligned_pointer_as_index %alloc_751 : memref<1200x128xi8> -> index
    %272 = arith.index_cast %intptr_760 : index to i64
    %intptr_761 = memref.extract_aligned_pointer_as_index %fwd_cst_32 : memref<128x64xi8> -> index
    %273 = arith.index_cast %intptr_761 : index to i64
    %intptr_762 = memref.extract_aligned_pointer_as_index %fwd_cst_33 : memref<1200x64xi32> -> index
    %274 = arith.index_cast %intptr_762 : index to i64
    %intptr_763 = memref.extract_aligned_pointer_as_index %alloc_752 : memref<1200x64xi8> -> index
    %275 = arith.index_cast %intptr_763 : index to i64
    %c128_i64_764 = arith.constant 128 : i64
    %c64_i64_765 = arith.constant 64 : i64
    %c64_i64_766 = arith.constant 64 : i64
    %c64_i64_767 = arith.constant 64 : i64
    %cst_768 = arith.constant 1.000000e+00 : f32
    %cst_769 = arith.constant 1.000000e+00 : f32
    %cst_770 = arith.constant 1.000000e+00 : f32
    %c0_i64_771 = arith.constant 0 : i64
    %cst_772 = arith.constant 0.0189360213 : f32
    %cst_773 = arith.constant 0.000000e+00 : f32
    %c0_i64_774 = arith.constant 0 : i64
    %c0_i64_775 = arith.constant 0 : i64
    %c0_i64_776 = arith.constant 0 : i64
    %c0_i64_777 = arith.constant 0 : i64
    %c0_i64_778 = arith.constant 0 : i64
    %c0_i64_779 = arith.constant 0 : i64
    %c1_i64_780 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_757, %c64_i64_758, %c128_i64_759, %272, %273, %274, %275, %c128_i64_764, %c64_i64_765, %c64_i64_766, %c64_i64_767, %cst_768, %cst_769, %cst_770, %c0_i64_771, %cst_772, %cst_773, %c0_i64_774, %c0_i64_775, %c0_i64_776, %c0_i64_777, %c0_i64_778, %c0_i64_779, %c1_i64_780) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%270, %269, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_751 : memref<1200x128xi8>
    memref.dealloc %alloc_752 : memref<1200x64xi8>
    %alloc_781 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_782 = memref.extract_aligned_pointer_as_index %alloc_781 : memref<1x30x40x64xf32> -> index
    %intptr_783 = memref.extract_aligned_pointer_as_index %alloc_750 : memref<1200x64xi8> -> index
    %276 = arith.index_cast %intptr_782 : index to i64
    %277 = arith.index_cast %intptr_783 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%276, %277, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_44) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_750 : memref<1200x64xi8>
    %alloc_784 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_781[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_784[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_785 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_784, %alloc_785 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_786 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_785[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %95[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_786[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_787 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_786[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_787[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_788 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_787[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_788[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_789 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_788[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_789[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_790 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_791 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_792 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_793 = memref.extract_aligned_pointer_as_index %alloc_789 : memref<1x30x40x64xi8> -> index
    %278 = arith.index_cast %intptr_793 : index to i64
    %intptr_794 = memref.extract_aligned_pointer_as_index %alloc_791 : memref<1200x64xi8> -> index
    %279 = arith.index_cast %intptr_794 : index to i64
    %intptr_795 = memref.extract_aligned_pointer_as_index %alloc_792 : memref<1200x64xi8> -> index
    %280 = arith.index_cast %intptr_795 : index to i64
    %intptr_796 = memref.extract_aligned_pointer_as_index %alloc_790 : memref<1200x64xi8> -> index
    %281 = arith.index_cast %intptr_796 : index to i64
    call @buddy_rvv_memcpy_i8(%279, %278, %c76800_i64) : (i64, i64, i64) -> ()
    %282 = arith.addi %279, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%282, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_797 = arith.constant 1200 : i64
    %c64_i64_798 = arith.constant 64 : i64
    %c64_i64_799 = arith.constant 64 : i64
    %intptr_800 = memref.extract_aligned_pointer_as_index %alloc_791 : memref<1200x64xi8> -> index
    %283 = arith.index_cast %intptr_800 : index to i64
    %intptr_801 = memref.extract_aligned_pointer_as_index %fwd_cst_34 : memref<64x64xi8> -> index
    %284 = arith.index_cast %intptr_801 : index to i64
    %intptr_802 = memref.extract_aligned_pointer_as_index %fwd_cst_35 : memref<1200x64xi32> -> index
    %285 = arith.index_cast %intptr_802 : index to i64
    %intptr_803 = memref.extract_aligned_pointer_as_index %alloc_792 : memref<1200x64xi8> -> index
    %286 = arith.index_cast %intptr_803 : index to i64
    %c64_i64_804 = arith.constant 64 : i64
    %c64_i64_805 = arith.constant 64 : i64
    %c64_i64_806 = arith.constant 64 : i64
    %c64_i64_807 = arith.constant 64 : i64
    %cst_808 = arith.constant 1.000000e+00 : f32
    %cst_809 = arith.constant 1.000000e+00 : f32
    %cst_810 = arith.constant 1.000000e+00 : f32
    %c0_i64_811 = arith.constant 0 : i64
    %cst_812 = arith.constant 0.0145288706 : f32
    %cst_813 = arith.constant 0.000000e+00 : f32
    %c0_i64_814 = arith.constant 0 : i64
    %c0_i64_815 = arith.constant 0 : i64
    %c0_i64_816 = arith.constant 0 : i64
    %c0_i64_817 = arith.constant 0 : i64
    %c0_i64_818 = arith.constant 0 : i64
    %c0_i64_819 = arith.constant 0 : i64
    %c1_i64_820 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_797, %c64_i64_798, %c64_i64_799, %283, %284, %285, %286, %c64_i64_804, %c64_i64_805, %c64_i64_806, %c64_i64_807, %cst_808, %cst_809, %cst_810, %c0_i64_811, %cst_812, %cst_813, %c0_i64_814, %c0_i64_815, %c0_i64_816, %c0_i64_817, %c0_i64_818, %c0_i64_819, %c1_i64_820) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%281, %280, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_791 : memref<1200x64xi8>
    memref.dealloc %alloc_792 : memref<1200x64xi8>
    %alloc_821 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_822 = memref.extract_aligned_pointer_as_index %alloc_821 : memref<1x30x40x64xf32> -> index
    %intptr_823 = memref.extract_aligned_pointer_as_index %alloc_790 : memref<1200x64xi8> -> index
    %287 = arith.index_cast %intptr_822 : index to i64
    %288 = arith.index_cast %intptr_823 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%287, %288, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_43) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_790 : memref<1200x64xi8>
    %alloc_824 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_821[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_824[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_825 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_824, %alloc_825 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_826 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_825[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %94[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_826[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_827 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_826[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_827[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_828 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_827[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_828[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_829 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_828[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_829[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_830 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_830[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_831 = memref.subview %alloc_830[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_829, %subview_831 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_832 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_37[%arg160] : memref<64xi32>
            memref.store %793, %alloc_832[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_833 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_834 = arith.constant 1 : i64
    %c32_i64_835 = arith.constant 32 : i64
    %c42_i64 = arith.constant 42 : i64
    %c64_i64_836 = arith.constant 64 : i64
    %c64_i64_837 = arith.constant 64 : i64
    %c30_i64_838 = arith.constant 30 : i64
    %c40_i64_839 = arith.constant 40 : i64
    %c1_i64_840 = arith.constant 1 : i64
    %c1_i64_841 = arith.constant 1 : i64
    %c1_i64_842 = arith.constant 1 : i64
    %c0_i64_843 = arith.constant 0 : i64
    %c3_i64_844 = arith.constant 3 : i64
    %c0_i64_845 = arith.constant 0 : i64
    %c0_i64_846 = arith.constant 0 : i64
    %c0_i64_847 = arith.constant 0 : i64
    %c0_i64_848 = arith.constant 0 : i64
    %c0_i64_849 = arith.constant 0 : i64
    %intptr_850 = memref.extract_aligned_pointer_as_index %alloc_830 : memref<1x32x42x64xi8> -> index
    %289 = arith.index_cast %intptr_850 : index to i64
    %intptr_851 = memref.extract_aligned_pointer_as_index %fwd_cst_36 : memref<576x64xi8> -> index
    %290 = arith.index_cast %intptr_851 : index to i64
    %intptr_852 = memref.extract_aligned_pointer_as_index %fwd_cst_37 : memref<64xi32> -> index
    %291 = arith.index_cast %intptr_852 : index to i64
    %intptr_853 = memref.extract_aligned_pointer_as_index %alloc_833 : memref<1200x64xi8> -> index
    %292 = arith.index_cast %intptr_853 : index to i64
    %c0_i64_854 = arith.constant 0 : i64
    %cst_855 = arith.constant 0.00607879459 : f32
    %c0_i64_856 = arith.constant 0 : i64
    %c0_i64_857 = arith.constant 0 : i64
    %c0_i64_858 = arith.constant 0 : i64
    %c1_i64_859 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_834, %c32_i64_835, %c42_i64, %c64_i64_836, %c64_i64_837, %c30_i64_838, %c40_i64_839, %c1_i64_840, %c1_i64_841, %c1_i64_842, %c0_i64_843, %c3_i64_844, %c0_i64_845, %c0_i64_846, %c0_i64_847, %c0_i64_848, %c0_i64_849, %289, %290, %291, %292, %c0_i64_854, %cst_855, %c0_i64_856, %c0_i64_857, %c0_i64_858, %c1_i64_859) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_860 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_861 = memref.extract_aligned_pointer_as_index %alloc_860 : memref<1x30x40x64xf32> -> index
    %intptr_862 = memref.extract_aligned_pointer_as_index %alloc_833 : memref<1200x64xi8> -> index
    %293 = arith.index_cast %intptr_861 : index to i64
    %294 = arith.index_cast %intptr_862 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%293, %294, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_42) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_833 : memref<1200x64xi8>
    %alloc_863 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_860[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_863[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_864 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_863, %alloc_864 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_865 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_864[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %93[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_865[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_866 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_865[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_866[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_867 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_866[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_867[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_868 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_788[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_868[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_869 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_868[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %92[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_869[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_870 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_869[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_870[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_871 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_867[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_871[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_872 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_871[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %91[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_872[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_873 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_872[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_873[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_874 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_870[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %alloc_873[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_874[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_875 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_874[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_875[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_876 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_875[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_876[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_877 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_876[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_877[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_878 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_877[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_878[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_879 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_880 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_881 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_882 = memref.extract_aligned_pointer_as_index %alloc_878 : memref<1x30x40x64xi8> -> index
    %295 = arith.index_cast %intptr_882 : index to i64
    %intptr_883 = memref.extract_aligned_pointer_as_index %alloc_880 : memref<1200x64xi8> -> index
    %296 = arith.index_cast %intptr_883 : index to i64
    %intptr_884 = memref.extract_aligned_pointer_as_index %alloc_881 : memref<1200x64xi8> -> index
    %297 = arith.index_cast %intptr_884 : index to i64
    %intptr_885 = memref.extract_aligned_pointer_as_index %alloc_879 : memref<1200x64xi8> -> index
    %298 = arith.index_cast %intptr_885 : index to i64
    call @buddy_rvv_memcpy_i8(%296, %295, %c76800_i64) : (i64, i64, i64) -> ()
    %299 = arith.addi %296, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%299, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_886 = arith.constant 1200 : i64
    %c64_i64_887 = arith.constant 64 : i64
    %c64_i64_888 = arith.constant 64 : i64
    %intptr_889 = memref.extract_aligned_pointer_as_index %alloc_880 : memref<1200x64xi8> -> index
    %300 = arith.index_cast %intptr_889 : index to i64
    %intptr_890 = memref.extract_aligned_pointer_as_index %fwd_cst_38 : memref<64x64xi8> -> index
    %301 = arith.index_cast %intptr_890 : index to i64
    %intptr_891 = memref.extract_aligned_pointer_as_index %fwd_cst_39 : memref<1200x64xi32> -> index
    %302 = arith.index_cast %intptr_891 : index to i64
    %intptr_892 = memref.extract_aligned_pointer_as_index %alloc_881 : memref<1200x64xi8> -> index
    %303 = arith.index_cast %intptr_892 : index to i64
    %c64_i64_893 = arith.constant 64 : i64
    %c64_i64_894 = arith.constant 64 : i64
    %c64_i64_895 = arith.constant 64 : i64
    %c64_i64_896 = arith.constant 64 : i64
    %cst_897 = arith.constant 1.000000e+00 : f32
    %cst_898 = arith.constant 1.000000e+00 : f32
    %cst_899 = arith.constant 1.000000e+00 : f32
    %c0_i64_900 = arith.constant 0 : i64
    %cst_901 = arith.constant 0.00671094796 : f32
    %cst_902 = arith.constant 0.000000e+00 : f32
    %c0_i64_903 = arith.constant 0 : i64
    %c0_i64_904 = arith.constant 0 : i64
    %c0_i64_905 = arith.constant 0 : i64
    %c0_i64_906 = arith.constant 0 : i64
    %c0_i64_907 = arith.constant 0 : i64
    %c0_i64_908 = arith.constant 0 : i64
    %c1_i64_909 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_886, %c64_i64_887, %c64_i64_888, %300, %301, %302, %303, %c64_i64_893, %c64_i64_894, %c64_i64_895, %c64_i64_896, %cst_897, %cst_898, %cst_899, %c0_i64_900, %cst_901, %cst_902, %c0_i64_903, %c0_i64_904, %c0_i64_905, %c0_i64_906, %c0_i64_907, %c0_i64_908, %c1_i64_909) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%298, %297, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_880 : memref<1200x64xi8>
    memref.dealloc %alloc_881 : memref<1200x64xi8>
    %alloc_910 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_911 = memref.extract_aligned_pointer_as_index %alloc_910 : memref<1x30x40x64xf32> -> index
    %intptr_912 = memref.extract_aligned_pointer_as_index %alloc_879 : memref<1200x64xi8> -> index
    %304 = arith.index_cast %intptr_911 : index to i64
    %305 = arith.index_cast %intptr_912 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%304, %305, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_41) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_879 : memref<1200x64xi8>
    %alloc_913 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_910[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_913[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_914 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_913, %alloc_914 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_915 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_914[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %90[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_915[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_916 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_915[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_916[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_917 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_916[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_917[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_918 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_917[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_918[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_919 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_919[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_920 = memref.subview %alloc_919[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_918, %subview_920 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_921 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_41[%arg160] : memref<64xi32>
            memref.store %793, %alloc_921[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_922 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_923 = arith.constant 1 : i64
    %c32_i64_924 = arith.constant 32 : i64
    %c42_i64_925 = arith.constant 42 : i64
    %c64_i64_926 = arith.constant 64 : i64
    %c64_i64_927 = arith.constant 64 : i64
    %c30_i64_928 = arith.constant 30 : i64
    %c40_i64_929 = arith.constant 40 : i64
    %c1_i64_930 = arith.constant 1 : i64
    %c1_i64_931 = arith.constant 1 : i64
    %c1_i64_932 = arith.constant 1 : i64
    %c0_i64_933 = arith.constant 0 : i64
    %c3_i64_934 = arith.constant 3 : i64
    %c0_i64_935 = arith.constant 0 : i64
    %c0_i64_936 = arith.constant 0 : i64
    %c0_i64_937 = arith.constant 0 : i64
    %c0_i64_938 = arith.constant 0 : i64
    %c0_i64_939 = arith.constant 0 : i64
    %intptr_940 = memref.extract_aligned_pointer_as_index %alloc_919 : memref<1x32x42x64xi8> -> index
    %306 = arith.index_cast %intptr_940 : index to i64
    %intptr_941 = memref.extract_aligned_pointer_as_index %fwd_cst_40 : memref<576x64xi8> -> index
    %307 = arith.index_cast %intptr_941 : index to i64
    %intptr_942 = memref.extract_aligned_pointer_as_index %fwd_cst_41 : memref<64xi32> -> index
    %308 = arith.index_cast %intptr_942 : index to i64
    %intptr_943 = memref.extract_aligned_pointer_as_index %alloc_922 : memref<1200x64xi8> -> index
    %309 = arith.index_cast %intptr_943 : index to i64
    %c0_i64_944 = arith.constant 0 : i64
    %cst_945 = arith.constant 0.00729554053 : f32
    %c0_i64_946 = arith.constant 0 : i64
    %c0_i64_947 = arith.constant 0 : i64
    %c0_i64_948 = arith.constant 0 : i64
    %c1_i64_949 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_923, %c32_i64_924, %c42_i64_925, %c64_i64_926, %c64_i64_927, %c30_i64_928, %c40_i64_929, %c1_i64_930, %c1_i64_931, %c1_i64_932, %c0_i64_933, %c3_i64_934, %c0_i64_935, %c0_i64_936, %c0_i64_937, %c0_i64_938, %c0_i64_939, %306, %307, %308, %309, %c0_i64_944, %cst_945, %c0_i64_946, %c0_i64_947, %c0_i64_948, %c1_i64_949) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_950 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_951 = memref.extract_aligned_pointer_as_index %alloc_950 : memref<1x30x40x64xf32> -> index
    %intptr_952 = memref.extract_aligned_pointer_as_index %alloc_922 : memref<1200x64xi8> -> index
    %310 = arith.index_cast %intptr_951 : index to i64
    %311 = arith.index_cast %intptr_952 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%310, %311, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_40) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_922 : memref<1200x64xi8>
    %alloc_953 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_950[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_953[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_954 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_953, %alloc_954 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_955 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_954[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %89[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_955[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_956 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_955[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_956[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_957 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_956[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_957[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_958 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_877[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_958[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_959 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_958[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %88[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_959[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_960 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_959[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_960[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_961 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_957[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_961[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_962 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_961[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %87[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_962[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_963 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_962[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_963[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_964 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_960[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %alloc_963[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_964[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_965 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_964[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_965[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_966 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_965[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_966[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_967 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_966[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_967[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_968 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_967[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_968[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_969 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_970 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_971 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_972 = memref.extract_aligned_pointer_as_index %alloc_968 : memref<1x30x40x64xi8> -> index
    %312 = arith.index_cast %intptr_972 : index to i64
    %intptr_973 = memref.extract_aligned_pointer_as_index %alloc_970 : memref<1200x64xi8> -> index
    %313 = arith.index_cast %intptr_973 : index to i64
    %intptr_974 = memref.extract_aligned_pointer_as_index %alloc_971 : memref<1200x64xi8> -> index
    %314 = arith.index_cast %intptr_974 : index to i64
    %intptr_975 = memref.extract_aligned_pointer_as_index %alloc_969 : memref<1200x64xi8> -> index
    %315 = arith.index_cast %intptr_975 : index to i64
    call @buddy_rvv_memcpy_i8(%313, %312, %c76800_i64) : (i64, i64, i64) -> ()
    %316 = arith.addi %313, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%316, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_976 = arith.constant 1200 : i64
    %c64_i64_977 = arith.constant 64 : i64
    %c64_i64_978 = arith.constant 64 : i64
    %intptr_979 = memref.extract_aligned_pointer_as_index %alloc_970 : memref<1200x64xi8> -> index
    %317 = arith.index_cast %intptr_979 : index to i64
    %intptr_980 = memref.extract_aligned_pointer_as_index %fwd_cst_42 : memref<64x64xi8> -> index
    %318 = arith.index_cast %intptr_980 : index to i64
    %intptr_981 = memref.extract_aligned_pointer_as_index %fwd_cst_43 : memref<1200x64xi32> -> index
    %319 = arith.index_cast %intptr_981 : index to i64
    %intptr_982 = memref.extract_aligned_pointer_as_index %alloc_971 : memref<1200x64xi8> -> index
    %320 = arith.index_cast %intptr_982 : index to i64
    %c64_i64_983 = arith.constant 64 : i64
    %c64_i64_984 = arith.constant 64 : i64
    %c64_i64_985 = arith.constant 64 : i64
    %c64_i64_986 = arith.constant 64 : i64
    %cst_987 = arith.constant 1.000000e+00 : f32
    %cst_988 = arith.constant 1.000000e+00 : f32
    %cst_989 = arith.constant 1.000000e+00 : f32
    %c0_i64_990 = arith.constant 0 : i64
    %cst_991 = arith.constant 0.0123461829 : f32
    %cst_992 = arith.constant 0.000000e+00 : f32
    %c0_i64_993 = arith.constant 0 : i64
    %c0_i64_994 = arith.constant 0 : i64
    %c0_i64_995 = arith.constant 0 : i64
    %c0_i64_996 = arith.constant 0 : i64
    %c0_i64_997 = arith.constant 0 : i64
    %c0_i64_998 = arith.constant 0 : i64
    %c1_i64_999 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_976, %c64_i64_977, %c64_i64_978, %317, %318, %319, %320, %c64_i64_983, %c64_i64_984, %c64_i64_985, %c64_i64_986, %cst_987, %cst_988, %cst_989, %c0_i64_990, %cst_991, %cst_992, %c0_i64_993, %c0_i64_994, %c0_i64_995, %c0_i64_996, %c0_i64_997, %c0_i64_998, %c1_i64_999) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%315, %314, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_970 : memref<1200x64xi8>
    memref.dealloc %alloc_971 : memref<1200x64xi8>
    %alloc_1000 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1001 = memref.extract_aligned_pointer_as_index %alloc_1000 : memref<1x30x40x64xf32> -> index
    %intptr_1002 = memref.extract_aligned_pointer_as_index %alloc_969 : memref<1200x64xi8> -> index
    %321 = arith.index_cast %intptr_1001 : index to i64
    %322 = arith.index_cast %intptr_1002 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%321, %322, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_39) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_969 : memref<1200x64xi8>
    %alloc_1003 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1000[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1003[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1004 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1003, %alloc_1004 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1005 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1004[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %86[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1005[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1006 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1005[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1006[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1007 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1006[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1007[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1008 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_1007[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_1008[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1009 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1009[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_1010 = memref.subview %alloc_1009[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_1008, %subview_1010 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_1011 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_45[%arg160] : memref<64xi32>
            memref.store %793, %alloc_1011[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_1012 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_1013 = arith.constant 1 : i64
    %c32_i64_1014 = arith.constant 32 : i64
    %c42_i64_1015 = arith.constant 42 : i64
    %c64_i64_1016 = arith.constant 64 : i64
    %c64_i64_1017 = arith.constant 64 : i64
    %c30_i64_1018 = arith.constant 30 : i64
    %c40_i64_1019 = arith.constant 40 : i64
    %c1_i64_1020 = arith.constant 1 : i64
    %c1_i64_1021 = arith.constant 1 : i64
    %c1_i64_1022 = arith.constant 1 : i64
    %c0_i64_1023 = arith.constant 0 : i64
    %c3_i64_1024 = arith.constant 3 : i64
    %c0_i64_1025 = arith.constant 0 : i64
    %c0_i64_1026 = arith.constant 0 : i64
    %c0_i64_1027 = arith.constant 0 : i64
    %c0_i64_1028 = arith.constant 0 : i64
    %c0_i64_1029 = arith.constant 0 : i64
    %intptr_1030 = memref.extract_aligned_pointer_as_index %alloc_1009 : memref<1x32x42x64xi8> -> index
    %323 = arith.index_cast %intptr_1030 : index to i64
    %intptr_1031 = memref.extract_aligned_pointer_as_index %fwd_cst_44 : memref<576x64xi8> -> index
    %324 = arith.index_cast %intptr_1031 : index to i64
    %intptr_1032 = memref.extract_aligned_pointer_as_index %fwd_cst_45 : memref<64xi32> -> index
    %325 = arith.index_cast %intptr_1032 : index to i64
    %intptr_1033 = memref.extract_aligned_pointer_as_index %alloc_1012 : memref<1200x64xi8> -> index
    %326 = arith.index_cast %intptr_1033 : index to i64
    %c0_i64_1034 = arith.constant 0 : i64
    %cst_1035 = arith.constant 0.00430227118 : f32
    %c0_i64_1036 = arith.constant 0 : i64
    %c0_i64_1037 = arith.constant 0 : i64
    %c0_i64_1038 = arith.constant 0 : i64
    %c1_i64_1039 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_1013, %c32_i64_1014, %c42_i64_1015, %c64_i64_1016, %c64_i64_1017, %c30_i64_1018, %c40_i64_1019, %c1_i64_1020, %c1_i64_1021, %c1_i64_1022, %c0_i64_1023, %c3_i64_1024, %c0_i64_1025, %c0_i64_1026, %c0_i64_1027, %c0_i64_1028, %c0_i64_1029, %323, %324, %325, %326, %c0_i64_1034, %cst_1035, %c0_i64_1036, %c0_i64_1037, %c0_i64_1038, %c1_i64_1039) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_1040 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1041 = memref.extract_aligned_pointer_as_index %alloc_1040 : memref<1x30x40x64xf32> -> index
    %intptr_1042 = memref.extract_aligned_pointer_as_index %alloc_1012 : memref<1200x64xi8> -> index
    %327 = arith.index_cast %intptr_1041 : index to i64
    %328 = arith.index_cast %intptr_1042 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%327, %328, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_38) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1012 : memref<1200x64xi8>
    %alloc_1043 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1040[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1043[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1044 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1043, %alloc_1044 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1045 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1044[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %85[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1045[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1046 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1045[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1046[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1047 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1046[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1047[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1048 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_967[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1048[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1049 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1048[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %84[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1049[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1050 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1049[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1050[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1051 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1047[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1051[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1052 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1051[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %83[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1052[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1053 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1052[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1053[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1054 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1050[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %alloc_1053[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_1054[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1055 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1054[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1055[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1056 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1055[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1056[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1057 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1056[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1057[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1058 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_748[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_1058[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1059 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1060 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1061 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1062 = memref.extract_aligned_pointer_as_index %alloc_1058 : memref<1x30x40x128xi8> -> index
    %329 = arith.index_cast %intptr_1062 : index to i64
    %intptr_1063 = memref.extract_aligned_pointer_as_index %alloc_1060 : memref<1200x128xi8> -> index
    %330 = arith.index_cast %intptr_1063 : index to i64
    %intptr_1064 = memref.extract_aligned_pointer_as_index %alloc_1061 : memref<1200x64xi8> -> index
    %331 = arith.index_cast %intptr_1064 : index to i64
    %intptr_1065 = memref.extract_aligned_pointer_as_index %alloc_1059 : memref<1200x64xi8> -> index
    %332 = arith.index_cast %intptr_1065 : index to i64
    call @buddy_rvv_memcpy_i8(%330, %329, %c153600_i64) : (i64, i64, i64) -> ()
    %333 = arith.addi %330, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%333, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1066 = arith.constant 1200 : i64
    %c64_i64_1067 = arith.constant 64 : i64
    %c128_i64_1068 = arith.constant 128 : i64
    %intptr_1069 = memref.extract_aligned_pointer_as_index %alloc_1060 : memref<1200x128xi8> -> index
    %334 = arith.index_cast %intptr_1069 : index to i64
    %intptr_1070 = memref.extract_aligned_pointer_as_index %fwd_cst_46 : memref<128x64xi8> -> index
    %335 = arith.index_cast %intptr_1070 : index to i64
    %intptr_1071 = memref.extract_aligned_pointer_as_index %fwd_cst_47 : memref<1200x64xi32> -> index
    %336 = arith.index_cast %intptr_1071 : index to i64
    %intptr_1072 = memref.extract_aligned_pointer_as_index %alloc_1061 : memref<1200x64xi8> -> index
    %337 = arith.index_cast %intptr_1072 : index to i64
    %c128_i64_1073 = arith.constant 128 : i64
    %c64_i64_1074 = arith.constant 64 : i64
    %c64_i64_1075 = arith.constant 64 : i64
    %c64_i64_1076 = arith.constant 64 : i64
    %cst_1077 = arith.constant 1.000000e+00 : f32
    %cst_1078 = arith.constant 1.000000e+00 : f32
    %cst_1079 = arith.constant 1.000000e+00 : f32
    %c0_i64_1080 = arith.constant 0 : i64
    %cst_1081 = arith.constant 0.00847221724 : f32
    %cst_1082 = arith.constant 0.000000e+00 : f32
    %c0_i64_1083 = arith.constant 0 : i64
    %c0_i64_1084 = arith.constant 0 : i64
    %c0_i64_1085 = arith.constant 0 : i64
    %c0_i64_1086 = arith.constant 0 : i64
    %c0_i64_1087 = arith.constant 0 : i64
    %c0_i64_1088 = arith.constant 0 : i64
    %c1_i64_1089 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1066, %c64_i64_1067, %c128_i64_1068, %334, %335, %336, %337, %c128_i64_1073, %c64_i64_1074, %c64_i64_1075, %c64_i64_1076, %cst_1077, %cst_1078, %cst_1079, %c0_i64_1080, %cst_1081, %cst_1082, %c0_i64_1083, %c0_i64_1084, %c0_i64_1085, %c0_i64_1086, %c0_i64_1087, %c0_i64_1088, %c1_i64_1089) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%332, %331, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1060 : memref<1200x128xi8>
    memref.dealloc %alloc_1061 : memref<1200x64xi8>
    %alloc_1090 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1091 = memref.extract_aligned_pointer_as_index %alloc_1090 : memref<1x30x40x64xf32> -> index
    %intptr_1092 = memref.extract_aligned_pointer_as_index %alloc_1059 : memref<1200x64xi8> -> index
    %338 = arith.index_cast %intptr_1091 : index to i64
    %339 = arith.index_cast %intptr_1092 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%338, %339, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_38) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1059 : memref<1200x64xi8>
    %alloc_1093 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1090[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1093[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1094 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1093, %alloc_1094 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1095 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1094[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %82[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1095[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1096 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1095[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1096[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1097 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1096[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1097[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1098 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1057[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1098[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1099 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1098[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %81[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1099[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1100 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1099[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1100[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1101 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1100[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1101[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1102 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1101[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1102[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1103 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1102[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1103[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1104 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1097[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1104[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1105 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1104[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1105[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1106 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1105[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1106[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1107 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1106[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1107[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1108 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_1109 = memref.subview %alloc_1108[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_1103, %subview_1109 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_1110 = memref.subview %alloc_1108[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_1107, %subview_1110 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_1111 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1108[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_1111[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1112 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1113 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1114 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_1115 = memref.extract_aligned_pointer_as_index %alloc_1111 : memref<1x30x40x128xi8> -> index
    %340 = arith.index_cast %intptr_1115 : index to i64
    %intptr_1116 = memref.extract_aligned_pointer_as_index %alloc_1113 : memref<1200x128xi8> -> index
    %341 = arith.index_cast %intptr_1116 : index to i64
    %intptr_1117 = memref.extract_aligned_pointer_as_index %alloc_1114 : memref<1200x128xi8> -> index
    %342 = arith.index_cast %intptr_1117 : index to i64
    %intptr_1118 = memref.extract_aligned_pointer_as_index %alloc_1112 : memref<1200x128xi8> -> index
    %343 = arith.index_cast %intptr_1118 : index to i64
    call @buddy_rvv_memcpy_i8(%341, %340, %c153600_i64) : (i64, i64, i64) -> ()
    %344 = arith.addi %341, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%344, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1119 = arith.constant 1200 : i64
    %c128_i64_1120 = arith.constant 128 : i64
    %c128_i64_1121 = arith.constant 128 : i64
    %intptr_1122 = memref.extract_aligned_pointer_as_index %alloc_1113 : memref<1200x128xi8> -> index
    %345 = arith.index_cast %intptr_1122 : index to i64
    %intptr_1123 = memref.extract_aligned_pointer_as_index %fwd_cst_48 : memref<128x128xi8> -> index
    %346 = arith.index_cast %intptr_1123 : index to i64
    %intptr_1124 = memref.extract_aligned_pointer_as_index %fwd_cst_49 : memref<1200x128xi32> -> index
    %347 = arith.index_cast %intptr_1124 : index to i64
    %intptr_1125 = memref.extract_aligned_pointer_as_index %alloc_1114 : memref<1200x128xi8> -> index
    %348 = arith.index_cast %intptr_1125 : index to i64
    %c128_i64_1126 = arith.constant 128 : i64
    %c128_i64_1127 = arith.constant 128 : i64
    %c128_i64_1128 = arith.constant 128 : i64
    %c128_i64_1129 = arith.constant 128 : i64
    %cst_1130 = arith.constant 1.000000e+00 : f32
    %cst_1131 = arith.constant 1.000000e+00 : f32
    %cst_1132 = arith.constant 1.000000e+00 : f32
    %c0_i64_1133 = arith.constant 0 : i64
    %cst_1134 = arith.constant 0.00620856694 : f32
    %cst_1135 = arith.constant 0.000000e+00 : f32
    %c0_i64_1136 = arith.constant 0 : i64
    %c0_i64_1137 = arith.constant 0 : i64
    %c0_i64_1138 = arith.constant 0 : i64
    %c0_i64_1139 = arith.constant 0 : i64
    %c0_i64_1140 = arith.constant 0 : i64
    %c0_i64_1141 = arith.constant 0 : i64
    %c1_i64_1142 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1119, %c128_i64_1120, %c128_i64_1121, %345, %346, %347, %348, %c128_i64_1126, %c128_i64_1127, %c128_i64_1128, %c128_i64_1129, %cst_1130, %cst_1131, %cst_1132, %c0_i64_1133, %cst_1134, %cst_1135, %c0_i64_1136, %c0_i64_1137, %c0_i64_1138, %c0_i64_1139, %c0_i64_1140, %c0_i64_1141, %c1_i64_1142) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%343, %342, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1113 : memref<1200x128xi8>
    memref.dealloc %alloc_1114 : memref<1200x128xi8>
    %alloc_1143 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_1144 = memref.extract_aligned_pointer_as_index %alloc_1143 : memref<1x30x40x128xf32> -> index
    %intptr_1145 = memref.extract_aligned_pointer_as_index %alloc_1112 : memref<1200x128xi8> -> index
    %349 = arith.index_cast %intptr_1144 : index to i64
    %350 = arith.index_cast %intptr_1145 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%349, %350, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_37) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1112 : memref<1200x128xi8>
    %alloc_1146 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1143[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x128xf32>
            memref.store %793, %alloc_1146[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1147 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_1146, %alloc_1147 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_1148 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1147[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = memref.load %80[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1148[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1149 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1148[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1149[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1150 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1149[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1150[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1151 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1150[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_1151[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1152 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c31 step %c1 {
        scf.for %arg159 = %c0 to %c41 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1152[%arg157, %arg158, %arg159, %arg160] : memref<1x31x41x128xi8>
          }
        }
      }
    }
    %subview_1153 = memref.subview %alloc_1152[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_1151, %subview_1153 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_1154 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %fwd_cst_51[%arg160] : memref<256xi32>
            memref.store %793, %alloc_1154[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi32>
          }
        }
      }
    }
    %alloc_1155 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %c1_i64_1156 = arith.constant 1 : i64
    %c31_i64 = arith.constant 31 : i64
    %c41_i64 = arith.constant 41 : i64
    %c128_i64_1157 = arith.constant 128 : i64
    %c256_i64_1158 = arith.constant 256 : i64
    %c15_i64_1159 = arith.constant 15 : i64
    %c20_i64_1160 = arith.constant 20 : i64
    %c2_i64_1161 = arith.constant 2 : i64
    %c1_i64_1162 = arith.constant 1 : i64
    %c1_i64_1163 = arith.constant 1 : i64
    %c0_i64_1164 = arith.constant 0 : i64
    %c3_i64_1165 = arith.constant 3 : i64
    %c0_i64_1166 = arith.constant 0 : i64
    %c0_i64_1167 = arith.constant 0 : i64
    %c0_i64_1168 = arith.constant 0 : i64
    %c0_i64_1169 = arith.constant 0 : i64
    %c0_i64_1170 = arith.constant 0 : i64
    %intptr_1171 = memref.extract_aligned_pointer_as_index %alloc_1152 : memref<1x31x41x128xi8> -> index
    %351 = arith.index_cast %intptr_1171 : index to i64
    %intptr_1172 = memref.extract_aligned_pointer_as_index %fwd_cst_50 : memref<1152x256xi8> -> index
    %352 = arith.index_cast %intptr_1172 : index to i64
    %intptr_1173 = memref.extract_aligned_pointer_as_index %fwd_cst_51 : memref<256xi32> -> index
    %353 = arith.index_cast %intptr_1173 : index to i64
    %intptr_1174 = memref.extract_aligned_pointer_as_index %alloc_1155 : memref<300x256xi8> -> index
    %354 = arith.index_cast %intptr_1174 : index to i64
    %c0_i64_1175 = arith.constant 0 : i64
    %cst_1176 = arith.constant 0.00459722057 : f32
    %c0_i64_1177 = arith.constant 0 : i64
    %c0_i64_1178 = arith.constant 0 : i64
    %c0_i64_1179 = arith.constant 0 : i64
    %c1_i64_1180 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_1156, %c31_i64, %c41_i64, %c128_i64_1157, %c256_i64_1158, %c15_i64_1159, %c20_i64_1160, %c2_i64_1161, %c1_i64_1162, %c1_i64_1163, %c0_i64_1164, %c3_i64_1165, %c0_i64_1166, %c0_i64_1167, %c0_i64_1168, %c0_i64_1169, %c0_i64_1170, %351, %352, %353, %354, %c0_i64_1175, %cst_1176, %c0_i64_1177, %c0_i64_1178, %c0_i64_1179, %c1_i64_1180) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_1181 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_1182 = memref.extract_aligned_pointer_as_index %alloc_1181 : memref<1x15x20x256xf32> -> index
    %intptr_1183 = memref.extract_aligned_pointer_as_index %alloc_1155 : memref<300x256xi8> -> index
    %355 = arith.index_cast %intptr_1182 : index to i64
    %356 = arith.index_cast %intptr_1183 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%355, %356, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_36) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1155 : memref<300x256xi8>
    %alloc_1184 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1181[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x256xf32>
            memref.store %793, %alloc_1184[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1185 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_1184, %alloc_1185 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_1186 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1185[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = memref.load %79[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1186[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1187 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1186[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1187[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1188 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1187[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1188[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_1189 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1188[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_1189[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1190 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1191 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1192 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1193 = memref.extract_aligned_pointer_as_index %alloc_1189 : memref<1x15x20x256xi8> -> index
    %357 = arith.index_cast %intptr_1193 : index to i64
    %intptr_1194 = memref.extract_aligned_pointer_as_index %alloc_1191 : memref<304x256xi8> -> index
    %358 = arith.index_cast %intptr_1194 : index to i64
    %intptr_1195 = memref.extract_aligned_pointer_as_index %alloc_1192 : memref<304x128xi8> -> index
    %359 = arith.index_cast %intptr_1195 : index to i64
    %intptr_1196 = memref.extract_aligned_pointer_as_index %alloc_1190 : memref<300x128xi8> -> index
    %360 = arith.index_cast %intptr_1196 : index to i64
    call @buddy_rvv_memcpy_i8(%358, %357, %c76800_i64) : (i64, i64, i64) -> ()
    %361 = arith.addi %358, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%361, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64 = arith.constant 304 : i64
    %c128_i64_1197 = arith.constant 128 : i64
    %c256_i64_1198 = arith.constant 256 : i64
    %intptr_1199 = memref.extract_aligned_pointer_as_index %alloc_1191 : memref<304x256xi8> -> index
    %362 = arith.index_cast %intptr_1199 : index to i64
    %intptr_1200 = memref.extract_aligned_pointer_as_index %fwd_cst_52 : memref<256x128xi8> -> index
    %363 = arith.index_cast %intptr_1200 : index to i64
    %intptr_1201 = memref.extract_aligned_pointer_as_index %fwd_cst_53 : memref<304x128xi32> -> index
    %364 = arith.index_cast %intptr_1201 : index to i64
    %intptr_1202 = memref.extract_aligned_pointer_as_index %alloc_1192 : memref<304x128xi8> -> index
    %365 = arith.index_cast %intptr_1202 : index to i64
    %c256_i64_1203 = arith.constant 256 : i64
    %c128_i64_1204 = arith.constant 128 : i64
    %c128_i64_1205 = arith.constant 128 : i64
    %c128_i64_1206 = arith.constant 128 : i64
    %cst_1207 = arith.constant 1.000000e+00 : f32
    %cst_1208 = arith.constant 1.000000e+00 : f32
    %cst_1209 = arith.constant 1.000000e+00 : f32
    %c0_i64_1210 = arith.constant 0 : i64
    %cst_1211 = arith.constant 0.00715792737 : f32
    %cst_1212 = arith.constant 0.000000e+00 : f32
    %c0_i64_1213 = arith.constant 0 : i64
    %c0_i64_1214 = arith.constant 0 : i64
    %c0_i64_1215 = arith.constant 0 : i64
    %c0_i64_1216 = arith.constant 0 : i64
    %c0_i64_1217 = arith.constant 0 : i64
    %c0_i64_1218 = arith.constant 0 : i64
    %c1_i64_1219 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64, %c128_i64_1197, %c256_i64_1198, %362, %363, %364, %365, %c256_i64_1203, %c128_i64_1204, %c128_i64_1205, %c128_i64_1206, %cst_1207, %cst_1208, %cst_1209, %c0_i64_1210, %cst_1211, %cst_1212, %c0_i64_1213, %c0_i64_1214, %c0_i64_1215, %c0_i64_1216, %c0_i64_1217, %c0_i64_1218, %c1_i64_1219) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%360, %359, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1191 : memref<304x256xi8>
    memref.dealloc %alloc_1192 : memref<304x128xi8>
    %alloc_1220 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1221 = memref.extract_aligned_pointer_as_index %alloc_1220 : memref<1x15x20x128xf32> -> index
    %intptr_1222 = memref.extract_aligned_pointer_as_index %alloc_1190 : memref<300x128xi8> -> index
    %366 = arith.index_cast %intptr_1221 : index to i64
    %367 = arith.index_cast %intptr_1222 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%366, %367, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_35) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1190 : memref<300x128xi8>
    %alloc_1223 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1220[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1223[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1224 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1223, %alloc_1224 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1225 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1224[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %78[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1225[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1226 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1225[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1226[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1227 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1226[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1227[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1228 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1227[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_1228[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1229 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1230 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %alloc_1231 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1232 = memref.extract_aligned_pointer_as_index %alloc_1228 : memref<1x15x20x128xi8> -> index
    %368 = arith.index_cast %intptr_1232 : index to i64
    %intptr_1233 = memref.extract_aligned_pointer_as_index %alloc_1230 : memref<304x128xi8> -> index
    %369 = arith.index_cast %intptr_1233 : index to i64
    %intptr_1234 = memref.extract_aligned_pointer_as_index %alloc_1231 : memref<304x128xi8> -> index
    %370 = arith.index_cast %intptr_1234 : index to i64
    %intptr_1235 = memref.extract_aligned_pointer_as_index %alloc_1229 : memref<300x128xi8> -> index
    %371 = arith.index_cast %intptr_1235 : index to i64
    call @buddy_rvv_memcpy_i8(%369, %368, %c38400_i64) : (i64, i64, i64) -> ()
    %372 = arith.addi %369, %c38400_i64 : i64
    call @buddy_rvv_memset_i8(%372, %c0_i64, %c512_i64) : (i64, i64, i64) -> ()
    %c304_i64_1236 = arith.constant 304 : i64
    %c128_i64_1237 = arith.constant 128 : i64
    %c128_i64_1238 = arith.constant 128 : i64
    %intptr_1239 = memref.extract_aligned_pointer_as_index %alloc_1230 : memref<304x128xi8> -> index
    %373 = arith.index_cast %intptr_1239 : index to i64
    %intptr_1240 = memref.extract_aligned_pointer_as_index %fwd_cst_54 : memref<128x128xi8> -> index
    %374 = arith.index_cast %intptr_1240 : index to i64
    %intptr_1241 = memref.extract_aligned_pointer_as_index %fwd_cst_55 : memref<304x128xi32> -> index
    %375 = arith.index_cast %intptr_1241 : index to i64
    %intptr_1242 = memref.extract_aligned_pointer_as_index %alloc_1231 : memref<304x128xi8> -> index
    %376 = arith.index_cast %intptr_1242 : index to i64
    %c128_i64_1243 = arith.constant 128 : i64
    %c128_i64_1244 = arith.constant 128 : i64
    %c128_i64_1245 = arith.constant 128 : i64
    %c128_i64_1246 = arith.constant 128 : i64
    %cst_1247 = arith.constant 1.000000e+00 : f32
    %cst_1248 = arith.constant 1.000000e+00 : f32
    %cst_1249 = arith.constant 1.000000e+00 : f32
    %c0_i64_1250 = arith.constant 0 : i64
    %cst_1251 = arith.constant 0.0129372664 : f32
    %cst_1252 = arith.constant 0.000000e+00 : f32
    %c0_i64_1253 = arith.constant 0 : i64
    %c0_i64_1254 = arith.constant 0 : i64
    %c0_i64_1255 = arith.constant 0 : i64
    %c0_i64_1256 = arith.constant 0 : i64
    %c0_i64_1257 = arith.constant 0 : i64
    %c0_i64_1258 = arith.constant 0 : i64
    %c1_i64_1259 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1236, %c128_i64_1237, %c128_i64_1238, %373, %374, %375, %376, %c128_i64_1243, %c128_i64_1244, %c128_i64_1245, %c128_i64_1246, %cst_1247, %cst_1248, %cst_1249, %c0_i64_1250, %cst_1251, %cst_1252, %c0_i64_1253, %c0_i64_1254, %c0_i64_1255, %c0_i64_1256, %c0_i64_1257, %c0_i64_1258, %c1_i64_1259) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%371, %370, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1230 : memref<304x128xi8>
    memref.dealloc %alloc_1231 : memref<304x128xi8>
    %alloc_1260 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1261 = memref.extract_aligned_pointer_as_index %alloc_1260 : memref<1x15x20x128xf32> -> index
    %intptr_1262 = memref.extract_aligned_pointer_as_index %alloc_1229 : memref<300x128xi8> -> index
    %377 = arith.index_cast %intptr_1261 : index to i64
    %378 = arith.index_cast %intptr_1262 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%377, %378, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_34) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1229 : memref<300x128xi8>
    %alloc_1263 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1260[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1263[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1264 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1263, %alloc_1264 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1265 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1264[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %77[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1265[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1266 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1265[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1266[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1267 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1266[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1267[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1268 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1267[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_1268[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1269 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_1269[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x128xi8>
          }
        }
      }
    }
    %subview_1270 = memref.subview %alloc_1269[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_1268, %subview_1270 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_1271 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %fwd_cst_57[%arg160] : memref<128xi32>
            memref.store %793, %alloc_1271[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_1272 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %c1_i64_1273 = arith.constant 1 : i64
    %c17_i64 = arith.constant 17 : i64
    %c22_i64 = arith.constant 22 : i64
    %c128_i64_1274 = arith.constant 128 : i64
    %c128_i64_1275 = arith.constant 128 : i64
    %c15_i64_1276 = arith.constant 15 : i64
    %c20_i64_1277 = arith.constant 20 : i64
    %c1_i64_1278 = arith.constant 1 : i64
    %c1_i64_1279 = arith.constant 1 : i64
    %c1_i64_1280 = arith.constant 1 : i64
    %c0_i64_1281 = arith.constant 0 : i64
    %c3_i64_1282 = arith.constant 3 : i64
    %c0_i64_1283 = arith.constant 0 : i64
    %c0_i64_1284 = arith.constant 0 : i64
    %c0_i64_1285 = arith.constant 0 : i64
    %c0_i64_1286 = arith.constant 0 : i64
    %c0_i64_1287 = arith.constant 0 : i64
    %intptr_1288 = memref.extract_aligned_pointer_as_index %alloc_1269 : memref<1x17x22x128xi8> -> index
    %379 = arith.index_cast %intptr_1288 : index to i64
    %intptr_1289 = memref.extract_aligned_pointer_as_index %fwd_cst_56 : memref<1152x128xi8> -> index
    %380 = arith.index_cast %intptr_1289 : index to i64
    %intptr_1290 = memref.extract_aligned_pointer_as_index %fwd_cst_57 : memref<128xi32> -> index
    %381 = arith.index_cast %intptr_1290 : index to i64
    %intptr_1291 = memref.extract_aligned_pointer_as_index %alloc_1272 : memref<300x128xi8> -> index
    %382 = arith.index_cast %intptr_1291 : index to i64
    %c0_i64_1292 = arith.constant 0 : i64
    %cst_1293 = arith.constant 0.003725769 : f32
    %c0_i64_1294 = arith.constant 0 : i64
    %c0_i64_1295 = arith.constant 0 : i64
    %c0_i64_1296 = arith.constant 0 : i64
    %c1_i64_1297 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_1273, %c17_i64, %c22_i64, %c128_i64_1274, %c128_i64_1275, %c15_i64_1276, %c20_i64_1277, %c1_i64_1278, %c1_i64_1279, %c1_i64_1280, %c0_i64_1281, %c3_i64_1282, %c0_i64_1283, %c0_i64_1284, %c0_i64_1285, %c0_i64_1286, %c0_i64_1287, %379, %380, %381, %382, %c0_i64_1292, %cst_1293, %c0_i64_1294, %c0_i64_1295, %c0_i64_1296, %c1_i64_1297) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_1298 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1299 = memref.extract_aligned_pointer_as_index %alloc_1298 : memref<1x15x20x128xf32> -> index
    %intptr_1300 = memref.extract_aligned_pointer_as_index %alloc_1272 : memref<300x128xi8> -> index
    %383 = arith.index_cast %intptr_1299 : index to i64
    %384 = arith.index_cast %intptr_1300 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%383, %384, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_33) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1272 : memref<300x128xi8>
    %alloc_1301 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1298[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1301[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1302 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1301, %alloc_1302 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1303 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1302[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %76[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1303[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1304 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1303[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1304[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1305 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1304[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1305[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1306 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1227[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1306[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1307 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1306[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %75[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1307[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1308 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1307[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1308[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1309 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1305[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1309[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1310 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1309[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %74[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1310[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1311 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1310[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1311[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1312 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1308[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %alloc_1311[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %795 = arith.addi %793, %794 : i32
            memref.store %795, %alloc_1312[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1313 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1312[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1313[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1314 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1313[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1314[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1315 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1314[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1315[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1316 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1188[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_1316[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1317 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1318 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1319 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1320 = memref.extract_aligned_pointer_as_index %alloc_1316 : memref<1x15x20x256xi8> -> index
    %385 = arith.index_cast %intptr_1320 : index to i64
    %intptr_1321 = memref.extract_aligned_pointer_as_index %alloc_1318 : memref<304x256xi8> -> index
    %386 = arith.index_cast %intptr_1321 : index to i64
    %intptr_1322 = memref.extract_aligned_pointer_as_index %alloc_1319 : memref<304x128xi8> -> index
    %387 = arith.index_cast %intptr_1322 : index to i64
    %intptr_1323 = memref.extract_aligned_pointer_as_index %alloc_1317 : memref<300x128xi8> -> index
    %388 = arith.index_cast %intptr_1323 : index to i64
    call @buddy_rvv_memcpy_i8(%386, %385, %c76800_i64) : (i64, i64, i64) -> ()
    %389 = arith.addi %386, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%389, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_1324 = arith.constant 304 : i64
    %c128_i64_1325 = arith.constant 128 : i64
    %c256_i64_1326 = arith.constant 256 : i64
    %intptr_1327 = memref.extract_aligned_pointer_as_index %alloc_1318 : memref<304x256xi8> -> index
    %390 = arith.index_cast %intptr_1327 : index to i64
    %intptr_1328 = memref.extract_aligned_pointer_as_index %fwd_cst_58 : memref<256x128xi8> -> index
    %391 = arith.index_cast %intptr_1328 : index to i64
    %intptr_1329 = memref.extract_aligned_pointer_as_index %fwd_cst_59 : memref<304x128xi32> -> index
    %392 = arith.index_cast %intptr_1329 : index to i64
    %intptr_1330 = memref.extract_aligned_pointer_as_index %alloc_1319 : memref<304x128xi8> -> index
    %393 = arith.index_cast %intptr_1330 : index to i64
    %c256_i64_1331 = arith.constant 256 : i64
    %c128_i64_1332 = arith.constant 128 : i64
    %c128_i64_1333 = arith.constant 128 : i64
    %c128_i64_1334 = arith.constant 128 : i64
    %cst_1335 = arith.constant 1.000000e+00 : f32
    %cst_1336 = arith.constant 1.000000e+00 : f32
    %cst_1337 = arith.constant 1.000000e+00 : f32
    %c0_i64_1338 = arith.constant 0 : i64
    %cst_1339 = arith.constant 0.0122155221 : f32
    %cst_1340 = arith.constant 0.000000e+00 : f32
    %c0_i64_1341 = arith.constant 0 : i64
    %c0_i64_1342 = arith.constant 0 : i64
    %c0_i64_1343 = arith.constant 0 : i64
    %c0_i64_1344 = arith.constant 0 : i64
    %c0_i64_1345 = arith.constant 0 : i64
    %c0_i64_1346 = arith.constant 0 : i64
    %c1_i64_1347 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1324, %c128_i64_1325, %c256_i64_1326, %390, %391, %392, %393, %c256_i64_1331, %c128_i64_1332, %c128_i64_1333, %c128_i64_1334, %cst_1335, %cst_1336, %cst_1337, %c0_i64_1338, %cst_1339, %cst_1340, %c0_i64_1341, %c0_i64_1342, %c0_i64_1343, %c0_i64_1344, %c0_i64_1345, %c0_i64_1346, %c1_i64_1347) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%388, %387, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1318 : memref<304x256xi8>
    memref.dealloc %alloc_1319 : memref<304x128xi8>
    %alloc_1348 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1349 = memref.extract_aligned_pointer_as_index %alloc_1348 : memref<1x15x20x128xf32> -> index
    %intptr_1350 = memref.extract_aligned_pointer_as_index %alloc_1317 : memref<300x128xi8> -> index
    %394 = arith.index_cast %intptr_1349 : index to i64
    %395 = arith.index_cast %intptr_1350 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%394, %395, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_33) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1317 : memref<300x128xi8>
    %alloc_1351 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1348[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1351[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1352 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1351, %alloc_1352 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1353 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1352[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %73[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1353[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1354 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1353[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1354[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1355 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1354[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1355[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1356 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1315[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1356[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1357 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1356[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1357[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1358 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1357[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1358[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1359 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1358[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1359[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1360 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1355[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1360[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1361 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1360[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %72[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1361[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1362 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1361[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1362[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1363 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1362[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1363[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1364 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1363[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1364[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_1365 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1364[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1365[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1366 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_1367 = memref.subview %alloc_1366[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_1359, %subview_1367 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_1368 = memref.subview %alloc_1366[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_1365, %subview_1368 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_1369 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1366[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_1369[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1370 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_1371 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1372 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_1373 = memref.extract_aligned_pointer_as_index %alloc_1369 : memref<1x15x20x256xi8> -> index
    %396 = arith.index_cast %intptr_1373 : index to i64
    %intptr_1374 = memref.extract_aligned_pointer_as_index %alloc_1371 : memref<304x256xi8> -> index
    %397 = arith.index_cast %intptr_1374 : index to i64
    %intptr_1375 = memref.extract_aligned_pointer_as_index %alloc_1372 : memref<304x256xi8> -> index
    %398 = arith.index_cast %intptr_1375 : index to i64
    %intptr_1376 = memref.extract_aligned_pointer_as_index %alloc_1370 : memref<300x256xi8> -> index
    %399 = arith.index_cast %intptr_1376 : index to i64
    call @buddy_rvv_memcpy_i8(%397, %396, %c76800_i64) : (i64, i64, i64) -> ()
    %400 = arith.addi %397, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%400, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_1377 = arith.constant 304 : i64
    %c256_i64_1378 = arith.constant 256 : i64
    %c256_i64_1379 = arith.constant 256 : i64
    %intptr_1380 = memref.extract_aligned_pointer_as_index %alloc_1371 : memref<304x256xi8> -> index
    %401 = arith.index_cast %intptr_1380 : index to i64
    %intptr_1381 = memref.extract_aligned_pointer_as_index %fwd_cst_60 : memref<256x256xi8> -> index
    %402 = arith.index_cast %intptr_1381 : index to i64
    %intptr_1382 = memref.extract_aligned_pointer_as_index %fwd_cst_61 : memref<304x256xi32> -> index
    %403 = arith.index_cast %intptr_1382 : index to i64
    %intptr_1383 = memref.extract_aligned_pointer_as_index %alloc_1372 : memref<304x256xi8> -> index
    %404 = arith.index_cast %intptr_1383 : index to i64
    %c256_i64_1384 = arith.constant 256 : i64
    %c256_i64_1385 = arith.constant 256 : i64
    %c256_i64_1386 = arith.constant 256 : i64
    %c256_i64_1387 = arith.constant 256 : i64
    %cst_1388 = arith.constant 1.000000e+00 : f32
    %cst_1389 = arith.constant 1.000000e+00 : f32
    %cst_1390 = arith.constant 1.000000e+00 : f32
    %c0_i64_1391 = arith.constant 0 : i64
    %cst_1392 = arith.constant 0.0109014092 : f32
    %cst_1393 = arith.constant 0.000000e+00 : f32
    %c0_i64_1394 = arith.constant 0 : i64
    %c0_i64_1395 = arith.constant 0 : i64
    %c0_i64_1396 = arith.constant 0 : i64
    %c0_i64_1397 = arith.constant 0 : i64
    %c0_i64_1398 = arith.constant 0 : i64
    %c0_i64_1399 = arith.constant 0 : i64
    %c1_i64_1400 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1377, %c256_i64_1378, %c256_i64_1379, %401, %402, %403, %404, %c256_i64_1384, %c256_i64_1385, %c256_i64_1386, %c256_i64_1387, %cst_1388, %cst_1389, %cst_1390, %c0_i64_1391, %cst_1392, %cst_1393, %c0_i64_1394, %c0_i64_1395, %c0_i64_1396, %c0_i64_1397, %c0_i64_1398, %c0_i64_1399, %c1_i64_1400) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%399, %398, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1371 : memref<304x256xi8>
    memref.dealloc %alloc_1372 : memref<304x256xi8>
    %alloc_1401 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_1402 = memref.extract_aligned_pointer_as_index %alloc_1401 : memref<1x15x20x256xf32> -> index
    %intptr_1403 = memref.extract_aligned_pointer_as_index %alloc_1370 : memref<300x256xi8> -> index
    %405 = arith.index_cast %intptr_1402 : index to i64
    %406 = arith.index_cast %intptr_1403 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%405, %406, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_32) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1370 : memref<300x256xi8>
    %alloc_1404 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1401[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x256xf32>
            memref.store %793, %alloc_1404[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1405 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_1404, %alloc_1405 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_1406 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1405[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = memref.load %71[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1406[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1407 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1406[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1407[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1408 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1407[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1408[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_1409 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1408[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_1409[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1410 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1411 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1412 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1413 = memref.extract_aligned_pointer_as_index %alloc_1409 : memref<1x15x20x256xi8> -> index
    %407 = arith.index_cast %intptr_1413 : index to i64
    %intptr_1414 = memref.extract_aligned_pointer_as_index %alloc_1411 : memref<304x256xi8> -> index
    %408 = arith.index_cast %intptr_1414 : index to i64
    %intptr_1415 = memref.extract_aligned_pointer_as_index %alloc_1412 : memref<304x128xi8> -> index
    %409 = arith.index_cast %intptr_1415 : index to i64
    %intptr_1416 = memref.extract_aligned_pointer_as_index %alloc_1410 : memref<300x128xi8> -> index
    %410 = arith.index_cast %intptr_1416 : index to i64
    call @buddy_rvv_memcpy_i8(%408, %407, %c76800_i64) : (i64, i64, i64) -> ()
    %411 = arith.addi %408, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%411, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_1417 = arith.constant 304 : i64
    %c128_i64_1418 = arith.constant 128 : i64
    %c256_i64_1419 = arith.constant 256 : i64
    %intptr_1420 = memref.extract_aligned_pointer_as_index %alloc_1411 : memref<304x256xi8> -> index
    %412 = arith.index_cast %intptr_1420 : index to i64
    %intptr_1421 = memref.extract_aligned_pointer_as_index %fwd_cst_62 : memref<256x128xi8> -> index
    %413 = arith.index_cast %intptr_1421 : index to i64
    %intptr_1422 = memref.extract_aligned_pointer_as_index %fwd_cst_63 : memref<304x128xi32> -> index
    %414 = arith.index_cast %intptr_1422 : index to i64
    %intptr_1423 = memref.extract_aligned_pointer_as_index %alloc_1412 : memref<304x128xi8> -> index
    %415 = arith.index_cast %intptr_1423 : index to i64
    %c256_i64_1424 = arith.constant 256 : i64
    %c128_i64_1425 = arith.constant 128 : i64
    %c128_i64_1426 = arith.constant 128 : i64
    %c128_i64_1427 = arith.constant 128 : i64
    %cst_1428 = arith.constant 1.000000e+00 : f32
    %cst_1429 = arith.constant 1.000000e+00 : f32
    %cst_1430 = arith.constant 1.000000e+00 : f32
    %c0_i64_1431 = arith.constant 0 : i64
    %cst_1432 = arith.constant 0.00621239562 : f32
    %cst_1433 = arith.constant 0.000000e+00 : f32
    %c0_i64_1434 = arith.constant 0 : i64
    %c0_i64_1435 = arith.constant 0 : i64
    %c0_i64_1436 = arith.constant 0 : i64
    %c0_i64_1437 = arith.constant 0 : i64
    %c0_i64_1438 = arith.constant 0 : i64
    %c0_i64_1439 = arith.constant 0 : i64
    %c1_i64_1440 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1417, %c128_i64_1418, %c256_i64_1419, %412, %413, %414, %415, %c256_i64_1424, %c128_i64_1425, %c128_i64_1426, %c128_i64_1427, %cst_1428, %cst_1429, %cst_1430, %c0_i64_1431, %cst_1432, %cst_1433, %c0_i64_1434, %c0_i64_1435, %c0_i64_1436, %c0_i64_1437, %c0_i64_1438, %c0_i64_1439, %c1_i64_1440) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%410, %409, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1411 : memref<304x256xi8>
    memref.dealloc %alloc_1412 : memref<304x128xi8>
    %alloc_1441 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1442 = memref.extract_aligned_pointer_as_index %alloc_1441 : memref<1x15x20x128xf32> -> index
    %intptr_1443 = memref.extract_aligned_pointer_as_index %alloc_1410 : memref<300x128xi8> -> index
    %416 = arith.index_cast %intptr_1442 : index to i64
    %417 = arith.index_cast %intptr_1443 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%416, %417, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_31) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1410 : memref<300x128xi8>
    %alloc_1444 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1441[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1444[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1445 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1444, %alloc_1445 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1446 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1445[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %70[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1446[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1447 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1446[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1447[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1448 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1447[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1448[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1449 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1448[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_1449[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1450 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c19 step %c1 {
        scf.for %arg159 = %c0 to %c24 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1450[%arg157, %arg158, %arg159, %arg160] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_1451 = memref.subview %alloc_1450[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_1449, %subview_1451 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_1452 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1452[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            scf.for %arg161 = %c0 to %c5 step %c1 {
              scf.for %arg162 = %c0 to %c5 step %c1 {
                %793 = arith.addi %arg158, %arg161 : index
                %794 = arith.addi %arg159, %arg162 : index
                %795 = memref.load %alloc_1450[%arg157, %793, %794, %arg160] : memref<1x19x24x128xi8>
                %796 = memref.load %alloc_1452[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
                %797 = arith.maxsi %796, %795 : i8
                memref.store %797, %alloc_1452[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_1453 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1452[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xi8>
            memref.store %793, %alloc_1453[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1454 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c19 step %c1 {
        scf.for %arg159 = %c0 to %c24 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1454[%arg157, %arg158, %arg159, %arg160] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_1455 = memref.subview %alloc_1454[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_1452, %subview_1455 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_1456 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1456[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            scf.for %arg161 = %c0 to %c5 step %c1 {
              scf.for %arg162 = %c0 to %c5 step %c1 {
                %793 = arith.addi %arg158, %arg161 : index
                %794 = arith.addi %arg159, %arg162 : index
                %795 = memref.load %alloc_1454[%arg157, %793, %794, %arg160] : memref<1x19x24x128xi8>
                %796 = memref.load %alloc_1456[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
                %797 = arith.maxsi %796, %795 : i8
                memref.store %797, %alloc_1456[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_1457 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1456[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xi8>
            memref.store %793, %alloc_1457[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1458 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c19 step %c1 {
        scf.for %arg159 = %c0 to %c24 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1458[%arg157, %arg158, %arg159, %arg160] : memref<1x19x24x128xi8>
          }
        }
      }
    }
    %subview_1459 = memref.subview %alloc_1458[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_1456, %subview_1459 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_1460 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c-128_i8, %alloc_1460[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            scf.for %arg161 = %c0 to %c5 step %c1 {
              scf.for %arg162 = %c0 to %c5 step %c1 {
                %793 = arith.addi %arg158, %arg161 : index
                %794 = arith.addi %arg159, %arg162 : index
                %795 = memref.load %alloc_1458[%arg157, %793, %794, %arg160] : memref<1x19x24x128xi8>
                %796 = memref.load %alloc_1460[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
                %797 = arith.maxsi %796, %795 : i8
                memref.store %797, %alloc_1460[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
              }
            }
          }
        }
      }
    }
    %alloc_1461 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1460[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xi8>
            memref.store %793, %alloc_1461[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1462 = memref.alloc() {alignment = 64 : i64} : memref<1x512x15x20xi8>
    %subview_1463 = memref.subview %alloc_1462[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    memref.copy %alloc_1448, %subview_1463 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    %subview_1464 = memref.subview %alloc_1462[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_1453, %subview_1464 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    %subview_1465 = memref.subview %alloc_1462[0, 256, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    memref.copy %alloc_1457, %subview_1465 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    %subview_1466 = memref.subview %alloc_1462[0, 384, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    memref.copy %alloc_1461, %subview_1466 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    %alloc_1467 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x512xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c512 step %c1 {
            %793 = memref.load %alloc_1462[%arg157, %arg160, %arg158, %arg159] : memref<1x512x15x20xi8>
            memref.store %793, %alloc_1467[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x512xi8>
          }
        }
      }
    }
    %alloc_1468 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_1469 = memref.alloc() {alignment = 64 : i64} : memref<304x512xi8>
    %alloc_1470 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_1471 = memref.extract_aligned_pointer_as_index %alloc_1467 : memref<1x15x20x512xi8> -> index
    %418 = arith.index_cast %intptr_1471 : index to i64
    %intptr_1472 = memref.extract_aligned_pointer_as_index %alloc_1469 : memref<304x512xi8> -> index
    %419 = arith.index_cast %intptr_1472 : index to i64
    %intptr_1473 = memref.extract_aligned_pointer_as_index %alloc_1470 : memref<304x256xi8> -> index
    %420 = arith.index_cast %intptr_1473 : index to i64
    %intptr_1474 = memref.extract_aligned_pointer_as_index %alloc_1468 : memref<300x256xi8> -> index
    %421 = arith.index_cast %intptr_1474 : index to i64
    call @buddy_rvv_memcpy_i8(%419, %418, %c153600_i64) : (i64, i64, i64) -> ()
    %422 = arith.addi %419, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%422, %c0_i64, %c2048_i64) : (i64, i64, i64) -> ()
    %c304_i64_1475 = arith.constant 304 : i64
    %c256_i64_1476 = arith.constant 256 : i64
    %c512_i64_1477 = arith.constant 512 : i64
    %intptr_1478 = memref.extract_aligned_pointer_as_index %alloc_1469 : memref<304x512xi8> -> index
    %423 = arith.index_cast %intptr_1478 : index to i64
    %intptr_1479 = memref.extract_aligned_pointer_as_index %fwd_cst_64 : memref<512x256xi8> -> index
    %424 = arith.index_cast %intptr_1479 : index to i64
    %intptr_1480 = memref.extract_aligned_pointer_as_index %fwd_cst_65 : memref<304x256xi32> -> index
    %425 = arith.index_cast %intptr_1480 : index to i64
    %intptr_1481 = memref.extract_aligned_pointer_as_index %alloc_1470 : memref<304x256xi8> -> index
    %426 = arith.index_cast %intptr_1481 : index to i64
    %c512_i64_1482 = arith.constant 512 : i64
    %c256_i64_1483 = arith.constant 256 : i64
    %c256_i64_1484 = arith.constant 256 : i64
    %c256_i64_1485 = arith.constant 256 : i64
    %cst_1486 = arith.constant 1.000000e+00 : f32
    %cst_1487 = arith.constant 1.000000e+00 : f32
    %cst_1488 = arith.constant 1.000000e+00 : f32
    %c0_i64_1489 = arith.constant 0 : i64
    %cst_1490 = arith.constant 8.516760e-03 : f32
    %cst_1491 = arith.constant 0.000000e+00 : f32
    %c0_i64_1492 = arith.constant 0 : i64
    %c0_i64_1493 = arith.constant 0 : i64
    %c0_i64_1494 = arith.constant 0 : i64
    %c0_i64_1495 = arith.constant 0 : i64
    %c0_i64_1496 = arith.constant 0 : i64
    %c0_i64_1497 = arith.constant 0 : i64
    %c1_i64_1498 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1475, %c256_i64_1476, %c512_i64_1477, %423, %424, %425, %426, %c512_i64_1482, %c256_i64_1483, %c256_i64_1484, %c256_i64_1485, %cst_1486, %cst_1487, %cst_1488, %c0_i64_1489, %cst_1490, %cst_1491, %c0_i64_1492, %c0_i64_1493, %c0_i64_1494, %c0_i64_1495, %c0_i64_1496, %c0_i64_1497, %c1_i64_1498) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%421, %420, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1469 : memref<304x512xi8>
    memref.dealloc %alloc_1470 : memref<304x256xi8>
    %alloc_1499 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_1500 = memref.extract_aligned_pointer_as_index %alloc_1499 : memref<1x15x20x256xf32> -> index
    %intptr_1501 = memref.extract_aligned_pointer_as_index %alloc_1468 : memref<300x256xi8> -> index
    %427 = arith.index_cast %intptr_1500 : index to i64
    %428 = arith.index_cast %intptr_1501 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%427, %428, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_30) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1468 : memref<300x256xi8>
    %alloc_1502 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1499[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x256xf32>
            memref.store %793, %alloc_1502[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1503 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_1502, %alloc_1503 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_1504 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1503[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = memref.load %69[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1504[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1505 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1504[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1505[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_1506 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1505[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1506[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_1507 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1506[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_1507[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_1508 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_1509 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_1510 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_1511 = memref.extract_aligned_pointer_as_index %alloc_1507 : memref<1x15x20x256xi8> -> index
    %429 = arith.index_cast %intptr_1511 : index to i64
    %intptr_1512 = memref.extract_aligned_pointer_as_index %alloc_1509 : memref<304x256xi8> -> index
    %430 = arith.index_cast %intptr_1512 : index to i64
    %intptr_1513 = memref.extract_aligned_pointer_as_index %alloc_1510 : memref<304x128xi8> -> index
    %431 = arith.index_cast %intptr_1513 : index to i64
    %intptr_1514 = memref.extract_aligned_pointer_as_index %alloc_1508 : memref<300x128xi8> -> index
    %432 = arith.index_cast %intptr_1514 : index to i64
    call @buddy_rvv_memcpy_i8(%430, %429, %c76800_i64) : (i64, i64, i64) -> ()
    %433 = arith.addi %430, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%433, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_1515 = arith.constant 304 : i64
    %c128_i64_1516 = arith.constant 128 : i64
    %c256_i64_1517 = arith.constant 256 : i64
    %intptr_1518 = memref.extract_aligned_pointer_as_index %alloc_1509 : memref<304x256xi8> -> index
    %434 = arith.index_cast %intptr_1518 : index to i64
    %intptr_1519 = memref.extract_aligned_pointer_as_index %fwd_cst_66 : memref<256x128xi8> -> index
    %435 = arith.index_cast %intptr_1519 : index to i64
    %intptr_1520 = memref.extract_aligned_pointer_as_index %fwd_cst_67 : memref<304x128xi32> -> index
    %436 = arith.index_cast %intptr_1520 : index to i64
    %intptr_1521 = memref.extract_aligned_pointer_as_index %alloc_1510 : memref<304x128xi8> -> index
    %437 = arith.index_cast %intptr_1521 : index to i64
    %c256_i64_1522 = arith.constant 256 : i64
    %c128_i64_1523 = arith.constant 128 : i64
    %c128_i64_1524 = arith.constant 128 : i64
    %c128_i64_1525 = arith.constant 128 : i64
    %cst_1526 = arith.constant 1.000000e+00 : f32
    %cst_1527 = arith.constant 1.000000e+00 : f32
    %cst_1528 = arith.constant 1.000000e+00 : f32
    %c0_i64_1529 = arith.constant 0 : i64
    %cst_1530 = arith.constant 0.00958314538 : f32
    %cst_1531 = arith.constant 0.000000e+00 : f32
    %c0_i64_1532 = arith.constant 0 : i64
    %c0_i64_1533 = arith.constant 0 : i64
    %c0_i64_1534 = arith.constant 0 : i64
    %c0_i64_1535 = arith.constant 0 : i64
    %c0_i64_1536 = arith.constant 0 : i64
    %c0_i64_1537 = arith.constant 0 : i64
    %c1_i64_1538 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_1515, %c128_i64_1516, %c256_i64_1517, %434, %435, %436, %437, %c256_i64_1522, %c128_i64_1523, %c128_i64_1524, %c128_i64_1525, %cst_1526, %cst_1527, %cst_1528, %c0_i64_1529, %cst_1530, %cst_1531, %c0_i64_1532, %c0_i64_1533, %c0_i64_1534, %c0_i64_1535, %c0_i64_1536, %c0_i64_1537, %c1_i64_1538) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%432, %431, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1509 : memref<304x256xi8>
    memref.dealloc %alloc_1510 : memref<304x128xi8>
    %alloc_1539 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_1540 = memref.extract_aligned_pointer_as_index %alloc_1539 : memref<1x15x20x128xf32> -> index
    %intptr_1541 = memref.extract_aligned_pointer_as_index %alloc_1508 : memref<300x128xi8> -> index
    %438 = arith.index_cast %intptr_1540 : index to i64
    %439 = arith.index_cast %intptr_1541 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%438, %439, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_29) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1508 : memref<300x128xi8>
    %alloc_1542 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1539[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_1542[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1543 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_1542, %alloc_1543 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_1544 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1543[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %68[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1544[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1545 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1544[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1545[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_1546 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1545[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1546[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_1547 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1546[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_1547[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_1548 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = arith.index_cast %arg158 : index to i32
            %794 = arith.index_cast %arg159 : index to i32
            %795 = arith.divsi %793, %c2_i32 : i32
            %796 = arith.muli %795, %c2_i32 : i32
            %797 = arith.subi %793, %796 : i32
            %798 = arith.divsi %794, %c2_i32 : i32
            %799 = arith.muli %798, %c2_i32 : i32
            %800 = arith.subi %794, %799 : i32
            %801 = arith.shli %797, %c1_i32 : i32
            %802 = arith.cmpi sge, %801, %c2_i32 : i32
            %803 = arith.extui %802 : i1 to i32
            %804 = arith.addi %795, %803 : i32
            %805 = arith.maxsi %804, %c0_i32 : i32
            %806 = arith.minsi %805, %c14_i32 : i32
            %807 = arith.index_cast %806 : i32 to index
            %808 = arith.shli %800, %c1_i32 : i32
            %809 = arith.cmpi sge, %808, %c2_i32 : i32
            %810 = arith.extui %809 : i1 to i32
            %811 = arith.addi %798, %810 : i32
            %812 = arith.maxsi %811, %c0_i32 : i32
            %813 = arith.minsi %812, %c19_i32 : i32
            %814 = arith.index_cast %813 : i32 to index
            %815 = memref.load %alloc_1547[%c0, %807, %814, %arg160] : memref<1x15x20x128xi8>
            memref.store %815, %alloc_1548[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1549 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1548[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x128xi8>
            memref.store %793, %alloc_1549[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1550 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1549[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1550[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1551 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1550[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %67[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1551[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1552 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1551[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1552[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1553 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1552[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1553[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1554 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1553[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1554[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1555 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1554[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1555[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1556 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1150[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1556[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1557 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1556[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %66[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1557[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1558 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1557[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1558[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1559 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1558[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1559[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1560 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1559[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1560[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
          }
        }
      }
    }
    %alloc_1561 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1560[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1561[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1562 = memref.alloc() {alignment = 64 : i64} : memref<1x256x30x40xi8>
    %subview_1563 = memref.subview %alloc_1562[0, 0, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    memref.copy %alloc_1555, %subview_1563 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    %subview_1564 = memref.subview %alloc_1562[0, 128, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    memref.copy %alloc_1561, %subview_1564 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    %alloc_1565 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1562[%arg157, %arg160, %arg158, %arg159] : memref<1x256x30x40xi8>
            memref.store %793, %alloc_1565[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x256xi8>
          }
        }
      }
    }
    %alloc_1566 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1567 = memref.alloc() {alignment = 64 : i64} : memref<1200x256xi8>
    %alloc_1568 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1569 = memref.extract_aligned_pointer_as_index %alloc_1565 : memref<1x30x40x256xi8> -> index
    %440 = arith.index_cast %intptr_1569 : index to i64
    %intptr_1570 = memref.extract_aligned_pointer_as_index %alloc_1567 : memref<1200x256xi8> -> index
    %441 = arith.index_cast %intptr_1570 : index to i64
    %intptr_1571 = memref.extract_aligned_pointer_as_index %alloc_1568 : memref<1200x64xi8> -> index
    %442 = arith.index_cast %intptr_1571 : index to i64
    %intptr_1572 = memref.extract_aligned_pointer_as_index %alloc_1566 : memref<1200x64xi8> -> index
    %443 = arith.index_cast %intptr_1572 : index to i64
    call @buddy_rvv_memcpy_i8(%441, %440, %c307200_i64) : (i64, i64, i64) -> ()
    %444 = arith.addi %441, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%444, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1573 = arith.constant 1200 : i64
    %c64_i64_1574 = arith.constant 64 : i64
    %c256_i64_1575 = arith.constant 256 : i64
    %intptr_1576 = memref.extract_aligned_pointer_as_index %alloc_1567 : memref<1200x256xi8> -> index
    %445 = arith.index_cast %intptr_1576 : index to i64
    %intptr_1577 = memref.extract_aligned_pointer_as_index %fwd_cst_68 : memref<256x64xi8> -> index
    %446 = arith.index_cast %intptr_1577 : index to i64
    %intptr_1578 = memref.extract_aligned_pointer_as_index %fwd_cst_69 : memref<1200x64xi32> -> index
    %447 = arith.index_cast %intptr_1578 : index to i64
    %intptr_1579 = memref.extract_aligned_pointer_as_index %alloc_1568 : memref<1200x64xi8> -> index
    %448 = arith.index_cast %intptr_1579 : index to i64
    %c256_i64_1580 = arith.constant 256 : i64
    %c64_i64_1581 = arith.constant 64 : i64
    %c64_i64_1582 = arith.constant 64 : i64
    %c64_i64_1583 = arith.constant 64 : i64
    %cst_1584 = arith.constant 1.000000e+00 : f32
    %cst_1585 = arith.constant 1.000000e+00 : f32
    %cst_1586 = arith.constant 1.000000e+00 : f32
    %c0_i64_1587 = arith.constant 0 : i64
    %cst_1588 = arith.constant 0.0254192129 : f32
    %cst_1589 = arith.constant 0.000000e+00 : f32
    %c0_i64_1590 = arith.constant 0 : i64
    %c0_i64_1591 = arith.constant 0 : i64
    %c0_i64_1592 = arith.constant 0 : i64
    %c0_i64_1593 = arith.constant 0 : i64
    %c0_i64_1594 = arith.constant 0 : i64
    %c0_i64_1595 = arith.constant 0 : i64
    %c1_i64_1596 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1573, %c64_i64_1574, %c256_i64_1575, %445, %446, %447, %448, %c256_i64_1580, %c64_i64_1581, %c64_i64_1582, %c64_i64_1583, %cst_1584, %cst_1585, %cst_1586, %c0_i64_1587, %cst_1588, %cst_1589, %c0_i64_1590, %c0_i64_1591, %c0_i64_1592, %c0_i64_1593, %c0_i64_1594, %c0_i64_1595, %c1_i64_1596) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%443, %442, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1567 : memref<1200x256xi8>
    memref.dealloc %alloc_1568 : memref<1200x64xi8>
    %alloc_1597 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1598 = memref.extract_aligned_pointer_as_index %alloc_1597 : memref<1x30x40x64xf32> -> index
    %intptr_1599 = memref.extract_aligned_pointer_as_index %alloc_1566 : memref<1200x64xi8> -> index
    %449 = arith.index_cast %intptr_1598 : index to i64
    %450 = arith.index_cast %intptr_1599 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%449, %450, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_28) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1566 : memref<1200x64xi8>
    %alloc_1600 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1597[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1600[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1601 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1600, %alloc_1601 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1602 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1601[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %65[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1602[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1603 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1602[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1603[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1604 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1603[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1604[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1605 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_1604[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_1605[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1606 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1607 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1608 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1609 = memref.extract_aligned_pointer_as_index %alloc_1605 : memref<1x30x40x64xi8> -> index
    %451 = arith.index_cast %intptr_1609 : index to i64
    %intptr_1610 = memref.extract_aligned_pointer_as_index %alloc_1607 : memref<1200x64xi8> -> index
    %452 = arith.index_cast %intptr_1610 : index to i64
    %intptr_1611 = memref.extract_aligned_pointer_as_index %alloc_1608 : memref<1200x64xi8> -> index
    %453 = arith.index_cast %intptr_1611 : index to i64
    %intptr_1612 = memref.extract_aligned_pointer_as_index %alloc_1606 : memref<1200x64xi8> -> index
    %454 = arith.index_cast %intptr_1612 : index to i64
    call @buddy_rvv_memcpy_i8(%452, %451, %c76800_i64) : (i64, i64, i64) -> ()
    %455 = arith.addi %452, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%455, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1613 = arith.constant 1200 : i64
    %c64_i64_1614 = arith.constant 64 : i64
    %c64_i64_1615 = arith.constant 64 : i64
    %intptr_1616 = memref.extract_aligned_pointer_as_index %alloc_1607 : memref<1200x64xi8> -> index
    %456 = arith.index_cast %intptr_1616 : index to i64
    %intptr_1617 = memref.extract_aligned_pointer_as_index %fwd_cst_70 : memref<64x64xi8> -> index
    %457 = arith.index_cast %intptr_1617 : index to i64
    %intptr_1618 = memref.extract_aligned_pointer_as_index %fwd_cst_71 : memref<1200x64xi32> -> index
    %458 = arith.index_cast %intptr_1618 : index to i64
    %intptr_1619 = memref.extract_aligned_pointer_as_index %alloc_1608 : memref<1200x64xi8> -> index
    %459 = arith.index_cast %intptr_1619 : index to i64
    %c64_i64_1620 = arith.constant 64 : i64
    %c64_i64_1621 = arith.constant 64 : i64
    %c64_i64_1622 = arith.constant 64 : i64
    %c64_i64_1623 = arith.constant 64 : i64
    %cst_1624 = arith.constant 1.000000e+00 : f32
    %cst_1625 = arith.constant 1.000000e+00 : f32
    %cst_1626 = arith.constant 1.000000e+00 : f32
    %c0_i64_1627 = arith.constant 0 : i64
    %cst_1628 = arith.constant 0.00802434888 : f32
    %cst_1629 = arith.constant 0.000000e+00 : f32
    %c0_i64_1630 = arith.constant 0 : i64
    %c0_i64_1631 = arith.constant 0 : i64
    %c0_i64_1632 = arith.constant 0 : i64
    %c0_i64_1633 = arith.constant 0 : i64
    %c0_i64_1634 = arith.constant 0 : i64
    %c0_i64_1635 = arith.constant 0 : i64
    %c1_i64_1636 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1613, %c64_i64_1614, %c64_i64_1615, %456, %457, %458, %459, %c64_i64_1620, %c64_i64_1621, %c64_i64_1622, %c64_i64_1623, %cst_1624, %cst_1625, %cst_1626, %c0_i64_1627, %cst_1628, %cst_1629, %c0_i64_1630, %c0_i64_1631, %c0_i64_1632, %c0_i64_1633, %c0_i64_1634, %c0_i64_1635, %c1_i64_1636) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%454, %453, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1607 : memref<1200x64xi8>
    memref.dealloc %alloc_1608 : memref<1200x64xi8>
    %alloc_1637 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1638 = memref.extract_aligned_pointer_as_index %alloc_1637 : memref<1x30x40x64xf32> -> index
    %intptr_1639 = memref.extract_aligned_pointer_as_index %alloc_1606 : memref<1200x64xi8> -> index
    %460 = arith.index_cast %intptr_1638 : index to i64
    %461 = arith.index_cast %intptr_1639 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%460, %461, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_27) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1606 : memref<1200x64xi8>
    %alloc_1640 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1637[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1640[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1641 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1640, %alloc_1641 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1642 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1641[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %64[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1642[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1643 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1642[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1643[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1644 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1643[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1644[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1645 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_1644[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_1645[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1646 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_1646[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_1647 = memref.subview %alloc_1646[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_1645, %subview_1647 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_1648 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_73[%arg160] : memref<64xi32>
            memref.store %793, %alloc_1648[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_1649 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_1650 = arith.constant 1 : i64
    %c32_i64_1651 = arith.constant 32 : i64
    %c42_i64_1652 = arith.constant 42 : i64
    %c64_i64_1653 = arith.constant 64 : i64
    %c64_i64_1654 = arith.constant 64 : i64
    %c30_i64_1655 = arith.constant 30 : i64
    %c40_i64_1656 = arith.constant 40 : i64
    %c1_i64_1657 = arith.constant 1 : i64
    %c1_i64_1658 = arith.constant 1 : i64
    %c1_i64_1659 = arith.constant 1 : i64
    %c0_i64_1660 = arith.constant 0 : i64
    %c3_i64_1661 = arith.constant 3 : i64
    %c0_i64_1662 = arith.constant 0 : i64
    %c0_i64_1663 = arith.constant 0 : i64
    %c0_i64_1664 = arith.constant 0 : i64
    %c0_i64_1665 = arith.constant 0 : i64
    %c0_i64_1666 = arith.constant 0 : i64
    %intptr_1667 = memref.extract_aligned_pointer_as_index %alloc_1646 : memref<1x32x42x64xi8> -> index
    %462 = arith.index_cast %intptr_1667 : index to i64
    %intptr_1668 = memref.extract_aligned_pointer_as_index %fwd_cst_72 : memref<576x64xi8> -> index
    %463 = arith.index_cast %intptr_1668 : index to i64
    %intptr_1669 = memref.extract_aligned_pointer_as_index %fwd_cst_73 : memref<64xi32> -> index
    %464 = arith.index_cast %intptr_1669 : index to i64
    %intptr_1670 = memref.extract_aligned_pointer_as_index %alloc_1649 : memref<1200x64xi8> -> index
    %465 = arith.index_cast %intptr_1670 : index to i64
    %c0_i64_1671 = arith.constant 0 : i64
    %cst_1672 = arith.constant 0.00396349095 : f32
    %c0_i64_1673 = arith.constant 0 : i64
    %c0_i64_1674 = arith.constant 0 : i64
    %c0_i64_1675 = arith.constant 0 : i64
    %c1_i64_1676 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_1650, %c32_i64_1651, %c42_i64_1652, %c64_i64_1653, %c64_i64_1654, %c30_i64_1655, %c40_i64_1656, %c1_i64_1657, %c1_i64_1658, %c1_i64_1659, %c0_i64_1660, %c3_i64_1661, %c0_i64_1662, %c0_i64_1663, %c0_i64_1664, %c0_i64_1665, %c0_i64_1666, %462, %463, %464, %465, %c0_i64_1671, %cst_1672, %c0_i64_1673, %c0_i64_1674, %c0_i64_1675, %c1_i64_1676) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_1677 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1678 = memref.extract_aligned_pointer_as_index %alloc_1677 : memref<1x30x40x64xf32> -> index
    %intptr_1679 = memref.extract_aligned_pointer_as_index %alloc_1649 : memref<1200x64xi8> -> index
    %466 = arith.index_cast %intptr_1678 : index to i64
    %467 = arith.index_cast %intptr_1679 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%466, %467, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_26) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1649 : memref<1200x64xi8>
    %alloc_1680 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1677[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1680[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1681 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1680, %alloc_1681 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1682 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1681[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %63[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1682[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1683 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1682[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1683[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1684 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1683[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1684[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1685 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_1562[%arg157, %arg160, %arg158, %arg159] : memref<1x256x30x40xi8>
            memref.store %793, %alloc_1685[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x256xi8>
          }
        }
      }
    }
    %alloc_1686 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1687 = memref.alloc() {alignment = 64 : i64} : memref<1200x256xi8>
    %alloc_1688 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1689 = memref.extract_aligned_pointer_as_index %alloc_1685 : memref<1x30x40x256xi8> -> index
    %468 = arith.index_cast %intptr_1689 : index to i64
    %intptr_1690 = memref.extract_aligned_pointer_as_index %alloc_1687 : memref<1200x256xi8> -> index
    %469 = arith.index_cast %intptr_1690 : index to i64
    %intptr_1691 = memref.extract_aligned_pointer_as_index %alloc_1688 : memref<1200x64xi8> -> index
    %470 = arith.index_cast %intptr_1691 : index to i64
    %intptr_1692 = memref.extract_aligned_pointer_as_index %alloc_1686 : memref<1200x64xi8> -> index
    %471 = arith.index_cast %intptr_1692 : index to i64
    call @buddy_rvv_memcpy_i8(%469, %468, %c307200_i64) : (i64, i64, i64) -> ()
    %472 = arith.addi %469, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%472, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1693 = arith.constant 1200 : i64
    %c64_i64_1694 = arith.constant 64 : i64
    %c256_i64_1695 = arith.constant 256 : i64
    %intptr_1696 = memref.extract_aligned_pointer_as_index %alloc_1687 : memref<1200x256xi8> -> index
    %473 = arith.index_cast %intptr_1696 : index to i64
    %intptr_1697 = memref.extract_aligned_pointer_as_index %fwd_cst_74 : memref<256x64xi8> -> index
    %474 = arith.index_cast %intptr_1697 : index to i64
    %intptr_1698 = memref.extract_aligned_pointer_as_index %fwd_cst_75 : memref<1200x64xi32> -> index
    %475 = arith.index_cast %intptr_1698 : index to i64
    %intptr_1699 = memref.extract_aligned_pointer_as_index %alloc_1688 : memref<1200x64xi8> -> index
    %476 = arith.index_cast %intptr_1699 : index to i64
    %c256_i64_1700 = arith.constant 256 : i64
    %c64_i64_1701 = arith.constant 64 : i64
    %c64_i64_1702 = arith.constant 64 : i64
    %c64_i64_1703 = arith.constant 64 : i64
    %cst_1704 = arith.constant 1.000000e+00 : f32
    %cst_1705 = arith.constant 1.000000e+00 : f32
    %cst_1706 = arith.constant 1.000000e+00 : f32
    %c0_i64_1707 = arith.constant 0 : i64
    %cst_1708 = arith.constant 0.0107464846 : f32
    %cst_1709 = arith.constant 0.000000e+00 : f32
    %c0_i64_1710 = arith.constant 0 : i64
    %c0_i64_1711 = arith.constant 0 : i64
    %c0_i64_1712 = arith.constant 0 : i64
    %c0_i64_1713 = arith.constant 0 : i64
    %c0_i64_1714 = arith.constant 0 : i64
    %c0_i64_1715 = arith.constant 0 : i64
    %c1_i64_1716 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1693, %c64_i64_1694, %c256_i64_1695, %473, %474, %475, %476, %c256_i64_1700, %c64_i64_1701, %c64_i64_1702, %c64_i64_1703, %cst_1704, %cst_1705, %cst_1706, %c0_i64_1707, %cst_1708, %cst_1709, %c0_i64_1710, %c0_i64_1711, %c0_i64_1712, %c0_i64_1713, %c0_i64_1714, %c0_i64_1715, %c1_i64_1716) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%471, %470, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1687 : memref<1200x256xi8>
    memref.dealloc %alloc_1688 : memref<1200x64xi8>
    %alloc_1717 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1718 = memref.extract_aligned_pointer_as_index %alloc_1717 : memref<1x30x40x64xf32> -> index
    %intptr_1719 = memref.extract_aligned_pointer_as_index %alloc_1686 : memref<1200x64xi8> -> index
    %477 = arith.index_cast %intptr_1718 : index to i64
    %478 = arith.index_cast %intptr_1719 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%477, %478, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_26) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1686 : memref<1200x64xi8>
    %alloc_1720 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1717[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1720[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1721 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1720, %alloc_1721 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1722 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1721[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %62[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1722[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1723 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1722[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1723[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1724 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1723[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1724[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1725 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1684[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1725[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1726 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1725[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %61[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1726[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1727 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1726[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1727[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1728 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1727[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1728[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1729 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1728[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1729[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1730 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1729[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1730[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1731 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1724[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1731[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1732 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1731[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %60[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1732[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1733 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1732[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1733[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1734 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1733[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1734[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1735 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1734[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1735[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_1736 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1735[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1736[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1737 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_1738 = memref.subview %alloc_1737[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_1730, %subview_1738 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_1739 = memref.subview %alloc_1737[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_1736, %subview_1739 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_1740 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1737[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_1740[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1741 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1742 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1743 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_1744 = memref.extract_aligned_pointer_as_index %alloc_1740 : memref<1x30x40x128xi8> -> index
    %479 = arith.index_cast %intptr_1744 : index to i64
    %intptr_1745 = memref.extract_aligned_pointer_as_index %alloc_1742 : memref<1200x128xi8> -> index
    %480 = arith.index_cast %intptr_1745 : index to i64
    %intptr_1746 = memref.extract_aligned_pointer_as_index %alloc_1743 : memref<1200x128xi8> -> index
    %481 = arith.index_cast %intptr_1746 : index to i64
    %intptr_1747 = memref.extract_aligned_pointer_as_index %alloc_1741 : memref<1200x128xi8> -> index
    %482 = arith.index_cast %intptr_1747 : index to i64
    call @buddy_rvv_memcpy_i8(%480, %479, %c153600_i64) : (i64, i64, i64) -> ()
    %483 = arith.addi %480, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%483, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1748 = arith.constant 1200 : i64
    %c128_i64_1749 = arith.constant 128 : i64
    %c128_i64_1750 = arith.constant 128 : i64
    %intptr_1751 = memref.extract_aligned_pointer_as_index %alloc_1742 : memref<1200x128xi8> -> index
    %484 = arith.index_cast %intptr_1751 : index to i64
    %intptr_1752 = memref.extract_aligned_pointer_as_index %fwd_cst_76 : memref<128x128xi8> -> index
    %485 = arith.index_cast %intptr_1752 : index to i64
    %intptr_1753 = memref.extract_aligned_pointer_as_index %fwd_cst_77 : memref<1200x128xi32> -> index
    %486 = arith.index_cast %intptr_1753 : index to i64
    %intptr_1754 = memref.extract_aligned_pointer_as_index %alloc_1743 : memref<1200x128xi8> -> index
    %487 = arith.index_cast %intptr_1754 : index to i64
    %c128_i64_1755 = arith.constant 128 : i64
    %c128_i64_1756 = arith.constant 128 : i64
    %c128_i64_1757 = arith.constant 128 : i64
    %c128_i64_1758 = arith.constant 128 : i64
    %cst_1759 = arith.constant 1.000000e+00 : f32
    %cst_1760 = arith.constant 1.000000e+00 : f32
    %cst_1761 = arith.constant 1.000000e+00 : f32
    %c0_i64_1762 = arith.constant 0 : i64
    %cst_1763 = arith.constant 9.169820e-03 : f32
    %cst_1764 = arith.constant 0.000000e+00 : f32
    %c0_i64_1765 = arith.constant 0 : i64
    %c0_i64_1766 = arith.constant 0 : i64
    %c0_i64_1767 = arith.constant 0 : i64
    %c0_i64_1768 = arith.constant 0 : i64
    %c0_i64_1769 = arith.constant 0 : i64
    %c0_i64_1770 = arith.constant 0 : i64
    %c1_i64_1771 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1748, %c128_i64_1749, %c128_i64_1750, %484, %485, %486, %487, %c128_i64_1755, %c128_i64_1756, %c128_i64_1757, %c128_i64_1758, %cst_1759, %cst_1760, %cst_1761, %c0_i64_1762, %cst_1763, %cst_1764, %c0_i64_1765, %c0_i64_1766, %c0_i64_1767, %c0_i64_1768, %c0_i64_1769, %c0_i64_1770, %c1_i64_1771) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%482, %481, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1742 : memref<1200x128xi8>
    memref.dealloc %alloc_1743 : memref<1200x128xi8>
    %alloc_1772 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_1773 = memref.extract_aligned_pointer_as_index %alloc_1772 : memref<1x30x40x128xf32> -> index
    %intptr_1774 = memref.extract_aligned_pointer_as_index %alloc_1741 : memref<1200x128xi8> -> index
    %488 = arith.index_cast %intptr_1773 : index to i64
    %489 = arith.index_cast %intptr_1774 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%488, %489, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_25) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1741 : memref<1200x128xi8>
    %alloc_1775 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1772[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x128xf32>
            memref.store %793, %alloc_1775[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1776 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_1775, %alloc_1776 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_1777 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1776[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = memref.load %59[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1777[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1778 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1777[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1778[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_1779 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1778[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1779[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_1780 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1779[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_1780[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_1781 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_1782 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_1783 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_1784 = memref.extract_aligned_pointer_as_index %alloc_1780 : memref<1x30x40x128xi8> -> index
    %490 = arith.index_cast %intptr_1784 : index to i64
    %intptr_1785 = memref.extract_aligned_pointer_as_index %alloc_1782 : memref<1200x128xi8> -> index
    %491 = arith.index_cast %intptr_1785 : index to i64
    %intptr_1786 = memref.extract_aligned_pointer_as_index %alloc_1783 : memref<1200x64xi8> -> index
    %492 = arith.index_cast %intptr_1786 : index to i64
    %intptr_1787 = memref.extract_aligned_pointer_as_index %alloc_1781 : memref<1200x64xi8> -> index
    %493 = arith.index_cast %intptr_1787 : index to i64
    call @buddy_rvv_memcpy_i8(%491, %490, %c153600_i64) : (i64, i64, i64) -> ()
    %494 = arith.addi %491, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%494, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_1788 = arith.constant 1200 : i64
    %c64_i64_1789 = arith.constant 64 : i64
    %c128_i64_1790 = arith.constant 128 : i64
    %intptr_1791 = memref.extract_aligned_pointer_as_index %alloc_1782 : memref<1200x128xi8> -> index
    %495 = arith.index_cast %intptr_1791 : index to i64
    %intptr_1792 = memref.extract_aligned_pointer_as_index %fwd_cst_78 : memref<128x64xi8> -> index
    %496 = arith.index_cast %intptr_1792 : index to i64
    %intptr_1793 = memref.extract_aligned_pointer_as_index %fwd_cst_79 : memref<1200x64xi32> -> index
    %497 = arith.index_cast %intptr_1793 : index to i64
    %intptr_1794 = memref.extract_aligned_pointer_as_index %alloc_1783 : memref<1200x64xi8> -> index
    %498 = arith.index_cast %intptr_1794 : index to i64
    %c128_i64_1795 = arith.constant 128 : i64
    %c64_i64_1796 = arith.constant 64 : i64
    %c64_i64_1797 = arith.constant 64 : i64
    %c64_i64_1798 = arith.constant 64 : i64
    %cst_1799 = arith.constant 1.000000e+00 : f32
    %cst_1800 = arith.constant 1.000000e+00 : f32
    %cst_1801 = arith.constant 1.000000e+00 : f32
    %c0_i64_1802 = arith.constant 0 : i64
    %cst_1803 = arith.constant 5.732980e-03 : f32
    %cst_1804 = arith.constant 0.000000e+00 : f32
    %c0_i64_1805 = arith.constant 0 : i64
    %c0_i64_1806 = arith.constant 0 : i64
    %c0_i64_1807 = arith.constant 0 : i64
    %c0_i64_1808 = arith.constant 0 : i64
    %c0_i64_1809 = arith.constant 0 : i64
    %c0_i64_1810 = arith.constant 0 : i64
    %c1_i64_1811 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_1788, %c64_i64_1789, %c128_i64_1790, %495, %496, %497, %498, %c128_i64_1795, %c64_i64_1796, %c64_i64_1797, %c64_i64_1798, %cst_1799, %cst_1800, %cst_1801, %c0_i64_1802, %cst_1803, %cst_1804, %c0_i64_1805, %c0_i64_1806, %c0_i64_1807, %c0_i64_1808, %c0_i64_1809, %c0_i64_1810, %c1_i64_1811) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%493, %492, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1782 : memref<1200x128xi8>
    memref.dealloc %alloc_1783 : memref<1200x64xi8>
    %alloc_1812 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_1813 = memref.extract_aligned_pointer_as_index %alloc_1812 : memref<1x30x40x64xf32> -> index
    %intptr_1814 = memref.extract_aligned_pointer_as_index %alloc_1781 : memref<1200x64xi8> -> index
    %499 = arith.index_cast %intptr_1813 : index to i64
    %500 = arith.index_cast %intptr_1814 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%499, %500, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_24) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1781 : memref<1200x64xi8>
    %alloc_1815 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1812[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_1815[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1816 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_1815, %alloc_1816 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_1817 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1816[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %58[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1817[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1818 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1817[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1818[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_1819 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1818[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1819[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_1820 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_1819[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_1820[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_1821 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = arith.index_cast %arg158 : index to i32
            %794 = arith.index_cast %arg159 : index to i32
            %795 = arith.divsi %793, %c2_i32 : i32
            %796 = arith.muli %795, %c2_i32 : i32
            %797 = arith.subi %793, %796 : i32
            %798 = arith.divsi %794, %c2_i32 : i32
            %799 = arith.muli %798, %c2_i32 : i32
            %800 = arith.subi %794, %799 : i32
            %801 = arith.shli %797, %c1_i32 : i32
            %802 = arith.cmpi sge, %801, %c2_i32 : i32
            %803 = arith.extui %802 : i1 to i32
            %804 = arith.addi %795, %803 : i32
            %805 = arith.maxsi %804, %c0_i32 : i32
            %806 = arith.minsi %805, %c29_i32 : i32
            %807 = arith.index_cast %806 : i32 to index
            %808 = arith.shli %800, %c1_i32 : i32
            %809 = arith.cmpi sge, %808, %c2_i32 : i32
            %810 = arith.extui %809 : i1 to i32
            %811 = arith.addi %798, %810 : i32
            %812 = arith.maxsi %811, %c0_i32 : i32
            %813 = arith.minsi %812, %c39_i32 : i32
            %814 = arith.index_cast %813 : i32 to index
            %815 = memref.load %alloc_1820[%c0, %807, %814, %arg160] : memref<1x30x40x64xi8>
            memref.store %815, %alloc_1821[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_1822 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1821[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xi8>
            memref.store %793, %alloc_1822[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_1823 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1822[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1823[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1824 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1823[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %57[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1824[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1825 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1824[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1825[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1826 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1825[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1826[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1827 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1826[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1827[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1828 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1827[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1828[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_1829 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_710[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1829[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1830 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1829[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %56[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1830[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1831 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1830[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_1831[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1832 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1831[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_1832[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1833 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1832[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_1833[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
          }
        }
      }
    }
    %alloc_1834 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1833[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_1834[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_1835 = memref.alloc() {alignment = 64 : i64} : memref<1x128x60x80xi8>
    %subview_1836 = memref.subview %alloc_1835[0, 0, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    memref.copy %alloc_1828, %subview_1836 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    %subview_1837 = memref.subview %alloc_1835[0, 64, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    memref.copy %alloc_1834, %subview_1837 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    %alloc_1838 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1835[%arg157, %arg160, %arg158, %arg159] : memref<1x128x60x80xi8>
            memref.store %793, %alloc_1838[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x128xi8>
          }
        }
      }
    }
    %alloc_1839 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_1840 = memref.alloc() {alignment = 64 : i64} : memref<4800x128xi8>
    %alloc_1841 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_1842 = memref.extract_aligned_pointer_as_index %alloc_1838 : memref<1x60x80x128xi8> -> index
    %501 = arith.index_cast %intptr_1842 : index to i64
    %intptr_1843 = memref.extract_aligned_pointer_as_index %alloc_1840 : memref<4800x128xi8> -> index
    %502 = arith.index_cast %intptr_1843 : index to i64
    %intptr_1844 = memref.extract_aligned_pointer_as_index %alloc_1841 : memref<4800x32xi8> -> index
    %503 = arith.index_cast %intptr_1844 : index to i64
    %intptr_1845 = memref.extract_aligned_pointer_as_index %alloc_1839 : memref<4800x32xi8> -> index
    %504 = arith.index_cast %intptr_1845 : index to i64
    call @buddy_rvv_memcpy_i8(%502, %501, %c614400_i64) : (i64, i64, i64) -> ()
    %505 = arith.addi %502, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%505, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_1846 = arith.constant 4800 : i64
    %c32_i64_1847 = arith.constant 32 : i64
    %c128_i64_1848 = arith.constant 128 : i64
    %intptr_1849 = memref.extract_aligned_pointer_as_index %alloc_1840 : memref<4800x128xi8> -> index
    %506 = arith.index_cast %intptr_1849 : index to i64
    %intptr_1850 = memref.extract_aligned_pointer_as_index %fwd_cst_80 : memref<128x32xi8> -> index
    %507 = arith.index_cast %intptr_1850 : index to i64
    %intptr_1851 = memref.extract_aligned_pointer_as_index %fwd_cst_81 : memref<4800x32xi32> -> index
    %508 = arith.index_cast %intptr_1851 : index to i64
    %intptr_1852 = memref.extract_aligned_pointer_as_index %alloc_1841 : memref<4800x32xi8> -> index
    %509 = arith.index_cast %intptr_1852 : index to i64
    %c128_i64_1853 = arith.constant 128 : i64
    %c32_i64_1854 = arith.constant 32 : i64
    %c32_i64_1855 = arith.constant 32 : i64
    %c32_i64_1856 = arith.constant 32 : i64
    %cst_1857 = arith.constant 1.000000e+00 : f32
    %cst_1858 = arith.constant 1.000000e+00 : f32
    %cst_1859 = arith.constant 1.000000e+00 : f32
    %c0_i64_1860 = arith.constant 0 : i64
    %cst_1861 = arith.constant 8.340900e-03 : f32
    %cst_1862 = arith.constant 0.000000e+00 : f32
    %c0_i64_1863 = arith.constant 0 : i64
    %c0_i64_1864 = arith.constant 0 : i64
    %c0_i64_1865 = arith.constant 0 : i64
    %c0_i64_1866 = arith.constant 0 : i64
    %c0_i64_1867 = arith.constant 0 : i64
    %c0_i64_1868 = arith.constant 0 : i64
    %c1_i64_1869 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_1846, %c32_i64_1847, %c128_i64_1848, %506, %507, %508, %509, %c128_i64_1853, %c32_i64_1854, %c32_i64_1855, %c32_i64_1856, %cst_1857, %cst_1858, %cst_1859, %c0_i64_1860, %cst_1861, %cst_1862, %c0_i64_1863, %c0_i64_1864, %c0_i64_1865, %c0_i64_1866, %c0_i64_1867, %c0_i64_1868, %c1_i64_1869) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%504, %503, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1840 : memref<4800x128xi8>
    memref.dealloc %alloc_1841 : memref<4800x32xi8>
    %alloc_1870 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_1871 = memref.extract_aligned_pointer_as_index %alloc_1870 : memref<1x60x80x32xf32> -> index
    %intptr_1872 = memref.extract_aligned_pointer_as_index %alloc_1839 : memref<4800x32xi8> -> index
    %510 = arith.index_cast %intptr_1871 : index to i64
    %511 = arith.index_cast %intptr_1872 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%510, %511, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_23) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1839 : memref<4800x32xi8>
    %alloc_1873 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1870[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_1873[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1874 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_1873, %alloc_1874 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_1875 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1874[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %55[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1875[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1876 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1875[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1876[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1877 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1876[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1877[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_1878 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_1877[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_1878[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_1879 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_1880 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_1881 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_1882 = memref.extract_aligned_pointer_as_index %alloc_1878 : memref<1x60x80x32xi8> -> index
    %512 = arith.index_cast %intptr_1882 : index to i64
    %intptr_1883 = memref.extract_aligned_pointer_as_index %alloc_1880 : memref<4800x32xi8> -> index
    %513 = arith.index_cast %intptr_1883 : index to i64
    %intptr_1884 = memref.extract_aligned_pointer_as_index %alloc_1881 : memref<4800x32xi8> -> index
    %514 = arith.index_cast %intptr_1884 : index to i64
    %intptr_1885 = memref.extract_aligned_pointer_as_index %alloc_1879 : memref<4800x32xi8> -> index
    %515 = arith.index_cast %intptr_1885 : index to i64
    call @buddy_rvv_memcpy_i8(%513, %512, %c153600_i64) : (i64, i64, i64) -> ()
    %516 = arith.addi %513, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%516, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_1886 = arith.constant 4800 : i64
    %c32_i64_1887 = arith.constant 32 : i64
    %c32_i64_1888 = arith.constant 32 : i64
    %intptr_1889 = memref.extract_aligned_pointer_as_index %alloc_1880 : memref<4800x32xi8> -> index
    %517 = arith.index_cast %intptr_1889 : index to i64
    %intptr_1890 = memref.extract_aligned_pointer_as_index %fwd_cst_82 : memref<32x32xi8> -> index
    %518 = arith.index_cast %intptr_1890 : index to i64
    %intptr_1891 = memref.extract_aligned_pointer_as_index %fwd_cst_83 : memref<4800x32xi32> -> index
    %519 = arith.index_cast %intptr_1891 : index to i64
    %intptr_1892 = memref.extract_aligned_pointer_as_index %alloc_1881 : memref<4800x32xi8> -> index
    %520 = arith.index_cast %intptr_1892 : index to i64
    %c32_i64_1893 = arith.constant 32 : i64
    %c32_i64_1894 = arith.constant 32 : i64
    %c32_i64_1895 = arith.constant 32 : i64
    %c32_i64_1896 = arith.constant 32 : i64
    %cst_1897 = arith.constant 1.000000e+00 : f32
    %cst_1898 = arith.constant 1.000000e+00 : f32
    %cst_1899 = arith.constant 1.000000e+00 : f32
    %c0_i64_1900 = arith.constant 0 : i64
    %cst_1901 = arith.constant 0.0178376455 : f32
    %cst_1902 = arith.constant 0.000000e+00 : f32
    %c0_i64_1903 = arith.constant 0 : i64
    %c0_i64_1904 = arith.constant 0 : i64
    %c0_i64_1905 = arith.constant 0 : i64
    %c0_i64_1906 = arith.constant 0 : i64
    %c0_i64_1907 = arith.constant 0 : i64
    %c0_i64_1908 = arith.constant 0 : i64
    %c1_i64_1909 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_1886, %c32_i64_1887, %c32_i64_1888, %517, %518, %519, %520, %c32_i64_1893, %c32_i64_1894, %c32_i64_1895, %c32_i64_1896, %cst_1897, %cst_1898, %cst_1899, %c0_i64_1900, %cst_1901, %cst_1902, %c0_i64_1903, %c0_i64_1904, %c0_i64_1905, %c0_i64_1906, %c0_i64_1907, %c0_i64_1908, %c1_i64_1909) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%515, %514, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1880 : memref<4800x32xi8>
    memref.dealloc %alloc_1881 : memref<4800x32xi8>
    %alloc_1910 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_1911 = memref.extract_aligned_pointer_as_index %alloc_1910 : memref<1x60x80x32xf32> -> index
    %intptr_1912 = memref.extract_aligned_pointer_as_index %alloc_1879 : memref<4800x32xi8> -> index
    %521 = arith.index_cast %intptr_1911 : index to i64
    %522 = arith.index_cast %intptr_1912 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%521, %522, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_22) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1879 : memref<4800x32xi8>
    %alloc_1913 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1910[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_1913[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1914 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_1913, %alloc_1914 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_1915 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1914[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %54[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1915[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1916 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1915[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1916[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1917 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1916[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1917[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_1918 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %alloc_1917[%arg157, %arg160, %arg158, %arg159] : memref<1x32x60x80xi8>
            memref.store %793, %alloc_1918[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi8>
          }
        }
      }
    }
    %alloc_1919 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            memref.store %c0_i8, %alloc_1919[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x32xi8>
          }
        }
      }
    }
    %subview_1920 = memref.subview %alloc_1919[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_1918, %subview_1920 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_1921 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c32 step %c1 {
            %793 = memref.load %fwd_cst_85[%arg160] : memref<32xi32>
            memref.store %793, %alloc_1921[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x32xi32>
          }
        }
      }
    }
    %alloc_1922 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %c1_i64_1923 = arith.constant 1 : i64
    %c62_i64_1924 = arith.constant 62 : i64
    %c82_i64_1925 = arith.constant 82 : i64
    %c32_i64_1926 = arith.constant 32 : i64
    %c32_i64_1927 = arith.constant 32 : i64
    %c60_i64_1928 = arith.constant 60 : i64
    %c80_i64_1929 = arith.constant 80 : i64
    %c1_i64_1930 = arith.constant 1 : i64
    %c1_i64_1931 = arith.constant 1 : i64
    %c1_i64_1932 = arith.constant 1 : i64
    %c0_i64_1933 = arith.constant 0 : i64
    %c3_i64_1934 = arith.constant 3 : i64
    %c0_i64_1935 = arith.constant 0 : i64
    %c0_i64_1936 = arith.constant 0 : i64
    %c0_i64_1937 = arith.constant 0 : i64
    %c0_i64_1938 = arith.constant 0 : i64
    %c0_i64_1939 = arith.constant 0 : i64
    %intptr_1940 = memref.extract_aligned_pointer_as_index %alloc_1919 : memref<1x62x82x32xi8> -> index
    %523 = arith.index_cast %intptr_1940 : index to i64
    %intptr_1941 = memref.extract_aligned_pointer_as_index %fwd_cst_84 : memref<288x32xi8> -> index
    %524 = arith.index_cast %intptr_1941 : index to i64
    %intptr_1942 = memref.extract_aligned_pointer_as_index %fwd_cst_85 : memref<32xi32> -> index
    %525 = arith.index_cast %intptr_1942 : index to i64
    %intptr_1943 = memref.extract_aligned_pointer_as_index %alloc_1922 : memref<4800x32xi8> -> index
    %526 = arith.index_cast %intptr_1943 : index to i64
    %c0_i64_1944 = arith.constant 0 : i64
    %cst_1945 = arith.constant 0.007817436 : f32
    %c0_i64_1946 = arith.constant 0 : i64
    %c0_i64_1947 = arith.constant 0 : i64
    %c0_i64_1948 = arith.constant 0 : i64
    %c1_i64_1949 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_1923, %c62_i64_1924, %c82_i64_1925, %c32_i64_1926, %c32_i64_1927, %c60_i64_1928, %c80_i64_1929, %c1_i64_1930, %c1_i64_1931, %c1_i64_1932, %c0_i64_1933, %c3_i64_1934, %c0_i64_1935, %c0_i64_1936, %c0_i64_1937, %c0_i64_1938, %c0_i64_1939, %523, %524, %525, %526, %c0_i64_1944, %cst_1945, %c0_i64_1946, %c0_i64_1947, %c0_i64_1948, %c1_i64_1949) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_1950 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_1951 = memref.extract_aligned_pointer_as_index %alloc_1950 : memref<1x60x80x32xf32> -> index
    %intptr_1952 = memref.extract_aligned_pointer_as_index %alloc_1922 : memref<4800x32xi8> -> index
    %527 = arith.index_cast %intptr_1951 : index to i64
    %528 = arith.index_cast %intptr_1952 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%527, %528, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_21) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1922 : memref<4800x32xi8>
    %alloc_1953 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1950[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_1953[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1954 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_1953, %alloc_1954 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_1955 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1954[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %53[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1955[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1956 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1955[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1956[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1957 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1956[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1957[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_1958 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_1835[%arg157, %arg160, %arg158, %arg159] : memref<1x128x60x80xi8>
            memref.store %793, %alloc_1958[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x128xi8>
          }
        }
      }
    }
    %alloc_1959 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %alloc_1960 = memref.alloc() {alignment = 64 : i64} : memref<4800x128xi8>
    %alloc_1961 = memref.alloc() {alignment = 64 : i64} : memref<4800x32xi8>
    %intptr_1962 = memref.extract_aligned_pointer_as_index %alloc_1958 : memref<1x60x80x128xi8> -> index
    %529 = arith.index_cast %intptr_1962 : index to i64
    %intptr_1963 = memref.extract_aligned_pointer_as_index %alloc_1960 : memref<4800x128xi8> -> index
    %530 = arith.index_cast %intptr_1963 : index to i64
    %intptr_1964 = memref.extract_aligned_pointer_as_index %alloc_1961 : memref<4800x32xi8> -> index
    %531 = arith.index_cast %intptr_1964 : index to i64
    %intptr_1965 = memref.extract_aligned_pointer_as_index %alloc_1959 : memref<4800x32xi8> -> index
    %532 = arith.index_cast %intptr_1965 : index to i64
    call @buddy_rvv_memcpy_i8(%530, %529, %c614400_i64) : (i64, i64, i64) -> ()
    %533 = arith.addi %530, %c614400_i64 : i64
    call @buddy_rvv_memset_i8(%533, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_1966 = arith.constant 4800 : i64
    %c32_i64_1967 = arith.constant 32 : i64
    %c128_i64_1968 = arith.constant 128 : i64
    %intptr_1969 = memref.extract_aligned_pointer_as_index %alloc_1960 : memref<4800x128xi8> -> index
    %534 = arith.index_cast %intptr_1969 : index to i64
    %intptr_1970 = memref.extract_aligned_pointer_as_index %fwd_cst_86 : memref<128x32xi8> -> index
    %535 = arith.index_cast %intptr_1970 : index to i64
    %intptr_1971 = memref.extract_aligned_pointer_as_index %fwd_cst_87 : memref<4800x32xi32> -> index
    %536 = arith.index_cast %intptr_1971 : index to i64
    %intptr_1972 = memref.extract_aligned_pointer_as_index %alloc_1961 : memref<4800x32xi8> -> index
    %537 = arith.index_cast %intptr_1972 : index to i64
    %c128_i64_1973 = arith.constant 128 : i64
    %c32_i64_1974 = arith.constant 32 : i64
    %c32_i64_1975 = arith.constant 32 : i64
    %c32_i64_1976 = arith.constant 32 : i64
    %cst_1977 = arith.constant 1.000000e+00 : f32
    %cst_1978 = arith.constant 1.000000e+00 : f32
    %cst_1979 = arith.constant 1.000000e+00 : f32
    %c0_i64_1980 = arith.constant 0 : i64
    %cst_1981 = arith.constant 0.00953922048 : f32
    %cst_1982 = arith.constant 0.000000e+00 : f32
    %c0_i64_1983 = arith.constant 0 : i64
    %c0_i64_1984 = arith.constant 0 : i64
    %c0_i64_1985 = arith.constant 0 : i64
    %c0_i64_1986 = arith.constant 0 : i64
    %c0_i64_1987 = arith.constant 0 : i64
    %c0_i64_1988 = arith.constant 0 : i64
    %c1_i64_1989 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_1966, %c32_i64_1967, %c128_i64_1968, %534, %535, %536, %537, %c128_i64_1973, %c32_i64_1974, %c32_i64_1975, %c32_i64_1976, %cst_1977, %cst_1978, %cst_1979, %c0_i64_1980, %cst_1981, %cst_1982, %c0_i64_1983, %c0_i64_1984, %c0_i64_1985, %c0_i64_1986, %c0_i64_1987, %c0_i64_1988, %c1_i64_1989) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%532, %531, %c4800_i64, %c32_i64, %c32_i64, %c32_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_1960 : memref<4800x128xi8>
    memref.dealloc %alloc_1961 : memref<4800x32xi8>
    %alloc_1990 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    %intptr_1991 = memref.extract_aligned_pointer_as_index %alloc_1990 : memref<1x60x80x32xf32> -> index
    %intptr_1992 = memref.extract_aligned_pointer_as_index %alloc_1959 : memref<4800x32xi8> -> index
    %538 = arith.index_cast %intptr_1991 : index to i64
    %539 = arith.index_cast %intptr_1992 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%538, %539, %c1_i64, %c60_i64, %c80_i64, %c32_i64, %cst_21) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_1959 : memref<4800x32xi8>
    %alloc_1993 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1990[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x32xf32>
            memref.store %793, %alloc_1993[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1994 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    memref.copy %alloc_1993, %alloc_1994 : memref<1x32x60x80xf32> to memref<1x32x60x80xf32>
    %alloc_1995 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1994[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = memref.load %52[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_1995[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1996 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1995[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_1996[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
          }
        }
      }
    }
    %alloc_1997 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1996[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_1997[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_1998 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1957[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_1998[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_1999 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1998[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %51[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_1999[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2000 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1999[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2000[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2001 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2000[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2001[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2002 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2001[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2002[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2003 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2002[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2003[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_2004 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_1997[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2004[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2005 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2004[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %50[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2005[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2006 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2005[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2006[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2007 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2006[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2007[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2008 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2007[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2008[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
          }
        }
      }
    }
    %alloc_2009 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2008[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2009[%arg157, %arg158, %arg159, %arg160] : memref<1x32x60x80xi8>
          }
        }
      }
    }
    %alloc_2010 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_2011 = memref.subview %alloc_2010[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_2003, %subview_2011 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_2012 = memref.subview %alloc_2010[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_2009, %subview_2012 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_2013 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2010[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2013[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2014 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_2015 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_2016 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_2017 = memref.extract_aligned_pointer_as_index %alloc_2013 : memref<1x60x80x64xi8> -> index
    %540 = arith.index_cast %intptr_2017 : index to i64
    %intptr_2018 = memref.extract_aligned_pointer_as_index %alloc_2015 : memref<4800x64xi8> -> index
    %541 = arith.index_cast %intptr_2018 : index to i64
    %intptr_2019 = memref.extract_aligned_pointer_as_index %alloc_2016 : memref<4800x64xi8> -> index
    %542 = arith.index_cast %intptr_2019 : index to i64
    %intptr_2020 = memref.extract_aligned_pointer_as_index %alloc_2014 : memref<4800x64xi8> -> index
    %543 = arith.index_cast %intptr_2020 : index to i64
    call @buddy_rvv_memcpy_i8(%541, %540, %c307200_i64) : (i64, i64, i64) -> ()
    %544 = arith.addi %541, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%544, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_2021 = arith.constant 4800 : i64
    %c64_i64_2022 = arith.constant 64 : i64
    %c64_i64_2023 = arith.constant 64 : i64
    %intptr_2024 = memref.extract_aligned_pointer_as_index %alloc_2015 : memref<4800x64xi8> -> index
    %545 = arith.index_cast %intptr_2024 : index to i64
    %intptr_2025 = memref.extract_aligned_pointer_as_index %fwd_cst_88 : memref<64x64xi8> -> index
    %546 = arith.index_cast %intptr_2025 : index to i64
    %intptr_2026 = memref.extract_aligned_pointer_as_index %fwd_cst_89 : memref<4800x64xi32> -> index
    %547 = arith.index_cast %intptr_2026 : index to i64
    %intptr_2027 = memref.extract_aligned_pointer_as_index %alloc_2016 : memref<4800x64xi8> -> index
    %548 = arith.index_cast %intptr_2027 : index to i64
    %c64_i64_2028 = arith.constant 64 : i64
    %c64_i64_2029 = arith.constant 64 : i64
    %c64_i64_2030 = arith.constant 64 : i64
    %c64_i64_2031 = arith.constant 64 : i64
    %cst_2032 = arith.constant 1.000000e+00 : f32
    %cst_2033 = arith.constant 1.000000e+00 : f32
    %cst_2034 = arith.constant 1.000000e+00 : f32
    %c0_i64_2035 = arith.constant 0 : i64
    %cst_2036 = arith.constant 0.0133869769 : f32
    %cst_2037 = arith.constant 0.000000e+00 : f32
    %c0_i64_2038 = arith.constant 0 : i64
    %c0_i64_2039 = arith.constant 0 : i64
    %c0_i64_2040 = arith.constant 0 : i64
    %c0_i64_2041 = arith.constant 0 : i64
    %c0_i64_2042 = arith.constant 0 : i64
    %c0_i64_2043 = arith.constant 0 : i64
    %c1_i64_2044 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_2021, %c64_i64_2022, %c64_i64_2023, %545, %546, %547, %548, %c64_i64_2028, %c64_i64_2029, %c64_i64_2030, %c64_i64_2031, %cst_2032, %cst_2033, %cst_2034, %c0_i64_2035, %cst_2036, %cst_2037, %c0_i64_2038, %c0_i64_2039, %c0_i64_2040, %c0_i64_2041, %c0_i64_2042, %c0_i64_2043, %c1_i64_2044) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%543, %542, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2015 : memref<4800x64xi8>
    memref.dealloc %alloc_2016 : memref<4800x64xi8>
    %alloc_2045 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_2046 = memref.extract_aligned_pointer_as_index %alloc_2045 : memref<1x60x80x64xf32> -> index
    %intptr_2047 = memref.extract_aligned_pointer_as_index %alloc_2014 : memref<4800x64xi8> -> index
    %549 = arith.index_cast %intptr_2046 : index to i64
    %550 = arith.index_cast %intptr_2047 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%549, %550, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_20) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2014 : memref<4800x64xi8>
    %alloc_2048 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2045[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_2048[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2049 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_2048, %alloc_2049 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_2050 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2049[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = memref.load %49[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2050[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2051 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2050[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2051[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2052 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2051[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2052[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_2053 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2052[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2053[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2054 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c61 step %c1 {
        scf.for %arg159 = %c0 to %c81 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2054[%arg157, %arg158, %arg159, %arg160] : memref<1x61x81x64xi8>
          }
        }
      }
    }
    %subview_2055 = memref.subview %alloc_2054[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_2053, %subview_2055 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_2056 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_91[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2056[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_2057 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_2058 = arith.constant 1 : i64
    %c61_i64_2059 = arith.constant 61 : i64
    %c81_i64_2060 = arith.constant 81 : i64
    %c64_i64_2061 = arith.constant 64 : i64
    %c64_i64_2062 = arith.constant 64 : i64
    %c30_i64_2063 = arith.constant 30 : i64
    %c40_i64_2064 = arith.constant 40 : i64
    %c2_i64_2065 = arith.constant 2 : i64
    %c1_i64_2066 = arith.constant 1 : i64
    %c1_i64_2067 = arith.constant 1 : i64
    %c0_i64_2068 = arith.constant 0 : i64
    %c3_i64_2069 = arith.constant 3 : i64
    %c0_i64_2070 = arith.constant 0 : i64
    %c0_i64_2071 = arith.constant 0 : i64
    %c0_i64_2072 = arith.constant 0 : i64
    %c0_i64_2073 = arith.constant 0 : i64
    %c0_i64_2074 = arith.constant 0 : i64
    %intptr_2075 = memref.extract_aligned_pointer_as_index %alloc_2054 : memref<1x61x81x64xi8> -> index
    %551 = arith.index_cast %intptr_2075 : index to i64
    %intptr_2076 = memref.extract_aligned_pointer_as_index %fwd_cst_90 : memref<576x64xi8> -> index
    %552 = arith.index_cast %intptr_2076 : index to i64
    %intptr_2077 = memref.extract_aligned_pointer_as_index %fwd_cst_91 : memref<64xi32> -> index
    %553 = arith.index_cast %intptr_2077 : index to i64
    %intptr_2078 = memref.extract_aligned_pointer_as_index %alloc_2057 : memref<1200x64xi8> -> index
    %554 = arith.index_cast %intptr_2078 : index to i64
    %c0_i64_2079 = arith.constant 0 : i64
    %cst_2080 = arith.constant 0.00338776759 : f32
    %c0_i64_2081 = arith.constant 0 : i64
    %c0_i64_2082 = arith.constant 0 : i64
    %c0_i64_2083 = arith.constant 0 : i64
    %c1_i64_2084 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2058, %c61_i64_2059, %c81_i64_2060, %c64_i64_2061, %c64_i64_2062, %c30_i64_2063, %c40_i64_2064, %c2_i64_2065, %c1_i64_2066, %c1_i64_2067, %c0_i64_2068, %c3_i64_2069, %c0_i64_2070, %c0_i64_2071, %c0_i64_2072, %c0_i64_2073, %c0_i64_2074, %551, %552, %553, %554, %c0_i64_2079, %cst_2080, %c0_i64_2081, %c0_i64_2082, %c0_i64_2083, %c1_i64_2084) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2085 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2086 = memref.extract_aligned_pointer_as_index %alloc_2085 : memref<1x30x40x64xf32> -> index
    %intptr_2087 = memref.extract_aligned_pointer_as_index %alloc_2057 : memref<1200x64xi8> -> index
    %555 = arith.index_cast %intptr_2086 : index to i64
    %556 = arith.index_cast %intptr_2087 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%555, %556, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_19) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2057 : memref<1200x64xi8>
    %alloc_2088 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2085[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2088[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2089 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2088, %alloc_2089 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2090 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2089[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %48[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2090[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2091 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2090[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2091[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2092 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2091[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2092[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2093 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2092[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2093[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2094 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2093[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %47[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2094[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2095 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2094[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2095[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2096 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2095[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2096[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2097 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2096[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2097[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2098 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2097[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2098[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2099 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_1819[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2099[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2100 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2099[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %46[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2100[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2101 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2100[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2101[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2102 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2101[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2102[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2103 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2102[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2103[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2104 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2103[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2104[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2105 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_2106 = memref.subview %alloc_2105[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_2098, %subview_2106 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_2107 = memref.subview %alloc_2105[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_2104, %subview_2107 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_2108 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2105[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_2108[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_2109 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2110 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_2111 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_2112 = memref.extract_aligned_pointer_as_index %alloc_2108 : memref<1x30x40x128xi8> -> index
    %557 = arith.index_cast %intptr_2112 : index to i64
    %intptr_2113 = memref.extract_aligned_pointer_as_index %alloc_2110 : memref<1200x128xi8> -> index
    %558 = arith.index_cast %intptr_2113 : index to i64
    %intptr_2114 = memref.extract_aligned_pointer_as_index %alloc_2111 : memref<1200x64xi8> -> index
    %559 = arith.index_cast %intptr_2114 : index to i64
    %intptr_2115 = memref.extract_aligned_pointer_as_index %alloc_2109 : memref<1200x64xi8> -> index
    %560 = arith.index_cast %intptr_2115 : index to i64
    call @buddy_rvv_memcpy_i8(%558, %557, %c153600_i64) : (i64, i64, i64) -> ()
    %561 = arith.addi %558, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%561, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_2116 = arith.constant 1200 : i64
    %c64_i64_2117 = arith.constant 64 : i64
    %c128_i64_2118 = arith.constant 128 : i64
    %intptr_2119 = memref.extract_aligned_pointer_as_index %alloc_2110 : memref<1200x128xi8> -> index
    %562 = arith.index_cast %intptr_2119 : index to i64
    %intptr_2120 = memref.extract_aligned_pointer_as_index %fwd_cst_92 : memref<128x64xi8> -> index
    %563 = arith.index_cast %intptr_2120 : index to i64
    %intptr_2121 = memref.extract_aligned_pointer_as_index %fwd_cst_93 : memref<1200x64xi32> -> index
    %564 = arith.index_cast %intptr_2121 : index to i64
    %intptr_2122 = memref.extract_aligned_pointer_as_index %alloc_2111 : memref<1200x64xi8> -> index
    %565 = arith.index_cast %intptr_2122 : index to i64
    %c128_i64_2123 = arith.constant 128 : i64
    %c64_i64_2124 = arith.constant 64 : i64
    %c64_i64_2125 = arith.constant 64 : i64
    %c64_i64_2126 = arith.constant 64 : i64
    %cst_2127 = arith.constant 1.000000e+00 : f32
    %cst_2128 = arith.constant 1.000000e+00 : f32
    %cst_2129 = arith.constant 1.000000e+00 : f32
    %c0_i64_2130 = arith.constant 0 : i64
    %cst_2131 = arith.constant 0.00869756192 : f32
    %cst_2132 = arith.constant 0.000000e+00 : f32
    %c0_i64_2133 = arith.constant 0 : i64
    %c0_i64_2134 = arith.constant 0 : i64
    %c0_i64_2135 = arith.constant 0 : i64
    %c0_i64_2136 = arith.constant 0 : i64
    %c0_i64_2137 = arith.constant 0 : i64
    %c0_i64_2138 = arith.constant 0 : i64
    %c1_i64_2139 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_2116, %c64_i64_2117, %c128_i64_2118, %562, %563, %564, %565, %c128_i64_2123, %c64_i64_2124, %c64_i64_2125, %c64_i64_2126, %cst_2127, %cst_2128, %cst_2129, %c0_i64_2130, %cst_2131, %cst_2132, %c0_i64_2133, %c0_i64_2134, %c0_i64_2135, %c0_i64_2136, %c0_i64_2137, %c0_i64_2138, %c1_i64_2139) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%560, %559, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2110 : memref<1200x128xi8>
    memref.dealloc %alloc_2111 : memref<1200x64xi8>
    %alloc_2140 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2141 = memref.extract_aligned_pointer_as_index %alloc_2140 : memref<1x30x40x64xf32> -> index
    %intptr_2142 = memref.extract_aligned_pointer_as_index %alloc_2109 : memref<1200x64xi8> -> index
    %566 = arith.index_cast %intptr_2141 : index to i64
    %567 = arith.index_cast %intptr_2142 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%566, %567, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_18) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2109 : memref<1200x64xi8>
    %alloc_2143 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2140[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2143[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2144 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2143, %alloc_2144 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2145 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2144[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %45[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2145[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2146 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2145[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2146[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2147 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2146[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2147[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2148 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2147[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_2148[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_2149 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2150 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2151 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_2152 = memref.extract_aligned_pointer_as_index %alloc_2148 : memref<1x30x40x64xi8> -> index
    %568 = arith.index_cast %intptr_2152 : index to i64
    %intptr_2153 = memref.extract_aligned_pointer_as_index %alloc_2150 : memref<1200x64xi8> -> index
    %569 = arith.index_cast %intptr_2153 : index to i64
    %intptr_2154 = memref.extract_aligned_pointer_as_index %alloc_2151 : memref<1200x64xi8> -> index
    %570 = arith.index_cast %intptr_2154 : index to i64
    %intptr_2155 = memref.extract_aligned_pointer_as_index %alloc_2149 : memref<1200x64xi8> -> index
    %571 = arith.index_cast %intptr_2155 : index to i64
    call @buddy_rvv_memcpy_i8(%569, %568, %c76800_i64) : (i64, i64, i64) -> ()
    %572 = arith.addi %569, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%572, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_2156 = arith.constant 1200 : i64
    %c64_i64_2157 = arith.constant 64 : i64
    %c64_i64_2158 = arith.constant 64 : i64
    %intptr_2159 = memref.extract_aligned_pointer_as_index %alloc_2150 : memref<1200x64xi8> -> index
    %573 = arith.index_cast %intptr_2159 : index to i64
    %intptr_2160 = memref.extract_aligned_pointer_as_index %fwd_cst_94 : memref<64x64xi8> -> index
    %574 = arith.index_cast %intptr_2160 : index to i64
    %intptr_2161 = memref.extract_aligned_pointer_as_index %fwd_cst_95 : memref<1200x64xi32> -> index
    %575 = arith.index_cast %intptr_2161 : index to i64
    %intptr_2162 = memref.extract_aligned_pointer_as_index %alloc_2151 : memref<1200x64xi8> -> index
    %576 = arith.index_cast %intptr_2162 : index to i64
    %c64_i64_2163 = arith.constant 64 : i64
    %c64_i64_2164 = arith.constant 64 : i64
    %c64_i64_2165 = arith.constant 64 : i64
    %c64_i64_2166 = arith.constant 64 : i64
    %cst_2167 = arith.constant 1.000000e+00 : f32
    %cst_2168 = arith.constant 1.000000e+00 : f32
    %cst_2169 = arith.constant 1.000000e+00 : f32
    %c0_i64_2170 = arith.constant 0 : i64
    %cst_2171 = arith.constant 0.0079792682 : f32
    %cst_2172 = arith.constant 0.000000e+00 : f32
    %c0_i64_2173 = arith.constant 0 : i64
    %c0_i64_2174 = arith.constant 0 : i64
    %c0_i64_2175 = arith.constant 0 : i64
    %c0_i64_2176 = arith.constant 0 : i64
    %c0_i64_2177 = arith.constant 0 : i64
    %c0_i64_2178 = arith.constant 0 : i64
    %c1_i64_2179 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_2156, %c64_i64_2157, %c64_i64_2158, %573, %574, %575, %576, %c64_i64_2163, %c64_i64_2164, %c64_i64_2165, %c64_i64_2166, %cst_2167, %cst_2168, %cst_2169, %c0_i64_2170, %cst_2171, %cst_2172, %c0_i64_2173, %c0_i64_2174, %c0_i64_2175, %c0_i64_2176, %c0_i64_2177, %c0_i64_2178, %c1_i64_2179) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%571, %570, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2150 : memref<1200x64xi8>
    memref.dealloc %alloc_2151 : memref<1200x64xi8>
    %alloc_2180 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2181 = memref.extract_aligned_pointer_as_index %alloc_2180 : memref<1x30x40x64xf32> -> index
    %intptr_2182 = memref.extract_aligned_pointer_as_index %alloc_2149 : memref<1200x64xi8> -> index
    %577 = arith.index_cast %intptr_2181 : index to i64
    %578 = arith.index_cast %intptr_2182 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%577, %578, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_17) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2149 : memref<1200x64xi8>
    %alloc_2183 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2180[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2183[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2184 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2183, %alloc_2184 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2185 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2184[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %44[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2185[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2186 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2185[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2186[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2187 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2186[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2187[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2188 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2187[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_2188[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_2189 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2189[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_2190 = memref.subview %alloc_2189[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_2188, %subview_2190 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_2191 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_97[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2191[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_2192 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_2193 = arith.constant 1 : i64
    %c32_i64_2194 = arith.constant 32 : i64
    %c42_i64_2195 = arith.constant 42 : i64
    %c64_i64_2196 = arith.constant 64 : i64
    %c64_i64_2197 = arith.constant 64 : i64
    %c30_i64_2198 = arith.constant 30 : i64
    %c40_i64_2199 = arith.constant 40 : i64
    %c1_i64_2200 = arith.constant 1 : i64
    %c1_i64_2201 = arith.constant 1 : i64
    %c1_i64_2202 = arith.constant 1 : i64
    %c0_i64_2203 = arith.constant 0 : i64
    %c3_i64_2204 = arith.constant 3 : i64
    %c0_i64_2205 = arith.constant 0 : i64
    %c0_i64_2206 = arith.constant 0 : i64
    %c0_i64_2207 = arith.constant 0 : i64
    %c0_i64_2208 = arith.constant 0 : i64
    %c0_i64_2209 = arith.constant 0 : i64
    %intptr_2210 = memref.extract_aligned_pointer_as_index %alloc_2189 : memref<1x32x42x64xi8> -> index
    %579 = arith.index_cast %intptr_2210 : index to i64
    %intptr_2211 = memref.extract_aligned_pointer_as_index %fwd_cst_96 : memref<576x64xi8> -> index
    %580 = arith.index_cast %intptr_2211 : index to i64
    %intptr_2212 = memref.extract_aligned_pointer_as_index %fwd_cst_97 : memref<64xi32> -> index
    %581 = arith.index_cast %intptr_2212 : index to i64
    %intptr_2213 = memref.extract_aligned_pointer_as_index %alloc_2192 : memref<1200x64xi8> -> index
    %582 = arith.index_cast %intptr_2213 : index to i64
    %c0_i64_2214 = arith.constant 0 : i64
    %cst_2215 = arith.constant 0.0050264271 : f32
    %c0_i64_2216 = arith.constant 0 : i64
    %c0_i64_2217 = arith.constant 0 : i64
    %c0_i64_2218 = arith.constant 0 : i64
    %c1_i64_2219 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2193, %c32_i64_2194, %c42_i64_2195, %c64_i64_2196, %c64_i64_2197, %c30_i64_2198, %c40_i64_2199, %c1_i64_2200, %c1_i64_2201, %c1_i64_2202, %c0_i64_2203, %c3_i64_2204, %c0_i64_2205, %c0_i64_2206, %c0_i64_2207, %c0_i64_2208, %c0_i64_2209, %579, %580, %581, %582, %c0_i64_2214, %cst_2215, %c0_i64_2216, %c0_i64_2217, %c0_i64_2218, %c1_i64_2219) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2220 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2221 = memref.extract_aligned_pointer_as_index %alloc_2220 : memref<1x30x40x64xf32> -> index
    %intptr_2222 = memref.extract_aligned_pointer_as_index %alloc_2192 : memref<1200x64xi8> -> index
    %583 = arith.index_cast %intptr_2221 : index to i64
    %584 = arith.index_cast %intptr_2222 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%583, %584, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_16) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2192 : memref<1200x64xi8>
    %alloc_2223 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2220[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2223[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2224 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2223, %alloc_2224 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2225 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2224[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %43[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2225[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2226 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2225[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2226[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2227 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2226[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2227[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2228 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2105[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_2228[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_2229 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2230 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_2231 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_2232 = memref.extract_aligned_pointer_as_index %alloc_2228 : memref<1x30x40x128xi8> -> index
    %585 = arith.index_cast %intptr_2232 : index to i64
    %intptr_2233 = memref.extract_aligned_pointer_as_index %alloc_2230 : memref<1200x128xi8> -> index
    %586 = arith.index_cast %intptr_2233 : index to i64
    %intptr_2234 = memref.extract_aligned_pointer_as_index %alloc_2231 : memref<1200x64xi8> -> index
    %587 = arith.index_cast %intptr_2234 : index to i64
    %intptr_2235 = memref.extract_aligned_pointer_as_index %alloc_2229 : memref<1200x64xi8> -> index
    %588 = arith.index_cast %intptr_2235 : index to i64
    call @buddy_rvv_memcpy_i8(%586, %585, %c153600_i64) : (i64, i64, i64) -> ()
    %589 = arith.addi %586, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%589, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_2236 = arith.constant 1200 : i64
    %c64_i64_2237 = arith.constant 64 : i64
    %c128_i64_2238 = arith.constant 128 : i64
    %intptr_2239 = memref.extract_aligned_pointer_as_index %alloc_2230 : memref<1200x128xi8> -> index
    %590 = arith.index_cast %intptr_2239 : index to i64
    %intptr_2240 = memref.extract_aligned_pointer_as_index %fwd_cst_98 : memref<128x64xi8> -> index
    %591 = arith.index_cast %intptr_2240 : index to i64
    %intptr_2241 = memref.extract_aligned_pointer_as_index %fwd_cst_99 : memref<1200x64xi32> -> index
    %592 = arith.index_cast %intptr_2241 : index to i64
    %intptr_2242 = memref.extract_aligned_pointer_as_index %alloc_2231 : memref<1200x64xi8> -> index
    %593 = arith.index_cast %intptr_2242 : index to i64
    %c128_i64_2243 = arith.constant 128 : i64
    %c64_i64_2244 = arith.constant 64 : i64
    %c64_i64_2245 = arith.constant 64 : i64
    %c64_i64_2246 = arith.constant 64 : i64
    %cst_2247 = arith.constant 1.000000e+00 : f32
    %cst_2248 = arith.constant 1.000000e+00 : f32
    %cst_2249 = arith.constant 1.000000e+00 : f32
    %c0_i64_2250 = arith.constant 0 : i64
    %cst_2251 = arith.constant 0.00879147648 : f32
    %cst_2252 = arith.constant 0.000000e+00 : f32
    %c0_i64_2253 = arith.constant 0 : i64
    %c0_i64_2254 = arith.constant 0 : i64
    %c0_i64_2255 = arith.constant 0 : i64
    %c0_i64_2256 = arith.constant 0 : i64
    %c0_i64_2257 = arith.constant 0 : i64
    %c0_i64_2258 = arith.constant 0 : i64
    %c1_i64_2259 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_2236, %c64_i64_2237, %c128_i64_2238, %590, %591, %592, %593, %c128_i64_2243, %c64_i64_2244, %c64_i64_2245, %c64_i64_2246, %cst_2247, %cst_2248, %cst_2249, %c0_i64_2250, %cst_2251, %cst_2252, %c0_i64_2253, %c0_i64_2254, %c0_i64_2255, %c0_i64_2256, %c0_i64_2257, %c0_i64_2258, %c1_i64_2259) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%588, %587, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2230 : memref<1200x128xi8>
    memref.dealloc %alloc_2231 : memref<1200x64xi8>
    %alloc_2260 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2261 = memref.extract_aligned_pointer_as_index %alloc_2260 : memref<1x30x40x64xf32> -> index
    %intptr_2262 = memref.extract_aligned_pointer_as_index %alloc_2229 : memref<1200x64xi8> -> index
    %594 = arith.index_cast %intptr_2261 : index to i64
    %595 = arith.index_cast %intptr_2262 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%594, %595, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_16) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2229 : memref<1200x64xi8>
    %alloc_2263 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2260[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2263[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2264 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2263, %alloc_2264 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2265 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2264[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %42[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2265[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2266 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2265[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2266[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2267 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2266[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2267[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2268 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2227[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2268[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2269 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2268[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %41[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2269[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2270 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2269[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2270[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2271 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2270[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2271[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2272 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2271[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2272[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2273 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2272[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2273[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2274 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2267[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2274[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2275 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2274[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %40[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2275[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2276 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2275[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2276[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2277 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2276[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2277[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2278 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2277[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2278[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
          }
        }
      }
    }
    %alloc_2279 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2278[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2279[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2280 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_2281 = memref.subview %alloc_2280[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_2273, %subview_2281 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_2282 = memref.subview %alloc_2280[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_2279, %subview_2282 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_2283 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2280[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_2283[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_2284 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_2285 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %alloc_2286 = memref.alloc() {alignment = 64 : i64} : memref<1200x128xi8>
    %intptr_2287 = memref.extract_aligned_pointer_as_index %alloc_2283 : memref<1x30x40x128xi8> -> index
    %596 = arith.index_cast %intptr_2287 : index to i64
    %intptr_2288 = memref.extract_aligned_pointer_as_index %alloc_2285 : memref<1200x128xi8> -> index
    %597 = arith.index_cast %intptr_2288 : index to i64
    %intptr_2289 = memref.extract_aligned_pointer_as_index %alloc_2286 : memref<1200x128xi8> -> index
    %598 = arith.index_cast %intptr_2289 : index to i64
    %intptr_2290 = memref.extract_aligned_pointer_as_index %alloc_2284 : memref<1200x128xi8> -> index
    %599 = arith.index_cast %intptr_2290 : index to i64
    call @buddy_rvv_memcpy_i8(%597, %596, %c153600_i64) : (i64, i64, i64) -> ()
    %600 = arith.addi %597, %c153600_i64 : i64
    call @buddy_rvv_memset_i8(%600, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_2291 = arith.constant 1200 : i64
    %c128_i64_2292 = arith.constant 128 : i64
    %c128_i64_2293 = arith.constant 128 : i64
    %intptr_2294 = memref.extract_aligned_pointer_as_index %alloc_2285 : memref<1200x128xi8> -> index
    %601 = arith.index_cast %intptr_2294 : index to i64
    %intptr_2295 = memref.extract_aligned_pointer_as_index %fwd_cst_100 : memref<128x128xi8> -> index
    %602 = arith.index_cast %intptr_2295 : index to i64
    %intptr_2296 = memref.extract_aligned_pointer_as_index %fwd_cst_101 : memref<1200x128xi32> -> index
    %603 = arith.index_cast %intptr_2296 : index to i64
    %intptr_2297 = memref.extract_aligned_pointer_as_index %alloc_2286 : memref<1200x128xi8> -> index
    %604 = arith.index_cast %intptr_2297 : index to i64
    %c128_i64_2298 = arith.constant 128 : i64
    %c128_i64_2299 = arith.constant 128 : i64
    %c128_i64_2300 = arith.constant 128 : i64
    %c128_i64_2301 = arith.constant 128 : i64
    %cst_2302 = arith.constant 1.000000e+00 : f32
    %cst_2303 = arith.constant 1.000000e+00 : f32
    %cst_2304 = arith.constant 1.000000e+00 : f32
    %c0_i64_2305 = arith.constant 0 : i64
    %cst_2306 = arith.constant 0.0108789504 : f32
    %cst_2307 = arith.constant 0.000000e+00 : f32
    %c0_i64_2308 = arith.constant 0 : i64
    %c0_i64_2309 = arith.constant 0 : i64
    %c0_i64_2310 = arith.constant 0 : i64
    %c0_i64_2311 = arith.constant 0 : i64
    %c0_i64_2312 = arith.constant 0 : i64
    %c0_i64_2313 = arith.constant 0 : i64
    %c1_i64_2314 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_2291, %c128_i64_2292, %c128_i64_2293, %601, %602, %603, %604, %c128_i64_2298, %c128_i64_2299, %c128_i64_2300, %c128_i64_2301, %cst_2302, %cst_2303, %cst_2304, %c0_i64_2305, %cst_2306, %cst_2307, %c0_i64_2308, %c0_i64_2309, %c0_i64_2310, %c0_i64_2311, %c0_i64_2312, %c0_i64_2313, %c1_i64_2314) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%599, %598, %c1200_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2285 : memref<1200x128xi8>
    memref.dealloc %alloc_2286 : memref<1200x128xi8>
    %alloc_2315 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    %intptr_2316 = memref.extract_aligned_pointer_as_index %alloc_2315 : memref<1x30x40x128xf32> -> index
    %intptr_2317 = memref.extract_aligned_pointer_as_index %alloc_2284 : memref<1200x128xi8> -> index
    %605 = arith.index_cast %intptr_2316 : index to i64
    %606 = arith.index_cast %intptr_2317 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%605, %606, %c1_i64, %c30_i64, %c40_i64, %c128_i64, %cst_15) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2284 : memref<1200x128xi8>
    %alloc_2318 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2315[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x128xf32>
            memref.store %793, %alloc_2318[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_2319 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    memref.copy %alloc_2318, %alloc_2319 : memref<1x128x30x40xf32> to memref<1x128x30x40xf32>
    %alloc_2320 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2319[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = memref.load %39[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2320[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_2321 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2320[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2321[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
          }
        }
      }
    }
    %alloc_2322 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2321[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2322[%arg157, %arg158, %arg159, %arg160] : memref<1x128x30x40xi8>
          }
        }
      }
    }
    %alloc_2323 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2322[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_2323[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_2324 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c31 step %c1 {
        scf.for %arg159 = %c0 to %c41 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_2324[%arg157, %arg158, %arg159, %arg160] : memref<1x31x41x128xi8>
          }
        }
      }
    }
    %subview_2325 = memref.subview %alloc_2324[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_2323, %subview_2325 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_2326 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %fwd_cst_103[%arg160] : memref<128xi32>
            memref.store %793, %alloc_2326[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_2327 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %c1_i64_2328 = arith.constant 1 : i64
    %c31_i64_2329 = arith.constant 31 : i64
    %c41_i64_2330 = arith.constant 41 : i64
    %c128_i64_2331 = arith.constant 128 : i64
    %c128_i64_2332 = arith.constant 128 : i64
    %c15_i64_2333 = arith.constant 15 : i64
    %c20_i64_2334 = arith.constant 20 : i64
    %c2_i64_2335 = arith.constant 2 : i64
    %c1_i64_2336 = arith.constant 1 : i64
    %c1_i64_2337 = arith.constant 1 : i64
    %c0_i64_2338 = arith.constant 0 : i64
    %c3_i64_2339 = arith.constant 3 : i64
    %c0_i64_2340 = arith.constant 0 : i64
    %c0_i64_2341 = arith.constant 0 : i64
    %c0_i64_2342 = arith.constant 0 : i64
    %c0_i64_2343 = arith.constant 0 : i64
    %c0_i64_2344 = arith.constant 0 : i64
    %intptr_2345 = memref.extract_aligned_pointer_as_index %alloc_2324 : memref<1x31x41x128xi8> -> index
    %607 = arith.index_cast %intptr_2345 : index to i64
    %intptr_2346 = memref.extract_aligned_pointer_as_index %fwd_cst_102 : memref<1152x128xi8> -> index
    %608 = arith.index_cast %intptr_2346 : index to i64
    %intptr_2347 = memref.extract_aligned_pointer_as_index %fwd_cst_103 : memref<128xi32> -> index
    %609 = arith.index_cast %intptr_2347 : index to i64
    %intptr_2348 = memref.extract_aligned_pointer_as_index %alloc_2327 : memref<300x128xi8> -> index
    %610 = arith.index_cast %intptr_2348 : index to i64
    %c0_i64_2349 = arith.constant 0 : i64
    %cst_2350 = arith.constant 0.0048789829 : f32
    %c0_i64_2351 = arith.constant 0 : i64
    %c0_i64_2352 = arith.constant 0 : i64
    %c0_i64_2353 = arith.constant 0 : i64
    %c1_i64_2354 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2328, %c31_i64_2329, %c41_i64_2330, %c128_i64_2331, %c128_i64_2332, %c15_i64_2333, %c20_i64_2334, %c2_i64_2335, %c1_i64_2336, %c1_i64_2337, %c0_i64_2338, %c3_i64_2339, %c0_i64_2340, %c0_i64_2341, %c0_i64_2342, %c0_i64_2343, %c0_i64_2344, %607, %608, %609, %610, %c0_i64_2349, %cst_2350, %c0_i64_2351, %c0_i64_2352, %c0_i64_2353, %c1_i64_2354) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2355 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_2356 = memref.extract_aligned_pointer_as_index %alloc_2355 : memref<1x15x20x128xf32> -> index
    %intptr_2357 = memref.extract_aligned_pointer_as_index %alloc_2327 : memref<300x128xi8> -> index
    %611 = arith.index_cast %intptr_2356 : index to i64
    %612 = arith.index_cast %intptr_2357 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%611, %612, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_29) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2327 : memref<300x128xi8>
    %alloc_2358 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2355[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_2358[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2359 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_2358, %alloc_2359 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_2360 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2359[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %38[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2360[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2361 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2360[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2361[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2362 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2361[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2362[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2363 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2362[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2363[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2364 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2363[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %37[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2364[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2365 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2364[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2365[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2366 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2365[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2366[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2367 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2366[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2367[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2368 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2367[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2368[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2369 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_1546[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2369[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2370 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2369[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %36[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2370[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2371 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2370[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2371[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2372 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2371[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2372[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2373 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2372[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2373[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2374 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2373[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2374[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2375 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_2376 = memref.subview %alloc_2375[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_2368, %subview_2376 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_2377 = memref.subview %alloc_2375[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_2374, %subview_2377 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_2378 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_2375[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_2378[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_2379 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_2380 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_2381 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_2382 = memref.extract_aligned_pointer_as_index %alloc_2378 : memref<1x15x20x256xi8> -> index
    %613 = arith.index_cast %intptr_2382 : index to i64
    %intptr_2383 = memref.extract_aligned_pointer_as_index %alloc_2380 : memref<304x256xi8> -> index
    %614 = arith.index_cast %intptr_2383 : index to i64
    %intptr_2384 = memref.extract_aligned_pointer_as_index %alloc_2381 : memref<304x128xi8> -> index
    %615 = arith.index_cast %intptr_2384 : index to i64
    %intptr_2385 = memref.extract_aligned_pointer_as_index %alloc_2379 : memref<300x128xi8> -> index
    %616 = arith.index_cast %intptr_2385 : index to i64
    call @buddy_rvv_memcpy_i8(%614, %613, %c76800_i64) : (i64, i64, i64) -> ()
    %617 = arith.addi %614, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%617, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_2386 = arith.constant 304 : i64
    %c128_i64_2387 = arith.constant 128 : i64
    %c256_i64_2388 = arith.constant 256 : i64
    %intptr_2389 = memref.extract_aligned_pointer_as_index %alloc_2380 : memref<304x256xi8> -> index
    %618 = arith.index_cast %intptr_2389 : index to i64
    %intptr_2390 = memref.extract_aligned_pointer_as_index %fwd_cst_104 : memref<256x128xi8> -> index
    %619 = arith.index_cast %intptr_2390 : index to i64
    %intptr_2391 = memref.extract_aligned_pointer_as_index %fwd_cst_105 : memref<304x128xi32> -> index
    %620 = arith.index_cast %intptr_2391 : index to i64
    %intptr_2392 = memref.extract_aligned_pointer_as_index %alloc_2381 : memref<304x128xi8> -> index
    %621 = arith.index_cast %intptr_2392 : index to i64
    %c256_i64_2393 = arith.constant 256 : i64
    %c128_i64_2394 = arith.constant 128 : i64
    %c128_i64_2395 = arith.constant 128 : i64
    %c128_i64_2396 = arith.constant 128 : i64
    %cst_2397 = arith.constant 1.000000e+00 : f32
    %cst_2398 = arith.constant 1.000000e+00 : f32
    %cst_2399 = arith.constant 1.000000e+00 : f32
    %c0_i64_2400 = arith.constant 0 : i64
    %cst_2401 = arith.constant 0.0125225503 : f32
    %cst_2402 = arith.constant 0.000000e+00 : f32
    %c0_i64_2403 = arith.constant 0 : i64
    %c0_i64_2404 = arith.constant 0 : i64
    %c0_i64_2405 = arith.constant 0 : i64
    %c0_i64_2406 = arith.constant 0 : i64
    %c0_i64_2407 = arith.constant 0 : i64
    %c0_i64_2408 = arith.constant 0 : i64
    %c1_i64_2409 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_2386, %c128_i64_2387, %c256_i64_2388, %618, %619, %620, %621, %c256_i64_2393, %c128_i64_2394, %c128_i64_2395, %c128_i64_2396, %cst_2397, %cst_2398, %cst_2399, %c0_i64_2400, %cst_2401, %cst_2402, %c0_i64_2403, %c0_i64_2404, %c0_i64_2405, %c0_i64_2406, %c0_i64_2407, %c0_i64_2408, %c1_i64_2409) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%616, %615, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2380 : memref<304x256xi8>
    memref.dealloc %alloc_2381 : memref<304x128xi8>
    %alloc_2410 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_2411 = memref.extract_aligned_pointer_as_index %alloc_2410 : memref<1x15x20x128xf32> -> index
    %intptr_2412 = memref.extract_aligned_pointer_as_index %alloc_2379 : memref<300x128xi8> -> index
    %622 = arith.index_cast %intptr_2411 : index to i64
    %623 = arith.index_cast %intptr_2412 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%622, %623, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_14) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2379 : memref<300x128xi8>
    %alloc_2413 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2410[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_2413[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2414 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_2413, %alloc_2414 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_2415 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2414[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %35[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2415[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2416 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2415[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2416[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2417 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2416[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2417[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2418 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2417[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_2418[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_2419 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_2420 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %alloc_2421 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_2422 = memref.extract_aligned_pointer_as_index %alloc_2418 : memref<1x15x20x128xi8> -> index
    %624 = arith.index_cast %intptr_2422 : index to i64
    %intptr_2423 = memref.extract_aligned_pointer_as_index %alloc_2420 : memref<304x128xi8> -> index
    %625 = arith.index_cast %intptr_2423 : index to i64
    %intptr_2424 = memref.extract_aligned_pointer_as_index %alloc_2421 : memref<304x128xi8> -> index
    %626 = arith.index_cast %intptr_2424 : index to i64
    %intptr_2425 = memref.extract_aligned_pointer_as_index %alloc_2419 : memref<300x128xi8> -> index
    %627 = arith.index_cast %intptr_2425 : index to i64
    call @buddy_rvv_memcpy_i8(%625, %624, %c38400_i64) : (i64, i64, i64) -> ()
    %628 = arith.addi %625, %c38400_i64 : i64
    call @buddy_rvv_memset_i8(%628, %c0_i64, %c512_i64) : (i64, i64, i64) -> ()
    %c304_i64_2426 = arith.constant 304 : i64
    %c128_i64_2427 = arith.constant 128 : i64
    %c128_i64_2428 = arith.constant 128 : i64
    %intptr_2429 = memref.extract_aligned_pointer_as_index %alloc_2420 : memref<304x128xi8> -> index
    %629 = arith.index_cast %intptr_2429 : index to i64
    %intptr_2430 = memref.extract_aligned_pointer_as_index %fwd_cst_106 : memref<128x128xi8> -> index
    %630 = arith.index_cast %intptr_2430 : index to i64
    %intptr_2431 = memref.extract_aligned_pointer_as_index %fwd_cst_107 : memref<304x128xi32> -> index
    %631 = arith.index_cast %intptr_2431 : index to i64
    %intptr_2432 = memref.extract_aligned_pointer_as_index %alloc_2421 : memref<304x128xi8> -> index
    %632 = arith.index_cast %intptr_2432 : index to i64
    %c128_i64_2433 = arith.constant 128 : i64
    %c128_i64_2434 = arith.constant 128 : i64
    %c128_i64_2435 = arith.constant 128 : i64
    %c128_i64_2436 = arith.constant 128 : i64
    %cst_2437 = arith.constant 1.000000e+00 : f32
    %cst_2438 = arith.constant 1.000000e+00 : f32
    %cst_2439 = arith.constant 1.000000e+00 : f32
    %c0_i64_2440 = arith.constant 0 : i64
    %cst_2441 = arith.constant 0.00973275303 : f32
    %cst_2442 = arith.constant 0.000000e+00 : f32
    %c0_i64_2443 = arith.constant 0 : i64
    %c0_i64_2444 = arith.constant 0 : i64
    %c0_i64_2445 = arith.constant 0 : i64
    %c0_i64_2446 = arith.constant 0 : i64
    %c0_i64_2447 = arith.constant 0 : i64
    %c0_i64_2448 = arith.constant 0 : i64
    %c1_i64_2449 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_2426, %c128_i64_2427, %c128_i64_2428, %629, %630, %631, %632, %c128_i64_2433, %c128_i64_2434, %c128_i64_2435, %c128_i64_2436, %cst_2437, %cst_2438, %cst_2439, %c0_i64_2440, %cst_2441, %cst_2442, %c0_i64_2443, %c0_i64_2444, %c0_i64_2445, %c0_i64_2446, %c0_i64_2447, %c0_i64_2448, %c1_i64_2449) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%627, %626, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2420 : memref<304x128xi8>
    memref.dealloc %alloc_2421 : memref<304x128xi8>
    %alloc_2450 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_2451 = memref.extract_aligned_pointer_as_index %alloc_2450 : memref<1x15x20x128xf32> -> index
    %intptr_2452 = memref.extract_aligned_pointer_as_index %alloc_2419 : memref<300x128xi8> -> index
    %633 = arith.index_cast %intptr_2451 : index to i64
    %634 = arith.index_cast %intptr_2452 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%633, %634, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_13) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2419 : memref<300x128xi8>
    %alloc_2453 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2450[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_2453[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2454 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_2453, %alloc_2454 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_2455 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2454[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %34[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2455[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2456 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2455[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2456[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2457 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2456[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2457[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2458 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2457[%arg157, %arg160, %arg158, %arg159] : memref<1x128x15x20xi8>
            memref.store %793, %alloc_2458[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi8>
          }
        }
      }
    }
    %alloc_2459 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_2459[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x128xi8>
          }
        }
      }
    }
    %subview_2460 = memref.subview %alloc_2459[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_2458, %subview_2460 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_2461 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %fwd_cst_109[%arg160] : memref<128xi32>
            memref.store %793, %alloc_2461[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x128xi32>
          }
        }
      }
    }
    %alloc_2462 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %c1_i64_2463 = arith.constant 1 : i64
    %c17_i64_2464 = arith.constant 17 : i64
    %c22_i64_2465 = arith.constant 22 : i64
    %c128_i64_2466 = arith.constant 128 : i64
    %c128_i64_2467 = arith.constant 128 : i64
    %c15_i64_2468 = arith.constant 15 : i64
    %c20_i64_2469 = arith.constant 20 : i64
    %c1_i64_2470 = arith.constant 1 : i64
    %c1_i64_2471 = arith.constant 1 : i64
    %c1_i64_2472 = arith.constant 1 : i64
    %c0_i64_2473 = arith.constant 0 : i64
    %c3_i64_2474 = arith.constant 3 : i64
    %c0_i64_2475 = arith.constant 0 : i64
    %c0_i64_2476 = arith.constant 0 : i64
    %c0_i64_2477 = arith.constant 0 : i64
    %c0_i64_2478 = arith.constant 0 : i64
    %c0_i64_2479 = arith.constant 0 : i64
    %intptr_2480 = memref.extract_aligned_pointer_as_index %alloc_2459 : memref<1x17x22x128xi8> -> index
    %635 = arith.index_cast %intptr_2480 : index to i64
    %intptr_2481 = memref.extract_aligned_pointer_as_index %fwd_cst_108 : memref<1152x128xi8> -> index
    %636 = arith.index_cast %intptr_2481 : index to i64
    %intptr_2482 = memref.extract_aligned_pointer_as_index %fwd_cst_109 : memref<128xi32> -> index
    %637 = arith.index_cast %intptr_2482 : index to i64
    %intptr_2483 = memref.extract_aligned_pointer_as_index %alloc_2462 : memref<300x128xi8> -> index
    %638 = arith.index_cast %intptr_2483 : index to i64
    %c0_i64_2484 = arith.constant 0 : i64
    %cst_2485 = arith.constant 0.00472895242 : f32
    %c0_i64_2486 = arith.constant 0 : i64
    %c0_i64_2487 = arith.constant 0 : i64
    %c0_i64_2488 = arith.constant 0 : i64
    %c1_i64_2489 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2463, %c17_i64_2464, %c22_i64_2465, %c128_i64_2466, %c128_i64_2467, %c15_i64_2468, %c20_i64_2469, %c1_i64_2470, %c1_i64_2471, %c1_i64_2472, %c0_i64_2473, %c3_i64_2474, %c0_i64_2475, %c0_i64_2476, %c0_i64_2477, %c0_i64_2478, %c0_i64_2479, %635, %636, %637, %638, %c0_i64_2484, %cst_2485, %c0_i64_2486, %c0_i64_2487, %c0_i64_2488, %c1_i64_2489) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2490 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_2491 = memref.extract_aligned_pointer_as_index %alloc_2490 : memref<1x15x20x128xf32> -> index
    %intptr_2492 = memref.extract_aligned_pointer_as_index %alloc_2462 : memref<300x128xi8> -> index
    %639 = arith.index_cast %intptr_2491 : index to i64
    %640 = arith.index_cast %intptr_2492 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%639, %640, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_12) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2462 : memref<300x128xi8>
    %alloc_2493 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2490[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_2493[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2494 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_2493, %alloc_2494 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_2495 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2494[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %33[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2495[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2496 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2495[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2496[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2497 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2496[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2497[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2498 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_2375[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_2498[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_2499 = memref.alloc() {alignment = 64 : i64} : memref<300x128xi8>
    %alloc_2500 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_2501 = memref.alloc() {alignment = 64 : i64} : memref<304x128xi8>
    %intptr_2502 = memref.extract_aligned_pointer_as_index %alloc_2498 : memref<1x15x20x256xi8> -> index
    %641 = arith.index_cast %intptr_2502 : index to i64
    %intptr_2503 = memref.extract_aligned_pointer_as_index %alloc_2500 : memref<304x256xi8> -> index
    %642 = arith.index_cast %intptr_2503 : index to i64
    %intptr_2504 = memref.extract_aligned_pointer_as_index %alloc_2501 : memref<304x128xi8> -> index
    %643 = arith.index_cast %intptr_2504 : index to i64
    %intptr_2505 = memref.extract_aligned_pointer_as_index %alloc_2499 : memref<300x128xi8> -> index
    %644 = arith.index_cast %intptr_2505 : index to i64
    call @buddy_rvv_memcpy_i8(%642, %641, %c76800_i64) : (i64, i64, i64) -> ()
    %645 = arith.addi %642, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%645, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_2506 = arith.constant 304 : i64
    %c128_i64_2507 = arith.constant 128 : i64
    %c256_i64_2508 = arith.constant 256 : i64
    %intptr_2509 = memref.extract_aligned_pointer_as_index %alloc_2500 : memref<304x256xi8> -> index
    %646 = arith.index_cast %intptr_2509 : index to i64
    %intptr_2510 = memref.extract_aligned_pointer_as_index %fwd_cst_110 : memref<256x128xi8> -> index
    %647 = arith.index_cast %intptr_2510 : index to i64
    %intptr_2511 = memref.extract_aligned_pointer_as_index %fwd_cst_111 : memref<304x128xi32> -> index
    %648 = arith.index_cast %intptr_2511 : index to i64
    %intptr_2512 = memref.extract_aligned_pointer_as_index %alloc_2501 : memref<304x128xi8> -> index
    %649 = arith.index_cast %intptr_2512 : index to i64
    %c256_i64_2513 = arith.constant 256 : i64
    %c128_i64_2514 = arith.constant 128 : i64
    %c128_i64_2515 = arith.constant 128 : i64
    %c128_i64_2516 = arith.constant 128 : i64
    %cst_2517 = arith.constant 1.000000e+00 : f32
    %cst_2518 = arith.constant 1.000000e+00 : f32
    %cst_2519 = arith.constant 1.000000e+00 : f32
    %c0_i64_2520 = arith.constant 0 : i64
    %cst_2521 = arith.constant 0.00609090552 : f32
    %cst_2522 = arith.constant 0.000000e+00 : f32
    %c0_i64_2523 = arith.constant 0 : i64
    %c0_i64_2524 = arith.constant 0 : i64
    %c0_i64_2525 = arith.constant 0 : i64
    %c0_i64_2526 = arith.constant 0 : i64
    %c0_i64_2527 = arith.constant 0 : i64
    %c0_i64_2528 = arith.constant 0 : i64
    %c1_i64_2529 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_2506, %c128_i64_2507, %c256_i64_2508, %646, %647, %648, %649, %c256_i64_2513, %c128_i64_2514, %c128_i64_2515, %c128_i64_2516, %cst_2517, %cst_2518, %cst_2519, %c0_i64_2520, %cst_2521, %cst_2522, %c0_i64_2523, %c0_i64_2524, %c0_i64_2525, %c0_i64_2526, %c0_i64_2527, %c0_i64_2528, %c1_i64_2529) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%644, %643, %c300_i64, %c128_i64, %c128_i64, %c128_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2500 : memref<304x256xi8>
    memref.dealloc %alloc_2501 : memref<304x128xi8>
    %alloc_2530 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    %intptr_2531 = memref.extract_aligned_pointer_as_index %alloc_2530 : memref<1x15x20x128xf32> -> index
    %intptr_2532 = memref.extract_aligned_pointer_as_index %alloc_2499 : memref<300x128xi8> -> index
    %650 = arith.index_cast %intptr_2531 : index to i64
    %651 = arith.index_cast %intptr_2532 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%650, %651, %c1_i64, %c15_i64, %c20_i64, %c128_i64, %cst_12) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2499 : memref<300x128xi8>
    %alloc_2533 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2530[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x128xf32>
            memref.store %793, %alloc_2533[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2534 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    memref.copy %alloc_2533, %alloc_2534 : memref<1x128x15x20xf32> to memref<1x128x15x20xf32>
    %alloc_2535 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2534[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = memref.load %32[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2535[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2536 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2535[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2536[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
          }
        }
      }
    }
    %alloc_2537 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2536[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2537[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2538 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2497[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2538[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2539 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2538[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %31[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2539[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2540 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2539[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2540[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2541 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2540[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2541[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2542 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2541[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2542[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2543 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2542[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2543[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2544 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2537[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
            %794 = arith.extsi %793 : i8 to i32
            memref.store %794, %alloc_2544[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2545 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2544[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %30[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.muli %793, %794 : i32
            memref.store %795, %alloc_2545[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2546 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2545[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %118[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.shrsi %793, %794 : i32
            memref.store %795, %alloc_2546[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2547 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2546[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %116[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.maxsi %793, %794 : i32
            memref.store %795, %alloc_2547[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2548 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2547[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = memref.load %115[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xi32>
            %795 = arith.minsi %793, %794 : i32
            memref.store %795, %alloc_2548[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
          }
        }
      }
    }
    %alloc_2549 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c128 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2548[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi32>
            %794 = arith.trunci %793 : i32 to i8
            memref.store %794, %alloc_2549[%arg157, %arg158, %arg159, %arg160] : memref<1x128x15x20xi8>
          }
        }
      }
    }
    %alloc_2550 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_2551 = memref.subview %alloc_2550[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_2543, %subview_2551 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_2552 = memref.subview %alloc_2550[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_2549, %subview_2552 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_2553 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_2550[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_2553[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_2554 = memref.alloc() {alignment = 64 : i64} : memref<300x256xi8>
    %alloc_2555 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %alloc_2556 = memref.alloc() {alignment = 64 : i64} : memref<304x256xi8>
    %intptr_2557 = memref.extract_aligned_pointer_as_index %alloc_2553 : memref<1x15x20x256xi8> -> index
    %652 = arith.index_cast %intptr_2557 : index to i64
    %intptr_2558 = memref.extract_aligned_pointer_as_index %alloc_2555 : memref<304x256xi8> -> index
    %653 = arith.index_cast %intptr_2558 : index to i64
    %intptr_2559 = memref.extract_aligned_pointer_as_index %alloc_2556 : memref<304x256xi8> -> index
    %654 = arith.index_cast %intptr_2559 : index to i64
    %intptr_2560 = memref.extract_aligned_pointer_as_index %alloc_2554 : memref<300x256xi8> -> index
    %655 = arith.index_cast %intptr_2560 : index to i64
    call @buddy_rvv_memcpy_i8(%653, %652, %c76800_i64) : (i64, i64, i64) -> ()
    %656 = arith.addi %653, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%656, %c0_i64, %c1024_i64) : (i64, i64, i64) -> ()
    %c304_i64_2561 = arith.constant 304 : i64
    %c256_i64_2562 = arith.constant 256 : i64
    %c256_i64_2563 = arith.constant 256 : i64
    %intptr_2564 = memref.extract_aligned_pointer_as_index %alloc_2555 : memref<304x256xi8> -> index
    %657 = arith.index_cast %intptr_2564 : index to i64
    %intptr_2565 = memref.extract_aligned_pointer_as_index %fwd_cst_112 : memref<256x256xi8> -> index
    %658 = arith.index_cast %intptr_2565 : index to i64
    %intptr_2566 = memref.extract_aligned_pointer_as_index %fwd_cst_113 : memref<304x256xi32> -> index
    %659 = arith.index_cast %intptr_2566 : index to i64
    %intptr_2567 = memref.extract_aligned_pointer_as_index %alloc_2556 : memref<304x256xi8> -> index
    %660 = arith.index_cast %intptr_2567 : index to i64
    %c256_i64_2568 = arith.constant 256 : i64
    %c256_i64_2569 = arith.constant 256 : i64
    %c256_i64_2570 = arith.constant 256 : i64
    %c256_i64_2571 = arith.constant 256 : i64
    %cst_2572 = arith.constant 1.000000e+00 : f32
    %cst_2573 = arith.constant 1.000000e+00 : f32
    %cst_2574 = arith.constant 1.000000e+00 : f32
    %c0_i64_2575 = arith.constant 0 : i64
    %cst_2576 = arith.constant 0.0181710888 : f32
    %cst_2577 = arith.constant 0.000000e+00 : f32
    %c0_i64_2578 = arith.constant 0 : i64
    %c0_i64_2579 = arith.constant 0 : i64
    %c0_i64_2580 = arith.constant 0 : i64
    %c0_i64_2581 = arith.constant 0 : i64
    %c0_i64_2582 = arith.constant 0 : i64
    %c0_i64_2583 = arith.constant 0 : i64
    %c1_i64_2584 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_2561, %c256_i64_2562, %c256_i64_2563, %657, %658, %659, %660, %c256_i64_2568, %c256_i64_2569, %c256_i64_2570, %c256_i64_2571, %cst_2572, %cst_2573, %cst_2574, %c0_i64_2575, %cst_2576, %cst_2577, %c0_i64_2578, %c0_i64_2579, %c0_i64_2580, %c0_i64_2581, %c0_i64_2582, %c0_i64_2583, %c1_i64_2584) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%655, %654, %c300_i64, %c256_i64, %c256_i64, %c256_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2555 : memref<304x256xi8>
    memref.dealloc %alloc_2556 : memref<304x256xi8>
    %alloc_2585 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    %intptr_2586 = memref.extract_aligned_pointer_as_index %alloc_2585 : memref<1x15x20x256xf32> -> index
    %intptr_2587 = memref.extract_aligned_pointer_as_index %alloc_2554 : memref<300x256xi8> -> index
    %661 = arith.index_cast %intptr_2586 : index to i64
    %662 = arith.index_cast %intptr_2587 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%661, %662, %c1_i64, %c15_i64, %c20_i64, %c256_i64, %cst_11) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2554 : memref<300x256xi8>
    %alloc_2588 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2585[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x256xf32>
            memref.store %793, %alloc_2588[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_2589 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    memref.copy %alloc_2588, %alloc_2589 : memref<1x256x15x20xf32> to memref<1x256x15x20xf32>
    %alloc_2590 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2589[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = memref.load %29[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2590[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_2591 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2590[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2591[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
          }
        }
      }
    }
    %alloc_2592 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c256 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2591[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2592[%arg157, %arg158, %arg159, %arg160] : memref<1x256x15x20xi8>
          }
        }
      }
    }
    %alloc_2593 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2052[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2593[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2594 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2594[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_2595 = memref.subview %alloc_2594[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_2593, %subview_2595 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_2596 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_115[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2596[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_2597 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %c1_i64_2598 = arith.constant 1 : i64
    %c62_i64_2599 = arith.constant 62 : i64
    %c82_i64_2600 = arith.constant 82 : i64
    %c64_i64_2601 = arith.constant 64 : i64
    %c64_i64_2602 = arith.constant 64 : i64
    %c60_i64_2603 = arith.constant 60 : i64
    %c80_i64_2604 = arith.constant 80 : i64
    %c1_i64_2605 = arith.constant 1 : i64
    %c1_i64_2606 = arith.constant 1 : i64
    %c1_i64_2607 = arith.constant 1 : i64
    %c0_i64_2608 = arith.constant 0 : i64
    %c3_i64_2609 = arith.constant 3 : i64
    %c0_i64_2610 = arith.constant 0 : i64
    %c0_i64_2611 = arith.constant 0 : i64
    %c0_i64_2612 = arith.constant 0 : i64
    %c0_i64_2613 = arith.constant 0 : i64
    %c0_i64_2614 = arith.constant 0 : i64
    %intptr_2615 = memref.extract_aligned_pointer_as_index %alloc_2594 : memref<1x62x82x64xi8> -> index
    %663 = arith.index_cast %intptr_2615 : index to i64
    %intptr_2616 = memref.extract_aligned_pointer_as_index %fwd_cst_114 : memref<576x64xi8> -> index
    %664 = arith.index_cast %intptr_2616 : index to i64
    %intptr_2617 = memref.extract_aligned_pointer_as_index %fwd_cst_115 : memref<64xi32> -> index
    %665 = arith.index_cast %intptr_2617 : index to i64
    %intptr_2618 = memref.extract_aligned_pointer_as_index %alloc_2597 : memref<4800x64xi8> -> index
    %666 = arith.index_cast %intptr_2618 : index to i64
    %c0_i64_2619 = arith.constant 0 : i64
    %cst_2620 = arith.constant 0.00989972334 : f32
    %c0_i64_2621 = arith.constant 0 : i64
    %c0_i64_2622 = arith.constant 0 : i64
    %c0_i64_2623 = arith.constant 0 : i64
    %c1_i64_2624 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2598, %c62_i64_2599, %c82_i64_2600, %c64_i64_2601, %c64_i64_2602, %c60_i64_2603, %c80_i64_2604, %c1_i64_2605, %c1_i64_2606, %c1_i64_2607, %c0_i64_2608, %c3_i64_2609, %c0_i64_2610, %c0_i64_2611, %c0_i64_2612, %c0_i64_2613, %c0_i64_2614, %663, %664, %665, %666, %c0_i64_2619, %cst_2620, %c0_i64_2621, %c0_i64_2622, %c0_i64_2623, %c1_i64_2624) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2625 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_2626 = memref.extract_aligned_pointer_as_index %alloc_2625 : memref<1x60x80x64xf32> -> index
    %intptr_2627 = memref.extract_aligned_pointer_as_index %alloc_2597 : memref<4800x64xi8> -> index
    %667 = arith.index_cast %intptr_2626 : index to i64
    %668 = arith.index_cast %intptr_2627 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%667, %668, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_10) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2597 : memref<4800x64xi8>
    %alloc_2628 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2625[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_2628[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2629 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_2628, %alloc_2629 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_2630 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2629[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = memref.load %28[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2630[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2631 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2630[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2631[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2632 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2631[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2632[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_2633 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2632[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2633[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2634 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2634[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_2635 = memref.subview %alloc_2634[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_2633, %subview_2635 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_2636 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_117[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2636[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    %alloc_2637 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %c1_i64_2638 = arith.constant 1 : i64
    %c62_i64_2639 = arith.constant 62 : i64
    %c82_i64_2640 = arith.constant 82 : i64
    %c64_i64_2641 = arith.constant 64 : i64
    %c64_i64_2642 = arith.constant 64 : i64
    %c60_i64_2643 = arith.constant 60 : i64
    %c80_i64_2644 = arith.constant 80 : i64
    %c1_i64_2645 = arith.constant 1 : i64
    %c1_i64_2646 = arith.constant 1 : i64
    %c1_i64_2647 = arith.constant 1 : i64
    %c0_i64_2648 = arith.constant 0 : i64
    %c3_i64_2649 = arith.constant 3 : i64
    %c0_i64_2650 = arith.constant 0 : i64
    %c0_i64_2651 = arith.constant 0 : i64
    %c0_i64_2652 = arith.constant 0 : i64
    %c0_i64_2653 = arith.constant 0 : i64
    %c0_i64_2654 = arith.constant 0 : i64
    %intptr_2655 = memref.extract_aligned_pointer_as_index %alloc_2634 : memref<1x62x82x64xi8> -> index
    %669 = arith.index_cast %intptr_2655 : index to i64
    %intptr_2656 = memref.extract_aligned_pointer_as_index %fwd_cst_116 : memref<576x64xi8> -> index
    %670 = arith.index_cast %intptr_2656 : index to i64
    %intptr_2657 = memref.extract_aligned_pointer_as_index %fwd_cst_117 : memref<64xi32> -> index
    %671 = arith.index_cast %intptr_2657 : index to i64
    %intptr_2658 = memref.extract_aligned_pointer_as_index %alloc_2637 : memref<4800x64xi8> -> index
    %672 = arith.index_cast %intptr_2658 : index to i64
    %c0_i64_2659 = arith.constant 0 : i64
    %cst_2660 = arith.constant 0.00611394271 : f32
    %c0_i64_2661 = arith.constant 0 : i64
    %c0_i64_2662 = arith.constant 0 : i64
    %c0_i64_2663 = arith.constant 0 : i64
    %c1_i64_2664 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2638, %c62_i64_2639, %c82_i64_2640, %c64_i64_2641, %c64_i64_2642, %c60_i64_2643, %c80_i64_2644, %c1_i64_2645, %c1_i64_2646, %c1_i64_2647, %c0_i64_2648, %c3_i64_2649, %c0_i64_2650, %c0_i64_2651, %c0_i64_2652, %c0_i64_2653, %c0_i64_2654, %669, %670, %671, %672, %c0_i64_2659, %cst_2660, %c0_i64_2661, %c0_i64_2662, %c0_i64_2663, %c1_i64_2664) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2665 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    %intptr_2666 = memref.extract_aligned_pointer_as_index %alloc_2665 : memref<1x60x80x64xf32> -> index
    %intptr_2667 = memref.extract_aligned_pointer_as_index %alloc_2637 : memref<4800x64xi8> -> index
    %673 = arith.index_cast %intptr_2666 : index to i64
    %674 = arith.index_cast %intptr_2667 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%673, %674, %c1_i64, %c60_i64, %c80_i64, %c64_i64, %cst_9) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2637 : memref<4800x64xi8>
    %alloc_2668 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2665[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_2668[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2669 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    memref.copy %alloc_2668, %alloc_2669 : memref<1x64x60x80xf32> to memref<1x64x60x80xf32>
    %alloc_2670 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2669[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = memref.load %27[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2670[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2671 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2670[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2671[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %alloc_2672 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2671[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2672[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xi8>
          }
        }
      }
    }
    %alloc_2673 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2672[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2673[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2674 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    %alloc_2675 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_2676 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %alloc_2677 = memref.alloc() {alignment = 64 : i64} : memref<4800x64xi8>
    %intptr_2678 = memref.extract_aligned_pointer_as_index %alloc_2673 : memref<1x60x80x64xi8> -> index
    %675 = arith.index_cast %intptr_2678 : index to i64
    %intptr_2679 = memref.extract_aligned_pointer_as_index %alloc_2676 : memref<4800x64xi8> -> index
    %676 = arith.index_cast %intptr_2679 : index to i64
    %intptr_2680 = memref.extract_aligned_pointer_as_index %alloc_2677 : memref<4800x64xi8> -> index
    %677 = arith.index_cast %intptr_2680 : index to i64
    %intptr_2681 = memref.extract_aligned_pointer_as_index %alloc_2675 : memref<4800x64xi8> -> index
    %678 = arith.index_cast %intptr_2681 : index to i64
    call @buddy_rvv_memcpy_i8(%676, %675, %c307200_i64) : (i64, i64, i64) -> ()
    %679 = arith.addi %676, %c307200_i64 : i64
    call @buddy_rvv_memset_i8(%679, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_2682 = arith.constant 4800 : i64
    %c64_i64_2683 = arith.constant 64 : i64
    %c64_i64_2684 = arith.constant 64 : i64
    %intptr_2685 = memref.extract_aligned_pointer_as_index %alloc_2676 : memref<4800x64xi8> -> index
    %680 = arith.index_cast %intptr_2685 : index to i64
    %intptr_2686 = memref.extract_aligned_pointer_as_index %fwd_cst_118 : memref<64x64xi8> -> index
    %681 = arith.index_cast %intptr_2686 : index to i64
    %intptr_2687 = memref.extract_aligned_pointer_as_index %fwd_cst_119 : memref<4800x64xi32> -> index
    %682 = arith.index_cast %intptr_2687 : index to i64
    %intptr_2688 = memref.extract_aligned_pointer_as_index %alloc_2677 : memref<4800x64xi8> -> index
    %683 = arith.index_cast %intptr_2688 : index to i64
    %c64_i64_2689 = arith.constant 64 : i64
    %c64_i64_2690 = arith.constant 64 : i64
    %c64_i64_2691 = arith.constant 64 : i64
    %c64_i64_2692 = arith.constant 64 : i64
    %cst_2693 = arith.constant 1.000000e+00 : f32
    %cst_2694 = arith.constant 1.000000e+00 : f32
    %cst_2695 = arith.constant 1.000000e+00 : f32
    %c0_i64_2696 = arith.constant 0 : i64
    %cst_2697 = arith.constant 0.005432026 : f32
    %cst_2698 = arith.constant 0.000000e+00 : f32
    %c0_i64_2699 = arith.constant 0 : i64
    %c0_i64_2700 = arith.constant 0 : i64
    %c0_i64_2701 = arith.constant 0 : i64
    %c0_i64_2702 = arith.constant 0 : i64
    %c0_i64_2703 = arith.constant 0 : i64
    %c0_i64_2704 = arith.constant 0 : i64
    %c1_i64_2705 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_2682, %c64_i64_2683, %c64_i64_2684, %680, %681, %682, %683, %c64_i64_2689, %c64_i64_2690, %c64_i64_2691, %c64_i64_2692, %cst_2693, %cst_2694, %cst_2695, %c0_i64_2696, %cst_2697, %cst_2698, %c0_i64_2699, %c0_i64_2700, %c0_i64_2701, %c0_i64_2702, %c0_i64_2703, %c0_i64_2704, %c1_i64_2705) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%678, %677, %c4800_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2676 : memref<4800x64xi8>
    memref.dealloc %alloc_2677 : memref<4800x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = arith.muli %arg157, %c60 : index
            %794 = arith.muli %793, %c80 : index
            %795 = arith.muli %arg158, %c80 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_2675[%797, %arg160] : memref<4800x64xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_2674[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_2675 : memref<4800x64xi8>
    %alloc_2706 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2674[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_2706[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xf32>
          }
        }
      }
    }
    %alloc_2707 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    memref.copy %alloc_2706, %alloc_2707 : memref<1x60x80x64xf32> to memref<1x60x80x64xf32>
    %alloc_2708 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2707[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xf32>
            %794 = memref.load %26[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2708[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xf32>
          }
        }
      }
    }
    %alloc_2709 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2708[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x64xf32>
            memref.store %793, %alloc_2709[%arg157, %arg158, %arg159, %arg160] : memref<1x64x60x80xf32>
          }
        }
      }
    }
    %collapse_shape = memref.collapse_shape %alloc_2709 [[0], [1], [2, 3]] : memref<1x64x60x80xf32> into memref<1x64x4800xf32>
    %alloc_2710 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2322[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_2710[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_2711 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_2711[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x128xi8>
          }
        }
      }
    }
    %subview_2712 = memref.subview %alloc_2711[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_2710, %subview_2712 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_2713 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_121[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2713[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_2714 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_2715 = arith.constant 1 : i64
    %c32_i64_2716 = arith.constant 32 : i64
    %c42_i64_2717 = arith.constant 42 : i64
    %c128_i64_2718 = arith.constant 128 : i64
    %c64_i64_2719 = arith.constant 64 : i64
    %c30_i64_2720 = arith.constant 30 : i64
    %c40_i64_2721 = arith.constant 40 : i64
    %c1_i64_2722 = arith.constant 1 : i64
    %c1_i64_2723 = arith.constant 1 : i64
    %c1_i64_2724 = arith.constant 1 : i64
    %c0_i64_2725 = arith.constant 0 : i64
    %c3_i64_2726 = arith.constant 3 : i64
    %c0_i64_2727 = arith.constant 0 : i64
    %c0_i64_2728 = arith.constant 0 : i64
    %c0_i64_2729 = arith.constant 0 : i64
    %c0_i64_2730 = arith.constant 0 : i64
    %c0_i64_2731 = arith.constant 0 : i64
    %intptr_2732 = memref.extract_aligned_pointer_as_index %alloc_2711 : memref<1x32x42x128xi8> -> index
    %684 = arith.index_cast %intptr_2732 : index to i64
    %intptr_2733 = memref.extract_aligned_pointer_as_index %fwd_cst_120 : memref<1152x64xi8> -> index
    %685 = arith.index_cast %intptr_2733 : index to i64
    %intptr_2734 = memref.extract_aligned_pointer_as_index %fwd_cst_121 : memref<64xi32> -> index
    %686 = arith.index_cast %intptr_2734 : index to i64
    %intptr_2735 = memref.extract_aligned_pointer_as_index %alloc_2714 : memref<1200x64xi8> -> index
    %687 = arith.index_cast %intptr_2735 : index to i64
    %c0_i64_2736 = arith.constant 0 : i64
    %cst_2737 = arith.constant 0.0153491423 : f32
    %c0_i64_2738 = arith.constant 0 : i64
    %c0_i64_2739 = arith.constant 0 : i64
    %c0_i64_2740 = arith.constant 0 : i64
    %c1_i64_2741 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2715, %c32_i64_2716, %c42_i64_2717, %c128_i64_2718, %c64_i64_2719, %c30_i64_2720, %c40_i64_2721, %c1_i64_2722, %c1_i64_2723, %c1_i64_2724, %c0_i64_2725, %c3_i64_2726, %c0_i64_2727, %c0_i64_2728, %c0_i64_2729, %c0_i64_2730, %c0_i64_2731, %684, %685, %686, %687, %c0_i64_2736, %cst_2737, %c0_i64_2738, %c0_i64_2739, %c0_i64_2740, %c1_i64_2741) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2742 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2743 = memref.extract_aligned_pointer_as_index %alloc_2742 : memref<1x30x40x64xf32> -> index
    %intptr_2744 = memref.extract_aligned_pointer_as_index %alloc_2714 : memref<1200x64xi8> -> index
    %688 = arith.index_cast %intptr_2743 : index to i64
    %689 = arith.index_cast %intptr_2744 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%688, %689, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_8) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2714 : memref<1200x64xi8>
    %alloc_2745 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2742[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2745[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2746 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2745, %alloc_2746 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2747 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2746[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %25[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2747[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2748 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2747[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2748[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2749 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2748[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2749[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2750 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2749[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_2750[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_2751 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2751[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x64xi8>
          }
        }
      }
    }
    %subview_2752 = memref.subview %alloc_2751[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_2750, %subview_2752 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_2753 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_123[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2753[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    %alloc_2754 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %c1_i64_2755 = arith.constant 1 : i64
    %c32_i64_2756 = arith.constant 32 : i64
    %c42_i64_2757 = arith.constant 42 : i64
    %c64_i64_2758 = arith.constant 64 : i64
    %c64_i64_2759 = arith.constant 64 : i64
    %c30_i64_2760 = arith.constant 30 : i64
    %c40_i64_2761 = arith.constant 40 : i64
    %c1_i64_2762 = arith.constant 1 : i64
    %c1_i64_2763 = arith.constant 1 : i64
    %c1_i64_2764 = arith.constant 1 : i64
    %c0_i64_2765 = arith.constant 0 : i64
    %c3_i64_2766 = arith.constant 3 : i64
    %c0_i64_2767 = arith.constant 0 : i64
    %c0_i64_2768 = arith.constant 0 : i64
    %c0_i64_2769 = arith.constant 0 : i64
    %c0_i64_2770 = arith.constant 0 : i64
    %c0_i64_2771 = arith.constant 0 : i64
    %intptr_2772 = memref.extract_aligned_pointer_as_index %alloc_2751 : memref<1x32x42x64xi8> -> index
    %690 = arith.index_cast %intptr_2772 : index to i64
    %intptr_2773 = memref.extract_aligned_pointer_as_index %fwd_cst_122 : memref<576x64xi8> -> index
    %691 = arith.index_cast %intptr_2773 : index to i64
    %intptr_2774 = memref.extract_aligned_pointer_as_index %fwd_cst_123 : memref<64xi32> -> index
    %692 = arith.index_cast %intptr_2774 : index to i64
    %intptr_2775 = memref.extract_aligned_pointer_as_index %alloc_2754 : memref<1200x64xi8> -> index
    %693 = arith.index_cast %intptr_2775 : index to i64
    %c0_i64_2776 = arith.constant 0 : i64
    %cst_2777 = arith.constant 7.832830e-03 : f32
    %c0_i64_2778 = arith.constant 0 : i64
    %c0_i64_2779 = arith.constant 0 : i64
    %c0_i64_2780 = arith.constant 0 : i64
    %c1_i64_2781 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2755, %c32_i64_2756, %c42_i64_2757, %c64_i64_2758, %c64_i64_2759, %c30_i64_2760, %c40_i64_2761, %c1_i64_2762, %c1_i64_2763, %c1_i64_2764, %c0_i64_2765, %c3_i64_2766, %c0_i64_2767, %c0_i64_2768, %c0_i64_2769, %c0_i64_2770, %c0_i64_2771, %690, %691, %692, %693, %c0_i64_2776, %cst_2777, %c0_i64_2778, %c0_i64_2779, %c0_i64_2780, %c1_i64_2781) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2782 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    %intptr_2783 = memref.extract_aligned_pointer_as_index %alloc_2782 : memref<1x30x40x64xf32> -> index
    %intptr_2784 = memref.extract_aligned_pointer_as_index %alloc_2754 : memref<1200x64xi8> -> index
    %694 = arith.index_cast %intptr_2783 : index to i64
    %695 = arith.index_cast %intptr_2784 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%694, %695, %c1_i64, %c30_i64, %c40_i64, %c64_i64, %cst_7) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2754 : memref<1200x64xi8>
    %alloc_2785 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2782[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2785[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2786 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    memref.copy %alloc_2785, %alloc_2786 : memref<1x64x30x40xf32> to memref<1x64x30x40xf32>
    %alloc_2787 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2786[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = memref.load %24[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2787[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2788 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2787[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2788[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %alloc_2789 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2788[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2789[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xi8>
          }
        }
      }
    }
    %alloc_2790 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2789[%arg157, %arg160, %arg158, %arg159] : memref<1x64x30x40xi8>
            memref.store %793, %alloc_2790[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi8>
          }
        }
      }
    }
    %alloc_2791 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    %alloc_2792 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2793 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %alloc_2794 = memref.alloc() {alignment = 64 : i64} : memref<1200x64xi8>
    %intptr_2795 = memref.extract_aligned_pointer_as_index %alloc_2790 : memref<1x30x40x64xi8> -> index
    %696 = arith.index_cast %intptr_2795 : index to i64
    %intptr_2796 = memref.extract_aligned_pointer_as_index %alloc_2793 : memref<1200x64xi8> -> index
    %697 = arith.index_cast %intptr_2796 : index to i64
    %intptr_2797 = memref.extract_aligned_pointer_as_index %alloc_2794 : memref<1200x64xi8> -> index
    %698 = arith.index_cast %intptr_2797 : index to i64
    %intptr_2798 = memref.extract_aligned_pointer_as_index %alloc_2792 : memref<1200x64xi8> -> index
    %699 = arith.index_cast %intptr_2798 : index to i64
    call @buddy_rvv_memcpy_i8(%697, %696, %c76800_i64) : (i64, i64, i64) -> ()
    %700 = arith.addi %697, %c76800_i64 : i64
    call @buddy_rvv_memset_i8(%700, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_2799 = arith.constant 1200 : i64
    %c64_i64_2800 = arith.constant 64 : i64
    %c64_i64_2801 = arith.constant 64 : i64
    %intptr_2802 = memref.extract_aligned_pointer_as_index %alloc_2793 : memref<1200x64xi8> -> index
    %701 = arith.index_cast %intptr_2802 : index to i64
    %intptr_2803 = memref.extract_aligned_pointer_as_index %fwd_cst_124 : memref<64x64xi8> -> index
    %702 = arith.index_cast %intptr_2803 : index to i64
    %intptr_2804 = memref.extract_aligned_pointer_as_index %fwd_cst_125 : memref<1200x64xi32> -> index
    %703 = arith.index_cast %intptr_2804 : index to i64
    %intptr_2805 = memref.extract_aligned_pointer_as_index %alloc_2794 : memref<1200x64xi8> -> index
    %704 = arith.index_cast %intptr_2805 : index to i64
    %c64_i64_2806 = arith.constant 64 : i64
    %c64_i64_2807 = arith.constant 64 : i64
    %c64_i64_2808 = arith.constant 64 : i64
    %c64_i64_2809 = arith.constant 64 : i64
    %cst_2810 = arith.constant 1.000000e+00 : f32
    %cst_2811 = arith.constant 1.000000e+00 : f32
    %cst_2812 = arith.constant 1.000000e+00 : f32
    %c0_i64_2813 = arith.constant 0 : i64
    %cst_2814 = arith.constant 0.00581856817 : f32
    %cst_2815 = arith.constant 0.000000e+00 : f32
    %c0_i64_2816 = arith.constant 0 : i64
    %c0_i64_2817 = arith.constant 0 : i64
    %c0_i64_2818 = arith.constant 0 : i64
    %c0_i64_2819 = arith.constant 0 : i64
    %c0_i64_2820 = arith.constant 0 : i64
    %c0_i64_2821 = arith.constant 0 : i64
    %c1_i64_2822 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_2799, %c64_i64_2800, %c64_i64_2801, %701, %702, %703, %704, %c64_i64_2806, %c64_i64_2807, %c64_i64_2808, %c64_i64_2809, %cst_2810, %cst_2811, %cst_2812, %c0_i64_2813, %cst_2814, %cst_2815, %c0_i64_2816, %c0_i64_2817, %c0_i64_2818, %c0_i64_2819, %c0_i64_2820, %c0_i64_2821, %c1_i64_2822) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%699, %698, %c1200_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2793 : memref<1200x64xi8>
    memref.dealloc %alloc_2794 : memref<1200x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = arith.muli %arg157, %c30 : index
            %794 = arith.muli %793, %c40 : index
            %795 = arith.muli %arg158, %c40 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_2792[%797, %arg160] : memref<1200x64xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_2791[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_2792 : memref<1200x64xi8>
    %alloc_2823 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2791[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_2823[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xf32>
          }
        }
      }
    }
    %alloc_2824 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    memref.copy %alloc_2823, %alloc_2824 : memref<1x30x40x64xf32> to memref<1x30x40x64xf32>
    %alloc_2825 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2824[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xf32>
            %794 = memref.load %23[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2825[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x64xf32>
          }
        }
      }
    }
    %alloc_2826 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_2825[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x64xf32>
            memref.store %793, %alloc_2826[%arg157, %arg158, %arg159, %arg160] : memref<1x64x30x40xf32>
          }
        }
      }
    }
    %collapse_shape_2827 = memref.collapse_shape %alloc_2826 [[0], [1], [2, 3]] : memref<1x64x30x40xf32> into memref<1x64x1200xf32>
    %alloc_2828 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_2592[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_2828[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_2829 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            memref.store %c0_i8, %alloc_2829[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x256xi8>
          }
        }
      }
    }
    %subview_2830 = memref.subview %alloc_2829[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_2828, %subview_2830 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_2831 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_127[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2831[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    %alloc_2832 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    %c1_i64_2833 = arith.constant 1 : i64
    %c17_i64_2834 = arith.constant 17 : i64
    %c22_i64_2835 = arith.constant 22 : i64
    %c256_i64_2836 = arith.constant 256 : i64
    %c64_i64_2837 = arith.constant 64 : i64
    %c15_i64_2838 = arith.constant 15 : i64
    %c20_i64_2839 = arith.constant 20 : i64
    %c1_i64_2840 = arith.constant 1 : i64
    %c1_i64_2841 = arith.constant 1 : i64
    %c1_i64_2842 = arith.constant 1 : i64
    %c0_i64_2843 = arith.constant 0 : i64
    %c3_i64_2844 = arith.constant 3 : i64
    %c0_i64_2845 = arith.constant 0 : i64
    %c0_i64_2846 = arith.constant 0 : i64
    %c0_i64_2847 = arith.constant 0 : i64
    %c0_i64_2848 = arith.constant 0 : i64
    %c0_i64_2849 = arith.constant 0 : i64
    %intptr_2850 = memref.extract_aligned_pointer_as_index %alloc_2829 : memref<1x17x22x256xi8> -> index
    %705 = arith.index_cast %intptr_2850 : index to i64
    %intptr_2851 = memref.extract_aligned_pointer_as_index %fwd_cst_126 : memref<2304x64xi8> -> index
    %706 = arith.index_cast %intptr_2851 : index to i64
    %intptr_2852 = memref.extract_aligned_pointer_as_index %fwd_cst_127 : memref<64xi32> -> index
    %707 = arith.index_cast %intptr_2852 : index to i64
    %intptr_2853 = memref.extract_aligned_pointer_as_index %alloc_2832 : memref<300x64xi8> -> index
    %708 = arith.index_cast %intptr_2853 : index to i64
    %c0_i64_2854 = arith.constant 0 : i64
    %cst_2855 = arith.constant 8.036410e-03 : f32
    %c0_i64_2856 = arith.constant 0 : i64
    %c0_i64_2857 = arith.constant 0 : i64
    %c0_i64_2858 = arith.constant 0 : i64
    %c1_i64_2859 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2833, %c17_i64_2834, %c22_i64_2835, %c256_i64_2836, %c64_i64_2837, %c15_i64_2838, %c20_i64_2839, %c1_i64_2840, %c1_i64_2841, %c1_i64_2842, %c0_i64_2843, %c3_i64_2844, %c0_i64_2845, %c0_i64_2846, %c0_i64_2847, %c0_i64_2848, %c0_i64_2849, %705, %706, %707, %708, %c0_i64_2854, %cst_2855, %c0_i64_2856, %c0_i64_2857, %c0_i64_2858, %c1_i64_2859) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2860 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    %intptr_2861 = memref.extract_aligned_pointer_as_index %alloc_2860 : memref<1x15x20x64xf32> -> index
    %intptr_2862 = memref.extract_aligned_pointer_as_index %alloc_2832 : memref<300x64xi8> -> index
    %709 = arith.index_cast %intptr_2861 : index to i64
    %710 = arith.index_cast %intptr_2862 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%709, %710, %c1_i64, %c15_i64, %c20_i64, %c64_i64, %cst_6) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2832 : memref<300x64xi8>
    %alloc_2863 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2860[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x64xf32>
            memref.store %793, %alloc_2863[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2864 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    memref.copy %alloc_2863, %alloc_2864 : memref<1x64x15x20xf32> to memref<1x64x15x20xf32>
    %alloc_2865 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2864[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = memref.load %22[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2865[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2866 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2865[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2866[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2867 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2866[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2867[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xi8>
          }
        }
      }
    }
    %alloc_2868 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2867[%arg157, %arg160, %arg158, %arg159] : memref<1x64x15x20xi8>
            memref.store %793, %alloc_2868[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi8>
          }
        }
      }
    }
    %alloc_2869 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2869[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x64xi8>
          }
        }
      }
    }
    %subview_2870 = memref.subview %alloc_2869[0, 1, 1, 0] [1, 15, 20, 64] [1, 1, 1, 1] : memref<1x17x22x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    memref.copy %alloc_2868, %subview_2870 : memref<1x15x20x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    %alloc_2871 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %fwd_cst_129[%arg160] : memref<64xi32>
            memref.store %793, %alloc_2871[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    %alloc_2872 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    %c1_i64_2873 = arith.constant 1 : i64
    %c17_i64_2874 = arith.constant 17 : i64
    %c22_i64_2875 = arith.constant 22 : i64
    %c64_i64_2876 = arith.constant 64 : i64
    %c64_i64_2877 = arith.constant 64 : i64
    %c15_i64_2878 = arith.constant 15 : i64
    %c20_i64_2879 = arith.constant 20 : i64
    %c1_i64_2880 = arith.constant 1 : i64
    %c1_i64_2881 = arith.constant 1 : i64
    %c1_i64_2882 = arith.constant 1 : i64
    %c0_i64_2883 = arith.constant 0 : i64
    %c3_i64_2884 = arith.constant 3 : i64
    %c0_i64_2885 = arith.constant 0 : i64
    %c0_i64_2886 = arith.constant 0 : i64
    %c0_i64_2887 = arith.constant 0 : i64
    %c0_i64_2888 = arith.constant 0 : i64
    %c0_i64_2889 = arith.constant 0 : i64
    %intptr_2890 = memref.extract_aligned_pointer_as_index %alloc_2869 : memref<1x17x22x64xi8> -> index
    %711 = arith.index_cast %intptr_2890 : index to i64
    %intptr_2891 = memref.extract_aligned_pointer_as_index %fwd_cst_128 : memref<576x64xi8> -> index
    %712 = arith.index_cast %intptr_2891 : index to i64
    %intptr_2892 = memref.extract_aligned_pointer_as_index %fwd_cst_129 : memref<64xi32> -> index
    %713 = arith.index_cast %intptr_2892 : index to i64
    %intptr_2893 = memref.extract_aligned_pointer_as_index %alloc_2872 : memref<300x64xi8> -> index
    %714 = arith.index_cast %intptr_2893 : index to i64
    %c0_i64_2894 = arith.constant 0 : i64
    %cst_2895 = arith.constant 0.00592346117 : f32
    %c0_i64_2896 = arith.constant 0 : i64
    %c0_i64_2897 = arith.constant 0 : i64
    %c0_i64_2898 = arith.constant 0 : i64
    %c1_i64_2899 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2873, %c17_i64_2874, %c22_i64_2875, %c64_i64_2876, %c64_i64_2877, %c15_i64_2878, %c20_i64_2879, %c1_i64_2880, %c1_i64_2881, %c1_i64_2882, %c0_i64_2883, %c3_i64_2884, %c0_i64_2885, %c0_i64_2886, %c0_i64_2887, %c0_i64_2888, %c0_i64_2889, %711, %712, %713, %714, %c0_i64_2894, %cst_2895, %c0_i64_2896, %c0_i64_2897, %c0_i64_2898, %c1_i64_2899) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2900 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    %intptr_2901 = memref.extract_aligned_pointer_as_index %alloc_2900 : memref<1x15x20x64xf32> -> index
    %intptr_2902 = memref.extract_aligned_pointer_as_index %alloc_2872 : memref<300x64xi8> -> index
    %715 = arith.index_cast %intptr_2901 : index to i64
    %716 = arith.index_cast %intptr_2902 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%715, %716, %c1_i64, %c15_i64, %c20_i64, %c64_i64, %cst_5) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2872 : memref<300x64xi8>
    %alloc_2903 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2900[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x64xf32>
            memref.store %793, %alloc_2903[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2904 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    memref.copy %alloc_2903, %alloc_2904 : memref<1x64x15x20xf32> to memref<1x64x15x20xf32>
    %alloc_2905 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2904[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = memref.load %21[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2905[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2906 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2905[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2906[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %alloc_2907 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2906[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2907[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xi8>
          }
        }
      }
    }
    %alloc_2908 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2907[%arg157, %arg160, %arg158, %arg159] : memref<1x64x15x20xi8>
            memref.store %793, %alloc_2908[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi8>
          }
        }
      }
    }
    %alloc_2909 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    %alloc_2910 = memref.alloc() {alignment = 64 : i64} : memref<300x64xi8>
    %alloc_2911 = memref.alloc() {alignment = 64 : i64} : memref<304x64xi8>
    %alloc_2912 = memref.alloc() {alignment = 64 : i64} : memref<304x64xi8>
    %intptr_2913 = memref.extract_aligned_pointer_as_index %alloc_2908 : memref<1x15x20x64xi8> -> index
    %717 = arith.index_cast %intptr_2913 : index to i64
    %intptr_2914 = memref.extract_aligned_pointer_as_index %alloc_2911 : memref<304x64xi8> -> index
    %718 = arith.index_cast %intptr_2914 : index to i64
    %intptr_2915 = memref.extract_aligned_pointer_as_index %alloc_2912 : memref<304x64xi8> -> index
    %719 = arith.index_cast %intptr_2915 : index to i64
    %intptr_2916 = memref.extract_aligned_pointer_as_index %alloc_2910 : memref<300x64xi8> -> index
    %720 = arith.index_cast %intptr_2916 : index to i64
    call @buddy_rvv_memcpy_i8(%718, %717, %c19200_i64) : (i64, i64, i64) -> ()
    %721 = arith.addi %718, %c19200_i64 : i64
    call @buddy_rvv_memset_i8(%721, %c0_i64, %c256_i64) : (i64, i64, i64) -> ()
    %c304_i64_2917 = arith.constant 304 : i64
    %c64_i64_2918 = arith.constant 64 : i64
    %c64_i64_2919 = arith.constant 64 : i64
    %intptr_2920 = memref.extract_aligned_pointer_as_index %alloc_2911 : memref<304x64xi8> -> index
    %722 = arith.index_cast %intptr_2920 : index to i64
    %intptr_2921 = memref.extract_aligned_pointer_as_index %fwd_cst_130 : memref<64x64xi8> -> index
    %723 = arith.index_cast %intptr_2921 : index to i64
    %intptr_2922 = memref.extract_aligned_pointer_as_index %fwd_cst_131 : memref<304x64xi32> -> index
    %724 = arith.index_cast %intptr_2922 : index to i64
    %intptr_2923 = memref.extract_aligned_pointer_as_index %alloc_2912 : memref<304x64xi8> -> index
    %725 = arith.index_cast %intptr_2923 : index to i64
    %c64_i64_2924 = arith.constant 64 : i64
    %c64_i64_2925 = arith.constant 64 : i64
    %c64_i64_2926 = arith.constant 64 : i64
    %c64_i64_2927 = arith.constant 64 : i64
    %cst_2928 = arith.constant 1.000000e+00 : f32
    %cst_2929 = arith.constant 1.000000e+00 : f32
    %cst_2930 = arith.constant 1.000000e+00 : f32
    %c0_i64_2931 = arith.constant 0 : i64
    %cst_2932 = arith.constant 0.00600688718 : f32
    %cst_2933 = arith.constant 0.000000e+00 : f32
    %c0_i64_2934 = arith.constant 0 : i64
    %c0_i64_2935 = arith.constant 0 : i64
    %c0_i64_2936 = arith.constant 0 : i64
    %c0_i64_2937 = arith.constant 0 : i64
    %c0_i64_2938 = arith.constant 0 : i64
    %c0_i64_2939 = arith.constant 0 : i64
    %c1_i64_2940 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_2917, %c64_i64_2918, %c64_i64_2919, %722, %723, %724, %725, %c64_i64_2924, %c64_i64_2925, %c64_i64_2926, %c64_i64_2927, %cst_2928, %cst_2929, %cst_2930, %c0_i64_2931, %cst_2932, %cst_2933, %c0_i64_2934, %c0_i64_2935, %c0_i64_2936, %c0_i64_2937, %c0_i64_2938, %c0_i64_2939, %c1_i64_2940) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%720, %719, %c300_i64, %c64_i64, %c64_i64, %c64_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_2911 : memref<304x64xi8>
    memref.dealloc %alloc_2912 : memref<304x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = arith.muli %arg157, %c15 : index
            %794 = arith.muli %793, %c20 : index
            %795 = arith.muli %arg158, %c20 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_2910[%797, %arg160] : memref<300x64xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_2909[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_2910 : memref<300x64xi8>
    %alloc_2941 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2909[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_2941[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xf32>
          }
        }
      }
    }
    %alloc_2942 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    memref.copy %alloc_2941, %alloc_2942 : memref<1x15x20x64xf32> to memref<1x15x20x64xf32>
    %alloc_2943 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2942[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xf32>
            %794 = memref.load %20[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2943[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x64xf32>
          }
        }
      }
    }
    %alloc_2944 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_2943[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x64xf32>
            memref.store %793, %alloc_2944[%arg157, %arg158, %arg159, %arg160] : memref<1x64x15x20xf32>
          }
        }
      }
    }
    %collapse_shape_2945 = memref.collapse_shape %alloc_2944 [[0], [1], [2, 3]] : memref<1x64x15x20xf32> into memref<1x64x300xf32>
    %alloc_2946 = memref.alloc() {alignment = 64 : i64} : memref<1x64x1200xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c1200 step %c1 {
          %793 = memref.load %collapse_shape_2827[%arg157, %arg158, %arg159] : memref<1x64x1200xf32>
          %794 = memref.load %19[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_2946[%arg157, %arg158, %arg159] : memref<1x64x1200xf32>
        }
      }
    }
    %alloc_2947 = memref.alloc() {alignment = 64 : i64} : memref<1x64x300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c64 step %c1 {
        scf.for %arg159 = %c0 to %c300 step %c1 {
          %793 = memref.load %collapse_shape_2945[%arg157, %arg158, %arg159] : memref<1x64x300xf32>
          %794 = memref.load %18[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_2947[%arg157, %arg158, %arg159] : memref<1x64x300xf32>
        }
      }
    }
    %alloc_2948 = memref.alloc() {alignment = 64 : i64} : memref<1x64x6300xf32>
    %subview_2949 = memref.subview %alloc_2948[0, 0, 0] [1, 64, 4800] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    memref.copy %collapse_shape, %subview_2949 : memref<1x64x4800xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    %subview_2950 = memref.subview %alloc_2948[0, 0, 4800] [1, 64, 1200] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    memref.copy %alloc_2946, %subview_2950 : memref<1x64x1200xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    %subview_2951 = memref.subview %alloc_2948[0, 0, 6000] [1, 64, 300] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    memref.copy %alloc_2947, %subview_2951 : memref<1x64x300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    %alloc_2952 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            %793 = memref.load %alloc_2052[%arg157, %arg160, %arg158, %arg159] : memref<1x64x60x80xi8>
            memref.store %793, %alloc_2952[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x64xi8>
          }
        }
      }
    }
    %alloc_2953 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c64 step %c1 {
            memref.store %c0_i8, %alloc_2953[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x64xi8>
          }
        }
      }
    }
    %subview_2954 = memref.subview %alloc_2953[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_2952, %subview_2954 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_2955 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_133[%arg160] : memref<80xi32>
            memref.store %793, %alloc_2955[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    %alloc_2956 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %c1_i64_2957 = arith.constant 1 : i64
    %c62_i64_2958 = arith.constant 62 : i64
    %c82_i64_2959 = arith.constant 82 : i64
    %c64_i64_2960 = arith.constant 64 : i64
    %c80_i64_2961 = arith.constant 80 : i64
    %c60_i64_2962 = arith.constant 60 : i64
    %c80_i64_2963 = arith.constant 80 : i64
    %c1_i64_2964 = arith.constant 1 : i64
    %c1_i64_2965 = arith.constant 1 : i64
    %c1_i64_2966 = arith.constant 1 : i64
    %c0_i64_2967 = arith.constant 0 : i64
    %c3_i64_2968 = arith.constant 3 : i64
    %c0_i64_2969 = arith.constant 0 : i64
    %c0_i64_2970 = arith.constant 0 : i64
    %c0_i64_2971 = arith.constant 0 : i64
    %c0_i64_2972 = arith.constant 0 : i64
    %c0_i64_2973 = arith.constant 0 : i64
    %intptr_2974 = memref.extract_aligned_pointer_as_index %alloc_2953 : memref<1x62x82x64xi8> -> index
    %726 = arith.index_cast %intptr_2974 : index to i64
    %intptr_2975 = memref.extract_aligned_pointer_as_index %fwd_cst_132 : memref<576x80xi8> -> index
    %727 = arith.index_cast %intptr_2975 : index to i64
    %intptr_2976 = memref.extract_aligned_pointer_as_index %fwd_cst_133 : memref<80xi32> -> index
    %728 = arith.index_cast %intptr_2976 : index to i64
    %intptr_2977 = memref.extract_aligned_pointer_as_index %alloc_2956 : memref<4800x80xi8> -> index
    %729 = arith.index_cast %intptr_2977 : index to i64
    %c0_i64_2978 = arith.constant 0 : i64
    %cst_2979 = arith.constant 0.0071694795 : f32
    %c0_i64_2980 = arith.constant 0 : i64
    %c0_i64_2981 = arith.constant 0 : i64
    %c0_i64_2982 = arith.constant 0 : i64
    %c1_i64_2983 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2957, %c62_i64_2958, %c82_i64_2959, %c64_i64_2960, %c80_i64_2961, %c60_i64_2962, %c80_i64_2963, %c1_i64_2964, %c1_i64_2965, %c1_i64_2966, %c0_i64_2967, %c3_i64_2968, %c0_i64_2969, %c0_i64_2970, %c0_i64_2971, %c0_i64_2972, %c0_i64_2973, %726, %727, %728, %729, %c0_i64_2978, %cst_2979, %c0_i64_2980, %c0_i64_2981, %c0_i64_2982, %c1_i64_2983) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_2984 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    %intptr_2985 = memref.extract_aligned_pointer_as_index %alloc_2984 : memref<1x60x80x80xf32> -> index
    %intptr_2986 = memref.extract_aligned_pointer_as_index %alloc_2956 : memref<4800x80xi8> -> index
    %730 = arith.index_cast %intptr_2985 : index to i64
    %731 = arith.index_cast %intptr_2986 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%730, %731, %c1_i64, %c60_i64, %c80_i64, %c80_i64, %cst_4) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2956 : memref<4800x80xi8>
    %alloc_2987 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2984[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x80xf32>
            memref.store %793, %alloc_2987[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_2988 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    memref.copy %alloc_2987, %alloc_2988 : memref<1x80x60x80xf32> to memref<1x80x60x80xf32>
    %alloc_2989 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2988[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = memref.load %17[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_2989[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_2990 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2989[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_2990[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_2991 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2990[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_2991[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xi8>
          }
        }
      }
    }
    %alloc_2992 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_2991[%arg157, %arg160, %arg158, %arg159] : memref<1x80x60x80xi8>
            memref.store %793, %alloc_2992[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi8>
          }
        }
      }
    }
    %alloc_2993 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c62 step %c1 {
        scf.for %arg159 = %c0 to %c82 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_2993[%arg157, %arg158, %arg159, %arg160] : memref<1x62x82x80xi8>
          }
        }
      }
    }
    %subview_2994 = memref.subview %alloc_2993[0, 1, 1, 0] [1, 60, 80, 80] [1, 1, 1, 1] : memref<1x62x82x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    memref.copy %alloc_2992, %subview_2994 : memref<1x60x80x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    %alloc_2995 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_135[%arg160] : memref<80xi32>
            memref.store %793, %alloc_2995[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    %alloc_2996 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %c1_i64_2997 = arith.constant 1 : i64
    %c62_i64_2998 = arith.constant 62 : i64
    %c82_i64_2999 = arith.constant 82 : i64
    %c80_i64_3000 = arith.constant 80 : i64
    %c80_i64_3001 = arith.constant 80 : i64
    %c60_i64_3002 = arith.constant 60 : i64
    %c80_i64_3003 = arith.constant 80 : i64
    %c1_i64_3004 = arith.constant 1 : i64
    %c1_i64_3005 = arith.constant 1 : i64
    %c1_i64_3006 = arith.constant 1 : i64
    %c0_i64_3007 = arith.constant 0 : i64
    %c3_i64_3008 = arith.constant 3 : i64
    %c0_i64_3009 = arith.constant 0 : i64
    %c0_i64_3010 = arith.constant 0 : i64
    %c0_i64_3011 = arith.constant 0 : i64
    %c0_i64_3012 = arith.constant 0 : i64
    %c0_i64_3013 = arith.constant 0 : i64
    %intptr_3014 = memref.extract_aligned_pointer_as_index %alloc_2993 : memref<1x62x82x80xi8> -> index
    %732 = arith.index_cast %intptr_3014 : index to i64
    %intptr_3015 = memref.extract_aligned_pointer_as_index %fwd_cst_134 : memref<720x80xi8> -> index
    %733 = arith.index_cast %intptr_3015 : index to i64
    %intptr_3016 = memref.extract_aligned_pointer_as_index %fwd_cst_135 : memref<80xi32> -> index
    %734 = arith.index_cast %intptr_3016 : index to i64
    %intptr_3017 = memref.extract_aligned_pointer_as_index %alloc_2996 : memref<4800x80xi8> -> index
    %735 = arith.index_cast %intptr_3017 : index to i64
    %c0_i64_3018 = arith.constant 0 : i64
    %cst_3019 = arith.constant 0.00637654448 : f32
    %c0_i64_3020 = arith.constant 0 : i64
    %c0_i64_3021 = arith.constant 0 : i64
    %c0_i64_3022 = arith.constant 0 : i64
    %c1_i64_3023 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_2997, %c62_i64_2998, %c82_i64_2999, %c80_i64_3000, %c80_i64_3001, %c60_i64_3002, %c80_i64_3003, %c1_i64_3004, %c1_i64_3005, %c1_i64_3006, %c0_i64_3007, %c3_i64_3008, %c0_i64_3009, %c0_i64_3010, %c0_i64_3011, %c0_i64_3012, %c0_i64_3013, %732, %733, %734, %735, %c0_i64_3018, %cst_3019, %c0_i64_3020, %c0_i64_3021, %c0_i64_3022, %c1_i64_3023) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_3024 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    %intptr_3025 = memref.extract_aligned_pointer_as_index %alloc_3024 : memref<1x60x80x80xf32> -> index
    %intptr_3026 = memref.extract_aligned_pointer_as_index %alloc_2996 : memref<4800x80xi8> -> index
    %736 = arith.index_cast %intptr_3025 : index to i64
    %737 = arith.index_cast %intptr_3026 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%736, %737, %c1_i64, %c60_i64, %c80_i64, %c80_i64, %cst_3) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_2996 : memref<4800x80xi8>
    %alloc_3027 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3024[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x80xf32>
            memref.store %793, %alloc_3027[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_3028 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    memref.copy %alloc_3027, %alloc_3028 : memref<1x80x60x80xf32> to memref<1x80x60x80xf32>
    %alloc_3029 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3028[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = memref.load %16[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3029[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_3030 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3029[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3030[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %alloc_3031 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3030[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3031[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xi8>
          }
        }
      }
    }
    %alloc_3032 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3031[%arg157, %arg160, %arg158, %arg159] : memref<1x80x60x80xi8>
            memref.store %793, %alloc_3032[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi8>
          }
        }
      }
    }
    %alloc_3033 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    %alloc_3034 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %alloc_3035 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %alloc_3036 = memref.alloc() {alignment = 64 : i64} : memref<4800x80xi8>
    %intptr_3037 = memref.extract_aligned_pointer_as_index %alloc_3032 : memref<1x60x80x80xi8> -> index
    %738 = arith.index_cast %intptr_3037 : index to i64
    %intptr_3038 = memref.extract_aligned_pointer_as_index %alloc_3035 : memref<4800x80xi8> -> index
    %739 = arith.index_cast %intptr_3038 : index to i64
    %intptr_3039 = memref.extract_aligned_pointer_as_index %alloc_3036 : memref<4800x80xi8> -> index
    %740 = arith.index_cast %intptr_3039 : index to i64
    %intptr_3040 = memref.extract_aligned_pointer_as_index %alloc_3034 : memref<4800x80xi8> -> index
    %741 = arith.index_cast %intptr_3040 : index to i64
    call @buddy_rvv_memcpy_i8(%739, %738, %c384000_i64) : (i64, i64, i64) -> ()
    %742 = arith.addi %739, %c384000_i64 : i64
    call @buddy_rvv_memset_i8(%742, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c4800_i64_3041 = arith.constant 4800 : i64
    %c80_i64_3042 = arith.constant 80 : i64
    %c80_i64_3043 = arith.constant 80 : i64
    %intptr_3044 = memref.extract_aligned_pointer_as_index %alloc_3035 : memref<4800x80xi8> -> index
    %743 = arith.index_cast %intptr_3044 : index to i64
    %intptr_3045 = memref.extract_aligned_pointer_as_index %fwd_cst_136 : memref<80x80xi8> -> index
    %744 = arith.index_cast %intptr_3045 : index to i64
    %intptr_3046 = memref.extract_aligned_pointer_as_index %fwd_cst_137 : memref<4800x80xi32> -> index
    %745 = arith.index_cast %intptr_3046 : index to i64
    %intptr_3047 = memref.extract_aligned_pointer_as_index %alloc_3036 : memref<4800x80xi8> -> index
    %746 = arith.index_cast %intptr_3047 : index to i64
    %c80_i64_3048 = arith.constant 80 : i64
    %c80_i64_3049 = arith.constant 80 : i64
    %c80_i64_3050 = arith.constant 80 : i64
    %c80_i64_3051 = arith.constant 80 : i64
    %cst_3052 = arith.constant 1.000000e+00 : f32
    %cst_3053 = arith.constant 1.000000e+00 : f32
    %cst_3054 = arith.constant 1.000000e+00 : f32
    %c0_i64_3055 = arith.constant 0 : i64
    %cst_3056 = arith.constant 0.00252736034 : f32
    %cst_3057 = arith.constant 0.000000e+00 : f32
    %c0_i64_3058 = arith.constant 0 : i64
    %c0_i64_3059 = arith.constant 0 : i64
    %c0_i64_3060 = arith.constant 0 : i64
    %c0_i64_3061 = arith.constant 0 : i64
    %c0_i64_3062 = arith.constant 0 : i64
    %c0_i64_3063 = arith.constant 0 : i64
    %c1_i64_3064 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c4800_i64_3041, %c80_i64_3042, %c80_i64_3043, %743, %744, %745, %746, %c80_i64_3048, %c80_i64_3049, %c80_i64_3050, %c80_i64_3051, %cst_3052, %cst_3053, %cst_3054, %c0_i64_3055, %cst_3056, %cst_3057, %c0_i64_3058, %c0_i64_3059, %c0_i64_3060, %c0_i64_3061, %c0_i64_3062, %c0_i64_3063, %c1_i64_3064) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%741, %740, %c4800_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_3035 : memref<4800x80xi8>
    memref.dealloc %alloc_3036 : memref<4800x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = arith.muli %arg157, %c60 : index
            %794 = arith.muli %793, %c80 : index
            %795 = arith.muli %arg158, %c80 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_3034[%797, %arg160] : memref<4800x80xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_3033[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_3034 : memref<4800x80xi8>
    %alloc_3065 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3033[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_3065[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xf32>
          }
        }
      }
    }
    %alloc_3066 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    memref.copy %alloc_3065, %alloc_3066 : memref<1x60x80x80xf32> to memref<1x60x80x80xf32>
    %alloc_3067 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c60 step %c1 {
        scf.for %arg159 = %c0 to %c80 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3066[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xf32>
            %794 = memref.load %15[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3067[%arg157, %arg158, %arg159, %arg160] : memref<1x60x80x80xf32>
          }
        }
      }
    }
    %alloc_3068 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c60 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3067[%arg157, %arg159, %arg160, %arg158] : memref<1x60x80x80xf32>
            memref.store %793, %alloc_3068[%arg157, %arg158, %arg159, %arg160] : memref<1x80x60x80xf32>
          }
        }
      }
    }
    %collapse_shape_3069 = memref.collapse_shape %alloc_3068 [[0], [1], [2, 3]] : memref<1x80x60x80xf32> into memref<1x80x4800xf32>
    %alloc_3070 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            %793 = memref.load %alloc_2322[%arg157, %arg160, %arg158, %arg159] : memref<1x128x30x40xi8>
            memref.store %793, %alloc_3070[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x128xi8>
          }
        }
      }
    }
    %alloc_3071 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c128 step %c1 {
            memref.store %c0_i8, %alloc_3071[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x128xi8>
          }
        }
      }
    }
    %subview_3072 = memref.subview %alloc_3071[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_3070, %subview_3072 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_3073 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_139[%arg160] : memref<80xi32>
            memref.store %793, %alloc_3073[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    %alloc_3074 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %c1_i64_3075 = arith.constant 1 : i64
    %c32_i64_3076 = arith.constant 32 : i64
    %c42_i64_3077 = arith.constant 42 : i64
    %c128_i64_3078 = arith.constant 128 : i64
    %c80_i64_3079 = arith.constant 80 : i64
    %c30_i64_3080 = arith.constant 30 : i64
    %c40_i64_3081 = arith.constant 40 : i64
    %c1_i64_3082 = arith.constant 1 : i64
    %c1_i64_3083 = arith.constant 1 : i64
    %c1_i64_3084 = arith.constant 1 : i64
    %c0_i64_3085 = arith.constant 0 : i64
    %c3_i64_3086 = arith.constant 3 : i64
    %c0_i64_3087 = arith.constant 0 : i64
    %c0_i64_3088 = arith.constant 0 : i64
    %c0_i64_3089 = arith.constant 0 : i64
    %c0_i64_3090 = arith.constant 0 : i64
    %c0_i64_3091 = arith.constant 0 : i64
    %intptr_3092 = memref.extract_aligned_pointer_as_index %alloc_3071 : memref<1x32x42x128xi8> -> index
    %747 = arith.index_cast %intptr_3092 : index to i64
    %intptr_3093 = memref.extract_aligned_pointer_as_index %fwd_cst_138 : memref<1152x80xi8> -> index
    %748 = arith.index_cast %intptr_3093 : index to i64
    %intptr_3094 = memref.extract_aligned_pointer_as_index %fwd_cst_139 : memref<80xi32> -> index
    %749 = arith.index_cast %intptr_3094 : index to i64
    %intptr_3095 = memref.extract_aligned_pointer_as_index %alloc_3074 : memref<1200x80xi8> -> index
    %750 = arith.index_cast %intptr_3095 : index to i64
    %c0_i64_3096 = arith.constant 0 : i64
    %cst_3097 = arith.constant 0.00700604171 : f32
    %c0_i64_3098 = arith.constant 0 : i64
    %c0_i64_3099 = arith.constant 0 : i64
    %c0_i64_3100 = arith.constant 0 : i64
    %c1_i64_3101 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_3075, %c32_i64_3076, %c42_i64_3077, %c128_i64_3078, %c80_i64_3079, %c30_i64_3080, %c40_i64_3081, %c1_i64_3082, %c1_i64_3083, %c1_i64_3084, %c0_i64_3085, %c3_i64_3086, %c0_i64_3087, %c0_i64_3088, %c0_i64_3089, %c0_i64_3090, %c0_i64_3091, %747, %748, %749, %750, %c0_i64_3096, %cst_3097, %c0_i64_3098, %c0_i64_3099, %c0_i64_3100, %c1_i64_3101) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_3102 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    %intptr_3103 = memref.extract_aligned_pointer_as_index %alloc_3102 : memref<1x30x40x80xf32> -> index
    %intptr_3104 = memref.extract_aligned_pointer_as_index %alloc_3074 : memref<1200x80xi8> -> index
    %751 = arith.index_cast %intptr_3103 : index to i64
    %752 = arith.index_cast %intptr_3104 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%751, %752, %c1_i64, %c30_i64, %c40_i64, %c80_i64, %cst_2) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_3074 : memref<1200x80xi8>
    %alloc_3105 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3102[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x80xf32>
            memref.store %793, %alloc_3105[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3106 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    memref.copy %alloc_3105, %alloc_3106 : memref<1x80x30x40xf32> to memref<1x80x30x40xf32>
    %alloc_3107 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3106[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = memref.load %14[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3107[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3108 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3107[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3108[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3109 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3108[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3109[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xi8>
          }
        }
      }
    }
    %alloc_3110 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3109[%arg157, %arg160, %arg158, %arg159] : memref<1x80x30x40xi8>
            memref.store %793, %alloc_3110[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi8>
          }
        }
      }
    }
    %alloc_3111 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c32 step %c1 {
        scf.for %arg159 = %c0 to %c42 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_3111[%arg157, %arg158, %arg159, %arg160] : memref<1x32x42x80xi8>
          }
        }
      }
    }
    %subview_3112 = memref.subview %alloc_3111[0, 1, 1, 0] [1, 30, 40, 80] [1, 1, 1, 1] : memref<1x32x42x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    memref.copy %alloc_3110, %subview_3112 : memref<1x30x40x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    %alloc_3113 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_141[%arg160] : memref<80xi32>
            memref.store %793, %alloc_3113[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    %alloc_3114 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %c1_i64_3115 = arith.constant 1 : i64
    %c32_i64_3116 = arith.constant 32 : i64
    %c42_i64_3117 = arith.constant 42 : i64
    %c80_i64_3118 = arith.constant 80 : i64
    %c80_i64_3119 = arith.constant 80 : i64
    %c30_i64_3120 = arith.constant 30 : i64
    %c40_i64_3121 = arith.constant 40 : i64
    %c1_i64_3122 = arith.constant 1 : i64
    %c1_i64_3123 = arith.constant 1 : i64
    %c1_i64_3124 = arith.constant 1 : i64
    %c0_i64_3125 = arith.constant 0 : i64
    %c3_i64_3126 = arith.constant 3 : i64
    %c0_i64_3127 = arith.constant 0 : i64
    %c0_i64_3128 = arith.constant 0 : i64
    %c0_i64_3129 = arith.constant 0 : i64
    %c0_i64_3130 = arith.constant 0 : i64
    %c0_i64_3131 = arith.constant 0 : i64
    %intptr_3132 = memref.extract_aligned_pointer_as_index %alloc_3111 : memref<1x32x42x80xi8> -> index
    %753 = arith.index_cast %intptr_3132 : index to i64
    %intptr_3133 = memref.extract_aligned_pointer_as_index %fwd_cst_140 : memref<720x80xi8> -> index
    %754 = arith.index_cast %intptr_3133 : index to i64
    %intptr_3134 = memref.extract_aligned_pointer_as_index %fwd_cst_141 : memref<80xi32> -> index
    %755 = arith.index_cast %intptr_3134 : index to i64
    %intptr_3135 = memref.extract_aligned_pointer_as_index %alloc_3114 : memref<1200x80xi8> -> index
    %756 = arith.index_cast %intptr_3135 : index to i64
    %c0_i64_3136 = arith.constant 0 : i64
    %cst_3137 = arith.constant 0.0068566585 : f32
    %c0_i64_3138 = arith.constant 0 : i64
    %c0_i64_3139 = arith.constant 0 : i64
    %c0_i64_3140 = arith.constant 0 : i64
    %c1_i64_3141 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_3115, %c32_i64_3116, %c42_i64_3117, %c80_i64_3118, %c80_i64_3119, %c30_i64_3120, %c40_i64_3121, %c1_i64_3122, %c1_i64_3123, %c1_i64_3124, %c0_i64_3125, %c3_i64_3126, %c0_i64_3127, %c0_i64_3128, %c0_i64_3129, %c0_i64_3130, %c0_i64_3131, %753, %754, %755, %756, %c0_i64_3136, %cst_3137, %c0_i64_3138, %c0_i64_3139, %c0_i64_3140, %c1_i64_3141) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_3142 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    %intptr_3143 = memref.extract_aligned_pointer_as_index %alloc_3142 : memref<1x30x40x80xf32> -> index
    %intptr_3144 = memref.extract_aligned_pointer_as_index %alloc_3114 : memref<1200x80xi8> -> index
    %757 = arith.index_cast %intptr_3143 : index to i64
    %758 = arith.index_cast %intptr_3144 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%757, %758, %c1_i64, %c30_i64, %c40_i64, %c80_i64, %cst_1) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_3114 : memref<1200x80xi8>
    %alloc_3145 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3142[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x80xf32>
            memref.store %793, %alloc_3145[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3146 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    memref.copy %alloc_3145, %alloc_3146 : memref<1x80x30x40xf32> to memref<1x80x30x40xf32>
    %alloc_3147 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3146[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = memref.load %13[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3147[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3148 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3147[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3148[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %alloc_3149 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3148[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3149[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xi8>
          }
        }
      }
    }
    %alloc_3150 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3149[%arg157, %arg160, %arg158, %arg159] : memref<1x80x30x40xi8>
            memref.store %793, %alloc_3150[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi8>
          }
        }
      }
    }
    %alloc_3151 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    %alloc_3152 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %alloc_3153 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %alloc_3154 = memref.alloc() {alignment = 64 : i64} : memref<1200x80xi8>
    %intptr_3155 = memref.extract_aligned_pointer_as_index %alloc_3150 : memref<1x30x40x80xi8> -> index
    %759 = arith.index_cast %intptr_3155 : index to i64
    %intptr_3156 = memref.extract_aligned_pointer_as_index %alloc_3153 : memref<1200x80xi8> -> index
    %760 = arith.index_cast %intptr_3156 : index to i64
    %intptr_3157 = memref.extract_aligned_pointer_as_index %alloc_3154 : memref<1200x80xi8> -> index
    %761 = arith.index_cast %intptr_3157 : index to i64
    %intptr_3158 = memref.extract_aligned_pointer_as_index %alloc_3152 : memref<1200x80xi8> -> index
    %762 = arith.index_cast %intptr_3158 : index to i64
    call @buddy_rvv_memcpy_i8(%760, %759, %c96000_i64) : (i64, i64, i64) -> ()
    %763 = arith.addi %760, %c96000_i64 : i64
    call @buddy_rvv_memset_i8(%763, %c0_i64, %c0_i64) : (i64, i64, i64) -> ()
    %c1200_i64_3159 = arith.constant 1200 : i64
    %c80_i64_3160 = arith.constant 80 : i64
    %c80_i64_3161 = arith.constant 80 : i64
    %intptr_3162 = memref.extract_aligned_pointer_as_index %alloc_3153 : memref<1200x80xi8> -> index
    %764 = arith.index_cast %intptr_3162 : index to i64
    %intptr_3163 = memref.extract_aligned_pointer_as_index %fwd_cst_142 : memref<80x80xi8> -> index
    %765 = arith.index_cast %intptr_3163 : index to i64
    %intptr_3164 = memref.extract_aligned_pointer_as_index %fwd_cst_143 : memref<1200x80xi32> -> index
    %766 = arith.index_cast %intptr_3164 : index to i64
    %intptr_3165 = memref.extract_aligned_pointer_as_index %alloc_3154 : memref<1200x80xi8> -> index
    %767 = arith.index_cast %intptr_3165 : index to i64
    %c80_i64_3166 = arith.constant 80 : i64
    %c80_i64_3167 = arith.constant 80 : i64
    %c80_i64_3168 = arith.constant 80 : i64
    %c80_i64_3169 = arith.constant 80 : i64
    %cst_3170 = arith.constant 1.000000e+00 : f32
    %cst_3171 = arith.constant 1.000000e+00 : f32
    %cst_3172 = arith.constant 1.000000e+00 : f32
    %c0_i64_3173 = arith.constant 0 : i64
    %cst_3174 = arith.constant 0.00488613872 : f32
    %cst_3175 = arith.constant 0.000000e+00 : f32
    %c0_i64_3176 = arith.constant 0 : i64
    %c0_i64_3177 = arith.constant 0 : i64
    %c0_i64_3178 = arith.constant 0 : i64
    %c0_i64_3179 = arith.constant 0 : i64
    %c0_i64_3180 = arith.constant 0 : i64
    %c0_i64_3181 = arith.constant 0 : i64
    %c1_i64_3182 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c1200_i64_3159, %c80_i64_3160, %c80_i64_3161, %764, %765, %766, %767, %c80_i64_3166, %c80_i64_3167, %c80_i64_3168, %c80_i64_3169, %cst_3170, %cst_3171, %cst_3172, %c0_i64_3173, %cst_3174, %cst_3175, %c0_i64_3176, %c0_i64_3177, %c0_i64_3178, %c0_i64_3179, %c0_i64_3180, %c0_i64_3181, %c1_i64_3182) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%762, %761, %c1200_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_3153 : memref<1200x80xi8>
    memref.dealloc %alloc_3154 : memref<1200x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = arith.muli %arg157, %c30 : index
            %794 = arith.muli %793, %c40 : index
            %795 = arith.muli %arg158, %c40 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_3152[%797, %arg160] : memref<1200x80xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_3151[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_3152 : memref<1200x80xi8>
    %alloc_3183 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3151[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_3183[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xf32>
          }
        }
      }
    }
    %alloc_3184 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    memref.copy %alloc_3183, %alloc_3184 : memref<1x30x40x80xf32> to memref<1x30x40x80xf32>
    %alloc_3185 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c30 step %c1 {
        scf.for %arg159 = %c0 to %c40 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3184[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xf32>
            %794 = memref.load %12[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3185[%arg157, %arg158, %arg159, %arg160] : memref<1x30x40x80xf32>
          }
        }
      }
    }
    %alloc_3186 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c30 step %c1 {
          scf.for %arg160 = %c0 to %c40 step %c1 {
            %793 = memref.load %alloc_3185[%arg157, %arg159, %arg160, %arg158] : memref<1x30x40x80xf32>
            memref.store %793, %alloc_3186[%arg157, %arg158, %arg159, %arg160] : memref<1x80x30x40xf32>
          }
        }
      }
    }
    %collapse_shape_3187 = memref.collapse_shape %alloc_3186 [[0], [1], [2, 3]] : memref<1x80x30x40xf32> into memref<1x80x1200xf32>
    %alloc_3188 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            %793 = memref.load %alloc_2592[%arg157, %arg160, %arg158, %arg159] : memref<1x256x15x20xi8>
            memref.store %793, %alloc_3188[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x256xi8>
          }
        }
      }
    }
    %alloc_3189 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c256 step %c1 {
            memref.store %c0_i8, %alloc_3189[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x256xi8>
          }
        }
      }
    }
    %subview_3190 = memref.subview %alloc_3189[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_3188, %subview_3190 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_3191 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_145[%arg160] : memref<80xi32>
            memref.store %793, %alloc_3191[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    %alloc_3192 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    %c1_i64_3193 = arith.constant 1 : i64
    %c17_i64_3194 = arith.constant 17 : i64
    %c22_i64_3195 = arith.constant 22 : i64
    %c256_i64_3196 = arith.constant 256 : i64
    %c80_i64_3197 = arith.constant 80 : i64
    %c15_i64_3198 = arith.constant 15 : i64
    %c20_i64_3199 = arith.constant 20 : i64
    %c1_i64_3200 = arith.constant 1 : i64
    %c1_i64_3201 = arith.constant 1 : i64
    %c1_i64_3202 = arith.constant 1 : i64
    %c0_i64_3203 = arith.constant 0 : i64
    %c3_i64_3204 = arith.constant 3 : i64
    %c0_i64_3205 = arith.constant 0 : i64
    %c0_i64_3206 = arith.constant 0 : i64
    %c0_i64_3207 = arith.constant 0 : i64
    %c0_i64_3208 = arith.constant 0 : i64
    %c0_i64_3209 = arith.constant 0 : i64
    %intptr_3210 = memref.extract_aligned_pointer_as_index %alloc_3189 : memref<1x17x22x256xi8> -> index
    %768 = arith.index_cast %intptr_3210 : index to i64
    %intptr_3211 = memref.extract_aligned_pointer_as_index %fwd_cst_144 : memref<2304x80xi8> -> index
    %769 = arith.index_cast %intptr_3211 : index to i64
    %intptr_3212 = memref.extract_aligned_pointer_as_index %fwd_cst_145 : memref<80xi32> -> index
    %770 = arith.index_cast %intptr_3212 : index to i64
    %intptr_3213 = memref.extract_aligned_pointer_as_index %alloc_3192 : memref<300x80xi8> -> index
    %771 = arith.index_cast %intptr_3213 : index to i64
    %c0_i64_3214 = arith.constant 0 : i64
    %cst_3215 = arith.constant 0.00787081196 : f32
    %c0_i64_3216 = arith.constant 0 : i64
    %c0_i64_3217 = arith.constant 0 : i64
    %c0_i64_3218 = arith.constant 0 : i64
    %c1_i64_3219 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_3193, %c17_i64_3194, %c22_i64_3195, %c256_i64_3196, %c80_i64_3197, %c15_i64_3198, %c20_i64_3199, %c1_i64_3200, %c1_i64_3201, %c1_i64_3202, %c0_i64_3203, %c3_i64_3204, %c0_i64_3205, %c0_i64_3206, %c0_i64_3207, %c0_i64_3208, %c0_i64_3209, %768, %769, %770, %771, %c0_i64_3214, %cst_3215, %c0_i64_3216, %c0_i64_3217, %c0_i64_3218, %c1_i64_3219) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_3220 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    %intptr_3221 = memref.extract_aligned_pointer_as_index %alloc_3220 : memref<1x15x20x80xf32> -> index
    %intptr_3222 = memref.extract_aligned_pointer_as_index %alloc_3192 : memref<300x80xi8> -> index
    %772 = arith.index_cast %intptr_3221 : index to i64
    %773 = arith.index_cast %intptr_3222 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%772, %773, %c1_i64, %c15_i64, %c20_i64, %c80_i64, %cst_0) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_3192 : memref<300x80xi8>
    %alloc_3223 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3220[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x80xf32>
            memref.store %793, %alloc_3223[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3224 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    memref.copy %alloc_3223, %alloc_3224 : memref<1x80x15x20xf32> to memref<1x80x15x20xf32>
    %alloc_3225 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3224[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = memref.load %11[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3225[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3226 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3225[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3226[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3227 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3226[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3227[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xi8>
          }
        }
      }
    }
    %alloc_3228 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3227[%arg157, %arg160, %arg158, %arg159] : memref<1x80x15x20xi8>
            memref.store %793, %alloc_3228[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi8>
          }
        }
      }
    }
    %alloc_3229 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c17 step %c1 {
        scf.for %arg159 = %c0 to %c22 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            memref.store %c0_i8, %alloc_3229[%arg157, %arg158, %arg159, %arg160] : memref<1x17x22x80xi8>
          }
        }
      }
    }
    %subview_3230 = memref.subview %alloc_3229[0, 1, 1, 0] [1, 15, 20, 80] [1, 1, 1, 1] : memref<1x17x22x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    memref.copy %alloc_3228, %subview_3230 : memref<1x15x20x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    %alloc_3231 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %fwd_cst_147[%arg160] : memref<80xi32>
            memref.store %793, %alloc_3231[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    %alloc_3232 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    %c1_i64_3233 = arith.constant 1 : i64
    %c17_i64_3234 = arith.constant 17 : i64
    %c22_i64_3235 = arith.constant 22 : i64
    %c80_i64_3236 = arith.constant 80 : i64
    %c80_i64_3237 = arith.constant 80 : i64
    %c15_i64_3238 = arith.constant 15 : i64
    %c20_i64_3239 = arith.constant 20 : i64
    %c1_i64_3240 = arith.constant 1 : i64
    %c1_i64_3241 = arith.constant 1 : i64
    %c1_i64_3242 = arith.constant 1 : i64
    %c0_i64_3243 = arith.constant 0 : i64
    %c3_i64_3244 = arith.constant 3 : i64
    %c0_i64_3245 = arith.constant 0 : i64
    %c0_i64_3246 = arith.constant 0 : i64
    %c0_i64_3247 = arith.constant 0 : i64
    %c0_i64_3248 = arith.constant 0 : i64
    %c0_i64_3249 = arith.constant 0 : i64
    %intptr_3250 = memref.extract_aligned_pointer_as_index %alloc_3229 : memref<1x17x22x80xi8> -> index
    %774 = arith.index_cast %intptr_3250 : index to i64
    %intptr_3251 = memref.extract_aligned_pointer_as_index %fwd_cst_146 : memref<720x80xi8> -> index
    %775 = arith.index_cast %intptr_3251 : index to i64
    %intptr_3252 = memref.extract_aligned_pointer_as_index %fwd_cst_147 : memref<80xi32> -> index
    %776 = arith.index_cast %intptr_3252 : index to i64
    %intptr_3253 = memref.extract_aligned_pointer_as_index %alloc_3232 : memref<300x80xi8> -> index
    %777 = arith.index_cast %intptr_3253 : index to i64
    %c0_i64_3254 = arith.constant 0 : i64
    %cst_3255 = arith.constant 0.00632192567 : f32
    %c0_i64_3256 = arith.constant 0 : i64
    %c0_i64_3257 = arith.constant 0 : i64
    %c0_i64_3258 = arith.constant 0 : i64
    %c1_i64_3259 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_3233, %c17_i64_3234, %c22_i64_3235, %c80_i64_3236, %c80_i64_3237, %c15_i64_3238, %c20_i64_3239, %c1_i64_3240, %c1_i64_3241, %c1_i64_3242, %c0_i64_3243, %c3_i64_3244, %c0_i64_3245, %c0_i64_3246, %c0_i64_3247, %c0_i64_3248, %c0_i64_3249, %774, %775, %776, %777, %c0_i64_3254, %cst_3255, %c0_i64_3256, %c0_i64_3257, %c0_i64_3258, %c1_i64_3259) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    %alloc_3260 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    %intptr_3261 = memref.extract_aligned_pointer_as_index %alloc_3260 : memref<1x15x20x80xf32> -> index
    %intptr_3262 = memref.extract_aligned_pointer_as_index %alloc_3232 : memref<300x80xi8> -> index
    %778 = arith.index_cast %intptr_3261 : index to i64
    %779 = arith.index_cast %intptr_3262 : index to i64
    call @buddy_int8_silu_dequant_nhwc(%778, %779, %c1_i64, %c15_i64, %c20_i64, %c80_i64, %cst) : (i64, i64, i64, i64, i64, i64, f32) -> ()
    memref.dealloc %alloc_3232 : memref<300x80xi8>
    %alloc_3263 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3260[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x80xf32>
            memref.store %793, %alloc_3263[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3264 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    memref.copy %alloc_3263, %alloc_3264 : memref<1x80x15x20xf32> to memref<1x80x15x20xf32>
    %alloc_3265 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3264[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = memref.load %10[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3265[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3266 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3265[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3266[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %alloc_3267 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3266[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3267[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xi8>
          }
        }
      }
    }
    %alloc_3268 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3267[%arg157, %arg160, %arg158, %arg159] : memref<1x80x15x20xi8>
            memref.store %793, %alloc_3268[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi8>
          }
        }
      }
    }
    %alloc_3269 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    %alloc_3270 = memref.alloc() {alignment = 64 : i64} : memref<300x80xi8>
    %alloc_3271 = memref.alloc() {alignment = 64 : i64} : memref<304x80xi8>
    %alloc_3272 = memref.alloc() {alignment = 64 : i64} : memref<304x80xi8>
    %intptr_3273 = memref.extract_aligned_pointer_as_index %alloc_3268 : memref<1x15x20x80xi8> -> index
    %780 = arith.index_cast %intptr_3273 : index to i64
    %intptr_3274 = memref.extract_aligned_pointer_as_index %alloc_3271 : memref<304x80xi8> -> index
    %781 = arith.index_cast %intptr_3274 : index to i64
    %intptr_3275 = memref.extract_aligned_pointer_as_index %alloc_3272 : memref<304x80xi8> -> index
    %782 = arith.index_cast %intptr_3275 : index to i64
    %intptr_3276 = memref.extract_aligned_pointer_as_index %alloc_3270 : memref<300x80xi8> -> index
    %783 = arith.index_cast %intptr_3276 : index to i64
    call @buddy_rvv_memcpy_i8(%781, %780, %c24000_i64) : (i64, i64, i64) -> ()
    %784 = arith.addi %781, %c24000_i64 : i64
    call @buddy_rvv_memset_i8(%784, %c0_i64, %c320_i64) : (i64, i64, i64) -> ()
    %c304_i64_3277 = arith.constant 304 : i64
    %c80_i64_3278 = arith.constant 80 : i64
    %c80_i64_3279 = arith.constant 80 : i64
    %intptr_3280 = memref.extract_aligned_pointer_as_index %alloc_3271 : memref<304x80xi8> -> index
    %785 = arith.index_cast %intptr_3280 : index to i64
    %intptr_3281 = memref.extract_aligned_pointer_as_index %fwd_cst_148 : memref<80x80xi8> -> index
    %786 = arith.index_cast %intptr_3281 : index to i64
    %intptr_3282 = memref.extract_aligned_pointer_as_index %fwd_cst_149 : memref<304x80xi32> -> index
    %787 = arith.index_cast %intptr_3282 : index to i64
    %intptr_3283 = memref.extract_aligned_pointer_as_index %alloc_3272 : memref<304x80xi8> -> index
    %788 = arith.index_cast %intptr_3283 : index to i64
    %c80_i64_3284 = arith.constant 80 : i64
    %c80_i64_3285 = arith.constant 80 : i64
    %c80_i64_3286 = arith.constant 80 : i64
    %c80_i64_3287 = arith.constant 80 : i64
    %cst_3288 = arith.constant 1.000000e+00 : f32
    %cst_3289 = arith.constant 1.000000e+00 : f32
    %cst_3290 = arith.constant 1.000000e+00 : f32
    %c0_i64_3291 = arith.constant 0 : i64
    %cst_3292 = arith.constant 0.00431937352 : f32
    %cst_3293 = arith.constant 0.000000e+00 : f32
    %c0_i64_3294 = arith.constant 0 : i64
    %c0_i64_3295 = arith.constant 0 : i64
    %c0_i64_3296 = arith.constant 0 : i64
    %c0_i64_3297 = arith.constant 0 : i64
    %c0_i64_3298 = arith.constant 0 : i64
    %c0_i64_3299 = arith.constant 0 : i64
    %c1_i64_3300 = arith.constant 1 : i64
    call @gemmini_tiled_matmul_auto(%c304_i64_3277, %c80_i64_3278, %c80_i64_3279, %785, %786, %787, %788, %c80_i64_3284, %c80_i64_3285, %c80_i64_3286, %c80_i64_3287, %cst_3288, %cst_3289, %cst_3290, %c0_i64_3291, %cst_3292, %cst_3293, %c0_i64_3294, %c0_i64_3295, %c0_i64_3296, %c0_i64_3297, %c0_i64_3298, %c0_i64_3299, %c1_i64_3300) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, f32, f32, i64, f32, f32, i64, i64, i64, i64, i64, i64, i64) -> ()
    call @buddy_rvv_copy_rows_i8(%783, %782, %c300_i64, %c80_i64, %c80_i64, %c80_i64) : (i64, i64, i64, i64, i64, i64) -> ()
    memref.dealloc %alloc_3271 : memref<304x80xi8>
    memref.dealloc %alloc_3272 : memref<304x80xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = arith.muli %arg157, %c15 : index
            %794 = arith.muli %793, %c20 : index
            %795 = arith.muli %arg158, %c20 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_3270[%797, %arg160] : memref<300x80xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_3269[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_3270 : memref<300x80xi8>
    %alloc_3301 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3269[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_3301[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xf32>
          }
        }
      }
    }
    %alloc_3302 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    memref.copy %alloc_3301, %alloc_3302 : memref<1x15x20x80xf32> to memref<1x15x20x80xf32>
    %alloc_3303 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c15 step %c1 {
        scf.for %arg159 = %c0 to %c20 step %c1 {
          scf.for %arg160 = %c0 to %c80 step %c1 {
            %793 = memref.load %alloc_3302[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xf32>
            %794 = memref.load %9[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3303[%arg157, %arg158, %arg159, %arg160] : memref<1x15x20x80xf32>
          }
        }
      }
    }
    %alloc_3304 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c15 step %c1 {
          scf.for %arg160 = %c0 to %c20 step %c1 {
            %793 = memref.load %alloc_3303[%arg157, %arg159, %arg160, %arg158] : memref<1x15x20x80xf32>
            memref.store %793, %alloc_3304[%arg157, %arg158, %arg159, %arg160] : memref<1x80x15x20xf32>
          }
        }
      }
    }
    %collapse_shape_3305 = memref.collapse_shape %alloc_3304 [[0], [1], [2, 3]] : memref<1x80x15x20xf32> into memref<1x80x300xf32>
    %alloc_3306 = memref.alloc() {alignment = 64 : i64} : memref<1x80x4800xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c4800 step %c1 {
          %793 = memref.load %collapse_shape_3069[%arg157, %arg158, %arg159] : memref<1x80x4800xf32>
          %794 = memref.load %8[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3306[%arg157, %arg158, %arg159] : memref<1x80x4800xf32>
        }
      }
    }
    %alloc_3307 = memref.alloc() {alignment = 64 : i64} : memref<1x80x1200xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c1200 step %c1 {
          %793 = memref.load %collapse_shape_3187[%arg157, %arg158, %arg159] : memref<1x80x1200xf32>
          %794 = memref.load %7[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3307[%arg157, %arg158, %arg159] : memref<1x80x1200xf32>
        }
      }
    }
    %alloc_3308 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    %subview_3309 = memref.subview %alloc_3308[0, 0, 0] [1, 80, 4800] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    memref.copy %alloc_3306, %subview_3309 : memref<1x80x4800xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    %subview_3310 = memref.subview %alloc_3308[0, 0, 4800] [1, 80, 1200] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    memref.copy %alloc_3307, %subview_3310 : memref<1x80x1200xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    %subview_3311 = memref.subview %alloc_3308[0, 0, 6000] [1, 80, 300] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    memref.copy %collapse_shape_3305, %subview_3311 : memref<1x80x300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    %expand_shape = memref.expand_shape %alloc_2948 [[0], [1, 2], [3]] output_shape [1, 4, 16, 6300] : memref<1x64x6300xf32> into memref<1x4x16x6300xf32>
    %alloc_3312 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c4 step %c1 {
          scf.for %arg160 = %c0 to %c6300 step %c1 {
            %793 = memref.load %expand_shape[%arg157, %arg159, %arg158, %arg160] : memref<1x4x16x6300xf32>
            memref.store %793, %alloc_3312[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_3313 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c4 step %c1 {
          scf.for %arg160 = %c0 to %c6300 step %c1 {
            %793 = memref.load %alloc_3312[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
            %794 = math.exp %793 : f32
            memref.store %794, %alloc_3313[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_3314 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          memref.store %cst_64, %alloc_3314[%arg157, %arg158, %arg159] : memref<1x4x6300xf32>
        }
      }
    }
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c4 step %c1 {
          scf.for %arg160 = %c0 to %c6300 step %c1 {
            %793 = memref.load %alloc_3313[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
            %794 = memref.load %alloc_3314[%arg157, %arg159, %arg160] : memref<1x4x6300xf32>
            %795 = arith.addf %793, %794 : f32
            memref.store %795, %alloc_3314[%arg157, %arg159, %arg160] : memref<1x4x6300xf32>
          }
        }
      }
    }
    %expand_shape_3315 = memref.expand_shape %alloc_3314 [[0], [1, 2], [3]] output_shape [1, 1, 4, 6300] : memref<1x4x6300xf32> into memref<1x1x4x6300xf32>
    %alloc_3316 = memref.alloc() {alignment = 64 : i64} : memref<1x1x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c4 step %c1 {
          scf.for %arg160 = %c0 to %c6300 step %c1 {
            %793 = memref.load %expand_shape_3315[%arg157, %arg158, %arg159, %arg160] : memref<1x1x4x6300xf32>
            %794 = arith.divf %cst_61, %793 : f32
            memref.store %794, %alloc_3316[%arg157, %arg158, %arg159, %arg160] : memref<1x1x4x6300xf32>
          }
        }
      }
    }
    %alloc_3317 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c16 step %c1 {
        scf.for %arg159 = %c0 to %c4 step %c1 {
          scf.for %arg160 = %c0 to %c6300 step %c1 {
            %793 = memref.load %alloc_3313[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
            %794 = memref.load %alloc_3316[%arg157, %c0, %arg159, %arg160] : memref<1x1x4x6300xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3317[%arg157, %arg158, %arg159, %arg160] : memref<1x16x4x6300xf32>
          }
        }
      }
    }
    %alloc_3318 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3317[%arg157, %arg160, %arg158, %arg159] : memref<1x16x4x6300xf32>
            memref.store %793, %alloc_3318[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %collapse_shape_3319 = memref.collapse_shape %fwd_cst_150 [[0], [1, 2, 3]] : memref<1x16x1x1xf32> into memref<1x16xf32>
    %expand_shape_3320 = memref.expand_shape %collapse_shape_3319 [[0, 1, 2], [3]] output_shape [1, 1, 1, 16] : memref<1x16xf32> into memref<1x1x1x16xf32>
    %alloc_3321 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3318[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
            %794 = memref.load %6[%arg157, %c0, %c0, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3321[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %alloc_3322 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3321[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_62 : f32
            memref.store %795, %alloc_3322[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
          }
        }
      }
    }
    %alloc_3323 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3322[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3323[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x16xi8>
          }
        }
      }
    }
    %alloc_3324 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c1 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %expand_shape_3320[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xf32>
            %794 = memref.load %5[%arg157, %arg158, %arg159, %c0] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3324[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xf32>
          }
        }
      }
    }
    %alloc_3325 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c1 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3324[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xf32>
            %794 = arith.minimumf %793, %cst_63 : f32
            %795 = arith.maximumf %794, %cst_65 : f32
            memref.store %795, %alloc_3325[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xf32>
          }
        }
      }
    }
    %alloc_3326 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c1 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = memref.load %alloc_3325[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xf32>
            %794 = arith.cmpf olt, %793, %cst_64 : f32
            %795 = arith.select %794, %cst_58, %cst_59 : f32
            %796 = arith.addf %793, %795 : f32
            %797 = arith.fptosi %796 : f32 to i32
            %798 = arith.maxsi %797, %c-128_i32 : i32
            %799 = arith.minsi %798, %c127_i32 : i32
            %800 = arith.trunci %799 : i32 to i8
            memref.store %800, %alloc_3326[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xi8>
          }
        }
      }
    }
    %alloc_3327 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xi32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c1 step %c1 {
            %793 = memref.load %125[%c0] : memref<1xi32>
            memref.store %793, %alloc_3327[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xi32>
          }
        }
      }
    }
    %alloc_3328 = memref.alloc() {alignment = 64 : i64} : memref<16x1xi8>
    %alloc_3329 = memref.alloc() {alignment = 64 : i64} : memref<25200x1xi8>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c1 step %c1 {
          scf.for %arg160 = %c0 to %c16 step %c1 {
            %793 = arith.muli %arg158, %c16 : index
            %794 = arith.muli %arg159, %c16 : index
            %795 = arith.addi %793, %794 : index
            %796 = arith.addi %795, %arg160 : index
            %797 = memref.load %alloc_3326[%arg157, %arg158, %arg159, %arg160] : memref<1x1x1x16xi8>
            memref.store %797, %alloc_3328[%796, %arg157] : memref<16x1xi8>
          }
        }
      }
    }
    %c1_i64_3330 = arith.constant 1 : i64
    %c4_i64_3331 = arith.constant 4 : i64
    %c6300_i64_3332 = arith.constant 6300 : i64
    %c16_i64_3333 = arith.constant 16 : i64
    %c1_i64_3334 = arith.constant 1 : i64
    %c4_i64_3335 = arith.constant 4 : i64
    %c6300_i64_3336 = arith.constant 6300 : i64
    %c1_i64_3337 = arith.constant 1 : i64
    %c1_i64_3338 = arith.constant 1 : i64
    %c1_i64_3339 = arith.constant 1 : i64
    %c0_i64_3340 = arith.constant 0 : i64
    %c1_i64_3341 = arith.constant 1 : i64
    %c0_i64_3342 = arith.constant 0 : i64
    %c0_i64_3343 = arith.constant 0 : i64
    %c0_i64_3344 = arith.constant 0 : i64
    %c0_i64_3345 = arith.constant 0 : i64
    %c0_i64_3346 = arith.constant 0 : i64
    %intptr_3347 = memref.extract_aligned_pointer_as_index %alloc_3323 : memref<1x4x6300x16xi8> -> index
    %789 = arith.index_cast %intptr_3347 : index to i64
    %intptr_3348 = memref.extract_aligned_pointer_as_index %alloc_3328 : memref<16x1xi8> -> index
    %790 = arith.index_cast %intptr_3348 : index to i64
    %intptr_3349 = memref.extract_aligned_pointer_as_index %125 : memref<1xi32> -> index
    %791 = arith.index_cast %intptr_3349 : index to i64
    %intptr_3350 = memref.extract_aligned_pointer_as_index %alloc_3329 : memref<25200x1xi8> -> index
    %792 = arith.index_cast %intptr_3350 : index to i64
    %c0_i64_3351 = arith.constant 0 : i64
    %cst_3352 = arith.constant 0.00859712064 : f32
    %c0_i64_3353 = arith.constant 0 : i64
    %c0_i64_3354 = arith.constant 0 : i64
    %c0_i64_3355 = arith.constant 0 : i64
    %c1_i64_3356 = arith.constant 1 : i64
    call @gemmini_tiled_conv_auto(%c1_i64_3330, %c4_i64_3331, %c6300_i64_3332, %c16_i64_3333, %c1_i64_3334, %c4_i64_3335, %c6300_i64_3336, %c1_i64_3337, %c1_i64_3338, %c1_i64_3339, %c0_i64_3340, %c1_i64_3341, %c0_i64_3342, %c0_i64_3343, %c0_i64_3344, %c0_i64_3345, %c0_i64_3346, %789, %790, %791, %792, %c0_i64_3351, %cst_3352, %c0_i64_3353, %c0_i64_3354, %c0_i64_3355, %c1_i64_3356) : (i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, f32, i64, i64, i64, i64) -> ()
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c1 step %c1 {
            %793 = arith.muli %arg157, %c4 : index
            %794 = arith.muli %793, %c6300 : index
            %795 = arith.muli %arg158, %c6300 : index
            %796 = arith.addi %794, %795 : index
            %797 = arith.addi %796, %arg159 : index
            %798 = memref.load %alloc_3329[%797, %arg160] : memref<25200x1xi8>
            %799 = arith.extsi %798 : i8 to i32
            memref.store %799, %alloc_3327[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xi32>
          }
        }
      }
    }
    memref.dealloc %alloc_3329 : memref<25200x1xi8>
    memref.dealloc %alloc_3328 : memref<16x1xi8>
    %alloc_3357 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c1 step %c1 {
            %793 = memref.load %alloc_3327[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xi32>
            %794 = arith.sitofp %793 : i32 to f32
            memref.store %794, %alloc_3357[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xf32>
          }
        }
      }
    }
    %alloc_3358 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    memref.copy %alloc_3357, %alloc_3358 : memref<1x4x6300x1xf32> to memref<1x4x6300x1xf32>
    %alloc_3359 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          scf.for %arg160 = %c0 to %c1 step %c1 {
            %793 = memref.load %alloc_3358[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xf32>
            %794 = memref.load %4[%arg157, %c0, %c0, %arg160] : memref<1x1x1x1xf32>
            %795 = arith.mulf %793, %794 : f32
            memref.store %795, %alloc_3359[%arg157, %arg158, %arg159, %arg160] : memref<1x4x6300x1xf32>
          }
        }
      }
    }
    %collapse_shape_3360 = memref.collapse_shape %alloc_3359 [[0], [1], [2, 3]] : memref<1x4x6300x1xf32> into memref<1x4x6300xf32>
    %subview_3361 = memref.subview %collapse_shape_3360[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_3362 = memref.subview %collapse_shape_3360[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %alloc_3363 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %fwd_cst_151[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %subview_3361[%arg157, %arg158, %arg159] : memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
          %795 = arith.subf %793, %794 : f32
          memref.store %795, %alloc_3363[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3364 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %fwd_cst_152[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %subview_3362[%arg157, %arg158, %arg159] : memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
          %795 = arith.addf %793, %794 : f32
          memref.store %795, %alloc_3364[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3365 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3363[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %3[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3365[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3366 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3364[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %2[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3366[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3367 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3365[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %alloc_3366[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %795 = arith.addf %793, %794 : f32
          memref.store %795, %alloc_3367[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %expand_shape_3368 = memref.expand_shape %fwd_cst_153 [] output_shape [1, 1, 1] : memref<f32> into memref<1x1x1xf32>
    %alloc_3369 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c1 step %c1 {
        scf.for %arg159 = %c0 to %c1 step %c1 {
          %793 = memref.load %expand_shape_3368[%arg157, %arg158, %arg159] : memref<1x1x1xf32>
          %794 = arith.divf %cst_61, %793 : f32
          memref.store %794, %alloc_3369[%arg157, %arg158, %arg159] : memref<1x1x1xf32>
        }
      }
    }
    %alloc_3370 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3367[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %alloc_3369[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3370[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3371 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3364[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %alloc_3363[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %795 = arith.subf %793, %794 : f32
          memref.store %795, %alloc_3371[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3372 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c2 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3371[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
          %794 = memref.load %1[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3372[%arg157, %arg158, %arg159] : memref<1x2x6300xf32>
        }
      }
    }
    %alloc_3373 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    %subview_3374 = memref.subview %alloc_3373[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    memref.copy %alloc_3370, %subview_3374 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_3375 = memref.subview %alloc_3373[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    memref.copy %alloc_3372, %subview_3375 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %expand_shape_3376 = memref.expand_shape %fwd_cst_154 [[0, 1], [2]] output_shape [1, 1, 6300] : memref<1x6300xf32> into memref<1x1x6300xf32>
    %alloc_3377 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c4 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3373[%arg157, %arg158, %arg159] : memref<1x4x6300xf32>
          %794 = memref.load %expand_shape_3376[%arg157, %c0, %arg159] : memref<1x1x6300xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3377[%arg157, %arg158, %arg159] : memref<1x4x6300xf32>
        }
      }
    }
    %alloc_3378 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3308[%arg157, %arg158, %arg159] : memref<1x80x6300xf32>
          %794 = arith.negf %793 : f32
          %795 = math.exp %794 : f32
          %796 = arith.addf %795, %cst_61 : f32
          %797 = arith.divf %cst_61, %796 : f32
          memref.store %797, %alloc_3378[%arg157, %arg158, %arg159] : memref<1x80x6300xf32>
        }
      }
    }
    %alloc_3379 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    scf.for %arg157 = %c0 to %c1 step %c1 {
      scf.for %arg158 = %c0 to %c80 step %c1 {
        scf.for %arg159 = %c0 to %c6300 step %c1 {
          %793 = memref.load %alloc_3378[%arg157, %arg158, %arg159] : memref<1x80x6300xf32>
          %794 = memref.load %0[%arg157, %c0, %c0] : memref<1x1x1xf32>
          %795 = arith.mulf %793, %794 : f32
          memref.store %795, %alloc_3379[%arg157, %arg158, %arg159] : memref<1x80x6300xf32>
        }
      }
    }
    %subview_3380 = memref.subview %arg156[0, 0, 0] [1, 4, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    memref.copy %alloc_3377, %subview_3380 : memref<1x4x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    %subview_3381 = memref.subview %arg156[0, 4, 0] [1, 80, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    memref.copy %alloc_3379, %subview_3381 : memref<1x80x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    return
  }
  func.func private @buddy_int8_silu_dequant_nhwc(i64, i64, i64, i64, i64, i64, f32)
}

