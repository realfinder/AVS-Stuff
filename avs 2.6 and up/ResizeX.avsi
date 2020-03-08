/* ResizeX v1.0.1 mod 9.37

ResizeX is a wrapper function for AviSynth's internal resizers and Dither_resize16
that corrects for the chroma shift caused by the internal resizers when they're
used on horizontally subsampled chroma with MPEG2 placement.
If either the lsb_in or lsb parameters are set to true, Dither_resize16 is used.
If both are false, AviSynth's internal resizers are used.

All AviSynth 2.6 colorspaces are supported. However, to use Dither_resize16 on RGB, the input
must first be split into a Y8 clip containing the individual red, green, and blue channels.
This can be done with the following script:


     Interleave(ShowRed("Y8"),ShowGreen("Y8"),ShowBlue("Y8"))
     ResizeX(target_width,target_height, lsb=true)
     DitherPost()
     MergeRGB(SelectEvery(3,0),SelectEvery(3,1),SelectEvery(3,2))


Internal and Dither_resize16 kernels: "Bicubic", "Bilinear", "Blackman", "Gauss", "Lanczos",
                                      "Point", "Sinc", "Spline16", "Spline36", "Spline64"

Dither_resize16 only kernels:         "Blackmanminlobe", "Impulse", "Rect" or "Box", "Spline"

Bicubic kernel presets:               "Catmull-Rom" or "CatRom", "Hermite",
                                      "Mitchell-Netravali" or "Mitchell", "Robidoux", "SoftCubic"

The number of taps for the Blackman, Blackmanminlobe, Lanczos, Sinc, and Spline kernels
can be set with the taps parameter or with a number after the kernel name.
Using the latter method overrides the taps parameter.

The b and c values for the Bicubic kernel can be set with the a1 and a2 parameters, respectively.
If a Bicubic preset is used, it will override a1 and a2.
The p value for the Gauss kernel can be set with a1.

The softness of the SoftCubic preset can be set with a number after it ranging from 0 through 100.
The default is 75.
*/

