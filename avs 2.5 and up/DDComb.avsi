### ONLY FOR PROGRESSIVE VIDEO or Field Based
### Based on Did�e's script
### 2021.09.10 mod
Function DDComb(clip c, float "band", bool "static", bool "strong", bool "checkmate", bool "use_frfun7", float "frfun7_lambda", float "frfun7_T", string "frfun7_params")
{
  avs26    = !(VersionNumber() < 2.60)
  sisphbd = AvsPlusVersionNumber > 2294
  band     = default(band,0)
  static   = default(static,false)
  strong   = default(strong,false)
  usecheck = default(checkmate,!strong)
  sisField = c.IsFieldBased()
  usefrfu7 = default(use_frfun7,!(strong && avs26 && sisField))
  frparams = Default(frfun7_params,"")
  frlambda = default(frfun7_lambda,1.01)
  frfun7_T = default(frfun7_T,8)
  c
  borders = sisField ? weave().bicubicresize(width()/2,height()/2).separatefields().bicubicresize(width()+8,height()) : bicubicresize(width()/2,height()/2).bicubicresize(width()+8,height())
  stackhorizontal(borders.crop(0,0,4,0),last,borders.crop(width()+4,0,0,0))

  o=last ox=o.width() oy=o.height()

  clean1  = sisField ? strong ? avs26 ? o.aBlur(2, blurv=0).Repair(o.sh_Vinverse2H(uv=1, pass=strong ? 5 : 1),9,-1) : o.blur(1,0).sh_Vinverse2H(uv=1, pass=strong ? 6 : 1) : o.sh_Vinverse2H(uv=1) : o.separatefields().sh_Vinverse2(uv=1).weave()
 
  D1      = mt_makediff(o,clean1)
  D8      = avs26 ? YToUV(sisphbd ? D1.ExtractU() : D1.utoy8(),sisphbd ? D1.ExtractV() : D1.vtoy8(),sisphbd ? D1.ExtractY().bicubicresize(ox/2-72,oy).blur(1,0).bicubicresize(ox,oy,1,0) : D1.converttoy8().bicubicresize(ox/2-72,oy).blur(1,0).bicubicresize(ox,oy,1,0)) : D1.bicubicresize(ox/2-72,oy).blur(1,0).bicubicresize(ox,oy,1,0)
  D9      = avs26 ? mt_lutxy(D1,D8,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?", use_expr=1) : mt_lutxy(D1,D8,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
  clean1a = clean1.mt_adddiff(D9,U=2,V=2)
  clean1b = usefrfu7 ? eval("clean1a.frfun7(frlambda,frfun7_T,0"+frparams+")") : sBlackerPixel(o=clean1a,filtered=clean1a.aBlur(1, blurv=0).Repair(clean1a,9,-1),mdifffade=128,averagewithwhiterPixel=true)
  clean1b = sisField && !(clean1b.IsFieldBased()) ? c.getparity() ? clean1b.AssumeBFF().AssumeFieldBased().AssumeTFF() : clean1b.AssumeTFF().AssumeFieldBased().AssumeBFF() : clean1b

  allD    = mt_makediff(o,clean1b)
  shrpD   = mt_makediff(clean1b,clean1b.removegrain(20,-1))
  DD      = avs26 ? shrpD.repair(allD,13,-1).mt_lutxy(shrpD,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?", use_expr=1) : shrpD.repair(allD,13,-1).mt_lutxy(shrpD,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
  clean1b = strong ? sBlackerPixel(o=clean1b, filtered=sisField && avs26 ? clean1a.aBlur(1, blurv=0).Repair(clean1a,9,-1) : clean1a.Blur(1,0).Blur(1,sisField ? 0 : 1),averagewithwhiterPixel=avs26,averagewithwhiterPixelrep=2,deeponly=!usecheck) : clean1b
  clean1c = avs26 ? clean1b.mt_lutxy(clean1a,"x 3 scalef + y < x 2 scalef + x y < x 1 scalef + x 3 scalef - y > x 2 scalef - x y > x 1 scalef - x ? ? ? ?",U=2,V=2, use_expr=1)
                \.mt_adddiff(sisField ? DD.sbrH(strong ? 3 : 1) : DD.sbr()) : clean1b.mt_lutxy(clean1a,"x 3 + y < x 2 + x y < x 1 + x 3 - y > x 2 - x y > x 1 - x ? ? ? ?",U=2,V=2)
                \.mt_adddiff(sisField ? DD.sbrH(strong ? 3 : 1) : DD.sbr())

  clean1c = clean1c.crop(4,0,-4,0,true)
  dirty2c = static ? sisField ? c.weave() : c : nop()
  clean2a = static ? dirty2c.tcomb(mode=0) : nop()
  clean2b = static && usecheck ? clean2a.checkmate(tthr2=0) : clean2a
  clean2b = static ? sisField ? clean2b.separatefields() : clean2b : nop()
  clean2b = static ? sisField ? clean2b.Repair(clean1c,9,-1) : clean2b : nop()
  clean2m = static ? avs26 ? mt_lutxy(c,clean2b,"x y == 0 x 64 scaleb <= x y - abs 32 scaleb < range_max x y - abs 48 scaleb < range_max 255 48 / x y - abs * - 0 ? ? y 40 scaleb > x y > & x y - 16 >= range_max x y - 16 scaleb < ? 255 16 / x y - * 0 ? 0 ? ? ?", use_expr=1).mt_inflate(155,155) : mt_lutxy(c,clean2b,"x y == 0 x 64 <= x y - abs 32 < 255 x y - abs 48 < 255 255 48 / x y - abs * - 0 ? ? y 40 > x y > & x y - 16 >= 255 x y - 16 < ? 255 16 / x y - * 0 ? 0 ? ? ?").mt_inflate(155,155) : nop()
  clean3c = static ? mt_merge(clean1c,clean2b,clean2m,U=1,V=1) : clean1c
  clean3c = clean3c.mergechroma(c)
  output  = band != 0 ? clean3c.gradfun3(thr=band,smode=2) : clean3c
  return output
  #--- end of script ---#
}