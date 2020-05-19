#################################################################################################
###### GrainStabilizeMC v1.0     ######      by mawen1250      ######      2014.03.22      ######
######                                       2020.05.18 mod                                ######
#################################################################################################
###### Requirements: masktools v2.0a48, mvtools v2.6.0.5, dither v1.25.1,                  ######
######               RgTools v0.92.1, MedianBlur2 v0.94, SmoothAdjust v3.00                ######
#################################################################################################


Function GSMC(clip input, clip "p", clip "Lmaskl", string "Preset", int "nrmode", int "radius", int "adapt", int "rep",
\             int "Y", int "U", int "V", bool "lsb_in", bool "lsb", bool "lsb_out", bool "tv_range", int "dither",
\             bool "chromamv", int "blksize", int "overlap", int "thSAD", int "thSADC", int "thSCD1", int "thSCD2", int "limit", int "limitc",
\             bool "truemotion", bool "MVglobal", int "pel", int "pelsearch", int "search", int "searchparam", int "MVsharp", int "DCT")
{
sisavs26 = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sischbd = sisphbd ? input.BitsPerComponent() > 8 : false
    ###############################################################################################################################
    ###############################################################################################################################
    # Parameters for input/output
    
    Y        = Default(Y,      3       )
    U        = Default(U,      2       )
    V        = Default(V,      2       )
    
    lsb_in   = Default(lsb_in, False   )    # input      clip is 16-bit stacked or not
    lsb      = Default(lsb,    False   )    # processing precision is 16-bit or not
    lsb_out  = Default(lsb_out,lsb     )    # output     clip is 16-bit stacked or not
	Assert(!((lsb || lsb_in || lsb_out) && sischbd), """GrainStabilizeMC: you can't use lsb hacks with HBD input""")
    tv_range = Default(tv_range,True   )    # input  clip is TV-range or PC-range
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50)    # dither mode for 16-bit to 8-bit conversion
    
    ###############################################################################################################################
    
    Y        = max(min(Y, 3), 1)
    U        = max(min(U, 3), 1)
    V        = max(min(V, 3), 1)
    Yt       = Y == 3
    Ut       = U == 3
    Vt       = V == 3
    Y31      = Yt ? 3 : 1
    U31      = Ut ? 3 : 1
    V31      = Vt ? 3 : 1
    Y32      = Yt ? 3 : 2
    U32      = Ut ? 3 : 2
    V32      = Vt ? 3 : 2
    Y321     = Y <= 1 ? 1 : 3
    U321     = U <= 1 ? 1 : 3
    V321     = V <= 1 ? 1 : 3
    Y421     = Y == 3 ? 4 : Y
    U421     = U == 3 ? 4 : U
    V421     = V == 3 ? 4 : V
    
    ###############################################################################################################################
    ###############################################################################################################################
    
    sw       = input.Width ()
    sh       = input.Height()
    sh       = lsb_in ? sh/2 : sh
    HD       = (sw > 1024 || sh > 576) ? True : False
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Parameters for noise dumper
    
    nrmode   = Default(nrmode, HD?2:1  )
    # Mode to get grain/noise from input clip:
    # -1: 3x3 Min Blur, -2: 5x5 Min Blur, -3: 7x7 Min Blur,
    #  0: 3x3 Average Blur,
    #  1: 3x3 SBR,       2: 5x5 SBR,       3: 7x7 SBR.
    # or define your own denoised clip "p".
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Parameters for MC grain stabilize
    
    radius   = Default(radius, 1       )
    # Temporal radius of MDegrain for grain stabilize.(1-3)
    
    Preset   = Default(Preset, "Faster")
    
    pnum     = preset == "Very Fast" ?  0
    \        : preset == "Faster"    ?  1
    \        : preset == "Fast"      ?  2
    \        : preset == "Medium"    ?  3
    \        : preset == "Slow"      ?  4
    \        : preset == "Slower"    ?  5
    \        : preset == "Very Slow" ?  6
    \        :                          7
    Assert( pnum<=6, """GrainStabilizeMC: Unknown Preset!
    Allowed Preset: "Very Fast","Faster","Fast","Medium","Slow","Slower","Very Slow".""" )
    
    # Preset groups:                                 Very Fast     Fast          Slow          Very Slow
    # Preset groups:                                        Faster        Medium        Slower
    
    bs          = HD ? 16 :  8
    bs2         = HD ? 32 : 16
    chromamv    = Default(chromamv,    Ut || Vt    )
    blksize     = Default(blksize,     Select(pnum,  bs2,   bs2,   bs2,   bs,    bs,    bs,    bs    ))
    ol          = blksize/2
    ol2         = blksize/4
    overlap     = Default(overlap,     Select(pnum,  ol2,   ol2,   ol2,   ol,    ol,    ol,    ol    ))
    thSAD       = Default(thSAD,       300         )
    thSADC      = Default(thSADC,      thSAD/2     )
    thSCD1      = Default(thSCD1,      300         )
    thSCD2      = Default(thSCD2,      100         )
    truemotion  = Default(truemotion,  False       )
    MVglobal    = Default(MVglobal,    False       )
    pel         = Default(pel,         Select(pnum,  1,     1,     HD?1:2,HD?1:2,2,     2,     2     ))
    pelsearch   = Default(pelsearch,   Select(pnum,  1,     2,     2,     2,     2,     2,     2     ))
    search      = Default(search,      Select(pnum,  2,     4,     HD?5:2,HD?3:4,4,     5,     3     ))
    searchparam = Default(searchparam, Select(pnum,  1,     2,     2,     2,     2,     2,     2     ))
    MVsharp     = Default(MVsharp,     2           )
    DCT         = Default(DCT,         0           )
    badrange    = search==3 || search==6 || search==7 ? -24 : 24
    
    ###############################################################################################################################
    
    Umv      = chromamv ? True : Ut
    Vmv      = chromamv ? True : Vt
    plane    = !Yt ? !Ut ? 2 : !Vt ? 1 : 3 : !Ut&&!Vt ? 0 : 4
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Parameters for post-processing
    
    adapt    = Default(adapt,  -1      )
    # Threshold for luma-adaptative mask
    # -1: off,  0: source,  255: invert.
    # or define your own luma mask clip "Lmaskl".
    
    rep      = Default(rep,    13      )
    # Mode of repair to avoid artifacts, set 0 to turn off this operation.
    
    ###############################################################################################################################
    ###############################################################################################################################
    
    Assert( nrmode>=-3 && nrmode<=  3, "GrainStabilizeMC: invalid value for nrmode(-3~3)!"  )
    Assert( radius>= 1 && radius<=  3, "GrainStabilizeMC: invalid value for radius(1~3)!"   )
    Assert( adapt >=-1 && adapt <=255, "GrainStabilizeMC: invalid value for adapt(-1~255)!" )
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Pre-Process: Bit Depth Conversion
    
    input8   = !lsb_in ? input : input.GSMC_Down8(tv_range, True, True, True, lsb?-1:dither)
    input16  =  lsb_in ? input : input.GSMC_U16  (tv_range, True, True, True)
    
    plsb_in  = Defined(p) ? input.Height() == p.Height() ? lsb_in : !lsb_in : lsb_in
    plsb     = (lsb_in || plsb_in) && lsb    # Whether we need 16bit precision for Spatial Noise Dumping. (MVTools2 only support 8bit input)
    iresc    = Defined(p) ? plsb_in == lsb_in ? input.Height() == p.Height() ? True : False
    \                                         : lsb_in == False ? input.Height()*2 == p.Height() ? True : False
    \                                                           : input.Height() == p.Height()*2 ? True : False
    \                     : True
    Assert( iresc == True, """GrainStabilizeMC: clip "input" and clip "p" resolution not match!
    (GSMC have already considered different condition of the lsb)""" )
    
    p8       = Defined(p) ? !plsb_in ? p : p.GSMC_Down8(tv_range, True, Umv, Vmv, -1) : NOP()
    p16      = Defined(p) ?  plsb_in ? p : p.GSMC_U16  (tv_range, True, Umv, Vmv)     : NOP()
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Kernel: Spatial Noise Dumping
    
    pre_nr8  = !plsb ? Defined(p) ? p8
    \                             : nrmode <  0 ? sischbd ? input8.MinBlur(-nrmode, Y=Y32, U=U32, V=V32) : input8 .GSMC_MinBlur(-nrmode, Y=Y32, U=U32, V=V32, lsb_in=False, lsb=False, tv_range=tv_range, dither=dither)
    \                             : nrmode == 0 ? input8 .RemoveGrain(Yt?20:0, Ut?20:0, Vt?20:0)
    \                                           : sischbd ? input8.sbr( r=nrmode, Y=Y32, U=U32, V=V32) : input8 .GSMC_sbr    ( nrmode, Y=Y32, U=U32, V=V32, lsb_in=False, lsb=False, tv_range=tv_range, dither=dither)
    \                : NOP()
    dif_nr8  = !plsb ? mt_makediff(input8, pre_nr8, Y=Y31, U=U31, V=V31) : NOP()
    
    pre_nr16 =  plsb ? Defined(p) ? p16
    \                             : nrmode <  0 ? input16.GSMC_MinBlur(-nrmode, Y=Y32, U=U32, V=V32, lsb_in=True,  lsb=True,  tv_range=tv_range, dither=dither)
    \                             : nrmode == 0 ? input16.Dither_removegrain16(Yt?20:0, Ut?20:0, Vt?20:0)
    \                                           : input16.GSMC_sbr    ( nrmode, Y=Y32, U=U32, V=V32, lsb_in=True,  lsb=True,  tv_range=tv_range, dither=dither) 
    \                : pre_nr8.GSMC_U16  (tv_range, True, Umv, Vmv)
    dif_nr16 =  plsb ? Dither_sub16(input16, pre_nr16, Y=Y31, U=U31, V=V31, dif=True)
    \                : NOP()
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Kernel: MC Grain Stabilize
    
    pre_nr   = Defined(p) ? p8 : plsb ? pre_nr16.GSMC_Down8(tv_range, True, Umv, Vmv, -1) : pre_nr8
    dif_nr   = plsb ? dif_nr16.GSMC_Down8(True    , True, Umv, Vmv, -1) : dif_nr8
    
    psuper   = pre_nr.MSuper(pel=pel, levels=0, sharp=MVsharp, chroma=chromamv)
    difsuper = dif_nr.MSuper(pel=pel, levels=1, sharp=MVsharp, chroma=Ut || Vt)
    
    fv3      = radius>=3 ? psuper.MAnalyse(isb=False, delta=3, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    fv2      = radius>=2 ? psuper.MAnalyse(isb=False, delta=2, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    fv1      = radius>=1 ? psuper.MAnalyse(isb=False, delta=1, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    bv1      = radius>=1 ? psuper.MAnalyse(isb=True,  delta=1, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    bv2      = radius>=2 ? psuper.MAnalyse(isb=True,  delta=2, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    bv3      = radius>=3 ? psuper.MAnalyse(isb=True,  delta=3, truemotion=truemotion, blksize=blksize, overlap=overlap, pelsearch=pelsearch, search=search, searchparam=searchparam, DCT=DCT, global=MVglobal, chroma=chromamv, badrange=badrange) : NOP()
    
    dif_sb   = radius==1 ? dif_nr.MDegrain1(difsuper, bv1, fv1                    , thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, lsb=lsb)
    \        : radius==2 ? dif_nr.MDegrain2(difsuper, bv1, fv1, bv2, fv2          , thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, lsb=lsb)
    \        :             dif_nr.MDegrain3(difsuper, bv1, fv1, bv2, fv2, bv3, fv3, thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc, plane=plane, lsb=lsb)
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Post-Process: Luma-Adaptive Mask Merging & Repairing
    
    adapt    = Defined(Lmaskl) ? 0 : adapt
    Lmaskl   = Defined(Lmaskl) ? Lmaskl
    \        : adapt == -1     ? NOP()
    \        : adapt == 0      ? input8.RemoveGrain(19, -1)
    \        : adapt == 255    ? input8.mt_invert(U=1, V=1).RemoveGrain(19, -1)
    \        :                   sisavs26 ? input8.mt_lut("x "+string(adapt)+" scalef - abs range_max * "+string(adapt)+" scalef range_half - abs range_half + /", clamp_float=true, use_expr=2, U=1, V=1).RemoveGrain(19, -1) : input8.mt_lut("x "+string(adapt)+" - abs 255 * "+string(adapt)+" 128 - abs 128 + /", U=1, V=1).RemoveGrain(19, -1)
    Lmask    = adapt == -1     ? NOP() : !sischbd && (Ut || Vt)  ? Lmaskl.GSMC_YtoYUV() : Lmaskl
    
    stable8  = !lsb ? mt_adddiff(pre_nr8, dif_sb, Y=Y31, U=U31, V=V31) : NOP()
    stable8  = !lsb ? rep   ==  0 ? stable8  : stable8.Repair(input8, Yt?rep:-1, Ut?rep:-1, Vt?rep:-1) : NOP()
    mL8      = !lsb ? adapt == -1 ? mt_lutxy(input8, stable8, Y=Y421, U=U421, V=V421)
    \                             : mt_merge(input8, stable8, Lmask, luma=False, Y=Y, U=U, V=V) : NOP()
    
    stable16 =  lsb ? Dither_add16(pre_nr16, dif_sb, Y=Y31, U=U31, V=V31, dif=True) : NOP()
    stable16 =  lsb ? rep   ==  0 ? stable16 : stable16.Dither_repair16(input16, Yt?rep:-1, Ut?rep:-1, Vt?rep:-1) : NOP()
    mL16     =  lsb ? adapt == -1 ? mt_lutxy(input16, stable16, Y=Y421, U=U421, V=V421)
    \                             : Dither_merge16_8(input16, stable16, Lmask, luma=False, Y=Y, U=U, V=V) : NOP()
    
    ###############################################################################################################################
    ###############################################################################################################################
    # Output
    
    end      = lsb_out ? lsb ? mL16
    \                        : mL8. GSMC_U16  (tv_range, True, True, True)
    \                  : lsb ? mL16.GSMC_Down8(tv_range, True, True, True, dither)
    \                        : mL8
    
    return end
}


Function GSMC_YtoYUV(clip inputl, string "colorspace")
{
    sw          = inputl.Width()
    sh          = inputl.Height()
    wmod4       = sw/4*4 == sw ? True : False
    hmod4       = sh/4*4 == sh ? True : False
   
    icolorspace = inputl.YtoYUV_GetCSP()
    ocolorspace = Defined(colorspace) ? colorspace : icolorspace
    
    try {
        inputp = inputl.ConvertToY8()
        inputc = ocolorspace == "YV24" ? inputp
        \      : ocolorspace == "YV16" ? inputp.BilinearResize(sw/2, sh  , -0.50)
        \      :                         inputp.BilinearResize(sw/2, sh/2, -0.50)
        
        output = YtoUV(inputc, inputc, inputp)
    } catch (error_msg) {
        inputp = wmod4&&hmod4 ? inputl : inputl.PointResize(wmod4?sw:sw+2, hmod4?sh:sh+2, 0, 0, wmod4?sw:sw+2, hmod4?sh:sh+2)
        inputc = inputp.BilinearResize(wmod4?sw/2:sw/2+1, hmod4?sh/2:sh/2+1, -0.50)
        
        output = YtoUV(inputc, inputc, inputp)
        output = wmod4&&hmod4 ? output : output.Crop(0, 0, wmod4?0:-2, hmod4?0:-2)
    }
    
    return output
    
    Function YtoYUV_GetCSP(clip c)
    {
        return c.IsPlanar ? c.IsYV12 ? "YV12" :
        \                   c.IsYV16 ? "YV16" :
        \                   c.IsYV24 ? "YV24" : c.GetCSP_Y8_YV411() :
        \      c.IsYUY2   ? "YUY2"   :
        \      c.IsRGB32  ? "RGB32"  :
        \      c.IsRGB24  ? "RGB24"  : "Unknown"
        
        Function GetCSP_Y8_YV411(clip c) {
            try {
                c.UtoY
                csp = "YV411"
            } catch (error_msg) {
                csp = "Y8"
            }
            return csp
        }
    }
}


Function GSMC_sbr(clip clp, int "r", int "Y", int "U", int "V", bool "lsb_in", bool "lsb", bool "tv_range", int "dither")
{
    r        = Default(r,    1)
    Y        = Default(Y,    3)
    U        = Default(U,    3)
    V        = Default(V,    3)
    
    Yt       = Y == 3
    Ut       = U == 3
    Vt       = V == 3
    Y31      = Yt ? 3 : 1
    U31      = Ut ? 3 : 1
    V31      = Vt ? 3 : 1
    Y2       = (Y==2) ? 1  :  Y
    Y11      = (Y==3) ? 11 : -1
    Y20      = (Y==3) ? 20 : -1
    U2       = (U==2) ? 1  :  U
    U11      = (U==3) ? 11 : -1
    U20      = (U==3) ? 20 : -1
    V2       = (V==2) ? 1  :  V
    V11      = (V==3) ? 11 : -1
    V20      = (V==3) ? 20 : -1
    
    lsb_in   = Default(lsb_in,   False )
    lsb      = Default(lsb,      False )
    tv_range = Default(tv_range, True  )
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50)
    
    clp8     = lsb_in ? clp.GSMC_Down8(tv_range, True, True, True, dither) : clp
    clp16    = lsb_in ? clp                                                : clp.GSMC_U16  (tv_range, True, True, True)
    
    RG11     = (r<=1) ? lsb ? clp16.Dither_removegrain16(Y11, U11, V11)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11)
    \        : (r==2) ? lsb ? clp16.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20)
    \        :          lsb ? clp16.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20).Dither_removegrain16(Y20, U20, V20)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20).         RemoveGrain(Y20, U20, V20)
    
    RG11D    = lsb ? Dither_sub16(clp16, RG11, y=Y31, u=U31, v=V31, dif=True)
    \              : mt_makediff (clp8 , RG11, Y=Y31, U=U31, V=V31)
    
    RG11DS   = (r<=1) ? lsb ? RG11D.Dither_removegrain16(Y11, U11, V11)
    \                       : RG11D.         RemoveGrain(Y11, U11, V11)
    \        : (r==2) ? lsb ? RG11D.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20)
    \                       : RG11D.         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20)
    \        :          lsb ? RG11D.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20).Dither_removegrain16(Y20, U20, V20)
    \                       : RG11D.         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20).         RemoveGrain(Y20, U20, V20)
    
    lsb ? \
    Eval("""
        abRG11D  = RG11D.Dither_lut16("x 32768 - abs", y=Y31, u=U31, v=V31)
        Ddiff    = Dither_sub16(RG11D, RG11DS, y=Y31, u=U31, v=V31, dif=True)
        abDdiff  = Ddiff.Dither_lut16("x 32768 - abs", y=Y31, u=U31, v=V31)
        abDDD    = Dither_sub16(abDdiff, abRG11D, y=Y31, u=U31, v=V31, dif=True)
        
        Dmask1   = abDDD.Dither_get_msb().mt_lut("x 128 < 255 0 ?", Y=Y31, U=U31, V=V31)
        Ddiffg   = Ddiff.Dither_lut16("x 32768 == x  x 32768 < 0 65535 ? ?", y=Y31, u=U31, v=V31).Dither_get_msb()
        RG11Dg   = RG11D.Dither_lut16("x 32768 == x  x 32768 < 0 65535 ? ?", y=Y31, u=U31, v=V31).Dither_get_msb()
        Dmask2   = mt_lutxy(Ddiffg, RG11Dg, "x 128 - y 128 - * 0 < 0 255 ?", Y=Y31, U=U31, V=V31)
        
        DD1      = Dither_merge16_8(RG11D, Ddiff, Dmask1, luma=False, y=Y31, u=U31, v=V31)
        DD       = Dither_merge16_8(DD1.GSMC_gen_null_diff(True), DD1, Dmask2, luma=False, y=Y31, u=U31, v=V31)
    """) : \
    Eval("""
        DD       = mt_lutxy(RG11D, RG11DS, "x y - x 128 - * 0 < 128 x y - abs x 128 - abs < x y - 128 + x ? ?", Y=Y31, U=U31, V=V31)
    """)
    
    return lsb ? clp16.Dither_sub16(DD, y=Y, u=U, v=V, dif=True)
    \          : clp8 .mt_makediff (DD, Y=Y, U=U, V=V)
}


