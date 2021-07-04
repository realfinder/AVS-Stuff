# Shared Functions and utility
# V1.154

### Functions list:-
# sh_StrReplace
# sAverageLumaMask
# m4_sh
# sh_sharpen2
# sh_SootheSS
# slinesm
# t_linemask
# swlinesm 
# GreyCenteredToMask_dhh
# Camembert_dhh
# Camembert_dhhMod
# EMask_dhh
# spasses
# spasses2
# sspasses
# sminideen
# DarkPreserve_function
# lightPreserve_function
# sh_Padding
# sTryFTurnRight
# sTryFTurnLeft
# sTryFTurn180
# slimit_dif
# slimit_dif2
# sh_GetCSP
# sh_Y8_YV411
# ContraSharpening
# MinBlur
# sbr
# Dither_YUY2toPlanar16
# Dither_YUY2toPlanar
# Dither_YUY2toInterleaved16
# Dither_YUY2toInterleaved
# Dither_Luma_Rebuild 
# SH_KNLMeansCL 
# sh_RemoveGrain
# y_gamma_to_linear 
# y_linear_to_gamma 
# linear_and_gamma 
# build_sigmoid_expr 
# sigmoid_direct 
# sigmoid_inverse 
# sh_Vinverse2
# sbrV
# sh_Vinverse2H
# sbrH
# sBlackerPixel
# swhiterPixel
# chroma_rep
# chroma_rep2
# smartfademod
# ediaa
# daa
# maa
# SharpAAMCmod
# VinverseD
# smam
# smam_mask
# Hqdn3d_2
# interlaced60or50
# convert_Fields_scan_order
# yadifmodclipin
# yadifmodclipout
# tmm2_ortmm1
# nonyuy2clipin
# nonyuy2clipout
# sh_LimitChange
# sh_Bob
# sneo_FFT3D
# sneo_dfttest
# svsTTempSmooth
# svsTTempSmoothf
# svsMSharpen
# svsTBilateral
# svsTcanny
# sTcannyMod
# sh_GetUserGlobalIMT
# sh_GetUserGlobalIMTint
# sh_GetUserGlobalIMTbool
# sChromaShift2
# ChrEatWhite
# IsAvsNeo
# IsAvsPlus
# AvsPlusVersionNumber

#################################################

# Original:- By Vampiredom, Gavino, IanB
# Repeated, string replacements

Function sh_StrReplace(string s, string find, string replace)
{
 AvsPlusVersionNumber > 2958 ? ReplaceStr(s,find,replace) : eval("""i = s.FindStr(find) Chr(3) i ==0 || Replace=="" ? s : (s.LeftStr(i-1)+replace+s.MidStr(Strlen(find)+i)).sh_StrReplace(find, replace)""")
}


function sAverageLumaMask(clip src) {
sisavs26 = !(VersionNumber() < 2.60)
src = AvsPlusVersionNumber > 2294 ? src.isvideofloat ? src.Limiter(0,1) : src : src
sisavs26 ? src.ScriptClip("""mt_lut(Y=-AverageLuma,paramscale="none")""") : src.ScriptClip("""mt_lut(Y=-round(AverageLuma))""")
}


# =======  MOD4-and-atleast-16 helper function  =======

function m4_sh(float x, int "mode") {
mode  = default(mode,  0 ) #0=any 1=NTSC 2=PAL/Force Original Behavior
nx = mode!=0 || VersionNumber() < 2.6 ? x<16?16:int(round(x/(mode!=1 ? 4.0 : 5.0))*(mode!=1 ? 4 : 12)) : round(x)
return(nx)
}


# =======  Modified sharpening function  =======

function sh_sharpen2(clip clp, float strength, float power, float zp, float lodmp, float hidmp, int rgmode, bool "sharpen22") 
{
sisavs26= !(VersionNumber() < 2.60)
STR  = string( strength )
PWR  = string( 1.0/float(power) )
ZRP  = string(    ZP    )
DMP  = string(   lodmp  )
HDMP = (hidmp==0) ? "1" : sisavs26 ? "1 scalef x y - abs "+string(hidmp)+" / 4 ^ +" : "1 x y - abs "+string(hidmp)+" / 4 ^ +"
sharpen22 = default(sharpen22, false )
!sharpen22 ? Assert(power>0,"SeeSaw::sh_sharpen2: Power must be value 1 or more") : nop()

sisavs26 ? mt_lutxy( clp, clp.RemoveGrain(rgmode,-1,-1), \
           "x y == x x x y - abs "+ZRP+" / "+PWR+" ^ "+ZRP+" * "+STR+" * x y - 2 ^ x y - 2 ^ "+DMP+" scalef + / * x y - x y - abs / * "+HDMP+" / + ?",chroma="copy first",use_expr=1) : \
mt_lutxy( clp, clp.RemoveGrain(rgmode,-1,-1), \
           "x y == x x x y - abs "+ZRP+" / "+PWR+" ^ "+ZRP+" * "+STR+" * x y - 2 ^ x y - 2 ^ "+DMP+" + / * x y - x y - abs / * "+HDMP+" / + ?",chroma="copy first")
return( last )
}


# =======  Soothe() function to stabilze sharpening  =======

function sh_SootheSS(clip sharp, clip orig, int "sootheT", int "sootheS", bool "SootheSS2", int "uv")
{
sisavs26   = !(VersionNumber() < 2.60)
sootheT  = default(sootheT, 25 )
sootheS  = default(sootheS,  0 )
sootheT  = (sootheT > 100) ? 100 : (sootheT < -100) ? -100 : sootheT
sootheS  = (sootheS > 100) ? 100 : (sootheS < 0) ? 0 : sootheS
ST    = string( 100 - abs(sootheT))
SSPT  = string( 100 - abs(sootheS))
SootheSS2 = default(SootheSS2, false)

mt_makediff(orig,sharp)

(sootheS==0) ? last
 \           : sisavs26 ? mt_lutxy( last, last.removegrain(SootheSS2 ? 1 : 20,-1,-1),
 \             "x range_half - y range_half - * 0 < x range_half - 100 / "+SSPT+" * range_half + x range_half - abs y range_half - abs > x "+SSPT+" * y 100 "+SSPT+" - * + 100 / x ? ?", chroma="ignore",use_expr=1) : \
mt_lutxy( last, last.removegrain(SootheSS2 ? 1 : 20,-1,-1),
 \             "x 128 - y 128 - * 0 < x 128 - 100 / "+SSPT+" * 128 + x 128 - abs y 128 - abs > x "+SSPT+" * y 100 "+SSPT+" - * + 100 / x ? ?", chroma="ignore")
 
(sootheT==0) ? last
 \           : sisavs26 ? mt_lutxy( last, last.temporalsoften(1,255,0,32,2),
 \           "x range_half - y range_half - * 0 < x range_half - 100 / "+ST+" * range_half + x range_half - abs y range_half - abs > x "+ST+" * y 100 "+ST+" - * + 100 / x ? ?", chroma="ignore",use_expr=1) : \
mt_lutxy( last, last.temporalsoften(1,255,0,32,2),
 \           "x 128 - y 128 - * 0 < x 128 - 100 / "+ST+" * 128 + x 128 - abs y 128 - abs > x "+ST+" * y 100 "+ST+" - * + 100 / x ? ?", chroma="ignore")

(sootheT > -1) ? last 
 \             : sisavs26 ? mt_lutxy( last, last.temporalsoften(1,255,0,32,2),
 \             "x range_half - y range_half - * 0 < x range_half - 100 / "+ST+" * range_half + x range_half - abs y range_half - abs > x "+ST+" * y 100 "+ST+" - * + 100 / x ? ?",chroma="ignore",use_expr=1) : \
mt_lutxy( last, last.temporalsoften(1,255,0,32,2),
 \             "x 128 - y 128 - * 0 < x 128 - 100 / "+ST+" * 128 + x 128 - abs y 128 - abs > x "+ST+" * y 100 "+ST+" - * + 100 / x ? ?",chroma="ignore")

mt_makediff(orig,last,u=uv,v=uv)
return( last )
}


# black lines mask by A.SONY
Function slinesm (clip i, float "thr", float "thr2", bool "analog", bool "autogain", val "edgesm", int "useMedianBlur", bool "noedges", float "mblur", float "thrfade", bool "honly", bool "lumaonly")
{
analog        = Default(analog,   true)
autogain      = Default(autogain, true)
noedges       = Default(noedges,  false)
mblur         = Default(mblur, 0.1)
thr           = Default(thr, mblur==0 ? 100 : 200)
thr2          = Default(thr2, 170)
thrfade       = Default(thrfade, 2.46)
useMedianBlur = default(useMedianBlur, -1)
lumaonly      = default(lumaonly, true)

sisavs26 = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294

oi          = autogain ? i.ColorYUV(autogain=true) : i
sislumaonly = sisphbd ? oi.isy() : !sisavs26 ? true : oi.isy8()
i = sislumaonly || !lumaonly ? oi : sisphbd ? oi.converttoy() : oi.converttoy8()

edgesm     = !noedges ? defined(edgesm) ? isclip(edgesm) ? edgesm : eval("i." + edgesm) : i.Camembert_dhh(useMedianBlur,honly,lumaonly) : nop()

edgesm     = !noedges ? defined(edgesm) ? isclip(edgesm) ? edgesm : eval("i." + edgesm) : i.Camembert_dhh(useMedianBlur) : nop()

LineDarkenclip = thr==0 ? nop() : mblur==0 ? i.FastLineDarkenMOD3_dhh(thr) : i.FastLineDarkenMOD3_dhh(thr).blur(mblur)
LineDarkenclip = thr==0 ? i : LineDarkenclip.FastLineDarkenMOD3_dhh(250,1,250,-2)

thr1 = analog ? thr2/thrfade : nop()
lut4dark   = analog ? !sisavs26 ? LineDarkenclip.mt_lut("x "+String(thr1)+" < 255 x "+String(thr2)+" > 0 255 x "+String(thr1)+" - 255 "+String(thr2)+" "+String(thr1)+" - / * - ? ?",u=1,v=1) : LineDarkenclip.mt_lut("x "+String(thr1)+" scalef < range_max x "+String(thr2)+" scalef > 0 range_max x "+String(thr1)+" scalef - range_max "+String(thr2)+" scalef "+String(thr1)+" scalef - / * - ? ?", use_expr=2,u=1,v=1) : 
                    \ LineDarkenclip.mt_binarize(70, mode="0 255")

noedges ? lut4dark : 
        \ mt_merge(i.mt_edge(mode="min/max", thY1=255, thY2=255), edgesm, lut4dark)
sislumaonly ? last : sisphbd ? CombinePlanes(last,oi,planes="YUV",sample_clip=oi) : YToUV(oi.UToY8(),oi.VToY8(),last)
}


# tophf lines mask
function t_linemask( clip clp, int "blur", float "thresh", float "str" )
{
	sisavs26 = !(VersionNumber() < 2.6)
	sisphbd = AvsPlusVersionNumber > 2294
	sislumaonly = sisphbd ? clp.isy() : sisavs26 ? clp.isy8() : true
c = sislumaonly ? clp : sisphbd ? clp.converttoy() : clp.converttoy8()
	blur=default(blur,5)
	thresh=default(thresh,4)
	str=default(str,16)
	!sisavs26 ? mt_lutxy(c,c.binomialblur(blur,u=1,v=1),"x "+string(thresh)+" + y < y x - "+string(str)+" * 0 ?")
        \                     : mt_lutxy(c,c.FastBlur(sqrt(blur),iterations=2,gamma=false,threads=1),"x "+string(thresh)+" scalef + y < y x - "+string(str)+" * 0 ?", clamp_float=true, use_expr=2)
sislumaonly ? last : sisphbd ? CombinePlanes(last,clp,planes="YUV",sample_clip=clp) : ytouv(clp.utoy8(),clp.vtoy8(),last)
}


# white lines mask by A.SONY
Function swlinesm (clip i, float "thr", float "thr2", bool "analog", bool "autogain", val "edgesm", int "useMedianBlur", bool "noedges", float "mblur", float "thrfade", float "bthr", bool "honly", bool "lumaonly")
{
analog        = Default(analog,   true)
autogain      = Default(autogain, true)
noedges       = Default(noedges,  false)
mblur         = Default(mblur, 0.1)
thr           = Default(thr, mblur==0 ? 100 : 200)
bthr          = Default(bthr, thr)
thr2          = Default(thr2, 200)
thrfade       = Default(thrfade, 2.46)
useMedianBlur = default(useMedianBlur, -1)
lumaonly      = default(lumaonly, true)

sisavs26 = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294

oi          = autogain ? i.ColorYUV(autogain=true) : i
sislumaonly = sisphbd ? oi.isy() : !sisavs26 ? true : oi.isy8()
i = sislumaonly || !lumaonly ? oi : sisphbd ? oi.converttoy() : oi.converttoy8()

edgesm     = !noedges ? defined(edgesm) ? isclip(edgesm) ? edgesm : eval("i." + edgesm) : i.Camembert_dhh(useMedianBlur,honly,lumaonly) : nop()

LineDarkenclip = bthr==0 ? i : mblur==0 ? i.FastLineDarkenMOD3_dhh(bthr) : i.FastLineDarkenMOD3_dhh(bthr).blur(mblur)
Linewhitenclip = thr==0 ? nop() : mblur==0 ? LineDarkenclip.mt_invert().FastLineDarkenMOD3_dhh(thr) : LineDarkenclip.mt_invert().FastLineDarkenMOD3_dhh(thr).blur(mblur)
Linewhitenclip = thr==0 ? i : Linewhitenclip.FastLineDarkenMOD3_dhh(250,1,250,-2).mt_invert()

thr1 = analog ? thr2/thrfade : nop()
lut4whit   = analog ? !sisavs26 ? Linewhitenclip.mt_lut("x "+String(thr2)+" > 255 x "+String(thr1)+" < 0 255 x "+String(thr1)+" - 255 "+String(thr2)+" "+String(thr1)+" - / * - ? ?",u=1,v=1) : Linewhitenclip.mt_lut("x "+String(thr2)+" scalef > range_max x "+String(thr1)+" scalef < 0 range_max x "+String(thr1)+" scalef - range_max "+String(thr2)+" scalef "+String(thr1)+" scalef - / * - ? ?",use_expr=2,u=1,v=1) : 
                    \ Linewhitenclip.mt_binarize(128, mode="255 0")

noedges ? lut4whit : 
        \ mt_merge(i.mt_edge(mode="min/max", thY1=255, thY2=255), edgesm, lut4whit)
sislumaonly ? last : sisphbd ? CombinePlanes(last,oi,planes="YUV",sample_clip=oi) : YToUV(oi.UToY8(),oi.VToY8(),last)
}


function GreyCenteredToMask_dhh(clip input) {
# Levels will convert to lut in avs26 by this "x input_low - input_high input_low - / 1 gamma / ^ output_high output_low - * output_low +"
VersionNumber() < 2.6 ? input.Levels(128, 1, 255, 0, 255, false) : input.mt_lut("x range_half - range_max range_half - / range_max *", use_expr=2)
one = last
VersionNumber() < 2.6 ? input.Levels(0, 1, 128, 255, 0, false) : input.mt_lut("x range_half / 0 range_max - * range_max +", use_expr=2)
two = last
Overlay(one, two, mode="lighten")
}


