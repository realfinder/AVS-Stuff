/* DebilinearM v1.3.1 mod 1.28

DebilinearM is a wrapper function for the Debilinear and Debicubic plugins that masks parts of the frame that aren't upscaled,
such as text overlays, and uses a regular resize kernel to downscale those areas. It works by downscaling the input
clip to the target resolution with Debilinear or Debicubic, upscaling it again, comparing it to the original clip,
and masking pixels that have a difference greater than the specified threshold.

##### Requirements #####

Plugins:
  Debicubic
  Debilinear
  Dither
  MaskTools2

Scripts:
  ResizeX

Color formats:
  Depends on settings and the avs/avs+ ver.
*/

function DebilinearM(clip input, int target_width, int target_height, int "thr", int "expand", int "inflate",
\                    string "kernel", int "taps", float "a1", float "a2", bool "cubic", float "b", float "c",
\                    bool "chroma", bool "lsb_inout", int "showmask", bool "DeResizeMT", bool "use_IResize", int "expandmode", int "inflatemode", bool "ifields") {

# Default settings and other variable assignment
thr       = Default(thr, 10)
expand    = Default(expand, 1)
inflate   = Default(inflate, 2)
kernel    = Default(kernel, "Spline36")
cubic     = Default(cubic, false)
chroma    = Default(chroma, true)
lsb_inout = Default(lsb_inout, false)
DeRMT     = Default(DeResizeMT, false)
use_IRe   = Default(use_IResize, false)
showmask  = Default(showmask, 0)
expdmode  = Default(expandmode, use_IRe ? 1 : 3) #0=square 1=horizontal 2=vertical 3=both
inflmode  = Default(inflatemode, use_IRe ? 1 : 0) #0=mt_inflate 1=horizontal 2=vertical 3=both
ifields   = Default(ifields, use_IRe && (expdmode!=1 || inflmode!=1))

Assert(target_width  > 0, "DebilinearM: target width must be greater than 0")
Assert(target_height > 0, "DebilinearM: target height must be greater than 0")
Assert(thr >= 0 && thr <= 255, "DebilinearM: thr must be in the range 0 to 255")
Assert(showmask > -1 && showmask < 3, "DebilinearM: showmask must be 0, 1, or 2")
Assert(!(lsb_inout && interlaced), "Interlaced 16 bit stacked clip is not a recognized format")

w = input.Width()
h = lsb_inout ? input.Height()/2 : input.Height()

uvint = chroma ? 3
\              : 1

# Resizing
input_8bit = lsb_inout ? input.DitherPost(mode=-1) : input

    use_IRe ? 
\   Eval("""
         dbi      = input.IResizeResizexwarpForDebilinearM(target_width,target_height,cubic ? "Bicubic" : "Bilinear", a1=b, a2=c, chroma=chroma, desampling=true)
         dbi2     = dbi.IResizeResizexwarpForDebilinearM(w,h,cubic ? "Bicubic" : "Bilinear", a1=b, a2=c, chroma=chroma)
         """)
\ : DeRMT ? 
\   Eval("""
         dbi      = input.ResizeX(target_width,target_height, a1=b, a2=c, chroma=chroma, desampling=true, kernel=cubic ? "Bicubic" : "Bilinear", lsb_in=lsb_inout, lsb_out=lsb_inout)
         dbi2     = dbi.ResizeX(w,h, kernel=cubic ? "Bicubic" : "Bilinear", a1=b, a2=c, chroma=chroma, lsb_in=lsb_inout, lsb_out=false, dither_mode=-1)
         """)
\ : cubic ?
\   Eval("""
         dbi      = chroma ? input.Debicubic(target_width,target_height, b=b, c=c, lsb_inout=lsb_inout)
         \                 : input.DebicubicY(target_width,target_height, b=b, c=c, lsb_inout=lsb_inout)
         dbi_8bit = chroma ? input_8bit.Debicubic(target_width,target_height, b=b, c=c)
         \                 : input_8bit.DebicubicY(target_width,target_height, b=b, c=c)
         dbi2     = lsb_inout ? dbi_8bit.ResizeX(w,h, kernel="Bicubic", a1=b, a2=c, chroma=chroma)
         \                    : dbi.ResizeX(w,h, kernel="Bicubic", a1=b, a2=c, chroma=chroma)
         """)
\ : Eval("""
         dbi      = chroma ? input.Debilinear(target_width,target_height, lsb_inout=lsb_inout)
         \                 : input.DebilinearY(target_width,target_height, lsb_inout=lsb_inout)
         dbi_8bit = chroma ? input_8bit.Debilinear(target_width,target_height)
         \                 : input_8bit.DebilinearY(target_width,target_height)
         dbi2     = lsb_inout ? dbi_8bit.ResizeX(w,h, kernel="Bilinear", chroma=chroma)
         \                    : dbi.ResizeX(w,h, kernel="Bilinear", chroma=chroma)
         """)

rs = use_IRe ? input.IResizeResizexwarpForDebilinearM(target_width,target_height, kernel=kernel, taps=taps, a1=a1, a2=a2, chroma=chroma) : input.ResizeX(target_width,target_height, kernel=kernel, taps=taps, a1=a1, a2=a2, chroma=chroma, lsb_in=lsb_inout, lsb_out=lsb_inout)

# Masking
diffmask = mt_lutxy(input_8bit,dbi2, "x y - abs", use_expr=1, U=uvint, V=uvint).mt_binarize(threshold=thr, U=uvint, V=uvint)
diffmask = showmask == 2 ? diffmask.DebilinearM_expand(expand=expand, expandmode=expdmode, ifields=ifields, U=uvint, V=uvint)
\                                  .DebilinearM_inflate(inflate=inflate, inflatemode=inflmode, ifields=ifields, U=uvint, V=uvint)
\                        : use_IRe ? diffmask.IResizeResizexwarpForDebilinearM(target_width,target_height, kernel="Bilinear", chroma=chroma)
\                                  .mt_binarize(threshold=3, U=uvint, V=uvint)
\                                  .DebilinearM_expand(expand=expand, expandmode=expdmode, ifields=ifields, U=uvint, V=uvint)
\                                  .DebilinearM_inflate(inflate=inflate, inflatemode=inflmode, ifields=ifields, U=uvint, V=uvint) : diffmask.ResizeX(target_width,target_height, kernel="Bilinear", chroma=chroma)
\                                  .mt_binarize(threshold=3, U=uvint, V=uvint)
\                                  .DebilinearM_expand(expand=expand, expandmode=expdmode, ifields=ifields, U=uvint, V=uvint)
\                                  .DebilinearM_inflate(inflate=inflate, inflatemode=inflmode, ifields=ifields, U=uvint, V=uvint)

merged = lsb_inout ? Dither_merge16_8(dbi,rs,diffmask, u=uvint, v=uvint)
\                  : mt_merge(dbi,rs,diffmask, U=uvint, V=uvint)

return showmask > 0 ? diffmask
\                   : merged
}

