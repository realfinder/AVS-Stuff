# 2020.04.06 HBD

# Changes 2008-08-18: (Didée)
# - Replaced the ugly stackXXX cascade with mt_LutSpa() (requires MaskTools v2.0a35)
# - Changed Quant and Offset defaults to 24,28,2,4,4,8

# Changes 2010-05-25:
# - Explicitly specified parameters of mt_LutSpa()
#   (required due to position of new 'biased' parameter, starting from MaskTools 2.0a43)
# - Non mod 16 input is now padded with borders internally

# Changes 2010-08-18:
# - Replaced AddBorders with PointResize
# - Changed Quant and Offset defaults to 18,19,3,4,1,1 to reduce blurring

# Changes 2010-10-16:
# - Replaced 'relative' with the new 'mode' parameter in mt_LutSpa(), starting from MaskTools 2.0a45
# - Changed Quant and Offset defaults to 24,26,1,1,2,2 to increase effectiveness, but still within sensible limits.
#   (see for details: http://forum.doom9.org/showthread.php?p=810932#post810932)

# Changes 2011-11-29: (06_taro)
# - Replaced (chroma=uv>2?"process":"ignore") by (chroma=uv>2?"process":"copy") to avoid garbage clip when uv=2.
#   The formal parameter is not used by MaskTools2 any more, if ever used.
#   Foxyshadis once mentioned chroma="ignore" but I had never found a document containing it.

# Changes 2016-06-19: (A.SONY)
# - re add "ignore" for chroma but if uv=2 will use "copy"
# - add exdeblock1 and exdeblock2 to use an external deblock

function Deblock_QED ( clip clp, int "quant1", int "quant2", 
 \                     int "aOff1", int "bOff1", int "aOff2", int "bOff2", int "uv", string "exdeblock1", string "exdeblock2" )
{

sisavs26	= !(VersionNumber() < 2.60)

quant1 = default( quant1, 24 ) # Strength of block edge deblocking
quant2 = default( quant2, 26 ) # Strength of block internal deblocking

aOff1 = default( aOff1, 1 ) # halfway "sensitivity" and halfway a strength modifier for borders
aOff2 = default( aOff2, 1 ) # halfway "sensitivity" and halfway a strength modifier for block interiors
bOff1 = default( bOff1, 2 ) # "sensitivity to detect blocking" for borders
bOff2 = default( bOff2, 2 ) # "sensitivity to detect blocking" for block interiors

uv    = default( uv, 3 )    # u=3 -> use proposed method for chroma deblocking
                            # u=2 -> no chroma deblocking at all (just copy it from source)
                            # u=1 -> ignore chroma (garbage but fastest method)
                            # u=-1 -> directly use chroma debl. from the normal|strong deblock()

# add borders if clp is not mod 8
padX = clp.width%8 == 0 ? 0 : (8 - clp.width%8)
padY = clp.height%8 == 0 ? 0 : (8 - clp.height%8)
clp=clp.pointresize(clp.width+padX, clp.height+padY, 0, 0, clp.width+padX, clp.height+padY)

# block
block = sisavs26 ? clp.mt_LutSpa(mode="absolute",expr="x 1 + 8 % 1 < x 8 % 1 < y 1 + 8 % 1 < y 8 % 1 < | | | 255 0 ? scalef",scale_inputs="intf",U=3,V=3) : clp.mt_LutSpa(mode="absolute",expr="x 1 + 8 % 1 < x 8 % 1 < y 1 + 8 % 1 < y 8 % 1 < | | | 255 0 ?",U=3,V=3)

# create normal deblocking (for block borders) and strong deblocking (for block interiour)
normal = defined(exdeblock1) ? eval("clp." + exdeblock1) : clp.deblock(quant=quant1,aOffset=aOff1,bOffset=bOff1)
strong = defined(exdeblock2) ? eval("clp." + exdeblock2) : clp.deblock(quant=quant2,aOffset=aOff2,bOffset=bOff2)

# build difference maps of both
normalD = mt_makediff(clp,normal,chroma=uv>2?"process":uv==2?"copy":"ignore") 
strongD = mt_makediff(clp,strong,chroma=uv>2?"process":uv==2?"copy":"ignore") 

# separate border values of the difference maps, and set the interiours to '128'
normalD2 = sisavs26 ? mt_lutxy(normalD,block,expr="y range_max == x range_half ?",use_expr=1,U=uv,V=uv) : mt_lutxy(normalD,block,expr="y 255 == x 128 ?",U=uv,V=uv)
strongD2 = sisavs26 ? mt_lutxy(StrongD,block,expr="y range_max == x range_half ?",use_expr=1,U=uv,V=uv) : mt_lutxy(StrongD,block,expr="y 255 == x 128 ?",U=uv,V=uv)

# interpolate the border values over the whole block: DCTFilter can do it. (Kiss to Tom Barry!)
# (Note: this is not fully accurate, but a reasonable approximation.)
# add borders if clp is not mod 16
sw=strongD2.width sh=strongD2.height
remX = sw%16 == 0 ? 0 : (16 - sw%16)
remY = sh%16 == 0 ? 0 : (16 - sh%16)
strongD3 = sisavs26 ? strongD2.pointresize(sw+remX, sh+remY, 0, 0, sw+remX, sh+remY).mt_lut(expr="x range_half - 1.01 * range_half +",use_expr=2,U=uv,V=uv)\
                        .dctfilter(1.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0).crop(0,0,-remX,-remY) : \
						strongD2.pointresize(sw+remX, sh+remY, 0, 0, sw+remX, sh+remY).mt_lut(expr="x 128 - 1.01 * 128 +",U=uv,V=uv)\
                        .dctfilter(1.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0).crop(0,0,-remX,-remY)

# apply compensation from "normal" deblocking to the borders of
# the full-block-compensations calculated from "strong" deblocking ... 
strongD4 = sisavs26 ? mt_lutxy(strongD3,normalD2,expr="y range_half == x y ?",use_expr=2,U=uv,V=uv) : mt_lutxy(strongD3,normalD2,expr="y 128 == x y ?",U=uv,V=uv)

# ... and apply it.
deblocked= mt_makediff(clp,strongD4,chroma=uv>2?"process":uv==2?"copy":"ignore") 

# simple decisions how to treat chroma
deblocked = (uv<0) ? deblocked.mergechroma(strong) : uv<2 ? deblocked.mergechroma(normal) : deblocked

deblocked.crop(0,0,-padX,-padY) # remove mod 8 borders
}
