/*
MAA2 v0.435 mod by A.SONY
=========

Updated version of the MAA antialising script from AnimeIVTC.
MAA2 uses tp7's SangNom2, which provide a nice speedup for SangNom-based antialiasing,
especially when only processing the luma plane.
The defaults of MAA2 match up with MAA, so you'll get identical output (save for the more accurate border region processing of SangNom2)
when using this script as a drop-in replacement.

MAA2 supports Y8, YV12, YV16 and YV24 input.

Requirements:

   * AviSynth 2.6
   * SangNom2 0.3+ (or not with ext_aa)
   * FTurn (not necessarily required but will improve speed in avs not avs+)
   * Masktools 2 beta or better

Parameters:

   + [int] mask (1)
       *   0: Disable masking
       *   1: Enable masking
       *  -i: Enable masking with custom treshold
   + [bool] chroma (false)
       *   false: Don't process chroma channels (copy UV from the source clip if present)
       *   true: Process chroma channels
   + [float] ss (2.0)
       *   Supersampling factor (sensible values are between 2.0 and 4.0 for HD content)
   + [int] aa (48)
       *   Sangnom2 luma antialiasing strength
   + [int] aac (aa-8)
       *   Sangnom2 chroma antialiasing strength
   + [int] threads (4)
       *   Number of threads used by every Sangnom2 instance
   + [int] show (0)
       *   0: Don't overlay mask
       *   1: Overlay mask only
       *   2: Overlay mask and run antialiasing on the luma plane
   + [int] maskt (1)
       *   0: with mask=0 will not use any masktools function
       *   1: sobel
       *   2: min/max
   + [val] ext_aa (undefined)
       *   External aa clip or function to use it instead of Sangnom2, you can use nnedi3_resize16(Width*2, Height*2) then nnedi3_resize16(Width/2, Height/2) or ext_aa="""edi_rpow2(2,2, fwidth=width(c),fheight=Height(c), edi="eedi3", mclip=m,cshift="spline36resize")""" or something else according to your source

*/

function maa2(clip c, int "mask", bool "chroma", float "ss", int "aa", int "aac", int "threads", int "show", int "maskt", val "ext_aa", float "ss_h")
{
    chroma = Default(chroma, false)
    mask   = Default(mask, 1)
    maskt  = Default(maskt, 1)
    mtresh = (mask < 0) ? -mask : 7
    show   = Default(show, 0)
    uv     = (chroma) ? 3 : 1
    aa     = Default(aa, 48)
    aac    = Default(aac, aa-8)
    aac    = (aac < 0) ? 0 : aac
	threads = default(Threads, sh_GetUserGlobalIMTint())

    sisphbd = AvsPlusVersionNumber > 2294
    sislumaonly = sisphbd  ? c.isy() : c.isy8()
    sisfullchro = sisphbd  ? c.is444() : c.isyv24()

    Assert(0 <= show <= 2, "MAA2: Parameter 'show' must be between 0 and 2")
    defined(ext_aa) ? Assert((Isclip(ext_aa) || IsString(ext_aa)), "'ext_aa' only accepts clip or string") : nop()

    # create mask
    (mask != 0) ? Eval("""
        m = (maskt != 1) ? c.mt_edge("min/max", 0, mtresh, 0, mtresh-6, u=uv, v=uv) : c.mt_edge("sobel", mtresh, mtresh, mtresh-6, mtresh-6, u=uv, v=uv)
                      """) : nop()

    # run sangnom2-based aa
    defined(ext_aa) ? isclip(ext_aa) ? eval("c_aa = ext_aa") : eval("c_aa = c." + ext_aa)
    \               : show != 1 ? Eval("""
        prfu  = sisfullchro && chroma
        cp_Y  = !(sislumaonly || prfu) ? sisphbd  ? c.ConvertToY() : c.ConvertToY8() : c
        cp_U  = !(sislumaonly || prfu || show > 0) ? sisphbd  ? c.ExtractU() : c.UtoY8() : nop()
        cp_V  = !(sislumaonly || prfu || show > 0) ? sisphbd  ? c.ExtractV() : c.VtoY8() : nop()

        c_aa_Y = cp_Y.Sangnom2AA(ss, ss_h, threads, aa, aac)
        c_aa_u = !(sislumaonly || prfu || show > 0) ? chroma ? cp_U.Sangnom2AA(ss, ss_h, threads, aac) : cp_U : nop()
        c_aa_v = !(sislumaonly || prfu || show > 0) ? chroma ? cp_V.Sangnom2AA(ss, ss_h, threads, aac) : cp_V : nop()

        c_aa = sislumaonly || prfu || show > 0 ? c_aa_Y : sisphbd  ? CombinePlanes(c_aa_Y,c_aa_u,c_aa_v,planes="YUV",sample_clip=c) : YToUV(c_aa_u, c_aa_v, c_aa_Y)
                                       """) : nop()

    # prepare chroma planes for mask overlay
    (mask != 0) ? Eval("m = m.mt_inflate(u=uv, v=uv)") : nop()
    (show == 1) ? Eval("""
        c_aa = sislumaonly ? c.invert()
                         \ : c.mt_lut("x 2 /", use_expr=2, y=2, u=3, v=3)
                       """) : \
    (show == 2) ? Eval("""
        c_aa = sislumaonly ? c_aa.invert()
                         \ : c_aa.mt_lut("x 2 /", use_expr=2, y=2, u=3, v=3)
                       """) : nop()

    # merge aa'ed lines into source
    (mask == 0) ? Eval("""
        lastaa = maskt == 0 ? sislumaonly ? c_aa : c.mergeluma(c_aa) : c.mt_logic(c_aa, "and", y=4, u=2, v=2)
        return lastaa
                       """) : \
    (show > 0) ? mt_merge(c, c_aa, m, luma=!sislumaonly) : Eval("""
        return (chroma) ? mt_merge(c, c_aa, m, u=3, v=3)
                      \ : mt_merge(c, c_aa, m, u=2, v=2)
                                                                  """)
}

