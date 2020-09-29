########################################################
#                                                      #
# LUTDeCrawl, a dot crawl removal script by Scintilla  #
# Created 10/3/08				       #
# Last updated 9/28/20                                 #
#                                                      #
########################################################
#
# Syntax:
# LUTDeCrawl(clip input, int "ythresh", int "cthresh", int "maxdiff",
#	\ int "scnchg", bool "usemaxdiff", bool "mask")
#
# Requires Planar YUV input.
# Is of average speed (faster than VagueDenoiser, slower than HQDN3D).
# Suggestions for improvement welcome: scintilla@aquilinestudios.org
#
# Required plugins:
# MaskTools 2.0 (MT_MaskTools)
#
# Arguments:

# ythresh (default=10) - This determines how close the luma values of the
#	pixel in the previous and next frames have to be for the pixel to
#	be hit.  Higher values (within reason) should catch more dot crawl,
#	but may introduce unwanted artifacts.  Probably shouldn't be set
#	above 20 or so.
#
# cthresh (default=10) - This determines how close the chroma values of the
#	pixel in the previous and next frames have to be for the pixel to
#	be hit.  Just as with ythresh.
#
# maxdiff (default=50) - This is the maximum difference allowed between the
#	luma values of the pixel in the CURRENT frame and in each of its
#	neighbour frames (so, the upper limit to what fluctuations are
#	considered dot crawl).  Lower values will reduce artifacts but may
#	cause the filter to miss some dot crawl.  Obviously, this should
#	never be lower than ythresh.  Meaningless if usemaxdiff = false.
#
# scnchg (default=25) - Scene change detection threshold.  Any frame with
#	total luma difference between it and the previous/next frame greater
#	than this value will not be processed.
#
# usemaxdiff (default=true) - Whether or not to reject luma fluctuations
#	higher than maxdiff.  Setting this to false is not recommended, as
#	it may introduce artifacts; but on the other hand, it produces a
#	30% speed boost.  Test on your particular source.
#
# mask (default=false) - When set true, the function will return the mask
#	instead of the image.  Use to find the best values of cthresh,
#	ythresh, and maxdiff.
#	(The scene change threshold, scnchg, is not reflected in the mask.)
#
###################
#
# Changelog:
#
# 10/3/08: Is this thing on?
# 4/20/20: AVS 2.6 Colors and HBD
#
###################

function LUTDeCrawl(clip input, float "ythresh", float "cthresh", float "maxdiff", 
	          \ float "scnchg", bool "usemaxdiff", bool "mask", clip "org_minus", clip "org_plus", bool "smoothmask") {

Assert(input.IsPlanar() && !IsRGB(input), "LUTDeCrawl: Planar YUV input only")

sisavs26=!(VersionNumber() < 2.6)

sisphbd = AvsPlusVersionNumber > 2294

siscfloat	= sisphbd ? IsVideoFloat(input) : false

org_minusd = defined(org_minus)
org_plusd = defined(org_plus)

sismc = org_minusd && org_plusd

smoothmask=default(smoothmask,sismc)
cthresh=default(cthresh,sismc ? 10 : 15)
ythresh=default(ythresh,10)
cthr=string(cthresh)
ythr=string(ythresh)
scnchg=default(scnchg,sismc ? -2 : 25)
scb = scnchg!=-2 ? sisphbd ? BitsPerComponent(input) > 8 ? BitsPerComponent(input) == 10 ? 4 : BitsPerComponent(input) == 12 ? 8 : BitsPerComponent(input) == 14 ? 64 : nop() : nop() : nop() : nop()
scnchg = scnchg!=-2 ? sisphbd ? siscfloat ? scnchg/255.0 : BitsPerComponent(input) > 8 ? BitsPerComponent(input) < 16 ? scnchg*scb : scnchg*256 : scnchg : scnchg : -2
sc=scnchg!=-2 ? string(scnchg) : nop()
maxdiff=default(maxdiff,sismc ? 100 : 50)
md=string(maxdiff)
usemaxdiff=default(usemaxdiff,true)
mask=default(mask,false)
org=siscfloat ? expr(input, "x", "x 0.5 +", "x 0.5 +") : input

fullchr = sisphbd ? org.is444() : sisavs26 ? org.isyv24() : false
nochr   = sisphbd ?   org.isy() : sisavs26 ? org.isy8() : false

Assert(!nochr, "LUTDeCrawl: not work with Greyscale video")

sisfield      = input.IsFieldBased()

org_minus=org_minusd ? org_minus : org.Trim(0,-1)+org.Trim(0,org.framecount-2)
org_minus=!org_minusd && sisfield ? org_minus.Trim(0,-1)+org_minus.Trim(0,org.framecount-2) : org_minus
org_plus=org_plusd ? org_plus : org.Trim(sisfield ? 2 : 1,0)+org.Trim(org.framecount-(sisfield ? 2 : 1),0)

org_y=sisphbd ? ExtractY(org) : sisavs26 ? ConvertToY8(org) : org.Greyscale()
org_minus_y=sisphbd ? ExtractY(org_minus) : sisavs26 ? ConvertToY8(org_minus) : org_minus.Greyscale()
org_minus_u=sisphbd ? ExtractU(org_minus) : sisavs26 ? UToY8(org_minus) : UToY(org_minus)
org_minus_v=sisphbd ? ExtractV(org_minus) : sisavs26 ? VToY8(org_minus) : VToY(org_minus)
org_plus_y=sisphbd ? ExtractY(org_plus) : sisavs26 ? ConvertToY8(org_plus) : org_plus.Greyscale()
org_plus_u=sisphbd ? ExtractU(org_plus) : sisavs26 ? UToY8(org_plus) : UToY(org_plus)
org_plus_v=sisphbd ? ExtractV(org_plus) : sisavs26 ? VToY8(org_plus) : VToY(org_plus)

diffs_u=smoothmask ? sisavs26 ? mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" scalef < x y - abs "+cthr+" scalef 2 / < range_max range_max range_max "+cthr+" scalef / x y - abs * - ? 0 ?", use_expr=1) : mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" < x y - abs "+cthr+" 2 / < 255 255 255 "+cthr+" / x y - abs * - ? 0 ?") : sisavs26 ? mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" < 255 0 ?")
diffs_v=smoothmask ? sisavs26 ? mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" scalef < x y - abs "+cthr+" scalef 2 / < range_max range_max range_max "+cthr+" scalef / x y - abs * - ? 0 ?", use_expr=1) : mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" < x y - abs "+cthr+" 2 / < 255 255 255 "+cthr+" / x y - abs * - ? 0 ?") : sisavs26 ? mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" < 255 0 ?")

