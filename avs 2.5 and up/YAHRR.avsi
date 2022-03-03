# Y'et A'nother H'alo R'inging R'educing script, based on YAHR
# 1.00
function YAHRR( clip clp, float "radius", float "radiusV", float "p", val "customfix" )
{
cfd       = defined(customfix)
    b1    = clp.minblur(2).removegrain(12,-1)
    b1D   = mt_makediff(clp,b1)
    w1    = cfd ? isclip(customfix) ? customfix : eval(customfix) : clp.srgauss(radius, radiusV, p, false)
    w1b1  = w1.minblur(2,1).removegrain(11,-1)
    w1b1D = mt_makediff(w1,w1b1)
    DD    = b1D.repair(w1b1D,13)
    DD2   = mt_makediff(b1D,DD)
    clp.mt_makediff(DD2,U=2,V=2)
}