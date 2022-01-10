#HBD mod 1.2 and new AutoDeblock3
#Author: eXmendiC, joletb, vinylfreak89, Gebbi
#Version: 2.6
function AutoDeblock2(clip c, float "edgeValue", float "db1", float "db2", float "db3", bool "deblockY", bool "deblockUV", bool "debug", bool "redfix", bool "fastdeblock", float "adb1", float "adb2", float "adb3", float "adb1d", float "adb2d", float "adb3d") {
 c
 global AutoDeblock2_o = c
 
 sisavs26   = !(VersionNumber() < 2.6)
 sisphbd = AvsPlusVersionNumber > 2294
 shbdbpc = sisphbd ? c.BitsPerComponent() : 8
 sischbd = shbdbpc > 8
 ssIsVF  = sischbd ? c.IsVideoFloat() : false
 mtnavb  = sisphbd ? shbdbpc > 8 ? shbdbpc == 10 ? 4 : shbdbpc == 12 ? 8 : shbdbpc == 14 ? 64 : 256 : nop() : nop()

 edgeValue = sisavs26 ? Default (edgeValue, 24) : round(Default (edgeValue, 24))
 db1 = Default (db1, 1)
 db2 = Default (db2, 6)
 db3 = Default (db3, 15)
 deblockY = Default (deblockY, true)
 deblockUV = Default (deblockUV, true)
 debug = Default(debug, false)
 redfix = Default(redfix, false)
 fastdeblock = Default(fastdeblock, false)
 adb1 = Default (adb1, 3)
 adb1 = ssIsVF ? adb1/255 : sischbd ? adb1*mtnavb : adb1
 global AutoDeblock2_adb1 = adb1
 adb2 = Default (adb2, 4)
 adb2 = ssIsVF ? adb2/255 : sischbd ? adb2*mtnavb : adb2
 global AutoDeblock2_adb2 = adb2
 adb3 = Default (adb3, 8)
 adb3 = ssIsVF ? adb3/255 : sischbd ? adb3*mtnavb : adb3
 global AutoDeblock2_adb3 = adb3
 adb1d = Default (adb1d, 2)
 adb1d = ssIsVF ? adb1d/255 : sischbd ? adb1d*mtnavb : adb1d
 global AutoDeblock2_adb1d = adb1d
 adb2d = Default (adb2d, 7)
 adb2d = ssIsVF ? adb2d/255 : sischbd ? adb2d*mtnavb : adb2d
 global AutoDeblock2_adb2d = adb2d
 adb3d = Default (adb3d, 11)
 adb3d = ssIsVF ? adb3d/255 : sischbd ? adb3d*mtnavb : adb3d
 global AutoDeblock2_adb3d = adb3d
 global AutoDeblock2_orig=last.mt_edge("prewitt",0,edgeValue,0,edgeValue)
 global AutoDeblock2_orig_d=mt_edge("prewitt",0,edgeValue,0,edgeValue).removegrain(4).removegrain(4)
 
 threads=sh_GetUserGlobalIMTint
 fastdeblock0 = debug ? removegrain(2).removegrain(2).deblock_qed.dfttest(tbsize=1).Subtitle("deblock") : removegrain(2).removegrain(2).deblock_qed.sneo_dfttest(tbsize=1,threads=threads,fft_threads=threads)
 
 unfiltered = debug ? last.Subtitle("unfiltered") : last
 weakdeblock = debug ? removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db1,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads).Subtitle("weakdeblock") : removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db1,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)
 mediumdeblock = debug ? removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db2,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads).Subtitle("mediumdeblock") : removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db2,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)
 strongdeblock = debug ? removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db3,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads).Subtitle("strongdeblock") : removegrain(2).removegrain(2).Deblock_QED().sneo_dfttest(sigma=db3,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)

 autodeblock0 = ConditionalFilter(fastdeblock0, unfiltered, "(LumaDifference(AutoDeblock2_orig,AutoDeblock2_orig_d) > AutoDeblock2_adb1) && (YDifferenceToNext > AutoDeblock2_adb1d)", "==", "True")
 autodeblock1 = ConditionalFilter(weakdeblock, unfiltered, "(LumaDifference(AutoDeblock2_orig,AutoDeblock2_orig_d) > AutoDeblock2_adb1) && (YDifferenceToNext > AutoDeblock2_adb1d)", "==", "True")
 autodeblock2 = ConditionalFilter(mediumdeblock, autodeblock1, "(LumaDifference(AutoDeblock2_orig,AutoDeblock2_orig_d) > AutoDeblock2_adb2) && (YDifferenceToNext > AutoDeblock2_adb2d)", "==", "True")
 autodeblock3 = ConditionalFilter(strongdeblock, autodeblock2, "(LumaDifference(AutoDeblock2_orig,AutoDeblock2_orig_d) > AutoDeblock2_adb3) && (YDifferenceToNext > AutoDeblock2_adb3d)", "==", "True")
 
 reddeblock = redfix ? ConditionalFilter(sischbd ? unfiltered.Vinverse_avsi : unfiltered.vinverse(), autodeblock3, "(AverageLuma(AutoDeblock2_o) > " + string(ssIsVF ? 50/255 : sischbd ? 50*mtnavb : 50) + ") && (AverageLuma(AutoDeblock2_o) < " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaU(AutoDeblock2_o) > " + string(ssIsVF ? 95/255 : sischbd ? 95*mtnavb : 95) + ") && (AverageChromaU(AutoDeblock2_o) < " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaV(AutoDeblock2_o) > " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaV(AutoDeblock2_o) < " + string(ssIsVF ? 155/255 : sischbd ? 155*mtnavb : 155) + ")", "==", "True") : autodeblock3
 fastdeblock ? autodeblock0 : reddeblock
 }
 
 
 ###################
 # AutoDeblock3, use admfilter method with AutoDeblock2 to make it work better
 # v1.1
 function AutoDeblock3(clip c, float "edgeValue", float "db1", float "db2", float "db3", bool "deblockY", bool "deblockUV", bool "debug", bool "redfix", bool "fastdeblock", float "adb1", float "adb2", float "adb3", float "adb1d", float "adb2d", float "adb3d", clip "MotionRampadc") {
 c
 sisavs26   = !(VersionNumber() < 2.6)
 sisphbd = AvsPlusVersionNumber > 2294
 shbdbpc = sisphbd ? c.BitsPerComponent() : 8
 sischbd = shbdbpc > 8
 ssIsVF  = sischbd ? c.IsVideoFloat() : false
 mtnavb  = sisphbd ? shbdbpc > 8 ? shbdbpc == 10 ? 4 : shbdbpc == 12 ? 8 : shbdbpc == 14 ? 64 : 256 : nop() : nop()

 edgeValue = sisavs26 ? Default (edgeValue, 24) : round(Default (edgeValue, 24))
 db1 = Default (db1, 1)
 db2 = Default (db2, 6)
 db3 = Default (db3, 15)
 deblockY = Default (deblockY, true)
 deblockUV = Default (deblockUV, true)
 debug = Default(debug, false)
 redfix = Default(redfix, false)
 fastdeblock = Default(fastdeblock, false)
 adb1 = Default (adb1, 3)
 adb1 = ssIsVF ? adb1/255 : sischbd ? adb1*mtnavb : adb1
 adb2 = Default (adb2, 4)
 adb2 = ssIsVF ? adb2/255 : sischbd ? adb2*mtnavb : adb2
 adb3 = Default (adb3, 8)
 adb3 = ssIsVF ? adb3/255 : sischbd ? adb3*mtnavb : adb3
 adb1d = Default (adb1d, 2)
 adb1d = ssIsVF ? adb1d/255 : sischbd ? adb1d*mtnavb : adb1d
 adb2d = Default (adb2d, 7)
 adb2d = ssIsVF ? adb2d/255 : sischbd ? adb2d*mtnavb : adb2d
 adb3d = Default (adb3d, 11)
 adb3d = ssIsVF ? adb3d/255 : sischbd ? adb3d*mtnavb : adb3d
 orig=last.mt_edge("prewitt",0,edgeValue,0,edgeValue)
 orig_d=mt_edge("prewitt",0,edgeValue,0,edgeValue).removegrain(4).removegrain(4)
 
 threads=sh_GetUserGlobalIMTint
 
 fastdeblock0 = debug ? removegrain(2).removegrain(2).deblock_qed.dfttest(tbsize=1).Subtitle("deblock") : removegrain(2).removegrain(2).deblock_qed.sneo_dfttest(tbsize=1,threads=threads,fft_threads=threads)
 
 unfiltered = debug ? last.Subtitle("unfiltered") : last
 
 MotionRampadc = defined(MotionRampadc) ? MotionRampadc : c.MotionRamp(5.0,10.0,15.0,20.0,25.0,Max=255,fast=True)
 autodeblock3 = fastdeblock ? nop() : GScriptClip("""
                     adfloat = AverageLuma(MotionRampadc)
                     adSigmb = shbdbpc > 8 ? shbdbpc == 10 ? 1023 : shbdbpc == 12 ? 4095 : shbdbpc == 14 ? 16383 : nop() : nop()
                     adSigma = ssIsVF ? adfloat : shbdbpc > 8 ? shbdbpc < 16 ? adfloat/adSigmb : adfloat/65535 : adfloat/255
do1d=(LumaDifference(orig,orig_d) > adb1) && (YDifferenceToNext > adb1d)
do2d=(LumaDifference(orig,orig_d) > adb2) && (YDifferenceToNext > adb2d)
do3d=(LumaDifference(orig,orig_d) > adb3) && (YDifferenceToNext > adb3d)
dostgd = do3d
domedd = do2d && !dostgd
dowakd = do1d && !domedd && !dostgd
 weakdeblock   = !dowakd ? nop() : merge(removegrain(2).removegrain(2).Deblock_QED(),adSigma/2  ).sneo_dfttest(sigma=db1*adSigma,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)
 weakdeblock   = !dowakd || !debug ? weakdeblock : weakdeblock.Subtitle("weakdeblock")
 mediumdeblock = !domedd ? nop() : merge(removegrain(2).removegrain(2).Deblock_QED(),adSigma/1.5).sneo_dfttest(sigma=db2*adSigma,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)
 mediumdeblock = !domedd || !debug ? mediumdeblock : mediumdeblock.Subtitle("mediumdeblock")
 strongdeblock = !dostgd ? nop() : merge(removegrain(2).removegrain(2).Deblock_QED(),adSigma    ).sneo_dfttest(sigma=db3*adSigma,y=deblockY ? 3 : 2,u=deblockUV ? 3 : 2,v=deblockUV ? 3 : 2,tbsize=1,threads=threads,fft_threads=threads)
 strongdeblock = !dostgd || !debug ? strongdeblock : strongdeblock.Subtitle("strongdeblock")
 autodeblock1 =  do1d ? weakdeblock : unfiltered
 autodeblock2 =  do2d ? mediumdeblock : autodeblock1
                 do3d ? strongdeblock : autodeblock2
                      """, args="MotionRampadc, adb1, adb2, adb3, db1, db2, db3, adb1d, adb2d, adb3d, deblockY, deblockUV, threads, orig, orig_d, debug, unfiltered, shbdbpc, ssIsVF, fastdeblock")
 autodeblock0 = !fastdeblock ? nop() : gConditionalFilter(fastdeblock0, unfiltered, "(LumaDifference(orig,orig_d) > adb1) && (YDifferenceToNext > adb1d)", "==", "True", args="adb1, orig, orig_d, adb1d")
 reddeblock = !fastdeblock && redfix ? gConditionalFilter(sischbd ? unfiltered.Vinverse_avsi : unfiltered.vinverse(), autodeblock3, "(AverageLuma(c) > " + string(ssIsVF ? 50/255 : sischbd ? 50*mtnavb : 50) + ") && (AverageLuma(c) < " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaU(c) > " + string(ssIsVF ? 95/255 : sischbd ? 95*mtnavb : 95) + ") && (AverageChromaU(c) < " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaV(c) > " + string(ssIsVF ? 130/255 : sischbd ? 130*mtnavb : 130) + ") && (AverageChromaV(c) < " + string(ssIsVF ? 155/255 : sischbd ? 155*mtnavb : 155) + ")", "==", "True", args="c") : autodeblock3
 fastdeblock ? autodeblock0 : reddeblock
 }