average_y=sisavs26 ? mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" scalef < x y + 2 / 0 ?", use_expr=1) : mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" < x y + 2 / 0 ?")

diffplus_y =  usemaxdiff ? sisavs26 ? mt_lutxy(org_plus_y,  org_y, "x y - abs "+md+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_plus_y,  org, "x y - abs "+md+" < 255 0 ?") : nop()
diffminus_y = usemaxdiff ? sisavs26 ? mt_lutxy(org_minus_y, org_y, "x y - abs "+md+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_y, org, "x y - abs "+md+" < 255 0 ?") : nop()
odiffs_y = usemaxdiff ? mt_logic(diffplus_y, diffminus_y, "and") : nop()

ymask=smoothmask ? sisavs26 ? average_y.mt_lut("x 32 *", use_expr=1, clamp_float=true) : average_y.mt_lut("x 32 *") : average_y.mt_Binarize(threshold=0,upper=false)
ymask=usemaxdiff ? mt_logic(ymask, odiffs_y, "and") : ymask
cmask=mt_logic(diffs_u,diffs_v,"and")
cmask=sisavs26 ? fullchr ? cmask : IsYV411(org) ? cmask.BilinearResize(input.width(), input.height(), src_left=0.375) : cmask.BilinearResize(input.width(), input.height(), src_left=0.25) : cmask.PointResize(cmask.Width()*2, cmask.Height()*2)

themask=mt_logic(ymask,cmask,"and")

fixed_y=mask ? nop() : smoothmask ? average(org_minus_y,0.25,org_y,0.5,org_plus_y,0.25).Repair(org_y) : mt_average(average_y,org_y)

output=mask ? nop() : mt_Merge(org_y,fixed_y,themask,u=1,v=1)
output=mask ? nop() : smoothmask ? mt_Merge(output.sBlackerPixel(output.blur(1.58,0).Sharpen(1,0),maxdiff=maxdiff,averagewithwhiterPixel=true),output,sisavs26 ? mt_lutxyz(output,org_y,themask.blur(1.58,0).Sharpen(1,0),"x y - abs "+md+" scalef 10 / < z 0 ?", use_expr=1) : mt_lutxyz(output,org_y,themask.blur(1.58,0).Sharpen(1,0),"x y - abs "+md+" 10 / < z 0 ?"),u=1,v=1) : output
output=mask ? nop() : MergeChroma(sisavs26 ? YToUV(diffs_u,diffs_v,output) : output,input)
output=mask ? nop() : scnchg!=-2 ? ConditionalFilter(input, input, output, "YDifferenceFromPrevious()", ">", sc) : output
output=mask ? nop() : scnchg!=-2 ? ConditionalFilter(input, input, output, "YDifferenceToNext()", ">", sc) : output

return (mask?themask:output)

}