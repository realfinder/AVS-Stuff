###                                                      #
###                                                      #
### Stabilization Tools Pack 2.1 by Dogway (18-09-2020)  #
###                 mod 2.537 by A.SONY in (01-06-2021)  #
###                                                      #
##########################################################
###
### FilmGateFix()
###
###  (http://forum.videohelp.com/threads/371336)
###
### Function to fix frames ( by means of FreezeFrame() ) with film gate issues after a scene change.
### This is aimed at animation, for live footage frame interpolation should be desired.
###
### Rationale:
### Film Gate is about non-linear vertical stretching, thus we compare
### current and next frames in two blocks, a 1/5 block of top and bottom.
### The difference in both should be very high for film gate artifacts
### between the 2nd and 3rd frame after a Scene Change (also 1st and 2nd are compared).
### We mask this through a Scene Detection filter, motion masks, etc.
###
###  EXPERIMENTAL:
###  It still grabs too many false-positives, and leaves many positives-positives undone
###  a better approach would be to automatically bookmark every scene change and manually freezeframe them
###
###
### Dependencies:
###
### Required:
### ------------
###
###   MVTools       (v2.5.11.3 or higher)               (http://avisynth.org.ru/mvtools/mvtools2.html)
###   masktools     (v2a48 or higher)                   (http://forum.doom9.org/showthread.php?t=98985)
###   Average       (v0.92 or higher)                   (http://forum.doom9.org/showthread.php?t=169832)
###   GRunT         (v1.0.1 or higher)                  (http://forum.doom9.org/showthread.php?t=139337)
###
####################################

