/* edi_rpow2 v1.0 mod 83

An improved rpow2 function for nnedi3, nnedi3ocl, eedi3, and eedi2.


##### Requirements #####

Plugins:
  Dither
  eedi2
  eedi3 (0.9.2.3 or up)
  FTurn
  MaskTools2 (2.2.14 or up)
  nnedi3 (0.9.4.48 or up)
  nnedi3ocl

Scripts:
  ResizeX (1.0.1 mod 7 or up)

Dither is only required if lsb=true.
FTurn is optional but recommended.
MaskTools2 is only required if eedi3's mclip parameter is used.

Color formats:
  Y8, YV12, YV16, YUY2, YV411, YV24, RGB24, HBD in avs+ if plugins support it
   
Using eedi2 on RGB24 isn't recommended as it can cause discoloration.


##### Common Parameters ######

int rfactorX, int rfactorY (defaults: 2, rfactorX)
--------------------------------------------------
The horizontal and vertical image enlargement factors. Must be a power of 2.
This includes 1, meaning no enlargement in that direction.


string edi (default: "nnedi3")
------------------------------
The edi method to use for image enlargement.
Options are "nnedi3", "nnedi3ocl", "eedi3", and "eedi2".


string cshift (default: "")
---------------------------
The resize kernel to use for correcting the image center shift caused by
image enlargement and for scaling to the final output resolution.
It can be any kernel supported by ResizeX, although kernels exclusive to
Dither_resize16 can only be used if lsb=true.


int fwidth, int fheight (defaults: width*rfactorX, height*rfactorY)
-------------------------------------------------------------------
The final output width and height to scale to after image enlargement.
These settings have no effect unless cshift is specified.


int taps (default: undefined)
-----------------------------
The number of taps to use for the cshift kernel.
Only applies to the Blackman, Blackmanminlobe, Lanczos, Sinc, and Spline kernels.


float a1, float a2 (defaults: undefined)
----------------------------------------
If cshift="Bicubic", these set the b and c values.
If cshift="Gauss", a1 sets the p value.


string cplace (default: "MPEG2")
--------------------------------
Specifies the input's chroma placement. Options are "MPEG1" and "MPEG2".
Only applies to formats with subsampled chroma.
Note that only YV12 should be able to have MPEG1 chroma placement.


bool Y, bool U, bool V (defaults: true)
---------------------------------------
Controls whether the specified plane is processed or not.
These settings have no effect for RGB24 input.


bool lsb (default: false)
bool lsb_out (default: false)
-------------------------
When set to true, Dither_resize16 will be used to correct the image
center shift if applicable and the output will be in stack16 format.
If the input is RGB24, the output will be in the RGB48Y format used by Dither.
It can be converted back to RGB24 with the following script:

     DitherPost()
     MergeRGB(SelectEvery(3,0),SelectEvery(3,1),SelectEvery(3,2),"RGB24")


bool bordfix (default: true)
----------------------------
nnedi3, nnedi3ocl, and eedi2 cause lines at the edge of the frame to distort slightly.
When set to true, the distortion is avoided by padding the frame with rows of
duplicate pixels before image enlargement and then cropping the padding off afterward.
Defaults to false when edi="eedi3" because it isn't needed when using eedi3.


bool c420fix (default: true)
-----------------------------
Enlarging YV12 vertically causes a small chroma shift that's corrected by
resizing the chroma channels even when not correcting the image center shift.
When set to false, the chroma shift won't be corrected, providing
output that hasn't been resized at all after image enlargement.
Only applies when the input is YV12 and the center shift isn't corrected.


##### nnedi3 Parameters ######

int nsize, int nns, int qual, int etype, int pscrn, int threads, int opt, int fapprox
-------------------------------------------------------------------------------------
See nnedi3's documentation for explanations of these parameters.
Like nnedi3_rpow2, defaults are nsize=0, nns=3, and the rest are the same as nnedi3.


##### nnedi3ocl Parameters ######

int nsize, int nns, int qual, int etype
---------------------------------------
Same as nnedi3's parameters.
As of the 2013.12.08-beta version, only nsize=0 is implemented. Other nsize values are ignored.
Like nnedi3x_rpow2, defaults are nsize=0, nns=3, and the rest are the same as nnedi3.


##### eedi3 Parameters ######

float alpha, float beta, float gamma, int nrad, int mdis, bool hp, bool ucubic, bool cost3, int vcheck,
float vthresh0, float vthresh1, float vthresh2, string sclip, string sclip_params, clip mclip, int threads, int opt
-------------------------------------------------------------------------------------------------------------------
See eedi3's documentation for explanations of these parameters.


string sclip (default: "")
--------------------------
Unlike eedi3, the sclip parameter in edi_rpow2 takes a string rather than a clip.
It specifies what resize kernel or edi method to use to generate the sclip.
All of AviSynth's internal resize kernels, ResizeX's bicubic presets,
"nnedi3", "nnedi3ocl", and "eedi2" are supported.


string sclip_params (default: "")
---------------------------------
Used to pass parameters to ResizeX, nnedi3, nnedi3ocl, or eedi2 when generating the sclip.
If nnedi3 or nnedi3ocl is used, it defaults to "nsize=0, nns=3".


clip mclip (default: undefined)
-------------------------------
The mclip should be the same resolution and colorspace as the input, with the exception of RGB.
If the input is RGB, the mclip can be any YUV format, but only its luma channel will be used.
The mclip is automatically scaled to the appropriate resolution for each iteration of image enlargement.


Other parameters are the same as eedi3.


##### eedi2 Parameters ######

int mthresh, int lthresh, int vthresh, int estr, int dstr, int maxd, int map, int nt, int pp
--------------------------------------------------------------------------------------------
See eedi2's documentation for explanations of these parameters.
Defaults are the same as eedi2.
*/

