# YAHR's functions 2020-09-06

# Y'et A'nother H'alo R'educing script

function YAHR(clip clp)
{
b1    = clp.minblur(2).removegrain(11,-1)
b1D   = mt_makediff(clp,b1)
w1    = clp.aWarpSharp(depth=32,blurlevel=2,thresh=0.5)
w1b1  = w1.minblur(2,1).removegrain(11,-1)
w1b1D = mt_makediff(w1,w1b1)
DD    = b1D.repair(w1b1D,13) 
DD2   = mt_makediff(b1D,DD)
clp.mt_makediff(DD2,U=2,V=2)
}


# Y'et A'nother H'alo R'educing script
# YAHR A.SONY mod 1.38, original YAHR was by Didée
# good deHalo for modern DVD and other cases

function YAHR2(clip clp, int "depth", int "blur", bool "useawarp4", int "depthV", int "blurV")
{

depth         = Default(depth, 8)
useawarp4     = Default(useawarp4, false)
threads       = sh_GetUserGlobalIMTint()

blur = defined(blurV) && !defined(blur) ? depth==0 ? 0 : blur : blur

defined(depthV) ? depthV != 0 && depth==0 ? eval("blurV=defined(blurV) ? blurV : blur Chr(3) blur=defined(blur) ? blur : 0") : depthV==0 && depth != 0 ? eval("blurV=defined(blurV) ? blurV : 0") : nop() : nop()

awarp_params = defined(depthV) ? ",depthV=" + string(depthV) : ""
awarp_params = defined(blurV) ? awarp_params + ",blurV=" + string(blurV) : defined(depthV) ? depthV==0 ? ",blurV=0" : awarp_params : awarp_params
awarp_params = defined(threads) ? awarp_params + ",threads=" + string(threads) : awarp_params

b1    = clp.minblur(2).removegrain(11,-1)
b1D   = mt_makediff(clp,b1)
w1    = useawarp4 ? clp.aWarpSharp4xx(depth=depth,blur=blur,chroma=1,useawarp4=true,depthV=depthV,blurV=blurV,threads=threads) : eval("clp.aWarpSharp2(depth=depth,blur=blur,chroma=1" + awarp_params + ")")
w1b1  = w1.minblur(2,1).removegrain(11,-1)
w1b1D = mt_makediff(w1,w1b1)
DD    = b1D.repair(w1b1D,13) 
DD2   = mt_makediff(b1D,DD)
clp.mt_makediff(DD2,U=2,V=2)
}


function YAHR3(clip src, int "depth", int "radius", int "blur", bool "useawarp4", int "depthV", int "blurV", bool "honly", bool "lumaonly")
{
depth         = Default(depth, 32)
radius        = Default(radius, 6)
src
edgm = EMask_dhh(ColorYUV(autogain=true), 3, 140,true,honly=honly,lumaonly=lumaonly)
hfil = YAHR2(depth=depth,blur=blur,useawarp4=useawarp4,depthV=depthV,blurV=blurV)
RM2  = spasses(edgm.mt_inflate(),radius,"mt_expand()").mt_inflate()
DeRinging = mt_Merge(hfil, src, edgm.mt_inflate(155,155))
mt_Merge(src, DeRinging, RM2, u=2, v=2)
}


# YAHRmask, by Tophf
# With slight modifications (merging both functions into one). Output should be identical.

function YAHRmask(clip input, int "expand", int "warpdepth", int "blur", bool "useawarp4", clip "yahr", int "warpdepthV", int "blurV") {

    expand = Default(expand,     5)
    warpde = Default(warpdepth, 32)
    blur   = Default(blur,       2)
    
    yahr  = defined(yahr) ? yahr : input.YAHR2(warpde, blur, useawarp4, warpdepthV, blurV)
    
    input
    vEdge = mt_lutxy(last, mt_expand().mt_expand(),"x y - abs 8 - 7 <<")
    
    mt_merge(yahr, vEdge.binomialblur(expand*2, u=1, v=1)
    \ .mt_lut("x 4 <<")
    \ .mt_logic(vEdge.removegrain(12, -1)
    \ .mt_invert(), "min"), true)
}