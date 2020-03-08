###############################
# FastLineDarken 1.48x MT MOD #
###############################
#
# Written by Vectrangle    (http://forum.doom9.org/showthread.php?t=82125)
# Didée: - Speed Boost, Updated: 11th May 2007
# Dogway - added protection option. 12-May-2011
# A.SONY - added high bit support and others. 31-Mar-2017
#
#  * requires mt_masktools v2 in avs2.5 and masktools 2.2.17 in avs 2.6 or avs+
#  * requires yuv input
#
#
#
# Parameters are:
#  strength (integer)  - Line darkening amount, 0-256. Default 48. Represents the _maximum_ amount
#                        that the luma will be reduced by, weaker lines will be reduced by
#                        proportionately less.
#  prot     (integer)  - Prevents the darkest lines from being darkened. Protection acts as a threshold.
#                        Values range from 0 (no prot) to ~50 (protect everything). Default 5.
#  luma_cap (integer)  - value from 0 (black) to 255 (white), used to stop the darkening
#                        determination from being 'blinded' by bright pixels, and to stop grey
#                        lines on white backgrounds being darkened. Any pixels brighter than
#                        luma_cap are treated as only being as bright as luma_cap. Lowering
#                        luma_cap tends to reduce line darkening. 255 disables capping. Default 191.
#  threshold (integer) - any pixels that were going to be darkened by an amount less than
#                        threshold will not be touched. setting this to 0 will disable it, setting
#                        it to 4 (default) is recommended, since often a lot of random pixels are
#                        marked for very slight darkening and a threshold of about 4 should fix
#                        them. Note if you set threshold too high, some lines will not be darkened
#  thinning (integer)  - optional line thinning amount, 0-256. Setting this to 0 will disable it,
#                        which is gives a _big_ speed increase. Note that thinning the lines will
#                        inherently darken the remaining pixels in each line a little. Default 0.
#
# Changelog:
#  1.43 - update to masktools 2.2.17
#  1.42 - added high bit support in avs+ and others Optmized
#  1.4  - added protection option. Prevents darkest lines to be over darkened thus creating artifacts (i.e. aliasing, clipping...)
#       - Optmized the code as suggested by Didée for possible faster processing. It also deals with the green screen bug.
#  1.3  - added ability to thin lines, now runs much slower unless thinning=0. Changed the defaults (again)
#  1.2  - huge speed increase using yv12lutxy =)
#       - weird darkening issues gone (they were caused by yv12layer)
#       - show option no longer available due to optimizations. Use subtract() instead
#  1.1  - added luma_cap option
#  1.0  - initial release
#