function ResizeX(clip input, int target_width, int target_height, float "src_left", float "src_top",
\                float "src_width", float "src_height", string "kernel", int "taps", float "a1", float "a2",
\                string "cplace", bool "luma", bool "chroma", bool "lsb_in", bool "lsb", bool "mt", string "mt_params", string "dither_params", bool "lsb_out", bool "desampling", int "dither_mode") {

lsb_in     = Default(lsb_in, false)
lsb_out = Default(lsb_out, false)
lsb        = Default(lsb, false)

lsb        = (lsb_out && !lsb) || (lsb_in && !lsb) ? true : lsb

iw = input.Width()
ih = lsb_in ? input.Height()/2 : input.Height()

src_left   = Default(src_left, 0)
src_top    = Default(src_top, 0)
desampling = Default(desampling, false)
src_width  = Default(src_width, desampling ? 0 : iw)
src_height = Default(src_height, desampling ? 0 : ih)
kernel     = Default(kernel, "Spline36")
cplace     = Default(cplace, "MPEG2")
luma       = Default(luma, true)
chroma     = Default(chroma, true)
mt         = Default(mt, true)
mt_params  = Default(mt_params,      "")
dither_params = Default(dither_params ,      "")
dither_mode   = Default(dither_mode, 6)

lsbdesampling = lsb && desampling
desampling = lsbdesampling ? false : desampling
dither_params = lsbdesampling ? dither_params + ",invks=true" : dither_params

sisphbd = AvsPlusVersionNumber > 2294

Assert(target_width  > 0, "ResizeX: target width must be greater than 0")
Assert(target_height > 0, "ResizeX: target height must be greater than 0")
Assert(cplace == "MPEG1" || cplace == "MPEG2", "ResizeX: cplace must be MPEG1 or MPEG2")
lsb_native = sisphbd ? !(Input.BitsPerComponent() > 8 && (lsb)) : true
sisphbd ? Assert(lsb_native, "lsb hack is not Compatible with native high bit depth" ) : nop()
sisphbd ? Assert(!(Input.isYUVA() && lsb), "lsb hack is not Compatible with YUVA" ) : nop()

# Set correct src_width and src_height values if the input values are zero or negative
src_width  = src_width  == 0 ? desampling ? undefined : iw
\          : src_width  <  0 ? iw-src_left+src_width
\                            : src_width
src_height = src_height == 0 ? desampling ? undefined : ih
\          : src_height <  0 ? ih-src_top+src_height
\                            : src_height

# Get the input clip's colorspace
csp = input.PixelType()

sislumaonly = sisphbd ? input.isy() : input.isy8()

chroma = sislumaonly ? false : chroma

chr420  = sisphbd ? input.is420() : input.isyv12()
chr422  = sisphbd ? input.is422() : input.isYV16()
chr444  = sisphbd ? input.is444() : input.isYV24()

Assert(csp != "RGB24" && csp != "RGB32" || !lsb, "ResizeX: lsb things must be false for RGB input")

# Check for subsampled chroma
hssc12 = chr420 || chr422 || csp == "YUY2"
hssc14 = csp == "YV411"
vssc12 = chr420

Assert(!hssc12 || target_width%2  == 0, "ResizeX: target width of "+csp+" must be a multiple of 2")
Assert(!hssc14 || target_width%4  == 0, "ResizeX: target width of "+csp+" must be a multiple of 4")
Assert(!vssc12 || target_height%2 == 0, "ResizeX: target height of "+csp+" must be a multiple of 2")

# Set chroma target and src values based on the subsampling ratios
target_width_c  = hssc12 ? target_width/2  : hssc14 ? target_width/4 : target_width
target_height_c = vssc12 ? target_height/2 : target_height
src_left_c      = hssc12 ? src_left/2.0    : hssc14 ? src_left/4.0   : src_left
src_top_c       = vssc12 ? src_top/2.0     : src_top
src_width2		= defined(src_width) ? src_width : iw
src_height2		= defined(src_height) ? src_height : ih
src_width_c     = defined(src_width) ? hssc12 ? src_width/2.0   : hssc14 ? src_width/4.0  : src_width : src_width
src_height_c    = defined(src_height) ? vssc12 ? src_height/2.0  : src_height : src_height
src_width_c2    = defined(src_width_c) ? src_width_c : hssc12 ? src_width2/2.0   : hssc14 ? src_width2/4.0  : src_width2
src_height_c2   = defined(src_height_c) ? src_height_c : vssc12 ? src_height2/2.0  : src_height2

# Add the MPEG2 chroma shift correction to the src_left_c value
MPEG2shift = hssc12 ? 0.25*(desampling ? 1.0-Float(target_width_c)/Float(src_width_c2): 1.0-Float(src_width_c2)/Float(target_width_c))
\          : hssc14 ? 0.375*(desampling ? 1.0-Float(target_width_c)/Float(src_width_c2) : 1.0-Float(src_width_c2)/Float(target_width_c))
\                   : 0
src_left_c  = cplace == "MPEG2" && kernel.LeftStr(5) != "Point" ? src_left_c+MPEG2shift
\                                                               : src_left_c

# Remove "Resize" from the end of the kernel string if present
kernel = kernel.RightStr(6) == "Resize" ? kernel.LeftStr(kernel.StrLen()-6) : kernel

# Support the Dither_resize16 kernel name variants when resizing 8-bit
kernel = kernel == "Linear"   ? "Bilinear"
\      : kernel == "Cubic"    ? "Bicubic"
\      : kernel == "Gaussian" ? "Gauss"
\                             : kernel

# Dither_resize16 kernels without an internal equivalent can't be used without lsb things being true
Assert(lsb || kernel == "Spline16" || kernel == "Spline36" || kernel == "Spline64" ||
\      kernel != "Rect" && kernel != "Box" && kernel != "Blackmanminlobe" && kernel.LeftStr(6) != "Spline" && kernel != "Impulse",
\      "ResizeX: Rect, Box, Blackmanminlobe, Spline, and Impulse kernels"+chr(10)+
\      "are available only when resizing for lsb things)")

# Get the taps value from the kernel string if present (overrides the parameter)
taps = kernel.LeftStr(6)  == "Spline"          && kernel != "Spline16" && kernel != "Spline36" && kernel != "Spline64" &&
\                                                 kernel.StrLen() >  6 ? kernel.RightStr(kernel.StrLen()-6).Value().Int()
\    : kernel.LeftStr(7)  == "Lanczos"         && kernel.StrLen() >  7 ? kernel.RightStr(kernel.StrLen()-7).Value().Int()
\    : kernel.LeftStr(8)  == "Blackman"        && kernel.LeftStr(15) != "Blackmanminlobe" &&
\                                                 kernel.StrLen() >  8 ? kernel.RightStr(kernel.StrLen()-8).Value().Int()
\    : kernel.LeftStr(15) == "Blackmanminlobe" && kernel.StrLen() > 15 ? kernel.RightStr(kernel.StrLen()-15).Value().Int()
\    : kernel.LeftStr(4)  == "Sinc"            && kernel.StrLen() >  4 ? kernel.RightStr(kernel.StrLen()-4).Value().Int()
\                                                                      : taps

# Remove the taps value from the kernel string if present
kernel = kernel.LeftStr(6)  == "Spline"          && kernel != "Spline16" && kernel != "Spline36" && kernel != "Spline64" &&
\                                                   kernel.StrLen() >  6 ? kernel.LeftStr(6)
\      : kernel.LeftStr(7)  == "Lanczos"         && kernel.StrLen() >  7 ? kernel.LeftStr(7)
\      : kernel.LeftStr(8)  == "Blackman"        && kernel.LeftStr(15) != "Blackmanminlobe" &&
\                                                   kernel.StrLen() >  8 ? kernel.LeftStr(8)
\      : kernel.LeftStr(15) == "Blackmanminlobe" && kernel.StrLen() > 15 ? kernel.LeftStr(15)
\      : kernel.LeftStr(4)  == "Sinc"            && kernel.StrLen() >  4 ? kernel.LeftStr(4)
\                                                                        : kernel

# Set the a1 and a2 values for bicubic presets (overrides the parameters)
    kernel == "Catmull-Rom" || kernel == "CatRom" ? 
\   Eval("""
         a1     = 0.0
         a2     = 0.5
         kernel = "Bicubic"
         """)
\ : kernel == "Hermite" ?
\   Eval("""
         a1     = 0.0
         a2     = 0.0
         kernel = "Bicubic"
         """)
\ : kernel == "Mitchell-Netravali" || kernel == "Mitchell" ?
\   Eval("""
         a1     = 1.0/3.0
         a2     = 1.0/3.0
         kernel = "Bicubic"
         """)
\ : kernel == "Robidoux" ?
\   Eval("""
         a1     = 0.3782
         a2     = 0.3109
         kernel = "Bicubic"
         """)
\ : kernel == "SoftCubic" ?
\   Eval("""
         a1     = 0.75
         a2     = 0.25
         kernel = "Bicubic"
         """)
\ : kernel.LeftStr(9) == "SoftCubic" && kernel.StrLen() > 9 ?
\   Eval("""
         a1     = kernel.RightStr(kernel.StrLen()-9).Value()
         a1     = a1 >= 0 && a1 <= 100 ? a1/100.0
         \      : Assert(false, "ResizeX: SoftCubic value must be in the range 0 through 100")
         a2     = 1.0-a1
         kernel = "Bicubic"
         """)
\ : NOP()

# If chroma=false and resizing 8-bit YUV, convert to Y8 to avoid processing chroma
csp2   = !chroma && !lsb && !(input.isrgb()) ? "Y" : csp
input2 = csp2 == "Y" && !sislumaonly ? sisphbd ? input.ConvertToY() : input.ConvertToY8() : input

# Convert YUY2 to YV16 because Dither_resize16 only supports planar formats
input2 = csp2 == "YUY2" ? input2.ConvertToYV16() : input2

# Dither_resize16 is used if lsb things is true,
# so the input needs to be converted to stack16 format if lsb_in=false and lsb is used
input2 = !lsb_in && lsb ? input2.Dither_convert_8_to_16() : input2

# Blank luma channel for luma=false
noY = input2.BlankClip(width=target_width, height=target_height, pixel_type=sisphbd ? "Y"+string(Input.BitsPerComponent()) : "Y8", color_yuv=color_gray)

# Perform resizing
    lsb ?
\   Eval("""
         resized = input2.Dither_resize16(target_width,target_height,src_left,src_top,src_width,src_height,kernel,
         \                                taps=taps, a1=a1, a2=a2, cplace=cplace, y=luma?3:1, u=chroma?3:1, v=chroma?3:1"""+dither_params+""")
         """)
\ : input.isRGB() || (sisphbd ? (csp2 == "Y" || input.is444() && luma) : (csp2 == "Y" || csp2 == "YV24" && luma)) ?
\   Eval("""
         r8 = desampling ? input2.ResizeX_deResizemt(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2,mt_params) : \
		 				   mt ? input2.ResizeX_AvsmtResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2,mt_params) : input2.ResizeX_AvsResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2)
         resized = luma || input.isRGB() ? r8 : noY
         """)
\ : Eval("""
         r8Y = sisphbd ? input2.ConvertToY() : input2.ConvertToY8()
         r8Y = desampling ? r8Y.ResizeX_deResizemt(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2,mt_params) : \
		 					mt ? r8Y.ResizeX_AvsmtResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2,mt_params) : r8Y.ResizeX_AvsResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2)
         r8U = sisphbd ? input2.ExtractU() : input2.UToY8()
         r8U = desampling ? r8U.ResizeX_deResizemt(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2,mt_params) : \
		 					mt ? r8U.ResizeX_AvsmtResize(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2,mt_params) : r8U.ResizeX_AvsResize(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2)
         r8V = sisphbd ? input2.ExtractV() : input2.VToY8()
         r8V = desampling ? r8V.ResizeX_deResizemt(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2,mt_params) : \
		 					mt ? r8V.ResizeX_AvsmtResize(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2,mt_params) : r8V.ResizeX_AvsResize(target_width_c,target_height_c,src_left_c,src_top_c,src_width_c,src_height_c,kernel,taps,a1,a2)
         resized = luma ? YToUV(r8U,r8V,r8Y)
         \              : YToUV(r8U,r8V,noY)
         """)

# The resized clip will be in stack16 format if lsb is used, so dither down to 8-bit if lsb_out=false
resized = lsb && !lsb_out ? resized.DitherPost(mode=dither_mode) : resized

# Make sure the output is the same colorspace as the input
resized = csp == "YV12"  ? resized.ConvertToYV12()  
\       : csp == "YV16"  ? resized.ConvertToYV16()
\       : csp == "YUY2"  ? resized.ConvertToYUY2()
\       : csp == "YV411" ? resized.ConvertToYV411()
\       : csp == "YV24"  ? resized.ConvertToYV24()
\       : chr420         ? resized.ConvertToYUV420()  
\       : chr422         ? resized.ConvertToYUV422()  
\       : chr444         ? resized.ConvertToYUV444()  
\                        : resized

resized = sisphbd ? input.IsYUVA() && !(resized.IsYUVA()) ? resized.AddAlphaPlane(mt ? input.ExtractA().ResizeX_AvsmtResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2,mt_params) : input.ExtractA().ResizeX_AvsResize(target_width,target_height,src_left,src_top,src_width,src_height,kernel,taps,a1,a2)) : resized : resized