function Camembert_dhh(clip input, int "useMedianBlur", bool "honly", bool "lumaonly") {

lumaonly = default(lumaonly, false)
useMedianBlur = default(useMedianBlur, lumaonly ? -1 : 0)
honly = default(honly, false)

sisphbd = AvsPlusVersionNumber > 2294
sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : !sisavs26 ? true : input.isy8()

useMedianBlur = sislumaonly && !(VersionNumber() < 2.6) ? -1 : useMedianBlur

c = sislumaonly || !lumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

c
useMedianBlur==0 ? SmoothUV(3,200,false) : useMedianBlur>0 ? MedianBlur(0,useMedianBlur,useMedianBlur) : last
Overlay(last, Blur(1,honly ? 0 : 1).Blur(1,honly ? 0 : 1), mode="difference")
grsc=sislumaonly ? nop() : GreyCenteredToMask_dhh().greyscale()
sislumaonly ? GreyCenteredToMask_dhh() : sisphbd ? grsc.converttoy() : grsc.converttoy8()
!sisavs26 ? greyscale() : last
!sisavs26 ? Levels(0, 1, 115, 0, 255, false) : mt_lut("x 115 scaleb / range_max *", use_expr=2)
Blur(1,honly ? 0 : 1)
!sisavs26 ? Levels(0, 0.4, 64, 0, 255, false) : mt_lut("x 64 scaleb / 1 0.4 / ^ range_max *", use_expr=2)
Blur(1,honly ? 0 : 1).Blur(1,honly ? 0 : 1)
!sisavs26 ? Levels(0, 1, 30, 0, 255, false).Blur(1,honly ? 0 : 1) : mt_lut("x 30 scaleb / range_max *", use_expr=2,u=3,v=3).Blur(1,honly ? 0 : 1)
sislumaonly ? last : sisphbd ? CombinePlanes(last,lumaonly ? input : grsc,planes="YUV",sample_clip=lumaonly ? input : grsc) : YToUV(lumaonly ? input.UToY8() : grsc.UToY8(),lumaonly ? input.VToY8() : grsc.VToY8(),last)
}


function Camembert_dhhMod(clip input, int "useMedianBlur", bool "honly", bool "lumaonly")
{
 EM1=input.Camembert_dhh(useMedianBlur,honly,lumaonly)
 EM2=input.mt_edge(mode="min/max", thY1=1, thY2=255, thC1=10, thC2=10, chroma="process").mt_inflate().blur(1.5).blur(1.5).invert()
 return mt_logic(EM1, EM2, "and")
}


Function EMask_dhh(clip oi, int "mode", float "trh", bool "analog", float "trh2", int "useMedianBlur", bool "honly", bool "lumaonly")
{
analog        = Default(analog, false)
trh2          = Default(trh2, 170)
lumaonly      = default(lumaonly, false)
useMedianBlur = default(useMedianBlur, lumaonly ? -1 : 0)
honly         = default(honly, false)

sisphbd = AvsPlusVersionNumber > 2294
sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? oi.isy() : !sisavs26 ? true : oi.isy8()

i = sislumaonly || !lumaonly ? oi : sisphbd ? oi.converttoy() : oi.converttoy8()

mode3thr1     = mode == 3 && analog ? trh2/2.46 : nop()
mode3dark     = mode == 3 ? trh != 0 ? i.FastLineDarkenMOD3_dhh(trh).blur(0.5).FastLineDarkenMOD3_dhh(250,1,250,-2) : i : nop()
mode3lut      = mode == 3 && analog ? !sisavs26 ? "x "+String(mode3thr1)+" < 255 x "+String(trh2)+" > 0 255 x "+String(mode3thr1)+" - 255 "+String(trh2)+" "+String(mode3thr1)+" - / * - ? ?"
                                      \                     : "x "+String(mode3thr1)+" scalef < range_max x "+String(trh2)+" scalef > 0 range_max x "+String(mode3thr1)+" scalef - range_max "+String(trh2)+" scalef "+String(mode3thr1)+" scalef - / * - ? ?" : nop()
e_mask = mode == 1 ? mt_makediff(i.blur(1.58).blur(1.58),i).mt_binarize(threshold=trh).mt_inflate().mt_inflate() :
     \   mode == 2 ? mt_logic(i.mt_binarize(105,upper=true).mt_expand(),i.mt_binarize(110,upper=false).mt_expand(),"and").mt_deflate() :
     \   mode == 3 ? analog ? mt_merge(i.mt_edge(mode="min/max", thY1=255, thY2=255), i.Camembert_dhh(useMedianBlur,honly,lumaonly), !sisavs26 ? mode3dark.mt_lut(mode3lut,u=1,v=1) : mode3dark.mt_lut(mode3lut,use_expr=2,u=1,v=1)) :
                            \ mt_merge(i.mt_edge(mode="min/max", thY1=255, thY2=255), i.Camembert_dhh(useMedianBlur,honly,lumaonly), mode3dark.mt_binarize(70, mode="0 255")) : NOP()
e_mask = sislumaonly ? e_mask : sisphbd ? CombinePlanes(e_mask,oi,planes="YUV",sample_clip=oi) : YToUV(oi.UToY8(),oi.VToY8(),e_mask)
return e_mask
}


Function spasses(clip i, int "pass", string "filter")
{
return pass > 0 ? eval("spasses(i." + filter + ", pass-1, filter)") : i
}

Function spasses2(clip i, int "pass", string "filter", clip "fclip2")
{
Assert(defined(fclip2), "spasses2: fclip2 clip is needed")
return pass > 0 ? eval("spasses2(" + filter + ", pass-1, filter, fclip2)") : i
}

Function sspasses(string i, int "pass", string "add")
{
return pass > 0 ? sspasses(i + add, pass-1, add) : i
}


Function sminideen(clip input, int "radius", int "thrY", int "thrUV", int "Y", int "U", int "V")
{
try { input.minideen(radius=radius, thrY=thrY, thrUV=thrUV, Y=Y, U=U, V=V) } catch(error_msg) { input.deen("a2d", radius, thrY, thrUV)  }
}


