# santiag v1.606
# Simple antialiasing

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# type = "nnedi3", "eedi2", "eedi3" or "sangnom"
# "eedi3" requires v0.9.2 or later and 0.9.2.3 or later in avs26\avs+
# "sangnom" requires sangnom2
Function santiag (clip c, int "strh", int "strv", string "type", int "nns", int "aa", int "aac", int "threads", int "nsize", int "vcheck", int "fw", int "fh", bool "halfres", string "scaler_post", int "maskt", string "typeh", string "typev", bool "lumaonly", bool "aath", int "nnrep", string "scaler_arg", bool "santiag_sangnom_bug")
{
	strh        = Default (strh,                       1)
	strv        = Default (strv,                       1)
	type        = Default (type,                "nnedi3")
	typeh       = Default (typeh,                   type)
	typev       = Default (typev,                   type)
	halfres     = Default (halfres,                false)
	scaler_post = Default (scaler_post, "Spline36Resize")
	aa          = Default (aa,                        48)
	aac         = Default (aac,                       48)
	lumaonly    = Default (lumaonly,               false)
	sangnom_bug = Default (santiag_sangnom_bug,     true)
	aain        = Default (aath,            !sangnom_bug) # make the turn for Horizontal (I think that what any antialiasing should do)
	nnrep       = Default (nnrep,                      0)
	scaler_arg  = Default (scaler_arg,                "")

	c

	w   = Width ()
	h   = Height ()
	fwh = (strv < 0) ? fw : w
	fhh = (strv < 0) ? fh : h

	(strh >= 0) ? santiag_dir (strh, typeh, halfres, scaler_post,  aain, nns=nns, aa=aa, aac=aac, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt, fw=aain ? fw : fwh, fh=aain ? fh : fhh, lumaonly=lumaonly, nnrep=nnrep, scaler_arg=scaler_arg,santiag_sangnom_bug=sangnom_bug) : last
	(strv >= 0) ? santiag_dir (strv, typev, halfres, scaler_post, !aain, nns=nns, aa=aa, aac=aac, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt, fw=aain ? fwh : fw, fh=aain ? fhh : fh, lumaonly=lumaonly, nnrep=nnrep, scaler_arg=scaler_arg,santiag_sangnom_bug=sangnom_bug) : last

	fwx = Default (fw, w)
	fhx = Default (fh, h)
	(strh < 0 && strv < 0) ? Eval (scaler_post + " (fwx, fhx" + scaler_arg + ")") : last
}