return resized
}

# Wrapper function for AviSynth's internal resizers
function ResizeX_AvsResize(clip input, int target_width, int target_height, float "src_left", float "src_top",
\                          float "src_width", float "src_height", string "kernel", int "taps", float "a1", float "a2") {

kernel = Default(kernel, "Spline36")

Eval("""
     kernel == "Spline16" ||
\    kernel == "Spline36" ||
\    kernel == "Spline64" || 
\    kernel == "Bilinear" ||
\    kernel == "Point"     ? input."""+kernel+"""Resize(target_width,target_height,src_left,src_top,src_width,src_height)
\  : kernel == "Lanczos"  ||
\    kernel == "Blackman" ||
\    kernel == "Sinc"      ? input."""+kernel+"""Resize(target_width,target_height,src_left,src_top,src_width,src_height,taps)
\  : kernel == "Bicubic"   ? input."""+kernel+"""Resize(target_width,target_height,a1,a2,src_left,src_top,src_width,src_height)
\  : kernel == "Gauss"     ? input."""+kernel+"""Resize(target_width,target_height,src_left,src_top,src_width,src_height,a1)
\                          : Assert(false, "ResizeX_AvsResize: invalid kernel")
     """)
}

# Wrapper function for AviSynth's mt resizers
function ResizeX_AvsmtResize(clip input, int target_width, int target_height, float "src_left", float "src_top",
\                          float "src_width", float "src_height", string "kernel", int "taps", float "a1", float "a2", string "mt_params") {

kernel    = Default(kernel, "Spline36")
mt_params = Default(mt_params,      "")

try { Eval("""
     kernel == "Spline16" ||
\    kernel == "Spline36" ||
\    kernel == "Spline64" || 
\    kernel == "Bilinear" ||
\    kernel == "Point"     ? input."""+kernel+"""Resizemt(target_width,target_height,src_left,src_top,src_width,src_height"""+mt_params+""")
\  : kernel == "Lanczos"  ||
\    kernel == "Blackman" ||
\    kernel == "Sinc"      ? input."""+kernel+"""Resizemt(target_width,target_height,src_left,src_top,src_width,src_height,taps"""+mt_params+""")
\  : kernel == "Bicubic"   ? input."""+kernel+"""Resizemt(target_width,target_height,a1,a2,src_left,src_top,src_width,src_height"""+mt_params+""")
\  : kernel == "Gauss"     ? input."""+kernel+"""Resizemt(target_width,target_height,src_left,src_top,src_width,src_height,a1"""+mt_params+""")
\                          : Assert(false, "ResizeX_AvsmtResize: invalid kernel")
          """)
      } catch(error_msg) { input.ResizeX_AvsResize(target_width, target_height, src_left, src_top, src_width, src_height, kernel, taps, a1, a2) }
}

