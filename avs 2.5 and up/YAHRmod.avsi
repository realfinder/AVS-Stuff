# YAHR's functions 2021-03-16

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

function YAHRmask(clip clp, int "expand", int "warpdepth", int "blur", bool "useawarp4", clip "yahrc", int "warpdepthV", int "blurV") {
sisavs26 = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
sischbd = sisphbd ? clp.BitsPerComponent() > 8 : false

sislumaonly = sisphbd ? clp.isy() : sisavs26 ? clp.isy8() : true
input = sislumaonly ? clp : sisphbd ? clp.converttoy() : clp.converttoy8()

    expand = Default(expand,     5)
    warpde = Default(warpdepth, 32)
    blur   = Default(blur,       2)
    
    yahrc  = defined(yahrc) ? yahrc : input.YAHR2(warpde, blur, useawarp4, warpdepthV, blurV)
    yahrc  = sisphbd ? yahrc.isy() ? yahrc : yahrc.converttoy() : sisavs26 ? yahrc.isy8() ? yahrc.converttoy8() : yahrc : yahrc
    
    input
    vEdge = sischbd ? mt_lutxy(last, mt_expand().mt_expand(),"x y - abs 8 scalef - 128 *", use_expr=1) : mt_lutxy(last, mt_expand().mt_expand(),"x y - abs 8 - 7 <<")
    expand = expand*2
#    hbdex = sischbd ? round(expand*2) : nop()
#    vmask = sischbd ? vEdge.sh_Padding(hbdex,hbdex,hbdex,hbdex).GBlur(hbdex,sqrt(expand),false,false).crop(hbdex,hbdex,-hbdex,-hbdex).mt_lut("x 16 *", use_expr=2) : vEdge.binomialblur(expand, u=1, v=1).mt_lut("x 4 <<")
    vmask = sisavs26 ? vEdge.FastBlur(sqrt(expand),iterations=2,gamma=false,threads=1).mt_lut("x 16 *", use_expr=2) : vEdge.binomialblur(expand, u=1, v=1).mt_lut("x 4 <<")
    
    mt_merge(yahrc, vmask.mt_logic(vEdge.removegrain(12, -1).mt_invert(), "min"), true)
	sislumaonly ? last : sisphbd ? CombinePlanes(last,clp,planes="YUV",sample_clip=clp) : ytouv(clp.utoy8(),clp.vtoy8(),last)
}