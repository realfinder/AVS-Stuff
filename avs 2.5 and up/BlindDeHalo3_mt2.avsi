# 2020.03.24
# BlindDeHalo3 with high bit support, need masktools 2.2.17 or up in avs26 and avs+

function BlindDeHalo3( clip input, float "rx", float "ry", int "strength",
 \                     float "lodamp", float "hidamp", float "sharpness", float "tweaker",
 \                     int "PPmode", float "PPlimit", bool "interlaced")
{
rx =         default( rx,           3.0 )
ry =         default( ry,           3.0 )
strength =   default( strength,     125 )
lodamp =     default( lodamp,       0.0 )
hidamp =     default( hidamp,       0.0 )
sharpness =  default( sharpness,    0.0 )
tweaker =    default( tweaker,      0.0 )
PPmode =     default( PPmode,         0 )
PPlimit =    default( PPlimit, (abs(PPmode)==3) ? 4 : 0 )
interlaced = default( interlaced, false )

sharpness = (sharpness>1.58) ? 1.58 : sharpness
tweaker   = (tweaker > 1.00) ? 1.00 : tweaker
strength  = float(strength)*(1.0+sharpness*0.25)
RR   = string((rx+ry)/2.0)
ST   = string(float(strength)/100.0)
LD   = string(lodamp)
HD   = string(pow(hidamp,2))
TWK0 = "x y - 12 "+ST+" / "+RR+" / /"
TWK  = "x y - 12 "+ST+" / "+RR+" / / abs"
sisavs26 = !(VersionNumber() < 2.6)
TWK_HLIGHT = !sisavs26 ? "x y - abs 1 < 128 "+TWK+" 128 "+TWK+" - "+TWK+" 128 / * + "+TWK0+" "+TWK+" "+LD+" + / * "
                                      \ + "128 "+TWK+" - 20 / 2 ^ 128 "+TWK+" - 20 / 2 ^ "+HD+" + / * 128 + ?"
             \                     : "x y - abs 1 scalef < range_half "+TWK+" range_half "+TWK+" - "+TWK+" range_half / * + "+TWK0+" "+TWK+" "+LD+" + / * "
                                      \ + "range_half "+TWK+" - 20 scalef / 2 ^ range_half "+TWK+" - 20 scalef / 2 ^ "+HD+" + / * range_half + ?"

sisphbd = AvsPlusVersionNumber > 2294
 
sislumaonly = sisphbd ? input.isy() : !sisavs26 ? true : input.isy8()
 
clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

i     = (interlaced==false) ? clp : clp.separatefields()
oxi   = i.width
oyi   = i.height
sm    = i.bicubicresize(m4_sh(oxi/rx),m4_sh(oyi/ry))
mm    = !sisavs26 ? mt_lutxy(sm.mt_expand(),sm.mt_inpand(),"x y - 4 *") : mt_lutxy(sm.mt_expand(),sm.mt_inpand(),"x y - 4 *",clamp_float=true,use_expr=3)
mm    = mm.mt_expand().mt_deflate().blur(1.58).mt_inflate().bicubicresize(oxi,oyi,1.0,.0).mt_inflate()
sm    = sm.bicubicresize(oxi,oyi,1.0,.0)
smd   = !sisavs26 ? mt_lutxy(i.sharpen(tweaker),sm,TWK_HLIGHT) : mt_lutxy(i.sharpen(tweaker),sm,TWK_HLIGHT,use_expr=2)
smd   = (sharpness==0.0) ? smd : smd.blur(sharpness)
clean = !sisavs26 ? mt_lutxy(i,smd,yexpr="x y 128 - -") : mt_lutxy(i,smd,yexpr="x y range_half - -", use_expr=3)
clean = mt_merge(i,clean,mm,u=2,v=2)

LL    = string(PPlimit)
LIM   = !sisavs26 ? "x "+LL+" + y < x "+LL+" + x "+LL+" - y > x "+LL+" - y ? ?" : "x "+LL+" scalef + y < x "+LL+" scalef + x "+LL+" scalef - y > x "+LL+" scalef - y ? ?"

base  = (PPmode<0) ? i : clean
small = base .bicubicresize(m4_sh(oxi/sqrt(rx*1.5)),m4_sh(oyi/sqrt(ry*1.5)))
ex1   = small.mt_expand().blur(.5)
in1   = small.mt_inpand().blur(.5)
huexp = "x y - 1 1 / * 1.0 ^ 1 - 5 *"
hull  = mt_logic( !sisavs26 ? mt_lutxy( ex1.mt_expand().RemoveGrain(12,-1), ex1, huexp ) : mt_lutxy( ex1.mt_expand().RemoveGrain(12,-1), ex1, "x y - 1 scalef - 5 *",clamp_float=true,use_expr=3 )
 \               ,!sisavs26 ? mt_lutxy( in1, in1.mt_inpand().RemoveGrain(12,-1), huexp ) : mt_lutxy( in1, in1.mt_inpand().RemoveGrain(12,-1), "x y - 1 scalef - 5 *",use_expr=3 )
 \               ,"max")
 \     .bicubicresize(oxi,oyi,1.0,.0)

postclean = (abs(PPmode)== 1) ?  mt_merge(base,small.bicubicresize(oxi,oyi,1.0,.0),hull,U=2,V=2)
 \        : (abs(PPmode)== 2) ?  mt_merge(base,base.RemoveGrain(19,-1),hull,U=2,V=2)
 \        : (abs(PPmode)== 3) ?  mt_merge(base,base.RemoveGrain(4,-1),hull,U=2,V=2)
 \        :                      clean

postclean = (PPlimit==0) ?  postclean
 \        :                 !sisavs26 ? mt_lutxy(base,postclean,yexpr=LIM,U=2,V=2) : mt_lutxy(base,postclean,yexpr=LIM,U=2,V=2, use_expr=1)

(PPmode==0) ? clean   : postclean
interlaced  ? weave() : last
sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)

return( last )
}