# Wrapper function for AviSynth's mt deresizers
function ResizeX_deResizemt(clip input, int target_width, int target_height, float "src_left", float "src_top",
\                          float "src_width", float "src_height", string "kernel", int "taps", float "a1", float "a2", string "mt_params") {

kernel    = Default(kernel, "Spline36")
mt_params = Default(mt_params,      "")

     kernel == "Spline16" ||
\    kernel == "Spline36" ||
\    kernel == "Spline64" || 
\    kernel == "Bilinear"  ? Eval("input.de"+kernel+"Resizemt(target_width,target_height,src_left,src_top,src_width,src_height"+mt_params+")")
\  : kernel == "Lanczos"  ||
\    kernel == "Blackman" ||
\    kernel == "Sinc"      ? Eval("input.de"+kernel+"Resizemt(target_width,target_height,src_left,src_top,src_width,src_height,taps"+mt_params+")")
\  : kernel == "Bicubic"   ? Eval("input.de"+kernel+"Resizemt(target_width,target_height,a1,a2,src_left,src_top,src_width,src_height"+mt_params+")")
\  : kernel == "Gauss"     ? Eval("input.de"+kernel+"Resizemt(target_width,target_height,src_left,src_top,src_width,src_height,a1"+mt_params+")")
\                          : Assert(false, "ResizeX_deResizemt: invalid kernel")
}

