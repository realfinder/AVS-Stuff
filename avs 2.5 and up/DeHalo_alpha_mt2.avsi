# DeHalo_alpha with high bit support, need masktools 2.2.20 or up in avs26 and last avs+
# 2020.01.28

function DeHalo_alpha_mt(clip input, float "rx", float "ry", float "darkstr", float "brightstr", float "lowsens", float "highsens", float "ss", bool "cs", int "search_rade", int "search_radi")
{
sre       = default( search_rade,   1 )
sri       = default( search_radi, sre )
input
DeHalo_alpha_2BD(rx, ry, darkstr, brightstr, lowsens, highsens, ss, cs, sre, sri)
}

function DeHalo_alpha(clip input, float "rx", float "ry", float "darkstr", float "brightstr", float "lowsens", float "highsens", float "ss", bool "cs", int "search_rade", int "search_radi")
{
input
DeHalo_alpha_mt(rx, ry, darkstr, brightstr, lowsens, highsens, ss, cs, search_rade, search_radi)
}

# modified dehalo_alpha: here with increased search-radius for validation

function DeHalo_alpha_2BD(clip input, float "rx", float "ry", float "darkstr", float "brightstr", float "lowsens", float "highsens", float "ss", bool "cs", int "search_rade", int "search_radi")
{
rx        = default( rx,        2.0 )
ry        = default( ry,        2.0 )
darkstr   = default( darkstr,   1.0 )
brightstr = default( brightstr, 1.0 )
lowsens   = default( lowsens,    50 )
highsens  = default( highsens,   50 )
ss        = default( ss,        1.5 )
cs        = default( cs,      false )
sre       = default( search_rade,  max(m4_sh(max(rx,ry)),3) )
sri       = default( search_radi, sre )

sisphbd = AvsPlusVersionNumber > 2294

sisavs26=!(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : sisavs26 ? input.isy8() : true

clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

LOS = string(lowsens)
HIS = string(highsens/100.0)
DRK = string(darkstr)
BRT = string(brightstr)
ox  = clp.width()
oy  = clp.height()

halos  = clp.bicubicresize(m4_sh(ox/rx),m4_sh(oy/ry)).bicubicresize(ox,oy,1,0)
are    = sre==1 && sri==1 ? clp .mt_edge(mode="min/max", thY1=0, thY2=255)  : !sisavs26 ? mt_lutxy(clp  .spasses(sre,"mt_expand()"),clp  .spasses(sri,"mt_inpand()"),"x y -",U=1,V=1) : mt_lutxy(clp  .spasses(sre,"mt_expand()"),clp  .spasses(sri,"mt_inpand()"),"x y -",use_expr=3,U=1,V=1)
ugly   = sre==1 && sri==1 ? halos.mt_edge(mode="min/max", thY1=0, thY2=255) : !sisavs26 ? mt_lutxy(halos.spasses(sre,"mt_expand()"),halos.spasses(sri,"mt_inpand()"),"x y -",U=1,V=1) : mt_lutxy(halos.spasses(sre,"mt_expand()"),halos.spasses(sri,"mt_inpand()"),"x y -",use_expr=3,U=1,V=1)
so     = !!sisavs26 ? mt_lutxy( ugly, are, "y x - y 0.001 + / 255 * "+LOS+" - y 256 + 512 / "+HIS+" + *" )
         \          : mt_lutxy( ugly, are, "y x - y 0.001 + / range_max * "+LOS+" scalef - y range_size + 512 scalef / "+HIS+" + *",clamp_float=true, scale_inputs="floatf",use_expr=1 )
lets   = mt_merge(halos,clp,so,U=1,V=1)
remove = (ss==1.0) ? clp.repair(lets,1,0) 
          \        : clp.lanczosresize(m4_sh(ox*ss),m4_sh(oy*ss))
          \             .mt_logic(lets.mt_expand(U=1,V=1).bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)),"min",U=2,V=2)
          \             .mt_logic(lets.mt_inpand(U=1,V=1).bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)),"max",U=2,V=2)
          \             .lanczosresize(ox,oy)
them   = VersionNumber() < 2.6 ? mt_lutxy(clp,remove,"x y < x x y - "+DRK+" * - x x y - "+BRT+" * - ?",U=2,V=2)
         \                     : mt_lutxy(clp,remove,"x y < x x y - "+DRK+" * - x x y - "+BRT+" * - ?",use_expr=1,U=2,V=2)

bb   = cs ? them.removegrain(11) : nop()
xD   = cs ? mt_makediff(bb,bb.repair(bb.repair(bb.medianblur(2,-333,-333),1),1)) : nop()
xD   = cs ? VersionNumber() < 2.6 ? xD.mt_lut("x 128 - 2.49 * 128 +") : xD.mt_lut("x range_half - 2.49 * range_half +",use_expr=1) : xD
xDD  = cs ? VersionNumber() < 2.6 ? mt_lutxy(xD,mt_makediff(clp,them),"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
            \                     : mt_lutxy(xD,mt_makediff(clp,them),"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",use_expr=1) : nop()
them = cs ? them.mt_adddiff(xDD,U=2,V=2) : them

them   = sislumaonly ? them : sisphbd ? CombinePlanes(them,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),them)

return( them )
}