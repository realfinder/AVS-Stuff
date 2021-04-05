# FineDehalo
# 1.1 mod8.79
#
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar.

Function FineDehalo (clip src, float "rx", float "ry", float "thmi", float "thma", float "thlimi", float "thlima", float "darkstr", float "brightstr", int "showmask", float "contra", bool "excl", float "edgeproc", val "exdehalo", clip "exedgesm")
{
	rx        = Default (rx,          2)
	ry        = Default (ry,         rx)
	thmi      = Default (thmi,       80)
	thma      = Default (thma,      128)
	thlimi    = Default (thlimi,     50)
	thlima    = Default (thlima,    100)
	darkstr   = Default (darkstr,   1.0)
	brightstr = Default (brightstr, 1.0)
	showmask  = Default (showmask,    0)
	contra    = Default (contra,    0.0)
	excl      = Default (excl,     true)
	edgeproc  = Default (edgeproc,  0.0)

	src


	### Dehaloing ###

	dehaloed = defined(exdehalo) ? isclip(exdehalo) ? exdehalo : eval("last." + exdehalo) : DeHalo_alpha (rx=rx, ry=ry, darkstr=darkstr, brightstr=brightstr)

	# Contrasharpening
	dehaloed =   (contra > 0)
\	           ? dehaloed.FineDehalo_contrasharp (src, contra, false)
\	           : dehaloed

	edgesm = defined(exedgesm) ? exedgesm : FineDehaloedges(rx=rx, ry=ry, thmi=thmi, thma=thma, thlimi=thlimi, thlima=thlima, showmask=showmask, excl=excl, edgeproc=edgeproc)

	### Masking ###

		  (showmask != 0) ? edgesm
	\	:                   mt_merge (last, dehaloed, edgesm, y=3, u=2, v=2)
}

# level == 1.0 : normal contrasharp
Function FineDehalo_contrasharp (clip dehaloed, clip src, float level, bool "chroma")
{
	chroma   = Default (chroma,   true)
	sisavs26 = !(VersionNumber() < 2.6)
	bb  = dehaloed.RemoveGrain (11, chroma ? undefined : -1)
	bb2 = bb.Repair (bb.Repair (bb.Medianblur (2, -256, -256), 1, chroma ? undefined : -1), 1, chroma ? undefined : -1)
	xd  = mt_makediff (bb, bb2, u=chroma ? 3 : undefined, v=chroma ? 3 : undefined)
	xd  = !sisavs26 ? xd.mt_lut ("x 128 - 2.49 * "+String(level)+" * 128 +", u=chroma ? 3 : undefined, v=chroma ? 3 : undefined)
              \     : xd.mt_lut ("x range_half - 2.49 * "+String(level)+" * range_half +", use_expr=2, u=chroma ? 3 : undefined, v=chroma ? 3 : undefined)
	xdd = !sisavs26 ? mt_lutxy (
\		xd,
\		mt_makediff (src, dehaloed, u=chroma ? 3 : undefined, v=chroma ? 3 : undefined),
\		"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?", u=chroma ? 3 : undefined, v=chroma ? 3 : undefined
\	) : mt_lutxy (
\		xd,
\		mt_makediff (src, dehaloed, u=chroma ? 3 : undefined, v=chroma ? 3 : undefined),
\		"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?", use_expr=2, u=chroma ? 3 : undefined, v=chroma ? 3 : undefined
\	)

	dehaloed.mt_adddiff (xdd, y=3, u=chroma ? 3 : 2, v=chroma ? 3 : 2)
}

