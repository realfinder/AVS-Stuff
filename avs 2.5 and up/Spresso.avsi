# SPresso by Didée, r.f mod in 2020.05.07 for HBD
function SPresso(clip clp, float "limit", float "bias", int "RGmode", float "limitC", float "biasC", int "RGmodeC", bool "HD", int "radius")
{
sisavs26 = !(VersionNumber() < 2.60)
limit   = default( limit,   2 )
limitC  = default( limitC,  4 )
bias    = default( bias,   25 )
biasC   = default( biasC,  50 )
RGmode  = default( RGmode,  4 )
RGmodeC = default( RGmodeC, 0 )
h      = clp.height()
ishd   = h > 720
HD     = default( HD,  ishd )
radius = default( radius,  round(h/540.0) )

yy = (RGmode ==0) ? 2 : 3
uv = (RGmodeC==0) ? 2 : 3
LIM1  = (limit>0) ? string( round(limit*100.0/bias-1.0) ) : string( round(100.0/bias) )
LIM2  = (limit<0) ? "1" : string(limit)
BIA   = string(bias)
LIM1c = (limitC>0) ? string( round(limitC*100.0/biasC-1.0) ) : string( round(100.0/biasC) )
LIM2c = (limitC<0) ? "1" : string(limitC)
BIAc  = string(biasC)

expr  = (limit<0) ?   sisavs26 ? "x y - abs "+LIM1+" scalef < x x 1 x y - x y - abs / * - ?" : "x y - abs "+LIM1+" < x x 1 x y - x y - abs / * - ?"
 \                :   sisavs26 ? "x y - abs 0 <= x x "+LIM1+" scalef + y < x "+LIM2+" scalef + x "+LIM1+" scalef - y > x "+LIM2+" scalef - " \ 
                    + "x 100 scalef "+BIA+" scalef - * y "+BIA+" scalef * + 100 scalef / ? ? ?" \
					           : "x y - abs 0 <= x x "+LIM1+" + y < x "+LIM2+" + x "+LIM1+" - y > x "+LIM2+" - " \ 
                    + "x 100 "+BIA+" - * y "+BIA+" * + 100 / ? ? ?"
exprC = (limit<0) ?   sisavs26 ? "x y - abs "+LIM1c+" scalef < x x 1 x y - x y - abs / * - ?" : "x y - abs "+LIM1c+" < x x 1 x y - x y - abs / * - ?"
 \                :   sisavs26 ? "x y - abs 0 <= x x "+LIM1c+" scalef + y < x "+LIM2c+" scalef + x "+LIM1c+" scalef - y > x "+LIM2c+" scalef - " \ 
                    + "x 100 scalef "+BIAc+" scalef - * y "+BIAc+" scalef * + 100 scalef / ? ? ?" \
					           : "x y - abs 0 <= x x "+LIM1c+" + y < x "+LIM2c+" + x "+LIM1c+" - y > x "+LIM2c+" - " \ 
                    + "x 100 "+BIAc+" - * y "+BIAc+" * + 100 / ? ? ?"

# For (old) MaskTools v1.5.8 :
# yv12lutxy( clp, clp.removegrain(RGmode,RGmodeC), expr,exprC,exprC, Y=yy,U=uv,V=uv)

# For (new) MaskTools v2.x :
sisavs26 ? mt_lutxy( clp, HD ? clp.minblur(radius,uv=uv) : clp.removegrain(RGmode,RGmodeC), yexpr=expr,uexpr=exprC,vexpr=exprC, scale_inputs=limit<0 ? "floatf" : "none", use_expr=1, Y=yy,U=uv,V=uv) : mt_lutxy( clp, HD ? clp.minblur(radius,uv=uv) : clp.removegrain(RGmode,RGmodeC), yexpr=expr,uexpr=exprC,vexpr=exprC, Y=yy,U=uv,V=uv)

return( last )
}