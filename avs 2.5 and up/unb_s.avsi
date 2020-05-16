#.mp4 guy unbt
# 2020.05.16 mod

function unbtmc(clip c, int "taps", int "strong", int "thSAD", clip "prefil", bool "chroma"){

chroma   = default(chroma, false)

exprefil  = defined(prefil)

prefil    = exprefil ? prefil : chroma ? c.MinBlur(3,blurrep=true) : c.Blur(1.5)

masuper = prefil.MSuper()
mcsuper = c.MSuper(levels=1)
 
b1v = MAnalyse(masuper, delta=1, truemotion = true, isb = true, chroma=chroma)
f1v = MAnalyse(masuper, delta=1, truemotion = true, isb = false, chroma=chroma)
 
t3 = c.MCompensate(mcsuper, f1v, thSAD=thSAD)
t1 = c.MCompensate(mcsuper, b1v, thSAD=thSAD)

c.unbt(taps, strong, t1, t3)

}

function unbt(clip c, int "taps", int "strong", clip "t1", clip "t3"){

sisavs26 = !(VersionNumber() < 2.60)

strong = default(strong, 1)

t2s0 = c
t1s0 = defined(t1) ? t1 : c.Trim(0, -1)+c.Trim(0, c.framecount-1)
t3s0 = defined(t3) ? t3 : c.Trim(1, 0)+c.Trim(c.framecount, 0)

smix1 = t2s0.Mt_convolution( Horizontal = " 0 -1 4  -6 10 -17 28 -39 58 -155 618 512 -128 48 -32 23 -14 8 -5 3 -1 ", vertical = " 1 ", u=2, v=2)
smix2 = t2s0.Mt_convolution( Horizontal = " -1 3  -5 8 -14 23 -32 48 -128 512 618 -155 58 -39 28 -17 10 -6 4 -1 ", vertical = " 1 ", u=2, v=2)
smix3 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)
smix4 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " 0 -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)

BasicSpatial = strong >= 1 ? C.unbs(strong=1) : t2s0
tmix1 = average(t2s0, 0.5, t1s0, 0.5)
tmix2 = average(t2s0, 0.5, t3s0, 0.5)


interleave(smix1, smix2, smix3, smix4, tmix1, tmix2, BasicSpatial)
sisavs26 ? MedianBlurTemporal(radiusy=0, radiusu=0, radiusv=0, temporalradius=3) : medianblurt(radiusy=0, radiusu=0, radiusv=0, temporalradius=3, mc=false, calcborder=false, markscenechange=false)
selectevery(7, 3)

return(last)}



function unbs(clip c, int "taps", int "strong"){

sisavs26 = !(VersionNumber() < 2.60)

strong = default(strong, 0)

t2s0 = c

smix1 = t2s0.Mt_convolution( Horizontal = " 0 -1 4  -6 10 -17 28 -39 58 -155 618 512 -128 48 -32 23 -14 8 -5 3 -1 ", vertical = " 1 ", u=2, v=2)
smix2 = t2s0.Mt_convolution( Horizontal = " -1 3  -5 8 -14 23 -32 48 -128 512 618 -155 58 -39 28 -17 10 -6 4 -1 ", vertical = " 1 ", u=2, v=2)
smix3 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)
smix4 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " 0 -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)

BasicSpatial = strong >= 1 ? c.ldd.ldd : t2s0

interleave(smix1, smix2, smix3, smix4, BasicSpatial)
sisavs26 ? MedianBlurTemporal(radiusy=0, radiusu=0, radiusv=0, temporalradius=3) : medianblurt(radiusy=0, radiusu=0, radiusv=0, temporalradius=3, mc=false, calcborder=false, markscenechange=false)
selectevery(5, 2)

return(last)}




function unbs_internal(clip c, int "taps", int "strong"){

sisavs26 = !(VersionNumber() < 2.60)

strong = default(strong, 0)

t2s0 = c

smix1 = t2s0.Mt_convolution( Horizontal = " 0 -1 4  -6 10 -17 28 -39 58 -155 618 512 -128 48 -32 23 -14 8 -5 3 -1 ", vertical = " 1 ", u=2, v=2)
smix2 = t2s0.Mt_convolution( Horizontal = " -1 3  -5 8 -14 23 -32 48 -128 512 618 -155 58 -39 28 -17 10 -6 4 -1 ", vertical = " 1 ", u=2, v=2)
smix3 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)
smix4 = t2s0.Mt_convolution( Horizontal = " 1 ", vertical = " 0 -1 3 -5 8 -14 23 -32 48 -128 512 512 -128 48 -32 23 -14 8 -5 3 -1 ", u=2, v=2)

