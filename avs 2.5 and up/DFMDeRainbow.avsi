# Last updated: 2020/06/01
#
# By Scintilla, with the third line of themask's definition
# borrowed from Shodan's derainbower
#
###################
#
# Syntax: 
# DFMDeRainbow(clip org, int "maskthresh", bool "mask", bool "interlaced")
#
# Requires any YUV input.  Is kinda slow.
# Suggestions for improvement welcome: scintilla@aquilinestudios.org
#
# Required plugins:
# MSharpen, MaskTools, FluxSmooth, Deen
#
# Arguments:
# maskthresh (default=10) - This is MSharpen's threshold value.
#	Lower values will increase the area in which the blurred chroma
#	is allowed to come through, which catches more edges but may
#	cause desaturation and/or chroma bleeding.
#	Set this as high as you can while still catching all the edges
#	that need to be derainbowed.
# mask (default=false) - When true, this displays the mask instead of
#	the image.  Use this to find the optimal value of maskthresh.
#
###################

function DFMDeRainbow(clip org, int "maskthresh", bool "mask", bool "interlaced", bool "mc", bool "use_Flux5framesT")
{
Assert(org.IsYUV(),"DFMDeRainbow: YUV input only")
sisavs26   = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? org.isy() : sisavs26 ? org.isy8() : false
Assert(!sislumaonly, "DFMDeRainbow: not work with Greyscale video")

maskthresh = default(maskthresh, 10)
mask       = default(mask, false)
interlaced = default(interlaced, false)
mc         = default(mc, false)
uFlux5     = default(use_Flux5framesT, false)

sisfield = org.IsFieldBased()
org = interlaced==true? org.separatefields() : org
sisfield2 = interlaced || sisfield

org_u=sisphbd ? org.ExtractU() : sisavs26 ? org.UtoY8() : org.UtoY()
org_v=sisphbd ? org.ExtractV() : sisavs26 ? org.VtoY8() : org.VtoY()

org_ue=sisfield2 ? org_u.selecteven() : org_u
org_uo=sisfield2 ? org_u.selectodd() : nop()

org_ve=sisfield2 ? org_v.selecteven() : org_v
org_vo=sisfield2 ? org_v.selectodd() : nop()

fluxtstr = mc ? "DFMDeRainbow_FluxsmoothSTMC(17, -1,chroma=false)" : "FluxSmoothT(17"+string(sisavs26 ? ",chroma=false" : "")+")"
fluxststr = mc ? "DFMDeRainbow_FluxsmoothSTMC(17, 14,chroma=false)." : "FluxSmoothST(17,14"+string(sisavs26 ? ",chroma=false" : "")+")."
flux5str = mc ? "Flux5framesTMC(17,chromamotion=false)" : "Flux5framesTfast(17,chromamotion=false)"

first_u=sisfield2 ? eval("interleave(org_ue."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5),org_uo."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5))")
                \ : eval("org_ue."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5)")
first_v=sisfield2 ? eval("interleave(org_ve."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5),org_vo."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5))")
                \ : eval("org_ve."+string(uFlux5 ? flux5str : fluxtstr)+".Blur(1.5)")

themask=subtract(org,YtoUV(first_u,first_v,org)).Levels(108,1,148,0,255)
	\ .svsMSharpen(mask=true,threshold=maskthresh).Invert()
	\ .Blur(0.5).Levels(0,2,255,0,255).Blur(0.5)

fixed_u=sisfield2 ? eval("interleave(org_ue."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0), org_uo."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0))")
                \ : eval("org_ue."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0)")
		  
fixed_v=sisfield2 ? eval("interleave(org_ve."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0), org_vo."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0))")
                \ : eval("org_ve."+string(uFlux5 ? fluxststr + flux5str : fluxststr + fluxtstr)+".sminiDeen(4,14,14,u=1,v=1).Blur(1.0)")

fixed=YtoUV(fixed_u,fixed_v,org)

output=mt_Merge(fixed,org,themask,y=2,u=3,v=3)

show = mask ? themask : interlaced ? output.weave() : output
  
return show
}

Function DFMDeRainbow_FluxsmoothSTMC(clip clp, int "tthr", int "sthr", bool "chroma")
{

sisavs26   = !(VersionNumber() < 2.6)

tthr = default( tthr, 12 )
sthr = default( sthr, 12 )

super = clp.MSuper(pel=2, sharp=1)

bv1  = manalyse(super,isb=true, truemotion=false, delta=1,blksize=16,overlap=8,chroma=chroma)
fv1  = manalyse(super,Isb=false, truemotion=false, delta=1,blksize=16,overlap=8,chroma=chroma)

bc1  = mcompensate(clp, super,bv1)
fc1  = mcompensate(clp, super,fv1)

result=sisavs26 ? sthr==-1 ? interleave(fc1, clp, bc1).FluxSmoothT(tthr,chroma=chroma).selectevery(3,1) : interleave(fc1, clp, bc1).FluxSmoothST(tthr,sthr,chroma=chroma).selectevery(3,1)
              \ : sthr==-1 ? interleave(fc1, clp, bc1).FluxSmoothT(tthr).selectevery(3,1) : interleave(fc1, clp, bc1).FluxSmoothST(tthr,sthr).selectevery(3,1)

Return(result)
}