# base on Dither_resize16nr
Function sResizeXnr (clip src, int width, int height,
\	float  "src_left",
\	float  "src_top",
\	float  "src_width",
\	float  "src_height",
\	string "kernel",
\	int    "taps",
\	float  "a1",
\	float  "a2",
\	string "cplace",
\	bool   "luma",
\	bool   "chroma",
\	bool   "mt",
\	string "mt_params",
\	string "dither_params",
\	bool   "desampling",
\	int    "dither_mode",
\	bool   "noring"
\	)
{
	noring = Default (noring, true)

	Assert (width > 0 && height > 0, "sResizeXnr: width and height must be > 0.")

	sr_h  = Float (width ) / Float (src.width () )
	sr_v  = Float (height) / Float (src.height ())
	sr_up =       max (sr_h, sr_v)
	sr_dw = 1.0 / min (sr_h, sr_v)
	sr    = max (sr_up, sr_dw)
	Assert (sr >= 1.0)

	# Depending on the scale ratio, we may blend or totally disable
	# the ringing cancellation
	thr = 2.5
	nrb = (sr > thr)
	nrf = (sr < thr + 1.0 && noring)
	nrr = (nrb) ? min (sr - thr, 1.0) : 1.0
	nrv = (nrb) ? Round ((1.0 - nrr) * 255) * $010101 : 0

	main = src.ResizeX (width, height,
\		src_left  =src_left,
\		src_top   =src_top,
\		src_width =src_width,
\		src_height=src_height,
\		kernel    =kernel,
\		taps      =taps,
\		a1        =a1,
\		a2        =a2,
\		cplace    =cplace,
\		luma      =luma,
\		chroma    =chroma,
\		mt        =mt,
\		mt_params =mt_params,
\		dither_params=dither_params,
\		desampling=desampling,
\		dither_mode=dither_mode
\	)

	nrng = (nrf) ? src.ResizeX (width, height,
\		src_left  =src_left,
\		src_top   =src_top,
\		src_width =src_width,
\		src_height=src_height,
\		kernel    ="gauss",
\		a1        =100,
\		cplace    =cplace,
\		luma      =luma,
\		chroma    =chroma
\	) : main

	nrm = (nrb && nrf) ? main.BlankClip (color_yuv=nrv, height=main.Height()) : main

	rgm  = 1
	rgc  = (nrb) ? -1 : 0
	ild  = Defined(luma)
	icd  = Defined(chroma)
	rgl  = ild ? (luma   ? rgm : rgc) : rgm
	rgch = icd ? (chroma ? rgm : rgc) : rgm
	y    = ild ? luma ? 3 : 2 : 3
	u    = icd ? chroma ? 3 : 2 : 3
	v    = u
	(nrf       ) ? main.repair (nrng, rgl, rgch)                                          : main
	(nrf && nrb) ? mt_merge (main, last, nrm, y=y, u=u, v=v, cplace=cplace , luma=chroma) : last
}

