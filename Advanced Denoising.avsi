# Advanced Denoising and anime bob v1.60

# MotionThresh by mf, mod by A.SONY
# Simple scenechange-proof motion threshold
# Tile outputs 16x16 clip for speed
# Use tile=true for conditional filtering, tile=false for masking
 
function MotionThresh(clip motinc, float thresh, bool "tile", bool "fast", int "cache") {
fast = Default(fast, false)
tile = Default(tile,  fast)
cache= default(cache,10)

sisphbd = AvsPlusVersionNumber > 2294
 
sislumaonly = !(VersionNumber() < 2.60) ? sisphbd ? motinc.isy() : motinc.isy8() : nop()

motinc = fast && !sislumaonly ? sisphbd ? motinc.converttoy() : motinc.converttoy8() : motinc
black  = !fast ? BlankClip(motinc, width=16, height=16               ) : BlankClip(motinc, width=16, height=16, Color_yuv=color_black)
white  = !fast ? BlankClip(motinc, width=16, height=16, color=$FFFFFF) : BlankClip(motinc, width=16, height=16, Color_yuv=color_white)
cond1  = fast ? nop() : ConditionalFilter(motinc, white, black, "YDifferenceFromPrevious()", "greaterthan", String(thresh))
cond2  = fast ? nop() : ConditionalFilter(motinc, white, black, "YDifferenceToNext()", "greaterthan", String(thresh))
fast ? eval("""
global MotionThreshblack = black
global MotionThreshthresh = thresh
global MotionThreshmotinc = motinc
global mtcav=0
global mtnav=0
""") : nop()
fast ? white.ScriptClip("""
MotionThreshwhite = last
motinc = MotionThreshmotinc
cfr=current_frame
 
mtpav=cfr<3 ? 0 : mtcav
global mtcav=cfr<2 ? 0 : mtnav
global mtnav=motinc.trim(1,0).AverageLuma()

cond1 = abs(mtcav-mtpav) > MotionThreshthresh ? MotionThreshwhite : MotionThreshblack
cond2 = abs(mtcav-mtnav) > MotionThreshthresh ? MotionThreshwhite : MotionThreshblack
Overlay(cond1, cond2, mode="darken")
""") : nop()
fast ? last : Overlay(cond1, cond2, mode="darken")
tile ? last : Eval("try { PointResizemt(motinc.width, motinc.height) } catch(error_msg) { PointResize(motinc.width, motinc.height) }")
fast ? cache<0 ? last : last.RequestLinear(8, cache, 5, false, false) : last
}


######################################################################
# MotionRamp by mf, mod for speed by A.SONY
# Average motion soft-thresholding based on 5 thresholds
# Dependancies: MotionThresh, ParameterisedBlend or Average if avs is 2.6 or up
 
function MotionRamp(clip morinc, int thresh1, int thresh2, int thresh3, int thresh4, int thresh5, int "min", int "max", int "floor", int "ceil", int "radius", bool "tile", bool "fast", int "cache") {
min = Default(min, 0)
max = Default(max, 255)
floor = Default(floor, 0)
ceil  = Default(ceil, 255)
radius = Default(radius, 2)
fast = Default(fast, false)
tile = Default(tile,  fast)
cache= default(cache,10)

sisphbd = AvsPlusVersionNumber > 2294
 
sislumaonly = fast ? sisphbd ? morinc.isy() : morinc.isy8() : false
 
fast && !(VersionNumber() < 2.60) && !sislumaonly ? sisphbd ? morinc.converttoy() : morinc.converttoy8() : morinc

fast ? eval("""
white = BlankClip(last, width=16, height=16, Color_yuv=color_white)
global MotionThreshblack = BlankClip(last, width=16, height=16, Color_yuv=color_black)
global MotionThreshthresh1 = thresh1
global MotionThreshthresh2 = thresh2
global MotionThreshthresh3 = thresh3
global MotionThreshthresh4 = thresh4
global MotionThreshthresh5 = thresh5
global MotionThreshmorinc = last
global mtnav=0
""") : last
fast ? white.ScriptClip("""
morinc = MotionThreshmorinc
MotionThreshwhite = last
cfr=current_frame
 
mtpav=cfr<1 ? 0 : mtnav
global mtnav=morinc.YDifferenceToNext()

cond11 = mtpav > MotionThreshthresh1 ? MotionThreshwhite : MotionThreshblack
cond21 = mtnav > MotionThreshthresh1 ? MotionThreshwhite : MotionThreshblack
c1=Overlay(cond11, cond21, mode="darken")

cond12 = mtpav > MotionThreshthresh2 ? MotionThreshwhite : MotionThreshblack
cond22 = mtnav > MotionThreshthresh2 ? MotionThreshwhite : MotionThreshblack
c2=Overlay(cond12, cond22, mode="darken")

cond13 = mtpav > MotionThreshthresh3 ? MotionThreshwhite : MotionThreshblack
cond23 = mtnav > MotionThreshthresh3 ? MotionThreshwhite : MotionThreshblack
c3=Overlay(cond13, cond23, mode="darken")

cond14 = mtpav > MotionThreshthresh4 ? MotionThreshwhite : MotionThreshblack
cond24 = mtnav > MotionThreshthresh4 ? MotionThreshwhite : MotionThreshblack
c4=Overlay(cond14, cond24, mode="darken")

cond15 = mtpav > MotionThreshthresh5 ? MotionThreshwhite : MotionThreshblack
cond25 = mtnav > MotionThreshthresh5 ? MotionThreshwhite : MotionThreshblack
c5=Overlay(cond15, cond25, mode="darken")

VersionNumber() < 2.6 ? Interleave(c3, c2, c4, c1, c5).ParameterisedBlend(0.20, 0.20, 0.20, 0.20, 0.20, gamma=1, scaleweights=false).SelectEvery(5,0) : Average(c3, 0.20, c2, 0.20, c4, 0.20, c1, 0.20, c5, 0.20)
""") : VersionNumber() < 2.6 ? Interleave(MotionThresh(thresh3, tile=true), MotionThresh(thresh2, tile=true), MotionThresh(thresh4, tile=true), MotionThresh(thresh1, tile=true), MotionThresh(thresh5, tile=true)).ParameterisedBlend(0.20, 0.20, 0.20, 0.20, 0.20, gamma=1, scaleweights=false).SelectEvery(5,0) : \
                               Average(MotionThresh(thresh3, tile=true), 0.20, MotionThresh(thresh2, tile=true), 0.20, MotionThresh(thresh4, tile=true), 0.20, MotionThresh(thresh1, tile=true), 0.20, MotionThresh(thresh5, tile=true), 0.20)
fast ? cache<0 ? last : last.RequestLinear(8, cache, 5, false, false) : last
TemporalSoften(radius,255,0,255,2)
fast ? last : Levels(floor, 1, ceil, min, max)
fast ? last : ColorYUV(levels="TV->PC")
tile ? last : Eval("try { PointResizemt(morinc.width, morinc.height) } catch(error_msg) { PointResize(morinc.width, morinc.height) }")
}