function FilmGateFix(clip c,  float "thr", int "window", int "thSCD1", int "thSCD2", bool "debug") {

thr     = Default(thr,1.2)      # Main tweak setting, use debug and tweak according 2nd frame after Scene Change
window  = Default(window,5)     # Enlarges/reduces detection area, "height()/window"
thSCD1  = Default(thSCD1,500)   # Increase to reduce number of scenes detected
thSCD2  = Default(thSCD2,145)   # Increase to reduce number of scenes detected
Debug   = Default(Debug,false)  # Check what frames will be fixed and the difference value of frames for tweaking "thr"
thr2    = 5.0                   # central part of frame must change less than this to consider static scene to fix.

c
w=width()
h=height()

# Block for Scene Change detection and Motion Mask
kind   = 0
gam    = 1.2 # Could probably be exposed
mvthr  = 30  # Threshold, heavily dependent on gamma value above
super  = MSuper  (pel=1, sharp=0,vpad=0,hpad=0)
b1v    = MAnalyse(super,isb=true, blksize=16,overlap=8,search=0)
f1v    = MAnalyse(super,isb=false, blksize=16,overlap=8,search=0)
SADbv1 = MMask   (b1v,kind=kind,gamma=gam,thSCD1=thSCD1,thSCD2=thSCD2)
SADfv1 = MMask   (f1v,kind=kind,gamma=gam,thSCD1=thSCD1,thSCD2=thSCD2)

SceneChange = MSCDetection (f1v,thSCD1=thSCD1,thSCD2=thSCD2)
mvmask      = Average(SADbv1,1./2,SADfv1,1./2)


# Film Gate happens commonly between 2nd and 3rd frame after SC
# 1st frame is commonly garbage
add  = round(w/(window*1.0))
T    = crop(0,0,0,((-h+add)/8)*8)
B    = crop(0,((h-add)/8)*8,0,0)

L    = crop(0,0,((-w+add)/8)*8,0)
R    = crop(((w-add)/8)*8,0,0,0)

CTB  = crop(0,((add)/8)*8,0,-((add)/8)*8)
CLR  = crop(round(((add*1.5)/8)*8),0,round(-((add*1.5)/8)*8),0)

SC2  = mt_logic(SceneChange,selectevery(SceneChange,1,-1),"max",U=3,V=3)

# Here, if after SC top area changes more than "thr" compared to bottom area
# then apply one FreezeFrame() for first SC frame, and another FreezeFrame() for the 2nd one,
# they (1st and 2nd) compute individually. There is a motionmask on top to rule out false positives.
scriptclip("""(abs(YDifferenceToNext(T)-YDifferenceToNext(B))>"""+string(thr)+""" && abs(YDifferenceToNext(CTB))<"""+
            \ string(thr2)+""") || (abs(YDifferenceToNext(L)-YDifferenceToNext(R))>"""+string(thr)+
            \ """ && abs(YDifferenceToNext(CLR))<"""+string(thr2)+""") ?"""+
            \ """(YplaneMax(SC2)>254?(YDifferenceFromPrevious(SC2)>250?(AverageLuma(mvmask)<"""+string(mvthr)+
            \ """?(LumaDifference(c,d)<3.7?freezeframe(current_frame,current_frame,current_frame+2):(YDifferenceToNext()<8.0?freezeframe(current_frame,current_frame,current_frame+1):c)):c):"""+
            \ """(AverageLuma(mvmask)<"""+string(mvthr)+"""?freezeframe(current_frame,current_frame,current_frame+1):c)):c):c""",
            \ args="T,B,L,R,c,SC2,CTB,CLR,mvmask,d=Trim(2,0)")

# Debug block
debug ? +\
eval("""stackhorizontal(scriptclip("Subtitle(c,"+Chr(34)+" Top & Bottom:"+Chr(34)+"+String(YDifferenceToNext(T)-YDifferenceToNext(B))+
       \ "+Chr(34)+"\n Left & Right:  "+Chr(34)+"+String(YDifferenceToNext(L)-YDifferenceToNext(R))+
       \ "+Chr(34)+"\n Center Horiz:  "+Chr(34)+"+String(YDifferenceToNext(CTB))+
       \ "+Chr(34)+"\n Center Vert:    "+Chr(34)+"+String(YDifferenceToNext(CLR))+
       \ "+Chr(34)+"\n AvgLuma:    "+Chr(34)+"+String(LumaDifference(c,d)),
       \ align=7,size=30,lsp=10)",args="T,B,L,R,c,CTB,CLR,d=Trim(2,0)"),
       \ scriptclip("AverageLuma(mvmask)<"""+string(mvthr)+"""?((abs(YDifferenceToNext(T)-YDifferenceToNext(B))>"+string(thr)+
           \ " && abs(YDifferenceToNext(CTB))<"+string(thr2)+") || (abs(YDifferenceToNext(L)-YDifferenceToNext(R))>"+
           \ string(thr)+" && abs(YDifferenceToNext(CLR))<"+string(thr2)+") ? "+
           \ "(YplaneMax(SC2)>254?(LumaDifference(c,d)<3.7?mt_lut(c,"+Chr(34)+"255"+Chr(34)+",U=128,V=128):(YDifferenceToNext()<8.0?mt_lut(c,"+Chr(34)+"255"+Chr(34)+",U=128,V=128):mt_lut(c,"+Chr(34)+"0"+Chr(34)+
           \ ",U=128,V=128))):mt_lut(c,"+Chr(34)+"0"+Chr(34)+",U=128,V=128)):mt_lut(c,"+Chr(34)+"0"+Chr(34)+",U=128,V=128)):mt_lut(c,"+Chr(34)+"0"+
           \ Chr(34)+",U=128,V=128)",args="T,B,L,R,c,CTB,CLR,SC2,mvmask,d=Trim(2,0)"))
           \ crop(0,0,-(round(w/1.1)/2)*2,0).Subtitle("Frame to Freeze",align=9,size=40)""") : last }





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


####################################
###
### FindBlackBorders()
###
###  (http://forum.videohelp.com/threads/371336)
###
### Script to find sources with black borders for example as a result of bad deshaking, run on analysis pass
### The output file is formatted to be imported to avspmod as bookmarks
### use ClipClop() afterwards on a scene by scene basis to fix this.
###
### "width" is border thickness for detection
### "thr" is threshold, pixel values below this will be considered borders
### "path" is the path to store the statistics file, with end backslash. Default is "C:"
### "filename" is the statistics file name. In case you don't want to overwrite old ones
###
### Dependencies:
###
### Required:
### ------------
###
###   masktools     (v2a48 or higher)                   (http://forum.doom9.org/showthread.php?t=98985)
###   Dither        (v1.26.5 or higher)                 (http://forum.doom9.org/showthread.php?p=1386559#post1386559)
###
####################################

