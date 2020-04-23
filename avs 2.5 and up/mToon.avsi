## mToon Toon v0.82 edit
## 2020.04.23 HBD mod base on MOmonster edit
###############

# function created by mf
#	support by Soulhunter ;-)
# 	ported to masktools v2 and optimized by Didee (0.82)
# 	added parameters and smaller changes by MOmonster (0.82 edited)

# toon v0.8 is the newest light-weight build of mf´s nice line darken function mf_toon
#
# needed filters:
#	- MaskTools v2
#	- AWarpSharp2
#
# parameters:
#	str	- strength of the line darken				1.0
#	l_thr	- lower threshold for the linemask			2
#	u_thr	- upper threshold for the linemask			12
#	wdepth	- warping depth (awarpsharp readme)			32
#	wlevel	- warping level (awarpsharp readme)			2	(1 is faster)
#	fast	- gives better speed with only a little
#		  difference to the default output			false


function mtoon(input, float "str", float "l_thr", float "u_thr", int "wdepth", int "wlevel", bool "fast", bool "lite")
{
sisavs26 = !(VersionNumber() < 2.60)
sstr	= string(default(str,1.0))
lthr	= string(128+default(l_thr,2))
uthr	= string(128+default(u_thr,12))
ludiff	= string(default(u_thr,12)-default(l_thr,2))
wdepth	= default(wdepth,32)
wlevel	= default(wlevel,2)
fast	= default(fast,false)
lite	= default(lite,false)

input.mt_expand().mt_inpand().mt_makediff(input)
lite ? last : mt_logic(last,last.aWarpsharp2(depth=wdepth,blur=wlevel,chroma=1), "min")
fast==true ? sisavs26 ? mt_lut("x "+lthr+" <= 128 x "+uthr+" >= x "+uthr+" x - 128 * x x "+lthr+" - * + "+ludiff+" / ? 128 - "+sstr+" * 128 + ?", scale_inputs="allf", use_expr=2) : mt_lut("x "+lthr+" <= 128 x "+uthr+" >= x "+uthr+" x - 128 * x x "+lthr+" - * + "+ludiff+" / ? 128 - "+sstr+" * 128 + ?") : \
sisavs26 ? mt_lutxy(last,last.mt_expand(),"y "+lthr+" <= 128 y "+uthr+" >= x "+uthr+" y - 128 * x y "+lthr+" - * + "+ludiff+" / ? 128 - "+sstr+" * 128 + ?", scale_inputs="allf", use_expr=1) : mt_lutxy(last,last.mt_expand(),"y "+lthr+" <= 128 y "+uthr+" >= x "+uthr+" y - 128 * x y "+lthr+" - * + "+ludiff+" / ? 128 - "+sstr+" * 128 + ?")

return mt_makediff(input,last,U=2,V=2)
}