function DarkPreserve_function(clip "filtered", clip "original", bool "merge16_8", int "u", int "v", bool "lsb", bool "lsb_in", bool "lsb_out") {
lsb_in    = default (lsb_in                       , false) #for original
F_lsb_in  = lsb_in ? (Height(filtered)) == (Height(original)) : (Height(filtered)) == (Height(original)*2)
lsb_out   = default (lsb_out         , F_lsb_in || lsb_in)
lsb       = default (lsb ,  lsb_in || lsb_out || F_lsb_in)
merge16_8 = default (merge16_8                     , true)
sisphbd = AvsPlusVersionNumber > 2294
sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? original.isy() : !sisavs26 ? nop() : original.isy8()
u         = default (u                                , !sisavs26 ? 3 : sislumaonly ? 1 : 3)
v         = default (v                                , u)
chroma    = !(u != 3 && v != 3)

F_lsb_in        ? Assert(lsb,                          "16stacked filtered clip requires: lsb=true")                : nop()
lsb_in          ? Assert(lsb,                          "lsb_in  requires: lsb=true")                                : nop()
lsb_out         ? Assert(lsb,                          "lsb_out requires: lsb=true")                                : nop()

dp_lut = lsb_in ? original.Dither_lut16("x 4096 < 65535 x 19200 > 0 65535 x 4096 - 4.338916843220339 * - ? ?",u=1,v=1) : !sisavs26 ? original.mt_lut("x 16 < 255 x 75 > 0 255 x 16 - 4.322033898305085 * - ? ?",u=1,v=1)
         														 \	   : original.mt_lut("x 16 scaleb < range_max x 75 scaleb > 0 range_max x 16 scaleb - range_max 75 scaleb 16 scaleb - / * - ? ?",use_expr=2,u=1,v=1)

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
sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? original.isy() : !sisavs26 ? nop() : original.isy8()
u         = default (u                                , !sisavs26 ? 3 : sislumaonly ? 1 : 3)
v         = default (v                                , u)
chroma    = !(u != 3 && v != 3)

F_lsb_in        ? Assert(lsb,                          "16stacked filtered clip requires: lsb=true")                : nop()
lsb_in          ? Assert(lsb,                          "lsb_in  requires: lsb=true")                                : nop()
lsb_out         ? Assert(lsb,                          "lsb_out requires: lsb=true")                                : nop()

dp_lut = lsb_in ? original.Dither_lut16("x 60160 > 65535 x 45056 < 0 65535 60160 x - 4.338916843220339 * - ? ?",u=1,v=1) : !sisavs26 ? original.mt_lut("x 235 > 255 x 176 < 0 255 235 x - 4.322033898305085 * - ? ?",u=1,v=1)
         														   \		         : original.mt_lut("x 235 scaleb > range_max x 176 scaleb < 0 range_max x 235 scaleb - range_max 176 scaleb 235 scaleb - / * - ? ?",use_expr=2,u=1,v=1)

dp_lut = lsb_in && merge16_8 ? dp_lut.Ditherpost(mode=6, slice=false, u=1, v=1) : dp_lut

dp_merge = lsb ? merge16_8 ? Dither_merge16_8(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             Dither_merge16(F_lsb_in ? filtered : filtered.Dither_convert_8_to_16(), lsb_in ? original : original.Dither_convert_8_to_16(), dp_lut, luma=chroma, u=u,v=v) : \
                             mt_merge(filtered, original, dp_lut, luma=chroma, u=u,v=v)
lsb ? lsb_out ? dp_merge : dp_merge.Ditherpost(mode=7, slice=false) : dp_merge
}


# Padding by Didée
function sh_Padding(clip c, int left, int top, int right, int bottom, int "threads")
{
threads = Default(threads, sh_GetUserGlobalIMTint(true))
w = c.width()
h = c.height()
threads!=1 ? Eval("try { pointresizemt(w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001, threads=threads) } catch(error_msg) { c.pointresize( w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001 ) }") : c.pointresize( w+left+right, h+top+bottom, -left, -top, w+left+right, h+top+bottom+0.0001 )
}


function sTryFTurnRight(clip c, bool "chroma", int "bitdepth", bool "mt") {
bitdepth=Default(bitdepth, 8)
mt = sh_GetUserGlobalIMTbool
bitdepth==8 ? eval("""
try {
    IsAvsPlus ? dontdoft : nop()
    return c.FTurnRight(chroma=chroma,mt=mt)
    }
catch(err_msg) {
    return c.TurnRight()
    }
    """) : BitdepthMsbLsb(c.BitdepthMsb(bitdepth=bitdepth).sTryFTurnRight(chroma,mt=mt), c.BitdepthLsb(bitdepth=bitdepth).sTryFTurnRight(chroma,mt=mt), bitdepth=bitdepth)
}


function sTryFTurnLeft(clip c, bool "chroma", int "bitdepth", bool "mt") {
bitdepth=Default(bitdepth, 8)
mt = sh_GetUserGlobalIMTbool
bitdepth==8 ? eval("""
try {
    IsAvsPlus ? dontdoft : nop()
    return c.FTurnLeft(chroma=chroma,mt=mt)
    }
catch(err_msg) {
    return c.TurnLeft()
    }
    """) : BitdepthMsbLsb(c.BitdepthMsb(bitdepth=bitdepth).sTryFTurnLeft(chroma,mt=mt), c.BitdepthLsb(bitdepth=bitdepth).sTryFTurnLeft(chroma,mt=mt), bitdepth=bitdepth)
}


function sTryFTurn180(clip c, bool "chroma", int "bitdepth", bool "mt") {
bitdepth=Default(bitdepth, 8)
mt = sh_GetUserGlobalIMTbool
bitdepth==8 ? eval("""
try {
    IsAvsPlus ? dontdoft : nop()
    return c.FTurn180(chroma=chroma,mt=mt)
    }
catch(err_msg) {
    return c.Turn180()
    }
    """) : BitdepthMsbLsb(c.BitdepthMsb(bitdepth=bitdepth).sTryFTurn180(chroma,mt=mt), c.BitdepthLsb(bitdepth=bitdepth).sTryFTurn180(chroma,mt=mt), bitdepth=bitdepth)
}


# base on Dither_limit_dif16 and vs LimitFilter
function slimit_dif(clip "flt", clip "src", clip "ref", float "thr", float "elast", float "brighten_thr", float "thrc", int "Y", int "U", int "V", int "A")
{
thr    = default(thr,                 0.25)
thrc   = default(thrc,                 thr)
elast  = default(elast,                3.0)
bthr   = default(brighten_thr,         thr)
Y  = default(Y,           3)
U  = default(U,           3)
V  = default(V,           3)
celast = U == 3 || V == 3 ? elast * thrc : nop()
A  = default(A,           2)

dref = defined(ref)
sisavs26 = !(VersionNumber() < 2.6)
 
Assert(!(elast < 1), "slimit_dif: elast must be more than 1")
Assert((defined(flt) && defined(src)), "slimit_dif: both flt clip and src clip are needed")
 
output = dref ? !sisavs26 ? mt_lutxyz(src,flt,ref, "y z - abs "+string(thrc)+" <= y y z - abs "+string(celast)+" >= x x y x - "+string(celast)+" y z - abs - * "+string(celast)+" "+string(thrc)+" - / + ? ?", \
					                               "y z - abs y x - 0 > "+string(bthr)+" "+string(thr)+" ? <= y y z - abs y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * >= x x y x - y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * y z - abs - * y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * y x - 0 > "+string(brighten_thr)+" "+string(thr)+" ? - / + ? ?", Y=Y,U=U,V=V)
                \         : mt_lutxyz(src,flt,ref, "y z - abs "+string(thrc)+" yscalef <= y y z - abs "+string(celast)+" yscalef >= x x y x - "+string(celast)+" yscalef y z - abs - * "+string(celast)+" yscalef "+string(thrc)+" yscalef - / + ? ?", \
					                               "y z - abs y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? <= y y z - abs y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * >= x x y x - y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * y z - abs - * y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? - / + ? ?",clamp_float_UV=false,use_expr=1,Y=Y,U=U,V=V,A=A) 
         \    : nop()
!dref ? !sisavs26 ? mt_lutxy(src,flt, "y x - abs "+string(thrc)+" <= y y x - abs "+string(celast)+" >= x x y x - "+string(celast)+" y x - abs - * "+string(celast)+" "+string(thrc)+" - / + ? ?", \
					                  "y x - abs y x - 0 > "+string(bthr)+" "+string(thr)+" ? <= y y x - abs y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * >= x x y x - y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * y x - abs - * y x - 0 > "+string(bthr)+" "+string(thr)+" ? "+string(elast)+" * y x - 0 > "+string(bthr)+" "+string(thr)+" ? - / + ? ?", Y=Y,U=U,V=V)
        \         : mt_lutxy(src,flt, "y x - abs "+string(thrc)+" yscalef <= y y x - abs "+string(celast)+" yscalef >= x x y x - "+string(celast)+" yscalef y x - abs - * "+string(celast)+" yscalef "+string(thrc)+" yscalef - / + ? ?", \
					                  "y x - abs y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? <= y y x - abs y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * >= x x y x - y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * y x - abs - * y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? "+string(elast)+" * y x - 0 > "+string(bthr)+" scalef "+string(thr)+" scalef ? - / + ? ?",clamp_float_UV=false,use_expr=2,Y=Y,U=U,V=V,A=A)
  \   : output
}


# base on Dither_limit_dif16 idea (not 100% same output)
function slimit_dif2(clip "flt", clip "src", clip "ref", float "thr", float "elast", int "Y", int "U", int "V", bool "elastinfl", int "A")
{
thr    = default(thr,                 0.25)
elast  = default(elast,                3.0)
elast2  = elast > 1.0 ? elast * thr : elast
Y  = default(Y,           3)
U  = default(U,           3)
V  = default(V,           3)
elastinfl = default(elastinfl, false)
A  = default(A,           2)

dref = defined(ref)
sisavs26 = !(VersionNumber() < 2.6)
 
Assert(!(elast < 1), "slimit_dif2: elast must be more than 1")
Assert((defined(flt) && defined(src)), "slimit_dif2: both flt clip and src clip are needed")
 
ldmask = elast!=1 ? !sisavs26 ? mt_lutxy(dref ? ref : src,flt,"x y - abs "+string(thr)+" <= 255 x y - abs "+string(elast2)+" <= ? 255 255 "+string(elast2)+" / x y - abs * - 0 ?", Y=Y==2 ? 1: Y,U=U==2 ? 1 : U,V=V==2 ? 1 : V)
                    \         : mt_lutxy(dref ? ref : src,flt,"x y - abs "+string(thr)+" yscalef <= yrange_max x y - abs "+string(elast2)+" yscalef <= ? yrange_max yrange_max "+string(elast2)+" yscalef / x y - abs * - 0 ?",use_expr=2, Y=Y==2 ? 1: Y,U=U==2 ? 1 : U,V=V==2 ? 1 : V,A=A==2 ? 1 : A) : 
         \   dref ? !sisavs26 ? ref.mt_lutxy(flt,"x y - abs "+string(thr)+" <= 255 0 ?", Y=Y==2 ? 1: Y,U=U==2 ? 1 : U,V=V==2 ? 1 : V) : ref.mt_lutxy(flt,"x y - abs "+string(thr)+" yscalef <= yrange_max 0 ?",use_expr=2,clamp_float_UV=true, Y=Y==2 ? 1: Y,U=U==2 ? 1 : U,V=V==2 ? 1 : V,A=A==2 ? 1 : A) : nop()

elast!=1 || dref ? !sisavs26 ? smaskmerge(src,flt, elastinfl ? ldmask.mt_inflate(155,Y=Y,U=U,V=V) : ldmask, Y=Y,U=U,V=V) : Mt_Merge(src,flt, elastinfl ? ldmask.mt_inflate(155,Y=Y,U=U,V=V,A=A) : ldmask, Y=Y,U=U,V=V,A=A) : \
                   !sisavs26 ? src.mt_lutxy(flt,"x y - abs "+string(thr)+" <= y x ?", Y=Y,U=U,V=V)
                   \         : src.mt_lutxy(flt,"x y - abs "+string(thr)+" yscalef <= y x ?",use_expr=2,clamp_float_UV=false, Y=Y,U=U,V=V,A=A)
}


Function sh_GetCSP(clip c) {
    VersionNumber() < 2.6 ? eval("""
  return c.IsPlanar ? c.IsYV12 ? "YV12" :
  \                   c.IsYV16 ? "YV16" :
  \                   c.IsYV24 ? "YV24" : c.sh_Y8_YV411 :
  \      c.IsYUY2   ? "YUY2"   :
  \      c.IsRGB32  ? "RGB32"  :
  \      c.IsRGB24  ? "RGB24"  : "Unknown"
    """) : c.PixelType()
}


Function sh_Y8_YV411(clip c) {
  try {
    c.UtoY
    csp = "YV411"
  } catch ( error_msg ) {
    csp = "Y8"
  }
  return csp
}


########################################################
#                                                      #
# HELPER FUNCTIONS: For Contrasharp and YUY2 handling  #
#                                                      #
########################################################

########################################
## Didée's functions:

 # contra-sharpening: sharpen the denoised clip, but don't add more to any pixel than what was removed previously.
 # script function from Didée, at the VERY GRAINY thread

 # ContraSharpeningHD formerly, HD parameter renamed to MC, and function renamed to ContraSharpening

FUNCTION ContraSharpening(clip denoised, clip original, bool "MC", bool "planar", int "overshoot", clip "cb1", clip "cf1", clip "Super"){
HD        = default(MC    ,false)
planar    = default(planar,false)
overshoot = default(overshoot,0)
avs26 = VersionNumber() < 2.60 ? false : true
yuy26 = avs26 && Isyuy2(denoised) && planar

HD ? eval("""
Super=defined(Super) ? Super : original.MSuper(chroma=false, planar=planar)
cb1=defined(cb1) ? cb1 : Super.MAnalyse(isb = true,  delta = 1, overlap= 4)
cf1=defined(cf1) ? cf1 : Super.MAnalyse(isb = false, delta = 1, overlap= 4)
cb1=original.MCompensate(Super, cb1, planar=planar)
cf1=original.MCompensate(Super, cf1, planar=planar)
pmax = !yuy26 ? original.mt_logic(cb1, "max").mt_logic(cf1, "max") : original.Planar2Interleaved().ConvertToYV16().mt_logic(cb1.Planar2Interleaved().ConvertToYV16(), "max").mt_logic(cf1.Planar2Interleaved().ConvertToYV16(), "max")
pmin = !yuy26 ? original.mt_logic(cb1, "min").mt_logic(cf1, "min") : original.Planar2Interleaved().ConvertToYV16().mt_logic(cb1.Planar2Interleaved().ConvertToYV16(), "min").mt_logic(cf1.Planar2Interleaved().ConvertToYV16(), "min")
          """) : nop()

s    = denoised.MinBlur(HD?2:1,1,planar=planar)                                   # Damp down remaining spots of the denoised clip.
s    = yuy26 ? s.Planar2Interleaved().ConvertToYV16() : s
original = yuy26 ? original.Planar2Interleaved().ConvertToYV16() : original
denoised = yuy26 ? denoised.Planar2Interleaved().ConvertToYV16() : denoised
allD = mt_makediff(original,denoised)                                             # The difference achieved by the denoising.
ssD  = mt_makediff(s,HD?s.removegrain(20,-1,planar=planar).\
                          removegrain(20,-1,planar=planar):\
                        s.removegrain(11,-1,planar=planar))                       # The difference of a simple kernel blur.
allD = yuy26 ? allD.ConvertToYUY2().Interleaved2planar(true) : allD
ssD  = yuy26 ? ssD.ConvertToYUY2().Interleaved2planar(true) : ssD
ssDD = ssD.repair(HD?ssD.repair(allD,1,planar=planar):allD,HD?12:1,planar=planar) # Limit the difference to the max of what the denoising removed locally.
ssDD = yuy26 ? ssDD.Planar2Interleaved().ConvertToYV16() : ssDD
ssD  = yuy26 ? ssD.Planar2Interleaved().ConvertToYV16() : ssD
ssDD = avs26 ? SSDD.mt_lutxy(ssD,"x range_half - abs y range_half - abs < x y ?",use_expr=1)
       \     : SSDD.mt_lutxy(ssD,"x 128 - abs y 128 - abs < x y ?")                       # abs(diff) after limiting may not be bigger than before.

denoised.mt_adddiff(ssDD,U=2,V=2)                                                 # Apply the limited difference. (Sharpening is just inverse blurring)
HD ? mt_clamp(last,pmax,pmin,overshoot,overshoot,chroma="copy first") : last
yuy26 ? last.ConvertToYUY2().Interleaved2planar() : last
}


 # MinBlur   by Didée
 # Nifty Gauss/Median combination (Modified for Planar input)

function MinBlur(clip clp, int "r", int "uv", bool "planar", string "mode", int "abtype", bool "blurrep", int "y", int "u", int "v"){

r      = default(r,1)
uv     = default(uv,3)
u      = defined(u) ? u : uv
v      = defined(v) ? v : uv
Y      = Default(Y, 3)
planar = default(planar,false)
defmod = defined(mode)
mode   = default(mode,"Median_Both")
avs26 = VersionNumber() < 2.60 ? false : true
yuy26 = avs26 && Isyuy2(clp) && planar

ch    = u==1 && v==1
u2    = (u==2) ? 1  : u
v2    = (v==2) ? 1  : v
ch2   = u2==1 && v2==1
y2    = (y==2) ? 1  : y
rg4    = (u==3) ? 4  : -1
rg11   = (u==3) ? 11 : -1
rg20   = (u==3) ? 20 : -1
rg4v    = (v==3) ? 4  : -1
rg11v   = (v==3) ? 11 : -1
rg20v   = (v==3) ? 20 : -1
rg4y    = (y==3) ? 4  : -1
rg11y   = (y==3) ? 11 : -1
rg20y   = (y==3) ? 20 : -1
um2   = r==2 ? (u==3?2:u==2?0:-1) : nop()
um3   = r==3 ? (u==3?3:u==2?0:-1) : nop()
vm2   = r==2 ? (v==3?2:v==2?0:-1) : nop()
vm3   = r==3 ? (v==3?3:v==2?0:-1) : nop()
ym2   = r==2 ? (y==3?2:y==2?0:-1) : nop()
ym3   = r==3 ? (y==3?3:y==2?0:-1) : nop()
medf   = (u==3) ? 1 : -200
medfv   = (v==3) ? 1 : -200
medfy   = (y==3) ? 1 : -200
rg4v   = !(defmod && r==1) && (r<=1)

blurrep= default(blurrep,false)

blurstr= mode == "Median_Both" ? "medianblur(r*medfy,r*medf,r*medf)" : mode == "average_Both" ? "aBlur(r, abtype, chroma=uv)" : mode == "average_horizontal" ? "aBlur(r, abtype, blurv="+String(r==1 ? 0 : 1)+", chroma=uv)" : mode == "average_vertical" ? "aBlur("+String(r==1 ? 0 : 1)+", abtype, blurv=r, chroma=uv)" : mode

RG11D = (r==0) ? yuy26 ? mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.sbr(planar=planar,y=y2,U=u2,V=v2).Planar2Interleaved(ch2).ConvertToYV16(),y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2) : mt_makediff(clp,clp.sbr(planar=planar,y=y2,U=u2,V=v2),y=y2,U=u2,V=v2)
 \    : (r==1) ? yuy26 ? mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.removegrain(rg11y,rg11,planar=planar).Planar2Interleaved(ch2).ConvertToYV16(),y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2) : mt_makediff(clp,clp.removegrain(rg11y,rg11,planar=planar),y=y2,U=u2,V=v2)
 \    : (r==2) ? yuy26 ? mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.removegrain(rg11y,rg11,planar=planar).removegrain(rg20y,rg20,planar=planar).Planar2Interleaved(ch2).ConvertToYV16(),y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2) : mt_makediff(clp,clp.removegrain(rg11y,rg11,planar=planar).removegrain(rg20y,rg20,planar=planar),y=y2,U=u2,V=v2)
 \    :          yuy26 ? mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.removegrain(rg11y,rg11,planar=planar).removegrain(rg20y,rg20,planar=planar).removegrain(rg20y,rg20,planar=planar).Planar2Interleaved(ch2).ConvertToYV16(),y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2) : mt_makediff(clp,clp.removegrain(rg11y,rg11,planar=planar).removegrain(rg20y,rg20,planar=planar).removegrain(rg20y,rg20,planar=planar),y=y2,U=u2,V=v2)
RG4D  = (rg4v) ? yuy26 ? mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.removegrain(rg4y,rg4,planar=planar).Planar2Interleaved(ch2).ConvertToYV16(),y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2) : mt_makediff(clp,clp.removegrain(rg4y,rg4,planar=planar),y=y2,U=u2,V=v2)
 \    : (r==2) ? avs26 ? yuy26 ? eval("mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.Planar2Interleaved(ch2).ConvertToYV16()."+blurstr+",y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2)") : eval("mt_makediff(clp,clp."+blurstr+",y=y2,U=u2,V=v2)") : mt_makediff(clp,clp.Quantile(radius_y=ym2, radius_u=uvm2, radius_v=uvm2, planar=planar),y=y2, U=uv2,V=uv2)
 \    :          avs26 ? yuy26 ? eval("mt_makediff(clp.Planar2Interleaved(ch2).ConvertToYV16(),clp.Planar2Interleaved(ch2).ConvertToYV16()."+blurstr+",y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch2)") : eval("mt_makediff(clp,clp."+blurstr+",y=y2,U=u2,V=v2)") : mt_makediff(clp,clp.Quantile(radius_y=ym3, radius_u=uvm3, radius_v=uvm3, planar=planar),y=y2, U=uv2,V=uv2)
