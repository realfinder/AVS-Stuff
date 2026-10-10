# SoftSharpen 8.8
# mod 1.1

function min_ssh(float a, float b) { a<b ? a : b}
function max_ssh(float a, float b) { a>b ? a : b}


function Diff(clip vid, clip v1, clip v2, int color)
{
sisavs25 = VersionNumber() < 2.60
  m = sisavs25 ? TheLutXY(v1,v2, "x y - abs 25 *") : mt_LutXY(v1,v2, "x y - abs 25 *", use_expr=1)
  b = BlankClip(vid, color=color)
  return vid.Overlay(b, mask=m) 
} 


function TheLutXY(clip Video1, clip Video2, string Expr, int "use_expr", string "scale_inputs")
{
sisavs25 = VersionNumber() < 2.60
  Try {Video1 = sisavs25 ? mt_lutxy(Video1,Video2,Expr,Y=3,U=1,V=1) : mt_lutxy(Video1,Video2,Expr,Y=3,U=1,V=1, use_expr=use_expr, scale_inputs=scale_inputs)
      }
  Catch(erreur)
      {Video1 = Yv12lutxy(Video1,Video2,Expr,Y=3,U=1,V=1)
      }
  return Video1
}


function TheClamp(clip Video1, clip Video2, int st)
{
  Try {Video1 = mt_clamp(Video1,Video2,Video2,st,st,Y=3,U=1,V=1)
      }
  Catch(erreur)
      {st = st.string
       st = "x y "+st+" + < x y "+st+" - > x y "+st+" - ? y "+st+" + ?"
       Video1 = Yv12lutxy(Video1,Video2,st,Y=3,U=1,V=1)
      }
  return Video1  
}


function DarkLines(clip v, float line, bool "fast", clip "mask")
{
sisavs25 = VersionNumber() < 2.60
  fast = Default(fast, false)
  th = round(line.frac*30)
  line = (1+th/30)*line.floor
  v0 = th==0 ? v : v.mt_expand(th,y=3,u=2,v=2)
  v1 = v0.mt_expand(y=3,u=2,v=2) 
  v1 = fast ? v1 : v1.mt_expand(y=3,u=2,v=2).mt_inpand(y=3,u=2,v=2)
  v1 = v1.mt_inpand(y=3,u=2,v=2)
  st = "x y -"
  mask = Defined(mask) ? mask :\
         sisavs25 ? mt_lutXY(v1,v,st,y=3,u=1,v=1).mt_binarize(th*2).mt_expand(y=3,u=2,v=2) : mt_lutXY(v1,v,st,y=3,u=1,v=1, use_expr=1).mt_binarize(th*2).mt_expand(y=3,u=2,v=2)
  st = "x y - " + string(line/100.) + " * x +"
  v1 = sisavs25 ? mt_lutXY(v0, v1, st) : mt_lutXY(v0, v1, st, use_expr=1)
  th==0 ? v1 : mt_merge(v,v1,mask, y=3,u=1,v=1)
}


function GradFun2dbMod_Mod(clip c, float strength, bool "fast")
{
sisphbd = AvsPlusVersionNumber > 2294
  fast = Default(fast, false) 

  w = c.width+32
  h = c.height+32
  v = fast ? c : c.PointResize(w,h,-16,-16,w,h)
  v = !sisphbd ? v.GradFun2db(strength) : v.GradFun2DB3(strength)
  return fast ? v : v.Crop(16,16,-16,-16)
}


