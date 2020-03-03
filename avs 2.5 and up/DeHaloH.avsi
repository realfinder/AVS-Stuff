# DeHaloHmod v.2.45

Function DeHaloHmod(clip input, int "Radius", int "Str", bool "Maska", bool "strong", int "mode", float "thr", val "exdehalo", bool "analog", bool "dirty", bool "smooth", bool "anime", bool "pel2", bool "usedeen", bool "maskpel2", float "thr2", val "extmask", val "extlmask", bool "RadInflate")
{
 usedeen    = Default(usedeen, false)
 pel2       = Default(pel2, false)
 exdhcb     = defined(exdehalo) ? isclip(exdehalo) ? true : false : false
 pel2       = exdhcb ? false : pel2
 maskpel2   = Default(maskpel2, false)
 exhmcb     = defined(extmask) ? isclip(extmask) ? true : false : false
 exhlmcb    = defined(extlmask) ? isclip(extlmask) ? true : false : false
 maskpel2   = exhmcb ? false : pel2
 smooth     = Default(smooth, false)
 RadInflate = Default(RadInflate, false)
 strong     = Default(strong, true)
 Maska      = Default(Maska, false)
 analog     = Default(analog, false)
 dirty      = Default(dirty, false)
 DR_Radius  = Default(Radius, defined(extlmask) ? -2 : dirty ? 6 : smooth || maskpel2 ? 4 : 2)
 DR_Str     = Default(Str, usedeen ? pel2 ? 40 : 15 : pel2 ? 7 : smooth ? 5 : 3)
 mode       = Default(mode, usedeen || defined(extlmask) ? 0 : 3)
 threshold  = Default(thr, smooth ? mode==1 ? 1 : 2250 : 140)
 anime      = Default(anime, defined(extlmask) ? true : mode != 3 ? false : true)
 thr2       = Default(thr2, smooth ? 170 : threshold/1.5)

 oclip = pel2 ? input.nnedi3_rpow2(rfactor=2) : input
 hfl = defined(exdehalo) ? exdhcb ? exdehalo : eval("oclip." + exdehalo) : smooth ? oclip.DeHalo_alpha_mt(rx=pel2 ? 3 : 2,ry=pel2 ? 3 : 2,darkstr=0.2,brightstr=0.8).yahr2(dirty ? pel2 ? 12 : 8 : pel2 ? 24 : 16).TBilateral(DR_Str,5,pel2 ? 1.4 : 0.9,0.9,pel2 ? 7 : 5,5,0.7,chroma=false) : usedeen ? oclip.sminideen(2, DR_Str  , 0, 3, 1, 1) : oclip.TBilateral(DR_Str,5,pel2 ? 1.4 : 0.9,0.9,pel2 ? 7 : 5,5,0.7,chroma=false)
 hfl = pel2 && !(maskpel2 && dirty) ? hfl.PointResize(input.Width(),input.Height()) : hfl

 cm  = dirty ? hfl : input

 cm  = !(dirty && pel2) && maskpel2 ? cm.nnedi3_rpow2(rfactor=2) : cm

 extmask = defined(extmask) ? exhmcb ? extmask : Eval("cm." + extmask) : undefined()

 extlmask = defined(extlmask) ? exhlmcb ? extlmask : Eval("cm." + extlmask) : undefined()

 EM1 = defined(extmask) ? extmask : mode == 0 ? (strong ? Camembert_dhh(analog ? cm.ColorYUV(autogain=true) : cm, 3) : Camembert_dhhMod(analog ? cm.ColorYUV(autogain=true) : cm, 3)) : EMask_dhh(analog ? cm.ColorYUV(autogain=true) : cm, mode, threshold, analog, thr2, 3)

 EM1 = maskpel2 ? EM1.PointResize(input.Width(),input.Height()) : EM1

 hfl = pel2 && (maskpel2 && dirty) ? hfl.PointResize(input.Width(),input.Height()) : hfl

 RM2 = DR_Radius < -1 ? EM1 : RadInflate ? spasses(EM1,DR_Radius,"mt_expand()").mt_inflate() : spasses(EM1.mt_inflate(),DR_Radius,"mt_expand()").mt_inflate()

 LiMa = defined(extlmask) ? extlmask : EM1

 DeRinging = anime ? mt_Merge(hfl, input, smooth ? LiMa.mt_inflate(155,155) : LiMa) : hfl
 DeRinging = Maska ? DeRinging.Invert() : DeRinging

return mt_Merge(input, DeRinging, RM2, u=2, v=2)
}

Function DeHaloH(clip input, int "DR_Radius", int "DR_Str", bool "Maska", bool "strong", int "mode", int "threshold")
{
 strong     = Default(strong, true)
 Maska      = Default(Maska, false)
 DR_Radius  = Default(DR_Radius, 2)
 DR_Str     = Default(DR_Str, 15)
 mode       = Default(mode, 0)
 threshold  = Default(threshold, 140)

 EM = mode == 0 ? (strong ? input.Camembert_dhh() : input.Camembert_dhhMod()) : EMask_dhh(input, mode, threshold)

 RM=spasses(EM,DR_Radius,"mt_expand()")
 DeRinging  = input.Deen("a2d", 2, DR_Str  , 0, 0, 0, 0, 0)
 DeRinging = Maska ?  DeRinging.Invert() : DeRinging
return mt_Merge(input, DeRinging, RM)
}