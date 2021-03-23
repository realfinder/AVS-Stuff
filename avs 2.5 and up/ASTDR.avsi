# ASTDR DeRainbow function v1.79
 
  function ASTDR(clip input, float "strength", int "tempsoftth", int "tempsoftrad", int "tempsoftsc", float "blstr", int "tht", int "FluxStv", int "dcn", bool "edgem", bool "exmc", clip "edgemprefil", bool "nomask")
  {
  nomask        = default(nomask, false)
  exmc          = default(exmc, false)
  sisfield      = input.IsFieldBased()
  fnomc         = sisfield && !exmc
  strn          = Default(strength, 5)
  blstr         = Default(blstr, sisfield ? 0.3 : 0.5)
  tht           = Default(tht, 255)
  tschrth       = Default(tempsoftth, 30)
  tschrrad      = Default(tempsoftrad, 3)
  tschrsc       = Default(tempsoftsc, 3)
  FluxStv       = Default(FluxStv, sisfield ? 60 : 75)
  dcn           = Default(dcn, 15)
  edgem         = default(edgem, false)

  momask    = exmc || nomask ? nop() : input.tweak(sat=1.1).mt_motion(thc2=1,thc1=1,thy2=1,thy1=1,y=3,v=3,u=3,tht=tht)
  momaskinv = exmc || nomask ? nop() : momask.mt_expand(u=3, v=3).mt_inflate(u=3, v=3).Invert().Levels(0,2,255,0,255)
 
  inrainev    = fnomc ? input.selecteven() : input
  filtered_uv = !exmc ? inrainev.DeCross(ThresholdY=15, Noise=dcn, Margin=1) : inrainev
  filtered_uv = filtered_uv.FluxSmoothST(FluxStv,sisfield ? FluxStv/2 : FluxStv).Mergeluma(inrainev)
  filtered_uv = sisfield ? filtered_uv : filtered_uv.awarpsharp2(depth=4,chroma=6,cplace="MPEG2")
  filtered_uv = (VersionNumber() < 2.60) && isyv12(input) ? filtered_uv.hqdn3d(ls=0,lt=0,cs=sisfield ? strn*2/5 : strn*3/5,ct=strn).temporalsoften(tschrrad,0,tschrth,tschrsc,2).blur(blstr).Mergeluma(inrainev) : filtered_uv.HQdn3d_2(ls=0,lt=0,cs=sisfield ? strn*2/5 : strn*3/5,ct=strn,y=2).temporalsoften(tschrrad,0,tschrth,tschrsc,2).blur(blstr).Mergeluma(inrainev)
  filtered_uv = sisfield ? filtered_uv : filtered_uv.aWarpSharp2(depth=4,chroma=6,cplace="MPEG2")
  filtered_uv = filtered_uv.sneo_FFT3D(sigma=sisfield ? 0.7 : 1,sigma3=sisfield ? 3 : 4,y=2,degrid=1)

  fnomc ? eval("""
 filtered_uve = filtered_uv
  inputodd    = input.selectodd()
  filtered_uv = inputodd.DeCross(ThresholdY=15, Noise=dcn, Margin=1).FluxSmoothST(FluxStv,sisfield ? FluxStv/2 : FluxStv).Mergeluma(inputodd)
  filtered_uv = (VersionNumber() < 2.60) && isyv12(input) ? filtered_uv.hqdn3d(ls=0,lt=0,cs=sisfield ? strn*2/5 : strn*3/5.0,ct=strn).temporalsoften(tschrrad,0,tschrth,tschrsc,2).blur(blstr).Mergeluma(inputodd) : filtered_uv.HQdn3d_2(ls=0,lt=0,cs=sisfield ? strn*2/5 : strn*3/5.0,ct=strn,y=2).temporalsoften(tschrrad,0,tschrth,tschrsc,2).blur(blstr).Mergeluma(inputodd)
  filtered_uv = filtered_uv.sneo_FFT3D(sigma=sisfield ? 0.7 : 1,sigma3=sisfield ? 3 : 4,y=2,degrid=1)
  filtered_uv = interleave(filtered_uve,filtered_uv)
                  """) : nop()
 
  filtered = exmc || nomask ? nop() : mt_merge(filtered_uv, input, momaskinv,y=2,u=3,v=3,luma=true)
  
  exmc || nomask ? filtered_uv : mt_merge(input, filtered, momask.mt_expand(y=1,u=3,v=3).mt_inflate(y=1,u=3,v=3),y=2,u=3,v=3)
  edgemclip = edgem && !nomask ? defined(edgemprefil) ? edgemprefil.mt_edge("sobel", 4, 4, 4, 4) : input.mt_edge("sobel", 4, 4, 4, 4) : nop()
  edgem && !nomask ? mt_merge(input, last, edgemclip.mt_expand().mt_inflate(),y=2,u=3,v=3,luma=true) : last
  }