function edi_rpow2(clip input, int "rfactorX", int "rfactorY", string "edi", string "cshift", int "fwidth", int "fheight", 
\                  int "taps", float "a1", float "a2", string "cplace", bool "Y", bool "U", bool "V", bool "lsb", bool "bordfix", bool "c420fix",
\                  int "nsize", int "nns", int "qual", int "etype", int "pscrn", int "threads", int "opt", int "fapprox",
\                  float "alpha", float "beta", float "gamma", int "nrad", int "mdis", bool "hp", bool "ucubic", bool "cost3",
\                  int "vcheck", float "vthresh0", float "vthresh1", float "vthresh2", string "sclip", string "sclip_params", clip "mclip",
\                  int "mthresh", int "lthresh", int "vthresh", int "estr", int "dstr", int "maxd", int "map", int "nt", int "pp", bool "mt", string "mt_params", bool "lsb_out", int "nnrep") {

# Row 1-2: Common parameters
# Row 3:   nnedi3 and nnedi3ocl parameters
# Row 4-5: eedi3 parameters (also threads and opt)
# Row 6:   eedi2 parameters

iw = input.Width()
ih = input.Height()

rfactorX  = Default(rfactorX, 2)
rfactorY  = Default(rfactorY, rfactorX)
edi       = Default(edi, "nnedi3")
cshift    = Default(cshift, "")
fwidth    = Default(fwidth, iw*rfactorX)
fheight   = Default(fheight, ih*rfactorY)
cplace    = Default(cplace, "MPEG2")
Y         = Default(Y, true)
U         = Default(U, true)
V         = Default(V, true)
lsb       = Default(lsb, false)
lsb_out   = Default(lsb_out , false)
lsb       = !lsb && lsb_out ? true : lsb
nnrep     = Default(nnrep, 0)
bordfix   = Default(bordfix, edi != "eedi3" ? true : nnrep > 0)
c420fix   = Default(c420fix, true)
nsize     = Default(nsize, 0)
nns       = Default(nns, 3)
Threads   = default(Threads, sh_GetUserGlobalIMTint())

sisphbd = AvsPlusVersionNumber > 2294

Assert(rfactorX > 0 && BitAnd(rfactorX,rfactorX-1) == 0, "edi_rpow2: rfactorX must be a power of 2")
Assert(rfactorY > 0 && BitAnd(rfactorY,rfactorY-1) == 0, "edi_rpow2: rfactorY must be a power of 2")
Assert(edi == "nnedi3" || edi == "nnedi3ocl" || edi == "eedi3" || edi == "eedi2", "edi_rpow2: invalid edi setting")
Assert(cplace == "MPEG1" || cplace == "MPEG2", "edi_rpow2: cplace must be MPEG1 or MPEG2")
Assert(!mclip.Defined() || mclip.Defined() && mclip.IsYUV(), "edi_rpow2: eedi3 mclip must be YUV")
lsb_native = sisphbd ? !(Input.BitsPerComponent() > 8 && (lsb)) : true
sisphbd ? Assert(lsb_native, "lsb hack is not Compatible with native high bit depth" ) : nop()
sisphbd ? Assert(!(Input.isYUVA() && lsb), "lsb hack is not Compatible with YUVA" ) : nop()

# Override the fwidth and fheight parameters if not correcting the center shift
ffwidth  = cshift == "" ? iw*rfactorX : fwidth
ffheight = cshift == "" ? ih*rfactorY : fheight

# Get the input clip's colorspace
csp = input.PixelType()

chr420  = sisphbd ? input.is420() : input.isyv12()
chr422  = sisphbd ? input.is422() : input.isYV16()
chr444  = sisphbd ? input.is444() : input.isYV24()

# Check for subsampled chroma
hssc12 = chr420  || chr422 || csp == "YUY2"
hssc14 = csp == "YV411"
vssc12 = chr420
alignc = hssc12 || hssc14

Assert(!hssc12 || ffwidth%2  == 0, "edi_rpow2: fwidth of "+csp+" must be a multiple of 2")
Assert(!hssc14 || ffwidth%4  == 0, "edi_rpow2: fwidth of "+csp+" must be a multiple of 4")
Assert(!vssc12 || ffheight%2 == 0, "edi_rpow2: fheight of "+csp+" must be a multiple of 2")

# Input and output chroma width and height determined by subsampling
iw_c      = hssc12 ? iw/2 : hssc14 ? iw/4 : iw
ih_c      = vssc12 ? ih/2 : ih
fwidth_c  = hssc12 ? ffwidth/2 : hssc14 ? ffwidth/4 : ffwidth
fheight_c = vssc12 ? ffheight/2 : ffheight

# Center shift correction values
cshiftH   = rfactorX == 1    ?  0
\         : hssc12 || hssc14 ? -0.5*(rfactorX-1)
\                            : -0.5
cshiftV   = rfactorY == 1    ?  0
\                            : -0.5
cshiftH_c = hssc12 ? cshiftH/2.0
\         : hssc14 ? cshiftH/4.0
\                  : cshiftH
cshiftV_c = vssc12 && rfactorY > 1 ? cshiftV/2.0-0.25
\                                  : cshiftV

# Add the MPEG1 or MPEG2 chroma shift correction to the cshiftH_c value
no_MPEG2shift_kernel = cshift.LeftStr(5) == "Point" ||
\                      cshift.LeftStr(4) == "Rect"  ||
\                      cshift.LeftStr(3) == "Box"    ? true : false
MPEG1shift = hssc12 ? -0.25*(rfactorX-1)
\          : hssc14 ? -0.375*(rfactorX-1)
\                   : 0
MPEG2shift = hssc12 ? 0.25*(1.0-Float(iw_c*rfactorX)/Float(fwidth_c))
\          : hssc14 ? 0.375*(1.0-Float(iw_c*rfactorX)/Float(fwidth_c))
\                   : 0
cshiftH_c = cplace == "MPEG1"     ? cshiftH_c+MPEG1shift
\         : cplace == "MPEG2"    &&
\           !no_MPEG2shift_kernel ? cshiftH_c+MPEG2shift
\                                 : cshiftH_c

# Pad the frame with rows of duplicate pixels to support mod1 and mod2
# resolutions with eedi3 and eedi2 since they have to work in YV12.
# Also pad at least four rows if bordfix=true.
iw_ismod8 = iw%8 == 0 ? true : false
ih_ismod8 = ih%8 == 0 ? true : false
iw_ismod4 = iw%4 == 0 ? true : false
ih_ismod4 = ih%4 == 0 ? true : false

pad8 = edi == "eedi3" && hssc14 && !iw_ismod8 ||
\      edi == "eedi3" && hssc14 && !ih_ismod8 ||
\      edi == "eedi2" && hssc14 && !iw_ismod8 ||
\      edi == "eedi2" && hssc14 && !ih_ismod8  ? true : false
pad4 = edi == "eedi3" && !chr420 && !iw_ismod4 ||
\      edi == "eedi3" && !chr420 && !ih_ismod4 ||
\      edi == "eedi2" && !chr420 && !iw_ismod4 ||
\      edi == "eedi2" && !chr420 && !ih_ismod4  ? true : false
pad  = pad8 || pad4 ? true : false

padR = pad8 && !iw_ismod8 ? 8-iw%8
\    : pad4 && !iw_ismod4 ? 4-iw%4
\                         : 0
padT = pad8 && !ih_ismod8 ? 8-ih%8
\    : pad4 && !ih_ismod4 ? 4-ih%4
\                         : 0

padR = padR >= 4                       ? padR
\    : bordfix && rfactorX > 1         ? padR+4
\                                      : padR
padT = padT >= 4                       ? padT
\    : bordfix && rfactorY > 1         ? padT+4
\                                      : padT
padL = bordfix && rfactorX > 1 && pad8 ? 8
\    : bordfix && rfactorX > 1         ? 4
\                                      : 0
padB = bordfix && rfactorY > 1 && pad8 ? 8
\    : bordfix && rfactorY > 1         ? 4
\                                      : 0

padL_c = hssc12 ? padL/2 : hssc14 ? padL/4 : padL
padT_c = vssc12 ? padT/2 : padT
padR_c = hssc12 ? padR/2 : hssc14 ? padR/4 : padR
padB_c = vssc12 ? padB/2 : padB

einput = pad || bordfix ? input.ResizeX(iw+padL+padR, ih+padT+padB, -padL, -padT, iw+padL+padR, ih+padT+padB,
\                                       kernel="Point", luma=Y, chroma=U||V?true:false,mt=mt,mt_params=mt_params)
\                       : input
emclip = mclip.Defined() && pad     ||
\        mclip.Defined() && bordfix  ? mclip.ResizeX(iw+padL+padR, ih+padT+padB, -padL, -padT, iw+padL+padR, ih+padT+padB,
\                                                   kernel="Point", luma=Y, chroma=U||V?true:false,mt=mt,mt_params=mt_params)
\                                    : mclip

# nnedi3 image enlargement
    edi == "nnedi3" && (sisphbd ? input.isy() : csp == "Y8") ?
\   Eval("""
         pow2  = einput.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
         """)
\ : edi == "nnedi3" && chr420  ||
\   edi == "nnedi3" && chr422  ||
\   edi == "nnedi3" && csp == "YUY2"  ||
\   edi == "nnedi3" && csp == "YV411" ||
\   edi == "nnedi3" && chr444   ?
\   Eval("""
         # For nnedi3 and nnedi3ocl, it's faster to split YV12 channels into separate Y8 clips even though they don't need to be
         pow2Y = sisphbd ? einput.ConvertToY() : einput.ConvertToY8()
         pow2Y = pow2Y.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
         pow2U = sisphbd ? einput.ExtractU() : einput.UToY8()
         pow2U = pow2U.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
         pow2V = sisphbd ? einput.ExtractV() : einput.VToY8()
         pow2V = pow2V.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
         """)
\ : edi == "nnedi3" && input.isrgb() ?
\   Eval("""
         # If using FTurn, it's faster to split RGB24 channels into an interleaved Y8 clip because FTurn doesn't support RGB24
         try {
             IsAvsPlus || csp != "RGB24" ? dontdoft : nop()
             tft  = BlankClip(pixel_type="Y8").FTurnRight()
             pow2 = sisphbd ? Interleave(einput.ExtractR(),einput.ExtractG(),einput.ExtractB()) : Interleave(einput.ShowRed("Y8"),einput.ShowGreen("Y8"),einput.ShowBlue("Y8"))
             pow2 = pow2.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
             splitRGB24 = true
             }
         catch(err_msg) {
             pow2 = einput.edi_rpow2_nnedi3(rfactorX,rfactorY,alignc,true,true,true,nsize,nns,qual,etype,pscrn,threads,opt,fapprox)
             splitRGB24 = false
             }
         """)
\ : NOP()

# nnedi3ocl image enlargement
    edi == "nnedi3ocl" && (sisphbd ? input.isy() : csp == "Y8") ?
\   Eval("""
         pow2  = einput.edi_rpow2_nnedi3ocl(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype)
         """)
\ : edi == "nnedi3ocl" && chr420  ||
\   edi == "nnedi3ocl" && chr422  ||
\   edi == "nnedi3ocl" && csp == "YUY2"  ||
\   edi == "nnedi3ocl" && csp == "YV411" ||
\   edi == "nnedi3ocl" && chr444   ?
\   Eval("""
         pow2Y = sisphbd ? einput.ConvertToY() : einput.ConvertToY8()
         pow2Y = pow2Y.edi_rpow2_nnedi3ocl(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype)
         pow2U = sisphbd ? einput.ExtractU() : einput.UToY8()
         pow2U = pow2U.edi_rpow2_nnedi3ocl(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype)
         pow2V = sisphbd ? einput.ExtractV() : einput.VToY8()
         pow2V = pow2V.edi_rpow2_nnedi3ocl(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype)
         """)
\ : edi == "nnedi3ocl" && csp == "RGB24" ?
\   Eval("""
         pow2  = Interleave(einput.ShowRed(sisphbd ? "Y" : "Y8"),einput.ShowGreen(sisphbd ? "Y" : "Y8"),einput.ShowBlue(sisphbd ? "Y" : "Y8"))
         pow2  = pow2.edi_rpow2_nnedi3ocl(rfactorX,rfactorY,alignc,true,false,false,nsize,nns,qual,etype)
         splitRGB24 = true
         """)
\ : NOP()

# Split the eedi3 mclip
    !mclip.Defined() ?
\   Eval("""
         mclipY = Undefined()
         mclipU = Undefined()
         mclipV = Undefined()
         """)
\ : (sisphbd ? input.isy() : csp == "Y8") || chr420 ?
\   nop()
\ : csp == "RGB24" ?
\   Eval("""
         emclip  = sisphbd ? emclip.ConvertToY() : emclip.ConvertToY8()
         emclip  = emclip.SelectEvery(3,0,0,0,1,1,1,2,2,2)
         """)
\ : Eval("""
         mclipY = sisphbd ? emclip.ConvertToY() : emclip.ConvertToY8()
         mclipU = sisphbd ? emclip.ExtractU() : emclip.UToY8()
         mclipV = sisphbd ? emclip.ExtractV() : emclip.VToY8()
         """)

# eedi3 image enlargement
    edi == "eedi3" && (sisphbd ? input.isy() : csp == "Y8") ?
\   Eval("""
         pow2  = einput
         \            .edi_rpow2_eedi3(rfactorX,rfactorY,alignc,true,false,false,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                             vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,emclip,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         """)
\ : edi == "eedi3" && chr420 ?
\   Eval("""
         pow2  = einput.edi_rpow2_eedi3(rfactorX,rfactorY,alignc,Y,U,V,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                             vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,emclip,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         pow2Y = sisphbd ? pow2.ConvertToY() : pow2.ConvertToY8()
         pow2U = sisphbd ? pow2.ExtractU() : pow2.UToY8()
         pow2V = sisphbd ? pow2.ExtractV() : pow2.VToY8()
         """)
\ : edi == "eedi3" && csp == "YV411" ||
\   edi == "eedi3" && chr422 ||
\   edi == "eedi3" && chr444 ||
\   edi == "eedi3" && csp == "YUY2" ?
\   Eval("""
         pow2Y = sisphbd ? einput.ConvertToY() : einput.ConvertToY8()
         pow2Y = pow2Y.edi_rpow2_eedi3(rfactorX,rfactorY,alignc,true,false,false,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                             vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,mclipY,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         pow2U = sisphbd ? einput.ExtractU() : einput.UToY8()
         pow2U = pow2U.edi_rpow2_eedi3(rfactorX,rfactorY,alignc,true,false,false,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                             vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,mclipU,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         pow2V = sisphbd ? einput.ExtractV() : einput.VToY8()
         pow2V = pow2V.edi_rpow2_eedi3(rfactorX,rfactorY,alignc,true,false,false,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                             vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,mclipV,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         """)
\ : edi == "eedi3" && input.isrgb() ?
\   Eval("""
         # Always split RGB24 so that the sclip and mclip parameters work
         pow2 = sisphbd ? Interleave(einput.ExtractR(),einput.ExtractG(),einput.ExtractB()) : Interleave(einput.ShowRed("Y8"),einput.ShowGreen("Y8"),einput.ShowBlue("Y8"))
         pow2 = pow2.edi_rpow2_eedi3(rfactorX,rfactorY,alignc,true,false,false,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
         \                           vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,emclip,opt,mt=mt,mt_params=mt_params,nnrep=nnrep)
         splitRGB24 = true
         """)
\ : NOP()

# eedi2 image enlargement
    edi == "eedi2" && csp == "Y8" ?
\   Eval("""
         pow2  = einput.ConvertToYV12()
         \            .edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp)
         \            .ConvertToY8()
         """)
\ : edi == "eedi2" && csp == "YV12" ?
\   Eval("""
         pow2  = einput.edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp)
         pow2Y = pow2.ConvertToY8()
         pow2U = pow2.UToY8()
         pow2V = pow2.VToY8()
         """)
\ : edi == "eedi2" && csp == "YV16"  ||
\   edi == "eedi2" && csp == "YUY2"  ||
\   edi == "eedi2" && csp == "YV411" ||
\   edi == "eedi2" && csp == "YV24"   ?
\   Eval("""
         pow2Y = einput.ConvertToYV12()
         \            .edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp)
         \            .ConvertToY8()
         pow2U = einput.UToY8().ConvertToYV12()
         \            .edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp)
         \            .ConvertToY8()
         pow2V = einput.VToY8().ConvertToYV12()
         \            .edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp)
         \            .ConvertToY8()
         """)
\ : edi == "eedi2" && csp == "RGB24" ?
\   Eval("""
         pow2  = Interleave(einput.ShowRed("YV12"),einput.ShowGreen("YV12"),einput.ShowBlue("YV12"))
         pow2  = pow2.edi_rpow2_eedi2(rfactorX,rfactorY,alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp).ConvertToY8()
         splitRGB24 = true
         """)
\ : NOP()

# Crop off the padding
    pad     && (sisphbd ? input.isy() : csp == "Y8")    ||
\   bordfix && (sisphbd ? input.isy() : csp == "Y8")    ||
\   pad     && input.isRGB() ||
\   bordfix && input.isRGB()  ?
\   Eval("""
         pow2  = pow2.Crop(padL*rfactorX, padT*rfactorY, -padR*rfactorX, -padB*rfactorY)
         """)
\ : pad || bordfix ?
\   Eval("""
         pow2Y = pow2Y.Crop(padL*rfactorX, padT*rfactorY, -padR*rfactorX, -padB*rfactorY)
         pow2U = pow2U.Crop(padL_c*rfactorX, padT_c*rfactorY, -padR_c*rfactorX, -padB_c*rfactorY)
         pow2V = pow2V.Crop(padL_c*rfactorX, padT_c*rfactorY, -padR_c*rfactorX, -padB_c*rfactorY)
         """)
\ : NOP()

# Blank luma and chroma channels for Y/U/V=false
noY  = einput.BlankClip(width=ffwidth, height=lsb_out?ffheight*2:ffheight, pixel_type=sisphbd ? "Y"+string(Input.BitsPerComponent()) : "Y8", color_yuv=color_gray)
noUV = einput.BlankClip(width=fwidth_c, height=lsb_out?fheight_c*2:fheight_c, pixel_type=sisphbd ? "Y"+string(Input.BitsPerComponent()) : "Y8", color_yuv=color_gray)

# Center shift correction
    cshift != "" && (sisphbd ? input.isy() : csp == "Y8") ?
\   Eval("""
         shift  = Y ? pow2.ResizeX(ffwidth,ffheight,cshiftH,cshiftV,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noY
         """)
\ : cshift != "" && chr420  ||
\   cshift != "" && chr422  ||
\   cshift != "" && csp == "YUY2"  ||
\   cshift != "" && csp == "YV411" ||
\   cshift != "" && chr444   ?
\   Eval("""
         shiftY = Y ? pow2Y.ResizeX(ffwidth,ffheight,cshiftH,cshiftV,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noY
         shiftU = U ? pow2U.ResizeX(fwidth_c,fheight_c,cshiftH_c,cshiftV_c,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noUV
         shiftV = V ? pow2V.ResizeX(fwidth_c,fheight_c,cshiftH_c,cshiftV_c,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noUV
         shift  = YToUV(shiftU,shiftV,shiftY)
         shift  = csp == "YUY2" ? shift.ConvertToYUY2() : shift
         """)
\ : cshift != "" && input.isRGB() && !splitRGB24 ?
\   Eval("""
         shift  = lsb_out ? Interleave(pow2.ShowRed("Y8"),pow2.ShowGreen("Y8"),pow2.ShowBlue("Y8")) : pow2
         shift  = shift.ResizeX(ffwidth,ffheight,cshiftH,cshiftV,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params)
         """)
\ : cshift != "" && input.isRGB() && splitRGB24 ?
\   Eval("""
         shift  = pow2.ResizeX(ffwidth,ffheight,cshiftH,cshiftV,0,0,cshift,taps,a1,a2, chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params)
         shift  = !lsb_out ? MergeRGB(shift.SelectEvery(3,0),shift.SelectEvery(3,1),shift.SelectEvery(3,2),"RGB24") : shift
         """)
\ : NOP()

# No center shift correction
    cshift == "" && (sisphbd ? input.isy() : csp == "Y8") ?
\   Eval("""
         shift  = Y &&  lsb_out ? pow2.Dither_convert_8_to_16()
         \      : Y && !lsb_out ? pow2
         \                  : noY
         """)
\ : cshift == "" && chr420 && rfactorY == 1 ||
\   cshift == "" && chr420 && !c420fix     ||
\   cshift == "" && chr422                  ||
\   cshift == "" && csp == "YUY2"                  ||
\   cshift == "" && csp == "YV411"                 ||
\   cshift == "" && chr444                   ?
\   Eval("""
         shiftY = Y &&  lsb_out ? pow2Y.Dither_convert_8_to_16()
         \      : Y && !lsb_out ? pow2Y
         \                  : noY
         shiftU = U &&  lsb_out ? pow2U.Dither_convert_8_to_16()
         \      : U && !lsb_out ? pow2U
         \                  : noUV
         shiftV = V &&  lsb_out ? pow2V.Dither_convert_8_to_16()
         \      : V && !lsb_out ? pow2V
         \                  : noUV
         shift  = YToUV(shiftU,shiftV,shiftY)
         shift  = csp == "YUY2" ? shift.ConvertToYUY2() : shift
         """)
\ : cshift == "" && chr420 ?
\   Eval("""
         # Even if the center shift isn't corrected,
         # doubling the height of YV12 causes a vertical chroma shift that needs to be corrected
         shiftY = Y &&  lsb_out ? pow2Y.Dither_convert_8_to_16()
         \      : Y && !lsb_out ? pow2Y
         \                  : noY
         shiftU = U ? pow2U.ResizeX(fwidth_c,fheight_c,0,-0.25,0,0,"Spline36", chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noUV
         shiftV = V ? pow2V.ResizeX(fwidth_c,fheight_c,0,-0.25,0,0,"Spline36", chroma=false, lsb=lsb, lsb_out=lsb_out,mt=mt,mt_params=mt_params) : noUV
         shift  = YToUV(shiftU,shiftV,shiftY)
         """)
\ : cshift == "" && input.isRGB() && !splitRGB24 ?
\   Eval("""
         shift  = lsb_out ? Interleave(pow2.ShowRed("Y8"),pow2.ShowGreen("Y8"),pow2.ShowBlue("Y8")).Dither_convert_8_to_16() : pow2
         """)
\ : cshift == "" && input.isRGB() && splitRGB24 ?
\   Eval("""
         shift  = lsb_out ? pow2.Dither_convert_8_to_16()
         \            : MergeRGB(pow2.SelectEvery(3,0),pow2.SelectEvery(3,1),pow2.SelectEvery(3,2),"RGB24")
         """)
\ : NOP()

shift = sisphbd ? input.hasalpha() && !(shift.hasalpha()) ? shift.AddAlphaPlane(input.ExtractA().edi_rpow2(rfactorX,rfactorY,edi,cshift,fwidth,fheight, 
\									   taps,a1,a2,cplace,Y,U,V,lsb,bordfix,c420fix,
\									   nsize,nns,qual,etype,pscrn,threads,opt,fapprox,
\									   alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
\									   vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,defined(mclip) ? mclip.ExtractA() : mclip,
\									   mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp,mt,mt_params,lsb_out)) : shift : shift

return shift
}

