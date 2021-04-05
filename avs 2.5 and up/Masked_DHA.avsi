# 2021.04.05
# Masked_DHA with high bit support, need masktools 2.2.17 or up in avs26 and avs+

function Masked_DHA(clip input, float "rx", float "ry", float "darkstr", float "brightstr", float "lowsens", float "highsens", float "msk_pull", float "msk_push", float "ss", bool "show_msk", bool "cs", int "search_rade", int "search_radi")
{
rx        = default( rx,         2.0 )
rxup      = rx < 0
rx        = abs(rx)
ry        = default( ry,         2.0 )
ryup      = ry < 0
ry        = abs(ry)
darkstr   = default( darkstr,    1.0 )
brightstr = default( brightstr,  1.0 )
lowsens   = default( lowsens,     50 )
highsens  = default( highsens,    50 )
msk_pull  = default( msk_pull,    48 )
msk_push  = default( msk_push,   192 )
ss        = default( ss,         1.5 )
show_msk  = default( show_msk, false )
cs        = default( cs,       false )
sre       = default( search_rade,  1 )
sri       = default( search_radi, sre )

rx        = max(rx, 1.0)
ry        = max(ry, 1.0)
darkstr   = max(min(darkstr, 1.0), 0.0)
lowsens   = max(min(lowsens, 100), 0)
highsens  = max(min(highsens, 100), 0)
msk_pull  = max(min(msk_pull, 254), 0)
msk_push  = max(min(msk_push, 255), msk_pull + 1)
ss        = max(ss, 1.0)

sisphbd = AvsPlusVersionNumber > 2294

sisavs26 = !(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : !sisavs26 ? true : input.isy8()
 
clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

LOS = string(lowsens)
HIS = string(highsens/100.0)
DRK = string(darkstr)
BRT = string(brightstr)
MPL = string(msk_pull)
MPS = string(msk_push)
ox  = clp.width()
oy  = clp.height()

# Parameters that can only be adjusted from within the script
mbl = 1.58

sm     = rxup && ryup ? clp.bilinearresize(m4_sh(ox*rx),m4_sh(oy*ry)) : rxup && !ryup ? clp.bilinearresize(m4_sh(ox*rx),oy).bicubicresize(ox,m4_sh(oy/ry)) : !rxup && ryup ? clp.bilinearresize(ox,m4_sh(oy*ry)).bicubicresize(m4_sh(ox/rx),oy) : clp.bicubicresize(m4_sh(ox/rx),m4_sh(oy/ry))
lg     = rxup && ryup ? sm.bilinearresize(ox,oy) : rxup && !ryup ? sm.bilinearresize(ox,m4_sh(oy/ry)).bicubicresize(m4_sh(ox*rx),oy,1,0) : !rxup && ryup ? sm.bilinearresize(m4_sh(ox/rx),oy).bicubicresize(ox,m4_sh(ox*rx),1,0) : sm.bicubicresize(ox,oy,1,0)
chl    = !sisavs26 ? mt_lutxy(clp.spasses(sre,"mt_expand()"),clp.spasses(sri,"mt_inpand()"),"x y -","x y -","x y -") : mt_lutxy(clp.spasses(sre,"mt_expand()"),clp.spasses(sri,"mt_inpand()"),"x y -", use_expr=3)
lhl    = !sisavs26 ? mt_lutxy(lg.spasses(sre,"mt_expand()"),lg.spasses(sri,"mt_inpand()"),"x y -","x y -","x y -") : mt_lutxy(lg.spasses(sre,"mt_expand()"),lg.spasses(sri,"mt_inpand()"),"x y -", use_expr=3)
mask_i = !sisavs26 ? mt_lutxy(lhl,chl,"y x - y 0.001 + / 255 * "+LOS+" - y 256 + 512 / "+HIS+" + *" )
         \                     : mt_lutxy(lhl,chl,"y x - y 0.001 + / range_max * "+LOS+" scalef - y range_size + 512 scalef / "+HIS+" + *", scale_inputs="floatf", clamp_float=true, use_expr=1 )

mask_f = !sisavs26 ? mt_lutxy(sm.mt_expand,sm.mt_inpand,"x y - 4 *") : mt_lutxy(sm.mt_expand,sm.mt_inpand,"x y - 4 *",use_expr=1)
mask_f = !sisavs26 ? mask_f.blur(mbl).bicubicresize(ox,oy,1.0,0).mt_lut(yExpr="255 255 "+MPL+" - 255 "+MPS+" - - / x "+MPL+" - *")
         \                     : mask_f.blur(mbl).bicubicresize(ox,oy,1.0,0).mt_lut(yExpr="range_max range_max "+MPL+" scalef - range_max "+MPS+" scalef - - / x "+MPL+" scalef - *", scale_inputs="floatf", clamp_float=true, use_expr=2)

mmg    = mt_merge(lg,clp,mask_i)
ssc    = (ss==1.0) ? clp.repair(mmg,1,0)
          \        : clp.spline64resize(m4_sh(ox*ss),m4_sh(oy*ss))
          \             .mt_logic(mmg.mt_expand().bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)),"min",U=2,V=2)
          \             .mt_logic(mmg.mt_inpand().bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)),"max",U=2,V=2)
          \             .spline64resize(ox,oy)
umfc   = !sisavs26 ? mt_lutxy(clp,ssc,"x y < x x y - "+DRK+" * - x x y - "+BRT+" * - ?",U=2,V=2)
         \                     : mt_lutxy(clp,ssc,"x y < x x y - "+DRK+" * - x x y - "+BRT+" * - ?",use_expr=1,U=2,V=2)
mfc    = mt_merge(clp,umfc,mask_f,U=2,V=2)

bb   = cs ? mfc.removegrain(11) : nop()
xD   = cs ? mt_makediff(bb,bb.repair(bb.repair(bb.medianblur(2,-333,-333),1),1)) : nop()
xD   = cs ? !sisavs26 ? xD.mt_lut("x 128 - 2.49 * 128 +") : xD.mt_lut("x range_half - 2.49 * range_half +",use_expr=1) : xD
xDD  = cs ? !sisavs26 ? mt_lutxy(xD,mt_makediff(clp,mfc),"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?")
            \                     : mt_lutxy(xD,mt_makediff(clp,mfc),"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?", use_expr=1) : nop()
mfc  = cs ? mfc.mt_adddiff(xDD,U=2,V=2) : mfc

mfc    = sislumaonly ? mfc : sisphbd ? CombinePlanes(mfc,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),mfc)

return(show_msk ? mask_f : mfc)
}