function AGain(clip video, float "gain", int "limit", \
                           bool "chroma", bool "debug")
{
sisavs25 = VersionNumber() < 2.60
  gain = Default(gain, 3)
  limit = Default(limit, 70)
  chroma = Default(chroma, true)
  debug = Default(debug, false)

  vg = video.colorYUV(autogain=true)
  var = mt_lutf(video, video, "avg", "y x - abs")

  dif = sisavs25 ? mt_lutxy(video, vg, "y x -") : mt_lutxy(video, vg, "y x -", use_expr=1)
  dif = sisavs25 ? mt_lutf(dif, dif, "avg", "1 x "+limit.string+" / 8 ^ - y *") : mt_lutf(dif, dif, "avg", "1 x "+limit.string+" / 8 ^ - y *", scale_inputs="allf")
  st  = string(gain/100.)+" x * 1 "
  dif = sisavs25 ? mt_lutf(var, dif, "avg", st+" < "+st+" ? 1.8 ^ y *") : mt_lutf(var, dif, "avg", st+" < "+st+" ? 1.8 ^ y *", scale_inputs="allf")

  vg = sisavs25 ? mt_lutxyz(video, vg, dif, "x y min z +") : mt_lutxyz(video, vg, dif, "x y min z +", use_expr=1)
  vg_ = sisavs25 ? mt_lutxy(video, vg, "100 y * x /") : mt_lutxy(video, vg, "100 y * x /", scale_inputs="allf", use_expr=1)

  vgUV = vg_.reduceBy2
  vgUV = YtoUV(vgUV,vgUV)
  st = "x 128 - y * 100 / 128 +"
  debug ? vg_.colorYUV(analyze=true) :\
  chroma ? sisavs25 ? mt_lutxy(vg, vgUV, uexpr=st, vexpr=st, y=2,u=3,v=3) : mt_lutxy(vg, vgUV, uexpr=st, vexpr=st, y=2,u=3,v=3, scale_inputs="allf", use_expr=1) : vg
}


function Experimental_AA(clip t, bool "Fast", clip "mask")
{
  Fast = Default(Fast, false)
  s = t.AssumeFrameBased.SeparateFields
  s = s.TDeint(mode=-1)
  s = fast ? s.selectOdd : overlay(s.selectOdd,s.selectEven,y=1,opacity=0.5)
  Defined(mask) ? mt_merge(t,s,mask, y=3,u=1,v=1) : s
}


function myDeblend(clip video, int "th", bool "debug")
{
sisavs25 = VersionNumber() < 2.60
  th = Default(th, 5)
  debug = Default(debug, th<0)

  video_a = video.Trim(1,0) 
  video_b = video.Trim(0,-1) + video

  diff_b = mt_makediff(video, video_b, y=3,u=1,v=1)
  diff_a = diff_b.Trim(1,0)

  st_b = " x 128 - x y + 256 - * 0 > y 128 - 2 ^ x 128 - 2 ^ >= & x 128 - abs 1 > & "
  st_a = " y 128 - y x + 256 - * 0 > x 128 - 2 ^ y 128 - 2 ^ >= & y 128 - abs 1 > & "
  detect = sisavs25 ? mt_lutxy(diff_b, diff_a, \
                               st_b + " 1 " + st_a + " 255 " + " 128 ? ?", y=3,u=1,v=1) : mt_lutxy(diff_b, diff_a, \
                               st_b + " 1 " + st_a + " 255 " + " 128 ? ?", y=3,u=1,v=1, scale_inputs="allf", use_expr=1)

sisphbd = AvsPlusVersionNumber > 2294
ssIsVF  = sisphbd ? IsVideoFloat() : false
shbdbpc = sisphbd ? BitsPerComponent() : 8
svhalf  = ssIsVF ? 0.5 : shbdbpc > 8 ? shbdbpc == 10 ? 512 : shbdbpc == 12 ? 2048 : shbdbpc == 14 ? 8192 : 32768 : 128
svhalfm = svhalf-th
svhalfp = svhalf+th
svrsize = ssIsVF ? 1.0 : shbdbpc > 8 ? shbdbpc == 10 ? 1024 : shbdbpc == 12 ? 4096 : shbdbpc == 14 ? 16384 : 65536 : 256

  v_deblend = video.ScriptClip("""
               ab = detect_b.AverageLuma(-1)
               a = detect.AverageLuma()
               aa = detect.AverageLuma(1)
               a < svhalfm && ab+a < svrsize ? video_b :\
               a > svhalfp && aa+a > svrsize ? video_a :\
               last
                               """, args="video_a, video_b, detect, th, svhalfm, svhalfp, svrsize")

  debug ? video.myDeblend_debug(ssdetect, ssth.abs) :\
          v_deblend.Trim(0, video.FrameCount-1)
}