Function GSMC_MinBlur(clip clp, int "r", int "Y", int "U", int "V", bool "lsb_in", bool "lsb", bool "tv_range", int "dither")
{
    r        = Default(r,    1)
    Y        = Default(Y,    3)
    U        = Default(U,    3)
    V        = Default(V,    3)
    
    Y2       = (Y==2) ? 1  :  Y
    Y4       = (Y==3) ? 4  : -1
    Y11      = (Y==3) ? 11 : -1
    Y20      = (Y==3) ? 20 : -1
    Ym2      = (Y==3) ? 2  : -256
    Ym3      = (Y==3) ? 3  : -256
    U2       = (U==2) ? 1  :  U
    U4       = (U==3) ? 4  : -1
    U11      = (U==3) ? 11 : -1
    U20      = (U==3) ? 20 : -1
    Um2      = (U==3) ? 2  : -256
    Um3      = (U==3) ? 3  : -256
    V2       = (V==2) ? 1  :  V
    V4       = (V==3) ? 4  : -1
    V11      = (V==3) ? 11 : -1
    V20      = (V==3) ? 20 : -1
    Vm2      = (V==3) ? 2  : -256
    Vm3      = (V==3) ? 3  : -256
    
    lsb_in   = Default(lsb_in,   False )
    lsb      = Default(lsb,      False )
    tv_range = Default(tv_range, True  )
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50)
    
    clp8     = lsb_in ? clp.GSMC_Down8(tv_range, True, True, True, dither) : clp
    clp16    = lsb_in ? clp                                                : clp.GSMC_U16  (tv_range, True, True, True)
    
    RG11     = (r<=1) ? lsb ? clp16.Dither_removegrain16(Y11, U11, V11)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11)
    \        : (r==2) ? lsb ? clp16.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20)
    \        :          lsb ? clp16.Dither_removegrain16(Y11, U11, V11).Dither_removegrain16(Y20, U20, V20).Dither_removegrain16(Y20, U20, V20)
    \                       : clp8 .         RemoveGrain(Y11, U11, V11).         RemoveGrain(Y20, U20, V20).         RemoveGrain(Y20, U20, V20)
    
    RG4      = (r<=1) ? lsb_in&&lsb ? clp16.Dither_removegrain16(Y4, U4, V4)
    \                               : clp8 .RemoveGrain(Y4, U4, V4)
    \        : (r==2) ? lsb_in&&lsb ? clp16.Dither_median16(2, 2, 0, y=Y2, u=U2, v=V2)
    \                               : clp8 .MedianBlur(Ym2, Um2, Vm2)
    \        :          lsb_in&&lsb ? clp16.Dither_median16(3, 3, 0, y=Y2, u=U2, v=V2)
    \                               : clp8 .MedianBlur(Ym3, Um3, Vm3)
    RG4      = !lsb_in&&lsb ? RG4  .GSMC_U16  (tv_range, Y==3, U==3, V==3) : RG4
    
    RG11D    = lsb ? NOP() : mt_makediff(clp8,  RG11, Y=Y2, U=U2, V=V2)
    RG4D     = lsb ? NOP() : mt_makediff(clp8,  RG4,  Y=Y2, U=U2, V=V2)
             
    DD       = lsb ? NOP() : mt_lutxy(RG11D, RG4D, "x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?", Y=Y2, U=U2, V=V2)
    end      = lsb ? GSMC_min_dif16(RG11, RG4, clp16, Y=Y, U=U, V=V)
    \              : clp8.mt_makediff(DD, Y=Y, U=U, V=V)
    
    return end
}


