# backport of vs mClean that originally a rip-off of buggy avs mClean
# aside from usual differences that come with vs rip-off of avs this one is indeed act differently from the original avs mClean
# since original one has bug in mt_lut line that were hidden in old versions of masktools2 but in recent updates of masktools2 there is an error message for such case
# v1.12
function VSmClean(clip c, int "thSAD", bool "chroma", int "sharp", int "rn", int "deband", int "depth", float "strength", int "outbits", bool "icalc", int "rgmode")
{

    defH        = Max (C.Height, C.Width/4*3)   # Resolution calculation for auto bs settings
    thSAD       = Default (thSAD, 400)   # Denoising threshold
    chroma      = Default (chroma, true)   # Process chroma
    sharp       = Default (sharp, 10)   # Sharp multiplier
    rn          = Default (rn, 14)   # Luma ReNoise strength from 0 (disabled) to 20
    deband      = Default (deband, 0)   # Apply deband/veed and/or auto balance
    depth       = Default (depth, 0)   # Depth enhancement
    strength    = Default (strength, 20)   # Strength of denoising.
    rgmode      = Default (rgmode, 18)   # Strength of denoising.
    bd          = BitsPerComponent(c)
    sisvfloat   = isvideofloat(c)
    icalc       = sisvfloat ? false : Default(icalc, true)
    outbits     = Default (outbits, bd)   # Output bits, default input depth
    deband      = depth !=0 || deband != 0 ? min(outbits, 16) : deband

    Assert(isYUV(c)==true, """mClean: This is not a YUV clip!""")
    Assert(isYUY2(c)==false, """mClean: YUY2 not Supported""")
	
    sharp = min(max(sharp, 0), 24) # Sharp multiplier
    rn = min(max(rn, 0), 20) # Luma ReNoise strength
    deband = min(max(deband, 0), 5)  # Apply deband/veed
    depth = min(max(depth, 0), 5) # Depth enhancement
    strength = min(max(strength, 0), 20) # Strength of denoising

sc         =  defH>2800 ? 8 : defH>1400 ? 4 : defH>720 ? 2 : 1
bs         =  defH/sc>360 ? 16 : 8
ov         =  bs>12 ? 6 : 2
pel        =  defH>720 ? 1 : 2
truemotion =  defH>20 ? false : True
lambda     =  777*(bs*bs)/64
depth2     =  -depth*3
depth      =  depth*2

sharp = sharp > 20 ? sharp + 30 : defH <= 2500 ? 15 + defH * sharp * 0.0007 : 50


# Denoise preparation
c           =  chroma ? Median(c, yy=false, uu=true, vv=true) : c

# Temporal luma noise filter
c           =  !(sisvfloat || icalc) ? c.fmtc_bitdepth(flt=true) : c

cy          =   ExtractY(c)

super1      =  MSuper (chroma ? c : cy, hpad=bs, vpad=bs, pel=pel, rfilter=4, sharp=1)
super2      =  MSuper (chroma ? c : cy, hpad=bs, vpad=bs, pel=pel, rfilter=1, levels=1)

# --> Analysis
bvec4       =  !icalc ? MRecalculate(super1, MAnalyse(super1, isb=true, delta=4, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180) : nop()
bvec3       =  MRecalculate(super1, MAnalyse(super1, isb=true, delta=3, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
bvec2       =  MRecalculate(super1, MAnalyse(super1, isb=true, delta=2, badsad=1100, lsad=1120, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
bvec1       =  MRecalculate(super1, MAnalyse(super1, isb=true, delta=1, badsad=1500, lsad=980, badrange=27, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
fvec1       =  MRecalculate(super1, MAnalyse(super1, isb=false, delta=1, badsad=1500, lsad=980, badrange=27, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
fvec2       =  MRecalculate(super1, MAnalyse(super1, isb=false, delta=2, badsad=1100, lsad=1120, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
fvec3       =  MRecalculate(super1, MAnalyse(super1, isb=false, delta=3, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180)
fvec4       =  !icalc ? MRecalculate(super1, MAnalyse(super1, isb=false, delta=4, blksize=bs, overlap=ov, search=5, truemotion=truemotion),
            \  blksize=bs, overlap=ov, search=5, truemotion=truemotion, lambda=lambda, thSAD=180) : nop()

# --> Applying cleaning
clean       =  !icalc ? MDegrain4(chroma ? c : cy, super2, bvec1, fvec1, bvec2, fvec2, bvec3, fvec3, bvec4, fvec4, thSAD=thSAD) : MDegrain3(chroma ? c : cy, super2, bvec1, fvec1, bvec2, fvec2, bvec3, fvec3, thSAD=thSAD)
c           =  bd != outbits ? c.fmtc_bitdepth(outbits,dmode=1) : c
cy          =  bd != outbits ? cy.fmtc_bitdepth(outbits,dmode=1) : cy
clean       =  bd != outbits ? clean.fmtc_bitdepth(outbits,dmode=1) : clean
uv          =  chroma ? mt_adddiff(clean, neo_tmedian(mt_makediff(c, clean, y=1, u=3, v=3), 1, y=1 , u=3, v=3), y=1 , u=3, v=3) : c
clean       =  ExtractY(clean)

# Post clean, pre-process deband
filt             =  CombinePlanes(clean, uv, planes="YUV", sample_clip=c)
filt             =  deband==0 ? filt : filt.neo_f3kdb(range=16, preset=chroma ? "high" : "luma", grainy=defH/15, grainc=chroma ? defH/16 : 0, output_depth=outbits)
clean            =  deband==0 ? clean : ExtractY(filt)
filt             =  deband == 2 ? veed(filt) : filt

# Spatial luma denoising
clean2      =  removegrain(clean, rgmode)

# Unsharp filter for spatial detail enhancement
clsharp     =  sharp>0 ? sharp <=50 ? mt_makediff(clean, Blur(clean2, 0.08+0.03*sharp,0)) :
            \  mt_makediff(clean, clean2.vsTCanny(sigmaY=(sharp-46)/4, mode=-1)) : nop()
clsharp     =  sharp>0 ? mt_adddiff(clean2, repair(neo_tmedian(clsharp), clsharp, 12)) : nop()

# If selected, combining ReNoise
noise_diff  =  mt_makediff (clean2, cy)
clean1      =  rn>0<=20 ? mergeluma(clean2, mt_adddiff(clean2, tweak(neo_tmedian(noise_diff), cont=1.008+0.00016*rn)), 0.3+rn*0.035) : nop()
clean2      =  rn>0<=20 ? mt_merge(clean2, clean1, mt_lut(mt_lutxy(clean, invert(clean), "x y min", use_expr=1), "x 32 scaleb < 0 x 45 scaleb > range_max 0 x 35 scaleb - range_max 32 scaleb 65 scaleb - / * - ? ?", use_expr=2)) : clean2

# Combining spatial detail enhancement with spatial noise reduction using prepared mask
noise_diff  =  mt_invert(mt_binarize(noise_diff))
clean2      =  mt_merge (clean2, sharp>0 ? clsharp : clean, mt_lutxy(noise_diff, mt_edge(clean, "prewitt",0,255,0,255), "x y max", use_expr=1))

# Combining result of luma and chroma cleaning
output      =  CombinePlanes(clean2, filt, planes="YUV", sample_clip=c)
output      =  strength<20 ? Merge(c, output, 0.2+0.04*strength) : output
return depth>0 ? mt_adddiff(output, mt_makediff(awarpsharp2(output, depth=depth2, blur=3), awarpsharp2(output, depth=depth, blur=2))) : output
}