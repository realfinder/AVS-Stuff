####################################
###
### Stab3()
###
### same as Stab2 but with some changes
###
####################################

function Stab3 (clip clp, int "ts", int "range", int "dxmax", int "dymax", bool "UVfix", bool "FixFalPos", float "zoom", int "mirror", float "PAR", clip "Prefilter", int "Luma_Exp", int "FillBorder", clip "FalPosclip", bool "use_ExInpaint", bool "use_InpaintDelogo", bool "use_Feedback") {

ts     = default(ts, 7)        #frames to temporal average for better motion estimation (max. 7)
range  = default(range, 1)     #frames before/after to estimate motion
dxmax  = default(dxmax, Round(clp.width()/180.0)) #maximum deviation in pixels
dymax  = default(dymax, dxmax) #x, and y should be the same
zoom   = default(zoom, 1)      #maximum zoom factor (1 disabled)
u_feed = default(use_Feedback, false)
mirror = default(mirror, u_feed ? 15 : 0)    #Edge filling. 0 off, 15 everything on
PAR    = default(PAR, 1.0)     #PAR of your source
UVfix  = default(UVfix, false)  # Fixes the bug of change of HUE in Depan, not need in depan 1.13.1 and up
bfix   = default(FillBorder, u_feed ? 2 : 1) # 1=Fixes borders of 3 or less pixels wide.
u_ExIn = default(use_ExInpaint, false)
u_InDe = default(use_InpaintDelogo, u_feed)
b3fix  = bfix > 0
FixFalPos  = default(FixFalPos, true) # Fixes borders of 3 or more pixels wide. Use along crop(2,2,-2,-2)...
									  # ...after stab2() to get rid of border issues entirely
Lumae  = default(Luma_Exp, 1) #Luma Rebuild

Pref   = Defined(Prefilter) ? Prefilter : clp
temp   = Pref.TemporalSoften(ts,255,255,25,2) # SC thr to 25 otherwise pans will stutter
rep    = temp.Repair(Pref.TemporalSoften(1,255,255,25,2))
inter  = Interleave(rep,Pref)

# temporal stable auto-contrast (better subpixel detection)
Luma_Expa = Lumae==2 ? AutoAdjust(inter,temporal_radius=10,auto_balance=false,auto_gain=true,use_interp=true,\
           avg_safety=0.25,dark_limit=10,bright_limit=10,gamma_limit=1.0,dark_exclude=0.05,bright_exclude=0.05,\
           chroma_process=0,scd_threshold=16,input_tv=false,output_tv=false,high_bitdepth=false,debug_view=false) : \
            Lumae==1 ? inter.ColorYUV(levels="TV->PC") : inter

mdata = DePanEstimate(Luma_Expa,range=range,pixaspect=PAR,trust=0,dxmax=dxmax,dymax=dymax,zoommax=zoom)

DePan(Defined(Prefilter)?Interleave(rep,clp):inter,data=mdata,offset=-1,mirror=b3fix ? 0 : mirror,pixaspect=PAR,matchfields=false,subpixel=2)
SelectEvery(2,0)

stabclip=last
FalPosclip = !defined(FalPosclip) && FixFalPos && mirror==15 && b3fix ? clp : FalPosclip

# from depansafe() function
b3fix && defined(FalPosclip) ? FalPosclip : FixFalPos ? eval("""
thick = b3fix ? 3.0 : 2.0  # removing >2px wide borders
cropx = dxmax*2
ratiox = "YPlaneMax("+string(ceil(99-thick/cropx*100))+")"

crop(0,0,0,cropx).conditionalfilter(last,clp,ratiox,">","0")
crop(0,height-cropx,0,0).conditionalfilter(last,clp,ratiox,">","0")
crop(0,0,cropx,0).conditionalfilter(last,clp,ratiox,">","0")
crop(width-cropx,0,0,0).conditionalfilter(last,clp,ratiox,">","0")""") : last

subsampl = b3fix ? AvsPlusVersionNumber > 2294 ? !(clp.is444() || clp.isy()) : VersionNumber() < 2.60 ? clp.isyv12() : !(clp.isyv24() || clp.isy8()) : nop()

bfixc = bfix > 0 ? stabclip.FillBorders_stabi(pad=subsampl && mirror!=15 ? 1 : 0,subsample=subsampl,FixFalPos=defined(FalPosclip) || FixFalPos ? last : Undefined, mirror=mirror==15,PAR=PAR, maskonly=bfix > 1) : last
stabbclp = bfix > 1 && u_feed ? BlankClip(bfixc,color_yuv=$000000) : nop()
stabclpa1 = bfix > 1 && u_feed ? stabclip.SCSelect(stabbclp,bfixc,bfixc).ExtractY().Invert() : nop()
stabclpa2 = bfix > 1 && u_feed ? stabclip.SCSelect(stabbclp,stabbclp,bfixc).ExtractY().Invert() : nop()
stabclip = bfix > 1 && u_feed ? Layer(stabclip.AddAlphaPlane(stabclpa1).FeedbackInput(), clp.AddAlphaPlane(stabclpa1)).FeedbackOutput() : stabclip
stabclip = bfix > 1 && u_feed ? stabclip.RemoveAlphaPlane() : stabclip
preclip = mt_merge(stabclip,clp,bfixc,luma=true)
preclip = bfix > 1 && u_feed ? mt_merge(stabclip,preclip,stabclpa2,luma=true).repair(preclip) : preclip
bfix > 1 ? stabclip.FillBorders_stabi(pad=subsampl && mirror!=15 ? 1 : 0,subsample=subsampl,FixFalPos=defined(FalPosclip) || FixFalPos ? last : Undefined, mirror=mirror==15,PAR=PAR, FillBordersc=u_ExIn ? preclip.ExInpaint(bfixc.mt_lut(u=-255,v=-255)) : u_InDe ? preclip.InpaintDelogo(mask=bfixc, Loc="0,0,0,0",dPP=0,dPPm=1,diPP=1,diPPm=0,oPP=1,oPPm=0,Inflate=0) : preclip.InpaintLogo(bfixc)) : bfixc
bfix > 1 && u_feed ? mt_merge(stabclip,last,stabclpa2.sh_Padding(2,2,2,2).mt_expand().crop(2,2,-2,-2),luma=true).repair(preclip) : last

UVfix ? eval("""
lumaf=last
clpDith=Dither_convert_8_to_16()

ScriptClip ("
blue=round((AverageChromaU(clp) - AverageChromaU()) * 256.0)
red=round((AverageChromaV(clp) - AverageChromaV()) * 256.0)

SmoothTweak16(clpDith,saturation=1.0,hue1=min(384,blue),hue2=min(384,red),HQ=true)
DitherPost(stacked=true,prot=false,mode=6,y=1,slice=false)
", args="clp,clpDith" )
Mergeluma(lumaf)
""") : last

}


