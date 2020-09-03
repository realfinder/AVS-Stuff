#Motion-Compensated Anti-aliasing with contra-sharpening by A.SONY
#some ideas was taken from Didée scripts daa and this http://forum.doom9.org/showthread.php?t=153219
#created because when applied daa3 to fixed scenes, it could damage some details and other issues.
# v3.62

function mcdaa3(clip input) {
sup    = input.HQdn3d().sneo_FFT3D().MSuper(pel=2,sharp=1)
fv1    = sup.MAnalyse(isb=false,delta=1,DCT=2,Truemotion=false)
fv2    = sup.MAnalyse(isb=true,delta=1,DCT=2,Truemotion=true)
csaa   = input.daa3mod()
momask1 = input.MMask(fv1, kind = 1, ml=2)
momask2 = input.MMask(fv2, kind = 1, ml=3)
momask = mt_average(momask1,momask2,u=3,v=3)
mt_merge(input,csaa,momask,u=3,v=3)
}


#############################

#Anti-aliasing with contra-sharpening by Didée with some modifications, v3.61

    FUNCTION daa3mod(clip c1, val "slow", int "threads", bool "FDCS") {
avs25 = VersionNumber() < 2.60
isslod = defined(slow)

slow    = default (slow      , true)
isslob = isbool(slow)
issloi = Isint(slow)
Assert(isslob || issloi, "'slow' only accepts bool or int")
slowb  = isslob ? slow : isslod
threads = default (threads, sh_GetUserGlobalIMTint(true))
FDCS = default (FDCS, issloi ? slow > 4 || slow < -4 : false)
sisphbd = AvsPlusVersionNumber > 2294
chr420  = sisphbd ? c1.is420() : input.isyv12()

rescale = slowb && issloi ? slow > -1 : slowb
upsizer = rescale ? issloi ? slow!=0 ? "BilinearResize" : "Spline36Resize" : "Spline36Resize" : nop()
downsizer = slowb ? issloi ? slow!=0 ? "BicubicResize" : "Spline36Resize" : "Spline36Resize" : nop()

c = rescale ? threads!=1 ? Eval("""try { Eval("c1."+upsizer+"mt(c1.width, chr420 ? m4_sh(c1.height*3/2,2) : c1.height*3/2,threads=threads)") } catch(error_msg) { Eval("c1."+upsizer+"(c1.width, chr420 ? m4_sh(c1.height*3/2,2) : c1.height*3/2)") }""") : Eval("c1."+upsizer+"(c1.width, chr420 ? m4_sh(c1.height*3/2,2) : c1.height*3/2)") : c1

    nn      = issloi ? slow > 1 || slow < -2 ? c.sh_Padding(slow==2 || slow==-3 ? 0 : 4,4,slow==2 || slow==-3 ? 0 : 4,4).nnedi3(field=-2,threads=threads).crop(slow==2 || slow==-3 ? 0 : 4,4,slow==2 || slow==-3 ? 0 : -4,-4) : c.nnedi3(field=-2,threads=threads) : c.nnedi3(field=-2,threads=threads)
 c =isyuy2(c) && avs25 ? c.Interleaved2Planar() : isyuy2(c) ? c.converttoyv16() : c
 nn=isyuy2(nn) && avs25 ? nn.Interleaved2Planar() : isyuy2(nn) ? nn.converttoyv16() : nn
    isslow4 = slowb && issloi ? (slow > 3 && slow != 5) || slow < -1 : false
    istof   = isslow4 ? c1.getparity : nop()
    seto    = isslow4 ? istof ? selecteven(nn) : selectodd(nn) : selecteven(nn)
    seto    = isslow4 ? threads!=1 ? Eval("""try { Eval("seto."+downsizer+"mt(c.width, c.height,src_top=-0.5,threads=threads)") } catch(error_msg) { Eval("seto."+downsizer+"(c.width, c.height,src_top=-0.5)") }""") : Eval("seto."+downsizer+"(c.width, c.height,src_top=-0.5)") : seto
    sebo    = isslow4 ? istof ? selectodd(nn) : selecteven(nn) : selectodd(nn)
    sebo    = isslow4 ? threads!=1 ? Eval("""try { Eval("sebo."+downsizer+"mt(c.width, c.height,src_top=0.5,threads=threads)") } catch(error_msg) { Eval("sebo."+downsizer+"(c.width, c.height,src_top=0.5)") }""") : Eval("sebo."+downsizer+"(c.width, c.height,src_top=0.5)") : sebo

    dbl     = mt_average(seto,sebo,U=3,V=3)
    dblD    = FDCS ? nop() : mt_makediff(c,dbl,U=3,V=3)
    shrpD   = FDCS ? nop() : mt_makediff(dbl,dbl.removegrain((width(c)>1100) ? 20 : 11,Planar=true),U=3,V=3)
    DD      = FDCS ? nop() : shrpD.repair(dblD,13,Planar=true)
 fd1 = FDCS ? FineDehalo_contrasharp(dbl,c,1) : dbl.mt_adddiff(DD,U=3,V=3)

 fd2 = rescale ? threads!=1 ? Eval("""try { Eval("fd1."+downsizer+"mt(c1.width, c1.height,threads=threads"+((downsizer!="Spline36Resize") ? ",b=0.3, c=0.2" : "" )+")") } catch(error_msg) { Eval("fd1."+downsizer+"(c1.width, c1.height"+((downsizer!="Spline36Resize") ? ",b=0.3, c=0.2" : "" )+")") }""") : Eval("fd1."+downsizer+"(c1.width, c1.height"+((downsizer!="Spline36Resize") ? ",b=0.3, c=0.2" : "" )+")") : fd1
 fd3 = isyuy2(c1) && avs25 ? fd2.Planar2Interleaved() : isyuy2(c1) ? fd2.converttoyuy2() : fd2
return fd3
}