function FindBlackBorders(clip c, int "width", int "thr", string "path", string "filename") {

add      = Default(width,1)     # Width for detection, normally 1 should suffix to most situations
thr      = Default(thr,1)       # Threshold for detection, pixels lower than this value will be considered a border
path     = Default(path, "C:")  # This is the path to store the statistics file
filename = Default(filename, "FindBlackBorders - Statistics.log") # Filename of the statistics file

c
converttoy8()
w=width()
h=height()

L1=crop(0,0,-w+add,0)
R1=crop(w-add,0,0 ,0)
T1=crop(0,0,0,-h+add)
B1=crop(0,h-add,0 ,0)

ScriptClip("""
x1 = AverageLuma(L1) < thr ? true : false
x2 = AverageLuma(R1) < thr ? true : false
y1 = AverageLuma(T1) < thr ? true : false
y2 = AverageLuma(B1) < thr ? true : false
function IsBorder(clip c, bool x1, bool x2, bool y1, bool y2) {return (x1||y1||x2||y2)?true:false}

q = chr(34)chr(34)chr(34)
WriteFileIf(""+path+"\"+filename+"", " "+string(IsBorder(x1,y1,x2,y2))+" ", q+"CHAPTER00="+q,
        \ "FFFormatTime_stabi(round((current_frame * 1000) / framerate()))", "", "")
""",args="thr,L1,R1,T1,B1,path,filename")

converttoyv12()

# Bug or limitations of 8-bit masktools with Overlay or...
# mt_merge (masking PC Range masks) so use Dither tools
Dither_merge16_8(Dither_convert_8_to_16(),Dither_convert_8_to_16(c),mt_lut("255"),luma=true)
ditherpost(mode=-1) }



####################################
###
### Stab2()
###
###  (http://forum.videohelp.com/threads/371336)
###
### For completeness I'm going to list all the shortcomings of Depan plugin
### maybe a programmer realises the urge of an avisynth bug-free stabilizer:
### -Color tint (hue shift to green) when subpixel>0 to stablizated frames --> addressed here
### -Artifacts occasionally on frame borders (1px skew) --> crop out, check example
### -No advanced border fill --> addressed above ( FillBorders_stabi() )
### -Some false-positives when people clapping, trembling...
### -Requires mod 4 inputs?
### -No medium jitter fix
### -Some thick borders (false positives) aren't 0 black on the inner side
###
#######################################
###
### What I improved over original Stab() was to work around the first issue by
### 	counter fixing the planes hue deviation on a frame by frame basis with float point precision
### Implemented a FixPalPos to replace frames that present black borders of 3 or more pixels
### 	with source frames, check output just in case, since some borders don't average to 0 black (rare).
### Also supplied a more contrasty clip version for more subtle global motion analysis
### Prefilter is for the prefilter clip, in case the clip is very grainy/noisy
### Finally a few more things were introduced by testing and checking other script versions.
###
###
### Required (*Optional):
### ------------
###   Depan         (v1.10.1 or higher)                 (http://avisynth.org.ru/depan/depan.html)
###   DePanEstimate (v1.10.1 or higher)                 (http://avisynth.org.ru/depan/depan.html)
###   Dither        (v1.26.5 or higher)                 (http://forum.doom9.org/showthread.php?p=1386559#post1386559)
###   SmoothAdjust* (v3.0 or higher)                    (http://forum.doom9.org/showthread.php?t=154971)
###   AutoAdjust    (v2.50 or higher)                   (http://forum.doom9.org/showthread.php?t=167573)
###   GRunT         (v1.0.1 or higher)                  (http://forum.doom9.org/showthread.php?t=139337)
###   Repair        (vanilla or tp7's branch)           (http://avisynth.nl/index.php/Removegrain)
###
### Example:
###
### stab2(UVfix=true,FixFalPos=true)
### crop(2,2,-2,-2) # to remove garbage around borders
###
####################################

