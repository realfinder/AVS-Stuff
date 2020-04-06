# Advanced Denoising and anime bob v1.87
# Collections of Functions

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
global sisphbdr = sisphbd
""") : nop()
fast ? white.ScriptClip("""
MotionThreshwhite = last
motinc = MotionThreshmotinc
cfr=current_frame
 
mtpav=cfr<3 ? 0 : mtcav
global mtcav=cfr<2 ? 0 : mtnav
mtnavb = sisphbdr ? BitsPerComponent() > 8 ? BitsPerComponent() == 10 ? 4 : BitsPerComponent() == 12 ? 8 : BitsPerComponent() == 14 ? 64 : nop() : nop() : nop()
global mtnav=sisphbdr ? isvideofloat() ? morinc.YDifferenceToNext()*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? morinc.YDifferenceToNext()/mtnavb : morinc.YDifferenceToNext()/256 : morinc.YDifferenceToNext() : morinc.YDifferenceToNext()
global mtnav=sisphbdr ? isvideofloat() ? motinc.trim(1,0).AverageLuma()*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? motinc.trim(1,0).AverageLuma()/mtnavb : sqrt(motinc.trim(1,0).AverageLuma()) : motinc.trim(1,0).AverageLuma() : motinc.trim(1,0).AverageLuma()

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
 
function MotionRamp(clip morinc, float thresh1, float thresh2, float thresh3, float thresh4, float thresh5, int "min", int "max", int "floor", int "ceil", int "radius", bool "tile", bool "fast", int "cache") {
min = Default(min, 0)
max = Default(max, 255)
floor = Default(floor, 0)
ceil  = Default(ceil, 255)
radius = Default(radius, 2)
fast = Default(fast, false)
tile = Default(tile,  fast)
cache= default(cache,10)

sisphbd = AvsPlusVersionNumber > 2294

morinc = morinc.killaudio()
 
sislumaonly = fast ? sisphbd ? morinc.isy() : morinc.isy8() : false

sisavs26 = !(VersionNumber() < 2.60)

sfas = fast && sisavs26
 
sfas && !sislumaonly ? sisphbd ? morinc.converttoy() : morinc.converttoy8() : morinc

fast ? eval("""
white = BlankClip(last, width=sfas ? 1 : 16, height=sfas ? 1 : 16, Color_yuv=color_white)
global MotionThreshblack = BlankClip(last, width=sfas ? 1 : 16, height=sfas ? 1 : 16, Color_yuv=color_black)
global MotionThreshthresh1 = thresh1
global MotionThreshthresh2 = thresh2
global MotionThreshthresh3 = thresh3
global MotionThreshthresh4 = thresh4
global MotionThreshthresh5 = thresh5
global MotionThreshmorinc = last
global mtnav=0
global sisavs26r = sisavs26
global sisphbdr = sisphbd
""") : last
fast ? white.ScriptClip("""
morinc = MotionThreshmorinc
MotionThreshwhite = last
cfr=current_frame
 
mtpav=cfr<1 ? 0 : mtnav
mtnavb = sisphbdr ? BitsPerComponent() > 8 ? BitsPerComponent() == 10 ? 4 : BitsPerComponent() == 12 ? 8 : BitsPerComponent() == 14 ? 64 : nop() : nop() : nop()
global mtnav=sisphbdr ? isvideofloat() ? morinc.YDifferenceToNext()*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? morinc.YDifferenceToNext()/mtnavb : morinc.YDifferenceToNext()/256 : morinc.YDifferenceToNext() : morinc.YDifferenceToNext()

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

!sisavs26r ? Interleave(c3, c2, c4, c1, c5).ParameterisedBlend(0.20, 0.20, 0.20, 0.20, 0.20, gamma=1, scaleweights=false).SelectEvery(5,0) : Average(c3, 0.20, c2, 0.20, c4, 0.20, c1, 0.20, c5, 0.20)
""") : !sisavs26 ? Interleave(MotionThresh(thresh3, tile=true), MotionThresh(thresh2, tile=true), MotionThresh(thresh4, tile=true), MotionThresh(thresh1, tile=true), MotionThresh(thresh5, tile=true)).ParameterisedBlend(0.20, 0.20, 0.20, 0.20, 0.20, gamma=1, scaleweights=false).SelectEvery(5,0) : \
                   Average(MotionThresh(thresh3, tile=true), 0.20, MotionThresh(thresh2, tile=true), 0.20, MotionThresh(thresh4, tile=true), 0.20, MotionThresh(thresh1, tile=true), 0.20, MotionThresh(thresh5, tile=true), 0.20)
fast ? cache<0 ? last : last.RequestLinear(8, cache, 5, false, false) : last
TemporalSoften(radius,255,0,255,2)
fast ? last : Levels(floor, 1, ceil, min, max)
fast ? last : ColorYUV(levels="TV->PC")
tile ? last : Eval("try { PointResizemt(morinc.width, morinc.height) } catch(error_msg) { PointResize(morinc.width, morinc.height) }")
}


