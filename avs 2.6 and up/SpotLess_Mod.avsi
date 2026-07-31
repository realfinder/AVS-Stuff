Function SpotLess_Mod(clip c, bool "DeGrain", int "RadT", int "ThSAD", int "ThSAD2", int "Pel", bool "Chroma",
                   \ int "BlkSz", Int "Olap", bool "Tm", bool "Glob", string "Denoiser", bool "FastHBD") {
DeGrain   = Default(DeGrain, false) # MDeGrain in MvTools
RadT      = Default(RadT, 1)        # Temporal radius. (MCompensate arg)
ThSAD     = Default(ThSAD, 10000)    # SAD threshold at radius 1 (Default Nearly OFF).
ThSAD2    = Default(ThSAD2, ThSAD)    # SAD threshold at radius RadT.
Pel       = Default(pel, 1)         # Default 2. 1, 2, or 4. Maybe set 1 for HD+. (1=precision to pixel, 2=precision to half pixel, 4=quarter pixel)
Chroma    = Default(chroma, true)   # MAnalyse chroma arg. If set to true, use chroma in block matching.
BlkSz     = Default(BlkSz, 8)       # Default 8. MAnalyse BlkSize. Bigger blksz quicker and perhaps  better, esp for HD clips. Maybe also better where BIG noise.
OLap      = Default(OLap, BlkSz/2)        # Default half of BlkSz.
Tm        = Default(tm, true)       # TrueMotion, Some folk swear MAnalyse(truemotion=false) is better.
Glob      = Default(glob, true)     # Default True, Allow set MAnalyse(global) independently of TrueMotion.
Denoiser  = Default(Denoiser, Undefined)
FastHB    = default(FastHBD, false)

pad = Max(BlkSz, 8)

sup      = (FastHB ? c.Pre_Clip_Spotlessmod(blur=1.0, contrast=0, brightness=0).convertbits(8) : c.Pre_Clip_Spotlessmod(blur=1.0, contrast=0, brightness=0)).MSuper(hpad=pad, vpad=pad, pel=pel, sharp=2, chroma=Chroma)
sup_rend = MSuper(c, hpad=pad, vpad=pad, pel=pel, sharp=2, levels=1, chroma=Chroma) # Only 1 Level required where not MAnalyse-ing.

MultiVec = MAnalyse(sup, multi=true, delta=RadT, blksize=BlkSz, overlap=OLap, chroma=Chroma, truemotion=Tm, global=Glob, search=5, dct=7, divide=0, plevel=0)
#~ MultiVec = Mrecalculate(sup, MultiVec, tr=RadT, blksize=4, overlap=2, search=5, dct=7, thSAD=150, chroma=Chroma) # bed vectors recalculate

c0 = MCompensate(c, sup_rend, MultiVec, tr=RadT, thSad=ThSAD, thSad2=ThSAD2)
c0 = RadT == 1 ? Clense(c0) : MedianBlurTemporal(c0, radiusY=0, radiusU=0, radiusV=0, temporalradius=RadT)
c0 = SelectEvery(c0, RadT*2+1, RadT) # Return middle frame
c1 = Restore_Objects_Spotlessmod(c, c0, threshold_dark=30, threshold_light=30, Y=3, U=2, V=2)

clensed = Clense(c, cache=4)
# sbegin = ForwardClense(c, cache=-1)
# send = BackwardClense(c, cache=-1)
# alt=Repair(SCSelect(c, sbegin, send, clensed, debug=true), c, mode=1) 
restore = Repair(clensed, c, mode=1)

c3 = RestoreMotionBlocks(clensed, restore, neighbour=c, alternative=restore, gmthreshold=70, dist=1, dmode=2, noise=10, noisy=12, grey=false, debug=false, show=false)

mask_c3 = mt_lutxy(c0, c3, expr="x y - abs", Y=3, U=2, V=2, scale_inputs="allf", use_expr=2).mt_binarize(threshold=7)
     \ .mt_inpand().mt_expand().mt_expand().mt_expand().Blur(1.58)#.mt_convolution(horizontal="3 1 3", vertical="3 1 3", Y=3, U=2, V=2, chroma="-128")

clear = mt_merge(c1, c, mask_c3, Y=3, U=2, V=2)

Defined(Denoiser) || DeGrain ? Eval("""
sup2      = MSuper((FastHB ? clear.convertbits(8) : clear), hpad=pad, vpad=pad, pel=pel, sharp=2, chroma=Chroma)
sup_rend2 = MSuper(clear, hpad=pad, vpad=pad, pel=pel, sharp=2, chroma=Chroma)
bvec1  = MAnalyse(sup2, isb=true,  blksize=BlkSz, overlap=OLap, divide=0, delta=1, search=5, dct=7, plevel=0,
                \ chroma=Chroma, truemotion=Tm, global=Glob) # backward vectors
fvec1  = MAnalyse(sup2, isb=false, blksize=BlkSz, overlap=OLap, divide=0, delta=1, search=5, dct=7, plevel=0,
                \ chroma=Chroma, truemotion=Tm, global=Glob) # forward vectors
# bvec1 = Mrecalculate(sup2, bvec1, blksize=4, overlap=2, search=5, dct=7, thSAD=150, chroma=Chroma) # bed vectors recalculate
# fvec1 = Mrecalculate(sup2, fvec1, blksize=4, overlap=2, search=5, dct=7, thSAD=150, chroma=Chroma) # bed vectors recalculate
backw1 = MFlow(clear, sup_rend2, bvec1)
forw1  = MFlow(clear, sup_rend2, fvec1)
DN = Defined(Denoiser) ? Interleave(backw1, clear, forw1).Eval(Denoiser).SelectEvery(3, 1) : clear
return DeGrain ? MDeGrain1(DN, sup_rend2, bvec1, fvec1, plane=4, limit=255.0, thSad=400) : DN
""") : clear
}

