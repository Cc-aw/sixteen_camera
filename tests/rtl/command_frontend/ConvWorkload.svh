// Inside MemoryLane, simulation only. Six un-fenced 3x3 convolutions exercise
// LoopConv slot backpressure without the old packet ingress/CPU credit loop.
task prepare_conv;
  reg [63:0] packed_lut;
  integer value;
  for(integer i=0;i<75;i=i+1) memory['h3000+i]=8'(ID+1);
  for(integer i=0;i<108;i=i+1) memory['h3100+i]=1;
  for(integer i=0;i<16;i=i+1) memory['h3200+i]=0;
  for(integer i=0;i<4;i=i+1) memory['h3200+4*i]=8'(i+1);
  // Deliberately non-identity LUT: proves funct26 reaches the original LUT.
  for(integer base=0;base<256;base=base+8) begin
    packed_lut=0;
    for(integer b=0;b<8;b=b+1) begin
      value=base+b; if(value>=128)value=value-256;
      packed_lut[b*8+:8]=8'(value/2);
    end
    raw(26,64'(base),packed_lut,0);
  end
  // no_pool path retains store configuration; select activation6 explicitly.
  raw(0,64'h1a,64'h00003c0000000004,0);
  for(integer c=0;c<6;c=c+1) begin
    raw(16,64'h0004000300050001,64'h0001000300030003,0);
    raw(17,64'h0003000300010100,64'h0001000300030004,0);
    raw(18,64'h0003000300030000,64'h5,0);
    raw(19,64'h0003000000000001,64'h0003000400040003,0);
    raw(20,64'(BASE)+'h3100,64'(BASE)+'h3400+c*64,0);
    raw(21,64'(BASE)+'h3200,64'(BASE)+'h3000,0);
    raw(15,64'h100,64'h31,0);
  end
endtask

task check_conv;
  integer expected,actual;
  for(integer c=0;c<6;c=c+1)
    for(integer p=0;p<9;p=p+1)
      for(integer ch=0;ch<4;ch=ch+1)begin
        expected=(27*(ID+1)+ch+1)/2;
        actual=$signed(memory['h3400+c*64+p*4+ch]);
        if(actual!==expected)
          $fatal(1,"conv lane=%0d chunk=%0d pixel=%0d ch=%0d expected=%0d actual=%0d",ID,c,p,ch,expected,actual);
      end
endtask
