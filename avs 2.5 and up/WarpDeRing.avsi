# WarpDeRing v1.0 by mirkosp
# HBD mod 1.1
#
# 	Uses aWarpSharp2's flattening to clean out ringing/smaller halos,
# 	then runs some masks to preserve the edges and avoid the thinning.
# 	This is nothing really new but it kind of just works, so eh.
#	Calling the filter more times in a row is probably more effective than toying with the parameters.
#	Only really tested out with a DVD, probably only works as intended on SD sources.
#	For HD, it might need some more mt_expand() in the owarp clip (I don't think, though).
#	Oh, and it's for newer and minor stuff, like downscaled HD sources released only on DVD and so on.
#	Don't expect this to work on Trigun. Or, well, I guess it could work, but... you know the deal.
#
# strength is the warpsharpening depth, so higher values nail more things
# tmax and tmin work out the hysteresis mask for the final masking pass
#
# Requirements:
#
# 	awarpsharp2 http://forum.doom9.org/showthread.php?t=147285
# 	mt_masktools https://github.com/tp7/masktools
# 	nnedi3 http://web.missouri.edu/~kes25c/
# 	fillmargins http://www.avisynth.nl/users/warpenterprises/
#

function warpdering(clip c, int "strength", int "tmax", int "tmin") {
sisavs26 = !(VersionNumber() < 2.60) 
strength = default(strength,6)
tmax = default(tmax,10)
tmin = default(tmin,7)
c 
addborders(4,4,4,4)
fillmargins(4,4,4,4)
warp = awarp4(nnedi3_rpow2(rfactor=2).nnedi3_rpow2(rfactor=2),asobel(thresh=255).ablur(),depth=strength)
owarp = mt_merge(last,warp,sisavs26 ? vsTEdgeMask(threshY=0,threshU=0,threshV=0).mt_expand().mt_expand().mt_expand().mt_expand().mt_expand().blur(1) : tedgemask(valon=-1).mt_expand().mt_expand().mt_expand().mt_expand().mt_expand().blur(1),true,u=3,v=3)
mt_merge(owarp,last,mt_hysteresis(sisavs26 ? vstedgemask(threshy=tmax) : tedgemask(threshy=tmax),sisavs26 ? vstedgemask(threshy=tmin) : tedgemask(threshy=tmin)).blur(1),true,u=3,v=3)
crop(4,4,-4,-4)
}


function warpdering_faster(clip c, int "strength", int "tmax", int "tmin") {
sisphbd = AvsPlusVersionNumber > 2294
sischbd = sisphbd ? c.BitsPerComponent() > 8 : false
strength = default(strength,6)
tmax = default(tmax,10)
tmin = default(tmin,7)
c
addborders(4,4,4,4)
fillmargins(4,4,4,4)
warp = awarp4(nnedi3_rpow2(rfactor=2).Spline36Resize(width*4, height*4, 0.25, 0.25),asobel(thresh=255).ablur(),depth=strength, chroma=1)
owarp = mt_merge(last,warp,sischbd ? vsTEdgeMask(threshY=0,threshU=0,threshV=0, u=1, v=1).mt_expand().mt_expand().mt_expand().mt_expand().mt_expand().blur(1) : TEMmod(threshY=0,chroma=0).mt_expand().mt_expand().mt_expand().mt_expand().mt_expand().blur(1),true,u=1,v=1)
mt_merge(owarp,last,mt_hysteresis(sischbd ? vstedgemask(threshy=tmax, u=1, v=1) : sischbd ? vstedgemask(threshy=tmax, u=1, v=1) : TEMmod(threshy=tmax,chroma=0),TEMmod(threshy=tmin,chroma=0)).blur(1),true,u=1,v=1)
crop(4,4,-4,-4)
Mergechroma(c)
}