##########
function admfilter(clip oin, bool "mc", float "f", bool "DarkPreserve", float "rStr", float "amp", bool "lsb", bool "lsb_in", bool "lsb_out", bool "luma_rebuild", bool "u", bool "v", string "pp", string "dfttest_params", string "mcdfttest_params", string "custom_filter", clip "MotionRampadc", bool "mcf", clip "ppsuper", clip "super", clip "exmcclip", bool "nlsb", bool "bthr") {
iscf = defined(custom_filter)
bthr = default (bthr      , true)
d = default (DarkPreserve      , true)
exmc = defined(exmcclip)
mc = default (mc      , !iscf)
sisphbd = AvsPlusVersionNumber > 2294
f = Default(f, 16.0)
sischbd = sisphbd ? oin.BitsPerComponent() > 8 : false
lsb = default (lsb, iscf ? false : sischbd ? false : true)
nlsb = default (nlsb, sisphbd && lsb)
lsb_in = default (lsb_in      , false)
u = default (u      , true)
v = default (v      , true)
mcf = default (mcf, sischbd || exmc || (nlsb && lsb_in))
oin8 = lsb_in ? oin.ditherpost(mode=7,slice=false,u=u ? 3 : 1,v=v ? 3 : 1) : oin
    ox = oin8.width()
    oy = oin8.height()
    HD = (ox > 1099 || oy > 599)
lsb_out = default (lsb_out      , lsb_in)
lsb = lsb_in || lsb_out ? true : lsb
luma_rebuild = default (luma_rebuild      , !iscf)
dfttest_params = default(dfttest_params, "")
mcdfttest_params = default(mcdfttest_params, "")
pp = default (pp, "oin8.blur(1.53)")

pel = HD ? 1 : 2

super = defined(super) ? super : mcf ? oin8.MSuper(pel=pel, levels=1, chroma=(U || V)) : nop()
ppsu = defined(ppsuper) ? ppsuper :  mcf ? oin.spp_super(pp=Eval(pp),rStr=rStr,amp=amp,lsb_in=lsb_in,lsb=lsb,luma_rebuild=luma_rebuild,u=u,v=v,hd=hd) : nop()
exmcclip = mcf ? exmc ? exmcclip : nlsb && lsb_in ? oin.ConvertFromStacked().sMCclips(ppsu,super.convertbits(16),hd=hd).ConvertToStacked() : oin8.sMCclips(ppsu,super,hd=hd) : exmcclip

custom_filter = defined(custom_filter) ? custom_filter : \
							mcf ? "dfttestmc(pp=oin8,lsb=lsb, Sigma=bthr ? (min(bthrvs,adSigma)+1.0)/f : (adSigma+1.0)/f,lsb_in=lsb_in,u=u,v=v,slices=false,super=super,input8=oin8,hd=hd,exmcclip=exmcclip,dfttest_params=dfttest_params" + mcdfttest_params + ")" : \
                                                         mc ? "dfttestmc(pp=Eval(pp),lsb=lsb, Sigma=bthr ? (min(bthrvs,adSigma)+1.0)/f : (adSigma+1.0)/f,rStr=rStr,amp=amp,lsb_in=lsb_in,luma_rebuild=luma_rebuild,u=u,v=v,dfttest_params=dfttest_params" + mcdfttest_params + ")" : \
                                                              "dfttest(lsb=lsb, Sigma=bthr ? (min(bthrvs,adSigma)+1.0)/f : (adSigma+1.0)/f, lsb_in=lsb_in,u=u,v=v" + dfttest_params + ")"

oin
MotionRampadc = defined(MotionRampadc) ? MotionRampadc : oin8.MotionRamp(5.0,10.0,15.0,20.0,25.0,Max=255,fast=True)
lsb_out && !lsb_in ? Dither_convert_8_to_16() : lsb_in && !lsb_out ? Ditherpost(mode=-1, y=1, u=1,v=1) : last
return GScriptClip("""
                     bthrv   = bthr ? AverageLuma() : nop()
                     adfloat = AverageLuma(MotionRampadc)
                     adSigmb = sisphbd ? BitsPerComponent() > 8 ? BitsPerComponent() == 10 ? 4 : BitsPerComponent() == 12 ? 8 : BitsPerComponent() == 14 ? 64 : nop() : nop() : nop()
                     adSigma = sisphbd ? isvideofloat() ? adfloat*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? adfloat/adSigmb : adfloat/256 : adfloat : adfloat
					 bthrvs  = bthr ? sisphbd ? isvideofloat() ? bthrv*255.0 : BitsPerComponent() > 8 ? BitsPerComponent() < 16 ? bthrv/adSigmb : bthrv/256 : bthrv : bthrv : nop()
                     (lsb_out && !lsb_in) || (lsb_in && !lsb_out) ? oin : last
                     adden = Eval(custom_filter)
                     d ? DarkPreserve_function(filtered=nlsb && lsb ? adden.ConvertFromStacked() : adden, original=nlsb && lsb_in ? last.ConvertFromStacked() : nlsb && lsb ? last.Convertbits(16) : last, u=u ? 3 : 4, v=v ? 3 : 4, lsb=lsb && !nlsb, lsb_in=lsb_in && !nlsb, lsb_out=lsb_out && !nlsb) : adden
                     d && lsb && nlsb ? ConvertToStacked() : last
                     d && lsb && nlsb && !lsb_out ? Ditherpost(mode=7, slice=false) : last
                     !d && !lsb_out && lsb ? Ditherpost(mode=7, slice=false) : last
                     """, args="MotionRampadc, f, d, rStr, amp, lsb_in, lsb_out, lsb, luma_rebuild, u, v,dfttest_params,mcdfttest_params,pp,oin,custom_filter,sisphbd,super,oin8,hd,exmcclip,nlsb,bthr")
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
bordertyp==0 ? sh_Padding(oneborder,oneborder,oneborder,oneborder) : AddBorders(oneborder,oneborder,oneborder,oneborder,bordertyp==1 ? undefined : bordertyp==2 ? color_white : bordertyp)
eval(filter)
Crop(oneborder, oneborder, -oneborder, -oneborder, align=true)
 
defined(linesm) ? mt_Merge(last, defined(clip4lines) ? clip4lines : src, minf,y=mmy,luma=mmLuma,u=mmuv,v=mmuv) : last
}


# filtering with black borders by A.SONY
Function filtering_wbb (clip src, string "filter", int "oneborder", clip "linesm", clip "clip4lines", int "mmy", bool "mmLuma", int "mmuv", bool "minflate")
{
filtering_wsb(src,filter,oneborder,linesm,clip4lines,mmy,mmLuma,mmuv,minflate)
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