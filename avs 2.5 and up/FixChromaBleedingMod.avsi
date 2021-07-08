# FixChromaBleedingMod v1.381
# since 1.38 it need Utils-r41.avsi for Levelss in avsplus, aside from other dependencies

Function FixChromaBleedingMod(clip input, int "cxShift", int "cyShift", float "thr", float "strength", bool "f", float "opacity", bool "n", bool "xysh", bool "Bic", bool "YIQNTSC", bool "noexpand") {
sisavs26 = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sisyuy2 = input.isyuy2()
input = sisavs26 && sisyuy2 ? input.converttoyv16() : input
  xShift = default ( cxShift,       -4 )
  yShift = default ( cyShift,       -4 )
  thr	 = default ( thr,         4.0 )
  stre = default ( strength,      0.8 )
  n =  default ( n,       false )
  sh =  default ( xysh,       false )
  Bic = default ( Bic,       false )
  YIQNTSC = default ( YIQNTSC,   false )
  opacity = default ( opacity,       1 )
  noexpand = default ( noexpand,   false )
  f =  default ( f,       !noexpand )

  # prepare to work on the V channel and reduce to speed up and filter noise
  vch  = sisphbd ? YIQNTSC ? input.SwapUV().Tweak(hue=-33).tweak(sat=thr).ExtractU() : input.tweak(sat=thr).ExtractV() : !sisavs26 ? YIQNTSC ? input.SwapUV().Tweak(hue=-33).tweak(sat=thr).UtoY : input.tweak(sat=thr).VtoY : YIQNTSC ? input.SwapUV().Tweak(hue=-33).tweak(sat=thr).UtoY8 : input.tweak(sat=thr).VtoY8
  area = f ? !sisavs26 ? vch.ConvertToyv12.ReduceBy2 : vch.ReduceBy2 : n ? !sisavs26 ? vch.ConvertToyv12.Blur(1) : vch.Blur(1) : !sisavs26 ? vch.ConvertToyv12 : vch

  # select and normalize both extremes of the scale
  red = sisphbd ? area.Levelss(255,1.0,255,255,0) : area.levels(255,1.0,255,255,0)
  blue = sisphbd ? area.Levelss(0,1.0,0,0,255) : area.levels(0,1.0,0,0,255)

  # merge both masks
  maskc = noexpand || n || f ?  MergeLuma(red, blue, 0.5) : MergeLuma(red, blue, 0.5).Blur(1)
  maskc = sisphbd ? maskc.Levelss(250,1.0,250,255,0) : maskc.Levels(250,1.0,250,255,0)

  # expand to cover beyond the bleeding areas and shift to compensate the resizing
   maskc = maskc.mt_edge("0 0 0 1 0 0 0 0 0", 0,255,0,255).mt_edge("1 1 1 1 1 1 0 0 0", 0,255,0,255)

  # back to full size and binarize (also a trick to expand)
  maskc = f ? Bic ? maskc.BicubicResize(Width(vch),Height(vch)) : maskc.BilinearResize(Width(vch),Height(vch)) : maskc
  maskc = (f && Bic) || noexpand ? sisphbd ? maskc.Levelss(10,1.0,10,0,255) : maskc.Levels(10,1.0,10,0,255) : sisphbd ? maskc.Levelss(10,1.0,10,0,255).mt_inflate() : maskc.Levels(10,1.0,10,0,255).mt_inflate()

  # prepare a version of the image that has its chroma shifted and less saturated
  input_c = sh ? sisavs26 ? input.sChromaShift2(ux=xShift,uy=yShift,ResizeMethod="Spline16").tweak(sat=stre) : input.ChromaShiftSP(x=xShift,y=yShift).tweak(sat=stre) : sisavs26 ? input.sChromaShift2(ux=xShift).tweak(sat=stre) : input.ChromaShift(C=xShift).tweak(sat=stre)

  # combine both images using the mask
  fu = sisphbd ? input.ExtractU.overlay(input_c.ExtractU,mask=maskc,mode="blend",opacity=opacity) : !sisavs26 ? input.utoy.overlay(input_c.utoy,mask=maskc,mode="blend",opacity=opacity) : input.utoy8.overlay(input_c.utoy8,mask=maskc,mode="blend",opacity=opacity)
  fv = sisphbd ? input.ExtractV.overlay(input_c.ExtractV,mask=maskc,mode="blend",opacity=opacity) : !sisavs26 ? input.vtoy.overlay(input_c.vtoy,mask=maskc,mode="blend",opacity=opacity) : input.vtoy8.overlay(input_c.vtoy8,mask=maskc,mode="blend",opacity=opacity)
  YToUV(fU, fV, input)
  sisavs26 && sisyuy2 ? converttoyuy2() : last
}