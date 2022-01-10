
/*
==============================================================================

        crt_display
        v1.0
        Author: Firesledge
        update to avs+ PlanarRGB HBD

Simulates a CRT display using aperture grille (Trinitron) or Cromaclear
technologies.

Useful to upscale low-resolution sources. It generates one scanline per
source line.

Default parameters are generally ok, try to set blurh if the result is too
rough or has a tint.

Warning: this function is slow, eats gigantic resources and is long to
initialize.

Requirements:
- Avisynth+ 2294 or better
- RGB input. Alpha channel is discarded.

Parameters:

sw
	Horizontal scale factor.

sh
	Vertical scale factor.

voff
	Vertical centering of the scanlines.
	Set to 0, the scanlines are centered between two pixels. When set to
	0.5, the scanline are centered exactly on a pixel. Default is pixel-
	centered.
	This is a sensitive setting when the scale factor is a small integer.
	When sh = 3, it's recommended to set the value closer to 0 to make
	centered the dark gap between the scanlines.

ppp
	Number of phosphor triads per source pixel.
	It is recommended to select a value that makes the phosphors aligned
	with destination pixels (for example 1 phosphor triad = 2 dest pix),
	in order to avoid moire patterns and beating.

cutoff
	Cutoff frequency of the low-pass filter at the electronic level.
	Lowering it thinners 1-pixel wide details.
	Good values are between 0.8 and 1. Effect is disabled at 1.0.

scandist
	Relative distance between two scanlines.

sharpv
	Vertical sharpness of the scanlines.
	High sharpness makes the lines look thinner especially at low
	luminance and may reduce the overall contrast.
	Low sharpness thickens the lines and make them slightly blend.
	Use values between 0.5 and 2.0.

sharph
	Horizontal beam focus.
	Use values between 0.5 and 2.0.

blurh
	Amount of horizontal bluring to apply after the final resizing.
	Requires phosphor to be set. Set it to 0 to disable bluring.
	Sometimes with medium scale factors, when the individual phosphors
	have a size close to a single destination pixel, the display becomes
	incredibly messy. Blurring in the horizontal direction make the
	neighbour phophors slightly merge and reduce the gird artefacts.
	Moreover, it alows to amplify more the contrast with reduced
	color artefacts.
	Usually, values in range 1.0-2.0 give good results.
	The sweet spot can be very narrow, don't hesitate to try steps
	as small as 0.1. It's also very dependent from other settings,
	adjust it after other parameters have changed.

glowgain
	Amount of glow left by the beam.
	Disabled when set to 0.

glowh
	Width of the beam glow, in phosphor triads.

glowv
	Height in scanlines of the beam glow.

glowsens
	Glow sensitivity to light.
	With 1 the glow is uniform. Greater values will leave the dark spots
	intact and only make the bright spots glow.

contrast
	Manual contrast amplification. The neutral value is 1.
	The value of 3 is generally good when the scaling factor is not high
	and the individual phosphors overlap. Use a slightly greater value
	when cromaclear is enable (should be 4).
	Contrast loss caused by thin scanlines or large phosphors is hard to
	recover.
	When unspecified, the contrast is set as high as possible depending
	on the other parameters.

gamma
	Gamma of the emulated monitor. Typically 2.4 to 2.8 for CRT monitors.
	Default is the sRGB gamma (2.2).

softclip
	Gently saturates the pixel values.
	Generally in range 0-1. Slightly reduces the overall contrast when
	pixel values are not clipping.
	Set to 0 for hard-clipping.

mix
	Amount of CRT-emulated picture in the result. Does not bypass the
	gamma processing.

beamshape
	Another way to sharpen the scanlines. The higher the value, the
	thinner the beam. Use values between 1 and 3. This gives control on
	the thickness of the beam at high luminance.

phosphor
	Enable phosphor processing.

pgrid
	Enables the black grid enclosing each phosphor, at the price of a
	higher calculation cost. Useful only for large scale factors, when
	individual phosphors are clearly visible.
	Requires phosphor processing.

vcs
	Vertical color shift in scanline units, misaligning the red and blue
	beams.
	Realistic values are between -0.25 and +0.25. When set to 0, the beams
	are correctly aligned.

cromaclear
	Implements the NEC's cromaclear variant of the aperture grille,
	combining it with a shadow mask. The value gives the amount of
	horizontal black grid to be mixed.
	May reduce the contrast.

maskpp
	Number of cromaclear units per scanline. Same as ppp but vertically.

gainb
	Manual contrast gain for the blue.
	For some reasons, the phosphor mix may generate a yellow tint in the
	high luminance ranges, depending on various parameters.
	Values ranging from 1.05 to 1.2 are generally enough to fix it without
	creating excessive blue tint in the darker colors.
	Use a test pattern to adjust the value.

halgain
	Amount of halation.
	Keep it to a low value, typically in range 0.01-0.05.
	Disable it with 0.

halrange
	Halation radius, in phosphor triad units.

pixel_type
	Final RGB format. "RGB24" or "RGB32".

==============================================================================
*/