# DebicubicM alias
function DebicubicM(clip input, int target_width, int target_height, int "thr", int "expand", int "inflate",
\                   string "kernel", int "taps", float "a1", float "a2", float "b", float "c",
\                   bool "chroma", bool "lsb_inout", int "showmask", bool "DeResizeMT", bool "use_IResize", int "expandmode", int "inflatemode", bool "ifields") {

return DebilinearM(input,target_width,target_height,thr,expand,inflate,kernel,taps,a1,a2,true,b,c,chroma,lsb_inout,showmask,DeResizeMT,use_IResize,expandmode,inflatemode,ifields)
}


# Helper functions
function DebilinearM_expand(clip input, int "expand", int "U", int "V", int "expandmode", bool "ifields") {
expdmode = Default(expandmode, 0)
ifields = Default(ifields, false)
expdmstr = expdmode == 1 ? "horizontal" : expdmode == 2 ? "vertical" : expdmode == 3 ? "both" : "square"
expclp  = expand > 0 ? ifields ? input.SeparateFields().mt_expand(mode=expdmstr, U=U, V=V).Weave() : input.mt_expand(mode=expdmstr, U=U, V=V) : nop()
return expand > 0 ? DebilinearM_expand(expclp, expand-1, U, V, expdmode, ifields)
\                 : input
}

function DebilinearM_inflate(clip input, int "inflate", int "U", int "V", int "inflatemode", bool "ifields") {
sisphbd     = AvsPlusVersionNumber > 2294
inflmode = Default(inflatemode, 0)
ifields = Default(ifields, false)
input   = inflate > 0 && ifields ? input.SeparateFields() : input
srcy        = inflmode!=0 ? sisphbd ? ExtractY(input) : ConvertToY8(input) : nop()
srcu        = inflmode!=0 ? sisphbd ? ExtractU(input) : UToY8(input) : nop()
srcv        = inflmode!=0 ? sisphbd ? ExtractV(input) : VToY8(input) : nop()
inflclp = inflmode!=0 ? YToUV(u==3 ? srcu.swhiterPixel(srcu.blur(inflmode!=2 ? 1 : 0,inflmode!=1 ? 1 : 0),255,255,false,0) : srcu, v==3 ? srcv.swhiterPixel(srcv.blur(inflmode!=2 ? 1 : 0,inflmode!=1 ? 1 : 0),255,255,false,0) : srcu, srcy.swhiterPixel(srcy.blur(inflmode!=2 ? 1 : 0,inflmode!=1 ? 1 : 0),255,255,false,0)) : input.mt_inflate(U=U, V=V)
inflclp = ifields ? inflclp.Weave() : inflclp
return inflate > 0 ? DebilinearM_inflate(inflclp, inflate-1, U, V, inflmode, ifields)
\                  : input
}

function IResizeResizexwarpForDebilinearM(clip input, int target_width, int target_height, string "kernel", float "a1", float "a2", int "taps", bool "chroma", bool "desampling") {
desampling     = Default(desampling, false)
chroma = defined(chroma) ? ", chroma="+string(chroma) : ""
kernel = defined(kernel) ? """, kernel=""""+string(kernel)+""""""" : ""
taps = defined(taps) ? ", taps="+string(taps) : ""
a1 = defined(a1) ? ", a1="+string(a1) : ""
a2 = defined(a2) ? ", a2="+string(a2) : ""
return desampling ? input.IResize(target_width,target_height,res_params=""", desampling=true"""+kernel+a1+a2+taps+chroma,resifilter="resizex")
\                 : input.IResize(target_width,target_height,res_params=""", desampling=false"""+kernel+a1+a2+taps+chroma,resifilter="resizex")
}