function Stab2 (clip clp, int "ts", int "range", int "dxmax", int "dymax", bool "UVfix", bool "FixFalPos", float "zoom", int "mirror", float "PAR", clip "Prefilter") {

ts     = default(ts, 7)        #frames to temporal average for better motion estimation (max. 7)
range  = default(range, 3)     #frames before/after to estimate motion
dxmax  = default(dxmax, 15)    #maximum deviation in pixels (use at least 8 for SD)
dymax  = default(dymax, 15)    #x, and y should be the same
zoom   = default(zoom, 1)      #maximum zoom factor (1 disabled)
mirror = default(mirror, 0)    #Edge filling. 0 off, 15 everything on
PAR    = default(PAR, 1.0)     #PAR of your source
UVfix  = default(UVfix, true)  # Fixes the bug of change of HUE in Depan,
FixFalPos  = default(FixFalPos, true) # Fixes borders of 3 or more pixels wide. Use along crop(2,2,-2,-2)...
									  # ...after stab2() to get rid of border issues entirely

Pref   = Defined(Prefilter) ? Prefilter : clp
temp   = Pref.TemporalSoften(ts,255,255,25,2) # SC thr to 25 otherwise pans will stutter
rep    = temp.Repair(Pref.TemporalSoften(1,255,255,25,2))
inter  = Interleave(rep,Pref)

# temporal stable auto-contrast (better subpixel detection)
Luma_Expa = AutoAdjust(inter,temporal_radius=10,auto_balance=false,auto_gain=true,use_interp=true,\
           avg_safety=0.25,dark_limit=10,bright_limit=10,gamma_limit=1.0,dark_exclude=0.05,bright_exclude=0.05,\
           chroma_process=0,scd_threshold=16,input_tv=false,output_tv=false,high_bitdepth=false,debug_view=false)

mdata = DePanEstimate(Luma_Expa,range=range,pixaspect=PAR,trust=0,dxmax=dxmax,dymax=dymax,zoommax=zoom)

DePan(Defined(Prefilter)?Interleave(rep,clp):inter,data=mdata,offset=-1,mirror=mirror,pixaspect=PAR,matchfields=false,subpixel=2)
SelectEvery(2,0)

# from depansafe() function
FixFalPos ? eval("""
thick = 2.0  # removing >2px wide borders
cropx = ceil(dxmax)*2
ratiox = "YPlaneMax("+string(ceil(99-thick/cropx*100))+")"

crop(0,0,0,cropx).conditionalfilter(last,clp,ratiox,">","0")
crop(0,height-cropx,0,0).conditionalfilter(last,clp,ratiox,">","0")
crop(0,0,cropx,0).conditionalfilter(last,clp,ratiox,">","0")
crop(width-cropx,0,0,0).conditionalfilter(last,clp,ratiox,">","0")""") : last


UVfix ? eval("""
clpDith=Dither_convert_8_to_16()

ScriptClip ("
blue=round((AverageChromaU(clp) - AverageChromaU()) * 256.0)
red=round((AverageChromaV(clp) - AverageChromaV()) * 256.0)

SmoothTweak16(clpDith,saturation=1.0,hue1=min(384,blue),hue2=min(384,red),HQ=true)
DitherPost(stacked=true,prot=false,mode=6)
", args="clp,clpDith" )
""") : last
}


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


######### HELPER FUNCTIONS #########

# Helper function for FindBlackBorders() from FFMS2.avsi
function FFFormatTime_stabi(int ms) {
    s = ms / 1000
    ms = ms % 1000
    m = s / 60
    s = s % 60
    h = m / 60
    m = m % 60
    return string(h) + ":" + string(m,"%02.0f") + ":" + string(s,"%02.0f") + "." + string(ms,"%03.0f")}