####################################
###
### FillBorders_stabi()
###
###  (http://forum.videohelp.com/threads/371336)
###
### Function to fill dark (use threshold) borders, in the vein of old FillMargins() function.
### But instead of mirroring or other approaches like resizing, this function fills/interpolates
### missing data from surrounding pixels.
### Useful to use as a clean pass after stab() and crop(x1,y1,x2,y2)
### for the remaining thin black borders (up to 3px)
###
### For borders of 4px and more you can enable FixFalPos, there you supply a clip
### without black borders (ie. before stab() ). It automatically replaces the offended frames.
### Some thick black borders aren't "0" black at all, they show garbage and the 3+1 pixel border
### may not average to 0, so a "thr2" setting is added as threshold, default 7 should be enough.
###
### Below you can still use the the FindBlackBorders() function for manual handling of thick black borders.
### Use ClipClop() for the stab() results according to the statistics file of FindBlackBorders()
###
### Mind you, for FillBorders_stabi() you need to manually load the AVSInpaint plugin:
### LoadCPlugin("AVSInpaint.dll")
###
###  EXPERIMENTAL:
###  Some thick black borders aren't value 0 at all, sometimes they average to 16, so one would
###  need to set thr2 to >16 which will basically bypass the Stab'ed clip in a lot of dark scenes.
###  So probably you might still want to use this for only <4px borders and FindBlackBorders() to
###  manually find the most offending borders and problematic areas.
###
###
### Dependencies:
###
###   masktools     (v2a48 or higher)                   (http://forum.doom9.org/showthread.php?t=98985)
###   GRunT         (v1.0.1 or higher)                  (http://forum.doom9.org/showthread.php?t=139337)
###   AVSInpaint    (v2008.02.23 or higher)             (http://forum.doom9.org/showthread.php?t=133682)
###
####################################

