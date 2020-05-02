#####################################################
#                                                   #
# LUTDeRainbow, a derainbowing script by Scintilla  #
# Last updated 5/02/20                              #
#                                                   #
#####################################################
#
# Syntax:
# LUTDeRainbow(clip input, float "cthresh", float "ythresh", bool "y",
#	\ bool "linkUV", bool "mask")
#
# Requires Planar YUV input.
# Is of reasonable speed (faster than aWarpSharp, slower than DeGrainMedian).
# Suggestions for improvement welcome: scintilla@aquilinestudios.org
#
# Required plugins:
# MaskTools 2.0 (MT_MaskTools)
#
# Arguments:

# cthresh (default=10) - This determines how close the chroma values of the
#	pixel in the previous and next frames have to be for the pixel to
#	be hit.  Higher values (within reason) should catch more rainbows,
#	but may introduce unwanted artifacts.  Probably shouldn't be set
#	above 20 or so.
#
# ythresh (default=10) - If the y parameter is set true, then this
#	determines how close the luma values of the pixel in the previous
#	and next frames have to be for the pixel to be hit.  Just as with
#	cthresh.
#
# y (default=true) - Determines whether luma difference will be considered
#	in determining which pixels to hit and which to leave alone.
#
# linkUV (default=true) - Determines whether both chroma channels are
#	considered in determining which pixels in each channel to hit.
#	When set true, only pixels that meet the thresholds for both U and
#	V will be hit; when set false, the U and V channels are masked
#	separately (so a pixel could have its U hit but not its V, or vice
#	versa).
#
# mask (default=false) - When set true, the function will return the mask
#	(for combined U/V) instead of the image.  Formerly used to find the
#	best values of cthresh and ythresh.  If linkUV=false, then this
#	mask won't actually be used anyway (because each chroma channel
#	will have its own mask).
#
###################
#
# Changelog:
#
# 6/23/05: Is this thing on?
# 6/24/05: Replaced whole mask mechanism; new mask checks to see that BOTH channels
# 	of the chroma are within the threshold from previous frame to next
# 7/1/05: Added Y option, to take luma into account when deciding whether to use the
#	averaged chroma; added ythresh and cthresh parameters, to determine how close
#	the chroma/luma values of a pixel have to be to be considered the same
#	(y=true is meant to cut down on artifacts)
# 9/2/05: Suddenly realized this wouldn't work for YUY2 and made it YV12 only;
#	added linkUV option, to decide whether to use a separate mask for each chroma
#	channel or use the same one for both.
# 10/3/08: Fixed "cthresh" typos in documentation; killed repmode since I realized I
#	wasn't using Repair anymore; finally upgraded to MaskTools 2.
# 4/20/20: AVS 2.6 Colors and HBD
#
###################