# Recursive functions for repeated edi image doubling
# When calling these functions, the f and t parameters should always be left at their default values.
# They're used only to control behavior during recursion and changing them will cause a malfunction.
function edi_rpow2_nnedi3(clip input, int "rfactorX", int "rfactorY", bool "alignc",
\                         bool "Y", bool "U", bool "V", int "nsize", int "nns", int "qual",
\                         int "etype", int "pscrn", int "threads", int "opt", int "fapprox",
\                         bool "f", bool "t") {

rfactorX = Default(rfactorX, 2)
rfactorY = Default(rfactorY, rfactorX)
alignc   = Default(alignc, false)
Y        = Default(Y, true)
U        = Default(U, true)
V        = Default(V, true)
nsize    = Default(nsize, 0)
nns      = Default(nns, 3)
f        = Default(f, true)
t        = Default(t, false)

Assert(rfactorX > 0 && BitAnd(rfactorX,rfactorX-1) == 0, "edi_rpow2_nnedi3: rfactorX must be a power of 2")
Assert(rfactorY > 0 && BitAnd(rfactorY,rfactorY-1) == 0, "edi_rpow2_nnedi3: rfactorY must be a power of 2")

# YV16/YUY2/YV411 chroma gets mangled by turning, so don't allow processing it
sisphbd = AvsPlusVersionNumber > 2294
chr422  = sisphbd ? input.is422() : input.isYV16()
Assert(!chr422 && !input.IsYUY2() && !input.IsYV411() || !U && !V,
\      "edi_rpow2_nnedi3: YV16/YUY2/YV411 supported only when U and V are false")

# If alignc=true, always use field=1 for doubling the width
# to maintain alignment of horizontally subsampled chroma.
field2 = f ? 1 : 0
field1 = alignc ? 1 : field2
UVbool = U || V ? true : false

# Only turn right if doubling the width and the input isn't already turned
    !t && rfactorX > 1 ?
\   Eval("""
         dbl = IsAvsPlus ? input.TurnRight() : input.sTryFTurnRight(UVbool)
         t   = true
         """)
\ : Eval("""dbl = input""")

dbl = rfactorX > 1 ? dbl.nnedi3(field1,true,Y,U,V,nsize,nns,qual,etype,pscrn,threads,opt,fapprox) : dbl

# Only turn left if the height is going to be doubled or after the last iteration of doubling the width.
# This avoids unnecessary turning when only the width is doubled repeatedly.
    t && rfactorY >  1 ||
\   t && rfactorX == 2  ?
\   Eval("""
         dbl = IsAvsPlus ? dbl.TurnLeft() : dbl.sTryFTurnLeft(UVbool)
         t   = false
         """)
\ : Eval("""dbl = dbl""")

dbl = rfactorY > 1 ? dbl.nnedi3(field2,true,Y,U,V,nsize,nns,qual,etype,pscrn,threads,opt,fapprox) : dbl

return rfactorX > 1 ||
\      rfactorY > 1  ? dbl.edi_rpow2_nnedi3(Max(1,rfactorX/2),Max(1,rfactorY/2),alignc,Y,U,V,
\                                           nsize,nns,qual,etype,pscrn,threads,opt,fapprox,false,t)
\                    : input
}

