################################################################################################
###                                                                                          ###
###                        Simple MDegrain Mod - NotSMDegrain()                              ###
###                                                                                          ###
###                       Mod by Dogway - Original idea by Caroliano                         ###
###                                                                                          ###
###          Special Thanks: Sagekilla, Didée, cretindesalpes, Gavino and MVtools people     ###
###                                                                                          ###
###                       v3.1.2d (Dogway's mod) - 21 July 2015                              ###
###   v3.1.2.115s mod for v3.1.2d to fix subpixel=3 and add Prefilter auto 16 (lsb) support  ###
###                     and yuy2 support in avs 2.6 with masktools 2.6                       ###
### and medianblur2 now will be used in Minblur instead of Quantile RemoveGrainHD in avs 2.6 ###
###                                    and add TV_range bool                                 ###
###               less lsb if not use lsb things and get ready for yv16 and yv24             ###
###              add dct, device_id and move all prefilters to external function             ###
###                                some cleanup and others                                   ###
###                        add MDegrain4 and MDegrain5 and MDegrain6                         ###
###                               add always_MDegrainN bool                                  ###
###                                     SH_KNLMeansCL                                        ###
###                 masktools 2.2.15 or up now required in avs26 and avs+                    ###
###                  now work basically with new high bit depth in avs+                      ###
###                   now has new parameters bool n16 and bool n16_out                       ###
###                                                                                          ###
################################################################################################
###
### General purpose simple degrain function. Pure temporal denoiser. Basically a wrapper(function)/frontend of mvtools2+mdegrain
### with some added common related options. Goal is accessibility and quality but not targeted to any specific kind of source.
### The reason behind is to keep it simple so aside masktools2 you will only need MVTools2.
###
### Check documentation for deep explanation on settings and defaults.
###
################################################################################################

