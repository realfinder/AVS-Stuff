# Small and relatively fast realtime-sharpening function, 
# for 1080p, or after scaling 720p -> 1080p during playback (to make 720p look more like being 1080p)
# It's a generic sharpener. Only for good quality sources! 
# (If the source is crap, FineSharp will happily sharpen the crap.) ;)
# Noise/grain will be enhanced, too. The method is GENERIC.
#
# Modus operandi: A basic nonlinear sharpening method is performed, then the *blurred* sharp-difference gets subtracted again. 
#
# - Didée
# mod 2020.04.12 HBD

function FineSharp(clip c, int "mode", float "sstr", float "cstr", float "xstr", float "lstr", float "pstr", float "ldmp")
{

sisavs26=!(VersionNumber() < 2.6)
 
mode  = default(mode, 1   )   #  1 to 3, weakest to strongest. When negative -1 to -3, a broader kernel for equalisation is used.
sstr  = default(sstr, 2.0 )   #  strength of sharpening, 0.0 up to ??
 
_cstr = spline(sstr, 0,0, 0.5,0.1, 1.0,0.6, 2.0,0.9, 2.5,1.00, 3.0,1.09, 3.5,1.15, 4.0,1.19, 8.0,1.249, 255.0,1.5)
_cstr = (mode>0) ? _cstr : pow(_cstr,1./1.25)

cstr  = default(cstr, _cstr)  #  strength of equalisation, 0.0 to ? 2.0 ? (recomm. 0.5 to 1.25, default AUTO)
xstr  = default(xstr, 0.19 )  #  strength of XSharpen-style final sharpening, 0.0 to 1.0 (but, better don't go beyond 0.249 ...)

                             #  Viscera parameters
lstr  = default(lstr, 1.49 )  #  modifier for non-linear sharpening
pstr  = default(pstr, 1.272)  #  exponent for non-linear sharpening
ldmp  = default(ldmp, sstr+0.1) # "low damp", to not overenhance very small differences (noise coming out of flat areas)

str1  = sstr
str2  = cstr
SSTR  = string(sstr)
CSTR  = string(cstr)
LSTR  = string(lstr)
PSTR  = string(pstr)
LDMP  = string(ldmp)
rg=mode>0?11:20
 
b = (abs(mode)==1) ? c.removegrain(11,-1).removegrain(4,-1)
\ : (abs(mode)==2) ? c.removegrain(4,-1).removegrain(11,-1)
\ : (abs(mode)==3) ? c.removegrain(4,-1).removegrain(11,-1).removegrain(4,-1) : c
 
shrpD = sisavs26 ? mt_lutxy(c,b,"x y - abs "+LSTR+" / 1 "+PSTR+" / ^ "+SSTR+" * x y - x y - abs 0.001 + / * x y - 2 ^ x y - 2 ^ "+LDMP+" + / * 128 +", scale_inputs="allf", use_expr=1) : mt_lutxy(c,b,"x y - abs "+LSTR+" / 1 "+PSTR+" / ^ "+SSTR+" * x y - x y - abs 0.001 + / * x y - 2 ^ x y - 2 ^ "+LDMP+" + / * 128 +")
 
shrp = (str1<0.01) ? c : c.mt_adddiff(shrpD,U=2,V=2)

shrp = (str2<0.01) ? shrp : sisavs26 ? shrp.mt_makediff(shrpD.mt_lut("x range_half - "+CSTR+" * range_half +", use_expr=2).removegrain(rg,-1),U=2,V=2) : shrp.mt_makediff(shrpD.mt_lut("x 128 - "+CSTR+" * 128 +").removegrain(rg,-1),U=2,V=2)

shrp = (xstr<0.01) ? shrp
\    : sisavs26 ? mt_lutxy(shrp,shrp.removegrain(20,-1),"x x y - 9.9 * +", use_expr=2,U=2,V=2).repair(shrp,12,0).mergeluma(shrp,1.0-xstr) : mt_lutxy(shrp,shrp.removegrain(20,-1),"x x y - 9.9 * +",U=2,V=2).repair(shrp,12,0).mergeluma(shrp,1.0-xstr)

return(shrp)
}