function Sangnom2AA(clip c, float "ss", float "ss_h", int "threads", int "aa", int "aac")
{
    threads = Default(threads, 4)
    aa = Default(aa, 48)
    aac = Default(aac, aa-8)
    aac = (aac < 0) ? 0 : aac
    ss = Default(ss, 2.0)
     w = c.width()
     h = c.height()
    aa_w = round(w*ss/2.0)*2
    hasss_h = defined(ss_h)
    hasss_h ? Assert(ss_h > 0, "MAA2: ss_h factor must be > 0") : nop()
    ss_h = hasss_h ? ss_h : ss
    aa_h = round(h*ss_h/2.0)*2

    Assert(ss > 0, "MAA2: Supersampling factor must be > 0")
    Assert(!(aa_w==w && aa_h==h), "MAA2: why do you use this filter then?!")

    sisp   = IsAvsPlus

    c
    Eval("""
    aa_h==h && aa_w!=w ? eval("try { sisp ? dontdoft : fTurnLeft(mt=threads!=1) } catch(error_msg) { TurnLeft() }") : last
    aa_h==h ? threads!=1 ? Eval("try { Spline36Resizemt(aa_h, aa_w, threads=threads) } catch(error_msg) { Spline36Resize(aa_h, aa_w) }") : Spline36Resize(aa_h, aa_w) : last
    aa_h!=h ? threads!=1 ? Eval("try { Spline36Resizemt(aa_w, aa_h, threads=threads) } catch(error_msg) { Spline36Resize(aa_w, aa_h) }") : Spline36Resize(aa_w, aa_h) : last
            SangNom2(threads=threads, aa=aa, aac=aac)
    aa_h!=h && aa_w!=w ? eval("try { sisp ? dontdoft : fTurnLeft(mt=threads!=1) } catch(error_msg) { TurnLeft() }") : last
    aa_w==w ? last : aa_h!=h ? SangNom2(threads=threads, aa=aa, aac=aac) : last
    aa_h!=h && aa_w==w ? threads!=1 ? Eval("try { Spline36Resizemt(c.width, c.height, threads=threads) } catch(error_msg) { Spline36Resize(c.width, c.height) }") : Spline36Resize(c.width, c.height) : last
    aa_w!=w ? threads!=1 ? Eval("try { Spline36Resizemt(c.height, c.width, threads=threads) } catch(error_msg) { Spline36Resize(c.height, c.width) }") : Spline36Resize(c.height, c.width) : last
    aa_w!=w ? eval("try { sisp ? dontdoft : fTurnRight(mt=threads!=1) } catch(error_msg) { TurnRight() }") : last
    """)
}

function maa2ee(clip c){c.maa2(mask=-7, maskt=2, chroma=true,ext_aa="""edi_rpow2(2,2, fwidth=width(c),fheight=Height(c), edi="eedi3", mclip=m,cshift="spline36resize",sclip="nnedi3",nnrep=2,bordfix=true)""")
}