#################################################################################################
###### eedi3_resize16 v3.3.09 ###### by mawen1250 mod by A.SONY ######      2020.09.09      ######
#################################################################################################
###### from v2.8 on, eedi3_resize16 only supports AviSynth v2.6+                          ######
###### Requirements: masktools v2.0a48, dither v1.25.1, eedi3 v0.9.2.3,                     ######
######               SmoothAdjust v3.00, Contra-Sharpen mod 3.4 (only for sharp>0),        ######
######               FTurn v1.4 (not necessarily required but will improve speed)          ######
######               nnedi3 v0.9.4.19 (only for nnsclip=true)                              ######
#################################################################################################
###### accept Y8, YV12, YV16, YV24 input, use eedi3 and Dither_resize16(nr) for scaling   ######
###### output format can be 8bit/16bit Y8/YV12/YV16/YV24 or RGB32/RGB24/RGB48YV12/RGB48Y   ######
#################################################################################################
###### "lsb_in"/"lsb" defines if input/output clip is stacked-16bit, default is False      ######
###### "output" defines colorspace of output clip, for RGB output "lsb" is ignored         ######
#################################################################################################
###### when horizontal/vertical scale ratio >  "ratiothr", we assume it's upscaling        ######
###### when horizontal/vertical scale ratio <= "ratiothr", we assume it's downscaling      ######
###### by default ratiothr=1.125                                                           ######
###### eedi3 is only applied when upscaling                                               ######
###### Dither_resize16 is used after eedi3 upscaling to fix shift and scale to target res ######
###### we call the eedi3+Dither_resize16 scaling method "edge area resize"                ######
###### for downscaling, Dither_resize16 is applied instead, we call it "flat area resize"  ######
###### when mixed=True, eedi3 (edge area) is combined with Dither_resize16 (flat area)    ######
#################################################################################################