Function santiag_dir (clip c, int strength, string type, bool halfres, string scaler_post, bool dot, int "nns", int "aa", int "aac", int "threads", int "nsize", int "vcheck", int "maskt", int "fw", int "fh", bool "lumaonly", int "nnrep", string "scaler_arg", bool "santiag_sangnom_bug")
{
sisavs26= !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sisyuy2 = c.isyuy2()
	c
	w = Width ()
	h = Height ()
	fw = Default (fw, w)
	fh = Default (fh, h)
	sislumaonly = sisphbd ? isy() : sisavs26 ? isy8() : false
	chr420  = sisphbd ? is420() : isyv12()
	chr422  = sisyuy2 || (sisphbd ? is422() : sisavs26 ? isyv16() : false)
	chr411  = sisavs26 ? isyv411() : false
	fullchr = sisphbd ? is444() : sisavs26 ? isyv24() : false

	multi = !fullchr || lumaonly
	c_y = multi && !sislumaonly ? sisphbd ? ExtractY() : sisavs26 ? converttoy8() :   ConvertToYV12 () : last
	c_u = multi && !sislumaonly ? sisphbd ? ExtractU() : sisavs26 ? UToY8() : UToY ().ConvertToYV12 () : nop()
	c_v = multi && !sislumaonly ? sisphbd ? ExtractV() : sisavs26 ? VToY8() : VToY ().ConvertToYV12 () : nop()
	c_y =                                            dot ? c_y.sTryFTurnLeft(!multi).santiag_stronger (strength, type, halfres, multi, sisavs26, nns=nns, aa=aa, aac=aac, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug).sTryFTurnRight(!multi) : c_y.santiag_stronger (strength, type, halfres, multi, sisavs26, nns=nns, aa=aa, aac=aac, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug)
	c_u = lumaonly ? c_u : (multi && !sislumaonly) ? dot ? c_u.sTryFTurnLeft(false ).santiag_stronger (strength, type, halfres, true, sisavs26 , nns=nns, aa=aac        , threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug).sTryFTurnRight(false ) : c_u.santiag_stronger (strength, type, halfres, true, sisavs26 , nns=nns, aa=aac        , threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug) : nop()
	c_v = lumaonly ? c_v : (multi && !sislumaonly) ? dot ? c_v.sTryFTurnLeft(false ).santiag_stronger (strength, type, halfres, true, sisavs26 , nns=nns, aa=aac        , threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug).sTryFTurnRight(false ) : c_v.santiag_stronger (strength, type, halfres, true, sisavs26 , nns=nns, aa=aac        , threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt,nnrep=nnrep,santiag_sangnom_bug=santiag_sangnom_bug) : nop()
	chrfw = chr422 || chr420 ? fw/2 : chr411 ? fw/4 : fw
	chrfh = chr420 ? fh/2 : fh
	c_u = lumaonly ? c_u : multi && !sislumaonly ? Eval ("c_u." + scaler_post + " (chrfw, chrfh, src_left=(halfres)?0:!dot?0:-0.5, src_top=(halfres)?0:dot?0:0.5, src_width=c_u.Width (), src_height=c_u.Height ()" + scaler_arg + ")") : c_u
	c_v = lumaonly ? c_v : multi && !sislumaonly ? Eval ("c_v." + scaler_post + " (chrfw, chrfh, src_left=(halfres)?0:!dot?0:-0.5, src_top=(halfres)?0:dot?0:0.5, src_width=c_v.Width (), src_height=c_v.Height ()" + scaler_arg + ")") : c_v
	c_y =                                          Eval ("c_y." + scaler_post + " (fw,    fh,    src_left=(halfres)?0:!dot?0:-0.5, src_top=(halfres)?0:dot?0:0.5, src_width=c_y.Width (), src_height=c_y.Height ()" + scaler_arg + ")")

	(multi && !sislumaonly) ? YToUV(c_u, c_v, c_y) : c_y
	sisyuy2 && sisavs26 ? ConvertToYUY2() : last
}

Function santiag_stronger (clip c, int strength, string type, bool halfres, bool lumaonly, bool itavs26, int "nns", int "aa", int "aac", int "threads", int "nsize", int "vcheck", int "maskt", int "nnrep", bool "santiag_sangnom_bug")
{
	strength = (strength < 0) ? 0 : strength
	field = strength % 2
	dh = (strength <= 0 && ! halfres)

	(strength > 0) ? c.santiag_stronger (strength - 1, type, halfres, lumaonly, itavs26, nns=nns, aa=aa, aac=aac, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt, nnrep=nnrep, santiag_sangnom_bug=santiag_sangnom_bug) : c

	  (type == "nnedi3" ) ? santiag_nnedi3  (dh, field, lumaonly, nns=nns, threads=threads, nsize=nsize)
\	: (type == "eedi2"  ) ? santiag_eedi2   (dh, field)
\	: (type == "eedi3"  ) ? santiag_eedi3   (dh, field, lumaonly, nns=nns, threads=threads, nsize=nsize, vcheck=vcheck, maskt=maskt, nnrep=nnrep)
\	: (type == "sangnom") ? santiag_sangnom (dh, santiag_sangnom_bug ? field : field==0 ? 2 : 1, aa=aa, aac=aac, itavs26, chroma=!lumaonly,santiag_sangnom_bug=santiag_sangnom_bug)
\	: Assert (false, "Santiag: unexpected value for type.")
}

Function santiag_nnedi3 (clip c, bool dh, int field, bool lumaonly, int "nns", int "threads", int "nsize")
{
	c.nnedi3 (dh=dh, field=field, nns=nns, threads=threads, nsize=nsize, u=!lumaonly, v=!lumaonly)
}

