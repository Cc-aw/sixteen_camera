#map = affine_map<(d0, d1, d2, d3) -> (d3)>
#map1 = affine_map<(d0, d1, d2, d3) -> (d0, d1, d2, d3)>
#map2 = affine_map<(d0, d1, d2, d3) -> (d0, 0, 0, 0)>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1, d2)>
#map4 = affine_map<(d0, d1, d2) -> (d0, 0, 0)>
#map5 = affine_map<(d0, d1, d2, d3) -> (d0, 0, d2, d3)>
#map6 = affine_map<(d0, d1, d2, d3) -> (d0, d1, d2, 0)>
#map7 = affine_map<(d0, d1, d2, d3) -> (0)>
#map8 = affine_map<(d0, d1, d2, d3) -> (d0, 0, 0, d3)>
#map9 = affine_map<(d0, d1, d2) -> (d0, 0, d2)>
module {
  func.func @forward(%arg0: tensor<1x3x480x640xi8>, %arg1: tensor<16x3x6x6xi8>, %arg2: tensor<16xi32>, %arg3: tensor<32x16x3x3xi8>, %arg4: tensor<32xi32>, %arg5: tensor<16x32x1x1xi8>, %arg6: tensor<16xi32>, %arg7: tensor<16x16x1x1xi8>, %arg8: tensor<16xi32>, %arg9: tensor<16x16x3x3xi8>, %arg10: tensor<16xi32>, %arg11: tensor<16x32x1x1xi8>, %arg12: tensor<16xi32>, %arg13: tensor<32x32x1x1xi8>, %arg14: tensor<32xi32>, %arg15: tensor<64x32x3x3xi8>, %arg16: tensor<64xi32>, %arg17: tensor<32x64x1x1xi8>, %arg18: tensor<32xi32>, %arg19: tensor<32x32x1x1xi8>, %arg20: tensor<32xi32>, %arg21: tensor<32x32x3x3xi8>, %arg22: tensor<32xi32>, %arg23: tensor<32x32x1x1xi8>, %arg24: tensor<32xi32>, %arg25: tensor<32x32x3x3xi8>, %arg26: tensor<32xi32>, %arg27: tensor<32x64x1x1xi8>, %arg28: tensor<32xi32>, %arg29: tensor<64x64x1x1xi8>, %arg30: tensor<64xi32>, %arg31: tensor<128x64x3x3xi8>, %arg32: tensor<128xi32>, %arg33: tensor<64x128x1x1xi8>, %arg34: tensor<64xi32>, %arg35: tensor<64x64x1x1xi8>, %arg36: tensor<64xi32>, %arg37: tensor<64x64x3x3xi8>, %arg38: tensor<64xi32>, %arg39: tensor<64x64x1x1xi8>, %arg40: tensor<64xi32>, %arg41: tensor<64x64x3x3xi8>, %arg42: tensor<64xi32>, %arg43: tensor<64x64x1x1xi8>, %arg44: tensor<64xi32>, %arg45: tensor<64x64x3x3xi8>, %arg46: tensor<64xi32>, %arg47: tensor<64x128x1x1xi8>, %arg48: tensor<64xi32>, %arg49: tensor<128x128x1x1xi8>, %arg50: tensor<128xi32>, %arg51: tensor<256x128x3x3xi8>, %arg52: tensor<256xi32>, %arg53: tensor<128x256x1x1xi8>, %arg54: tensor<128xi32>, %arg55: tensor<128x128x1x1xi8>, %arg56: tensor<128xi32>, %arg57: tensor<128x128x3x3xi8>, %arg58: tensor<128xi32>, %arg59: tensor<128x256x1x1xi8>, %arg60: tensor<128xi32>, %arg61: tensor<256x256x1x1xi8>, %arg62: tensor<256xi32>, %arg63: tensor<128x256x1x1xi8>, %arg64: tensor<128xi32>, %arg65: tensor<256x512x1x1xi8>, %arg66: tensor<256xi32>, %arg67: tensor<128x256x1x1xi8>, %arg68: tensor<128xi32>, %arg69: tensor<4xf32>, %arg70: tensor<64x256x1x1xi8>, %arg71: tensor<64xi32>, %arg72: tensor<64x64x1x1xi8>, %arg73: tensor<64xi32>, %arg74: tensor<64x64x3x3xi8>, %arg75: tensor<64xi32>, %arg76: tensor<64x256x1x1xi8>, %arg77: tensor<64xi32>, %arg78: tensor<128x128x1x1xi8>, %arg79: tensor<128xi32>, %arg80: tensor<64x128x1x1xi8>, %arg81: tensor<64xi32>, %arg82: tensor<4xf32>, %arg83: tensor<32x128x1x1xi8>, %arg84: tensor<32xi32>, %arg85: tensor<32x32x1x1xi8>, %arg86: tensor<32xi32>, %arg87: tensor<32x32x3x3xi8>, %arg88: tensor<32xi32>, %arg89: tensor<32x128x1x1xi8>, %arg90: tensor<32xi32>, %arg91: tensor<64x64x1x1xi8>, %arg92: tensor<64xi32>, %arg93: tensor<64x64x3x3xi8>, %arg94: tensor<64xi32>, %arg95: tensor<64x128x1x1xi8>, %arg96: tensor<64xi32>, %arg97: tensor<64x64x1x1xi8>, %arg98: tensor<64xi32>, %arg99: tensor<64x64x3x3xi8>, %arg100: tensor<64xi32>, %arg101: tensor<64x128x1x1xi8>, %arg102: tensor<64xi32>, %arg103: tensor<128x128x1x1xi8>, %arg104: tensor<128xi32>, %arg105: tensor<128x128x3x3xi8>, %arg106: tensor<128xi32>, %arg107: tensor<128x256x1x1xi8>, %arg108: tensor<128xi32>, %arg109: tensor<128x128x1x1xi8>, %arg110: tensor<128xi32>, %arg111: tensor<128x128x3x3xi8>, %arg112: tensor<128xi32>, %arg113: tensor<128x256x1x1xi8>, %arg114: tensor<128xi32>, %arg115: tensor<256x256x1x1xi8>, %arg116: tensor<256xi32>, %arg117: tensor<64x64x3x3xi8>, %arg118: tensor<64xi32>, %arg119: tensor<64x64x3x3xi8>, %arg120: tensor<64xi32>, %arg121: tensor<64x64x1x1xi8>, %arg122: tensor<64xi32>, %arg123: tensor<3xi64>, %arg124: tensor<64x128x3x3xi8>, %arg125: tensor<64xi32>, %arg126: tensor<64x64x3x3xi8>, %arg127: tensor<64xi32>, %arg128: tensor<64x64x1x1xi8>, %arg129: tensor<64xi32>, %arg130: tensor<3xi64>, %arg131: tensor<64x256x3x3xi8>, %arg132: tensor<64xi32>, %arg133: tensor<64x64x3x3xi8>, %arg134: tensor<64xi32>, %arg135: tensor<64x64x1x1xi8>, %arg136: tensor<64xi32>, %arg137: tensor<3xi64>, %arg138: tensor<80x64x3x3xi8>, %arg139: tensor<80xi32>, %arg140: tensor<80x80x3x3xi8>, %arg141: tensor<80xi32>, %arg142: tensor<80x80x1x1xi8>, %arg143: tensor<80xi32>, %arg144: tensor<3xi64>, %arg145: tensor<80x128x3x3xi8>, %arg146: tensor<80xi32>, %arg147: tensor<80x80x3x3xi8>, %arg148: tensor<80xi32>, %arg149: tensor<80x80x1x1xi8>, %arg150: tensor<80xi32>, %arg151: tensor<3xi64>, %arg152: tensor<80x256x3x3xi8>, %arg153: tensor<80xi32>, %arg154: tensor<80x80x3x3xi8>, %arg155: tensor<80xi32>, %arg156: tensor<80x80x1x1xi8>, %arg157: tensor<80xi32>, %arg158: tensor<3xi64>, %arg159: tensor<4xi64>, %arg160: tensor<1x16x1x1xf32>, %arg161: tensor<3xi64>, %arg162: tensor<1x2x6300xf32>, %arg163: tensor<1x2x6300xf32>, %arg164: tensor<f32>, %arg165: tensor<1x6300xf32>) -> tensor<1x84x6300xf32> {
    %cst = arith.constant -1.270000e+02 : f32
    %cst_0 = arith.constant 0.000000e+00 : f32
    %c39_i32 = arith.constant 39 : i32
    %c29_i32 = arith.constant 29 : i32
    %c1_i32 = arith.constant 1 : i32
    %c2_i32 = arith.constant 2 : i32
    %c19_i32 = arith.constant 19 : i32
    %c14_i32 = arith.constant 14 : i32
    %c0_i32 = arith.constant 0 : i32
    %c0 = arith.constant 0 : index
    %cst_1 = arith.constant 1.270000e+02 : f32
    %cst_2 = arith.constant -1.280000e+02 : f32
    %cst_3 = arith.constant 1.000000e+00 : f32
    %c-128_i8 = arith.constant -128 : i8
    %c0_i8 = arith.constant 0 : i8
    %cst_4 = arith.constant dense<0.0014061142> : tensor<1x1x1xf32>
    %cst_5 = arith.constant dense<0.293548733> : tensor<1x1x1xf32>
    %cst_6 = arith.constant dense<0.516002178> : tensor<1x1x1xf32>
    %cst_7 = arith.constant dense<0.497813642> : tensor<1x1x1xf32>
    %cst_8 = arith.constant dense<0.103162147> : tensor<1x1x1x1xf32>
    %cst_9 = arith.constant dense<0.00859712064> : tensor<1x1x1x1xf32>
    %cst_10 = arith.constant dense<0.11811024> : tensor<1x1x1x1xf32>
    %cst_11 = arith.constant dense<133.172363> : tensor<1x1x1x1xf32>
    %cst_12 = arith.constant dense<0.774029731> : tensor<1x1x1xf32>
    %cst_13 = arith.constant dense<0.521160185> : tensor<1x1x1xf32>
    %cst_14 = arith.constant dense<0.406570375> : tensor<1x1x1x1xf32>
    %cst_15 = arith.constant dense<0.00431937352> : tensor<1x1x1x1xf32>
    %cst_16 = arith.constant dense<2.06453156> : tensor<1x1x1x1xf32>
    %cst_17 = arith.constant dense<0.00381394778> : tensor<1x1x1x1xf32>
    %cst_18 = arith.constant dense<0.00632192567> : tensor<1x1x1x1xf32>
    %cst_19 = arith.constant dense<11.8411112> : tensor<1x1x1x1xf32>
    %cst_20 = arith.constant dense<4.57801943E-4> : tensor<1x1x1x1xf32>
    %cst_21 = arith.constant dense<0.00787081196> : tensor<1x1x1x1xf32>
    %cst_22 = arith.constant dense<0.314697564> : tensor<1x1x1x1xf32>
    %cst_23 = arith.constant dense<0.00488613872> : tensor<1x1x1x1xf32>
    %cst_24 = arith.constant dense<1.68025982> : tensor<1x1x1x1xf32>
    %cst_25 = arith.constant dense<0.00468618935> : tensor<1x1x1x1xf32>
    %cst_26 = arith.constant dense<0.0068566585> : tensor<1x1x1x1xf32>
    %cst_27 = arith.constant dense<14.0195532> : tensor<1x1x1x1xf32>
    %cst_28 = arith.constant dense<4.25516366E-4> : tensor<1x1x1x1xf32>
    %cst_29 = arith.constant dense<0.00700604171> : tensor<1x1x1x1xf32>
    %cst_30 = arith.constant dense<0.211888283> : tensor<1x1x1x1xf32>
    %cst_31 = arith.constant dense<0.00252736034> : tensor<1x1x1x1xf32>
    %cst_32 = arith.constant dense<3.93434811> : tensor<1x1x1x1xf32>
    %cst_33 = arith.constant dense<0.00200135214> : tensor<1x1x1x1xf32>
    %cst_34 = arith.constant dense<0.00637654448> : tensor<1x1x1x1xf32>
    %cst_35 = arith.constant dense<15.0777407> : tensor<1x1x1x1xf32>
    %cst_36 = arith.constant dense<3.36615805E-4> : tensor<1x1x1x1xf32>
    %cst_37 = arith.constant dense<0.0071694795> : tensor<1x1x1x1xf32>
    %cst_38 = arith.constant dense<7.661290e-01> : tensor<1x1x1xf32>
    %cst_39 = arith.constant dense<0.702382326> : tensor<1x1x1xf32>
    %cst_40 = arith.constant dense<0.104074538> : tensor<1x1x1x1xf32>
    %cst_41 = arith.constant dense<0.00600688718> : tensor<1x1x1x1xf32>
    %cst_42 = arith.constant dense<4.8984437> : tensor<1x1x1x1xf32>
    %cst_43 = arith.constant dense<0.00160745252> : tensor<1x1x1x1xf32>
    %cst_44 = arith.constant dense<0.00592346117> : tensor<1x1x1x1xf32>
    %cst_45 = arith.constant dense<8.32852458> : tensor<1x1x1x1xf32>
    %cst_46 = arith.constant dense<5.28013043E-4> : tensor<1x1x1x1xf32>
    %cst_47 = arith.constant dense<8.036410e-03> : tensor<1x1x1x1xf32>
    %cst_48 = arith.constant dense<0.0954148918> : tensor<1x1x1x1xf32>
    %cst_49 = arith.constant dense<0.00581856817> : tensor<1x1x1x1xf32>
    %cst_50 = arith.constant dense<5.57480812> : tensor<1x1x1x1xf32>
    %cst_51 = arith.constant dense<0.0014124281> : tensor<1x1x1x1xf32>
    %cst_52 = arith.constant dense<7.832830e-03> : tensor<1x1x1x1xf32>
    %cst_53 = arith.constant dense<11.7519951> : tensor<1x1x1x1xf32>
    %cst_54 = arith.constant dense<3.95502779E-4> : tensor<1x1x1x1xf32>
    %cst_55 = arith.constant dense<0.0153491423> : tensor<1x1x1x1xf32>
    %cst_56 = arith.constant dense<0.135844663> : tensor<1x1x1x1xf32>
    %cst_57 = arith.constant dense<0.005432026> : tensor<1x1x1x1xf32>
    %cst_58 = arith.constant dense<3.69670081> : tensor<1x1x1x1xf32>
    %cst_59 = arith.constant dense<0.00213001156> : tensor<1x1x1x1xf32>
    %cst_60 = arith.constant dense<0.00611394271> : tensor<1x1x1x1xf32>
    %cst_61 = arith.constant dense<12.3325214> : tensor<1x1x1x1xf32>
    %cst_62 = arith.constant dense<2.97596853E-4> : tensor<1x1x1x1xf32>
    %cst_63 = arith.constant dense<0.00989972334> : tensor<1x1x1x1xf32>
    %cst_64 = arith.constant dense<7.38426685> : tensor<1x1x1x1xf32>
    %cst_65 = arith.constant dense<4.73392225E-4> : tensor<1x1x1x1xf32>
    %cst_66 = arith.constant dense<0.0181710888> : tensor<1x1x1x1xf32>
    %cst_67 = arith.constant dense<60708> : tensor<1x1x1x1xi32>
    %cst_68 = arith.constant dense<74179> : tensor<1x1x1x1xi32>
    %cst_69 = arith.constant dense<15.6661739> : tensor<1x1x1x1xf32>
    %cst_70 = arith.constant dense<0.00609090552> : tensor<1x1x1x1xf32>
    %cst_71 = arith.constant dense<12.8210926> : tensor<1x1x1x1xf32>
    %cst_72 = arith.constant dense<5.42587542E-4> : tensor<1x1x1x1xf32>
    %cst_73 = arith.constant dense<0.00472895242> : tensor<1x1x1x1xf32>
    %cst_74 = arith.constant dense<12.1606197> : tensor<1x1x1x1xf32>
    %cst_75 = arith.constant dense<5.583310e-04> : tensor<1x1x1x1xf32>
    %cst_76 = arith.constant dense<0.00973275303> : tensor<1x1x1x1xf32>
    %cst_77 = arith.constant dense<10.667697> : tensor<1x1x1x1xf32>
    %cst_78 = arith.constant dense<5.61099325E-4> : tensor<1x1x1x1xf32>
    %cst_79 = arith.constant dense<0.0125225503> : tensor<1x1x1x1xf32>
    %cst_80 = arith.constant dense<65551> : tensor<1x1x1x1xi32>
    %cst_81 = arith.constant dense<89816> : tensor<1x1x1x1xi32>
    %cst_82 = arith.constant dense<11.0415249> : tensor<1x1x1x1xf32>
    %cst_83 = arith.constant dense<0.0048789829> : tensor<1x1x1x1xf32>
    %cst_84 = arith.constant dense<12.0136404> : tensor<1x1x1x1xf32>
    %cst_85 = arith.constant dense<4.42717166E-4> : tensor<1x1x1x1xf32>
    %cst_86 = arith.constant dense<0.0108789504> : tensor<1x1x1x1xf32>
    %cst_87 = arith.constant dense<49065> : tensor<1x1x1x1xi32>
    %cst_88 = arith.constant dense<72605> : tensor<1x1x1x1xi32>
    %cst_89 = arith.constant dense<25.1426163> : tensor<1x1x1x1xf32>
    %cst_90 = arith.constant dense<0.00879147648> : tensor<1x1x1x1xf32>
    %cst_91 = arith.constant dense<16.9908028> : tensor<1x1x1x1xf32>
    %cst_92 = arith.constant dense<4.18305572E-4> : tensor<1x1x1x1xf32>
    %cst_93 = arith.constant dense<0.0050264271> : tensor<1x1x1x1xf32>
    %cst_94 = arith.constant dense<18.4147568> : tensor<1x1x1x1xf32>
    %cst_95 = arith.constant dense<3.446150e-04> : tensor<1x1x1x1xf32>
    %cst_96 = arith.constant dense<0.0079792682> : tensor<1x1x1x1xf32>
    %cst_97 = arith.constant dense<16.8264713> : tensor<1x1x1x1xf32>
    %cst_98 = arith.constant dense<4.09246713E-4> : tensor<1x1x1x1xf32>
    %cst_99 = arith.constant dense<0.00869756192> : tensor<1x1x1x1xf32>
    %cst_100 = arith.constant dense<53138> : tensor<1x1x1x1xi32>
    %cst_101 = arith.constant dense<71088> : tensor<1x1x1x1xi32>
    %cst_102 = arith.constant dense<18.74473> : tensor<1x1x1x1xf32>
    %cst_103 = arith.constant dense<3.87256674E-4> : tensor<1x1x1x1xf32>
    %cst_104 = arith.constant dense<0.00338776759> : tensor<1x1x1x1xf32>
    %cst_105 = arith.constant dense<17.89324> : tensor<1x1x1x1xf32>
    %cst_106 = arith.constant dense<2.29190773E-4> : tensor<1x1x1x1xf32>
    %cst_107 = arith.constant dense<0.0133869769> : tensor<1x1x1x1xf32>
    %cst_108 = arith.constant dense<55932> : tensor<1x1x1x1xi32>
    %cst_109 = arith.constant dense<93014> : tensor<1x1x1x1xi32>
    %cst_110 = arith.constant dense<37.4880905> : tensor<1x1x1x1xf32>
    %cst_111 = arith.constant dense<0.00953922048> : tensor<1x1x1x1xf32>
    %cst_112 = arith.constant dense<22.5425873> : tensor<1x1x1x1xf32>
    %cst_113 = arith.constant dense<2.46106938E-4> : tensor<1x1x1x1xf32>
    %cst_114 = arith.constant dense<0.007817436> : tensor<1x1x1x1xf32>
    %cst_115 = arith.constant dense<21.9819336> : tensor<1x1x1x1xf32>
    %cst_116 = arith.constant dense<2.885320e-04> : tensor<1x1x1x1xf32>
    %cst_117 = arith.constant dense<0.0178376455> : tensor<1x1x1x1xf32>
    %cst_118 = arith.constant dense<20.5571404> : tensor<1x1x1x1xf32>
    %cst_119 = arith.constant dense<2.409260e-04> : tensor<1x1x1x1xf32>
    %cst_120 = arith.constant dense<8.340900e-03> : tensor<1x1x1x1xf32>
    %cst_121 = arith.constant dense<65560> : tensor<1x1x1x1xi32>
    %cst_122 = arith.constant dense<40025> : tensor<1x1x1x1xi32>
    %cst_123 = arith.constant dense<25.0770168> : tensor<1x1x1x1xf32>
    %cst_124 = arith.constant dense<2.9983971E-4> : tensor<1x1x1x1xf32>
    %cst_125 = arith.constant dense<5.732980e-03> : tensor<1x1x1x1xf32>
    %cst_126 = arith.constant dense<15.4127302> : tensor<1x1x1x1xf32>
    %cst_127 = arith.constant dense<3.79452569E-4> : tensor<1x1x1x1xf32>
    %cst_128 = arith.constant dense<9.169820e-03> : tensor<1x1x1x1xf32>
    %cst_129 = arith.constant dense<103254> : tensor<1x1x1x1xi32>
    %cst_130 = arith.constant dense<65829> : tensor<1x1x1x1xi32>
    %cst_131 = arith.constant dense<14.9673128> : tensor<1x1x1x1xf32>
    %cst_132 = arith.constant dense<0.0107464846> : tensor<1x1x1x1xf32>
    %cst_133 = arith.constant dense<23.4764938> : tensor<1x1x1x1xf32>
    %cst_134 = arith.constant dense<3.33906384E-4> : tensor<1x1x1x1xf32>
    %cst_135 = arith.constant dense<0.00396349095> : tensor<1x1x1x1xf32>
    %cst_136 = arith.constant dense<20.3466301> : tensor<1x1x1x1xf32>
    %cst_137 = arith.constant dense<3.3741878E-4> : tensor<1x1x1x1xf32>
    %cst_138 = arith.constant dense<0.00802434888> : tensor<1x1x1x1xf32>
    %cst_139 = arith.constant dense<19.0208664> : tensor<1x1x1x1xf32>
    %cst_140 = arith.constant dense<2.77157931E-4> : tensor<1x1x1x1xf32>
    %cst_141 = arith.constant dense<0.0254192129> : tensor<1x1x1x1xf32>
    %cst_142 = arith.constant dense<65537> : tensor<1x1x1x1xi32>
    %cst_143 = arith.constant dense<47231> : tensor<1x1x1x1xi32>
    %cst_144 = arith.constant dense<15.1288424> : tensor<1x1x1x1xf32>
    %cst_145 = arith.constant dense<5.20346279E-4> : tensor<1x1x1x1xf32>
    %cst_146 = arith.constant dense<0.00958314538> : tensor<1x1x1x1xf32>
    %cst_147 = arith.constant dense<18.3486519> : tensor<1x1x1x1xf32>
    %cst_148 = arith.constant dense<3.88529152E-4> : tensor<1x1x1x1xf32>
    %cst_149 = arith.constant dense<8.516760e-03> : tensor<1x1x1x1xf32>
    %cst_150 = arith.constant dense<17.678215> : tensor<1x1x1x1xf32>
    %cst_151 = arith.constant dense<4.45070211E-4> : tensor<1x1x1x1xf32>
    %cst_152 = arith.constant dense<0.00621239562> : tensor<1x1x1x1xf32>
    %cst_153 = arith.constant dense<11.3165159> : tensor<1x1x1x1xf32>
    %cst_154 = arith.constant dense<5.51108562E-4> : tensor<1x1x1x1xf32>
    %cst_155 = arith.constant dense<0.0109014092> : tensor<1x1x1x1xf32>
    %cst_156 = arith.constant dense<46806> : tensor<1x1x1x1xi32>
    %cst_157 = arith.constant dense<13.2879763> : tensor<1x1x1x1xf32>
    %cst_158 = arith.constant dense<0.0122155221> : tensor<1x1x1x1xf32>
    %cst_159 = arith.constant dense<66627> : tensor<1x1x1x1xi32>
    %cst_160 = arith.constant dense<30531> : tensor<1x1x1x1xi32>
    %cst_161 = arith.constant dense<9.3348627> : tensor<1x1x1x1xf32>
    %cst_162 = arith.constant dense<8.29692464E-4> : tensor<1x1x1x1xf32>
    %cst_163 = arith.constant dense<0.003725769> : tensor<1x1x1x1xf32>
    %cst_164 = arith.constant dense<9.418950e+00> : tensor<1x1x1x1xf32>
    %cst_165 = arith.constant dense<8.35974759E-4> : tensor<1x1x1x1xf32>
    %cst_166 = arith.constant dense<0.0129372664> : tensor<1x1x1x1xf32>
    %cst_167 = arith.constant dense<20.3715038> : tensor<1x1x1x1xf32>
    %cst_168 = arith.constant dense<3.85764521E-4> : tensor<1x1x1x1xf32>
    %cst_169 = arith.constant dense<0.00715792737> : tensor<1x1x1x1xf32>
    %cst_170 = arith.constant dense<11.3715963> : tensor<1x1x1x1xf32>
    %cst_171 = arith.constant dense<6.92418544E-4> : tensor<1x1x1x1xf32>
    %cst_172 = arith.constant dense<0.00459722057> : tensor<1x1x1x1xf32>
    %cst_173 = arith.constant dense<10.905489> : tensor<1x1x1x1xf32>
    %cst_174 = arith.constant dense<7.22016848E-4> : tensor<1x1x1x1xf32>
    %cst_175 = arith.constant dense<0.00620856694> : tensor<1x1x1x1xf32>
    %cst_176 = arith.constant dense<45579> : tensor<1x1x1x1xi32>
    %cst_177 = arith.constant dense<9.28887557> : tensor<1x1x1x1xf32>
    %cst_178 = arith.constant dense<0.00847221724> : tensor<1x1x1x1xf32>
    %cst_179 = arith.constant dense<101333> : tensor<1x1x1x1xi32>
    %cst_180 = arith.constant dense<50910> : tensor<1x1x1x1xi32>
    %cst_181 = arith.constant dense<8.63794327> : tensor<1x1x1x1xf32>
    %cst_182 = arith.constant dense<8.47681367E-4> : tensor<1x1x1x1xf32>
    %cst_183 = arith.constant dense<0.00430227118> : tensor<1x1x1x1xf32>
    %cst_184 = arith.constant dense<19.6601658> : tensor<1x1x1x1xf32>
    %cst_185 = arith.constant dense<3.37153353E-4> : tensor<1x1x1x1xf32>
    %cst_186 = arith.constant dense<0.0123461829> : tensor<1x1x1x1xf32>
    %cst_187 = arith.constant dense<66229> : tensor<1x1x1x1xi32>
    %cst_188 = arith.constant dense<25999> : tensor<1x1x1x1xi32>
    %cst_189 = arith.constant dense<17.0134296> : tensor<1x1x1x1xf32>
    %cst_190 = arith.constant dense<4.579670e-04> : tensor<1x1x1x1xf32>
    %cst_191 = arith.constant dense<0.00729554053> : tensor<1x1x1x1xf32>
    %cst_192 = arith.constant dense<20.2499313> : tensor<1x1x1x1xf32>
    %cst_193 = arith.constant dense<3.88108398E-4> : tensor<1x1x1x1xf32>
    %cst_194 = arith.constant dense<0.00671094796> : tensor<1x1x1x1xf32>
    %cst_195 = arith.constant dense<101262> : tensor<1x1x1x1xi32>
    %cst_196 = arith.constant dense<110335> : tensor<1x1x1x1xi32>
    %cst_197 = arith.constant dense<2.804900e+01> : tensor<1x1x1x1xf32>
    %cst_198 = arith.constant dense<1.8168152E-4> : tensor<1x1x1x1xf32>
    %cst_199 = arith.constant dense<0.00607879459> : tensor<1x1x1x1xf32>
    %cst_200 = arith.constant dense<18.4688377> : tensor<1x1x1x1xf32>
    %cst_201 = arith.constant dense<3.475954E-4> : tensor<1x1x1x1xf32>
    %cst_202 = arith.constant dense<0.0145288706> : tensor<1x1x1x1xf32>
    %cst_203 = arith.constant dense<25.7426586> : tensor<1x1x1x1xf32>
    %cst_204 = arith.constant dense<9.96137532E-5> : tensor<1x1x1x1xf32>
    %cst_205 = arith.constant dense<0.0189360213> : tensor<1x1x1x1xf32>
    %cst_206 = arith.constant dense<9.813340e+00> : tensor<1x1x1x1xf32>
    %cst_207 = arith.constant dense<3.95768555E-4> : tensor<1x1x1x1xf32>
    %cst_208 = arith.constant dense<0.0122586582> : tensor<1x1x1x1xf32>
    %cst_209 = arith.constant dense<16.0323334> : tensor<1x1x1x1xf32>
    %cst_210 = arith.constant dense<4.9095531E-4> : tensor<1x1x1x1xf32>
    %cst_211 = arith.constant dense<0.0150127029> : tensor<1x1x1x1xf32>
    %cst_212 = arith.constant dense<73339> : tensor<1x1x1x1xi32>
    %cst_213 = arith.constant dense<53949> : tensor<1x1x1x1xi32>
    %cst_214 = arith.constant dense<9.20053672> : tensor<1x1x1x1xf32>
    %cst_215 = arith.constant dense<0.0120223034> : tensor<1x1x1x1xf32>
    %cst_216 = arith.constant dense<78613> : tensor<1x1x1x1xi32>
    %cst_217 = arith.constant dense<39320> : tensor<1x1x1x1xi32>
    %cst_218 = arith.constant dense<10.4267635> : tensor<1x1x1x1xf32>
    %cst_219 = arith.constant dense<7.64760188E-4> : tensor<1x1x1x1xf32>
    %cst_220 = arith.constant dense<0.00380956917> : tensor<1x1x1x1xf32>
    %cst_221 = arith.constant dense<16.2107983> : tensor<1x1x1x1xf32>
    %cst_222 = arith.constant dense<3.14696459E-4> : tensor<1x1x1x1xf32>
    %cst_223 = arith.constant dense<0.0162679348> : tensor<1x1x1x1xf32>
    %cst_224 = arith.constant dense<61609> : tensor<1x1x1x1xi32>
    %cst_225 = arith.constant dense<86932> : tensor<1x1x1x1xi32>
    %cst_226 = arith.constant dense<22.1751671> : tensor<1x1x1x1xf32>
    %cst_227 = arith.constant dense<3.77716817E-4> : tensor<1x1x1x1xf32>
    %cst_228 = arith.constant dense<0.00458907802> : tensor<1x1x1x1xf32>
    %cst_229 = arith.constant dense<18.5029144> : tensor<1x1x1x1xf32>
    %cst_230 = arith.constant dense<2.73298618E-4> : tensor<1x1x1x1xf32>
    %cst_231 = arith.constant dense<1.479830e-02> : tensor<1x1x1x1xf32>
    %cst_232 = arith.constant dense<15.7156057> : tensor<1x1x1x1xf32>
    %cst_233 = arith.constant dense<1.90971798E-4> : tensor<1x1x1x1xf32>
    %cst_234 = arith.constant dense<0.0151615953> : tensor<1x1x1x1xf32>
    %cst_235 = arith.constant dense<11.8159323> : tensor<1x1x1x1xf32>
    %cst_236 = arith.constant dense<5.31277445E-4> : tensor<1x1x1x1xf32>
    %cst_237 = arith.constant dense<0.00754241226> : tensor<1x1x1x1xf32>
    %cst_238 = arith.constant dense<6.4917078> : tensor<1x1x1x1xf32>
    %cst_239 = arith.constant dense<0.00107590214> : tensor<1x1x1x1xf32>
    %cst_240 = arith.constant dense<8.487220e-03> : tensor<1x1x1x1xf32>
    %cst_241 = arith.constant dense<152175> : tensor<1x1x1x1xi32>
    %cst_242 = arith.constant dense<58432> : tensor<1x1x1x1xi32>
    %cst_243 = arith.constant dense<2.33338523> : tensor<1x1x1x1xf32>
    %cst_244 = arith.constant dense<0.0373886824> : tensor<1x1x1x1xf32>
    %cst_245 = arith.constant dense<127> : tensor<1x1x1x1xi32>
    %cst_246 = arith.constant dense<-128> : tensor<1x1x1x1xi32>
    %cst_247 = arith.constant dense<86024> : tensor<1x1x1x1xi32>
    %cst_248 = arith.constant dense<16> : tensor<1x1x1x1xi32>
    %cst_249 = arith.constant dense<119876> : tensor<1x1x1x1xi32>
    %cst_250 = arith.constant dense<4.62957716> : tensor<1x1x1x1xf32>
    %cst_251 = arith.constant dense<0.00145326788> : tensor<1x1x1x1xf32>
    %cst_252 = arith.constant dense<0.0068890308> : tensor<1x1x1x1xf32>
    %cst_253 = arith.constant dense<6.16502953> : tensor<1x1x1x1xf32>
    %cst_254 = arith.constant dense<8.82133085E-4> : tensor<1x1x1x1xf32>
    %cst_255 = arith.constant dense<0.0180469286> : tensor<1x1x1x1xf32>
    %cst_256 = arith.constant dense<3.32224584> : tensor<1x1x1x1xf32>
    %cst_257 = arith.constant dense<4.50051331E-4> : tensor<1x1x1x1xf32>
    %cst_258 = arith.constant dense<0.0475858524> : tensor<1x1x1x1xf32>
    %cst_259 = arith.constant dense<1.14747286> : tensor<1x1x1x1xf32>
    %cst_260 = arith.constant dense<0.00686204992> : tensor<1x1x1x1xf32>
    %cst_261 = arith.constant dense<5.703000e-03> : tensor<1x1x1x1xf32>
    %cst_262 = arith.constant dense<5.2070775> : tensor<1x1x1x1xf32>
    %cst_263 = arith.constant dense<0.00151217566> : tensor<1x1x1x1xf32>
    %cst_264 = arith.constant dense<0.00288073183> : tensor<1x1x1x1xf32>
    %cst_265 = arith.constant dense<0> : tensor<1xi32>
    %0 = tensor.empty() : tensor<1x480x640x3xi8>
    %transposed = linalg.transpose ins(%arg0 : tensor<1x3x480x640xi8>) outs(%0 : tensor<1x480x640x3xi8>) permutation = [0, 2, 3, 1] 
    %1 = tensor.empty() : tensor<16x6x6x3xi8>
    %transposed_266 = linalg.transpose ins(%arg1 : tensor<16x3x6x6xi8>) outs(%1 : tensor<16x6x6x3xi8>) permutation = [0, 2, 3, 1] 
    %padded = tensor.pad %transposed low[0, 2, 2, 0] high[0, 2, 2, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x480x640x3xi8> to tensor<1x484x644x3xi8>
    %2 = tensor.empty() : tensor<1x240x320x16xi32>
    %3 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg2 : tensor<16xi32>) outs(%2 : tensor<1x240x320x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x240x320x16xi32>
    %4 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded, %transposed_266 : tensor<1x484x644x3xi8>, tensor<16x6x6x3xi8>) outs(%3 : tensor<1x240x320x16xi32>) -> tensor<1x240x320x16xi32>
    %5 = tensor.empty() : tensor<1x240x320x16xf32>
    %6 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%4 : tensor<1x240x320x16xi32>) outs(%5 : tensor<1x240x320x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x240x320x16xf32>
    %7 = tensor.empty() : tensor<1x240x320x16xf32>
    %8 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%6, %cst_264 : tensor<1x240x320x16xf32>, tensor<1x1x1x1xf32>) outs(%7 : tensor<1x240x320x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x240x320x16xf32>
    %9 = tensor.empty() : tensor<1x240x320x16xf32>
    %10 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%8, %cst_263 : tensor<1x240x320x16xf32>, tensor<1x1x1x1xf32>) outs(%9 : tensor<1x240x320x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x240x320x16xf32>
    %11 = tensor.empty() : tensor<1x16x240x320xf32>
    %transposed_267 = linalg.transpose ins(%10 : tensor<1x240x320x16xf32>) outs(%11 : tensor<1x16x240x320xf32>) permutation = [0, 3, 1, 2] 
    %12 = tensor.empty() : tensor<1x16x240x320xf32>
    %13 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_267 : tensor<1x16x240x320xf32>) outs(%12 : tensor<1x16x240x320xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x16x240x320xf32>
    %14 = tensor.empty() : tensor<1x16x240x320xf32>
    %15 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_267, %13 : tensor<1x16x240x320xf32>, tensor<1x16x240x320xf32>) outs(%14 : tensor<1x16x240x320xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x240x320xf32>
    %16 = tensor.empty() : tensor<1x16x240x320xf32>
    %17 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%15, %cst_262 : tensor<1x16x240x320xf32>, tensor<1x1x1x1xf32>) outs(%16 : tensor<1x16x240x320xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x240x320xf32>
    %18 = tensor.empty() : tensor<1x16x240x320xf32>
    %19 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%17 : tensor<1x16x240x320xf32>) outs(%18 : tensor<1x16x240x320xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x16x240x320xf32>
    %20 = tensor.empty() : tensor<1x16x240x320xi8>
    %21 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%19 : tensor<1x16x240x320xf32>) outs(%20 : tensor<1x16x240x320xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x16x240x320xi8>
    %22 = tensor.empty() : tensor<1x240x320x16xi8>
    %transposed_268 = linalg.transpose ins(%21 : tensor<1x16x240x320xi8>) outs(%22 : tensor<1x240x320x16xi8>) permutation = [0, 2, 3, 1] 
    %23 = tensor.empty() : tensor<32x3x3x16xi8>
    %transposed_269 = linalg.transpose ins(%arg3 : tensor<32x16x3x3xi8>) outs(%23 : tensor<32x3x3x16xi8>) permutation = [0, 2, 3, 1] 
    %padded_270 = tensor.pad %transposed_268 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x240x320x16xi8> to tensor<1x241x321x16xi8>
    %24 = tensor.empty() : tensor<1x120x160x32xi32>
    %25 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg4 : tensor<32xi32>) outs(%24 : tensor<1x120x160x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x32xi32>
    %26 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_270, %transposed_269 : tensor<1x241x321x16xi8>, tensor<32x3x3x16xi8>) outs(%25 : tensor<1x120x160x32xi32>) -> tensor<1x120x160x32xi32>
    %27 = tensor.empty() : tensor<1x120x160x32xf32>
    %28 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%26 : tensor<1x120x160x32xi32>) outs(%27 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %29 = tensor.empty() : tensor<1x120x160x32xf32>
    %30 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%28, %cst_261 : tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>) outs(%29 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %31 = tensor.empty() : tensor<1x120x160x32xf32>
    %32 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%30, %cst_260 : tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>) outs(%31 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %33 = tensor.empty() : tensor<1x32x120x160xf32>
    %transposed_271 = linalg.transpose ins(%32 : tensor<1x120x160x32xf32>) outs(%33 : tensor<1x32x120x160xf32>) permutation = [0, 3, 1, 2] 
    %34 = tensor.empty() : tensor<1x32x120x160xf32>
    %35 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_271 : tensor<1x32x120x160xf32>) outs(%34 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x120x160xf32>
    %36 = tensor.empty() : tensor<1x32x120x160xf32>
    %37 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_271, %35 : tensor<1x32x120x160xf32>, tensor<1x32x120x160xf32>) outs(%36 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x120x160xf32>
    %38 = tensor.empty() : tensor<1x32x120x160xf32>
    %39 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%37, %cst_259 : tensor<1x32x120x160xf32>, tensor<1x1x1x1xf32>) outs(%38 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x120x160xf32>
    %40 = tensor.empty() : tensor<1x32x120x160xf32>
    %41 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%39 : tensor<1x32x120x160xf32>) outs(%40 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x120x160xf32>
    %42 = tensor.empty() : tensor<1x32x120x160xi8>
    %43 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%41 : tensor<1x32x120x160xf32>) outs(%42 : tensor<1x32x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x120x160xi8>
    %44 = tensor.empty() : tensor<1x120x160x32xi8>
    %transposed_272 = linalg.transpose ins(%43 : tensor<1x32x120x160xi8>) outs(%44 : tensor<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed = tensor.collapse_shape %arg5 [[0], [1, 2, 3]] : tensor<16x32x1x1xi8> into tensor<16x32xi8>
    %expanded = tensor.expand_shape %collapsed [[0, 1, 2], [3]] output_shape [16, 1, 1, 32] : tensor<16x32xi8> into tensor<16x1x1x32xi8>
    %45 = tensor.empty() : tensor<1x120x160x16xi32>
    %46 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg6 : tensor<16xi32>) outs(%45 : tensor<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x16xi32>
    %47 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_272, %expanded : tensor<1x120x160x32xi8>, tensor<16x1x1x32xi8>) outs(%46 : tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xi32>
    %48 = tensor.empty() : tensor<1x120x160x16xf32>
    %49 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%47 : tensor<1x120x160x16xi32>) outs(%48 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %50 = tensor.empty() : tensor<1x120x160x16xf32>
    %51 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%49, %cst_258 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%50 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %52 = tensor.empty() : tensor<1x120x160x16xf32>
    %53 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%51, %cst_257 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%52 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %54 = tensor.empty() : tensor<1x16x120x160xf32>
    %transposed_273 = linalg.transpose ins(%53 : tensor<1x120x160x16xf32>) outs(%54 : tensor<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %55 = tensor.empty() : tensor<1x16x120x160xf32>
    %56 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_273 : tensor<1x16x120x160xf32>) outs(%55 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x16x120x160xf32>
    %57 = tensor.empty() : tensor<1x16x120x160xf32>
    %58 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_273, %56 : tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>) outs(%57 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %59 = tensor.empty() : tensor<1x16x120x160xf32>
    %60 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%58, %cst_256 : tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>) outs(%59 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %61 = tensor.empty() : tensor<1x16x120x160xf32>
    %62 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%60 : tensor<1x16x120x160xf32>) outs(%61 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x16x120x160xf32>
    %63 = tensor.empty() : tensor<1x16x120x160xi8>
    %64 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%62 : tensor<1x16x120x160xf32>) outs(%63 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x16x120x160xi8>
    %65 = tensor.empty() : tensor<1x120x160x16xi8>
    %transposed_274 = linalg.transpose ins(%64 : tensor<1x16x120x160xi8>) outs(%65 : tensor<1x120x160x16xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_275 = tensor.collapse_shape %arg7 [[0], [1, 2, 3]] : tensor<16x16x1x1xi8> into tensor<16x16xi8>
    %expanded_276 = tensor.expand_shape %collapsed_275 [[0, 1, 2], [3]] output_shape [16, 1, 1, 16] : tensor<16x16xi8> into tensor<16x1x1x16xi8>
    %66 = tensor.empty() : tensor<1x120x160x16xi32>
    %67 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg8 : tensor<16xi32>) outs(%66 : tensor<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x16xi32>
    %68 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_274, %expanded_276 : tensor<1x120x160x16xi8>, tensor<16x1x1x16xi8>) outs(%67 : tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xi32>
    %69 = tensor.empty() : tensor<1x120x160x16xf32>
    %70 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%68 : tensor<1x120x160x16xi32>) outs(%69 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %71 = tensor.empty() : tensor<1x120x160x16xf32>
    %72 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%70, %cst_255 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%71 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %73 = tensor.empty() : tensor<1x120x160x16xf32>
    %74 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%72, %cst_254 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%73 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %75 = tensor.empty() : tensor<1x16x120x160xf32>
    %transposed_277 = linalg.transpose ins(%74 : tensor<1x120x160x16xf32>) outs(%75 : tensor<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %76 = tensor.empty() : tensor<1x16x120x160xf32>
    %77 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_277 : tensor<1x16x120x160xf32>) outs(%76 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x16x120x160xf32>
    %78 = tensor.empty() : tensor<1x16x120x160xf32>
    %79 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_277, %77 : tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>) outs(%78 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %80 = tensor.empty() : tensor<1x16x120x160xf32>
    %81 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%79, %cst_253 : tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>) outs(%80 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %82 = tensor.empty() : tensor<1x16x120x160xf32>
    %83 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%81 : tensor<1x16x120x160xf32>) outs(%82 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x16x120x160xf32>
    %84 = tensor.empty() : tensor<1x16x120x160xi8>
    %85 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%83 : tensor<1x16x120x160xf32>) outs(%84 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x16x120x160xi8>
    %86 = tensor.empty() : tensor<1x120x160x16xi8>
    %transposed_278 = linalg.transpose ins(%85 : tensor<1x16x120x160xi8>) outs(%86 : tensor<1x120x160x16xi8>) permutation = [0, 2, 3, 1] 
    %87 = tensor.empty() : tensor<16x3x3x16xi8>
    %transposed_279 = linalg.transpose ins(%arg9 : tensor<16x16x3x3xi8>) outs(%87 : tensor<16x3x3x16xi8>) permutation = [0, 2, 3, 1] 
    %padded_280 = tensor.pad %transposed_278 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x120x160x16xi8> to tensor<1x122x162x16xi8>
    %88 = tensor.empty() : tensor<1x120x160x16xi32>
    %89 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg10 : tensor<16xi32>) outs(%88 : tensor<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x16xi32>
    %90 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_280, %transposed_279 : tensor<1x122x162x16xi8>, tensor<16x3x3x16xi8>) outs(%89 : tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xi32>
    %91 = tensor.empty() : tensor<1x120x160x16xf32>
    %92 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%90 : tensor<1x120x160x16xi32>) outs(%91 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %93 = tensor.empty() : tensor<1x120x160x16xf32>
    %94 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%92, %cst_252 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%93 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %95 = tensor.empty() : tensor<1x120x160x16xf32>
    %96 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%94, %cst_251 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%95 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %97 = tensor.empty() : tensor<1x16x120x160xf32>
    %transposed_281 = linalg.transpose ins(%96 : tensor<1x120x160x16xf32>) outs(%97 : tensor<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %98 = tensor.empty() : tensor<1x16x120x160xf32>
    %99 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_281 : tensor<1x16x120x160xf32>) outs(%98 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x16x120x160xf32>
    %100 = tensor.empty() : tensor<1x16x120x160xf32>
    %101 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_281, %99 : tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>) outs(%100 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %102 = tensor.empty() : tensor<1x16x120x160xf32>
    %103 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%101, %cst_250 : tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>) outs(%102 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %104 = tensor.empty() : tensor<1x16x120x160xf32>
    %105 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%103 : tensor<1x16x120x160xf32>) outs(%104 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x16x120x160xf32>
    %106 = tensor.empty() : tensor<1x16x120x160xi8>
    %107 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%105 : tensor<1x16x120x160xf32>) outs(%106 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x16x120x160xi8>
    %108 = tensor.empty() : tensor<1x16x120x160xi32>
    %109 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%64 : tensor<1x16x120x160xi8>) outs(%108 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %110 = tensor.empty() : tensor<1x16x120x160xi32>
    %111 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%109, %cst_249 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%110 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %112 = tensor.empty() : tensor<1x16x120x160xi32>
    %113 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%111, %cst_248 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%112 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %114 = tensor.empty() : tensor<1x16x120x160xi32>
    %115 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%107 : tensor<1x16x120x160xi8>) outs(%114 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %116 = tensor.empty() : tensor<1x16x120x160xi32>
    %117 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%115, %cst_247 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%116 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %118 = tensor.empty() : tensor<1x16x120x160xi32>
    %119 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%117, %cst_248 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%118 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %120 = tensor.empty() : tensor<1x16x120x160xi32>
    %121 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%113, %119 : tensor<1x16x120x160xi32>, tensor<1x16x120x160xi32>) outs(%120 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %122 = tensor.empty() : tensor<1x16x120x160xi32>
    %123 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%121, %cst_246 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%122 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %124 = tensor.empty() : tensor<1x16x120x160xi32>
    %125 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%123, %cst_245 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%124 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %126 = tensor.empty() : tensor<1x16x120x160xi8>
    %127 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%125 : tensor<1x16x120x160xi32>) outs(%126 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x16x120x160xi8>
    %128 = tensor.empty() : tensor<1x120x160x32xi8>
    %transposed_282 = linalg.transpose ins(%43 : tensor<1x32x120x160xi8>) outs(%128 : tensor<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_283 = tensor.collapse_shape %arg11 [[0], [1, 2, 3]] : tensor<16x32x1x1xi8> into tensor<16x32xi8>
    %expanded_284 = tensor.expand_shape %collapsed_283 [[0, 1, 2], [3]] output_shape [16, 1, 1, 32] : tensor<16x32xi8> into tensor<16x1x1x32xi8>
    %129 = tensor.empty() : tensor<1x120x160x16xi32>
    %130 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg12 : tensor<16xi32>) outs(%129 : tensor<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x16xi32>
    %131 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_282, %expanded_284 : tensor<1x120x160x32xi8>, tensor<16x1x1x32xi8>) outs(%130 : tensor<1x120x160x16xi32>) -> tensor<1x120x160x16xi32>
    %132 = tensor.empty() : tensor<1x120x160x16xf32>
    %133 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%131 : tensor<1x120x160x16xi32>) outs(%132 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %134 = tensor.empty() : tensor<1x120x160x16xf32>
    %135 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%133, %cst_244 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%134 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %136 = tensor.empty() : tensor<1x120x160x16xf32>
    %137 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%135, %cst_251 : tensor<1x120x160x16xf32>, tensor<1x1x1x1xf32>) outs(%136 : tensor<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x16xf32>
    %138 = tensor.empty() : tensor<1x16x120x160xf32>
    %transposed_285 = linalg.transpose ins(%137 : tensor<1x120x160x16xf32>) outs(%138 : tensor<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %139 = tensor.empty() : tensor<1x16x120x160xf32>
    %140 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_285 : tensor<1x16x120x160xf32>) outs(%139 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x16x120x160xf32>
    %141 = tensor.empty() : tensor<1x16x120x160xf32>
    %142 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_285, %140 : tensor<1x16x120x160xf32>, tensor<1x16x120x160xf32>) outs(%141 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %143 = tensor.empty() : tensor<1x16x120x160xf32>
    %144 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%142, %cst_243 : tensor<1x16x120x160xf32>, tensor<1x1x1x1xf32>) outs(%143 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x120x160xf32>
    %145 = tensor.empty() : tensor<1x16x120x160xf32>
    %146 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%144 : tensor<1x16x120x160xf32>) outs(%145 : tensor<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x16x120x160xf32>
    %147 = tensor.empty() : tensor<1x16x120x160xi8>
    %148 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%146 : tensor<1x16x120x160xf32>) outs(%147 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x16x120x160xi8>
    %149 = tensor.empty() : tensor<1x16x120x160xi32>
    %150 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%127 : tensor<1x16x120x160xi8>) outs(%149 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %151 = tensor.empty() : tensor<1x16x120x160xi32>
    %152 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%150, %cst_242 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%151 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %153 = tensor.empty() : tensor<1x16x120x160xi32>
    %154 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%152, %cst_248 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%153 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %155 = tensor.empty() : tensor<1x16x120x160xi32>
    %156 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%154, %cst_246 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%155 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %157 = tensor.empty() : tensor<1x16x120x160xi32>
    %158 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%156, %cst_245 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%157 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %159 = tensor.empty() : tensor<1x16x120x160xi8>
    %160 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%158 : tensor<1x16x120x160xi32>) outs(%159 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x16x120x160xi8>
    %161 = tensor.empty() : tensor<1x16x120x160xi32>
    %162 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%148 : tensor<1x16x120x160xi8>) outs(%161 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %163 = tensor.empty() : tensor<1x16x120x160xi32>
    %164 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%162, %cst_241 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%163 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %165 = tensor.empty() : tensor<1x16x120x160xi32>
    %166 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%164, %cst_248 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%165 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %167 = tensor.empty() : tensor<1x16x120x160xi32>
    %168 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%166, %cst_246 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%167 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %169 = tensor.empty() : tensor<1x16x120x160xi32>
    %170 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%168, %cst_245 : tensor<1x16x120x160xi32>, tensor<1x1x1x1xi32>) outs(%169 : tensor<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x16x120x160xi32>
    %171 = tensor.empty() : tensor<1x16x120x160xi8>
    %172 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%170 : tensor<1x16x120x160xi32>) outs(%171 : tensor<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x16x120x160xi8>
    %173 = tensor.empty() : tensor<1x32x120x160xi8>
    %inserted_slice = tensor.insert_slice %160 into %173[0, 0, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : tensor<1x16x120x160xi8> into tensor<1x32x120x160xi8>
    %inserted_slice_286 = tensor.insert_slice %172 into %inserted_slice[0, 16, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : tensor<1x16x120x160xi8> into tensor<1x32x120x160xi8>
    %174 = tensor.empty() : tensor<1x120x160x32xi8>
    %transposed_287 = linalg.transpose ins(%inserted_slice_286 : tensor<1x32x120x160xi8>) outs(%174 : tensor<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_288 = tensor.collapse_shape %arg13 [[0], [1, 2, 3]] : tensor<32x32x1x1xi8> into tensor<32x32xi8>
    %expanded_289 = tensor.expand_shape %collapsed_288 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : tensor<32x32xi8> into tensor<32x1x1x32xi8>
    %175 = tensor.empty() : tensor<1x120x160x32xi32>
    %176 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg14 : tensor<32xi32>) outs(%175 : tensor<1x120x160x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x120x160x32xi32>
    %177 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_287, %expanded_289 : tensor<1x120x160x32xi8>, tensor<32x1x1x32xi8>) outs(%176 : tensor<1x120x160x32xi32>) -> tensor<1x120x160x32xi32>
    %178 = tensor.empty() : tensor<1x120x160x32xf32>
    %179 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%177 : tensor<1x120x160x32xi32>) outs(%178 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %180 = tensor.empty() : tensor<1x120x160x32xf32>
    %181 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%179, %cst_240 : tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>) outs(%180 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %182 = tensor.empty() : tensor<1x120x160x32xf32>
    %183 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%181, %cst_239 : tensor<1x120x160x32xf32>, tensor<1x1x1x1xf32>) outs(%182 : tensor<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x120x160x32xf32>
    %184 = tensor.empty() : tensor<1x32x120x160xf32>
    %transposed_290 = linalg.transpose ins(%183 : tensor<1x120x160x32xf32>) outs(%184 : tensor<1x32x120x160xf32>) permutation = [0, 3, 1, 2] 
    %185 = tensor.empty() : tensor<1x32x120x160xf32>
    %186 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_290 : tensor<1x32x120x160xf32>) outs(%185 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x120x160xf32>
    %187 = tensor.empty() : tensor<1x32x120x160xf32>
    %188 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_290, %186 : tensor<1x32x120x160xf32>, tensor<1x32x120x160xf32>) outs(%187 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x120x160xf32>
    %189 = tensor.empty() : tensor<1x32x120x160xf32>
    %190 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%188, %cst_238 : tensor<1x32x120x160xf32>, tensor<1x1x1x1xf32>) outs(%189 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x120x160xf32>
    %191 = tensor.empty() : tensor<1x32x120x160xf32>
    %192 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%190 : tensor<1x32x120x160xf32>) outs(%191 : tensor<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x120x160xf32>
    %193 = tensor.empty() : tensor<1x32x120x160xi8>
    %194 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%192 : tensor<1x32x120x160xf32>) outs(%193 : tensor<1x32x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x120x160xi8>
    %195 = tensor.empty() : tensor<1x120x160x32xi8>
    %transposed_291 = linalg.transpose ins(%194 : tensor<1x32x120x160xi8>) outs(%195 : tensor<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %196 = tensor.empty() : tensor<64x3x3x32xi8>
    %transposed_292 = linalg.transpose ins(%arg15 : tensor<64x32x3x3xi8>) outs(%196 : tensor<64x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %padded_293 = tensor.pad %transposed_291 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x120x160x32xi8> to tensor<1x121x161x32xi8>
    %197 = tensor.empty() : tensor<1x60x80x64xi32>
    %198 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg16 : tensor<64xi32>) outs(%197 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %199 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_293, %transposed_292 : tensor<1x121x161x32xi8>, tensor<64x3x3x32xi8>) outs(%198 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %200 = tensor.empty() : tensor<1x60x80x64xf32>
    %201 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%199 : tensor<1x60x80x64xi32>) outs(%200 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %202 = tensor.empty() : tensor<1x60x80x64xf32>
    %203 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%201, %cst_237 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%202 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %204 = tensor.empty() : tensor<1x60x80x64xf32>
    %205 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%203, %cst_236 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%204 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %206 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_294 = linalg.transpose ins(%205 : tensor<1x60x80x64xf32>) outs(%206 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %207 = tensor.empty() : tensor<1x64x60x80xf32>
    %208 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_294 : tensor<1x64x60x80xf32>) outs(%207 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x60x80xf32>
    %209 = tensor.empty() : tensor<1x64x60x80xf32>
    %210 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_294, %208 : tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>) outs(%209 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %211 = tensor.empty() : tensor<1x64x60x80xf32>
    %212 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%210, %cst_235 : tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>) outs(%211 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %213 = tensor.empty() : tensor<1x64x60x80xf32>
    %214 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%212 : tensor<1x64x60x80xf32>) outs(%213 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x60x80xf32>
    %215 = tensor.empty() : tensor<1x64x60x80xi8>
    %216 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%214 : tensor<1x64x60x80xf32>) outs(%215 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x60x80xi8>
    %217 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_295 = linalg.transpose ins(%216 : tensor<1x64x60x80xi8>) outs(%217 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_296 = tensor.collapse_shape %arg17 [[0], [1, 2, 3]] : tensor<32x64x1x1xi8> into tensor<32x64xi8>
    %expanded_297 = tensor.expand_shape %collapsed_296 [[0, 1, 2], [3]] output_shape [32, 1, 1, 64] : tensor<32x64xi8> into tensor<32x1x1x64xi8>
    %218 = tensor.empty() : tensor<1x60x80x32xi32>
    %219 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg18 : tensor<32xi32>) outs(%218 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %220 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_295, %expanded_297 : tensor<1x60x80x64xi8>, tensor<32x1x1x64xi8>) outs(%219 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %221 = tensor.empty() : tensor<1x60x80x32xf32>
    %222 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%220 : tensor<1x60x80x32xi32>) outs(%221 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %223 = tensor.empty() : tensor<1x60x80x32xf32>
    %224 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%222, %cst_234 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%223 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %225 = tensor.empty() : tensor<1x60x80x32xf32>
    %226 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%224, %cst_233 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%225 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %227 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_298 = linalg.transpose ins(%226 : tensor<1x60x80x32xf32>) outs(%227 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %228 = tensor.empty() : tensor<1x32x60x80xf32>
    %229 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_298 : tensor<1x32x60x80xf32>) outs(%228 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %230 = tensor.empty() : tensor<1x32x60x80xf32>
    %231 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_298, %229 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%230 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %232 = tensor.empty() : tensor<1x32x60x80xf32>
    %233 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%231, %cst_232 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%232 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %234 = tensor.empty() : tensor<1x32x60x80xf32>
    %235 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%233 : tensor<1x32x60x80xf32>) outs(%234 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %236 = tensor.empty() : tensor<1x32x60x80xi8>
    %237 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%235 : tensor<1x32x60x80xf32>) outs(%236 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %238 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_299 = linalg.transpose ins(%237 : tensor<1x32x60x80xi8>) outs(%238 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_300 = tensor.collapse_shape %arg19 [[0], [1, 2, 3]] : tensor<32x32x1x1xi8> into tensor<32x32xi8>
    %expanded_301 = tensor.expand_shape %collapsed_300 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : tensor<32x32xi8> into tensor<32x1x1x32xi8>
    %239 = tensor.empty() : tensor<1x60x80x32xi32>
    %240 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg20 : tensor<32xi32>) outs(%239 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %241 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_299, %expanded_301 : tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>) outs(%240 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %242 = tensor.empty() : tensor<1x60x80x32xf32>
    %243 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%241 : tensor<1x60x80x32xi32>) outs(%242 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %244 = tensor.empty() : tensor<1x60x80x32xf32>
    %245 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%243, %cst_231 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%244 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %246 = tensor.empty() : tensor<1x60x80x32xf32>
    %247 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%245, %cst_230 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%246 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %248 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_302 = linalg.transpose ins(%247 : tensor<1x60x80x32xf32>) outs(%248 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %249 = tensor.empty() : tensor<1x32x60x80xf32>
    %250 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_302 : tensor<1x32x60x80xf32>) outs(%249 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %251 = tensor.empty() : tensor<1x32x60x80xf32>
    %252 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_302, %250 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%251 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %253 = tensor.empty() : tensor<1x32x60x80xf32>
    %254 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%252, %cst_229 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%253 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %255 = tensor.empty() : tensor<1x32x60x80xf32>
    %256 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%254 : tensor<1x32x60x80xf32>) outs(%255 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %257 = tensor.empty() : tensor<1x32x60x80xi8>
    %258 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%256 : tensor<1x32x60x80xf32>) outs(%257 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %259 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_303 = linalg.transpose ins(%258 : tensor<1x32x60x80xi8>) outs(%259 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %260 = tensor.empty() : tensor<32x3x3x32xi8>
    %transposed_304 = linalg.transpose ins(%arg21 : tensor<32x32x3x3xi8>) outs(%260 : tensor<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %padded_305 = tensor.pad %transposed_303 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x32xi8> to tensor<1x62x82x32xi8>
    %261 = tensor.empty() : tensor<1x60x80x32xi32>
    %262 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg22 : tensor<32xi32>) outs(%261 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %263 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_305, %transposed_304 : tensor<1x62x82x32xi8>, tensor<32x3x3x32xi8>) outs(%262 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %264 = tensor.empty() : tensor<1x60x80x32xf32>
    %265 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%263 : tensor<1x60x80x32xi32>) outs(%264 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %266 = tensor.empty() : tensor<1x60x80x32xf32>
    %267 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%265, %cst_228 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%266 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %268 = tensor.empty() : tensor<1x60x80x32xf32>
    %269 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%267, %cst_227 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%268 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %270 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_306 = linalg.transpose ins(%269 : tensor<1x60x80x32xf32>) outs(%270 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %271 = tensor.empty() : tensor<1x32x60x80xf32>
    %272 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_306 : tensor<1x32x60x80xf32>) outs(%271 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %273 = tensor.empty() : tensor<1x32x60x80xf32>
    %274 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_306, %272 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%273 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %275 = tensor.empty() : tensor<1x32x60x80xf32>
    %276 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%274, %cst_226 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%275 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %277 = tensor.empty() : tensor<1x32x60x80xf32>
    %278 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%276 : tensor<1x32x60x80xf32>) outs(%277 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %279 = tensor.empty() : tensor<1x32x60x80xi8>
    %280 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%278 : tensor<1x32x60x80xf32>) outs(%279 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %281 = tensor.empty() : tensor<1x32x60x80xi32>
    %282 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%237 : tensor<1x32x60x80xi8>) outs(%281 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %283 = tensor.empty() : tensor<1x32x60x80xi32>
    %284 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%282, %cst_225 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%283 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %285 = tensor.empty() : tensor<1x32x60x80xi32>
    %286 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%284, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%285 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %287 = tensor.empty() : tensor<1x32x60x80xi32>
    %288 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%280 : tensor<1x32x60x80xi8>) outs(%287 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %289 = tensor.empty() : tensor<1x32x60x80xi32>
    %290 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%288, %cst_224 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%289 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %291 = tensor.empty() : tensor<1x32x60x80xi32>
    %292 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%290, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%291 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %293 = tensor.empty() : tensor<1x32x60x80xi32>
    %294 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%286, %292 : tensor<1x32x60x80xi32>, tensor<1x32x60x80xi32>) outs(%293 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %295 = tensor.empty() : tensor<1x32x60x80xi32>
    %296 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%294, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%295 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %297 = tensor.empty() : tensor<1x32x60x80xi32>
    %298 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%296, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%297 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %299 = tensor.empty() : tensor<1x32x60x80xi8>
    %300 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%298 : tensor<1x32x60x80xi32>) outs(%299 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %301 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_307 = linalg.transpose ins(%300 : tensor<1x32x60x80xi8>) outs(%301 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_308 = tensor.collapse_shape %arg23 [[0], [1, 2, 3]] : tensor<32x32x1x1xi8> into tensor<32x32xi8>
    %expanded_309 = tensor.expand_shape %collapsed_308 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : tensor<32x32xi8> into tensor<32x1x1x32xi8>
    %302 = tensor.empty() : tensor<1x60x80x32xi32>
    %303 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg24 : tensor<32xi32>) outs(%302 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %304 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_307, %expanded_309 : tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>) outs(%303 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %305 = tensor.empty() : tensor<1x60x80x32xf32>
    %306 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%304 : tensor<1x60x80x32xi32>) outs(%305 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %307 = tensor.empty() : tensor<1x60x80x32xf32>
    %308 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%306, %cst_223 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%307 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %309 = tensor.empty() : tensor<1x60x80x32xf32>
    %310 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%308, %cst_222 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%309 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %311 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_310 = linalg.transpose ins(%310 : tensor<1x60x80x32xf32>) outs(%311 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %312 = tensor.empty() : tensor<1x32x60x80xf32>
    %313 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_310 : tensor<1x32x60x80xf32>) outs(%312 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %314 = tensor.empty() : tensor<1x32x60x80xf32>
    %315 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_310, %313 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%314 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %316 = tensor.empty() : tensor<1x32x60x80xf32>
    %317 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%315, %cst_221 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%316 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %318 = tensor.empty() : tensor<1x32x60x80xf32>
    %319 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%317 : tensor<1x32x60x80xf32>) outs(%318 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %320 = tensor.empty() : tensor<1x32x60x80xi8>
    %321 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%319 : tensor<1x32x60x80xf32>) outs(%320 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %322 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_311 = linalg.transpose ins(%321 : tensor<1x32x60x80xi8>) outs(%322 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %323 = tensor.empty() : tensor<32x3x3x32xi8>
    %transposed_312 = linalg.transpose ins(%arg25 : tensor<32x32x3x3xi8>) outs(%323 : tensor<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %padded_313 = tensor.pad %transposed_311 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x32xi8> to tensor<1x62x82x32xi8>
    %324 = tensor.empty() : tensor<1x60x80x32xi32>
    %325 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg26 : tensor<32xi32>) outs(%324 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %326 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_313, %transposed_312 : tensor<1x62x82x32xi8>, tensor<32x3x3x32xi8>) outs(%325 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %327 = tensor.empty() : tensor<1x60x80x32xf32>
    %328 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%326 : tensor<1x60x80x32xi32>) outs(%327 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %329 = tensor.empty() : tensor<1x60x80x32xf32>
    %330 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%328, %cst_220 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%329 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %331 = tensor.empty() : tensor<1x60x80x32xf32>
    %332 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%330, %cst_219 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%331 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %333 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_314 = linalg.transpose ins(%332 : tensor<1x60x80x32xf32>) outs(%333 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %334 = tensor.empty() : tensor<1x32x60x80xf32>
    %335 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_314 : tensor<1x32x60x80xf32>) outs(%334 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %336 = tensor.empty() : tensor<1x32x60x80xf32>
    %337 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_314, %335 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%336 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %338 = tensor.empty() : tensor<1x32x60x80xf32>
    %339 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%337, %cst_218 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%338 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %340 = tensor.empty() : tensor<1x32x60x80xf32>
    %341 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%339 : tensor<1x32x60x80xf32>) outs(%340 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %342 = tensor.empty() : tensor<1x32x60x80xi8>
    %343 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%341 : tensor<1x32x60x80xf32>) outs(%342 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %344 = tensor.empty() : tensor<1x32x60x80xi32>
    %345 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%300 : tensor<1x32x60x80xi8>) outs(%344 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %346 = tensor.empty() : tensor<1x32x60x80xi32>
    %347 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%345, %cst_217 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%346 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %348 = tensor.empty() : tensor<1x32x60x80xi32>
    %349 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%347, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%348 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %350 = tensor.empty() : tensor<1x32x60x80xi32>
    %351 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%343 : tensor<1x32x60x80xi8>) outs(%350 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %352 = tensor.empty() : tensor<1x32x60x80xi32>
    %353 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%351, %cst_216 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%352 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %354 = tensor.empty() : tensor<1x32x60x80xi32>
    %355 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%353, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%354 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %356 = tensor.empty() : tensor<1x32x60x80xi32>
    %357 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%349, %355 : tensor<1x32x60x80xi32>, tensor<1x32x60x80xi32>) outs(%356 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %358 = tensor.empty() : tensor<1x32x60x80xi32>
    %359 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%357, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%358 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %360 = tensor.empty() : tensor<1x32x60x80xi32>
    %361 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%359, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%360 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %362 = tensor.empty() : tensor<1x32x60x80xi8>
    %363 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%361 : tensor<1x32x60x80xi32>) outs(%362 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %364 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_315 = linalg.transpose ins(%216 : tensor<1x64x60x80xi8>) outs(%364 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_316 = tensor.collapse_shape %arg27 [[0], [1, 2, 3]] : tensor<32x64x1x1xi8> into tensor<32x64xi8>
    %expanded_317 = tensor.expand_shape %collapsed_316 [[0, 1, 2], [3]] output_shape [32, 1, 1, 64] : tensor<32x64xi8> into tensor<32x1x1x64xi8>
    %365 = tensor.empty() : tensor<1x60x80x32xi32>
    %366 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg28 : tensor<32xi32>) outs(%365 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %367 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_315, %expanded_317 : tensor<1x60x80x64xi8>, tensor<32x1x1x64xi8>) outs(%366 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %368 = tensor.empty() : tensor<1x60x80x32xf32>
    %369 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%367 : tensor<1x60x80x32xi32>) outs(%368 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %370 = tensor.empty() : tensor<1x60x80x32xf32>
    %371 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%369, %cst_215 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%370 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %372 = tensor.empty() : tensor<1x60x80x32xf32>
    %373 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%371, %cst_219 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%372 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %374 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_318 = linalg.transpose ins(%373 : tensor<1x60x80x32xf32>) outs(%374 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %375 = tensor.empty() : tensor<1x32x60x80xf32>
    %376 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_318 : tensor<1x32x60x80xf32>) outs(%375 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %377 = tensor.empty() : tensor<1x32x60x80xf32>
    %378 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_318, %376 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%377 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %379 = tensor.empty() : tensor<1x32x60x80xf32>
    %380 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%378, %cst_214 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%379 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %381 = tensor.empty() : tensor<1x32x60x80xf32>
    %382 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%380 : tensor<1x32x60x80xf32>) outs(%381 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %383 = tensor.empty() : tensor<1x32x60x80xi8>
    %384 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%382 : tensor<1x32x60x80xf32>) outs(%383 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %385 = tensor.empty() : tensor<1x32x60x80xi32>
    %386 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%363 : tensor<1x32x60x80xi8>) outs(%385 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %387 = tensor.empty() : tensor<1x32x60x80xi32>
    %388 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%386, %cst_213 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%387 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %389 = tensor.empty() : tensor<1x32x60x80xi32>
    %390 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%388, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%389 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %391 = tensor.empty() : tensor<1x32x60x80xi32>
    %392 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%390, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%391 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %393 = tensor.empty() : tensor<1x32x60x80xi32>
    %394 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%392, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%393 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %395 = tensor.empty() : tensor<1x32x60x80xi8>
    %396 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%394 : tensor<1x32x60x80xi32>) outs(%395 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %397 = tensor.empty() : tensor<1x32x60x80xi32>
    %398 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%384 : tensor<1x32x60x80xi8>) outs(%397 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %399 = tensor.empty() : tensor<1x32x60x80xi32>
    %400 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%398, %cst_212 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%399 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %401 = tensor.empty() : tensor<1x32x60x80xi32>
    %402 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%400, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%401 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %403 = tensor.empty() : tensor<1x32x60x80xi32>
    %404 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%402, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%403 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %405 = tensor.empty() : tensor<1x32x60x80xi32>
    %406 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%404, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%405 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %407 = tensor.empty() : tensor<1x32x60x80xi8>
    %408 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%406 : tensor<1x32x60x80xi32>) outs(%407 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %409 = tensor.empty() : tensor<1x64x60x80xi8>
    %inserted_slice_319 = tensor.insert_slice %396 into %409[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : tensor<1x32x60x80xi8> into tensor<1x64x60x80xi8>
    %inserted_slice_320 = tensor.insert_slice %408 into %inserted_slice_319[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : tensor<1x32x60x80xi8> into tensor<1x64x60x80xi8>
    %410 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_321 = linalg.transpose ins(%inserted_slice_320 : tensor<1x64x60x80xi8>) outs(%410 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_322 = tensor.collapse_shape %arg29 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_323 = tensor.expand_shape %collapsed_322 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %411 = tensor.empty() : tensor<1x60x80x64xi32>
    %412 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg30 : tensor<64xi32>) outs(%411 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %413 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_321, %expanded_323 : tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>) outs(%412 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %414 = tensor.empty() : tensor<1x60x80x64xf32>
    %415 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%413 : tensor<1x60x80x64xi32>) outs(%414 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %416 = tensor.empty() : tensor<1x60x80x64xf32>
    %417 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%415, %cst_211 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%416 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %418 = tensor.empty() : tensor<1x60x80x64xf32>
    %419 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%417, %cst_210 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%418 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %420 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_324 = linalg.transpose ins(%419 : tensor<1x60x80x64xf32>) outs(%420 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %421 = tensor.empty() : tensor<1x64x60x80xf32>
    %422 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_324 : tensor<1x64x60x80xf32>) outs(%421 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x60x80xf32>
    %423 = tensor.empty() : tensor<1x64x60x80xf32>
    %424 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_324, %422 : tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>) outs(%423 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %425 = tensor.empty() : tensor<1x64x60x80xf32>
    %426 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%424, %cst_209 : tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>) outs(%425 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %427 = tensor.empty() : tensor<1x64x60x80xf32>
    %428 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%426 : tensor<1x64x60x80xf32>) outs(%427 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x60x80xf32>
    %429 = tensor.empty() : tensor<1x64x60x80xi8>
    %430 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%428 : tensor<1x64x60x80xf32>) outs(%429 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x60x80xi8>
    %431 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_325 = linalg.transpose ins(%430 : tensor<1x64x60x80xi8>) outs(%431 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %432 = tensor.empty() : tensor<128x3x3x64xi8>
    %transposed_326 = linalg.transpose ins(%arg31 : tensor<128x64x3x3xi8>) outs(%432 : tensor<128x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_327 = tensor.pad %transposed_325 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x64xi8> to tensor<1x61x81x64xi8>
    %433 = tensor.empty() : tensor<1x30x40x128xi32>
    %434 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg32 : tensor<128xi32>) outs(%433 : tensor<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x128xi32>
    %435 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_327, %transposed_326 : tensor<1x61x81x64xi8>, tensor<128x3x3x64xi8>) outs(%434 : tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xi32>
    %436 = tensor.empty() : tensor<1x30x40x128xf32>
    %437 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%435 : tensor<1x30x40x128xi32>) outs(%436 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %438 = tensor.empty() : tensor<1x30x40x128xf32>
    %439 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%437, %cst_208 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%438 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %440 = tensor.empty() : tensor<1x30x40x128xf32>
    %441 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%439, %cst_207 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%440 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %442 = tensor.empty() : tensor<1x128x30x40xf32>
    %transposed_328 = linalg.transpose ins(%441 : tensor<1x30x40x128xf32>) outs(%442 : tensor<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %443 = tensor.empty() : tensor<1x128x30x40xf32>
    %444 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_328 : tensor<1x128x30x40xf32>) outs(%443 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x30x40xf32>
    %445 = tensor.empty() : tensor<1x128x30x40xf32>
    %446 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_328, %444 : tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>) outs(%445 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %447 = tensor.empty() : tensor<1x128x30x40xf32>
    %448 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%446, %cst_206 : tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>) outs(%447 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %449 = tensor.empty() : tensor<1x128x30x40xf32>
    %450 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%448 : tensor<1x128x30x40xf32>) outs(%449 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x30x40xf32>
    %451 = tensor.empty() : tensor<1x128x30x40xi8>
    %452 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%450 : tensor<1x128x30x40xf32>) outs(%451 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x30x40xi8>
    %453 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_329 = linalg.transpose ins(%452 : tensor<1x128x30x40xi8>) outs(%453 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_330 = tensor.collapse_shape %arg33 [[0], [1, 2, 3]] : tensor<64x128x1x1xi8> into tensor<64x128xi8>
    %expanded_331 = tensor.expand_shape %collapsed_330 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : tensor<64x128xi8> into tensor<64x1x1x128xi8>
    %454 = tensor.empty() : tensor<1x30x40x64xi32>
    %455 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg34 : tensor<64xi32>) outs(%454 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %456 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_329, %expanded_331 : tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>) outs(%455 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %457 = tensor.empty() : tensor<1x30x40x64xf32>
    %458 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%456 : tensor<1x30x40x64xi32>) outs(%457 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %459 = tensor.empty() : tensor<1x30x40x64xf32>
    %460 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%458, %cst_205 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%459 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %461 = tensor.empty() : tensor<1x30x40x64xf32>
    %462 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%460, %cst_204 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%461 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %463 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_332 = linalg.transpose ins(%462 : tensor<1x30x40x64xf32>) outs(%463 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %464 = tensor.empty() : tensor<1x64x30x40xf32>
    %465 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_332 : tensor<1x64x30x40xf32>) outs(%464 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %466 = tensor.empty() : tensor<1x64x30x40xf32>
    %467 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_332, %465 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%466 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %468 = tensor.empty() : tensor<1x64x30x40xf32>
    %469 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%467, %cst_203 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%468 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %470 = tensor.empty() : tensor<1x64x30x40xf32>
    %471 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%469 : tensor<1x64x30x40xf32>) outs(%470 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %472 = tensor.empty() : tensor<1x64x30x40xi8>
    %473 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%471 : tensor<1x64x30x40xf32>) outs(%472 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %474 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_333 = linalg.transpose ins(%473 : tensor<1x64x30x40xi8>) outs(%474 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_334 = tensor.collapse_shape %arg35 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_335 = tensor.expand_shape %collapsed_334 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %475 = tensor.empty() : tensor<1x30x40x64xi32>
    %476 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg36 : tensor<64xi32>) outs(%475 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %477 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_333, %expanded_335 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%476 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %478 = tensor.empty() : tensor<1x30x40x64xf32>
    %479 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%477 : tensor<1x30x40x64xi32>) outs(%478 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %480 = tensor.empty() : tensor<1x30x40x64xf32>
    %481 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%479, %cst_202 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%480 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %482 = tensor.empty() : tensor<1x30x40x64xf32>
    %483 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%481, %cst_201 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%482 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %484 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_336 = linalg.transpose ins(%483 : tensor<1x30x40x64xf32>) outs(%484 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %485 = tensor.empty() : tensor<1x64x30x40xf32>
    %486 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_336 : tensor<1x64x30x40xf32>) outs(%485 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %487 = tensor.empty() : tensor<1x64x30x40xf32>
    %488 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_336, %486 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%487 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %489 = tensor.empty() : tensor<1x64x30x40xf32>
    %490 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%488, %cst_200 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%489 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %491 = tensor.empty() : tensor<1x64x30x40xf32>
    %492 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%490 : tensor<1x64x30x40xf32>) outs(%491 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %493 = tensor.empty() : tensor<1x64x30x40xi8>
    %494 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%492 : tensor<1x64x30x40xf32>) outs(%493 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %495 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_337 = linalg.transpose ins(%494 : tensor<1x64x30x40xi8>) outs(%495 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %496 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_338 = linalg.transpose ins(%arg37 : tensor<64x64x3x3xi8>) outs(%496 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_339 = tensor.pad %transposed_337 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %497 = tensor.empty() : tensor<1x30x40x64xi32>
    %498 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg38 : tensor<64xi32>) outs(%497 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %499 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_339, %transposed_338 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%498 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %500 = tensor.empty() : tensor<1x30x40x64xf32>
    %501 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%499 : tensor<1x30x40x64xi32>) outs(%500 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %502 = tensor.empty() : tensor<1x30x40x64xf32>
    %503 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%501, %cst_199 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%502 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %504 = tensor.empty() : tensor<1x30x40x64xf32>
    %505 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%503, %cst_198 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%504 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %506 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_340 = linalg.transpose ins(%505 : tensor<1x30x40x64xf32>) outs(%506 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %507 = tensor.empty() : tensor<1x64x30x40xf32>
    %508 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_340 : tensor<1x64x30x40xf32>) outs(%507 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %509 = tensor.empty() : tensor<1x64x30x40xf32>
    %510 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_340, %508 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%509 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %511 = tensor.empty() : tensor<1x64x30x40xf32>
    %512 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%510, %cst_197 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%511 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %513 = tensor.empty() : tensor<1x64x30x40xf32>
    %514 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%512 : tensor<1x64x30x40xf32>) outs(%513 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %515 = tensor.empty() : tensor<1x64x30x40xi8>
    %516 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%514 : tensor<1x64x30x40xf32>) outs(%515 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %517 = tensor.empty() : tensor<1x64x30x40xi32>
    %518 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%473 : tensor<1x64x30x40xi8>) outs(%517 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %519 = tensor.empty() : tensor<1x64x30x40xi32>
    %520 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%518, %cst_196 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%519 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %521 = tensor.empty() : tensor<1x64x30x40xi32>
    %522 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%520, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%521 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %523 = tensor.empty() : tensor<1x64x30x40xi32>
    %524 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%516 : tensor<1x64x30x40xi8>) outs(%523 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %525 = tensor.empty() : tensor<1x64x30x40xi32>
    %526 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%524, %cst_195 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%525 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %527 = tensor.empty() : tensor<1x64x30x40xi32>
    %528 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%526, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%527 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %529 = tensor.empty() : tensor<1x64x30x40xi32>
    %530 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%522, %528 : tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) outs(%529 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %531 = tensor.empty() : tensor<1x64x30x40xi32>
    %532 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%530, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%531 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %533 = tensor.empty() : tensor<1x64x30x40xi32>
    %534 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%532, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%533 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %535 = tensor.empty() : tensor<1x64x30x40xi8>
    %536 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%534 : tensor<1x64x30x40xi32>) outs(%535 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %537 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_341 = linalg.transpose ins(%536 : tensor<1x64x30x40xi8>) outs(%537 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_342 = tensor.collapse_shape %arg39 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_343 = tensor.expand_shape %collapsed_342 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %538 = tensor.empty() : tensor<1x30x40x64xi32>
    %539 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg40 : tensor<64xi32>) outs(%538 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %540 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_341, %expanded_343 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%539 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %541 = tensor.empty() : tensor<1x30x40x64xf32>
    %542 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%540 : tensor<1x30x40x64xi32>) outs(%541 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %543 = tensor.empty() : tensor<1x30x40x64xf32>
    %544 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%542, %cst_194 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%543 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %545 = tensor.empty() : tensor<1x30x40x64xf32>
    %546 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%544, %cst_193 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%545 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %547 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_344 = linalg.transpose ins(%546 : tensor<1x30x40x64xf32>) outs(%547 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %548 = tensor.empty() : tensor<1x64x30x40xf32>
    %549 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_344 : tensor<1x64x30x40xf32>) outs(%548 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %550 = tensor.empty() : tensor<1x64x30x40xf32>
    %551 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_344, %549 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%550 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %552 = tensor.empty() : tensor<1x64x30x40xf32>
    %553 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%551, %cst_192 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%552 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %554 = tensor.empty() : tensor<1x64x30x40xf32>
    %555 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%553 : tensor<1x64x30x40xf32>) outs(%554 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %556 = tensor.empty() : tensor<1x64x30x40xi8>
    %557 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%555 : tensor<1x64x30x40xf32>) outs(%556 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %558 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_345 = linalg.transpose ins(%557 : tensor<1x64x30x40xi8>) outs(%558 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %559 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_346 = linalg.transpose ins(%arg41 : tensor<64x64x3x3xi8>) outs(%559 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_347 = tensor.pad %transposed_345 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %560 = tensor.empty() : tensor<1x30x40x64xi32>
    %561 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg42 : tensor<64xi32>) outs(%560 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %562 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_347, %transposed_346 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%561 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %563 = tensor.empty() : tensor<1x30x40x64xf32>
    %564 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%562 : tensor<1x30x40x64xi32>) outs(%563 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %565 = tensor.empty() : tensor<1x30x40x64xf32>
    %566 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%564, %cst_191 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%565 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %567 = tensor.empty() : tensor<1x30x40x64xf32>
    %568 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%566, %cst_190 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%567 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %569 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_348 = linalg.transpose ins(%568 : tensor<1x30x40x64xf32>) outs(%569 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %570 = tensor.empty() : tensor<1x64x30x40xf32>
    %571 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_348 : tensor<1x64x30x40xf32>) outs(%570 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %572 = tensor.empty() : tensor<1x64x30x40xf32>
    %573 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_348, %571 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%572 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %574 = tensor.empty() : tensor<1x64x30x40xf32>
    %575 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%573, %cst_189 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%574 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %576 = tensor.empty() : tensor<1x64x30x40xf32>
    %577 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%575 : tensor<1x64x30x40xf32>) outs(%576 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %578 = tensor.empty() : tensor<1x64x30x40xi8>
    %579 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%577 : tensor<1x64x30x40xf32>) outs(%578 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %580 = tensor.empty() : tensor<1x64x30x40xi32>
    %581 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%536 : tensor<1x64x30x40xi8>) outs(%580 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %582 = tensor.empty() : tensor<1x64x30x40xi32>
    %583 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%581, %cst_188 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%582 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %584 = tensor.empty() : tensor<1x64x30x40xi32>
    %585 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%583, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%584 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %586 = tensor.empty() : tensor<1x64x30x40xi32>
    %587 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%579 : tensor<1x64x30x40xi8>) outs(%586 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %588 = tensor.empty() : tensor<1x64x30x40xi32>
    %589 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%587, %cst_187 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%588 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %590 = tensor.empty() : tensor<1x64x30x40xi32>
    %591 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%589, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%590 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %592 = tensor.empty() : tensor<1x64x30x40xi32>
    %593 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%585, %591 : tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) outs(%592 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %594 = tensor.empty() : tensor<1x64x30x40xi32>
    %595 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%593, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%594 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %596 = tensor.empty() : tensor<1x64x30x40xi32>
    %597 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%595, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%596 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %598 = tensor.empty() : tensor<1x64x30x40xi8>
    %599 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%597 : tensor<1x64x30x40xi32>) outs(%598 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %600 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_349 = linalg.transpose ins(%599 : tensor<1x64x30x40xi8>) outs(%600 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_350 = tensor.collapse_shape %arg43 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_351 = tensor.expand_shape %collapsed_350 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %601 = tensor.empty() : tensor<1x30x40x64xi32>
    %602 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg44 : tensor<64xi32>) outs(%601 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %603 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_349, %expanded_351 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%602 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %604 = tensor.empty() : tensor<1x30x40x64xf32>
    %605 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%603 : tensor<1x30x40x64xi32>) outs(%604 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %606 = tensor.empty() : tensor<1x30x40x64xf32>
    %607 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%605, %cst_186 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%606 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %608 = tensor.empty() : tensor<1x30x40x64xf32>
    %609 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%607, %cst_185 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%608 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %610 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_352 = linalg.transpose ins(%609 : tensor<1x30x40x64xf32>) outs(%610 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %611 = tensor.empty() : tensor<1x64x30x40xf32>
    %612 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_352 : tensor<1x64x30x40xf32>) outs(%611 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %613 = tensor.empty() : tensor<1x64x30x40xf32>
    %614 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_352, %612 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%613 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %615 = tensor.empty() : tensor<1x64x30x40xf32>
    %616 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%614, %cst_184 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%615 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %617 = tensor.empty() : tensor<1x64x30x40xf32>
    %618 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%616 : tensor<1x64x30x40xf32>) outs(%617 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %619 = tensor.empty() : tensor<1x64x30x40xi8>
    %620 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%618 : tensor<1x64x30x40xf32>) outs(%619 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %621 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_353 = linalg.transpose ins(%620 : tensor<1x64x30x40xi8>) outs(%621 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %622 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_354 = linalg.transpose ins(%arg45 : tensor<64x64x3x3xi8>) outs(%622 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_355 = tensor.pad %transposed_353 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %623 = tensor.empty() : tensor<1x30x40x64xi32>
    %624 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg46 : tensor<64xi32>) outs(%623 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %625 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_355, %transposed_354 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%624 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %626 = tensor.empty() : tensor<1x30x40x64xf32>
    %627 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%625 : tensor<1x30x40x64xi32>) outs(%626 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %628 = tensor.empty() : tensor<1x30x40x64xf32>
    %629 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%627, %cst_183 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%628 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %630 = tensor.empty() : tensor<1x30x40x64xf32>
    %631 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%629, %cst_182 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%630 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %632 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_356 = linalg.transpose ins(%631 : tensor<1x30x40x64xf32>) outs(%632 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %633 = tensor.empty() : tensor<1x64x30x40xf32>
    %634 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_356 : tensor<1x64x30x40xf32>) outs(%633 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %635 = tensor.empty() : tensor<1x64x30x40xf32>
    %636 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_356, %634 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%635 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %637 = tensor.empty() : tensor<1x64x30x40xf32>
    %638 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%636, %cst_181 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%637 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %639 = tensor.empty() : tensor<1x64x30x40xf32>
    %640 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%638 : tensor<1x64x30x40xf32>) outs(%639 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %641 = tensor.empty() : tensor<1x64x30x40xi8>
    %642 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%640 : tensor<1x64x30x40xf32>) outs(%641 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %643 = tensor.empty() : tensor<1x64x30x40xi32>
    %644 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%599 : tensor<1x64x30x40xi8>) outs(%643 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %645 = tensor.empty() : tensor<1x64x30x40xi32>
    %646 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%644, %cst_180 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%645 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %647 = tensor.empty() : tensor<1x64x30x40xi32>
    %648 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%646, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%647 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %649 = tensor.empty() : tensor<1x64x30x40xi32>
    %650 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%642 : tensor<1x64x30x40xi8>) outs(%649 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %651 = tensor.empty() : tensor<1x64x30x40xi32>
    %652 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%650, %cst_179 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%651 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %653 = tensor.empty() : tensor<1x64x30x40xi32>
    %654 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%652, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%653 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %655 = tensor.empty() : tensor<1x64x30x40xi32>
    %656 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%648, %654 : tensor<1x64x30x40xi32>, tensor<1x64x30x40xi32>) outs(%655 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %657 = tensor.empty() : tensor<1x64x30x40xi32>
    %658 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%656, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%657 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %659 = tensor.empty() : tensor<1x64x30x40xi32>
    %660 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%658, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%659 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %661 = tensor.empty() : tensor<1x64x30x40xi8>
    %662 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%660 : tensor<1x64x30x40xi32>) outs(%661 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %663 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_357 = linalg.transpose ins(%452 : tensor<1x128x30x40xi8>) outs(%663 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_358 = tensor.collapse_shape %arg47 [[0], [1, 2, 3]] : tensor<64x128x1x1xi8> into tensor<64x128xi8>
    %expanded_359 = tensor.expand_shape %collapsed_358 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : tensor<64x128xi8> into tensor<64x1x1x128xi8>
    %664 = tensor.empty() : tensor<1x30x40x64xi32>
    %665 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg48 : tensor<64xi32>) outs(%664 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %666 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_357, %expanded_359 : tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>) outs(%665 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %667 = tensor.empty() : tensor<1x30x40x64xf32>
    %668 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%666 : tensor<1x30x40x64xi32>) outs(%667 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %669 = tensor.empty() : tensor<1x30x40x64xf32>
    %670 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%668, %cst_178 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%669 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %671 = tensor.empty() : tensor<1x30x40x64xf32>
    %672 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%670, %cst_182 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%671 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %673 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_360 = linalg.transpose ins(%672 : tensor<1x30x40x64xf32>) outs(%673 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %674 = tensor.empty() : tensor<1x64x30x40xf32>
    %675 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_360 : tensor<1x64x30x40xf32>) outs(%674 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %676 = tensor.empty() : tensor<1x64x30x40xf32>
    %677 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_360, %675 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%676 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %678 = tensor.empty() : tensor<1x64x30x40xf32>
    %679 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%677, %cst_177 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%678 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %680 = tensor.empty() : tensor<1x64x30x40xf32>
    %681 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%679 : tensor<1x64x30x40xf32>) outs(%680 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %682 = tensor.empty() : tensor<1x64x30x40xi8>
    %683 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%681 : tensor<1x64x30x40xf32>) outs(%682 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %684 = tensor.empty() : tensor<1x64x30x40xi32>
    %685 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%662 : tensor<1x64x30x40xi8>) outs(%684 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %686 = tensor.empty() : tensor<1x64x30x40xi32>
    %687 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%685, %cst_176 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%686 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %688 = tensor.empty() : tensor<1x64x30x40xi32>
    %689 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%687, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%688 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %690 = tensor.empty() : tensor<1x64x30x40xi32>
    %691 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%689, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%690 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %692 = tensor.empty() : tensor<1x64x30x40xi32>
    %693 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%691, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%692 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %694 = tensor.empty() : tensor<1x64x30x40xi8>
    %695 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%693 : tensor<1x64x30x40xi32>) outs(%694 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %696 = tensor.empty() : tensor<1x64x30x40xi32>
    %697 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%683 : tensor<1x64x30x40xi8>) outs(%696 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %698 = tensor.empty() : tensor<1x64x30x40xi32>
    %699 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%697, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%698 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %700 = tensor.empty() : tensor<1x64x30x40xi32>
    %701 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%699, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%700 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %702 = tensor.empty() : tensor<1x64x30x40xi8>
    %703 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%701 : tensor<1x64x30x40xi32>) outs(%702 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %704 = tensor.empty() : tensor<1x128x30x40xi8>
    %inserted_slice_361 = tensor.insert_slice %695 into %704[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %inserted_slice_362 = tensor.insert_slice %703 into %inserted_slice_361[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %705 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_363 = linalg.transpose ins(%inserted_slice_362 : tensor<1x128x30x40xi8>) outs(%705 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_364 = tensor.collapse_shape %arg49 [[0], [1, 2, 3]] : tensor<128x128x1x1xi8> into tensor<128x128xi8>
    %expanded_365 = tensor.expand_shape %collapsed_364 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : tensor<128x128xi8> into tensor<128x1x1x128xi8>
    %706 = tensor.empty() : tensor<1x30x40x128xi32>
    %707 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg50 : tensor<128xi32>) outs(%706 : tensor<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x128xi32>
    %708 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_363, %expanded_365 : tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>) outs(%707 : tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xi32>
    %709 = tensor.empty() : tensor<1x30x40x128xf32>
    %710 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%708 : tensor<1x30x40x128xi32>) outs(%709 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %711 = tensor.empty() : tensor<1x30x40x128xf32>
    %712 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%710, %cst_175 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%711 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %713 = tensor.empty() : tensor<1x30x40x128xf32>
    %714 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%712, %cst_174 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%713 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %715 = tensor.empty() : tensor<1x128x30x40xf32>
    %transposed_366 = linalg.transpose ins(%714 : tensor<1x30x40x128xf32>) outs(%715 : tensor<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %716 = tensor.empty() : tensor<1x128x30x40xf32>
    %717 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_366 : tensor<1x128x30x40xf32>) outs(%716 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x30x40xf32>
    %718 = tensor.empty() : tensor<1x128x30x40xf32>
    %719 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_366, %717 : tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>) outs(%718 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %720 = tensor.empty() : tensor<1x128x30x40xf32>
    %721 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%719, %cst_173 : tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>) outs(%720 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %722 = tensor.empty() : tensor<1x128x30x40xf32>
    %723 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%721 : tensor<1x128x30x40xf32>) outs(%722 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x30x40xf32>
    %724 = tensor.empty() : tensor<1x128x30x40xi8>
    %725 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%723 : tensor<1x128x30x40xf32>) outs(%724 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x30x40xi8>
    %726 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_367 = linalg.transpose ins(%725 : tensor<1x128x30x40xi8>) outs(%726 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %727 = tensor.empty() : tensor<256x3x3x128xi8>
    %transposed_368 = linalg.transpose ins(%arg51 : tensor<256x128x3x3xi8>) outs(%727 : tensor<256x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_369 = tensor.pad %transposed_367 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x128xi8> to tensor<1x31x41x128xi8>
    %728 = tensor.empty() : tensor<1x15x20x256xi32>
    %729 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg52 : tensor<256xi32>) outs(%728 : tensor<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x256xi32>
    %730 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_369, %transposed_368 : tensor<1x31x41x128xi8>, tensor<256x3x3x128xi8>) outs(%729 : tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xi32>
    %731 = tensor.empty() : tensor<1x15x20x256xf32>
    %732 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%730 : tensor<1x15x20x256xi32>) outs(%731 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %733 = tensor.empty() : tensor<1x15x20x256xf32>
    %734 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%732, %cst_172 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%733 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %735 = tensor.empty() : tensor<1x15x20x256xf32>
    %736 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%734, %cst_171 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%735 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %737 = tensor.empty() : tensor<1x256x15x20xf32>
    %transposed_370 = linalg.transpose ins(%736 : tensor<1x15x20x256xf32>) outs(%737 : tensor<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %738 = tensor.empty() : tensor<1x256x15x20xf32>
    %739 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_370 : tensor<1x256x15x20xf32>) outs(%738 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x256x15x20xf32>
    %740 = tensor.empty() : tensor<1x256x15x20xf32>
    %741 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_370, %739 : tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>) outs(%740 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %742 = tensor.empty() : tensor<1x256x15x20xf32>
    %743 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%741, %cst_170 : tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>) outs(%742 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %744 = tensor.empty() : tensor<1x256x15x20xf32>
    %745 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%743 : tensor<1x256x15x20xf32>) outs(%744 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x256x15x20xf32>
    %746 = tensor.empty() : tensor<1x256x15x20xi8>
    %747 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%745 : tensor<1x256x15x20xf32>) outs(%746 : tensor<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x256x15x20xi8>
    %748 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_371 = linalg.transpose ins(%747 : tensor<1x256x15x20xi8>) outs(%748 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_372 = tensor.collapse_shape %arg53 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_373 = tensor.expand_shape %collapsed_372 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %749 = tensor.empty() : tensor<1x15x20x128xi32>
    %750 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg54 : tensor<128xi32>) outs(%749 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %751 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_371, %expanded_373 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%750 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %752 = tensor.empty() : tensor<1x15x20x128xf32>
    %753 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%751 : tensor<1x15x20x128xi32>) outs(%752 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %754 = tensor.empty() : tensor<1x15x20x128xf32>
    %755 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%753, %cst_169 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%754 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %756 = tensor.empty() : tensor<1x15x20x128xf32>
    %757 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%755, %cst_168 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%756 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %758 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_374 = linalg.transpose ins(%757 : tensor<1x15x20x128xf32>) outs(%758 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %759 = tensor.empty() : tensor<1x128x15x20xf32>
    %760 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_374 : tensor<1x128x15x20xf32>) outs(%759 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %761 = tensor.empty() : tensor<1x128x15x20xf32>
    %762 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_374, %760 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%761 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %763 = tensor.empty() : tensor<1x128x15x20xf32>
    %764 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%762, %cst_167 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%763 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %765 = tensor.empty() : tensor<1x128x15x20xf32>
    %766 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%764 : tensor<1x128x15x20xf32>) outs(%765 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %767 = tensor.empty() : tensor<1x128x15x20xi8>
    %768 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%766 : tensor<1x128x15x20xf32>) outs(%767 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %769 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_375 = linalg.transpose ins(%768 : tensor<1x128x15x20xi8>) outs(%769 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_376 = tensor.collapse_shape %arg55 [[0], [1, 2, 3]] : tensor<128x128x1x1xi8> into tensor<128x128xi8>
    %expanded_377 = tensor.expand_shape %collapsed_376 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : tensor<128x128xi8> into tensor<128x1x1x128xi8>
    %770 = tensor.empty() : tensor<1x15x20x128xi32>
    %771 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg56 : tensor<128xi32>) outs(%770 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %772 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_375, %expanded_377 : tensor<1x15x20x128xi8>, tensor<128x1x1x128xi8>) outs(%771 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %773 = tensor.empty() : tensor<1x15x20x128xf32>
    %774 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%772 : tensor<1x15x20x128xi32>) outs(%773 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %775 = tensor.empty() : tensor<1x15x20x128xf32>
    %776 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%774, %cst_166 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%775 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %777 = tensor.empty() : tensor<1x15x20x128xf32>
    %778 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%776, %cst_165 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%777 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %779 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_378 = linalg.transpose ins(%778 : tensor<1x15x20x128xf32>) outs(%779 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %780 = tensor.empty() : tensor<1x128x15x20xf32>
    %781 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_378 : tensor<1x128x15x20xf32>) outs(%780 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %782 = tensor.empty() : tensor<1x128x15x20xf32>
    %783 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_378, %781 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%782 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %784 = tensor.empty() : tensor<1x128x15x20xf32>
    %785 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%783, %cst_164 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%784 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %786 = tensor.empty() : tensor<1x128x15x20xf32>
    %787 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%785 : tensor<1x128x15x20xf32>) outs(%786 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %788 = tensor.empty() : tensor<1x128x15x20xi8>
    %789 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%787 : tensor<1x128x15x20xf32>) outs(%788 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %790 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_379 = linalg.transpose ins(%789 : tensor<1x128x15x20xi8>) outs(%790 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %791 = tensor.empty() : tensor<128x3x3x128xi8>
    %transposed_380 = linalg.transpose ins(%arg57 : tensor<128x128x3x3xi8>) outs(%791 : tensor<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_381 = tensor.pad %transposed_379 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x128xi8> to tensor<1x17x22x128xi8>
    %792 = tensor.empty() : tensor<1x15x20x128xi32>
    %793 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg58 : tensor<128xi32>) outs(%792 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %794 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_381, %transposed_380 : tensor<1x17x22x128xi8>, tensor<128x3x3x128xi8>) outs(%793 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %795 = tensor.empty() : tensor<1x15x20x128xf32>
    %796 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%794 : tensor<1x15x20x128xi32>) outs(%795 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %797 = tensor.empty() : tensor<1x15x20x128xf32>
    %798 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%796, %cst_163 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%797 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %799 = tensor.empty() : tensor<1x15x20x128xf32>
    %800 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%798, %cst_162 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%799 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %801 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_382 = linalg.transpose ins(%800 : tensor<1x15x20x128xf32>) outs(%801 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %802 = tensor.empty() : tensor<1x128x15x20xf32>
    %803 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_382 : tensor<1x128x15x20xf32>) outs(%802 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %804 = tensor.empty() : tensor<1x128x15x20xf32>
    %805 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_382, %803 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%804 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %806 = tensor.empty() : tensor<1x128x15x20xf32>
    %807 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%805, %cst_161 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%806 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %808 = tensor.empty() : tensor<1x128x15x20xf32>
    %809 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%807 : tensor<1x128x15x20xf32>) outs(%808 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %810 = tensor.empty() : tensor<1x128x15x20xi8>
    %811 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%809 : tensor<1x128x15x20xf32>) outs(%810 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %812 = tensor.empty() : tensor<1x128x15x20xi32>
    %813 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%768 : tensor<1x128x15x20xi8>) outs(%812 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %814 = tensor.empty() : tensor<1x128x15x20xi32>
    %815 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%813, %cst_160 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%814 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %816 = tensor.empty() : tensor<1x128x15x20xi32>
    %817 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%815, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%816 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %818 = tensor.empty() : tensor<1x128x15x20xi32>
    %819 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%811 : tensor<1x128x15x20xi8>) outs(%818 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %820 = tensor.empty() : tensor<1x128x15x20xi32>
    %821 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%819, %cst_159 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%820 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %822 = tensor.empty() : tensor<1x128x15x20xi32>
    %823 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%821, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%822 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %824 = tensor.empty() : tensor<1x128x15x20xi32>
    %825 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%817, %823 : tensor<1x128x15x20xi32>, tensor<1x128x15x20xi32>) outs(%824 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.addi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %826 = tensor.empty() : tensor<1x128x15x20xi32>
    %827 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%825, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%826 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %828 = tensor.empty() : tensor<1x128x15x20xi32>
    %829 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%827, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%828 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %830 = tensor.empty() : tensor<1x128x15x20xi8>
    %831 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%829 : tensor<1x128x15x20xi32>) outs(%830 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %832 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_383 = linalg.transpose ins(%747 : tensor<1x256x15x20xi8>) outs(%832 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_384 = tensor.collapse_shape %arg59 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_385 = tensor.expand_shape %collapsed_384 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %833 = tensor.empty() : tensor<1x15x20x128xi32>
    %834 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg60 : tensor<128xi32>) outs(%833 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %835 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_383, %expanded_385 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%834 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %836 = tensor.empty() : tensor<1x15x20x128xf32>
    %837 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%835 : tensor<1x15x20x128xi32>) outs(%836 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %838 = tensor.empty() : tensor<1x15x20x128xf32>
    %839 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%837, %cst_158 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%838 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %840 = tensor.empty() : tensor<1x15x20x128xf32>
    %841 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%839, %cst_162 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%840 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %842 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_386 = linalg.transpose ins(%841 : tensor<1x15x20x128xf32>) outs(%842 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %843 = tensor.empty() : tensor<1x128x15x20xf32>
    %844 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_386 : tensor<1x128x15x20xf32>) outs(%843 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %845 = tensor.empty() : tensor<1x128x15x20xf32>
    %846 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_386, %844 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%845 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %847 = tensor.empty() : tensor<1x128x15x20xf32>
    %848 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%846, %cst_157 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%847 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %849 = tensor.empty() : tensor<1x128x15x20xf32>
    %850 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%848 : tensor<1x128x15x20xf32>) outs(%849 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %851 = tensor.empty() : tensor<1x128x15x20xi8>
    %852 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%850 : tensor<1x128x15x20xf32>) outs(%851 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %853 = tensor.empty() : tensor<1x128x15x20xi32>
    %854 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%831 : tensor<1x128x15x20xi8>) outs(%853 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %855 = tensor.empty() : tensor<1x128x15x20xi32>
    %856 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%854, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%855 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %857 = tensor.empty() : tensor<1x128x15x20xi32>
    %858 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%856, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%857 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %859 = tensor.empty() : tensor<1x128x15x20xi8>
    %860 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%858 : tensor<1x128x15x20xi32>) outs(%859 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %861 = tensor.empty() : tensor<1x128x15x20xi32>
    %862 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%852 : tensor<1x128x15x20xi8>) outs(%861 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %863 = tensor.empty() : tensor<1x128x15x20xi32>
    %864 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%862, %cst_156 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%863 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %865 = tensor.empty() : tensor<1x128x15x20xi32>
    %866 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%864, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%865 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %867 = tensor.empty() : tensor<1x128x15x20xi32>
    %868 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%866, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%867 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %869 = tensor.empty() : tensor<1x128x15x20xi32>
    %870 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%868, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%869 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %871 = tensor.empty() : tensor<1x128x15x20xi8>
    %872 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%870 : tensor<1x128x15x20xi32>) outs(%871 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %873 = tensor.empty() : tensor<1x256x15x20xi8>
    %inserted_slice_387 = tensor.insert_slice %860 into %873[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %inserted_slice_388 = tensor.insert_slice %872 into %inserted_slice_387[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %874 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_389 = linalg.transpose ins(%inserted_slice_388 : tensor<1x256x15x20xi8>) outs(%874 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_390 = tensor.collapse_shape %arg61 [[0], [1, 2, 3]] : tensor<256x256x1x1xi8> into tensor<256x256xi8>
    %expanded_391 = tensor.expand_shape %collapsed_390 [[0, 1, 2], [3]] output_shape [256, 1, 1, 256] : tensor<256x256xi8> into tensor<256x1x1x256xi8>
    %875 = tensor.empty() : tensor<1x15x20x256xi32>
    %876 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg62 : tensor<256xi32>) outs(%875 : tensor<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x256xi32>
    %877 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_389, %expanded_391 : tensor<1x15x20x256xi8>, tensor<256x1x1x256xi8>) outs(%876 : tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xi32>
    %878 = tensor.empty() : tensor<1x15x20x256xf32>
    %879 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%877 : tensor<1x15x20x256xi32>) outs(%878 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %880 = tensor.empty() : tensor<1x15x20x256xf32>
    %881 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%879, %cst_155 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%880 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %882 = tensor.empty() : tensor<1x15x20x256xf32>
    %883 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%881, %cst_154 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%882 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %884 = tensor.empty() : tensor<1x256x15x20xf32>
    %transposed_392 = linalg.transpose ins(%883 : tensor<1x15x20x256xf32>) outs(%884 : tensor<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %885 = tensor.empty() : tensor<1x256x15x20xf32>
    %886 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_392 : tensor<1x256x15x20xf32>) outs(%885 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x256x15x20xf32>
    %887 = tensor.empty() : tensor<1x256x15x20xf32>
    %888 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_392, %886 : tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>) outs(%887 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %889 = tensor.empty() : tensor<1x256x15x20xf32>
    %890 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%888, %cst_153 : tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>) outs(%889 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %891 = tensor.empty() : tensor<1x256x15x20xf32>
    %892 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%890 : tensor<1x256x15x20xf32>) outs(%891 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x256x15x20xf32>
    %893 = tensor.empty() : tensor<1x256x15x20xi8>
    %894 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%892 : tensor<1x256x15x20xf32>) outs(%893 : tensor<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x256x15x20xi8>
    %895 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_393 = linalg.transpose ins(%894 : tensor<1x256x15x20xi8>) outs(%895 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_394 = tensor.collapse_shape %arg63 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_395 = tensor.expand_shape %collapsed_394 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %896 = tensor.empty() : tensor<1x15x20x128xi32>
    %897 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg64 : tensor<128xi32>) outs(%896 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %898 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_393, %expanded_395 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%897 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %899 = tensor.empty() : tensor<1x15x20x128xf32>
    %900 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%898 : tensor<1x15x20x128xi32>) outs(%899 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %901 = tensor.empty() : tensor<1x15x20x128xf32>
    %902 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%900, %cst_152 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%901 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %903 = tensor.empty() : tensor<1x15x20x128xf32>
    %904 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%902, %cst_151 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%903 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %905 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_396 = linalg.transpose ins(%904 : tensor<1x15x20x128xf32>) outs(%905 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %906 = tensor.empty() : tensor<1x128x15x20xf32>
    %907 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_396 : tensor<1x128x15x20xf32>) outs(%906 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %908 = tensor.empty() : tensor<1x128x15x20xf32>
    %909 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_396, %907 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%908 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %910 = tensor.empty() : tensor<1x128x15x20xf32>
    %911 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%909, %cst_150 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%910 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %912 = tensor.empty() : tensor<1x128x15x20xf32>
    %913 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%911 : tensor<1x128x15x20xf32>) outs(%912 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %914 = tensor.empty() : tensor<1x128x15x20xi8>
    %915 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%913 : tensor<1x128x15x20xf32>) outs(%914 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %916 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_397 = linalg.transpose ins(%915 : tensor<1x128x15x20xi8>) outs(%916 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_398 = tensor.pad %transposed_397 low[0, 2, 2, 0] high[0, 2, 2, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c-128_i8 : i8
    } : tensor<1x15x20x128xi8> to tensor<1x19x24x128xi8>
    %917 = tensor.empty() : tensor<1x15x20x128xi8>
    %918 = linalg.fill ins(%c-128_i8 : i8) outs(%917 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %919 = tensor.empty() : tensor<5x5xi8>
    %920 = linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%padded_398, %919 : tensor<1x19x24x128xi8>, tensor<5x5xi8>) outs(%918 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %921 = tensor.empty() : tensor<1x128x15x20xi8>
    %transposed_399 = linalg.transpose ins(%920 : tensor<1x15x20x128xi8>) outs(%921 : tensor<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %padded_400 = tensor.pad %920 low[0, 2, 2, 0] high[0, 2, 2, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c-128_i8 : i8
    } : tensor<1x15x20x128xi8> to tensor<1x19x24x128xi8>
    %922 = tensor.empty() : tensor<1x15x20x128xi8>
    %923 = linalg.fill ins(%c-128_i8 : i8) outs(%922 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %924 = tensor.empty() : tensor<5x5xi8>
    %925 = linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%padded_400, %924 : tensor<1x19x24x128xi8>, tensor<5x5xi8>) outs(%923 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %926 = tensor.empty() : tensor<1x128x15x20xi8>
    %transposed_401 = linalg.transpose ins(%925 : tensor<1x15x20x128xi8>) outs(%926 : tensor<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %padded_402 = tensor.pad %925 low[0, 2, 2, 0] high[0, 2, 2, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c-128_i8 : i8
    } : tensor<1x15x20x128xi8> to tensor<1x19x24x128xi8>
    %927 = tensor.empty() : tensor<1x15x20x128xi8>
    %928 = linalg.fill ins(%c-128_i8 : i8) outs(%927 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %929 = tensor.empty() : tensor<5x5xi8>
    %930 = linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%padded_402, %929 : tensor<1x19x24x128xi8>, tensor<5x5xi8>) outs(%928 : tensor<1x15x20x128xi8>) -> tensor<1x15x20x128xi8>
    %931 = tensor.empty() : tensor<1x128x15x20xi8>
    %transposed_403 = linalg.transpose ins(%930 : tensor<1x15x20x128xi8>) outs(%931 : tensor<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %932 = tensor.empty() : tensor<1x512x15x20xi8>
    %inserted_slice_404 = tensor.insert_slice %915 into %932[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x512x15x20xi8>
    %inserted_slice_405 = tensor.insert_slice %transposed_399 into %inserted_slice_404[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x512x15x20xi8>
    %inserted_slice_406 = tensor.insert_slice %transposed_401 into %inserted_slice_405[0, 256, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x512x15x20xi8>
    %inserted_slice_407 = tensor.insert_slice %transposed_403 into %inserted_slice_406[0, 384, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x512x15x20xi8>
    %933 = tensor.empty() : tensor<1x15x20x512xi8>
    %transposed_408 = linalg.transpose ins(%inserted_slice_407 : tensor<1x512x15x20xi8>) outs(%933 : tensor<1x15x20x512xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_409 = tensor.collapse_shape %arg65 [[0], [1, 2, 3]] : tensor<256x512x1x1xi8> into tensor<256x512xi8>
    %expanded_410 = tensor.expand_shape %collapsed_409 [[0, 1, 2], [3]] output_shape [256, 1, 1, 512] : tensor<256x512xi8> into tensor<256x1x1x512xi8>
    %934 = tensor.empty() : tensor<1x15x20x256xi32>
    %935 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg66 : tensor<256xi32>) outs(%934 : tensor<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x256xi32>
    %936 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_408, %expanded_410 : tensor<1x15x20x512xi8>, tensor<256x1x1x512xi8>) outs(%935 : tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xi32>
    %937 = tensor.empty() : tensor<1x15x20x256xf32>
    %938 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%936 : tensor<1x15x20x256xi32>) outs(%937 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %939 = tensor.empty() : tensor<1x15x20x256xf32>
    %940 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%938, %cst_149 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%939 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %941 = tensor.empty() : tensor<1x15x20x256xf32>
    %942 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%940, %cst_148 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%941 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %943 = tensor.empty() : tensor<1x256x15x20xf32>
    %transposed_411 = linalg.transpose ins(%942 : tensor<1x15x20x256xf32>) outs(%943 : tensor<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %944 = tensor.empty() : tensor<1x256x15x20xf32>
    %945 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_411 : tensor<1x256x15x20xf32>) outs(%944 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x256x15x20xf32>
    %946 = tensor.empty() : tensor<1x256x15x20xf32>
    %947 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_411, %945 : tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>) outs(%946 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %948 = tensor.empty() : tensor<1x256x15x20xf32>
    %949 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%947, %cst_147 : tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>) outs(%948 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %950 = tensor.empty() : tensor<1x256x15x20xf32>
    %951 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%949 : tensor<1x256x15x20xf32>) outs(%950 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x256x15x20xf32>
    %952 = tensor.empty() : tensor<1x256x15x20xi8>
    %953 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%951 : tensor<1x256x15x20xf32>) outs(%952 : tensor<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x256x15x20xi8>
    %954 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_412 = linalg.transpose ins(%953 : tensor<1x256x15x20xi8>) outs(%954 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_413 = tensor.collapse_shape %arg67 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_414 = tensor.expand_shape %collapsed_413 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %955 = tensor.empty() : tensor<1x15x20x128xi32>
    %956 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg68 : tensor<128xi32>) outs(%955 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %957 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_412, %expanded_414 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%956 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %958 = tensor.empty() : tensor<1x15x20x128xf32>
    %959 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%957 : tensor<1x15x20x128xi32>) outs(%958 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %960 = tensor.empty() : tensor<1x15x20x128xf32>
    %961 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%959, %cst_146 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%960 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %962 = tensor.empty() : tensor<1x15x20x128xf32>
    %963 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%961, %cst_145 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%962 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %964 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_415 = linalg.transpose ins(%963 : tensor<1x15x20x128xf32>) outs(%964 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %965 = tensor.empty() : tensor<1x128x15x20xf32>
    %966 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_415 : tensor<1x128x15x20xf32>) outs(%965 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %967 = tensor.empty() : tensor<1x128x15x20xf32>
    %968 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_415, %966 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%967 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %969 = tensor.empty() : tensor<1x128x15x20xf32>
    %970 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%968, %cst_144 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%969 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %971 = tensor.empty() : tensor<1x128x15x20xf32>
    %972 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%970 : tensor<1x128x15x20xf32>) outs(%971 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %973 = tensor.empty() : tensor<1x128x15x20xi8>
    %974 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%972 : tensor<1x128x15x20xf32>) outs(%973 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %975 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_416 = linalg.transpose ins(%974 : tensor<1x128x15x20xi8>) outs(%975 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %976 = tensor.empty() : tensor<1x30x40x128xi8>
    %977 = linalg.generic {indexing_maps = [#map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} outs(%976 : tensor<1x30x40x128xi8>) {
    ^bb0(%out: i8):
      %2069 = linalg.index 1 : index
      %2070 = linalg.index 2 : index
      %2071 = linalg.index 3 : index
      %2072 = arith.index_cast %2069 : index to i32
      %2073 = arith.index_cast %2070 : index to i32
      %2074 = arith.divsi %2072, %c2_i32 : i32
      %2075 = arith.muli %2074, %c2_i32 : i32
      %2076 = arith.subi %2072, %2075 : i32
      %2077 = arith.divsi %2073, %c2_i32 : i32
      %2078 = arith.muli %2077, %c2_i32 : i32
      %2079 = arith.subi %2073, %2078 : i32
      %2080 = arith.shli %2076, %c1_i32 : i32
      %2081 = arith.cmpi sge, %2080, %c2_i32 : i32
      %2082 = arith.extui %2081 : i1 to i32
      %2083 = arith.addi %2074, %2082 : i32
      %2084 = arith.maxsi %2083, %c0_i32 : i32
      %2085 = arith.minsi %2084, %c14_i32 : i32
      %2086 = arith.index_cast %2085 : i32 to index
      %2087 = arith.shli %2079, %c1_i32 : i32
      %2088 = arith.cmpi sge, %2087, %c2_i32 : i32
      %2089 = arith.extui %2088 : i1 to i32
      %2090 = arith.addi %2077, %2089 : i32
      %2091 = arith.maxsi %2090, %c0_i32 : i32
      %2092 = arith.minsi %2091, %c19_i32 : i32
      %2093 = arith.index_cast %2092 : i32 to index
      %extracted = tensor.extract %transposed_416[%c0, %2086, %2093, %2071] : tensor<1x15x20x128xi8>
      linalg.yield %extracted : i8
    } -> tensor<1x30x40x128xi8>
    %978 = tensor.empty() : tensor<1x128x30x40xi8>
    %transposed_417 = linalg.transpose ins(%977 : tensor<1x30x40x128xi8>) outs(%978 : tensor<1x128x30x40xi8>) permutation = [0, 3, 1, 2] 
    %979 = tensor.empty() : tensor<1x128x30x40xi32>
    %980 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_417 : tensor<1x128x30x40xi8>) outs(%979 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %981 = tensor.empty() : tensor<1x128x30x40xi32>
    %982 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%980, %cst_143 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%981 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %983 = tensor.empty() : tensor<1x128x30x40xi32>
    %984 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%982, %cst_248 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%983 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %985 = tensor.empty() : tensor<1x128x30x40xi32>
    %986 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%984, %cst_246 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%985 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %987 = tensor.empty() : tensor<1x128x30x40xi32>
    %988 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%986, %cst_245 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%987 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %989 = tensor.empty() : tensor<1x128x30x40xi8>
    %990 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%988 : tensor<1x128x30x40xi32>) outs(%989 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x30x40xi8>
    %991 = tensor.empty() : tensor<1x128x30x40xi32>
    %992 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%725 : tensor<1x128x30x40xi8>) outs(%991 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %993 = tensor.empty() : tensor<1x128x30x40xi32>
    %994 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%992, %cst_142 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%993 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %995 = tensor.empty() : tensor<1x128x30x40xi32>
    %996 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%994, %cst_248 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%995 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %997 = tensor.empty() : tensor<1x128x30x40xi32>
    %998 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%996, %cst_246 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%997 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %999 = tensor.empty() : tensor<1x128x30x40xi32>
    %1000 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%998, %cst_245 : tensor<1x128x30x40xi32>, tensor<1x1x1x1xi32>) outs(%999 : tensor<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x30x40xi32>
    %1001 = tensor.empty() : tensor<1x128x30x40xi8>
    %1002 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1000 : tensor<1x128x30x40xi32>) outs(%1001 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x30x40xi8>
    %1003 = tensor.empty() : tensor<1x256x30x40xi8>
    %inserted_slice_418 = tensor.insert_slice %990 into %1003[0, 0, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : tensor<1x128x30x40xi8> into tensor<1x256x30x40xi8>
    %inserted_slice_419 = tensor.insert_slice %1002 into %inserted_slice_418[0, 128, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : tensor<1x128x30x40xi8> into tensor<1x256x30x40xi8>
    %1004 = tensor.empty() : tensor<1x30x40x256xi8>
    %transposed_420 = linalg.transpose ins(%inserted_slice_419 : tensor<1x256x30x40xi8>) outs(%1004 : tensor<1x30x40x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_421 = tensor.collapse_shape %arg70 [[0], [1, 2, 3]] : tensor<64x256x1x1xi8> into tensor<64x256xi8>
    %expanded_422 = tensor.expand_shape %collapsed_421 [[0, 1, 2], [3]] output_shape [64, 1, 1, 256] : tensor<64x256xi8> into tensor<64x1x1x256xi8>
    %1005 = tensor.empty() : tensor<1x30x40x64xi32>
    %1006 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg71 : tensor<64xi32>) outs(%1005 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1007 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_420, %expanded_422 : tensor<1x30x40x256xi8>, tensor<64x1x1x256xi8>) outs(%1006 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1008 = tensor.empty() : tensor<1x30x40x64xf32>
    %1009 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1007 : tensor<1x30x40x64xi32>) outs(%1008 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1010 = tensor.empty() : tensor<1x30x40x64xf32>
    %1011 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1009, %cst_141 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1010 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1012 = tensor.empty() : tensor<1x30x40x64xf32>
    %1013 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1011, %cst_140 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1012 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1014 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_423 = linalg.transpose ins(%1013 : tensor<1x30x40x64xf32>) outs(%1014 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1015 = tensor.empty() : tensor<1x64x30x40xf32>
    %1016 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_423 : tensor<1x64x30x40xf32>) outs(%1015 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1017 = tensor.empty() : tensor<1x64x30x40xf32>
    %1018 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_423, %1016 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1017 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1019 = tensor.empty() : tensor<1x64x30x40xf32>
    %1020 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1018, %cst_139 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1019 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1021 = tensor.empty() : tensor<1x64x30x40xf32>
    %1022 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1020 : tensor<1x64x30x40xf32>) outs(%1021 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1023 = tensor.empty() : tensor<1x64x30x40xi8>
    %1024 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1022 : tensor<1x64x30x40xf32>) outs(%1023 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1025 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_424 = linalg.transpose ins(%1024 : tensor<1x64x30x40xi8>) outs(%1025 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_425 = tensor.collapse_shape %arg72 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_426 = tensor.expand_shape %collapsed_425 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1026 = tensor.empty() : tensor<1x30x40x64xi32>
    %1027 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg73 : tensor<64xi32>) outs(%1026 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1028 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_424, %expanded_426 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%1027 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1029 = tensor.empty() : tensor<1x30x40x64xf32>
    %1030 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1028 : tensor<1x30x40x64xi32>) outs(%1029 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1031 = tensor.empty() : tensor<1x30x40x64xf32>
    %1032 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1030, %cst_138 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1031 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1033 = tensor.empty() : tensor<1x30x40x64xf32>
    %1034 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1032, %cst_137 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1033 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1035 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_427 = linalg.transpose ins(%1034 : tensor<1x30x40x64xf32>) outs(%1035 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1036 = tensor.empty() : tensor<1x64x30x40xf32>
    %1037 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_427 : tensor<1x64x30x40xf32>) outs(%1036 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1038 = tensor.empty() : tensor<1x64x30x40xf32>
    %1039 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_427, %1037 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1038 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1040 = tensor.empty() : tensor<1x64x30x40xf32>
    %1041 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1039, %cst_136 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1040 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1042 = tensor.empty() : tensor<1x64x30x40xf32>
    %1043 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1041 : tensor<1x64x30x40xf32>) outs(%1042 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1044 = tensor.empty() : tensor<1x64x30x40xi8>
    %1045 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1043 : tensor<1x64x30x40xf32>) outs(%1044 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1046 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_428 = linalg.transpose ins(%1045 : tensor<1x64x30x40xi8>) outs(%1046 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %1047 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_429 = linalg.transpose ins(%arg74 : tensor<64x64x3x3xi8>) outs(%1047 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_430 = tensor.pad %transposed_428 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %1048 = tensor.empty() : tensor<1x30x40x64xi32>
    %1049 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg75 : tensor<64xi32>) outs(%1048 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1050 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_430, %transposed_429 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%1049 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1051 = tensor.empty() : tensor<1x30x40x64xf32>
    %1052 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1050 : tensor<1x30x40x64xi32>) outs(%1051 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1053 = tensor.empty() : tensor<1x30x40x64xf32>
    %1054 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1052, %cst_135 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1053 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1055 = tensor.empty() : tensor<1x30x40x64xf32>
    %1056 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1054, %cst_134 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1055 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1057 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_431 = linalg.transpose ins(%1056 : tensor<1x30x40x64xf32>) outs(%1057 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1058 = tensor.empty() : tensor<1x64x30x40xf32>
    %1059 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_431 : tensor<1x64x30x40xf32>) outs(%1058 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1060 = tensor.empty() : tensor<1x64x30x40xf32>
    %1061 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_431, %1059 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1060 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1062 = tensor.empty() : tensor<1x64x30x40xf32>
    %1063 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1061, %cst_133 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1062 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1064 = tensor.empty() : tensor<1x64x30x40xf32>
    %1065 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1063 : tensor<1x64x30x40xf32>) outs(%1064 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1066 = tensor.empty() : tensor<1x64x30x40xi8>
    %1067 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1065 : tensor<1x64x30x40xf32>) outs(%1066 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1068 = tensor.empty() : tensor<1x30x40x256xi8>
    %transposed_432 = linalg.transpose ins(%inserted_slice_419 : tensor<1x256x30x40xi8>) outs(%1068 : tensor<1x30x40x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_433 = tensor.collapse_shape %arg76 [[0], [1, 2, 3]] : tensor<64x256x1x1xi8> into tensor<64x256xi8>
    %expanded_434 = tensor.expand_shape %collapsed_433 [[0, 1, 2], [3]] output_shape [64, 1, 1, 256] : tensor<64x256xi8> into tensor<64x1x1x256xi8>
    %1069 = tensor.empty() : tensor<1x30x40x64xi32>
    %1070 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg77 : tensor<64xi32>) outs(%1069 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1071 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_432, %expanded_434 : tensor<1x30x40x256xi8>, tensor<64x1x1x256xi8>) outs(%1070 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1072 = tensor.empty() : tensor<1x30x40x64xf32>
    %1073 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1071 : tensor<1x30x40x64xi32>) outs(%1072 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1074 = tensor.empty() : tensor<1x30x40x64xf32>
    %1075 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1073, %cst_132 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1074 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1076 = tensor.empty() : tensor<1x30x40x64xf32>
    %1077 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1075, %cst_134 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1076 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1078 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_435 = linalg.transpose ins(%1077 : tensor<1x30x40x64xf32>) outs(%1078 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1079 = tensor.empty() : tensor<1x64x30x40xf32>
    %1080 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_435 : tensor<1x64x30x40xf32>) outs(%1079 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1081 = tensor.empty() : tensor<1x64x30x40xf32>
    %1082 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_435, %1080 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1081 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1083 = tensor.empty() : tensor<1x64x30x40xf32>
    %1084 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1082, %cst_131 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1083 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1085 = tensor.empty() : tensor<1x64x30x40xf32>
    %1086 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1084 : tensor<1x64x30x40xf32>) outs(%1085 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1087 = tensor.empty() : tensor<1x64x30x40xi8>
    %1088 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1086 : tensor<1x64x30x40xf32>) outs(%1087 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1089 = tensor.empty() : tensor<1x64x30x40xi32>
    %1090 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1067 : tensor<1x64x30x40xi8>) outs(%1089 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1091 = tensor.empty() : tensor<1x64x30x40xi32>
    %1092 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1090, %cst_130 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1091 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1093 = tensor.empty() : tensor<1x64x30x40xi32>
    %1094 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1092, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1093 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1095 = tensor.empty() : tensor<1x64x30x40xi32>
    %1096 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1094, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1095 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1097 = tensor.empty() : tensor<1x64x30x40xi32>
    %1098 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1096, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1097 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1099 = tensor.empty() : tensor<1x64x30x40xi8>
    %1100 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1098 : tensor<1x64x30x40xi32>) outs(%1099 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1101 = tensor.empty() : tensor<1x64x30x40xi32>
    %1102 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1088 : tensor<1x64x30x40xi8>) outs(%1101 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1103 = tensor.empty() : tensor<1x64x30x40xi32>
    %1104 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1102, %cst_129 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1103 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1105 = tensor.empty() : tensor<1x64x30x40xi32>
    %1106 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1104, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1105 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1107 = tensor.empty() : tensor<1x64x30x40xi32>
    %1108 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1106, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1107 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1109 = tensor.empty() : tensor<1x64x30x40xi32>
    %1110 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1108, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1109 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1111 = tensor.empty() : tensor<1x64x30x40xi8>
    %1112 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1110 : tensor<1x64x30x40xi32>) outs(%1111 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1113 = tensor.empty() : tensor<1x128x30x40xi8>
    %inserted_slice_436 = tensor.insert_slice %1100 into %1113[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %inserted_slice_437 = tensor.insert_slice %1112 into %inserted_slice_436[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %1114 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_438 = linalg.transpose ins(%inserted_slice_437 : tensor<1x128x30x40xi8>) outs(%1114 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_439 = tensor.collapse_shape %arg78 [[0], [1, 2, 3]] : tensor<128x128x1x1xi8> into tensor<128x128xi8>
    %expanded_440 = tensor.expand_shape %collapsed_439 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : tensor<128x128xi8> into tensor<128x1x1x128xi8>
    %1115 = tensor.empty() : tensor<1x30x40x128xi32>
    %1116 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg79 : tensor<128xi32>) outs(%1115 : tensor<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x128xi32>
    %1117 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_438, %expanded_440 : tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>) outs(%1116 : tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xi32>
    %1118 = tensor.empty() : tensor<1x30x40x128xf32>
    %1119 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1117 : tensor<1x30x40x128xi32>) outs(%1118 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1120 = tensor.empty() : tensor<1x30x40x128xf32>
    %1121 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1119, %cst_128 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%1120 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1122 = tensor.empty() : tensor<1x30x40x128xf32>
    %1123 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1121, %cst_127 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%1122 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1124 = tensor.empty() : tensor<1x128x30x40xf32>
    %transposed_441 = linalg.transpose ins(%1123 : tensor<1x30x40x128xf32>) outs(%1124 : tensor<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1125 = tensor.empty() : tensor<1x128x30x40xf32>
    %1126 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_441 : tensor<1x128x30x40xf32>) outs(%1125 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x30x40xf32>
    %1127 = tensor.empty() : tensor<1x128x30x40xf32>
    %1128 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_441, %1126 : tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>) outs(%1127 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %1129 = tensor.empty() : tensor<1x128x30x40xf32>
    %1130 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1128, %cst_126 : tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1129 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %1131 = tensor.empty() : tensor<1x128x30x40xf32>
    %1132 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1130 : tensor<1x128x30x40xf32>) outs(%1131 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x30x40xf32>
    %1133 = tensor.empty() : tensor<1x128x30x40xi8>
    %1134 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1132 : tensor<1x128x30x40xf32>) outs(%1133 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x30x40xi8>
    %1135 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_442 = linalg.transpose ins(%1134 : tensor<1x128x30x40xi8>) outs(%1135 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_443 = tensor.collapse_shape %arg80 [[0], [1, 2, 3]] : tensor<64x128x1x1xi8> into tensor<64x128xi8>
    %expanded_444 = tensor.expand_shape %collapsed_443 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : tensor<64x128xi8> into tensor<64x1x1x128xi8>
    %1136 = tensor.empty() : tensor<1x30x40x64xi32>
    %1137 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg81 : tensor<64xi32>) outs(%1136 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1138 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_442, %expanded_444 : tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>) outs(%1137 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1139 = tensor.empty() : tensor<1x30x40x64xf32>
    %1140 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1138 : tensor<1x30x40x64xi32>) outs(%1139 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1141 = tensor.empty() : tensor<1x30x40x64xf32>
    %1142 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1140, %cst_125 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1141 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1143 = tensor.empty() : tensor<1x30x40x64xf32>
    %1144 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1142, %cst_124 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1143 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1145 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_445 = linalg.transpose ins(%1144 : tensor<1x30x40x64xf32>) outs(%1145 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1146 = tensor.empty() : tensor<1x64x30x40xf32>
    %1147 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_445 : tensor<1x64x30x40xf32>) outs(%1146 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1148 = tensor.empty() : tensor<1x64x30x40xf32>
    %1149 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_445, %1147 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1148 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1150 = tensor.empty() : tensor<1x64x30x40xf32>
    %1151 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1149, %cst_123 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1150 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1152 = tensor.empty() : tensor<1x64x30x40xf32>
    %1153 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1151 : tensor<1x64x30x40xf32>) outs(%1152 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1154 = tensor.empty() : tensor<1x64x30x40xi8>
    %1155 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1153 : tensor<1x64x30x40xf32>) outs(%1154 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1156 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_446 = linalg.transpose ins(%1155 : tensor<1x64x30x40xi8>) outs(%1156 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %1157 = tensor.empty() : tensor<1x60x80x64xi8>
    %1158 = linalg.generic {indexing_maps = [#map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} outs(%1157 : tensor<1x60x80x64xi8>) {
    ^bb0(%out: i8):
      %2069 = linalg.index 1 : index
      %2070 = linalg.index 2 : index
      %2071 = linalg.index 3 : index
      %2072 = arith.index_cast %2069 : index to i32
      %2073 = arith.index_cast %2070 : index to i32
      %2074 = arith.divsi %2072, %c2_i32 : i32
      %2075 = arith.muli %2074, %c2_i32 : i32
      %2076 = arith.subi %2072, %2075 : i32
      %2077 = arith.divsi %2073, %c2_i32 : i32
      %2078 = arith.muli %2077, %c2_i32 : i32
      %2079 = arith.subi %2073, %2078 : i32
      %2080 = arith.shli %2076, %c1_i32 : i32
      %2081 = arith.cmpi sge, %2080, %c2_i32 : i32
      %2082 = arith.extui %2081 : i1 to i32
      %2083 = arith.addi %2074, %2082 : i32
      %2084 = arith.maxsi %2083, %c0_i32 : i32
      %2085 = arith.minsi %2084, %c29_i32 : i32
      %2086 = arith.index_cast %2085 : i32 to index
      %2087 = arith.shli %2079, %c1_i32 : i32
      %2088 = arith.cmpi sge, %2087, %c2_i32 : i32
      %2089 = arith.extui %2088 : i1 to i32
      %2090 = arith.addi %2077, %2089 : i32
      %2091 = arith.maxsi %2090, %c0_i32 : i32
      %2092 = arith.minsi %2091, %c39_i32 : i32
      %2093 = arith.index_cast %2092 : i32 to index
      %extracted = tensor.extract %transposed_446[%c0, %2086, %2093, %2071] : tensor<1x30x40x64xi8>
      linalg.yield %extracted : i8
    } -> tensor<1x60x80x64xi8>
    %1159 = tensor.empty() : tensor<1x64x60x80xi8>
    %transposed_447 = linalg.transpose ins(%1158 : tensor<1x60x80x64xi8>) outs(%1159 : tensor<1x64x60x80xi8>) permutation = [0, 3, 1, 2] 
    %1160 = tensor.empty() : tensor<1x64x60x80xi32>
    %1161 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_447 : tensor<1x64x60x80xi8>) outs(%1160 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1162 = tensor.empty() : tensor<1x64x60x80xi32>
    %1163 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1161, %cst_122 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1162 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1164 = tensor.empty() : tensor<1x64x60x80xi32>
    %1165 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1163, %cst_248 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1164 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1166 = tensor.empty() : tensor<1x64x60x80xi32>
    %1167 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1165, %cst_246 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1166 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1168 = tensor.empty() : tensor<1x64x60x80xi32>
    %1169 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1167, %cst_245 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1168 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1170 = tensor.empty() : tensor<1x64x60x80xi8>
    %1171 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1169 : tensor<1x64x60x80xi32>) outs(%1170 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x60x80xi8>
    %1172 = tensor.empty() : tensor<1x64x60x80xi32>
    %1173 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%430 : tensor<1x64x60x80xi8>) outs(%1172 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1174 = tensor.empty() : tensor<1x64x60x80xi32>
    %1175 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1173, %cst_121 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1174 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1176 = tensor.empty() : tensor<1x64x60x80xi32>
    %1177 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1175, %cst_248 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1176 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1178 = tensor.empty() : tensor<1x64x60x80xi32>
    %1179 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1177, %cst_246 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1178 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1180 = tensor.empty() : tensor<1x64x60x80xi32>
    %1181 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1179, %cst_245 : tensor<1x64x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1180 : tensor<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x60x80xi32>
    %1182 = tensor.empty() : tensor<1x64x60x80xi8>
    %1183 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1181 : tensor<1x64x60x80xi32>) outs(%1182 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x60x80xi8>
    %1184 = tensor.empty() : tensor<1x128x60x80xi8>
    %inserted_slice_448 = tensor.insert_slice %1171 into %1184[0, 0, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : tensor<1x64x60x80xi8> into tensor<1x128x60x80xi8>
    %inserted_slice_449 = tensor.insert_slice %1183 into %inserted_slice_448[0, 64, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : tensor<1x64x60x80xi8> into tensor<1x128x60x80xi8>
    %1185 = tensor.empty() : tensor<1x60x80x128xi8>
    %transposed_450 = linalg.transpose ins(%inserted_slice_449 : tensor<1x128x60x80xi8>) outs(%1185 : tensor<1x60x80x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_451 = tensor.collapse_shape %arg83 [[0], [1, 2, 3]] : tensor<32x128x1x1xi8> into tensor<32x128xi8>
    %expanded_452 = tensor.expand_shape %collapsed_451 [[0, 1, 2], [3]] output_shape [32, 1, 1, 128] : tensor<32x128xi8> into tensor<32x1x1x128xi8>
    %1186 = tensor.empty() : tensor<1x60x80x32xi32>
    %1187 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg84 : tensor<32xi32>) outs(%1186 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %1188 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_450, %expanded_452 : tensor<1x60x80x128xi8>, tensor<32x1x1x128xi8>) outs(%1187 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %1189 = tensor.empty() : tensor<1x60x80x32xf32>
    %1190 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1188 : tensor<1x60x80x32xi32>) outs(%1189 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1191 = tensor.empty() : tensor<1x60x80x32xf32>
    %1192 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1190, %cst_120 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1191 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1193 = tensor.empty() : tensor<1x60x80x32xf32>
    %1194 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1192, %cst_119 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1193 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1195 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_453 = linalg.transpose ins(%1194 : tensor<1x60x80x32xf32>) outs(%1195 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1196 = tensor.empty() : tensor<1x32x60x80xf32>
    %1197 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_453 : tensor<1x32x60x80xf32>) outs(%1196 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %1198 = tensor.empty() : tensor<1x32x60x80xf32>
    %1199 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_453, %1197 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%1198 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1200 = tensor.empty() : tensor<1x32x60x80xf32>
    %1201 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1199, %cst_118 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1200 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1202 = tensor.empty() : tensor<1x32x60x80xf32>
    %1203 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1201 : tensor<1x32x60x80xf32>) outs(%1202 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %1204 = tensor.empty() : tensor<1x32x60x80xi8>
    %1205 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1203 : tensor<1x32x60x80xf32>) outs(%1204 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %1206 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_454 = linalg.transpose ins(%1205 : tensor<1x32x60x80xi8>) outs(%1206 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_455 = tensor.collapse_shape %arg85 [[0], [1, 2, 3]] : tensor<32x32x1x1xi8> into tensor<32x32xi8>
    %expanded_456 = tensor.expand_shape %collapsed_455 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : tensor<32x32xi8> into tensor<32x1x1x32xi8>
    %1207 = tensor.empty() : tensor<1x60x80x32xi32>
    %1208 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg86 : tensor<32xi32>) outs(%1207 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %1209 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_454, %expanded_456 : tensor<1x60x80x32xi8>, tensor<32x1x1x32xi8>) outs(%1208 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %1210 = tensor.empty() : tensor<1x60x80x32xf32>
    %1211 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1209 : tensor<1x60x80x32xi32>) outs(%1210 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1212 = tensor.empty() : tensor<1x60x80x32xf32>
    %1213 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1211, %cst_117 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1212 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1214 = tensor.empty() : tensor<1x60x80x32xf32>
    %1215 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1213, %cst_116 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1214 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1216 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_457 = linalg.transpose ins(%1215 : tensor<1x60x80x32xf32>) outs(%1216 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1217 = tensor.empty() : tensor<1x32x60x80xf32>
    %1218 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_457 : tensor<1x32x60x80xf32>) outs(%1217 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %1219 = tensor.empty() : tensor<1x32x60x80xf32>
    %1220 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_457, %1218 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%1219 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1221 = tensor.empty() : tensor<1x32x60x80xf32>
    %1222 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1220, %cst_115 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1221 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1223 = tensor.empty() : tensor<1x32x60x80xf32>
    %1224 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1222 : tensor<1x32x60x80xf32>) outs(%1223 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %1225 = tensor.empty() : tensor<1x32x60x80xi8>
    %1226 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1224 : tensor<1x32x60x80xf32>) outs(%1225 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %1227 = tensor.empty() : tensor<1x60x80x32xi8>
    %transposed_458 = linalg.transpose ins(%1226 : tensor<1x32x60x80xi8>) outs(%1227 : tensor<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %1228 = tensor.empty() : tensor<32x3x3x32xi8>
    %transposed_459 = linalg.transpose ins(%arg87 : tensor<32x32x3x3xi8>) outs(%1228 : tensor<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %padded_460 = tensor.pad %transposed_458 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x32xi8> to tensor<1x62x82x32xi8>
    %1229 = tensor.empty() : tensor<1x60x80x32xi32>
    %1230 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg88 : tensor<32xi32>) outs(%1229 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %1231 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_460, %transposed_459 : tensor<1x62x82x32xi8>, tensor<32x3x3x32xi8>) outs(%1230 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %1232 = tensor.empty() : tensor<1x60x80x32xf32>
    %1233 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1231 : tensor<1x60x80x32xi32>) outs(%1232 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1234 = tensor.empty() : tensor<1x60x80x32xf32>
    %1235 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1233, %cst_114 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1234 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1236 = tensor.empty() : tensor<1x60x80x32xf32>
    %1237 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1235, %cst_113 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1236 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1238 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_461 = linalg.transpose ins(%1237 : tensor<1x60x80x32xf32>) outs(%1238 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1239 = tensor.empty() : tensor<1x32x60x80xf32>
    %1240 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_461 : tensor<1x32x60x80xf32>) outs(%1239 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %1241 = tensor.empty() : tensor<1x32x60x80xf32>
    %1242 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_461, %1240 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%1241 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1243 = tensor.empty() : tensor<1x32x60x80xf32>
    %1244 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1242, %cst_112 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1243 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1245 = tensor.empty() : tensor<1x32x60x80xf32>
    %1246 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1244 : tensor<1x32x60x80xf32>) outs(%1245 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %1247 = tensor.empty() : tensor<1x32x60x80xi8>
    %1248 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1246 : tensor<1x32x60x80xf32>) outs(%1247 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %1249 = tensor.empty() : tensor<1x60x80x128xi8>
    %transposed_462 = linalg.transpose ins(%inserted_slice_449 : tensor<1x128x60x80xi8>) outs(%1249 : tensor<1x60x80x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_463 = tensor.collapse_shape %arg89 [[0], [1, 2, 3]] : tensor<32x128x1x1xi8> into tensor<32x128xi8>
    %expanded_464 = tensor.expand_shape %collapsed_463 [[0, 1, 2], [3]] output_shape [32, 1, 1, 128] : tensor<32x128xi8> into tensor<32x1x1x128xi8>
    %1250 = tensor.empty() : tensor<1x60x80x32xi32>
    %1251 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg90 : tensor<32xi32>) outs(%1250 : tensor<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x32xi32>
    %1252 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_462, %expanded_464 : tensor<1x60x80x128xi8>, tensor<32x1x1x128xi8>) outs(%1251 : tensor<1x60x80x32xi32>) -> tensor<1x60x80x32xi32>
    %1253 = tensor.empty() : tensor<1x60x80x32xf32>
    %1254 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1252 : tensor<1x60x80x32xi32>) outs(%1253 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1255 = tensor.empty() : tensor<1x60x80x32xf32>
    %1256 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1254, %cst_111 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1255 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1257 = tensor.empty() : tensor<1x60x80x32xf32>
    %1258 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1256, %cst_113 : tensor<1x60x80x32xf32>, tensor<1x1x1x1xf32>) outs(%1257 : tensor<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x32xf32>
    %1259 = tensor.empty() : tensor<1x32x60x80xf32>
    %transposed_465 = linalg.transpose ins(%1258 : tensor<1x60x80x32xf32>) outs(%1259 : tensor<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1260 = tensor.empty() : tensor<1x32x60x80xf32>
    %1261 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_465 : tensor<1x32x60x80xf32>) outs(%1260 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x32x60x80xf32>
    %1262 = tensor.empty() : tensor<1x32x60x80xf32>
    %1263 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_465, %1261 : tensor<1x32x60x80xf32>, tensor<1x32x60x80xf32>) outs(%1262 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1264 = tensor.empty() : tensor<1x32x60x80xf32>
    %1265 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1263, %cst_110 : tensor<1x32x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1264 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x32x60x80xf32>
    %1266 = tensor.empty() : tensor<1x32x60x80xf32>
    %1267 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1265 : tensor<1x32x60x80xf32>) outs(%1266 : tensor<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x32x60x80xf32>
    %1268 = tensor.empty() : tensor<1x32x60x80xi8>
    %1269 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1267 : tensor<1x32x60x80xf32>) outs(%1268 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x32x60x80xi8>
    %1270 = tensor.empty() : tensor<1x32x60x80xi32>
    %1271 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1248 : tensor<1x32x60x80xi8>) outs(%1270 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1272 = tensor.empty() : tensor<1x32x60x80xi32>
    %1273 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1271, %cst_109 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1272 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1274 = tensor.empty() : tensor<1x32x60x80xi32>
    %1275 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1273, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1274 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1276 = tensor.empty() : tensor<1x32x60x80xi32>
    %1277 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1275, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1276 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1278 = tensor.empty() : tensor<1x32x60x80xi32>
    %1279 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1277, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1278 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1280 = tensor.empty() : tensor<1x32x60x80xi8>
    %1281 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1279 : tensor<1x32x60x80xi32>) outs(%1280 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %1282 = tensor.empty() : tensor<1x32x60x80xi32>
    %1283 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1269 : tensor<1x32x60x80xi8>) outs(%1282 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1284 = tensor.empty() : tensor<1x32x60x80xi32>
    %1285 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1283, %cst_108 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1284 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1286 = tensor.empty() : tensor<1x32x60x80xi32>
    %1287 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1285, %cst_248 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1286 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1288 = tensor.empty() : tensor<1x32x60x80xi32>
    %1289 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1287, %cst_246 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1288 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1290 = tensor.empty() : tensor<1x32x60x80xi32>
    %1291 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1289, %cst_245 : tensor<1x32x60x80xi32>, tensor<1x1x1x1xi32>) outs(%1290 : tensor<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x32x60x80xi32>
    %1292 = tensor.empty() : tensor<1x32x60x80xi8>
    %1293 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1291 : tensor<1x32x60x80xi32>) outs(%1292 : tensor<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x32x60x80xi8>
    %1294 = tensor.empty() : tensor<1x64x60x80xi8>
    %inserted_slice_466 = tensor.insert_slice %1281 into %1294[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : tensor<1x32x60x80xi8> into tensor<1x64x60x80xi8>
    %inserted_slice_467 = tensor.insert_slice %1293 into %inserted_slice_466[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : tensor<1x32x60x80xi8> into tensor<1x64x60x80xi8>
    %1295 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_468 = linalg.transpose ins(%inserted_slice_467 : tensor<1x64x60x80xi8>) outs(%1295 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_469 = tensor.collapse_shape %arg91 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_470 = tensor.expand_shape %collapsed_469 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1296 = tensor.empty() : tensor<1x60x80x64xi32>
    %1297 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg92 : tensor<64xi32>) outs(%1296 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %1298 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_468, %expanded_470 : tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>) outs(%1297 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %1299 = tensor.empty() : tensor<1x60x80x64xf32>
    %1300 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1298 : tensor<1x60x80x64xi32>) outs(%1299 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1301 = tensor.empty() : tensor<1x60x80x64xf32>
    %1302 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1300, %cst_107 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1301 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1303 = tensor.empty() : tensor<1x60x80x64xf32>
    %1304 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1302, %cst_106 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1303 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1305 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_471 = linalg.transpose ins(%1304 : tensor<1x60x80x64xf32>) outs(%1305 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1306 = tensor.empty() : tensor<1x64x60x80xf32>
    %1307 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_471 : tensor<1x64x60x80xf32>) outs(%1306 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x60x80xf32>
    %1308 = tensor.empty() : tensor<1x64x60x80xf32>
    %1309 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_471, %1307 : tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>) outs(%1308 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1310 = tensor.empty() : tensor<1x64x60x80xf32>
    %1311 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1309, %cst_105 : tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1310 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1312 = tensor.empty() : tensor<1x64x60x80xf32>
    %1313 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1311 : tensor<1x64x60x80xf32>) outs(%1312 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x60x80xf32>
    %1314 = tensor.empty() : tensor<1x64x60x80xi8>
    %1315 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1313 : tensor<1x64x60x80xf32>) outs(%1314 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x60x80xi8>
    %1316 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_472 = linalg.transpose ins(%1315 : tensor<1x64x60x80xi8>) outs(%1316 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %1317 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_473 = linalg.transpose ins(%arg93 : tensor<64x64x3x3xi8>) outs(%1317 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_474 = tensor.pad %transposed_472 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x64xi8> to tensor<1x61x81x64xi8>
    %1318 = tensor.empty() : tensor<1x30x40x64xi32>
    %1319 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg94 : tensor<64xi32>) outs(%1318 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1320 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_474, %transposed_473 : tensor<1x61x81x64xi8>, tensor<64x3x3x64xi8>) outs(%1319 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1321 = tensor.empty() : tensor<1x30x40x64xf32>
    %1322 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1320 : tensor<1x30x40x64xi32>) outs(%1321 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1323 = tensor.empty() : tensor<1x30x40x64xf32>
    %1324 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1322, %cst_104 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1323 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1325 = tensor.empty() : tensor<1x30x40x64xf32>
    %1326 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1324, %cst_103 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1325 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1327 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_475 = linalg.transpose ins(%1326 : tensor<1x30x40x64xf32>) outs(%1327 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1328 = tensor.empty() : tensor<1x64x30x40xf32>
    %1329 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_475 : tensor<1x64x30x40xf32>) outs(%1328 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1330 = tensor.empty() : tensor<1x64x30x40xf32>
    %1331 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_475, %1329 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1330 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1332 = tensor.empty() : tensor<1x64x30x40xf32>
    %1333 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1331, %cst_102 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1332 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1334 = tensor.empty() : tensor<1x64x30x40xf32>
    %1335 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1333 : tensor<1x64x30x40xf32>) outs(%1334 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1336 = tensor.empty() : tensor<1x64x30x40xi8>
    %1337 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1335 : tensor<1x64x30x40xf32>) outs(%1336 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1338 = tensor.empty() : tensor<1x64x30x40xi32>
    %1339 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1337 : tensor<1x64x30x40xi8>) outs(%1338 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1340 = tensor.empty() : tensor<1x64x30x40xi32>
    %1341 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1339, %cst_101 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1340 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1342 = tensor.empty() : tensor<1x64x30x40xi32>
    %1343 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1341, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1342 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1344 = tensor.empty() : tensor<1x64x30x40xi32>
    %1345 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1343, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1344 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1346 = tensor.empty() : tensor<1x64x30x40xi32>
    %1347 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1345, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1346 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1348 = tensor.empty() : tensor<1x64x30x40xi8>
    %1349 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1347 : tensor<1x64x30x40xi32>) outs(%1348 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1350 = tensor.empty() : tensor<1x64x30x40xi32>
    %1351 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1155 : tensor<1x64x30x40xi8>) outs(%1350 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1352 = tensor.empty() : tensor<1x64x30x40xi32>
    %1353 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1351, %cst_100 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1352 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1354 = tensor.empty() : tensor<1x64x30x40xi32>
    %1355 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1353, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1354 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1356 = tensor.empty() : tensor<1x64x30x40xi32>
    %1357 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1355, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1356 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1358 = tensor.empty() : tensor<1x64x30x40xi32>
    %1359 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1357, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1358 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1360 = tensor.empty() : tensor<1x64x30x40xi8>
    %1361 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1359 : tensor<1x64x30x40xi32>) outs(%1360 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1362 = tensor.empty() : tensor<1x128x30x40xi8>
    %inserted_slice_476 = tensor.insert_slice %1349 into %1362[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %inserted_slice_477 = tensor.insert_slice %1361 into %inserted_slice_476[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %1363 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_478 = linalg.transpose ins(%inserted_slice_477 : tensor<1x128x30x40xi8>) outs(%1363 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_479 = tensor.collapse_shape %arg95 [[0], [1, 2, 3]] : tensor<64x128x1x1xi8> into tensor<64x128xi8>
    %expanded_480 = tensor.expand_shape %collapsed_479 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : tensor<64x128xi8> into tensor<64x1x1x128xi8>
    %1364 = tensor.empty() : tensor<1x30x40x64xi32>
    %1365 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg96 : tensor<64xi32>) outs(%1364 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1366 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_478, %expanded_480 : tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>) outs(%1365 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1367 = tensor.empty() : tensor<1x30x40x64xf32>
    %1368 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1366 : tensor<1x30x40x64xi32>) outs(%1367 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1369 = tensor.empty() : tensor<1x30x40x64xf32>
    %1370 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1368, %cst_99 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1369 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1371 = tensor.empty() : tensor<1x30x40x64xf32>
    %1372 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1370, %cst_98 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1371 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1373 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_481 = linalg.transpose ins(%1372 : tensor<1x30x40x64xf32>) outs(%1373 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1374 = tensor.empty() : tensor<1x64x30x40xf32>
    %1375 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_481 : tensor<1x64x30x40xf32>) outs(%1374 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1376 = tensor.empty() : tensor<1x64x30x40xf32>
    %1377 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_481, %1375 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1376 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1378 = tensor.empty() : tensor<1x64x30x40xf32>
    %1379 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1377, %cst_97 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1378 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1380 = tensor.empty() : tensor<1x64x30x40xf32>
    %1381 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1379 : tensor<1x64x30x40xf32>) outs(%1380 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1382 = tensor.empty() : tensor<1x64x30x40xi8>
    %1383 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1381 : tensor<1x64x30x40xf32>) outs(%1382 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1384 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_482 = linalg.transpose ins(%1383 : tensor<1x64x30x40xi8>) outs(%1384 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_483 = tensor.collapse_shape %arg97 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_484 = tensor.expand_shape %collapsed_483 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1385 = tensor.empty() : tensor<1x30x40x64xi32>
    %1386 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg98 : tensor<64xi32>) outs(%1385 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1387 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_482, %expanded_484 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%1386 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1388 = tensor.empty() : tensor<1x30x40x64xf32>
    %1389 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1387 : tensor<1x30x40x64xi32>) outs(%1388 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1390 = tensor.empty() : tensor<1x30x40x64xf32>
    %1391 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1389, %cst_96 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1390 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1392 = tensor.empty() : tensor<1x30x40x64xf32>
    %1393 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1391, %cst_95 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1392 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1394 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_485 = linalg.transpose ins(%1393 : tensor<1x30x40x64xf32>) outs(%1394 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1395 = tensor.empty() : tensor<1x64x30x40xf32>
    %1396 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_485 : tensor<1x64x30x40xf32>) outs(%1395 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1397 = tensor.empty() : tensor<1x64x30x40xf32>
    %1398 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_485, %1396 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1397 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1399 = tensor.empty() : tensor<1x64x30x40xf32>
    %1400 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1398, %cst_94 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1399 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1401 = tensor.empty() : tensor<1x64x30x40xf32>
    %1402 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1400 : tensor<1x64x30x40xf32>) outs(%1401 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1403 = tensor.empty() : tensor<1x64x30x40xi8>
    %1404 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1402 : tensor<1x64x30x40xf32>) outs(%1403 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1405 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_486 = linalg.transpose ins(%1404 : tensor<1x64x30x40xi8>) outs(%1405 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %1406 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_487 = linalg.transpose ins(%arg99 : tensor<64x64x3x3xi8>) outs(%1406 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_488 = tensor.pad %transposed_486 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %1407 = tensor.empty() : tensor<1x30x40x64xi32>
    %1408 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg100 : tensor<64xi32>) outs(%1407 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1409 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_488, %transposed_487 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%1408 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1410 = tensor.empty() : tensor<1x30x40x64xf32>
    %1411 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1409 : tensor<1x30x40x64xi32>) outs(%1410 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1412 = tensor.empty() : tensor<1x30x40x64xf32>
    %1413 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1411, %cst_93 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1412 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1414 = tensor.empty() : tensor<1x30x40x64xf32>
    %1415 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1413, %cst_92 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1414 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1416 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_489 = linalg.transpose ins(%1415 : tensor<1x30x40x64xf32>) outs(%1416 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1417 = tensor.empty() : tensor<1x64x30x40xf32>
    %1418 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_489 : tensor<1x64x30x40xf32>) outs(%1417 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1419 = tensor.empty() : tensor<1x64x30x40xf32>
    %1420 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_489, %1418 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1419 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1421 = tensor.empty() : tensor<1x64x30x40xf32>
    %1422 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1420, %cst_91 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1421 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1423 = tensor.empty() : tensor<1x64x30x40xf32>
    %1424 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1422 : tensor<1x64x30x40xf32>) outs(%1423 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1425 = tensor.empty() : tensor<1x64x30x40xi8>
    %1426 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1424 : tensor<1x64x30x40xf32>) outs(%1425 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1427 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_490 = linalg.transpose ins(%inserted_slice_477 : tensor<1x128x30x40xi8>) outs(%1427 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_491 = tensor.collapse_shape %arg101 [[0], [1, 2, 3]] : tensor<64x128x1x1xi8> into tensor<64x128xi8>
    %expanded_492 = tensor.expand_shape %collapsed_491 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : tensor<64x128xi8> into tensor<64x1x1x128xi8>
    %1428 = tensor.empty() : tensor<1x30x40x64xi32>
    %1429 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg102 : tensor<64xi32>) outs(%1428 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1430 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_490, %expanded_492 : tensor<1x30x40x128xi8>, tensor<64x1x1x128xi8>) outs(%1429 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1431 = tensor.empty() : tensor<1x30x40x64xf32>
    %1432 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1430 : tensor<1x30x40x64xi32>) outs(%1431 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1433 = tensor.empty() : tensor<1x30x40x64xf32>
    %1434 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1432, %cst_90 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1433 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1435 = tensor.empty() : tensor<1x30x40x64xf32>
    %1436 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1434, %cst_92 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1435 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1437 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_493 = linalg.transpose ins(%1436 : tensor<1x30x40x64xf32>) outs(%1437 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1438 = tensor.empty() : tensor<1x64x30x40xf32>
    %1439 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_493 : tensor<1x64x30x40xf32>) outs(%1438 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1440 = tensor.empty() : tensor<1x64x30x40xf32>
    %1441 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_493, %1439 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1440 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1442 = tensor.empty() : tensor<1x64x30x40xf32>
    %1443 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1441, %cst_89 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1442 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1444 = tensor.empty() : tensor<1x64x30x40xf32>
    %1445 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1443 : tensor<1x64x30x40xf32>) outs(%1444 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1446 = tensor.empty() : tensor<1x64x30x40xi8>
    %1447 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1445 : tensor<1x64x30x40xf32>) outs(%1446 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1448 = tensor.empty() : tensor<1x64x30x40xi32>
    %1449 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1426 : tensor<1x64x30x40xi8>) outs(%1448 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1450 = tensor.empty() : tensor<1x64x30x40xi32>
    %1451 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1449, %cst_88 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1450 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1452 = tensor.empty() : tensor<1x64x30x40xi32>
    %1453 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1451, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1452 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1454 = tensor.empty() : tensor<1x64x30x40xi32>
    %1455 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1453, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1454 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1456 = tensor.empty() : tensor<1x64x30x40xi32>
    %1457 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1455, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1456 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1458 = tensor.empty() : tensor<1x64x30x40xi8>
    %1459 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1457 : tensor<1x64x30x40xi32>) outs(%1458 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1460 = tensor.empty() : tensor<1x64x30x40xi32>
    %1461 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1447 : tensor<1x64x30x40xi8>) outs(%1460 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1462 = tensor.empty() : tensor<1x64x30x40xi32>
    %1463 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1461, %cst_87 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1462 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1464 = tensor.empty() : tensor<1x64x30x40xi32>
    %1465 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1463, %cst_248 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1464 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1466 = tensor.empty() : tensor<1x64x30x40xi32>
    %1467 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1465, %cst_246 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1466 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1468 = tensor.empty() : tensor<1x64x30x40xi32>
    %1469 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1467, %cst_245 : tensor<1x64x30x40xi32>, tensor<1x1x1x1xi32>) outs(%1468 : tensor<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x64x30x40xi32>
    %1470 = tensor.empty() : tensor<1x64x30x40xi8>
    %1471 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1469 : tensor<1x64x30x40xi32>) outs(%1470 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x64x30x40xi8>
    %1472 = tensor.empty() : tensor<1x128x30x40xi8>
    %inserted_slice_494 = tensor.insert_slice %1459 into %1472[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %inserted_slice_495 = tensor.insert_slice %1471 into %inserted_slice_494[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : tensor<1x64x30x40xi8> into tensor<1x128x30x40xi8>
    %1473 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_496 = linalg.transpose ins(%inserted_slice_495 : tensor<1x128x30x40xi8>) outs(%1473 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_497 = tensor.collapse_shape %arg103 [[0], [1, 2, 3]] : tensor<128x128x1x1xi8> into tensor<128x128xi8>
    %expanded_498 = tensor.expand_shape %collapsed_497 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : tensor<128x128xi8> into tensor<128x1x1x128xi8>
    %1474 = tensor.empty() : tensor<1x30x40x128xi32>
    %1475 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg104 : tensor<128xi32>) outs(%1474 : tensor<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x128xi32>
    %1476 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_496, %expanded_498 : tensor<1x30x40x128xi8>, tensor<128x1x1x128xi8>) outs(%1475 : tensor<1x30x40x128xi32>) -> tensor<1x30x40x128xi32>
    %1477 = tensor.empty() : tensor<1x30x40x128xf32>
    %1478 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1476 : tensor<1x30x40x128xi32>) outs(%1477 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1479 = tensor.empty() : tensor<1x30x40x128xf32>
    %1480 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1478, %cst_86 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%1479 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1481 = tensor.empty() : tensor<1x30x40x128xf32>
    %1482 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1480, %cst_85 : tensor<1x30x40x128xf32>, tensor<1x1x1x1xf32>) outs(%1481 : tensor<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x128xf32>
    %1483 = tensor.empty() : tensor<1x128x30x40xf32>
    %transposed_499 = linalg.transpose ins(%1482 : tensor<1x30x40x128xf32>) outs(%1483 : tensor<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1484 = tensor.empty() : tensor<1x128x30x40xf32>
    %1485 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_499 : tensor<1x128x30x40xf32>) outs(%1484 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x30x40xf32>
    %1486 = tensor.empty() : tensor<1x128x30x40xf32>
    %1487 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_499, %1485 : tensor<1x128x30x40xf32>, tensor<1x128x30x40xf32>) outs(%1486 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %1488 = tensor.empty() : tensor<1x128x30x40xf32>
    %1489 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1487, %cst_84 : tensor<1x128x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1488 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x30x40xf32>
    %1490 = tensor.empty() : tensor<1x128x30x40xf32>
    %1491 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1489 : tensor<1x128x30x40xf32>) outs(%1490 : tensor<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x30x40xf32>
    %1492 = tensor.empty() : tensor<1x128x30x40xi8>
    %1493 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1491 : tensor<1x128x30x40xf32>) outs(%1492 : tensor<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x30x40xi8>
    %1494 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_500 = linalg.transpose ins(%1493 : tensor<1x128x30x40xi8>) outs(%1494 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %1495 = tensor.empty() : tensor<128x3x3x128xi8>
    %transposed_501 = linalg.transpose ins(%arg105 : tensor<128x128x3x3xi8>) outs(%1495 : tensor<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_502 = tensor.pad %transposed_500 low[0, 1, 1, 0] high[0, 0, 0, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x128xi8> to tensor<1x31x41x128xi8>
    %1496 = tensor.empty() : tensor<1x15x20x128xi32>
    %1497 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg106 : tensor<128xi32>) outs(%1496 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %1498 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%padded_502, %transposed_501 : tensor<1x31x41x128xi8>, tensor<128x3x3x128xi8>) outs(%1497 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %1499 = tensor.empty() : tensor<1x15x20x128xf32>
    %1500 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1498 : tensor<1x15x20x128xi32>) outs(%1499 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1501 = tensor.empty() : tensor<1x15x20x128xf32>
    %1502 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1500, %cst_83 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1501 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1503 = tensor.empty() : tensor<1x15x20x128xf32>
    %1504 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1502, %cst_145 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1503 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1505 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_503 = linalg.transpose ins(%1504 : tensor<1x15x20x128xf32>) outs(%1505 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1506 = tensor.empty() : tensor<1x128x15x20xf32>
    %1507 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_503 : tensor<1x128x15x20xf32>) outs(%1506 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %1508 = tensor.empty() : tensor<1x128x15x20xf32>
    %1509 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_503, %1507 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%1508 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1510 = tensor.empty() : tensor<1x128x15x20xf32>
    %1511 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1509, %cst_82 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1510 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1512 = tensor.empty() : tensor<1x128x15x20xf32>
    %1513 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1511 : tensor<1x128x15x20xf32>) outs(%1512 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %1514 = tensor.empty() : tensor<1x128x15x20xi8>
    %1515 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1513 : tensor<1x128x15x20xf32>) outs(%1514 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %1516 = tensor.empty() : tensor<1x128x15x20xi32>
    %1517 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1515 : tensor<1x128x15x20xi8>) outs(%1516 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1518 = tensor.empty() : tensor<1x128x15x20xi32>
    %1519 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1517, %cst_81 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1518 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1520 = tensor.empty() : tensor<1x128x15x20xi32>
    %1521 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1519, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1520 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1522 = tensor.empty() : tensor<1x128x15x20xi32>
    %1523 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1521, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1522 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1524 = tensor.empty() : tensor<1x128x15x20xi32>
    %1525 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1523, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1524 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1526 = tensor.empty() : tensor<1x128x15x20xi8>
    %1527 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1525 : tensor<1x128x15x20xi32>) outs(%1526 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %1528 = tensor.empty() : tensor<1x128x15x20xi32>
    %1529 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%974 : tensor<1x128x15x20xi8>) outs(%1528 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1530 = tensor.empty() : tensor<1x128x15x20xi32>
    %1531 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1529, %cst_80 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1530 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1532 = tensor.empty() : tensor<1x128x15x20xi32>
    %1533 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1531, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1532 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1534 = tensor.empty() : tensor<1x128x15x20xi32>
    %1535 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1533, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1534 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1536 = tensor.empty() : tensor<1x128x15x20xi32>
    %1537 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1535, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1536 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1538 = tensor.empty() : tensor<1x128x15x20xi8>
    %1539 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1537 : tensor<1x128x15x20xi32>) outs(%1538 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %1540 = tensor.empty() : tensor<1x256x15x20xi8>
    %inserted_slice_504 = tensor.insert_slice %1527 into %1540[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %inserted_slice_505 = tensor.insert_slice %1539 into %inserted_slice_504[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %1541 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_506 = linalg.transpose ins(%inserted_slice_505 : tensor<1x256x15x20xi8>) outs(%1541 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_507 = tensor.collapse_shape %arg107 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_508 = tensor.expand_shape %collapsed_507 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %1542 = tensor.empty() : tensor<1x15x20x128xi32>
    %1543 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg108 : tensor<128xi32>) outs(%1542 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %1544 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_506, %expanded_508 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%1543 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %1545 = tensor.empty() : tensor<1x15x20x128xf32>
    %1546 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1544 : tensor<1x15x20x128xi32>) outs(%1545 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1547 = tensor.empty() : tensor<1x15x20x128xf32>
    %1548 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1546, %cst_79 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1547 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1549 = tensor.empty() : tensor<1x15x20x128xf32>
    %1550 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1548, %cst_78 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1549 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1551 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_509 = linalg.transpose ins(%1550 : tensor<1x15x20x128xf32>) outs(%1551 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1552 = tensor.empty() : tensor<1x128x15x20xf32>
    %1553 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_509 : tensor<1x128x15x20xf32>) outs(%1552 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %1554 = tensor.empty() : tensor<1x128x15x20xf32>
    %1555 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_509, %1553 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%1554 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1556 = tensor.empty() : tensor<1x128x15x20xf32>
    %1557 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1555, %cst_77 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1556 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1558 = tensor.empty() : tensor<1x128x15x20xf32>
    %1559 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1557 : tensor<1x128x15x20xf32>) outs(%1558 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %1560 = tensor.empty() : tensor<1x128x15x20xi8>
    %1561 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1559 : tensor<1x128x15x20xf32>) outs(%1560 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %1562 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_510 = linalg.transpose ins(%1561 : tensor<1x128x15x20xi8>) outs(%1562 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_511 = tensor.collapse_shape %arg109 [[0], [1, 2, 3]] : tensor<128x128x1x1xi8> into tensor<128x128xi8>
    %expanded_512 = tensor.expand_shape %collapsed_511 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : tensor<128x128xi8> into tensor<128x1x1x128xi8>
    %1563 = tensor.empty() : tensor<1x15x20x128xi32>
    %1564 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg110 : tensor<128xi32>) outs(%1563 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %1565 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_510, %expanded_512 : tensor<1x15x20x128xi8>, tensor<128x1x1x128xi8>) outs(%1564 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %1566 = tensor.empty() : tensor<1x15x20x128xf32>
    %1567 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1565 : tensor<1x15x20x128xi32>) outs(%1566 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1568 = tensor.empty() : tensor<1x15x20x128xf32>
    %1569 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1567, %cst_76 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1568 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1570 = tensor.empty() : tensor<1x15x20x128xf32>
    %1571 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1569, %cst_75 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1570 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1572 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_513 = linalg.transpose ins(%1571 : tensor<1x15x20x128xf32>) outs(%1572 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1573 = tensor.empty() : tensor<1x128x15x20xf32>
    %1574 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_513 : tensor<1x128x15x20xf32>) outs(%1573 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %1575 = tensor.empty() : tensor<1x128x15x20xf32>
    %1576 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_513, %1574 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%1575 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1577 = tensor.empty() : tensor<1x128x15x20xf32>
    %1578 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1576, %cst_74 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1577 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1579 = tensor.empty() : tensor<1x128x15x20xf32>
    %1580 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1578 : tensor<1x128x15x20xf32>) outs(%1579 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %1581 = tensor.empty() : tensor<1x128x15x20xi8>
    %1582 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1580 : tensor<1x128x15x20xf32>) outs(%1581 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %1583 = tensor.empty() : tensor<1x15x20x128xi8>
    %transposed_514 = linalg.transpose ins(%1582 : tensor<1x128x15x20xi8>) outs(%1583 : tensor<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %1584 = tensor.empty() : tensor<128x3x3x128xi8>
    %transposed_515 = linalg.transpose ins(%arg111 : tensor<128x128x3x3xi8>) outs(%1584 : tensor<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_516 = tensor.pad %transposed_514 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x128xi8> to tensor<1x17x22x128xi8>
    %1585 = tensor.empty() : tensor<1x15x20x128xi32>
    %1586 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg112 : tensor<128xi32>) outs(%1585 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %1587 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_516, %transposed_515 : tensor<1x17x22x128xi8>, tensor<128x3x3x128xi8>) outs(%1586 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %1588 = tensor.empty() : tensor<1x15x20x128xf32>
    %1589 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1587 : tensor<1x15x20x128xi32>) outs(%1588 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1590 = tensor.empty() : tensor<1x15x20x128xf32>
    %1591 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1589, %cst_73 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1590 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1592 = tensor.empty() : tensor<1x15x20x128xf32>
    %1593 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1591, %cst_72 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1592 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1594 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_517 = linalg.transpose ins(%1593 : tensor<1x15x20x128xf32>) outs(%1594 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1595 = tensor.empty() : tensor<1x128x15x20xf32>
    %1596 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_517 : tensor<1x128x15x20xf32>) outs(%1595 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %1597 = tensor.empty() : tensor<1x128x15x20xf32>
    %1598 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_517, %1596 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%1597 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1599 = tensor.empty() : tensor<1x128x15x20xf32>
    %1600 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1598, %cst_71 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1599 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1601 = tensor.empty() : tensor<1x128x15x20xf32>
    %1602 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1600 : tensor<1x128x15x20xf32>) outs(%1601 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %1603 = tensor.empty() : tensor<1x128x15x20xi8>
    %1604 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1602 : tensor<1x128x15x20xf32>) outs(%1603 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %1605 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_518 = linalg.transpose ins(%inserted_slice_505 : tensor<1x256x15x20xi8>) outs(%1605 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_519 = tensor.collapse_shape %arg113 [[0], [1, 2, 3]] : tensor<128x256x1x1xi8> into tensor<128x256xi8>
    %expanded_520 = tensor.expand_shape %collapsed_519 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : tensor<128x256xi8> into tensor<128x1x1x256xi8>
    %1606 = tensor.empty() : tensor<1x15x20x128xi32>
    %1607 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg114 : tensor<128xi32>) outs(%1606 : tensor<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x128xi32>
    %1608 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_518, %expanded_520 : tensor<1x15x20x256xi8>, tensor<128x1x1x256xi8>) outs(%1607 : tensor<1x15x20x128xi32>) -> tensor<1x15x20x128xi32>
    %1609 = tensor.empty() : tensor<1x15x20x128xf32>
    %1610 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1608 : tensor<1x15x20x128xi32>) outs(%1609 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1611 = tensor.empty() : tensor<1x15x20x128xf32>
    %1612 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1610, %cst_70 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1611 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1613 = tensor.empty() : tensor<1x15x20x128xf32>
    %1614 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1612, %cst_72 : tensor<1x15x20x128xf32>, tensor<1x1x1x1xf32>) outs(%1613 : tensor<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x128xf32>
    %1615 = tensor.empty() : tensor<1x128x15x20xf32>
    %transposed_521 = linalg.transpose ins(%1614 : tensor<1x15x20x128xf32>) outs(%1615 : tensor<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1616 = tensor.empty() : tensor<1x128x15x20xf32>
    %1617 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_521 : tensor<1x128x15x20xf32>) outs(%1616 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x128x15x20xf32>
    %1618 = tensor.empty() : tensor<1x128x15x20xf32>
    %1619 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_521, %1617 : tensor<1x128x15x20xf32>, tensor<1x128x15x20xf32>) outs(%1618 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1620 = tensor.empty() : tensor<1x128x15x20xf32>
    %1621 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1619, %cst_69 : tensor<1x128x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1620 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x128x15x20xf32>
    %1622 = tensor.empty() : tensor<1x128x15x20xf32>
    %1623 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1621 : tensor<1x128x15x20xf32>) outs(%1622 : tensor<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x128x15x20xf32>
    %1624 = tensor.empty() : tensor<1x128x15x20xi8>
    %1625 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1623 : tensor<1x128x15x20xf32>) outs(%1624 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x128x15x20xi8>
    %1626 = tensor.empty() : tensor<1x128x15x20xi32>
    %1627 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1604 : tensor<1x128x15x20xi8>) outs(%1626 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1628 = tensor.empty() : tensor<1x128x15x20xi32>
    %1629 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1627, %cst_68 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1628 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1630 = tensor.empty() : tensor<1x128x15x20xi32>
    %1631 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1629, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1630 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1632 = tensor.empty() : tensor<1x128x15x20xi32>
    %1633 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1631, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1632 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1634 = tensor.empty() : tensor<1x128x15x20xi32>
    %1635 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1633, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1634 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1636 = tensor.empty() : tensor<1x128x15x20xi8>
    %1637 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1635 : tensor<1x128x15x20xi32>) outs(%1636 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %1638 = tensor.empty() : tensor<1x128x15x20xi32>
    %1639 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1625 : tensor<1x128x15x20xi8>) outs(%1638 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %2069 = arith.extsi %in : i8 to i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1640 = tensor.empty() : tensor<1x128x15x20xi32>
    %1641 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1639, %cst_67 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1640 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.muli %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1642 = tensor.empty() : tensor<1x128x15x20xi32>
    %1643 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1641, %cst_248 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1642 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.shrsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1644 = tensor.empty() : tensor<1x128x15x20xi32>
    %1645 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1643, %cst_246 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1644 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.maxsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1646 = tensor.empty() : tensor<1x128x15x20xi32>
    %1647 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1645, %cst_245 : tensor<1x128x15x20xi32>, tensor<1x1x1x1xi32>) outs(%1646 : tensor<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_626: i32, %out: i32):
      %2069 = arith.minsi %in, %in_626 : i32
      linalg.yield %2069 : i32
    } -> tensor<1x128x15x20xi32>
    %1648 = tensor.empty() : tensor<1x128x15x20xi8>
    %1649 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1647 : tensor<1x128x15x20xi32>) outs(%1648 : tensor<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %2069 = arith.trunci %in : i32 to i8
      linalg.yield %2069 : i8
    } -> tensor<1x128x15x20xi8>
    %1650 = tensor.empty() : tensor<1x256x15x20xi8>
    %inserted_slice_522 = tensor.insert_slice %1637 into %1650[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %inserted_slice_523 = tensor.insert_slice %1649 into %inserted_slice_522[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : tensor<1x128x15x20xi8> into tensor<1x256x15x20xi8>
    %1651 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_524 = linalg.transpose ins(%inserted_slice_523 : tensor<1x256x15x20xi8>) outs(%1651 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_525 = tensor.collapse_shape %arg115 [[0], [1, 2, 3]] : tensor<256x256x1x1xi8> into tensor<256x256xi8>
    %expanded_526 = tensor.expand_shape %collapsed_525 [[0, 1, 2], [3]] output_shape [256, 1, 1, 256] : tensor<256x256xi8> into tensor<256x1x1x256xi8>
    %1652 = tensor.empty() : tensor<1x15x20x256xi32>
    %1653 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg116 : tensor<256xi32>) outs(%1652 : tensor<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x256xi32>
    %1654 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_524, %expanded_526 : tensor<1x15x20x256xi8>, tensor<256x1x1x256xi8>) outs(%1653 : tensor<1x15x20x256xi32>) -> tensor<1x15x20x256xi32>
    %1655 = tensor.empty() : tensor<1x15x20x256xf32>
    %1656 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1654 : tensor<1x15x20x256xi32>) outs(%1655 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %1657 = tensor.empty() : tensor<1x15x20x256xf32>
    %1658 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1656, %cst_66 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%1657 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %1659 = tensor.empty() : tensor<1x15x20x256xf32>
    %1660 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1658, %cst_65 : tensor<1x15x20x256xf32>, tensor<1x1x1x1xf32>) outs(%1659 : tensor<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x256xf32>
    %1661 = tensor.empty() : tensor<1x256x15x20xf32>
    %transposed_527 = linalg.transpose ins(%1660 : tensor<1x15x20x256xf32>) outs(%1661 : tensor<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1662 = tensor.empty() : tensor<1x256x15x20xf32>
    %1663 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_527 : tensor<1x256x15x20xf32>) outs(%1662 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x256x15x20xf32>
    %1664 = tensor.empty() : tensor<1x256x15x20xf32>
    %1665 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_527, %1663 : tensor<1x256x15x20xf32>, tensor<1x256x15x20xf32>) outs(%1664 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %1666 = tensor.empty() : tensor<1x256x15x20xf32>
    %1667 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1665, %cst_64 : tensor<1x256x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1666 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x256x15x20xf32>
    %1668 = tensor.empty() : tensor<1x256x15x20xf32>
    %1669 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1667 : tensor<1x256x15x20xf32>) outs(%1668 : tensor<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x256x15x20xf32>
    %1670 = tensor.empty() : tensor<1x256x15x20xi8>
    %1671 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1669 : tensor<1x256x15x20xf32>) outs(%1670 : tensor<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x256x15x20xi8>
    %1672 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_528 = linalg.transpose ins(%1315 : tensor<1x64x60x80xi8>) outs(%1672 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %1673 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_529 = linalg.transpose ins(%arg117 : tensor<64x64x3x3xi8>) outs(%1673 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_530 = tensor.pad %transposed_528 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x64xi8> to tensor<1x62x82x64xi8>
    %1674 = tensor.empty() : tensor<1x60x80x64xi32>
    %1675 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg118 : tensor<64xi32>) outs(%1674 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %1676 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_530, %transposed_529 : tensor<1x62x82x64xi8>, tensor<64x3x3x64xi8>) outs(%1675 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %1677 = tensor.empty() : tensor<1x60x80x64xf32>
    %1678 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1676 : tensor<1x60x80x64xi32>) outs(%1677 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1679 = tensor.empty() : tensor<1x60x80x64xf32>
    %1680 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1678, %cst_63 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1679 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1681 = tensor.empty() : tensor<1x60x80x64xf32>
    %1682 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1680, %cst_62 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1681 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1683 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_531 = linalg.transpose ins(%1682 : tensor<1x60x80x64xf32>) outs(%1683 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1684 = tensor.empty() : tensor<1x64x60x80xf32>
    %1685 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_531 : tensor<1x64x60x80xf32>) outs(%1684 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x60x80xf32>
    %1686 = tensor.empty() : tensor<1x64x60x80xf32>
    %1687 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_531, %1685 : tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>) outs(%1686 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1688 = tensor.empty() : tensor<1x64x60x80xf32>
    %1689 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1687, %cst_61 : tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1688 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1690 = tensor.empty() : tensor<1x64x60x80xf32>
    %1691 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1689 : tensor<1x64x60x80xf32>) outs(%1690 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x60x80xf32>
    %1692 = tensor.empty() : tensor<1x64x60x80xi8>
    %1693 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1691 : tensor<1x64x60x80xf32>) outs(%1692 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x60x80xi8>
    %1694 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_532 = linalg.transpose ins(%1693 : tensor<1x64x60x80xi8>) outs(%1694 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %1695 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_533 = linalg.transpose ins(%arg119 : tensor<64x64x3x3xi8>) outs(%1695 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_534 = tensor.pad %transposed_532 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x64xi8> to tensor<1x62x82x64xi8>
    %1696 = tensor.empty() : tensor<1x60x80x64xi32>
    %1697 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg120 : tensor<64xi32>) outs(%1696 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %1698 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_534, %transposed_533 : tensor<1x62x82x64xi8>, tensor<64x3x3x64xi8>) outs(%1697 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %1699 = tensor.empty() : tensor<1x60x80x64xf32>
    %1700 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1698 : tensor<1x60x80x64xi32>) outs(%1699 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1701 = tensor.empty() : tensor<1x60x80x64xf32>
    %1702 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1700, %cst_60 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1701 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1703 = tensor.empty() : tensor<1x60x80x64xf32>
    %1704 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1702, %cst_59 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1703 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1705 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_535 = linalg.transpose ins(%1704 : tensor<1x60x80x64xf32>) outs(%1705 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1706 = tensor.empty() : tensor<1x64x60x80xf32>
    %1707 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_535 : tensor<1x64x60x80xf32>) outs(%1706 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x60x80xf32>
    %1708 = tensor.empty() : tensor<1x64x60x80xf32>
    %1709 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_535, %1707 : tensor<1x64x60x80xf32>, tensor<1x64x60x80xf32>) outs(%1708 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1710 = tensor.empty() : tensor<1x64x60x80xf32>
    %1711 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1709, %cst_58 : tensor<1x64x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1710 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x60x80xf32>
    %1712 = tensor.empty() : tensor<1x64x60x80xf32>
    %1713 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1711 : tensor<1x64x60x80xf32>) outs(%1712 : tensor<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x60x80xf32>
    %1714 = tensor.empty() : tensor<1x64x60x80xi8>
    %1715 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1713 : tensor<1x64x60x80xf32>) outs(%1714 : tensor<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x60x80xi8>
    %1716 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_536 = linalg.transpose ins(%1715 : tensor<1x64x60x80xi8>) outs(%1716 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_537 = tensor.collapse_shape %arg121 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_538 = tensor.expand_shape %collapsed_537 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1717 = tensor.empty() : tensor<1x60x80x64xi32>
    %1718 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg122 : tensor<64xi32>) outs(%1717 : tensor<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x64xi32>
    %1719 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_536, %expanded_538 : tensor<1x60x80x64xi8>, tensor<64x1x1x64xi8>) outs(%1718 : tensor<1x60x80x64xi32>) -> tensor<1x60x80x64xi32>
    %1720 = tensor.empty() : tensor<1x60x80x64xf32>
    %1721 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1719 : tensor<1x60x80x64xi32>) outs(%1720 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1722 = tensor.empty() : tensor<1x60x80x64xf32>
    %1723 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1721, %cst_57 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1722 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1724 = tensor.empty() : tensor<1x60x80x64xf32>
    %1725 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1723, %cst_56 : tensor<1x60x80x64xf32>, tensor<1x1x1x1xf32>) outs(%1724 : tensor<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x64xf32>
    %1726 = tensor.empty() : tensor<1x64x60x80xf32>
    %transposed_539 = linalg.transpose ins(%1725 : tensor<1x60x80x64xf32>) outs(%1726 : tensor<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_540 = tensor.collapse_shape %transposed_539 [[0], [1], [2, 3]] : tensor<1x64x60x80xf32> into tensor<1x64x4800xf32>
    %1727 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_541 = linalg.transpose ins(%1493 : tensor<1x128x30x40xi8>) outs(%1727 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %1728 = tensor.empty() : tensor<64x3x3x128xi8>
    %transposed_542 = linalg.transpose ins(%arg124 : tensor<64x128x3x3xi8>) outs(%1728 : tensor<64x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_543 = tensor.pad %transposed_541 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x128xi8> to tensor<1x32x42x128xi8>
    %1729 = tensor.empty() : tensor<1x30x40x64xi32>
    %1730 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg125 : tensor<64xi32>) outs(%1729 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1731 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_543, %transposed_542 : tensor<1x32x42x128xi8>, tensor<64x3x3x128xi8>) outs(%1730 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1732 = tensor.empty() : tensor<1x30x40x64xf32>
    %1733 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1731 : tensor<1x30x40x64xi32>) outs(%1732 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1734 = tensor.empty() : tensor<1x30x40x64xf32>
    %1735 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1733, %cst_55 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1734 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1736 = tensor.empty() : tensor<1x30x40x64xf32>
    %1737 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1735, %cst_54 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1736 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1738 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_544 = linalg.transpose ins(%1737 : tensor<1x30x40x64xf32>) outs(%1738 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1739 = tensor.empty() : tensor<1x64x30x40xf32>
    %1740 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_544 : tensor<1x64x30x40xf32>) outs(%1739 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1741 = tensor.empty() : tensor<1x64x30x40xf32>
    %1742 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_544, %1740 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1741 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1743 = tensor.empty() : tensor<1x64x30x40xf32>
    %1744 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1742, %cst_53 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1743 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1745 = tensor.empty() : tensor<1x64x30x40xf32>
    %1746 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1744 : tensor<1x64x30x40xf32>) outs(%1745 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1747 = tensor.empty() : tensor<1x64x30x40xi8>
    %1748 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1746 : tensor<1x64x30x40xf32>) outs(%1747 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1749 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_545 = linalg.transpose ins(%1748 : tensor<1x64x30x40xi8>) outs(%1749 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %1750 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_546 = linalg.transpose ins(%arg126 : tensor<64x64x3x3xi8>) outs(%1750 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_547 = tensor.pad %transposed_545 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x64xi8> to tensor<1x32x42x64xi8>
    %1751 = tensor.empty() : tensor<1x30x40x64xi32>
    %1752 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg127 : tensor<64xi32>) outs(%1751 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1753 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_547, %transposed_546 : tensor<1x32x42x64xi8>, tensor<64x3x3x64xi8>) outs(%1752 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1754 = tensor.empty() : tensor<1x30x40x64xf32>
    %1755 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1753 : tensor<1x30x40x64xi32>) outs(%1754 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1756 = tensor.empty() : tensor<1x30x40x64xf32>
    %1757 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1755, %cst_52 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1756 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1758 = tensor.empty() : tensor<1x30x40x64xf32>
    %1759 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1757, %cst_51 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1758 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1760 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_548 = linalg.transpose ins(%1759 : tensor<1x30x40x64xf32>) outs(%1760 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1761 = tensor.empty() : tensor<1x64x30x40xf32>
    %1762 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_548 : tensor<1x64x30x40xf32>) outs(%1761 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x30x40xf32>
    %1763 = tensor.empty() : tensor<1x64x30x40xf32>
    %1764 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_548, %1762 : tensor<1x64x30x40xf32>, tensor<1x64x30x40xf32>) outs(%1763 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1765 = tensor.empty() : tensor<1x64x30x40xf32>
    %1766 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1764, %cst_50 : tensor<1x64x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1765 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x30x40xf32>
    %1767 = tensor.empty() : tensor<1x64x30x40xf32>
    %1768 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1766 : tensor<1x64x30x40xf32>) outs(%1767 : tensor<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x30x40xf32>
    %1769 = tensor.empty() : tensor<1x64x30x40xi8>
    %1770 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1768 : tensor<1x64x30x40xf32>) outs(%1769 : tensor<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x30x40xi8>
    %1771 = tensor.empty() : tensor<1x30x40x64xi8>
    %transposed_549 = linalg.transpose ins(%1770 : tensor<1x64x30x40xi8>) outs(%1771 : tensor<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_550 = tensor.collapse_shape %arg128 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_551 = tensor.expand_shape %collapsed_550 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1772 = tensor.empty() : tensor<1x30x40x64xi32>
    %1773 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg129 : tensor<64xi32>) outs(%1772 : tensor<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x64xi32>
    %1774 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_549, %expanded_551 : tensor<1x30x40x64xi8>, tensor<64x1x1x64xi8>) outs(%1773 : tensor<1x30x40x64xi32>) -> tensor<1x30x40x64xi32>
    %1775 = tensor.empty() : tensor<1x30x40x64xf32>
    %1776 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1774 : tensor<1x30x40x64xi32>) outs(%1775 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1777 = tensor.empty() : tensor<1x30x40x64xf32>
    %1778 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1776, %cst_49 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1777 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1779 = tensor.empty() : tensor<1x30x40x64xf32>
    %1780 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1778, %cst_48 : tensor<1x30x40x64xf32>, tensor<1x1x1x1xf32>) outs(%1779 : tensor<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x64xf32>
    %1781 = tensor.empty() : tensor<1x64x30x40xf32>
    %transposed_552 = linalg.transpose ins(%1780 : tensor<1x30x40x64xf32>) outs(%1781 : tensor<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_553 = tensor.collapse_shape %transposed_552 [[0], [1], [2, 3]] : tensor<1x64x30x40xf32> into tensor<1x64x1200xf32>
    %1782 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_554 = linalg.transpose ins(%1671 : tensor<1x256x15x20xi8>) outs(%1782 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %1783 = tensor.empty() : tensor<64x3x3x256xi8>
    %transposed_555 = linalg.transpose ins(%arg131 : tensor<64x256x3x3xi8>) outs(%1783 : tensor<64x3x3x256xi8>) permutation = [0, 2, 3, 1] 
    %padded_556 = tensor.pad %transposed_554 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x256xi8> to tensor<1x17x22x256xi8>
    %1784 = tensor.empty() : tensor<1x15x20x64xi32>
    %1785 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg132 : tensor<64xi32>) outs(%1784 : tensor<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x64xi32>
    %1786 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_556, %transposed_555 : tensor<1x17x22x256xi8>, tensor<64x3x3x256xi8>) outs(%1785 : tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xi32>
    %1787 = tensor.empty() : tensor<1x15x20x64xf32>
    %1788 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1786 : tensor<1x15x20x64xi32>) outs(%1787 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1789 = tensor.empty() : tensor<1x15x20x64xf32>
    %1790 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1788, %cst_47 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1789 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1791 = tensor.empty() : tensor<1x15x20x64xf32>
    %1792 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1790, %cst_46 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1791 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1793 = tensor.empty() : tensor<1x64x15x20xf32>
    %transposed_557 = linalg.transpose ins(%1792 : tensor<1x15x20x64xf32>) outs(%1793 : tensor<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1794 = tensor.empty() : tensor<1x64x15x20xf32>
    %1795 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_557 : tensor<1x64x15x20xf32>) outs(%1794 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x15x20xf32>
    %1796 = tensor.empty() : tensor<1x64x15x20xf32>
    %1797 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_557, %1795 : tensor<1x64x15x20xf32>, tensor<1x64x15x20xf32>) outs(%1796 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x15x20xf32>
    %1798 = tensor.empty() : tensor<1x64x15x20xf32>
    %1799 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1797, %cst_45 : tensor<1x64x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1798 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x15x20xf32>
    %1800 = tensor.empty() : tensor<1x64x15x20xf32>
    %1801 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1799 : tensor<1x64x15x20xf32>) outs(%1800 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x15x20xf32>
    %1802 = tensor.empty() : tensor<1x64x15x20xi8>
    %1803 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1801 : tensor<1x64x15x20xf32>) outs(%1802 : tensor<1x64x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x15x20xi8>
    %1804 = tensor.empty() : tensor<1x15x20x64xi8>
    %transposed_558 = linalg.transpose ins(%1803 : tensor<1x64x15x20xi8>) outs(%1804 : tensor<1x15x20x64xi8>) permutation = [0, 2, 3, 1] 
    %1805 = tensor.empty() : tensor<64x3x3x64xi8>
    %transposed_559 = linalg.transpose ins(%arg133 : tensor<64x64x3x3xi8>) outs(%1805 : tensor<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_560 = tensor.pad %transposed_558 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x64xi8> to tensor<1x17x22x64xi8>
    %1806 = tensor.empty() : tensor<1x15x20x64xi32>
    %1807 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg134 : tensor<64xi32>) outs(%1806 : tensor<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x64xi32>
    %1808 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_560, %transposed_559 : tensor<1x17x22x64xi8>, tensor<64x3x3x64xi8>) outs(%1807 : tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xi32>
    %1809 = tensor.empty() : tensor<1x15x20x64xf32>
    %1810 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1808 : tensor<1x15x20x64xi32>) outs(%1809 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1811 = tensor.empty() : tensor<1x15x20x64xf32>
    %1812 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1810, %cst_44 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1811 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1813 = tensor.empty() : tensor<1x15x20x64xf32>
    %1814 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1812, %cst_43 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1813 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1815 = tensor.empty() : tensor<1x64x15x20xf32>
    %transposed_561 = linalg.transpose ins(%1814 : tensor<1x15x20x64xf32>) outs(%1815 : tensor<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1816 = tensor.empty() : tensor<1x64x15x20xf32>
    %1817 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_561 : tensor<1x64x15x20xf32>) outs(%1816 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x64x15x20xf32>
    %1818 = tensor.empty() : tensor<1x64x15x20xf32>
    %1819 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_561, %1817 : tensor<1x64x15x20xf32>, tensor<1x64x15x20xf32>) outs(%1818 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x15x20xf32>
    %1820 = tensor.empty() : tensor<1x64x15x20xf32>
    %1821 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1819, %cst_42 : tensor<1x64x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1820 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x15x20xf32>
    %1822 = tensor.empty() : tensor<1x64x15x20xf32>
    %1823 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1821 : tensor<1x64x15x20xf32>) outs(%1822 : tensor<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x64x15x20xf32>
    %1824 = tensor.empty() : tensor<1x64x15x20xi8>
    %1825 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1823 : tensor<1x64x15x20xf32>) outs(%1824 : tensor<1x64x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x64x15x20xi8>
    %1826 = tensor.empty() : tensor<1x15x20x64xi8>
    %transposed_562 = linalg.transpose ins(%1825 : tensor<1x64x15x20xi8>) outs(%1826 : tensor<1x15x20x64xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_563 = tensor.collapse_shape %arg135 [[0], [1, 2, 3]] : tensor<64x64x1x1xi8> into tensor<64x64xi8>
    %expanded_564 = tensor.expand_shape %collapsed_563 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : tensor<64x64xi8> into tensor<64x1x1x64xi8>
    %1827 = tensor.empty() : tensor<1x15x20x64xi32>
    %1828 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg136 : tensor<64xi32>) outs(%1827 : tensor<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x64xi32>
    %1829 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_562, %expanded_564 : tensor<1x15x20x64xi8>, tensor<64x1x1x64xi8>) outs(%1828 : tensor<1x15x20x64xi32>) -> tensor<1x15x20x64xi32>
    %1830 = tensor.empty() : tensor<1x15x20x64xf32>
    %1831 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1829 : tensor<1x15x20x64xi32>) outs(%1830 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1832 = tensor.empty() : tensor<1x15x20x64xf32>
    %1833 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1831, %cst_41 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1832 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1834 = tensor.empty() : tensor<1x15x20x64xf32>
    %1835 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1833, %cst_40 : tensor<1x15x20x64xf32>, tensor<1x1x1x1xf32>) outs(%1834 : tensor<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x64xf32>
    %1836 = tensor.empty() : tensor<1x64x15x20xf32>
    %transposed_565 = linalg.transpose ins(%1835 : tensor<1x15x20x64xf32>) outs(%1836 : tensor<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_566 = tensor.collapse_shape %transposed_565 [[0], [1], [2, 3]] : tensor<1x64x15x20xf32> into tensor<1x64x300xf32>
    %1837 = tensor.empty() : tensor<1x64x1200xf32>
    %1838 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapsed_553, %cst_39 : tensor<1x64x1200xf32>, tensor<1x1x1xf32>) outs(%1837 : tensor<1x64x1200xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x1200xf32>
    %1839 = tensor.empty() : tensor<1x64x300xf32>
    %1840 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapsed_566, %cst_38 : tensor<1x64x300xf32>, tensor<1x1x1xf32>) outs(%1839 : tensor<1x64x300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x64x300xf32>
    %1841 = tensor.empty() : tensor<1x64x6300xf32>
    %inserted_slice_567 = tensor.insert_slice %collapsed_540 into %1841[0, 0, 0] [1, 64, 4800] [1, 1, 1] : tensor<1x64x4800xf32> into tensor<1x64x6300xf32>
    %inserted_slice_568 = tensor.insert_slice %1838 into %inserted_slice_567[0, 0, 4800] [1, 64, 1200] [1, 1, 1] : tensor<1x64x1200xf32> into tensor<1x64x6300xf32>
    %inserted_slice_569 = tensor.insert_slice %1840 into %inserted_slice_568[0, 0, 6000] [1, 64, 300] [1, 1, 1] : tensor<1x64x300xf32> into tensor<1x64x6300xf32>
    %1842 = tensor.empty() : tensor<1x60x80x64xi8>
    %transposed_570 = linalg.transpose ins(%1315 : tensor<1x64x60x80xi8>) outs(%1842 : tensor<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %1843 = tensor.empty() : tensor<80x3x3x64xi8>
    %transposed_571 = linalg.transpose ins(%arg138 : tensor<80x64x3x3xi8>) outs(%1843 : tensor<80x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %padded_572 = tensor.pad %transposed_570 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x64xi8> to tensor<1x62x82x64xi8>
    %1844 = tensor.empty() : tensor<1x60x80x80xi32>
    %1845 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg139 : tensor<80xi32>) outs(%1844 : tensor<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x80xi32>
    %1846 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_572, %transposed_571 : tensor<1x62x82x64xi8>, tensor<80x3x3x64xi8>) outs(%1845 : tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xi32>
    %1847 = tensor.empty() : tensor<1x60x80x80xf32>
    %1848 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1846 : tensor<1x60x80x80xi32>) outs(%1847 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1849 = tensor.empty() : tensor<1x60x80x80xf32>
    %1850 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1848, %cst_37 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1849 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1851 = tensor.empty() : tensor<1x60x80x80xf32>
    %1852 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1850, %cst_36 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1851 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1853 = tensor.empty() : tensor<1x80x60x80xf32>
    %transposed_573 = linalg.transpose ins(%1852 : tensor<1x60x80x80xf32>) outs(%1853 : tensor<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1854 = tensor.empty() : tensor<1x80x60x80xf32>
    %1855 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_573 : tensor<1x80x60x80xf32>) outs(%1854 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x60x80xf32>
    %1856 = tensor.empty() : tensor<1x80x60x80xf32>
    %1857 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_573, %1855 : tensor<1x80x60x80xf32>, tensor<1x80x60x80xf32>) outs(%1856 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x60x80xf32>
    %1858 = tensor.empty() : tensor<1x80x60x80xf32>
    %1859 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1857, %cst_35 : tensor<1x80x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1858 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x60x80xf32>
    %1860 = tensor.empty() : tensor<1x80x60x80xf32>
    %1861 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1859 : tensor<1x80x60x80xf32>) outs(%1860 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x60x80xf32>
    %1862 = tensor.empty() : tensor<1x80x60x80xi8>
    %1863 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1861 : tensor<1x80x60x80xf32>) outs(%1862 : tensor<1x80x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x60x80xi8>
    %1864 = tensor.empty() : tensor<1x60x80x80xi8>
    %transposed_574 = linalg.transpose ins(%1863 : tensor<1x80x60x80xi8>) outs(%1864 : tensor<1x60x80x80xi8>) permutation = [0, 2, 3, 1] 
    %1865 = tensor.empty() : tensor<80x3x3x80xi8>
    %transposed_575 = linalg.transpose ins(%arg140 : tensor<80x80x3x3xi8>) outs(%1865 : tensor<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %padded_576 = tensor.pad %transposed_574 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x60x80x80xi8> to tensor<1x62x82x80xi8>
    %1866 = tensor.empty() : tensor<1x60x80x80xi32>
    %1867 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg141 : tensor<80xi32>) outs(%1866 : tensor<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x80xi32>
    %1868 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_576, %transposed_575 : tensor<1x62x82x80xi8>, tensor<80x3x3x80xi8>) outs(%1867 : tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xi32>
    %1869 = tensor.empty() : tensor<1x60x80x80xf32>
    %1870 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1868 : tensor<1x60x80x80xi32>) outs(%1869 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1871 = tensor.empty() : tensor<1x60x80x80xf32>
    %1872 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1870, %cst_34 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1871 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1873 = tensor.empty() : tensor<1x60x80x80xf32>
    %1874 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1872, %cst_33 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1873 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1875 = tensor.empty() : tensor<1x80x60x80xf32>
    %transposed_577 = linalg.transpose ins(%1874 : tensor<1x60x80x80xf32>) outs(%1875 : tensor<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %1876 = tensor.empty() : tensor<1x80x60x80xf32>
    %1877 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_577 : tensor<1x80x60x80xf32>) outs(%1876 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x60x80xf32>
    %1878 = tensor.empty() : tensor<1x80x60x80xf32>
    %1879 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_577, %1877 : tensor<1x80x60x80xf32>, tensor<1x80x60x80xf32>) outs(%1878 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x60x80xf32>
    %1880 = tensor.empty() : tensor<1x80x60x80xf32>
    %1881 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1879, %cst_32 : tensor<1x80x60x80xf32>, tensor<1x1x1x1xf32>) outs(%1880 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x60x80xf32>
    %1882 = tensor.empty() : tensor<1x80x60x80xf32>
    %1883 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1881 : tensor<1x80x60x80xf32>) outs(%1882 : tensor<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x60x80xf32>
    %1884 = tensor.empty() : tensor<1x80x60x80xi8>
    %1885 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1883 : tensor<1x80x60x80xf32>) outs(%1884 : tensor<1x80x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x60x80xi8>
    %1886 = tensor.empty() : tensor<1x60x80x80xi8>
    %transposed_578 = linalg.transpose ins(%1885 : tensor<1x80x60x80xi8>) outs(%1886 : tensor<1x60x80x80xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_579 = tensor.collapse_shape %arg142 [[0], [1, 2, 3]] : tensor<80x80x1x1xi8> into tensor<80x80xi8>
    %expanded_580 = tensor.expand_shape %collapsed_579 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : tensor<80x80xi8> into tensor<80x1x1x80xi8>
    %1887 = tensor.empty() : tensor<1x60x80x80xi32>
    %1888 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg143 : tensor<80xi32>) outs(%1887 : tensor<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x60x80x80xi32>
    %1889 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_578, %expanded_580 : tensor<1x60x80x80xi8>, tensor<80x1x1x80xi8>) outs(%1888 : tensor<1x60x80x80xi32>) -> tensor<1x60x80x80xi32>
    %1890 = tensor.empty() : tensor<1x60x80x80xf32>
    %1891 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1889 : tensor<1x60x80x80xi32>) outs(%1890 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1892 = tensor.empty() : tensor<1x60x80x80xf32>
    %1893 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1891, %cst_31 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1892 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1894 = tensor.empty() : tensor<1x60x80x80xf32>
    %1895 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1893, %cst_30 : tensor<1x60x80x80xf32>, tensor<1x1x1x1xf32>) outs(%1894 : tensor<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x60x80x80xf32>
    %1896 = tensor.empty() : tensor<1x80x60x80xf32>
    %transposed_581 = linalg.transpose ins(%1895 : tensor<1x60x80x80xf32>) outs(%1896 : tensor<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_582 = tensor.collapse_shape %transposed_581 [[0], [1], [2, 3]] : tensor<1x80x60x80xf32> into tensor<1x80x4800xf32>
    %1897 = tensor.empty() : tensor<1x30x40x128xi8>
    %transposed_583 = linalg.transpose ins(%1493 : tensor<1x128x30x40xi8>) outs(%1897 : tensor<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %1898 = tensor.empty() : tensor<80x3x3x128xi8>
    %transposed_584 = linalg.transpose ins(%arg145 : tensor<80x128x3x3xi8>) outs(%1898 : tensor<80x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %padded_585 = tensor.pad %transposed_583 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x128xi8> to tensor<1x32x42x128xi8>
    %1899 = tensor.empty() : tensor<1x30x40x80xi32>
    %1900 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg146 : tensor<80xi32>) outs(%1899 : tensor<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x80xi32>
    %1901 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_585, %transposed_584 : tensor<1x32x42x128xi8>, tensor<80x3x3x128xi8>) outs(%1900 : tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xi32>
    %1902 = tensor.empty() : tensor<1x30x40x80xf32>
    %1903 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1901 : tensor<1x30x40x80xi32>) outs(%1902 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1904 = tensor.empty() : tensor<1x30x40x80xf32>
    %1905 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1903, %cst_29 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1904 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1906 = tensor.empty() : tensor<1x30x40x80xf32>
    %1907 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1905, %cst_28 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1906 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1908 = tensor.empty() : tensor<1x80x30x40xf32>
    %transposed_586 = linalg.transpose ins(%1907 : tensor<1x30x40x80xf32>) outs(%1908 : tensor<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1909 = tensor.empty() : tensor<1x80x30x40xf32>
    %1910 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_586 : tensor<1x80x30x40xf32>) outs(%1909 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x30x40xf32>
    %1911 = tensor.empty() : tensor<1x80x30x40xf32>
    %1912 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_586, %1910 : tensor<1x80x30x40xf32>, tensor<1x80x30x40xf32>) outs(%1911 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x30x40xf32>
    %1913 = tensor.empty() : tensor<1x80x30x40xf32>
    %1914 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1912, %cst_27 : tensor<1x80x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1913 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x30x40xf32>
    %1915 = tensor.empty() : tensor<1x80x30x40xf32>
    %1916 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1914 : tensor<1x80x30x40xf32>) outs(%1915 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x30x40xf32>
    %1917 = tensor.empty() : tensor<1x80x30x40xi8>
    %1918 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1916 : tensor<1x80x30x40xf32>) outs(%1917 : tensor<1x80x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x30x40xi8>
    %1919 = tensor.empty() : tensor<1x30x40x80xi8>
    %transposed_587 = linalg.transpose ins(%1918 : tensor<1x80x30x40xi8>) outs(%1919 : tensor<1x30x40x80xi8>) permutation = [0, 2, 3, 1] 
    %1920 = tensor.empty() : tensor<80x3x3x80xi8>
    %transposed_588 = linalg.transpose ins(%arg147 : tensor<80x80x3x3xi8>) outs(%1920 : tensor<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %padded_589 = tensor.pad %transposed_587 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x30x40x80xi8> to tensor<1x32x42x80xi8>
    %1921 = tensor.empty() : tensor<1x30x40x80xi32>
    %1922 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg148 : tensor<80xi32>) outs(%1921 : tensor<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x80xi32>
    %1923 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_589, %transposed_588 : tensor<1x32x42x80xi8>, tensor<80x3x3x80xi8>) outs(%1922 : tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xi32>
    %1924 = tensor.empty() : tensor<1x30x40x80xf32>
    %1925 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1923 : tensor<1x30x40x80xi32>) outs(%1924 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1926 = tensor.empty() : tensor<1x30x40x80xf32>
    %1927 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1925, %cst_26 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1926 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1928 = tensor.empty() : tensor<1x30x40x80xf32>
    %1929 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1927, %cst_25 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1928 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1930 = tensor.empty() : tensor<1x80x30x40xf32>
    %transposed_590 = linalg.transpose ins(%1929 : tensor<1x30x40x80xf32>) outs(%1930 : tensor<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %1931 = tensor.empty() : tensor<1x80x30x40xf32>
    %1932 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_590 : tensor<1x80x30x40xf32>) outs(%1931 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x30x40xf32>
    %1933 = tensor.empty() : tensor<1x80x30x40xf32>
    %1934 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_590, %1932 : tensor<1x80x30x40xf32>, tensor<1x80x30x40xf32>) outs(%1933 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x30x40xf32>
    %1935 = tensor.empty() : tensor<1x80x30x40xf32>
    %1936 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1934, %cst_24 : tensor<1x80x30x40xf32>, tensor<1x1x1x1xf32>) outs(%1935 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x30x40xf32>
    %1937 = tensor.empty() : tensor<1x80x30x40xf32>
    %1938 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1936 : tensor<1x80x30x40xf32>) outs(%1937 : tensor<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x30x40xf32>
    %1939 = tensor.empty() : tensor<1x80x30x40xi8>
    %1940 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1938 : tensor<1x80x30x40xf32>) outs(%1939 : tensor<1x80x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x30x40xi8>
    %1941 = tensor.empty() : tensor<1x30x40x80xi8>
    %transposed_591 = linalg.transpose ins(%1940 : tensor<1x80x30x40xi8>) outs(%1941 : tensor<1x30x40x80xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_592 = tensor.collapse_shape %arg149 [[0], [1, 2, 3]] : tensor<80x80x1x1xi8> into tensor<80x80xi8>
    %expanded_593 = tensor.expand_shape %collapsed_592 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : tensor<80x80xi8> into tensor<80x1x1x80xi8>
    %1942 = tensor.empty() : tensor<1x30x40x80xi32>
    %1943 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg150 : tensor<80xi32>) outs(%1942 : tensor<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x30x40x80xi32>
    %1944 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_591, %expanded_593 : tensor<1x30x40x80xi8>, tensor<80x1x1x80xi8>) outs(%1943 : tensor<1x30x40x80xi32>) -> tensor<1x30x40x80xi32>
    %1945 = tensor.empty() : tensor<1x30x40x80xf32>
    %1946 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1944 : tensor<1x30x40x80xi32>) outs(%1945 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1947 = tensor.empty() : tensor<1x30x40x80xf32>
    %1948 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1946, %cst_23 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1947 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1949 = tensor.empty() : tensor<1x30x40x80xf32>
    %1950 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1948, %cst_22 : tensor<1x30x40x80xf32>, tensor<1x1x1x1xf32>) outs(%1949 : tensor<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x30x40x80xf32>
    %1951 = tensor.empty() : tensor<1x80x30x40xf32>
    %transposed_594 = linalg.transpose ins(%1950 : tensor<1x30x40x80xf32>) outs(%1951 : tensor<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_595 = tensor.collapse_shape %transposed_594 [[0], [1], [2, 3]] : tensor<1x80x30x40xf32> into tensor<1x80x1200xf32>
    %1952 = tensor.empty() : tensor<1x15x20x256xi8>
    %transposed_596 = linalg.transpose ins(%1671 : tensor<1x256x15x20xi8>) outs(%1952 : tensor<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %1953 = tensor.empty() : tensor<80x3x3x256xi8>
    %transposed_597 = linalg.transpose ins(%arg152 : tensor<80x256x3x3xi8>) outs(%1953 : tensor<80x3x3x256xi8>) permutation = [0, 2, 3, 1] 
    %padded_598 = tensor.pad %transposed_596 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x256xi8> to tensor<1x17x22x256xi8>
    %1954 = tensor.empty() : tensor<1x15x20x80xi32>
    %1955 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg153 : tensor<80xi32>) outs(%1954 : tensor<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x80xi32>
    %1956 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_598, %transposed_597 : tensor<1x17x22x256xi8>, tensor<80x3x3x256xi8>) outs(%1955 : tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xi32>
    %1957 = tensor.empty() : tensor<1x15x20x80xf32>
    %1958 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1956 : tensor<1x15x20x80xi32>) outs(%1957 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1959 = tensor.empty() : tensor<1x15x20x80xf32>
    %1960 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1958, %cst_21 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%1959 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1961 = tensor.empty() : tensor<1x15x20x80xf32>
    %1962 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1960, %cst_20 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%1961 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1963 = tensor.empty() : tensor<1x80x15x20xf32>
    %transposed_599 = linalg.transpose ins(%1962 : tensor<1x15x20x80xf32>) outs(%1963 : tensor<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1964 = tensor.empty() : tensor<1x80x15x20xf32>
    %1965 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_599 : tensor<1x80x15x20xf32>) outs(%1964 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x15x20xf32>
    %1966 = tensor.empty() : tensor<1x80x15x20xf32>
    %1967 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_599, %1965 : tensor<1x80x15x20xf32>, tensor<1x80x15x20xf32>) outs(%1966 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x15x20xf32>
    %1968 = tensor.empty() : tensor<1x80x15x20xf32>
    %1969 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1967, %cst_19 : tensor<1x80x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1968 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x15x20xf32>
    %1970 = tensor.empty() : tensor<1x80x15x20xf32>
    %1971 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1969 : tensor<1x80x15x20xf32>) outs(%1970 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x15x20xf32>
    %1972 = tensor.empty() : tensor<1x80x15x20xi8>
    %1973 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1971 : tensor<1x80x15x20xf32>) outs(%1972 : tensor<1x80x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x15x20xi8>
    %1974 = tensor.empty() : tensor<1x15x20x80xi8>
    %transposed_600 = linalg.transpose ins(%1973 : tensor<1x80x15x20xi8>) outs(%1974 : tensor<1x15x20x80xi8>) permutation = [0, 2, 3, 1] 
    %1975 = tensor.empty() : tensor<80x3x3x80xi8>
    %transposed_601 = linalg.transpose ins(%arg154 : tensor<80x80x3x3xi8>) outs(%1975 : tensor<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %padded_602 = tensor.pad %transposed_600 low[0, 1, 1, 0] high[0, 1, 1, 0] {
    ^bb0(%arg166: index, %arg167: index, %arg168: index, %arg169: index):
      tensor.yield %c0_i8 : i8
    } : tensor<1x15x20x80xi8> to tensor<1x17x22x80xi8>
    %1976 = tensor.empty() : tensor<1x15x20x80xi32>
    %1977 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg155 : tensor<80xi32>) outs(%1976 : tensor<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x80xi32>
    %1978 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%padded_602, %transposed_601 : tensor<1x17x22x80xi8>, tensor<80x3x3x80xi8>) outs(%1977 : tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xi32>
    %1979 = tensor.empty() : tensor<1x15x20x80xf32>
    %1980 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1978 : tensor<1x15x20x80xi32>) outs(%1979 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1981 = tensor.empty() : tensor<1x15x20x80xf32>
    %1982 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1980, %cst_18 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%1981 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1983 = tensor.empty() : tensor<1x15x20x80xf32>
    %1984 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1982, %cst_17 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%1983 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %1985 = tensor.empty() : tensor<1x80x15x20xf32>
    %transposed_603 = linalg.transpose ins(%1984 : tensor<1x15x20x80xf32>) outs(%1985 : tensor<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %1986 = tensor.empty() : tensor<1x80x15x20xf32>
    %1987 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_603 : tensor<1x80x15x20xf32>) outs(%1986 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x15x20xf32>
    %1988 = tensor.empty() : tensor<1x80x15x20xf32>
    %1989 = linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_603, %1987 : tensor<1x80x15x20xf32>, tensor<1x80x15x20xf32>) outs(%1988 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x15x20xf32>
    %1990 = tensor.empty() : tensor<1x80x15x20xf32>
    %1991 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1989, %cst_16 : tensor<1x80x15x20xf32>, tensor<1x1x1x1xf32>) outs(%1990 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x15x20xf32>
    %1992 = tensor.empty() : tensor<1x80x15x20xf32>
    %1993 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1991 : tensor<1x80x15x20xf32>) outs(%1992 : tensor<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x80x15x20xf32>
    %1994 = tensor.empty() : tensor<1x80x15x20xi8>
    %1995 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1993 : tensor<1x80x15x20xf32>) outs(%1994 : tensor<1x80x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x80x15x20xi8>
    %1996 = tensor.empty() : tensor<1x15x20x80xi8>
    %transposed_604 = linalg.transpose ins(%1995 : tensor<1x80x15x20xi8>) outs(%1996 : tensor<1x15x20x80xi8>) permutation = [0, 2, 3, 1] 
    %collapsed_605 = tensor.collapse_shape %arg156 [[0], [1, 2, 3]] : tensor<80x80x1x1xi8> into tensor<80x80xi8>
    %expanded_606 = tensor.expand_shape %collapsed_605 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : tensor<80x80xi8> into tensor<80x1x1x80xi8>
    %1997 = tensor.empty() : tensor<1x15x20x80xi32>
    %1998 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%arg157 : tensor<80xi32>) outs(%1997 : tensor<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x15x20x80xi32>
    %1999 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%transposed_604, %expanded_606 : tensor<1x15x20x80xi8>, tensor<80x1x1x80xi8>) outs(%1998 : tensor<1x15x20x80xi32>) -> tensor<1x15x20x80xi32>
    %2000 = tensor.empty() : tensor<1x15x20x80xf32>
    %2001 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%1999 : tensor<1x15x20x80xi32>) outs(%2000 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %2002 = tensor.empty() : tensor<1x15x20x80xf32>
    %2003 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2001, %cst_15 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%2002 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %2004 = tensor.empty() : tensor<1x15x20x80xf32>
    %2005 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2003, %cst_14 : tensor<1x15x20x80xf32>, tensor<1x1x1x1xf32>) outs(%2004 : tensor<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x15x20x80xf32>
    %2006 = tensor.empty() : tensor<1x80x15x20xf32>
    %transposed_607 = linalg.transpose ins(%2005 : tensor<1x15x20x80xf32>) outs(%2006 : tensor<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %collapsed_608 = tensor.collapse_shape %transposed_607 [[0], [1], [2, 3]] : tensor<1x80x15x20xf32> into tensor<1x80x300xf32>
    %2007 = tensor.empty() : tensor<1x80x4800xf32>
    %2008 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapsed_582, %cst_13 : tensor<1x80x4800xf32>, tensor<1x1x1xf32>) outs(%2007 : tensor<1x80x4800xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x4800xf32>
    %2009 = tensor.empty() : tensor<1x80x1200xf32>
    %2010 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapsed_595, %cst_12 : tensor<1x80x1200xf32>, tensor<1x1x1xf32>) outs(%2009 : tensor<1x80x1200xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x1200xf32>
    %2011 = tensor.empty() : tensor<1x80x6300xf32>
    %inserted_slice_609 = tensor.insert_slice %2008 into %2011[0, 0, 0] [1, 80, 4800] [1, 1, 1] : tensor<1x80x4800xf32> into tensor<1x80x6300xf32>
    %inserted_slice_610 = tensor.insert_slice %2010 into %inserted_slice_609[0, 0, 4800] [1, 80, 1200] [1, 1, 1] : tensor<1x80x1200xf32> into tensor<1x80x6300xf32>
    %inserted_slice_611 = tensor.insert_slice %collapsed_608 into %inserted_slice_610[0, 0, 6000] [1, 80, 300] [1, 1, 1] : tensor<1x80x300xf32> into tensor<1x80x6300xf32>
    %expanded_612 = tensor.expand_shape %inserted_slice_569 [[0], [1, 2], [3]] output_shape [1, 4, 16, 6300] : tensor<1x64x6300xf32> into tensor<1x4x16x6300xf32>
    %2012 = tensor.empty() : tensor<1x16x4x6300xf32>
    %transposed_613 = linalg.transpose ins(%expanded_612 : tensor<1x4x16x6300xf32>) outs(%2012 : tensor<1x16x4x6300xf32>) permutation = [0, 2, 1, 3] 
    %2013 = tensor.empty() : tensor<1x16x4x6300xf32>
    %2014 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_613 : tensor<1x16x4x6300xf32>) outs(%2013 : tensor<1x16x4x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = math.exp %in : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x4x6300xf32>
    %2015 = tensor.empty() : tensor<1x4x6300xf32>
    %2016 = linalg.fill ins(%cst_0 : f32) outs(%2015 : tensor<1x4x6300xf32>) -> tensor<1x4x6300xf32>
    %reduced = linalg.reduce ins(%2014 : tensor<1x16x4x6300xf32>) outs(%2016 : tensor<1x4x6300xf32>) dimensions = [1] 
      (%in: f32, %init: f32) {
        %2069 = arith.addf %in, %init : f32
        linalg.yield %2069 : f32
      }
    %expanded_614 = tensor.expand_shape %reduced [[0], [1, 2], [3]] output_shape [1, 1, 4, 6300] : tensor<1x4x6300xf32> into tensor<1x1x4x6300xf32>
    %2017 = tensor.empty() : tensor<1x1x4x6300xf32>
    %2018 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%expanded_614 : tensor<1x1x4x6300xf32>) outs(%2017 : tensor<1x1x4x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.divf %cst_3, %in : f32
      linalg.yield %2069 : f32
    } -> tensor<1x1x4x6300xf32>
    %2019 = tensor.empty() : tensor<1x16x4x6300xf32>
    %2020 = linalg.generic {indexing_maps = [#map1, #map5, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2014, %2018 : tensor<1x16x4x6300xf32>, tensor<1x1x4x6300xf32>) outs(%2019 : tensor<1x16x4x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x16x4x6300xf32>
    %2021 = tensor.empty() : tensor<1x4x6300x16xf32>
    %transposed_615 = linalg.transpose ins(%2020 : tensor<1x16x4x6300xf32>) outs(%2021 : tensor<1x4x6300x16xf32>) permutation = [0, 2, 3, 1] 
    %collapsed_616 = tensor.collapse_shape %arg160 [[0], [1, 2, 3]] : tensor<1x16x1x1xf32> into tensor<1x16xf32>
    %expanded_617 = tensor.expand_shape %collapsed_616 [[0, 1, 2], [3]] output_shape [1, 1, 1, 16] : tensor<1x16xf32> into tensor<1x1x1x16xf32>
    %2022 = tensor.empty() : tensor<1x4x6300x16xf32>
    %2023 = linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%transposed_615, %cst_11 : tensor<1x4x6300x16xf32>, tensor<1x1x1x1xf32>) outs(%2022 : tensor<1x4x6300x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x4x6300x16xf32>
    %2024 = tensor.empty() : tensor<1x4x6300x16xf32>
    %2025 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2023 : tensor<1x4x6300x16xf32>) outs(%2024 : tensor<1x4x6300x16xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst_2 : f32
      linalg.yield %2070 : f32
    } -> tensor<1x4x6300x16xf32>
    %2026 = tensor.empty() : tensor<1x4x6300x16xi8>
    %2027 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2025 : tensor<1x4x6300x16xf32>) outs(%2026 : tensor<1x4x6300x16xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x4x6300x16xi8>
    %2028 = tensor.empty() : tensor<1x1x1x16xf32>
    %2029 = linalg.generic {indexing_maps = [#map1, #map6, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%expanded_617, %cst_10 : tensor<1x1x1x16xf32>, tensor<1x1x1x1xf32>) outs(%2028 : tensor<1x1x1x16xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x1x1x16xf32>
    %2030 = tensor.empty() : tensor<1x1x1x16xf32>
    %2031 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2029 : tensor<1x1x1x16xf32>) outs(%2030 : tensor<1x1x1x16xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.minimumf %in, %cst_1 : f32
      %2070 = arith.maximumf %2069, %cst : f32
      linalg.yield %2070 : f32
    } -> tensor<1x1x1x16xf32>
    %2032 = tensor.empty() : tensor<1x1x1x16xi8>
    %2033 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2031 : tensor<1x1x1x16xf32>) outs(%2032 : tensor<1x1x1x16xi8>) {
    ^bb0(%in: f32, %out: i8):
      %2069 = math.roundeven %in : f32
      %2070 = arith.minimumf %2069, %cst_1 : f32
      %2071 = arith.maximumf %2070, %cst_2 : f32
      %2072 = arith.fptosi %2071 : f32 to i8
      linalg.yield %2072 : i8
    } -> tensor<1x1x1x16xi8>
    %2034 = tensor.empty() : tensor<1x4x6300x1xi32>
    %2035 = linalg.generic {indexing_maps = [#map7, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%cst_265 : tensor<1xi32>) outs(%2034 : tensor<1x4x6300x1xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    } -> tensor<1x4x6300x1xi32>
    %2036 = linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%2027, %2033 : tensor<1x4x6300x16xi8>, tensor<1x1x1x16xi8>) outs(%2035 : tensor<1x4x6300x1xi32>) -> tensor<1x4x6300x1xi32>
    %2037 = tensor.empty() : tensor<1x4x6300x1xf32>
    %2038 = linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2036 : tensor<1x4x6300x1xi32>) outs(%2037 : tensor<1x4x6300x1xf32>) {
    ^bb0(%in: i32, %out: f32):
      %2069 = arith.sitofp %in : i32 to f32
      linalg.yield %2069 : f32
    } -> tensor<1x4x6300x1xf32>
    %2039 = tensor.empty() : tensor<1x4x6300x1xf32>
    %2040 = linalg.generic {indexing_maps = [#map1, #map8, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2038, %cst_9 : tensor<1x4x6300x1xf32>, tensor<1x1x1x1xf32>) outs(%2039 : tensor<1x4x6300x1xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x4x6300x1xf32>
    %2041 = tensor.empty() : tensor<1x4x6300x1xf32>
    %2042 = linalg.generic {indexing_maps = [#map1, #map8, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%2040, %cst_8 : tensor<1x4x6300x1xf32>, tensor<1x1x1x1xf32>) outs(%2041 : tensor<1x4x6300x1xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x4x6300x1xf32>
    %collapsed_618 = tensor.collapse_shape %2042 [[0], [1], [2, 3]] : tensor<1x4x6300x1xf32> into tensor<1x4x6300xf32>
    %extracted_slice = tensor.extract_slice %collapsed_618[0, 0, 0] [1, 2, 6300] [1, 1, 1] : tensor<1x4x6300xf32> to tensor<1x2x6300xf32>
    %extracted_slice_619 = tensor.extract_slice %collapsed_618[0, 2, 0] [1, 2, 6300] [1, 1, 1] : tensor<1x4x6300xf32> to tensor<1x2x6300xf32>
    %2043 = tensor.empty() : tensor<1x2x6300xf32>
    %2044 = linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%arg162, %extracted_slice : tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) outs(%2043 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.subf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2045 = tensor.empty() : tensor<1x2x6300xf32>
    %2046 = linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%arg163, %extracted_slice_619 : tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) outs(%2045 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.addf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2047 = tensor.empty() : tensor<1x2x6300xf32>
    %2048 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2044, %cst_7 : tensor<1x2x6300xf32>, tensor<1x1x1xf32>) outs(%2047 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2049 = tensor.empty() : tensor<1x2x6300xf32>
    %2050 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2046, %cst_6 : tensor<1x2x6300xf32>, tensor<1x1x1xf32>) outs(%2049 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2051 = tensor.empty() : tensor<1x2x6300xf32>
    %2052 = linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2048, %2050 : tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) outs(%2051 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.addf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %expanded_620 = tensor.expand_shape %arg164 [] output_shape [1, 1, 1] : tensor<f32> into tensor<1x1x1xf32>
    %2053 = tensor.empty() : tensor<1x1x1xf32>
    %2054 = linalg.generic {indexing_maps = [#map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%expanded_620 : tensor<1x1x1xf32>) outs(%2053 : tensor<1x1x1xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.divf %cst_3, %in : f32
      linalg.yield %2069 : f32
    } -> tensor<1x1x1xf32>
    %2055 = tensor.empty() : tensor<1x2x6300xf32>
    %2056 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2052, %2054 : tensor<1x2x6300xf32>, tensor<1x1x1xf32>) outs(%2055 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2057 = tensor.empty() : tensor<1x2x6300xf32>
    %2058 = linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2046, %2044 : tensor<1x2x6300xf32>, tensor<1x2x6300xf32>) outs(%2057 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.subf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2059 = tensor.empty() : tensor<1x2x6300xf32>
    %2060 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2058, %cst_5 : tensor<1x2x6300xf32>, tensor<1x1x1xf32>) outs(%2059 : tensor<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x2x6300xf32>
    %2061 = tensor.empty() : tensor<1x4x6300xf32>
    %inserted_slice_621 = tensor.insert_slice %2056 into %2061[0, 0, 0] [1, 2, 6300] [1, 1, 1] : tensor<1x2x6300xf32> into tensor<1x4x6300xf32>
    %inserted_slice_622 = tensor.insert_slice %2060 into %inserted_slice_621[0, 2, 0] [1, 2, 6300] [1, 1, 1] : tensor<1x2x6300xf32> into tensor<1x4x6300xf32>
    %expanded_623 = tensor.expand_shape %arg165 [[0, 1], [2]] output_shape [1, 1, 6300] : tensor<1x6300xf32> into tensor<1x1x6300xf32>
    %2062 = tensor.empty() : tensor<1x4x6300xf32>
    %2063 = linalg.generic {indexing_maps = [#map3, #map9, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%inserted_slice_622, %expanded_623 : tensor<1x4x6300xf32>, tensor<1x1x6300xf32>) outs(%2062 : tensor<1x4x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x4x6300xf32>
    %2064 = tensor.empty() : tensor<1x80x6300xf32>
    %2065 = linalg.generic {indexing_maps = [#map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%inserted_slice_611 : tensor<1x80x6300xf32>) outs(%2064 : tensor<1x80x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %2069 = arith.negf %in : f32
      %2070 = math.exp %2069 : f32
      %2071 = arith.addf %2070, %cst_3 : f32
      %2072 = arith.divf %cst_3, %2071 : f32
      linalg.yield %2072 : f32
    } -> tensor<1x80x6300xf32>
    %2066 = tensor.empty() : tensor<1x80x6300xf32>
    %2067 = linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2065, %cst_4 : tensor<1x80x6300xf32>, tensor<1x1x1xf32>) outs(%2066 : tensor<1x80x6300xf32>) {
    ^bb0(%in: f32, %in_626: f32, %out: f32):
      %2069 = arith.mulf %in, %in_626 : f32
      linalg.yield %2069 : f32
    } -> tensor<1x80x6300xf32>
    %2068 = tensor.empty() : tensor<1x84x6300xf32>
    %inserted_slice_624 = tensor.insert_slice %2063 into %2068[0, 0, 0] [1, 4, 6300] [1, 1, 1] : tensor<1x4x6300xf32> into tensor<1x84x6300xf32>
    %inserted_slice_625 = tensor.insert_slice %2067 into %inserted_slice_624[0, 4, 0] [1, 80, 6300] [1, 1, 1] : tensor<1x80x6300xf32> into tensor<1x84x6300xf32>
    return %inserted_slice_625 : tensor<1x84x6300xf32>
  }
}