# Median2 g-force 
Function Median2(clip "input_1", clip "input_2", clip "input_3", clip "input_4", clip "input_5", string "chroma", bool "chromamotion")
{# median of 5 clips from Helpers.avs by G-force

chromamotion = default(chromamotion, true)
chroma = default(chroma, (chromamotion == true) ? "process" : "copy first") #default is "process". Alternates: "copy first" or "copy second"

#MEDIAN(i1,i3,i5)
Interleave(input_1,input_3,input_5)
chroma == "process" ? Clense() : Clense(grey=true)
#chroma == "process" ? MedianBlurT(0,0,0,1).merge(last,0.5).MedianBlurT(0,0,0,1) : MedianBlurT(0,-1,-1,1).merge(last,0.5).MedianBlurT(0,-1,-1,1)
m1 = selectevery(3,1)

#MAX(MIN(i1,i3,i5),i2)
m2  = input_1.MT_Logic(input_3,"min",chroma=chroma).MT_Logic(input_5,"min",chroma=chroma).MT_Logic(input_2,"max",chroma=chroma)

#MIN(MAX(i1,i3,i5),i4)
m3  = input_1.MT_Logic(input_3,"max",chroma=chroma).MT_Logic(input_5,"max",chroma=chroma).MT_Logic(input_4,"min",chroma=chroma)

Interleave(m1,m2,m3)
chroma == "process" ? Clense() : Clense(grey=true)
#chroma == "process" ? MedianBlurT(0,0,0,1).merge(last,0.5).MedianBlurT(0,0,0,1) : MedianBlurT(0,-1,-1,1).merge(last,0.5).MedianBlurT(0,-1,-1,1)
selectevery(3,1)

chroma == "copy first" ? last.MergeChroma(input_1) : chroma == "copy second" ? last.MergeChroma(input_2) : last

Return(last)
}

function TMedian2(clip c, bool "chromamotion")
{
Median2( c.selectevery(1,-2), c.selectevery(1,-1), c, c.selectevery(1,1), c.selectevery(1,2), chromamotion=chromamotion )
}

function Flux5framesT(clip c, int "th", int "thC", bool "chromamotion")
{
sisavs26   = !(VersionNumber() < 2.6)
chromamotion = default(chromamotion, true)
th  = default(th,7)
thC = default(thC, (chromamotion == true) ? th : 0)
med  = c.TMedian2(chromamotion=chromamotion)
avg  = c.temporalsoften(2,th,thC,24,2)
medD = mt_makediff(c,med,U=chromamotion?3:1,V=chromamotion?3:1)
avgD = mt_makediff(c,avg,U=chromamotion?3:1,V=chromamotion?3:1)
DD   = sisavs26 ? mt_lutxy(medD,avgD,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",use_expr=1,U=chromamotion?3:1,V=chromamotion?3:1) : mt_lutxy(medD,avgD,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?",U=chromamotion?3:1,V=chromamotion?3:1)
output = c.mt_makediff(DD,U=chromamotion?3:1,V=chromamotion?3:1)
return output
}


function Flux5framesTMC(clip c, int "th", int "thC", bool "chromamotion", bool "fast") {

fast = default(fast, true)
super = c.MSuper(pel=2, sharp=1)

bv2  = manalyse(super,isb=true, truemotion=false, delta=2,blksize=16,overlap=8, chroma=chromamotion)
bv1  = manalyse(super,isb=true, truemotion=false, delta=1,blksize=16,overlap=8, chroma=chromamotion)
fv1  = manalyse(super,Isb=false, truemotion=false, delta=1,blksize=16,overlap=8, chroma=chromamotion)
fv2  = manalyse(super,Isb=false, truemotion=false, delta=2,blksize=16,overlap=8, chroma=chromamotion)

bc2  = mcompensate(c, super,bv2)
bc1  = mcompensate(c, super,bv1)
fc1  = mcompensate(c, super,fv1)
fc2  = mcompensate(c, super,fv2)

result=fast ? interleave(fc2, fc1, c, bc1, bc2).Flux5framesTfast(th, thC, chromamotion).selectevery(5,2) : interleave(fc2, fc1, c, bc1, bc2).Flux5framesT(th, thC, chromamotion).selectevery(5,2)

Return(result)
}

function Flux5framesTfast(clip c,int "th",int "thC",bool "chromamotion")
{
sisavs26   = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
chromamotion = default(chromamotion, true)
sislumaonly = sisphbd ? c.isy() : sisavs26 ? c.isy8() : false
u=sislumaonly ? nop() : sisphbd ? c.ExtractU() : sisavs26 ? c.utoy8() : c.utoy()
v=sislumaonly  ? nop() : sisphbd ? c.ExtractV() : sisavs26 ? c.vtoy8() : c.vtoy()
y=sislumaonly ? c : sisphbd ? c.ExtractY() : sisavs26 ? c.converttoy8() : c
	th  = default(th, 7)
	thC = default(thC, chromamotion ? th : 0)
	med = sislumaonly ? y.median5t() : sisavs26 ? ytouv(chromamotion ? u.median5t() : u, chromamotion ? v.median5t() : v, y.median5t()) : y.median5t().mergechroma(c)
	avg = c.temporalsoften(2, th, thC, 24, 2)
	output = interleave(c, med, avg).clense(grey=!chromamotion).selectevery(3,1)
	return output
}

function median5t(clip src)
{
	function clmin(clip a, clip b) {return mt_logic(a, b, mode="min")}
	function clmax(clip a, clip b) {return mt_logic(a, b, mode="max")}
	src
	last + trim(framecount()-1,-1).loop(5)
	bcmin = clmin(SelectEvery(2, -1), SelectEvery(2, 0))
	bcmax = clmax(SelectEvery(2, -1), SelectEvery(2, 0))
	demin = bcmin.SelectEvery(1, 1)
	demax = bcmax.SelectEvery(1, 1)
	x = clmax(bcmin, demin)
	y = clmin(bcmax, demax)
	a = SelectEvery(2, -2)
	f = SelectEvery(2, 3)
	Interleave(a, x, y, f).Clense(grey=true).SelectEvery(4, 1, 2)
	trim(0,length=src.framecount())
}