function FastLineDarkenMOD4( clip input, float "strength", float "prot", float "luma_cap", float "threshold", float "thinning")
{
## parameters ##
str        = string(default(strength, 48) /128.)
lum        = string(default(luma_cap, 191))
protection = default(prot,5)
thr        = string(default(threshold, 4))
thinning   = default(thinning,0)
thn        = string(thinning /16.)

Assert(!(input.isrgb()), "FastLineDarkenMOD4: RGB Color formats is not supported" )

sisphbd = AvsPlusVersionNumber > 2294

sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : !sisavs26 ? true : input.isy8()

c = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()
 
## filtering ##
exin    = c.mt_expand(thy=255/(protection+1)).mt_inpand()
diff    = !sisavs26 ? mt_lutxy(c,exin,yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? 127 +",uexpr="x",vexpr="x")
          \                     : mt_lutxy(c,exin,yexpr="y "+lum+" scalef < y "+lum+" scalef ? x "+thr+" scalef + > x y "+lum+" scalef < y "+lum+" scalef ? - 0 ? 127 scalef +", use_expr=1)
linemask= thinning != 0 ? !sisavs26 ? mt_lut(diff.mt_inpand(),"x 127 - "+thn+" * 255 +").RemoveGrain(20,-1)
			\			: mt_lut(diff.mt_inpand(),"x 127 scalef - "+thn+" * range_max +",clamp_float=true,use_expr=2).RemoveGrain(20,-1) : nop()
thick   = !sisavs26 ? mt_lutxy(c, exin, yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? "+str+" * x +",uexpr="x",vexpr="x",u=2, v=2)
          \                     : mt_lutxy(c, exin, yexpr="y "+lum+" scalef < y "+lum+" scalef ? x "+thr+" scalef + > x y "+lum+" scalef < y "+lum+" scalef ? - 0 ? "+str+" * x +",use_expr=1,u=2, v=2)
thin    = thinning != 0 ? !sisavs26 ? mt_lutxy(c.mt_expand(U=2,V=2),diff,yexpr="x y 127 - "+str+" 1 + * +",u=2, v=2)
			\ 			: mt_lutxy(c.mt_expand(U=2,V=2),diff,yexpr="x y 127 scalef - "+str+" 1 + * +", scale_inputs="floatf", use_expr=3,u=2, v=2) : nop()
 
thinning == 0 ? thick : mt_merge(thin,thick,linemask,y=3,u=2,v=2)

return sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)
}

#############


function FastLineDarkenMOD3( clip c, int "strength", int "prot", int "luma_cap", int "threshold", int "thinning") 
{
## parameters ##
str        = string(default(strength, 50) /128.)
lum 	   = string(default(luma_cap, 191))
protection = default(prot,5)
thr 	   = string(default(threshold, 4))
thinning   = default(thinning,0)
thn 	   = string(thinning /16.)

## filtering ##
exin	= c.mt_expand(thy=255/(protection+1)).mt_inpand()
diff 	= mt_lutxy(c,exin,yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? 127 +",uexpr="x",vexpr="x")
linemask= mt_lut(diff.mt_inpand(),"x 127 - "+thn+" * 255 +").mt_convolution("1 1 1","1 1 1",y=3,u=0,v=0)#".RemoveGrain(20,-1)" gives a little speed boost.
thick 	= mt_lutxy(c, exin, yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? "+str+" * x +",uexpr="x",vexpr="x")
thin 	= mt_lutxy(c.mt_expand(),diff,yexpr="x y 127 - "+str+" 1 + * +")

(thinning == 0) ? thick : mt_merge(thin,thick,linemask,y=3)
return mergechroma(c)}

#############


function FastLineDarkenMOD2( clip c, int "strength", int "luma_cap", int "threshold", int "thinning")
{
## parameters ##
str     = string(default(strength, 48) /128.)
lum     = string(default(luma_cap, 191))
thr     = string(default(threshold, 4))
thinning = default(thinning,24)
thn     = string(thinning /16.)
 
## filtering ##
exin    = c.mt_expand().mt_inpand()
diff    = mt_lutxy(c,exin,yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? 127 +",uexpr="x",vexpr="x",u=2, v=2)
linemask= mt_lut(diff.mt_inpand(),"x 127 - "+thn+" * 255 +").mt_convolution("1 1 1","1 1 1",y=3,u=0,v=0)#".RemoveGrain(20,-1)" gives a little speed boost.
thick   = mt_lutxy(c, exin, yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? "+str+" * x +",uexpr="x",vexpr="x",u=2, v=2)
thin    = mt_lutxy(c.mt_expand(U=2,V=2),diff,yexpr="x y 127 - "+str+" 1 + * +",u=2, v=2)
 
return (thinning == 0) ? thick : mt_merge(thin,thick,linemask,y=3,u=2,v=2)
}


function FastLineDarkenMOD3_dhh( clip input, float "strength", float "prot", float "luma_cap", float "threshold", float "thinning") 
{
## parameters ##
str        = string(default(strength, 48) /128.)
lum        = string(default(luma_cap, 191))
protection = default(prot,5)
thr        = string(default(threshold, 4))
thinning   = default(thinning,0)
thn        = string(thinning /16.)

Assert(!(input.isrgb()), "FastLineDarkenMOD4: RGB Color formats is not supported" )

sisphbd = AvsPlusVersionNumber > 2294

sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : !sisavs26 ? true : input.isy8()

c = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()
 
## filtering ##
exin    = c.mt_expand(thy=255/(protection+1)).mt_inpand()
diff    = !sisavs26 ? mt_lutxy(c,exin,yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? 127 +",uexpr="x",vexpr="x")
          \                     : mt_lutxy(c,exin,yexpr="y "+lum+" scalef < y "+lum+" scalef ? x "+thr+" scalef + > x y "+lum+" scalef < y "+lum+" scalef ? - 0 ? 127 scalef +", use_expr=1)
linemask= thinning != 0 ? !sisavs26 ? mt_lut(diff.mt_inpand(),"x 127 - "+thn+" * 255 +").mt_convolution("1 1 1","1 1 1")
			\			: mt_lut(diff.mt_inpand(),"x 127 scalef - "+thn+" * range_max +", clamp_float=true, use_expr=2).mt_convolution("1 1 1","1 1 1") : nop()
thick   = !sisavs26 ? mt_lutxy(c, exin, yexpr="y "+lum+" < y "+lum+" ? x "+thr+" + > x y "+lum+" < y "+lum+" ? - 0 ? "+str+" * x +",uexpr="x",vexpr="x",u=2, v=2)
          \                     : mt_lutxy(c, exin, yexpr="y "+lum+" scalef < y "+lum+" scalef ? x "+thr+" scalef + > x y "+lum+" scalef < y "+lum+" scalef ? - 0 ? "+str+" * x +",use_expr=1,u=2,v=2)
thin    = thinning != 0 ? !sisavs26 ? mt_lutxy(c.mt_expand(U=2,V=2),diff,yexpr="x y 127 - "+str+" 1 + * +",u=2, v=2)
			\ 			: mt_lutxy(c.mt_expand(U=2,V=2),diff,yexpr="x y 127 scalef - "+str+" 1 + * +",scale_inputs="floatf", use_expr=3,u=2, v=2) : nop()
 
thinning == 0 ? thick : mt_merge(thin,thick,linemask,y=3,u=2,v=2)

return sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)
}