# moved FineDehalo edges mask in stand-alone Function
Function FineDehaloedges (clip src, float "rx", float "ry", float "thmi", float "thma", float "thlimi", float "thlima", int "showmask", bool "excl", float "edgeproc", clip "edgemask")
{
	sisavs26 = !(VersionNumber() < 2.6)
	rx        = Default (rx,          2)
	ry        = Default (ry,         rx)
	thmi      = Default (thmi,       80)
	thma      = Default (thma,      128)
	thlimi    = Default (thlimi,     50)
	thlima    = Default (thlima,    100)
	showmask  = Default (showmask,    0)
	excl      = Default (excl,     true)
	edgeproc  = Default (edgeproc,  0.0)

	rx_i = Round (abs(rx))
	ry_i = Round (abs(ry))

	src

	### Main edges ###

	# Basic edge detection, thresholding will be applied later.
	edges = defined(edgemask) ? edgemask : mt_edge (mode="prewitt", thY1=0, thY2=255)

	# Keeps only the sharpest edges (line edges)
	strong = !sisavs26 ? edges.mt_lut (expr="x "+String(thmi)+" - "+String(thma-thmi)+" / 255 *")
                 \     : edges.mt_lut (expr="x "+String(thmi)+" scalef - "+String(thma-thmi)+" scalef / range_max *", scale_inputs="floatf", clamp_float=true, use_expr=2)

	# Extends them to include the potential halos
	large = strong.mt_expand_multi (sw=rx_i, sh=ry_i)


	### Exclusion zones ###

	# When two edges are close from each other (both edges of a single
	# line or multiple parallel color bands), the halo removal
	# oversmoothes them or makes seriously bleed the bands, producing
	# annoying artifacts. Therefore we have to produce a mask to exclude
	# these zones from the halo removal.

	# Includes more edges than previously, but ignores simple details
	light = !sisavs26 ? edges.mt_lut (expr="x "+String(thlimi)+" - "+String(thlima-thlimi)+" / 255 *")
                \     : edges.mt_lut (expr="x "+String(thlimi)+" scalef - "+String(thlima-thlimi)+" scalef / range_max *", scale_inputs="floatf", clamp_float=true, use_expr=2)

	# To build the exclusion zone, we make grow the edge mask, then shrink
	# it to its original shape. During the growing stage, close adjacent
	# edge masks will join and merge, forming a solid area, which will
	# remain solid even after the shrinking stage.

	# Mask growing
	shrink = light.mt_expand_multi (sw=rx_i, sh=ry_i, mode="ellipse")

	# At this point, because the mask was made of a shades of grey, we may
	# end up with large areas of dark grey after shrinking. To avoid this,
	# we amplify and saturate the mask here (actually we could even
	# binarize it).
	shrink = !sisavs26 ? shrink.mt_lut ("x 4 *")
                 \     : shrink.mt_lut ("x 4 *", clamp_float=true, use_expr=2)

	# Mask shrinking
	shrink = shrink.mt_inpand_multi (sw=rx_i, sh=ry_i, mode="ellipse")

	# This mask is almost binary, which will produce distinct
	# discontinuities once applied. Then we have to smooth it.
	shrink = shrink.RemoveGrain (20, -1)
	shrink = shrink.RemoveGrain (20, -1)


	### Final mask building ###

	# Previous mask may be a bit weak on the pure edge side, so we ensure
	# that the main edges are really excluded. We do not want them to be
	# smoothed by the halo removal.
	shr_med = (excl) ? mt_logic (strong, shrink, mode="max") : strong

	# Substracts masks and amplifies the difference to be sure we get 255
	# on the areas to be processed.
	outside = !sisavs26 ? mt_lutxy (large, shr_med, "x y - 2 *")
                  \     : mt_lutxy (large, shr_med, "x y - 2 *", clamp_float=true, use_expr=1)

	# If edge processing is required, adds the edgemask
	outside = (edgeproc > 0) ? !sisavs26 ? mt_lutxy(outside, strong, "x y "+String(edgeproc * 0.66)+" * +") : mt_lutxy(outside, strong, "x y "+String(edgeproc * 0.66)+" * +", clamp_float=true, use_expr=1) : outside

	# Smooth again and amplify to grow the mask a bit, otherwise the halo
	# parts sticking to the edges could be missed.
	!sisavs26 ? outside.RemoveGrain (20, -1).mt_lut ("x 2 *")
        \     : outside.RemoveGrain (20, -1).mt_lut ("x 2 *", clamp_float=true, use_expr=1)

	  (showmask == 1) ? outside.GreyScale ()
\	: (showmask == 2) ? shrink.GreyScale ()
\	: (showmask == 3) ? edges.GreyScale ()
\	: (showmask == 4) ? strong.GreyScale ()
\	:                   last
}



