########################################################
#                                                      #
# LUTDeCrawl, a dot crawl removal script by Scintilla  #
# Created 10/3/08				       #
# Last updated 4/22/20                                 #
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
	          \ float "scnchg", bool "usemaxdiff", bool "mask", clip "org_minus", clip "org_plus", bool "exmc") {

Assert(input.IsPlanar() && !IsRGB(input), "LUTDeCrawl: Planar YUV input only")

sisavs26=!(VersionNumber() < 2.6)

sisphbd = AvsPlusVersionNumber > 2294

siscfloat	= sisphbd ? IsVideoFloat(input) : false

cthresh=default(cthresh,15)
ythresh=default(ythresh,10)
cthr=string(cthresh)
ythr=string(ythresh)
scnchg=default(scnchg,25)
exmc=default(exmc,false)
scb = sisphbd ? BitsPerComponent(input) > 8 ? BitsPerComponent(input) == 10 ? 4 : BitsPerComponent(input) == 12 ? 8 : BitsPerComponent(input) == 14 ? 64 : nop() : nop() : nop()
scnchg = sisphbd ? siscfloat ? scnchg/255.0 : BitsPerComponent(input) > 8 ? BitsPerComponent(input) < 16 ? scnchg*scb : scnchg*256 : scnchg : scnchg
sc=string(scnchg)
maxdiff=default(maxdiff,50)
md=string(maxdiff)
usemaxdiff=default(usemaxdiff,true)
org=siscfloat ? expr(input, "x", "x 0.5 +", "x 0.5 +") : input

fullchr = sisphbd ? org.is444() : org.isyv24()
chr420  = sisphbd ? org.is420() : org.isyv12()
nochr   = sisphbd ?   org.isy() : org.isy8()

Assert(!nochr, "LUTDeCrawl: not work with Greyscale video")

sisfield      = input.IsFieldBased()
org_minusd = defined(org_minus)

org_minus=org_minusd ? org_minus : org.Trim(0,-1)+org.Trim(0,org.framecount-2)
org_minus=!org_minusd && sisfield ? org_minus.Trim(0,-1)+org_minus.Trim(0,org.framecount-2) : org_minus
org_plus=defined(org_plus) ? org_plus : org.Trim(sisfield ? 2 : 1,0)+org.Trim(org.framecount-(sisfield ? 2 : 1),0)

org_y=sisphbd ? ExtractY(org) : sisavs26 ? ConvertToY8(org) : org.Greyscale()
org_minus_y=sisphbd ? ExtractY(org_minus) : sisavs26 ? ConvertToY8(org_minus) : org_minus.Greyscale()
org_minus_u=sisphbd ? ExtractU(org_minus) : sisavs26 ? UToY8(org_minus) : UToY(org_minus)
org_minus_v=sisphbd ? ExtractV(org_minus) : sisavs26 ? VToY8(org_minus) : VToY(org_minus)
org_plus_y=sisphbd ? ExtractY(org_plus) : sisavs26 ? ConvertToY8(org_plus) : org_plus.Greyscale()
org_plus_u=sisphbd ? ExtractU(org_plus) : sisavs26 ? UToY8(org_plus) : UToY(org_plus)
org_plus_v=sisphbd ? ExtractV(org_plus) : sisavs26 ? VToY8(org_plus) : VToY(org_plus)

average_u=sisavs26 ? mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_u,org_plus_u,"x y - abs "+cthr+" < 255 0 ?")
average_v=sisavs26 ? mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(org_minus_v,org_plus_v,"x y - abs "+cthr+" < 255 0 ?")
average_y=sisavs26 ? mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" scalef < x y + 2 / 0 ?", use_expr=1) : mt_lutxy(org_minus_y,org_plus_y,"x y - abs "+ythr+" < x y + 2 / 0 ?")

diffplus_y =  sisavs26 ? mt_lutxy(exmc ? org_plus_y.selectevery(3, 1) : org_plus_y,  org_y, "x y - abs "+md+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(exmc ? org_plus_y.selectevery(3, 1) : org_plus_y,  org, "x y - abs "+md+" < 255 0 ?")
diffminus_y = sisavs26 ? mt_lutxy(exmc ? org_minus_y.selectevery(3, 1) : org_minus_y, org_y, "x y - abs "+md+" scalef < range_max 0 ?", use_expr=1) : mt_lutxy(exmc ? org_minus_y.selectevery(3, 1) : org_minus_y, org, "x y - abs "+md+" < 255 0 ?")
diffs_y = mt_logic(diffplus_y, diffminus_y, "and")

ymask=average_y.mt_Binarize(threshold=0,upper=false)
ymask=usemaxdiff ? mt_logic(ymask, diffs_y, "and") : ymask
cmask=mt_logic(average_u.mt_Binarize(upper=false),average_v.mt_Binarize(upper=false),"and")
cmask=sisavs26 ? fullchr ? cmask : IsYV411(org) ? cmask.BilinearResize(input.width(), input.height(), src_left=1.5) : cmask.BilinearResize(input.width(), input.height(), src_left=0.5) : cmask.PointResize(cmask.Width()*2, cmask.Height()*2)

themask=mt_logic(ymask,cmask,"and")

fixed_y=sisavs26 ? mt_lutxy(exmc ? average_y.selectevery(3, 1) : average_y,org_y,"x y + 2 /", use_expr=1,y=3,u=2,v=2) : mt_lutxy(exmc ? average_y.selectevery(3, 1) : average_y,org_y,"x y + 2 /",y=3,u=2,v=2)

output=mt_Merge(org_y,fixed_y,exmc ? themask.selectevery(3, 1) : themask)
output=MergeChroma(sisavs26 ? YToUV(exmc ? average_u.selectevery(3, 1) : average_u,exmc ? average_v.selectevery(3, 1) : average_v,output) : output,input)
output=ConditionalFilter(input, input, output, "YDifferenceFromPrevious()", ">", sc)
output=ConditionalFilter(input, input, output, "YDifferenceToNext()", ">", sc)

return (default(mask,false)?themask:output)

}