function NotSMDegrain (clip input   , int "tr"      , int "thSAD"    , int  "thSADC" , bool "RefineMotion",  val  "contrasharp", clip "CClip"      , bool "interlaced" ,  int   "plane" ,  int   "Globals",                                  \
                     int "pel"   , int "subpixel", val "prefilter", clip "mfilter", int  "blksize"     , int  "overlap"     ,  int  "search"    , bool "truemotion" , float "limit"  ,  float "limitc" ,  int   "thSCD1" , int "thSCD2",  \
                    bool "chroma", int "hpad"    , int "vpad"     , bool "lsb"    , bool "lsb_in"      ,  bool "lsb_out"    , int  "mode"       , bool  "slices"    , val  "Show"    ,  float "Str"    ,  float "Amp" , bool "TV_range", int "dct", int "device_id", int "searchparam", int "pelsearch", bool "trymany", bool "always_MDegrainN", bool "n16", bool "n16_out", int "divide", int "srfilter", int "threads", bool "nf32", bool "nf32_out", bool "MCContraSharp"){



# Defaults & Conditionals


tr           = default( tr,       2 )
thSAD        = default( thSAD,  300 )
thSAD2=int(thSAD/2)
thSADC       = default( thSADC, thSAD2)
RefineMotion = default( RefineMotion, false)
alway_grainN = default( always_MDegrainN, false)
srfilter     = default( srfilter, 4)
Threads      = default( Threads, sh_GetUserGlobalIMTint())

lsb_in       = default( lsb_in,  false)
lsb_out      = default( lsb_out, false)
lsb          = default( lsb    , lsb_in || lsb_out)
mode         = default( mode, 0 )
mode         = mode != 9 ? mode : -1
ampn         = mode != 9 ? 0.0  : 1.0
slices       = default(slices, true)

Globals      = default( Globals,  0 )
GlobalR = Globals == 1 
GlobalO = Globals == 3 
if1     = Defined(CClip)

Contrasharp  = default( Contrasharp, !GlobalO && if1)
Interlaced   = default( Interlaced,  false)

w       = input.width ()
h       = input.height()
sShow   = IsString(show)
preclip = IsClip(prefilter)
planar  = IsYUY2(input)
ifC     = IsBool(Contrasharp)
if0     = ifC ? (Contrasharp  ? true : false) : (Contrasharp > 0.0 ? true : false)
if2     = if0 && lsb && !GlobalO
avs26   = VersionNumber() < 2.60 ? false : true
sisphbd = AvsPlusVersionNumber > 2294
SBitsn  = sisphbd ? input.BitsPerComponent() : 8
n16_out = default( n16_out,  false)
n16     = default( n16,  n16_out)
n32_out = default( nf32_out,  false)
n32     = default( nf32,  n32_out)
if3     = alway_grainN ? true : !avs26 ? tr > 3 : tr > 6
if4     = (w > 1099 ||  h > (lsb_in ? 1199 : 599))
if5     = interlaced ? (GetParity(input)                            ? true : false) : nop()
MCCS    = default( MCContraSharp, if4)


pel          = default( pel, if4 ? 1 : 2 )
subpixel     = default( subpixel,  2 )
prefilter    = default( prefilter, -1 )
MFilterB     = defined(mfilter)
pelclip      = pel>1 && subpixel == 3
Str          = default( Str, 1.0 )
Amp          = default( Amp, 0.0625 )
TV_range     = default( TV_range, !(Isrgb(input)))

blksize      = default( blksize,  if4 ? 16 : 8 )
blk2=blksize/2
overlap      = default( overlap,  blk2 )
ovl2=overlap/2
search       = default( search,   4 )
truemotion   = default( truemotion, !if4)
dct          = default( dct,   0 )
thSCD1       = default( thSCD1,  int(pow((blksize*2.5),2)))
thSCD2       = default( thSCD2,  130 )


plane        = default( plane,    4 )
chroma       = default( chroma, true)
Chr          = chroma ? 3 : 1
Chr2         = chroma ? 3 : preclip ? 1 : (prefilter==3 ? 2 : 1)
plane0       = plane!=0
U            = plane0 && plane!=2 ? 3 : 2
V            = plane0 && plane!=1 ? 3 : 2
Uin          = lsb_in ? 3 : u
Vin          = lsb_in ? 3 : v


hpad         = blksize
vpad         = blksize
limit        = default( limit,  255 )
limitc       = default( limitc,limit)
limit        = avs26 ? limit : round(limit)
limitc       = avs26 ? limitc : round(limit)

Show         = default( Show,  false)




# Error Report

                  Assert(blksize==4 || blksize==8 || blksize==16 || blksize==32,"MAnalyse: Block's size must be 4x4, 8x4, 8x8, 16x2, 16x8, 16x16, 32x16, 32x32")
                  Assert(overlap <= blk2,              "Overlap must be at least half blksize or less")
                  Assert(overlap == overlap-overlap%2, "MAnalyse: overlap must be an even figure")
                  Assert(IsBool(Show) || sShow,        "'Show' only accepts bool inputs (true,false), or string modes ('Speed','Memory',Quality')")
                  Assert(preclip || IsInt(prefilter),  "'prefilter' only accepts integers and clip inputs")
                  Assert(ifC     || IsInt(Contrasharp),"'Contrasharp' only accepts integers and bool inputs")
MFilterB        ? Assert(IsClip(mfilter),              "'mfilter' only accepts clip inputs")                        : nop()
interlaced      ? Assert(h%4==0,                       "Interlaced sources require mod 4 height sizes")             : nop()
lsb_in          ? Assert(!interlaced,                  "Interlaced 16 bit stacked clip is not a recognized format") : nop()
planar && if0   ? Assert(ifC || avs26,                 "LSFmod doesn't support YUY2 sources")                       : nop()
RefineMotion    ? Assert(blksize > 7,                  "For RefineMotion you need a blksize of at least 8")         : nop()
lsb_in          ? Assert(lsb,                          "lsb_in  requires: lsb=true")                                : nop()
lsb_out         ? Assert(lsb,                          "lsb_out requires: lsb=true")                                : nop()
n16_out         ? Assert(n16,                          "n16_out requires: n16=true")                                : nop()
n32_out         ? Assert(n32,                        "nf32_out requires: nf32=true")                                : nop()
                  Assert(!((n16 || n32) && lsb),                          "you can't use n16/nf32 with lsb") 



# RefineMotion Variables

halfblksize  = RefineMotion ?  blk2                                     : nop() # MRecalculate works with half block size
halfoverlap  = RefineMotion ? (overlap == 2 ? overlap : ovl2+ovl2%2)    : nop() # Halve the overlap to suit the halved block size
halfthSAD    = RefineMotion || if3 ?     thSAD2                         : nop() # MRecalculate uses a more strict thSAD, which defaults to 150 (half of function's default of 300)
halfthSADC   =                 if3 ? int(thSADC/2)                      : nop() # For MDegrainN()






# Input preparation for: LSB_IN, Interlacing, Planar and MSuper optimization when pel=2

inputY  = planar      ? (lsb_in   ? Dither_YUY2toPlanar16(input)          : Interleaved2planar(input))                          : input

inputP  = !interlaced ? (pel == 2 ? inputY.AssumeFrameBased()             : inputY)                                             : \
                        (if5      ? inputY.AssumeTFF().SeparateFields()   : inputY.AssumeBFF().SeparateFields())

input8h = lsb_in      ?             inputP. Ditherpost(mode=6, slice=slices)                                                    : nop()
input8y = planar      ? (lsb_in   ? input8h.Dither_YUY2toInterleaved()    : inputP)                                             : inputP
input8  = lsb_in      ? (planar   ? input8y.Interleaved2planar()                                                                : \
                                    input8h)                                                                                    : input8y


# Prefilter & Motion Filter

Mfilter = MFilterB ? Mfilter : input8

bug_wa = interlaced && planar && chroma && !avs26 ? 2 : Chr # bug: crash prevention workaround

pref   = !GlobalR ? preclip ? prefilter                                                                                                                                   : \
                              input.NotSMDegrain_prefilters(inputP=inputP,input8=input8,input8y=input8y\
                                                                      ,inputY=inputY,input8h=input8h,prefilter=prefilter,chroma=chroma\
                                                                      ,Chr=Chr,Chr2=Chr2,bug_wa=bug_wa,lsb=lsb,lsb_in=lsb_in,Interlaced=Interlaced\
                                                                      ,if5=if5,pel=pel,device_type="GPU",device_id=device_id,a=1,d=1,h=7.0,slices=slices,planar=planar,cplace="mpeg1")   : \
                    input8





# Default Auto-Prefilter - Luma expansion TV->PC (up to 16% more values for motion estimation)

pref16 = (Height(pref)) == (Height(input8)*2) ? true : false
pref   = !GlobalR ? (!planar && lsb ? ((!preclip ? ((lsb_in && prefilter==-1) || prefilter==3 || prefilter==4 ) : false)          ? \
                     !TV_range ? pref.Ditherpost(mode=6,ampn=0.0,slice=slices,staticnoise=false,u=Chr2,v=Chr2)                                      : \
                     pref.Dither_Luma_Rebuild(S0=Str,c=Amp,slice=slices,lsb_in=true,uv=Chr2)                                      : \
                     !TV_range ? pref16 ? pref.Ditherpost(mode=6,ampn=0.0,slice=slices,staticnoise=false,u=Chr2,v=Chr2) : pref                                      : \
                     pref.Dither_Luma_Rebuild(S0=Str,c=Amp,slice=slices,lsb=true,lsb_in=pref16,uv=Chr2))                       : \
                                      ((!preclip ?  (lsb_in && prefilter==-1)                                   : false)                                 ? \
                     !TV_range ? !planar ? pref.Ditherpost(mode=6,slice=slices,u=Chr,v=Chr) : pref.Ditherpost(mode=6,slice=slices,u=Chr,v=Chr).Dither_YUY2toInterleaved().Interleaved2planar(!chroma)   : \
                                 !planar ? pref.Dither_Luma_Rebuild(S0=Str,c=Amp,uv=chr, lsb_in=true) : pref.Dither_Luma_Rebuild(S0=Str,c=Amp,uv=chr, lsb_in=true).Dither_YUY2toInterleaved().Interleaved2planar(!chroma) : \
                     !TV_range ? pref16 ? !planar ? pref.Ditherpost(mode=6,slice=slices,u=Chr,v=Chr) : pref.planar2Interleaved(!chroma).Dither_YUY2toPlanar16().Ditherpost(mode=6,slice=slices,u=chr,v=chr).Dither_YUY2toInterleaved().Interleaved2planar(!chroma) : pref                                  : \
                     pref.Dither_Luma_Rebuild(S0=Str,lsb=lsb,lsb_in=pref16,slice=slices,c=Amp,uv=bug_wa)))                                  : \
                     pref

pref = sisphbd ? (n16 || n32) && sbitsn != pref.BitsPerComponent() ? pref.ConvertBits(sbitsn,dither=1) : pref : pref



mvt2mt = Defined(threads) ? ",mt=" + string(threads!=1) : ""
md16str = mvt2mt + (n32 ? ",out32=true" : n16 ? ",out16=true" : lsb ? ",lsb=true" : "")

(sShow ? false : !Show) ? eval("""


# Subpixel 3

pclip  = pelclip              ?    pel==4 ? pref.nnedi3_rpow2(rfactor=2,nns=4,threads=threads).nnedi3_rpow2(rfactor=2,nns=4,threads=threads) :   pref.nnedi3_rpow2(rfactor=2,nns=4,threads=threads)  : nop()
pclip2 = pelclip && !GlobalR  ?  pel==4 ? input8.nnedi3_rpow2(rfactor=2,nns=4,threads=threads).nnedi3_rpow2(rfactor=2,nns=4,threads=threads) : input8.nnedi3_rpow2(rfactor=2,nns=4,threads=threads)  : nop()




# Motion vectors search


super_search =                             pelclip ? MSuper(pref,     pel=pel,               chroma=chroma, hpad=hpad, vpad=vpad,          pelclip=pclip,  rfilter=srfilter, planar=planar"""+mvt2mt+""") : \
                                                     MSuper(pref,     pel=pel,sharp=subpixel,chroma=chroma, hpad=hpad, vpad=vpad                        ,  rfilter=srfilter, planar=planar"""+mvt2mt+""")
super_render = !GlobalR ?                 (pelclip ? MSuper(input8,   pel=pel,               chroma=plane0, hpad=hpad, vpad=vpad,levels=1, pelclip=pclip2                  , planar=planar"""+mvt2mt+""") : \
                                                     MSuper(input8,   pel=pel,sharp=subpixel,chroma=plane0, hpad=hpad, vpad=vpad,levels=1                                  , planar=planar"""+mvt2mt+""")): super_search
Recalculate  = !GlobalR && RefineMotion ? (pelclip ? MSuper(pref,     pel=pel,               chroma=chroma, hpad=hpad, vpad=vpad,levels=1, pelclip=pclip                   , planar=planar"""+mvt2mt+""") : \
                                                     MSuper(pref,     pel=pel,sharp=subpixel,chroma=chroma, hpad=hpad, vpad=vpad,levels=1                                  , planar=planar"""+mvt2mt+""")): nop()
!if3  ? eval("
t2 = interlaced ? tr > 1 ? tr*2 : tr : tr
bv12 =   interlaced && (tr > 5)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta =12,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv12) : nop()
bv12 =   interlaced && (tr > 5) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate,bv12,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv12
bv10 =   interlaced && (tr > 4)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta =10,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv10) : nop()
bv10 =   interlaced && (tr > 4) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate,bv10,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv10
bv8  =   interlaced && (tr > 3)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 8,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv8)  : nop()
bv8  =   interlaced && (tr > 3) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, bv8,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv8
bv6  =                  t2 > 5                   ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 6,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv6)  : nop()
bv6  =                  t2 > 5  && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, bv6,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv6
bv5  =  !interlaced ? ((tr > 4)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 5,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv5)  : nop()) : nop()
bv5  =  !interlaced ? ((tr > 4  && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, bv5,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv5)  : nop()
bv4  =                  t2 > 3                   ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 4,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv4)  : nop()
bv4  =                  t2 > 3  && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, bv4,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv4
bv3  =  !interlaced ? ((tr > 2)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 3,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv3)  : nop()) : nop()
bv3  =  !interlaced ? ((tr > 2  && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, bv3,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv3)  : nop()
bv2  =  (interlaced ||  tr > 1)                  ? (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 2,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv2)  : nop()
bv2  = ((interlaced ||  tr > 1) && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, bv2,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv2
bv1  =  !interlaced ?                              (!GlobalR  ? super_search.MAnalyse(isb = true, delta = 1,  overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : bv1)  : nop()
bv1  =  !interlaced ?            ( RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, bv1,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              bv1)  : nop()

fv1  =  !interlaced ?                              (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 1, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv1)  : nop()
fv1  =  !interlaced ?            ( RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, fv1,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv1)  : nop()
fv2  =  (interlaced ||  tr > 1)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 2, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv2)  : nop()
fv2  = ((interlaced ||  tr > 1) && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, fv2,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv2
fv3  =  !interlaced ? ((tr > 2)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 3, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv3)  : nop()) : nop()
fv3  =  !interlaced ? ((tr > 2  && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, fv3,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv3)  : nop()
fv4  =                  t2 > 3                   ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 4, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv4)  : nop()
fv4  =                  t2 > 3  && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, fv4,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv4
fv5  =  !interlaced ? ((tr > 4)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 5, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv5)  : nop()) : nop()
fv5  =  !interlaced ? ((tr > 4  && RefineMotion &&  !GlobalR) ?   MRecalculate           (Recalculate, fv5,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv5)  : nop()
fv6  =                  t2 > 5                   ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 6, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv6)  : nop()
fv6  =                  t2 > 5  && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, fv6,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv6
fv8  =   interlaced && (tr > 3)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta = 8, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv8)  : nop()
fv8  =   interlaced && (tr > 3) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate, fv8,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv8
fv10 =   interlaced && (tr > 4)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta =10, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv10) : nop()
fv10 =   interlaced && (tr > 4) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate,fv10,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv10
fv12 =   interlaced && (tr > 5)                  ? (!GlobalR  ? super_search.MAnalyse(isb = false, delta =12, overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : fv12) : nop()
fv12 =   interlaced && (tr > 5) && RefineMotion &&  !GlobalR  ?   MRecalculate           (Recalculate,fv12,   overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma, truemotion=truemotion, divide=divide, dct=dct"+mvt2mt+") :                                                              fv12              
              ") : eval("
tr2    = tr*2
vmulti =                   !GlobalR ? super_search.MAnalyse( multi=true,overlap=    overlap,blksize=    blksize,   search=search,chroma=chroma,truemotion=truemotion, divide=divide, delta = interlaced ? tr2 : tr, dct=dct,searchparam=searchparam,pelsearch=pelsearch, trymany=trymany"+mvt2mt+") : vmulti
vmulti = RefineMotion   ? (!GlobalR ? MRecalculate (Recalculate, vmulti,overlap=halfoverlap,blksize=halfblksize, thSAD=halfthSAD,chroma=chroma,truemotion=truemotion, divide=divide,    tr = interlaced ? tr2 : tr, dct=dct"+mvt2mt+") :                                                    vmulti) : vmulti
vmulti =                   !GlobalR ? (interlaced ? vmulti.SelectEvery (4, 2, 3) : vmulti) : vmulti.SelectRangeEvery (Rtr*2, tr2, 0, false)
                         ")



# Finally, MDegrain


output  = !GlobalO ? interlaced ?
 \                    ( if3  ? mfilter.MDegrainN(super_render, vmulti, tr, thSAD2=halfthSAD, thSADC2=halfthSADC,   thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 6) ? mfilter.MDegrain6(super_render, bv2, fv2, bv4, fv4, bv6, fv6, bv8, fv8, bv10, fv10, bv12, fv12, thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 5) ? mfilter.MDegrain5(super_render, bv2, fv2, bv4, fv4, bv6, fv6, bv8, fv8, bv10, fv10,             thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 4) ? mfilter.MDegrain4(super_render, bv2, fv2, bv4, fv4, bv6, fv6, bv8, fv8,                         thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 3) ? mfilter.MDegrain3(super_render, bv2, fv2, bv4, fv4, bv6, fv6,                                   thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 2) ? mfilter.MDegrain2(super_render, bv2, fv2, bv4, fv4,                                             thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                             mfilter.MDegrain1(super_render, bv2, fv2,                                                       thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""")):
 \                    ( if3  ? mfilter.MDegrainN(super_render, vmulti, tr, thSAD2=halfthSAD, thSADC2=halfthSADC,               thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 6) ? mfilter.MDegrain6(super_render, bv1, fv1, bv2, fv2, bv3, fv3, bv4, fv4, bv5, fv5, bv6, fv6,     thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 5) ? mfilter.MDegrain5(super_render, bv1, fv1, bv2, fv2, bv3, fv3, bv4, fv4, bv5, fv5,               thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 4) ? mfilter.MDegrain4(super_render, bv1, fv1, bv2, fv2, bv3, fv3, bv4, fv4,                         thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 3) ? mfilter.MDegrain3(super_render, bv1, fv1, bv2, fv2, bv3, fv3,                                   thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                 (tr == 2) ? mfilter.MDegrain2(super_render, bv1, fv1, bv2, fv2,                                             thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""") :
 \                             mfilter.MDegrain1(super_render, bv1, fv1,                                                       thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, planar=planar"""+md16str+""")):    nop()


# LSB_IN merging

type  = avs26 ? input.PixelType() : "YV12"

outputI= !GlobalO && planar && (lsb || if0) ? output.Planar2Interleaved()                                                                                             : nop()
!GlobalO && lsb   ? eval("
blnkclp= lsb_in  || (if2 && !planar) ? BlankClip (lsb_in?input8h:input8, pixel_type=type, color_yuv=0)                                          : nop()
output = lsb && planar               ? Dither_YUY2toPlanar16(outputI)                                                                                                 : output
output = lsb_in                      ? inputY.Dither_add16 (Dither_sub16(output, planar?inputY:input8.Dither_convert_8_to_16 (), dif=true,u=u,v=v), dif=true,u=u,v=v) : output") : nop()




# Contrasharp (only sharpens luma)

ifC && if0 && MCCS ? eval("
Super           = n32 ? super_render.ConvertBits(32) : n16 ? super_render.ConvertBits(16) : super_render
cb1      = !if3 ? (interlaced ? bv2 : bv1) : vmulti.SelectEvery (tr2, 0)
cf1      = !if3 ? (interlaced ? fv2 : fv1) : vmulti.SelectEvery (tr2, 1)") : nop()

!GlobalO && if0   ? eval("

CCh   =       if1 ? CClip.height() : nop()
ref8  =       if1 ? (h == CCh*2)   : nop()
ref16 =       if1 ? (h == CCh/2)   : nop()

interlaced && if1 ? Assert(!ref16, "+Chr(34)+"Interlaced 16 bit stacked CClip is not a recognized format"+Chr(34)+")         : nop()

CClip = planar ?  (if1 ?  (lsb_in ? (ref8 ? CClip.Interleaved2planar(true) : CClip.Dither_YUY2toPlanar16().DitherPost(mode=-1,u=1,v=1).Dither_YUY2toInterleaved().Interleaved2planar(true))                         : \
                                     (interlaced ? (if5 ? CClip.AssumeTFF().SeparateFields().Interleaved2planar(true) : CClip.AssumeBFF().SeparateFields().Interleaved2planar(true))                                : \
                                     (ref16 ? CClip.Dither_YUY2toPlanar16().DitherPost(mode=-1,u=1,v=1).Dither_YUY2toInterleaved().Interleaved2planar(true) : CClip.Interleaved2planar(true))))                     : \
                          (lsb_in ?  inputY.DitherPost(mode=-1,u=1,v=1).Dither_YUY2toInterleaved().Interleaved2planar(true)                                                                                         : \
                                     inputP))                                                                                                                                                                       : \
                  (if1 ?  (lsb_in ? (ref8 ? CClip : CClip.DitherPost(mode=-1,u=1,v=1))                                                                                                                              : \
                                     (interlaced ? (if5 ? CClip.AssumeTFF().SeparateFields()                          : CClip.AssumeBFF().SeparateFields()) : (ref16 ? CClip.DitherPost(mode=-1,u=1,v=1) : CClip))) : \
                          (lsb_in ?  input.DitherPost(mode=-1,u=1,v=1)                                                                                                                                              : \
                                     n32 ? inputP.ConvertBits(32) : n16 ? inputP.ConvertBits(16) : inputP))")                                                                                                                                  : nop()


!GlobalO && if2   ? eval("
OutTO8  = output.DitherPost(mode=-1,u=1,v=1)
OutTO8P = planar  ? OutTO8.Dither_YUY2toInterleaved()                                                                                               : nop()
ctr16   = ifC     ? Contrasharpening (planar ? OutTO8P.Interleaved2planar(true):OutTO8, CClip, planar=planar, MC=MCCS, cb1=cb1, cf1=cf1, Super=Super)                             : \
                    LSFmod(planar ? OutTO8P : OutTO8,source=planar ? CClip.planar2Interleaved(true):CClip,defaults="+Chr(34)+"slow"+Chr(34)+",strength=Contrasharp,soothe=false,Lmode=0,soft=-2,keep=0)
ctr16   = ifC     ? ctr16 : planar ? ctr16.Interleaved2planar(true) : ctr16


ctr16P  = planar  ? ctr16.Planar2Interleaved(true)  : ctr16
ctr16   = StackVertical (ctr16P, planar ? BlankClip  (ctr16P, pixel_type="+Chr(34)+"YUY2"+Chr(34)+", color_yuv=0,length=1) : blnkclp )
ctr16   = Dither_add16 (output,mt_makediff(!planar?ctr16P:ctr16P.Dither_YUY2toPlanar(), OutTO8,u=2,v=2).Dither_convert_8_to_16(), dif=true,u=2,v=2)
ctr16   = MergeChroma(ctr16, output)                                                                                                     ")         : nop()



# Globals Output

GlobalO || Globals == 2  ? (!if3 ? eval("
global Super           = super_render
global bv12            = bv12
global bv10            = bv10
global bv8             = bv8
global bv6             = bv6
global bv5             = bv5
global bv4             = bv4
global bv3             = bv3
global bv2             = bv2
global bv1             = bv1

global fv1             = fv1
global fv2             = fv2
global fv3             = fv3
global fv4             = fv4
global fv5             = fv5
global fv6             = fv6
global fv8             = fv8
global fv10            = fv10
global fv12            = fv12
") : avs26 ? eval("
global bv1             =                                             vmulti.SelectEvery (tr2,  0)
global bv2             = interlaced ? bv1                          : vmulti.SelectEvery (tr2,  2)
global bv3             =                                             vmulti.SelectEvery (tr2,  4)
global bv4             = interlaced ? vmulti.SelectEvery (tr2,  2) : vmulti.SelectEvery (tr2,  6)
global bv5             =                                             vmulti.SelectEvery (tr2,  8)
global bv6             = interlaced ? bv3                          : vmulti.SelectEvery (tr2, 10)
global bv8             = interlaced ? vmulti.SelectEvery (tr2,  6) : nop()
global bv10            = interlaced ? bv5                          : nop()
global bv12            = interlaced ? vmulti.SelectEvery (tr2, 10) : nop()

global fv1             =                                             vmulti.SelectEvery (tr2,  1)
global fv2             = interlaced ? fv1                          : vmulti.SelectEvery (tr2,  3)
global fv3             =                                             vmulti.SelectEvery (tr2,  5)
global fv4             = interlaced ? vmulti.SelectEvery (tr2,  3) : vmulti.SelectEvery (tr2,  7)
global fv5             =                                             vmulti.SelectEvery (tr2,  9)
global fv6             = interlaced ? fv3                          : vmulti.SelectEvery (tr2, 11)
global fv8             = interlaced ? vmulti.SelectEvery (tr2,  7) : nop()
global fv10            = interlaced ? fv5                          : nop()
global fv12            = interlaced ? vmulti.SelectEvery (tr2, 11) : nop()
global Super           = super_render
global vmulti          = vmulti
global Rtr             = tr
") : eval("
global bv1             =                                            vmulti.SelectEvery (tr2, 0)
global bv2             = interlaced ? bv1                         : vmulti.SelectEvery (tr2, 2)
global bv3             =                                            vmulti.SelectEvery (tr2, 4)
global bv4             = interlaced ? vmulti.SelectEvery (tr2, 2) : nop()
global bv6             = interlaced ? bv3                         : nop()

global fv1             =                                            vmulti.SelectEvery (tr2, 1)
global fv2             = interlaced ? fv1                         : vmulti.SelectEvery (tr2, 3)
global fv3             =                                            vmulti.SelectEvery (tr2, 5)
global fv4             = interlaced ? vmulti.SelectEvery (tr2, 3) : nop()
global fv6             = interlaced ? fv3                         : nop()
global Super           = super_render
global vmulti          = vmulti
global Rtr             = tr")) : nop()



# Output

output = !GlobalO && !lsb && if0 ? ifC ? ContraSharpening(output, CClip, planar=planar, MC=MCCS, cb1=cb1, cf1=cf1, Super=Super) : \
			               planar ? LSFmod(output.planar2Interleaved(),source=CClip.planar2Interleaved(true),defaults="slow",strength=Contrasharp,soothe=false,Lmode=0,soft=-2,keep=0).Interleaved2planar() : \
			               		LSFmod(output,source=CClip,defaults="slow",strength=Contrasharp,soothe=false,Lmode=0,soft=-2,keep=0) \
			    : output

!GlobalO ? n16_out || n32_out ? output : n32 || n16 ? output.ConvertBits(sbitsn,dither=interlaced ? 1 : mode) : \
	 	  lsb_out ? (if0 ? ctr16 : output)  : \
                      		 if0 && lsb ?  (interlaced ?  ctr16.weave().DitherPost(u=u,v=v,mode=6,slice=slices,interlaced=true)               :  ctr16.DitherPost(mode=mode,slice=slices,ampn=ampn,u=Uin,v=Vin)) : \
                             		 lsb ?             (interlaced ? output.weave().DitherPost(u=u,v=v,mode=6,slice=slices,interlaced=true)              : output.DitherPost(mode=mode,slice=slices,ampn=ampn,u=Uin,v=Vin)) : \
                                                                           (interlaced ? output.weave() : output)    \
	:  input

!GlobalO ? (planar ? (lsb ? Dither_YUY2toInterleaved() : (if0 ? MergeChroma(Planar2Interleaved(true), interlaced ? outputI.weave() : outputI) : Planar2Interleaved())) : last) : last """) : \
 \
 \
 \
 \
 \
eval("""

##############
# SHOW PANEL #
##############


  # Common Variables

h     = lsb_in ? h/2 : h
w2    = w*1.0
h2    = h*1.0
hi    = interlaced ? round(h/2.0) : h
AR    = w2/h2
lsp   = interlaced?15:30
lsp   = AR < 1.9 ? lsp : floor(AR < 1.9 ? lsp : ((AR>2.4) ? 0 : lsp-((AR-1.9)*(lsp/(2.4-1.9)))))
ys    = round(lsb_in ? h2/6 : (interlaced?h2/15:h2/6))
s     = floor(((interlaced?w2/1.6:w2)/720.0)*16.0)
type  = avs26 ? input.PixelType() : planar?"YUY2":"YV12"

Wadd  = w2/40
Wadd2 = Wadd/2
w1    = round(w2+Wadd+Wadd2)
w3    = (w2/3)+Wadd/2.1
w2    = round(w1+w3)
w3    = round(w1+(w3+Wadd2)*1.96)
w3sq  = string(round(w3*1.01))
w3s   = string(w3)

  # Panel Separator

blkclp = BlankClip(interlaced?assumeframebased(pref):pref,length=1,pixel_type=type,color=$161616)
         \.crop(0,interlaced?h/2%8:h%8,0,0).separatefields().assumeframebased().separatefields()

Interleave(selecteven(blkclp).addborders(2,0,0,0,color=$7f7f7f).crop(0,0,-2,0),selectodd(blkclp))

WOut=weave().assumefieldbased().weave()
sep=round((hi-height(WOut))/2.0)

StackHorizontal(planar? pref.Planar2Interleaved() : pref,WOut.addborders(0,sep-sep%2,0,hi-(height(WOut)+(sep-sep%2)),color=$161616))



  # Color Guide Squares

a=interlaced?h*0.37:h*0.74
b=interlaced?h*0.40:h*0.80
c=interlaced?h*0.43:h*0.86

!planar ? avs26 ? mt_merge(mt_lut(yexpr="127 scalef",uexpr="183 scalef",vexpr="47 scalef",use_expr=3 ,u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(a)+" >= y "+string(interlaced?h*0.3835:h*0.767)+" <= & & 255 0 ? scalef",scale_inputs="intf").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true)
          \     : mt_merge(mt_lut(yexpr="127",uexpr="183",vexpr="47" ,u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(a)+" >= y "+string(interlaced?h*0.3835:h*0.767)+" <= & & 255 0 ?").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true) : nop()
!planar ? avs26 ? mt_merge(mt_lut(yexpr="81 scalef" ,uexpr="91 scalef" ,vexpr="240 scalef",use_expr=3,u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(b)+" >= y "+string(interlaced?h*0.4135:h*0.827)+" <= & & 255 0 ? scalef",scale_inputs="intf").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true)
          \     : mt_merge(mt_lut(yexpr="81" ,uexpr="91" ,vexpr="240",u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(b)+" >= y "+string(interlaced?h*0.4135:h*0.827)+" <= & & 255 0 ?").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true) : nop()
!planar ? avs26 ? mt_merge(mt_lut(yexpr="210 scalef",uexpr="16 scalef" ,vexpr="146 scalef",use_expr=3,u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(c)+" >= y "+string(interlaced?h*0.4435:h*0.887)+" <= & & 255 0 ? scalef",scale_inputs="intf").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true)
          \     : mt_merge(mt_lut(yexpr="210",uexpr="16" ,vexpr="146",u=3,v=3) ,mt_lutspa(mode="absolute", yexpr="x "+w3s+" >= x "+w3sq+" <= & y "+string(c)+" >= y "+string(interlaced?h*0.4435:h*0.887)+" <= & & 255 0 ?").trim(0,-1).FreezeFrame(0, FrameCount(pref)-1, 0),luma=true) : nop()


  # Parameters List

blue  = sShow ? (show=="Speed"   ? true : false) : false
red   = sShow ? (show=="Memory"  ? true : false) : false
yellow= sShow ? (show=="Quality" ? true : false) : false

Color = sShow ? (blue   ? $00aef0 : \
                 red    ? $ff0000 : \
                 yellow ? $ffff00 : \
                 Assert(false,    "Revise typo for possible color guide modes: 'Speed','Memory','Quality'")) : nop()



varn = "\n\n\n\n\n"
sp   = !GlobalR && str==1.0 ? "  " : ""

Subtitle("NotSMDegrain Mod v3.1.2.112s",text_color=red||blue||yellow?Color:$7f7f7f,halo_color=$000000,font="VERDANA",size=s*2,x=w1,y=lsb_in?h/40:(interlaced?h/50:h/20))

Subtitle("BASIC"   ,lsp=lsp,text_color=$ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle(            "\n\ntr           = " + string(tr)                                                                              + \
         varn+varn+      "chroma       = " + string(chroma)                                                                          ,lsp=lsp,text_color=red||blue               ?Color:$ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle(          "\n\n\nthSAD(C)     = " + string( GlobalO?"bypass":string(thSAD)     + "(" + string(plane0?thSADC:"bypass") + ")")+ \
         varn+           "CClip        = " + string( GlobalO?"bypass":(defined(CClip)?"defined":"undefined"))                        + \
                     "\n\nInterlaced   = " + string(interlaced)                                                                      ,lsp=lsp,text_color=                               $ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle(varn+           "RefineMotion = " + string( GlobalO?"bypass":RefineMotion)                                                  ,lsp=lsp,text_color=yellow                  ?Color:$ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle(varn+       "\n\nContrasharp  = " + string( GlobalO?"bypass":contrasharp)                                                   ,lsp=lsp,text_color=yellow&&!GlobalO        ?Color:$ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle(varn+varn+    "\nplane        = " + string( GlobalO?"bypass":(plane==0?"0 (Luma)":plane==1?"1 (U plane)":plane==2?"2 (V plane)":plane==3?"3 (Chroma)":"4(Luma+Chroma)")),lsp=lsp,text_color=(red||blue)&&!GlobalO?Color:$ffffff,font="COURIER NEW",size=s,x=w1,y=ys)
Subtitle("<-- "+string(IsClip(prefilter)||prefilter!=-1?"Prefiltered clip converted\n    to PC levels":"Clip converted to PC levels\n   ")+" for the motion search",lsp=lsp,text_color=$ffffff,font="COURIER NEW",size=s,x=w1-10,y=(interlaced?h/2:h)-int(ys/1.5))

Subtitle("ADVANCED",lsp=lsp,text_color=$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(              "\n\npel        = " + string(pel)                                                                             ,lsp=lsp,text_color=red                     ?Color:$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(            "\n\n\nsubpixel   = " + string( pel==1 ?"bypass":subpixel)                                                      ,lsp=lsp,text_color=(yellow||blue)&&pel!=1  ?Color:$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(varn+varn+  "\n\n\ntruemotion = " + string( GlobalR?"bypass":truemotion)                                                    ,lsp=lsp,text_color=(yellow||blue)&&!GlobalR?Color:$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(varn+             "mfilter    = " + string( GlobalR?"bypass":MFilterB?"Clip"+sp+" Variable":"OFF")                          ,lsp=lsp,text_color=                               $7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(varn+         "\n\nStr        = " + (GlobalR?string("bypass"):string(Str,"%1.2f"))+sp+" Brightness"                         + \
         varn+             "search     = " + string( GlobalR?"bypass":search)                                                        ,lsp=lsp,text_color=yellow&&!GlobalR        ?Color:$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(varn+varn+        "blksize    = " + string( GlobalR?"bypass":blksize)                                                       + \
                         "\noverlap    = " + string( GlobalR?"bypass":overlap)                                                       ,lsp=lsp,text_color=(red||blue)&&!GlobalR   ?Color:$7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)
Subtitle(varn+           "\nprefilter  = " + (GlobalR?string("bypass"):(preclip?"Clip"+sp+" Variable":(prefilter==0?"0"+sp+"    MinBlur(0)":prefilter==1?"1"+sp+"    MinBlur(1)":prefilter==2?"2"+sp+"    MinBlur(2)":prefilter==3?"3"+sp+"    Dfttest":prefilter==4?"4"+sp+"    KNLmeans":"OFF"+sp+"    (-1)"))) + \
                       "\n\nAmp        = " + (GlobalR||str==1.0?string("bypass"):string(Amp,"%1.2f"))+" Amplitude"                   + \
         varn+           "\nlimit(C)   = " + (GlobalO?string("bypass"):string(limit)     + "(" + string(limitc) + ")")               ,lsp=lsp,text_color=                               $7f7f7f,font="COURIER NEW",size=s,x=w2,y=ys)

Subtitle("OTHERS"  ,lsp=lsp,text_color=$494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(             "\n\n\nthSCD1(2) = " + (GlobalO?string("bypass"):string(thSCD1) + "(" + string(thSCD2) + ")")                  + \
                   varn+"\n\nGlobals   = " + string(Globals==0 ? "0 (OFF)" : Globals==1 ? "1 (Import)" : Globals==2 ? "2 (Export)" : "3 (E.Only)"),lsp=lsp,text_color=                  $494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(          varn+"\n\nslices    = " + string(slices)                                                                          ,lsp=lsp,text_color=blue                    ?Color:$494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(               "\n\nhpad(v)   = " + string(hpad)   + "(" + string(vpad)   + ")"                                             ,lsp=lsp,text_color=red||blue               ?Color:$494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(varn+              "lsb       = " + string(lsb)                                                                             ,lsp=lsp,text_color=yellow                  ?Color:$494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(varn+            "\nlsb_in/out= " + string(lsb_in) +"/"+ string(lsb_out)                                                    ,lsp=lsp,text_color=red&&lsb_in             ?Color:$494949,font="COURIER NEW",size=s,x=w3,y=ys)
Subtitle(varn+        "\n\n\nmode      = " + (GlobalO||(lsb_out||!lsb)?string("bypass"):interlaced?"6 (locked)":string(mode))        ,lsp=lsp,text_color=yellow&&!GlobalO&&lsb   ?Color:$494949,font="COURIER NEW",size=s,x=w3,y=ys)

Subtitle("   Speed"   ,lsp=interlaced?15:30,text_color=planar?$00aef0:$7f7f7f,font="COURIER NEW",size=s,x=w3,y=int(a-1))
Subtitle("   Memory"  ,lsp=interlaced?17:34,text_color=planar?$ff0000:$7f7f7f,font="COURIER NEW",size=s,x=w3,y=int(b-1))
Subtitle("   Quality" ,lsp=interlaced?19:38,text_color=planar?$ffff00:$7f7f7f,font="COURIER NEW",size=s,x=w3,y=int(c-1))

lsb_out ? StackVertical (last, BlankClip (last, pixel_type=type, color_yuv=0,length=1)) : last""")}


# NotSMDegrain prefilters

function NotSMDegrain_prefilters (clip input, int "prefilter", bool "chroma", int "Chr", int "Chr2", int "bug_wa", bool "lsb", bool "lsb_in", bool "Interlaced", val "if5", int "pel", String "device_type", int "device_id", int "d", int "a", bool "slices", bool "planar", clip "inputP", clip "input8", clip "input8y", clip "inputY", val "input8h", float "h", String "knlm_params", String "cplace", int "Threads")
{
Interlaced   = Default( Interlaced  ,false)
slices       = default(slices, true)
if5          = Default( if5  ,interlaced ? (GetParity(input)                            ? true : false) : nop())
lsb_in       = Default( lsb_in  ,false)
lsb          = Default( lsb     ,lsb_in)
pel          = default( pel, (input.width () > 1099 ||  input.height() > (lsb_in ? 1199 : 599)) ? 1 : 2 )
sisphbd      = AvsPlusVersionNumber > 2294
chroma       = default( chroma, true)
planar       = Default( planar , input.isyuy2())
prefilter    = Default( prefilter, 3)
cplace       = Default( cplace, "mpeg2")
Threads      = default( Threads, sh_GetUserGlobalIMTint())

Chr          = Default(Chr,     chroma ? 3 : 1)
Chr2         = Default(Chr2,    chroma ? 3 : (prefilter==3 ? 2 : 1))
avs26        = !(VersionNumber() < 2.60)

Assert(!(!defined(inputP) && prefilter==-1), "prefilter must be between 0~4: "+string(prefilter))
lsb_native = sisphbd ? !(Input.BitsPerComponent() > 8 && (lsb)) : true
sisphbd ? Assert(lsb_native, "lsb hack is not Compatible with native high bit depth" ) : nop()

# Input preparation for: LSB_IN, Interlacing, Planar and MSuper optimization when pel=2

inputY  = defined(inputY )                    ? inputY  : planar      ? (lsb_in   ? Dither_YUY2toPlanar16(input)         : Interleaved2planar(input))                           : input

inputP  = defined(inputP )                    ? inputP  : !interlaced ? (pel == 2 ? inputY.AssumeFrameBased()            : inputY)                                             : \
                                                                        (if5      ? inputY.AssumeTFF().SeparateFields()  : inputY.AssumeBFF().SeparateFields())

input8h = defined(input8h) && isclip(input8h) ? input8h : lsb_in      ?             inputP. Ditherpost(mode=6, slice=slices)                                                    : nop()
input8y = defined(input8y)                    ? input8y : planar      ? (lsb_in   ? input8h.Dither_YUY2toInterleaved()   :  inputP)                                             : inputP
input8  = defined(input8 )                    ? input8  : lsb_in      ? (planar   ? input8y.Interleaved2planar()         : input8h)                                             : input8y

inputd  = (prefilter == 3 || prefilter == 4)  ? Interlaced ? if5 ? input.AssumeTFF().SeparateFields() : \
                                                                   input.AssumeBFF().SeparateFields() : \
                                                             input : nop()

bug_wa    = defined(bug_wa) ? bug_wa : interlaced && planar && chroma && !avs26 ? 2 : Chr # bug: crash prevention workaround

# The mt_merge() line for prefilter=3 should be swapped with a high bitdepth variant (Dither_merge16_8() ?) due to a 1 point limited range
# in both range ends, but then it won't work with planar sources. This isn't as critical since we are only trying to find motion vectors.
                     (prefilter==-1) ?  inputP                                                                                                                                      : \
                     (prefilter==0)  ?  input8.MinBlur(0,Chr,planar)                                               : \
                     (prefilter==1)  ?  input8.MinBlur(1,Chr,planar)                                               : \
                     (prefilter==2)  ?  input8.MinBlur(2,Chr,planar)                                               : \
                     (prefilter==3)  ?  (!planar && lsb ? Dither_merge16_8( inputd.Dfttest(sstring="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma,v=chroma,lsb=true,lsb_in=lsb_in,quiet=true,threads=Threads), lsb_in?inputP:inputP.Dither_convert_8_to_16(),                                \
                                                                   lsb_in?inputP.Dither_lut16("x 4096 < 65535 x 19200 > 0 65535 x 4096 - 4.338916843220339 * - ? ?",u=1,v=1).Ditherpost(mode=6, slice=slices, u=Chr,   v=Chr)                                           \
                                                                         :inputd.mt_lut(      "x 16 < 255 x 75 > 0 255 x 16 - 255 75 16 - / * - ? ?",u=1,v=1), luma=chroma,                       u=Chr2,  v=Chr2)                                                       : \
                                 avs26 && planar && lsb ? Dither_merge16_8( inputd.Dfttest(sstring="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma,v=chroma,lsb=true,lsb_in=lsb_in,quiet=true,threads=Threads).ConvertToYV16(), lsb_in?inputP:inputd.ConvertToYV16().Dither_convert_8_to_16(),                                \
                                                                   lsb_in?inputP.Dither_lut16("x 4096 < 65535 x 19200 > 0 65535 x 4096 - 4.338916843220339 * - ? ?",u=1,v=1).Ditherpost(mode=6, slice=slices, u=Chr,   v=Chr)                                           \
                                                                         :inputd.ConvertToYV16().mt_lut(      "x 16 < 255 x 75 > 0 255 x 16 - 255 75 16 - / * - ? ?",u=1,v=1), luma=chroma,                       u=Chr2,  v=Chr2).ConvertToYUY2().Interleaved2planar(!chroma)                                                       : \
                                           avs26 && planar ? mt_merge     (        Dfttest(!lsb_in?inputd:input8y,sstring="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma,v=chroma,dither=1,threads=Threads).ConvertToYV16(),!lsb_in?input8y.Planar2Interleaved(!chroma).ConvertToYV16():input8y.ConvertToYV16(),                                                   \
                                                                          input8.Planar2Interleaved(!chroma).ConvertToYV16().mt_lut(      "x 16 < 255 x 75 > 0 255 x 16 - 4.322033898305085 * - ? ?",u=1,v=1), luma=planar?false:chroma,          u=bug_wa,v=bug_wa).ConvertToYUY2().Interleaved2planar(!chroma)                                                    : \
                                                     avs26 ? mt_merge     (sneo_dfttest(inputd,slocation="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma?3:2,v=chroma?3:2,dither=1,threads=Threads,fft_threads=Threads),input8,   \
                                                                          input8.mt_lut("x ymin < range_max x 75 scaleb > 0 range_max x ymin - range_max 75 scaleb ymin - / * - ? ?",use_expr=2,u=1,v=1), luma=chroma, cplace=cplace, u=chr,v=chr)                                                   : \
                                                             mt_merge     (planar ? Dfttest(!lsb_in?inputd:input8y,sstring="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma,v=chroma,dither=1,threads=Threads).Interleaved2planar(!chroma)                          : \
                                                                                    Dfttest(!lsb_in?inputd:input8 ,sstring="0.0:4.0 0.2:9.0 1.0:15.0",tbsize=1,u=chroma,v=chroma,dither=1,threads=Threads),input8,   \
                                                                          input8.mt_lut(      "x 16 < 255 x 75 > 0 255 x 16 - 4.322033898305085 * - ? ?",u=1,v=1), luma=chroma,          u=bug_wa,v=bug_wa))                                                   : \
                     (prefilter==4)  ?  planar ? inputd.SH_KNLMeansCL(lsb=lsb, lsb_in=lsb_in, device_type=device_type, device_id=device_id, chroma=chroma, h=h, d=d, a=a, knlm_params=knlm_params).Interleaved2planar(!chroma) : \ 
                                                 inputd.SH_KNLMeansCL(lsb=lsb, lsb_in=lsb_in, device_type=device_type, device_id=device_id, chroma=chroma, h=h, d=d, a=a, knlm_params=knlm_params) : \
                                         Assert(false,    "prefilter must be between -1~4: "+string(prefilter))
}


# Didée MCDegrain, mod

function MCDegrainMod(clip c, int "frames", clip "srch", bool "soft", int "thSAD", bool "TV_range")
{
frames = default(frames, 2)
srch   = default(srch,c)
soft   = default(soft,false)
thSAD  = default(thSAD,400)
bs = (c.width>960) ? 16 : 8
rg = (c.width<640) ? 11 : (c.width<1200) ? 11 : 20
rg = soft ? rg : 0
input = soft ? c.mt_adddiff(mt_makediff(c,c.removegrain(rg)),U=2,V=2)
 \           : c
(frames<=0) ? c :\
                     input.NotSMDegrain(frames,thsad,pel=2,prefilter=srch,mfilter=c.removegrain(rg),TV_range=TV_range,subpixel=1,srfilter=2,Truemotion=true,vpad=8,hpad=8)
return(last) }