Function eedi3_resize16(clip input, int "target_width", int "target_height", float "src_left", float "src_top",
\                        float "src_width", float "src_height",
\                        string "kernel_d", string "kernel_u", float "f_d", float "f_u", int "taps",
\                        float "a1", float "a2", float "a3", bool "invks_d", bool "invks_u", int "invkstaps", bool "noring",
\                        int "nsize", int "nns", int "qual", int "etype", int "pscrn", int "threads",
\                        float "ratiothr", bool "mixed", float "thr", float "elast", float "sharp",
\                        string "output", bool "tv_range", string "cplace", string "matrix", string "curve", float "gcor",
\                        int "Y", int "U", int "V", bool "lsb_in", bool "lsb", int "dither", bool "nnsclip", float "alpha",
\                        float "beta", float "gamma", int "nrad", int "mdis", bool "hp", bool "ucubic", bool "cost3", 
\                        int "vcheck", float "vthresh0", float "vthresh1", float "vthresh2", int "nnrep")
{
    ###############################################################################################################################
    ###############################################################################################################################
    # Parameters for merging edge&flat upscaled clip
	
    mixed    = Default(mixed,    True   )   # eedi3_resize16 uses eedi3+Dither_resize16 for edge upscaling, this parameter defines whether to combine eedi3+Dither_resize16(edge area) and Dither_resize16(flat area) in upscaling, which achieves higher precision upscaling result(mainly for flat area).
    thr      = Default(thr,      1.0    )   # the same with "thr"   in Dither_limit_dif16, valid value range is (0, 10.0].
    elast    = Default(elast,    1.5    )   # the same with "elast" in Dither_limit_dif16, valid value range is [1, 10.0].
                                            # PDiff: pixel value diff between flat   clip and edge clip (edge clip as reference)
                                            # ODiff: pixel value diff between merged clip and edge clip (edge clip as reference)
                                            # PDiff, thr and elast is used to calculate ODiff:
                                            # ODiff = PDiff when [PDiff <= thr]
                                            # ODiff gradually smooths from thr to 0 when [thr <= PDiff <= thr * elast]
                                            # for elast>2.0, ODiff reaches maximum when [PDiff == thr * elast / 2]
                                            # ODiff = 0     when [PDiff >= thr * elast]
                                            #
                                            # Larger "thr"   will result in more pixels being taken from flat area upscaled clip (Dither_resize16)
                                            # Larger "thr"   will result in less pixels being taken from edge area upscaled clip (eedi3+Dither_resize16)
                                            # Larger "elast" will result in more pixels being blended from edge&flat area upscaled clip, for smoother merging
    
    ###############################################################################################################################
	###############################################################################################################################
    # Parameters for nnedi3
	
    nsize    = Default(nsize,    0      )
    nns      = Default(nns,      3      )
    qual     = Default(qual,     2      )
    etype    = Default(etype,    0      )
    pscrn    = Default(pscrn,    2      )
    threads  = Default(threads,  sh_GetUserGlobalIMTint(true))
    nnsclip  = Default(nnsclip,  false  )
    
    ###############################################################################################################################
	###############################################################################################################################
    # Parameters for Dither_resize16
	
    kernel_d = Default(kernel_d, "Spline36" )   # "kernelh","kernelv" of Dither_resize16 used in downscaling
    kernel_u = Default(kernel_u, "Spline64" )   # "kernelh","kernelv" of Dither_resize16 used in upscaling
	f_d      = Default(f_d,      1.0        )   # "fh","fv" of Dither_resize16 used in downscaling
	f_u      = Default(f_u,      1.0        )   # "fh","fv" of Dither_resize16 used in upscaling
	taps     = Default(taps,     4          )   # "taps"    of Dither_resize16
	# a1, a2, a3                                # "a1","a2","a3"      of Dither_resize16
	invks_d  = Default(invks_d,  False      )   # "invksh","invksv"   of Dither_resize16 used in downscaling
	invks_u  = Default(invks_u,  False      )   # "invksh","invksv"   of Dither_resize16 used in upscaling
	invkstaps= Default(invkstaps,5          )   # "invkstaps"         of Dither_resize16
	
    noring   = Default(noring,   False      )   # True use non-ringing algorithm of Dither_resize16 in flat area scaling
                                                # It actually doesn't make much sense for eedi3_resize16(which uses eedi3 for upscaling),
                                                # while it may produce blurring and aliasing when downscaling.
                                                # You'd better not set it to True unless you know what you are doing.
    resste   = "Dither_resize16"
    resstf   = noring ? "Dither_resize16nr" : "Dither_resize16"
    
    ###############################################################################################################################
	###############################################################################################################################
    # Post-Process
	
    sharp    = Default(sharp,    0      )   # Strength of Contra-Sharpen mod, for sharper edge. 0 means no sharpening, common value is about 100.
                                            # *Only* when {horrizontal or vertical}{scale ratio}>{ratiothr} will sharpening take effect (when eedi3 is used for upscaling).
    
    ###############################################################################################################################
	###############################################################################################################################
    # Parameters for input/output
	
    Y        = Default(Y,        3      )
    U        = Default(U,        3      )
    V        = Default(V,        3      )
    lsb_in   = Default(lsb_in,   False  )   # input  clip is 16-bit stacked or not
    lsb      = Default(lsb,      False  )   # output clip is 16-bit stacked or not
    tv_range = Default(tv_range, True   )   # input  clip is TV-range or PC-range
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50)    # dither mode for 16-bit to 8-bit conversion
    
    sCSP     = input.eedi3_resize16_GetCSP()
    Assert(sCSP=="Y8" || sCSP=="YV12" || sCSP=="YV16" || sCSP=="YV24", """eedi3_resize16: only accept Y8, YV12, YV16, YV24 input""")
    
    output   = Default(output,   sCSP   )
    # Output format. Possible values are:
    # "Y8"       : Regular Y8    colorspace. Parameter "lsb" works on this output mode.
    # "YV12"     : Regular YV12  colorspace. Parameter "lsb" works on this output mode.
    # "YV16"     : Regular YV16  colorspace. Parameter "lsb" works on this output mode.
    # "YV24"     : Regular YV24  colorspace. Parameter "lsb" works on this output mode.
    # "RGB32"    : Regular RGB32 colorspace.
    # "RGB24"    : Regular RGB24 colorspace.
    # "RGB48YV12": 48-bit RGB conveyed on YV12. Use it for rawvideo export only. Not suitable for display or further processing (it will look like garbage).
    # "RGB48Y"   : 48-bit RGB. The components R, G and B are conveyed on three YV12 or Y8 (if supported) stack16 clips interleaved on a frame basis.
    
	###############################################################################################################################
	
    IsY8     = sCSP == "Y8" || output == "Y8"
    sCSP     = IsY8 ? "YV24" : sCSP
    
    IsRGB    = LeftStr(output, 3) == "RGB"
    oCSP     = IsRGB || IsY8 ? "YV24" : output
    
    Y        = min(Y, 4)
    U        = IsY8 ? 1 : min(U, 4)
    V        = IsY8 ? 1 : min(V, 4)
    Yt       = Y == 3 || Y == 4
    Ut       = U == 3 || U == 4
    Vt       = V == 3 || V == 4
    Y31      = Yt ? 3 : 1
    U31      = Ut ? 3 : 1
    V31      = Vt ? 3 : 1
    Y32      = Yt ? 3 : Y
    U32      = Ut ? 3 : U
    V32      = Vt ? 3 : V
    Y21      = Yt ? 2 : Y
    U21      = Ut ? 2 : U
    V21      = Vt ? 2 : V
    Y321     = Y > 1 ? 3 : Y
    U321     = U > 1 ? 3 : U
    V321     = V > 1 ? 3 : V
    
    sw       = input.Width ()
    sh       = input.Height()
    sh       = lsb_in ? sh/2 : sh
    swc      = sCSP=="YV24" ? sw   : sw/2
    shc      = sCSP=="YV12" ? sh/2 : sh
    HD       = (sw > 1024 || sh > 576) ? True : False
    
	###############################################################################################################################
	
    cplace   = Default(cplace,   "MPEG2")
    # Placement of the chroma subsamples. Can be one of these strings:
    # "MPEG1": 4:2:0 subsampling used in MPEG-1. Chroma samples are located on the center of each group of 4 pixels.
    # "MPEG2": Subsampling used in MPEG-2 4:2:x. Chroma samples are located on the left pixel column of the group.
    
    matrix   = Default(matrix,   HD ? "709" : "601")
    # The matrix used to convert the YUV pixels to computer RGB. Possible values are:
    # "601"  : ITU-R BT.601 / ITU-R BT.470-2 / SMPTE 170M. For Standard Definition content.
    # "709"  : ITU-R BT.709. For High Definition content.
    # "240"  : SMPTE 240M
    # "FCC"  : FCC
    # "YCgCo": YCgCo
    # When the parameter is not defined, ITU-R BT.601 and ITU-R BT.709 are automatically selected depending on the clip definition.
    
    curve    = Default(curve,    "linear"   )
    # type of gamma mapping(transfer characteristic) for gamma-aware resize(only take effects for Dither_resize16 processing parts)
    # possible values:
    # "709"    - ITU-R BT.709 transfer curve for digital video
    # "601"    - ITU-R BT.601 transfer curve, same as "709"
    # "170"    - SMPTE 170M, same as "709"
    # "240"    - SMPTE 240M (1987)
    # "srgb"   - sRGB curve
    # "2020"   - ITU-R BT.2020 transfer curve, for 12-bit content. For sources of lower bitdepth, use the "709" curve.
    # "linear" - linear curve without gamma-aware processing
    curve    = Yt ? curve : "linear"
    gcor     = Default(gcor,     1.0    )   # Gamma correction, applied on the linear part.
    
    ###############################################################################################################################
	###############################################################################################################################
    # Parameters for scaling
	
    ow       = Default(target_width,  sw)
    oh       = Default(target_height, sh)
    owc      = oCSP=="YV24" ? ow   : ow/2
    ohc      = oCSP=="YV12" ? oh/2 : oh
    Assert(!(output=="YV16" && ow!=owc*2), """eedi3_resize16: width  of YV16 output clip must be MOD2!""")
    Assert(!(output=="YV12" && ow!=owc*2), """eedi3_resize16: width  of YV12 output clip must be MOD2!""")
    Assert(!(output=="YV12" && oh!=ohc*2), """eedi3_resize16: height of YV12 output clip must be MOD2!""")
    
    src_left    = Default(src_left,   0 )
    src_top     = Default(src_top,    0 )
    src_width   = Default(src_width,  sw)
    src_height  = Default(src_height, sh)
    
    ###############################################################################################################################
	###############################################################################################################################
    # Pre-Cropping/sh_Padding Calculation
	
    prel        = int(src_left/2) * 2
    pret        = int(src_top /2) * 2
    prer        = int((src_width > 0 ? -sw+src_left+src_width : src_width )/2) * 2
    preb        = int((src_height> 0 ? -sh+src_top+src_height : src_height)/2) * 2
    prew        = sw - prel + prer
    preh        = sh - pret + preb
    
    sCSP=="YV24" ? \
    Eval("""
        swmod2      = sw  /2*2 == sw
        pwmod2      = prew/2*2 == prew
        wpre        = prew < sw
        prel        = wpre ?          prel            :          0
        prer        = wpre ? pwmod2 ? prer : prer + 1 : swmod2 ? 0 : 1
        prew        = sw - prel + prer
        wpre        = prew < sw || !swmod2
    """) : \
    Eval("""
        swmod4      = sw  /4*4 == sw
        pwmod4      = prew/4*4 == prew
        wpre        = prew < sw
        prel        = wpre ?          prel            :          0
        prer        = wpre ? pwmod4 ? prer : prer + 2 : swmod4 ? 0 : 2
        prew        = sw - prel + prer
        wpre        = prew < sw || !swmod4
    """)
    
    sCSP=="YV12" ? \
    Eval("""
        shmod4      = sh  /4*4 == sh
        phmod4      = preh/4*4 == preh
        hpre        = preh < sh
        pret        = hpre ?          pret            :          0
        preb        = hpre ? phmod4 ? preb : preb + 2 : shmod4 ? 0 : 2
        preh        = sh - pret + preb
        hpre        = preh < sh || !shmod4
    """) : \
    Eval("""
        shmod2      = sh  /2*2 == sh
        phmod2      = preh/2*2 == preh
        hpre        = preh < sh
        pret        = hpre ?          pret            :          0
        preb        = hpre ? phmod2 ? preb : preb + 1 : shmod2 ? 0 : 1
        preh        = sh - pret + preb
        hpre        = preh < sh || !shmod2
    """)
    
    src_width   = src_width <=0 ? +sw-src_left+src_width : src_width
    src_height  = src_height<=0 ? +sh-src_top+src_height : src_height
    src_left    = wpre ? src_left-prel : src_left
    src_top     = hpre ? src_top -pret : src_top
    
    src_leftc   = sCSP=="YV24" ? src_left      : src_left  /2.
    src_topc    = sCSP=="YV12" ? src_top   /2. : src_top
    src_widthc  = sCSP=="YV24" ? src_width     : src_width /2.
    src_heightc = sCSP=="YV12" ? src_height/2. : src_height
    
    ###############################################################################################################################
	###############################################################################################################################
    # Scaling Ratio Calculation
	
    ratiothr = Default(ratiothr,   1.125)    # When scale ratio is larger than ratiothr, use eedi3+Dither_resize16 upscale method instead of pure Dither_resize16.
	# when horizontal/vertical scale ratio >  "ratiothr", we assume it's upscaling
    # when horizontal/vertical scale ratio <= "ratiothr", we assume it's downscaling
    
	###############################################################################################################################
	
    yhratio  = float(ow ) / float(src_width  )
    yvratio  = float(oh ) / float(src_height )
    chratio  = float(owc) / float(src_widthc )
    cvratio  = float(ohc) / float(src_heightc)
    
    enable   = yhratio!=1 || yvratio!=1 || chratio!=1 || cvratio!=1 ||
    \          src_width  !=int(src_width  ) || src_height !=int(src_height ) || src_widthc !=int(src_widthc ) || src_heightc!=int(src_heightc) ||
    \          src_left   !=int(src_left   ) || src_top    !=int(src_top    ) || src_leftc  !=int(src_leftc  ) || src_topc   !=int(src_topc   )
    
    yhct     = yhratio>ratiothr ? Ceil( log(yhratio/ratiothr) / log(2) ) : 0
    yhrf     = int(Pow(2, yhct))
    yrhratio = yhratio/yhrf
    yvct     = yvratio>ratiothr ? Ceil( log(yvratio/ratiothr) / log(2) ) : 0
    yvrf     = int(Pow(2, yvct))
    yrvratio = yvratio/yvrf
    
    chct     = chratio>ratiothr ? Ceil( log(chratio/ratiothr) / log(2) ) : 0
    chrf     = int(Pow(2, chct))
    crhratio = chratio/chrf
    cvct     = cvratio>ratiothr ? Ceil( log(cvratio/ratiothr) / log(2) ) : 0
    cvrf     = int(Pow(2, cvct))
    crvratio = cvratio/cvrf
    
    nonenny  = yhct<=0 && yvct<=0
    nonennc  = chct<=0 && cvct<=0
    nonenn   = nonenny || nonennc
    
    Ynnt     = Yt&&!nonenny
    Unnt     = Ut&&!nonennc
    Vnnt     = Vt&&!nonennc
    Ynn31    = Ynnt ? 3 : 1
    Unn31    = Unnt ? 3 : 1
    Vnn31    = Vnnt ? 3 : 1
    Ynn      = Yt&&nonenny ? 2 : Y
    Unn      = Ut&&nonennc ? 2 : U
    Vnn      = Vt&&nonennc ? 2 : V
    
    nnt      = Ynnt || Unnt || Vnnt
    mixed    = !nnt || !enable ? False : mixed
    
    ###############################################################################################################################
    ###############################################################################################################################
	# Shift Calculation
	
    yhshift  = yhrf>=2 ? 0.5 : 0       #              luma   horizontal shift introduced by eedi3_resize16_rpow2 (edge area resize)
    yvshift  = yvrf>=2 ? 0.5 : 0       #              luma     vertical shift introduced by eedi3_resize16_rpow2 (edge area resize)
    yhfix    = -yhshift                # value to fix luma   horizontal shift introduced by eedi3_resize16_rpow2 (edge area resize)
    yvfix    = -yvshift                # value to fix luma     vertical shift introduced by eedi3_resize16_rpow2 (edge area resize)
    
    chshift  = oCSP=="YV24" ? sCSP=="YV24" ?                   chrf>=2 ? 0.50         :  0
    \                                      : cplace=="MPEG1" ? chrf>=2 ? 0.50         :  0
    \                                                        : chrf>=2 ? 0.50-chrf/4. : -0.25
    \                       : sCSP=="YV24" ? cplace=="MPEG1" ? chrf>=2 ? 0.50         :  0
    \                                                        : chrf>=2 ? 0.75         :  0.25
    \                                      : cplace=="MPEG1" ? chrf>=2 ? 0.50         :  0
    \                                                        : chrf>=2 ? 0.75-chrf/4. :  0
	#                                                         (chrf/2-0.5)/2-(chrf/2-1)
	#                                                 chroma horizontal shift introduced by eedi3_resize16_rpow2 (edge area resize)
    cvshift  = cvrf>=2 ? 0.5 : 0       #              chroma   vertical shift introduced by eedi3_resize16_rpow2 (edge area resize)
    chfix    = -chshift                # value to fix chroma horizontal shift introduced by eedi3_resize16_rpow2 (edge area resize)
    cvfix    = -cvshift                # value to fix chroma   vertical shift introduced by eedi3_resize16_rpow2 (edge area resize)
    
    cphfixe  = oCSP=="YV24" ?                   0
    \                       : cplace=="MPEG1" ? 0
    \                                         : 0.25-0.25/crhratio
	# value to fix chroma horizontal shift introduced by Dither_resize16 after eedi3_resize16_rpow2 processing   (edge area resize)
    
    cphfix   = oCSP=="YV24" ? sCSP=="YV24" ?                   0
    \                                      : cplace=="MPEG1" ? 0
    \                                                        : 0.25
    \                       : sCSP=="YV24" ? cplace=="MPEG1" ? 0
    \                                                        : -0.5
    \                                      : cplace=="MPEG1" ? 0
    \                                                        : 0.25-0.25/chratio
	# value to fix chroma horizontal shift introduced by Dither_resize16 (flat area resize)
	# this fixing only take effects when Y/U/V is processed separately(as Y8) in flat area scaling (colorspace transferring)
	# Dither_resize16 accepts "cplace" and correctly processes chroma placement for YUV input
    
    ###############################################################################################################################
	###############################################################################################################################
    # Pre-Process
	
    input    = wpre || hpre ? lsb_in ? input.Dither_resize16(wpre?prew:sw, hpre?preh:sh, wpre?prel:0, hpre?pret:0,
    \                                                        wpre?prew:sw, hpre?preh:sh, kernel="point")
    \                                : input.PointResize(wpre?prew:sw, hpre?preh:sh, wpre?prel:0, hpre?pret:0, wpre?prew:sw, hpre?preh:sh)
    \                       : input
    input8   = lsb_in ? input.eedi3_resize16_Down8(tv_range, Yt, Ut, Vt, mixed ? -1 : dither) : input
    input16  = lsb_in ? input : input.eedi3_resize16_U16(tv_range, True, True, True)
    
    ###############################################################################################################################
	###############################################################################################################################
    # eedi3 upscale for edge area
	
    !(enable && nnt) ? NOP() : \
    yhct==chct && yvct==cvct && sCSP=="YV12" ? \
    Eval("""
        edgenn  = input8.eedi3_resize16_rpow2(yvct, yhct, 1, 1, Yt, Ut, Vt, nsize, nns, qual, etype, pscrn, threads, false, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
    	edgennY = sharp>0 ? edgenn.CSmod(chroma=False, ss_w=1.00, ss_h=1.00, preblur=-4, Smethod=1, kernel=6, strength=sharp, Soothe=-1)
        \                         .eedi3_resize16_U16(tv_range, Yt, Ut, Vt)
    	\                 : edgenn.eedi3_resize16_U16(tv_range, Yt, Ut, Vt)
    	edgennU = edgennY.UToY8()
    	edgennV = edgennY.VToY8()
    	edgennY = edgennY.ConvertToY8()
    """) : \
    Eval("""
        edgennY = !Ynnt ? NOP()
    	\               : sharp>0 ? input8.ConvertToY8().eedi3_resize16_rpow2(yvct, yhct, 1, 1, Yt, False, False,
        \                                                                        nsize, nns, qual, etype, pscrn, threads, false, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
        \                                 .CSmod(chroma=False, ss_w=1.00, ss_h=1.00, preblur=-4, Smethod=1, kernel=6, strength=sharp, Soothe=-1)
    	\                                 .eedi3_resize16_U16(tv_range, Yt, False, False)
        \                         : input8.ConvertToY8().eedi3_resize16_rpow2(yvct, yhct, 1, 1, Yt, False, False,
        \                                                                        nsize, nns, qual, etype, pscrn, threads, false, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
    	\                                 .eedi3_resize16_U16(tv_range, Yt, False, False)
    	edgennU = !Unnt ? NOP()
    	\               : input8.UToY8().eedi3_resize16_rpow2(cvct, chct, 1, 1, Ut, False, False,
        \                                                            nsize, nns, qual, etype, pscrn, threads, false, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
    	\                       .eedi3_resize16_U16(tv_range, Ut, False, False)
    	edgennV = !Vnnt ? NOP()
    	\               : input8.VToY8().eedi3_resize16_rpow2(cvct, chct, 1, 1, Vt, False, False,
        \                                                            nsize, nns, qual, etype, pscrn, threads, false, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
    	\                       .eedi3_resize16_U16(tv_range, Vt, False, False)
    """)
    
    ###############################################################################################################################
	###############################################################################################################################
    # edge area resize & fix center shift
	
	yrh      = yrhratio>ratiothr
	yrv      = yrvratio>ratiothr
	crh      = crhratio>ratiothr
	crv      = crvratio>ratiothr
	
    !(enable && nnt) ? NOP() : \
    Eval("""
        edgennY = !Ynnt ? NOP()
        \               : curve=="linear" ? edgennY
        \                                 : edgennY.Dither_y_gamma_to_linear(tv_range, tv_range, curve, u=1, v=1, gcor=gcor)
        edgeY   = !Ynnt ? input16.BlankClip(width=ow , height=oh *2, pixel_type="Y8", color_yuv=$008080)
    	\               : edgennY.""" + resste + """(ow , oh , src_left *yhrf+yhfix        , src_top *yvrf+yvfix,
        \                                            src_width *yhrf, src_height *yvrf, y=Y31, u=1  , v=1  ,
        \                                            kernelh=yrh?kernel_u:kernel_d, kernelv=yrv?kernel_u:kernel_d,
		\                                            fh=yrh?f_u:f_d, fv=yrv?f_u:f_d,
		\                                            invksh=yrh?invks_u:invks_d, invksv=yrv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
        edgeY   = !Ynnt ? edgeY
        \               : curve=="linear" ? edgeY
        \                                 : edgeY  .Dither_y_linear_to_gamma(tv_range, tv_range, curve, u=1, v=1, gcor=gcor)
        
    	edgeU   = !Unnt ? input16.BlankClip(width=owc, height=ohc*2, pixel_type="Y8", color_yuv=$008080)
    	\               : edgennU.""" + resste + """(owc, ohc, src_leftc*chrf+chfix+cphfixe, src_topc*cvrf+cvfix,
        \                                            src_widthc*chrf, src_heightc*cvrf, y=U31, u=1  , v=1  ,
        \                                            kernelh=crh?kernel_u:kernel_d, kernelv=crv?kernel_u:kernel_d,
		\                                            fh=crh?f_u:f_d, fv=crv?f_u:f_d,
		\                                            invksh=crh?invks_u:invks_d, invksv=crv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
		
    	edgeV   = !Vnnt ? input16.BlankClip(width=owc, height=ohc*2, pixel_type="Y8", color_yuv=$008080)
    	\               : edgennV.""" + resste + """(owc, ohc, src_leftc*chrf+chfix+cphfixe, src_topc*cvrf+cvfix,
        \                                            src_widthc*chrf, src_heightc*cvrf, y=V31, u=1  , v=1  ,
        \                                            kernelh=crh?kernel_u:kernel_d, kernelv=crv?kernel_u:kernel_d,
		\                                            fh=crh?f_u:f_d, fv=crv?f_u:f_d,
		\                                            invksh=crh?invks_u:invks_d, invksv=crv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
		
    	edge16  = IsY8 ? edgeY : YToUV(edgeU, edgeV, edgeY)
    """)
    
    ###############################################################################################################################
	###############################################################################################################################
    # flat area resize

	yh       = yhratio>ratiothr
	yv       = yvratio>ratiothr
	ch       = chratio>ratiothr
	cv       = cvratio>ratiothr
	
    !(enable && (mixed || !(Ynnt && Unnt && Vnnt))) ? NOP() : \
    yhratio==chratio && yvratio==cvratio && (!mixed || (Ynnt && Unnt && Vnnt)) ? \
    Eval("""
        flat16  = curve=="linear" ? input16
        \                         : input16.Dither_y_gamma_to_linear(tv_range, tv_range, curve, u=U21, v=V21, gcor=gcor)
        flat16  =                   flat16.      """ + resstf + """
		\                                           (ow , oh , src_left                    , src_top            ,
        \                                            src_width      , src_height      , y=Y32, u=U32, v=V32, cplace=cplace,
        \                                            kernelh=yh?kernel_u:kernel_d, kernelv=yv?kernel_u:kernel_d,
		\                                            fh=yh?f_u:f_d, fv=yv?f_u:f_d,
		\                                            invksh=yh?invks_u:invks_d, invksv=yv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
        flat16  = curve=="linear" ? flat16
        \                         : flat16 .Dither_y_linear_to_gamma(tv_range, tv_range, curve, u=U21, v=V21, gcor=gcor)
    """) : \
    Eval("""
        flatY   = curve=="linear"        ? input16.ConvertToY8() :
        \         (mixed || !Ynnt) && Yt ? input16.ConvertToY8().Dither_y_gamma_to_linear(tv_range, tv_range, curve, u=1  , v=1  , gcor=gcor)
        \                                : input16.ConvertToY8()
        flatY   = (mixed || !Ynnt) && Yt ? flatY          .""" + resstf + """
		\                                           (ow , oh , src_left                    , src_top            ,
        \                                            src_width      , src_height      , y=Y32, u=1  , v=1  ,
        \                                            kernelh=yh?kernel_u:kernel_d, kernelv=yv?kernel_u:kernel_d,
		\                                            fh=yh?f_u:f_d, fv=yv?f_u:f_d,
		\                                            invksh=yh?invks_u:invks_d, invksv=yv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
        \                                : input16.BlankClip(width=ow , height=oh *2, pixel_type="Y8", color_yuv=$008080)
        flatY   = curve=="linear"        ? flatY                 :
        \         (mixed || !Ynnt) && Yt ? flatY                .Dither_y_linear_to_gamma(tv_range, tv_range, curve, u=1  , v=1  , gcor=gcor)
        \                                : flatY
        
        flatU   = (mixed || !Unnt) && Ut ? input16.UToY8().""" + resstf + """
		\                                           (owc, ohc, src_leftc           +cphfix , src_topc           ,
        \                                            src_widthc     , src_heightc     , y=U32, u=1  , v=1  ,
        \                                            kernelh=ch?kernel_u:kernel_d, kernelv=cv?kernel_u:kernel_d,
		\                                            fh=ch?f_u:f_d, fv=cv?f_u:f_d,
		\                                            invksh=ch?invks_u:invks_d, invksv=cv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
        \                                : input16.BlankClip(width=owc, height=ohc*2, pixel_type="Y8", color_yuv=$008080)
		
        flatV   = (mixed || !Vnnt) && Vt ? input16.VToY8().""" + resstf + """
		\                                           (owc, ohc, src_leftc           +cphfix , src_topc           ,
        \                                            src_widthc     , src_heightc     , y=V32, u=1  , v=1  ,
        \                                            kernelh=ch?kernel_u:kernel_d, kernelv=cv?kernel_u:kernel_d,
		\                                            fh=ch?f_u:f_d, fv=cv?f_u:f_d,
		\                                            invksh=ch?invks_u:invks_d, invksv=cv?invks_u:invks_d,
		\                                            taps=taps, a1=a1, a2=a2, a3=a3, invkstaps=invkstaps
		\                                           )
        \                                : input16.BlankClip(width=owc, height=ohc*2, pixel_type="Y8", color_yuv=$008080)
		
    	flat16  = IsY8 ? flatY : YToUV(flatU, flatV, flatY)
    """)
    
    ###############################################################################################################################
	###############################################################################################################################
    # Threshold Merging & Output
	
    enable ? \
    Eval("""
        merge16  = !nnt ? flat16
        \               : mixed ? Dither_limit_dif16(flat16, edge16, thr=thr, elast=elast, y=Ynn, u=Unn, v=Vnn)
        \                       : Ynnt==Unnt && Unnt==Vnnt || IsY8 ? edge16
        \                                                          : mt_lutxy(edge16, flat16, Y=Yt?Ynnt?2:4:1, U=Ut?Unnt?2:4:1, V=Vt?Vnnt?2:4:1)
        merge16  = IsY8 ? output=="Y8" ? merge16.ConvertToY8() : Eval("merge16.ConvertTo"+oCSP).Dither_lut16(Y=2, U=-32768, V=-32768) : merge16
        
        final    = IsRGB ? merge16.Dither_convert_yuv_to_rgb(matrix=matrix, tv_range=tv_range, lsb_in=True, mode=dither, output=output)
        \                : lsb ? merge16
        \                      : merge16.eedi3_resize16_Down8(tv_range, True, !IsY8, !IsY8, dither)
    """) : \
    Eval("""
        shift16  = input16.Dither_resize16(ow, oh, src_left, src_top, src_width, src_height, kernel="point", y=Y, u=U, v=V)
        shift16  = IsY8 ? output=="Y8" ? shift16.ConvertToY8() : Eval("shift16.ConvertTo"+oCSP).Dither_lut16(Y=2, U=-32768, V=-32768) : shift16
        
        final    = IsRGB ? shift16.Dither_convert_yuv_to_rgb(matrix=matrix, tv_range=tv_range, lsb_in=True, mode=dither, output=output)
        \                : lsb ? shift16
        \                      : shift16.eedi3_resize16_Down8(tv_range, True, !IsY8, !IsY8, dither)
    """)
    
    
    return final
}