function myDeblend_debug(clip video, clip detect, int th)
{
sisphbd = AvsPlusVersionNumber > 2294
ssIsVF  = sisphbd ? video.IsVideoFloat() : false
shbdbpc = sisphbd ? video.BitsPerComponent() : 8
sscalva = shbdbpc > 8 ? shbdbpc == 10 ? 4.0 : shbdbpc == 12 ? 16.0 : shbdbpc == 14 ? 64.0 : 256.0 : 1
  th0 = ssIsVF ? string((128-th)/255.0) : string((128-th)*sscalva)
  th1 = ssIsVF ? string((128+th)/255.0) : string((128+th)*sscalva)

  video = video.Subtitle( th0 + "..." + th1 ,10,10)

  video = video.ScriptClip("Subtitle(AverageLuma(detect).string, 30,30)", args="detect")

  video = ConditionalFilter(detect, video.Subtitle("-", 20,50), video,\
                            "AverageLuma()", "<", th0)
  video = ConditionalFilter(detect, video.Subtitle("+", 55,50), video,\
                            "AverageLuma()", ">", th1)

  return video
}


function TestDecimate(clip v)
{
  w_diff = mt_lutxy(v, v.trim(1,0), "x y - abs", y=3,u=1,v=1)
  global sscompt_1 = 0
  global sscompt_2 = 0
  global sscompt_3 = 0
  v.scriptclip("""
      a = AverageLuma(w_diff)
      sscompt_1 = 0.7>a          ? 1+sscompt_1 : sscompt_1
      sscompt_2 = 0.7<a && a<1.4 ? 1+sscompt_2 : sscompt_2
      sscompt_3 =          a>1.4 ? 1+sscompt_3 : sscompt_3
      subtitle("nombre d'images identiques : " + sscompt_1.string, 10,10)
      subtitle("nombre d'images proches : " + sscompt_2.string, 10,30)
      subtitle("nombre d'images distinctes : " + sscompt_3.string, 10,50)
      subtitle("LumaDifferenceToNext : "+a.string,10,70) 
      subtitle("Score : "+string(sscompt_3-2*sscompt_1),10,90) 
               """, args="w_diff")
}


function ADecimate(clip v, float f)
{
  global ssgth = 1
  v_e = v.ChangeFPS(f)
  v_o = v.Trim(1,0).ChangeFPS(f)
  v_ob = v_o.Trim(0,-1) + v_o
  global ssim_o = true
  v_e.ScriptClip("""
       yd = YDifferenceFromPrevious
       ssgth = min_ssh(min_ssh(  yd,  2.), (ssgth+yd)/3.  )
       ld = LumaDifference(v_ob, v_e)
       ssim_o = (yd > ssgth && ssim_o) || ld > ssgth
       ssim_o ? last : v_o
       #subtitle(ssim_o ? "v_e   "+ssgth.string : "v_o   "+ssgth.string)
                   """, args="v_e, v_o, v_ob")
}


function TheDecimate(clip v, float f, bool "fast")
{
  fast = Default(fast, true)

  Try {Video = fast ? v.FDecimate(f) : v.ADecimate(f)
      }
  Catch(erreur)
      {Video = v.ADecimate(f)
      }
  return Video
}


