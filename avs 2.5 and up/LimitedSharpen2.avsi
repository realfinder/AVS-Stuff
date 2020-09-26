# LimitedSharpen2 (aka aSaWLimitedSharpen)
#
# A multi-purpose sharpener by Didée, hacked by Akirasuto n' Soulhunter... ^^
#
# HBD update 2020.09.25

function LimitedSharpen2( clip clp,
 \                       float "ss_x",   float "ss_y",
 \                       int   "dest_x", int   "dest_y",
 \                       int   "Smode" , float "strength", int  "radius",
 \                       int   "Lmode",  bool  "wide",     float  "overshoot",
 \                       bool  "soft",   int   "edgemode", bool "special",
 \                       float "aSharpS", float "aWThresh",int   "exborder" )
{
sisavs26 = !(VersionNumber() < 2.60)
ox = clp.width
oy = clp.height
ss_x =     default( ss_x, 1.0 )
ss_y =     default( ss_y, 1.0 )
dest_x =   default( dest_x, ox )
dest_y =   default( dest_y, oy )
Smode =    default( Smode, 4 )
strength = Smode==1
 \       ? default( strength, 160 )
 \       : default( strength, 100 )
strength = Smode==2&&strength>100 ? 100 : strength
radius =   default( radius, 2 )
Lmode =    default( Lmode, 1 )
aSharpS = default(aSharpS, 0.5)
aWThresh = default(aWThresh,0.75)
wide =     default( wide, false )
overshoot= default( overshoot, 1)
overshoot= overshoot<0 ? 0 : overshoot
soft =     default( soft, false )
edgemode = default( edgemode, 0 )
special =  default( special, false )
exborder = default( exborder, 0)

xxs=round(ox*ss_x/8)*8
yys=round(oy*ss_y/8)*8
smx=exborder==0?dest_x:round(dest_x/Exborder/4)*4
smy=exborder==0?dest_y:round(dest_y/Exborder/4)*4

clp.isYUY2() ? clp.converttoyv12() : clp

ss_x != 1.0 || ss_y != 1.0 ? last.lanczosresize(xxs,yys) : last
tmp = last

edge = mt_logic( tmp.mt_edge("5 10 5 0 0 0 -5 -10 -5 2",0,255,0,255)
 \           ,tmp.mt_edge("5 0 -5 10 0 -10 5 0 -5 2",0,255,0,255)
 \           ,"max")

edge = sisavs26 ? edge.mt_lut("x range_half / 0.86 ^ range_max *") : edge.mt_lut("x 128 / 0.86 ^ 255 *",use_expr=1)

bright_limit = (soft == true) ? tmp.blur(1.0) : tmp
dark_limit   = bright_limit.mt_inpand()
bright_limit = bright_limit.mt_expand()
dark_limit   = (wide==false) ? dark_limit   : dark_limit  .mt_inflate().mt_deflate().mt_inpand()
bright_limit = (wide==false) ? bright_limit : bright_limit.mt_deflate().mt_inflate().mt_expand()

minmaxavg    = special==false
 \           ? mt_average(bright_limit,dark_limit)
\            : mt_merge(dark_limit,bright_limit,tmp,Y=3,U=-128,V=-128)

Str=string(float(strength)/100.0)

normsharp = Smode==1 ? unsharpmask(strength,radius,0)
 \             : Smode==2 ? sharpen(float(strength)/100.0)
 \             : Smode==3 ? sisavs26 ? mt_lutxy(tmp,minmaxavg,yexpr="x x y - "+Str+" * +",use_expr=1) : mt_lutxy(tmp,minmaxavg,yexpr="x x y - "+Str+" * +")
 \             : asharp(aSharpS,0,0).awarpsharp(3,1,bm=3,cm=0,aWThresh)

OS = string(overshoot)

Lmode == 1 ? sisavs26 ? mt_lutxy( bright_limit, normsharp, yexpr="y x "+OS+" scalef + < y x "+OS+" scalef + ?",use_expr=1) : mt_lutxy( bright_limit, normsharp, yexpr="y x "+OS+" + < y x "+OS+" + ?")
 \         : sisavs26 ? mt_lutxy( bright_limit, normsharp, yexpr="y x "+OS+" scalef + < y x y x - "+OS+" scalef - 1 2 / ^ + "+OS+" + ?") : mt_lutxy( bright_limit, normsharp, yexpr="y x "+OS+" + < y x y x - "+OS+" - 1 2 / ^ + "+OS+" + ?")

Lmode == 1 ? sisavs26 ? mt_lutxy( dark_limit,   last,      yexpr="y x "+OS+" scalef - > y x "+OS+" scalef - ?",use_expr=1) : mt_lutxy( dark_limit,   last,      yexpr="y x "+OS+" - > y x "+OS+" - ?")
 \         : sisavs26 ? mt_lutxy( dark_limit,   last,      yexpr="y x "+OS+" scalef - > y x x y - "+OS+" scalef - 1 2 / ^ - "+OS+" - ?") : mt_lutxy( dark_limit,   last,      yexpr="y x "+OS+" - > y x x y - "+OS+" - 1 2 / ^ - "+OS+" - ?")


edgemode==0 ? NOP()
 \          : edgemode==1
 \            ? mt_merge(tmp,last,edge.mt_inflate().mt_inflate().blur(1.0),Y=3,U=1,V=1)
 \            : mt_merge(last,tmp,edge.mt_inflate().mt_inflate().blur(1.0),Y=3,U=1,V=1)

     (ss_x != 1.0 || ss_y != 1.0)
\ || (dest_x != ox || dest_y != oy) ? lanczosresize(dest_x,dest_y) : last

ex=blankclip(last,width=smx,height=smy,color=$FFFFFF).addborders(2,2,2,2).coloryuv(levels="TV->PC")
 \.blur(1.3).mt_inpand().blur(1.3).bicubicresize(dest_x,dest_y,1.0,.0)
 
tmp=clp.lanczosresize(dest_x,dest_y)

!(clp.isYUY2()) ? ( exborder==0 ? tmp.mergeluma(last)
 \                           : mt_merge(tmp,last,ex,Y=3,U=1,V=1) )
 \              : ( exborder==0 ? tmp.mergeluma(last.converttoyuy2())
 \                           : tmp.mergeluma( mt_merge(tmp.converttoyv12(),last,ex,Y=3,U=1,V=1)
 \                                           .converttoyuy2()) )
 
return last
}