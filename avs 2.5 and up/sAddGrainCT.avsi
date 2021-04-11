# AdaptiveGrainFactory and sAddGrainCT

# sAddGrainCT V1.1
# base on Dither_add_grain16 but work with HBD
# soft = noise regen period, in frames (low-pass cutoff period)
# soft >= 100: static noise.
Function sAddGrainCT(clip src, float "var", float "uvar",
\	float "soft", int "maxts", bool "replace", int "seed", bool "AlreadyHalfBlank", int "AlreadyHalfBlankLen", int "AlreadyHalfBlankts_rad", float "AlreadyHalfBlankrate_mul", bool "AlreadyHalfBlankrate_con", int "AlreadyHalfBlankts_fpsn", int "AlreadyHalfBlankts_fpsd")
{
   sisavs26 = !(VersionNumber() < 2.60)
	var     = Default (var,  1.0)
	uvar    = Default (uvar, 0.0)
	replace = Default (replace, false)
	ahblank = Default (AlreadyHalfBlank, false) #don't use these AlreadyHalfBlank things unless you know what are you doing
	soft    = Default (soft, 1.0)
	maxts   = Default (maxts,  5)
	Assert (soft  >= 1.0)
	Assert (maxts >= 0)
	yvar1 = var==0 ? 1 : 3
	uvvar1 = uvar==0 ? 1 : 3
	yvar = var==0 ? 2 : 3
	uvvar = uvar==0 ? 2 : 3
	
	constant = ahblank ? AlreadyHalfBlankrate_con : (soft >= 100)

	ts_rad   = ahblank ? AlreadyHalfBlankts_rad : (constant)   ? 0 : Ceil ((soft - 1) * 0.5)
	ts_rad   = ahblank ? ts_rad : (ts_rad > maxts) ? maxts : ts_rad

	rate_mul = ahblank ? AlreadyHalfBlankrate_mul : (constant)   ? 1 : soft / Float (ts_rad * 2 + 1)
	decim    = (rate_mul < 2.0/3.0) ? 2.0 : 1.0

	amp_comp = pow (ts_rad * 2 + 1, 0.7)

	pa_max = 128.0 / 64
	a_pre  = (amp_comp > pa_max) ? pa_max : amp_comp
	a_post = amp_comp / a_pre
	R_H_M  = sisavs26 ? "x range_half - " : "x 128 - "
	R_H_P  = sisavs26 ? " * range_half +" : " * 128 +" 
	a_str  = R_H_M+String(a_post)+R_H_P

	amp_al   = ts_rad > 0 && a_post != 1.0

	len      = ahblank ? AlreadyHalfBlankLen : src.FrameCount ()
	base_len = Ceil (len / rate_mul) + ts_rad * 2
	ahblank ? src : src.BlankClip (color_yuv=$808080, length=base_len)

	AddGrainC (var=64*a_pre, uvar=64*a_pre, constant=constant, seed=seed)

	(! constant && ts_rad > 0) ? TemporalSoften (ts_rad, 255, 255, mode=2)                 : last
	(! constant && ts_rad > 0) ? Trim (ts_rad, 0)                                          : last
	(! constant &&     amp_al) ? sisavs26 ? mt_lut (expr=a_str, y=!replace ? yvar1 : yvar, u=replace ? uvvar : uvvar1, v=replace ? uvvar : uvvar1, use_expr=2) : mt_lut (expr=a_str, y=!replace ? yvar1 : yvar, u=replace ? uvvar : uvvar1, v=replace ? uvvar : uvvar1) : last

	(! constant &&  decim > 1) ? SelectEven ()                                             : last
	(! constant              ) ? ConvertFPS (FrameRate () * rate_mul * decim)              : last

	AssumeFPS (ahblank ? AlreadyHalfBlankts_fpsn : src.FrameRateNumerator (), ahblank ? AlreadyHalfBlankts_fpsd : src.FrameRateDenominator ())
	Assert (FrameCount () >= len)
	Trim (0, -len)

	grain = sisavs26 ? mt_lut(
\		expr="x range_half - "+String(sqrt(uvar*64)*0.015625)+" * range_half +",
\		yexpr="x range_half - "+String(sqrt(var*64)*0.015625)+" * range_half +",
\		y=!replace ? yvar1 : yvar, u=replace ? uvvar : uvvar1, v=replace ? uvvar : uvvar1, use_expr=2
\	) : mt_lut(
\		expr="x 128 - "+String(sqrt(uvar*64)*0.015625)+" * 128 +",
\		yexpr="x 128 - "+String(sqrt(var*64)*0.015625)+" * 128 +",
\		y=!replace ? yvar1 : yvar, u=replace ? uvvar : uvvar1, v=replace ? uvvar : uvvar1
\	)

	ahblank || replace ? grain : mt_adddiff(src, grain, y=var==0 ? 2 : 3, u=uvar==0 ? 2 : 3, v=uvar==0 ? 2 : 3)
}