Function GSMC_min_dif16(clip src1, clip src2, clip ref, int "Y", int "U", int "V")
{
    Y          = Default(Y,        3)
    U          = Default(U,        3)
    V          = Default(V,        3)
    
    sh         = ref.Height()/2
    
    maxdif     = Dither_max_dif16(src1, src2, ref, y=Y==3?3:1, u=U==3?3:1, v=V==3?3:1)
    bin_stack  = mt_lutxy(src1, maxdif, "x y == 255 0 ?", Y=Y==3?3:1, U=U==3?3:1, V=V==3?3:1)
    bin_msb    = bin_stack.Crop(0, 0, 0, sh)
    bin_lsb    = bin_stack.Crop(0, sh, 0, 0)
    bin        = mt_logic(bin_msb, bin_lsb, "min", Y=Y==3?3:1, U=U==3?3:1, V=V==3?3:1)
    
    return Dither_merge16_8(src1, src2, bin, luma=False, y=Y, u=U, v=V)
}


Function GSMC_gen_null_diff(clip input, bool "lsb_in", bool "lsb")
{
    lsb_in     = Default(lsb_in, True  )
    lsb        = Default(lsb,    lsb_in)
    
    sh         = lsb_in ? input.Height()/2 : input.Height()
    output     = input.BlankClip(height=sh, color_yuv=$808080)
    output     = lsb    ? StackVertical(output, input.BlankClip(height=sh, color_yuv=$000000)) : output
    
    return output
}