function LUTDeRainbow(clip input, float "cthresh", float "ythresh", bool "y", bool "linkUV", bool "mask", clip "org_minus", clip "org_plus", bool "exmc") {

Assert(input.IsPlanar() && !IsRGB(input), "LUTDeRainbow: Planar YUV input only")

sisavs26=!(VersionNumber() < 2.6)

sisphbd = AvsPlusVersionNumber > 2294

siscfloat	= sisphbd ? IsVideoFloat(input) : false

input = siscfloat ? expr(input, "x", "x 0.5 +", "x 0.5 +") : input

cthresh=default(cthresh,10)
ythresh=default(ythresh,10)
cthr=string(cthresh)
ythr=string(ythresh)
exmc=default(exmc,false)
#repmode=default(repmode,11)
org=input #.SeparateFields()

fullchr = sisphbd ? org.is444() : sisavs26 ? org.isyv24() : false
nochr   = sisphbd ?   org.isy() : sisavs26 ? org.isy8() : false

Assert(!nochr, "LUTDeRainbow: not work with Greyscale video")

sisfield      = input.IsFieldBased()
org_minusd = defined(org_minus)

org_minus=org_minusd ? org_minus : org.Trim(0,-1)+org.Trim(0,org.framecount-2)
org_minus=!org_minusd && sisfield ? org_minus.Trim(0,-1)+org_minus.Trim(0,org.framecount-2) : org_minus
org_plus=defined(org_plus) ? org_plus : org.Trim(sisfield ? 2 : 1,0)+org.Trim(org.framecount-(sisfield ? 2 : 1),0)

org_u=sisphbd ? ExtractU(org) : sisavs26 ? UToY8(org) : UToY(org)
org_v=sisphbd ? ExtractV(org) : sisavs26 ? VToY8(org) : VToY(org)
org_minus_y=sisphbd ? ExtractY(org_minus) : sisavs26 ? ConvertToY8(org_minus) : org_minus.Greyscale()
org_minus_u=sisphbd ? ExtractU(org_minus) : sisavs26 ? UToY8(org_minus) : UToY(org_minus)
org_minus_v=sisphbd ? ExtractV(org_minus) : sisavs26 ? VToY8(org_minus) : VToY(org_minus)
org_plus_y=sisphbd ? ExtractY(org_plus) : sisavs26 ? ConvertToY8(org_plus) : org_plus.Greyscale()
org_plus_u=sisphbd ? ExtractU(org_plus) : sisavs26 ? UToY8(org_plus) : UToY(org_plus)
org_plus_v=sisphbd ? ExtractV(org_plus) : sisavs26 ? VToY8(org_plus) : VToY(org_plus)

average_u=sisavs26 ? mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" scalef < x y + 2 / 0 ?", use_expr=1) : mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" < x y + 2 / 0 ?").Greyscale()
average_v=sisavs26 ? mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" scalef < x y + 2 / 0 ?", use_expr=1) : mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" < x y + 2 / 0 ?").Greyscale()
average_y=sisavs26 ? mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" < 255 0 ?").Greyscale().ReduceBy2()
average_y=!sisavs26 ? average_y : fullchr ? average_y : IsYV411(org) ? average_y.BilinearResize(org_minus_u.width(), org_minus_v.height(), src_left=-1.5) : average_y.BilinearResize(org_minus_u.width(), org_minus_v.height(), src_left=-0.5)

umask=average_u.mt_Binarize(threshold=20,upper=false)
umask=(default(y,true)?mt_Logic(umask,average_y,"and"):umask)
vmask=average_v.mt_Binarize(threshold=20,upper=false)
vmask=(default(y,true)?mt_Logic(vmask,average_y,"and"):vmask)

themask=mt_Logic(average_u.mt_Binarize(threshold=20,upper=false),average_v.mt_Binarize(threshold=20,upper=false),"and")
themask=(default(y,true)?mt_Logic(themask,average_y,"and"):themask)

fixed_u=sisavs26 ? mt_lutxy(exmc ? average_u.selectevery(3, 1) : average_u,org_u,"x y + 2 /", use_expr=1,y=3,u=2,v=2) : mt_lutxy(exmc ? average_u.selectevery(3, 1) : average_u,org_u,"x y + 2 /",y=3,u=2,v=2)
fixed_v=sisavs26 ? mt_lutxy(exmc ? average_v.selectevery(3, 1) : average_v,org_v,"x y + 2 /", use_expr=1,y=3,u=2,v=2) : mt_lutxy(exmc ? average_v.selectevery(3, 1) : average_v,org_v,"x y + 2 /",y=3,u=2,v=2)

output_u=mt_Merge(org_u,fixed_u,exmc ? selectevery(default(linkUV,true)?themask:umask,3, 1) : default(linkUV,true)?themask:umask)#.Repair(org_u,repmode)
output_v=mt_Merge(org_v,fixed_v,exmc ? selectevery(default(linkUV,true)?themask:vmask,3, 1) : default(linkUV,true)?themask:vmask)#.Repair(org_v,repmode)

output=YToUV(output_u,output_v,org)

return (default(mask,false)?themask.PointResize(org.width,org.height):siscfloat?expr(output,"x","x 0.5 -","x 0.5 -"):output)

}