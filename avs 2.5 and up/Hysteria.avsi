#####################################################
#                                                   #
# Hysteria, a line darkening script by Scintilla    #
# Last updated 2020.04.10                           #
#                                                   #
#####################################################
#
# Syntax:
# Hysteria(clip orig, int "lowthresh", int "highthresh", bool "showmask", \
#	float "strength", bool "usemask", int "luma_cap", int "maxchg")
#
# Requires YV12 input, frame-based only.  Is reasonably fast.
# Suggestions for improvement welcome: scintilla@aquilinestudios.org
#
# Required plugins:
# MaskTools 2.0 (MT_MaskTools)
#
# Arguments:
#
# strength (default=1.0) - This is a multiplicative factor for the amounts
#	by which the pixels are darkened.  Ordinarily, each pixel is
#	darkened by the difference between its luma value and the average
#	luma value of its brighter spatial neighbours.  So if you want more
#	darkening, increase this value.
#
# usemask (default=true) - Whether or not to apply the mask.  If false,
#	the entire image will have its edges darkened instead of just the
#	edges detected in the mask.  Could be useful on some sources
#	(specifically, it will often make dark lines look thicker), but
#	you will probably want to stick to lower values of strength if you
#	choose to go that route.
#
# lowthresh (default=6) - This is the threshold used for the noisy mask.
#	Increase this value if your mask is picking up too much noise
#	around the edges, or decrease it if the mask is not being grown
#	thick enough to cover all of each edge.
#
# highthresh (default=20) - This is the threshold used for the clean mask.
#	Increase this value if your mask is picking up too many weaker
#	edges, or decrease it if the mask is not picking up enough.
#
# luma_cap (default=191) - An idea swiped from FLD/VMToon.  Any pixels
#	brighter than this value will not be darkened at all, no matter
#	what the rest of the parameters are.  This is useful if you have
#	lighter edges that you do not want darkened.  0 will result in
#	no darkening at all, while 255 will turn off the cap.
#
# maxchg (default=255) - No pixel will be darkened by more than this
#	amount, no matter how high you set the strength parameter.
#	This can be useful if you want to darken your weaker lines more
#	without going overboard on the stronger ones.  0 will result in
#	no darkening at all, while 255 (the default) will turn off the
#	limiting.
#
# minchg (default=0) - Another idea swiped from FLD/VMToon (though in
#	those functions it was called "threshold").  Any pixels that
#	would have been darkened by less than this amount will instead
#	not be darkened at all.  This can be useful if you have noise
#	that is getting darkened slightly.  0 (the default) will turn
#	off the thresholding, while 255 will result in no darkening at all.
#
# showmask (default=false) - When true, the function will display the
#	current edge mask plus the chroma from the original image.
#	Use this to find the optimal values of lowthresh and highthresh.
#
###################
#
# Changelog:
#
# 9/11/10: Is this thing on?
# 10/19/16: remove yv12 limit
# 04/10/20: HBD
#
###################


function Hysteria(clip input, float "strength", bool "usemask", float "lowthresh", float "highthresh", \
float "luma_cap", float "maxchg", float "minchg", bool "showmask") {

Assert(input.IsPlanar() && !IsRGB(input), "Hysteria: Planar YUV input only")

sisphbd = AvsPlusVersionNumber > 2294

sisavs26=!(VersionNumber() < 2.6)
sislumaonly = sisphbd ? input.isy() : sisavs26 ? input.isy8() : true

orig = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

lowthresh = Default(lowthresh, 6)
highthresh = Default(highthresh, 20)
showmask = Default(showmask, false)
strength = Default(strength, 1.0)
str = String(strength)
usemask = Default(usemask, true)
luma_cap = Default(luma_cap, 191)
lc = String(luma_cap)
maxchg = Default(maxchg, 255)
lim = String(maxchg)
minchg = Default(minchg, 0)
thr = String(minchg)


noisymask = orig.mt_edge(thy1=lowthresh,thy2=lowthresh,mode="cartoon")
cleanmask = orig.mt_edge(thy1=highthresh,thy2=highthresh,mode="cartoon")
themask = mt_hysteresis(cleanmask,noisymask).mt_inflate().Blur(1.0).Blur(1.0).mt_deflate()

diffs = sisavs26 ? mt_makediff(orig.mt_inflate(u=2,v=2),orig).mt_lut("x range_half - "+str+" *", use_expr=2) : mt_makediff(orig.mt_inflate(u=2,v=2),orig).mt_lut("x 128 - "+str+" *")
darkened = sisavs26 ? mt_lutxy(orig, diffs, "x x "+lc+" scalef > 0 y "+lim+" scalef > "+lim+" scalef y "+thr+" scalef < 0 y ? ? ? -", use_expr=3) : mt_lutxy(orig, diffs, "x x "+lc+" > 0 y "+lim+" > "+lim+" y "+thr+" < 0 y ? ? ? -")

usemask? mt_merge(orig,darkened,themask,u=2,v=2): sisavs26 ? darkened : darkened.MergeChroma(orig)

showmask? sisavs26 ? themask.mt_lut("x 0 - range_max 0 - / range_max 80 scalef - * 80 scalef +", use_expr=2) : themask.Levels(0,1,255,80,255).MergeChroma(orig) : last
return sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)
}