Function crt_display (clip src, float sw, float sh, float "voff", float "ppp",
\	float "cutoff", float "scandist", float "sharpv", float "sharph",
\	float "blurh", float "glowgain", float "glowh", float "glowv",
\	float "glowsens", float "contrast", float "gamma", float "softclip",
\	float "mix", float "beamshape", bool "phosphor", bool "pgrid",
\	float "vcs", float "cromaclear", float "maskpp", float "gainb",
\	float "halgain", float "halrange", string "pixel_type")
{
	Assert (IsRGB (src), "Scrt_display: src must be RGB.")
	Assert (src.BitsPerComponent() > 8, "Scrt_display: more than 8bit only")
	
	voff       = Default (voff, (sh == 3) ? 0.25 : 0.5)
	ppp        = Default (ppp, Max (Min (sw * 0.5, 2.5), 1.0))
	maskpp     = Default (maskpp,    ppp)
	cutoff     = Default (cutoff,      1)
	scandist   = Default (scandist,    1)
	sharpv     = Default (sharpv,      1)
	sharph     = Default (sharph,      1)
	blurh      = Default (blurh, (Abs ((sw / ppp) - Round (sw / ppp)) < 0.0001) ? 0 : 1.5)
	glowgain   = Default (glowgain,    0)
	glowh      = Default (glowh,       4)
	glowv      = Default (glowv,       1)
	glowsens   = Default (glowsens,    2)
	gamma      = Default (gamma,     2.2)
	softclip   = Default (softclip,    0)
	mix        = Default (mix,         1)
	beamshape  = Default (beamshape, 1.0)
	phosphor   = Default (phosphor, (sw >= 1.5))
	pgrid      = Default (pgrid, (sw > ppp * 3 * 2))
	vcs        = Default (vcs,         0)
	cromaclear = Default (cromaclear,  0)
	gainb      = Default (gainb,     1.0)
	halgain    = Default (halgain,     0)
	halrange   = Default (halrange,  6.0)

	g_thickness = (pgrid) ? 1 : 0	# 0 or 1	# Horizontal thickness of the phosphor grid, in oversampled pixels
	ccl_thickness = 0.25	# Vertical thickness of the Cromaclear grid, relative to the grid height
	ssx = (g_thickness > 0 && phosphor) ? 12 : 3	# Horizontal oversampling. Multiple of 3, >= 3*(g_thickness+1)
	maxrad = 3	# You must add code for z4-zN if you want to increase this
	ssy = Min (Int (Round (scandist * (maxrad*2+1))), maxrad*4+1)	# Vertical oversampling, internal lines per scanline, >= maxrad*2+1
	err_div = scandist * 7 / ssy
	rad = Int (Round (((maxrad*2+1) / err_div - 1) * 0.5))	# Maximum radius of the beam, [0 ; maxrad], 2*rad+1 <= ssy

	# Calculations for the contrast correction. Horribly complicated.

	inv_area_ratio = Float (ssx) / Float (ssx/3 - g_thickness)	# Inverse of: area of one color relative to the phosphore tile
	cont_def_h_lim = Max ((inv_area_ratio * ppp / sw) * 2.5, 1.0)	# Phosphor overlapping in destination pixels, * 2.5 for the saturation spread
	cont_def_blurh_room = Max (blurh / 1.25, 1.0)
	cont_def_hgrid = Min (inv_area_ratio, cont_def_h_lim * cont_def_blurh_room)
	cont_def_hgrid = (phosphor) ? cont_def_hgrid : 1.0

	ccl_pix_tot_m  = Max (sh / maskpp, 1.0)
	ccl_pix_black  = ccl_thickness * ccl_pix_tot_m
	ccl_cont_1pix  = Max (1.0 / (1 + Floor (ccl_pix_black) - ccl_pix_black), 1.0)
	cont_def_v_lim = ccl_pix_tot_m / (1 / ccl_cont_1pix + ccl_pix_tot_m - 1)
	cont_def_vgrid = 1.0 / (1 - ccl_thickness * cromaclear)
	cont_def_vgrid = (cromaclear > 0) ? Min (cont_def_vgrid, cont_def_v_lim) : 1.0

	cont_def       = cont_def_hgrid * cont_def_vgrid
	contrast       = Default (contrast, cont_def)

	# Processing

	src
	w  = Width ()
	h  = Height ()
	r  = ExtractR()
	g  = ExtractG()
	b  = ExtractB()
	Interleave (r, g, b)

	# Low-pass filtering from the display electronics
	# Oversamples the picture horizontally
	ssw = Int (Round (w * ssx * ppp))
	(cutoff < 1) ? fmtc_resample (ssw, h, kernel="bicubic", fh=-cutoff*1.5) : last

	# Converts the pixel values to linear light.
	y_gamma_to_linear (tv_range_in=false, tv_range_out=false, curve="sRGB", gcor=gamma/2.2)

	orig = last

	# Sets the beam sharpness
	# Oversamples the picture horizontally if it's not already done
	fmtc_resample (ssw, h, kernel="gauss", a1=100, fh=-sharph)

	# Oversamples the picture vertically to show a beam with variable width.
	# The beam won't fill all the line height, it will be smoothed and
	# completed later by a vertical gaussian blur.
	# The beam is centered at y = floor (ssy / 7)
	ssh  = ssy * h
	contrast_fix_ssy = Float (ssy)
	part = 1.0 / (rad * 2 + 1)
	p1 = Int (Pow (part * 1, 1.0 / beamshape) * 65536)	# A single unit
	p2 = Int (Pow (part * 3, 1.0 / beamshape) * 65536)	# In steps of 2 units because we mirror these lines
	p3 = Int (Pow (part * 5, 1.0 / beamshape) * 65536)
	zb = mt_lut (y=0)
	z0 = (rad > 0) ? spread_range (0 , p1   , 1.0) : last
	z1 = (rad > 0) ? spread_range (p1, p2   , 0.5) : zb
	z2 = (rad > 1) ? spread_range (p2, p3   , 0.5) : zb
	z3 = (rad > 2) ? spread_range (p3, 65536, 0.5) : zb
	zb1_cnt = (ssy - 7) / 2
	zb0_cnt = ssy - 7 - zb1_cnt
	zb0_str = (zb0_cnt > 0) ? FillStr (zb0_cnt, "zb, ") : ""
	zb1_str = (zb1_cnt > 0) ? FillStr (zb1_cnt, ", zb") : ""
	Eval ("Interleave (" + zb0_str + "z3, z2, z1, z0, z1, z2, z3" + zb1_str + ")")
	WeaveRows (ssy)

	# Now vertically misaligns each color component
	r = SelectEvery (3, 0)
	g = SelectEvery (3, 1)
	b = SelectEvery (3, 2)
	r = (vcs != 0) ? r.shift_vertical16 (+vcs * ssy) : r
	b = (vcs != 0) ? b.shift_vertical16 (-vcs * ssy) : b
	Interleave (r, g, b)

	# Applies a vertical gaussian blur to smooth and expand the beam
	vblur = Float (sharpv * scandist) / (ssy - rad)
	(vblur < 1) ? fmtc_resample (ssw, ssh, fv=-vblur, center=false, cnorm=true, kernel="gauss", taps=ssy*3/4, a1=80.0) : last

	# It's better to fix the contrast at this point to avoid losing
	# precision in the next steps. But don't fix it completely because
	# there is a risk of saturation. We'll finish later, after the
	# vertical downsampling.
	contrast_fix_1 = sqrt (contrast_fix_ssy)
	expr ("i16 x " + String (contrast_fix_1) + " *", scale_inputs="allf")
	contrast_fix_ssy = contrast_fix_ssy / contrast_fix_1

	# Adds a glow.
	# Works by remapping the pixel values (high luma emphasis), blurring
	# the modified picture, extracting the blur part only, then applying
	# this blur to the original picture.
	glowflag = (glowgain > 0 && (glowh > 0 || glowv > 0))
	glow_fh  = (glowh > 0) ? -1.0 / (glowh * ssx / ppp) : undefined ()
	glow_fv  = (glowv > 0) ? -1.0 / (glowv * ssy      ) : undefined ()
	c_glo0 = (glowflag) ? expr ("i16 x " + String(contrast_fix_ssy/65536.0) + " * "
\	                                    + String (glowsens) + " ^ "
\	                                    + String(65536.0/contrast_fix_ssy) + " *", scale_inputs="allf") : last
	c_glow = (glowflag) ? c_glo0.fmtc_resample (ssw, ssh, kernel="gauss", fh=glow_fh, fv=glow_fv, center=false, a1=70.0) : last
	c_glow = (glowflag) ? c_glow.ex_makediff (c_glo0, dif=false, uv=3) : c_glow
	c_glow = (glowflag) ? c_glow.expr ("i16 x " + String (glowgain) + " *", scale_inputs="allf") : c_glow
	(glowflag) ? ex_adddiff (c_glow, dif=false, uv=3) : last

	# Phosphor processing. Applies a mask to put each color component on
	# its own phosphor column.
	r = SelectEvery (3, 0)
	g = SelectEvery (3, 1)
	b = SelectEvery (3, 2)
	r = (phosphor) ? r.insert_black_col16 (ssx,           0, ssx / 3 - g_thickness) : r
	g = (phosphor) ? g.insert_black_col16 (ssx,     ssx / 3, ssx / 3 - g_thickness) : g
	b = (phosphor) ? b.insert_black_col16 (ssx, 2 * ssx / 3, ssx / 3 - g_thickness) : b
	Interleave (r, g, b)

	# Adds the cromaclear shadow mask (horizontal)
	ccl_h = Float (ssy) / maskpp
	ccl_t = ccl_h * ccl_thickness
	(cromaclear > 0) ? shadowmask_cromaclear (ssx, ccl_h, (ccl_h / 4.0), ccl_t, cromaclear) : last

	# Next steps will be easier with all the components packed in 4:4:4
	YToUV (SelectEvery (3, 1), SelectEvery (3, 2), SelectEvery (3, 0))

	# Rescales the picture to the target resolution
	dw = Int (w * sw)
	dh = Int (Height () * sh / Float (ssy))
	src_left = (phosphor && sw >= ssx) ? 0.25 : 0	# With an integer scaling ratio, this helps to obtain a nice grid pattern with all the color components. This value may affect the color of the tint at low blurh.
	center_dst = sh * 0.5 + voff	# center_src = ssy / 2 + 0.5
	center_fix = Float (Round (center_dst))
	src_top = (center_fix - center_dst) * ssy / sh	# With an integer scaling ratio, ensures that the center of the scanline is located exactly on a pixel line, not between lines (when voff = 0.5).
	blurh_freq = sw / (blurh * ssx * ppp)
	(blurh > 0) ? fmtc_resample (ssw, ssh, kernel="gauss", fh=-blurh_freq, a1=70) : last	# Could be done at the final resolution to save computation, but this would help less to fight moire & color tint because of the spline36 aliasing.
	fmtc_resample (dw, dh, sx=src_left, sy=src_top, kernel="spline36")

	# Final contrast correction
	# Saturated components are spread on the neighbour pixels to make
	# possible to get full-brightness white even when the phosphors are
	# visible while minimizing errors on chroma/hue.
	contr_all   = contrast * contrast_fix_ssy
	contr_all_b = contr_all * gainb
	cexpr  = "x " + String (contr_all  ) + " * "
	cvexpr = "x " + String (contr_all_b) + " * "
	cexprsat  = gen_expr_softclip (cexpr , softclip)
	cvexprsat = gen_expr_softclip (cvexpr, softclip)
	satres = expr ("i16 " + cexpr + cexprsat + " -", "i16 " + cvexpr + cvexprsat + " -", "i16 " + cvexpr + cvexprsat + " -", scale_inputs="allf")
	expr ("i16 " + cexprsat, "i16 " + cvexprsat, "i16 " + cvexprsat, scale_inputs="allf")
	spread_residual (last, satres, 2)

	# Halation
	hal_rad = Int (Round (halrange * sqrt (sw * sh / (ppp * maskpp))))
	c_hal = (halgain > 0) ?  last.ex_boxblur (radius=hal_rad-1,mode="mean", uv=3) : last	# Cheap but fast gaussian blur with large radius
	c_hal = (halgain > 0) ? c_hal.ex_boxblur (radius=hal_rad-1,mode="mean", uv=3) : c_hal
	c_hal = (halgain > 0) ? c_hal.ex_boxblur (radius=hal_rad-1,mode="mean", uv=3) : c_hal
	(halgain > 0) ? ex_adddiff (c_hal.expr ("i16 x " + String (halgain) + " *", scale_inputs="allf"), dif=false, uv=3) : last

	# Mix the CRT emulation with the unprocessed picture
	orig = (mix != 1) ? YToUV (orig.SelectEvery (3, 1), orig.SelectEvery (3, 2), orig.SelectEvery (3, 0)) : last
	orig = (mix != 1) ? orig.smooth_pointresize16 (dw, dh) : orig
	(mix == 0) ? orig : (mix == 1) ? last : ex_adddiff (
\		last.expr ("i16 x " + String (    mix) + " *", scale_inputs="allf"),
\		orig.expr ("i16 x " + String (1 - mix) + " *", scale_inputs="allf"), dif=false,
\		y=3, uv=3
\	)

	# Back to the sRGB colorspace
	y_linear_to_gamma (tv_range_in=false, tv_range_out=false, curve="sRGB", u=3, v=3)
	r = ExtractY()
	g = ExtractU()
	b = ExtractV()

	MergeRGB (r, g, b, pixel_type=pixel_type)

}



# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
# Support functions

# Lower bound included, upper bound excluded
Function spread_range (clip src, int lo, int up, float scale)
{
	src
	expr (  "i16 x " + String (lo) + " " + String (up - 1) + " clip "
\	              + String (lo) + " - " + String (scale) + " *", scale_inputs="allf")
}

Function shift_vertical16 (clip src, float ofs)
{
	src
	w = Width ()
	h = Height ()
	(Abs (ofs - Round (ofs)) < 0.1)
\	?	src.PointResize (w, h, src_top=-Int (Round (ofs)))
\	:	src.sigmoid_inverse ()
\		   .fmtc_resample (w, h, sy=-ofs, kernel="spline36")
\		   .sigmoid_direct ()
}

Function insert_black_col16 (clip src, int nbr, int ofs, int w)
{
	src
	dw = Width ()
	dh = Height ()

# Tiling the mt_lutspa speeds up a bit the filter initialisation.
#	msk = last.mt_lutspa (mode="absolute", expr="x "+String(nbr)+" % "+String(ofs)+" >=   x "+String(nbr)+" % "+String(ofs+w)+" <   &  255 0 ?")

	msk = last.Crop (0, 0, 0, 32)
	msk = msk.mt_lutspa (mode="absolute", expr="x "+String(nbr)+" % "+String(ofs)+" >=   x "+String(nbr)+" % "+String(ofs+w)+" <   &  255 0 ? scalef", scale_inputs="intf")
	msk = msk.make_tile (dw, dh)
# end tiling

	ex_logic (last, msk, mode="and")
}

