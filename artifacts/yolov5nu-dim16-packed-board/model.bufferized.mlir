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
  func.func @forward(%arg0: tensor<1x3x480x640xi8>, %arg1: tensor<16x3x6x6xi8>, %arg2: tensor<16xi32>, %arg3: tensor<32x16x3x3xi8>, %arg4: tensor<32xi32>, %arg5: tensor<16x32x1x1xi8>, %arg6: tensor<16xi32>, %arg7: tensor<16x16x1x1xi8>, %arg8: tensor<16xi32>, %arg9: tensor<16x16x3x3xi8>, %arg10: tensor<16xi32>, %arg11: tensor<16x32x1x1xi8>, %arg12: tensor<16xi32>, %arg13: tensor<32x32x1x1xi8>, %arg14: tensor<32xi32>, %arg15: tensor<64x32x3x3xi8>, %arg16: tensor<64xi32>, %arg17: tensor<32x64x1x1xi8>, %arg18: tensor<32xi32>, %arg19: tensor<32x32x1x1xi8>, %arg20: tensor<32xi32>, %arg21: tensor<32x32x3x3xi8>, %arg22: tensor<32xi32>, %arg23: tensor<32x32x1x1xi8>, %arg24: tensor<32xi32>, %arg25: tensor<32x32x3x3xi8>, %arg26: tensor<32xi32>, %arg27: tensor<32x64x1x1xi8>, %arg28: tensor<32xi32>, %arg29: tensor<64x64x1x1xi8>, %arg30: tensor<64xi32>, %arg31: tensor<128x64x3x3xi8>, %arg32: tensor<128xi32>, %arg33: tensor<64x128x1x1xi8>, %arg34: tensor<64xi32>, %arg35: tensor<64x64x1x1xi8>, %arg36: tensor<64xi32>, %arg37: tensor<64x64x3x3xi8>, %arg38: tensor<64xi32>, %arg39: tensor<64x64x1x1xi8>, %arg40: tensor<64xi32>, %arg41: tensor<64x64x3x3xi8>, %arg42: tensor<64xi32>, %arg43: tensor<64x64x1x1xi8>, %arg44: tensor<64xi32>, %arg45: tensor<64x64x3x3xi8>, %arg46: tensor<64xi32>, %arg47: tensor<64x128x1x1xi8>, %arg48: tensor<64xi32>, %arg49: tensor<128x128x1x1xi8>, %arg50: tensor<128xi32>, %arg51: tensor<256x128x3x3xi8>, %arg52: tensor<256xi32>, %arg53: tensor<128x256x1x1xi8>, %arg54: tensor<128xi32>, %arg55: tensor<128x128x1x1xi8>, %arg56: tensor<128xi32>, %arg57: tensor<128x128x3x3xi8>, %arg58: tensor<128xi32>, %arg59: tensor<128x256x1x1xi8>, %arg60: tensor<128xi32>, %arg61: tensor<256x256x1x1xi8>, %arg62: tensor<256xi32>, %arg63: tensor<128x256x1x1xi8>, %arg64: tensor<128xi32>, %arg65: tensor<256x512x1x1xi8>, %arg66: tensor<256xi32>, %arg67: tensor<128x256x1x1xi8>, %arg68: tensor<128xi32>, %arg69: tensor<4xf32>, %arg70: tensor<64x256x1x1xi8>, %arg71: tensor<64xi32>, %arg72: tensor<64x64x1x1xi8>, %arg73: tensor<64xi32>, %arg74: tensor<64x64x3x3xi8>, %arg75: tensor<64xi32>, %arg76: tensor<64x256x1x1xi8>, %arg77: tensor<64xi32>, %arg78: tensor<128x128x1x1xi8>, %arg79: tensor<128xi32>, %arg80: tensor<64x128x1x1xi8>, %arg81: tensor<64xi32>, %arg82: tensor<4xf32>, %arg83: tensor<32x128x1x1xi8>, %arg84: tensor<32xi32>, %arg85: tensor<32x32x1x1xi8>, %arg86: tensor<32xi32>, %arg87: tensor<32x32x3x3xi8>, %arg88: tensor<32xi32>, %arg89: tensor<32x128x1x1xi8>, %arg90: tensor<32xi32>, %arg91: tensor<64x64x1x1xi8>, %arg92: tensor<64xi32>, %arg93: tensor<64x64x3x3xi8>, %arg94: tensor<64xi32>, %arg95: tensor<64x128x1x1xi8>, %arg96: tensor<64xi32>, %arg97: tensor<64x64x1x1xi8>, %arg98: tensor<64xi32>, %arg99: tensor<64x64x3x3xi8>, %arg100: tensor<64xi32>, %arg101: tensor<64x128x1x1xi8>, %arg102: tensor<64xi32>, %arg103: tensor<128x128x1x1xi8>, %arg104: tensor<128xi32>, %arg105: tensor<128x128x3x3xi8>, %arg106: tensor<128xi32>, %arg107: tensor<128x256x1x1xi8>, %arg108: tensor<128xi32>, %arg109: tensor<128x128x1x1xi8>, %arg110: tensor<128xi32>, %arg111: tensor<128x128x3x3xi8>, %arg112: tensor<128xi32>, %arg113: tensor<128x256x1x1xi8>, %arg114: tensor<128xi32>, %arg115: tensor<256x256x1x1xi8>, %arg116: tensor<256xi32>, %arg117: tensor<64x64x3x3xi8>, %arg118: tensor<64xi32>, %arg119: tensor<64x64x3x3xi8>, %arg120: tensor<64xi32>, %arg121: tensor<64x64x1x1xi8>, %arg122: tensor<64xi32>, %arg123: tensor<3xi64>, %arg124: tensor<64x128x3x3xi8>, %arg125: tensor<64xi32>, %arg126: tensor<64x64x3x3xi8>, %arg127: tensor<64xi32>, %arg128: tensor<64x64x1x1xi8>, %arg129: tensor<64xi32>, %arg130: tensor<3xi64>, %arg131: tensor<64x256x3x3xi8>, %arg132: tensor<64xi32>, %arg133: tensor<64x64x3x3xi8>, %arg134: tensor<64xi32>, %arg135: tensor<64x64x1x1xi8>, %arg136: tensor<64xi32>, %arg137: tensor<3xi64>, %arg138: tensor<80x64x3x3xi8>, %arg139: tensor<80xi32>, %arg140: tensor<80x80x3x3xi8>, %arg141: tensor<80xi32>, %arg142: tensor<80x80x1x1xi8>, %arg143: tensor<80xi32>, %arg144: tensor<3xi64>, %arg145: tensor<80x128x3x3xi8>, %arg146: tensor<80xi32>, %arg147: tensor<80x80x3x3xi8>, %arg148: tensor<80xi32>, %arg149: tensor<80x80x1x1xi8>, %arg150: tensor<80xi32>, %arg151: tensor<3xi64>, %arg152: tensor<80x256x3x3xi8>, %arg153: tensor<80xi32>, %arg154: tensor<80x80x3x3xi8>, %arg155: tensor<80xi32>, %arg156: tensor<80x80x1x1xi8>, %arg157: tensor<80xi32>, %arg158: tensor<3xi64>, %arg159: tensor<4xi64>, %arg160: tensor<1x16x1x1xf32>, %arg161: tensor<3xi64>, %arg162: tensor<1x2x6300xf32>, %arg163: tensor<1x2x6300xf32>, %arg164: tensor<f32>, %arg165: tensor<1x6300xf32>) -> tensor<1x84x6300xf32> {
    %0 = bufferization.to_buffer %arg165 : tensor<1x6300xf32> to memref<1x6300xf32>
    %1 = bufferization.to_buffer %arg164 : tensor<f32> to memref<f32>
    %2 = bufferization.to_buffer %arg163 : tensor<1x2x6300xf32> to memref<1x2x6300xf32>
    %3 = bufferization.to_buffer %arg162 : tensor<1x2x6300xf32> to memref<1x2x6300xf32>
    %4 = bufferization.to_buffer %arg160 : tensor<1x16x1x1xf32> to memref<1x16x1x1xf32>
    %5 = bufferization.to_buffer %arg157 : tensor<80xi32> to memref<80xi32>
    %6 = bufferization.to_buffer %arg156 : tensor<80x80x1x1xi8> to memref<80x80x1x1xi8>
    %7 = bufferization.to_buffer %arg155 : tensor<80xi32> to memref<80xi32>
    %8 = bufferization.to_buffer %arg154 : tensor<80x80x3x3xi8> to memref<80x80x3x3xi8>
    %9 = bufferization.to_buffer %arg153 : tensor<80xi32> to memref<80xi32>
    %10 = bufferization.to_buffer %arg152 : tensor<80x256x3x3xi8> to memref<80x256x3x3xi8>
    %11 = bufferization.to_buffer %arg150 : tensor<80xi32> to memref<80xi32>
    %12 = bufferization.to_buffer %arg149 : tensor<80x80x1x1xi8> to memref<80x80x1x1xi8>
    %13 = bufferization.to_buffer %arg148 : tensor<80xi32> to memref<80xi32>
    %14 = bufferization.to_buffer %arg147 : tensor<80x80x3x3xi8> to memref<80x80x3x3xi8>
    %15 = bufferization.to_buffer %arg146 : tensor<80xi32> to memref<80xi32>
    %16 = bufferization.to_buffer %arg145 : tensor<80x128x3x3xi8> to memref<80x128x3x3xi8>
    %17 = bufferization.to_buffer %arg143 : tensor<80xi32> to memref<80xi32>
    %18 = bufferization.to_buffer %arg142 : tensor<80x80x1x1xi8> to memref<80x80x1x1xi8>
    %19 = bufferization.to_buffer %arg141 : tensor<80xi32> to memref<80xi32>
    %20 = bufferization.to_buffer %arg140 : tensor<80x80x3x3xi8> to memref<80x80x3x3xi8>
    %21 = bufferization.to_buffer %arg139 : tensor<80xi32> to memref<80xi32>
    %22 = bufferization.to_buffer %arg138 : tensor<80x64x3x3xi8> to memref<80x64x3x3xi8>
    %23 = bufferization.to_buffer %arg136 : tensor<64xi32> to memref<64xi32>
    %24 = bufferization.to_buffer %arg135 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %25 = bufferization.to_buffer %arg134 : tensor<64xi32> to memref<64xi32>
    %26 = bufferization.to_buffer %arg133 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %27 = bufferization.to_buffer %arg132 : tensor<64xi32> to memref<64xi32>
    %28 = bufferization.to_buffer %arg131 : tensor<64x256x3x3xi8> to memref<64x256x3x3xi8>
    %29 = bufferization.to_buffer %arg129 : tensor<64xi32> to memref<64xi32>
    %30 = bufferization.to_buffer %arg128 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %31 = bufferization.to_buffer %arg127 : tensor<64xi32> to memref<64xi32>
    %32 = bufferization.to_buffer %arg126 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %33 = bufferization.to_buffer %arg125 : tensor<64xi32> to memref<64xi32>
    %34 = bufferization.to_buffer %arg124 : tensor<64x128x3x3xi8> to memref<64x128x3x3xi8>
    %35 = bufferization.to_buffer %arg122 : tensor<64xi32> to memref<64xi32>
    %36 = bufferization.to_buffer %arg121 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %37 = bufferization.to_buffer %arg120 : tensor<64xi32> to memref<64xi32>
    %38 = bufferization.to_buffer %arg119 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %39 = bufferization.to_buffer %arg118 : tensor<64xi32> to memref<64xi32>
    %40 = bufferization.to_buffer %arg117 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %41 = bufferization.to_buffer %arg116 : tensor<256xi32> to memref<256xi32>
    %42 = bufferization.to_buffer %arg115 : tensor<256x256x1x1xi8> to memref<256x256x1x1xi8>
    %43 = bufferization.to_buffer %arg114 : tensor<128xi32> to memref<128xi32>
    %44 = bufferization.to_buffer %arg113 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %45 = bufferization.to_buffer %arg112 : tensor<128xi32> to memref<128xi32>
    %46 = bufferization.to_buffer %arg111 : tensor<128x128x3x3xi8> to memref<128x128x3x3xi8>
    %47 = bufferization.to_buffer %arg110 : tensor<128xi32> to memref<128xi32>
    %48 = bufferization.to_buffer %arg109 : tensor<128x128x1x1xi8> to memref<128x128x1x1xi8>
    %49 = bufferization.to_buffer %arg108 : tensor<128xi32> to memref<128xi32>
    %50 = bufferization.to_buffer %arg107 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %51 = bufferization.to_buffer %arg106 : tensor<128xi32> to memref<128xi32>
    %52 = bufferization.to_buffer %arg105 : tensor<128x128x3x3xi8> to memref<128x128x3x3xi8>
    %53 = bufferization.to_buffer %arg104 : tensor<128xi32> to memref<128xi32>
    %54 = bufferization.to_buffer %arg103 : tensor<128x128x1x1xi8> to memref<128x128x1x1xi8>
    %55 = bufferization.to_buffer %arg102 : tensor<64xi32> to memref<64xi32>
    %56 = bufferization.to_buffer %arg101 : tensor<64x128x1x1xi8> to memref<64x128x1x1xi8>
    %57 = bufferization.to_buffer %arg100 : tensor<64xi32> to memref<64xi32>
    %58 = bufferization.to_buffer %arg99 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %59 = bufferization.to_buffer %arg98 : tensor<64xi32> to memref<64xi32>
    %60 = bufferization.to_buffer %arg97 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %61 = bufferization.to_buffer %arg96 : tensor<64xi32> to memref<64xi32>
    %62 = bufferization.to_buffer %arg95 : tensor<64x128x1x1xi8> to memref<64x128x1x1xi8>
    %63 = bufferization.to_buffer %arg94 : tensor<64xi32> to memref<64xi32>
    %64 = bufferization.to_buffer %arg93 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %65 = bufferization.to_buffer %arg92 : tensor<64xi32> to memref<64xi32>
    %66 = bufferization.to_buffer %arg91 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %67 = bufferization.to_buffer %arg90 : tensor<32xi32> to memref<32xi32>
    %68 = bufferization.to_buffer %arg89 : tensor<32x128x1x1xi8> to memref<32x128x1x1xi8>
    %69 = bufferization.to_buffer %arg88 : tensor<32xi32> to memref<32xi32>
    %70 = bufferization.to_buffer %arg87 : tensor<32x32x3x3xi8> to memref<32x32x3x3xi8>
    %71 = bufferization.to_buffer %arg86 : tensor<32xi32> to memref<32xi32>
    %72 = bufferization.to_buffer %arg85 : tensor<32x32x1x1xi8> to memref<32x32x1x1xi8>
    %73 = bufferization.to_buffer %arg84 : tensor<32xi32> to memref<32xi32>
    %74 = bufferization.to_buffer %arg83 : tensor<32x128x1x1xi8> to memref<32x128x1x1xi8>
    %75 = bufferization.to_buffer %arg81 : tensor<64xi32> to memref<64xi32>
    %76 = bufferization.to_buffer %arg80 : tensor<64x128x1x1xi8> to memref<64x128x1x1xi8>
    %77 = bufferization.to_buffer %arg79 : tensor<128xi32> to memref<128xi32>
    %78 = bufferization.to_buffer %arg78 : tensor<128x128x1x1xi8> to memref<128x128x1x1xi8>
    %79 = bufferization.to_buffer %arg77 : tensor<64xi32> to memref<64xi32>
    %80 = bufferization.to_buffer %arg76 : tensor<64x256x1x1xi8> to memref<64x256x1x1xi8>
    %81 = bufferization.to_buffer %arg75 : tensor<64xi32> to memref<64xi32>
    %82 = bufferization.to_buffer %arg74 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %83 = bufferization.to_buffer %arg73 : tensor<64xi32> to memref<64xi32>
    %84 = bufferization.to_buffer %arg72 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %85 = bufferization.to_buffer %arg71 : tensor<64xi32> to memref<64xi32>
    %86 = bufferization.to_buffer %arg70 : tensor<64x256x1x1xi8> to memref<64x256x1x1xi8>
    %87 = bufferization.to_buffer %arg68 : tensor<128xi32> to memref<128xi32>
    %88 = bufferization.to_buffer %arg67 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %89 = bufferization.to_buffer %arg66 : tensor<256xi32> to memref<256xi32>
    %90 = bufferization.to_buffer %arg65 : tensor<256x512x1x1xi8> to memref<256x512x1x1xi8>
    %91 = bufferization.to_buffer %arg64 : tensor<128xi32> to memref<128xi32>
    %92 = bufferization.to_buffer %arg63 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %93 = bufferization.to_buffer %arg62 : tensor<256xi32> to memref<256xi32>
    %94 = bufferization.to_buffer %arg61 : tensor<256x256x1x1xi8> to memref<256x256x1x1xi8>
    %95 = bufferization.to_buffer %arg60 : tensor<128xi32> to memref<128xi32>
    %96 = bufferization.to_buffer %arg59 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %97 = bufferization.to_buffer %arg58 : tensor<128xi32> to memref<128xi32>
    %98 = bufferization.to_buffer %arg57 : tensor<128x128x3x3xi8> to memref<128x128x3x3xi8>
    %99 = bufferization.to_buffer %arg56 : tensor<128xi32> to memref<128xi32>
    %100 = bufferization.to_buffer %arg55 : tensor<128x128x1x1xi8> to memref<128x128x1x1xi8>
    %101 = bufferization.to_buffer %arg54 : tensor<128xi32> to memref<128xi32>
    %102 = bufferization.to_buffer %arg53 : tensor<128x256x1x1xi8> to memref<128x256x1x1xi8>
    %103 = bufferization.to_buffer %arg52 : tensor<256xi32> to memref<256xi32>
    %104 = bufferization.to_buffer %arg51 : tensor<256x128x3x3xi8> to memref<256x128x3x3xi8>
    %105 = bufferization.to_buffer %arg50 : tensor<128xi32> to memref<128xi32>
    %106 = bufferization.to_buffer %arg49 : tensor<128x128x1x1xi8> to memref<128x128x1x1xi8>
    %107 = bufferization.to_buffer %arg48 : tensor<64xi32> to memref<64xi32>
    %108 = bufferization.to_buffer %arg47 : tensor<64x128x1x1xi8> to memref<64x128x1x1xi8>
    %109 = bufferization.to_buffer %arg46 : tensor<64xi32> to memref<64xi32>
    %110 = bufferization.to_buffer %arg45 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %111 = bufferization.to_buffer %arg44 : tensor<64xi32> to memref<64xi32>
    %112 = bufferization.to_buffer %arg43 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %113 = bufferization.to_buffer %arg42 : tensor<64xi32> to memref<64xi32>
    %114 = bufferization.to_buffer %arg41 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %115 = bufferization.to_buffer %arg40 : tensor<64xi32> to memref<64xi32>
    %116 = bufferization.to_buffer %arg39 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %117 = bufferization.to_buffer %arg38 : tensor<64xi32> to memref<64xi32>
    %118 = bufferization.to_buffer %arg37 : tensor<64x64x3x3xi8> to memref<64x64x3x3xi8>
    %119 = bufferization.to_buffer %arg36 : tensor<64xi32> to memref<64xi32>
    %120 = bufferization.to_buffer %arg35 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %121 = bufferization.to_buffer %arg34 : tensor<64xi32> to memref<64xi32>
    %122 = bufferization.to_buffer %arg33 : tensor<64x128x1x1xi8> to memref<64x128x1x1xi8>
    %123 = bufferization.to_buffer %arg32 : tensor<128xi32> to memref<128xi32>
    %124 = bufferization.to_buffer %arg31 : tensor<128x64x3x3xi8> to memref<128x64x3x3xi8>
    %125 = bufferization.to_buffer %arg30 : tensor<64xi32> to memref<64xi32>
    %126 = bufferization.to_buffer %arg29 : tensor<64x64x1x1xi8> to memref<64x64x1x1xi8>
    %127 = bufferization.to_buffer %arg28 : tensor<32xi32> to memref<32xi32>
    %128 = bufferization.to_buffer %arg27 : tensor<32x64x1x1xi8> to memref<32x64x1x1xi8>
    %129 = bufferization.to_buffer %arg26 : tensor<32xi32> to memref<32xi32>
    %130 = bufferization.to_buffer %arg25 : tensor<32x32x3x3xi8> to memref<32x32x3x3xi8>
    %131 = bufferization.to_buffer %arg24 : tensor<32xi32> to memref<32xi32>
    %132 = bufferization.to_buffer %arg23 : tensor<32x32x1x1xi8> to memref<32x32x1x1xi8>
    %133 = bufferization.to_buffer %arg22 : tensor<32xi32> to memref<32xi32>
    %134 = bufferization.to_buffer %arg21 : tensor<32x32x3x3xi8> to memref<32x32x3x3xi8>
    %135 = bufferization.to_buffer %arg20 : tensor<32xi32> to memref<32xi32>
    %136 = bufferization.to_buffer %arg19 : tensor<32x32x1x1xi8> to memref<32x32x1x1xi8>
    %137 = bufferization.to_buffer %arg18 : tensor<32xi32> to memref<32xi32>
    %138 = bufferization.to_buffer %arg17 : tensor<32x64x1x1xi8> to memref<32x64x1x1xi8>
    %139 = bufferization.to_buffer %arg16 : tensor<64xi32> to memref<64xi32>
    %140 = bufferization.to_buffer %arg15 : tensor<64x32x3x3xi8> to memref<64x32x3x3xi8>
    %141 = bufferization.to_buffer %arg14 : tensor<32xi32> to memref<32xi32>
    %142 = bufferization.to_buffer %arg13 : tensor<32x32x1x1xi8> to memref<32x32x1x1xi8>
    %143 = bufferization.to_buffer %arg12 : tensor<16xi32> to memref<16xi32>
    %144 = bufferization.to_buffer %arg11 : tensor<16x32x1x1xi8> to memref<16x32x1x1xi8>
    %145 = bufferization.to_buffer %arg10 : tensor<16xi32> to memref<16xi32>
    %146 = bufferization.to_buffer %arg9 : tensor<16x16x3x3xi8> to memref<16x16x3x3xi8>
    %147 = bufferization.to_buffer %arg8 : tensor<16xi32> to memref<16xi32>
    %148 = bufferization.to_buffer %arg7 : tensor<16x16x1x1xi8> to memref<16x16x1x1xi8>
    %149 = bufferization.to_buffer %arg6 : tensor<16xi32> to memref<16xi32>
    %150 = bufferization.to_buffer %arg5 : tensor<16x32x1x1xi8> to memref<16x32x1x1xi8>
    %151 = bufferization.to_buffer %arg4 : tensor<32xi32> to memref<32xi32>
    %152 = bufferization.to_buffer %arg3 : tensor<32x16x3x3xi8> to memref<32x16x3x3xi8>
    %153 = bufferization.to_buffer %arg2 : tensor<16xi32> to memref<16xi32>
    %154 = bufferization.to_buffer %arg1 : tensor<16x3x6x6xi8> to memref<16x3x6x6xi8>
    %155 = bufferization.to_buffer %arg0 : tensor<1x3x480x640xi8> to memref<1x3x480x640xi8>
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
    %156 = memref.get_global @__constant_1x1x1xf32 : memref<1x1x1xf32>
    %157 = memref.get_global @__constant_1x1x1xf32_0 : memref<1x1x1xf32>
    %158 = memref.get_global @__constant_1x1x1xf32_1 : memref<1x1x1xf32>
    %159 = memref.get_global @__constant_1x1x1xf32_2 : memref<1x1x1xf32>
    %160 = memref.get_global @__constant_1x1x1x1xf32 : memref<1x1x1x1xf32>
    %161 = memref.get_global @__constant_1x1x1x1xf32_3 : memref<1x1x1x1xf32>
    %162 = memref.get_global @__constant_1x1x1x1xf32_4 : memref<1x1x1x1xf32>
    %163 = memref.get_global @__constant_1x1x1x1xf32_5 : memref<1x1x1x1xf32>
    %164 = memref.get_global @__constant_1x1x1xf32_6 : memref<1x1x1xf32>
    %165 = memref.get_global @__constant_1x1x1xf32_7 : memref<1x1x1xf32>
    %166 = memref.get_global @__constant_1x1x1x1xf32_8 : memref<1x1x1x1xf32>
    %167 = memref.get_global @__constant_1x1x1x1xf32_9 : memref<1x1x1x1xf32>
    %168 = memref.get_global @__constant_1x1x1x1xf32_10 : memref<1x1x1x1xf32>
    %169 = memref.get_global @__constant_1x1x1x1xf32_11 : memref<1x1x1x1xf32>
    %170 = memref.get_global @__constant_1x1x1x1xf32_12 : memref<1x1x1x1xf32>
    %171 = memref.get_global @__constant_1x1x1x1xf32_13 : memref<1x1x1x1xf32>
    %172 = memref.get_global @__constant_1x1x1x1xf32_14 : memref<1x1x1x1xf32>
    %173 = memref.get_global @__constant_1x1x1x1xf32_15 : memref<1x1x1x1xf32>
    %174 = memref.get_global @__constant_1x1x1x1xf32_16 : memref<1x1x1x1xf32>
    %175 = memref.get_global @__constant_1x1x1x1xf32_17 : memref<1x1x1x1xf32>
    %176 = memref.get_global @__constant_1x1x1x1xf32_18 : memref<1x1x1x1xf32>
    %177 = memref.get_global @__constant_1x1x1x1xf32_19 : memref<1x1x1x1xf32>
    %178 = memref.get_global @__constant_1x1x1x1xf32_20 : memref<1x1x1x1xf32>
    %179 = memref.get_global @__constant_1x1x1x1xf32_21 : memref<1x1x1x1xf32>
    %180 = memref.get_global @__constant_1x1x1x1xf32_22 : memref<1x1x1x1xf32>
    %181 = memref.get_global @__constant_1x1x1x1xf32_23 : memref<1x1x1x1xf32>
    %182 = memref.get_global @__constant_1x1x1x1xf32_24 : memref<1x1x1x1xf32>
    %183 = memref.get_global @__constant_1x1x1x1xf32_25 : memref<1x1x1x1xf32>
    %184 = memref.get_global @__constant_1x1x1x1xf32_26 : memref<1x1x1x1xf32>
    %185 = memref.get_global @__constant_1x1x1x1xf32_27 : memref<1x1x1x1xf32>
    %186 = memref.get_global @__constant_1x1x1x1xf32_28 : memref<1x1x1x1xf32>
    %187 = memref.get_global @__constant_1x1x1x1xf32_29 : memref<1x1x1x1xf32>
    %188 = memref.get_global @__constant_1x1x1x1xf32_30 : memref<1x1x1x1xf32>
    %189 = memref.get_global @__constant_1x1x1x1xf32_31 : memref<1x1x1x1xf32>
    %190 = memref.get_global @__constant_1x1x1xf32_32 : memref<1x1x1xf32>
    %191 = memref.get_global @__constant_1x1x1xf32_33 : memref<1x1x1xf32>
    %192 = memref.get_global @__constant_1x1x1x1xf32_34 : memref<1x1x1x1xf32>
    %193 = memref.get_global @__constant_1x1x1x1xf32_35 : memref<1x1x1x1xf32>
    %194 = memref.get_global @__constant_1x1x1x1xf32_36 : memref<1x1x1x1xf32>
    %195 = memref.get_global @__constant_1x1x1x1xf32_37 : memref<1x1x1x1xf32>
    %196 = memref.get_global @__constant_1x1x1x1xf32_38 : memref<1x1x1x1xf32>
    %197 = memref.get_global @__constant_1x1x1x1xf32_39 : memref<1x1x1x1xf32>
    %198 = memref.get_global @__constant_1x1x1x1xf32_40 : memref<1x1x1x1xf32>
    %199 = memref.get_global @__constant_1x1x1x1xf32_41 : memref<1x1x1x1xf32>
    %200 = memref.get_global @__constant_1x1x1x1xf32_42 : memref<1x1x1x1xf32>
    %201 = memref.get_global @__constant_1x1x1x1xf32_43 : memref<1x1x1x1xf32>
    %202 = memref.get_global @__constant_1x1x1x1xf32_44 : memref<1x1x1x1xf32>
    %203 = memref.get_global @__constant_1x1x1x1xf32_45 : memref<1x1x1x1xf32>
    %204 = memref.get_global @__constant_1x1x1x1xf32_46 : memref<1x1x1x1xf32>
    %205 = memref.get_global @__constant_1x1x1x1xf32_47 : memref<1x1x1x1xf32>
    %206 = memref.get_global @__constant_1x1x1x1xf32_48 : memref<1x1x1x1xf32>
    %207 = memref.get_global @__constant_1x1x1x1xf32_49 : memref<1x1x1x1xf32>
    %208 = memref.get_global @__constant_1x1x1x1xf32_50 : memref<1x1x1x1xf32>
    %209 = memref.get_global @__constant_1x1x1x1xf32_51 : memref<1x1x1x1xf32>
    %210 = memref.get_global @__constant_1x1x1x1xf32_52 : memref<1x1x1x1xf32>
    %211 = memref.get_global @__constant_1x1x1x1xf32_53 : memref<1x1x1x1xf32>
    %212 = memref.get_global @__constant_1x1x1x1xf32_54 : memref<1x1x1x1xf32>
    %213 = memref.get_global @__constant_1x1x1x1xf32_55 : memref<1x1x1x1xf32>
    %214 = memref.get_global @__constant_1x1x1x1xf32_56 : memref<1x1x1x1xf32>
    %215 = memref.get_global @__constant_1x1x1x1xf32_57 : memref<1x1x1x1xf32>
    %216 = memref.get_global @__constant_1x1x1x1xf32_58 : memref<1x1x1x1xf32>
    %217 = memref.get_global @__constant_1x1x1x1xf32_59 : memref<1x1x1x1xf32>
    %218 = memref.get_global @__constant_1x1x1x1xf32_60 : memref<1x1x1x1xf32>
    %219 = memref.get_global @__constant_1x1x1x1xi32 : memref<1x1x1x1xi32>
    %220 = memref.get_global @__constant_1x1x1x1xi32_61 : memref<1x1x1x1xi32>
    %221 = memref.get_global @__constant_1x1x1x1xf32_62 : memref<1x1x1x1xf32>
    %222 = memref.get_global @__constant_1x1x1x1xf32_63 : memref<1x1x1x1xf32>
    %223 = memref.get_global @__constant_1x1x1x1xf32_64 : memref<1x1x1x1xf32>
    %224 = memref.get_global @__constant_1x1x1x1xf32_65 : memref<1x1x1x1xf32>
    %225 = memref.get_global @__constant_1x1x1x1xf32_66 : memref<1x1x1x1xf32>
    %226 = memref.get_global @__constant_1x1x1x1xf32_67 : memref<1x1x1x1xf32>
    %227 = memref.get_global @__constant_1x1x1x1xf32_68 : memref<1x1x1x1xf32>
    %228 = memref.get_global @__constant_1x1x1x1xf32_69 : memref<1x1x1x1xf32>
    %229 = memref.get_global @__constant_1x1x1x1xf32_70 : memref<1x1x1x1xf32>
    %230 = memref.get_global @__constant_1x1x1x1xf32_71 : memref<1x1x1x1xf32>
    %231 = memref.get_global @__constant_1x1x1x1xf32_72 : memref<1x1x1x1xf32>
    %232 = memref.get_global @__constant_1x1x1x1xi32_73 : memref<1x1x1x1xi32>
    %233 = memref.get_global @__constant_1x1x1x1xi32_74 : memref<1x1x1x1xi32>
    %234 = memref.get_global @__constant_1x1x1x1xf32_75 : memref<1x1x1x1xf32>
    %235 = memref.get_global @__constant_1x1x1x1xf32_76 : memref<1x1x1x1xf32>
    %236 = memref.get_global @__constant_1x1x1x1xf32_77 : memref<1x1x1x1xf32>
    %237 = memref.get_global @__constant_1x1x1x1xf32_78 : memref<1x1x1x1xf32>
    %238 = memref.get_global @__constant_1x1x1x1xf32_79 : memref<1x1x1x1xf32>
    %239 = memref.get_global @__constant_1x1x1x1xi32_80 : memref<1x1x1x1xi32>
    %240 = memref.get_global @__constant_1x1x1x1xi32_81 : memref<1x1x1x1xi32>
    %241 = memref.get_global @__constant_1x1x1x1xf32_82 : memref<1x1x1x1xf32>
    %242 = memref.get_global @__constant_1x1x1x1xf32_83 : memref<1x1x1x1xf32>
    %243 = memref.get_global @__constant_1x1x1x1xf32_84 : memref<1x1x1x1xf32>
    %244 = memref.get_global @__constant_1x1x1x1xf32_85 : memref<1x1x1x1xf32>
    %245 = memref.get_global @__constant_1x1x1x1xf32_86 : memref<1x1x1x1xf32>
    %246 = memref.get_global @__constant_1x1x1x1xf32_87 : memref<1x1x1x1xf32>
    %247 = memref.get_global @__constant_1x1x1x1xf32_88 : memref<1x1x1x1xf32>
    %248 = memref.get_global @__constant_1x1x1x1xf32_89 : memref<1x1x1x1xf32>
    %249 = memref.get_global @__constant_1x1x1x1xf32_90 : memref<1x1x1x1xf32>
    %250 = memref.get_global @__constant_1x1x1x1xf32_91 : memref<1x1x1x1xf32>
    %251 = memref.get_global @__constant_1x1x1x1xf32_92 : memref<1x1x1x1xf32>
    %252 = memref.get_global @__constant_1x1x1x1xi32_93 : memref<1x1x1x1xi32>
    %253 = memref.get_global @__constant_1x1x1x1xi32_94 : memref<1x1x1x1xi32>
    %254 = memref.get_global @__constant_1x1x1x1xf32_95 : memref<1x1x1x1xf32>
    %255 = memref.get_global @__constant_1x1x1x1xf32_96 : memref<1x1x1x1xf32>
    %256 = memref.get_global @__constant_1x1x1x1xf32_97 : memref<1x1x1x1xf32>
    %257 = memref.get_global @__constant_1x1x1x1xf32_98 : memref<1x1x1x1xf32>
    %258 = memref.get_global @__constant_1x1x1x1xf32_99 : memref<1x1x1x1xf32>
    %259 = memref.get_global @__constant_1x1x1x1xf32_100 : memref<1x1x1x1xf32>
    %260 = memref.get_global @__constant_1x1x1x1xi32_101 : memref<1x1x1x1xi32>
    %261 = memref.get_global @__constant_1x1x1x1xi32_102 : memref<1x1x1x1xi32>
    %262 = memref.get_global @__constant_1x1x1x1xf32_103 : memref<1x1x1x1xf32>
    %263 = memref.get_global @__constant_1x1x1x1xf32_104 : memref<1x1x1x1xf32>
    %264 = memref.get_global @__constant_1x1x1x1xf32_105 : memref<1x1x1x1xf32>
    %265 = memref.get_global @__constant_1x1x1x1xf32_106 : memref<1x1x1x1xf32>
    %266 = memref.get_global @__constant_1x1x1x1xf32_107 : memref<1x1x1x1xf32>
    %267 = memref.get_global @__constant_1x1x1x1xf32_108 : memref<1x1x1x1xf32>
    %268 = memref.get_global @__constant_1x1x1x1xf32_109 : memref<1x1x1x1xf32>
    %269 = memref.get_global @__constant_1x1x1x1xf32_110 : memref<1x1x1x1xf32>
    %270 = memref.get_global @__constant_1x1x1x1xf32_111 : memref<1x1x1x1xf32>
    %271 = memref.get_global @__constant_1x1x1x1xf32_112 : memref<1x1x1x1xf32>
    %272 = memref.get_global @__constant_1x1x1x1xf32_113 : memref<1x1x1x1xf32>
    %273 = memref.get_global @__constant_1x1x1x1xi32_114 : memref<1x1x1x1xi32>
    %274 = memref.get_global @__constant_1x1x1x1xi32_115 : memref<1x1x1x1xi32>
    %275 = memref.get_global @__constant_1x1x1x1xf32_116 : memref<1x1x1x1xf32>
    %276 = memref.get_global @__constant_1x1x1x1xf32_117 : memref<1x1x1x1xf32>
    %277 = memref.get_global @__constant_1x1x1x1xf32_118 : memref<1x1x1x1xf32>
    %278 = memref.get_global @__constant_1x1x1x1xf32_119 : memref<1x1x1x1xf32>
    %279 = memref.get_global @__constant_1x1x1x1xf32_120 : memref<1x1x1x1xf32>
    %280 = memref.get_global @__constant_1x1x1x1xf32_121 : memref<1x1x1x1xf32>
    %281 = memref.get_global @__constant_1x1x1x1xi32_122 : memref<1x1x1x1xi32>
    %282 = memref.get_global @__constant_1x1x1x1xi32_123 : memref<1x1x1x1xi32>
    %283 = memref.get_global @__constant_1x1x1x1xf32_124 : memref<1x1x1x1xf32>
    %284 = memref.get_global @__constant_1x1x1x1xf32_125 : memref<1x1x1x1xf32>
    %285 = memref.get_global @__constant_1x1x1x1xf32_126 : memref<1x1x1x1xf32>
    %286 = memref.get_global @__constant_1x1x1x1xf32_127 : memref<1x1x1x1xf32>
    %287 = memref.get_global @__constant_1x1x1x1xf32_128 : memref<1x1x1x1xf32>
    %288 = memref.get_global @__constant_1x1x1x1xf32_129 : memref<1x1x1x1xf32>
    %289 = memref.get_global @__constant_1x1x1x1xf32_130 : memref<1x1x1x1xf32>
    %290 = memref.get_global @__constant_1x1x1x1xf32_131 : memref<1x1x1x1xf32>
    %291 = memref.get_global @__constant_1x1x1x1xf32_132 : memref<1x1x1x1xf32>
    %292 = memref.get_global @__constant_1x1x1x1xf32_133 : memref<1x1x1x1xf32>
    %293 = memref.get_global @__constant_1x1x1x1xf32_134 : memref<1x1x1x1xf32>
    %294 = memref.get_global @__constant_1x1x1x1xi32_135 : memref<1x1x1x1xi32>
    %295 = memref.get_global @__constant_1x1x1x1xi32_136 : memref<1x1x1x1xi32>
    %296 = memref.get_global @__constant_1x1x1x1xf32_137 : memref<1x1x1x1xf32>
    %297 = memref.get_global @__constant_1x1x1x1xf32_138 : memref<1x1x1x1xf32>
    %298 = memref.get_global @__constant_1x1x1x1xf32_139 : memref<1x1x1x1xf32>
    %299 = memref.get_global @__constant_1x1x1x1xf32_140 : memref<1x1x1x1xf32>
    %300 = memref.get_global @__constant_1x1x1x1xf32_141 : memref<1x1x1x1xf32>
    %301 = memref.get_global @__constant_1x1x1x1xf32_142 : memref<1x1x1x1xf32>
    %302 = memref.get_global @__constant_1x1x1x1xf32_143 : memref<1x1x1x1xf32>
    %303 = memref.get_global @__constant_1x1x1x1xf32_144 : memref<1x1x1x1xf32>
    %304 = memref.get_global @__constant_1x1x1x1xf32_145 : memref<1x1x1x1xf32>
    %305 = memref.get_global @__constant_1x1x1x1xf32_146 : memref<1x1x1x1xf32>
    %306 = memref.get_global @__constant_1x1x1x1xf32_147 : memref<1x1x1x1xf32>
    %307 = memref.get_global @__constant_1x1x1x1xf32_148 : memref<1x1x1x1xf32>
    %308 = memref.get_global @__constant_1x1x1x1xi32_149 : memref<1x1x1x1xi32>
    %309 = memref.get_global @__constant_1x1x1x1xf32_150 : memref<1x1x1x1xf32>
    %310 = memref.get_global @__constant_1x1x1x1xf32_151 : memref<1x1x1x1xf32>
    %311 = memref.get_global @__constant_1x1x1x1xi32_152 : memref<1x1x1x1xi32>
    %312 = memref.get_global @__constant_1x1x1x1xi32_153 : memref<1x1x1x1xi32>
    %313 = memref.get_global @__constant_1x1x1x1xf32_154 : memref<1x1x1x1xf32>
    %314 = memref.get_global @__constant_1x1x1x1xf32_155 : memref<1x1x1x1xf32>
    %315 = memref.get_global @__constant_1x1x1x1xf32_156 : memref<1x1x1x1xf32>
    %316 = memref.get_global @__constant_1x1x1x1xf32_157 : memref<1x1x1x1xf32>
    %317 = memref.get_global @__constant_1x1x1x1xf32_158 : memref<1x1x1x1xf32>
    %318 = memref.get_global @__constant_1x1x1x1xf32_159 : memref<1x1x1x1xf32>
    %319 = memref.get_global @__constant_1x1x1x1xf32_160 : memref<1x1x1x1xf32>
    %320 = memref.get_global @__constant_1x1x1x1xf32_161 : memref<1x1x1x1xf32>
    %321 = memref.get_global @__constant_1x1x1x1xf32_162 : memref<1x1x1x1xf32>
    %322 = memref.get_global @__constant_1x1x1x1xf32_163 : memref<1x1x1x1xf32>
    %323 = memref.get_global @__constant_1x1x1x1xf32_164 : memref<1x1x1x1xf32>
    %324 = memref.get_global @__constant_1x1x1x1xf32_165 : memref<1x1x1x1xf32>
    %325 = memref.get_global @__constant_1x1x1x1xf32_166 : memref<1x1x1x1xf32>
    %326 = memref.get_global @__constant_1x1x1x1xf32_167 : memref<1x1x1x1xf32>
    %327 = memref.get_global @__constant_1x1x1x1xf32_168 : memref<1x1x1x1xf32>
    %328 = memref.get_global @__constant_1x1x1x1xi32_169 : memref<1x1x1x1xi32>
    %329 = memref.get_global @__constant_1x1x1x1xf32_170 : memref<1x1x1x1xf32>
    %330 = memref.get_global @__constant_1x1x1x1xf32_171 : memref<1x1x1x1xf32>
    %331 = memref.get_global @__constant_1x1x1x1xi32_172 : memref<1x1x1x1xi32>
    %332 = memref.get_global @__constant_1x1x1x1xi32_173 : memref<1x1x1x1xi32>
    %333 = memref.get_global @__constant_1x1x1x1xf32_174 : memref<1x1x1x1xf32>
    %334 = memref.get_global @__constant_1x1x1x1xf32_175 : memref<1x1x1x1xf32>
    %335 = memref.get_global @__constant_1x1x1x1xf32_176 : memref<1x1x1x1xf32>
    %336 = memref.get_global @__constant_1x1x1x1xf32_177 : memref<1x1x1x1xf32>
    %337 = memref.get_global @__constant_1x1x1x1xf32_178 : memref<1x1x1x1xf32>
    %338 = memref.get_global @__constant_1x1x1x1xf32_179 : memref<1x1x1x1xf32>
    %339 = memref.get_global @__constant_1x1x1x1xi32_180 : memref<1x1x1x1xi32>
    %340 = memref.get_global @__constant_1x1x1x1xi32_181 : memref<1x1x1x1xi32>
    %341 = memref.get_global @__constant_1x1x1x1xf32_182 : memref<1x1x1x1xf32>
    %342 = memref.get_global @__constant_1x1x1x1xf32_183 : memref<1x1x1x1xf32>
    %343 = memref.get_global @__constant_1x1x1x1xf32_184 : memref<1x1x1x1xf32>
    %344 = memref.get_global @__constant_1x1x1x1xf32_185 : memref<1x1x1x1xf32>
    %345 = memref.get_global @__constant_1x1x1x1xf32_186 : memref<1x1x1x1xf32>
    %346 = memref.get_global @__constant_1x1x1x1xf32_187 : memref<1x1x1x1xf32>
    %347 = memref.get_global @__constant_1x1x1x1xi32_188 : memref<1x1x1x1xi32>
    %348 = memref.get_global @__constant_1x1x1x1xi32_189 : memref<1x1x1x1xi32>
    %349 = memref.get_global @__constant_1x1x1x1xf32_190 : memref<1x1x1x1xf32>
    %350 = memref.get_global @__constant_1x1x1x1xf32_191 : memref<1x1x1x1xf32>
    %351 = memref.get_global @__constant_1x1x1x1xf32_192 : memref<1x1x1x1xf32>
    %352 = memref.get_global @__constant_1x1x1x1xf32_193 : memref<1x1x1x1xf32>
    %353 = memref.get_global @__constant_1x1x1x1xf32_194 : memref<1x1x1x1xf32>
    %354 = memref.get_global @__constant_1x1x1x1xf32_195 : memref<1x1x1x1xf32>
    %355 = memref.get_global @__constant_1x1x1x1xf32_196 : memref<1x1x1x1xf32>
    %356 = memref.get_global @__constant_1x1x1x1xf32_197 : memref<1x1x1x1xf32>
    %357 = memref.get_global @__constant_1x1x1x1xf32_198 : memref<1x1x1x1xf32>
    %358 = memref.get_global @__constant_1x1x1x1xf32_199 : memref<1x1x1x1xf32>
    %359 = memref.get_global @__constant_1x1x1x1xf32_200 : memref<1x1x1x1xf32>
    %360 = memref.get_global @__constant_1x1x1x1xf32_201 : memref<1x1x1x1xf32>
    %361 = memref.get_global @__constant_1x1x1x1xf32_202 : memref<1x1x1x1xf32>
    %362 = memref.get_global @__constant_1x1x1x1xf32_203 : memref<1x1x1x1xf32>
    %363 = memref.get_global @__constant_1x1x1x1xf32_204 : memref<1x1x1x1xf32>
    %364 = memref.get_global @__constant_1x1x1x1xi32_205 : memref<1x1x1x1xi32>
    %365 = memref.get_global @__constant_1x1x1x1xi32_206 : memref<1x1x1x1xi32>
    %366 = memref.get_global @__constant_1x1x1x1xf32_207 : memref<1x1x1x1xf32>
    %367 = memref.get_global @__constant_1x1x1x1xf32_208 : memref<1x1x1x1xf32>
    %368 = memref.get_global @__constant_1x1x1x1xi32_209 : memref<1x1x1x1xi32>
    %369 = memref.get_global @__constant_1x1x1x1xi32_210 : memref<1x1x1x1xi32>
    %370 = memref.get_global @__constant_1x1x1x1xf32_211 : memref<1x1x1x1xf32>
    %371 = memref.get_global @__constant_1x1x1x1xf32_212 : memref<1x1x1x1xf32>
    %372 = memref.get_global @__constant_1x1x1x1xf32_213 : memref<1x1x1x1xf32>
    %373 = memref.get_global @__constant_1x1x1x1xf32_214 : memref<1x1x1x1xf32>
    %374 = memref.get_global @__constant_1x1x1x1xf32_215 : memref<1x1x1x1xf32>
    %375 = memref.get_global @__constant_1x1x1x1xf32_216 : memref<1x1x1x1xf32>
    %376 = memref.get_global @__constant_1x1x1x1xi32_217 : memref<1x1x1x1xi32>
    %377 = memref.get_global @__constant_1x1x1x1xi32_218 : memref<1x1x1x1xi32>
    %378 = memref.get_global @__constant_1x1x1x1xf32_219 : memref<1x1x1x1xf32>
    %379 = memref.get_global @__constant_1x1x1x1xf32_220 : memref<1x1x1x1xf32>
    %380 = memref.get_global @__constant_1x1x1x1xf32_221 : memref<1x1x1x1xf32>
    %381 = memref.get_global @__constant_1x1x1x1xf32_222 : memref<1x1x1x1xf32>
    %382 = memref.get_global @__constant_1x1x1x1xf32_223 : memref<1x1x1x1xf32>
    %383 = memref.get_global @__constant_1x1x1x1xf32_224 : memref<1x1x1x1xf32>
    %384 = memref.get_global @__constant_1x1x1x1xf32_225 : memref<1x1x1x1xf32>
    %385 = memref.get_global @__constant_1x1x1x1xf32_226 : memref<1x1x1x1xf32>
    %386 = memref.get_global @__constant_1x1x1x1xf32_227 : memref<1x1x1x1xf32>
    %387 = memref.get_global @__constant_1x1x1x1xf32_228 : memref<1x1x1x1xf32>
    %388 = memref.get_global @__constant_1x1x1x1xf32_229 : memref<1x1x1x1xf32>
    %389 = memref.get_global @__constant_1x1x1x1xf32_230 : memref<1x1x1x1xf32>
    %390 = memref.get_global @__constant_1x1x1x1xf32_231 : memref<1x1x1x1xf32>
    %391 = memref.get_global @__constant_1x1x1x1xf32_232 : memref<1x1x1x1xf32>
    %392 = memref.get_global @__constant_1x1x1x1xf32_233 : memref<1x1x1x1xf32>
    %393 = memref.get_global @__constant_1x1x1x1xi32_234 : memref<1x1x1x1xi32>
    %394 = memref.get_global @__constant_1x1x1x1xi32_235 : memref<1x1x1x1xi32>
    %395 = memref.get_global @__constant_1x1x1x1xf32_236 : memref<1x1x1x1xf32>
    %396 = memref.get_global @__constant_1x1x1x1xf32_237 : memref<1x1x1x1xf32>
    %397 = memref.get_global @__constant_1x1x1x1xi32_238 : memref<1x1x1x1xi32>
    %398 = memref.get_global @__constant_1x1x1x1xi32_239 : memref<1x1x1x1xi32>
    %399 = memref.get_global @__constant_1x1x1x1xi32_240 : memref<1x1x1x1xi32>
    %400 = memref.get_global @__constant_1x1x1x1xi32_241 : memref<1x1x1x1xi32>
    %401 = memref.get_global @__constant_1x1x1x1xi32_242 : memref<1x1x1x1xi32>
    %402 = memref.get_global @__constant_1x1x1x1xf32_243 : memref<1x1x1x1xf32>
    %403 = memref.get_global @__constant_1x1x1x1xf32_244 : memref<1x1x1x1xf32>
    %404 = memref.get_global @__constant_1x1x1x1xf32_245 : memref<1x1x1x1xf32>
    %405 = memref.get_global @__constant_1x1x1x1xf32_246 : memref<1x1x1x1xf32>
    %406 = memref.get_global @__constant_1x1x1x1xf32_247 : memref<1x1x1x1xf32>
    %407 = memref.get_global @__constant_1x1x1x1xf32_248 : memref<1x1x1x1xf32>
    %408 = memref.get_global @__constant_1x1x1x1xf32_249 : memref<1x1x1x1xf32>
    %409 = memref.get_global @__constant_1x1x1x1xf32_250 : memref<1x1x1x1xf32>
    %410 = memref.get_global @__constant_1x1x1x1xf32_251 : memref<1x1x1x1xf32>
    %411 = memref.get_global @__constant_1x1x1x1xf32_252 : memref<1x1x1x1xf32>
    %412 = memref.get_global @__constant_1x1x1x1xf32_253 : memref<1x1x1x1xf32>
    %413 = memref.get_global @__constant_1x1x1x1xf32_254 : memref<1x1x1x1xf32>
    %414 = memref.get_global @__constant_1x1x1x1xf32_255 : memref<1x1x1x1xf32>
    %415 = memref.get_global @__constant_1x1x1x1xf32_256 : memref<1x1x1x1xf32>
    %416 = memref.get_global @__constant_1x1x1x1xf32_257 : memref<1x1x1x1xf32>
    %417 = memref.get_global @__constant_1xi32 : memref<1xi32>
    %alloc = memref.alloc() {alignment = 64 : i64} : memref<1x480x640x3xi8>
    linalg.transpose ins(%155 : memref<1x3x480x640xi8>) outs(%alloc : memref<1x480x640x3xi8>) permutation = [0, 2, 3, 1] 
    %alloc_4 = memref.alloc() {alignment = 64 : i64} : memref<16x6x6x3xi8>
    linalg.transpose ins(%154 : memref<16x3x6x6xi8>) outs(%alloc_4 : memref<16x6x6x3xi8>) permutation = [0, 2, 3, 1] 
    %alloc_5 = memref.alloc() {alignment = 64 : i64} : memref<1x484x644x3xi8>
    linalg.map outs(%alloc_5 : memref<1x484x644x3xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview = memref.subview %alloc_5[0, 2, 2, 0] [1, 480, 640, 3] [1, 1, 1, 1] : memref<1x484x644x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    memref.copy %alloc, %subview : memref<1x480x640x3xi8> to memref<1x480x640x3xi8, strided<[935088, 1932, 3, 1], offset: 3870>>
    %alloc_6 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%153 : memref<16xi32>) outs(%alloc_6 : memref<1x240x320x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_5, %alloc_4 : memref<1x484x644x3xi8>, memref<16x6x6x3xi8>) outs(%alloc_6 : memref<1x240x320x16xi32>)
    %alloc_7 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_6 : memref<1x240x320x16xi32>) outs(%alloc_7 : memref<1x240x320x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_8 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_7, %416 : memref<1x240x320x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_8 : memref<1x240x320x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_9 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_8, %415 : memref<1x240x320x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_9 : memref<1x240x320x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_10 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    linalg.transpose ins(%alloc_9 : memref<1x240x320x16xf32>) outs(%alloc_10 : memref<1x16x240x320xf32>) permutation = [0, 3, 1, 2] 
    %alloc_11 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_10 : memref<1x16x240x320xf32>) outs(%alloc_11 : memref<1x16x240x320xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_12 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_10, %alloc_11 : memref<1x16x240x320xf32>, memref<1x16x240x320xf32>) outs(%alloc_12 : memref<1x16x240x320xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_13 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_12, %414 : memref<1x16x240x320xf32>, memref<1x1x1x1xf32>) outs(%alloc_13 : memref<1x16x240x320xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_14 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_13 : memref<1x16x240x320xf32>) outs(%alloc_14 : memref<1x16x240x320xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_15 = memref.alloc() {alignment = 64 : i64} : memref<1x16x240x320xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_14 : memref<1x16x240x320xf32>) outs(%alloc_15 : memref<1x16x240x320xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_16 = memref.alloc() {alignment = 64 : i64} : memref<1x240x320x16xi8>
    linalg.transpose ins(%alloc_15 : memref<1x16x240x320xi8>) outs(%alloc_16 : memref<1x240x320x16xi8>) permutation = [0, 2, 3, 1] 
    %alloc_17 = memref.alloc() {alignment = 64 : i64} : memref<32x3x3x16xi8>
    linalg.transpose ins(%152 : memref<32x16x3x3xi8>) outs(%alloc_17 : memref<32x3x3x16xi8>) permutation = [0, 2, 3, 1] 
    %alloc_18 = memref.alloc() {alignment = 64 : i64} : memref<1x241x321x16xi8>
    linalg.map outs(%alloc_18 : memref<1x241x321x16xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_19 = memref.subview %alloc_18[0, 1, 1, 0] [1, 240, 320, 16] [1, 1, 1, 1] : memref<1x241x321x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    memref.copy %alloc_16, %subview_19 : memref<1x240x320x16xi8> to memref<1x240x320x16xi8, strided<[1237776, 5136, 16, 1], offset: 5152>>
    %alloc_20 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%151 : memref<32xi32>) outs(%alloc_20 : memref<1x120x160x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_18, %alloc_17 : memref<1x241x321x16xi8>, memref<32x3x3x16xi8>) outs(%alloc_20 : memref<1x120x160x32xi32>)
    %alloc_21 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_20 : memref<1x120x160x32xi32>) outs(%alloc_21 : memref<1x120x160x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_22 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_21, %413 : memref<1x120x160x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_22 : memref<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_23 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_22, %412 : memref<1x120x160x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_23 : memref<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_24 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.transpose ins(%alloc_23 : memref<1x120x160x32xf32>) outs(%alloc_24 : memref<1x32x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_25 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_24 : memref<1x32x120x160xf32>) outs(%alloc_25 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_26 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_24, %alloc_25 : memref<1x32x120x160xf32>, memref<1x32x120x160xf32>) outs(%alloc_26 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_27 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_26, %411 : memref<1x32x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_27 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_28 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_27 : memref<1x32x120x160xf32>) outs(%alloc_28 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_29 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_28 : memref<1x32x120x160xf32>) outs(%alloc_29 : memref<1x32x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_30 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    linalg.transpose ins(%alloc_29 : memref<1x32x120x160xi8>) outs(%alloc_30 : memref<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape = memref.collapse_shape %150 [[0], [1, 2, 3]] : memref<16x32x1x1xi8> into memref<16x32xi8>
    %expand_shape = memref.expand_shape %collapse_shape [[0, 1, 2], [3]] output_shape [16, 1, 1, 32] : memref<16x32xi8> into memref<16x1x1x32xi8>
    %alloc_31 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%149 : memref<16xi32>) outs(%alloc_31 : memref<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_30, %expand_shape : memref<1x120x160x32xi8>, memref<16x1x1x32xi8>) outs(%alloc_31 : memref<1x120x160x16xi32>)
    %alloc_32 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_31 : memref<1x120x160x16xi32>) outs(%alloc_32 : memref<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_33 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_32, %410 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_33 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_34 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_33, %409 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_34 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_35 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.transpose ins(%alloc_34 : memref<1x120x160x16xf32>) outs(%alloc_35 : memref<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_36 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_35 : memref<1x16x120x160xf32>) outs(%alloc_36 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_37 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_35, %alloc_36 : memref<1x16x120x160xf32>, memref<1x16x120x160xf32>) outs(%alloc_37 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_38 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_37, %408 : memref<1x16x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_38 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_39 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_38 : memref<1x16x120x160xf32>) outs(%alloc_39 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_40 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_39 : memref<1x16x120x160xf32>) outs(%alloc_40 : memref<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_41 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    linalg.transpose ins(%alloc_40 : memref<1x16x120x160xi8>) outs(%alloc_41 : memref<1x120x160x16xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_42 = memref.collapse_shape %148 [[0], [1, 2, 3]] : memref<16x16x1x1xi8> into memref<16x16xi8>
    %expand_shape_43 = memref.expand_shape %collapse_shape_42 [[0, 1, 2], [3]] output_shape [16, 1, 1, 16] : memref<16x16xi8> into memref<16x1x1x16xi8>
    %alloc_44 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%147 : memref<16xi32>) outs(%alloc_44 : memref<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_41, %expand_shape_43 : memref<1x120x160x16xi8>, memref<16x1x1x16xi8>) outs(%alloc_44 : memref<1x120x160x16xi32>)
    %alloc_45 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_44 : memref<1x120x160x16xi32>) outs(%alloc_45 : memref<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_46 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_45, %407 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_46 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_47 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_46, %406 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_47 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_48 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.transpose ins(%alloc_47 : memref<1x120x160x16xf32>) outs(%alloc_48 : memref<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_49 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_48 : memref<1x16x120x160xf32>) outs(%alloc_49 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_50 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_48, %alloc_49 : memref<1x16x120x160xf32>, memref<1x16x120x160xf32>) outs(%alloc_50 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_51 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_50, %405 : memref<1x16x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_51 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_52 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_51 : memref<1x16x120x160xf32>) outs(%alloc_52 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_53 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_52 : memref<1x16x120x160xf32>) outs(%alloc_53 : memref<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_54 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi8>
    linalg.transpose ins(%alloc_53 : memref<1x16x120x160xi8>) outs(%alloc_54 : memref<1x120x160x16xi8>) permutation = [0, 2, 3, 1] 
    %alloc_55 = memref.alloc() {alignment = 64 : i64} : memref<16x3x3x16xi8>
    linalg.transpose ins(%146 : memref<16x16x3x3xi8>) outs(%alloc_55 : memref<16x3x3x16xi8>) permutation = [0, 2, 3, 1] 
    %alloc_56 = memref.alloc() {alignment = 64 : i64} : memref<1x122x162x16xi8>
    linalg.map outs(%alloc_56 : memref<1x122x162x16xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_57 = memref.subview %alloc_56[0, 1, 1, 0] [1, 120, 160, 16] [1, 1, 1, 1] : memref<1x122x162x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    memref.copy %alloc_54, %subview_57 : memref<1x120x160x16xi8> to memref<1x120x160x16xi8, strided<[316224, 2592, 16, 1], offset: 2608>>
    %alloc_58 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%145 : memref<16xi32>) outs(%alloc_58 : memref<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_56, %alloc_55 : memref<1x122x162x16xi8>, memref<16x3x3x16xi8>) outs(%alloc_58 : memref<1x120x160x16xi32>)
    %alloc_59 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_58 : memref<1x120x160x16xi32>) outs(%alloc_59 : memref<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_60 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_59, %404 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_60 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_61 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_60, %403 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_61 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_62 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.transpose ins(%alloc_61 : memref<1x120x160x16xf32>) outs(%alloc_62 : memref<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_63 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_62 : memref<1x16x120x160xf32>) outs(%alloc_63 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_64 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_62, %alloc_63 : memref<1x16x120x160xf32>, memref<1x16x120x160xf32>) outs(%alloc_64 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_65 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_64, %402 : memref<1x16x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_65 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_66 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_65 : memref<1x16x120x160xf32>) outs(%alloc_66 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_67 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_66 : memref<1x16x120x160xf32>) outs(%alloc_67 : memref<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_68 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_40 : memref<1x16x120x160xi8>) outs(%alloc_68 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_69 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_68, %401 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_69 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_70 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_69, %400 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_70 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_71 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_67 : memref<1x16x120x160xi8>) outs(%alloc_71 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_72 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_71, %399 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_72 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_73 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_72, %400 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_73 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_74 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_70, %alloc_73 : memref<1x16x120x160xi32>, memref<1x16x120x160xi32>) outs(%alloc_74 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_75 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_74, %398 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_75 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_76 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_75, %397 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_76 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_77 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_76 : memref<1x16x120x160xi32>) outs(%alloc_77 : memref<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_78 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    linalg.transpose ins(%alloc_29 : memref<1x32x120x160xi8>) outs(%alloc_78 : memref<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_79 = memref.collapse_shape %144 [[0], [1, 2, 3]] : memref<16x32x1x1xi8> into memref<16x32xi8>
    %expand_shape_80 = memref.expand_shape %collapse_shape_79 [[0, 1, 2], [3]] output_shape [16, 1, 1, 32] : memref<16x32xi8> into memref<16x1x1x32xi8>
    %alloc_81 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%143 : memref<16xi32>) outs(%alloc_81 : memref<1x120x160x16xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_78, %expand_shape_80 : memref<1x120x160x32xi8>, memref<16x1x1x32xi8>) outs(%alloc_81 : memref<1x120x160x16xi32>)
    %alloc_82 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_81 : memref<1x120x160x16xi32>) outs(%alloc_82 : memref<1x120x160x16xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_83 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_82, %396 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_83 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_84 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_83, %403 : memref<1x120x160x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_84 : memref<1x120x160x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_85 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.transpose ins(%alloc_84 : memref<1x120x160x16xf32>) outs(%alloc_85 : memref<1x16x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_86 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_85 : memref<1x16x120x160xf32>) outs(%alloc_86 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_87 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_85, %alloc_86 : memref<1x16x120x160xf32>, memref<1x16x120x160xf32>) outs(%alloc_87 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_88 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_87, %395 : memref<1x16x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_88 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_89 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_88 : memref<1x16x120x160xf32>) outs(%alloc_89 : memref<1x16x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_90 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_89 : memref<1x16x120x160xf32>) outs(%alloc_90 : memref<1x16x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_91 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_77 : memref<1x16x120x160xi8>) outs(%alloc_91 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_92 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_91, %394 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_92 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_93 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_92, %400 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_93 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_94 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_93, %398 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_94 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_95 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_94, %397 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_95 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_96 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_95 : memref<1x16x120x160xi32>) outs(%alloc_96 : memref<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_97 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_90 : memref<1x16x120x160xi8>) outs(%alloc_97 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_98 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_97, %393 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_98 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_99 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_98, %400 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_99 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_100 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_99, %398 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_100 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_101 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_100, %397 : memref<1x16x120x160xi32>, memref<1x1x1x1xi32>) outs(%alloc_101 : memref<1x16x120x160xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_102 = memref.alloc() {alignment = 64 : i64} : memref<1x16x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_101 : memref<1x16x120x160xi32>) outs(%alloc_102 : memref<1x16x120x160xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_103 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    %subview_104 = memref.subview %alloc_103[0, 0, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    memref.copy %alloc_96, %subview_104 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1]>>
    %subview_105 = memref.subview %alloc_103[0, 16, 0, 0] [1, 16, 120, 160] [1, 1, 1, 1] : memref<1x32x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    memref.copy %alloc_102, %subview_105 : memref<1x16x120x160xi8> to memref<1x16x120x160xi8, strided<[614400, 19200, 160, 1], offset: 307200>>
    %alloc_106 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    linalg.transpose ins(%alloc_103 : memref<1x32x120x160xi8>) outs(%alloc_106 : memref<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_107 = memref.collapse_shape %142 [[0], [1, 2, 3]] : memref<32x32x1x1xi8> into memref<32x32xi8>
    %expand_shape_108 = memref.expand_shape %collapse_shape_107 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : memref<32x32xi8> into memref<32x1x1x32xi8>
    %alloc_109 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%141 : memref<32xi32>) outs(%alloc_109 : memref<1x120x160x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_106, %expand_shape_108 : memref<1x120x160x32xi8>, memref<32x1x1x32xi8>) outs(%alloc_109 : memref<1x120x160x32xi32>)
    %alloc_110 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_109 : memref<1x120x160x32xi32>) outs(%alloc_110 : memref<1x120x160x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_111 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_110, %392 : memref<1x120x160x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_111 : memref<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_112 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_111, %391 : memref<1x120x160x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_112 : memref<1x120x160x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_113 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.transpose ins(%alloc_112 : memref<1x120x160x32xf32>) outs(%alloc_113 : memref<1x32x120x160xf32>) permutation = [0, 3, 1, 2] 
    %alloc_114 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_113 : memref<1x32x120x160xf32>) outs(%alloc_114 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_115 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_113, %alloc_114 : memref<1x32x120x160xf32>, memref<1x32x120x160xf32>) outs(%alloc_115 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_116 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_115, %390 : memref<1x32x120x160xf32>, memref<1x1x1x1xf32>) outs(%alloc_116 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_117 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_116 : memref<1x32x120x160xf32>) outs(%alloc_117 : memref<1x32x120x160xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_118 = memref.alloc() {alignment = 64 : i64} : memref<1x32x120x160xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_117 : memref<1x32x120x160xf32>) outs(%alloc_118 : memref<1x32x120x160xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_119 = memref.alloc() {alignment = 64 : i64} : memref<1x120x160x32xi8>
    linalg.transpose ins(%alloc_118 : memref<1x32x120x160xi8>) outs(%alloc_119 : memref<1x120x160x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_120 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x32xi8>
    linalg.transpose ins(%140 : memref<64x32x3x3xi8>) outs(%alloc_120 : memref<64x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_121 = memref.alloc() {alignment = 64 : i64} : memref<1x121x161x32xi8>
    linalg.map outs(%alloc_121 : memref<1x121x161x32xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_122 = memref.subview %alloc_121[0, 1, 1, 0] [1, 120, 160, 32] [1, 1, 1, 1] : memref<1x121x161x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    memref.copy %alloc_119, %subview_122 : memref<1x120x160x32xi8> to memref<1x120x160x32xi8, strided<[623392, 5152, 32, 1], offset: 5184>>
    %alloc_123 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%139 : memref<64xi32>) outs(%alloc_123 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_121, %alloc_120 : memref<1x121x161x32xi8>, memref<64x3x3x32xi8>) outs(%alloc_123 : memref<1x60x80x64xi32>)
    %alloc_124 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_123 : memref<1x60x80x64xi32>) outs(%alloc_124 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_125 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_124, %389 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_125 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_126 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_125, %388 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_126 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_127 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_126 : memref<1x60x80x64xf32>) outs(%alloc_127 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_128 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_127 : memref<1x64x60x80xf32>) outs(%alloc_128 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_129 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_127, %alloc_128 : memref<1x64x60x80xf32>, memref<1x64x60x80xf32>) outs(%alloc_129 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_130 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_129, %387 : memref<1x64x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_130 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_131 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_130 : memref<1x64x60x80xf32>) outs(%alloc_131 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_132 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_131 : memref<1x64x60x80xf32>) outs(%alloc_132 : memref<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_133 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_132 : memref<1x64x60x80xi8>) outs(%alloc_133 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_134 = memref.collapse_shape %138 [[0], [1, 2, 3]] : memref<32x64x1x1xi8> into memref<32x64xi8>
    %expand_shape_135 = memref.expand_shape %collapse_shape_134 [[0, 1, 2], [3]] output_shape [32, 1, 1, 64] : memref<32x64xi8> into memref<32x1x1x64xi8>
    %alloc_136 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%137 : memref<32xi32>) outs(%alloc_136 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_133, %expand_shape_135 : memref<1x60x80x64xi8>, memref<32x1x1x64xi8>) outs(%alloc_136 : memref<1x60x80x32xi32>)
    %alloc_137 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_136 : memref<1x60x80x32xi32>) outs(%alloc_137 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_138 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_137, %386 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_138 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_139 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_138, %385 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_139 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_140 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_139 : memref<1x60x80x32xf32>) outs(%alloc_140 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_141 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_140 : memref<1x32x60x80xf32>) outs(%alloc_141 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_142 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_140, %alloc_141 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_142 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_143 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_142, %384 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_143 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_144 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_143 : memref<1x32x60x80xf32>) outs(%alloc_144 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_145 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_144 : memref<1x32x60x80xf32>) outs(%alloc_145 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_146 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_145 : memref<1x32x60x80xi8>) outs(%alloc_146 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_147 = memref.collapse_shape %136 [[0], [1, 2, 3]] : memref<32x32x1x1xi8> into memref<32x32xi8>
    %expand_shape_148 = memref.expand_shape %collapse_shape_147 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : memref<32x32xi8> into memref<32x1x1x32xi8>
    %alloc_149 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%135 : memref<32xi32>) outs(%alloc_149 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_146, %expand_shape_148 : memref<1x60x80x32xi8>, memref<32x1x1x32xi8>) outs(%alloc_149 : memref<1x60x80x32xi32>)
    %alloc_150 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_149 : memref<1x60x80x32xi32>) outs(%alloc_150 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_151 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_150, %383 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_151 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_152 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_151, %382 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_152 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_153 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_152 : memref<1x60x80x32xf32>) outs(%alloc_153 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_154 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_153 : memref<1x32x60x80xf32>) outs(%alloc_154 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_155 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_153, %alloc_154 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_155 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_156 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_155, %381 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_156 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_157 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_156 : memref<1x32x60x80xf32>) outs(%alloc_157 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_158 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_157 : memref<1x32x60x80xf32>) outs(%alloc_158 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_159 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_158 : memref<1x32x60x80xi8>) outs(%alloc_159 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_160 = memref.alloc() {alignment = 64 : i64} : memref<32x3x3x32xi8>
    linalg.transpose ins(%134 : memref<32x32x3x3xi8>) outs(%alloc_160 : memref<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_161 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    linalg.map outs(%alloc_161 : memref<1x62x82x32xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_162 = memref.subview %alloc_161[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_159, %subview_162 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_163 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%133 : memref<32xi32>) outs(%alloc_163 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_161, %alloc_160 : memref<1x62x82x32xi8>, memref<32x3x3x32xi8>) outs(%alloc_163 : memref<1x60x80x32xi32>)
    %alloc_164 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_163 : memref<1x60x80x32xi32>) outs(%alloc_164 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_165 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_164, %380 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_165 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_166 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_165, %379 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_166 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_167 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_166 : memref<1x60x80x32xf32>) outs(%alloc_167 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_168 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_167 : memref<1x32x60x80xf32>) outs(%alloc_168 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_169 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_167, %alloc_168 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_169 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_170 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_169, %378 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_170 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_171 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_170 : memref<1x32x60x80xf32>) outs(%alloc_171 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_172 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_171 : memref<1x32x60x80xf32>) outs(%alloc_172 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_173 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_145 : memref<1x32x60x80xi8>) outs(%alloc_173 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_174 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_173, %377 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_174 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_175 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_174, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_175 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_176 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_172 : memref<1x32x60x80xi8>) outs(%alloc_176 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_177 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_176, %376 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_177 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_178 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_177, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_178 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_179 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_175, %alloc_178 : memref<1x32x60x80xi32>, memref<1x32x60x80xi32>) outs(%alloc_179 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_180 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_179, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_180 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_181 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_180, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_181 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_182 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_181 : memref<1x32x60x80xi32>) outs(%alloc_182 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_183 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_182 : memref<1x32x60x80xi8>) outs(%alloc_183 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_184 = memref.collapse_shape %132 [[0], [1, 2, 3]] : memref<32x32x1x1xi8> into memref<32x32xi8>
    %expand_shape_185 = memref.expand_shape %collapse_shape_184 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : memref<32x32xi8> into memref<32x1x1x32xi8>
    %alloc_186 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%131 : memref<32xi32>) outs(%alloc_186 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_183, %expand_shape_185 : memref<1x60x80x32xi8>, memref<32x1x1x32xi8>) outs(%alloc_186 : memref<1x60x80x32xi32>)
    %alloc_187 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_186 : memref<1x60x80x32xi32>) outs(%alloc_187 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_188 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_187, %375 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_188 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_189 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_188, %374 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_189 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_190 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_189 : memref<1x60x80x32xf32>) outs(%alloc_190 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_191 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_190 : memref<1x32x60x80xf32>) outs(%alloc_191 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_192 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_190, %alloc_191 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_192 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_193 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_192, %373 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_193 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_194 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_193 : memref<1x32x60x80xf32>) outs(%alloc_194 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_195 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_194 : memref<1x32x60x80xf32>) outs(%alloc_195 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_196 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_195 : memref<1x32x60x80xi8>) outs(%alloc_196 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_197 = memref.alloc() {alignment = 64 : i64} : memref<32x3x3x32xi8>
    linalg.transpose ins(%130 : memref<32x32x3x3xi8>) outs(%alloc_197 : memref<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_198 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    linalg.map outs(%alloc_198 : memref<1x62x82x32xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_199 = memref.subview %alloc_198[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_196, %subview_199 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_200 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%129 : memref<32xi32>) outs(%alloc_200 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_198, %alloc_197 : memref<1x62x82x32xi8>, memref<32x3x3x32xi8>) outs(%alloc_200 : memref<1x60x80x32xi32>)
    %alloc_201 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_200 : memref<1x60x80x32xi32>) outs(%alloc_201 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_202 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_201, %372 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_202 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_203 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_202, %371 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_203 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_204 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_203 : memref<1x60x80x32xf32>) outs(%alloc_204 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_205 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_204 : memref<1x32x60x80xf32>) outs(%alloc_205 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_206 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_204, %alloc_205 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_206 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_207 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_206, %370 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_207 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_208 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_207 : memref<1x32x60x80xf32>) outs(%alloc_208 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_209 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_208 : memref<1x32x60x80xf32>) outs(%alloc_209 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_210 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_182 : memref<1x32x60x80xi8>) outs(%alloc_210 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_211 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_210, %369 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_211 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_212 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_211, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_212 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_213 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_209 : memref<1x32x60x80xi8>) outs(%alloc_213 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_214 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_213, %368 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_214 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_215 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_214, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_215 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_216 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_212, %alloc_215 : memref<1x32x60x80xi32>, memref<1x32x60x80xi32>) outs(%alloc_216 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_217 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_216, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_217 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_218 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_217, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_218 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_219 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_218 : memref<1x32x60x80xi32>) outs(%alloc_219 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_220 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_132 : memref<1x64x60x80xi8>) outs(%alloc_220 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_221 = memref.collapse_shape %128 [[0], [1, 2, 3]] : memref<32x64x1x1xi8> into memref<32x64xi8>
    %expand_shape_222 = memref.expand_shape %collapse_shape_221 [[0, 1, 2], [3]] output_shape [32, 1, 1, 64] : memref<32x64xi8> into memref<32x1x1x64xi8>
    %alloc_223 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%127 : memref<32xi32>) outs(%alloc_223 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_220, %expand_shape_222 : memref<1x60x80x64xi8>, memref<32x1x1x64xi8>) outs(%alloc_223 : memref<1x60x80x32xi32>)
    %alloc_224 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_223 : memref<1x60x80x32xi32>) outs(%alloc_224 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_225 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_224, %367 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_225 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_226 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_225, %371 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_226 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_227 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_226 : memref<1x60x80x32xf32>) outs(%alloc_227 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_228 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_227 : memref<1x32x60x80xf32>) outs(%alloc_228 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_229 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_227, %alloc_228 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_229 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_230 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_229, %366 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_230 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_231 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_230 : memref<1x32x60x80xf32>) outs(%alloc_231 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_232 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_231 : memref<1x32x60x80xf32>) outs(%alloc_232 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_233 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_219 : memref<1x32x60x80xi8>) outs(%alloc_233 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_234 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_233, %365 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_234 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_235 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_234, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_235 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_236 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_235, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_236 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_237 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_236, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_237 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_238 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_237 : memref<1x32x60x80xi32>) outs(%alloc_238 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_239 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_232 : memref<1x32x60x80xi8>) outs(%alloc_239 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_240 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_239, %364 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_240 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_241 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_240, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_241 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_242 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_241, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_242 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_243 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_242, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_243 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_244 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_243 : memref<1x32x60x80xi32>) outs(%alloc_244 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_245 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_246 = memref.subview %alloc_245[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_238, %subview_246 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_247 = memref.subview %alloc_245[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_244, %subview_247 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_248 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_245 : memref<1x64x60x80xi8>) outs(%alloc_248 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_249 = memref.collapse_shape %126 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_250 = memref.expand_shape %collapse_shape_249 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_251 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%125 : memref<64xi32>) outs(%alloc_251 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_248, %expand_shape_250 : memref<1x60x80x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_251 : memref<1x60x80x64xi32>)
    %alloc_252 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_251 : memref<1x60x80x64xi32>) outs(%alloc_252 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_253 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_252, %363 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_253 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_254 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_253, %362 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_254 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_255 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_254 : memref<1x60x80x64xf32>) outs(%alloc_255 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_256 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_255 : memref<1x64x60x80xf32>) outs(%alloc_256 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_257 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_255, %alloc_256 : memref<1x64x60x80xf32>, memref<1x64x60x80xf32>) outs(%alloc_257 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_258 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_257, %361 : memref<1x64x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_258 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_259 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_258 : memref<1x64x60x80xf32>) outs(%alloc_259 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_260 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_259 : memref<1x64x60x80xf32>) outs(%alloc_260 : memref<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_261 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_260 : memref<1x64x60x80xi8>) outs(%alloc_261 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_262 = memref.alloc() {alignment = 64 : i64} : memref<128x3x3x64xi8>
    linalg.transpose ins(%124 : memref<128x64x3x3xi8>) outs(%alloc_262 : memref<128x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_263 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    linalg.map outs(%alloc_263 : memref<1x61x81x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_264 = memref.subview %alloc_263[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_261, %subview_264 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_265 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%123 : memref<128xi32>) outs(%alloc_265 : memref<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_263, %alloc_262 : memref<1x61x81x64xi8>, memref<128x3x3x64xi8>) outs(%alloc_265 : memref<1x30x40x128xi32>)
    %alloc_266 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_265 : memref<1x30x40x128xi32>) outs(%alloc_266 : memref<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_267 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_266, %360 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_267 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_268 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_267, %359 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_268 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_269 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.transpose ins(%alloc_268 : memref<1x30x40x128xf32>) outs(%alloc_269 : memref<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_270 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_269 : memref<1x128x30x40xf32>) outs(%alloc_270 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_271 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_269, %alloc_270 : memref<1x128x30x40xf32>, memref<1x128x30x40xf32>) outs(%alloc_271 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_272 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_271, %358 : memref<1x128x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_272 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_273 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_272 : memref<1x128x30x40xf32>) outs(%alloc_273 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_274 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_273 : memref<1x128x30x40xf32>) outs(%alloc_274 : memref<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_275 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_274 : memref<1x128x30x40xi8>) outs(%alloc_275 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_276 = memref.collapse_shape %122 [[0], [1, 2, 3]] : memref<64x128x1x1xi8> into memref<64x128xi8>
    %expand_shape_277 = memref.expand_shape %collapse_shape_276 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : memref<64x128xi8> into memref<64x1x1x128xi8>
    %alloc_278 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%121 : memref<64xi32>) outs(%alloc_278 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_275, %expand_shape_277 : memref<1x30x40x128xi8>, memref<64x1x1x128xi8>) outs(%alloc_278 : memref<1x30x40x64xi32>)
    %alloc_279 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_278 : memref<1x30x40x64xi32>) outs(%alloc_279 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_280 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_279, %357 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_280 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_281 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_280, %356 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_281 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_282 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_281 : memref<1x30x40x64xf32>) outs(%alloc_282 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_283 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_282 : memref<1x64x30x40xf32>) outs(%alloc_283 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_284 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_282, %alloc_283 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_284 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_285 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_284, %355 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_285 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_286 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_285 : memref<1x64x30x40xf32>) outs(%alloc_286 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_287 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_286 : memref<1x64x30x40xf32>) outs(%alloc_287 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_288 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_287 : memref<1x64x30x40xi8>) outs(%alloc_288 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_289 = memref.collapse_shape %120 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_290 = memref.expand_shape %collapse_shape_289 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_291 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%119 : memref<64xi32>) outs(%alloc_291 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_288, %expand_shape_290 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_291 : memref<1x30x40x64xi32>)
    %alloc_292 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_291 : memref<1x30x40x64xi32>) outs(%alloc_292 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_293 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_292, %354 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_293 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_294 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_293, %353 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_294 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_295 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_294 : memref<1x30x40x64xf32>) outs(%alloc_295 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_296 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_295 : memref<1x64x30x40xf32>) outs(%alloc_296 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_297 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_295, %alloc_296 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_297 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_298 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_297, %352 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_298 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_299 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_298 : memref<1x64x30x40xf32>) outs(%alloc_299 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_300 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_299 : memref<1x64x30x40xf32>) outs(%alloc_300 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_301 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_300 : memref<1x64x30x40xi8>) outs(%alloc_301 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_302 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%118 : memref<64x64x3x3xi8>) outs(%alloc_302 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_303 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_303 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_304 = memref.subview %alloc_303[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_301, %subview_304 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_305 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%117 : memref<64xi32>) outs(%alloc_305 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_303, %alloc_302 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_305 : memref<1x30x40x64xi32>)
    %alloc_306 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_305 : memref<1x30x40x64xi32>) outs(%alloc_306 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_307 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_306, %351 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_307 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_308 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_307, %350 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_308 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_309 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_308 : memref<1x30x40x64xf32>) outs(%alloc_309 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_310 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_309 : memref<1x64x30x40xf32>) outs(%alloc_310 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_311 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_309, %alloc_310 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_311 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_312 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_311, %349 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_312 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_313 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_312 : memref<1x64x30x40xf32>) outs(%alloc_313 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_314 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_313 : memref<1x64x30x40xf32>) outs(%alloc_314 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_315 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_287 : memref<1x64x30x40xi8>) outs(%alloc_315 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_316 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_315, %348 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_316 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_317 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_316, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_317 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_318 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_314 : memref<1x64x30x40xi8>) outs(%alloc_318 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_319 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_318, %347 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_319 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_320 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_319, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_320 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_321 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_317, %alloc_320 : memref<1x64x30x40xi32>, memref<1x64x30x40xi32>) outs(%alloc_321 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_322 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_321, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_322 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_323 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_322, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_323 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_324 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_323 : memref<1x64x30x40xi32>) outs(%alloc_324 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_325 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_324 : memref<1x64x30x40xi8>) outs(%alloc_325 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_326 = memref.collapse_shape %116 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_327 = memref.expand_shape %collapse_shape_326 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_328 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%115 : memref<64xi32>) outs(%alloc_328 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_325, %expand_shape_327 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_328 : memref<1x30x40x64xi32>)
    %alloc_329 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_328 : memref<1x30x40x64xi32>) outs(%alloc_329 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_330 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_329, %346 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_330 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_331 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_330, %345 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_331 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_332 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_331 : memref<1x30x40x64xf32>) outs(%alloc_332 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_333 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_332 : memref<1x64x30x40xf32>) outs(%alloc_333 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_334 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_332, %alloc_333 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_334 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_335 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_334, %344 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_335 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_336 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_335 : memref<1x64x30x40xf32>) outs(%alloc_336 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_337 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_336 : memref<1x64x30x40xf32>) outs(%alloc_337 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_338 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_337 : memref<1x64x30x40xi8>) outs(%alloc_338 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_339 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%114 : memref<64x64x3x3xi8>) outs(%alloc_339 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_340 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_340 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_341 = memref.subview %alloc_340[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_338, %subview_341 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_342 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%113 : memref<64xi32>) outs(%alloc_342 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_340, %alloc_339 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_342 : memref<1x30x40x64xi32>)
    %alloc_343 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_342 : memref<1x30x40x64xi32>) outs(%alloc_343 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_344 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_343, %343 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_344 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_345 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_344, %342 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_345 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_346 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_345 : memref<1x30x40x64xf32>) outs(%alloc_346 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_347 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_346 : memref<1x64x30x40xf32>) outs(%alloc_347 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_348 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_346, %alloc_347 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_348 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_349 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_348, %341 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_349 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_350 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_349 : memref<1x64x30x40xf32>) outs(%alloc_350 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_351 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_350 : memref<1x64x30x40xf32>) outs(%alloc_351 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_352 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_324 : memref<1x64x30x40xi8>) outs(%alloc_352 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_353 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_352, %340 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_353 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_354 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_353, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_354 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_355 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_351 : memref<1x64x30x40xi8>) outs(%alloc_355 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_356 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_355, %339 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_356 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_357 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_356, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_357 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_358 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_354, %alloc_357 : memref<1x64x30x40xi32>, memref<1x64x30x40xi32>) outs(%alloc_358 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_359 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_358, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_359 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_360 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_359, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_360 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_361 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_360 : memref<1x64x30x40xi32>) outs(%alloc_361 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_362 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_361 : memref<1x64x30x40xi8>) outs(%alloc_362 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_363 = memref.collapse_shape %112 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_364 = memref.expand_shape %collapse_shape_363 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_365 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%111 : memref<64xi32>) outs(%alloc_365 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_362, %expand_shape_364 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_365 : memref<1x30x40x64xi32>)
    %alloc_366 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_365 : memref<1x30x40x64xi32>) outs(%alloc_366 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_367 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_366, %338 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_367 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_368 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_367, %337 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_368 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_369 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_368 : memref<1x30x40x64xf32>) outs(%alloc_369 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_370 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_369 : memref<1x64x30x40xf32>) outs(%alloc_370 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_371 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_369, %alloc_370 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_371 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_372 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_371, %336 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_372 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_373 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_372 : memref<1x64x30x40xf32>) outs(%alloc_373 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_374 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_373 : memref<1x64x30x40xf32>) outs(%alloc_374 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_375 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_374 : memref<1x64x30x40xi8>) outs(%alloc_375 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_376 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%110 : memref<64x64x3x3xi8>) outs(%alloc_376 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_377 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_377 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_378 = memref.subview %alloc_377[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_375, %subview_378 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_379 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%109 : memref<64xi32>) outs(%alloc_379 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_377, %alloc_376 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_379 : memref<1x30x40x64xi32>)
    %alloc_380 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_379 : memref<1x30x40x64xi32>) outs(%alloc_380 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_381 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_380, %335 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_381 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_382 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_381, %334 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_382 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_383 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_382 : memref<1x30x40x64xf32>) outs(%alloc_383 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_384 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_383 : memref<1x64x30x40xf32>) outs(%alloc_384 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_385 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_383, %alloc_384 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_385 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_386 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_385, %333 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_386 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_387 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_386 : memref<1x64x30x40xf32>) outs(%alloc_387 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_388 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_387 : memref<1x64x30x40xf32>) outs(%alloc_388 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_389 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_361 : memref<1x64x30x40xi8>) outs(%alloc_389 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_390 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_389, %332 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_390 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_391 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_390, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_391 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_392 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_388 : memref<1x64x30x40xi8>) outs(%alloc_392 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_393 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_392, %331 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_393 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_394 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_393, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_394 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_395 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_391, %alloc_394 : memref<1x64x30x40xi32>, memref<1x64x30x40xi32>) outs(%alloc_395 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_396 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_395, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_396 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_397 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_396, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_397 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_398 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_397 : memref<1x64x30x40xi32>) outs(%alloc_398 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_399 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_274 : memref<1x128x30x40xi8>) outs(%alloc_399 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_400 = memref.collapse_shape %108 [[0], [1, 2, 3]] : memref<64x128x1x1xi8> into memref<64x128xi8>
    %expand_shape_401 = memref.expand_shape %collapse_shape_400 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : memref<64x128xi8> into memref<64x1x1x128xi8>
    %alloc_402 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%107 : memref<64xi32>) outs(%alloc_402 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_399, %expand_shape_401 : memref<1x30x40x128xi8>, memref<64x1x1x128xi8>) outs(%alloc_402 : memref<1x30x40x64xi32>)
    %alloc_403 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_402 : memref<1x30x40x64xi32>) outs(%alloc_403 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_404 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_403, %330 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_404 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_405 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_404, %334 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_405 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_406 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_405 : memref<1x30x40x64xf32>) outs(%alloc_406 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_407 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_406 : memref<1x64x30x40xf32>) outs(%alloc_407 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_408 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_406, %alloc_407 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_408 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_409 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_408, %329 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_409 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_410 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_409 : memref<1x64x30x40xf32>) outs(%alloc_410 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_411 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_410 : memref<1x64x30x40xf32>) outs(%alloc_411 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_412 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_398 : memref<1x64x30x40xi8>) outs(%alloc_412 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_413 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_412, %328 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_413 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_414 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_413, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_414 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_415 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_414, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_415 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_416 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_415, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_416 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_417 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_416 : memref<1x64x30x40xi32>) outs(%alloc_417 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_418 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_411 : memref<1x64x30x40xi8>) outs(%alloc_418 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_419 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_418, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_419 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_420 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_419, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_420 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_421 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_420 : memref<1x64x30x40xi32>) outs(%alloc_421 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_422 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_423 = memref.subview %alloc_422[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_417, %subview_423 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_424 = memref.subview %alloc_422[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_421, %subview_424 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_425 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_422 : memref<1x128x30x40xi8>) outs(%alloc_425 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_426 = memref.collapse_shape %106 [[0], [1, 2, 3]] : memref<128x128x1x1xi8> into memref<128x128xi8>
    %expand_shape_427 = memref.expand_shape %collapse_shape_426 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : memref<128x128xi8> into memref<128x1x1x128xi8>
    %alloc_428 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%105 : memref<128xi32>) outs(%alloc_428 : memref<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_425, %expand_shape_427 : memref<1x30x40x128xi8>, memref<128x1x1x128xi8>) outs(%alloc_428 : memref<1x30x40x128xi32>)
    %alloc_429 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_428 : memref<1x30x40x128xi32>) outs(%alloc_429 : memref<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_430 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_429, %327 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_430 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_431 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_430, %326 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_431 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_432 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.transpose ins(%alloc_431 : memref<1x30x40x128xf32>) outs(%alloc_432 : memref<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_433 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_432 : memref<1x128x30x40xf32>) outs(%alloc_433 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_434 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_432, %alloc_433 : memref<1x128x30x40xf32>, memref<1x128x30x40xf32>) outs(%alloc_434 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_435 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_434, %325 : memref<1x128x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_435 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_436 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_435 : memref<1x128x30x40xf32>) outs(%alloc_436 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_437 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_436 : memref<1x128x30x40xf32>) outs(%alloc_437 : memref<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_438 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_437 : memref<1x128x30x40xi8>) outs(%alloc_438 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_439 = memref.alloc() {alignment = 64 : i64} : memref<256x3x3x128xi8>
    linalg.transpose ins(%104 : memref<256x128x3x3xi8>) outs(%alloc_439 : memref<256x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_440 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    linalg.map outs(%alloc_440 : memref<1x31x41x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_441 = memref.subview %alloc_440[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_438, %subview_441 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_442 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%103 : memref<256xi32>) outs(%alloc_442 : memref<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_440, %alloc_439 : memref<1x31x41x128xi8>, memref<256x3x3x128xi8>) outs(%alloc_442 : memref<1x15x20x256xi32>)
    %alloc_443 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_442 : memref<1x15x20x256xi32>) outs(%alloc_443 : memref<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_444 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_443, %324 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_444 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_445 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_444, %323 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_445 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_446 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.transpose ins(%alloc_445 : memref<1x15x20x256xf32>) outs(%alloc_446 : memref<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_447 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_446 : memref<1x256x15x20xf32>) outs(%alloc_447 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_448 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_446, %alloc_447 : memref<1x256x15x20xf32>, memref<1x256x15x20xf32>) outs(%alloc_448 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_449 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_448, %322 : memref<1x256x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_449 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_450 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_449 : memref<1x256x15x20xf32>) outs(%alloc_450 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_451 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_450 : memref<1x256x15x20xf32>) outs(%alloc_451 : memref<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_452 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_451 : memref<1x256x15x20xi8>) outs(%alloc_452 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_453 = memref.collapse_shape %102 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_454 = memref.expand_shape %collapse_shape_453 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_455 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%101 : memref<128xi32>) outs(%alloc_455 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_452, %expand_shape_454 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_455 : memref<1x15x20x128xi32>)
    %alloc_456 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_455 : memref<1x15x20x128xi32>) outs(%alloc_456 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_457 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_456, %321 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_457 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_458 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_457, %320 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_458 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_459 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_458 : memref<1x15x20x128xf32>) outs(%alloc_459 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_460 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_459 : memref<1x128x15x20xf32>) outs(%alloc_460 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_461 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_459, %alloc_460 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_461 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_462 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_461, %319 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_462 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_463 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_462 : memref<1x128x15x20xf32>) outs(%alloc_463 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_464 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_463 : memref<1x128x15x20xf32>) outs(%alloc_464 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_465 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_464 : memref<1x128x15x20xi8>) outs(%alloc_465 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_466 = memref.collapse_shape %100 [[0], [1, 2, 3]] : memref<128x128x1x1xi8> into memref<128x128xi8>
    %expand_shape_467 = memref.expand_shape %collapse_shape_466 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : memref<128x128xi8> into memref<128x1x1x128xi8>
    %alloc_468 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%99 : memref<128xi32>) outs(%alloc_468 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_465, %expand_shape_467 : memref<1x15x20x128xi8>, memref<128x1x1x128xi8>) outs(%alloc_468 : memref<1x15x20x128xi32>)
    %alloc_469 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_468 : memref<1x15x20x128xi32>) outs(%alloc_469 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_470 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_469, %318 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_470 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_471 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_470, %317 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_471 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_472 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_471 : memref<1x15x20x128xf32>) outs(%alloc_472 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_473 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_472 : memref<1x128x15x20xf32>) outs(%alloc_473 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_474 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_472, %alloc_473 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_474 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_475 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_474, %316 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_475 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_476 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_475 : memref<1x128x15x20xf32>) outs(%alloc_476 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_477 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_476 : memref<1x128x15x20xf32>) outs(%alloc_477 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_478 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_477 : memref<1x128x15x20xi8>) outs(%alloc_478 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_479 = memref.alloc() {alignment = 64 : i64} : memref<128x3x3x128xi8>
    linalg.transpose ins(%98 : memref<128x128x3x3xi8>) outs(%alloc_479 : memref<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_480 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    linalg.map outs(%alloc_480 : memref<1x17x22x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_481 = memref.subview %alloc_480[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_478, %subview_481 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_482 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%97 : memref<128xi32>) outs(%alloc_482 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_480, %alloc_479 : memref<1x17x22x128xi8>, memref<128x3x3x128xi8>) outs(%alloc_482 : memref<1x15x20x128xi32>)
    %alloc_483 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_482 : memref<1x15x20x128xi32>) outs(%alloc_483 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_484 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_483, %315 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_484 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_485 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_484, %314 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_485 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_486 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_485 : memref<1x15x20x128xf32>) outs(%alloc_486 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_487 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_486 : memref<1x128x15x20xf32>) outs(%alloc_487 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_488 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_486, %alloc_487 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_488 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_489 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_488, %313 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_489 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_490 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_489 : memref<1x128x15x20xf32>) outs(%alloc_490 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_491 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_490 : memref<1x128x15x20xf32>) outs(%alloc_491 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_492 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_464 : memref<1x128x15x20xi8>) outs(%alloc_492 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_493 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_492, %312 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_493 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_494 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_493, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_494 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_495 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_491 : memref<1x128x15x20xi8>) outs(%alloc_495 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_496 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_495, %311 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_496 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_497 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_496, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_497 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_498 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_494, %alloc_497 : memref<1x128x15x20xi32>, memref<1x128x15x20xi32>) outs(%alloc_498 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.addi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_499 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_498, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_499 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_500 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_499, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_500 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_501 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_500 : memref<1x128x15x20xi32>) outs(%alloc_501 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_502 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_451 : memref<1x256x15x20xi8>) outs(%alloc_502 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_503 = memref.collapse_shape %96 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_504 = memref.expand_shape %collapse_shape_503 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_505 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%95 : memref<128xi32>) outs(%alloc_505 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_502, %expand_shape_504 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_505 : memref<1x15x20x128xi32>)
    %alloc_506 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_505 : memref<1x15x20x128xi32>) outs(%alloc_506 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_507 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_506, %310 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_507 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_508 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_507, %314 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_508 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_509 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_508 : memref<1x15x20x128xf32>) outs(%alloc_509 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_510 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_509 : memref<1x128x15x20xf32>) outs(%alloc_510 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_511 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_509, %alloc_510 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_511 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_512 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_511, %309 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_512 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_513 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_512 : memref<1x128x15x20xf32>) outs(%alloc_513 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_514 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_513 : memref<1x128x15x20xf32>) outs(%alloc_514 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_515 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_501 : memref<1x128x15x20xi8>) outs(%alloc_515 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_516 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_515, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_516 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_517 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_516, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_517 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_518 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_517 : memref<1x128x15x20xi32>) outs(%alloc_518 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_519 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_514 : memref<1x128x15x20xi8>) outs(%alloc_519 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_520 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_519, %308 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_520 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_521 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_520, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_521 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_522 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_521, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_522 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_523 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_522, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_523 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_524 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_523 : memref<1x128x15x20xi32>) outs(%alloc_524 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_525 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_526 = memref.subview %alloc_525[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_518, %subview_526 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_527 = memref.subview %alloc_525[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_524, %subview_527 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_528 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_525 : memref<1x256x15x20xi8>) outs(%alloc_528 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_529 = memref.collapse_shape %94 [[0], [1, 2, 3]] : memref<256x256x1x1xi8> into memref<256x256xi8>
    %expand_shape_530 = memref.expand_shape %collapse_shape_529 [[0, 1, 2], [3]] output_shape [256, 1, 1, 256] : memref<256x256xi8> into memref<256x1x1x256xi8>
    %alloc_531 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%93 : memref<256xi32>) outs(%alloc_531 : memref<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_528, %expand_shape_530 : memref<1x15x20x256xi8>, memref<256x1x1x256xi8>) outs(%alloc_531 : memref<1x15x20x256xi32>)
    %alloc_532 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_531 : memref<1x15x20x256xi32>) outs(%alloc_532 : memref<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_533 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_532, %307 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_533 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_534 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_533, %306 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_534 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_535 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.transpose ins(%alloc_534 : memref<1x15x20x256xf32>) outs(%alloc_535 : memref<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_536 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_535 : memref<1x256x15x20xf32>) outs(%alloc_536 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_537 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_535, %alloc_536 : memref<1x256x15x20xf32>, memref<1x256x15x20xf32>) outs(%alloc_537 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_538 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_537, %305 : memref<1x256x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_538 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_539 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_538 : memref<1x256x15x20xf32>) outs(%alloc_539 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_540 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_539 : memref<1x256x15x20xf32>) outs(%alloc_540 : memref<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_541 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_540 : memref<1x256x15x20xi8>) outs(%alloc_541 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_542 = memref.collapse_shape %92 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_543 = memref.expand_shape %collapse_shape_542 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_544 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%91 : memref<128xi32>) outs(%alloc_544 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_541, %expand_shape_543 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_544 : memref<1x15x20x128xi32>)
    %alloc_545 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_544 : memref<1x15x20x128xi32>) outs(%alloc_545 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_546 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_545, %304 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_546 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_547 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_546, %303 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_547 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_548 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_547 : memref<1x15x20x128xf32>) outs(%alloc_548 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_549 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_548 : memref<1x128x15x20xf32>) outs(%alloc_549 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_550 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_548, %alloc_549 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_550 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_551 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_550, %302 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_551 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_552 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_551 : memref<1x128x15x20xf32>) outs(%alloc_552 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_553 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_552 : memref<1x128x15x20xf32>) outs(%alloc_553 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_554 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_553 : memref<1x128x15x20xi8>) outs(%alloc_554 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_555 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    linalg.map outs(%alloc_555 : memref<1x19x24x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c-128_i8 : i8
      }
    %subview_556 = memref.subview %alloc_555[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_554, %subview_556 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_557 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.fill ins(%c-128_i8 : i8) outs(%alloc_557 : memref<1x15x20x128xi8>)
    %alloc_558 = memref.alloc() {alignment = 64 : i64} : memref<5x5xi8>
    linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%alloc_555, %alloc_558 : memref<1x19x24x128xi8>, memref<5x5xi8>) outs(%alloc_557 : memref<1x15x20x128xi8>)
    %alloc_559 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.transpose ins(%alloc_557 : memref<1x15x20x128xi8>) outs(%alloc_559 : memref<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %alloc_560 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    linalg.map outs(%alloc_560 : memref<1x19x24x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c-128_i8 : i8
      }
    %subview_561 = memref.subview %alloc_560[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_557, %subview_561 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_562 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.fill ins(%c-128_i8 : i8) outs(%alloc_562 : memref<1x15x20x128xi8>)
    %alloc_563 = memref.alloc() {alignment = 64 : i64} : memref<5x5xi8>
    linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%alloc_560, %alloc_563 : memref<1x19x24x128xi8>, memref<5x5xi8>) outs(%alloc_562 : memref<1x15x20x128xi8>)
    %alloc_564 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.transpose ins(%alloc_562 : memref<1x15x20x128xi8>) outs(%alloc_564 : memref<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %alloc_565 = memref.alloc() {alignment = 64 : i64} : memref<1x19x24x128xi8>
    linalg.map outs(%alloc_565 : memref<1x19x24x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c-128_i8 : i8
      }
    %subview_566 = memref.subview %alloc_565[0, 2, 2, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x19x24x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    memref.copy %alloc_562, %subview_566 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[58368, 3072, 128, 1], offset: 6400>>
    %alloc_567 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.fill ins(%c-128_i8 : i8) outs(%alloc_567 : memref<1x15x20x128xi8>)
    %alloc_568 = memref.alloc() {alignment = 64 : i64} : memref<5x5xi8>
    linalg.pooling_nhwc_max {dilations = dense<1> : vector<2xi64>, strides = dense<1> : vector<2xi64>} ins(%alloc_565, %alloc_568 : memref<1x19x24x128xi8>, memref<5x5xi8>) outs(%alloc_567 : memref<1x15x20x128xi8>)
    %alloc_569 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.transpose ins(%alloc_567 : memref<1x15x20x128xi8>) outs(%alloc_569 : memref<1x128x15x20xi8>) permutation = [0, 3, 1, 2] 
    %alloc_570 = memref.alloc() {alignment = 64 : i64} : memref<1x512x15x20xi8>
    %subview_571 = memref.subview %alloc_570[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    memref.copy %alloc_553, %subview_571 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1]>>
    %subview_572 = memref.subview %alloc_570[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_559, %subview_572 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 38400>>
    %subview_573 = memref.subview %alloc_570[0, 256, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    memref.copy %alloc_564, %subview_573 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 76800>>
    %subview_574 = memref.subview %alloc_570[0, 384, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x512x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    memref.copy %alloc_569, %subview_574 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[153600, 300, 20, 1], offset: 115200>>
    %alloc_575 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x512xi8>
    linalg.transpose ins(%alloc_570 : memref<1x512x15x20xi8>) outs(%alloc_575 : memref<1x15x20x512xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_576 = memref.collapse_shape %90 [[0], [1, 2, 3]] : memref<256x512x1x1xi8> into memref<256x512xi8>
    %expand_shape_577 = memref.expand_shape %collapse_shape_576 [[0, 1, 2], [3]] output_shape [256, 1, 1, 512] : memref<256x512xi8> into memref<256x1x1x512xi8>
    %alloc_578 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%89 : memref<256xi32>) outs(%alloc_578 : memref<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_575, %expand_shape_577 : memref<1x15x20x512xi8>, memref<256x1x1x512xi8>) outs(%alloc_578 : memref<1x15x20x256xi32>)
    %alloc_579 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_578 : memref<1x15x20x256xi32>) outs(%alloc_579 : memref<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_580 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_579, %301 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_580 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_581 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_580, %300 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_581 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_582 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.transpose ins(%alloc_581 : memref<1x15x20x256xf32>) outs(%alloc_582 : memref<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_583 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_582 : memref<1x256x15x20xf32>) outs(%alloc_583 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_584 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_582, %alloc_583 : memref<1x256x15x20xf32>, memref<1x256x15x20xf32>) outs(%alloc_584 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_585 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_584, %299 : memref<1x256x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_585 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_586 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_585 : memref<1x256x15x20xf32>) outs(%alloc_586 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_587 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_586 : memref<1x256x15x20xf32>) outs(%alloc_587 : memref<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_588 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_587 : memref<1x256x15x20xi8>) outs(%alloc_588 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_589 = memref.collapse_shape %88 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_590 = memref.expand_shape %collapse_shape_589 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_591 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%87 : memref<128xi32>) outs(%alloc_591 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_588, %expand_shape_590 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_591 : memref<1x15x20x128xi32>)
    %alloc_592 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_591 : memref<1x15x20x128xi32>) outs(%alloc_592 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_593 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_592, %298 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_593 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_594 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_593, %297 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_594 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_595 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_594 : memref<1x15x20x128xf32>) outs(%alloc_595 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_596 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_595 : memref<1x128x15x20xf32>) outs(%alloc_596 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_597 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_595, %alloc_596 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_597 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_598 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_597, %296 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_598 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_599 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_598 : memref<1x128x15x20xf32>) outs(%alloc_599 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_600 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_599 : memref<1x128x15x20xf32>) outs(%alloc_600 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_601 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_600 : memref<1x128x15x20xi8>) outs(%alloc_601 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_602 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.generic {indexing_maps = [#map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} outs(%alloc_602 : memref<1x30x40x128xi8>) {
    ^bb0(%out: i8):
      %419 = linalg.index 1 : index
      %420 = linalg.index 2 : index
      %421 = linalg.index 3 : index
      %422 = arith.index_cast %419 : index to i32
      %423 = arith.index_cast %420 : index to i32
      %424 = arith.divsi %422, %c2_i32 : i32
      %425 = arith.muli %424, %c2_i32 : i32
      %426 = arith.subi %422, %425 : i32
      %427 = arith.divsi %423, %c2_i32 : i32
      %428 = arith.muli %427, %c2_i32 : i32
      %429 = arith.subi %423, %428 : i32
      %430 = arith.shli %426, %c1_i32 : i32
      %431 = arith.cmpi sge, %430, %c2_i32 : i32
      %432 = arith.extui %431 : i1 to i32
      %433 = arith.addi %424, %432 : i32
      %434 = arith.maxsi %433, %c0_i32 : i32
      %435 = arith.minsi %434, %c14_i32 : i32
      %436 = arith.index_cast %435 : i32 to index
      %437 = arith.shli %429, %c1_i32 : i32
      %438 = arith.cmpi sge, %437, %c2_i32 : i32
      %439 = arith.extui %438 : i1 to i32
      %440 = arith.addi %427, %439 : i32
      %441 = arith.maxsi %440, %c0_i32 : i32
      %442 = arith.minsi %441, %c19_i32 : i32
      %443 = arith.index_cast %442 : i32 to index
      %444 = memref.load %alloc_601[%c0, %436, %443, %421] : memref<1x15x20x128xi8>
      linalg.yield %444 : i8
    }
    %alloc_603 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.transpose ins(%alloc_602 : memref<1x30x40x128xi8>) outs(%alloc_603 : memref<1x128x30x40xi8>) permutation = [0, 3, 1, 2] 
    %alloc_604 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_603 : memref<1x128x30x40xi8>) outs(%alloc_604 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_605 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_604, %295 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_605 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_606 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_605, %400 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_606 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_607 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_606, %398 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_607 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_608 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_607, %397 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_608 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_609 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_608 : memref<1x128x30x40xi32>) outs(%alloc_609 : memref<1x128x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_610 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_437 : memref<1x128x30x40xi8>) outs(%alloc_610 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_611 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_610, %294 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_611 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_612 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_611, %400 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_612 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_613 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_612, %398 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_613 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_614 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_613, %397 : memref<1x128x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_614 : memref<1x128x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_615 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_614 : memref<1x128x30x40xi32>) outs(%alloc_615 : memref<1x128x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_616 = memref.alloc() {alignment = 64 : i64} : memref<1x256x30x40xi8>
    %subview_617 = memref.subview %alloc_616[0, 0, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    memref.copy %alloc_609, %subview_617 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1]>>
    %subview_618 = memref.subview %alloc_616[0, 128, 0, 0] [1, 128, 30, 40] [1, 1, 1, 1] : memref<1x256x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    memref.copy %alloc_615, %subview_618 : memref<1x128x30x40xi8> to memref<1x128x30x40xi8, strided<[307200, 1200, 40, 1], offset: 153600>>
    %alloc_619 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    linalg.transpose ins(%alloc_616 : memref<1x256x30x40xi8>) outs(%alloc_619 : memref<1x30x40x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_620 = memref.collapse_shape %86 [[0], [1, 2, 3]] : memref<64x256x1x1xi8> into memref<64x256xi8>
    %expand_shape_621 = memref.expand_shape %collapse_shape_620 [[0, 1, 2], [3]] output_shape [64, 1, 1, 256] : memref<64x256xi8> into memref<64x1x1x256xi8>
    %alloc_622 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%85 : memref<64xi32>) outs(%alloc_622 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_619, %expand_shape_621 : memref<1x30x40x256xi8>, memref<64x1x1x256xi8>) outs(%alloc_622 : memref<1x30x40x64xi32>)
    %alloc_623 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_622 : memref<1x30x40x64xi32>) outs(%alloc_623 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_624 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_623, %293 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_624 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_625 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_624, %292 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_625 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_626 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_625 : memref<1x30x40x64xf32>) outs(%alloc_626 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_627 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_626 : memref<1x64x30x40xf32>) outs(%alloc_627 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_628 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_626, %alloc_627 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_628 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_629 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_628, %291 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_629 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_630 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_629 : memref<1x64x30x40xf32>) outs(%alloc_630 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_631 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_630 : memref<1x64x30x40xf32>) outs(%alloc_631 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_632 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_631 : memref<1x64x30x40xi8>) outs(%alloc_632 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_633 = memref.collapse_shape %84 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_634 = memref.expand_shape %collapse_shape_633 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_635 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%83 : memref<64xi32>) outs(%alloc_635 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_632, %expand_shape_634 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_635 : memref<1x30x40x64xi32>)
    %alloc_636 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_635 : memref<1x30x40x64xi32>) outs(%alloc_636 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_637 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_636, %290 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_637 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_638 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_637, %289 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_638 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_639 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_638 : memref<1x30x40x64xf32>) outs(%alloc_639 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_640 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_639 : memref<1x64x30x40xf32>) outs(%alloc_640 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_641 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_639, %alloc_640 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_641 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_642 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_641, %288 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_642 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_643 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_642 : memref<1x64x30x40xf32>) outs(%alloc_643 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_644 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_643 : memref<1x64x30x40xf32>) outs(%alloc_644 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_645 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_644 : memref<1x64x30x40xi8>) outs(%alloc_645 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_646 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%82 : memref<64x64x3x3xi8>) outs(%alloc_646 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_647 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_647 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_648 = memref.subview %alloc_647[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_645, %subview_648 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_649 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%81 : memref<64xi32>) outs(%alloc_649 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_647, %alloc_646 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_649 : memref<1x30x40x64xi32>)
    %alloc_650 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_649 : memref<1x30x40x64xi32>) outs(%alloc_650 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_651 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_650, %287 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_651 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_652 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_651, %286 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_652 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_653 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_652 : memref<1x30x40x64xf32>) outs(%alloc_653 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_654 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_653 : memref<1x64x30x40xf32>) outs(%alloc_654 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_655 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_653, %alloc_654 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_655 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_656 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_655, %285 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_656 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_657 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_656 : memref<1x64x30x40xf32>) outs(%alloc_657 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_658 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_657 : memref<1x64x30x40xf32>) outs(%alloc_658 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_659 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x256xi8>
    linalg.transpose ins(%alloc_616 : memref<1x256x30x40xi8>) outs(%alloc_659 : memref<1x30x40x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_660 = memref.collapse_shape %80 [[0], [1, 2, 3]] : memref<64x256x1x1xi8> into memref<64x256xi8>
    %expand_shape_661 = memref.expand_shape %collapse_shape_660 [[0, 1, 2], [3]] output_shape [64, 1, 1, 256] : memref<64x256xi8> into memref<64x1x1x256xi8>
    %alloc_662 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%79 : memref<64xi32>) outs(%alloc_662 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_659, %expand_shape_661 : memref<1x30x40x256xi8>, memref<64x1x1x256xi8>) outs(%alloc_662 : memref<1x30x40x64xi32>)
    %alloc_663 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_662 : memref<1x30x40x64xi32>) outs(%alloc_663 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_664 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_663, %284 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_664 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_665 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_664, %286 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_665 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_666 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_665 : memref<1x30x40x64xf32>) outs(%alloc_666 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_667 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_666 : memref<1x64x30x40xf32>) outs(%alloc_667 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_668 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_666, %alloc_667 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_668 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_669 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_668, %283 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_669 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_670 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_669 : memref<1x64x30x40xf32>) outs(%alloc_670 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_671 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_670 : memref<1x64x30x40xf32>) outs(%alloc_671 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_672 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_658 : memref<1x64x30x40xi8>) outs(%alloc_672 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_673 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_672, %282 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_673 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_674 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_673, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_674 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_675 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_674, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_675 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_676 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_675, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_676 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_677 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_676 : memref<1x64x30x40xi32>) outs(%alloc_677 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_678 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_671 : memref<1x64x30x40xi8>) outs(%alloc_678 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_679 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_678, %281 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_679 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_680 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_679, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_680 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_681 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_680, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_681 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_682 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_681, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_682 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_683 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_682 : memref<1x64x30x40xi32>) outs(%alloc_683 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_684 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_685 = memref.subview %alloc_684[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_677, %subview_685 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_686 = memref.subview %alloc_684[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_683, %subview_686 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_687 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_684 : memref<1x128x30x40xi8>) outs(%alloc_687 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_688 = memref.collapse_shape %78 [[0], [1, 2, 3]] : memref<128x128x1x1xi8> into memref<128x128xi8>
    %expand_shape_689 = memref.expand_shape %collapse_shape_688 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : memref<128x128xi8> into memref<128x1x1x128xi8>
    %alloc_690 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%77 : memref<128xi32>) outs(%alloc_690 : memref<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_687, %expand_shape_689 : memref<1x30x40x128xi8>, memref<128x1x1x128xi8>) outs(%alloc_690 : memref<1x30x40x128xi32>)
    %alloc_691 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_690 : memref<1x30x40x128xi32>) outs(%alloc_691 : memref<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_692 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_691, %280 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_692 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_693 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_692, %279 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_693 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_694 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.transpose ins(%alloc_693 : memref<1x30x40x128xf32>) outs(%alloc_694 : memref<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_695 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_694 : memref<1x128x30x40xf32>) outs(%alloc_695 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_696 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_694, %alloc_695 : memref<1x128x30x40xf32>, memref<1x128x30x40xf32>) outs(%alloc_696 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_697 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_696, %278 : memref<1x128x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_697 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_698 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_697 : memref<1x128x30x40xf32>) outs(%alloc_698 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_699 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_698 : memref<1x128x30x40xf32>) outs(%alloc_699 : memref<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_700 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_699 : memref<1x128x30x40xi8>) outs(%alloc_700 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_701 = memref.collapse_shape %76 [[0], [1, 2, 3]] : memref<64x128x1x1xi8> into memref<64x128xi8>
    %expand_shape_702 = memref.expand_shape %collapse_shape_701 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : memref<64x128xi8> into memref<64x1x1x128xi8>
    %alloc_703 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%75 : memref<64xi32>) outs(%alloc_703 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_700, %expand_shape_702 : memref<1x30x40x128xi8>, memref<64x1x1x128xi8>) outs(%alloc_703 : memref<1x30x40x64xi32>)
    %alloc_704 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_703 : memref<1x30x40x64xi32>) outs(%alloc_704 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_705 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_704, %277 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_705 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_706 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_705, %276 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_706 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_707 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_706 : memref<1x30x40x64xf32>) outs(%alloc_707 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_708 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_707 : memref<1x64x30x40xf32>) outs(%alloc_708 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_709 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_707, %alloc_708 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_709 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_710 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_709, %275 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_710 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_711 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_710 : memref<1x64x30x40xf32>) outs(%alloc_711 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_712 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_711 : memref<1x64x30x40xf32>) outs(%alloc_712 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_713 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_712 : memref<1x64x30x40xi8>) outs(%alloc_713 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_714 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.generic {indexing_maps = [#map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} outs(%alloc_714 : memref<1x60x80x64xi8>) {
    ^bb0(%out: i8):
      %419 = linalg.index 1 : index
      %420 = linalg.index 2 : index
      %421 = linalg.index 3 : index
      %422 = arith.index_cast %419 : index to i32
      %423 = arith.index_cast %420 : index to i32
      %424 = arith.divsi %422, %c2_i32 : i32
      %425 = arith.muli %424, %c2_i32 : i32
      %426 = arith.subi %422, %425 : i32
      %427 = arith.divsi %423, %c2_i32 : i32
      %428 = arith.muli %427, %c2_i32 : i32
      %429 = arith.subi %423, %428 : i32
      %430 = arith.shli %426, %c1_i32 : i32
      %431 = arith.cmpi sge, %430, %c2_i32 : i32
      %432 = arith.extui %431 : i1 to i32
      %433 = arith.addi %424, %432 : i32
      %434 = arith.maxsi %433, %c0_i32 : i32
      %435 = arith.minsi %434, %c29_i32 : i32
      %436 = arith.index_cast %435 : i32 to index
      %437 = arith.shli %429, %c1_i32 : i32
      %438 = arith.cmpi sge, %437, %c2_i32 : i32
      %439 = arith.extui %438 : i1 to i32
      %440 = arith.addi %427, %439 : i32
      %441 = arith.maxsi %440, %c0_i32 : i32
      %442 = arith.minsi %441, %c39_i32 : i32
      %443 = arith.index_cast %442 : i32 to index
      %444 = memref.load %alloc_713[%c0, %436, %443, %421] : memref<1x30x40x64xi8>
      linalg.yield %444 : i8
    }
    %alloc_715 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.transpose ins(%alloc_714 : memref<1x60x80x64xi8>) outs(%alloc_715 : memref<1x64x60x80xi8>) permutation = [0, 3, 1, 2] 
    %alloc_716 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_715 : memref<1x64x60x80xi8>) outs(%alloc_716 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_717 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_716, %274 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_717 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_718 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_717, %400 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_718 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_719 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_718, %398 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_719 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_720 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_719, %397 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_720 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_721 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_720 : memref<1x64x60x80xi32>) outs(%alloc_721 : memref<1x64x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_722 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_260 : memref<1x64x60x80xi8>) outs(%alloc_722 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_723 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_722, %273 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_723 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_724 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_723, %400 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_724 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_725 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_724, %398 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_725 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_726 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_725, %397 : memref<1x64x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_726 : memref<1x64x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_727 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_726 : memref<1x64x60x80xi32>) outs(%alloc_727 : memref<1x64x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_728 = memref.alloc() {alignment = 64 : i64} : memref<1x128x60x80xi8>
    %subview_729 = memref.subview %alloc_728[0, 0, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    memref.copy %alloc_721, %subview_729 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1]>>
    %subview_730 = memref.subview %alloc_728[0, 64, 0, 0] [1, 64, 60, 80] [1, 1, 1, 1] : memref<1x128x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    memref.copy %alloc_727, %subview_730 : memref<1x64x60x80xi8> to memref<1x64x60x80xi8, strided<[614400, 4800, 80, 1], offset: 307200>>
    %alloc_731 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    linalg.transpose ins(%alloc_728 : memref<1x128x60x80xi8>) outs(%alloc_731 : memref<1x60x80x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_732 = memref.collapse_shape %74 [[0], [1, 2, 3]] : memref<32x128x1x1xi8> into memref<32x128xi8>
    %expand_shape_733 = memref.expand_shape %collapse_shape_732 [[0, 1, 2], [3]] output_shape [32, 1, 1, 128] : memref<32x128xi8> into memref<32x1x1x128xi8>
    %alloc_734 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%73 : memref<32xi32>) outs(%alloc_734 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_731, %expand_shape_733 : memref<1x60x80x128xi8>, memref<32x1x1x128xi8>) outs(%alloc_734 : memref<1x60x80x32xi32>)
    %alloc_735 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_734 : memref<1x60x80x32xi32>) outs(%alloc_735 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_736 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_735, %272 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_736 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_737 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_736, %271 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_737 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_738 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_737 : memref<1x60x80x32xf32>) outs(%alloc_738 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_739 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_738 : memref<1x32x60x80xf32>) outs(%alloc_739 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_740 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_738, %alloc_739 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_740 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_741 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_740, %270 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_741 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_742 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_741 : memref<1x32x60x80xf32>) outs(%alloc_742 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_743 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_742 : memref<1x32x60x80xf32>) outs(%alloc_743 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_744 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_743 : memref<1x32x60x80xi8>) outs(%alloc_744 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_745 = memref.collapse_shape %72 [[0], [1, 2, 3]] : memref<32x32x1x1xi8> into memref<32x32xi8>
    %expand_shape_746 = memref.expand_shape %collapse_shape_745 [[0, 1, 2], [3]] output_shape [32, 1, 1, 32] : memref<32x32xi8> into memref<32x1x1x32xi8>
    %alloc_747 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%71 : memref<32xi32>) outs(%alloc_747 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_744, %expand_shape_746 : memref<1x60x80x32xi8>, memref<32x1x1x32xi8>) outs(%alloc_747 : memref<1x60x80x32xi32>)
    %alloc_748 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_747 : memref<1x60x80x32xi32>) outs(%alloc_748 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_749 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_748, %269 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_749 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_750 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_749, %268 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_750 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_751 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_750 : memref<1x60x80x32xf32>) outs(%alloc_751 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_752 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_751 : memref<1x32x60x80xf32>) outs(%alloc_752 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_753 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_751, %alloc_752 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_753 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_754 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_753, %267 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_754 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_755 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_754 : memref<1x32x60x80xf32>) outs(%alloc_755 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_756 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_755 : memref<1x32x60x80xf32>) outs(%alloc_756 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_757 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi8>
    linalg.transpose ins(%alloc_756 : memref<1x32x60x80xi8>) outs(%alloc_757 : memref<1x60x80x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_758 = memref.alloc() {alignment = 64 : i64} : memref<32x3x3x32xi8>
    linalg.transpose ins(%70 : memref<32x32x3x3xi8>) outs(%alloc_758 : memref<32x3x3x32xi8>) permutation = [0, 2, 3, 1] 
    %alloc_759 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x32xi8>
    linalg.map outs(%alloc_759 : memref<1x62x82x32xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_760 = memref.subview %alloc_759[0, 1, 1, 0] [1, 60, 80, 32] [1, 1, 1, 1] : memref<1x62x82x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    memref.copy %alloc_757, %subview_760 : memref<1x60x80x32xi8> to memref<1x60x80x32xi8, strided<[162688, 2624, 32, 1], offset: 2656>>
    %alloc_761 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%69 : memref<32xi32>) outs(%alloc_761 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_759, %alloc_758 : memref<1x62x82x32xi8>, memref<32x3x3x32xi8>) outs(%alloc_761 : memref<1x60x80x32xi32>)
    %alloc_762 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_761 : memref<1x60x80x32xi32>) outs(%alloc_762 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_763 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_762, %266 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_763 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_764 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_763, %265 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_764 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_765 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_764 : memref<1x60x80x32xf32>) outs(%alloc_765 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_766 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_765 : memref<1x32x60x80xf32>) outs(%alloc_766 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_767 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_765, %alloc_766 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_767 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_768 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_767, %264 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_768 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_769 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_768 : memref<1x32x60x80xf32>) outs(%alloc_769 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_770 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_769 : memref<1x32x60x80xf32>) outs(%alloc_770 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_771 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x128xi8>
    linalg.transpose ins(%alloc_728 : memref<1x128x60x80xi8>) outs(%alloc_771 : memref<1x60x80x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_772 = memref.collapse_shape %68 [[0], [1, 2, 3]] : memref<32x128x1x1xi8> into memref<32x128xi8>
    %expand_shape_773 = memref.expand_shape %collapse_shape_772 [[0, 1, 2], [3]] output_shape [32, 1, 1, 128] : memref<32x128xi8> into memref<32x1x1x128xi8>
    %alloc_774 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%67 : memref<32xi32>) outs(%alloc_774 : memref<1x60x80x32xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_771, %expand_shape_773 : memref<1x60x80x128xi8>, memref<32x1x1x128xi8>) outs(%alloc_774 : memref<1x60x80x32xi32>)
    %alloc_775 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_774 : memref<1x60x80x32xi32>) outs(%alloc_775 : memref<1x60x80x32xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_776 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_775, %263 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_776 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_777 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x32xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_776, %265 : memref<1x60x80x32xf32>, memref<1x1x1x1xf32>) outs(%alloc_777 : memref<1x60x80x32xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_778 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.transpose ins(%alloc_777 : memref<1x60x80x32xf32>) outs(%alloc_778 : memref<1x32x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_779 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_778 : memref<1x32x60x80xf32>) outs(%alloc_779 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_780 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_778, %alloc_779 : memref<1x32x60x80xf32>, memref<1x32x60x80xf32>) outs(%alloc_780 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_781 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_780, %262 : memref<1x32x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_781 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_782 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_781 : memref<1x32x60x80xf32>) outs(%alloc_782 : memref<1x32x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_783 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_782 : memref<1x32x60x80xf32>) outs(%alloc_783 : memref<1x32x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_784 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_770 : memref<1x32x60x80xi8>) outs(%alloc_784 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_785 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_784, %261 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_785 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_786 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_785, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_786 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_787 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_786, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_787 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_788 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_787, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_788 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_789 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_788 : memref<1x32x60x80xi32>) outs(%alloc_789 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_790 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_783 : memref<1x32x60x80xi8>) outs(%alloc_790 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_791 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_790, %260 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_791 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_792 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_791, %400 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_792 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_793 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_792, %398 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_793 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_794 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_793, %397 : memref<1x32x60x80xi32>, memref<1x1x1x1xi32>) outs(%alloc_794 : memref<1x32x60x80xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_795 = memref.alloc() {alignment = 64 : i64} : memref<1x32x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_794 : memref<1x32x60x80xi32>) outs(%alloc_795 : memref<1x32x60x80xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_796 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    %subview_797 = memref.subview %alloc_796[0, 0, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    memref.copy %alloc_789, %subview_797 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1]>>
    %subview_798 = memref.subview %alloc_796[0, 32, 0, 0] [1, 32, 60, 80] [1, 1, 1, 1] : memref<1x64x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    memref.copy %alloc_795, %subview_798 : memref<1x32x60x80xi8> to memref<1x32x60x80xi8, strided<[307200, 4800, 80, 1], offset: 153600>>
    %alloc_799 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_796 : memref<1x64x60x80xi8>) outs(%alloc_799 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_800 = memref.collapse_shape %66 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_801 = memref.expand_shape %collapse_shape_800 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_802 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%65 : memref<64xi32>) outs(%alloc_802 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_799, %expand_shape_801 : memref<1x60x80x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_802 : memref<1x60x80x64xi32>)
    %alloc_803 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_802 : memref<1x60x80x64xi32>) outs(%alloc_803 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_804 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_803, %259 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_804 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_805 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_804, %258 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_805 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_806 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_805 : memref<1x60x80x64xf32>) outs(%alloc_806 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_807 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_806 : memref<1x64x60x80xf32>) outs(%alloc_807 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_808 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_806, %alloc_807 : memref<1x64x60x80xf32>, memref<1x64x60x80xf32>) outs(%alloc_808 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_809 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_808, %257 : memref<1x64x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_809 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_810 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_809 : memref<1x64x60x80xf32>) outs(%alloc_810 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_811 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_810 : memref<1x64x60x80xf32>) outs(%alloc_811 : memref<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_812 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_811 : memref<1x64x60x80xi8>) outs(%alloc_812 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_813 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%64 : memref<64x64x3x3xi8>) outs(%alloc_813 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_814 = memref.alloc() {alignment = 64 : i64} : memref<1x61x81x64xi8>
    linalg.map outs(%alloc_814 : memref<1x61x81x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_815 = memref.subview %alloc_814[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x61x81x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    memref.copy %alloc_812, %subview_815 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[316224, 5184, 64, 1], offset: 5248>>
    %alloc_816 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%63 : memref<64xi32>) outs(%alloc_816 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_814, %alloc_813 : memref<1x61x81x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_816 : memref<1x30x40x64xi32>)
    %alloc_817 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_816 : memref<1x30x40x64xi32>) outs(%alloc_817 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_818 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_817, %256 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_818 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_819 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_818, %255 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_819 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_820 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_819 : memref<1x30x40x64xf32>) outs(%alloc_820 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_821 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_820 : memref<1x64x30x40xf32>) outs(%alloc_821 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_822 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_820, %alloc_821 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_822 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_823 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_822, %254 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_823 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_824 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_823 : memref<1x64x30x40xf32>) outs(%alloc_824 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_825 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_824 : memref<1x64x30x40xf32>) outs(%alloc_825 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_826 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_825 : memref<1x64x30x40xi8>) outs(%alloc_826 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_827 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_826, %253 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_827 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_828 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_827, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_828 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_829 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_828, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_829 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_830 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_829, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_830 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_831 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_830 : memref<1x64x30x40xi32>) outs(%alloc_831 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_832 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_712 : memref<1x64x30x40xi8>) outs(%alloc_832 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_833 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_832, %252 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_833 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_834 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_833, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_834 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_835 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_834, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_835 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_836 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_835, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_836 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_837 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_836 : memref<1x64x30x40xi32>) outs(%alloc_837 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_838 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_839 = memref.subview %alloc_838[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_831, %subview_839 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_840 = memref.subview %alloc_838[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_837, %subview_840 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_841 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_838 : memref<1x128x30x40xi8>) outs(%alloc_841 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_842 = memref.collapse_shape %62 [[0], [1, 2, 3]] : memref<64x128x1x1xi8> into memref<64x128xi8>
    %expand_shape_843 = memref.expand_shape %collapse_shape_842 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : memref<64x128xi8> into memref<64x1x1x128xi8>
    %alloc_844 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%61 : memref<64xi32>) outs(%alloc_844 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_841, %expand_shape_843 : memref<1x30x40x128xi8>, memref<64x1x1x128xi8>) outs(%alloc_844 : memref<1x30x40x64xi32>)
    %alloc_845 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_844 : memref<1x30x40x64xi32>) outs(%alloc_845 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_846 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_845, %251 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_846 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_847 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_846, %250 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_847 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_848 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_847 : memref<1x30x40x64xf32>) outs(%alloc_848 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_849 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_848 : memref<1x64x30x40xf32>) outs(%alloc_849 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_850 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_848, %alloc_849 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_850 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_851 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_850, %249 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_851 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_852 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_851 : memref<1x64x30x40xf32>) outs(%alloc_852 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_853 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_852 : memref<1x64x30x40xf32>) outs(%alloc_853 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_854 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_853 : memref<1x64x30x40xi8>) outs(%alloc_854 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_855 = memref.collapse_shape %60 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_856 = memref.expand_shape %collapse_shape_855 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_857 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%59 : memref<64xi32>) outs(%alloc_857 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_854, %expand_shape_856 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_857 : memref<1x30x40x64xi32>)
    %alloc_858 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_857 : memref<1x30x40x64xi32>) outs(%alloc_858 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_859 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_858, %248 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_859 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_860 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_859, %247 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_860 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_861 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_860 : memref<1x30x40x64xf32>) outs(%alloc_861 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_862 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_861 : memref<1x64x30x40xf32>) outs(%alloc_862 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_863 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_861, %alloc_862 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_863 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_864 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_863, %246 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_864 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_865 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_864 : memref<1x64x30x40xf32>) outs(%alloc_865 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_866 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_865 : memref<1x64x30x40xf32>) outs(%alloc_866 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_867 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_866 : memref<1x64x30x40xi8>) outs(%alloc_867 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_868 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%58 : memref<64x64x3x3xi8>) outs(%alloc_868 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_869 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_869 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_870 = memref.subview %alloc_869[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_867, %subview_870 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_871 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%57 : memref<64xi32>) outs(%alloc_871 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_869, %alloc_868 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_871 : memref<1x30x40x64xi32>)
    %alloc_872 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_871 : memref<1x30x40x64xi32>) outs(%alloc_872 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_873 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_872, %245 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_873 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_874 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_873, %244 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_874 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_875 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_874 : memref<1x30x40x64xf32>) outs(%alloc_875 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_876 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_875 : memref<1x64x30x40xf32>) outs(%alloc_876 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_877 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_875, %alloc_876 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_877 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_878 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_877, %243 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_878 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_879 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_878 : memref<1x64x30x40xf32>) outs(%alloc_879 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_880 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_879 : memref<1x64x30x40xf32>) outs(%alloc_880 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_881 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_838 : memref<1x128x30x40xi8>) outs(%alloc_881 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_882 = memref.collapse_shape %56 [[0], [1, 2, 3]] : memref<64x128x1x1xi8> into memref<64x128xi8>
    %expand_shape_883 = memref.expand_shape %collapse_shape_882 [[0, 1, 2], [3]] output_shape [64, 1, 1, 128] : memref<64x128xi8> into memref<64x1x1x128xi8>
    %alloc_884 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%55 : memref<64xi32>) outs(%alloc_884 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_881, %expand_shape_883 : memref<1x30x40x128xi8>, memref<64x1x1x128xi8>) outs(%alloc_884 : memref<1x30x40x64xi32>)
    %alloc_885 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_884 : memref<1x30x40x64xi32>) outs(%alloc_885 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_886 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_885, %242 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_886 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_887 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_886, %244 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_887 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_888 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_887 : memref<1x30x40x64xf32>) outs(%alloc_888 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_889 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_888 : memref<1x64x30x40xf32>) outs(%alloc_889 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_890 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_888, %alloc_889 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_890 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_891 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_890, %241 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_891 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_892 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_891 : memref<1x64x30x40xf32>) outs(%alloc_892 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_893 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_892 : memref<1x64x30x40xf32>) outs(%alloc_893 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_894 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_880 : memref<1x64x30x40xi8>) outs(%alloc_894 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_895 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_894, %240 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_895 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_896 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_895, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_896 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_897 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_896, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_897 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_898 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_897, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_898 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_899 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_898 : memref<1x64x30x40xi32>) outs(%alloc_899 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_900 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_893 : memref<1x64x30x40xi8>) outs(%alloc_900 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_901 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_900, %239 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_901 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_902 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_901, %400 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_902 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_903 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_902, %398 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_903 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_904 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_903, %397 : memref<1x64x30x40xi32>, memref<1x1x1x1xi32>) outs(%alloc_904 : memref<1x64x30x40xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_905 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_904 : memref<1x64x30x40xi32>) outs(%alloc_905 : memref<1x64x30x40xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_906 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    %subview_907 = memref.subview %alloc_906[0, 0, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    memref.copy %alloc_899, %subview_907 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1]>>
    %subview_908 = memref.subview %alloc_906[0, 64, 0, 0] [1, 64, 30, 40] [1, 1, 1, 1] : memref<1x128x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    memref.copy %alloc_905, %subview_908 : memref<1x64x30x40xi8> to memref<1x64x30x40xi8, strided<[153600, 1200, 40, 1], offset: 76800>>
    %alloc_909 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_906 : memref<1x128x30x40xi8>) outs(%alloc_909 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_910 = memref.collapse_shape %54 [[0], [1, 2, 3]] : memref<128x128x1x1xi8> into memref<128x128xi8>
    %expand_shape_911 = memref.expand_shape %collapse_shape_910 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : memref<128x128xi8> into memref<128x1x1x128xi8>
    %alloc_912 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%53 : memref<128xi32>) outs(%alloc_912 : memref<1x30x40x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_909, %expand_shape_911 : memref<1x30x40x128xi8>, memref<128x1x1x128xi8>) outs(%alloc_912 : memref<1x30x40x128xi32>)
    %alloc_913 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_912 : memref<1x30x40x128xi32>) outs(%alloc_913 : memref<1x30x40x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_914 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_913, %238 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_914 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_915 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_914, %237 : memref<1x30x40x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_915 : memref<1x30x40x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_916 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.transpose ins(%alloc_915 : memref<1x30x40x128xf32>) outs(%alloc_916 : memref<1x128x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_917 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_916 : memref<1x128x30x40xf32>) outs(%alloc_917 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_918 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_916, %alloc_917 : memref<1x128x30x40xf32>, memref<1x128x30x40xf32>) outs(%alloc_918 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_919 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_918, %236 : memref<1x128x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_919 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_920 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_919 : memref<1x128x30x40xf32>) outs(%alloc_920 : memref<1x128x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_921 = memref.alloc() {alignment = 64 : i64} : memref<1x128x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_920 : memref<1x128x30x40xf32>) outs(%alloc_921 : memref<1x128x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_922 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_921 : memref<1x128x30x40xi8>) outs(%alloc_922 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_923 = memref.alloc() {alignment = 64 : i64} : memref<128x3x3x128xi8>
    linalg.transpose ins(%52 : memref<128x128x3x3xi8>) outs(%alloc_923 : memref<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_924 = memref.alloc() {alignment = 64 : i64} : memref<1x31x41x128xi8>
    linalg.map outs(%alloc_924 : memref<1x31x41x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_925 = memref.subview %alloc_924[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x31x41x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    memref.copy %alloc_922, %subview_925 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[162688, 5248, 128, 1], offset: 5376>>
    %alloc_926 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%51 : memref<128xi32>) outs(%alloc_926 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<2> : tensor<2xi64>} ins(%alloc_924, %alloc_923 : memref<1x31x41x128xi8>, memref<128x3x3x128xi8>) outs(%alloc_926 : memref<1x15x20x128xi32>)
    %alloc_927 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_926 : memref<1x15x20x128xi32>) outs(%alloc_927 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_928 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_927, %235 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_928 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_929 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_928, %297 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_929 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_930 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_929 : memref<1x15x20x128xf32>) outs(%alloc_930 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_931 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_930 : memref<1x128x15x20xf32>) outs(%alloc_931 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_932 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_930, %alloc_931 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_932 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_933 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_932, %234 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_933 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_934 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_933 : memref<1x128x15x20xf32>) outs(%alloc_934 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_935 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_934 : memref<1x128x15x20xf32>) outs(%alloc_935 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_936 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_935 : memref<1x128x15x20xi8>) outs(%alloc_936 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_937 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_936, %233 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_937 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_938 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_937, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_938 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_939 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_938, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_939 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_940 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_939, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_940 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_941 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_940 : memref<1x128x15x20xi32>) outs(%alloc_941 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_942 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_600 : memref<1x128x15x20xi8>) outs(%alloc_942 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_943 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_942, %232 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_943 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_944 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_943, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_944 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_945 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_944, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_945 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_946 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_945, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_946 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_947 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_946 : memref<1x128x15x20xi32>) outs(%alloc_947 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_948 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_949 = memref.subview %alloc_948[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_941, %subview_949 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_950 = memref.subview %alloc_948[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_947, %subview_950 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_951 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_948 : memref<1x256x15x20xi8>) outs(%alloc_951 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_952 = memref.collapse_shape %50 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_953 = memref.expand_shape %collapse_shape_952 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_954 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%49 : memref<128xi32>) outs(%alloc_954 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_951, %expand_shape_953 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_954 : memref<1x15x20x128xi32>)
    %alloc_955 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_954 : memref<1x15x20x128xi32>) outs(%alloc_955 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_956 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_955, %231 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_956 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_957 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_956, %230 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_957 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_958 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_957 : memref<1x15x20x128xf32>) outs(%alloc_958 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_959 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_958 : memref<1x128x15x20xf32>) outs(%alloc_959 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_960 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_958, %alloc_959 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_960 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_961 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_960, %229 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_961 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_962 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_961 : memref<1x128x15x20xf32>) outs(%alloc_962 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_963 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_962 : memref<1x128x15x20xf32>) outs(%alloc_963 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_964 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_963 : memref<1x128x15x20xi8>) outs(%alloc_964 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_965 = memref.collapse_shape %48 [[0], [1, 2, 3]] : memref<128x128x1x1xi8> into memref<128x128xi8>
    %expand_shape_966 = memref.expand_shape %collapse_shape_965 [[0, 1, 2], [3]] output_shape [128, 1, 1, 128] : memref<128x128xi8> into memref<128x1x1x128xi8>
    %alloc_967 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%47 : memref<128xi32>) outs(%alloc_967 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_964, %expand_shape_966 : memref<1x15x20x128xi8>, memref<128x1x1x128xi8>) outs(%alloc_967 : memref<1x15x20x128xi32>)
    %alloc_968 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_967 : memref<1x15x20x128xi32>) outs(%alloc_968 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_969 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_968, %228 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_969 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_970 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_969, %227 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_970 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_971 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_970 : memref<1x15x20x128xf32>) outs(%alloc_971 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_972 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_971 : memref<1x128x15x20xf32>) outs(%alloc_972 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_973 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_971, %alloc_972 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_973 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_974 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_973, %226 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_974 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_975 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_974 : memref<1x128x15x20xf32>) outs(%alloc_975 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_976 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_975 : memref<1x128x15x20xf32>) outs(%alloc_976 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_977 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi8>
    linalg.transpose ins(%alloc_976 : memref<1x128x15x20xi8>) outs(%alloc_977 : memref<1x15x20x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_978 = memref.alloc() {alignment = 64 : i64} : memref<128x3x3x128xi8>
    linalg.transpose ins(%46 : memref<128x128x3x3xi8>) outs(%alloc_978 : memref<128x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_979 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x128xi8>
    linalg.map outs(%alloc_979 : memref<1x17x22x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_980 = memref.subview %alloc_979[0, 1, 1, 0] [1, 15, 20, 128] [1, 1, 1, 1] : memref<1x17x22x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    memref.copy %alloc_977, %subview_980 : memref<1x15x20x128xi8> to memref<1x15x20x128xi8, strided<[47872, 2816, 128, 1], offset: 2944>>
    %alloc_981 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%45 : memref<128xi32>) outs(%alloc_981 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_979, %alloc_978 : memref<1x17x22x128xi8>, memref<128x3x3x128xi8>) outs(%alloc_981 : memref<1x15x20x128xi32>)
    %alloc_982 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_981 : memref<1x15x20x128xi32>) outs(%alloc_982 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_983 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_982, %225 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_983 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_984 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_983, %224 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_984 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_985 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_984 : memref<1x15x20x128xf32>) outs(%alloc_985 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_986 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_985 : memref<1x128x15x20xf32>) outs(%alloc_986 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_987 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_985, %alloc_986 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_987 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_988 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_987, %223 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_988 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_989 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_988 : memref<1x128x15x20xf32>) outs(%alloc_989 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_990 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_989 : memref<1x128x15x20xf32>) outs(%alloc_990 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_991 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_948 : memref<1x256x15x20xi8>) outs(%alloc_991 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_992 = memref.collapse_shape %44 [[0], [1, 2, 3]] : memref<128x256x1x1xi8> into memref<128x256xi8>
    %expand_shape_993 = memref.expand_shape %collapse_shape_992 [[0, 1, 2], [3]] output_shape [128, 1, 1, 256] : memref<128x256xi8> into memref<128x1x1x256xi8>
    %alloc_994 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%43 : memref<128xi32>) outs(%alloc_994 : memref<1x15x20x128xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_991, %expand_shape_993 : memref<1x15x20x256xi8>, memref<128x1x1x256xi8>) outs(%alloc_994 : memref<1x15x20x128xi32>)
    %alloc_995 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_994 : memref<1x15x20x128xi32>) outs(%alloc_995 : memref<1x15x20x128xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_996 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_995, %222 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_996 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_997 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x128xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_996, %224 : memref<1x15x20x128xf32>, memref<1x1x1x1xf32>) outs(%alloc_997 : memref<1x15x20x128xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_998 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.transpose ins(%alloc_997 : memref<1x15x20x128xf32>) outs(%alloc_998 : memref<1x128x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_999 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_998 : memref<1x128x15x20xf32>) outs(%alloc_999 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1000 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_998, %alloc_999 : memref<1x128x15x20xf32>, memref<1x128x15x20xf32>) outs(%alloc_1000 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1001 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1000, %221 : memref<1x128x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1001 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1002 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1001 : memref<1x128x15x20xf32>) outs(%alloc_1002 : memref<1x128x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1003 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1002 : memref<1x128x15x20xf32>) outs(%alloc_1003 : memref<1x128x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1004 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_990 : memref<1x128x15x20xi8>) outs(%alloc_1004 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_1005 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1004, %220 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1005 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1006 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1005, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1006 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1007 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1006, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1007 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1008 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1007, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1008 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1009 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1008 : memref<1x128x15x20xi32>) outs(%alloc_1009 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_1010 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1003 : memref<1x128x15x20xi8>) outs(%alloc_1010 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i8, %out: i32):
      %419 = arith.extsi %in : i8 to i32
      linalg.yield %419 : i32
    }
    %alloc_1011 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1010, %219 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1011 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.muli %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1012 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1011, %400 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1012 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.shrsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1013 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1012, %398 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1013 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.maxsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1014 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1013, %397 : memref<1x128x15x20xi32>, memref<1x1x1x1xi32>) outs(%alloc_1014 : memref<1x128x15x20xi32>) {
    ^bb0(%in: i32, %in_1309: i32, %out: i32):
      %419 = arith.minsi %in, %in_1309 : i32
      linalg.yield %419 : i32
    }
    %alloc_1015 = memref.alloc() {alignment = 64 : i64} : memref<1x128x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1014 : memref<1x128x15x20xi32>) outs(%alloc_1015 : memref<1x128x15x20xi8>) {
    ^bb0(%in: i32, %out: i8):
      %419 = arith.trunci %in : i32 to i8
      linalg.yield %419 : i8
    }
    %alloc_1016 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    %subview_1017 = memref.subview %alloc_1016[0, 0, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    memref.copy %alloc_1009, %subview_1017 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1]>>
    %subview_1018 = memref.subview %alloc_1016[0, 128, 0, 0] [1, 128, 15, 20] [1, 1, 1, 1] : memref<1x256x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    memref.copy %alloc_1015, %subview_1018 : memref<1x128x15x20xi8> to memref<1x128x15x20xi8, strided<[76800, 300, 20, 1], offset: 38400>>
    %alloc_1019 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_1016 : memref<1x256x15x20xi8>) outs(%alloc_1019 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1020 = memref.collapse_shape %42 [[0], [1, 2, 3]] : memref<256x256x1x1xi8> into memref<256x256xi8>
    %expand_shape_1021 = memref.expand_shape %collapse_shape_1020 [[0, 1, 2], [3]] output_shape [256, 1, 1, 256] : memref<256x256xi8> into memref<256x1x1x256xi8>
    %alloc_1022 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%41 : memref<256xi32>) outs(%alloc_1022 : memref<1x15x20x256xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1019, %expand_shape_1021 : memref<1x15x20x256xi8>, memref<256x1x1x256xi8>) outs(%alloc_1022 : memref<1x15x20x256xi32>)
    %alloc_1023 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1022 : memref<1x15x20x256xi32>) outs(%alloc_1023 : memref<1x15x20x256xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1024 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1023, %218 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_1024 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1025 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1024, %217 : memref<1x15x20x256xf32>, memref<1x1x1x1xf32>) outs(%alloc_1025 : memref<1x15x20x256xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1026 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.transpose ins(%alloc_1025 : memref<1x15x20x256xf32>) outs(%alloc_1026 : memref<1x256x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1027 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1026 : memref<1x256x15x20xf32>) outs(%alloc_1027 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1028 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1026, %alloc_1027 : memref<1x256x15x20xf32>, memref<1x256x15x20xf32>) outs(%alloc_1028 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1029 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1028, %216 : memref<1x256x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1029 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1030 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1029 : memref<1x256x15x20xf32>) outs(%alloc_1030 : memref<1x256x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1031 = memref.alloc() {alignment = 64 : i64} : memref<1x256x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1030 : memref<1x256x15x20xf32>) outs(%alloc_1031 : memref<1x256x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1032 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_811 : memref<1x64x60x80xi8>) outs(%alloc_1032 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1033 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%40 : memref<64x64x3x3xi8>) outs(%alloc_1033 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1034 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    linalg.map outs(%alloc_1034 : memref<1x62x82x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1035 = memref.subview %alloc_1034[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1032, %subview_1035 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1036 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%39 : memref<64xi32>) outs(%alloc_1036 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1034, %alloc_1033 : memref<1x62x82x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_1036 : memref<1x60x80x64xi32>)
    %alloc_1037 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1036 : memref<1x60x80x64xi32>) outs(%alloc_1037 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1038 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1037, %215 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1038 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1039 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1038, %214 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1039 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1040 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_1039 : memref<1x60x80x64xf32>) outs(%alloc_1040 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1041 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1040 : memref<1x64x60x80xf32>) outs(%alloc_1041 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1042 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1040, %alloc_1041 : memref<1x64x60x80xf32>, memref<1x64x60x80xf32>) outs(%alloc_1042 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1043 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1042, %213 : memref<1x64x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1043 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1044 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1043 : memref<1x64x60x80xf32>) outs(%alloc_1044 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1045 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1044 : memref<1x64x60x80xf32>) outs(%alloc_1045 : memref<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1046 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_1045 : memref<1x64x60x80xi8>) outs(%alloc_1046 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1047 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%38 : memref<64x64x3x3xi8>) outs(%alloc_1047 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1048 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    linalg.map outs(%alloc_1048 : memref<1x62x82x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1049 = memref.subview %alloc_1048[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1046, %subview_1049 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1050 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%37 : memref<64xi32>) outs(%alloc_1050 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1048, %alloc_1047 : memref<1x62x82x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_1050 : memref<1x60x80x64xi32>)
    %alloc_1051 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1050 : memref<1x60x80x64xi32>) outs(%alloc_1051 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1052 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1051, %212 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1052 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1053 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1052, %211 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1053 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1054 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_1053 : memref<1x60x80x64xf32>) outs(%alloc_1054 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1055 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1054 : memref<1x64x60x80xf32>) outs(%alloc_1055 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1056 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1054, %alloc_1055 : memref<1x64x60x80xf32>, memref<1x64x60x80xf32>) outs(%alloc_1056 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1057 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1056, %210 : memref<1x64x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1057 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1058 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1057 : memref<1x64x60x80xf32>) outs(%alloc_1058 : memref<1x64x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1059 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1058 : memref<1x64x60x80xf32>) outs(%alloc_1059 : memref<1x64x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1060 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_1059 : memref<1x64x60x80xi8>) outs(%alloc_1060 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1061 = memref.collapse_shape %36 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_1062 = memref.expand_shape %collapse_shape_1061 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_1063 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%35 : memref<64xi32>) outs(%alloc_1063 : memref<1x60x80x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1060, %expand_shape_1062 : memref<1x60x80x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_1063 : memref<1x60x80x64xi32>)
    %alloc_1064 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1063 : memref<1x60x80x64xi32>) outs(%alloc_1064 : memref<1x60x80x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1065 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1064, %209 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1065 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1066 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1065, %208 : memref<1x60x80x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1066 : memref<1x60x80x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1067 = memref.alloc() {alignment = 64 : i64} : memref<1x64x60x80xf32>
    linalg.transpose ins(%alloc_1066 : memref<1x60x80x64xf32>) outs(%alloc_1067 : memref<1x64x60x80xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1068 = memref.collapse_shape %alloc_1067 [[0], [1], [2, 3]] : memref<1x64x60x80xf32> into memref<1x64x4800xf32>
    %alloc_1069 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_921 : memref<1x128x30x40xi8>) outs(%alloc_1069 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1070 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x128xi8>
    linalg.transpose ins(%34 : memref<64x128x3x3xi8>) outs(%alloc_1070 : memref<64x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1071 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    linalg.map outs(%alloc_1071 : memref<1x32x42x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1072 = memref.subview %alloc_1071[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_1069, %subview_1072 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_1073 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%33 : memref<64xi32>) outs(%alloc_1073 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1071, %alloc_1070 : memref<1x32x42x128xi8>, memref<64x3x3x128xi8>) outs(%alloc_1073 : memref<1x30x40x64xi32>)
    %alloc_1074 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1073 : memref<1x30x40x64xi32>) outs(%alloc_1074 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1075 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1074, %207 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1075 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1076 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1075, %206 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1076 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1077 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_1076 : memref<1x30x40x64xf32>) outs(%alloc_1077 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1078 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1077 : memref<1x64x30x40xf32>) outs(%alloc_1078 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1079 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1077, %alloc_1078 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_1079 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1080 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1079, %205 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_1080 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1081 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1080 : memref<1x64x30x40xf32>) outs(%alloc_1081 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1082 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1081 : memref<1x64x30x40xf32>) outs(%alloc_1082 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1083 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_1082 : memref<1x64x30x40xi8>) outs(%alloc_1083 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1084 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%32 : memref<64x64x3x3xi8>) outs(%alloc_1084 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1085 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x64xi8>
    linalg.map outs(%alloc_1085 : memref<1x32x42x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1086 = memref.subview %alloc_1085[0, 1, 1, 0] [1, 30, 40, 64] [1, 1, 1, 1] : memref<1x32x42x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    memref.copy %alloc_1083, %subview_1086 : memref<1x30x40x64xi8> to memref<1x30x40x64xi8, strided<[86016, 2688, 64, 1], offset: 2752>>
    %alloc_1087 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%31 : memref<64xi32>) outs(%alloc_1087 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1085, %alloc_1084 : memref<1x32x42x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_1087 : memref<1x30x40x64xi32>)
    %alloc_1088 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1087 : memref<1x30x40x64xi32>) outs(%alloc_1088 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1089 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1088, %204 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1089 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1090 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1089, %203 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1090 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1091 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_1090 : memref<1x30x40x64xf32>) outs(%alloc_1091 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1092 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1091 : memref<1x64x30x40xf32>) outs(%alloc_1092 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1093 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1091, %alloc_1092 : memref<1x64x30x40xf32>, memref<1x64x30x40xf32>) outs(%alloc_1093 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1094 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1093, %202 : memref<1x64x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_1094 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1095 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1094 : memref<1x64x30x40xf32>) outs(%alloc_1095 : memref<1x64x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1096 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1095 : memref<1x64x30x40xf32>) outs(%alloc_1096 : memref<1x64x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1097 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi8>
    linalg.transpose ins(%alloc_1096 : memref<1x64x30x40xi8>) outs(%alloc_1097 : memref<1x30x40x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1098 = memref.collapse_shape %30 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_1099 = memref.expand_shape %collapse_shape_1098 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_1100 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%29 : memref<64xi32>) outs(%alloc_1100 : memref<1x30x40x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1097, %expand_shape_1099 : memref<1x30x40x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_1100 : memref<1x30x40x64xi32>)
    %alloc_1101 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1100 : memref<1x30x40x64xi32>) outs(%alloc_1101 : memref<1x30x40x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1102 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1101, %201 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1102 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1103 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1102, %200 : memref<1x30x40x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1103 : memref<1x30x40x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1104 = memref.alloc() {alignment = 64 : i64} : memref<1x64x30x40xf32>
    linalg.transpose ins(%alloc_1103 : memref<1x30x40x64xf32>) outs(%alloc_1104 : memref<1x64x30x40xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1105 = memref.collapse_shape %alloc_1104 [[0], [1], [2, 3]] : memref<1x64x30x40xf32> into memref<1x64x1200xf32>
    %alloc_1106 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_1031 : memref<1x256x15x20xi8>) outs(%alloc_1106 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1107 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x256xi8>
    linalg.transpose ins(%28 : memref<64x256x3x3xi8>) outs(%alloc_1107 : memref<64x3x3x256xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1108 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    linalg.map outs(%alloc_1108 : memref<1x17x22x256xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1109 = memref.subview %alloc_1108[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_1106, %subview_1109 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_1110 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%27 : memref<64xi32>) outs(%alloc_1110 : memref<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1108, %alloc_1107 : memref<1x17x22x256xi8>, memref<64x3x3x256xi8>) outs(%alloc_1110 : memref<1x15x20x64xi32>)
    %alloc_1111 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1110 : memref<1x15x20x64xi32>) outs(%alloc_1111 : memref<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1112 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1111, %199 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1112 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1113 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1112, %198 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1113 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1114 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.transpose ins(%alloc_1113 : memref<1x15x20x64xf32>) outs(%alloc_1114 : memref<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1115 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1114 : memref<1x64x15x20xf32>) outs(%alloc_1115 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1116 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1114, %alloc_1115 : memref<1x64x15x20xf32>, memref<1x64x15x20xf32>) outs(%alloc_1116 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1117 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1116, %197 : memref<1x64x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1117 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1118 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1117 : memref<1x64x15x20xf32>) outs(%alloc_1118 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1119 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1118 : memref<1x64x15x20xf32>) outs(%alloc_1119 : memref<1x64x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1120 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    linalg.transpose ins(%alloc_1119 : memref<1x64x15x20xi8>) outs(%alloc_1120 : memref<1x15x20x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1121 = memref.alloc() {alignment = 64 : i64} : memref<64x3x3x64xi8>
    linalg.transpose ins(%26 : memref<64x64x3x3xi8>) outs(%alloc_1121 : memref<64x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1122 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x64xi8>
    linalg.map outs(%alloc_1122 : memref<1x17x22x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1123 = memref.subview %alloc_1122[0, 1, 1, 0] [1, 15, 20, 64] [1, 1, 1, 1] : memref<1x17x22x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    memref.copy %alloc_1120, %subview_1123 : memref<1x15x20x64xi8> to memref<1x15x20x64xi8, strided<[23936, 1408, 64, 1], offset: 1472>>
    %alloc_1124 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%25 : memref<64xi32>) outs(%alloc_1124 : memref<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1122, %alloc_1121 : memref<1x17x22x64xi8>, memref<64x3x3x64xi8>) outs(%alloc_1124 : memref<1x15x20x64xi32>)
    %alloc_1125 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1124 : memref<1x15x20x64xi32>) outs(%alloc_1125 : memref<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1126 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1125, %196 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1126 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1127 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1126, %195 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1127 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1128 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.transpose ins(%alloc_1127 : memref<1x15x20x64xf32>) outs(%alloc_1128 : memref<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1129 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1128 : memref<1x64x15x20xf32>) outs(%alloc_1129 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1130 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1128, %alloc_1129 : memref<1x64x15x20xf32>, memref<1x64x15x20xf32>) outs(%alloc_1130 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1131 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1130, %194 : memref<1x64x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1131 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1132 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1131 : memref<1x64x15x20xf32>) outs(%alloc_1132 : memref<1x64x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1133 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1132 : memref<1x64x15x20xf32>) outs(%alloc_1133 : memref<1x64x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1134 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi8>
    linalg.transpose ins(%alloc_1133 : memref<1x64x15x20xi8>) outs(%alloc_1134 : memref<1x15x20x64xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1135 = memref.collapse_shape %24 [[0], [1, 2, 3]] : memref<64x64x1x1xi8> into memref<64x64xi8>
    %expand_shape_1136 = memref.expand_shape %collapse_shape_1135 [[0, 1, 2], [3]] output_shape [64, 1, 1, 64] : memref<64x64xi8> into memref<64x1x1x64xi8>
    %alloc_1137 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%23 : memref<64xi32>) outs(%alloc_1137 : memref<1x15x20x64xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1134, %expand_shape_1136 : memref<1x15x20x64xi8>, memref<64x1x1x64xi8>) outs(%alloc_1137 : memref<1x15x20x64xi32>)
    %alloc_1138 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1137 : memref<1x15x20x64xi32>) outs(%alloc_1138 : memref<1x15x20x64xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1139 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1138, %193 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1139 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1140 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x64xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1139, %192 : memref<1x15x20x64xf32>, memref<1x1x1x1xf32>) outs(%alloc_1140 : memref<1x15x20x64xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1141 = memref.alloc() {alignment = 64 : i64} : memref<1x64x15x20xf32>
    linalg.transpose ins(%alloc_1140 : memref<1x15x20x64xf32>) outs(%alloc_1141 : memref<1x64x15x20xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1142 = memref.collapse_shape %alloc_1141 [[0], [1], [2, 3]] : memref<1x64x15x20xf32> into memref<1x64x300xf32>
    %alloc_1143 = memref.alloc() {alignment = 64 : i64} : memref<1x64x1200xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapse_shape_1105, %191 : memref<1x64x1200xf32>, memref<1x1x1xf32>) outs(%alloc_1143 : memref<1x64x1200xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1144 = memref.alloc() {alignment = 64 : i64} : memref<1x64x300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapse_shape_1142, %190 : memref<1x64x300xf32>, memref<1x1x1xf32>) outs(%alloc_1144 : memref<1x64x300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1145 = memref.alloc() {alignment = 64 : i64} : memref<1x64x6300xf32>
    %subview_1146 = memref.subview %alloc_1145[0, 0, 0] [1, 64, 4800] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    memref.copy %collapse_shape_1068, %subview_1146 : memref<1x64x4800xf32> to memref<1x64x4800xf32, strided<[403200, 6300, 1]>>
    %subview_1147 = memref.subview %alloc_1145[0, 0, 4800] [1, 64, 1200] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    memref.copy %alloc_1143, %subview_1147 : memref<1x64x1200xf32> to memref<1x64x1200xf32, strided<[403200, 6300, 1], offset: 4800>>
    %subview_1148 = memref.subview %alloc_1145[0, 0, 6000] [1, 64, 300] [1, 1, 1] : memref<1x64x6300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    memref.copy %alloc_1144, %subview_1148 : memref<1x64x300xf32> to memref<1x64x300xf32, strided<[403200, 6300, 1], offset: 6000>>
    %alloc_1149 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x64xi8>
    linalg.transpose ins(%alloc_811 : memref<1x64x60x80xi8>) outs(%alloc_1149 : memref<1x60x80x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1150 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x64xi8>
    linalg.transpose ins(%22 : memref<80x64x3x3xi8>) outs(%alloc_1150 : memref<80x3x3x64xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1151 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x64xi8>
    linalg.map outs(%alloc_1151 : memref<1x62x82x64xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1152 = memref.subview %alloc_1151[0, 1, 1, 0] [1, 60, 80, 64] [1, 1, 1, 1] : memref<1x62x82x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    memref.copy %alloc_1149, %subview_1152 : memref<1x60x80x64xi8> to memref<1x60x80x64xi8, strided<[325376, 5248, 64, 1], offset: 5312>>
    %alloc_1153 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%21 : memref<80xi32>) outs(%alloc_1153 : memref<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1151, %alloc_1150 : memref<1x62x82x64xi8>, memref<80x3x3x64xi8>) outs(%alloc_1153 : memref<1x60x80x80xi32>)
    %alloc_1154 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1153 : memref<1x60x80x80xi32>) outs(%alloc_1154 : memref<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1155 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1154, %189 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1155 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1156 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1155, %188 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1156 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1157 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.transpose ins(%alloc_1156 : memref<1x60x80x80xf32>) outs(%alloc_1157 : memref<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1158 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1157 : memref<1x80x60x80xf32>) outs(%alloc_1158 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1159 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1157, %alloc_1158 : memref<1x80x60x80xf32>, memref<1x80x60x80xf32>) outs(%alloc_1159 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1160 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1159, %187 : memref<1x80x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1160 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1161 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1160 : memref<1x80x60x80xf32>) outs(%alloc_1161 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1162 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1161 : memref<1x80x60x80xf32>) outs(%alloc_1162 : memref<1x80x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1163 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    linalg.transpose ins(%alloc_1162 : memref<1x80x60x80xi8>) outs(%alloc_1163 : memref<1x60x80x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1164 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x80xi8>
    linalg.transpose ins(%20 : memref<80x80x3x3xi8>) outs(%alloc_1164 : memref<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1165 = memref.alloc() {alignment = 64 : i64} : memref<1x62x82x80xi8>
    linalg.map outs(%alloc_1165 : memref<1x62x82x80xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1166 = memref.subview %alloc_1165[0, 1, 1, 0] [1, 60, 80, 80] [1, 1, 1, 1] : memref<1x62x82x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    memref.copy %alloc_1163, %subview_1166 : memref<1x60x80x80xi8> to memref<1x60x80x80xi8, strided<[406720, 6560, 80, 1], offset: 6640>>
    %alloc_1167 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%19 : memref<80xi32>) outs(%alloc_1167 : memref<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1165, %alloc_1164 : memref<1x62x82x80xi8>, memref<80x3x3x80xi8>) outs(%alloc_1167 : memref<1x60x80x80xi32>)
    %alloc_1168 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1167 : memref<1x60x80x80xi32>) outs(%alloc_1168 : memref<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1169 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1168, %186 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1169 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1170 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1169, %185 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1170 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1171 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.transpose ins(%alloc_1170 : memref<1x60x80x80xf32>) outs(%alloc_1171 : memref<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1172 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1171 : memref<1x80x60x80xf32>) outs(%alloc_1172 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1173 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1171, %alloc_1172 : memref<1x80x60x80xf32>, memref<1x80x60x80xf32>) outs(%alloc_1173 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1174 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1173, %184 : memref<1x80x60x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1174 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1175 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1174 : memref<1x80x60x80xf32>) outs(%alloc_1175 : memref<1x80x60x80xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1176 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1175 : memref<1x80x60x80xf32>) outs(%alloc_1176 : memref<1x80x60x80xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1177 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi8>
    linalg.transpose ins(%alloc_1176 : memref<1x80x60x80xi8>) outs(%alloc_1177 : memref<1x60x80x80xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1178 = memref.collapse_shape %18 [[0], [1, 2, 3]] : memref<80x80x1x1xi8> into memref<80x80xi8>
    %expand_shape_1179 = memref.expand_shape %collapse_shape_1178 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : memref<80x80xi8> into memref<80x1x1x80xi8>
    %alloc_1180 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%17 : memref<80xi32>) outs(%alloc_1180 : memref<1x60x80x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1177, %expand_shape_1179 : memref<1x60x80x80xi8>, memref<80x1x1x80xi8>) outs(%alloc_1180 : memref<1x60x80x80xi32>)
    %alloc_1181 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1180 : memref<1x60x80x80xi32>) outs(%alloc_1181 : memref<1x60x80x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1182 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1181, %183 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1182 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1183 = memref.alloc() {alignment = 64 : i64} : memref<1x60x80x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1182, %182 : memref<1x60x80x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1183 : memref<1x60x80x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1184 = memref.alloc() {alignment = 64 : i64} : memref<1x80x60x80xf32>
    linalg.transpose ins(%alloc_1183 : memref<1x60x80x80xf32>) outs(%alloc_1184 : memref<1x80x60x80xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1185 = memref.collapse_shape %alloc_1184 [[0], [1], [2, 3]] : memref<1x80x60x80xf32> into memref<1x80x4800xf32>
    %alloc_1186 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x128xi8>
    linalg.transpose ins(%alloc_921 : memref<1x128x30x40xi8>) outs(%alloc_1186 : memref<1x30x40x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1187 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x128xi8>
    linalg.transpose ins(%16 : memref<80x128x3x3xi8>) outs(%alloc_1187 : memref<80x3x3x128xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1188 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x128xi8>
    linalg.map outs(%alloc_1188 : memref<1x32x42x128xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1189 = memref.subview %alloc_1188[0, 1, 1, 0] [1, 30, 40, 128] [1, 1, 1, 1] : memref<1x32x42x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    memref.copy %alloc_1186, %subview_1189 : memref<1x30x40x128xi8> to memref<1x30x40x128xi8, strided<[172032, 5376, 128, 1], offset: 5504>>
    %alloc_1190 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%15 : memref<80xi32>) outs(%alloc_1190 : memref<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1188, %alloc_1187 : memref<1x32x42x128xi8>, memref<80x3x3x128xi8>) outs(%alloc_1190 : memref<1x30x40x80xi32>)
    %alloc_1191 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1190 : memref<1x30x40x80xi32>) outs(%alloc_1191 : memref<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1192 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1191, %181 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1192 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1193 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1192, %180 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1193 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1194 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.transpose ins(%alloc_1193 : memref<1x30x40x80xf32>) outs(%alloc_1194 : memref<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1195 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1194 : memref<1x80x30x40xf32>) outs(%alloc_1195 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1196 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1194, %alloc_1195 : memref<1x80x30x40xf32>, memref<1x80x30x40xf32>) outs(%alloc_1196 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1197 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1196, %179 : memref<1x80x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_1197 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1198 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1197 : memref<1x80x30x40xf32>) outs(%alloc_1198 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1199 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1198 : memref<1x80x30x40xf32>) outs(%alloc_1199 : memref<1x80x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1200 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    linalg.transpose ins(%alloc_1199 : memref<1x80x30x40xi8>) outs(%alloc_1200 : memref<1x30x40x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1201 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x80xi8>
    linalg.transpose ins(%14 : memref<80x80x3x3xi8>) outs(%alloc_1201 : memref<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1202 = memref.alloc() {alignment = 64 : i64} : memref<1x32x42x80xi8>
    linalg.map outs(%alloc_1202 : memref<1x32x42x80xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1203 = memref.subview %alloc_1202[0, 1, 1, 0] [1, 30, 40, 80] [1, 1, 1, 1] : memref<1x32x42x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    memref.copy %alloc_1200, %subview_1203 : memref<1x30x40x80xi8> to memref<1x30x40x80xi8, strided<[107520, 3360, 80, 1], offset: 3440>>
    %alloc_1204 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%13 : memref<80xi32>) outs(%alloc_1204 : memref<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1202, %alloc_1201 : memref<1x32x42x80xi8>, memref<80x3x3x80xi8>) outs(%alloc_1204 : memref<1x30x40x80xi32>)
    %alloc_1205 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1204 : memref<1x30x40x80xi32>) outs(%alloc_1205 : memref<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1206 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1205, %178 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1206 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1207 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1206, %177 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1207 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1208 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.transpose ins(%alloc_1207 : memref<1x30x40x80xf32>) outs(%alloc_1208 : memref<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1209 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1208 : memref<1x80x30x40xf32>) outs(%alloc_1209 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1210 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1208, %alloc_1209 : memref<1x80x30x40xf32>, memref<1x80x30x40xf32>) outs(%alloc_1210 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1211 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1210, %176 : memref<1x80x30x40xf32>, memref<1x1x1x1xf32>) outs(%alloc_1211 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1212 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1211 : memref<1x80x30x40xf32>) outs(%alloc_1212 : memref<1x80x30x40xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1213 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1212 : memref<1x80x30x40xf32>) outs(%alloc_1213 : memref<1x80x30x40xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1214 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi8>
    linalg.transpose ins(%alloc_1213 : memref<1x80x30x40xi8>) outs(%alloc_1214 : memref<1x30x40x80xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1215 = memref.collapse_shape %12 [[0], [1, 2, 3]] : memref<80x80x1x1xi8> into memref<80x80xi8>
    %expand_shape_1216 = memref.expand_shape %collapse_shape_1215 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : memref<80x80xi8> into memref<80x1x1x80xi8>
    %alloc_1217 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%11 : memref<80xi32>) outs(%alloc_1217 : memref<1x30x40x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1214, %expand_shape_1216 : memref<1x30x40x80xi8>, memref<80x1x1x80xi8>) outs(%alloc_1217 : memref<1x30x40x80xi32>)
    %alloc_1218 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1217 : memref<1x30x40x80xi32>) outs(%alloc_1218 : memref<1x30x40x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1219 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1218, %175 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1219 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1220 = memref.alloc() {alignment = 64 : i64} : memref<1x30x40x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1219, %174 : memref<1x30x40x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1220 : memref<1x30x40x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1221 = memref.alloc() {alignment = 64 : i64} : memref<1x80x30x40xf32>
    linalg.transpose ins(%alloc_1220 : memref<1x30x40x80xf32>) outs(%alloc_1221 : memref<1x80x30x40xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1222 = memref.collapse_shape %alloc_1221 [[0], [1], [2, 3]] : memref<1x80x30x40xf32> into memref<1x80x1200xf32>
    %alloc_1223 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x256xi8>
    linalg.transpose ins(%alloc_1031 : memref<1x256x15x20xi8>) outs(%alloc_1223 : memref<1x15x20x256xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1224 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x256xi8>
    linalg.transpose ins(%10 : memref<80x256x3x3xi8>) outs(%alloc_1224 : memref<80x3x3x256xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1225 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x256xi8>
    linalg.map outs(%alloc_1225 : memref<1x17x22x256xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1226 = memref.subview %alloc_1225[0, 1, 1, 0] [1, 15, 20, 256] [1, 1, 1, 1] : memref<1x17x22x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    memref.copy %alloc_1223, %subview_1226 : memref<1x15x20x256xi8> to memref<1x15x20x256xi8, strided<[95744, 5632, 256, 1], offset: 5888>>
    %alloc_1227 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%9 : memref<80xi32>) outs(%alloc_1227 : memref<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1225, %alloc_1224 : memref<1x17x22x256xi8>, memref<80x3x3x256xi8>) outs(%alloc_1227 : memref<1x15x20x80xi32>)
    %alloc_1228 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1227 : memref<1x15x20x80xi32>) outs(%alloc_1228 : memref<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1229 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1228, %173 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1229 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1230 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1229, %172 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1230 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1231 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.transpose ins(%alloc_1230 : memref<1x15x20x80xf32>) outs(%alloc_1231 : memref<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1232 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1231 : memref<1x80x15x20xf32>) outs(%alloc_1232 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1233 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1231, %alloc_1232 : memref<1x80x15x20xf32>, memref<1x80x15x20xf32>) outs(%alloc_1233 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1234 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1233, %171 : memref<1x80x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1234 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1235 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1234 : memref<1x80x15x20xf32>) outs(%alloc_1235 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1236 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1235 : memref<1x80x15x20xf32>) outs(%alloc_1236 : memref<1x80x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1237 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    linalg.transpose ins(%alloc_1236 : memref<1x80x15x20xi8>) outs(%alloc_1237 : memref<1x15x20x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1238 = memref.alloc() {alignment = 64 : i64} : memref<80x3x3x80xi8>
    linalg.transpose ins(%8 : memref<80x80x3x3xi8>) outs(%alloc_1238 : memref<80x3x3x80xi8>) permutation = [0, 2, 3, 1] 
    %alloc_1239 = memref.alloc() {alignment = 64 : i64} : memref<1x17x22x80xi8>
    linalg.map outs(%alloc_1239 : memref<1x17x22x80xi8>)
      (%init: i8) {
        %419 = linalg.index 0 : index
        %420 = linalg.index 1 : index
        %421 = linalg.index 2 : index
        %422 = linalg.index 3 : index
        linalg.yield %c0_i8 : i8
      }
    %subview_1240 = memref.subview %alloc_1239[0, 1, 1, 0] [1, 15, 20, 80] [1, 1, 1, 1] : memref<1x17x22x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    memref.copy %alloc_1237, %subview_1240 : memref<1x15x20x80xi8> to memref<1x15x20x80xi8, strided<[29920, 1760, 80, 1], offset: 1840>>
    %alloc_1241 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%7 : memref<80xi32>) outs(%alloc_1241 : memref<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1239, %alloc_1238 : memref<1x17x22x80xi8>, memref<80x3x3x80xi8>) outs(%alloc_1241 : memref<1x15x20x80xi32>)
    %alloc_1242 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1241 : memref<1x15x20x80xi32>) outs(%alloc_1242 : memref<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1243 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1242, %170 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1243 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1244 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1243, %169 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1244 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1245 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.transpose ins(%alloc_1244 : memref<1x15x20x80xf32>) outs(%alloc_1245 : memref<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %alloc_1246 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1245 : memref<1x80x15x20xf32>) outs(%alloc_1246 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1247 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1245, %alloc_1246 : memref<1x80x15x20xf32>, memref<1x80x15x20xf32>) outs(%alloc_1247 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1248 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1247, %168 : memref<1x80x15x20xf32>, memref<1x1x1x1xf32>) outs(%alloc_1248 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1249 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1248 : memref<1x80x15x20xf32>) outs(%alloc_1249 : memref<1x80x15x20xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1250 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1249 : memref<1x80x15x20xf32>) outs(%alloc_1250 : memref<1x80x15x20xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1251 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi8>
    linalg.transpose ins(%alloc_1250 : memref<1x80x15x20xi8>) outs(%alloc_1251 : memref<1x15x20x80xi8>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1252 = memref.collapse_shape %6 [[0], [1, 2, 3]] : memref<80x80x1x1xi8> into memref<80x80xi8>
    %expand_shape_1253 = memref.expand_shape %collapse_shape_1252 [[0, 1, 2], [3]] output_shape [80, 1, 1, 80] : memref<80x80xi8> into memref<80x1x1x80xi8>
    %alloc_1254 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xi32>
    linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%5 : memref<80xi32>) outs(%alloc_1254 : memref<1x15x20x80xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1251, %expand_shape_1253 : memref<1x15x20x80xi8>, memref<80x1x1x80xi8>) outs(%alloc_1254 : memref<1x15x20x80xi32>)
    %alloc_1255 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1254 : memref<1x15x20x80xi32>) outs(%alloc_1255 : memref<1x15x20x80xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1256 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1255, %167 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1256 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1257 = memref.alloc() {alignment = 64 : i64} : memref<1x15x20x80xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1256, %166 : memref<1x15x20x80xf32>, memref<1x1x1x1xf32>) outs(%alloc_1257 : memref<1x15x20x80xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1258 = memref.alloc() {alignment = 64 : i64} : memref<1x80x15x20xf32>
    linalg.transpose ins(%alloc_1257 : memref<1x15x20x80xf32>) outs(%alloc_1258 : memref<1x80x15x20xf32>) permutation = [0, 3, 1, 2] 
    %collapse_shape_1259 = memref.collapse_shape %alloc_1258 [[0], [1], [2, 3]] : memref<1x80x15x20xf32> into memref<1x80x300xf32>
    %alloc_1260 = memref.alloc() {alignment = 64 : i64} : memref<1x80x4800xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapse_shape_1185, %165 : memref<1x80x4800xf32>, memref<1x1x1xf32>) outs(%alloc_1260 : memref<1x80x4800xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1261 = memref.alloc() {alignment = 64 : i64} : memref<1x80x1200xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%collapse_shape_1222, %164 : memref<1x80x1200xf32>, memref<1x1x1xf32>) outs(%alloc_1261 : memref<1x80x1200xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1262 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    %subview_1263 = memref.subview %alloc_1262[0, 0, 0] [1, 80, 4800] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    memref.copy %alloc_1260, %subview_1263 : memref<1x80x4800xf32> to memref<1x80x4800xf32, strided<[504000, 6300, 1]>>
    %subview_1264 = memref.subview %alloc_1262[0, 0, 4800] [1, 80, 1200] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    memref.copy %alloc_1261, %subview_1264 : memref<1x80x1200xf32> to memref<1x80x1200xf32, strided<[504000, 6300, 1], offset: 4800>>
    %subview_1265 = memref.subview %alloc_1262[0, 0, 6000] [1, 80, 300] [1, 1, 1] : memref<1x80x6300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    memref.copy %collapse_shape_1259, %subview_1265 : memref<1x80x300xf32> to memref<1x80x300xf32, strided<[504000, 6300, 1], offset: 6000>>
    %expand_shape_1266 = memref.expand_shape %alloc_1145 [[0], [1, 2], [3]] output_shape [1, 4, 16, 6300] : memref<1x64x6300xf32> into memref<1x4x16x6300xf32>
    %alloc_1267 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    linalg.transpose ins(%expand_shape_1266 : memref<1x4x16x6300xf32>) outs(%alloc_1267 : memref<1x16x4x6300xf32>) permutation = [0, 2, 1, 3] 
    %alloc_1268 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1267 : memref<1x16x4x6300xf32>) outs(%alloc_1268 : memref<1x16x4x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = math.exp %in : f32
      linalg.yield %419 : f32
    }
    %alloc_1269 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    linalg.fill ins(%cst_0 : f32) outs(%alloc_1269 : memref<1x4x6300xf32>)
    linalg.reduce ins(%alloc_1268 : memref<1x16x4x6300xf32>) outs(%alloc_1269 : memref<1x4x6300xf32>) dimensions = [1] 
      (%in: f32, %init: f32) {
        %419 = arith.addf %in, %init : f32
        linalg.yield %419 : f32
      }
    %expand_shape_1270 = memref.expand_shape %alloc_1269 [[0], [1, 2], [3]] output_shape [1, 1, 4, 6300] : memref<1x4x6300xf32> into memref<1x1x4x6300xf32>
    %alloc_1271 = memref.alloc() {alignment = 64 : i64} : memref<1x1x4x6300xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%expand_shape_1270 : memref<1x1x4x6300xf32>) outs(%alloc_1271 : memref<1x1x4x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.divf %cst_3, %in : f32
      linalg.yield %419 : f32
    }
    %alloc_1272 = memref.alloc() {alignment = 64 : i64} : memref<1x16x4x6300xf32>
    linalg.generic {indexing_maps = [#map1, #map5, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1268, %alloc_1271 : memref<1x16x4x6300xf32>, memref<1x1x4x6300xf32>) outs(%alloc_1272 : memref<1x16x4x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1273 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    linalg.transpose ins(%alloc_1272 : memref<1x16x4x6300xf32>) outs(%alloc_1273 : memref<1x4x6300x16xf32>) permutation = [0, 2, 3, 1] 
    %collapse_shape_1274 = memref.collapse_shape %4 [[0], [1, 2, 3]] : memref<1x16x1x1xf32> into memref<1x16xf32>
    %expand_shape_1275 = memref.expand_shape %collapse_shape_1274 [[0, 1, 2], [3]] output_shape [1, 1, 1, 16] : memref<1x16xf32> into memref<1x1x1x16xf32>
    %alloc_1276 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    linalg.generic {indexing_maps = [#map1, #map2, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1273, %163 : memref<1x4x6300x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_1276 : memref<1x4x6300x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1277 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1276 : memref<1x4x6300x16xf32>) outs(%alloc_1277 : memref<1x4x6300x16xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst_2 : f32
      linalg.yield %420 : f32
    }
    %alloc_1278 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x16xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1277 : memref<1x4x6300x16xf32>) outs(%alloc_1278 : memref<1x4x6300x16xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1279 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    linalg.generic {indexing_maps = [#map1, #map6, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%expand_shape_1275, %162 : memref<1x1x1x16xf32>, memref<1x1x1x1xf32>) outs(%alloc_1279 : memref<1x1x1x16xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1280 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1279 : memref<1x1x1x16xf32>) outs(%alloc_1280 : memref<1x1x1x16xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.minimumf %in, %cst_1 : f32
      %420 = arith.maximumf %419, %cst : f32
      linalg.yield %420 : f32
    }
    %alloc_1281 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1x16xi8>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1280 : memref<1x1x1x16xf32>) outs(%alloc_1281 : memref<1x1x1x16xi8>) {
    ^bb0(%in: f32, %out: i8):
      %419 = math.roundeven %in : f32
      %420 = arith.minimumf %419, %cst_1 : f32
      %421 = arith.maximumf %420, %cst_2 : f32
      %422 = arith.fptosi %421 : f32 to i8
      linalg.yield %422 : i8
    }
    %alloc_1282 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xi32>
    linalg.generic {indexing_maps = [#map7, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%417 : memref<1xi32>) outs(%alloc_1282 : memref<1x4x6300x1xi32>) {
    ^bb0(%in: i32, %out: i32):
      linalg.yield %in : i32
    }
    linalg.conv_2d_nhwc_fhwc {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>} ins(%alloc_1278, %alloc_1281 : memref<1x4x6300x16xi8>, memref<1x1x1x16xi8>) outs(%alloc_1282 : memref<1x4x6300x1xi32>)
    %alloc_1283 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    linalg.generic {indexing_maps = [#map1, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1282 : memref<1x4x6300x1xi32>) outs(%alloc_1283 : memref<1x4x6300x1xf32>) {
    ^bb0(%in: i32, %out: f32):
      %419 = arith.sitofp %in : i32 to f32
      linalg.yield %419 : f32
    }
    %alloc_1284 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    linalg.generic {indexing_maps = [#map1, #map8, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1283, %161 : memref<1x4x6300x1xf32>, memref<1x1x1x1xf32>) outs(%alloc_1284 : memref<1x4x6300x1xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1285 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300x1xf32>
    linalg.generic {indexing_maps = [#map1, #map8, #map1], iterator_types = ["parallel", "parallel", "parallel", "parallel"]} ins(%alloc_1284, %160 : memref<1x4x6300x1xf32>, memref<1x1x1x1xf32>) outs(%alloc_1285 : memref<1x4x6300x1xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %collapse_shape_1286 = memref.collapse_shape %alloc_1285 [[0], [1], [2, 3]] : memref<1x4x6300x1xf32> into memref<1x4x6300xf32>
    %subview_1287 = memref.subview %collapse_shape_1286[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_1288 = memref.subview %collapse_shape_1286[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %alloc_1289 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%3, %subview_1287 : memref<1x2x6300xf32>, memref<1x2x6300xf32, strided<[25200, 6300, 1]>>) outs(%alloc_1289 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.subf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1290 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%2, %subview_1288 : memref<1x2x6300xf32>, memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>) outs(%alloc_1290 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.addf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1291 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1289, %159 : memref<1x2x6300xf32>, memref<1x1x1xf32>) outs(%alloc_1291 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1292 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1290, %158 : memref<1x2x6300xf32>, memref<1x1x1xf32>) outs(%alloc_1292 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1293 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1291, %alloc_1292 : memref<1x2x6300xf32>, memref<1x2x6300xf32>) outs(%alloc_1293 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.addf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %expand_shape_1294 = memref.expand_shape %1 [] output_shape [1, 1, 1] : memref<f32> into memref<1x1x1xf32>
    %alloc_1295 = memref.alloc() {alignment = 64 : i64} : memref<1x1x1xf32>
    linalg.generic {indexing_maps = [#map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%expand_shape_1294 : memref<1x1x1xf32>) outs(%alloc_1295 : memref<1x1x1xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.divf %cst_3, %in : f32
      linalg.yield %419 : f32
    }
    %alloc_1296 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1293, %alloc_1295 : memref<1x2x6300xf32>, memref<1x1x1xf32>) outs(%alloc_1296 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1297 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1290, %alloc_1289 : memref<1x2x6300xf32>, memref<1x2x6300xf32>) outs(%alloc_1297 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.subf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1298 = memref.alloc() {alignment = 64 : i64} : memref<1x2x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1297, %157 : memref<1x2x6300xf32>, memref<1x1x1xf32>) outs(%alloc_1298 : memref<1x2x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1299 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    %subview_1300 = memref.subview %alloc_1299[0, 0, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    memref.copy %alloc_1296, %subview_1300 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1]>>
    %subview_1301 = memref.subview %alloc_1299[0, 2, 0] [1, 2, 6300] [1, 1, 1] : memref<1x4x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    memref.copy %alloc_1298, %subview_1301 : memref<1x2x6300xf32> to memref<1x2x6300xf32, strided<[25200, 6300, 1], offset: 12600>>
    %expand_shape_1302 = memref.expand_shape %0 [[0, 1], [2]] output_shape [1, 1, 6300] : memref<1x6300xf32> into memref<1x1x6300xf32>
    %alloc_1303 = memref.alloc() {alignment = 64 : i64} : memref<1x4x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map9, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1299, %expand_shape_1302 : memref<1x4x6300xf32>, memref<1x1x6300xf32>) outs(%alloc_1303 : memref<1x4x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1304 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1262 : memref<1x80x6300xf32>) outs(%alloc_1304 : memref<1x80x6300xf32>) {
    ^bb0(%in: f32, %out: f32):
      %419 = arith.negf %in : f32
      %420 = math.exp %419 : f32
      %421 = arith.addf %420, %cst_3 : f32
      %422 = arith.divf %cst_3, %421 : f32
      linalg.yield %422 : f32
    }
    %alloc_1305 = memref.alloc() {alignment = 64 : i64} : memref<1x80x6300xf32>
    linalg.generic {indexing_maps = [#map3, #map4, #map3], iterator_types = ["parallel", "parallel", "parallel"]} ins(%alloc_1304, %156 : memref<1x80x6300xf32>, memref<1x1x1xf32>) outs(%alloc_1305 : memref<1x80x6300xf32>) {
    ^bb0(%in: f32, %in_1309: f32, %out: f32):
      %419 = arith.mulf %in, %in_1309 : f32
      linalg.yield %419 : f32
    }
    %alloc_1306 = memref.alloc() {alignment = 64 : i64} : memref<1x84x6300xf32>
    %subview_1307 = memref.subview %alloc_1306[0, 0, 0] [1, 4, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    memref.copy %alloc_1303, %subview_1307 : memref<1x4x6300xf32> to memref<1x4x6300xf32, strided<[529200, 6300, 1]>>
    %subview_1308 = memref.subview %alloc_1306[0, 4, 0] [1, 80, 6300] [1, 1, 1] : memref<1x84x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    memref.copy %alloc_1305, %subview_1308 : memref<1x80x6300xf32> to memref<1x80x6300xf32, strided<[529200, 6300, 1], offset: 25200>>
    %418 = bufferization.to_tensor %alloc_1306 : memref<1x84x6300xf32> to tensor<1x84x6300xf32>
    return %418 : tensor<1x84x6300xf32>
  }
}