function FindFPS(clip video)
{
sisavs25 = VersionNumber() < 2.60
  Video = !sisavs25 || Video.IsYV12 ? Video : Video.ConvertToYV12
  v1 = video.myDeblend()
  global ssn0 = 0
  global ssn1 = 0
  global sscf = 0
  global ssm0 = 0
  global ssm1 = 0
  global ssmf0 = 0
  global ssmf1 = 0
  cfr = ceil(video.FrameRate)
  video.ScriptClip("""
     sscf = 1 + sscf
     subtitle("nombre d'images analysées : " + sscf.string, 10,10)
     ssn0 = 0.7 < YDifferenceToNext(video) ? 1 + ssn0 : ssn0
     ssn1 = 0.7 < YDifferenceToNext(v1) ? 1 + ssn1 : ssn1
     subtitle("nombre d'images distinctes sans deblend : " + ssn0.string, 10,30)
     subtitle("nombre d'images distinctes avec deblend : " + ssn1.string, 10,50)
     f0 = ssn0 * FrameRate / sscf
     f1 = ssn1 * FrameRate / sscf
     subtitle("fréquence 'ips' moyenne comprise entre ", 10,90)
     subtitle(f1.string + "  et  " + f0.string, 10,110)
     ssmf0 = sscf%cfr == 0 ? max_ssh(ssmf0, (ssn0-ssm0) * FrameRate / cfr) : ssmf0
     ssmf1 = sscf%cfr == 0 ? max_ssh(ssmf1, (ssn1-ssm1) * FrameRate / cfr) : ssmf1
     ssm0 = sscf%cfr == 0 ? ssn0 : ssm0
     ssm1 = sscf%cfr == 0 ? ssn1 : ssm1
     subtitle("fréquence 'ips' maximale comprise entre ", 10,130)
     subtitle(ssmf1.string + "  et  " + ssmf0.string, 10,150)
                   """, args="video, v1, cfr")
}



function TheMAnalyse(clip s, bool i, int b, int d, int o, bool chr)
{
  s.MAnalyse(isb=i,blksize=b,delta=d,overlap=o,TrueMotion=true,chroma=chr)
}


function TheBlindPP(clip video, int quant, string cpu2) 
{
  # (BlindPP + avisynth 2.6) needs video.width mod 32!
  w = video.width
  h = video.height
  w2 = ceil(w/32.)*32
  video = video.PointResize(w2,h,w-w2,0,w2,h)
  video = video.BlindPP(quant=quant, cpu2=cpu2)
  return video.Crop(w2-w,0,0,0)  
}


function EstimSoftSharpen(clip Video, int "Width", int "Height",
                         \ bool "Fast", int "Move", int "Mouv", bool "DeInt")
{
  DeInt = Default(DeInt, false)
  Height = Default(Height, Video.height)
  Width = Default(Width, Video.width)
  Ratio = Width.float/Height
  Height = round(Height/8.)
  Width = round(Height*Ratio)*8
  Height = Height*8

  Fast = Default(Fast, true)
  Move = Default(Move, Default(Mouv, 30))
  Move = Move<0 ? 0 : Move>255 ? 255 : Move

  Video = DeInt ? Video.TDeint(mode=2) : Video
  Video = Video.PointResize(Width,Height)
sisavs25 = VersionNumber() < 2.60
  Video = !sisavs25 || Video.IsYV12 ? Video : Video.ConvertToYV12

  blk = Fast ? 32 : 16
  chr = Fast ? false : true
  Super = Video.MSuper(blk,blk,1,sharp=0,chroma=chr)
  Masq = Super.TheMAnalyse(false, blk, 1, 0, chr)
  Masq = Video.MMask(Masq, ml=Move, Ysc=255)
  Masq = Fast ? Masq : mt_logic(Masq, Masq.trim(1,0), "min", y=3,u=1,v=1)
  MasqN = Masq.mt_binarize(35, false)
  global ssNet = 0
  global ssnb = 0

  Masq = Video.ScriptClip(""" WriteFile("EstimSoftSharpen.txt", \
                          string(Round(14+ssNet/6)), append=false) """)
  Masq = Masq.FrameEvaluate("ssNet=ssNet*(1-1./ssnb)+MasqN.AverageLuma/ssnb", args="MasqN")
  Masq = Masq.FrameEvaluate("ssnb=ssnb+1")
  return Masq
}