Function santiag_eedi2 (clip c, bool dh, int field)
{
	c
	w = Width ()
	h = Height ()
	(dh) ? last : PointResize (w, h / 2, 0, 1-field, w, h)
	eedi2 (field=field)
}

# maskt = 24
Function santiag_eedi3 (clip c, bool dh, int field, bool lumaonly, int "nns", int "threads", int "nsize", int "vcheck", int "maskt", int "nnrep")
{
	chroma = (lumaonly) ? 1 : 3
	sclip = c.santiag_nnedi3 (dh, field, lumaonly, nns=nns, threads=threads, nsize=nsize)
	mclip_flag = (Defined (maskt) && maskt > 0)

	mclip = (mclip_flag && dh) ? sclip.BicubicResize (c.Width (), c.Height (), src_top=0.5-field) : sclip
	mclip = (mclip_flag)
\	?	mclip.mt_edge (mode="1 2 1 0 0 0 -1 -2 -1 1", thY1=0, thY2=255, u=chroma, v=chroma)
\			.mt_binarize (threshold=maskt, y=3, u=chroma, v=chroma)
\			.mt_expand (y=3, u=chroma, v=chroma)
\	:	Undefined

	c.eedi3 (dh=dh, field=field, threads=threads, vcheck=vcheck, sclip=sclip, mclip=mclip, u=!lumaonly, v=!lumaonly)
	nnrep > 1 ? slimit_dif2(last,sclip,thr=4,u=!lumaonly ? 3 : 2, v=!lumaonly ? 3 : 2) : nnrep > 1 ? Repair(sclip,9,!lumaonly ? 9 : 0) : last
}

Function santiag_sangnom (clip c, bool dh, int field, bool itavs26, int "aa", int "aac", bool "luma", bool "chroma", bool "santiag_sangnom_bug")
{
	c
	w = Width ()
	h = Height ()
	(santiag_sangnom_bug || !itavs26) && (dh) ? Spline36Resize (w, h * 2, 0, -0.25, w, h) : last
	!santiag_sangnom_bug && itavs26 ? SangNom2 (order=field, aa=aa, aac=aac, dh=dh, luma=luma, chroma=chroma) : SangNom2 (order=field, aa=aa, aac=aac)
}

Function santiaguv (clip c, int "strh", int "strv", string "type", int "nns", int "aac", int "threads", int "nsize", int "vcheck", int "fw", int "fh", bool "halfres", string "scaler_post", int "maskt", string "typeh", string "typev", bool "aath", int "nnrep")
{
sisavs26= !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sisyuy2 = c.isyuy2()
c
sislumaonly = sisphbd ? isy() : sisavs26 ? isy8() : false
Assert(!sislumaonly, "santiaguv: use santiag for this clip!" )
	c_y = sisphbd ? ExtractY() : sisavs26 ? converttoy8() : ConvertToYV12 ()
	c_u = sisphbd ? ExtractU() : sisavs26 ? UToY8() : UToY ().ConvertToYV12 ()
	c_v = sisphbd ? ExtractV() : sisavs26 ? VToY8() : VToY ().ConvertToYV12 ()
	c_u = c_u.santiag(strh=strh, strv=strv, type=type, nns=nns, aa=aac, threads=threads, nsize=nsize, vcheck=vcheck, fw=fw, fh=fh, halfres=halfres, scaler_post=scaler_post, maskt=maskt, typeh=typeh, typev=typev, aath=aath, lumaonly=true, nnrep=nnrep)
	c_v = c_v.santiag(strh=strh, strv=strv, type=type, nns=nns, aa=aac, threads=threads, nsize=nsize, vcheck=vcheck, fw=fw, fh=fh, halfres=halfres, scaler_post=scaler_post, maskt=maskt, typeh=typeh, typev=typev, aath=aath, lumaonly=true, nnrep=nnrep)
YToUV (c_u, c_v, c_y)
sisyuy2 && sisavs26 ? ConvertToYUY2() : last
}