function edi_rpow2_nnedi3ocl(clip input, int "rfactorX", int "rfactorY", bool "alignc",
\                            bool "Y", bool "U", bool "V", int "nsize", int "nns", int "qual", int "etype",
\                            bool "f", bool "t") {

rfactorX = Default(rfactorX, 2)
rfactorY = Default(rfactorY, rfactorX)
alignc   = Default(alignc, false)
Y        = Default(Y, true)
U        = Default(U, true)
V        = Default(V, true)
nsize    = Default(nsize, 0)
nns      = Default(nns, 3)
f        = Default(f, true)
t        = Default(t, false)

Assert(rfactorX > 0 && BitAnd(rfactorX,rfactorX-1) == 0, "edi_rpow2_nnedi3ocl: rfactorX must be a power of 2")
Assert(rfactorY > 0 && BitAnd(rfactorY,rfactorY-1) == 0, "edi_rpow2_nnedi3ocl: rfactorY must be a power of 2")
sisphbd = AvsPlusVersionNumber > 2294
chr422  = sisphbd ? input.is422() : input.isYV16()
Assert(!chr422 && !input.IsYV411() || !U && !V,
\      "edi_rpow2_nnedi3ocl: YV16/YV411 supported only when U and V are false")

field2 = f ? 1 : 0
field1 = alignc ? 1 : field2
dw     = rfactorX > 1 ? field1 : -1
UVbool = U || V ? true : false

# Doubling the width and height together is faster than turning,
# but doubling only the width causes artifacts because the clip still gets deinterlaced vertically,
# so the input is turned and the height doubled in that case.

dbl1 = input.nnedi3ocl(field2,true,Y,U,V,nsize,nns,qual,etype,dw)

    !t && rfactorX > 1 && rfactorY < 2 ?
\   Eval("""
         dbl2 = IsAvsPlus ? input.TurnRight() : input.sTryFTurnRight(UVbool)
         t    = true
         """)
\ : Eval("""dbl2 = input""")

dbl2 = rfactorX > 1 ? dbl2.nnedi3ocl(field1,true,Y,U,V,nsize,nns,qual,etype,-1) : dbl2

    t && rfactorX == 2 ?
\   Eval("""
         dbl2 = IsAvsPlus ? dbl2.TurnLeft() : dbl2.sTryFTurnLeft(UVbool)
         t    = false
         """)
\ : Eval("""dbl2 = dbl2""")

dbl = rfactorX > 1 && rfactorY < 2 ? dbl2 : dbl1

return rfactorX > 1 ||
\      rfactorY > 1  ? dbl.edi_rpow2_nnedi3ocl(Max(1,rfactorX/2),Max(1,rfactorY/2),alignc,Y,U,V,nsize,nns,qual,etype,false,t)
\                    : input
}

