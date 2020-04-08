# IResize by Gavino and IanB and mod by A.SONY to use Custom resizer and Extra resizer parameters may be passed via res_params. like this IResize(240,480,resifilter="LanczosResize",res_params=",taps=5")
# some parameters are special for 420 (yv12 in vanilla avs)
# v 1.19
function IResize(clip c, int NewWidth, int NewHeight, string "resifilter", string "res_params", bool "mpeg2", Float "src_left", Float "src_top", float "src_width", float "src_height", string "cresifilter", string "cres_params", bool "invshift", bool "invcshift", bool "inhcshift") {
  avs26   = VersionNumber() < 2.60 ? false : true
  sisphbd = AvsPlusVersionNumber > 2294
  lresifilter  = defined(resifilter) ? LCase(resifilter) : "resifilter"
  lcresifilter = defined(cresifilter) ? LCase(cresifilter) : defined(resifilter) ? lresifilter : "cresifilter"
  lresifilter  = LeftStr(lresifilter, 2) == "de" && RightStr(lresifilter, 8) == "resizemt" ? "deresizemt" : lresifilter
  lcresifilter = LeftStr(lcresifilter, 2) == "de" && RightStr(lcresifilter, 8) == "resizemt" ? "deresizemt" : lcresifilter
  resifilter   = default ( resifilter,         "Spline36resize" )
  res_params   = default(res_params, "")
  mpeg2        = default(mpeg2, true)
  src_left     = default(src_left, 0)
  src_top      = default(src_top, 0)
  res_params_c = default(cres_params, res_params)
  cresifilter  = default(cresifilter, resifilter)
  invshift	   = default(invshift, ((lresifilter == "debicubic" || lresifilter == "debicubicy" || lresifilter == "debilinear" || lresifilter == "debilinearY") && isrgb(c)))
  invcshift	   = default(invcshift, ((lcresifilter == "debicubic" || lcresifilter == "debicubicy" || lcresifilter == "debilinear" || lcresifilter == "debilinearY") && isrgb(c)))
  chr420  = sisphbd ? c.is420() : c.isyv12()
  slumSep = chr420 && avs26
  slumres = slumSep ? sisphbd ? "ConvertToY()." : "ConvertToY8()." : ""
  c420_ow = slumSep ? Float(Width(c)/2.0) : nop()
  ch420m  = slumSep && mpeg2
  desam = lcresifilter == "deresizemt" ? true : lcresifilter == "resizex" ? defined(res_params) ? FindStr(LCase(res_params), "desampling=true") != 0 : false : false
  inhcshift	   = default(inhcshift, lcresifilter == "deresizemt" && ch420m)
  c420_nw = defined(src_width) ? Float(src_width/2.0) : Float(NewWidth/2.0)
  wShift  = ch420m ? (slumSep ? 0.25 : 0.5)*(desam ? 1.0-c420_nw/c420_ow : 1.0-c420_ow/c420_nw) : 0
  c
  SeparateFields() 
  luhe  = defined(src_height) ? Float(src_height/2.0) : Height()
  Shift = (GetParity() ? -0.25 : 0.25) * (desam ? Float(NewHeight/2.0)/luhe-1.0 : luhe/Float(NewHeight/2.0)-1.0)
  v2=last
  SelectEven(v2)
  euvcl = slumSep ? sisphbd ? Interleave(ExtractU(),ExtractV()) : Interleave(UToY8(),VToY8()) : nop()
  eschrres = slumSep ? "euvcl." : ""
  E  = Eval(slumres + resifilter + "(NewWidth, NewHeight/2, src_left=src_left, src_top=src_top + (invshift ? -Shift : Shift),src_width=src_width,src_height=src_height" + res_params + ")")
  Ec = chr420 ? Eval(eschrres + cresifilter + "(slumSep ? NewWidth/2 : NewWidth, slumSep ? NewHeight/4 : NewHeight/2, src_left=wShift + (slumSep ? src_left==0 ? 0 : src_left/2 : src_left), src_top=slumSep ? (invcshift ? -Shift : Shift) + (src_top==0 ? 0 : src_top/2) : src_top + (invcshift ? -2*shift : 2*Shift),src_width=defined(src_width) ? c420_nw : src_width,src_height=defined(src_height) ? luhe : src_height" + res_params_c + ")") : nop()
  SelectOdd(v2)
  ouvcl = slumSep ? sisphbd ? Interleave(ExtractU(),ExtractV()) : Interleave(UToY8(),VToY8()) : nop()
  oschrres = slumSep ? "ouvcl." : ""
  O  = Eval(slumres + resifilter + "(NewWidth, NewHeight/2, src_left=src_left, src_top=src_top + (invshift ? Shift : -Shift),src_width=src_width,src_height=src_height" + res_params + ")")
  Oc = chr420 ? Eval(oschrres + cresifilter + "(slumSep ? NewWidth/2 : NewWidth, slumSep ? NewHeight/4 : NewHeight/2, src_left=wShift + (slumSep ? src_left==0 ? 0 : src_left/2 : src_left), src_top=slumSep ? (invcshift ? Shift : -Shift) + (src_top==0 ? 0 : src_top/2) : src_top + (invcshift ? 2*shift : -2*shift),src_width=defined(src_width) ? c420_nw : src_width,src_height=defined(src_height) ? luhe : src_height" + res_params_c + ")") : nop()
  Interleave(E, O)
  chr420 ? avs26 ? sisphbd ? CombinePlanes(last, Interleave(Ec.Selecteven(),Oc.Selecteven()), Interleave(Ec.SelectOdd(),Oc.SelectOdd()), planes="YUV", source_planes="YYY", pixel_type=c.PixelType()) : YtoUV( Interleave(Ec.Selecteven(),Oc.Selecteven()), Interleave(Ec.SelectOdd(),Oc.SelectOdd()), last ) : MergeChroma(Interleave(Ec, Oc)) : Last
  Weave()
}