Function eedi3_resize16_rpow2(clip input, int "vct", int "hct", int "vfield", int "hfield", bool "Y", bool "U", bool "V",
\                              int "nsize", int "nns", int "qual", int "etype", int "pscrn", int "threads", bool "honly", bool "nnsclip", float "alpha", float "beta", float "gamma", int "nrad", int "mdis", bool "hp", bool "ucubic", bool "cost3", int "vcheck", float "vthresh0", float "vthresh1", float "vthresh2", int "nnrep")
{
    vct      = Default(vct,      1      )
    hct      = Default(hct,      1      )
    vfield   = Default(vfield,   1      )
    hfield   = Default(hfield,   1      )
    Y        = Default(Y,        True   )
    U        = Default(U,        False  )
    V        = Default(V,        False  )
    honly    = Default(honly,    False  )
    nnsclip  = Default(nnsclip,  false  )
    nnrep    = Default(nnrep,    0      )
    
    
    input
    
    hct >= 1 ? \
    Eval("""
        (honly) ? last
        \       : Eval(" try { fturnright(chroma=U||V, mt=threads!=1) } catch(error_msg) { TurnRight() } ")
        nnec = (nnrep > 0 || nnsclip) ? sh_Padding(2,2,2,2).nnedi3(hfield, True, Y, U, V, nsize, nns, qual, etype, pscrn, threads).crop(2,4,-2,-4,true) : nop()
        eedi3(hfield, True, Y, U, V, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnsclip ? nnec : undefined, threads)
        nnrep > 1 ? slimit_dif(last,nnec,thr=4) : nnrep > 1 ? Repair(nnec,9) : last
        
    	hct    = hct - 1
        honly  = hct >= 1
        hfield = 0
        
    	(honly) ? last
        \       : Eval(" try { fturnleft (chroma=U||V, mt=threads!=1) } catch(error_msg) { TurnLeft () } ")
    """) : NOP()
    
    vct >= 1 && !honly ? \
    Eval("""
        nnec = (nnrep > 0 || nnsclip) ? sh_Padding(2,2,2,2).nnedi3(vfield, True, Y, U, V, nsize, nns, qual, etype, pscrn, threads).crop(2,4,-2,-4,true) : nop()
        eedi3(vfield, True, Y, U, V, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnsclip ? nnec : undefined, threads)
        nnrep > 1 ? slimit_dif(last,nnec,thr=4) : nnrep > 1 ? Repair(nnec,9) : last
        
    	vct    = vct - 1
        vfield = 0
    """) : NOP()
    
    
    return Y||U||V ? vct <= 0 && hct <= 0 ? last
    \                                     : last.eedi3_resize16_rpow2(vct, hct, vfield, hfield, Y, U, V, nsize, nns, qual, etype, pscrn, threads, honly, nnsclip, alpha, beta, gamma, nrad, mdis, hp, ucubic, cost3, vcheck, vthresh0, vthresh1, vthresh2, nnrep)
    \              : input
}


