# crt_tv_interlace by Doom9 real.finder
# helper Function for crt_display by cretindesalpes
# you need crt_display avs+ update by real.finder to make it work unless you disable do8bitout, YUVout, do16bitin and doRGBin
# 1.00
Function crt_tv_interlace (clip src, int "w", int "h", bool "do8bitout", bool "YUVout", bool "do16bitin", bool "doRGBin", float "voff", float "ppp",
\	float "cutoff", float "scandist", float "sharpv", float "sharph",
\	float "blurh", float "glowgain", float "glowh", float "glowv",
\	float "glowsens", float "contrast", float "gamma", float "softclip",
\	float "mix", float "beamshape", bool "phosphor", bool "pgrid",
\	float "vcs", float "cromaclear", float "maskpp", float "gainb",
\	float "halgain", float "halrange", string "pixel_type")
{
w = Default (w, 1440)
h = Default (h, 1080)
s8bout = Default (do8bitout, true)
YUVout = Default (YUVout, true)
s16bin = Default (do16bitin, true)
doRGBin = Default (doRGBin, true)

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
YUVout ? ConvertToYUV420(matrix="Rec709") : last
s8bout ? Convertbits(8,dither=1) : last
}