function edi_rpow2_eedi3(clip input, int "rfactorX", int "rfactorY", bool "alignc",
\                        bool "Y", bool "U", bool "V", float "alpha", float "beta", float "gamma",
\                        int "nrad", int "mdis", bool "hp", bool "ucubic", bool "cost3",
\                        int "vcheck", float "vthresh0", float "vthresh1", float "vthresh2",
\                        string "sclip", string "sclip_params", int "threads", clip "mclip", int "opt",
\                        bool "f", bool "t", bool "mt", string "mt_params", int "nnrep") {

rfactorX     = Default(rfactorX, 2)
rfactorY     = Default(rfactorY, rfactorX)
alignc       = Default(alignc, false)
Y            = Default(Y, true)
U            = Default(U, true)
V            = Default(V, true)
sclip        = Default(sclip, "")
sclip_params = Default(sclip_params, sclip == "nnedi3" || sclip == "nnedi3ocl" ? "nsize=0, nns=3" : "")
f            = Default(f, true)
t            = Default(t, false)
nnrep        = Default(nnrep, 0)

Assert(rfactorX > 0 && BitAnd(rfactorX,rfactorX-1) == 0, "edi_rpow2_eedi3: rfactorX must be a power of 2")
Assert(rfactorY > 0 && BitAnd(rfactorY,rfactorY-1) == 0, "edi_rpow2_eedi3: rfactorY must be a power of 2")
sisphbd = AvsPlusVersionNumber > 2294
chr422  = sisphbd ? input.is422() : input.isYV16()
chr420  = sisphbd ? input.is420() : input.isyv12()
Assert(!chr422 && !input.IsYUY2() || !U && !V, "edi_rpow2_eedi3: 422 supported only when U and V are false")

# If the sclip_params string doesn't start with a comma, add one to avoid a syntax error
sclip_params = sclip_params == "" || sclip_params.LeftStr(1) == "," ? sclip_params : ","+sclip_params

field2  = f ? 1 : 0
field1  = alignc ? 1 : field2
UVbool  = U || V ? true : false
Yint    = Y ? 3 : 1
Uint    = U ? 3 : 1
Vint    = V ? 3 : 1

# Use a src_left or src_top shift dependent on the field when resizing
# for the sclip or mclip to keep it in alignment with the eedi3 clip.
# Additionally, the vertical shift for YV12 chroma is doubled,
# so the chroma must be resized separately when doubling the height.
rshift1 = field1 == 1 ? 0.25 : -0.25
rshift2 = field2 == 1 ? 0.25 : -0.25

    !t && rfactorX > 1 ?
\   Eval("""
         dbl      = IsAvsPlus ? input.TurnRight() : input.sTryFTurnRight(UVbool)
         t        = true
         """)
\ : Eval("""
         dbl      = input
         """)

sclip2 = sclip == ""          ? Undefined()
\      : sclip == "nnedi3"    ? Eval(""" rfactorX > 1    ? dbl.nnedi3(field1,true,Y=Y,U=U,V=V"""+sclip_params+""") : Undefined() """)
\      : sclip == "nnedi3ocl" ? Eval(""" rfactorX > 1    ? dbl.nnedi3ocl(field1,true,Y=Y,U=U,V=V"""+sclip_params+""") : Undefined() """)
\      : sclip == "eedi2"     ? Eval(""" rfactorX > 1    ? dbl.eedi2(field=field1"""+sclip_params+""") : Undefined() """)
\                             : Eval(""" rfactorX > 1   &&
                                     \   UVbool         &&
                                     \   chr420          ? dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift1, kernel=sclip,
                                     \                                 luma=Y,mt=mt,mt_params=mt_params, chroma=false"""+sclip_params+""")
                                     \                        .MergeChroma(dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift1*2.0, kernel=sclip,
                                     \                                                 luma=false,mt=mt,mt_params=mt_params, chroma=true"""+sclip_params+"""))
                                     \ : rfactorX > 1    ? dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift1, kernel=sclip,
                                     \                                 luma=Y,mt=mt,mt_params=mt_params, chroma=UVbool"""+sclip_params+""")
                                     \                   : Undefined() """)
mclip1 = mclip.Defined() && rfactorX > 1 ? IsAvsPlus ? mclip.TurnRight() : mclip.sTryFTurnRight(UVbool) : mclip
dbl    = rfactorX > 1 ? dbl.eedi3(field1,true,Y,U,V,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
\                                 vcheck,vthresh0,vthresh1,vthresh2,sclip2,threads,mclip1,opt) : dbl
dbl    = rfactorX > 1 && nnrep > 0 && sclip == "nnedi3" ? nnrep > 1 ? slimit_dif(dbl,sclip2,thr=4) : dbl.Repair(sclip2,9) : dbl

# No need to resize 420 chroma separately here because it's the width being doubled
mclip  = mclip.Defined() && rfactorX > 1 ? mclip.ResizeX(mclip.Width()*2,mclip.Height(),rshift1,0, luma=Y, chroma=UVbool,mt=mt,mt_params=mt_params)
\                                               .mt_binarize(128, Y=Yint, U=Uint, V=Vint)
\                                        : mclip

    t && rfactorY >  1 ||
\   t && rfactorX == 2  ?
\   Eval("""
         dbl = IsAvsPlus ? dbl.TurnLeft() : dbl.sTryFTurnLeft(UVbool)
         t   = false
         """)
\ : Eval("""dbl = dbl""")

sclip2 = sclip == ""          ? Undefined()
\      : sclip == "nnedi3"    ? Eval(""" rfactorY > 1    ? dbl.nnedi3(field2,true,Y=Y,U=U,V=V"""+sclip_params+""") : Undefined() """)
\      : sclip == "nnedi3ocl" ? Eval(""" rfactorY > 1    ? dbl.nnedi3ocl(field2,true,Y=Y,U=U,V=V"""+sclip_params+""") : Undefined() """)
\      : sclip == "eedi2"     ? Eval(""" rfactorY > 1    ? dbl.eedi2(field=field2"""+sclip_params+""") : Undefined() """)
\                             : Eval(""" rfactorY > 1   &&
                                     \   UVbool         &&
                                     \   chr420          ? dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift2, kernel=sclip,
                                     \                                 luma=Y,mt=mt,mt_params=mt_params, chroma=false"""+sclip_params+""")
                                     \                        .MergeChroma(dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift2*2.0, kernel=sclip,
                                     \                                                 luma=false,mt=mt,mt_params=mt_params, chroma=true"""+sclip_params+"""))
                                     \ : rfactorY > 1    ? dbl.ResizeX(dbl.Width(),dbl.Height()*2,0,rshift2, kernel=sclip,
                                     \                                 luma=Y,mt=mt,mt_params=mt_params, chroma=UVbool"""+sclip_params+""")
                                     \                   : Undefined() """)
dbl    = rfactorY > 1 ? dbl.eedi3(field2,true,Y,U,V,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
\                                 vcheck,vthresh0,vthresh1,vthresh2,sclip2,threads,mclip,opt) : dbl
dbl    = rfactorY > 1 && nnrep > 0 && sclip == "nnedi3" ? nnrep > 1 ? slimit_dif(dbl,sclip2,thr=4) : dbl.Repair(sclip2,9) : dbl
mclip  = mclip.Defined() && rfactorY > 1 &&
\        chr420          && UVbool        ? mclip.ResizeX(mclip.Width(),mclip.Height()*2,0,rshift2, luma=Y, chroma=false,mt=mt,mt_params=mt_params)
\                                                .MergeChroma(mclip.ResizeX(mclip.Width(),mclip.Height()*2,0,rshift2*2.0, luma=false, chroma=true,mt=mt,mt_params=mt_params))
\      : mclip.Defined() && rfactorY > 1  ? mclip.ResizeX(mclip.Width(),mclip.Height()*2,0,rshift2, luma=Y, chroma=UVbool,mt=mt,mt_params=mt_params)
\                                                .mt_binarize(128, Y=Yint, U=Uint, V=Vint)
\                                         : mclip

return rfactorX > 1 ||
\      rfactorY > 1  ? dbl.edi_rpow2_eedi3(Max(1,rfactorX/2),Max(1,rfactorY/2),alignc,Y,U,V,alpha,beta,gamma,nrad,mdis,hp,ucubic,cost3,
\                                          vcheck,vthresh0,vthresh1,vthresh2,sclip,sclip_params,threads,mclip,opt,false,t,mt=mt,mt_params=mt_params,nnrep=nnrep)
\                    : input
}