function RemoveDust_Spotlessmod(clip input, int "mode") {
mode = Default(mode, 17)

clensed = Clense(input)
rep = Repair(clensed, input, mode=mode)

RemoveGrain(rep, mode=10)
}

function Pre_Clip_Spotlessmod(clip clp, float "blur", float "contrast", float "brightness"){
blur       = Default(blur, 1.0)
contrast   = Default(contrast, 1.2)
brightness = Default(brightness, 10.0)

v = clp.mt_lut(expr="x 20 1 x 127.5 / - 21 ^ pi x * 255 / cos 21 ^ - * 1.05 * -", Y=3, U=2, V=2, scale_inputs="allf", use_expr=2)

mask_1 = clp.Tweak(sat=0).Blur(blur).mt_edge(mode="min/max", thY1=0, thY2=255, Y=3, U=2, V=2)

pre_1 = v.Tweak(cont=contrast, bright=brightness)
pre_2 = mt_merge(v, pre_1, mask_1, Y=3, U=2, V=2)
pre_3 = pre_2.Tweak(sat=0).mt_invert().Blur(1.58).Blur(1.58).Blur(1.58)
pre_4 = mt_lutxy(pre_2, pre_3, expr="x 127.5 > y 255 x - 127.5 / * x 255 x - - + y x 127.5 / * ? ", scale_inputs="allf", use_expr=2)

return pre_4
}

# v1.1
function Restore_Objects_Spotlessmod(clip source, clip filtered, float "threshold_dark", float "threshold_light", int "Y", int "U", int "V") {
dark  = String(Default(threshold_dark, 20.0))   # Threshold for dark objects. Range: 0...127
light = String(Default(threshold_light, 20.0))  # Threshold for light objects. The lower the thresholds, the more objects will be restored.
Y = Default(Y, 3)
U = Default(U, 2)
V = Default(V, 2)

m1 = mt_lut(source.ColorYUV(autogain=true), expr="x "+dark+" > x 255 "+light+" - < 0 255 ? 255 ?", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_expand().mt_expand().mt_expand(chroma="-128")
m2 = mt_lutxy(source, filtered, expr="x y * 255 /", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_binarize(threshold=128, chroma="-128")
mask_1 = mt_logic(m1, m2, "max").mt_expand().mt_expand(chroma="-128").Blur(1.58)#.mt_convolution(horizontal="3 1 3", vertical="3 1 3", Y=Y, U=U, V=V)

r = mt_merge(source.RemoveDust_Spotlessmod(), filtered, mask_1, Y=Y, U=U, V=V)

m3 = mt_lutxy(source, r, expr="x y - abs", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_binarize(threshold=5).mt_inpand(chroma="-128", thY=128, thC=128)
m4 = m3.mt_inpand().mt_inpand(chroma="-128")
mask_2 = mt_logic(m3, m4, "xor").Blur(1.58)#.mt_convolution(horizontal="3 1 3", vertical="3 1 3", Y=Y, U=U, V=V)

mt_merge(Repair(filtered, r, 17), filtered.RemoveDust_Spotlessmod(), mask_2, Y=Y, U=U, V=V)
}