# Doesn't look very good, but works.
Function shadowmask_cromaclear (clip src, int ssx, float ssy, float ofs, float thick, float cromaclear)
{
	src
	sc_t = (thick < 1) ? 1.0 / thick : Round (thick) / thick
	ssy2 = Int (Round (ssy * sc_t))
	Assert (ssy2 >= 2)
	scale = Float (ssy2) / ssy
	ofs2 = Int (Round (ofs * scale))
	w = Width ()
	h = Height ()
	h2 = Round(h*scale)
	dist = "y " + String(ssy2-ofs2) + " + " + String(ssy2) + " %   x " + String(ssx) + " / floor 2 % " + String(ssy2/2) + " *   -"
	expr = dist + " 0 >= " + dist + " " + String(Int(Round(thick*scale))) + " < &  " + String(Int(Round(cromaclear*255))) + " 0 ?"

# Tiling the mt_lutspa speeds up a bit the filter initialisation.
#	msk = msk.BlankClip (height=h2)
#	msk = msk.mt_lutspa (mode="absolute", expr=expr)

	msk = src.BlankClip (width=ssx*2, height=ssy2)
	msk = msk.mt_lutspa (mode="absolute", expr=expr + " scalef",scale_inputs="intf")
	msk = msk.make_tile (w, h2)
# end tiling

	msk = msk.BicubicResize (w, h)

	mt_merge (last, last.mt_lut (y=0), msk, u=1, v=1)
}