##########
function admfilter(clip oin, bool "mc", float "f", bool "DarkPreserve", float "rStr", float "amp", bool "lsb", bool "lsb_in", bool "lsb_out", bool "luma_rebuild", bool "u", bool "v", string "pp", string "dfttest_params", string "mcdfttest_params", string "custom_filter", clip "MotionRampadc", bool "mcf", clip "ppsuper", clip "super", clip "exmcclip") {
d = default (DarkPreserve      , true)
mc = default (mc      , true)
sisphbd = AvsPlusVersionNumber > 2294
f = Default(f, 16.0)
lsb = default (lsb, sisphbd ? oin.BitsPerComponent() > 8 ? false : true : true)
lsb_in = default (lsb_in      , false)
oin8 = lsb_in ? oin.ditherpost(mode=7,slice=false,u=u ? 3 : 1,v=v ? 3 : 1) : oin
    ox = oin8.width()
    oy = oin8.height()
    HD = (ox > 1099 || oy > 599)
lsb_out = default (lsb_out      , lsb_in)
lsb = lsb_in || lsb_out ? true : lsb
luma_rebuild = default (luma_rebuild      , true)
u = default (u      , true)
v = default (v      , true)
exmc = defined(exmcclip)
mcf = default (mcf, exmc)
dfttest_params = default(dfttest_params, "")
mcdfttest_params = default(mcdfttest_params, "")
pp = default (pp, "blur(1.53)")

pel = HD ? 1 : 2

super = defined(super) ? super : oin8.MSuper(pel=pel, levels=1, chroma=(U || V))
ppsu = defined(ppsuper) ? ppsuper : oin8.spp_super(pp=oin8.Eval(pp),rStr=rStr,amp=amp,lsb_in=lsb_in,luma_rebuild=luma_rebuild,u=u,v=v,hd=hd)
exmcclip = mcf ? exmc ? exmcclip : oin8.sMCclips(ppsu,super,hd=hd) : nop()

custom_filter = defined(custom_filter) ? custom_filter : \
							mcf ? "dfttestmc(pp=oin8,lsb=lsb, Sigma=adSigma+1.0/f,lsb_in=lsb_in,u=u,v=v,slices=false,super=super,input8=oin8,hd=hd,exmcclip=exmcclip,dfttest_params=dfttest_params" + mcdfttest_params + ")" : \
                                                         mc ? "dfttestmc(pp=Eval(pp),lsb=lsb, Sigma=adSigma+1.0/f,rStr=rStr,amp=amp,lsb_in=lsb_in,luma_rebuild=luma_rebuild,u=u,v=v,dfttest_params=dfttest_params" + mcdfttest_params + ")" : \
                                                              "dfttest(lsb=lsb, Sigma=adSigma+1.0/f, lsb_in=lsb_in,u=u,v=v" + dfttest_params + ")"

oin
MotionRampadc = defined(MotionRampadc) ? MotionRampadc : last.MotionRamp(5,10,15,20,25,Max=255,fast=True)
lsb_out && !lsb_in ? Dither_convert_8_to_16() : lsb_in && !lsb_out ? Ditherpost(mode=-1, y=1, u=1,v=1) : last
return GScriptClip("""
                     adfloat = AverageLuma(MotionRampadc)
                     adSigmb = sisphbd ? BitsPerComponent() > 8 ? BitsPerComponent() == 10 ? 4 : BitsPerComponent() == 12 ? 8 : BitsPerComponent() == 14 ? 64 : nop() : nop() : nop()
                     adSigma = sisphbd ? isvideofloat() ? adfloat*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? adfloat/adSigmb : sqrt(adfloat) : adfloat : adfloat
                     (lsb_out && !lsb_in) || (lsb_in && !lsb_out) ? oin : last
                     adden = Eval(custom_filter)
                     d ? DarkPreserve_function(filtered=adden, original=last, u=u ? 3 : 4, v=v ? 3 : 4, lsb=lsb, lsb_in=lsb_in, lsb_out=lsb_out) : adden
                     !d && !lsb_out && lsb ? Ditherpost(mode=7, slice=false) : last
                     """, args="MotionRampadc, f, d, rStr, amp, lsb_in, lsb_out, lsb, luma_rebuild, u, v,dfttest_params,mcdfttest_params,pp,oin,custom_filter,sisphbd,super,oin8,hd,exmcclip")
}