Function eedi3_resize16_GetCSP(clip c)
{
    return c.IsPlanar ? c.IsYV12 ? "YV12" :
    \                   c.IsYV16 ? "YV16" :
    \                   c.IsYV24 ? "YV24" : c.GetCSP_Y8_YV411fed :
    \      c.IsYUY2   ? "YUY2"   :
    \      c.IsRGB32  ? "RGB32"  :
    \      c.IsRGB24  ? "RGB24"  : "Unknown"
    
    
    Function GetCSP_Y8_YV411fed(clip c) {
        try {
            c.UtoY
            csp = "YV411"
        } catch ( error_msg ) {
        csp = "Y8"
        }
        return csp
    }
}

/*
Function eedi3_resize16_RemoveGrain(clip input, int "mode", int "modeU", int "modeV")
{
    mode     = Default(mode,     1      )
    modeU    = Default(modeU,    mode   )
    modeV    = Default(modeV,    modeU  )
    
    
    iCSP     = input.eedi3_resize16_GetCSP()
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
    \             : isY8 ? input_m4                      .RemoveGrain(mode , -1, -1)
    \                              .Crop(0, 0, sw, sh)
    \                    : YToUV(input_m4.UToY8()        .RemoveGrain(modeU, -1, -1),
    \                            input_m4.VToY8()        .RemoveGrain(modeV, -1, -1),
    \                            input_m4.ConvertToY8()  .RemoveGrain(mode , -1, -1))
    \                     .Crop(0, 0, sw, sh)
}
*/