BasicSpatial = strong >= 1 ? c.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2) : t2s0

interleave(smix1, smix2, smix3, smix4, BasicSpatial)
sisavs26 ? MedianBlurTemporal(radiusy=0, radiusu=0, radiusv=0, temporalradius=3) : medianblurt(radiusy=0, radiusu=0, radiusv=0, temporalradius=3, mc=false, calcborder=false, markscenechange=false)
selectevery(5, 2)

return(last)}





Function LDD(clip c)
{

	Prefiltered = C.unbs_internal#.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Prefiltered_Spatial_Position1 = Prefiltered.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", Vertical = " 1 ", u=2, v=2)
	Prefiltered_Spatial_Position2 = Prefiltered.Mt_convolution( Horizontal = " 1 ", Vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Prefiltered_Temporal_Position_Previous = Prefiltered.Trim(0, -1)+c.Trim(0, c.framecount-1)
	Prefiltered_Temporal_Position1_Next = Prefiltered.Trim(1, 0)+c.Trim(c.framecount, 0)
	
	Prefiltered_Temporal_Filter = Average(Prefiltered, 0.5, Prefiltered_Temporal_Position_Previous, 0.25, Prefiltered_Temporal_Position1_Next, 0.25)
	
	
	Spatial_Position0 = C
	Spatial_Position1 = C.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", Vertical = " 1 ", u=2, v=2)
	Spatial_Position2 = C.Mt_convolution( Horizontal = " 1 ", Vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Temporal_Position_Previous = C.Trim(0, -1)+c.Trim(0, c.framecount-1)
	Temporal_Position1_Next = C.Trim(1, 0)+c.Trim(c.framecount, 0)
	
	Temporal_Filter = Average(C, 0.5, Temporal_Position_Previous, 0.25, Temporal_Position1_Next, 0.25)
	
	
	Difference1 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position1, u=1, v=1)
	Difference2 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position2, u=1, v=1)
	Difference3 = mt_makediff(Prefiltered, Prefiltered_Temporal_Filter, u=1, v=1)
	#Difference4 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position4, u=1, v=1)
	#Difference5 = mt_makediff(Prefiltered, Prefiltered_Temporal_Position_Previous, u=1, v=1)
	#Difference6 = mt_makediff(Prefiltered, Prefiltered_Temporal_Position1_Next, u=1, v=1)
	
Thresh=256
	
	Compare1 = mt_merge(Spatial_Position1, Spatial_Position2, mt_lutxy(Difference1, Difference2, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		Compare1_Prefiltered = mt_merge(Prefiltered_Spatial_Position1, Prefiltered_Spatial_Position2, mt_lutxy(Difference1, Difference2, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	Difference_Step2_1 = mt_makediff(C, Compare1_Prefiltered, u=1, v=1)
	
	Compare2 = mt_merge(Compare1, Temporal_Filter, mt_lutxy(Difference_Step2_1, Difference3, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		Compare2_Prefiltered = mt_merge(Compare1_Prefiltered, Prefiltered_Temporal_Filter, mt_lutxy(Difference_Step2_1, Difference3, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	Difference_Step2_2 = mt_makediff(C, Compare2_Prefiltered, u=1, v=1)
	
	#Compare3 = mt_merge(Compare2, Spatial_Position4, mt_lutxy(Difference_Step2_2, Difference4, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare3_Prefiltered = mt_merge(Compare2_Prefiltered, Prefiltered_Spatial_Position4, mt_lutxy(Difference_Step2_2, Difference4, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_3 = mt_makediff(C, Compare3_Prefiltered, u=1, v=1)
	
	#Compare4 = mt_merge(Compare3, Temporal_Position_Previous, mt_lutxy(Difference_Step2_3, Difference5, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare4_Prefiltered = mt_merge(Compare3_Prefiltered, Prefiltered_Temporal_Position_Previous, mt_lutxy(Difference_Step2_3, Difference5, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_4 = mt_makediff(C, Compare4_Prefiltered, u=1, v=1)

	#Compare5 = mt_merge(Compare4, Temporal_Position1_Next, mt_lutxy(Difference_Step2_4, Difference6, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare5_Prefiltered = mt_merge(Compare4_Prefiltered, Prefiltered_Temporal_Position1_Next, mt_lutxy(Difference_Step2_4, Difference6, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_5 = mt_makediff(C, Compare5_Prefiltered, u=1, v=1)
	
return(mergechroma(Compare1, C, 1))}



Function LDD2(clip c)
{

	Prefiltered = C.Unbt#.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Prefiltered_Spatial_Position1 = Prefiltered.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", Vertical = " 1 ", u=2, v=2)
	Prefiltered_Spatial_Position2 = Prefiltered.Mt_convolution( Horizontal = " 1 ", Vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Prefiltered_Temporal_Position_Previous = Prefiltered.Trim(0, -1)+c.Trim(0, c.framecount-1)
	Prefiltered_Temporal_Position1_Next = Prefiltered.Trim(1, 0)+c.Trim(c.framecount, 0)
	
	Prefiltered_Temporal_Filter = Average(Prefiltered, 0.5, Prefiltered_Temporal_Position_Previous, 0.25, Prefiltered_Temporal_Position1_Next, 0.25)
	
	
	Spatial_Position0 = C
	Spatial_Position1 = C.Mt_convolution( Horizontal = " -1 3 -3 5 -9 14 -16 26 -107 490 0 490 -107 26 -16 14 -9 5 -3 3 -1 ", Vertical = " 1 ", u=2, v=2)
	Spatial_Position2 = C.Mt_convolution( Horizontal = " 1 ", Vertical = " -1 2 -2 3 -6 9 -9 16 -80 384 0 384 -80 16 -9 9 -6 3 -2 2 -1 ", u=2, v=2)

	Temporal_Position_Previous = C.Trim(0, -1)+c.Trim(0, c.framecount-1)
	Temporal_Position1_Next = C.Trim(1, 0)+c.Trim(c.framecount, 0)
	
	Temporal_Filter = Average(C, 0.5, Temporal_Position_Previous, 0.25, Temporal_Position1_Next, 0.25)
	
	
	Difference1 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position1, u=1, v=1)
	Difference2 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position2, u=1, v=1)
	Difference3 = mt_makediff(Prefiltered, Prefiltered_Temporal_Filter, u=1, v=1)
	#Difference4 = mt_makediff(Prefiltered, Prefiltered_Spatial_Position4, u=1, v=1)
	#Difference5 = mt_makediff(Prefiltered, Prefiltered_Temporal_Position_Previous, u=1, v=1)
	#Difference6 = mt_makediff(Prefiltered, Prefiltered_Temporal_Position1_Next, u=1, v=1)
	
Thresh=256
	
	Compare1 = mt_merge(Spatial_Position1, Spatial_Position2, mt_lutxy(Difference1, Difference2, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		Compare1_Prefiltered = mt_merge(Prefiltered_Spatial_Position1, Prefiltered_Spatial_Position2, mt_lutxy(Difference1, Difference2, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	Difference_Step2_1 = mt_makediff(C, Compare1_Prefiltered, u=1, v=1)
	
	Compare2 = mt_merge(Compare1, Temporal_Filter, mt_lutxy(Difference_Step2_1, Difference3, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		Compare2_Prefiltered = mt_merge(Compare1_Prefiltered, Prefiltered_Temporal_Filter, mt_lutxy(Difference_Step2_1, Difference3, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	Difference_Step2_2 = mt_makediff(C, Compare2_Prefiltered, u=1, v=1)
	
	#Compare3 = mt_merge(Compare2, Spatial_Position4, mt_lutxy(Difference_Step2_2, Difference4, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare3_Prefiltered = mt_merge(Compare2_Prefiltered, Prefiltered_Spatial_Position4, mt_lutxy(Difference_Step2_2, Difference4, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_3 = mt_makediff(C, Compare3_Prefiltered, u=1, v=1)
	
	#Compare4 = mt_merge(Compare3, Temporal_Position_Previous, mt_lutxy(Difference_Step2_3, Difference5, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare4_Prefiltered = mt_merge(Compare3_Prefiltered, Prefiltered_Temporal_Position_Previous, mt_lutxy(Difference_Step2_3, Difference5, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_4 = mt_makediff(C, Compare4_Prefiltered, u=1, v=1)

	#Compare5 = mt_merge(Compare4, Temporal_Position1_Next, mt_lutxy(Difference_Step2_4, Difference6, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
		#Compare5_Prefiltered = mt_merge(Compare4_Prefiltered, Prefiltered_Temporal_Position1_Next, mt_lutxy(Difference_Step2_4, Difference6, "x 128 - abs y 128 - abs - "+string(thresh)+" *", u=1, v=1), u=3, v=3)
	#Difference_Step2_5 = mt_makediff(C, Compare5_Prefiltered, u=1, v=1)
	
return(mergechroma(Compare2, C, 1))}