function edi_rpow2_eedi2(clip input, int "rfactorX", int "rfactorY", bool "alignc",
\                        int "mthresh", int "lthresh", int "vthresh", int "estr",
\                        int "dstr", int "maxd", int "map", int "nt", int "pp",
\                        bool "f", bool "t") {

rfactorX = Default(rfactorX, 2)
rfactorY = Default(rfactorY, rfactorX)
alignc   = Default(alignc, false)
f        = Default(f, true)
t        = Default(t, false)

sisp = IsAvsPlus

Assert(rfactorX > 0 && BitAnd(rfactorX,rfactorX-1) == 0, "edi_rpow2_eedi2: rfactorX must be a power of 2")
Assert(rfactorY > 0 && BitAnd(rfactorY,rfactorY-1) == 0, "edi_rpow2_eedi2: rfactorY must be a power of 2")
Assert(!input.IsYUY2(), "edi_rpow2_eedi2: YUY2 not supported")

field2 = f ? 1 : 0
field1 = alignc ? 1 : field2

    !t && rfactorX > 1 ?
\   Eval("""
         dbl = sisp ? input.TurnRight() : input.sTryFTurnRight()
         t   = true
         """)
\ : Eval("""dbl = input""")

dbl = rfactorX > 1 ? dbl.eedi2(mthresh,lthresh,vthresh,estr,dstr,maxd,field1,map,nt,pp) : dbl

    t && rfactorY >  1 ||
\   t && rfactorX == 2  ?
\   Eval("""
         dbl = sisp ? dbl.TurnLeft() : dbl.sTryFTurnLeft()
         t   = false
         """)
\ : Eval("""dbl = dbl""")

dbl = rfactorY > 1 ? dbl.eedi2(mthresh,lthresh,vthresh,estr,dstr,maxd,field2,map,nt,pp) : dbl

return rfactorX > 1 ||
\      rfactorY > 1  ? dbl.edi_rpow2_eedi2(Max(1,rfactorX/2),Max(1,rfactorY/2),alignc,mthresh,lthresh,vthresh,estr,dstr,maxd,map,nt,pp,false,t)
\                    : input
}