Function eedi3_resize16_U16(clip input, bool "tv_range", bool "Y", bool "U", bool "V", int "dither", int "interp", bool "HQ")
{ 
    tv_range = Default(tv_range, True   ) # define if input clip is of tv range(limited range)
    interp   = Default(interp,   0      ) # use interp or not for SmoothCurve/SmoothCurve16
    HQ       = Default(HQ,       False  ) # enable high quality interpolation (slower)
    dither   = Default(dither,   -1     ) # -1 for no dither, 0 for ordered-dither, 1-100 for noise strength
    Y        = Default(Y,        True   )
    U        = Default(U,        True   )
    V        = Default(V,        True   )
    
    
    Assert(dither>=-1 && dither<=100 , """eedi3_resize16_U16: "dither" ranges from -1 to 100!""")
    
    oCceil   = (255-128) / (255.5-128) * (65535.5-32768) + 32768
    
    Yexpr    = "0-0  ;                  255-65535             ;65535-65535          "
    Cexpr    = "0-0.5;0.5-0.5;128-32768;255-"+String(oCceil)+";65535-"+String(oCceil)
    DfExpr   = "0-0;65535-65535"
    Yexpr    = Y ? Yexpr : DfExpr
    Uexpr    = U ? Cexpr : DfExpr
    Vexpr    = V ? Cexpr : DfExpr
      
    up       =  tv_range ? input.Dither_convert_8_to_16()
    \                    : Y||U||V ? StackVertical(input.Dither_gen_null_lsb(), input)
	\                               .SmoothCurve16(Ycurve=Yexpr, Ucurve=Uexpr, Vcurve=Vexpr, mode=0, interp=interp, HQ=HQ,
    \                                              dither=dither, limiter=False, TVrange=0)
    \                              : StackVertical(input.Dither_gen_null_lsb(), input)
    
    
    return up
}


