# STPresso by Didée, MC by SilaSurfer, r.f mod in 2020.08.17 for HBD
function STPresso(clip clp, float "limit", float "bias", int "RGmode", int "tthr", float "tlimit", float "tbias", float "back", bool "mc", bool "HD", int "radius")
{
sisavs26 = !(VersionNumber() < 2.60)
limit  = default( limit,   3 )  # spatial limit:  the spatial part won't change a pixel more than this
bias   = default( bias,   24 )  # bias: the percentage of the spatial filter that will apply
RGmode = default( RGmode,  4 )  # the spatial filter is RemoveGrain, this is its mode
tthr   = default( tthr,   12 )  # temporal threshold for fluxsmooth. Can be set "a good bit bigger" than usually
tlimit = default( tlimit,  3 )  # the temporal filter won't change a pixel more than this
tbias  = default( tbias,  49 )  # the percentage of the temporal filter that will apply
back   = default( back,    1 )  # after all changes have been calculated, reduce all pixel changes by this value. (Shift "back" towards original value)
mc     = default( mc,  false )  # 
h      = clp.height()
ishd   = h > 720
HD     = default( HD,  ishd )  # 
radius = default( radius,  round(h/540.0) )  # 

LIM1  = (limit>0) ? string( round(limit*100.0/bias-1.0) ) : string( round(100.0/bias) )
LIM2  = (limit<0) ? "1" : string(limit)
BIA   = string(bias)
BK = string(back)
TLIM1  = (tlimit>0) ? string( round(tlimit*100.0/tbias-1.0) ) : string( round(100.0/tbias) )
TLIM2  = (tlimit<0) ? "1" : string(tlimit)
TBIA   = string(tbias)

expr  = (limit<0) ?   sisavs26 ? "x y - abs "+LIM1+" scalef < x x 1 x y - x y - abs / * - ?" : "x y - abs "+LIM1+" < x x 1 x y - dup abs / * - ?"
 \                :   sisavs26 ? "x y - abs 1 scalef < x x "+LIM1+" scalef + y < x "+LIM2+" scalef + x "+LIM1+" scalef - y > x "+LIM2+" scalef - " \ 
                    + "x 100 scalef "+BIA+" scalef - * y "+BIA+" scalef * + 100 scalef / ? ? ?" \
					           : "x y - abs 1 < x x "+LIM1+" + y < x "+LIM2+" + x "+LIM1+" - y > x "+LIM2+" - " \ 
                    + "x 100 "+BIA+" - * y "+BIA+" * + 100 / ? ? ?"
texpr  = (limit<0) ?  sisavs26 ? "x y - abs "+TLIM1+" scalef < x x 1 x y - x y - abs / * - ?" : "x y - abs "+TLIM1+" < x x 1 x y - x y - abs / * - ?"
 \                :   sisavs26 ? "x y - abs 1 scalef < x x "+TLIM1+" scalef + y < x "+TLIM2+" scalef + x "+TLIM1+" scalef - y > x "+TLIM2+" scalef - " \ 
                    + "x 100 scalef "+TBIA+" scalef - * y "+TBIA+" scalef * + 100 scalef / ? ? ?" \
					           : "x y - abs 1 < x x "+TLIM1+" + y < x "+TLIM2+" + x "+TLIM1+" - y > x "+TLIM2+" - " \ 
                    + "x 100 "+TBIA+" - * y "+TBIA+" * + 100 / ? ? ?"

bzz = HD ? clp.minblur(radius) : clp.removegrain(RGmode)
sisavs26 ? mt_lutxy( clp, bzz, expr, scale_inputs=limit<0 ? "floatf" : "none", use_expr=1, U=3,V=3) : mt_lutxy( clp, bzz, expr, U=3,V=3)
tthr==0 ? last : sisavs26 ? mt_lutxy(last,last.mt_makediff(mt_makediff(bzz,mc ? bzz.STPresso_FluxsmoothTMC(tthr) : bzz.fluxsmootht(tthr),U=3,V=3),U=3,V=3),texpr,scale_inputs=limit<0 ? "floatf" : "none",use_expr=1,U=3,V=3) : mt_lutxy(last,last.mt_makediff(mt_makediff(bzz,mc ? bzz.STPresso_FluxsmoothTMC(tthr) : bzz.fluxsmootht(tthr),U=3,V=3),U=3,V=3),texpr,U=3,V=3)
back==0 ? last : sisavs26 ? mt_lutxy(last,clp,"x "+BK+" scalef + y < x "+BK+" scalef + x "+BK+" scalef - y > x "+BK+" scalef - y ? ?",U=2,V=2) : mt_lutxy(last,clp,"x "+BK+" + y < x "+BK+" + x "+BK+" - y > x "+BK+" - y ? ?",U=2,V=2)
}


Function STPresso_FluxsmoothTMC(clip clp, int "tthr")
{

tthr = default( tthr, 12 )

super = clp.MSuper(pel=2, sharp=1)

bv1  = manalyse(super,isb=true, truemotion=false, delta=1,blksize=16,overlap=8)
fv1  = manalyse(super,Isb=false, truemotion=false, delta=1,blksize=16,overlap=8)

bc1  = mcompensate(clp, super,bv1)
fc1  = mcompensate(clp, super,fv1)

result=interleave(fc1, clp, bc1).FluxSmoothT(tthr).selectevery(3,1)

Return(result)
}