Function make_tile (clip src, int w, int h)
{
	src
	tw = Width ()
	th = Height ()
	make_tile_internal ((w + tw - 1) / tw, (h + th - 1) / th)
	Crop (0, 0, w, h)
}

Function make_tile_internal (clip src, int nx, int ny)
{
	src
	(nx > 1) ? StackHorizontal (make_tile_internal (nx / 2, 1), make_tile_internal (nx - nx / 2, 1)) : last
	(ny > 1) ? StackVertical (make_tile_internal (1, ny / 2), make_tile_internal (1, ny - ny / 2)) : last
}

Function gen_expr_softclip (string x, float softclip)
{
	# tanh (x) = 1 - 2 / (exp (x * 2) + 1)
	expr = (softclip > 0) ? " 1 2 " + x + " 65536 / "
\		+ String (1.0 / softclip) + " ^ 2 * exp 1 + / - "
\		+ String (softclip) + " ^ 65536 * " : x + " 65536 min "

	return (expr)
}

# Spreads the saturated energy to the neighbour pixels.
# This is not optimal but pretty helpful anyway.
# Two passes are enough.
Function spread_residual (clip src, clip residual, int count)
{
	residual = residual.removegrain (20)
	avail    = src.expr ("i16 65535 x -", scale_inputs="allf")
	src.ex_adddiff (residual, dif=false, y=3, uv=3)
	residual = residual.ex_makediff (avail, dif=false, y=3, uv=3)
	(count > 1) ? last.spread_residual (residual, count - 1) : last
}

# PointResize with non-integer scale factors
Function smooth_pointresize16 (clip src, int dw, int dh)
{
	src
	w  = Width ()
	h  = Height ()
	rx = Max (dw / w, 1)
	ry = Max (dh / h, 1)
	(w > 1 || h > 1) ? PointResize (w * rx, h * ry) : last
	fmtc_resamplenr (dw, dh, kernel="bicubic", a1=0.5, a2=0.25)
}