function FillBorders_stabi(clip c, int "thr", int "pad", bool "blur", bool "debug", clip "FixFalPos", int "thr2", bool "mirror", float "PAR", bool "subsample", bool "maskonly", clip "FillBordersc" ) {

thr      = Default(thr, 1)       # Threshold, pixel values below this will be considered borders
pad      = Default(pad, 0)       # Pixels, you can expand the replacement area adding more pixels
                                 # (to deal with dirty borders) (use "1" to deal with 1px b/w chroma, due to the chroma subsampling nature of video)
mirror   = Default(mirror, false)
blur     = Default(blur, mirror) # Blurs the masking for the replacement area. Currently not supported for InpaintLogo()
debug    = Default(debug,false)  # Show the borders that are going to be filled
FalPos   = Defined(FixFalPos)    # If you supply a reference clip borders with 4 or more
                                 # average thr2 pixels will be replaced with the clip's frame
thr2     = Default(thr2, 7)      # Threshold for FalPos, FalPos frames sometimes have garbage borders so you need to increase threshold 
mskonly  = Default(maskonly, false) 
subsampl = Default(subsample,false) 

sisphbd = AvsPlusVersionNumber > 2294

c
contoy = sisphbd ? !isy() : !isy8()
contoy ? sisphbd ? converttoy() : converttoy8() : last
yclip=last
w=width()
h=height()

# 4px or greater
L4=FalPos ? crop(0,0,-w+4,0) : nop()
R4=FalPos ? crop(w-4,0,0 ,0) : nop()
T4=FalPos ? crop(0,0,0,-h+4) : nop()
B4=FalPos ? crop(0,h-4,0 ,0) : nop()
# 3px
L3=crop(0,0,-w+3,0)
R3=crop(w-3,0,0 ,0)
T3=crop(0,0,0,-h+3)
B3=crop(0,h-3,0 ,0)
# 2px
L2=crop(L3,0,0,-1, 0)
R2=crop(R3,1,0,0 , 0)
T2=crop(T3,0,0,0 ,-1)
B2=crop(B3,0,1,0 , 0)
# 1px
L1=crop(L3,0,0,-2,0 )
R1=crop(R3,2,0,0 ,0 )
T1=crop(T3,0,0,0 ,-2)
B1=crop(B3,0,2,0 ,0 )

c
Fill = gScriptClip("""
yclip
pad= blur ? pad+2 : pad

L1A = AverageLuma(L1)
R1A = AverageLuma(R1)
T1A = AverageLuma(T1)
B1A = AverageLuma(B1)

x1o = L1A < thr ? (AverageLuma(L2) < thr ? (AverageLuma(L3) < thr ? 3 : 2) : 1) : 0
x1  = L1A < thr ? x1o+pad : x1o
x2o = R1A < thr ? (AverageLuma(R2) < thr ? (AverageLuma(R3) < thr ? 3 : 2) : 1) : 0
x2  = R1A < thr ? x2o+pad : x2o
y1o = T1A < thr ? (AverageLuma(T2) < thr ? (AverageLuma(T3) < thr ? 3 : 2) : 1) : 0
y1  = T1A < thr ? y1o+pad : y1o
y2o = B1A < thr ? (AverageLuma(B2) < thr ? (AverageLuma(B3) < thr ? 3 : 2) : 1) : 0
y2  = B1A < thr ? y2o+pad : y2o

FalPos = !mskonly && FalPos ? ((x1-pad > 2 || x2-pad > 2 || y1-pad > 2 || y2-pad > 2 )
                          \ ? ((AverageLuma(L4) < thr2) || (AverageLuma(R4) < thr2) || (AverageLuma(T4) < thr2) || (AverageLuma(B4) < thr2)
                          \ ? true : false) : false) : false


cropnpad = (x1+y1+x2+y2>0)
ter = !FalPos && cropnpad

x1inp=cropnpad && subsampl ? int(round(x1o/2.0)*2) : x1
x2inp=cropnpad && subsampl ? int(round(x2o/2.0)*2) : x2
y1inp=cropnpad && subsampl ? int(round(y1o/2.0)*2) : y1
y2inp=cropnpad && subsampl ? int(round(y2o/2.0)*2) : y2

PaCl = mskonly ? nop() : mirror && !ter ? c.crop(x1inp,y1inp,-x2inp,-y2inp,align=true).sh_Padding(x1inp,y1inp,x2inp,y2inp) : c

sispLBox = AvsPlusVersionNumber > 3042
msk  = sispLBox ? LetterBox(BlankClip(last, Color_yuv=$000000),y1,y2,x1,x2, Color_yuv=$ffffff) : LetterBox(BlankClip(last, Color_yuv=$000000),y1,y2,x1,x2,$ffffff)
msk  = sispLBox ? msk : !mirror ? msk.mt_lut("x 128 > 255 x ?") : msk
msk  = !mirror && blur ? msk.mt_convolution("1 1 1 1 1", "1 1 1 1 1") : msk
msk  = contoy ? sisphbd ? CombinePlanes(msk,c,planes="YUV",sample_clip=c) : YToUV(c.UToY8(),c.VToY8(),msk) : msk

fill = mskonly ? msk : FalPos ? trim(c,0,current_frame-1)++trim(FixFalPos,current_frame,-1)++trim(c,current_frame+1,0) : \
                       (ter ? Defined(FillBordersc) ? FillBordersc : InpaintLogo(c, radius=max(x1,y1,x2,y2)+max(2,pad), mask=msk,ChromaTensor=subsampl,PixelAspect=PAR,PreBlur=mirror && blur ? 2.5 : undefined) : PaCl)
sub  = debug  ? subtitle(msk,"Bordered",align=3,size=round(h/20.0)) : nop()

debug ? (ter?sub:msk) : fill
""",args="yclip,c,sisphbd,contoy,thr,thr2,L4,R4,T4,B4,L3,R3,T3,B3,L2,R2,T2,B2,L1,R1,T1,B1,pad,blur,debug,FalPos,FixFalPos,mirror,subsampl,PAR,mskonly,FillBordersc")

!debug ? Fill : \
eval("""
 box    = h/4.0
 m      = 2

 corner = crop(mt_lut("255"),round((w-box)/m)*m,round((h-box)/m)*m,0,0,align=true)
 corner = corner.addborders(0,0,round((w/2.0-box)/m)*m,round(box/m)*m).mt_lut("x 255 < 0 255 ?")

 horiz  = stackhorizontal(corner,corner.fliphorizontal())
 verti  = stackvertical(horiz,horiz.flipvertical())

 mt_merge(c,Fill.pointresize(w,h),verti,luma=true)""") }