Function eedi3_resize16_Down8(clip input, bool "tv_range", bool "Y", bool "U", bool "V", int "dither", int "interp", bool "HQ")
{
    tv_range = Default(tv_range, True   ) # define if input clip is of tv range(limited range)
    interp   = Default(interp,   0      ) # use interp or not for SmoothCurve/SmoothCurve16
    HQ       = Default(HQ,       False  ) # enable high quality interpolation (slower)
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50) # dither mode
    Y        = Default(Y,        True   )
    U        = Default(U,        True   )
    V        = Default(V,        True   )
    
    
    Assert(dither>=-1 && dither<=100 , """eedi3_resize16_Down8: "dither" ranges from -1 to 100!""")
    
    iCceil   = (255-128) / (255.5-128) * (65535.5-32768) + 32768
    
    Yexpr    = "0-0;                                           65535-255"
    Cexpr    = "0-0.5;0.5-0.5;32768-128;"+String(iCceil)+"-255;65535-255"
    DfExpr   = "0-0;65535-65535"
    Yexpr    = Y ? Yexpr : DfExpr
    Uexpr    = U ? Cexpr : DfExpr
    Vexpr    = V ? Cexpr : DfExpr
    
    sDown    = tv_range ? NOP()
    \                   : input.SmoothCurve16(Ycurve=Yexpr, Ucurve=Uexpr, Vcurve=Vexpr, mode=0, interp=interp, HQ=HQ,
    \                                         dither=dither, limiter=False, TVrange=0)
    
    down     = tv_range ? input.DitherPost(mode=dither, y=Y?3:1, u=U?3:1, v=V?3:1)
    \                   : Y||U||V ? sDown.Dither_get_lsb()
    \                             : input.Dither_get_msb()
    
    
    return down
}