# AdaptiveGrainFactory V1.0
# Based on Didée's GrainFactory3 and GrainFactoryLite by 06_taro
function AdaptiveGrainFactory(clip clp,
 \                        float "g1str",   float "g2str",   float "g3str",
 \                        float "g1cstr",  float "g2cstr",  float "g3cstr",
 \                        int   "g1shrp",  int   "g2shrp",  int   "g3shrp",
 \                        float "g1size",  float "g2size",  float "g3size",
 \                        int   "g1tex",   int   "g2tex",   int   "g3tex",
 \                        int   "th1",     int   "th2",     int   "th3",     int "th4",
 \                        float "g1soft",  float "g2soft",  float "g3soft",
 \                        int   "g1maxts", int   "g2maxts", int   "g3maxts",
 \                        float "ontop_grain",
 \                        float "ontop_cgrain",
 \                        float "ontop_soft", int "ontop_maxts",
 \                        bool  "use_sAverageLumaMask")
{
len      = clp.FrameCount ()
fpsn     = clp.FrameRateNumerator ()
fpsd     = clp.FrameRateDenominator ()
ox       = clp.width
oy       = clp.height
sisavs26 = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
fullchr = sisphbd ? clp.is444() : clp.isyv24()
chr420  = sisphbd ? clp.is420() : clp.isyv12()
nochr   = sisphbd ?   clp.isy() : clp.isy8()

dorealm4s = !(fullchr || nochr)
m4v = dorealm4s ? 2 : 0

g1str        = default( g1str,          3 )  # [ 0 - ???] strength of luma grain / for dark areas
g2str        = default( g2str,          5 )  # [ 0 - ???] strength of luma grain / for midtone areas
g3str        = default( g3str,          9 )  # [ 0 - ???] strength of luma grain / for bright areas
g1cstr       = default( g1cstr,         0 )  # [ 0 - ???] strength of chroma grain / for dark areas
g2cstr       = default( g2cstr,         0 )  # [ 0 - ???] strength of chroma grain / for midtone areas
g3cstr       = default( g3cstr,         0 )  # [ 0 - ???] strength of chroma grain / for bright areas
g1shrp       = default( g1shrp,        60 )  # [ 0 - 100] sharpness of grain / for dark areas (NO EFFECT when g1size=1.0 !!)
g2shrp       = default( g2shrp,        66 )  # [ 0 - 100] sharpness of grain / for midtone areas (NO EFFECT when g2size=1.0 !!)
g3shrp       = default( g3shrp,        80 )  # [ 0 - 100] sharpness of grain / for bright areas (NO EFFECT when g3size=1.0 !!)
g1size       = default( g1size,  oy/320.0 )  # [0.5 - 4.0] size of grain / for dark areas
g2size       = default( g2size,  oy/400.0 )  # [0.5 - 4.0] size of grain / for mid-tone areas
g3size       = default( g3size, oy/533.33 )  # [0.5 - 4.0] size of grain / for bright areas
g1tex        = default( g1tex,          0 )  # [ 0 - 100] strength of "material texture" appearance
g2tex        = default( g2tex,          0 )  # [ 0 - 100] (in fact: 'bump' effect)
g3tex        = default( g3tex,          0 )  # [ 0 - 100] for dark / midtone / bright grain
g1soft       = Default( g1soft,       2.0 )
g1maxts      = Default( g1maxts,        3 )
g2soft       = Default( g2soft,       4.0 )
g2maxts      = Default( g2maxts,        5 )
g3soft       = Default( g3soft,       8.0 )
g3maxts      = Default( g3maxts,        7 )
otsoft       = default( ontop_soft,   1.0 )
otmaxts      = Default( ontop_maxts,    5 )
g1const      = (g1soft >= 100)
g2const      = (g2soft >= 100)
g3const      = (g3soft >= 100)
g1tsrad      = g1const ? 0 : Ceil ((g1soft - 1) * 0.5)
g1tsrad      = (g1tsrad > g1maxts) ? g1maxts : g1tsrad
g2tsrad      = g2const ? 0 : Ceil ((g2soft - 1) * 0.5)
g2tsrad      = (g2tsrad > g2maxts) ? g2maxts : g2tsrad
g3tsrad      = g3const ? 0 : Ceil ((g3soft - 1) * 0.5)
g3tsrad      = (g3tsrad > g3maxts) ? g3maxts : g3tsrad
g1rmul       = g1const ? 1 : g1soft / Float (g1tsrad * 2 + 1)
g2rmul       = g2const ? 1 : g2soft / Float (g2tsrad * 2 + 1)
g3rmul       = g3const ? 1 : g3soft / Float (g3tsrad * 2 + 1)
g1base_len   = Ceil (len / g1rmul) + g1tsrad * 2
g2base_len   = Ceil (len / g2rmul) + g2tsrad * 2
g3base_len   = Ceil (len / g3rmul) + g3tsrad * 2
th1          = default( th1,           24 )  # start of dark->midtone  mixing zone
th2          = default( th2,           56 )  # end  of  dark->midtone  mixing zone
th3          = default( th3,          128 )  # start of midtone->bright  mixing zone
th4          = default( th4,          160 )  # end  of  midtone->bright  mixing zone
ontop_grain  = default( ontop_grain,    0 )  # [ 0 - ???] additional luma grain to put on top of prev. generated grain
ontop_cgrain = Default( ontop_cgrain,   0 )  # [ 0 - ???] additional chroma grain to put on top of prev. generated grain
use_ALMask   = default( use_sAverageLumaMask, true)


#-----------------------------------------------------------------------------------

oblr = clp.RemoveGrain(19, -1)
sx1  = m4_sh(ox/float(g1size),m4v)
sy1  = m4_sh(oy/float(g1size),m4v)
sx1a = m4_sh((ox+sx1)/2.0,m4v)
sy1a = m4_sh((oy+sy1)/2.0,m4v)
sx2  = m4_sh(ox/float(g2size),m4v)
sy2  = m4_sh(oy/float(g2size),m4v)
sx2a = m4_sh((ox+sx2)/2.0,m4v)
sy2a = m4_sh((oy+sy2)/2.0,m4v)
sx3  = m4_sh(ox/float(g3size),m4v)
sy3  = m4_sh(oy/float(g3size),m4v)
sx3a = m4_sh((ox+sx3)/2.0,m4v)
sy3a = m4_sh((oy+sy3)/2.0,m4v)

b1   = g1shrp/(-50.0) + 1.0
b2   = g2shrp/(-50.0) + 1.0
b3   = g3shrp/(-50.0) + 1.0
b1a  = b1/2.0
b2a  = b2/2.0
b3a  = b3/2.0
c1   = (1.0-b1)/2.0
c2   = (1.0-b2)/2.0
c3   = (1.0-b3)/2.0
c1a  = (1.0-b1a)/2.0
c2a  = (1.0-b2a)/2.0
c3a  = (1.0-b3a)/2.0
T1a  = string(int(g1tex*1.28))
T1b  = string(128-int(g1tex*1.28))
T2a  = string(int(g2tex*1.28))
T2b  = string(128-int(g2tex*1.28))
T3a  = string(int(g3tex*1.28))
T3b  = string(128-int(g3tex*1.28))
th1str = string(th1)
th2str = string(th2)
th3str = string(th3)
th4str = string(th4)

chroma  = ( g1cstr == 0 ) && ( g2cstr == 0 ) && ( g3cstr == 0 ) ? false : true
ochroma = ( ontop_cgrain != 0 ) || chroma ? true : false

#-----------------------------------------------------------------------------------

BUMPKERNEL1 = T1a + " 0 0 0 " + T1b + " 0 0 0 0 128"
BUMPKERNEL2 = T2a + " 0 0 0 " + T2b + " 0 0 0 0 128"
BUMPKERNEL3 = T3a + " 0 0 0 " + T3b + " 0 0 0 0 128"

#-----------------------------------------------------------------------------------

grainlayer1 = blankclip(clp, width=sx1, height=sy1, color_yuv=$808080, length=g1base_len)
grainlayer1 = (g1str!=0 || g1cstr!=0) ? grainlayer1.sAddGrainCT(g1str, g1cstr, g1soft, g1maxts, AlreadyHalfBlank=true, AlreadyHalfBlankLen=Len, AlreadyHalfBlankts_rad=g1tsrad,AlreadyHalfBlankrate_mul=g1rmul, AlreadyHalfBlankrate_con=g1const, AlreadyHalfBlankts_fpsn=fpsn, AlreadyHalfBlankts_fpsd=fpsd)
\           : grainLayer1

grainlayer1 = (g1tex==0)
\           ? grainlayer1
\           : mt_makediff(grainlayer1,grainlayer1.mt_edge(BUMPKERNEL1, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer1 = (g1size == 1.0 || sx1==ox && sy1==oy) ? grainlayer1
\           : (g1size > 1.5) ? grainlayer1.bicubicresize(sx1a,sy1a, b1a,c1a).bicubicresize(ox,oy, b1a,c1a)
\                            : grainlayer1.bicubicresize(ox,oy, b1,c1)


#-----------------------------------------------------------------------------------

grainlayer2 = blankclip(clp, width=sx2, height=sy2, color_yuv=$808080, length=g2base_len)
grainlayer2 = (g2str!=0 || g2cstr!=0) ? grainlayer2.sAddGrainCT(g2str, g2cstr, g2soft, g2maxts, AlreadyHalfBlank=true, AlreadyHalfBlankLen=Len, AlreadyHalfBlankts_rad=g2tsrad,AlreadyHalfBlankrate_mul=g2rmul, AlreadyHalfBlankrate_con=g2const, AlreadyHalfBlankts_fpsn=fpsn, AlreadyHalfBlankts_fpsd=fpsd)
\           : grainLayer2

grainlayer2 = (g2tex==0)
\           ? grainlayer2
\           : mt_makediff(grainlayer2,grainlayer2.mt_edge(BUMPKERNEL2, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer2 = (g2size==1.0 || sx2==ox && sy2==oy) ? grainlayer2
\           : (g2size > 1.5) ? grainlayer2.bicubicresize(sx2a,sy2a, b2a,c2a).bicubicresize(ox,oy, b2a,c2a)
\                            : grainlayer2.bicubicresize(ox,oy, b2,c2)

#-----------------------------------------------------------------------------------

grainlayer3 = blankclip(clp, width=sx3, height=sy3, color_yuv=$808080, length=g3base_len)
grainlayer3 = (g3str!=0 || g3cstr!=0) ? grainlayer3.sAddGrainCT(g3str, g3cstr, g3soft, g3maxts, AlreadyHalfBlank=true, AlreadyHalfBlankLen=Len, AlreadyHalfBlankts_rad=g3tsrad,AlreadyHalfBlankrate_mul=g3rmul, AlreadyHalfBlankrate_con=g3const, AlreadyHalfBlankts_fpsn=fpsn, AlreadyHalfBlankts_fpsd=fpsd)
\           : grainLayer3

grainlayer3 = (g3tex==0)
\           ? grainlayer3
\           : mt_makediff(grainlayer3,grainlayer3.mt_edge(BUMPKERNEL2, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer3 = (g3size==1.0 || sx3==ox && sy3==oy) ? grainlayer3
\           : (g3size > 1.5) ? grainlayer3.bicubicresize(sx3a,sy3a, b3a,c3a).bicubicresize(ox,oy, b3a,c3a)
\                            : grainlayer3.bicubicresize(ox,oy, b3,c3)

#-----------------------------------------------------------------------------------

grainlayer = grainlayer1.mt_merge(grainlayer2,
 \                                 sisavs26 ? oblr.mt_lut("x "+th1str+" scalef < 0 x "+th2str+" scalef > range_max range_max "+th2str+" scalef "+th1str+" scalef - / x "+th1str+" scalef - * ? ?", use_expr=2) : 
 \											  oblr.mt_lut("x "+th1str+" < 0 x "+th2str+" > 255 255 "+th2str+" "+th1str+" - / x "+th1str+" - * ? ?", U=1, V=1),
 \                                 luma=chroma,
 \                                 U=chroma?3:1, V=chroma?3:1)
 \                      .mt_merge(grainlayer3,
 \                                 luma=chroma,
 \                                 sisavs26 ? oblr.mt_lut("x "+th3str+" scalef < 0 x "+th4str+" scalef > range_max range_max "+th4str+" scalef "+th3str+" scalef - / x "+th3str+" scalef - * ? ?", use_expr=2) : 
 \											  oblr.mt_lut("x "+th3str+" < 0 x "+th4str+" > 255 255 "+th4str+" "+th3str+" - / x "+th3str+" - * ? ?", U=1, V=1),
 \                                 U=chroma?3:1, V=chroma?3:1)

grainlayer = (  ontop_grain!=0  ||  ontop_cgrain!=0  ) ? grainlayer.sAddGrainCT(ontop_grain, ontop_cgrain, otsoft, otmaxts)
\          : grainLayer

#-----------------------------------------------------------------------------------

result = clp.mt_makediff(grainlayer, U=ochroma?3:2, V=ochroma?3:2)
result = use_ALMask ? mt_merge(result,clp,clp.sAverageLumaMask,luma=chroma, U=ochroma?3:2, V=ochroma?3:2) : result

return( result ) }