# ASTDRmc DeRainbow function v1.78

  function ASTDRmc(clip input, float "strength", int "tempsoftth", int "tempsoftrad", int "tempsoftsc", float "blstr", int "tht", int "FluxStv", int "dcn", bool "edgem", int "thSAD", clip "prefil", bool "chroma", clip "edgemprefil", bool "nomask")
  {
sisfield = input.IsFieldBased()

  nomask   = default(nomask, false)
  tht      = Default(tht, 255)
  tschrrad = Default(tempsoftrad, sisfield ? 5 : 3).min(5)
  tschrth  = Default(tempsoftth, sisfield ? 50 : 30)
  thSAD    = Default(thSAD, tht)
  edgem    = default(edgem, sisfield)
  chroma   = default(chroma, false)

derbmask = sisfield || nomask ? nop() : (VersionNumber() < 2.60) ? input.tedgemask(threshY=2,u=1,v=1).mt_inflate() : input.vsTEdgeMask(threshY=2,u=1,v=1).mt_inflate()

exprefil  = defined(prefil)
prefil    = exprefil ? prefil : chroma ? sisfield ? input.MinBlur(3).mergeluma(input).Blur(1) : input.MinBlur(3,blurrep=true) : input.Blur(1.5)
ieven     = sisfield ? input.selecteven().mc4ASTDRmc(tschrrad,prefil.selecteven(),thSAD,chroma) : nop()
iodd      = sisfield ? input.selectodd().mc4ASTDRmc(tschrrad,prefil.selectodd(),thSAD,chroma) : nop()
mcclip    = sisfield ? nop() : input.mc4ASTDRmc(tschrrad,prefil,thSAD,chroma)

astev     = sisfield ? ieven.ASTDR(strength=strength,tempsoftth=tschrth,tempsoftrad=tschrrad,tempsoftsc=tempsoftsc,blstr=blstr,tht=tht,FluxStv=FluxStv,dcn=dcn,edgem=edgem,exmc=true,edgemprefil=defined(edgemprefil) ? edgemprefil.selecteven().changefps(framerate(prefil)/2*(tschrrad*2+1)) : !exprefil ? undefined : prefil.selecteven().changefps(framerate(prefil)/2*(tschrrad*2+1)), nomask=nomask).selectevery(tschrrad * 2 + 1, tschrrad) : nop()
astod     = sisfield ? iodd.ASTDR(strength=strength,tempsoftth=tschrth,tempsoftrad=tschrrad,tempsoftsc=tempsoftsc,blstr=blstr,tht=tht,FluxStv=FluxStv,dcn=dcn,edgem=edgem,exmc=true,edgemprefil=defined(edgemprefil) ? edgemprefil.selectodd().changefps(framerate(prefil)/2*(tschrrad*2+1)) : !exprefil ? undefined : prefil.selectodd().changefps(framerate(prefil)/2*(tschrrad*2+1)), nomask=nomask).selectevery(tschrrad * 2 + 1, tschrrad) : nop()
ASTDRclip = !sisfield ? mcclip.ASTDR(strength=strength,tempsoftth=tschrth,tempsoftrad=tschrrad,tempsoftsc=tempsoftsc,blstr=blstr,tht=tht,FluxStv=FluxStv,dcn=dcn,edgem=edgem,exmc=true,edgemprefil=defined(edgemprefil) ? edgemprefil.changefps(framerate(prefil)*(tschrrad*2+1)) : prefil.changefps(framerate(prefil)*(tschrrad*2+1)), nomask=nomask) : interleave(astev,astod)

sisfield || nomask ? ASTDRclip : mt_merge(input,ASTDRclip.selectevery(tschrrad * 2 + 1, tschrrad), derbmask,luma=true,y=2,u=3,v=3)
  }

  function mc4ASTDRmc(clip input, int "tschrrad", clip "prefil", int "thSAD", bool "chroma")
  {
masuper = prefil.MSuper()
mcsuper = input.MSuper(levels=1)

b5v = tschrrad > 4 ? MAnalyse(masuper, delta=5, truemotion = true, isb = true, chroma=chroma) : nop()
b4v = tschrrad > 3 ? MAnalyse(masuper, delta=4, truemotion = true, isb = true, chroma=chroma) : nop()
b3v = tschrrad > 2 ? MAnalyse(masuper, delta=3, truemotion = true, isb = true, chroma=chroma) : nop()
b2v = tschrrad > 1 ? MAnalyse(masuper, delta=2, truemotion = true, isb = true, chroma=chroma) : nop()
b1v = MAnalyse(masuper, delta=1, truemotion = true, isb = true, chroma=chroma)
f1v = MAnalyse(masuper, delta=1, truemotion = true, isb = false, chroma=chroma)
f2v = tschrrad > 1 ? MAnalyse(masuper, delta=2, truemotion = true, isb = false, chroma=chroma) : nop()
f3v = tschrrad > 2 ? MAnalyse(masuper, delta=3, truemotion = true, isb = false, chroma=chroma) : nop()
f4v = tschrrad > 3 ? MAnalyse(masuper, delta=4, truemotion = true, isb = false, chroma=chroma) : nop()
f5v = tschrrad > 4 ? MAnalyse(masuper, delta=5, truemotion = true, isb = false, chroma=chroma) : nop()

f5c = tschrrad > 4 ? input.MCompensate(mcsuper, f5v, thSAD=thSAD) : nop()
f4c = tschrrad > 3 ? input.MCompensate(mcsuper, f4v, thSAD=thSAD) : nop()
f3c = tschrrad > 2 ? input.MCompensate(mcsuper, f3v, thSAD=thSAD) : nop()
f2c = tschrrad > 1 ? input.MCompensate(mcsuper, f2v, thSAD=thSAD) : nop()
f1c = input.MCompensate(mcsuper, f1v, thSAD=thSAD)
b1c = input.MCompensate(mcsuper, b1v, thSAD=thSAD)
b2c = tschrrad > 1 ? input.MCompensate(mcsuper, b2v, thSAD=thSAD) : nop()
b3c = tschrrad > 2 ? input.MCompensate(mcsuper, b3v, thSAD=thSAD) : nop()
b4c = tschrrad > 3 ? input.MCompensate(mcsuper, b4v, thSAD=thSAD) : nop()
b5c = tschrrad > 4 ? input.MCompensate(mcsuper, b5v, thSAD=thSAD) : nop()

         tschrrad == 5 ? interleave(f5c,f4c,f3c,f2c,f1c,input,b1c,b2c,b3c,b4c,b5c) : \
         tschrrad == 4 ? interleave(f4c,f3c,f2c,f1c,input,b1c,b2c,b3c,b4c) : \
         tschrrad == 3 ? interleave(f3c,f2c,f1c,input,b1c,b2c,b3c) : \
         tschrrad == 2 ? interleave(f2c,f1c,input,b1c,b2c) : \
                         interleave(f1c,input,b1c)
  }