# Try to remove 2nd order halos.
Function FineDehalo2 (clip src, string "hconv", string "vconv", int "showmask")
{
	sisavs26 = !(VersionNumber() < 2.6)
	hconv    = Default (hconv, "-1 -2 0 0 40 0 0 -2 -1")
	vconv    = Default (vconv, "-2 -1 0 0 40 0 0 -1 -2")
	showmask = Default (showmask, 0)

	src
	fix_h = mt_convolution (horizontal="1", vertical=vconv, y=3, u=2, v=2)
	fix_v = mt_convolution (horizontal=hconv, vertical="1", y=3, u=2, v=2)
	edges_h = mt_edge (mode="1 2 1 0 0 0 -1 -2 -1", thY1=0, thY2=255)
	edges_v = mt_edge (mode="1 0 -1 2 0 -2 1 0 -1", thY1=0, thY2=255)
	mask_h = edges_h	#.mt_lut (expr="x 2 *")
	mask_v = edges_v	#.mt_lut (expr="x 2 *")
	temp_h = !sisavs26 ? mt_lutxy (mask_h, mask_v, expr="x 3 * y -")
                 \	   : mt_lutxy (mask_h, mask_v, expr="x 3 * y -", clamp_float=true, use_expr=1)
	temp_v = !sisavs26 ? mt_lutxy (mask_v, mask_h, expr="x 3 * y -")
                 \	   : mt_lutxy (mask_v, mask_h, expr="x 3 * y -", clamp_float=true, use_expr=1)
	mask_h = temp_h
	mask_v = temp_v

	mask_h = mask_h.FineDehalo2_grow_mask ("vertical")
	mask_v = mask_v.FineDehalo2_grow_mask ("horizontal")

	src
	mt_merge (last, fix_h, mask_h, y=3, u=2, v=2)
	mt_merge (last, fix_v, mask_v, y=3, u=2, v=2)

	  (showmask == 1) ? mt_logic (mask_h, mask_v, mode="max").GreyScale ()
\	:                   last
}

Function FineDehalo2_grow_mask (clip mask, string mode)
{
	sisavs26 = !(VersionNumber() < 2.6)
	Assert ((mode == "horizontal" || mode == "vertical"), "Wrong mode")

	mask
	mt_expand (mode=mode).mt_inpand (mode=mode)
	mask_1 = mt_expand (mode=mode)
	mask_2 = mask_1.mt_expand (mode=mode).mt_expand (mode=mode)
	!sisavs26 ? mt_lutxy (mask_2, mask_1, expr="x y -")
        \	  : mt_lutxy (mask_2, mask_1, expr="x y -", clamp_float=true, use_expr=1)
	!sisavs26 ? RemoveGrain (12, -1).mt_lut (expr="x 1.8 *")
        \	  : RemoveGrain (12, -1).mt_lut (expr="x 1.8 *", clamp_float=true, use_expr=2)
}


# new Functions added to the mod ver.


Function FineDehaloanalog (clip src, int "dhhradius", float "arx", float "ary", string "exdehalo", clip "fexedgesm", clip "linesm", bool "remasked", float "darkstr", float "brightstr")
{
rx       = Default (arx,          2) # DeHalo_alpha rx
ry       = Default (ary,         rx) # DeHalo_alpha ry
edgm     = Defined(linesm) ? linesm : src.slinesm()
rad      = Default(dhhradius,      2)
remasked = Default(remasked, true)
blurmix  = remasked ? 0.5 : 0.8
	rx_i = Round (rx)
	ry_i = Round (ry)
exdehalo = Default(exdehalo, "VHSHaloremover("+String(rx_i)+","+String(ry_i)+",200,100,"+String(blurmix)+")")
useldh   = !defined(darkstr) && !defined(brightstr) && !defined(arx) && !defined(ary)

src
lightdh = DeHalo_alpha_mt(rx=rx_i,ry=ry_i,darkstr=0.2,brightstr=0.8)
FDedges = Defined(fexedgesm) ? fexedgesm : lightdh.FineDehaloedges(rx=rx_i,ry=ry_i)
alphadh = remasked ? lightdh : \ 
                     FineDehalo(rx=rx,ry=ry,exdehalo=useldh ? lightdh : \
                                                              undefined(),darkstr=darkstr,brightstr=brightstr,exedgesm=FDedges)

hfil = alphadh.FineDehalo(rx=rx,ry=ry,exdehalo=DeHaloHmod(rad,exdehalo=exdehalo,extmask=edgm), exedgesm=FDedges)
RM2  = remasked ? spasses(edgm.mt_inflate(),rad,"mt_expand()").mt_inflate() : nop()

DeRinging = mt_Merge(hfil, src, edgm.mt_inflate(155,155),u=remasked ? 1 : 4,v=remasked ? 1 : 4)
remasked ? mt_Merge(src, DeRinging, RM2, u=2, v=2) : DeRinging
}