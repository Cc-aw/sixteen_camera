module {
  func.func @forward(%v0: tensor<1x3x480x640xi8>, %v1: tensor<16x3x6x6xi8>, %v2: tensor<16xi32>, %v3: tensor<32x16x3x3xi8>, %v4: tensor<32xi32>, %v5: tensor<16x32x1x1xi8>, %v6: tensor<16xi32>, %v7: tensor<16x16x1x1xi8>, %v8: tensor<16xi32>, %v9: tensor<16x16x3x3xi8>, %v10: tensor<16xi32>, %v11: tensor<16x32x1x1xi8>, %v12: tensor<16xi32>, %v13: tensor<32x32x1x1xi8>, %v14: tensor<32xi32>, %v15: tensor<64x32x3x3xi8>, %v16: tensor<64xi32>, %v17: tensor<32x64x1x1xi8>, %v18: tensor<32xi32>, %v19: tensor<32x32x1x1xi8>, %v20: tensor<32xi32>, %v21: tensor<32x32x3x3xi8>, %v22: tensor<32xi32>, %v23: tensor<32x32x1x1xi8>, %v24: tensor<32xi32>, %v25: tensor<32x32x3x3xi8>, %v26: tensor<32xi32>, %v27: tensor<32x64x1x1xi8>, %v28: tensor<32xi32>, %v29: tensor<64x64x1x1xi8>, %v30: tensor<64xi32>, %v31: tensor<128x64x3x3xi8>, %v32: tensor<128xi32>, %v33: tensor<64x128x1x1xi8>, %v34: tensor<64xi32>, %v35: tensor<64x64x1x1xi8>, %v36: tensor<64xi32>, %v37: tensor<64x64x3x3xi8>, %v38: tensor<64xi32>, %v39: tensor<64x64x1x1xi8>, %v40: tensor<64xi32>, %v41: tensor<64x64x3x3xi8>, %v42: tensor<64xi32>, %v43: tensor<64x64x1x1xi8>, %v44: tensor<64xi32>, %v45: tensor<64x64x3x3xi8>, %v46: tensor<64xi32>, %v47: tensor<64x128x1x1xi8>, %v48: tensor<64xi32>, %v49: tensor<128x128x1x1xi8>, %v50: tensor<128xi32>, %v51: tensor<256x128x3x3xi8>, %v52: tensor<256xi32>, %v53: tensor<128x256x1x1xi8>, %v54: tensor<128xi32>, %v55: tensor<128x128x1x1xi8>, %v56: tensor<128xi32>, %v57: tensor<128x128x3x3xi8>, %v58: tensor<128xi32>, %v59: tensor<128x256x1x1xi8>, %v60: tensor<128xi32>, %v61: tensor<256x256x1x1xi8>, %v62: tensor<256xi32>, %v63: tensor<128x256x1x1xi8>, %v64: tensor<128xi32>, %v65: tensor<256x512x1x1xi8>, %v66: tensor<256xi32>, %v67: tensor<128x256x1x1xi8>, %v68: tensor<128xi32>, %v69: tensor<4xf32>, %v70: tensor<64x256x1x1xi8>, %v71: tensor<64xi32>, %v72: tensor<64x64x1x1xi8>, %v73: tensor<64xi32>, %v74: tensor<64x64x3x3xi8>, %v75: tensor<64xi32>, %v76: tensor<64x256x1x1xi8>, %v77: tensor<64xi32>, %v78: tensor<128x128x1x1xi8>, %v79: tensor<128xi32>, %v80: tensor<64x128x1x1xi8>, %v81: tensor<64xi32>, %v82: tensor<4xf32>, %v83: tensor<32x128x1x1xi8>, %v84: tensor<32xi32>, %v85: tensor<32x32x1x1xi8>, %v86: tensor<32xi32>, %v87: tensor<32x32x3x3xi8>, %v88: tensor<32xi32>, %v89: tensor<32x128x1x1xi8>, %v90: tensor<32xi32>, %v91: tensor<64x64x1x1xi8>, %v92: tensor<64xi32>, %v93: tensor<64x64x3x3xi8>, %v94: tensor<64xi32>, %v95: tensor<64x128x1x1xi8>, %v96: tensor<64xi32>, %v97: tensor<64x64x1x1xi8>, %v98: tensor<64xi32>, %v99: tensor<64x64x3x3xi8>, %v100: tensor<64xi32>, %v101: tensor<64x128x1x1xi8>, %v102: tensor<64xi32>, %v103: tensor<128x128x1x1xi8>, %v104: tensor<128xi32>, %v105: tensor<128x128x3x3xi8>, %v106: tensor<128xi32>, %v107: tensor<128x256x1x1xi8>, %v108: tensor<128xi32>, %v109: tensor<128x128x1x1xi8>, %v110: tensor<128xi32>, %v111: tensor<128x128x3x3xi8>, %v112: tensor<128xi32>, %v113: tensor<128x256x1x1xi8>, %v114: tensor<128xi32>, %v115: tensor<256x256x1x1xi8>, %v116: tensor<256xi32>, %v117: tensor<64x64x3x3xi8>, %v118: tensor<64xi32>, %v119: tensor<64x64x3x3xi8>, %v120: tensor<64xi32>, %v121: tensor<64x64x1x1xi8>, %v122: tensor<64xi32>, %v123: tensor<3xi64>, %v124: tensor<64x128x3x3xi8>, %v125: tensor<64xi32>, %v126: tensor<64x64x3x3xi8>, %v127: tensor<64xi32>, %v128: tensor<64x64x1x1xi8>, %v129: tensor<64xi32>, %v130: tensor<3xi64>, %v131: tensor<64x256x3x3xi8>, %v132: tensor<64xi32>, %v133: tensor<64x64x3x3xi8>, %v134: tensor<64xi32>, %v135: tensor<64x64x1x1xi8>, %v136: tensor<64xi32>, %v137: tensor<3xi64>, %v138: tensor<80x64x3x3xi8>, %v139: tensor<80xi32>, %v140: tensor<80x80x3x3xi8>, %v141: tensor<80xi32>, %v142: tensor<80x80x1x1xi8>, %v143: tensor<80xi32>, %v144: tensor<3xi64>, %v145: tensor<80x128x3x3xi8>, %v146: tensor<80xi32>, %v147: tensor<80x80x3x3xi8>, %v148: tensor<80xi32>, %v149: tensor<80x80x1x1xi8>, %v150: tensor<80xi32>, %v151: tensor<3xi64>, %v152: tensor<80x256x3x3xi8>, %v153: tensor<80xi32>, %v154: tensor<80x80x3x3xi8>, %v155: tensor<80xi32>, %v156: tensor<80x80x1x1xi8>, %v157: tensor<80xi32>, %v158: tensor<3xi64>, %v159: tensor<4xi64>, %v160: tensor<1x16x1x1xf32>, %v161: tensor<3xi64>, %v162: tensor<1x2x6300xf32>, %v163: tensor<1x2x6300xf32>, %v164: tensor<f32>, %v165: tensor<1x6300xf32>) -> tensor<1x84x6300xf32> {
  %shift0 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %tr0 = tosa.transpose %v0 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x3x480x640xi8>) -> tensor<1x480x640x3xi8>
  %tr1 = tosa.transpose %v1 {perms = array<i32: 0, 2, 3, 1>} : (tensor<16x3x6x6xi8>) -> tensor<16x6x6x3xi8>
  %izp2 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv3 = tosa.conv2d %tr0, %tr1, %v2, %izp2, %wzp2 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 2, 2, 2, 2>, stride = array<i64: 2, 2>} : (tensor<1x480x640x3xi8>, tensor<16x6x6x3xi8>, tensor<16xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x240x320x16xi32>
  %cs4 = tosa.cast %cv3 : (tensor<1x240x320x16xi32>) -> tensor<1x240x320x16xf32>
  %sp5 = "tosa.const"() <{values = dense<0.002880731904357528> : tensor<f32>}> : () -> tensor<f32>
  %shp7 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb6 = tosa.reshape %sp5, %shp7 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm8 = tosa.mul %cs4, %bb6, %shift0 : (tensor<1x240x320x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x240x320x16xf32>
  %sp9 = "tosa.const"() <{values = dense<0.001512175654661368> : tensor<f32>}> : () -> tensor<f32>
  %shp11 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb10 = tosa.reshape %sp9, %shp11 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm12 = tosa.mul %sm8, %bb10, %shift0 : (tensor<1x240x320x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x240x320x16xf32>
  %v166 = tosa.transpose %sm12 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x240x320x16xf32>) -> tensor<1x16x240x320xf32>
  %v167 = tosa.sigmoid %v166 : (tensor<1x16x240x320xf32>) -> tensor<1x16x240x320xf32>
  %mf14 = tosa.mul %v166, %v167, %shift0 : (tensor<1x16x240x320xf32>, tensor<1x16x240x320xf32>, tensor<1xi8>) -> tensor<1x16x240x320xf32>
  %sp15 = "tosa.const"() <{values = dense<5.207077447490569> : tensor<f32>}> : () -> tensor<f32>
  %shp17 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb16 = tosa.reshape %sp15, %shp17 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm18 = tosa.mul %mf14, %bb16, %shift0 : (tensor<1x16x240x320xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x16x240x320xf32>
  %cl19 = tosa.clamp %sm18 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x16x240x320xf32>) -> tensor<1x16x240x320xf32>
  %v168 = tosa.cast %cl19 : (tensor<1x16x240x320xf32>) -> tensor<1x16x240x320xi8>
  %tr20 = tosa.transpose %v168 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x16x240x320xi8>) -> tensor<1x240x320x16xi8>
  %tr21 = tosa.transpose %v3 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x16x3x3xi8>) -> tensor<32x3x3x16xi8>
  %izp22 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp22 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv23 = tosa.conv2d %tr20, %tr21, %v4, %izp22, %wzp22 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x240x320x16xi8>, tensor<32x3x3x16xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x32xi32>
  %cs24 = tosa.cast %cv23 : (tensor<1x120x160x32xi32>) -> tensor<1x120x160x32xf32>
  %sp25 = "tosa.const"() <{values = dense<0.005702999928475817> : tensor<f32>}> : () -> tensor<f32>
  %shp27 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb26 = tosa.reshape %sp25, %shp27 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm28 = tosa.mul %cs24, %bb26, %shift0 : (tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x32xf32>
  %sp29 = "tosa.const"() <{values = dense<0.006862049811135755> : tensor<f32>}> : () -> tensor<f32>
  %shp31 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb30 = tosa.reshape %sp29, %shp31 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm32 = tosa.mul %sm28, %bb30, %shift0 : (tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x32xf32>
  %v169 = tosa.transpose %sm32 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x32xf32>) -> tensor<1x32x120x160xf32>
  %v170 = tosa.sigmoid %v169 : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xf32>
  %mf34 = tosa.mul %v169, %v170, %shift0 : (tensor<1x32x120x160xf32>, tensor<1x32x120x160xf32>, tensor<1xi8>) -> tensor<1x32x120x160xf32>
  %sp35 = "tosa.const"() <{values = dense<1.147472834611827> : tensor<f32>}> : () -> tensor<f32>
  %shp37 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb36 = tosa.reshape %sp35, %shp37 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm38 = tosa.mul %mf34, %bb36, %shift0 : (tensor<1x32x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x120x160xf32>
  %cl39 = tosa.clamp %sm38 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xf32>
  %v171 = tosa.cast %cl39 : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xi8>
  %tr40 = tosa.transpose %v171 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x120x160xi8>) -> tensor<1x120x160x32xi8>
  %tr41 = tosa.transpose %v5 {perms = array<i32: 0, 2, 3, 1>} : (tensor<16x32x1x1xi8>) -> tensor<16x1x1x32xi8>
  %izp42 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp42 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv43 = tosa.conv2d %tr40, %tr41, %v6, %izp42, %wzp42 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x120x160x32xi8>, tensor<16x1x1x32xi8>, tensor<16xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x16xi32>
  %cs44 = tosa.cast %cv43 : (tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xf32>
  %sp45 = "tosa.const"() <{values = dense<0.04758585065541345> : tensor<f32>}> : () -> tensor<f32>
  %shp47 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb46 = tosa.reshape %sp45, %shp47 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm48 = tosa.mul %cs44, %bb46, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %sp49 = "tosa.const"() <{values = dense<0.0004500513208637502> : tensor<f32>}> : () -> tensor<f32>
  %shp51 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb50 = tosa.reshape %sp49, %shp51 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm52 = tosa.mul %sm48, %bb50, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %v172 = tosa.transpose %sm52 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x16xf32>) -> tensor<1x16x120x160xf32>
  %v173 = tosa.sigmoid %v172 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %mf54 = tosa.mul %v172, %v173, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %sp55 = "tosa.const"() <{values = dense<3.322245771612648> : tensor<f32>}> : () -> tensor<f32>
  %shp57 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb56 = tosa.reshape %sp55, %shp57 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm58 = tosa.mul %mf54, %bb56, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %cl59 = tosa.clamp %sm58 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %v174 = tosa.cast %cl59 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xi8>
  %tr60 = tosa.transpose %v174 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x16x120x160xi8>) -> tensor<1x120x160x16xi8>
  %tr61 = tosa.transpose %v7 {perms = array<i32: 0, 2, 3, 1>} : (tensor<16x16x1x1xi8>) -> tensor<16x1x1x16xi8>
  %izp62 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp62 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv63 = tosa.conv2d %tr60, %tr61, %v8, %izp62, %wzp62 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x120x160x16xi8>, tensor<16x1x1x16xi8>, tensor<16xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x16xi32>
  %cs64 = tosa.cast %cv63 : (tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xf32>
  %sp65 = "tosa.const"() <{values = dense<0.01804692837264893> : tensor<f32>}> : () -> tensor<f32>
  %shp67 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb66 = tosa.reshape %sp65, %shp67 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm68 = tosa.mul %cs64, %bb66, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %sp69 = "tosa.const"() <{values = dense<0.0008821330737754249> : tensor<f32>}> : () -> tensor<f32>
  %shp71 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb70 = tosa.reshape %sp69, %shp71 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm72 = tosa.mul %sm68, %bb70, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %v175 = tosa.transpose %sm72 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x16xf32>) -> tensor<1x16x120x160xf32>
  %v176 = tosa.sigmoid %v175 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %mf74 = tosa.mul %v175, %v176, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %sp75 = "tosa.const"() <{values = dense<6.16502959251566> : tensor<f32>}> : () -> tensor<f32>
  %shp77 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb76 = tosa.reshape %sp75, %shp77 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm78 = tosa.mul %mf74, %bb76, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %cl79 = tosa.clamp %sm78 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %v177 = tosa.cast %cl79 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xi8>
  %tr80 = tosa.transpose %v177 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x16x120x160xi8>) -> tensor<1x120x160x16xi8>
  %tr81 = tosa.transpose %v9 {perms = array<i32: 0, 2, 3, 1>} : (tensor<16x16x3x3xi8>) -> tensor<16x3x3x16xi8>
  %izp82 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp82 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv83 = tosa.conv2d %tr80, %tr81, %v10, %izp82, %wzp82 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x120x160x16xi8>, tensor<16x3x3x16xi8>, tensor<16xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x16xi32>
  %cs84 = tosa.cast %cv83 : (tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xf32>
  %sp85 = "tosa.const"() <{values = dense<0.006889030881369349> : tensor<f32>}> : () -> tensor<f32>
  %shp87 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb86 = tosa.reshape %sp85, %shp87 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm88 = tosa.mul %cs84, %bb86, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %sp89 = "tosa.const"() <{values = dense<0.00145326792118428> : tensor<f32>}> : () -> tensor<f32>
  %shp91 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb90 = tosa.reshape %sp89, %shp91 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm92 = tosa.mul %sm88, %bb90, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %v178 = tosa.transpose %sm92 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x16xf32>) -> tensor<1x16x120x160xf32>
  %v179 = tosa.sigmoid %v178 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %mf94 = tosa.mul %v178, %v179, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %sp95 = "tosa.const"() <{values = dense<4.629576972795699> : tensor<f32>}> : () -> tensor<f32>
  %shp97 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb96 = tosa.reshape %sp95, %shp97 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm98 = tosa.mul %mf94, %bb96, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %cl99 = tosa.clamp %sm98 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %v180 = tosa.cast %cl99 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xi8>
  %cs100 = tosa.cast %v174 : (tensor<1x16x120x160xi8>) -> tensor<1x16x120x160xi32>
  %rq101 = "tosa.const"() <{values = dense<119876> : tensor<i32>}> : () -> tensor<i32>
  %shp103 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb102 = tosa.reshape %rq101, %shp103 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp104 = tosa.mul %cs100, %bb102, %shift0 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x16x120x160xi32>
  %rsh105 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp107 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb106 = tosa.reshape %rsh105, %shp107 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs108 = tosa.arithmetic_right_shift %rp104, %bb106 {round = false} : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %cs109 = tosa.cast %v180 : (tensor<1x16x120x160xi8>) -> tensor<1x16x120x160xi32>
  %rq110 = "tosa.const"() <{values = dense<86024> : tensor<i32>}> : () -> tensor<i32>
  %shp112 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb111 = tosa.reshape %rq110, %shp112 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp113 = tosa.mul %cs109, %bb111, %shift0 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x16x120x160xi32>
  %rsh114 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp116 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb115 = tosa.reshape %rsh114, %shp116 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs117 = tosa.arithmetic_right_shift %rp113, %bb115 {round = false} : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %ad118 = tosa.add %rs108, %rs117 : (tensor<1x16x120x160xi32>, tensor<1x16x120x160xi32>) -> tensor<1x16x120x160xi32>
  %lo119 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi120 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp122 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb121 = tosa.reshape %lo119, %shp122 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx123 = tosa.maximum %ad118, %bb121 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %shp125 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb124 = tosa.reshape %hi120, %shp125 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn126 = tosa.minimum %mx123, %bb124 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %v181 = tosa.cast %mn126 : (tensor<1x16x120x160xi32>) -> tensor<1x16x120x160xi8>
  %tr127 = tosa.transpose %v171 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x120x160xi8>) -> tensor<1x120x160x32xi8>
  %tr128 = tosa.transpose %v11 {perms = array<i32: 0, 2, 3, 1>} : (tensor<16x32x1x1xi8>) -> tensor<16x1x1x32xi8>
  %izp129 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp129 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv130 = tosa.conv2d %tr127, %tr128, %v12, %izp129, %wzp129 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x120x160x32xi8>, tensor<16x1x1x32xi8>, tensor<16xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x16xi32>
  %cs131 = tosa.cast %cv130 : (tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xf32>
  %sp132 = "tosa.const"() <{values = dense<0.03738868262605299> : tensor<f32>}> : () -> tensor<f32>
  %shp134 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb133 = tosa.reshape %sp132, %shp134 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm135 = tosa.mul %cs131, %bb133, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %sp136 = "tosa.const"() <{values = dense<0.00145326792118428> : tensor<f32>}> : () -> tensor<f32>
  %shp138 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb137 = tosa.reshape %sp136, %shp138 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm139 = tosa.mul %sm135, %bb137, %shift0 : (tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x16xf32>
  %v182 = tosa.transpose %sm139 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x16xf32>) -> tensor<1x16x120x160xf32>
  %v183 = tosa.sigmoid %v182 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %mf141 = tosa.mul %v182, %v183, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %sp142 = "tosa.const"() <{values = dense<2.333385245075522> : tensor<f32>}> : () -> tensor<f32>
  %shp144 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb143 = tosa.reshape %sp142, %shp144 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm145 = tosa.mul %mf141, %bb143, %shift0 : (tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x16x120x160xf32>
  %cl146 = tosa.clamp %sm145 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xf32>
  %v184 = tosa.cast %cl146 : (tensor<1x16x120x160xf32>) -> tensor<1x16x120x160xi8>
  %cs147 = tosa.cast %v181 : (tensor<1x16x120x160xi8>) -> tensor<1x16x120x160xi32>
  %rq148 = "tosa.const"() <{values = dense<58432> : tensor<i32>}> : () -> tensor<i32>
  %shp150 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb149 = tosa.reshape %rq148, %shp150 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp151 = tosa.mul %cs147, %bb149, %shift0 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x16x120x160xi32>
  %rsh152 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp154 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb153 = tosa.reshape %rsh152, %shp154 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs155 = tosa.arithmetic_right_shift %rp151, %bb153 {round = false} : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %lo156 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi157 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp159 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb158 = tosa.reshape %lo156, %shp159 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx160 = tosa.maximum %rs155, %bb158 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %shp162 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb161 = tosa.reshape %hi157, %shp162 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn163 = tosa.minimum %mx160, %bb161 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %cs164 = tosa.cast %mn163 : (tensor<1x16x120x160xi32>) -> tensor<1x16x120x160xi8>
  %cs165 = tosa.cast %v184 : (tensor<1x16x120x160xi8>) -> tensor<1x16x120x160xi32>
  %rq166 = "tosa.const"() <{values = dense<152175> : tensor<i32>}> : () -> tensor<i32>
  %shp168 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb167 = tosa.reshape %rq166, %shp168 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp169 = tosa.mul %cs165, %bb167, %shift0 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x16x120x160xi32>
  %rsh170 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp172 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb171 = tosa.reshape %rsh170, %shp172 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs173 = tosa.arithmetic_right_shift %rp169, %bb171 {round = false} : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %lo174 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi175 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp177 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb176 = tosa.reshape %lo174, %shp177 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx178 = tosa.maximum %rs173, %bb176 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %shp180 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb179 = tosa.reshape %hi175, %shp180 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn181 = tosa.minimum %mx178, %bb179 : (tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) -> tensor<1x16x120x160xi32>
  %cs182 = tosa.cast %mn181 : (tensor<1x16x120x160xi32>) -> tensor<1x16x120x160xi8>
  %v185 = tosa.concat %cs164, %cs182 {axis = 1 : i32} : (tensor<1x16x120x160xi8>, tensor<1x16x120x160xi8>) -> tensor<1x32x120x160xi8>
  %tr183 = tosa.transpose %v185 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x120x160xi8>) -> tensor<1x120x160x32xi8>
  %tr184 = tosa.transpose %v13 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x1x1xi8>) -> tensor<32x1x1x32xi8>
  %izp185 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp185 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv186 = tosa.conv2d %tr183, %tr184, %v14, %izp185, %wzp185 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x120x160x32xi8>, tensor<32x1x1x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x120x160x32xi32>
  %cs187 = tosa.cast %cv186 : (tensor<1x120x160x32xi32>) -> tensor<1x120x160x32xf32>
  %sp188 = "tosa.const"() <{values = dense<0.008487219896744672> : tensor<f32>}> : () -> tensor<f32>
  %shp190 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb189 = tosa.reshape %sp188, %shp190 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm191 = tosa.mul %cs187, %bb189, %shift0 : (tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x32xf32>
  %sp192 = "tosa.const"() <{values = dense<0.001075902145700776> : tensor<f32>}> : () -> tensor<f32>
  %shp194 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb193 = tosa.reshape %sp192, %shp194 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm195 = tosa.mul %sm191, %bb193, %shift0 : (tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x120x160x32xf32>
  %v186 = tosa.transpose %sm195 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x120x160x32xf32>) -> tensor<1x32x120x160xf32>
  %v187 = tosa.sigmoid %v186 : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xf32>
  %mf197 = tosa.mul %v186, %v187, %shift0 : (tensor<1x32x120x160xf32>, tensor<1x32x120x160xf32>, tensor<1xi8>) -> tensor<1x32x120x160xf32>
  %sp198 = "tosa.const"() <{values = dense<6.491707700968308> : tensor<f32>}> : () -> tensor<f32>
  %shp200 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb199 = tosa.reshape %sp198, %shp200 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm201 = tosa.mul %mf197, %bb199, %shift0 : (tensor<1x32x120x160xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x120x160xf32>
  %cl202 = tosa.clamp %sm201 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xf32>
  %v188 = tosa.cast %cl202 : (tensor<1x32x120x160xf32>) -> tensor<1x32x120x160xi8>
  %tr203 = tosa.transpose %v188 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x120x160xi8>) -> tensor<1x120x160x32xi8>
  %tr204 = tosa.transpose %v15 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x32x3x3xi8>) -> tensor<64x3x3x32xi8>
  %izp205 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp205 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv206 = tosa.conv2d %tr203, %tr204, %v16, %izp205, %wzp205 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x120x160x32xi8>, tensor<64x3x3x32xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs207 = tosa.cast %cv206 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp208 = "tosa.const"() <{values = dense<0.007542412395172083> : tensor<f32>}> : () -> tensor<f32>
  %shp210 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb209 = tosa.reshape %sp208, %shp210 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm211 = tosa.mul %cs207, %bb209, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp212 = "tosa.const"() <{values = dense<0.0005312774221129498> : tensor<f32>}> : () -> tensor<f32>
  %shp214 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb213 = tosa.reshape %sp212, %shp214 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm215 = tosa.mul %sm211, %bb213, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v189 = tosa.transpose %sm215 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %v190 = tosa.sigmoid %v189 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %mf217 = tosa.mul %v189, %v190, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %sp218 = "tosa.const"() <{values = dense<11.81593256047042> : tensor<f32>}> : () -> tensor<f32>
  %shp220 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb219 = tosa.reshape %sp218, %shp220 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm221 = tosa.mul %mf217, %bb219, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %cl222 = tosa.clamp %sm221 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %v191 = tosa.cast %cl222 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xi8>
  %tr223 = tosa.transpose %v191 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr224 = tosa.transpose %v17 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x64x1x1xi8>) -> tensor<32x1x1x64xi8>
  %izp225 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp225 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv226 = tosa.conv2d %tr223, %tr224, %v18, %izp225, %wzp225 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<32x1x1x64xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs227 = tosa.cast %cv226 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp228 = "tosa.const"() <{values = dense<0.01516159556770923> : tensor<f32>}> : () -> tensor<f32>
  %shp230 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb229 = tosa.reshape %sp228, %shp230 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm231 = tosa.mul %cs227, %bb229, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp232 = "tosa.const"() <{values = dense<0.0001909718036622047> : tensor<f32>}> : () -> tensor<f32>
  %shp234 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb233 = tosa.reshape %sp232, %shp234 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm235 = tosa.mul %sm231, %bb233, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v192 = tosa.transpose %sm235 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v193 = tosa.sigmoid %v192 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf237 = tosa.mul %v192, %v193, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp238 = "tosa.const"() <{values = dense<15.71560532844668> : tensor<f32>}> : () -> tensor<f32>
  %shp240 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb239 = tosa.reshape %sp238, %shp240 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm241 = tosa.mul %mf237, %bb239, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl242 = tosa.clamp %sm241 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v194 = tosa.cast %cl242 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr243 = tosa.transpose %v194 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr244 = tosa.transpose %v19 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x1x1xi8>) -> tensor<32x1x1x32xi8>
  %izp245 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp245 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv246 = tosa.conv2d %tr243, %tr244, %v20, %izp245, %wzp245 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs247 = tosa.cast %cv246 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp248 = "tosa.const"() <{values = dense<0.01479829997001559> : tensor<f32>}> : () -> tensor<f32>
  %shp250 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb249 = tosa.reshape %sp248, %shp250 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm251 = tosa.mul %cs247, %bb249, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp252 = "tosa.const"() <{values = dense<0.0002732986155974753> : tensor<f32>}> : () -> tensor<f32>
  %shp254 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb253 = tosa.reshape %sp252, %shp254 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm255 = tosa.mul %sm251, %bb253, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v195 = tosa.transpose %sm255 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v196 = tosa.sigmoid %v195 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf257 = tosa.mul %v195, %v196, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp258 = "tosa.const"() <{values = dense<18.50291370295583> : tensor<f32>}> : () -> tensor<f32>
  %shp260 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb259 = tosa.reshape %sp258, %shp260 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm261 = tosa.mul %mf257, %bb259, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl262 = tosa.clamp %sm261 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v197 = tosa.cast %cl262 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr263 = tosa.transpose %v197 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr264 = tosa.transpose %v21 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x3x3xi8>) -> tensor<32x3x3x32xi8>
  %izp265 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp265 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv266 = tosa.conv2d %tr263, %tr264, %v22, %izp265, %wzp265 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x3x3x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs267 = tosa.cast %cv266 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp268 = "tosa.const"() <{values = dense<0.004589078236262823> : tensor<f32>}> : () -> tensor<f32>
  %shp270 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb269 = tosa.reshape %sp268, %shp270 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm271 = tosa.mul %cs267, %bb269, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp272 = "tosa.const"() <{values = dense<0.0003777168179794123> : tensor<f32>}> : () -> tensor<f32>
  %shp274 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb273 = tosa.reshape %sp272, %shp274 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm275 = tosa.mul %sm271, %bb273, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v198 = tosa.transpose %sm275 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v199 = tosa.sigmoid %v198 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf277 = tosa.mul %v198, %v199, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp278 = "tosa.const"() <{values = dense<22.17516711826565> : tensor<f32>}> : () -> tensor<f32>
  %shp280 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb279 = tosa.reshape %sp278, %shp280 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm281 = tosa.mul %mf277, %bb279, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl282 = tosa.clamp %sm281 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v200 = tosa.cast %cl282 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %cs283 = tosa.cast %v194 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq284 = "tosa.const"() <{values = dense<86932> : tensor<i32>}> : () -> tensor<i32>
  %shp286 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb285 = tosa.reshape %rq284, %shp286 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp287 = tosa.mul %cs283, %bb285, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh288 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp290 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb289 = tosa.reshape %rsh288, %shp290 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs291 = tosa.arithmetic_right_shift %rp287, %bb289 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs292 = tosa.cast %v200 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq293 = "tosa.const"() <{values = dense<61609> : tensor<i32>}> : () -> tensor<i32>
  %shp295 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb294 = tosa.reshape %rq293, %shp295 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp296 = tosa.mul %cs292, %bb294, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh297 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp299 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb298 = tosa.reshape %rsh297, %shp299 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs300 = tosa.arithmetic_right_shift %rp296, %bb298 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %ad301 = tosa.add %rs291, %rs300 : (tensor<1x32x60x80xi32>, tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi32>
  %lo302 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi303 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp305 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb304 = tosa.reshape %lo302, %shp305 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx306 = tosa.maximum %ad301, %bb304 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp308 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb307 = tosa.reshape %hi303, %shp308 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn309 = tosa.minimum %mx306, %bb307 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %v201 = tosa.cast %mn309 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %tr310 = tosa.transpose %v201 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr311 = tosa.transpose %v23 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x1x1xi8>) -> tensor<32x1x1x32xi8>
  %izp312 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp312 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv313 = tosa.conv2d %tr310, %tr311, %v24, %izp312, %wzp312 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs314 = tosa.cast %cv313 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp315 = "tosa.const"() <{values = dense<0.01626793437336005> : tensor<f32>}> : () -> tensor<f32>
  %shp317 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb316 = tosa.reshape %sp315, %shp317 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm318 = tosa.mul %cs314, %bb316, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp319 = "tosa.const"() <{values = dense<0.0003146964711821879> : tensor<f32>}> : () -> tensor<f32>
  %shp321 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb320 = tosa.reshape %sp319, %shp321 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm322 = tosa.mul %sm318, %bb320, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v202 = tosa.transpose %sm322 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v203 = tosa.sigmoid %v202 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf324 = tosa.mul %v202, %v203, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp325 = "tosa.const"() <{values = dense<16.21079894172037> : tensor<f32>}> : () -> tensor<f32>
  %shp327 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb326 = tosa.reshape %sp325, %shp327 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm328 = tosa.mul %mf324, %bb326, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl329 = tosa.clamp %sm328 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v204 = tosa.cast %cl329 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr330 = tosa.transpose %v204 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr331 = tosa.transpose %v25 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x3x3xi8>) -> tensor<32x3x3x32xi8>
  %izp332 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp332 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv333 = tosa.conv2d %tr330, %tr331, %v26, %izp332, %wzp332 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x3x3x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs334 = tosa.cast %cv333 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp335 = "tosa.const"() <{values = dense<0.00380956908663108> : tensor<f32>}> : () -> tensor<f32>
  %shp337 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb336 = tosa.reshape %sp335, %shp337 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm338 = tosa.mul %cs334, %bb336, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp339 = "tosa.const"() <{values = dense<0.0007647601793464085> : tensor<f32>}> : () -> tensor<f32>
  %shp341 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb340 = tosa.reshape %sp339, %shp341 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm342 = tosa.mul %sm338, %bb340, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v205 = tosa.transpose %sm342 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v206 = tosa.sigmoid %v205 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf344 = tosa.mul %v205, %v206, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp345 = "tosa.const"() <{values = dense<10.42676340225804> : tensor<f32>}> : () -> tensor<f32>
  %shp347 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb346 = tosa.reshape %sp345, %shp347 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm348 = tosa.mul %mf344, %bb346, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl349 = tosa.clamp %sm348 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v207 = tosa.cast %cl349 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %cs350 = tosa.cast %v201 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq351 = "tosa.const"() <{values = dense<39320> : tensor<i32>}> : () -> tensor<i32>
  %shp353 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb352 = tosa.reshape %rq351, %shp353 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp354 = tosa.mul %cs350, %bb352, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh355 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp357 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb356 = tosa.reshape %rsh355, %shp357 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs358 = tosa.arithmetic_right_shift %rp354, %bb356 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs359 = tosa.cast %v207 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq360 = "tosa.const"() <{values = dense<78613> : tensor<i32>}> : () -> tensor<i32>
  %shp362 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb361 = tosa.reshape %rq360, %shp362 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp363 = tosa.mul %cs359, %bb361, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh364 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp366 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb365 = tosa.reshape %rsh364, %shp366 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs367 = tosa.arithmetic_right_shift %rp363, %bb365 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %ad368 = tosa.add %rs358, %rs367 : (tensor<1x32x60x80xi32>, tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi32>
  %lo369 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi370 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp372 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb371 = tosa.reshape %lo369, %shp372 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx373 = tosa.maximum %ad368, %bb371 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp375 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb374 = tosa.reshape %hi370, %shp375 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn376 = tosa.minimum %mx373, %bb374 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %v208 = tosa.cast %mn376 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %tr377 = tosa.transpose %v191 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr378 = tosa.transpose %v27 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x64x1x1xi8>) -> tensor<32x1x1x64xi8>
  %izp379 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp379 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv380 = tosa.conv2d %tr377, %tr378, %v28, %izp379, %wzp379 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<32x1x1x64xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs381 = tosa.cast %cv380 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp382 = "tosa.const"() <{values = dense<0.01202230349071504> : tensor<f32>}> : () -> tensor<f32>
  %shp384 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb383 = tosa.reshape %sp382, %shp384 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm385 = tosa.mul %cs381, %bb383, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp386 = "tosa.const"() <{values = dense<0.0007647601793464085> : tensor<f32>}> : () -> tensor<f32>
  %shp388 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb387 = tosa.reshape %sp386, %shp388 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm389 = tosa.mul %sm385, %bb387, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v209 = tosa.transpose %sm389 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v210 = tosa.sigmoid %v209 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf391 = tosa.mul %v209, %v210, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp392 = "tosa.const"() <{values = dense<9.200536352471566> : tensor<f32>}> : () -> tensor<f32>
  %shp394 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb393 = tosa.reshape %sp392, %shp394 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm395 = tosa.mul %mf391, %bb393, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl396 = tosa.clamp %sm395 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v211 = tosa.cast %cl396 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %cs397 = tosa.cast %v208 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq398 = "tosa.const"() <{values = dense<53949> : tensor<i32>}> : () -> tensor<i32>
  %shp400 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb399 = tosa.reshape %rq398, %shp400 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp401 = tosa.mul %cs397, %bb399, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh402 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp404 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb403 = tosa.reshape %rsh402, %shp404 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs405 = tosa.arithmetic_right_shift %rp401, %bb403 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %lo406 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi407 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp409 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb408 = tosa.reshape %lo406, %shp409 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx410 = tosa.maximum %rs405, %bb408 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp412 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb411 = tosa.reshape %hi407, %shp412 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn413 = tosa.minimum %mx410, %bb411 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs414 = tosa.cast %mn413 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %cs415 = tosa.cast %v211 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq416 = "tosa.const"() <{values = dense<73339> : tensor<i32>}> : () -> tensor<i32>
  %shp418 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb417 = tosa.reshape %rq416, %shp418 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp419 = tosa.mul %cs415, %bb417, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh420 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp422 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb421 = tosa.reshape %rsh420, %shp422 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs423 = tosa.arithmetic_right_shift %rp419, %bb421 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %lo424 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi425 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp427 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb426 = tosa.reshape %lo424, %shp427 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx428 = tosa.maximum %rs423, %bb426 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp430 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb429 = tosa.reshape %hi425, %shp430 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn431 = tosa.minimum %mx428, %bb429 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs432 = tosa.cast %mn431 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %v212 = tosa.concat %cs414, %cs432 {axis = 1 : i32} : (tensor<1x32x60x80xi8>, tensor<1x32x60x80xi8>) -> tensor<1x64x60x80xi8>
  %tr433 = tosa.transpose %v212 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr434 = tosa.transpose %v29 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp435 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp435 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv436 = tosa.conv2d %tr433, %tr434, %v30, %izp435, %wzp435 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs437 = tosa.cast %cv436 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp438 = "tosa.const"() <{values = dense<0.01501270249340711> : tensor<f32>}> : () -> tensor<f32>
  %shp440 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb439 = tosa.reshape %sp438, %shp440 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm441 = tosa.mul %cs437, %bb439, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp442 = "tosa.const"() <{values = dense<0.0004909553104476082> : tensor<f32>}> : () -> tensor<f32>
  %shp444 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb443 = tosa.reshape %sp442, %shp444 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm445 = tosa.mul %sm441, %bb443, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v213 = tosa.transpose %sm445 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %v214 = tosa.sigmoid %v213 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %mf447 = tosa.mul %v213, %v214, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %sp448 = "tosa.const"() <{values = dense<16.03233406603144> : tensor<f32>}> : () -> tensor<f32>
  %shp450 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb449 = tosa.reshape %sp448, %shp450 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm451 = tosa.mul %mf447, %bb449, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %cl452 = tosa.clamp %sm451 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %v215 = tosa.cast %cl452 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xi8>
  %tr453 = tosa.transpose %v215 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr454 = tosa.transpose %v31 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x64x3x3xi8>) -> tensor<128x3x3x64xi8>
  %izp455 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp455 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv456 = tosa.conv2d %tr453, %tr454, %v32, %izp455, %wzp455 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x60x80x64xi8>, tensor<128x3x3x64xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x128xi32>
  %cs457 = tosa.cast %cv456 : (tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xf32>
  %sp458 = "tosa.const"() <{values = dense<0.01225865773037692> : tensor<f32>}> : () -> tensor<f32>
  %shp460 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb459 = tosa.reshape %sp458, %shp460 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm461 = tosa.mul %cs457, %bb459, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %sp462 = "tosa.const"() <{values = dense<0.0003957685441844883> : tensor<f32>}> : () -> tensor<f32>
  %shp464 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb463 = tosa.reshape %sp462, %shp464 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm465 = tosa.mul %sm461, %bb463, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %v216 = tosa.transpose %sm465 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x128xf32>) -> tensor<1x128x30x40xf32>
  %v217 = tosa.sigmoid %v216 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %mf467 = tosa.mul %v216, %v217, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %sp468 = "tosa.const"() <{values = dense<9.813339904586639> : tensor<f32>}> : () -> tensor<f32>
  %shp470 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb469 = tosa.reshape %sp468, %shp470 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm471 = tosa.mul %mf467, %bb469, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %cl472 = tosa.clamp %sm471 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %v218 = tosa.cast %cl472 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xi8>
  %tr473 = tosa.transpose %v218 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr474 = tosa.transpose %v33 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x1x1xi8>) -> tensor<64x1x1x128xi8>
  %izp475 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp475 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv476 = tosa.conv2d %tr473, %tr474, %v34, %izp475, %wzp475 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs477 = tosa.cast %cv476 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp478 = "tosa.const"() <{values = dense<0.01893602197332028> : tensor<f32>}> : () -> tensor<f32>
  %shp480 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb479 = tosa.reshape %sp478, %shp480 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm481 = tosa.mul %cs477, %bb479, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp482 = "tosa.const"() <{values = dense<9.961375537413246e-05> : tensor<f32>}> : () -> tensor<f32>
  %shp484 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb483 = tosa.reshape %sp482, %shp484 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm485 = tosa.mul %sm481, %bb483, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v219 = tosa.transpose %sm485 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v220 = tosa.sigmoid %v219 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf487 = tosa.mul %v219, %v220, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp488 = "tosa.const"() <{values = dense<25.74265818753483> : tensor<f32>}> : () -> tensor<f32>
  %shp490 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb489 = tosa.reshape %sp488, %shp490 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm491 = tosa.mul %mf487, %bb489, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl492 = tosa.clamp %sm491 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v221 = tosa.cast %cl492 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr493 = tosa.transpose %v221 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr494 = tosa.transpose %v35 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp495 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp495 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv496 = tosa.conv2d %tr493, %tr494, %v36, %izp495, %wzp495 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs497 = tosa.cast %cv496 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp498 = "tosa.const"() <{values = dense<0.0145288709770541> : tensor<f32>}> : () -> tensor<f32>
  %shp500 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb499 = tosa.reshape %sp498, %shp500 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm501 = tosa.mul %cs497, %bb499, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp502 = "tosa.const"() <{values = dense<0.0003475953969577617> : tensor<f32>}> : () -> tensor<f32>
  %shp504 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb503 = tosa.reshape %sp502, %shp504 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm505 = tosa.mul %sm501, %bb503, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v222 = tosa.transpose %sm505 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v223 = tosa.sigmoid %v222 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf507 = tosa.mul %v222, %v223, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp508 = "tosa.const"() <{values = dense<18.46883698495183> : tensor<f32>}> : () -> tensor<f32>
  %shp510 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb509 = tosa.reshape %sp508, %shp510 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm511 = tosa.mul %mf507, %bb509, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl512 = tosa.clamp %sm511 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v224 = tosa.cast %cl512 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr513 = tosa.transpose %v224 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr514 = tosa.transpose %v37 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp515 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp515 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv516 = tosa.conv2d %tr513, %tr514, %v38, %izp515, %wzp515 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs517 = tosa.cast %cv516 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp518 = "tosa.const"() <{values = dense<0.006078794630753558> : tensor<f32>}> : () -> tensor<f32>
  %shp520 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb519 = tosa.reshape %sp518, %shp520 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm521 = tosa.mul %cs517, %bb519, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp522 = "tosa.const"() <{values = dense<0.0001816815204751625> : tensor<f32>}> : () -> tensor<f32>
  %shp524 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb523 = tosa.reshape %sp522, %shp524 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm525 = tosa.mul %sm521, %bb523, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v225 = tosa.transpose %sm525 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v226 = tosa.sigmoid %v225 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf527 = tosa.mul %v225, %v226, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp528 = "tosa.const"() <{values = dense<28.04900065452297> : tensor<f32>}> : () -> tensor<f32>
  %shp530 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb529 = tosa.reshape %sp528, %shp530 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm531 = tosa.mul %mf527, %bb529, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl532 = tosa.clamp %sm531 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v227 = tosa.cast %cl532 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs533 = tosa.cast %v221 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq534 = "tosa.const"() <{values = dense<110335> : tensor<i32>}> : () -> tensor<i32>
  %shp536 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb535 = tosa.reshape %rq534, %shp536 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp537 = tosa.mul %cs533, %bb535, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh538 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp540 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb539 = tosa.reshape %rsh538, %shp540 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs541 = tosa.arithmetic_right_shift %rp537, %bb539 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs542 = tosa.cast %v227 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq543 = "tosa.const"() <{values = dense<101262> : tensor<i32>}> : () -> tensor<i32>
  %shp545 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb544 = tosa.reshape %rq543, %shp545 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp546 = tosa.mul %cs542, %bb544, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh547 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp549 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb548 = tosa.reshape %rsh547, %shp549 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs550 = tosa.arithmetic_right_shift %rp546, %bb548 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %ad551 = tosa.add %rs541, %rs550 : (tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi32>
  %lo552 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi553 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp555 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb554 = tosa.reshape %lo552, %shp555 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx556 = tosa.maximum %ad551, %bb554 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp558 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb557 = tosa.reshape %hi553, %shp558 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn559 = tosa.minimum %mx556, %bb557 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %v228 = tosa.cast %mn559 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %tr560 = tosa.transpose %v228 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr561 = tosa.transpose %v39 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp562 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp562 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv563 = tosa.conv2d %tr560, %tr561, %v40, %izp562, %wzp562 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs564 = tosa.cast %cv563 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp565 = "tosa.const"() <{values = dense<0.006710947822897221> : tensor<f32>}> : () -> tensor<f32>
  %shp567 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb566 = tosa.reshape %sp565, %shp567 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm568 = tosa.mul %cs564, %bb566, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp569 = "tosa.const"() <{values = dense<0.0003881084031317843> : tensor<f32>}> : () -> tensor<f32>
  %shp571 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb570 = tosa.reshape %sp569, %shp571 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm572 = tosa.mul %sm568, %bb570, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v229 = tosa.transpose %sm572 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v230 = tosa.sigmoid %v229 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf574 = tosa.mul %v229, %v230, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp575 = "tosa.const"() <{values = dense<20.24993200939772> : tensor<f32>}> : () -> tensor<f32>
  %shp577 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb576 = tosa.reshape %sp575, %shp577 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm578 = tosa.mul %mf574, %bb576, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl579 = tosa.clamp %sm578 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v231 = tosa.cast %cl579 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr580 = tosa.transpose %v231 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr581 = tosa.transpose %v41 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp582 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp582 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv583 = tosa.conv2d %tr580, %tr581, %v42, %izp582, %wzp582 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs584 = tosa.cast %cv583 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp585 = "tosa.const"() <{values = dense<0.007295540645634467> : tensor<f32>}> : () -> tensor<f32>
  %shp587 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb586 = tosa.reshape %sp585, %shp587 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm588 = tosa.mul %cs584, %bb586, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp589 = "tosa.const"() <{values = dense<0.0004579669832481144> : tensor<f32>}> : () -> tensor<f32>
  %shp591 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb590 = tosa.reshape %sp589, %shp591 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm592 = tosa.mul %sm588, %bb590, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v232 = tosa.transpose %sm592 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v233 = tosa.sigmoid %v232 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf594 = tosa.mul %v232, %v233, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp595 = "tosa.const"() <{values = dense<17.01342883842461> : tensor<f32>}> : () -> tensor<f32>
  %shp597 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb596 = tosa.reshape %sp595, %shp597 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm598 = tosa.mul %mf594, %bb596, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl599 = tosa.clamp %sm598 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v234 = tosa.cast %cl599 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs600 = tosa.cast %v228 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq601 = "tosa.const"() <{values = dense<25999> : tensor<i32>}> : () -> tensor<i32>
  %shp603 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb602 = tosa.reshape %rq601, %shp603 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp604 = tosa.mul %cs600, %bb602, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh605 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp607 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb606 = tosa.reshape %rsh605, %shp607 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs608 = tosa.arithmetic_right_shift %rp604, %bb606 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs609 = tosa.cast %v234 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq610 = "tosa.const"() <{values = dense<66229> : tensor<i32>}> : () -> tensor<i32>
  %shp612 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb611 = tosa.reshape %rq610, %shp612 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp613 = tosa.mul %cs609, %bb611, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh614 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp616 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb615 = tosa.reshape %rsh614, %shp616 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs617 = tosa.arithmetic_right_shift %rp613, %bb615 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %ad618 = tosa.add %rs608, %rs617 : (tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi32>
  %lo619 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi620 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp622 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb621 = tosa.reshape %lo619, %shp622 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx623 = tosa.maximum %ad618, %bb621 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp625 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb624 = tosa.reshape %hi620, %shp625 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn626 = tosa.minimum %mx623, %bb624 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %v235 = tosa.cast %mn626 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %tr627 = tosa.transpose %v235 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr628 = tosa.transpose %v43 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp629 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp629 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv630 = tosa.conv2d %tr627, %tr628, %v44, %izp629, %wzp629 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs631 = tosa.cast %cv630 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp632 = "tosa.const"() <{values = dense<0.01234618252259703> : tensor<f32>}> : () -> tensor<f32>
  %shp634 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb633 = tosa.reshape %sp632, %shp634 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm635 = tosa.mul %cs631, %bb633, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp636 = "tosa.const"() <{values = dense<0.0003371533461206571> : tensor<f32>}> : () -> tensor<f32>
  %shp638 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb637 = tosa.reshape %sp636, %shp638 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm639 = tosa.mul %sm635, %bb637, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v236 = tosa.transpose %sm639 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v237 = tosa.sigmoid %v236 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf641 = tosa.mul %v236, %v237, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp642 = "tosa.const"() <{values = dense<19.6601653017501> : tensor<f32>}> : () -> tensor<f32>
  %shp644 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb643 = tosa.reshape %sp642, %shp644 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm645 = tosa.mul %mf641, %bb643, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl646 = tosa.clamp %sm645 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v238 = tosa.cast %cl646 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr647 = tosa.transpose %v238 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr648 = tosa.transpose %v45 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp649 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp649 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv650 = tosa.conv2d %tr647, %tr648, %v46, %izp649, %wzp649 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs651 = tosa.cast %cv650 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp652 = "tosa.const"() <{values = dense<0.004302270979746697> : tensor<f32>}> : () -> tensor<f32>
  %shp654 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb653 = tosa.reshape %sp652, %shp654 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm655 = tosa.mul %cs651, %bb653, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp656 = "tosa.const"() <{values = dense<0.0008476813599745364> : tensor<f32>}> : () -> tensor<f32>
  %shp658 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb657 = tosa.reshape %sp656, %shp658 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm659 = tosa.mul %sm655, %bb657, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v239 = tosa.transpose %sm659 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v240 = tosa.sigmoid %v239 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf661 = tosa.mul %v239, %v240, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp662 = "tosa.const"() <{values = dense<8.637943392278251> : tensor<f32>}> : () -> tensor<f32>
  %shp664 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb663 = tosa.reshape %sp662, %shp664 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm665 = tosa.mul %mf661, %bb663, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl666 = tosa.clamp %sm665 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v241 = tosa.cast %cl666 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs667 = tosa.cast %v235 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq668 = "tosa.const"() <{values = dense<50910> : tensor<i32>}> : () -> tensor<i32>
  %shp670 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb669 = tosa.reshape %rq668, %shp670 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp671 = tosa.mul %cs667, %bb669, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh672 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp674 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb673 = tosa.reshape %rsh672, %shp674 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs675 = tosa.arithmetic_right_shift %rp671, %bb673 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs676 = tosa.cast %v241 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq677 = "tosa.const"() <{values = dense<101333> : tensor<i32>}> : () -> tensor<i32>
  %shp679 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb678 = tosa.reshape %rq677, %shp679 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp680 = tosa.mul %cs676, %bb678, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh681 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp683 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb682 = tosa.reshape %rsh681, %shp683 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs684 = tosa.arithmetic_right_shift %rp680, %bb682 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %ad685 = tosa.add %rs675, %rs684 : (tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi32>
  %lo686 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi687 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp689 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb688 = tosa.reshape %lo686, %shp689 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx690 = tosa.maximum %ad685, %bb688 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp692 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb691 = tosa.reshape %hi687, %shp692 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn693 = tosa.minimum %mx690, %bb691 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %v242 = tosa.cast %mn693 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %tr694 = tosa.transpose %v218 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr695 = tosa.transpose %v47 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x1x1xi8>) -> tensor<64x1x1x128xi8>
  %izp696 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp696 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv697 = tosa.conv2d %tr694, %tr695, %v48, %izp696, %wzp696 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs698 = tosa.cast %cv697 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp699 = "tosa.const"() <{values = dense<0.008472216827225624> : tensor<f32>}> : () -> tensor<f32>
  %shp701 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb700 = tosa.reshape %sp699, %shp701 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm702 = tosa.mul %cs698, %bb700, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp703 = "tosa.const"() <{values = dense<0.0008476813599745364> : tensor<f32>}> : () -> tensor<f32>
  %shp705 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb704 = tosa.reshape %sp703, %shp705 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm706 = tosa.mul %sm702, %bb704, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v243 = tosa.transpose %sm706 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v244 = tosa.sigmoid %v243 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf708 = tosa.mul %v243, %v244, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp709 = "tosa.const"() <{values = dense<9.288875257709163> : tensor<f32>}> : () -> tensor<f32>
  %shp711 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb710 = tosa.reshape %sp709, %shp711 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm712 = tosa.mul %mf708, %bb710, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl713 = tosa.clamp %sm712 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v245 = tosa.cast %cl713 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs714 = tosa.cast %v242 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq715 = "tosa.const"() <{values = dense<45579> : tensor<i32>}> : () -> tensor<i32>
  %shp717 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb716 = tosa.reshape %rq715, %shp717 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp718 = tosa.mul %cs714, %bb716, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh719 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp721 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb720 = tosa.reshape %rsh719, %shp721 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs722 = tosa.arithmetic_right_shift %rp718, %bb720 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo723 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi724 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp726 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb725 = tosa.reshape %lo723, %shp726 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx727 = tosa.maximum %rs722, %bb725 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp729 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb728 = tosa.reshape %hi724, %shp729 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn730 = tosa.minimum %mx727, %bb728 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs731 = tosa.cast %mn730 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %cs732 = tosa.cast %v245 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %lo733 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi734 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp736 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb735 = tosa.reshape %lo733, %shp736 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx737 = tosa.maximum %cs732, %bb735 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp739 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb738 = tosa.reshape %hi734, %shp739 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn740 = tosa.minimum %mx737, %bb738 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs741 = tosa.cast %mn740 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %v246 = tosa.concat %cs731, %cs741 {axis = 1 : i32} : (tensor<1x64x30x40xi8>, tensor<1x64x30x40xi8>) -> tensor<1x128x30x40xi8>
  %tr742 = tosa.transpose %v246 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr743 = tosa.transpose %v49 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x1x1xi8>) -> tensor<128x1x1x128xi8>
  %izp744 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp744 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv745 = tosa.conv2d %tr742, %tr743, %v50, %izp744, %wzp744 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x128xi32>
  %cs746 = tosa.cast %cv745 : (tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xf32>
  %sp747 = "tosa.const"() <{values = dense<0.006208567071924729> : tensor<f32>}> : () -> tensor<f32>
  %shp749 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb748 = tosa.reshape %sp747, %shp749 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm750 = tosa.mul %cs746, %bb748, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %sp751 = "tosa.const"() <{values = dense<0.000722016838244492> : tensor<f32>}> : () -> tensor<f32>
  %shp753 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb752 = tosa.reshape %sp751, %shp753 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm754 = tosa.mul %sm750, %bb752, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %v247 = tosa.transpose %sm754 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x128xf32>) -> tensor<1x128x30x40xf32>
  %v248 = tosa.sigmoid %v247 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %mf756 = tosa.mul %v247, %v248, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %sp757 = "tosa.const"() <{values = dense<10.90548909018308> : tensor<f32>}> : () -> tensor<f32>
  %shp759 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb758 = tosa.reshape %sp757, %shp759 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm760 = tosa.mul %mf756, %bb758, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %cl761 = tosa.clamp %sm760 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %v249 = tosa.cast %cl761 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xi8>
  %tr762 = tosa.transpose %v249 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr763 = tosa.transpose %v51 {perms = array<i32: 0, 2, 3, 1>} : (tensor<256x128x3x3xi8>) -> tensor<256x3x3x128xi8>
  %izp764 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp764 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv765 = tosa.conv2d %tr762, %tr763, %v52, %izp764, %wzp764 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x30x40x128xi8>, tensor<256x3x3x128xi8>, tensor<256xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x256xi32>
  %cs766 = tosa.cast %cv765 : (tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xf32>
  %sp767 = "tosa.const"() <{values = dense<0.004597220396409063> : tensor<f32>}> : () -> tensor<f32>
  %shp769 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb768 = tosa.reshape %sp767, %shp769 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm770 = tosa.mul %cs766, %bb768, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %sp771 = "tosa.const"() <{values = dense<0.0006924185219830401> : tensor<f32>}> : () -> tensor<f32>
  %shp773 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb772 = tosa.reshape %sp771, %shp773 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm774 = tosa.mul %sm770, %bb772, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %v250 = tosa.transpose %sm774 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x256xf32>) -> tensor<1x256x15x20xf32>
  %v251 = tosa.sigmoid %v250 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %mf776 = tosa.mul %v250, %v251, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %sp777 = "tosa.const"() <{values = dense<11.37159663288611> : tensor<f32>}> : () -> tensor<f32>
  %shp779 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb778 = tosa.reshape %sp777, %shp779 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm780 = tosa.mul %mf776, %bb778, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %cl781 = tosa.clamp %sm780 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %v252 = tosa.cast %cl781 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xi8>
  %tr782 = tosa.transpose %v252 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr783 = tosa.transpose %v53 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp784 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp784 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv785 = tosa.conv2d %tr782, %tr783, %v54, %izp784, %wzp784 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs786 = tosa.cast %cv785 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp787 = "tosa.const"() <{values = dense<0.007157927243031634> : tensor<f32>}> : () -> tensor<f32>
  %shp789 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb788 = tosa.reshape %sp787, %shp789 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm790 = tosa.mul %cs786, %bb788, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp791 = "tosa.const"() <{values = dense<0.0003857645130222512> : tensor<f32>}> : () -> tensor<f32>
  %shp793 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb792 = tosa.reshape %sp791, %shp793 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm794 = tosa.mul %sm790, %bb792, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v253 = tosa.transpose %sm794 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v254 = tosa.sigmoid %v253 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf796 = tosa.mul %v253, %v254, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp797 = "tosa.const"() <{values = dense<20.37150382184205> : tensor<f32>}> : () -> tensor<f32>
  %shp799 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb798 = tosa.reshape %sp797, %shp799 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm800 = tosa.mul %mf796, %bb798, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl801 = tosa.clamp %sm800 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v255 = tosa.cast %cl801 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr802 = tosa.transpose %v255 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %tr803 = tosa.transpose %v55 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x1x1xi8>) -> tensor<128x1x1x128xi8>
  %izp804 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp804 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv805 = tosa.conv2d %tr802, %tr803, %v56, %izp804, %wzp804 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x128xi8>, tensor<128x1x1x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs806 = tosa.cast %cv805 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp807 = "tosa.const"() <{values = dense<0.01293726614980326> : tensor<f32>}> : () -> tensor<f32>
  %shp809 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb808 = tosa.reshape %sp807, %shp809 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm810 = tosa.mul %cs806, %bb808, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp811 = "tosa.const"() <{values = dense<0.0008359747401867851> : tensor<f32>}> : () -> tensor<f32>
  %shp813 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb812 = tosa.reshape %sp811, %shp813 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm814 = tosa.mul %sm810, %bb812, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v256 = tosa.transpose %sm814 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v257 = tosa.sigmoid %v256 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf816 = tosa.mul %v256, %v257, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp817 = "tosa.const"() <{values = dense<9.418950395333908> : tensor<f32>}> : () -> tensor<f32>
  %shp819 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb818 = tosa.reshape %sp817, %shp819 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm820 = tosa.mul %mf816, %bb818, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl821 = tosa.clamp %sm820 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v258 = tosa.cast %cl821 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr822 = tosa.transpose %v258 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %tr823 = tosa.transpose %v57 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x3x3xi8>) -> tensor<128x3x3x128xi8>
  %izp824 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp824 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv825 = tosa.conv2d %tr822, %tr823, %v58, %izp824, %wzp824 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x128xi8>, tensor<128x3x3x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs826 = tosa.cast %cv825 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp827 = "tosa.const"() <{values = dense<0.003725768937216035> : tensor<f32>}> : () -> tensor<f32>
  %shp829 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb828 = tosa.reshape %sp827, %shp829 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm830 = tosa.mul %cs826, %bb828, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp831 = "tosa.const"() <{values = dense<0.0008296924571907005> : tensor<f32>}> : () -> tensor<f32>
  %shp833 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb832 = tosa.reshape %sp831, %shp833 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm834 = tosa.mul %sm830, %bb832, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v259 = tosa.transpose %sm834 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v260 = tosa.sigmoid %v259 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf836 = tosa.mul %v259, %v260, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp837 = "tosa.const"() <{values = dense<9.33486258661107> : tensor<f32>}> : () -> tensor<f32>
  %shp839 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb838 = tosa.reshape %sp837, %shp839 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm840 = tosa.mul %mf836, %bb838, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl841 = tosa.clamp %sm840 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v261 = tosa.cast %cl841 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %cs842 = tosa.cast %v255 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq843 = "tosa.const"() <{values = dense<30531> : tensor<i32>}> : () -> tensor<i32>
  %shp845 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb844 = tosa.reshape %rq843, %shp845 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp846 = tosa.mul %cs842, %bb844, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh847 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp849 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb848 = tosa.reshape %rsh847, %shp849 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs850 = tosa.arithmetic_right_shift %rp846, %bb848 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs851 = tosa.cast %v261 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq852 = "tosa.const"() <{values = dense<66627> : tensor<i32>}> : () -> tensor<i32>
  %shp854 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb853 = tosa.reshape %rq852, %shp854 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp855 = tosa.mul %cs851, %bb853, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh856 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp858 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb857 = tosa.reshape %rsh856, %shp858 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs859 = tosa.arithmetic_right_shift %rp855, %bb857 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %ad860 = tosa.add %rs850, %rs859 : (tensor<1x128x15x20xi32>, tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi32>
  %lo861 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi862 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp864 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb863 = tosa.reshape %lo861, %shp864 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx865 = tosa.maximum %ad860, %bb863 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp867 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb866 = tosa.reshape %hi862, %shp867 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn868 = tosa.minimum %mx865, %bb866 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %v262 = tosa.cast %mn868 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %tr869 = tosa.transpose %v252 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr870 = tosa.transpose %v59 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp871 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp871 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv872 = tosa.conv2d %tr869, %tr870, %v60, %izp871, %wzp871 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs873 = tosa.cast %cv872 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp874 = "tosa.const"() <{values = dense<0.01221552243409646> : tensor<f32>}> : () -> tensor<f32>
  %shp876 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb875 = tosa.reshape %sp874, %shp876 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm877 = tosa.mul %cs873, %bb875, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp878 = "tosa.const"() <{values = dense<0.0008296924571907005> : tensor<f32>}> : () -> tensor<f32>
  %shp880 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb879 = tosa.reshape %sp878, %shp880 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm881 = tosa.mul %sm877, %bb879, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v263 = tosa.transpose %sm881 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v264 = tosa.sigmoid %v263 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf883 = tosa.mul %v263, %v264, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp884 = "tosa.const"() <{values = dense<13.28797664446369> : tensor<f32>}> : () -> tensor<f32>
  %shp886 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb885 = tosa.reshape %sp884, %shp886 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm887 = tosa.mul %mf883, %bb885, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl888 = tosa.clamp %sm887 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v265 = tosa.cast %cl888 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %cs889 = tosa.cast %v262 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %lo890 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi891 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp893 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb892 = tosa.reshape %lo890, %shp893 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx894 = tosa.maximum %cs889, %bb892 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp896 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb895 = tosa.reshape %hi891, %shp896 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn897 = tosa.minimum %mx894, %bb895 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs898 = tosa.cast %mn897 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %cs899 = tosa.cast %v265 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq900 = "tosa.const"() <{values = dense<46806> : tensor<i32>}> : () -> tensor<i32>
  %shp902 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb901 = tosa.reshape %rq900, %shp902 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp903 = tosa.mul %cs899, %bb901, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh904 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp906 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb905 = tosa.reshape %rsh904, %shp906 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs907 = tosa.arithmetic_right_shift %rp903, %bb905 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %lo908 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi909 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp911 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb910 = tosa.reshape %lo908, %shp911 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx912 = tosa.maximum %rs907, %bb910 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp914 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb913 = tosa.reshape %hi909, %shp914 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn915 = tosa.minimum %mx912, %bb913 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs916 = tosa.cast %mn915 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %v266 = tosa.concat %cs898, %cs916 {axis = 1 : i32} : (tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>) -> tensor<1x256x15x20xi8>
  %tr917 = tosa.transpose %v266 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr918 = tosa.transpose %v61 {perms = array<i32: 0, 2, 3, 1>} : (tensor<256x256x1x1xi8>) -> tensor<256x1x1x256xi8>
  %izp919 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp919 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv920 = tosa.conv2d %tr917, %tr918, %v62, %izp919, %wzp919 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<256x1x1x256xi8>, tensor<256xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x256xi32>
  %cs921 = tosa.cast %cv920 : (tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xf32>
  %sp922 = "tosa.const"() <{values = dense<0.010901408750929> : tensor<f32>}> : () -> tensor<f32>
  %shp924 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb923 = tosa.reshape %sp922, %shp924 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm925 = tosa.mul %cs921, %bb923, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %sp926 = "tosa.const"() <{values = dense<0.0005511085736832117> : tensor<f32>}> : () -> tensor<f32>
  %shp928 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb927 = tosa.reshape %sp926, %shp928 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm929 = tosa.mul %sm925, %bb927, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %v267 = tosa.transpose %sm929 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x256xf32>) -> tensor<1x256x15x20xf32>
  %v268 = tosa.sigmoid %v267 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %mf931 = tosa.mul %v267, %v268, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %sp932 = "tosa.const"() <{values = dense<11.31651614281522> : tensor<f32>}> : () -> tensor<f32>
  %shp934 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb933 = tosa.reshape %sp932, %shp934 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm935 = tosa.mul %mf931, %bb933, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %cl936 = tosa.clamp %sm935 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %v269 = tosa.cast %cl936 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xi8>
  %tr937 = tosa.transpose %v269 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr938 = tosa.transpose %v63 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp939 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp939 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv940 = tosa.conv2d %tr937, %tr938, %v64, %izp939, %wzp939 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs941 = tosa.cast %cv940 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp942 = "tosa.const"() <{values = dense<0.006212395786110391> : tensor<f32>}> : () -> tensor<f32>
  %shp944 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb943 = tosa.reshape %sp942, %shp944 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm945 = tosa.mul %cs941, %bb943, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp946 = "tosa.const"() <{values = dense<0.0004450702070044276> : tensor<f32>}> : () -> tensor<f32>
  %shp948 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb947 = tosa.reshape %sp946, %shp948 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm949 = tosa.mul %sm945, %bb947, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v270 = tosa.transpose %sm949 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v271 = tosa.sigmoid %v270 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf951 = tosa.mul %v270, %v271, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp952 = "tosa.const"() <{values = dense<17.67821475045807> : tensor<f32>}> : () -> tensor<f32>
  %shp954 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb953 = tosa.reshape %sp952, %shp954 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm955 = tosa.mul %mf951, %bb953, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl956 = tosa.clamp %sm955 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v272 = tosa.cast %cl956 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr957 = tosa.transpose %v272 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %p958 = tosa.max_pool2d %tr957 {kernel = array<i64: 5, 5>, stride = array<i64: 1, 1>, pad = array<i64: 2, 2, 2, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
  %v273 = tosa.transpose %p958 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x128x15x20xi8>
  %tr960 = tosa.transpose %v273 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %p961 = tosa.max_pool2d %tr960 {kernel = array<i64: 5, 5>, stride = array<i64: 1, 1>, pad = array<i64: 2, 2, 2, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
  %v274 = tosa.transpose %p961 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x128x15x20xi8>
  %tr963 = tosa.transpose %v274 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %p964 = tosa.max_pool2d %tr963 {kernel = array<i64: 5, 5>, stride = array<i64: 1, 1>, pad = array<i64: 2, 2, 2, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
  %v275 = tosa.transpose %p964 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xi8>) -> tensor<1x128x15x20xi8>
  %v276 = tosa.concat %v272, %v273, %v274, %v275 {axis = 1 : i32} : (tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>) -> tensor<1x512x15x20xi8>
  %tr966 = tosa.transpose %v276 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x512x15x20xi8>) -> tensor<1x15x20x512xi8>
  %tr967 = tosa.transpose %v65 {perms = array<i32: 0, 2, 3, 1>} : (tensor<256x512x1x1xi8>) -> tensor<256x1x1x512xi8>
  %izp968 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp968 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv969 = tosa.conv2d %tr966, %tr967, %v66, %izp968, %wzp968 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x512xi8>, tensor<256x1x1x512xi8>, tensor<256xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x256xi32>
  %cs970 = tosa.cast %cv969 : (tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xf32>
  %sp971 = "tosa.const"() <{values = dense<0.008516760054957564> : tensor<f32>}> : () -> tensor<f32>
  %shp973 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb972 = tosa.reshape %sp971, %shp973 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm974 = tosa.mul %cs970, %bb972, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %sp975 = "tosa.const"() <{values = dense<0.0003885291574522968> : tensor<f32>}> : () -> tensor<f32>
  %shp977 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb976 = tosa.reshape %sp975, %shp977 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm978 = tosa.mul %sm974, %bb976, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %v277 = tosa.transpose %sm978 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x256xf32>) -> tensor<1x256x15x20xf32>
  %v278 = tosa.sigmoid %v277 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %mf980 = tosa.mul %v277, %v278, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %sp981 = "tosa.const"() <{values = dense<18.34865238093434> : tensor<f32>}> : () -> tensor<f32>
  %shp983 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb982 = tosa.reshape %sp981, %shp983 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm984 = tosa.mul %mf980, %bb982, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %cl985 = tosa.clamp %sm984 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %v279 = tosa.cast %cl985 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xi8>
  %tr986 = tosa.transpose %v279 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr987 = tosa.transpose %v67 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp988 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp988 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv989 = tosa.conv2d %tr986, %tr987, %v68, %izp988, %wzp988 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs990 = tosa.cast %cv989 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp991 = "tosa.const"() <{values = dense<0.009583145215554846> : tensor<f32>}> : () -> tensor<f32>
  %shp993 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb992 = tosa.reshape %sp991, %shp993 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm994 = tosa.mul %cs990, %bb992, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp995 = "tosa.const"() <{values = dense<0.0005203462650730233> : tensor<f32>}> : () -> tensor<f32>
  %shp997 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb996 = tosa.reshape %sp995, %shp997 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm998 = tosa.mul %sm994, %bb996, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v280 = tosa.transpose %sm998 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v281 = tosa.sigmoid %v280 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1000 = tosa.mul %v280, %v281, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1001 = "tosa.const"() <{values = dense<15.12884216189884> : tensor<f32>}> : () -> tensor<f32>
  %shp1003 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1002 = tosa.reshape %sp1001, %shp1003 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1004 = tosa.mul %mf1000, %bb1002, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1005 = tosa.clamp %sm1004 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v282 = tosa.cast %cl1005 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr1006 = tosa.transpose %v282 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %rsc1007 = "tosa.const_shape"() <{values = dense<[2, 1, 2, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %roff1007 = "tosa.const_shape"() <{values = dense<[0, 0]> : tensor<2xindex>}> : () -> !tosa.shape<2>
  %rbr1007 = "tosa.const_shape"() <{values = dense<[1, 1]> : tensor<2xindex>}> : () -> !tosa.shape<2>
  %rs1007 = "tosa.resize"(%tr1006, %rsc1007, %roff1007, %rbr1007) {mode = #tosa.resize_mode<NEAREST_NEIGHBOR>} : (tensor<1x15x20x128xi8>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x30x40x128xi8>
  %v283 = tosa.transpose %rs1007 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x128xi8>) -> tensor<1x128x30x40xi8>
  %cs1009 = tosa.cast %v283 : (tensor<1x128x30x40xi8>) -> tensor<1x128x30x40xi32>
  %rq1010 = "tosa.const"() <{values = dense<47231> : tensor<i32>}> : () -> tensor<i32>
  %shp1012 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1011 = tosa.reshape %rq1010, %shp1012 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1013 = tosa.mul %cs1009, %bb1011, %shift0 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x30x40xi32>
  %rsh1014 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1016 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1015 = tosa.reshape %rsh1014, %shp1016 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1017 = tosa.arithmetic_right_shift %rp1013, %bb1015 {round = false} : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %lo1018 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1019 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1021 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1020 = tosa.reshape %lo1018, %shp1021 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1022 = tosa.maximum %rs1017, %bb1020 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %shp1024 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1023 = tosa.reshape %hi1019, %shp1024 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1025 = tosa.minimum %mx1022, %bb1023 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %cs1026 = tosa.cast %mn1025 : (tensor<1x128x30x40xi32>) -> tensor<1x128x30x40xi8>
  %cs1027 = tosa.cast %v249 : (tensor<1x128x30x40xi8>) -> tensor<1x128x30x40xi32>
  %rq1028 = "tosa.const"() <{values = dense<65537> : tensor<i32>}> : () -> tensor<i32>
  %shp1030 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1029 = tosa.reshape %rq1028, %shp1030 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1031 = tosa.mul %cs1027, %bb1029, %shift0 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x30x40xi32>
  %rsh1032 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1034 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1033 = tosa.reshape %rsh1032, %shp1034 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1035 = tosa.arithmetic_right_shift %rp1031, %bb1033 {round = false} : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %lo1036 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1037 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1039 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1038 = tosa.reshape %lo1036, %shp1039 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1040 = tosa.maximum %rs1035, %bb1038 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %shp1042 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1041 = tosa.reshape %hi1037, %shp1042 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1043 = tosa.minimum %mx1040, %bb1041 : (tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x30x40xi32>
  %cs1044 = tosa.cast %mn1043 : (tensor<1x128x30x40xi32>) -> tensor<1x128x30x40xi8>
  %v284 = tosa.concat %cs1026, %cs1044 {axis = 1 : i32} : (tensor<1x128x30x40xi8>, tensor<1x128x30x40xi8>) -> tensor<1x256x30x40xi8>
  %tr1045 = tosa.transpose %v284 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x30x40xi8>) -> tensor<1x30x40x256xi8>
  %tr1046 = tosa.transpose %v70 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x256x1x1xi8>) -> tensor<64x1x1x256xi8>
  %izp1047 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1047 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1048 = tosa.conv2d %tr1045, %tr1046, %v71, %izp1047, %wzp1047 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x256xi8>, tensor<64x1x1x256xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1049 = tosa.cast %cv1048 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1050 = "tosa.const"() <{values = dense<0.02541921262975388> : tensor<f32>}> : () -> tensor<f32>
  %shp1052 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1051 = tosa.reshape %sp1050, %shp1052 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1053 = tosa.mul %cs1049, %bb1051, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1054 = "tosa.const"() <{values = dense<0.0002771579248831716> : tensor<f32>}> : () -> tensor<f32>
  %shp1056 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1055 = tosa.reshape %sp1054, %shp1056 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1057 = tosa.mul %sm1053, %bb1055, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v285 = tosa.transpose %sm1057 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v286 = tosa.sigmoid %v285 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1059 = tosa.mul %v285, %v286, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1060 = "tosa.const"() <{values = dense<19.02086580984383> : tensor<f32>}> : () -> tensor<f32>
  %shp1062 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1061 = tosa.reshape %sp1060, %shp1062 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1063 = tosa.mul %mf1059, %bb1061, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1064 = tosa.clamp %sm1063 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v287 = tosa.cast %cl1064 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1065 = tosa.transpose %v287 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1066 = tosa.transpose %v72 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1067 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1067 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1068 = tosa.conv2d %tr1065, %tr1066, %v73, %izp1067, %wzp1067 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1069 = tosa.cast %cv1068 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1070 = "tosa.const"() <{values = dense<0.0080243491368647> : tensor<f32>}> : () -> tensor<f32>
  %shp1072 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1071 = tosa.reshape %sp1070, %shp1072 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1073 = tosa.mul %cs1069, %bb1071, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1074 = "tosa.const"() <{values = dense<0.0003374187713799012> : tensor<f32>}> : () -> tensor<f32>
  %shp1076 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1075 = tosa.reshape %sp1074, %shp1076 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1077 = tosa.mul %sm1073, %bb1075, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v288 = tosa.transpose %sm1077 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v289 = tosa.sigmoid %v288 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1079 = tosa.mul %v288, %v289, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1080 = "tosa.const"() <{values = dense<20.34663012999573> : tensor<f32>}> : () -> tensor<f32>
  %shp1082 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1081 = tosa.reshape %sp1080, %shp1082 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1083 = tosa.mul %mf1079, %bb1081, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1084 = tosa.clamp %sm1083 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v290 = tosa.cast %cl1084 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1085 = tosa.transpose %v290 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1086 = tosa.transpose %v74 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1087 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1087 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1088 = tosa.conv2d %tr1085, %tr1086, %v75, %izp1087, %wzp1087 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1089 = tosa.cast %cv1088 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1090 = "tosa.const"() <{values = dense<0.00396349110451799> : tensor<f32>}> : () -> tensor<f32>
  %shp1092 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1091 = tosa.reshape %sp1090, %shp1092 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1093 = tosa.mul %cs1089, %bb1091, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1094 = "tosa.const"() <{values = dense<0.000333906395199265> : tensor<f32>}> : () -> tensor<f32>
  %shp1096 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1095 = tosa.reshape %sp1094, %shp1096 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1097 = tosa.mul %sm1093, %bb1095, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v291 = tosa.transpose %sm1097 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v292 = tosa.sigmoid %v291 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1099 = tosa.mul %v291, %v292, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1100 = "tosa.const"() <{values = dense<23.47649325559968> : tensor<f32>}> : () -> tensor<f32>
  %shp1102 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1101 = tosa.reshape %sp1100, %shp1102 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1103 = tosa.mul %mf1099, %bb1101, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1104 = tosa.clamp %sm1103 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v293 = tosa.cast %cl1104 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1105 = tosa.transpose %v284 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x30x40xi8>) -> tensor<1x30x40x256xi8>
  %tr1106 = tosa.transpose %v76 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x256x1x1xi8>) -> tensor<64x1x1x256xi8>
  %izp1107 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1107 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1108 = tosa.conv2d %tr1105, %tr1106, %v77, %izp1107, %wzp1107 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x256xi8>, tensor<64x1x1x256xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1109 = tosa.cast %cv1108 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1110 = "tosa.const"() <{values = dense<0.01074648481389599> : tensor<f32>}> : () -> tensor<f32>
  %shp1112 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1111 = tosa.reshape %sp1110, %shp1112 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1113 = tosa.mul %cs1109, %bb1111, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1114 = "tosa.const"() <{values = dense<0.000333906395199265> : tensor<f32>}> : () -> tensor<f32>
  %shp1116 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1115 = tosa.reshape %sp1114, %shp1116 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1117 = tosa.mul %sm1113, %bb1115, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v294 = tosa.transpose %sm1117 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v295 = tosa.sigmoid %v294 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1119 = tosa.mul %v294, %v295, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1120 = "tosa.const"() <{values = dense<14.96731289784398> : tensor<f32>}> : () -> tensor<f32>
  %shp1122 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1121 = tosa.reshape %sp1120, %shp1122 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1123 = tosa.mul %mf1119, %bb1121, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1124 = tosa.clamp %sm1123 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v296 = tosa.cast %cl1124 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs1125 = tosa.cast %v293 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1126 = "tosa.const"() <{values = dense<65829> : tensor<i32>}> : () -> tensor<i32>
  %shp1128 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1127 = tosa.reshape %rq1126, %shp1128 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1129 = tosa.mul %cs1125, %bb1127, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1130 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1132 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1131 = tosa.reshape %rsh1130, %shp1132 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1133 = tosa.arithmetic_right_shift %rp1129, %bb1131 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1134 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1135 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1137 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1136 = tosa.reshape %lo1134, %shp1137 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1138 = tosa.maximum %rs1133, %bb1136 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1140 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1139 = tosa.reshape %hi1135, %shp1140 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1141 = tosa.minimum %mx1138, %bb1139 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1142 = tosa.cast %mn1141 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %cs1143 = tosa.cast %v296 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1144 = "tosa.const"() <{values = dense<103254> : tensor<i32>}> : () -> tensor<i32>
  %shp1146 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1145 = tosa.reshape %rq1144, %shp1146 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1147 = tosa.mul %cs1143, %bb1145, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1148 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1150 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1149 = tosa.reshape %rsh1148, %shp1150 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1151 = tosa.arithmetic_right_shift %rp1147, %bb1149 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1152 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1153 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1155 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1154 = tosa.reshape %lo1152, %shp1155 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1156 = tosa.maximum %rs1151, %bb1154 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1158 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1157 = tosa.reshape %hi1153, %shp1158 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1159 = tosa.minimum %mx1156, %bb1157 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1160 = tosa.cast %mn1159 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %v297 = tosa.concat %cs1142, %cs1160 {axis = 1 : i32} : (tensor<1x64x30x40xi8>, tensor<1x64x30x40xi8>) -> tensor<1x128x30x40xi8>
  %tr1161 = tosa.transpose %v297 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1162 = tosa.transpose %v78 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x1x1xi8>) -> tensor<128x1x1x128xi8>
  %izp1163 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1163 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1164 = tosa.conv2d %tr1161, %tr1162, %v79, %izp1163, %wzp1163 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x128xi32>
  %cs1165 = tosa.cast %cv1164 : (tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xf32>
  %sp1166 = "tosa.const"() <{values = dense<0.009169819519299774> : tensor<f32>}> : () -> tensor<f32>
  %shp1168 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1167 = tosa.reshape %sp1166, %shp1168 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1169 = tosa.mul %cs1165, %bb1167, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %sp1170 = "tosa.const"() <{values = dense<0.0003794525773713413> : tensor<f32>}> : () -> tensor<f32>
  %shp1172 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1171 = tosa.reshape %sp1170, %shp1172 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1173 = tosa.mul %sm1169, %bb1171, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %v298 = tosa.transpose %sm1173 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x128xf32>) -> tensor<1x128x30x40xf32>
  %v299 = tosa.sigmoid %v298 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %mf1175 = tosa.mul %v298, %v299, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %sp1176 = "tosa.const"() <{values = dense<15.4127306007207> : tensor<f32>}> : () -> tensor<f32>
  %shp1178 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1177 = tosa.reshape %sp1176, %shp1178 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1179 = tosa.mul %mf1175, %bb1177, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %cl1180 = tosa.clamp %sm1179 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %v300 = tosa.cast %cl1180 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xi8>
  %tr1181 = tosa.transpose %v300 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1182 = tosa.transpose %v80 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x1x1xi8>) -> tensor<64x1x1x128xi8>
  %izp1183 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1183 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1184 = tosa.conv2d %tr1181, %tr1182, %v81, %izp1183, %wzp1183 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1185 = tosa.cast %cv1184 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1186 = "tosa.const"() <{values = dense<0.005732980160669968> : tensor<f32>}> : () -> tensor<f32>
  %shp1188 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1187 = tosa.reshape %sp1186, %shp1188 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1189 = tosa.mul %cs1185, %bb1187, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1190 = "tosa.const"() <{values = dense<0.0002998397224516617> : tensor<f32>}> : () -> tensor<f32>
  %shp1192 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1191 = tosa.reshape %sp1190, %shp1192 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1193 = tosa.mul %sm1189, %bb1191, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v301 = tosa.transpose %sm1193 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v302 = tosa.sigmoid %v301 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1195 = tosa.mul %v301, %v302, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1196 = "tosa.const"() <{values = dense<25.07701660880386> : tensor<f32>}> : () -> tensor<f32>
  %shp1198 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1197 = tosa.reshape %sp1196, %shp1198 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1199 = tosa.mul %mf1195, %bb1197, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1200 = tosa.clamp %sm1199 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v303 = tosa.cast %cl1200 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1201 = tosa.transpose %v303 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %rsc1202 = "tosa.const_shape"() <{values = dense<[2, 1, 2, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %roff1202 = "tosa.const_shape"() <{values = dense<[0, 0]> : tensor<2xindex>}> : () -> !tosa.shape<2>
  %rbr1202 = "tosa.const_shape"() <{values = dense<[1, 1]> : tensor<2xindex>}> : () -> !tosa.shape<2>
  %rs1202 = "tosa.resize"(%tr1201, %rsc1202, %roff1202, %rbr1202) {mode = #tosa.resize_mode<NEAREST_NEIGHBOR>} : (tensor<1x30x40x64xi8>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x60x80x64xi8>
  %v304 = tosa.transpose %rs1202 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xi8>) -> tensor<1x64x60x80xi8>
  %cs1204 = tosa.cast %v304 : (tensor<1x64x60x80xi8>) -> tensor<1x64x60x80xi32>
  %rq1205 = "tosa.const"() <{values = dense<40025> : tensor<i32>}> : () -> tensor<i32>
  %shp1207 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1206 = tosa.reshape %rq1205, %shp1207 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1208 = tosa.mul %cs1204, %bb1206, %shift0 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x60x80xi32>
  %rsh1209 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1211 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1210 = tosa.reshape %rsh1209, %shp1211 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1212 = tosa.arithmetic_right_shift %rp1208, %bb1210 {round = false} : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %lo1213 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1214 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1216 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1215 = tosa.reshape %lo1213, %shp1216 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1217 = tosa.maximum %rs1212, %bb1215 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %shp1219 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1218 = tosa.reshape %hi1214, %shp1219 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1220 = tosa.minimum %mx1217, %bb1218 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %cs1221 = tosa.cast %mn1220 : (tensor<1x64x60x80xi32>) -> tensor<1x64x60x80xi8>
  %cs1222 = tosa.cast %v215 : (tensor<1x64x60x80xi8>) -> tensor<1x64x60x80xi32>
  %rq1223 = "tosa.const"() <{values = dense<65560> : tensor<i32>}> : () -> tensor<i32>
  %shp1225 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1224 = tosa.reshape %rq1223, %shp1225 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1226 = tosa.mul %cs1222, %bb1224, %shift0 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x60x80xi32>
  %rsh1227 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1229 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1228 = tosa.reshape %rsh1227, %shp1229 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1230 = tosa.arithmetic_right_shift %rp1226, %bb1228 {round = false} : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %lo1231 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1232 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1234 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1233 = tosa.reshape %lo1231, %shp1234 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1235 = tosa.maximum %rs1230, %bb1233 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %shp1237 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1236 = tosa.reshape %hi1232, %shp1237 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1238 = tosa.minimum %mx1235, %bb1236 : (tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x60x80xi32>
  %cs1239 = tosa.cast %mn1238 : (tensor<1x64x60x80xi32>) -> tensor<1x64x60x80xi8>
  %v305 = tosa.concat %cs1221, %cs1239 {axis = 1 : i32} : (tensor<1x64x60x80xi8>, tensor<1x64x60x80xi8>) -> tensor<1x128x60x80xi8>
  %tr1240 = tosa.transpose %v305 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x60x80xi8>) -> tensor<1x60x80x128xi8>
  %tr1241 = tosa.transpose %v83 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x128x1x1xi8>) -> tensor<32x1x1x128xi8>
  %izp1242 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1242 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1243 = tosa.conv2d %tr1240, %tr1241, %v84, %izp1242, %wzp1242 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x128xi8>, tensor<32x1x1x128xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs1244 = tosa.cast %cv1243 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp1245 = "tosa.const"() <{values = dense<0.008340899890591833> : tensor<f32>}> : () -> tensor<f32>
  %shp1247 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1246 = tosa.reshape %sp1245, %shp1247 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1248 = tosa.mul %cs1244, %bb1246, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp1249 = "tosa.const"() <{values = dense<0.000240926002272079> : tensor<f32>}> : () -> tensor<f32>
  %shp1251 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1250 = tosa.reshape %sp1249, %shp1251 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1252 = tosa.mul %sm1248, %bb1250, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v306 = tosa.transpose %sm1252 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v307 = tosa.sigmoid %v306 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf1254 = tosa.mul %v306, %v307, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp1255 = "tosa.const"() <{values = dense<20.55713985798086> : tensor<f32>}> : () -> tensor<f32>
  %shp1257 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1256 = tosa.reshape %sp1255, %shp1257 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1258 = tosa.mul %mf1254, %bb1256, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl1259 = tosa.clamp %sm1258 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v308 = tosa.cast %cl1259 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr1260 = tosa.transpose %v308 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr1261 = tosa.transpose %v85 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x1x1xi8>) -> tensor<32x1x1x32xi8>
  %izp1262 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1262 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1263 = tosa.conv2d %tr1260, %tr1261, %v86, %izp1262, %wzp1262 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs1264 = tosa.cast %cv1263 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp1265 = "tosa.const"() <{values = dense<0.01783764482704429> : tensor<f32>}> : () -> tensor<f32>
  %shp1267 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1266 = tosa.reshape %sp1265, %shp1267 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1268 = tosa.mul %cs1264, %bb1266, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp1269 = "tosa.const"() <{values = dense<0.0002885320092158128> : tensor<f32>}> : () -> tensor<f32>
  %shp1271 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1270 = tosa.reshape %sp1269, %shp1271 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1272 = tosa.mul %sm1268, %bb1270, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v309 = tosa.transpose %sm1272 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v310 = tosa.sigmoid %v309 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf1274 = tosa.mul %v309, %v310, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp1275 = "tosa.const"() <{values = dense<21.98193432349782> : tensor<f32>}> : () -> tensor<f32>
  %shp1277 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1276 = tosa.reshape %sp1275, %shp1277 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1278 = tosa.mul %mf1274, %bb1276, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl1279 = tosa.clamp %sm1278 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v311 = tosa.cast %cl1279 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr1280 = tosa.transpose %v311 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x32x60x80xi8>) -> tensor<1x60x80x32xi8>
  %tr1281 = tosa.transpose %v87 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x32x3x3xi8>) -> tensor<32x3x3x32xi8>
  %izp1282 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1282 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1283 = tosa.conv2d %tr1280, %tr1281, %v88, %izp1282, %wzp1282 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x32xi8>, tensor<32x3x3x32xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs1284 = tosa.cast %cv1283 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp1285 = "tosa.const"() <{values = dense<0.007817436053854687> : tensor<f32>}> : () -> tensor<f32>
  %shp1287 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1286 = tosa.reshape %sp1285, %shp1287 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1288 = tosa.mul %cs1284, %bb1286, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp1289 = "tosa.const"() <{values = dense<0.0002461069241749079> : tensor<f32>}> : () -> tensor<f32>
  %shp1291 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1290 = tosa.reshape %sp1289, %shp1291 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1292 = tosa.mul %sm1288, %bb1290, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v312 = tosa.transpose %sm1292 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v313 = tosa.sigmoid %v312 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf1294 = tosa.mul %v312, %v313, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp1295 = "tosa.const"() <{values = dense<22.542587471154> : tensor<f32>}> : () -> tensor<f32>
  %shp1297 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1296 = tosa.reshape %sp1295, %shp1297 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1298 = tosa.mul %mf1294, %bb1296, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl1299 = tosa.clamp %sm1298 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v314 = tosa.cast %cl1299 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %tr1300 = tosa.transpose %v305 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x60x80xi8>) -> tensor<1x60x80x128xi8>
  %tr1301 = tosa.transpose %v89 {perms = array<i32: 0, 2, 3, 1>} : (tensor<32x128x1x1xi8>) -> tensor<32x1x1x128xi8>
  %izp1302 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1302 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1303 = tosa.conv2d %tr1300, %tr1301, %v90, %izp1302, %wzp1302 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x128xi8>, tensor<32x1x1x128xi8>, tensor<32xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x32xi32>
  %cs1304 = tosa.cast %cv1303 : (tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xf32>
  %sp1305 = "tosa.const"() <{values = dense<0.009539220851513807> : tensor<f32>}> : () -> tensor<f32>
  %shp1307 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1306 = tosa.reshape %sp1305, %shp1307 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1308 = tosa.mul %cs1304, %bb1306, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %sp1309 = "tosa.const"() <{values = dense<0.0002461069241749079> : tensor<f32>}> : () -> tensor<f32>
  %shp1311 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1310 = tosa.reshape %sp1309, %shp1311 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1312 = tosa.mul %sm1308, %bb1310, %shift0 : (tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x32xf32>
  %v315 = tosa.transpose %sm1312 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x32xf32>) -> tensor<1x32x60x80xf32>
  %v316 = tosa.sigmoid %v315 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %mf1314 = tosa.mul %v315, %v316, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %sp1315 = "tosa.const"() <{values = dense<37.4880910439713> : tensor<f32>}> : () -> tensor<f32>
  %shp1317 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1316 = tosa.reshape %sp1315, %shp1317 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1318 = tosa.mul %mf1314, %bb1316, %shift0 : (tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x32x60x80xf32>
  %cl1319 = tosa.clamp %sm1318 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xf32>
  %v317 = tosa.cast %cl1319 : (tensor<1x32x60x80xf32>) -> tensor<1x32x60x80xi8>
  %cs1320 = tosa.cast %v314 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq1321 = "tosa.const"() <{values = dense<93014> : tensor<i32>}> : () -> tensor<i32>
  %shp1323 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1322 = tosa.reshape %rq1321, %shp1323 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1324 = tosa.mul %cs1320, %bb1322, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh1325 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1327 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1326 = tosa.reshape %rsh1325, %shp1327 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1328 = tosa.arithmetic_right_shift %rp1324, %bb1326 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %lo1329 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1330 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1332 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1331 = tosa.reshape %lo1329, %shp1332 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1333 = tosa.maximum %rs1328, %bb1331 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp1335 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1334 = tosa.reshape %hi1330, %shp1335 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1336 = tosa.minimum %mx1333, %bb1334 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs1337 = tosa.cast %mn1336 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %cs1338 = tosa.cast %v317 : (tensor<1x32x60x80xi8>) -> tensor<1x32x60x80xi32>
  %rq1339 = "tosa.const"() <{values = dense<55932> : tensor<i32>}> : () -> tensor<i32>
  %shp1341 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1340 = tosa.reshape %rq1339, %shp1341 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1342 = tosa.mul %cs1338, %bb1340, %shift0 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x32x60x80xi32>
  %rsh1343 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1345 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1344 = tosa.reshape %rsh1343, %shp1345 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1346 = tosa.arithmetic_right_shift %rp1342, %bb1344 {round = false} : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %lo1347 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1348 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1350 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1349 = tosa.reshape %lo1347, %shp1350 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1351 = tosa.maximum %rs1346, %bb1349 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %shp1353 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1352 = tosa.reshape %hi1348, %shp1353 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1354 = tosa.minimum %mx1351, %bb1352 : (tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) -> tensor<1x32x60x80xi32>
  %cs1355 = tosa.cast %mn1354 : (tensor<1x32x60x80xi32>) -> tensor<1x32x60x80xi8>
  %v318 = tosa.concat %cs1337, %cs1355 {axis = 1 : i32} : (tensor<1x32x60x80xi8>, tensor<1x32x60x80xi8>) -> tensor<1x64x60x80xi8>
  %tr1356 = tosa.transpose %v318 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1357 = tosa.transpose %v91 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1358 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1358 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1359 = tosa.conv2d %tr1356, %tr1357, %v92, %izp1358, %wzp1358 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs1360 = tosa.cast %cv1359 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp1361 = "tosa.const"() <{values = dense<0.01338697703255983> : tensor<f32>}> : () -> tensor<f32>
  %shp1363 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1362 = tosa.reshape %sp1361, %shp1363 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1364 = tosa.mul %cs1360, %bb1362, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp1365 = "tosa.const"() <{values = dense<0.0002291907793501866> : tensor<f32>}> : () -> tensor<f32>
  %shp1367 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1366 = tosa.reshape %sp1365, %shp1367 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1368 = tosa.mul %sm1364, %bb1366, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v319 = tosa.transpose %sm1368 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %v320 = tosa.sigmoid %v319 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %mf1370 = tosa.mul %v319, %v320, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %sp1371 = "tosa.const"() <{values = dense<17.89324021676797> : tensor<f32>}> : () -> tensor<f32>
  %shp1373 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1372 = tosa.reshape %sp1371, %shp1373 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1374 = tosa.mul %mf1370, %bb1372, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %cl1375 = tosa.clamp %sm1374 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %v321 = tosa.cast %cl1375 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xi8>
  %tr1376 = tosa.transpose %v321 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1377 = tosa.transpose %v93 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1378 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1378 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1379 = tosa.conv2d %tr1376, %tr1377, %v94, %izp1378, %wzp1378 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x60x80x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1380 = tosa.cast %cv1379 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1381 = "tosa.const"() <{values = dense<0.003387767657951768> : tensor<f32>}> : () -> tensor<f32>
  %shp1383 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1382 = tosa.reshape %sp1381, %shp1383 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1384 = tosa.mul %cs1380, %bb1382, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1385 = "tosa.const"() <{values = dense<0.0003872566653595832> : tensor<f32>}> : () -> tensor<f32>
  %shp1387 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1386 = tosa.reshape %sp1385, %shp1387 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1388 = tosa.mul %sm1384, %bb1386, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v322 = tosa.transpose %sm1388 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v323 = tosa.sigmoid %v322 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1390 = tosa.mul %v322, %v323, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1391 = "tosa.const"() <{values = dense<18.74473018402876> : tensor<f32>}> : () -> tensor<f32>
  %shp1393 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1392 = tosa.reshape %sp1391, %shp1393 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1394 = tosa.mul %mf1390, %bb1392, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1395 = tosa.clamp %sm1394 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v324 = tosa.cast %cl1395 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs1396 = tosa.cast %v324 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1397 = "tosa.const"() <{values = dense<71088> : tensor<i32>}> : () -> tensor<i32>
  %shp1399 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1398 = tosa.reshape %rq1397, %shp1399 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1400 = tosa.mul %cs1396, %bb1398, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1401 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1403 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1402 = tosa.reshape %rsh1401, %shp1403 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1404 = tosa.arithmetic_right_shift %rp1400, %bb1402 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1405 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1406 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1408 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1407 = tosa.reshape %lo1405, %shp1408 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1409 = tosa.maximum %rs1404, %bb1407 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1411 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1410 = tosa.reshape %hi1406, %shp1411 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1412 = tosa.minimum %mx1409, %bb1410 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1413 = tosa.cast %mn1412 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %cs1414 = tosa.cast %v303 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1415 = "tosa.const"() <{values = dense<53138> : tensor<i32>}> : () -> tensor<i32>
  %shp1417 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1416 = tosa.reshape %rq1415, %shp1417 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1418 = tosa.mul %cs1414, %bb1416, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1419 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1421 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1420 = tosa.reshape %rsh1419, %shp1421 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1422 = tosa.arithmetic_right_shift %rp1418, %bb1420 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1423 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1424 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1426 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1425 = tosa.reshape %lo1423, %shp1426 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1427 = tosa.maximum %rs1422, %bb1425 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1429 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1428 = tosa.reshape %hi1424, %shp1429 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1430 = tosa.minimum %mx1427, %bb1428 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1431 = tosa.cast %mn1430 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %v325 = tosa.concat %cs1413, %cs1431 {axis = 1 : i32} : (tensor<1x64x30x40xi8>, tensor<1x64x30x40xi8>) -> tensor<1x128x30x40xi8>
  %tr1432 = tosa.transpose %v325 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1433 = tosa.transpose %v95 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x1x1xi8>) -> tensor<64x1x1x128xi8>
  %izp1434 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1434 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1435 = tosa.conv2d %tr1432, %tr1433, %v96, %izp1434, %wzp1434 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1436 = tosa.cast %cv1435 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1437 = "tosa.const"() <{values = dense<0.008697562299249739> : tensor<f32>}> : () -> tensor<f32>
  %shp1439 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1438 = tosa.reshape %sp1437, %shp1439 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1440 = tosa.mul %cs1436, %bb1438, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1441 = "tosa.const"() <{values = dense<0.0004092467253232846> : tensor<f32>}> : () -> tensor<f32>
  %shp1443 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1442 = tosa.reshape %sp1441, %shp1443 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1444 = tosa.mul %sm1440, %bb1442, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v326 = tosa.transpose %sm1444 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v327 = tosa.sigmoid %v326 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1446 = tosa.mul %v326, %v327, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1447 = "tosa.const"() <{values = dense<16.82647225146443> : tensor<f32>}> : () -> tensor<f32>
  %shp1449 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1448 = tosa.reshape %sp1447, %shp1449 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1450 = tosa.mul %mf1446, %bb1448, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1451 = tosa.clamp %sm1450 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v328 = tosa.cast %cl1451 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1452 = tosa.transpose %v328 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1453 = tosa.transpose %v97 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1454 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1454 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1455 = tosa.conv2d %tr1452, %tr1453, %v98, %izp1454, %wzp1454 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1456 = tosa.cast %cv1455 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1457 = "tosa.const"() <{values = dense<0.007979267772831006> : tensor<f32>}> : () -> tensor<f32>
  %shp1459 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1458 = tosa.reshape %sp1457, %shp1459 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1460 = tosa.mul %cs1456, %bb1458, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1461 = "tosa.const"() <{values = dense<0.0003446149947262052> : tensor<f32>}> : () -> tensor<f32>
  %shp1463 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1462 = tosa.reshape %sp1461, %shp1463 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1464 = tosa.mul %sm1460, %bb1462, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v329 = tosa.transpose %sm1464 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v330 = tosa.sigmoid %v329 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1466 = tosa.mul %v329, %v330, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1467 = "tosa.const"() <{values = dense<18.41475584874803> : tensor<f32>}> : () -> tensor<f32>
  %shp1469 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1468 = tosa.reshape %sp1467, %shp1469 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1470 = tosa.mul %mf1466, %bb1468, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1471 = tosa.clamp %sm1470 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v331 = tosa.cast %cl1471 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1472 = tosa.transpose %v331 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1473 = tosa.transpose %v99 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1474 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1474 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1475 = tosa.conv2d %tr1472, %tr1473, %v100, %izp1474, %wzp1474 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1476 = tosa.cast %cv1475 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1477 = "tosa.const"() <{values = dense<0.005026427152289101> : tensor<f32>}> : () -> tensor<f32>
  %shp1479 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1478 = tosa.reshape %sp1477, %shp1479 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1480 = tosa.mul %cs1476, %bb1478, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1481 = "tosa.const"() <{values = dense<0.0004183055670264783> : tensor<f32>}> : () -> tensor<f32>
  %shp1483 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1482 = tosa.reshape %sp1481, %shp1483 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1484 = tosa.mul %sm1480, %bb1482, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v332 = tosa.transpose %sm1484 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v333 = tosa.sigmoid %v332 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1486 = tosa.mul %v332, %v333, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1487 = "tosa.const"() <{values = dense<16.99080242723649> : tensor<f32>}> : () -> tensor<f32>
  %shp1489 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1488 = tosa.reshape %sp1487, %shp1489 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1490 = tosa.mul %mf1486, %bb1488, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1491 = tosa.clamp %sm1490 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v334 = tosa.cast %cl1491 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1492 = tosa.transpose %v325 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1493 = tosa.transpose %v101 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x1x1xi8>) -> tensor<64x1x1x128xi8>
  %izp1494 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1494 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1495 = tosa.conv2d %tr1492, %tr1493, %v102, %izp1494, %wzp1494 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1496 = tosa.cast %cv1495 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1497 = "tosa.const"() <{values = dense<0.008791476922212875> : tensor<f32>}> : () -> tensor<f32>
  %shp1499 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1498 = tosa.reshape %sp1497, %shp1499 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1500 = tosa.mul %cs1496, %bb1498, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1501 = "tosa.const"() <{values = dense<0.0004183055670264783> : tensor<f32>}> : () -> tensor<f32>
  %shp1503 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1502 = tosa.reshape %sp1501, %shp1503 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1504 = tosa.mul %sm1500, %bb1502, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v335 = tosa.transpose %sm1504 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v336 = tosa.sigmoid %v335 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1506 = tosa.mul %v335, %v336, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1507 = "tosa.const"() <{values = dense<25.14261677080047> : tensor<f32>}> : () -> tensor<f32>
  %shp1509 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1508 = tosa.reshape %sp1507, %shp1509 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1510 = tosa.mul %mf1506, %bb1508, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1511 = tosa.clamp %sm1510 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v337 = tosa.cast %cl1511 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %cs1512 = tosa.cast %v334 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1513 = "tosa.const"() <{values = dense<72605> : tensor<i32>}> : () -> tensor<i32>
  %shp1515 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1514 = tosa.reshape %rq1513, %shp1515 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1516 = tosa.mul %cs1512, %bb1514, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1517 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1519 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1518 = tosa.reshape %rsh1517, %shp1519 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1520 = tosa.arithmetic_right_shift %rp1516, %bb1518 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1521 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1522 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1524 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1523 = tosa.reshape %lo1521, %shp1524 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1525 = tosa.maximum %rs1520, %bb1523 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1527 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1526 = tosa.reshape %hi1522, %shp1527 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1528 = tosa.minimum %mx1525, %bb1526 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1529 = tosa.cast %mn1528 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %cs1530 = tosa.cast %v337 : (tensor<1x64x30x40xi8>) -> tensor<1x64x30x40xi32>
  %rq1531 = "tosa.const"() <{values = dense<49065> : tensor<i32>}> : () -> tensor<i32>
  %shp1533 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1532 = tosa.reshape %rq1531, %shp1533 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1534 = tosa.mul %cs1530, %bb1532, %shift0 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x64x30x40xi32>
  %rsh1535 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1537 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1536 = tosa.reshape %rsh1535, %shp1537 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1538 = tosa.arithmetic_right_shift %rp1534, %bb1536 {round = false} : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %lo1539 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1540 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1542 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1541 = tosa.reshape %lo1539, %shp1542 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1543 = tosa.maximum %rs1538, %bb1541 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %shp1545 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1544 = tosa.reshape %hi1540, %shp1545 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1546 = tosa.minimum %mx1543, %bb1544 : (tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) -> tensor<1x64x30x40xi32>
  %cs1547 = tosa.cast %mn1546 : (tensor<1x64x30x40xi32>) -> tensor<1x64x30x40xi8>
  %v338 = tosa.concat %cs1529, %cs1547 {axis = 1 : i32} : (tensor<1x64x30x40xi8>, tensor<1x64x30x40xi8>) -> tensor<1x128x30x40xi8>
  %tr1548 = tosa.transpose %v338 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1549 = tosa.transpose %v103 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x1x1xi8>) -> tensor<128x1x1x128xi8>
  %izp1550 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1550 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1551 = tosa.conv2d %tr1548, %tr1549, %v104, %izp1550, %wzp1550 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x128xi32>
  %cs1552 = tosa.cast %cv1551 : (tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xf32>
  %sp1553 = "tosa.const"() <{values = dense<0.01087895071934569> : tensor<f32>}> : () -> tensor<f32>
  %shp1555 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1554 = tosa.reshape %sp1553, %shp1555 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1556 = tosa.mul %cs1552, %bb1554, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %sp1557 = "tosa.const"() <{values = dense<0.0004427171520663842> : tensor<f32>}> : () -> tensor<f32>
  %shp1559 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1558 = tosa.reshape %sp1557, %shp1559 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1560 = tosa.mul %sm1556, %bb1558, %shift0 : (tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x128xf32>
  %v339 = tosa.transpose %sm1560 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x128xf32>) -> tensor<1x128x30x40xf32>
  %v340 = tosa.sigmoid %v339 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %mf1562 = tosa.mul %v339, %v340, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %sp1563 = "tosa.const"() <{values = dense<12.01364062539891> : tensor<f32>}> : () -> tensor<f32>
  %shp1565 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1564 = tosa.reshape %sp1563, %shp1565 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1566 = tosa.mul %mf1562, %bb1564, %shift0 : (tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x30x40xf32>
  %cl1567 = tosa.clamp %sm1566 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xf32>
  %v341 = tosa.cast %cl1567 : (tensor<1x128x30x40xf32>) -> tensor<1x128x30x40xi8>
  %tr1568 = tosa.transpose %v341 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1569 = tosa.transpose %v105 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x3x3xi8>) -> tensor<128x3x3x128xi8>
  %izp1570 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1570 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1571 = tosa.conv2d %tr1568, %tr1569, %v106, %izp1570, %wzp1570 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 0, 1, 0>, stride = array<i64: 2, 2>} : (tensor<1x30x40x128xi8>, tensor<128x3x3x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs1572 = tosa.cast %cv1571 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp1573 = "tosa.const"() <{values = dense<0.00487898277148804> : tensor<f32>}> : () -> tensor<f32>
  %shp1575 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1574 = tosa.reshape %sp1573, %shp1575 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1576 = tosa.mul %cs1572, %bb1574, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp1577 = "tosa.const"() <{values = dense<0.0005203462650730233> : tensor<f32>}> : () -> tensor<f32>
  %shp1579 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1578 = tosa.reshape %sp1577, %shp1579 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1580 = tosa.mul %sm1576, %bb1578, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v342 = tosa.transpose %sm1580 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v343 = tosa.sigmoid %v342 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1582 = tosa.mul %v342, %v343, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1583 = "tosa.const"() <{values = dense<11.04152517126413> : tensor<f32>}> : () -> tensor<f32>
  %shp1585 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1584 = tosa.reshape %sp1583, %shp1585 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1586 = tosa.mul %mf1582, %bb1584, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1587 = tosa.clamp %sm1586 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v344 = tosa.cast %cl1587 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %cs1588 = tosa.cast %v344 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq1589 = "tosa.const"() <{values = dense<89816> : tensor<i32>}> : () -> tensor<i32>
  %shp1591 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1590 = tosa.reshape %rq1589, %shp1591 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1592 = tosa.mul %cs1588, %bb1590, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh1593 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1595 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1594 = tosa.reshape %rsh1593, %shp1595 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1596 = tosa.arithmetic_right_shift %rp1592, %bb1594 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %lo1597 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1598 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1600 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1599 = tosa.reshape %lo1597, %shp1600 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1601 = tosa.maximum %rs1596, %bb1599 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp1603 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1602 = tosa.reshape %hi1598, %shp1603 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1604 = tosa.minimum %mx1601, %bb1602 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs1605 = tosa.cast %mn1604 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %cs1606 = tosa.cast %v282 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq1607 = "tosa.const"() <{values = dense<65551> : tensor<i32>}> : () -> tensor<i32>
  %shp1609 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1608 = tosa.reshape %rq1607, %shp1609 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1610 = tosa.mul %cs1606, %bb1608, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh1611 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1613 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1612 = tosa.reshape %rsh1611, %shp1613 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1614 = tosa.arithmetic_right_shift %rp1610, %bb1612 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %lo1615 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1616 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1618 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1617 = tosa.reshape %lo1615, %shp1618 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1619 = tosa.maximum %rs1614, %bb1617 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp1621 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1620 = tosa.reshape %hi1616, %shp1621 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1622 = tosa.minimum %mx1619, %bb1620 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs1623 = tosa.cast %mn1622 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %v345 = tosa.concat %cs1605, %cs1623 {axis = 1 : i32} : (tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>) -> tensor<1x256x15x20xi8>
  %tr1624 = tosa.transpose %v345 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr1625 = tosa.transpose %v107 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp1626 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1626 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1627 = tosa.conv2d %tr1624, %tr1625, %v108, %izp1626, %wzp1626 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs1628 = tosa.cast %cv1627 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp1629 = "tosa.const"() <{values = dense<0.01252255012638307> : tensor<f32>}> : () -> tensor<f32>
  %shp1631 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1630 = tosa.reshape %sp1629, %shp1631 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1632 = tosa.mul %cs1628, %bb1630, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp1633 = "tosa.const"() <{values = dense<0.0005610993010621275> : tensor<f32>}> : () -> tensor<f32>
  %shp1635 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1634 = tosa.reshape %sp1633, %shp1635 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1636 = tosa.mul %sm1632, %bb1634, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v346 = tosa.transpose %sm1636 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v347 = tosa.sigmoid %v346 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1638 = tosa.mul %v346, %v347, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1639 = "tosa.const"() <{values = dense<10.66769715499028> : tensor<f32>}> : () -> tensor<f32>
  %shp1641 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1640 = tosa.reshape %sp1639, %shp1641 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1642 = tosa.mul %mf1638, %bb1640, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1643 = tosa.clamp %sm1642 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v348 = tosa.cast %cl1643 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr1644 = tosa.transpose %v348 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %tr1645 = tosa.transpose %v109 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x1x1xi8>) -> tensor<128x1x1x128xi8>
  %izp1646 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1646 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1647 = tosa.conv2d %tr1644, %tr1645, %v110, %izp1646, %wzp1646 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x128xi8>, tensor<128x1x1x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs1648 = tosa.cast %cv1647 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp1649 = "tosa.const"() <{values = dense<0.009732753109844507> : tensor<f32>}> : () -> tensor<f32>
  %shp1651 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1650 = tosa.reshape %sp1649, %shp1651 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1652 = tosa.mul %cs1648, %bb1650, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp1653 = "tosa.const"() <{values = dense<0.0005583310498286036> : tensor<f32>}> : () -> tensor<f32>
  %shp1655 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1654 = tosa.reshape %sp1653, %shp1655 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1656 = tosa.mul %sm1652, %bb1654, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v349 = tosa.transpose %sm1656 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v350 = tosa.sigmoid %v349 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1658 = tosa.mul %v349, %v350, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1659 = "tosa.const"() <{values = dense<12.16062019649248> : tensor<f32>}> : () -> tensor<f32>
  %shp1661 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1660 = tosa.reshape %sp1659, %shp1661 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1662 = tosa.mul %mf1658, %bb1660, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1663 = tosa.clamp %sm1662 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v351 = tosa.cast %cl1663 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr1664 = tosa.transpose %v351 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x15x20xi8>) -> tensor<1x15x20x128xi8>
  %tr1665 = tosa.transpose %v111 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x128x3x3xi8>) -> tensor<128x3x3x128xi8>
  %izp1666 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1666 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1667 = tosa.conv2d %tr1664, %tr1665, %v112, %izp1666, %wzp1666 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x128xi8>, tensor<128x3x3x128xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs1668 = tosa.cast %cv1667 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp1669 = "tosa.const"() <{values = dense<0.004728952214671039> : tensor<f32>}> : () -> tensor<f32>
  %shp1671 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1670 = tosa.reshape %sp1669, %shp1671 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1672 = tosa.mul %cs1668, %bb1670, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp1673 = "tosa.const"() <{values = dense<0.0005425875300297964> : tensor<f32>}> : () -> tensor<f32>
  %shp1675 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1674 = tosa.reshape %sp1673, %shp1675 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1676 = tosa.mul %sm1672, %bb1674, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v352 = tosa.transpose %sm1676 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v353 = tosa.sigmoid %v352 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1678 = tosa.mul %v352, %v353, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1679 = "tosa.const"() <{values = dense<12.82109277188842> : tensor<f32>}> : () -> tensor<f32>
  %shp1681 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1680 = tosa.reshape %sp1679, %shp1681 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1682 = tosa.mul %mf1678, %bb1680, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1683 = tosa.clamp %sm1682 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v354 = tosa.cast %cl1683 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %tr1684 = tosa.transpose %v345 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr1685 = tosa.transpose %v113 {perms = array<i32: 0, 2, 3, 1>} : (tensor<128x256x1x1xi8>) -> tensor<128x1x1x256xi8>
  %izp1686 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1686 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1687 = tosa.conv2d %tr1684, %tr1685, %v114, %izp1686, %wzp1686 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>, tensor<128xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x128xi32>
  %cs1688 = tosa.cast %cv1687 : (tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xf32>
  %sp1689 = "tosa.const"() <{values = dense<0.006090905562879087> : tensor<f32>}> : () -> tensor<f32>
  %shp1691 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1690 = tosa.reshape %sp1689, %shp1691 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1692 = tosa.mul %cs1688, %bb1690, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %sp1693 = "tosa.const"() <{values = dense<0.0005425875300297964> : tensor<f32>}> : () -> tensor<f32>
  %shp1695 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1694 = tosa.reshape %sp1693, %shp1695 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1696 = tosa.mul %sm1692, %bb1694, %shift0 : (tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x128xf32>
  %v355 = tosa.transpose %sm1696 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x128xf32>) -> tensor<1x128x15x20xf32>
  %v356 = tosa.sigmoid %v355 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %mf1698 = tosa.mul %v355, %v356, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %sp1699 = "tosa.const"() <{values = dense<15.66617390704889> : tensor<f32>}> : () -> tensor<f32>
  %shp1701 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1700 = tosa.reshape %sp1699, %shp1701 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1702 = tosa.mul %mf1698, %bb1700, %shift0 : (tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x128x15x20xf32>
  %cl1703 = tosa.clamp %sm1702 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xf32>
  %v357 = tosa.cast %cl1703 : (tensor<1x128x15x20xf32>) -> tensor<1x128x15x20xi8>
  %cs1704 = tosa.cast %v354 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq1705 = "tosa.const"() <{values = dense<74179> : tensor<i32>}> : () -> tensor<i32>
  %shp1707 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1706 = tosa.reshape %rq1705, %shp1707 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1708 = tosa.mul %cs1704, %bb1706, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh1709 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1711 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1710 = tosa.reshape %rsh1709, %shp1711 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1712 = tosa.arithmetic_right_shift %rp1708, %bb1710 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %lo1713 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1714 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1716 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1715 = tosa.reshape %lo1713, %shp1716 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1717 = tosa.maximum %rs1712, %bb1715 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp1719 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1718 = tosa.reshape %hi1714, %shp1719 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1720 = tosa.minimum %mx1717, %bb1718 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs1721 = tosa.cast %mn1720 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %cs1722 = tosa.cast %v357 : (tensor<1x128x15x20xi8>) -> tensor<1x128x15x20xi32>
  %rq1723 = "tosa.const"() <{values = dense<60708> : tensor<i32>}> : () -> tensor<i32>
  %shp1725 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1724 = tosa.reshape %rq1723, %shp1725 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rp1726 = tosa.mul %cs1722, %bb1724, %shift0 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>, tensor<1xi8>) -> tensor<1x128x15x20xi32>
  %rsh1727 = "tosa.const"() <{values = dense<16> : tensor<i32>}> : () -> tensor<i32>
  %shp1729 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1728 = tosa.reshape %rsh1727, %shp1729 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %rs1730 = tosa.arithmetic_right_shift %rp1726, %bb1728 {round = false} : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %lo1731 = "tosa.const"() <{values = dense<-128> : tensor<i32>}> : () -> tensor<i32>
  %hi1732 = "tosa.const"() <{values = dense<127> : tensor<i32>}> : () -> tensor<i32>
  %shp1734 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1733 = tosa.reshape %lo1731, %shp1734 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mx1735 = tosa.maximum %rs1730, %bb1733 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %shp1737 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1736 = tosa.reshape %hi1732, %shp1737 : (tensor<i32>, !tosa.shape<4>) -> tensor<1x1x1x1xi32>
  %mn1738 = tosa.minimum %mx1735, %bb1736 : (tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) -> tensor<1x128x15x20xi32>
  %cs1739 = tosa.cast %mn1738 : (tensor<1x128x15x20xi32>) -> tensor<1x128x15x20xi8>
  %v358 = tosa.concat %cs1721, %cs1739 {axis = 1 : i32} : (tensor<1x128x15x20xi8>, tensor<1x128x15x20xi8>) -> tensor<1x256x15x20xi8>
  %tr1740 = tosa.transpose %v358 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr1741 = tosa.transpose %v115 {perms = array<i32: 0, 2, 3, 1>} : (tensor<256x256x1x1xi8>) -> tensor<256x1x1x256xi8>
  %izp1742 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1742 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1743 = tosa.conv2d %tr1740, %tr1741, %v116, %izp1742, %wzp1742 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<256x1x1x256xi8>, tensor<256xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x256xi32>
  %cs1744 = tosa.cast %cv1743 : (tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xf32>
  %sp1745 = "tosa.const"() <{values = dense<0.0181710895548913> : tensor<f32>}> : () -> tensor<f32>
  %shp1747 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1746 = tosa.reshape %sp1745, %shp1747 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1748 = tosa.mul %cs1744, %bb1746, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %sp1749 = "tosa.const"() <{values = dense<0.000473392217421947> : tensor<f32>}> : () -> tensor<f32>
  %shp1751 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1750 = tosa.reshape %sp1749, %shp1751 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1752 = tosa.mul %sm1748, %bb1750, %shift0 : (tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x256xf32>
  %v359 = tosa.transpose %sm1752 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x256xf32>) -> tensor<1x256x15x20xf32>
  %v360 = tosa.sigmoid %v359 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %mf1754 = tosa.mul %v359, %v360, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %sp1755 = "tosa.const"() <{values = dense<7.384266781500501> : tensor<f32>}> : () -> tensor<f32>
  %shp1757 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1756 = tosa.reshape %sp1755, %shp1757 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1758 = tosa.mul %mf1754, %bb1756, %shift0 : (tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x256x15x20xf32>
  %cl1759 = tosa.clamp %sm1758 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xf32>
  %v361 = tosa.cast %cl1759 : (tensor<1x256x15x20xf32>) -> tensor<1x256x15x20xi8>
  %tr1760 = tosa.transpose %v321 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1761 = tosa.transpose %v117 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1762 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1762 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1763 = tosa.conv2d %tr1760, %tr1761, %v118, %izp1762, %wzp1762 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs1764 = tosa.cast %cv1763 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp1765 = "tosa.const"() <{values = dense<0.009899723110967198> : tensor<f32>}> : () -> tensor<f32>
  %shp1767 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1766 = tosa.reshape %sp1765, %shp1767 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1768 = tosa.mul %cs1764, %bb1766, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp1769 = "tosa.const"() <{values = dense<0.0002975968524034827> : tensor<f32>}> : () -> tensor<f32>
  %shp1771 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1770 = tosa.reshape %sp1769, %shp1771 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1772 = tosa.mul %sm1768, %bb1770, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v362 = tosa.transpose %sm1772 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %v363 = tosa.sigmoid %v362 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %mf1774 = tosa.mul %v362, %v363, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %sp1775 = "tosa.const"() <{values = dense<12.33252103820911> : tensor<f32>}> : () -> tensor<f32>
  %shp1777 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1776 = tosa.reshape %sp1775, %shp1777 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1778 = tosa.mul %mf1774, %bb1776, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %cl1779 = tosa.clamp %sm1778 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %v364 = tosa.cast %cl1779 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xi8>
  %tr1780 = tosa.transpose %v364 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1781 = tosa.transpose %v119 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1782 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1782 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1783 = tosa.conv2d %tr1780, %tr1781, %v120, %izp1782, %wzp1782 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs1784 = tosa.cast %cv1783 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp1785 = "tosa.const"() <{values = dense<0.006113942570336641> : tensor<f32>}> : () -> tensor<f32>
  %shp1787 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1786 = tosa.reshape %sp1785, %shp1787 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1788 = tosa.mul %cs1784, %bb1786, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp1789 = "tosa.const"() <{values = dense<0.002130011630018377> : tensor<f32>}> : () -> tensor<f32>
  %shp1791 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1790 = tosa.reshape %sp1789, %shp1791 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1792 = tosa.mul %sm1788, %bb1790, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v365 = tosa.transpose %sm1792 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %v366 = tosa.sigmoid %v365 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %mf1794 = tosa.mul %v365, %v366, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %sp1795 = "tosa.const"() <{values = dense<3.696700824099989> : tensor<f32>}> : () -> tensor<f32>
  %shp1797 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1796 = tosa.reshape %sp1795, %shp1797 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1798 = tosa.mul %mf1794, %bb1796, %shift0 : (tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x60x80xf32>
  %cl1799 = tosa.clamp %sm1798 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xf32>
  %v367 = tosa.cast %cl1799 : (tensor<1x64x60x80xf32>) -> tensor<1x64x60x80xi8>
  %tr1800 = tosa.transpose %v367 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1801 = tosa.transpose %v121 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1802 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1802 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1803 = tosa.conv2d %tr1800, %tr1801, %v122, %izp1802, %wzp1802 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x64xi32>
  %cs1804 = tosa.cast %cv1803 : (tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xf32>
  %sp1805 = "tosa.const"() <{values = dense<0.005432026191325574> : tensor<f32>}> : () -> tensor<f32>
  %shp1807 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1806 = tosa.reshape %sp1805, %shp1807 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1808 = tosa.mul %cs1804, %bb1806, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %sp1809 = "tosa.const"() <{values = dense<0.1358446586789109> : tensor<f32>}> : () -> tensor<f32>
  %shp1811 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1810 = tosa.reshape %sp1809, %shp1811 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1812 = tosa.mul %sm1808, %bb1810, %shift0 : (tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x64xf32>
  %v368 = tosa.transpose %sm1812 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x64xf32>) -> tensor<1x64x60x80xf32>
  %shp1814 = "tosa.const_shape"() <{values = dense<[1, 64, 4800]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v369 = tosa.reshape %v368, %shp1814 : (tensor<1x64x60x80xf32>, !tosa.shape<3>) -> tensor<1x64x4800xf32>
  %tr1815 = tosa.transpose %v341 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1816 = tosa.transpose %v124 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x128x3x3xi8>) -> tensor<64x3x3x128xi8>
  %izp1817 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1817 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1818 = tosa.conv2d %tr1815, %tr1816, %v125, %izp1817, %wzp1817 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<64x3x3x128xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1819 = tosa.cast %cv1818 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1820 = "tosa.const"() <{values = dense<0.01534914192112415> : tensor<f32>}> : () -> tensor<f32>
  %shp1822 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1821 = tosa.reshape %sp1820, %shp1822 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1823 = tosa.mul %cs1819, %bb1821, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1824 = "tosa.const"() <{values = dense<0.0003955027641576889> : tensor<f32>}> : () -> tensor<f32>
  %shp1826 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1825 = tosa.reshape %sp1824, %shp1826 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1827 = tosa.mul %sm1823, %bb1825, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v370 = tosa.transpose %sm1827 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v371 = tosa.sigmoid %v370 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1829 = tosa.mul %v370, %v371, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1830 = "tosa.const"() <{values = dense<11.7519948822856> : tensor<f32>}> : () -> tensor<f32>
  %shp1832 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1831 = tosa.reshape %sp1830, %shp1832 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1833 = tosa.mul %mf1829, %bb1831, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1834 = tosa.clamp %sm1833 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v372 = tosa.cast %cl1834 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1835 = tosa.transpose %v372 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1836 = tosa.transpose %v126 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1837 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1837 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1838 = tosa.conv2d %tr1835, %tr1836, %v127, %izp1837, %wzp1837 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1839 = tosa.cast %cv1838 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1840 = "tosa.const"() <{values = dense<0.007832830256382197> : tensor<f32>}> : () -> tensor<f32>
  %shp1842 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1841 = tosa.reshape %sp1840, %shp1842 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1843 = tosa.mul %cs1839, %bb1841, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1844 = "tosa.const"() <{values = dense<0.00141242814452792> : tensor<f32>}> : () -> tensor<f32>
  %shp1846 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1845 = tosa.reshape %sp1844, %shp1846 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1847 = tosa.mul %sm1843, %bb1845, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v373 = tosa.transpose %sm1847 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %v374 = tosa.sigmoid %v373 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %mf1849 = tosa.mul %v373, %v374, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %sp1850 = "tosa.const"() <{values = dense<5.574808020172418> : tensor<f32>}> : () -> tensor<f32>
  %shp1852 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1851 = tosa.reshape %sp1850, %shp1852 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1853 = tosa.mul %mf1849, %bb1851, %shift0 : (tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x30x40xf32>
  %cl1854 = tosa.clamp %sm1853 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xf32>
  %v375 = tosa.cast %cl1854 : (tensor<1x64x30x40xf32>) -> tensor<1x64x30x40xi8>
  %tr1855 = tosa.transpose %v375 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x30x40xi8>) -> tensor<1x30x40x64xi8>
  %tr1856 = tosa.transpose %v128 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1857 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1857 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1858 = tosa.conv2d %tr1855, %tr1856, %v129, %izp1857, %wzp1857 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x64xi32>
  %cs1859 = tosa.cast %cv1858 : (tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xf32>
  %sp1860 = "tosa.const"() <{values = dense<0.005818568300985312> : tensor<f32>}> : () -> tensor<f32>
  %shp1862 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1861 = tosa.reshape %sp1860, %shp1862 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1863 = tosa.mul %cs1859, %bb1861, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %sp1864 = "tosa.const"() <{values = dense<0.09541489007904774> : tensor<f32>}> : () -> tensor<f32>
  %shp1866 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1865 = tosa.reshape %sp1864, %shp1866 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1867 = tosa.mul %sm1863, %bb1865, %shift0 : (tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x64xf32>
  %v376 = tosa.transpose %sm1867 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x64xf32>) -> tensor<1x64x30x40xf32>
  %shp1869 = "tosa.const_shape"() <{values = dense<[1, 64, 1200]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v377 = tosa.reshape %v376, %shp1869 : (tensor<1x64x30x40xf32>, !tosa.shape<3>) -> tensor<1x64x1200xf32>
  %tr1870 = tosa.transpose %v361 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr1871 = tosa.transpose %v131 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x256x3x3xi8>) -> tensor<64x3x3x256xi8>
  %izp1872 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1872 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1873 = tosa.conv2d %tr1870, %tr1871, %v132, %izp1872, %wzp1872 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<64x3x3x256xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x64xi32>
  %cs1874 = tosa.cast %cv1873 : (tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xf32>
  %sp1875 = "tosa.const"() <{values = dense<0.008036410689612444> : tensor<f32>}> : () -> tensor<f32>
  %shp1877 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1876 = tosa.reshape %sp1875, %shp1877 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1878 = tosa.mul %cs1874, %bb1876, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %sp1879 = "tosa.const"() <{values = dense<0.0005280130284534251> : tensor<f32>}> : () -> tensor<f32>
  %shp1881 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1880 = tosa.reshape %sp1879, %shp1881 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1882 = tosa.mul %sm1878, %bb1880, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %v378 = tosa.transpose %sm1882 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x64xf32>) -> tensor<1x64x15x20xf32>
  %v379 = tosa.sigmoid %v378 : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xf32>
  %mf1884 = tosa.mul %v378, %v379, %shift0 : (tensor<1x64x15x20xf32>, tensor<1x64x15x20xf32>, tensor<1xi8>) -> tensor<1x64x15x20xf32>
  %sp1885 = "tosa.const"() <{values = dense<8.328524580936582> : tensor<f32>}> : () -> tensor<f32>
  %shp1887 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1886 = tosa.reshape %sp1885, %shp1887 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1888 = tosa.mul %mf1884, %bb1886, %shift0 : (tensor<1x64x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x15x20xf32>
  %cl1889 = tosa.clamp %sm1888 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xf32>
  %v380 = tosa.cast %cl1889 : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xi8>
  %tr1890 = tosa.transpose %v380 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x15x20xi8>) -> tensor<1x15x20x64xi8>
  %tr1891 = tosa.transpose %v133 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x3x3xi8>) -> tensor<64x3x3x64xi8>
  %izp1892 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1892 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1893 = tosa.conv2d %tr1890, %tr1891, %v134, %izp1892, %wzp1892 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x64xi8>, tensor<64x3x3x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x64xi32>
  %cs1894 = tosa.cast %cv1893 : (tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xf32>
  %sp1895 = "tosa.const"() <{values = dense<0.005923461158920044> : tensor<f32>}> : () -> tensor<f32>
  %shp1897 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1896 = tosa.reshape %sp1895, %shp1897 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1898 = tosa.mul %cs1894, %bb1896, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %sp1899 = "tosa.const"() <{values = dense<0.001607452502319555> : tensor<f32>}> : () -> tensor<f32>
  %shp1901 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1900 = tosa.reshape %sp1899, %shp1901 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1902 = tosa.mul %sm1898, %bb1900, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %v381 = tosa.transpose %sm1902 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x64xf32>) -> tensor<1x64x15x20xf32>
  %v382 = tosa.sigmoid %v381 : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xf32>
  %mf1904 = tosa.mul %v381, %v382, %shift0 : (tensor<1x64x15x20xf32>, tensor<1x64x15x20xf32>, tensor<1xi8>) -> tensor<1x64x15x20xf32>
  %sp1905 = "tosa.const"() <{values = dense<4.898443802643801> : tensor<f32>}> : () -> tensor<f32>
  %shp1907 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1906 = tosa.reshape %sp1905, %shp1907 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1908 = tosa.mul %mf1904, %bb1906, %shift0 : (tensor<1x64x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x15x20xf32>
  %cl1909 = tosa.clamp %sm1908 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xf32>
  %v383 = tosa.cast %cl1909 : (tensor<1x64x15x20xf32>) -> tensor<1x64x15x20xi8>
  %tr1910 = tosa.transpose %v383 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x15x20xi8>) -> tensor<1x15x20x64xi8>
  %tr1911 = tosa.transpose %v135 {perms = array<i32: 0, 2, 3, 1>} : (tensor<64x64x1x1xi8>) -> tensor<64x1x1x64xi8>
  %izp1912 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1912 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1913 = tosa.conv2d %tr1910, %tr1911, %v136, %izp1912, %wzp1912 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x64xi8>, tensor<64x1x1x64xi8>, tensor<64xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x64xi32>
  %cs1914 = tosa.cast %cv1913 : (tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xf32>
  %sp1915 = "tosa.const"() <{values = dense<0.006006887305775968> : tensor<f32>}> : () -> tensor<f32>
  %shp1917 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1916 = tosa.reshape %sp1915, %shp1917 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1918 = tosa.mul %cs1914, %bb1916, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %sp1919 = "tosa.const"() <{values = dense<0.1040745382233867> : tensor<f32>}> : () -> tensor<f32>
  %shp1921 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1920 = tosa.reshape %sp1919, %shp1921 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1922 = tosa.mul %sm1918, %bb1920, %shift0 : (tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x64xf32>
  %v384 = tosa.transpose %sm1922 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x64xf32>) -> tensor<1x64x15x20xf32>
  %shp1924 = "tosa.const_shape"() <{values = dense<[1, 64, 300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v385 = tosa.reshape %v384, %shp1924 : (tensor<1x64x15x20xf32>, !tosa.shape<3>) -> tensor<1x64x300xf32>
  %sp1925 = "tosa.const"() <{values = dense<0.7023823461809794> : tensor<f32>}> : () -> tensor<f32>
  %shp1927 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb1926 = tosa.reshape %sp1925, %shp1927 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm1928 = tosa.mul %v377, %bb1926, %shift0 : (tensor<1x64x1200xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x1200xf32>
  %sp1929 = "tosa.const"() <{values = dense<0.766129042065485> : tensor<f32>}> : () -> tensor<f32>
  %shp1931 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb1930 = tosa.reshape %sp1929, %shp1931 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm1932 = tosa.mul %v385, %bb1930, %shift0 : (tensor<1x64x300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x64x300xf32>
  %v386 = tosa.concat %v369, %sm1928, %sm1932 {axis = 2 : i32} : (tensor<1x64x4800xf32>, tensor<1x64x1200xf32>, tensor<1x64x300xf32>) -> tensor<1x64x6300xf32>
  %tr1933 = tosa.transpose %v321 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x64x60x80xi8>) -> tensor<1x60x80x64xi8>
  %tr1934 = tosa.transpose %v138 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x64x3x3xi8>) -> tensor<80x3x3x64xi8>
  %izp1935 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1935 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1936 = tosa.conv2d %tr1933, %tr1934, %v139, %izp1935, %wzp1935 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x64xi8>, tensor<80x3x3x64xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x80xi32>
  %cs1937 = tosa.cast %cv1936 : (tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xf32>
  %sp1938 = "tosa.const"() <{values = dense<0.007169479300447184> : tensor<f32>}> : () -> tensor<f32>
  %shp1940 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1939 = tosa.reshape %sp1938, %shp1940 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1941 = tosa.mul %cs1937, %bb1939, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %sp1942 = "tosa.const"() <{values = dense<0.0003366158141465453> : tensor<f32>}> : () -> tensor<f32>
  %shp1944 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1943 = tosa.reshape %sp1942, %shp1944 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1945 = tosa.mul %sm1941, %bb1943, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %v387 = tosa.transpose %sm1945 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x80xf32>) -> tensor<1x80x60x80xf32>
  %v388 = tosa.sigmoid %v387 : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xf32>
  %mf1947 = tosa.mul %v387, %v388, %shift0 : (tensor<1x80x60x80xf32>, tensor<1x80x60x80xf32>, tensor<1xi8>) -> tensor<1x80x60x80xf32>
  %sp1948 = "tosa.const"() <{values = dense<15.07774047348958> : tensor<f32>}> : () -> tensor<f32>
  %shp1950 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1949 = tosa.reshape %sp1948, %shp1950 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1951 = tosa.mul %mf1947, %bb1949, %shift0 : (tensor<1x80x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x60x80xf32>
  %cl1952 = tosa.clamp %sm1951 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xf32>
  %v389 = tosa.cast %cl1952 : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xi8>
  %tr1953 = tosa.transpose %v389 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x60x80xi8>) -> tensor<1x60x80x80xi8>
  %tr1954 = tosa.transpose %v140 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x3x3xi8>) -> tensor<80x3x3x80xi8>
  %izp1955 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1955 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1956 = tosa.conv2d %tr1953, %tr1954, %v141, %izp1955, %wzp1955 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x60x80x80xi8>, tensor<80x3x3x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x80xi32>
  %cs1957 = tosa.cast %cv1956 : (tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xf32>
  %sp1958 = "tosa.const"() <{values = dense<0.006376544519253703> : tensor<f32>}> : () -> tensor<f32>
  %shp1960 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1959 = tosa.reshape %sp1958, %shp1960 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1961 = tosa.mul %cs1957, %bb1959, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %sp1962 = "tosa.const"() <{values = dense<0.002001352101459086> : tensor<f32>}> : () -> tensor<f32>
  %shp1964 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1963 = tosa.reshape %sp1962, %shp1964 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1965 = tosa.mul %sm1961, %bb1963, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %v390 = tosa.transpose %sm1965 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x80xf32>) -> tensor<1x80x60x80xf32>
  %v391 = tosa.sigmoid %v390 : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xf32>
  %mf1967 = tosa.mul %v390, %v391, %shift0 : (tensor<1x80x60x80xf32>, tensor<1x80x60x80xf32>, tensor<1xi8>) -> tensor<1x80x60x80xf32>
  %sp1968 = "tosa.const"() <{values = dense<3.934348055142793> : tensor<f32>}> : () -> tensor<f32>
  %shp1970 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1969 = tosa.reshape %sp1968, %shp1970 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1971 = tosa.mul %mf1967, %bb1969, %shift0 : (tensor<1x80x60x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x60x80xf32>
  %cl1972 = tosa.clamp %sm1971 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xf32>
  %v392 = tosa.cast %cl1972 : (tensor<1x80x60x80xf32>) -> tensor<1x80x60x80xi8>
  %tr1973 = tosa.transpose %v392 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x60x80xi8>) -> tensor<1x60x80x80xi8>
  %tr1974 = tosa.transpose %v142 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x1x1xi8>) -> tensor<80x1x1x80xi8>
  %izp1975 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1975 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1976 = tosa.conv2d %tr1973, %tr1974, %v143, %izp1975, %wzp1975 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x60x80x80xi8>, tensor<80x1x1x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x60x80x80xi32>
  %cs1977 = tosa.cast %cv1976 : (tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xf32>
  %sp1978 = "tosa.const"() <{values = dense<0.002527360246467554> : tensor<f32>}> : () -> tensor<f32>
  %shp1980 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1979 = tosa.reshape %sp1978, %shp1980 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1981 = tosa.mul %cs1977, %bb1979, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %sp1982 = "tosa.const"() <{values = dense<0.2118882907657173> : tensor<f32>}> : () -> tensor<f32>
  %shp1984 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1983 = tosa.reshape %sp1982, %shp1984 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1985 = tosa.mul %sm1981, %bb1983, %shift0 : (tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x60x80x80xf32>
  %v393 = tosa.transpose %sm1985 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x60x80x80xf32>) -> tensor<1x80x60x80xf32>
  %shp1987 = "tosa.const_shape"() <{values = dense<[1, 80, 4800]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v394 = tosa.reshape %v393, %shp1987 : (tensor<1x80x60x80xf32>, !tosa.shape<3>) -> tensor<1x80x4800xf32>
  %tr1988 = tosa.transpose %v341 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x128x30x40xi8>) -> tensor<1x30x40x128xi8>
  %tr1989 = tosa.transpose %v145 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x128x3x3xi8>) -> tensor<80x3x3x128xi8>
  %izp1990 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp1990 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv1991 = tosa.conv2d %tr1988, %tr1989, %v146, %izp1990, %wzp1990 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x128xi8>, tensor<80x3x3x128xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x80xi32>
  %cs1992 = tosa.cast %cv1991 : (tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xf32>
  %sp1993 = "tosa.const"() <{values = dense<0.007006041668825016> : tensor<f32>}> : () -> tensor<f32>
  %shp1995 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1994 = tosa.reshape %sp1993, %shp1995 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm1996 = tosa.mul %cs1992, %bb1994, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %sp1997 = "tosa.const"() <{values = dense<0.0004255163654065101> : tensor<f32>}> : () -> tensor<f32>
  %shp1999 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb1998 = tosa.reshape %sp1997, %shp1999 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2000 = tosa.mul %sm1996, %bb1998, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %v395 = tosa.transpose %sm2000 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x80xf32>) -> tensor<1x80x30x40xf32>
  %v396 = tosa.sigmoid %v395 : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xf32>
  %mf2002 = tosa.mul %v395, %v396, %shift0 : (tensor<1x80x30x40xf32>, tensor<1x80x30x40xf32>, tensor<1xi8>) -> tensor<1x80x30x40xf32>
  %sp2003 = "tosa.const"() <{values = dense<14.01955275267991> : tensor<f32>}> : () -> tensor<f32>
  %shp2005 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2004 = tosa.reshape %sp2003, %shp2005 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2006 = tosa.mul %mf2002, %bb2004, %shift0 : (tensor<1x80x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x30x40xf32>
  %cl2007 = tosa.clamp %sm2006 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xf32>
  %v397 = tosa.cast %cl2007 : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xi8>
  %tr2008 = tosa.transpose %v397 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x30x40xi8>) -> tensor<1x30x40x80xi8>
  %tr2009 = tosa.transpose %v147 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x3x3xi8>) -> tensor<80x3x3x80xi8>
  %izp2010 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2010 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv2011 = tosa.conv2d %tr2008, %tr2009, %v148, %izp2010, %wzp2010 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x30x40x80xi8>, tensor<80x3x3x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x80xi32>
  %cs2012 = tosa.cast %cv2011 : (tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xf32>
  %sp2013 = "tosa.const"() <{values = dense<0.006856658646442153> : tensor<f32>}> : () -> tensor<f32>
  %shp2015 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2014 = tosa.reshape %sp2013, %shp2015 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2016 = tosa.mul %cs2012, %bb2014, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %sp2017 = "tosa.const"() <{values = dense<0.004686189441348609> : tensor<f32>}> : () -> tensor<f32>
  %shp2019 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2018 = tosa.reshape %sp2017, %shp2019 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2020 = tosa.mul %sm2016, %bb2018, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %v398 = tosa.transpose %sm2020 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x80xf32>) -> tensor<1x80x30x40xf32>
  %v399 = tosa.sigmoid %v398 : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xf32>
  %mf2022 = tosa.mul %v398, %v399, %shift0 : (tensor<1x80x30x40xf32>, tensor<1x80x30x40xf32>, tensor<1xi8>) -> tensor<1x80x30x40xf32>
  %sp2023 = "tosa.const"() <{values = dense<1.680259803104648> : tensor<f32>}> : () -> tensor<f32>
  %shp2025 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2024 = tosa.reshape %sp2023, %shp2025 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2026 = tosa.mul %mf2022, %bb2024, %shift0 : (tensor<1x80x30x40xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x30x40xf32>
  %cl2027 = tosa.clamp %sm2026 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xf32>
  %v400 = tosa.cast %cl2027 : (tensor<1x80x30x40xf32>) -> tensor<1x80x30x40xi8>
  %tr2028 = tosa.transpose %v400 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x30x40xi8>) -> tensor<1x30x40x80xi8>
  %tr2029 = tosa.transpose %v149 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x1x1xi8>) -> tensor<80x1x1x80xi8>
  %izp2030 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2030 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv2031 = tosa.conv2d %tr2028, %tr2029, %v150, %izp2030, %wzp2030 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x30x40x80xi8>, tensor<80x1x1x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x30x40x80xi32>
  %cs2032 = tosa.cast %cv2031 : (tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xf32>
  %sp2033 = "tosa.const"() <{values = dense<0.004886138555223559> : tensor<f32>}> : () -> tensor<f32>
  %shp2035 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2034 = tosa.reshape %sp2033, %shp2035 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2036 = tosa.mul %cs2032, %bb2034, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %sp2037 = "tosa.const"() <{values = dense<0.3146975659948634> : tensor<f32>}> : () -> tensor<f32>
  %shp2039 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2038 = tosa.reshape %sp2037, %shp2039 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2040 = tosa.mul %sm2036, %bb2038, %shift0 : (tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x30x40x80xf32>
  %v401 = tosa.transpose %sm2040 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x30x40x80xf32>) -> tensor<1x80x30x40xf32>
  %shp2042 = "tosa.const_shape"() <{values = dense<[1, 80, 1200]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v402 = tosa.reshape %v401, %shp2042 : (tensor<1x80x30x40xf32>, !tosa.shape<3>) -> tensor<1x80x1200xf32>
  %tr2043 = tosa.transpose %v361 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x256x15x20xi8>) -> tensor<1x15x20x256xi8>
  %tr2044 = tosa.transpose %v152 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x256x3x3xi8>) -> tensor<80x3x3x256xi8>
  %izp2045 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2045 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv2046 = tosa.conv2d %tr2043, %tr2044, %v153, %izp2045, %wzp2045 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x256xi8>, tensor<80x3x3x256xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x80xi32>
  %cs2047 = tosa.cast %cv2046 : (tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xf32>
  %sp2048 = "tosa.const"() <{values = dense<0.007870811858317461> : tensor<f32>}> : () -> tensor<f32>
  %shp2050 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2049 = tosa.reshape %sp2048, %shp2050 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2051 = tosa.mul %cs2047, %bb2049, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %sp2052 = "tosa.const"() <{values = dense<0.0004578019572070028> : tensor<f32>}> : () -> tensor<f32>
  %shp2054 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2053 = tosa.reshape %sp2052, %shp2054 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2055 = tosa.mul %sm2051, %bb2053, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %v403 = tosa.transpose %sm2055 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x80xf32>) -> tensor<1x80x15x20xf32>
  %v404 = tosa.sigmoid %v403 : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xf32>
  %mf2057 = tosa.mul %v403, %v404, %shift0 : (tensor<1x80x15x20xf32>, tensor<1x80x15x20xf32>, tensor<1xi8>) -> tensor<1x80x15x20xf32>
  %sp2058 = "tosa.const"() <{values = dense<11.84111131631369> : tensor<f32>}> : () -> tensor<f32>
  %shp2060 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2059 = tosa.reshape %sp2058, %shp2060 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2061 = tosa.mul %mf2057, %bb2059, %shift0 : (tensor<1x80x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x15x20xf32>
  %cl2062 = tosa.clamp %sm2061 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xf32>
  %v405 = tosa.cast %cl2062 : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xi8>
  %tr2063 = tosa.transpose %v405 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x15x20xi8>) -> tensor<1x15x20x80xi8>
  %tr2064 = tosa.transpose %v154 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x3x3xi8>) -> tensor<80x3x3x80xi8>
  %izp2065 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2065 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv2066 = tosa.conv2d %tr2063, %tr2064, %v155, %izp2065, %wzp2065 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<1x15x20x80xi8>, tensor<80x3x3x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x80xi32>
  %cs2067 = tosa.cast %cv2066 : (tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xf32>
  %sp2068 = "tosa.const"() <{values = dense<0.006321925847924934> : tensor<f32>}> : () -> tensor<f32>
  %shp2070 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2069 = tosa.reshape %sp2068, %shp2070 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2071 = tosa.mul %cs2067, %bb2069, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %sp2072 = "tosa.const"() <{values = dense<0.003813947760036633> : tensor<f32>}> : () -> tensor<f32>
  %shp2074 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2073 = tosa.reshape %sp2072, %shp2074 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2075 = tosa.mul %sm2071, %bb2073, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %v406 = tosa.transpose %sm2075 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x80xf32>) -> tensor<1x80x15x20xf32>
  %v407 = tosa.sigmoid %v406 : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xf32>
  %mf2077 = tosa.mul %v406, %v407, %shift0 : (tensor<1x80x15x20xf32>, tensor<1x80x15x20xf32>, tensor<1xi8>) -> tensor<1x80x15x20xf32>
  %sp2078 = "tosa.const"() <{values = dense<2.064531620106896> : tensor<f32>}> : () -> tensor<f32>
  %shp2080 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2079 = tosa.reshape %sp2078, %shp2080 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2081 = tosa.mul %mf2077, %bb2079, %shift0 : (tensor<1x80x15x20xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x15x20xf32>
  %cl2082 = tosa.clamp %sm2081 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xf32>
  %v408 = tosa.cast %cl2082 : (tensor<1x80x15x20xf32>) -> tensor<1x80x15x20xi8>
  %tr2083 = tosa.transpose %v408 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x80x15x20xi8>) -> tensor<1x15x20x80xi8>
  %tr2084 = tosa.transpose %v156 {perms = array<i32: 0, 2, 3, 1>} : (tensor<80x80x1x1xi8>) -> tensor<80x1x1x80xi8>
  %izp2085 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2085 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %cv2086 = tosa.conv2d %tr2083, %tr2084, %v157, %izp2085, %wzp2085 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x15x20x80xi8>, tensor<80x1x1x80xi8>, tensor<80xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x15x20x80xi32>
  %cs2087 = tosa.cast %cv2086 : (tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xf32>
  %sp2088 = "tosa.const"() <{values = dense<0.004319373413858982> : tensor<f32>}> : () -> tensor<f32>
  %shp2090 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2089 = tosa.reshape %sp2088, %shp2090 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2091 = tosa.mul %cs2087, %bb2089, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %sp2092 = "tosa.const"() <{values = dense<0.4065703744963398> : tensor<f32>}> : () -> tensor<f32>
  %shp2094 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2093 = tosa.reshape %sp2092, %shp2094 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2095 = tosa.mul %sm2091, %bb2093, %shift0 : (tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x15x20x80xf32>
  %v409 = tosa.transpose %sm2095 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x15x20x80xf32>) -> tensor<1x80x15x20xf32>
  %shp2097 = "tosa.const_shape"() <{values = dense<[1, 80, 300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v410 = tosa.reshape %v409, %shp2097 : (tensor<1x80x15x20xf32>, !tosa.shape<3>) -> tensor<1x80x300xf32>
  %sp2098 = "tosa.const"() <{values = dense<0.5211601829774364> : tensor<f32>}> : () -> tensor<f32>
  %shp2100 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2099 = tosa.reshape %sp2098, %shp2100 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2101 = tosa.mul %v394, %bb2099, %shift0 : (tensor<1x80x4800xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x4800xf32>
  %sp2102 = "tosa.const"() <{values = dense<0.7740297516382284> : tensor<f32>}> : () -> tensor<f32>
  %shp2104 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2103 = tosa.reshape %sp2102, %shp2104 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2105 = tosa.mul %v402, %bb2103, %shift0 : (tensor<1x80x1200xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x1200xf32>
  %v411 = tosa.concat %sm2101, %sm2105, %v410 {axis = 2 : i32} : (tensor<1x80x4800xf32>, tensor<1x80x1200xf32>, tensor<1x80x300xf32>) -> tensor<1x80x6300xf32>
  %shp2106 = "tosa.const_shape"() <{values = dense<[1, 4, 16, 6300]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %v412 = tosa.reshape %v386, %shp2106 : (tensor<1x64x6300xf32>, !tosa.shape<4>) -> tensor<1x4x16x6300xf32>
  %v413 = tosa.transpose %v412 {perms = array<i32: 0, 2, 1, 3>} : (tensor<1x4x16x6300xf32>) -> tensor<1x16x4x6300xf32>
  %smexp2107 = tosa.exp %v413 : (tensor<1x16x4x6300xf32>) -> tensor<1x16x4x6300xf32>
  %smsum2107 = tosa.reduce_sum %smexp2107 {axis = 1 : i32} : (tensor<1x16x4x6300xf32>) -> tensor<1x1x4x6300xf32>
  %smrcp2107 = tosa.reciprocal %smsum2107 : (tensor<1x1x4x6300xf32>) -> tensor<1x1x4x6300xf32>
  %v414 = tosa.mul %smexp2107, %smrcp2107, %shift0 : (tensor<1x16x4x6300xf32>, tensor<1x1x4x6300xf32>, tensor<1xi8>) -> tensor<1x16x4x6300xf32>
  %tr2108 = tosa.transpose %v414 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x16x4x6300xf32>) -> tensor<1x4x6300x16xf32>
  %tr2109 = tosa.transpose %v160 {perms = array<i32: 0, 2, 3, 1>} : (tensor<1x16x1x1xf32>) -> tensor<1x1x1x16xf32>
  %sp2110 = "tosa.const"() <{values = dense<133.1723647833004> : tensor<f32>}> : () -> tensor<f32>
  %shp2112 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2111 = tosa.reshape %sp2110, %shp2112 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2113 = tosa.mul %tr2108, %bb2111, %shift0 : (tensor<1x4x6300x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x4x6300x16xf32>
  %cl2114 = tosa.clamp %sm2113 {min_val = -1.280000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x4x6300x16xf32>) -> tensor<1x4x6300x16xf32>
  %cs2115 = tosa.cast %cl2114 : (tensor<1x4x6300x16xf32>) -> tensor<1x4x6300x16xi8>
  %sp2116 = "tosa.const"() <{values = dense<0.1181102362204724> : tensor<f32>}> : () -> tensor<f32>
  %shp2118 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2117 = tosa.reshape %sp2116, %shp2118 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2119 = tosa.mul %tr2109, %bb2117, %shift0 : (tensor<1x1x1x16xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x1x1x16xf32>
  %cl2120 = tosa.clamp %sm2119 {min_val = -1.270000e+02 : f32, max_val = 1.270000e+02 : f32} : (tensor<1x1x1x16xf32>) -> tensor<1x1x1x16xf32>
  %cs2121 = tosa.cast %cl2120 : (tensor<1x1x1x16xf32>) -> tensor<1x1x1x16xi8>
  %izp2122 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %wzp2122 = "tosa.const"() <{values = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %bias2123 = "tosa.const"() <{values = dense<0> : tensor<1xi32>}> : () -> tensor<1xi32>
  %cv2124 = tosa.conv2d %cs2115, %cs2121, %bias2123, %izp2122, %wzp2122 {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x4x6300x16xi8>, tensor<1x1x1x16xi8>, tensor<1xi32>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x4x6300x1xi32>
  %cs2125 = tosa.cast %cv2124 : (tensor<1x4x6300x1xi32>) -> tensor<1x4x6300x1xf32>
  %sp2126 = "tosa.const"() <{values = dense<0.008597121069812672> : tensor<f32>}> : () -> tensor<f32>
  %shp2128 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2127 = tosa.reshape %sp2126, %shp2128 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2129 = tosa.mul %cs2125, %bb2127, %shift0 : (tensor<1x4x6300x1xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x4x6300x1xf32>
  %sp2130 = "tosa.const"() <{values = dense<0.1031621497447096> : tensor<f32>}> : () -> tensor<f32>
  %shp2132 = "tosa.const_shape"() <{values = dense<[1, 1, 1, 1]> : tensor<4xindex>}> : () -> !tosa.shape<4>
  %bb2131 = tosa.reshape %sp2130, %shp2132 : (tensor<f32>, !tosa.shape<4>) -> tensor<1x1x1x1xf32>
  %sm2133 = tosa.mul %sm2129, %bb2131, %shift0 : (tensor<1x4x6300x1xf32>, tensor<1x1x1x1xf32>, tensor<1xi8>) -> tensor<1x4x6300x1xf32>
  %v415 = tosa.transpose %sm2133 {perms = array<i32: 0, 3, 1, 2>} : (tensor<1x4x6300x1xf32>) -> tensor<1x1x4x6300xf32>
  %shp2135 = "tosa.const_shape"() <{values = dense<[1, 4, 6300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v416 = tosa.reshape %v415, %shp2135 : (tensor<1x1x4x6300xf32>, !tosa.shape<3>) -> tensor<1x4x6300xf32>
  %v417 = "tosa.const"() <{values = dense<0> : tensor<1xi64>}> : () -> tensor<1xi64>
  %v418 = "tosa.const"() <{values = dense<0> : tensor<1xi64>}> : () -> tensor<1xi64>
  %st2136 = "tosa.const_shape"() <{values = dense<[0, 0, 0]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %sz2136 = "tosa.const_shape"() <{values = dense<[1, 2, 6300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v419 = tosa.slice %v416, %st2136, %sz2136 : (tensor<1x4x6300xf32>, !tosa.shape<3>, !tosa.shape<3>) -> tensor<1x2x6300xf32>
  %st2137 = "tosa.const_shape"() <{values = dense<[0, 2, 0]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %sz2137 = "tosa.const_shape"() <{values = dense<[1, 2, 6300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %v420 = tosa.slice %v416, %st2137, %sz2137 : (tensor<1x4x6300xf32>, !tosa.shape<3>, !tosa.shape<3>) -> tensor<1x2x6300xf32>
  %v421 = tosa.sub %v162, %v419 : (tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) -> tensor<1x2x6300xf32>
  %v422 = tosa.add %v163, %v420 : (tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) -> tensor<1x2x6300xf32>
  %sp2138 = "tosa.const"() <{values = dense<0.4978136454740276> : tensor<f32>}> : () -> tensor<f32>
  %shp2140 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2139 = tosa.reshape %sp2138, %shp2140 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2141 = tosa.mul %v421, %bb2139, %shift0 : (tensor<1x2x6300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x2x6300xf32>
  %sp2142 = "tosa.const"() <{values = dense<0.5160021871211299> : tensor<f32>}> : () -> tensor<f32>
  %shp2144 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2143 = tosa.reshape %sp2142, %shp2144 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2145 = tosa.mul %v422, %bb2143, %shift0 : (tensor<1x2x6300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x2x6300xf32>
  %v423 = tosa.add %sm2141, %sm2145 : (tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) -> tensor<1x2x6300xf32>
  %shp2147 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2146 = tosa.reshape %v164, %shp2147 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %divr2148 = tosa.reciprocal %bb2146 : (tensor<1x1x1xf32>) -> tensor<1x1x1xf32>
  %v424 = tosa.mul %v423, %divr2148, %shift0 : (tensor<1x2x6300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x2x6300xf32>
  %v425 = tosa.sub %v422, %v421 : (tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) -> tensor<1x2x6300xf32>
  %sp2149 = "tosa.const"() <{values = dense<0.2935487353142635> : tensor<f32>}> : () -> tensor<f32>
  %shp2151 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2150 = tosa.reshape %sp2149, %shp2151 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2152 = tosa.mul %v425, %bb2150, %shift0 : (tensor<1x2x6300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x2x6300xf32>
  %v426 = tosa.concat %v424, %sm2152 {axis = 1 : i32} : (tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) -> tensor<1x4x6300xf32>
  %shp2154 = "tosa.const_shape"() <{values = dense<[1, 1, 6300]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2153 = tosa.reshape %v165, %shp2154 : (tensor<1x6300xf32>, !tosa.shape<3>) -> tensor<1x1x6300xf32>
  %v427 = tosa.mul %v426, %bb2153, %shift0 : (tensor<1x4x6300xf32>, tensor<1x1x6300xf32>, tensor<1xi8>) -> tensor<1x4x6300xf32>
  %v428 = tosa.sigmoid %v411 : (tensor<1x80x6300xf32>) -> tensor<1x80x6300xf32>
  %sp2155 = "tosa.const"() <{values = dense<0.001406114230992965> : tensor<f32>}> : () -> tensor<f32>
  %shp2157 = "tosa.const_shape"() <{values = dense<[1, 1, 1]> : tensor<3xindex>}> : () -> !tosa.shape<3>
  %bb2156 = tosa.reshape %sp2155, %shp2157 : (tensor<f32>, !tosa.shape<3>) -> tensor<1x1x1xf32>
  %sm2158 = tosa.mul %v428, %bb2156, %shift0 : (tensor<1x80x6300xf32>, tensor<1x1x1xf32>, tensor<1xi8>) -> tensor<1x80x6300xf32>
  %v429 = tosa.concat %v427, %sm2158 {axis = 1 : i32} : (tensor<1x4x6300xf32>, tensor<1x80x6300xf32>) -> tensor<1x84x6300xf32>
  return %v429 : tensor<1x84x6300xf32>
  }
}
