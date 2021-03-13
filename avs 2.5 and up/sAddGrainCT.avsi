# base on Dither_add_grain16 but work with HBD
# soft = noise regen period, in frames (low-pass cutoff period)
# soft >= 100: static noise.
Function sAddGrainCT(clip src, float "var", float "uvar",
\	float "soft", int "maxts", bool "replace", int "seed")
{
   sisavs26 = !(VersionNumber() < 2.60)
	var     = Default (var,  1.0)
	uvar    = Default (uvar, 0.0)
	replace = Default (replace, false)
	soft    = Default (soft, 1.0)
	maxts   = Default (maxts,  5)
	Assert (soft  >= 1.0)
	Assert (maxts >= 0)
	
	constant = (soft >= 100)

	ts_rad   = (constant)   ? 0 : Ceil ((soft - 1) * 0.5)
	ts_rad   = (ts_rad > maxts) ? maxts : ts_rad

	rate_mul = (constant)   ? 1 : soft / Float (ts_rad * 2 + 1)
	decim    = (rate_mul < 2.0/3.0) ? 2.0 : 1.0

	amp_comp = pow (ts_rad * 2 + 1, 0.7)

	pa_max = 128.0 / 64
	a_pre  = (amp_comp > pa_max) ? pa_max : amp_comp
	a_post = amp_comp / a_pre
	R_H_M  = sisavs26 ? "x range_half - " : "x 128 - "
	R_H_P  = sisavs26 ? " * range_half +" : " * 128 +" 
	a_str  = R_H_M+String(a_post)+R_H_P

	amp_al   = ts_rad > 0 && a_post != 1.0

	len      = src.FrameCount ()
	base_len = Ceil (len / rate_mul) + ts_rad * 2
	src.BlankClip (color_yuv=$808080, length=base_len)

	AddGrainC (var=64*a_pre, uvar=64*a_pre, constant=constant, seed=seed)

	(! constant && ts_rad > 0) ? TemporalSoften (ts_rad, 255, 255, mode=2)                 : last
	(! constant && ts_rad > 0) ? Trim (ts_rad, 0)                                          : last
	(! constant &&     amp_al) ? sisavs26 ? mt_lut (yexpr=a_str, y=3, u=3, v=3, use_expr=2) : mt_lut (yexpr=a_str, y=3, u=3, v=3) : last

	(! constant &&  decim > 1) ? SelectEven ()                                             : last
	(! constant              ) ? ConvertFPS (FrameRate () * rate_mul * decim)              : last

	AssumeFPS (src.FrameRateNumerator (), src.FrameRateDenominator ())
	Assert (FrameCount () >= len)
	Trim (0, -len)

	grain = sisavs26 ? mt_lut(
\		expr="x range_half - "+String(sqrt(uvar*64)*0.015625)+" * range_half +",
\		yexpr="x range_half - "+String(sqrt(var*64)*0.015625)+" * range_half +",
\		y=3, u=3, v=3, use_expr=2
\	) : mt_lut(
\		expr="x 128 - "+String(sqrt(uvar*64)*0.015625)+" * 128 +",
\		yexpr="x 128 - "+String(sqrt(var*64)*0.015625)+" * 128 +",
\		y=3, u=3, v=3
\	)

	replace ? grain : mt_adddiff(src, grain)
}