function SoftSharpen(clip Video, int "Blur", float "Sharp", float "Gain",
                    \ int "DeNois", float "DeNoisT", int "DeRin", float "Line",
                     \ int "Move", float "DeBan", int "DeBl", bool "DeInt", float "FPS",
                      \ int "Blend", bool "AA", string "Preset", bool "Fast", 
                       \ int "Overlap", int "Width", int "Height", int "DCT",
                        \ bool "Verbose", bool "Show",
    \ int "Flou", float "Net", int "Larg", int "Haut", 
     \ int "DeBr", float "DeBrT", int "Mouv")
{
  Preset = Default(Preset, "")
  pr7 = Preset=="anim" ? 1 :\
        Preset=="static video" || Preset=="low motion" ? 2 :\
        Preset=="film" ? 3 :\
        Preset=="fast video" || Preset=="high motion" ? 4 :\
        Preset=="vhs" ? 5 :\
        Preset=="maxi" ? 6 :\
        Preset=="light" ? 7 : 0
  w = Video.width
  h = Video.height
  Width = Default(Width, w)
  Width = Default(Larg, Width)
  Height = Default(Height, h)
  Height = Default(Haut, Height)
  assert(w%4==0 && h%4==0 && Width%4==0 && Height%4==0, "Resolution mod 4")
  Sharp = Default(Sharp, pr7.Select(21,15,15,19,23,25,30,13))
  Sharp = Default(Net, Sharp)
  Sharp = min_ssh(max_ssh(Sharp,0),70)
  SharpW = Sharp.frac
  Sharp = Sharp.floor
  DeRin = Default(DeRin, Sharp/5)
  DeRin = min_ssh(max_ssh(DeRin, 0), 255)
  Gain = Default(Gain, 0)
  Fast = Default(Fast, false)
  Blur = Default(Blur, Fast || Sharp==0 ? 0 :\
                                          pr7.Select(15,20,18,15,12,20,30,12))
  Blur = Default(Flou, Blur)
  Blur = min_ssh(max_ssh(Blur,0), 30)
  Move = Default(Move, 30)
  Move = Default(Mouv, Move)
  Move = min_ssh(max_ssh(Move,0), 255)
  Move = Sharp==0 && Blur==0 ? 0 : Move
  DeNois = Default(DeNois, pr7.Select(8,10,3,5,7,10,10,2))
  DeNois = Default(Debr, DeNois)
  DeNois = min_ssh(max_ssh(DeNois, 0), 45)
  DeNoisT = Default(DeNoisT, pr7.Select(DeNois,6,10,7,6,10.2,15.3,5))
  DeNoisT = Default(DebrT, DenoisT)
  DeNoisT = DeNoisT<0 ? 0 : DeNoisT
  meth = round(10*DeNoisT.frac)
  meth = meth>0 ? meth : Fast ? 1 : ceil(DeNoisT/8.)
  meth = min_ssh(meth,3)
  DeNoisT = DeNoisT.floor
  DeBan = Default(DeBan, pr7.Select(0,1.5,0,0,0,0,1.5,0))
  DeBan = DeBan>1.2 || DeBan==0 ? DeBan : 1.2
  DeBl = Default(DeBl, pr7.Select(0,0,0,0,0,5,10,0))
  DeBl = min_ssh(max_ssh(DeBl,0), 255)
  Line = Default(Line, pr7.Select(0,10,0,0,0,10,10,0))
  Line = min_ssh(max_ssh(Line,0), 255)
  Overlap = Default(Overlap, 0)
  DeInt = Default(DeInt, false)
  Blend = Default(Blend, 0)
  Blend = min_ssh(Blend, 128)
  FPS = Default(FPS, Video.FrameRate)
  AA = Default(AA, false)
  DCT = Default(DCT, pr7.select(6,6,5,5,5,7,7,4))
  DCT = min_ssh(max_ssh(DCT,0), 14)
  DCT = Height%16==0 && Width%16==0 ? DCT : 0 
  Verbose = Default(Verbose, false)
  Show = Default(Show, false)

sisavs25 = VersionNumber() < 2.60

  Video = !sisavs25 || Video.IsYV12 ? Video : Video.ConvertToYV12

  Video = DeInt ? Video.TDeint(mode=2) : Video
  Video = Video.AssumeFrameBased

  Video = Blend == 0 ? Video : Video.myDeblend(Blend)
  Video = FPS < Video.FrameRate ? Video.TheDecimate(FPS,fast) : Video

  Resize = Height==h && Width==w ? false : true
  Video0 = Resize==false || w*h < Width*Height ? Video :\
           Fast ? Video.BilinearResize(Width,Height) :\
                  Video.BicubicResize(Width,Height,0,0.7-Denois/180.)  

  h = Video0.height 
  w = Video0.width  
  w2 = w%16==0 || (derin==0 && debl==0 && denoisT==0) ? w : ceil(1+w/16.)*16
  h2 = h%16==0 && denois<9 ? h :\
       derin==0 && debl==0 && denoisT==0 && move==0 && denois<9 ? h :\
       ceil(1+h/16.)*16       
       
  dw = w2-w  # mulitple de 4
  dh = h2-h  # mulitple de 4
  Video0 = h==h2 && w==w2 ? Video0 :\
                            Video0.PointResize(w2,h2,-dw/2,-dh/2,w2,h2)
 
  Video0 = AA ? Video0.Experimental_AA(Fast) : Video0
 
  blk = Fast ? 32 : 16
  chr = Fast ? false : true
  Super = Video0.MSuper(blk, blk, 1, sharp=0, chroma=chr)
  VB1 = Super.TheMAnalyse( true, blk, 1, Overlap, chr)
  VB2 = Super.TheMAnalyse( true, blk, 2, Overlap, chr)
  VB3 = Super.TheMAnalyse( true, blk, 3, Overlap, chr)
  VF1 = Super.TheMAnalyse(false, blk, 1, Overlap, chr)
  VF2 = Super.TheMAnalyse(false, blk, 2, Overlap, chr)
  VF3 = Super.TheMAnalyse(false, blk, 3, Overlap, chr)

  stuv =        sisavs25 ? "101 x < x 131 < & 136 y < & y 164 < & " : "101 scalef x < x 131 scalef < & 136 scalef y < & y 164 scalef < & "
  stuv = sisavs25 ? stuv + "255 y x + < & y x + 274 < & y x - 60 < & " : stuv + "range_max y x + < & y x + 274 scalef < & y x - 60 scalef < & "
  Masq2 = sisavs25 ? TheLutXY(Video0.UtoY, Video0.VtoY, stuv + " x 0 ?") : mt_LutXY(Video0.sh_ExtractU, Video0.sh_ExtractV, stuv + " x 0 ?", use_expr=1)
  Masq2 = Masq2.PointResize(w2,h2).MatchColorFormat(Video0)
  sty = sisavs25 ? "30 y < y 170 < & 0 x < & 216 x y 2 * + < & x y 2 * + 420 < & " : "30 scalef y < y 170 scalef < & 0 x < & 216 scalef x y 2 * + < & x y 2 * + 420 scalef < & "
  st = sisavs25 ? "450 x 116 - abs 8 * - y 100 - abs 3 * - " : "450 scalef x 116 scalef - abs 8 * - y 100 scalef - abs 3 * - " 
  Masq2 = sisavs25 ? TheLutXY(Masq2, Video0, sty + st + " 0 ?") : mt_LutXY(Masq2, Video0, sty + st + " 0 ?", use_expr=1)
  #return Video0.mergeluma(Masq2,0.5)

  Video1 = meth==1 ? Video0.MDegrain1(Super,VB1,VF1,thSAD=DeNoisT*50) :\
           meth==2 ? Video0.MDegrain2(Super,VB1,VF1,VB2,VF2,thSAD=DeNoisT*50):\
             Video0.MDegrain3(Super,VB1,VF1,VB2,VF2,VB3,VF3,thSAD=DeNoisT*50)

  Video1 = DeNoisT==0 ? Video0 :\
           DeNoisT>9 || Fast || pr7==1 || pr7>4 ? Video1 :\
                                 Video1.mt_merge(Video0, Masq2, y=3,u=1,v=1)

  Video = Show ? Video0.Diff(Video0, Video1, $FF0000) : nop

  Video2 = Fast && Sharp<31 ? Video1.Sharpen(Sharp/30) :\ 
           Video1.ASharp(Sharp/9., 16*SharpW+(1-SharpW)*Sharp/3.5, 1, true)

  Masq = Move==0 ? BlankClip(Video0, color=0) : Video0.MMask(VF1, ml=Move)
  Masq = Fast || Move==0 ? Masq :\
                      mt_average(Masq, Video0.MMask(VB1, ml=Move), y=3,u=1,v=1)
  Masq = sisavs25 ? Masq.mt_lut("300 5 x * -",y=3,u=1,v=1) : Masq.mt_lut("300 scalef 5 x * -", y=3, u=1, v=1, use_expr=1)

  Masq3 = Video0.svsMSharpen(6, mask=true)

  SharpWStr = string(SharpW)
  st0 = sisavs25 ? "255 x 2 * - " + SharpWStr + " * x +" : "range_max x 2 * - " + SharpWStr + " * x +"
  st1 = sisavs25 ? "255 x 2 * - " + SharpWStr + " * x + y * 255 /" : "range_max x 2 * - " + SharpWStr + " * x + y * range_max /"
  Masq4 = Move==0 && SharpW==0 ? nop :\
          Move==0 ? sisavs25 ? mt_lut(Masq3, st0, y=3,u=1,v=1) : Masq3.mt_lut(st0, y=3, u=1, v=1, use_expr=1) :\
          SharpW==0 ? sisavs25 ? TheLutXY(Masq3, Masq, "x y * 255 /") : mt_LutXY(Masq3, Masq, "x y * range_max /", use_expr=1) :\
                      sisavs25 ? TheLutXY(Masq3, Masq, st1) : mt_LutXY(Masq3, Masq, st1, use_expr=1)
  Video2 = Move==0 && SharpW==0 ? Video2 :\
                     Video1.mt_merge(Video2, Masq4, y=3,u=1,v=1) 
  #return Video0.mergeluma(Masq4,0.5)
  Video2 = Sharp==0 ? Video1 : Video2.TheClamp(Video1, Sharp/3)
  Video = Show ? Video.Diff(Video2, Video1, $00FF00) : nop


  Video2 = DeRin==0 ? Video2 : Video2.TheBlindPP(derin, "ooooxx")


  Masq = sisavs25 ? Masq.TheLutXY(Masq3, "y 128 < 50 x - 5 * 0 ?") : Masq.mt_LutXY(Masq3, "y range_half < 50 scalef x - 5 * 0 ?", use_expr=1)
  #return Video0.mergeluma(Masq,0.5)
  Video3 = Fast ? Video1.Blur(blur/19) : Video1.myDeen("c2d",1,blur,blur)
  Video3 = Blur==0 || Move==0 ? Video2 :\
                    Video2.mt_merge(Video3, Masq, y=3, u=3, v=3)
  Video = Show ? Video.Diff(Video2, Video3, $0000FF) : nop


  Video3 = Line==0 ? Video3 : Video3.DarkLines(Line, Fast, Masq3)
  Video3 = Gain==0 ? Video3 : Video3.AGain(Gain, chroma=fast ? false : true)
  Video3 = DeBan==0 || 8<DeNois ? Video3 : Video3.GradFun2dbMod_Mod(DeBan,Fast)


  mode = DeNois<3 ? 1 : DeNois<6 ? 2 : 27
  modeU = Denois<9 ? Denois/2 : 4 
  Video4 = Video3.RemoveGrain(mode=mode, modeU=modeU)
  Video4 = DeNois<9 ? Video4 :\
                      Video4.myDeen("c2d", DeNois/6, DeNois-7, DeNois-7)

  Masq2 = sisavs25 ? Masq2.TheLutXY(Masq, "y 0 == x 0 ?").mt_inflate(y=3,u=1,v=1) : Masq2.mt_LutXY(Masq, "y 0 == x 0 ?", use_expr=1).mt_inflate(y=3, u=1, v=1)
  #return Video0.mergeluma(Masq2,0.5)
  Video4 = DeNois==0 ? Video3 :\
           DeNois>9 || Fast || pr7==1 || pr7>4 ? Video4 :\
                                  Video4.mt_merge(Video3, Masq2, y=3,u=1,v=1)
  Video = Show ? Video.Diff(Video4, Video3, $FF0000) : nop

  Video5 = DeBl==0 ? Video4 :\
           Fast ? Video4.TheBlindPP(Debl, "xxxxoo") :\
                  Video4.DeBlock(16+2*DeBl)

  Video5 = DeBan==0 || DeNois<9 ? Video5 : Video5.GradFun2dbMod_Mod(DeBan,Fast)

  Video = Show ? Video : Video5
  Video = Video.Crop(dw/2,dh/2,-dw/2,-dh/2)

  Video = Width==w && Height==h ? Video :\
          Fast ? Video.BilinearResize(Width,Height) :\
                 Video.BicubicResize(Width,Height,0,0.7-Denois/180.)

  Video = DCT==0 ? Video : Video.dctFilterD(DCT)

  Video = FPS > Video.FrameRate ? Video.ChangeFPS(FPS) : Video

  x = 10
  y = -8

  st = "Preset : "+Preset+" ("+pr7.string+")"
  y = Verbose ? y+18 : y 
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Blur level : "+Blur.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Sharp level : "+Sharp.string+" (Bal. "+SharpWStr+")" 
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Gain level : "+Gain.string 
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Spatial denoising level : "+DeNois.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Temporal denoising level : "+DeNoisT.string+" (MD"+meth.string+")"
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "DeRinging level : "+DeRin.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Movement detection : "+Move.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "DCT reduction : "+DCT.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  x = 280
  y = -8

  st = "Debanding level : "+DeBan.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Deblocking level : "+DeBl.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Antialiasing level : "+AA.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Deblend level : "+Blend.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "FPS : "+FPS.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Dark line level : "+Line.floor.string
  st = st + " (thin "+round(30*Line.frac).string+")"
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Overlap : "+Overlap.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Fast process : "+Fast.string
  y = Verbose ? y+18 : y  
  Video = Verbose ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Video width : "+Width.string
  y = Verbose && Resize ? y+18 : y  
  Video = Verbose && Resize ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Video height : "+Height.string
  y = Verbose && Resize ? y+18 : y  
  Video = Verbose && Resize ? Video.Subtitle(st,x,y,size=16) : Video

  st = "Green=Sharpened,  Blue=Blurred,  Red=Denoised"
  y = Show ? y+18 : y  
  Video = Show ? Video.Subtitle(st,x,y,size=16) : Video

  return Video
} 

function myDeen(clip clip, string "mode", int "rad", int "thrY", int "thrUV", int "tthY", int "tthUV", float "min", float "scd")
{
  mode  = Default(mode, "c3d")
  rad   = Default(rad, 1)
  thrY  = Default(thrY, 7)
  thrUV = Default(thrUV, 9)
  tthY  = Default(tthY, 4)
  tthUV = Default(tthUV, 6)
  min   = Default(min, 0.5)
  scd   = Default(scd, 9.0)

  sisphbd = AvsPlusVersionNumber > 2294

  return !sisphbd ? clip.Deen(mode, rad, thrY, thrUV, tthY, tthUV, min, scd) : eval("""
                    \ clip.neo_smo_Deen(
                    \   mode=mode, 
                    \   radius=[rad, rad, rad], 
                    \   threshold=[float(thrY), float(thrUV), float(thrUV)], 
                    \   temporal_threshold=[float(tthY), float(tthUV), float(tthUV)], 
                    \   minimum=[min, min, min], 
                    \   scenechange=round(scd), 
                    \   scalep=true
                    \ )
""")
}