#######
function DarkPreserve_function(clip "filtered", clip "original", bool "merge16_8", int "u", int "v", bool "lsb", bool "lsb_in", bool "lsb_out") {
lsb_in    = default (lsb_in                       , false) #for original
F_lsb_in  = lsb_in ? (Height(filtered)) == (Height(original)) : (Height(filtered)) == (Height(original)*2)
lsb_out   = default (lsb_out         , F_lsb_in || lsb_in)
lsb       = default (lsb ,  lsb_in || lsb_out || F_lsb_in)
merge16_8 = default (merge16_8                     , true)
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? original.isy() : VersionNumber() < 2.6 ? nop() : original.isy8()
u         = default (u                                , VersionNumber() < 2.6 ? 3 : sislumaonly ? 1 : 3)
v         = default (v                                , u)
chroma    = !(u != 3 && v != 3)

F_lsb_in        ? Assert(lsb,                          "16stacked filtered clip requires: lsb=true")                : nop()
lsb_in          ? Assert(lsb,                          "lsb_in  requires: lsb=true")                                : nop()
lsb_out         ? Assert(lsb,                          "lsb_out requires: lsb=true")                                : nop()

dp_lut = lsb_in ? original.Dither_lut16("x 4096 < 65535 x 19200 > 0 65535 x 4096 - 4.338916843220339 * - ? ?",u=1,v=1) : VersionNumber() < 2.6 ? original.mt_lut("x 16 < 255 x 75 > 0 255 x 16 - 4.322033898305085 * - ? ?",u=1,v=1)
         														 \		       : original.mt_lut("x 16 scalef < range_max x 75 scalef > 0 range_max x 16 scalef - range_max 75 scalef 16 scalef - / * - ? ?",u=1,v=1)

dp_lut = lsb_in && merge16_8 ? dp_lut.Ditherpost(mode=6, slice=false, u=1, v=1) : dp_lut

dp_merge = lsb ? merge16_8 ? Dither_merge16_8(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             Dither_merge16(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             mt_merge(filtered, original, dp_lut, luma=chroma, u=u,v=v)
lsb ? lsb_out ? dp_merge : dp_merge.Ditherpost(mode=7, slice=false) : dp_merge
}

function lightPreserve_function(clip "filtered", clip "original", bool "merge16_8", int "u", int "v", bool "lsb", bool "lsb_in", bool "lsb_out") {
lsb_in    = default (lsb_in                       , false) #for original
F_lsb_in  = lsb_in ? (Height(filtered)) == (Height(original)) : (Height(filtered)) == (Height(original)*2)
lsb_out   = default (lsb_out         , F_lsb_in || lsb_in)
lsb       = default (lsb ,  lsb_in || lsb_out || F_lsb_in)
merge16_8 = default (merge16_8                     , true)
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? original.isy() : VersionNumber() < 2.6 ? nop() : original.isy8()
u         = default (u                                , VersionNumber() < 2.6 ? 3 : sislumaonly ? 1 : 3)
v         = default (v                                , u)
chroma    = !(u != 3 && v != 3)

F_lsb_in        ? Assert(lsb,                          "16stacked filtered clip requires: lsb=true")                : nop()
lsb_in          ? Assert(lsb,                          "lsb_in  requires: lsb=true")                                : nop()
lsb_out         ? Assert(lsb,                          "lsb_out requires: lsb=true")                                : nop()

dp_lut = lsb_in ? original.Dither_lut16("x 60160 > 65535 x 45056 < 0 65535 60160 x - 4.338916843220339 * - ? ?",u=1,v=1) : VersionNumber() < 2.6 ? original.mt_lut("x 235 > 255 x 176 < 0 255 235 x - 4.322033898305085 * - ? ?",u=1,v=1)
         														   \		         : original.mt_lut("x 235 scalef > range_max x 176 scalef < 0 range_max x 235 scalef - range_max 176 scalef 235 scalef - / * - ? ?",u=1,v=1)

dp_lut = lsb_in && merge16_8 ? dp_lut.Ditherpost(mode=6, slice=false, u=1, v=1) : dp_lut

dp_merge = lsb ? merge16_8 ? Dither_merge16_8(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             Dither_merge16(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             mt_merge(filtered, original, dp_lut, luma=chroma, u=u,v=v)
lsb ? lsb_out ? dp_merge : dp_merge.Ditherpost(mode=7, slice=false) : dp_merge
}


##########
#edge side bleed
#original idea by "colours", this function mod by A.SONY
##########
function edgesidebleed(clip input, float "w32", float "w16", float "w8", float "w4", float "w2", bool "bleed", bool "chroma", int "mode") {
w2     = Default(w2,     0.001)
w4     = Default(w4,     0.055)
w8     = Default(w8,     0.015)
w16    = Default(w16,     0.02)
w32    = Default(w32,    0.001)
chroma = default(chroma, false)
mode   = default(mode,       0)
avs26  = !(VersionNumber() < 2.6)
bleed  = default(bleed, avs26)

sisyuy2 = input.isyuy2()
input = sisyuy2 && avs26 ? input.converttoyv16() : input

sisphbd = !chroma ? AvsPlusVersionNumber > 2294 : nop()
sislumaonly = !chroma ? sisphbd ? input.isy() : !avs26 ? true : input.isy8() : nop()
!chroma ? sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8() : input
w = bleed ?  Width() : nop()
h = bleed ? Height() : nop()

shift32 = w32!=0 ? !bleed ? Crop(Width()-32,0,32,0,true).StackHorizontal(Crop(0,0,-32,0,true)) : nop() : nop()
shift32 = w32!=0 ? bleed ? BicubicResize (w / 32, h, 1, 0,src_left=-32).BicubicResize (w, h, 1, 0) : shift32 : nop()
w32==0 ? last : mode == 0 ? average(last,1+w32,shift32,-w32) : mode==1 ? lightPreserve_function(average(last,1+w32,shift32,-w32),last) : DarkPreserve_function(average(last,1+w32,shift32,-w32),last)
shift16 = w16!=0 ? !bleed ? Crop(Width()-16,0,16,0,true).StackHorizontal(Crop(0,0,-16,0,true)) : nop() : nop()
shift16 = w16!=0 ? bleed ? BicubicResize (w / 16, h, 1, 0,src_left=-16).BicubicResize (w, h, 1, 0) : shift16 : nop()
w16==0 ? last : mode == 0 ? average(last,1+w16,shift16,-w16) : mode==1 ? lightPreserve_function(average(last,1+w16,shift16,-w16),last) : DarkPreserve_function(average(last,1+w16,shift16,-w16),last)
shift8 = w8!=0 ? !bleed ? Crop(Width()-8,0,8,0,true).StackHorizontal(Crop(0,0,-8,0,true)) : nop() : nop()
shift8 = w8!=0 ? bleed ? BicubicResize (w / 8, h, 1, 0,src_left=-8).BicubicResize (w, h, 1, 0) : shift8 : nop()
w8==0 ? last : mode == 0 ? average(last,1+w8,shift8,-w8) : mode==1 ? lightPreserve_function(average(last,1+w8,shift8,-w8),last) : DarkPreserve_function(average(last,1+w8,shift8,-w8),last)
shift4 = w4!=0 ? !bleed ? Crop(Width()-4,0,4,0,true).StackHorizontal(Crop(0,0,-4,0,true)) : nop() : nop()
shift4 = w4!=0 ? bleed ? BicubicResize (w / 4, h, 1, 0,src_left=-4).BicubicResize (w, h, 1, 0) : shift4 : nop()
w4==0 ? last : mode == 0 ? average(last,1+w4,shift4,-w4) : mode==1 ? lightPreserve_function(average(last,1+w4,shift4,-w4),last) : DarkPreserve_function(average(last,1+w4,shift4,-w4),last)
shift2 = w2!=0 ? !bleed ? Crop(Width()-2,0,2,0,true).StackHorizontal(Crop(0,0,-2,0,true)) : nop() : nop()
shift2 = w2!=0 ? bleed ? BicubicResize (w / 2, h, 1, 0,src_left=-2).BicubicResize (w, h, 1, 0) : shift2 : nop()
w2==0 ? last : mode == 0 ? average(last,1+w2,shift2,-w2) : mode==1 ? lightPreserve_function(average(last,1+w2,shift2,-w2),last) : DarkPreserve_function(average(last,1+w2,shift2,-w2),last)

!chroma ? sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last) : last
sisyuy2 ? converttoyuy2() : last
}


##########
#chroma edge side bleed (aka pink artifacts) fix, by A.SONY
##########
function chromasidebleed(clip input, int "diameter", float "sDev", float "iDev", float "cs", bool "bic", string "cplace", bool "d2", int "kernS", int "kernI", int "resType")
{
diameter  = default (diameter,    11)
sDev      = default (sDev,      31.1)
iDev      = default (iDev,      15.1)
d2        = default (d2,        true)
kernS     = default (kernS,        8)
kernI     = default (kernI,        3)
restype   = default (restype,      0)
bic       = default (bic,       true)
cplace    = default (cplace, "MPEG2")

avs25   = VersionNumber() < 2.6
sisyuy2 = input.isyuy2()
input = sisyuy2 && !avs25 ? input.converttoyv16() : input

chroma = false

sisphbd = AvsPlusVersionNumber > 2294
sisfullchr = sisphbd ? input.is444() : avs25 ? false : input.isyv24()
sislumaonly = sisphbd ? input.isy() : avs25 ? false : input.isy8()
Assert(!sislumaonly, "why you use this on no chroma clip?!")

y=avs25 ? input : sisphbd ? input.converttoy() : input.converttoy8()
u=avs25 ? input.utoy() : input.utoy8()
v=avs25 ? input.vtoy() : input.vtoy8()
cshift = (cplace == "MPEG1" && IsYV12(input)) || IsYV24(input) ? 0 : -0.5
ych = sisfullchr ? y : bic ? input.BicubicResize(u.width(), v.height(), 1, 0, src_left=cshift) : input.BilinearResize(u.width(), v.height(), src_left=cshift)
u=u.ConvertToYV12().TBilateral(diameterL=diameter, sDevL=sDev, iDevL=iDev, csL=cs, d2=d2, chroma=chroma, ppclip=ych.ConvertToYV12(), kernS=kernS, kernI=kernI, resType=resType)
v=v.ConvertToYV12().TBilateral(diameterL=diameter, sDevL=sDev, iDevL=iDev, csL=cs, d2=d2, chroma=chroma, ppclip=ych.ConvertToYV12(), kernS=kernS, kernI=kernI, resType=resType)
YToUV(u,v,y)
sisyuy2 ? converttoyuy2() : last
}


#########
# Comb wrapper function

function sComb(clip clip, bool "DeCrawing", bool "DeRainbowing", int "LRepair", int "CRepair", bool "ntsccombmask") {
DeCrawing = default (DeCrawing, true)
ntsccombmask = default (ntsccombmask, false)
DeRainbowing = default (DeRainbowing, true)
LRepair = default (LRepair, ntsccombmask ? 7 : DeCrawing ? 2 : 0)
CRepair = default (CRepair, ntsccombmask ? 5 : 0)
sisphbd = AvsPlusVersionNumber > 2294
avs26   = !(VersionNumber() < 2.6)
clip
sis422  = avs26 ? isyv16() : false
Assert((isyv12 || sis422), "sComb: only yv12 and yv16 is supported")
prefil = ntsccombmask ? (VersionNumber() < 2.60) && isyv12(input) ? last.HQdn3d().FFT3DFilter().tweak(sat=1.5) : last.HQdn3d_2().FFT3DFilter().tweak(sat=1.5) : nop()
iqchr  = ntsccombmask ? prefil.SwapUV().Tweak(hue=-33) : nop()
I = ntsccombmask ? sisphbd ? iqchr.ExtractU().sypixsub(2,2) : avs26 ? iqchr.utoy8().sypixsub(2,2) : iqchr.utoy().sypixsub(2,2) : nop()
Q = ntsccombmask ? sisphbd ? iqchr.ExtractV().sypixsub(2,2) : avs26 ? iqchr.Vtoy8().sypixsub(2,2) : iqchr.Vtoy().sypixsub(2,2) : nop()
m = ntsccombmask ? ytouv(i,q,prefil).sypixsub(2).mt_edge("min/max", 0, 15, 0, 10,u=3,v=3).mt_expand(128,128,y=2,u=3,v=3).mt_expand(128,mode="horizontal",u=2,v=2).mt_inpand(128,mode="horizontal",u=2,v=2) : nop()
mU = ntsccombmask ? sisphbd ? m.ExtractU() : avs26 ? m.utoy8() : m.utoy() : nop()
mV = ntsccombmask ? sisphbd ? m.ExtractV() : avs26 ? m.vtoy8() : m.vtoy() : nop()
y=ntsccombmask ? Overlay(mu,mv,mode="add").Spline36Resize(width(),Height(),0.5) : nop()
m = ntsccombmask ? sisphbd ? m.ConvertToY() : avs26 ? m.ConvertToY8() : m : nop()
uv=ntsccombmask ? m.Spline36Resize(mu.width(),mu.Height(),-0.5) : nop()
m=ntsccombmask ? ytouv(uv,uv,y) : nop()

DeRainbowing && ntsccombmask ? TComb(mode=1) : last
SeparateFields()
oriFiel=last
DeCrawing ? DDComb(static=true,strong=true,checkmate=ntsccombmask) : last
DeRainbowing ? ASTDRmc(edgemprefil=oriFiel,chroma=true, nomask=ntsccombmask) : last
ntsccombmask ? mt_merge(oriFiel,last,m.SeparateFields(),u=3,v=3) : last
Weave()
LRepair==0 && CRepair==0 ? last : last.Repair(clip,LRepair,CRepair)
}


# Padding by Didée
function Padding(clip c, int left, int top, int right, int bottom, int "threads")
{
threads = Default(threads, 0)
w = c.width()
h = c.height()
threads!=1 ? Eval("try { pointresizemt(w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001, threads=threads) } catch(error_msg) { c.pointresize( w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001 ) }") : c.pointresize( w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001 )
}


# filtering with some borders by A.SONY
Function filtering_wsb (clip src, string "filter", int "oneborder", clip "linesm", clip "clip4lines", int "mmy", bool "mmLuma", int "mmuv", bool "minflate", int "bordertype")
{
oneborder = Default (oneborder,   2)
mmLuma    = Default (mmLuma,  false)
minflate  = Default (minflate, true)
mmuv      = Default (mmuv, mmLuma ? 3 : 2)
mmy       = Default (mmy,         3)
bordertyp = Default (bordertype,  1)
filter    = Default (filter, defined(linesm) ? "yahr3.TBilateral(5,5,0.9,0.9,5,5,0.7,chroma=false)" : \
                                             """FineDehaloanalog(exdehalo="VHSHaloremover(2,2,200,100,0.5).yahr2(32)")""")
minf = defined(linesm) ? minflate ? linesm.mt_inflate(155,155,u=mmLuma || mmuv!=3 ? 1 : 3 ,v=mmLuma || mmuv!=3 ? 1 : 3) : linesm : nop()
 
src
bordertyp==0 ? Padding(oneborder,oneborder,oneborder,oneborder) : AddBorders(oneborder,oneborder,oneborder,oneborder,bordertyp==1 ? undefined : bordertyp==2 ? color_white : bordertyp)
eval(filter)
Crop(oneborder, oneborder, -oneborder, -oneborder, align=true)
 
defined(linesm) ? mt_Merge(last, defined(clip4lines) ? clip4lines : src, minf,y=mmy,luma=mmLuma,u=mmuv,v=mmuv) : last
}


###############
# Hqdn3d_2

function Hqdn3d_2(clip clip, float "ls", float "cs", float "lt", float "ct", int "UV", bool "lsb", bool "lsb_in", bool "i16") {
cs        = default (cs              , 3.0)
ct        = default (ct              , 4.5)
UV        = default (UV               , 3)
UV        = !(VersionNumber() < 2.60) ? isY8(clip) ? 1 : UV : UV
lsb_in    = default (lsb_in          , false)
i16       = default (i16             , false)
lsb_out   = default (lsb             , lsb_in)

i16b      = lsb_out || i16 || lsb_in

isrgb(clip) ? Assert(!i16b, "no 16bit for RGB, but you can use some trickes for that (see dither doc)") : nop()

yString = VersionNumber() < 2.60 ? "yv12" : "Y8"

pclip   = isYUV(clip) && i16b && isYUY2(clip) && !(VersionNumber() < 2.60) ? clip.ConvertToYV16() : clip

i16clip = isYUV(clip) ? i16b ? lsb_in ? pclip.Bitdepth(from=88, to=16) : i16 ? clip : pclip.Bitdepth(from=8, to=16) : nop() : nop()

	y = isYUV(clip) ? VersionNumber() < 2.60 ? i16b ? i16clip : clip : i16b ? ConvertToY8(i16clip) : ConvertToY8(clip) : nop()
	u = isYUV(clip) && UV != 1 ? VersionNumber() < 2.60 ? i16b ? UToY(i16clip) : UToY(clip) : i16b ? UToY8(i16clip) : UToY8(clip) : nop()
	v = isYUV(clip) && UV != 1 ? VersionNumber() < 2.60 ? i16b ? VToY(i16clip) : VToY(clip) : i16b ? VToY8(i16clip) : VToY8(clip) : nop()
	y = isYUV(clip) ? VersionNumber() < 2.60 ? isclip(i16clip) ? y.converttoyv12().Hqdn3d16Y(sp=ls, tp=lt) : y.converttoyv12().Hqdn3dY(sp=ls, tp=lt) : isclip(i16clip) ? y.Hqdn3d16Y(sp=ls, tp=lt) : y.Hqdn3dY(sp=ls, tp=lt) : nop()
	u = isYUV(clip) ? UV == 3 ? VersionNumber() < 2.60 ? isclip(i16clip) ? u.converttoyv12().Hqdn3d16Y(sp=cs, tp=ct) : u.converttoyv12().Hqdn3dY(sp=cs, tp=ct) : isclip(i16clip) ? u.Hqdn3d16Y(sp=cs, tp=ct) : u.Hqdn3dY(sp=cs, tp=ct) : u : nop()
	v = isYUV(clip) ? UV == 3 ? VersionNumber() < 2.60 ? isclip(i16clip) ? v.converttoyv12().Hqdn3d16Y(sp=cs, tp=ct) : v.converttoyv12().Hqdn3dY(sp=cs, tp=ct) : isclip(i16clip) ? v.Hqdn3d16Y(sp=cs, tp=ct) : v.Hqdn3dY(sp=cs, tp=ct) : v : nop()
	isYUV(clip) ? (VersionNumber() < 2.60) && isYUY2(clip) ? UV == 1 ? y : YToUV(u.converttoyuy2(),v.converttoyuy2(),y.converttoyuy2()) : UV == 1 ? y : YToUV(u,v,y) : nop()
        isYUV(clip) ? i16b && !i16 && lsb_out ? Bitdepth(from=16, to=88) : last : last
	isYUV(clip) ? !i16b || lsb_out || i16 ? last : Bitdepth(from=16, to=8) : last
	isYUY2(clip) ? VersionNumber() < 2.60 ? last : converttoyuy2() : last

	A = isrgb32(clip) ? clip.ShowAlpha(yString) : nop()
	r = isrgb(clip) ? clip.ShowRed(yString) : nop()
	g = isrgb(clip) ? clip.ShowGreen(yString) : nop()
	b = isrgb(clip) ? clip.ShowBlue(yString) : nop()
	A = isrgb32(clip) ? A.Hqdn3dY(sp=ls, tp=lt) : nop()
	r = isrgb(clip) ? r.Hqdn3dY(sp=ls, tp=lt) : nop()
	g = isrgb(clip) ? g.Hqdn3dY(sp=ls, tp=lt) : nop()
	b = isrgb(clip) ? b.Hqdn3dY(sp=ls, tp=lt) : nop()
	isYUV(clip) ? last : isrgb32(clip) ? MergeARGB(A,r,g,b) : MergeRGB(r,g,b,"RGB24")
}


###############
#motion adaptive by A.SONY

function smam(clip input, clip "prefilter", val "filter", int "pel", int "blksize", clip "motionmask", float "Str", float "Amp", bool "TV_range", bool "qtgmc_lsb", int "tr2", int "usedaa3mod", bool "repblend", val "dslow", bool "qtgmc_n16") {

sisphbd = AvsPlusVersionNumber > 2294
qtgmc_lsb = default(qtgmc_lsb, sisphbd ? false : true)
qtgmc_n16 = default(qtgmc_n16, sisphbd ? input.BitsPerComponent() > 8 ? false : true : false)
repblend  = default(repblend, false)

defined(filter) ? Assert((Isclip(filter) || IsString(filter)),        "'filter' only accepts clip or string") : nop()

Str             = default (Str, 1.5)
exfilclp        = isclip(filter)
sisbob          = round(framerate(input))==60 || framerate(input)==50
tr2             = default (tr2, sisbob ? 3 : 1)
usedaa3mod      = default (usedaa3mod, exfilclp ? 0 : sisbob ? 1 : 2)

infiltr = usedaa3mod == 1 ? input.daa3mod(dslow) : input
filclip = defined(filter) ? exfilclp ? filter : eval("infiltr." + filter) : infiltr.QTGMC(InputType=1, tr0=0, tr1=sisbob ? undefined : 1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep1=sisbob ? undefined : 11, rep2=sisbob ? undefined : 11, Sharpness=0.0, TV_range=TV_range, Str=Str, Amp=Amp)
filclip = usedaa3mod == 2 ? filclip.daa3mod(dslow) : filclip

momask  = !defined(motionmask) ? input.smam_mask(prefilter,pel,blksize) : motionmask #if you deal with YUY2 then it should be Planar YUY2 in avs2.5 and yv16 in avs2.6
isyuy2(input) && VersionNumber() < 2.60 ? mt_merge(input.Interleaved2Planar(),filclip.Interleaved2Planar(),momask,u=3,v=3).Planar2Interleaved() : isyuy2(input) ? mt_merge(input.converttoyv16(),filclip.converttoyv16(),momask,u=3,v=3).converttoyuy2() : mt_merge(input,filclip,momask,u=3,v=3)
repblend ? isyuy2(input) && VersionNumber() < 2.60 ? Interleaved2Planar() : isyuy2(input) ? converttoyv16() : last : last
repblend ? isyuy2(input) && VersionNumber() < 2.60 ? Repair(Repair(input.Interleaved2Planar(),16,Planar=true),12,Planar=true).Planar2Interleaved() : isyuy2(input) ? Repair(Repair(input.converttoyv16(),16),12).converttoyuy2() : Repair(Repair(input,16),12) : last
}


###############
#smam_mask
# if input is YUY2 the output will be Planar YUY2 in avs 2.5 and yv16 in avs 2.6

function smam_mask(clip input, clip "prefilter", int "pel", int "blksize", bool "chroma", int "dct") {
    ox = input.width()
    oy = input.height()
    HD = (ox > 1099 || oy > 599)
    sisbob  = round(framerate(input))==60 || framerate(input)==50
    pel = default( pel,     HD ? 1 : 2 )
    dct = default( dct, sisbob ? 0 : 2 )
    blksize = default(blksize,HD ? sisbob ? 8 : 16 : sisbob ? 4 : 8)
preclip= defined(prefilter) ? prefilter : (VersionNumber() < 2.60) && isyv12(input) ? input.HQdn3d().FFT3DFilter() : input.HQdn3d_2().FFT3DFilter()
sup    = preclip.MSuper(pel=pel,sharp=1)
fv1    = sup.MAnalyse(isb=false,delta=1,DCT=dct,Truemotion=false,blksize=blksize,chroma=chroma)
fv2    = sup.MAnalyse(isb=true,delta=1,DCT=dct,Truemotion=true,blksize=blksize,chroma=chroma)

momask1 = input.MMask(fv1, kind = 1, ml=2)
momask2 = input.MMask(fv2, kind = 1, ml=3)
momask1 =isyuy2(input) && VersionNumber() < 2.60 ? momask1.Interleaved2Planar() : isyuy2(input) ? momask1.converttoyv16() : momask1
momask2 =isyuy2(input) && VersionNumber() < 2.60 ? momask2.Interleaved2Planar() : isyuy2(input) ? momask2.converttoyv16() : momask2
mt_average(momask1,momask2,u=3,v=3)
}


##############
# sanimebob by A.SONY

function sanimebob(clip i, val "useqtgmc", val "bobpresmooth", float "Str", float "Amp", bool "TV_range", bool "qtgmc_lsb", bool "usedaa3mod", bool "usesmam", int "tr2", bool "repblend", val "dslow", bool "qtgmc_n16", bool "nnrep", bool "nnedi3pad") {

sisphbd = AvsPlusVersionNumber > 2294
qtgmc_lsb = default(qtgmc_lsb, sisphbd ? false : true)
qtgmc_n16 = default(qtgmc_n16, sisphbd ? i.BitsPerComponent() > 8 ? false : true : false)

useq                  = default (useqtgmc,                                                                                                           0)
Stringuseq        = IsString(useq                                                                                                                 )
bobpresmbool = default (isbool(bobpresmooth) ? bobpresmooth : !Stringuseq ? (useq==8 || defined(bobpresmooth)) : defined(bobpresmooth), false)
Str                     = default (Str,                                                                                                              1.5)
tr2                     = default (tr2,                                                                                !Stringuseq ? useq==8 ? 3 : 1 : 1)
usedaa3mod   = default (usedaa3mod,                                            !Stringuseq ? useq==4 || useq==5 || useq==7 || useq==9 : false)
usesmam        = default (usesmam,                                                       !Stringuseq ? !(useq==0 || useq==1 || useq==8) : false)
nnrep               = default (nnrep, false)
nnedi3pad       = default (nnedi3pad, false)

Assert(Isint(useq) || Stringuseq, "'useqtgmc' only accepts int or string")

prefiltered_i   = defined(bobpresmooth) ? isclip(bobpresmooth) ? bobpresmooth : IsString(bobpresmooth) ? Eval("i." + bobpresmooth) : undefined() : undefined()

nonyuy2=!(VersionNumber() < 2.6) && i.isyuy2()
iforbob   = bobpresmbool ? defined(prefiltered_i) ? prefiltered_i : i.QTGMC_bob(0,0.5).nonyuy2clipin(nonyuy2).reduceflicker(strength=2).nonyuy2clipout(nonyuy2).interlaced60or50(BFF=!(GetParity(i))) : i
iforbob   = bobpresmbool && !defined(prefiltered_i) ? isyuy2(i) ? iforbob.SeparateFields().Interleaved2Planar().Repair(i.SeparateFields().Interleaved2Planar(),Planar=true).Planar2Interleaved().weave() : iforbob.SeparateFields().Repair(i.SeparateFields()).weave() : iforbob

pyi       = i.Padding(0,4,0,4)
pni       = nnedi3pad ? iforbob.Padding(2,4,2,4).nnedi3(-2).crop(2,4,-2,-4,true) : iforbob.nnedi3(-2)
pei       = i.eedi3(-2,sclip=pni)
pei       = nnrep ? isyuy2(i) ? pei.Interleaved2Planar().Repair(pni.Interleaved2Planar(),9,Planar=true).Planar2Interleaved().Padding(0,4,0,4) : pei.Repair(pni,9).Padding(0,4,0,4) : pei.Padding(0,4,0,4)

ymodclip  = VersionNumber() < 2.60 ? pyi.yadifmod(mode=3, edeint=pei).crop(0,4,-0,-4) : pyi.nonyuy2clipin(nonyuy2).yadifmod2(mode=3, edeint=pei.nonyuy2clipin(nonyuy2)).crop(0,4,-0,-4)
yadifclip = isyuy2(i) && VersionNumber() < 2.60 ? ymodclip.Interleaved2Planar().Repair(i.TDeint(1,emask=iforbob.tmm2_ortmm1(1)).Interleaved2Planar(),Planar=true).Planar2Interleaved() : \
                                                  ymodclip.Repair(i.TDeint(1,emask=iforbob.tmm2_ortmm1(1)).nonyuy2clipin(nonyuy2)).nonyuy2clipout(nonyuy2)

# for custom qtgmc, don't forget to put the input clip like this:- iforbob.QTGMC(... or yadifclip.QTGMC(... or i.QTGMC(...
QTGMCclip = isstring(useq) ? eval(useq) : \
                             useq==0 ? yadifclip : \
       useq==1 || useq==2 || useq==4 ? iforbob.QTGMC(SourceMatch=3, Lossless=2, EdiExt=yadifclip, tr0=1, tr1=1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep0=11, rep1=11, rep2=11, Sharpness=0.1, TV_range=TV_range, Str=Str, Amp=Amp) : \
                  useq==3 || useq==5 ? yadifclip.QTGMC(InputType=1, tr0=1, tr1=1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep0=11, rep1=11, rep2=11, Sharpness=0.1, TV_range=TV_range, Str=Str, Amp=Amp) : \
                  useq==6 || useq==7 ? yadifclip.QTGMC(InputType=1, tr0=0, lsb=qtgmc_lsb, n16=qtgmc_n16, Sharpness=usedaa3mod ? 0.0 : 0.1, TV_range=TV_range, Str=Str, Amp=Amp) : \
                                       i.QTGMC(SourceMatch=3, Lossless=2, EdiExt=yadifclip, useEdiExt=!(useq==9), tr0=useq==9 ? -1 : undefined(), rep0=useq==9 ? undefined() : 11, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, Sharpness=0.0, TV_range=TV_range, Str=Str, Amp=Amp)

daa3mclip = usedaa3mod ? QTGMCclip.daa3mod(dslow) : QTGMCclip

!usesmam ? daa3mclip : \
           yadifclip.smam(filter=daa3mclip,repblend=repblend)
}


##############
# sypixsub 1.3, Subtracting one luma pixel with the neighboring pixel on the left or the top
Function sypixsub(clip clip, int "left", int "top", bool "expr")
{
left=Default(left, 1) #set the "left" to 2 will make it 2 pass since the subtract mode in overlay ignore the negative result of subtracting, set it to -1 and will show the negative result only
top=Default(top, 0) #same as "left" parameter
expr=Default(expr, true)
sisphbd = AvsPlusVersionNumber > 2294
expr=sisphbd ? expr : false

Assert(!(left>2 || left<-1 || top>2 || top<-1), "sypixsub: left and top modes must be between -1 to 2")
Assert(!(left==0 && top==0), "sypixsub: why you use sypixsub then?!!!!")

sislumaonly = sisphbd ? clip.isy() : VersionNumber() < 2.6 ? true : clip.isy8()
c= sislumaonly ? clip : sisphbd ? clip.converttoy() : clip.converttoy8()
lexp = left==-1 ? "x[-1,0] x -" : left==0 ? "" : "x x[-1,0] -" + string(left>1 ? " abs" : "")
texp = top==-1 ? " x[0,-1] x -" : top==0 ? "" : " x x[0,-1] -" + string(top>1 ? " abs" : "")
expr ? c.Expr(lexp + texp + (top != 0 && left != 0 ? " +" : "")) : eval("""
c
left != 0 ? PointResize(Width(), Height(), src_left=-1) : last
leftsub1 = left != 0 ? overlay(c,last,mode="Subtract") : last
leftsub2 = left == -1 || left > 1 ? overlay(last,c,mode="Subtract") : nop()
left > 1 ? overlay(leftsub1,leftsub2,mode="add") : left == -1 ? leftsub2 : leftsub1
h=last
top != 0 ? c : last
top != 0 ? PointResize(Width(), Height(), src_top=-1) : last
topsub1 = top != 0 ? overlay(c,last,mode="Subtract") : last
topsub2 = top == -1 || top > 1 ? overlay(last,c,mode="Subtract") : nop()
top > 1 ? overlay(topsub1,topsub2,mode="add") : top == -1 ? topsub2 : topsub1

top != 0 && left != 0 ? overlay(h,last,mode="add") : last
""")
sislumaonly ? last : sisphbd ? CombinePlanes(last,clip,planes="YUV",sample_clip=clip) : YToUV(clip.UToY8(),clip.VToY8(),last)
}