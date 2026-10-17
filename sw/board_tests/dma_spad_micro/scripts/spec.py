"""Transaction counts derived from logical rows and original repeat writes."""

MODES=('legacy','read_coalesced','read_assembled')
CASES=('continuous','strided')


def predict(case,mode):
    cols,rows,pixels,stride,offset,ops=(case[k] for k in ('c','n','p','stride','offset','ops'))
    eligible=mode!=0 and (stride==cols and rows>1 or mode==2 and pixels>1)
    merge=int(eligible and stride==cols and rows>1)
    assembly=int(eligible and mode==2)
    spans=[(offset,cols*rows)] if merge else [(offset+i*stride,cols) for i in range(rows)]
    get32=get64=returned=0
    for address,length in spans:
        while length:
            useful,width=max(((min(length,w-address%w),w) for w in (32,64)),key=lambda x:(x[0],-x[1]))
            get32+=width==32;get64+=width==64;returned+=width
            address+=useful;length-=useful
    writes=rows+pixels-1 if assembly else (rows if eligible else get32+get64)*pixels
    values={i:0 for i in range(8,35)}
    values.update({8:rows*ops,9:rows*cols*ops,11:int(eligible)*ops,
        18:get32*ops,19:get64*ops,21:writes*ops if assembly else 0,
        22:writes*ops,31:0,33:returned*ops})
    return dict(read_merge=merge,assembly=assembly,values=values)