Function GSMC_U16(clip input, bool "tv_range", bool "Y", bool "U", bool "V", int "dither", int "interp", bool "HQ")
{ 
    tv_range = Default(tv_range, True   ) # define if input clip is of tv range(limited range)
    interp   = Default(interp,   0      ) # use interp or not for SmoothCurve/SmoothCurve16
    HQ       = Default(HQ,       False  ) # enable high quality interpolation (slower)
    dither   = Default(dither,   -1     ) # -1 for no dither, 0 for ordered-dither, 1-100 for noise strength
    Y        = Default(Y,        True   )
    U        = Default(U,        True   )
    V        = Default(V,        True   )
    
    
    Assert(dither>=-1 && dither<=100 , """GSMC_U16: "dither" ranges from -1 to 100!""")
    
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


Function GSMC_Down8(clip input, bool "tv_range", bool "Y", bool "U", bool "V", int "dither", int "interp", bool "HQ")
{
    tv_range = Default(tv_range, True   ) # define if input clip is of tv range(limited range)
    interp   = Default(interp,   0      ) # use interp or not for SmoothCurve/SmoothCurve16
    HQ       = Default(HQ,       False  ) # enable high quality interpolation (slower)
    dither   = tv_range ? Default(dither, 6) : Default(dither, 50) # dither mode
    Y        = Default(Y,        True   )
    U        = Default(U,        True   )
    V        = Default(V,        True   )
    
    
    Assert(dither>=-1 && dither<=100 , """GSMC_Down8: "dither" ranges from -1 to 100!""")
    
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
