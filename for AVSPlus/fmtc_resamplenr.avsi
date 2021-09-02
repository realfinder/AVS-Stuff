# base on Dither_resize16nr
Function fmtc_resamplenr (clip src, int w, int h,
\	val "sx",
\	val "sy",
\	val "sw",
\	val "sh",
\	float "scale",
\	float "scaleh",
\	float "scalev",
\	string "kernel",
\	string "kernelh",
\	string "kernelv",
\	val "impulse",
\	val "impulseh",
\	val "impulsev",
\	val "taps",
\	val "tapsh",
\	val "tapsv",
\	val "a1",
\	val "a2",
\	val "a3",
\	val "a1h",
\	val "a2h",
\	val "a3h",
\	val "a1v",
\	val "a2v",
\	val "a3v",
\	int    "kovrspl",
\	val "fh",
\	val "fv",
\	bool   "cnorm",
\	val "totah",
\	val "totalh",
\	val "totalv",
\	val "invks",
\	val "invksh",
\	val "invksv",
\	val "invkstaps",
\	val "invkstapsh",
\	val "invkstapsv",
\	string "csp",
\	string "css",
\	int    "y",
\	int    "u",
\	int    "v",
\	int "fulls",
\	int "fulld",
\	val "center",
\	string "cplace",
\	string "cplaces",
\	string "cplaced",
\	int "interlaced",
\	int "interlacedd",
\	int "tff",
\	int "tffd",
\	bool "flt",
\	int "cpuopt",
\	bool   "noring")
{
	noring = Default (noring, true)

	Assert (w > 0 && h > 0, "Dither_resize16nr: width and height must be > 0.")

	sr_h  = Float (w) / Float (src.width  ())
	sr_v  = Float (h) / Float (src.height ())
	sr_up =       max (sr_h, sr_v)
	sr_dw = 1.0 / min (sr_h, sr_v)
	sr    = max (sr_up, sr_dw)
	Assert (sr >= 1.0)

	# Depending on the scale ratio, we may blend or totally disable
	# the ringing cancellation
	thr = 2.5
	nrb = (sr > thr)
	nrf = (sr < thr + 1.0 && noring)
	nrr = (nrb) ? min (sr - thr, 1.0) : 1.0
	nrv = (nrb) ? Round ((1.0 - nrr) * 255) * $010101 : 0
	y   = Default (y, 3)
	u   = Default (u, 3)
	v   = Default (v, 3)
	sisrgb = isrgb(src)
	y   = sisrgb ? 3 : y
	u   = sisrgb ? 3 : u
	v   = sisrgb ? 3 : v
	planes = string(y) + ", " + string(u) + ", " + string(v)

	main = src.fmtc_resample (w, h,
\		sx          =sx,
\		sy          =sy,
\		sw          =sw,
\		sh          =sh,
\		scale       =scale,
\		scaleh      =scaleh,
\		scalev      =scalev,
\		kernel      =kernel,
\		kernelh     =kernelh,
\		kernelv     =kernelv,
\		impulse     =impulse,
\		impulseh    =impulseh,
\		impulsev    =impulsev,
\		taps        =taps,
\		tapsh       =tapsh,
\		tapsv       =tapsv,
\		a1          =a1,
\		a2          =a2,
\		a3          =a3,
\		a1h         =a1h,
\		a2h         =a2h,
\		a3h         =a3h,
\		a1v         =a1v,
\		a2v         =a2v,
\		a3v         =a3v,
\		kovrspl     =kovrspl,
\		fh          =fh,
\		fv          =fv,
\		cnorm       =cnorm,
\		total       =total,
\		totalh      =totalh,
\		totalv      =totalv,
\		invks       =invks,
\		invksh      =invksh,
\		invksv      =invksv,
\		invkstaps   =invkstaps,
\		invkstapsh  =invkstapsh,
\		invkstapsh  =invkstapsh,
\		csp         =csp,
\		css         =css,
\		planes      =planes,
\		fulls       =fulls,
\		fulld       =fulld,
\		center      =center,
\		cplace      =cplace,
\		cplaces     =cplaces,
\		cplaced     =cplaced,
\		interlaced  =interlaced,
\		interlacedd =interlacedd,
\		tff         =tff,
\		tffd        =tffd,
\		flt         =flt,
\		cpuopt      =cpuopt
\	)

	nrng = (nrf) ? src.fmtc_resample (w, h,
\		sx          =sx,
\		sy          =sy,
\		sw          =sw,
\		sh          =sh,
\		scale       =scale,
\		scaleh      =scaleh,
\		scalev      =scalev,
\		kernel      ="gauss",
\		kernelh     ="gauss",
\		kernelv     ="gauss",
\		impulse     =impulse,
\		impulseh    =impulseh,
\		impulsev    =impulsev,
\		taps        =taps,
\		tapsh       =tapsh,
\		tapsv       =tapsv,
\		a1          =100,
\		a2          =a2,
\		a3          =a3,
\		a1h         =100,
\		a2h         =a2h,
\		a3h         =a3h,
\		a1v         =100,
\		a2v         =a2v,
\		a3v         =a3v,
\		kovrspl     =kovrspl,
\		fh          =fh,
\		fv          =fv,
\		cnorm       =cnorm,
\		total       =total,
\		totalh      =totalh,
\		totalv      =totalv,
\		invks       =invks,
\		invksh      =invksh,
\		invksv      =invksv,
\		invkstaps   =invkstaps,
\		invkstapsh  =invkstapsh,
\		invkstapsh  =invkstapsh,
\		csp         =csp,
\		css         =css,
\		planes      =planes,
\		fulls       =fulls,
\		fulld       =fulld,
\		center      =center,
\		cplace      =cplace,
\		cplaces     =cplaces,
\		cplaced     =cplaced,
\		interlaced  =interlaced,
\		interlacedd =interlacedd,
\		tff         =tff,
\		tffd        =tffd,
\		flt         =flt,
\		cpuopt      =cpuopt
\	) : main

	nrm = (nrb && nrf) ? main.BlankClip (color_yuv=nrv) : main

	# To do: use a simple frame blending instead of Dither_merge16
	rgm = 1
	rgc = (nrb) ? -1 : 0
	rgy = Defined (y) ? ((y == 3) ? rgm : rgc) : rgm
	rgu = Defined (u) ? ((u == 3) ? rgm : rgc) : rgm
	rgv = Defined (v) ? ((v == 3) ? rgm : rgc) : rgm
	rguv = max (rgu, rgv)
	(nrf       ) ? main.repair(nrng, rgy, rguv)              : main
	(nrf && nrb) ? mt_merge (main, last, nrm, y=y, u=u, v=v) : last
}