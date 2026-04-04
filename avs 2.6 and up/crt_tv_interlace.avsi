# crt_tv_interlace by Doom9 real.finder
# helper Function for crt_display by cretindesalpes
# you need crt_display avs+ update by real.finder to make it work unless you disable do8bitout, YUVout, do16bitin and doRGBin (and maybe Afterglow)
# 1.02
Function crt_tv_interlace (clip src, int "w", int "h", bool "do8bitout", bool "YUVout", bool "do16bitin", bool "doRGBin", float "voff", float "ppp",
\	float "cutoff", float "scandist", float "sharpv", float "sharph",
\	float "blurh", float "glowgain", float "glowh", float "glowv",
\	float "glowsens", float "contrast", float "gamma", float "softclip",
\	float "mix", float "beamshape", bool "phosphor", bool "pgrid",
\	float "vcs", float "cromaclear", float "maskpp", float "gainb",
\	float "halgain", float "halrange", string "pixel_type", bool "Afterglow")
{
w = Default (w, 1440)
h = Default (h, 1080)
s8bout = Default (do8bitout, true)
YUVout = Default (YUVout, true)
s16bin = Default (do16bitin, true)
doRGBin = Default (doRGBin, true)
Afterglow = Default (Afterglow, true)

blurh = Default (blurh, 1.15)
scandist = Default (scandist, 1.05)
cutoff = Default (cutoff, 0.9)
glowgain = Default (glowgain, 0.125)
halgain = Default (halgain, 0.03)
cromaclear = Default (cromaclear, 0.15)
softclip = Default (softclip, 0.75)

IsFieldBased(src) ? src : SeparateFields(src)
s16bin ? convertbits(16) : last
doRGBin ? ConvertToPlanarRGB() : last
ow=Width()
oh=Height()
cw=float(w)/ow
ch=float(h)/oh
ishift=ch/4
sistff=GetParity(src)
Interleave(\
SelectEven().crt_display(cw, ch, voff, ppp, cutoff, scandist, sharpv, sharph, blurh, glowgain, glowh, glowv, glowsens, contrast, gamma, softclip, mix, beamshape, phosphor, pgrid, vcs, cromaclear, maskpp, gainb, halgain, halrange, pixel_type).BilinearResize(w,h,0,sistff ? ishift : -ishift), \
SelectOdd().crt_display(cw, ch, voff, ppp, cutoff, scandist, sharpv, sharph, blurh, glowgain, glowh, glowv, glowsens, contrast, gamma, softclip, mix, beamshape, phosphor, pgrid, vcs, cromaclear, maskpp, gainb, halgain, halrange, pixel_type).BilinearResize(w,h,0,sistff ? -ishift : ishift)).AssumeFrameBased()
AvsPlusVersionNumber >= 3276 ? propSet("_FieldBased", 0).propset("_Combed", 0) : last
Afterglow ? SMiniPhosphorPersistence() : last
YUVout ? ConvertToYUV420(matrix="Rec709") : last
s8bout ? Convertbits(8,dither=1) : last
}


# SMiniPhosphorPersistence by Doom9 real.finder
# 1.01
function SMiniPhosphorPersistence(clip c)
{
c

f3=Loop(4,0,0)
f2=Loop(3,0,0)
f1=Loop(2,0,0)

p2=mt_merge(f2,f3,Mt_lutxy(sh_ConvertToY(f2),sh_ConvertToY(f3),"y x > range_half range_min ?",use_expr=1),luma=true)
p1=mt_merge(f1,p2,Mt_lutxy(sh_ConvertToY(f1),sh_ConvertToY(p2),"y x > range_half 4 / range_min ?",use_expr=1),luma=true)
   mt_merge( c,p1,Mt_lutxy(sh_ConvertToY(c ),sh_ConvertToY(p1),"y x > range_half 8 / range_min ?",use_expr=1),luma=true)
}