#RG4D  = blurrep ? RG4D.Repair(clp.removegrain(3,uv==3 ? 0 : -1,planar=planar),9,uv==3 ? 0 : -1,planar=planar) : RG4D
DD    = yuy26 ? mt_lutxy(RG11D.Planar2Interleaved(ch2).ConvertToYV16(),RG4D.Planar2Interleaved(ch2).ConvertToYV16(),"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?",y=y2,U=u2,V=v2).ConvertToYUY2().Interleaved2planar(ch)
    \ : avs26 ? mt_lutxy(RG11D,RG4D,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",use_expr=1,y=y2,U=u2,V=v2)
    \         : mt_lutxy(RG11D,RG4D,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?",y=y2,U=u2,V=v2)
yuy26 ? clp.Planar2Interleaved(ch).ConvertToYV16().mt_makediff(DD.Planar2Interleaved(ch).ConvertToYV16(),y=y,U=u,V=v).ConvertToYUY2().Interleaved2planar(ch) : clp.mt_makediff(DD,y=y,U=u,V=v)
blurrep ? Repair(clp.removegrain(y!=3 ? 0 : 17,u==3 ? 0 : -1,v==3 ? 0 : -1,planar=planar),y!=3 ? 0 : 9,u==3 ? 0 : -1,v==3 ? 0 : -1,planar=planar) : last
 }


 # helper function: make a highpass on a blur's difference (well, kind of that)
 # Highpass of spatial r=1 Gaussian (like blur(1.0)) (Modified for Planar input)

function sbr(clip c, bool "planar", int "y", int "r", int "U", int "V") {

planar = default(planar,false)
avs26 = VersionNumber() < 2.60 ? false : true
yuy26 = avs26 && Isyuy2(c) && planar
Y      = Default(Y, 3)
r      = Default(r,    1)
U      = Default(U,    3)
V      = Default(V,    3)
chroma = U==3 || V==3
nochr  = U==1 && V==1
Yt     = Y == 3
Ut     = U == 3
Vt     = V == 3
Y31    = Yt ? 3 : 1
U31    = Ut ? 3 : 1
V31    = Vt ? 3 : 1
Y11    = (Y==3) ? 11 : -1
Y20    = (Y==3) ? 20 : -1
U11    = (U==3) ? 11 : -1
U20    = (U==3) ? 20 : -1
V11    = (V==3) ? 11 : -1
V20    = (V==3) ? 20 : -1

rg11   = (r<=1) ? c.removegrain(Y11, U11, V11,planar=planar) : (r==2) ? c.removegrain(Y11, U11, V11,planar=planar).removegrain(Y20, U20, V20,planar=planar) : c.removegrain(Y11, U11, V11,planar=planar).removegrain(Y20, U20, V20,planar=planar).removegrain(Y20, U20, V20,planar=planar)
rg11D  = yuy26 ? mt_makediff(c.Planar2Interleaved(!chroma).ConvertToYV16(),rg11.Planar2Interleaved(!chroma).ConvertToYV16(), Y=Y31, U=U31, V=V31).ConvertToYUY2().Interleaved2planar(!chroma) : mt_makediff(c,rg11, Y=Y31, U=U31, V=V31)
RG11DS = (r<=1) ? rg11D.removegrain(Y11, U11, V11,planar=planar) : (r==2) ? rg11D.removegrain(Y11, U11, V11,planar=planar).removegrain(Y20, U20, V20,planar=planar) : rg11D.removegrain(Y11, U11, V11,planar=planar).removegrain(Y20, U20, V20,planar=planar).removegrain(Y20, U20, V20,planar=planar)
rg11DD = yuy26 ? mt_lutxy(RG11D.Planar2Interleaved(!chroma).ConvertToYV16(),RG11DS.Planar2Interleaved(!chroma).ConvertToYV16(),"x y - x 128 - * 0 < 128 x y - abs x 128 - abs < x y - 128 + x ? ?", Y=Y31, U=U31, V=V31).ConvertToYUY2().Interleaved2planar(!chroma)
     \ : avs26 ? mt_lutxy(RG11D, RG11DS, "x y - x range_half - * 0 < range_half x y - abs x range_half - abs < x y - range_half + x ? ?", Y=Y31, U=U31, V=V31,use_expr=1)
     \         : mt_lutxy(RG11D, RG11DS, "x y - x 128 - * 0 < 128 x y - abs x 128 - abs < x y - 128 + x ? ?", Y=Y31, U=U31, V=V31)
yuy26 ? c.Planar2Interleaved(nochr).ConvertToYV16().mt_makediff(rg11DD.Planar2Interleaved(nochr).ConvertToYV16(), Y=Y, U=U, V=V).ConvertToYUY2().Interleaved2planar(nochr) : c.mt_makediff(rg11DD, Y=Y, U=U, V=V) 
}
 
 
## cretindesalpes' functions
# Converts 16 bit interleaved YUY2 to 16bit planar YUY2 suitable for Ditherpost. (Use right before Ditherpost; this format is not suitable for filtering)

function Dither_YUY2toPlanar16(c){c
yuy26   = !(VersionNumber() < 2.60) && isyuy2(c)
my = !yuy26 ? Dither_get_msb().ConvertToYV12() : nop()
ly = !yuy26 ? Dither_get_lsb().ConvertToYV12() : nop()
u = !yuy26 ? UToY ().ConvertToYV12 () : nop()
v = !yuy26 ? VToY ().ConvertToYV12 () : nop()
yuy26 ? ConvertToYV16() : YToUV (u, v, StackVertical (StackVertical (my, my), StackVertical (ly, ly)))}


# Converts 8 bit interleaved YUY2 to 8 bit planar YUY2 ready for either 8 or 16 bit processing also suitable for Ditherpost

function Dither_YUY2toPlanar(c){c
yuy26   = !(VersionNumber() < 2.60) && isyuy2(c)
y = !yuy26 ? ConvertToYV12 () : nop()
u = !yuy26 ? UToY ().ConvertToYV12 () : nop()
v = !yuy26 ? VToY ().ConvertToYV12 () : nop()
yuy26 ? ConvertToYV16() : YToUV (u, v, StackVertical (y, y))}


# Converts back the above special planar formats to normal interleaved 16 bit YUY2

function Dither_YUY2toInterleaved16(c){c
yuy26   = !(VersionNumber() < 2.60)
y = !yuy26 ? StackVertical (Crop (0, 0, 0, (Height () /(4))), Crop (0, (Height () /(2))+(Height () /(4)), 0, 0)).ConvertToYUY2 () : nop()
u = !yuy26 ? UToY ().ConvertToYUY2 () : nop()
v = !yuy26 ? VToY ().ConvertToYUY2 () : nop()
yuy26 ? ConvertToYUY2() : YToUV (u, v, y)}


# Converts back the above special planar formats to normal interleaved YUY2

function Dither_YUY2toInterleaved(c){c
yuy26   = !(VersionNumber() < 2.60)
y = !yuy26 ? Crop (0, 0, 0, Height () /(2)).ConvertToYUY2 () : nop()
u = !yuy26 ? UToY ().ConvertToYUY2 () : nop()
v = !yuy26 ? VToY ().ConvertToYUY2 () : nop()
yuy26 ? ConvertToYUY2() : YToUV (u, v, y)}


# Converts luma (and chroma) to PC levels, and optionally allows tweaking for pumping up the darks. (for the clip to be fed to motion search only)
# By courtesy of cretindesalpes.

function Dither_Luma_Rebuild (clip src, float "s0", float "c",int "uv", bool "lsb", bool "lsb_in", bool "lsb_out", int "mode", float "ampn", bool "slice", bool "chromaonlytvtopc"){
lsb_in  = Default( lsb_in  ,false)
lsb_out = Default( lsb_out ,false)
lsb     = Default( lsb     ,lsb_in || lsb_out)
lsb     = !lsb && (lsb_in || lsb_out) ? true : lsb
mode    = Default( mode ,6)
uv      = Default(uv,    3)
s0      = Default(s0,  2.0)
c       = Default(c,  1.0/16)
ampn    = Default(ampn, 0.0)
slice   = Default(slice, true)
chrtv2pc   = Default(chromaonlytvtopc, false)
y = chrtv2pc ? 2 : 3
yuy2    = isyuy2(src)
avs26   = VersionNumber() < 2.60 ? false : true
sisphbd = AvsPlusVersionNumber > 2294
lsb_native = sisphbd ? !(src.BitsPerComponent() > 8 && (lsb)) : true
sisphbd ? Assert(lsb_native, "lsb hack is not Compatible with native high bit depth" ) : nop()
sisphbd ? Assert(!(src.isYUVA() && lsb), "lsb hack is not Compatible with YUVA" ) : nop()
Assert(!(src.isrgb()), "Dither_Luma_Rebuild: RGB Color formats is not supported" )
src     = yuy2 ? lsb_in ? src.Planar2Interleaved(uv==1).Dither_YUY2toPlanar16() : avs26 ? src.Planar2Interleaved(uv==1).ConvertToYV16() : lsb ? src.Planar2Interleaved(uv==1).Dither_YUY2toPlanar() : src : src

    k = (s0 - 1) * c
    t = lsb_in ? "x 4096 - 56064 / 0 1 clip"
     \ : avs26 ? "x 16 scaleb - 219 scaleb / 0 1 clip"
             \ : "x 16 - 219 / 0 1 clip"
    e = String(k)+" "+String(1+c)+" "+String((1+c)*c)+" "+t+" "+String(c)
\       +" + / - * "+t+" 1 "+String(k)+" - * + "+String(lsb?65536:avs26?"range_size":255)+" *"
src
lsb ? (lsb_in ? Dither_lut16  (yexpr=e,expr="x 32768 - 32768 * 28672 / 32768 +",y=y, u=uv, v=uv)                  : \
                Dither_lut8   (yexpr=e,expr="x 128 - 32768 * 112 / 32768 +"    ,y=y, u=uv, v=uv))                 : \
                avs26 ? mt_lut(yexpr=e,expr="x range_half - 128 * 112 / range_half +",use_expr=2,y=y, u=uv, v=uv) : \
                        mt_lut(yexpr=e,expr="x 128 - 128 * 112 / 128 +"        ,y=y, u=uv, v=uv)

lsb_out && !yuy2 ? last : (lsb && !lsb_out ? yuy2 ? Ditherpost(mode=mode,ampn=ampn,slice=slice,staticnoise=ampn!=0.0?true:false,u=uv,v=uv).Dither_YUY2toInterleaved().Interleaved2planar(uv==1) : Ditherpost(mode=mode,ampn=ampn,slice=slice,staticnoise=ampn!=0.0?true:false,u=uv,v=uv) : last)
return yuy2 && lsb_out ? last.Dither_YUY2toInterleaved16().Interleaved2planar(uv==1) : yuy2 && avs26 && !lsb ? converttoyuy2().Interleaved2planar(uv==1) : last
}

# SH_KNLMeansCL

function SH_KNLMeansCL (clip input, String "device_type", int "device_id", bool "chroma", bool "lsb", bool "lsb_in", float "h", int "d", int "a", String "knlm_params", clip "rclip")
{
d            = Default( d ,0)
a            = Default( a ,1)
h            = Default( h ,7.0)
deviceid     = Default( device_id ,0)
knlm_params  = default(knlm_params, "")
chroma       = Default( chroma  ,true)
lsb_in       = Default( lsb_in  ,false)
lsb          = Default( lsb     ,lsb_in)

                                              sisphbd = AvsPlusVersionNumber > 2294
                                              fullchr = sisphbd ? input.is444() : input.isyv24()
                                              chr420  = sisphbd ? input.is420() : input.isyv12()
                                              nochr   = sisphbd ?   input.isy() : input.isy8()
                                              chrlsb  = chroma && !fullchr && !nochr
                                              NL_in   = lsb && !lsb_in ? input.Dither_convert_8_to_16() : input
                                              cnl     = chrlsb ? "Y" : input.isrgb() ? "auto" : !nochr && chroma ? "YUV" : "Y"
											  drclip  = defined(rclip)
											  rclip   = drclip ? lsb && !lsb_in ? rclip.Dither_convert_8_to_16() : rclip : nop()

NL_in = !chrlsb && input.isyuy2() ? NL_in.converttoyv16() : NL_in
rclip = drclip ? !chrlsb && rclip.isyuy2() ? rclip.converttoyv16() : rclip : undefined

                               chrlsb ? eval("""
                                              # In a more lucid state I could probably have laid out this block much better... or not...

                                              NL_W    = width(NL_in)
                                              Uclip   = sisphbd ? ExtractU(NL_in) : UToY8(NL_in)
											  Urclip  = drclip ? sisphbd ? ExtractU(rclip) : UToY8(rclip) : nop()
                                              Vclip   = sisphbd ? ExtractV(NL_in) : VToY8(NL_in)
											  Vrclip  = drclip ? sisphbd ? ExtractV(rclip) : VToY8(rclip) : nop()
                                              NL_lsb  = (chr420 ? StackVertical(  lsb ? StackVertical(Dither_get_msb(uclip),Dither_get_msb(vclip)) : uclip,\
                                                                                  lsb ? StackVertical(Dither_get_lsb(uclip),Dither_get_lsb(vclip)) : vclip) : \
                                                                  StackHorizontal(uclip,vclip))
                                              rNL_lsb = drclip ? (chr420 ? StackVertical(  lsb ? StackVertical(Dither_get_msb(urclip),Dither_get_msb(vrclip)) : urclip,\
											                                               lsb ? StackVertical(Dither_get_lsb(urclip),Dither_get_lsb(vrclip)) : vrclip) : \
                                                                           StackHorizontal(urclip,vrclip)) : \
																  nop()

                                              nlc     = StackHorizontal(sisphbd ? ConvertToY(NL_in) : ConvertToY8(NL_in),NL_lsb)
											  nlrc    = drclip ? StackHorizontal(sisphbd ? ConvertToY(rclip) : ConvertToY8(rclip),rNL_lsb) : undefined

                                              nlc     = Eval("nlc.KNLMeansCL(D=d, A=a, h=h,stacked=lsb_in || lsb,device_type=device_type,device_id=deviceid,rclip=nlrc,channels=cnl" + knlm_params + ")")

                                              uvh = lsb_in || lsb ? uclip.height()/2 : uclip.height()
                                              uvw = uclip.width()

                                              nly = nlc.crop(0,0,chr420 ? -uvw : -(uvw+uvw),0)

                                              nlu = chr420 ? lsb_in || lsb ? StackVertical(Dither_get_msb(nlc).crop(NL_W,0,0,-uvh),Dither_get_lsb(nlc).crop(NL_W,0,0,-uvh)) : nlc.crop(NL_W,0,0,-uvh)                : \
                                                              nlc.crop(NL_W    ,0,-uvw,0)
                                              nlv = chr420 ? lsb_in || lsb ? StackVertical(Dither_get_msb(nlc).crop(NL_W,uvh, 0,0),Dither_get_lsb(nlc).crop(NL_W,uvh, 0,0)) : nlc.crop(NL_W,uvh, 0,0)                : \
                                                              nlc.crop(NL_W+uvw,0,   0,0)
                                              YToUV(nlu, nlv, nly)
                                             """) :   Eval("NL_in.KNLMeansCL(D=d, A=a, h=h,stacked=lsb_in || lsb,device_type=device_type,device_id=deviceid,rclip=rclip,channels=cnl" + knlm_params + ")")

!lsb && lsb_in ? Ditherpost(mode=6,slice=false) : last
input.isyuy2() ? converttoyuy2() : last
}


Function sh_RemoveGrain(clip input, int "mode", int "modeU", int "modeV")
{
    mode     = Default(mode,     1      )
    modeU    = Default(modeU,    mode   )
    modeV    = Default(modeV,    modeU  )
    
    
    iCSP     = input.sh_GetCSP()
    isYV12   = iCSP == "YV12"
    isY8     = iCSP == "Y8"
    
    sw       = input.Width ()
    sh       = input.Height()
    wmod4    = sw/4*4 == sw
    hmod4    = sh/4*4 == sh
    mod4     = wmod4 && hmod4
    padw     = wmod4 ? sw : (sw/4+1)*4
    padh     = hmod4 ? sh : (sh/4+1)*4
    
    
    input_m4 = mod4 ? input : input.PointResize(padw, padh, 0, 0, padw, padh)
    
    return isYV12 ? input.RemoveGrain(mode, modeU, modeV)
    \             : isY8 ? input_m4                       .RemoveGrain(mode , -1, -1)
    \                              .Crop(0, 0, sw, sh)
    \                    : YToUV(input_m4.UToY8()         .RemoveGrain(modeU, -1, -1),
    \                            input_m4.VToY8()         .RemoveGrain(modeV, -1, -1),
    \                            input_m4.ConvertToY8()   .RemoveGrain(mode , -1, -1))
    \                     .Crop(0, 0, sw, sh)
}


# base on dithertools avsi functions by cretindesalpes

Function y_gamma_to_linear (clip src,
\	bool "tv_range_in", bool "tv_range_out", string "curve", int "u", int "v",
\	float "gcor", bool "sigmoid", float "thr", float "cont")
{
	src
	linear_and_gamma (false,
\		tv_range_in, tv_range_out, curve, u, v,
\		gcor, sigmoid, thr, cont
\	)
}


Function y_linear_to_gamma (clip src,
\	bool "tv_range_in", bool "tv_range_out", string "curve", int "u", int "v",
\	float "gcor", bool "sigmoid", float "thr", float "cont")
{
	src
	linear_and_gamma (true,
\		tv_range_in, tv_range_out, curve, u, v,
\		gcor, sigmoid, thr, cont
\	)
}


Function linear_and_gamma (clip src, bool l2g_flag,
\	bool "tv_range_in", bool "tv_range_out", string "curve", int "u", int "v",
\	float "gcor", bool "sigmoid", float "thr", float "cont")
{
	sisphbd = AvsPlusVersionNumber > 2294
	sishasalpha  = sisphbd ? src.hasalpha : false
	src2         = sishasalpha ? src.RemoveAlphaPlane : src
	tv_range_in  = Default (tv_range_in,  true)
	tv_range_in  = src.IsRGB ? false : tv_range_in
	tv_range_out = Default (tv_range_out, true)
	tv_range_out = src.IsRGB ? false : tv_range_out
	curve        = Default (curve,      "srgb")
	u            = Default (u,               2)
	u            = src.IsRGB ? 3 : u
	v            = Default (v,               2)
	v            = src.IsRGB ? 3 : v
	gcor         = Default (gcor,          1.0)
	sigmoid      = Default (sigmoid,     false)

	c_num =
\	  (curve == "srgb" ) ? 0
\	: (curve == "709"  ) ? 1
\	: (curve == "601"  ) ? 1
\	: (curve == "170"  ) ? 1
\	: (curve == "240"  ) ? 2
\	: (curve == "2020" ) ? 3
\	: (curve == "1886" ) ? 4
\	: (curve == "1886a") ? 5
\	: Assert (false, "linear_and_gamma: wrong curve value.")

	#                                  BT-709/601
	#                         sRGB     SMPTE 170M  SMPTE 240M    BT-2020    BT-1886    BT-1886a
	k0    = Select (c_num, " 0.04045", " 0.081  ", " 0.0912 ", " 0.08145", "0      ", "0.35   ")
	phi   = Select (c_num, "12.92   ", " 4.5    ", " 4.0    ", " 4.5    ", "4.5    ", "0.65709357")	# 0.35 ^ (3.0-2.6)
	gam2  = Select (c_num, " 1      ", " 1      ", " 1      ", " 1      ", "1      ", "3.0    ")
	alpha = Select (c_num, " 0.055  ", " 0.099  ", " 0.1115 ", " 0.0993 ", "0      ", "0      ")
	gamma = Select (c_num, " 2.4    ", " 2.22222", " 2.22222", " 2.22222", "2.4    ", "2.6    ")

	expr = (tv_range_in) ? "x 4096 - 56064 /" : "x 65536 /"

	# E = (E' <= k0)   ?   (E' ^ gam2) / phi   :   ((E' + alpha) / (1 + alpha)) ^ gamma
	g2l = expr
	g2l =   g2l + " " + k0 +" <= "
\	      + g2l + " " + gam2 + " ^ " + phi +" / "
\	      + g2l + " " + alpha + " + 1 " + alpha + " + / " + gamma + " ^   ?"
	g2l = (gcor != 1.0) ? g2l + " 0 >=   " + g2l + " " + String (gcor) + " ^   " + g2l + "   ?" : g2l
	g2l = (sigmoid) ? build_sigmoid_expr (g2l , true , thr, cont) : g2l

	l2g = (sigmoid) ? build_sigmoid_expr (expr, false, thr, cont) : expr
	l2g = (gcor != 1.0) ? l2g + " 0 >=   " + l2g + " " + String (gcor) + " ^   " + l2g + "   ?" : l2g
	# E' = (E <= k0 / phi)   ?   (E * phi) ^ (1 / gam2)   :   (E ^ (1 / gamma)) * (alpha + 1) - alpha
	l2g =   l2g + " " + k0 + " " + phi + " / <= "
\	      + l2g + " " + phi + " * 1 " + gam2 + " / ^ "
\	      + l2g + " 1 " + gamma + " / ^ " + alpha + " 1 + * " + alpha + " -   ?"

	expr = (l2g_flag) ? l2g : g2l
	expr = expr + ((tv_range_out) ? " 56064 * 4096 +" : " 65536 *")
	src2.mt_lut (expr="i16 " + expr, scale_inputs=!tv_range_out || !tv_range_in ? "allf" : "all", use_expr=2, y=3, u=u, v=v)
	sishasalpha ? last.AddAlphaPlane(src.ExtractA) : last
}


# Sigmoidal functions:
# x0 = 1 / (1 + exp (cont *  thr     ))
# x1 = 1 / (1 + exp (cont * (thr - 1)))
# y  = (1 / (1 + exp (cont * (thr - x))) - x0) / (x1 - x0)
# x  = thr - log (1 / (y * (x1 - x0) + x0) - 1) / cont
Function build_sigmoid_expr (string in, bool inv, float "thr", float "cont")
{
	thr   = Default (thr,  0.5)
	cont  = Default (cont, 6.5)
	Assert ((cont > 0), "build_sigmoid_expr: cont must be strictly positive.")
	Assert ((thr >= 0 && thr <= 1), "build_sigmoid_expr: thr must be in the 0-1 range.")
	x0v = 1 / (1 + exp (cont *  thr     ))
	x1v = 1 / (1 + exp (cont * (thr - 1)))

	x0   = String (      x0v)
	x1m0 = String (x1v - x0v)
	cont = String (cont)
	thr  = String (thr)

	expr = (inv)
\	? thr + " 1 " + in + " " + x1m0 + " * " + x0 + " + 0.000001 max / 1 - 0.000001 max log " + cont + " / -"
\	: "1 1 " + cont + " " + thr + " " + in + " - * exp + / " + x0 + " - " + x1m0 + " /"

	return (expr)
}


Function sigmoid_direct (clip src, float "thr", float "cont", int "u", int "v")
{
	u = Default (u, 2)
	u = src.IsRGB ? 3 : u
	v = Default (v, 2)
	v = src.IsRGB ? 3 : v

	expr = "x 65536 /"
	expr = build_sigmoid_expr (expr, false, thr, cont)
	expr = expr + " 65536 *"
	src.MT_lut (yexpr="i16 " + expr, scale_inputs="allf", use_expr=2, y=3, u=u, v=v)
}


Function sigmoid_inverse (clip src, float "thr", float "cont", int "u", int "v")
{
	u = Default (u, 2)
	u = src.IsRGB ? 3 : u
	v = Default (v, 2)
	v = src.IsRGB ? 3 : v

	expr = "x 65536 /"
	expr = build_sigmoid_expr (expr, true , thr, cont)
	expr = expr + " 65536 *"
	src.mt_lut (yexpr="i16 " + expr, scale_inputs="allf", use_expr=2, y=3, u=u, v=v)
}
 
 
function sh_Vinverse2(clip clp, float "sstr", int "amnt", int "uv")
{
  uv   = default(uv,3)
  sstr = default(sstr,2.7)
  amnt = default(amnt,255)
  uv2  = (uv==2) ? 1 : uv
  STR  = string(sstr)
  AMN  = string(amnt)
  vblur  = clp.sbrV()
  vblurD = mt_MakeDiff(clp,vblur,U=uv2,V=uv2)
  Vshrp  = mt_LutXY(vblur,vblur.mt_convolution("1","1 2 1"),expr="x x y - "+STR+" * +",U=uv2,V=uv2)
  VshrpD = mt_MakeDiff(Vshrp,vblur,U=uv2,V=uv2)
  VlimD  = mt_LutXY(VshrpD,VblurD,expr="x 128 - y 128 - * 0 < x 128 - abs y 128 - abs < x y ? 128 - 0.25 * 128 + x 128 - abs y 128 - abs < x y ? ?",U=uv2,V=uv2)
  mt_AddDiff(Vblur,VlimD,U=uv,V=uv)
  (amnt>254) ? last : (amnt==0) ? clp : mt_LutXY(clp,last,expr="x "+AMN+" + y < x "+AMN+" + x "+AMN+" - y > x "+AMN+" - y ? ?",U=uv,V=uv)
  return(last)
}


function sbrV(clip o)
{
  rg11=o.mt_convolution("1","1 2 1")
  rg11D=mt_makediff(o,rg11)
  rg11DD=mt_makediff(rg11D,rg11D.mt_convolution("1","1 2 1")).mt_lutxy(rg11D,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
  o.mt_makediff(rg11DD,U=2,V=2)
}


function sh_Vinverse2H(clip clp, float "sstr", int "amnt", int "uv", int "pass")
{
  uv   = default(uv,3)
  sstr = default(sstr,2.7)
  amnt = default(amnt,255)
  uv2  = (uv==2) ? 1 : uv
  STR  = string(sstr)
  AMN  = string(amnt)
  pass = Default(pass, 1)
  Hblur  = clp.sbrH(pass)
  HblurD = mt_MakeDiff(clp,Hblur,U=uv2,V=uv2)
  Hshrp  = mt_LutXY(Hblur,spasses(Hblur, pass, """mt_convolution("1 2 1","1")"""),expr="x x y - "+STR+" * +",U=uv2,V=uv2)
  HshrpD = mt_MakeDiff(Hshrp,Hblur,U=uv2,V=uv2)
  HlimD  = mt_LutXY(HshrpD,HblurD,expr="x 128 - y 128 - * 0 < x 128 - abs y 128 - abs < x y ? 128 - 0.25 * 128 + x 128 - abs y 128 - abs < x y ? ?",U=uv2,V=uv2)
  mt_AddDiff(Hblur,HlimD,U=uv,V=uv)
  (amnt>254) ? last : (amnt==0) ? clp : mt_LutXY(clp,last,expr="x "+AMN+" + y < x "+AMN+" + x "+AMN+" - y > x "+AMN+" - y ? ?",U=uv,V=uv)
  return(last)
}


function sbrH(clip o, int "pass")
{
  pass = Default(pass, 1)
  rg11=spasses(o, pass, """mt_convolution("1 2 1","1")""")
  rg11D=mt_makediff(o,rg11)
  rg11DD=mt_makediff(rg11D,spasses(rg11D, pass, """mt_convolution("1 2 1","1")""")).mt_lutxy(rg11D,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
  o.mt_makediff(rg11DD,U=2,V=2)
}


# sBlackerPixel by A.SONY, for repairing DeCrawled and dehaloed clip
# v1.56

function sBlackerPixel(clip "o", clip "filtered", float "maxdiff", float "thr", bool "linflate", float "mdifffade", clip "o2", val "averagewithwhiterPixel", int "averagewithwhiterPixelrep", bool "deeponly")
{
maxdiff   = default(maxdiff,              32)
thr       = default(thr,                  40)
mdifffade = default(mdifffade, maxdiff*3/2.0) #should be more than the maxdiff
linflate  = default(linflate,           true)
whidorep  = defined(averagewithwhiterPixelrep)

Assert((defined(o) && defined(filtered)), "both o clip and filtered clip are needed")

doaverage = defined(averagewithwhiterPixel)
whiterPixelclip = doaverage ? isclip(averagewithwhiterPixel) ? averagewithwhiterPixel : isstring(averagewithwhiterPixel) ? eval(averagewithwhiterPixel) : swhiterPixel(o, filtered, maxdiff, 255-thr, linflate, mdifffade, o2, deeponly) : nop()

dpmask = mdifffade!=0 ? VersionNumber() < 2.6 ? o.mt_lutxy(filtered,"y "+string(thr)+" > x y > & x y - "+string(maxdiff)+" < 255 x y - "+string(mdifffade)+" < ? 255 255 "+string(mdifffade)+" / x y - * - 0 ? 0 ?")
                        \                     : o.mt_lutxy(filtered,"y "+string(thr)+" scalef > x y > & x y - "+string(maxdiff)+" scalef < range_max x y - "+string(mdifffade)+" scalef < ? range_max range_max "+string(mdifffade)+" scalef / x y - * - 0 ? 0 ?",use_expr=2) : nop()

mdifffade!=0 ? Mt_Merge(defined(o2) ? o2 : o,filtered, linflate ? dpmask.mt_inflate(155) : dpmask,U=2,V=2) : \
               VersionNumber() < 2.6 ? o.mt_lutxy(filtered,"x y > y "+string(thr)+" > & x y - "+string(maxdiff)+" < & y x ?",U=2,V=2)
               \                     : o.mt_lutxy(filtered,"x y > y "+string(thr)+" scalef > & x y - "+string(maxdiff)+" scalef < & y x ?",use_expr=2,U=2,V=2)
doaverage ? whidorep ? mt_average(last, whiterPixelclip.Repair(o,averagewithwhiterPixelrep,-1), u=2, v=2) : mt_average(last, whiterPixelclip, u=2, v=2) : last
}


# swhiterPixel by A.SONY
# v1.27

function swhiterPixel(clip "o", clip "filtered", float "maxdiff", float "thr", bool "linflate", float "mdifffade", clip "o2", bool "deeponly")
{
maxdiff   = default(maxdiff,              32)
thr       = default(thr,                 215)
mdifffade = default(mdifffade, maxdiff*3/2.0) #should be more than the maxdiff
linflate  = default(linflate,           true)
deeponly  = default(deeponly,          false)

Assert((defined(o) && defined(filtered)), "both o clip and filtered clip are needed")

wpmask = mdifffade!=0 ? VersionNumber() < 2.6 ? o.mt_lutxy(filtered,"y "+string(thr)+" < x y < & y x - "+string(maxdiff)+" < 255 y x - "+string(mdifffade)+" > ? 255 255 "+string(mdifffade)+" / y x - * - 0 ? 0 ?")
                        \                     : o.mt_lutxy(filtered,"y "+string(thr)+" scalef < x y < & y x - "+string(maxdiff)+" scalef < range_max y x - "+string(mdifffade)+" scalef > ? range_max range_max "+string(mdifffade)+" scalef / y x - * - 0 ? 0 ?",use_expr=2) : nop()

wpmask = mdifffade!=0 && deeponly ? wpmask.mt_invert().mt_expand(155).mt_inpand(155).mt_invert() : wpmask

mdifffade!=0 ? Mt_Merge(defined(o2) ? o2 : o,filtered, linflate ? wpmask.mt_inflate(155) : wpmask,U=2,V=2) : \
               VersionNumber() < 2.6 ? o.mt_lutxy(filtered,"x y < y "+string(thr)+" < & y x - "+string(maxdiff)+" < & y x ?",U=2,V=2)
               \                     : o.mt_lutxy(filtered,"x y < y "+string(thr)+" scalef < & y x - "+string(maxdiff)+" scalef < & y x ?",use_expr=2,U=2,V=2)
}



function chroma_rep(clip sourceo, int "cache", float "thr")
{
###### parameters & other necessary vars ######
    cache   = default(cache,-1)
global  rep_thr = default(thr, 0.125)


avs26=!(VersionNumber() < 2.6)
nonyuy2=avs26 && sourceo.isyuy2()

source=nonyuy2 ? sourceo.nonyuy2clipin(true) : sourceo

###### source preparation & lut ######
global  out1    = source
global  out2    = mergechroma(source,mt_adddiff(source.trim(1,0),mt_makediff(source.trim(1,0),source.trim(2,0),y=1,u=3,v=3),y=1,u=3,v=3).blur(1))


###### initialise variables ######
global  alfr     = -100


###### evaluation call & output calculation ######
scriptclip( source, """

 ### preparation ###
        cfr = current_frame
        ajmp = alfr+1==cfr
        
    global  alfr = cfr

        al_v = LumaDifference(out1.trim(1,0),out1.trim(2,0))
        ac_v = ChromaUDifference(out1.trim(1,0),out1.trim(2,0)) + ChromaVDifference(out1.trim(1,0),out1.trim(2,0))

  ## luma value shifting ##
    l10 = ajmp ? l01 : al_v
global 		l01	= ajmp ? l12 : al_v
global 		l12	= al_v
  
  ## chroma value shifting ##
    c10 = ajmp ? c01 : ac_v
global 		c01 = ajmp ? c12 : ac_v
global 		c12 = ac_v
	
 ### condition ###
    change  = l12*2<l01 && c01*1.25<c12 && c01*l12/c12/l01<rep_thr
    chango  = l01*2<l10 && c10*1.25<c01 && c10*l01/c01/l10<rep_thr
    
    change ? out2 : chango ? out1.trim(1,0) : out1

""")

nonyuy2 ? nonyuy2clipout(true) : last


###### final decimation & caching ######
cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)

return last
}


function chroma_rep2(clip sourceo, int "cache", float "thr")
{
###### parameters & other necessary vars ######
    cache   = default(cache,-1)
global  rep_thr = default(thr, 0.125)


avs26=!(VersionNumber() < 2.6)
nonyuy2=avs26 && sourceo.isyuy2()

source=nonyuy2 ? sourceo.nonyuy2clipin(true) : sourceo

###### source preparation & lut ######
global  out1    = source
global  out2    = mergechroma(source,mt_adddiff(source.trim(1,0),mt_makediff(source.trim(1,0),source.trim(2,0),y=1,u=3,v=3),y=1,u=3,v=3).blur(1))


###### initialise variables ######
global  alfr     = -100


###### evaluation call & output calculation ######
chrixout = scriptclip( source, """

 ### preparation ###
        cfr = current_frame
        ajmp = alfr+1==cfr
        
    global  alfr = cfr

        al_v = LumaDifference(out1,out1.trim(1,0))
        ac_v = ChromaUDifference(out1,out1.trim(1,0)) + ChromaVDifference(out1,out1.trim(1,0))

  ## luma value shifting ##
    l10 = ajmp ? l01 : al_v
global 		l01	= ajmp ? l12 : al_v
global 		l12	= al_v
  
  ## chroma value shifting ##
    c10 = ajmp ? c01 : ac_v
global 		c01 = ajmp ? c12 : ac_v
global 		c12 = ac_v
	
 ### condition ###
    change  = l12*2<l01 && c01*1.25<c12 && c01*l12/c12/l01<rep_thr
    chango  = l01*2<l10 && c10*1.25<c01 && c10*l01/c01/l10<rep_thr
    
    change ? out2 : chango ? out1.trim(1,0) : out1

""")

chrixout=nonyuy2 ? chrixout.nonyuy2clipout(true) : chrixout


###### final decimation & caching ######
chrixout2 = cache<0 ? sourceo.mergechroma(chrixout) : sourceo.mergechroma(chrixout).RequestLinear(8, cache, 5, false, false)

return chrixout2
}


#based on smartfade v0.2 by martino - Aimed at removing interlaced fades in anime. Uses luma difference between two fields as activation threshold.
#mod by thetoof : removed degrainmedian post-processing, 
#		changed how the fields are blended together (average of 2 nnedi interpolations + contra-sharpening to retain more detail) and 
#		added cache parameter to forward the setting of animeivtc to this function
#		renamed global parameter to something less general than "threshold"

function smartfademod(clip c, float "sfthr", bool "sfshow", int "cache") {
    
global sfthr	= default ( sfthr,  0.4 ) # Threshold for fade detection.
show		= default ( sfshow, false ) # Displays luma difference between fields without processing anything.
cache		= default ( cache,   10 ) # Cache the frames to help seeking and other functions requesting many frames

show ? scriptclip(c, "subtitle(string(abs(	  separatefields().selectodd().averageluma() \
            				- separatefields().selecteven().averageluma())))") : \
       scriptclip(c, "sep = separatefields() \
       avg = sep.selectodd().averageluma() - sep.selecteven().averageluma() \
       abs(avg) > sfthr ? interleave(sep.selecteven(),sep.selectodd()).weave().daa3() : last")

cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)

    return last

}


#Suggested by Mystery Keeper in "Denoise of tv-anime" thread
function ediaa(clip a) {return a.EEDI2(field=1).TurnRight().EEDI2(field=1).TurnLeft().spline36resize(a.width,a.height,-0.5,-0.5)}


#Anti-aliasing with contra-sharpening by Didée
function daa(clip c) {
nn	= c.nnedi2(field=-2)
dbl   	= mt_average(selecteven(nn),selectodd(nn),U=3,V=3)
dblD 	= mt_makediff(c,dbl,U=3,V=3)
shrpD 	= mt_makediff(dbl,dbl.removegrain((width(c)>1100) ? 20 : 11),U=3,V=3)
DD 	= shrpD.repair(dblD,13)
return dbl.mt_adddiff(DD,U=3,V=3) }


#Anti-aliasing with edge masking by martino, mask using "sobel" taken from Kintaro's useless filterscripts and modded by thetoof for spline36
function maa(clip input, int "mask") {
sisavs26 = !(VersionNumber() < 2.60)
mask = input.mt_edge("sobel",7,7,5,5).mt_inflate()
aa_clip=sisavs26 ? input.spline36Resize(width(input)*2,height(input)*2).TurnLeft().SangNom2().TurnRight().SangNom2().spline36Resize(width(input),height(input)).MergeChroma(input) : input.spline36Resize(width(input)*2,height(input)*2).TurnLeft().SangNom().TurnRight().SangNom().spline36Resize(width(input),height(input)).MergeChroma(input)
return mt_merge(input,aa_clip,mask) }


#Developped in the "fine anime antialiasing thread"
#tunned by Dogway for eedi3,resizer and HQ lsfmod settings
#another mod by RF for HBD

function SharpAAMCmod(clip orig, float "dark", int "thin", int "sharp", int "smooth", bool "stabilize", int "tradius", int "aapel", int "aaov", int "aablk", string "aatype", int "width", int "height")
{

sisavs26 = !(VersionNumber() < 2.60)
dw = defined(width)
dh = defined(height)
dmodd = !(!dh && !dw)
w	= default (width, orig.width)
h	= default (height, orig.height)
orig2   = dmodd ? orig.spline36resize(w,h) : orig
dark	= default ( dark,     0.2 ) # strokes darkening strength
thin	= default ( thin,      10 ) # Presharpening
sharp	= default ( sharp,    150 ) # Postsharpening
smooth	= default ( smooth,    -1 ) # Postsmoothing
stabilize= default ( stabilize,false ) # Use post stabilization with Motion Compensation
Tradius	= default ( Tradius,    2 ) # 2 = MDegrain2 / 3 = MDegrain3 
aapel	= default ( aapel,      1 ) # accuracy of the motion estimation (Value can only be 1, 2 or 4. 1 means a precision to the pixel. 2 means a precision to half a pixel, 4 means a precision to quarter a pixel, produced by spatial interpolation (better but slower).)
aaov	= default ( aaov,       (orig2.width>1100) ? 8 : 4 ) # block overlap value (horizontal). Must be even and less than block size. (Higher = more precise & slower)
aablk	= default ( aablk,      (orig2.width>1100) ? 16 : 8 ) # Size of a block (horizontal). It's either 4, 8 or 16 ( default is 8 ). Larger blocks are less sensitive to noise, are faster, but also less accurate.
aatype	= default ( aatype, "Sangnom" ) # Use Sangnom() or EEDI2() or EEDI3() for anti-aliasing


m=mt_logic( orig.mt_edge("5 10 5 0 0 0 -5 -10 -5 4",0,255,0,255,U=3,V=3)
 \       ,orig.mt_edge("5 0 -5 10 0 -10 5 0 -5 4",0,255,0,255,U=3,V=3)
 \       ,"max")
m=sisavs26 ? m.mt_lut("x 128 / 0.86 ^ 255 *", scale_inputs="allf", use_expr=2) : m.mt_lut("x 128 / 0.86 ^ 255 *")
m=dmodd ? m.spline36resize(w,h) : m
preaa=(thin==0 && dark==0) ? orig : (thin==0) ? orig.mToon(dark,10,20) : (dark==0) ? orig.awarpsharp2(depth=thin) : orig.mToon(dark,10,20).awarpsharp2(depth=thin)
aa= (aatype=="Sangnom") ? preaa.spline36resize(w*2,h*2).TurnLeft().SangNom().TurnRight().SangNom().spline36resize(w,h) : (aatype=="EEDI2") ? preaa.ediaa() : (aatype=="EEDI3") ? preaa.\
eedi3_rpow2(rfactor=2,hp=false).spline36resize(w,h,-0.5,-0.5) : blankclip(pixel_type="YV12").subtitle("Please use Sangnom or EEDI2 or EEDI3 for aatype")
postsh=(sharp==0 && smooth==0) ? aa : dmodd ? aa.LSFmod(defaults="slow",strength=sharp,edgemode=0,soothe=true,ss_x=1.0,ss_y=1.0,overshoot=1,soft=smooth) : aa.lsfmod(edgemode=1,strength=sharp,overshoot=1,soft=smooth)
merged=mt_merge(orig2,postsh,m,Y=3,U=3,V=3)

sD=mt_makediff(orig2,merged)

origsuper= orig2.MSuper(pel=aapel)
sDsuper  = sD.  MSuper(pel=aapel, levels=1)


fv3 = tradius==3 ? origsuper.MAnalyse(isb=false,delta=3,overlap=aaov,blksize=aablk) : nop()
fv2 = tradius>=2 ? origsuper.MAnalyse(isb=false,delta=2,overlap=aaov,blksize=aablk) : nop()
fv1 = tradius>=1 ? origsuper.MAnalyse(isb=false,delta=1,overlap=aaov,blksize=aablk) : nop()
bv1 = tradius>=1 ? origsuper.MAnalyse(isb=true, delta=1,overlap=aaov,blksize=aablk) : nop()
bv2 = tradius>=2 ? origsuper.MAnalyse(isb=true, delta=2,overlap=aaov,blksize=aablk) : nop()
bv3 = tradius==3 ? origsuper.MAnalyse(isb=true, delta=3,overlap=aaov,blksize=aablk) : nop()
sDD = tradius==1 ? sD.MDegrain1(sDsuper,bv1,fv1) : tradius==2 ? sD.MDegrain2(sDsuper,bv1,fv1,bv2,fv2) : sD.MDegrain3(sDsuper,bv1,fv1,bv2,fv2,bv3,fv3)

reduc = 0.4
sDD = sisavs26 ? mt_lutxy(sD,sDD,"x range_half - abs y range_half - abs < x y ?", use_expr=1).mergeluma(sDD,1.0-reduc) : mt_lutxy(sD,sDD,"x 128 - abs y 128 - abs < x y ?").mergeluma(sDD,1.0-reduc)

return stabilize ? orig2.mt_makediff(sDD,U=2,V=2) : merged
}


# Kill Combing Function from mcbob
function VinverseD(clip clp, float "sstr", float "amnt", int "uv")
{
sisavs26  = !(VersionNumber() < 2.60)
uv   = default(uv,3)
sstr = default(sstr,2.7)
amnt = default(amnt,255)
uv2  = (uv==2) ? 1 : uv
STR  = string(sstr)
AMN  = string(amnt)
vblur  = clp.mt_convolution("1","50 99 50",U=uv,V=uv)
vblurD = mt_makediff(clp,vblur,U=uv2,V=uv2)
Vshrp  = sisavs26 ? mt_lutxy(vblur,vblur.mt_convolution("1","1 4 6 4 1",U=uv2,V=uv2),expr="x x y - "+STR+" * +",U=uv2,V=uv2, use_expr=1) : mt_lutxy(vblur,vblur.mt_convolution("1","1 4 6 4 1",U=uv2,V=uv2),expr="x x y - "+STR+" * +",U=uv2,V=uv2)
VshrpD = mt_makediff(Vshrp,vblur,U=uv2,V=uv2)
VlimD  = sisavs26 ? mt_lutxy(VshrpD,VblurD,expr="x range_half - y range_half - * 0 < x range_half - abs y range_half - abs < x y ? range_half - 0.25 * range_half + x range_half - abs y range_half - abs < x y ? ?",U=uv2,V=uv2, use_expr=1) : mt_lutxy(VshrpD,VblurD,expr="x 128 - y 128 - * 0 < x 128 - abs y 128 - abs < x y ? 128 - 0.25 * 128 + x 128 - abs y 128 - abs < x y ? ?",U=uv2,V=uv2)
mt_adddiff(Vblur,VlimD,U=uv,V=uv)
(amnt>254) ? last : (amnt==0) ? clp : sisavs26 ? mt_lutxy(clp,last,expr="x "+AMN+" scalef + y < x "+AMN+" scalef + x "+AMN+" scalef - y > x "+AMN+" scalef - y ? ?",U=uv,V=uv, use_expr=1) : mt_lutxy(clp,last,expr="x "+AMN+" + y < x "+AMN+" + x "+AMN+" - y > x "+AMN+" - y ? ?",U=uv,V=uv)
return(last)
}



###############
#motion adaptive by A.SONY

function smam(clip input, clip "prefilter", val "filter", int "pel", int "blksize", clip "motionmask", float "Str", float "Amp", bool "TV_range", bool "qtgmc_lsb", int "tr2", int "usedaa3mod", bool "repblend", val "dslow", bool "qtgmc_n16") {

sisphbd = AvsPlusVersionNumber > 2294
qtgmc_lsb = default(qtgmc_lsb, sisphbd ? false : true)
qtgmc_n16 = default(qtgmc_n16, sisphbd ? input.BitsPerComponent() > 8 ? false : true : false)
repblend  = default(repblend, false)
threads = sh_GetUserGlobalIMTint()

defined(filter) ? Assert((Isclip(filter) || IsString(filter)),        "'filter' only accepts clip or string") : nop()

Str             = default (Str, 1.5)
exfilclp        = isclip(filter)
sisbob          = round(framerate(input))==60 || framerate(input)==50
dslow           = default(dslow, sisbob ? 5 : -5)
tr2             = default (tr2, sisbob ? 3 : 1)
usedaa3mod      = default (usedaa3mod, exfilclp ? 0 : sisbob ? 1 : 2)

infiltr = usedaa3mod == 1 ? input.daa3mod(dslow,threads=threads) : input
filclip = defined(filter) ? exfilclp ? filter : eval("infiltr." + filter) : infiltr.QTGMC(InputType=1, tr0=0, tr1=sisbob ? undefined : 1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep1=sisbob ? undefined : 11, rep2=sisbob ? undefined : 11, Sharpness=0.0, TV_range=TV_range, Str=Str, Amp=Amp, EdiThreads=threads)
filclip = usedaa3mod == 2 ? filclip.daa3mod(dslow,threads=threads) : filclip

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
	threads = sh_GetUserGlobalIMTint()
	mt = sh_GetUserGlobalIMTbool()
preclip= defined(prefilter) ? prefilter : isyuy2(input) ? input.HQdn3d_2().FFT3DFilter(ncpu=threads) : input.HQdn3d().sneo_FFT3D(ncpu=threads)
sup    = defined(mt) ? preclip.MSuper(pel=pel,sharp=1,mt=mt) : preclip.MSuper(pel=pel,sharp=1)
fv1    = defined(mt) ? sup.MAnalyse(isb=false,delta=1,DCT=dct,Truemotion=false,blksize=blksize,chroma=chroma,mt=mt) : sup.MAnalyse(isb=false,delta=1,DCT=dct,Truemotion=false,blksize=blksize,chroma=chroma)
fv2    = defined(mt) ? sup.MAnalyse(isb=true,delta=1,DCT=dct,Truemotion=true,blksize=blksize,chroma=chroma,mt=mt) : sup.MAnalyse(isb=true,delta=1,DCT=dct,Truemotion=true,blksize=blksize,chroma=chroma)

momask1 = input.MMask(fv1, kind = 1, ml=2)
momask2 = input.MMask(fv2, kind = 1, ml=3)
momask1 =isyuy2(input) && VersionNumber() < 2.60 ? momask1.Interleaved2Planar() : isyuy2(input) ? momask1.converttoyv16() : momask1
momask2 =isyuy2(input) && VersionNumber() < 2.60 ? momask2.Interleaved2Planar() : isyuy2(input) ? momask2.converttoyv16() : momask2
mt_average(momask1,momask2,u=3,v=3)
}


###############
# Hqdn3d_2

function Hqdn3d_2(clip clip, float "ls", float "cs", float "lt", float "ct", int "UV", bool "lsb", bool "lsb_in", bool "i16", int "Y") {
sisavs26  = !(VersionNumber() < 2.60)
sisphbd   = AvsPlusVersionNumber > 2294
cs        = default (cs              , 3.0)
ct        = default (ct              , 4.5)
UV        = default (UV               , 3)
Y         = default (Y                , 3)
UV        = sisavs26 ? isY8(clip) ? 1 : UV : UV
lsb_in    = default (lsb_in          , false)
i16       = default (i16             , false)
lsb_out   = default (lsb             , lsb_in)

i16b      = sisphbd ? clip.BitsPerComponent() > 8 : (lsb_out || i16 || lsb_in)

isrgb(clip) ? Assert(!i16b, "Hqdn3d_2: no 16bit for RGB, but you can use some trickes for that (see dither doc)") : nop()
Assert(!(sisphbd && i16b && clip.BitsPerComponent() != 16), "Hqdn3d_2: only HBD 16bit Supported")
Assert(!(sisphbd && i16b && (i16 || lsb_in || lsb_out)), "Hqdn3d_2: lsb hack is not Compatible with HBD")

yString = sisphbd ? "Y" : !sisavs26 ? "yv12" : "Y8"

pclip   = isYUV(clip) && i16b && isYUY2(clip) && sisavs26 ? clip.ConvertToYV16() : clip

i16clip = isYUV(clip) ? i16b ? sisphbd ? pclip.ConvertToDoubleWidth() : lsb_in ? pclip.Bitdepth(from=88, to=16) : i16 ? clip : pclip.Bitdepth(from=8, to=16) : nop() : nop()

	yclip = isYUV(clip) ? !sisavs26 ? i16b ? i16clip : clip : i16b ? ConvertToY8(i16clip) : ConvertToY8(clip) : nop()
	u = isYUV(clip) && UV != 1 ? !sisavs26 ? i16b ? UToY(i16clip) : UToY(clip) : i16b ? UToY8(i16clip) : UToY8(clip) : nop()
	v = isYUV(clip) && UV != 1 ? !sisavs26 ? i16b ? VToY(i16clip) : VToY(clip) : i16b ? VToY8(i16clip) : VToY8(clip) : nop()
	yclip = isYUV(clip) ? Y == 3 ? !sisavs26 ? isclip(i16clip) ? yclip.converttoyv12().Hqdn3d16Y(sp=ls, tp=lt) : yclip.converttoyv12().Hqdn3dY(sp=ls, tp=lt) : isclip(i16clip) ? yclip.Hqdn3d16Y(sp=ls, tp=lt) : yclip.Hqdn3dY(sp=ls, tp=lt) : yclip : nop()
	u = isYUV(clip) ? UV == 3 ? !sisavs26 ? isclip(i16clip) ? u.converttoyv12().Hqdn3d16Y(sp=cs, tp=ct) : u.converttoyv12().Hqdn3dY(sp=cs, tp=ct) : isclip(i16clip) ? u.Hqdn3d16Y(sp=cs, tp=ct) : u.Hqdn3dY(sp=cs, tp=ct) : u : nop()
	v = isYUV(clip) ? UV == 3 ? !sisavs26 ? isclip(i16clip) ? v.converttoyv12().Hqdn3d16Y(sp=cs, tp=ct) : v.converttoyv12().Hqdn3dY(sp=cs, tp=ct) : isclip(i16clip) ? v.Hqdn3d16Y(sp=cs, tp=ct) : v.Hqdn3dY(sp=cs, tp=ct) : v : nop()
	isYUV(clip) ? !sisavs26 && isYUY2(clip) ? UV == 1 ? yclip : YToUV(u.converttoyuy2(),v.converttoyuy2(),yclip.converttoyuy2()) : UV == 1 ? yclip : YToUV(u,v,yclip) : nop()
        isYUV(clip) ? i16b && !i16 && lsb_out ? Bitdepth(from=16, to=88) : last : last
	isYUV(clip) ? sisphbd && i16b ? ConvertFromDoubleWidth() : !i16b || lsb_out || i16 ? last : Bitdepth(from=16, to=8) : last
	isYUY2(clip) ? !sisavs26 ? last : converttoyuy2() : last

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


# 60p or 50p progressive to interlaced

    FUNCTION interlaced60or50(clip c1, bool "BFF") {
BFF	= default ( BFF,        false  )
Ifrate 	= round(framerate(c1))==60 ? 1 : framerate(c1)==50 ? 2 : 3
assert(ifrate!=3 && c1.IsFrameBased, "only Frame Based with 50 or ~60 fps is allowed.") 

desiredoutputfieldorder = BFF ? c1.AssumeTFF() : c1.AssumeBFF() # opposite to the desired output field order
outputfieldDoubleWeave = desiredoutputfieldorder.DoubleWeave()
return outputfieldDoubleWeave.SelectEvery(4,1)
}


# convert_Fields_scan_order with add audio delay (-16) in NTSC source and -20 in PAL source

    FUNCTION convert_Fields_scan_order(clip c1, bool "fast") {
fast     = default ( fast, true)
originField = !fast ? c1.SeparateFields() : nop()
newoFields = !fast ? originField.Trim(1,0)+blankclip(originField,length=1) : nop()
newoFields = fast ? c1.DoubleWeave().Selectodd() : newoFields.Weave()
return newoFields
}


function yadifmodclipin(clip i, bool "doyv16")
{
i.nonyuy2clipin(doyv16)
pointresize(width(),height()+8,0,-4,width(),height()+8.0001)
}


function yadifmodclipout(clip i, bool "doyuy2")
{
i.crop(0,4,-0,-4)
nonyuy2clipout(doyuy2)
}


function tmm2_ortmm1(clip clip, int "mode", int "order", int "field", int "length", int "mtype", int "ttype", int "mtqL", int "mthL", int "mtqC", int "mthC", int "nt", int "minthresh", int "maxthresh", int "cstr", int "opt")
{
sisavs26=!(VersionNumber() < 2.6)
sisphbd=AvsPlusVersionNumber > 2294
sischbd=sisphbd ? clip.BitsPerComponent() > 8 : false
nonyuy2=sisavs26 && clip.isyuy2()
sischbd ? clip.nonyuy2clipin(nonyuy2).vsTMM(mode, order, field, length, mtype, ttype, mtqL, mthL, mtqC, mthC, nt, minthresh, maxthresh, cstr, opt=opt).nonyuy2clipout(nonyuy2) \
            : sisavs26 ? clip.nonyuy2clipin(nonyuy2).tmm2(mode, order, field, length, mtype, ttype, mtqL, mthL, mtqC, mthC, nt, minthresh, maxthresh, cstr, opt).nonyuy2clipout(nonyuy2) : \
                         clip.TMM(mode, order, field, length, mtype, ttype, mtqL, mthL, mtqC, mthC, nt, minthresh, maxthresh, cstr)
}


function nonyuy2clipin(clip i, bool "doyv16")
{
doyv16 ? Eval("try { i.PackedToPlanar() } catch(error_msg) { i.converttoyv16() }") : i
}


function nonyuy2clipout(clip i, bool "doyuy2")
{
doyuy2 ? Eval("try { i.PlanarToPacked() } catch(error_msg) { i.converttoyuy2() }") : i
}


# StainlessS script port of Kassandro LimitChange with HBD support
Function sh_LimitChange(clip Src,clip Denoised,float LimitY,float "LimitU",float "LimitV") 
{
sisavs26   = !(VersionNumber() < 2.6)
    LimitU=Default(LimitU,LimitY)           LimitV=Default(LimitV,LimitU)
    Lim_Y = String(LimitY,"%.0f")           Lim_U = String(LimitU,"%.0f")           Lim_V = String(LimitV,"%.0f")
    # "min(max(Denoised,Src-LimitY),Src+LimitY)"
    # Infix = "min(max(x,y-LimitY),x+LimitY)"           # where x is Denoised and y = Src
    # RPN   = "x y LimitY - max y LimitY + min"
    RPN_1 = "x y "
    RPN_2 = " - max y "
    RPN_3 = " + min"
    Expr_Y = RPN_1 + Lim_Y + String(sisavs26 ? " yscalef" : "") + RPN_2 + Lim_Y + String(sisavs26 ? " yscalef" : "") + RPN_3
    Expr_U = RPN_1 + Lim_U + String(sisavs26 ? " yscalef" : "") + RPN_2 + Lim_U + String(sisavs26 ? " yscalef" : "") + RPN_3
    Expr_V = RPN_1 + Lim_V + String(sisavs26 ? " yscalef" : "") + RPN_2 + Lim_V + String(sisavs26 ? " yscalef" : "") + RPN_3
    Return sisavs26 ? mt_lutxy(Denoised,Src,YExpr=Expr_Y,UExpr=Expr_U,VExpr=Expr_V,U=3,V=3, use_expr=1) : mt_lutxy(Denoised,Src,YExpr=Expr_Y,UExpr=Expr_U,VExpr=Expr_V,U=3,V=3)      # MUST SET U=3 and V=3 (Even when UExpr and VEXpr explicitly supplied, ELSE dont work proper).
}


# Same as Bob, but keeps the field order the same.
function sh_Bob(clip cp, float "b", float "c", int "height" )
{
  sisavs26=!(VersionNumber() < 2.6)
  sisphbd = AvsPlusVersionNumber > 2294
  h = Default(height, cp.Height)
  w = cp.Width
  shift = GetParity(cp) ? 0.25 : -0.25

  c420 = sisphbd  ? Is420(cp) : IsYV12(cp)

  c420 ? cp.SeparateFields() : nop()

  oeven=c420 ? SelectEven() : nop()
  oodd=c420 ? SelectOdd() : nop()

  even=c420 ? sisphbd  ? oeven.ConvertToY().BicubicResize(w, h, b, c, 0, shift, w, Height()).AssumeFrameBased() : sisavs26 ? oeven.ConvertToY8().BicubicResize(w, h, b, c, 0, shift, w, Height()).AssumeFrameBased() : oeven.BicubicResize(w, h, b, c, 0, shift, w, Height()) : nop()
  odd=c420 ? sisphbd  ? oodd.ConvertToY().BicubicResize(w, h, b, c, 0, -shift, w, Height()).AssumeFrameBased() : sisavs26 ? oodd.ConvertToY8().BicubicResize(w, h, b, c, 0, -shift, w, Height()).AssumeFrameBased() : oodd.BicubicResize(w, h, b, c, 0, -shift, w, Height()) : nop()

  evenChr=c420 ? sisavs26 ? Interleave(sisphbd  ? oeven.ExtractU() : oeven.UToY8(), sisphbd  ? oeven.ExtractV() : oeven.VToY8()).BicubicResize(w/2, h/2, b, c, 0, shift, w/2, Height()/2).AssumeFrameBased() : oeven.BicubicResize(w, h, b, c, 0, 2*shift, w, Height()) : nop()
  oddChr=c420 ? sisavs26 ? Interleave(sisphbd  ? oodd.ExtractU() : oodd.UToY8(), sisphbd  ? oodd.ExtractV() :oodd.VToY8()).BicubicResize(w/2, h/2, b, c, 0, -shift, w/2, Height()/2).AssumeFrameBased() : oodd.BicubicResize(w, h, b, c, 0, -2*shift, w, Height()) : nop()

  c420 ? !sisavs26 ? Interleave(even, odd).MergeChroma(Interleave(evenChr, oddChr)).AssumeFrameBased() : YToUV(Interleave(evenChr.SelectEven(), oddChr.SelectEven()),Interleave(evenChr.SelectOdd(), oddChr.SelectOdd()),Interleave(even, odd)) : cp.Bob( b,c, h )
  GetParity(cp) ? AssumeTFF() : AssumeBFF()
}


Function sneo_FFT3D(clip input, float "sigma", float "beta", int "bw", int "bh", int "bt", int "ow", int "oh", float "kratio", float "sharpen", float "scutoff", float "svr", float "smin", float "smax", bool "measure", bool "interlaced", int "wintype", int "pframe", int "px", int "py", bool "pshow", float "pcutoff", float "pfactor", float "sigma2", float "sigma3", float "sigma4", float "degrid", float "dehalo", float "hr", float "ht", int "y", int "u", int "v", int "l", int "t", int "r", int "b", int "opt", int "ncpu")
{
y=Default(y,3)
u=Default(u,3)
v=Default(v,3)
	   try { input.neo_fft3d(sigma=sigma, beta=beta, bw=bw, bh=bh, bt=bt, ow=ow, oh=oh, kratio=kratio, sharpen=sharpen, scutoff=scutoff, svr=svr, smin=smin, smax=smax, measure=measure, interlaced=interlaced, wintype=wintype, pframe=pframe, px=px, py=py, pshow=pshow, pcutoff=pcutoff, pfactor=pfactor, sigma2=sigma2, sigma3=sigma3, sigma4=sigma4, degrid=degrid, dehalo=dehalo, hr=hr, ht=ht, y=y, u=u, v=v, l=l, t=t, r=r, b=b, opt=opt, ncpu=ncpu)
} catch(error_msg) { 
plane = y==3 && u!=3 && v!=3 ? 0 : y!=3 && u==3 && v!=3 ? 1 : y!=3 && u!=3 && v==3 ? 2 : y!=3 && u==3 && v==3 ? 3 : 4
input.FFT3DFilter(sigma=sigma, beta=beta, bw=bw, bh=bh, bt=bt, ow=ow, oh=oh, kratio=kratio, sharpen=sharpen, scutoff=scutoff, svr=svr, smin=smin, smax=smax, measure=measure, interlaced=interlaced, wintype=wintype, pframe=pframe, px=px, py=py, pshow=pshow, pcutoff=pcutoff, pfactor=pfactor, sigma2=sigma2, sigma3=sigma3, sigma4=sigma4, degrid=degrid, dehalo=dehalo, hr=hr, ht=ht  , plane=plane, ncpu=ncpu) }
}


Function sneo_dfttest(clip input, int "ftype", float "sigma", float "sigma2", float "pmin", float "pmax", int "sbsize", int "smode", int "sosize", int "tbsize", int "tmode", int "tosize", int "swin", int "twin", float "sbeta", float "tbeta", bool "zmean", float "f0beta", string "nlocation", float "alpha", string "slocation", string "ssx", string "ssy", string "sst", int "ssystem", int "dither", int "y", int "u", int "v", int "opt", int "threads", int "fft_threads", \
                      int "chrftype", float "chrsigma", float "chrsigma2", float "chrpmin", float "chrpmax", int "chrsbsize", int "chrsmode", int "chrsosize", int "chrtmode", int "chrtosize", int "chrswin", int "chrtwin", float "chrsbeta", float "chrtbeta", bool "chrzmean", float "chrf0beta", string "chrnlocation", float "chralpha", string "chrslocation", string "chrssx", string "chrssy", string "chrsst", int "chrssystem")
{
sisavs26  = !(VersionNumber() < 2.60)
sisphbd   = AvsPlusVersionNumber > 2294
y=Default(y,3)
u=Default(u,3)
v=Default(v,3)
sigma=Default(sigma,16.0)
sigma2=Default(sigma2,16.0)
sbsize=Default(sbsize,12)
sosize=Default(sosize,9)
tbsize=Default(tbsize,5)
sislumaonly = sisphbd ? input.isy() : sisavs26 ? input.isy8() : true
dosep = (u==3 || v==3) && !sislumaonly && isYUV(input) && (defined(chrsst) || defined(chrssy) || defined(chrssx) || defined(chrslocation) || defined(chrnlocation) || defined(chrf0beta) || defined(chrzmean) || defined(chrtbeta)
\ || defined(chrsbeta) || defined(chrtwin) || defined(chrswin) || defined(chrtosize) || defined(chrtmode) || defined(chrsosize) || defined(chrsmode) || defined(chrsbsize) || defined(chrpmax)
\ || defined(chrpmin) || defined(chrsigma2) || defined(chrsigma) || defined(chrftype))
dosep ? eval("""
Yclip   = sisphbd ? converttoY(input) : sisavs26 ? converttoY8(input) : input
Uclip   = sisphbd ? ExtractU(input) : sisavs26 ? UToY8(input) : UToY(input)
Vclip   = sisphbd ? ExtractV(input) : sisavs26 ? VToY8(input) : VToY(input)

chrftype     = defined(chrftype) ? chrftype : ftype
chrsigma     = defined(chrsigma) ? chrsigma : sigma
chrsigma2    = defined(chrsigma2) ? chrsigma2 : sigma2
chrpmin      = defined(chrpmin) ? chrpmin : pmin
chrpmax      = defined(chrpmax) ? chrpmax : pmax
chrsbsize    = defined(chrsbsize) ? chrsbsize : sbsize
chrsmode     = defined(chrsmode) ? chrsmode : smode
chrsosize    = defined(chrsosize) ? chrsosize : sosize
chrtmode     = defined(chrtmode) ? chrtmode : tmode
chrtosize    = defined(chrtosize) ? chrtosize : tosize
chrswin      = defined(chrswin) ? chrswin : swin
chrtwin      = defined(chrtwin) ? chrtwin : twin
chrsbeta     = defined(chrsbeta) ? chrsbeta : sbeta
chrtbeta     = defined(chrtbeta) ? chrtbeta : tbeta
chrzmean     = defined(chrzmean) ? chrzmean : zmean
chrf0beta    = defined(chrf0beta) ? chrf0beta : f0beta
chrnlocation = defined(chrnlocation) ? chrnlocation : nlocation
chralpha     = defined(chralpha) ? chralpha : alpha
chrslocation = defined(chrslocation) ? chrslocation : slocation
chrssx       = defined(chrssx) ? chrssx : ssx
chrssy       = defined(chrssy) ? chrssy : ssy
chrsst       = defined(chrsst) ? chrsst : sst
chrssystem   = defined(chrssystem) ? chrssystem : ssystem

Yclip   = y==3 ? Yclip.sneo_dfttest(   ftype=ftype,    sigma=sigma,    sigma2=sigma2,    pmin=pmin,    pmax=pmax,    sbsize=sbsize,    smode=smode,    sosize=sosize, tbsize=tbsize,    tmode=tmode,    tosize=tosize,    swin=swin,    twin=twin,    sbeta=sbeta,    tbeta=tbeta,    zmean=zmean,    f0beta=f0beta,    nlocation=nlocation,    alpha=alpha,    slocation=slocation,    ssx=ssx,    ssy=ssy,    sst=sst,    ssystem=ssystem, dither=dither, y=3, u=1, v=1, opt=opt, threads=threads, fft_threads=fft_threads) : Yclip
Uclip   = u==3 ? Uclip.sneo_dfttest(ftype=chrftype, sigma=chrsigma, sigma2=chrsigma2, pmin=chrpmin, pmax=chrpmax, sbsize=chrsbsize, smode=chrsmode, sosize=chrsosize, tbsize=tbsize, tmode=chrtmode, tosize=chrtosize, swin=chrswin, twin=chrtwin, sbeta=chrsbeta, tbeta=chrtbeta, zmean=chrzmean, f0beta=chrf0beta, nlocation=chrnlocation, alpha=chralpha, slocation=chrslocation, ssx=chrssx, ssy=chrssy, sst=chrsst, ssystem=chrssystem, dither=dither, y=3, u=1, v=1, opt=opt, threads=threads, fft_threads=fft_threads) : Uclip
Vclip   = v==3 ? Vclip.sneo_dfttest(ftype=chrftype, sigma=chrsigma, sigma2=chrsigma2, pmin=chrpmin, pmax=chrpmax, sbsize=chrsbsize, smode=chrsmode, sosize=chrsosize, tbsize=tbsize, tmode=chrtmode, tosize=chrtosize, swin=chrswin, twin=chrtwin, sbeta=chrsbeta, tbeta=chrtbeta, zmean=chrzmean, f0beta=chrf0beta, nlocation=chrnlocation, alpha=chralpha, slocation=chrslocation, ssx=chrssx, ssy=chrssy, sst=chrsst, ssystem=chrssystem, dither=dither, y=3, u=1, v=1, opt=opt, threads=threads, fft_threads=fft_threads) : Vclip

	!sisavs26 && isYUY2(input) ? YToUV(uclip.converttoyuy2(),vclip.converttoyuy2(),yclip.converttoyuy2()) : !(isYUY2(input)) && sisphbd ? CombinePlanes(yclip,uclip,vclip,planes="YUV",sample_clip=input) : YToUV(uclip,vclip,yclip)
	 sisavs26 && isYUY2(input) ? converttoyuy2() : last
""") : \
eval("""
	   try { input.neo_dfttest(ftype=ftype, sigma=sigma, sigma2=sigma2, pmin=pmin, pmax=pmax, sbsize=sbsize, smode=smode, sosize=sosize, tbsize=tbsize, tmode=tmode, tosize=tosize, swin=swin, twin=twin, sbeta=sbeta, tbeta=tbeta, zmean=zmean, f0beta=f0beta, nlocation=nlocation, alpha=alpha, slocation=slocation, ssx=ssx, ssy=ssy, sst=sst, ssystem=ssystem, dither=dither, y=y, u=u, v=v, opt=opt, threads=threads, fft_threads=fft_threads)
} catch(error_msg) { 
nstring = defined(nlocation) && defined(alpha) ? "a:" + string(alpha) + " " + nlocation : nlocation
sstring = defined(slocation) && defined(ssystem) ? ssystem == 1 ? "$" + " " + slocation : slocation : slocation
y=y==3
u=u==3
v=v==3
input.dfttest(ftype=ftype, sigma=sigma, sigma2=sigma2, pmin=pmin, pmax=pmax, sbsize=sbsize, smode=smode, sosize=sosize, tbsize=tbsize, tmode=tmode, tosize=tosize, swin=swin, twin=twin, sbeta=sbeta, tbeta=tbeta, zmean=zmean, f0beta=f0beta, nstring=nstring , sstring=sstring, ssx=ssx, ssy=ssy, sst=sst                   , dither=dither, Y=y, U=u, V=v, opt=opt, threads=threads)  }
""")
}


Function svsTTempSmooth(clip input, int "maxr", int "lthresh", int "cthresh", int "lmdiff", int "cmdiff", int "strength", float "scthresh", bool "fp", bool "y", bool "u", bool "v", clip "pfclip")
{
	   try { input.vsTTempSmooth(maxr=maxr, ythresh=lthresh, uthresh=cthresh, vthresh=cthresh, ymdiff=lmdiff, umdiff=cmdiff, vmdiff=cmdiff, strength=strength, scthresh=scthresh, fp=fp, y=y, u=u, v=v, pfclip=pfclip)
} catch(error_msg) { 
input.TTempSmooth(maxr=maxr, lthresh=lthresh, cthresh=cthresh, lmdiff=lmdiff, cmdiff=cmdiff, strength=strength, scthresh=strength, fp=fp, pfclip=pfclip)  }
}


Function svsTTempSmoothf(clip input, int "maxr", int "lthresh", int "cthresh", int "strength", float "scthresh", bool "fp", bool "y", bool "u", bool "v", clip "pfclip")
{
	   try { input.vsTTempSmooth(maxr=maxr, ythresh=lthresh, uthresh=cthresh, vthresh=cthresh, ymdiff=255, umdiff=255, vmdiff=255, strength=strength, scthresh=scthresh, fp=fp, y=y, u=u, v=v, pfclip=pfclip)
} catch(error_msg) { 
input.TTempSmoothf(maxr=maxr, lthresh=lthresh, cthresh=cthresh, strength=strength, scthresh=scthresh, fp=fp, pfclip=pfclip)  }
}


Function svsMSharpen(clip input, float "threshold", float "strength", bool "highq", bool "mask", bool "luma", bool "chroma")
{
threshold=Default(threshold,15)
strength=Default(strength,100)
	   try { input.vsMSharpen(threshold=threshold/2.55, strength=strength/2.55, mask=mask, luma=luma, chroma=chroma)
} catch(error_msg) { 
input.MSharpen (threshold=round(threshold), strength=round(strength), highq=highq, mask=mask)   }
}


Function svsTBilateral(clip input, int "diameterL", int "diameterC", float "sDevL", float "sDevC", float "iDevL", float "iDevC", float "csL", float "csC", bool "d2", bool "chroma", clip "ppClip", int "kernS", int "kernI", int "resType")
{
	   try { input.vsTBilateral(diameterY=diameterL, diameterU=diameterC, diameterV=diameterC, sDevY=sDevL, sDevU=sDevC, sDevV=sDevC, iDevY=iDevL, iDevU=iDevC, iDevV=iDevC, csY=csL, csU=csC, csV=csC, d2=d2, u=defined(chroma)?chroma?3:2:undefined, v=defined(chroma)?chroma?3:2:undefined, ppClip=ppClip, kernS=kernS, kernI=kernI, resType=resType)
} catch(error_msg) { 
input.TBilateral(diameterL=diameterL, diameterC=diameterC, sDevL=sDevL, sDevC=sDevC, iDevL=iDevL, iDevC=iDevC, csL=csL, csC=csC, d2=d2, chroma=chroma, ppClip=ppClip, kernS=kernS, kernI=kernI, resType=resType)   }
}


Function svsTcanny(clip clip, float "sigma", float "t_h", float "t_l", int "mode", float "gmmax", int "y", int "u", int "v", int "opt") 
{
sigma=Default(sigma,1.5)
	   try { vsTCanny(clip, sigmaY=sigma, sigmaU=sigma, sigmaV=sigma, sigma_vY=sigma, sigma_vU=sigma, sigma_vV=sigma, t_h=t_h, t_l=t_l, mode=mode, op=0, gmmax=gmmax, y=y, u=u, v=v, opt=opt)
} catch(error_msg) { 
sTcannymod(clip, mode=mode, sigma=sigma, t_h=t_h, t_l=t_l, opt=opt, gmmax=gmmax, y=y, u=u, v=v, opt=opt)
}
}


Function sTcannyMod(clip clip, float "sigma", float "t_h", float "t_l", int "mode", float "gmmax", int "y", int "u", int "v", int "opt") 
{
gmmax=Default(gmmax,50)
y=Default(y,3)
u=Default(u,3)
v=Default(v,3)
chroma = max(u,v) == 3 ? 1 : max(u,v) == 2 ? 2 : 0
try { TCannyMod(clip, mode=mode, sigma=sigma, t_h=t_h, t_l=t_l, sobel=false, chroma=chroma, gmmax=gmmax, opt=opt)
} catch(error_msg) { 
plane = y==3 && u!=3 && v!=3 ? 1 : y!=3 && u==3 && v!=3 ? 2 : y!=3 && u!=3 && v==3 ? 4 : y!=3 && u==3 && v==3 ? 6 : y==3 && u==3 && v!=3 ? 3 : y==3 && u!=3 && v==3 ? 5 : 7
TCanny(clip, mode=mode, sigma=sigma, t_h=t_h, t_l=t_l, gmmax=gmmax, plane=plane)
}
}

function sh_GetUserGlobalIMT(bool "setzero")
{
	setzero = default( setzero, false )
	try       { ret = Eval( string(set_plugins_threads) ) }
	catch (e) { ret = setzero ? 0 : Undefined }
	return ret
}


function sh_GetUserGlobalIMTint(bool "setzero")
{
	setzero = default( setzero, false )
	try       { ret = Eval( string(set_plugins_threads_int) ) }
	catch (e) { ret = sh_GetUserGlobalIMT(setzero) }
	return ret
}


function sh_GetUserGlobalIMTbool()
{
	try       { ret = Eval( string(set_plugins_threads_bool) ) }
	catch (e) { ret = defined(sh_GetUserGlobalIMT) ? sh_GetUserGlobalIMT!=1 : Undefined }
	return ret
}


# sChromaShift2: Shift U & V chroma separately with subpixel accuracy, based on the ChromaShiftSP2 function by Asd-g
# try to clone ChromaShift() work
# sChromaShift2 v1.1
function sChromaShift2(clip clp, float "UX", float "UY", float "VX", float "VY", string "ResizeMethod", bool "LinkToY", bool "SPClone") {
sisavs26 = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294

sisyuy2 = clp.isyuy2()
clp = sisavs26 && sisyuy2 ? clp.converttoyv16() : clp
fullchr = sisphbd ? clp.is444() : sisavs26 ? clp.isyv24() : false
chr420  = sisphbd ? clp.is420() : clp.isyv12()
chr422  = sisyuy2 || (sisphbd ? clp.is422() : sisavs26 ? clp.isyv16() : false)
chr411  = sisavs26 ? clp.isyv411() : false
nochr   = sisphbd ? clp.isy() : sisavs26 ? clp.isy8() : false

Assert(!nochr, "sChromaShift2: clip must has chroma")
Assert(!(clp.isrgb()), "sChromaShift2: not work with RGB clip")

UX = default(UX, 0.0) # positive values shift the U chroma to left, negative values to right
UY = default(UY, 0.0) # positive values shift the U chroma upwards, negative values downwards
VX = default(VX,  UX) # positive values shift the V chroma to left, negative values to right
VY = default(VY,  UY) # positive values shift the V chroma upwards, negative values downwards
ResizeMethod = Default(ResizeMethod, "Point")
LinkToY = Default(LinkToY, true)
SPClone = Default(SPClone, ResizeMethod != "Point")

LinkToY = fullchr ? false : LinkToY

UX = UX !=0.0 && LinkToY ? chr411 ? UX/4 : UX/2 : UX
UY = UY !=0.0 && LinkToY && chr420 ? UY/2 : UY
VX = VX !=0.0 && LinkToY ? chr411 ? VX/4 : VX/2 : VX
VY = VY !=0.0 && LinkToY && chr420 ? VY/2 : VY

U = sisphbd ? clp.PlaneToY("U") : sisavs26 ? clp.Utoy8() : clp.Utoy()
V = sisphbd ? clp.PlaneToY("V") : sisavs26 ? clp.Vtoy8() : clp.Vtoy()
w = U.Width()
h = V.Height()
U = SPClone ? Eval("U." + ResizeMethod + "Resize(w, h, UX, UY, w+UX, h+UY)") : Eval("U." + ResizeMethod + "Resize(w, h, -UX, -UY)")
V = SPClone ? Eval("V." + ResizeMethod + "Resize(w, h, VX, VY, w+VX, h+VY)") : Eval("V." + ResizeMethod + "Resize(w, h, -VX, -VY)")

YToUV(U, V, clp)
sisavs26 && sisyuy2 ? converttoyuy2() : last }


#StainlessS helper function ChrEatWhite
Function ChrEatWhite(String S)
{
i=1
C=RT_Ord(S,i)
sss="""
While(C==32||C>=8&&C<=13){
      i=i+1 C=RT_Ord(S,i)}
"""
IsAvsPlus ? eval(sss) : GScript(sss)
return i>1?MidStr(S,i):S
}


VersionNumber() < 2.60 ? eval("""
# Undefined
#
#   Generates an "undefined" variable value.  This function can be used to
#   set an already-defined variable to an undefined state.
#
# USAGE:
#   x = Undefined() # Subsequent calls to Defined(x) will return false.
#
function Undefined(val "dummyArg")
{
    Assert(!Defined(dummyArg), "Undefined: Cannot be called with any arguments.")
    return dummyArg
}
""") : nop()


####################
#### some of StainlessS AvsVersion.avsi https://forum.doom9.org/showpost.php?p=1897680&postcount=5103
Function IsAvsNeo()               { FindStr(VersionString," Neo")!=0}
Function IsAvsPlus()              { FindStr(VersionString,"AviSynth+")!=0||IsAvsNeo}
Function AvsPlusVersionNumber()   { V=VersionString Off=(!IsAvsPlus)?0:FindStr(V,"(r") return (Off==0)?0:V.MidStr(Off+2).Value.Int } # Avs+ & Neo, (More than 4 digits, Max 24 bit, ~16M)