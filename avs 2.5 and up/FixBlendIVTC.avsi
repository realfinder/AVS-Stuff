################################
## FixBlendIVTC  by MOmonster ##
################################


## FixBlendIVTC is a blend replacing / frame restoring function for doubleblends, caused by blenddeinterlacing
## of telecined sources. It will only work for this special case and is not created for any other conversions.
##
## Use import("FixBlendIVTC.avs") in your script and load the necessary filters to be able using this function
##
## required filters:
##		- Average
##		- mt_masktools
##		- removegrain
##      - TIVTC	(for cache>-1, not default. or for decimating (external))
##		- Decomb (if you want to use the function decimate for decimating)
## version:
##		- v0.93b  - 19.04.2020
##
## Thanks to Manao, Clouded and Kassandro for the really useful plugins,
## and of course also to foxyshadis, who gives me the idea and many inspirations.



## sample1:	source				#progressive
##		FixBlendIVTC(sbd=true)
##		decimate(cycle=5,quality=0)	#recommed decimating
##
## sample2:	source
##		FixBlendIVTC(post="""pp2.deen("a2d")""")
##		tdecimate(rate=23.976,mode=7)


## parameter description:
##	post
##		It's the parameter for the postprocessing. These are the modes:
##			0 ->	the fastest mode, no postprocessing
##			1 ->	like post=0 but with chromablurring
##			2 ->	use difference masking, higher quality and still good speed			[0...6  ->2]
##			3 ->	like post=2 but with chromablurring
##			4 ->	use a special blurring mask on luma and chroma that reduces artefacts
##			5 ->	combines post 2 and 4 but without chromapostprocessing
##			6 ->	like post=5 but with extra chromaprocessing (slowest)
##		If these postprocessing modes aren't strong or individual enough for you you can also use your own
##		favourit filter on the restored frames. Therefore set a string with your setted filters.
##		Use pp0 till pp6 for the postprocessing mode and add your filter like this:
##			post="pp4.blur(1)"		#post=4 + blurring
##		If you want to use a filter with inputstrings use three quotation marks like in the second example.
##	bthresh
##		The blendthreshold can be used to make the blenddetection less aggressive if there are some wrong detections.
##														[0...2.0  ->0.1]
##	mthresh
##		It´s used for (m)otion (thresh)olding. It regulates the blenddetection of frames with small pixelvaluedifferences.
##		A better quality of the source allows lower values and a more accurate detection. Don´t change this parameter too
##		much. It has a high influence on the double and single blenddetection.				[0...1.0  ->0.1]
##	sbd
##		The (s)ingle(b)lend(d)etection value is a boolean, Set it true for 12fps animations.	[bool  ->false]
##  chroma
##      With chroma=true you enable the processing of the chroma. This cost some speed, but depending on the source it
##      can improve	the blend and motion detection.                                         [bool  ->false]
##  cache
##	    With cache>=0 FixBlendIVTC use the RequestLinear function to be more compatible with non-linear requesting (codec or other functions).
##	    You can set the number of frames you want to have cached. If cache is negative FixBlendIVTC doesn´t use RequestLinear
##      (can be useful if you have problems with the memory usage).                         [-1...50  ->5]
##	dclip
##		The (d)etection(clip) you can set to improve the blenddetection (cleaning the clip before).
##		This clip is only used for the blenddetection and not for output.




Function FixBlendIVTC(clip input, "post", float "bthresh", "mthresh", bool "sbd", clip "dclip", bool "chroma", int "cache") 
{
avs26 = !(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
###### PREPARATION ######
global pp 	= default(post, 6)						#(p)ost(p)rocessing string
global mthresh 	= default(mthresh, 0.1)						#(m)otion(thresh)old
global thresh	= 1+default(bthresh, 0.01)
global sbd	= default(sbd,false)						#(s)ingle(b)lend(d)etection

       cache	= default(cache,-1)							#caching for non-linear request

rate	= framerate(input)


###### DETECTION CLIPS ######
dclip	= default(dclip,input)							#(d)etection clip
sis420  = sisphbd ? dclip.is420() : dclip.isyv12()
sislumaonly = sisphbd ? dclip.isy() : !avs26 ? false : dclip.isy8()
dclip	= default(chroma,false)==false || !sislumaonly ? dclip : \
                                                                 sis420 ? stackvertical(stackhorizontal(sisphbd ? dclip.ExtractU() : avs26 ? dclip.utoy8() : dclip.UtoY(),sisphbd ? dclip.ExtractV() : avs26 ? dclip.vtoy8() : dclip.VtoY()), sisphbd ? dclip.converttoy() : avs26 ? dclip.converttoy8() : dclip) : \
                                                                        stackhorizontal(stackhorizontal(sisphbd ? dclip.ExtractU() : avs26 ? dclip.utoy8() : dclip.UtoY(),sisphbd ? dclip.ExtractV() : avs26 ? dclip.vtoy8() : dclip.VtoY()), sisphbd ? dclip.converttoy() : avs26 ? dclip.converttoy8() : dclip)

o_diff	= mt_makediff(dclip.trim(1,0), dclip.trim(4,0))
c_diff	= mt_makediff(dclip.trim(2,0), dclip.trim(3,0))
global re_lut	= avs26 ? mt_lutxy(o_diff, c_diff, yexpr="x 128 - abs 126 > y 128 - abs 63 > & 0 x 128 + y 2 * - 2 ^ x 128 + y 2 * - abs 0.8 ^ - y 128 - abs 1 + 0.5 ^ / ?", scale_inputs="allf", use_expr=1) : mt_lutxy(o_diff, c_diff, yexpr="x 128 - abs 126 > y 128 - abs 63 > & 0 x 128 + y 2 * - 2 ^ x 128 + y 2 * - abs 0.8 ^ - y 128 - abs 1 + 0.5 ^ / ?", uexpr="x", vexpr="x")
global sdiff	= avs26 ? mt_lut(c_diff, yexpr="x 128 - 2 ^ 12 -", scale_inputs="allf", use_expr=2).mt_inpand() : mt_lut(c_diff, yexpr="x 128 - 2 ^ 12 -", uexpr="x", vexpr="x").mt_inpand()


###### POSTPROCESSING ######
unblend1 = Average(input, 2.0, input.duplicateframe(0), -1.0)
unblend2 = Average(input.trim(2,0), -1.0, input.trim(1,0), 2.0)

qmask1 	= mt_makediff(unblend1.RemoveGrain(mode=19, modeU=-1, modeV=-1), unblend1)
qmask2 	= mt_makediff(unblend2.RemoveGrain(mode=19, modeU=-1, modeV=-1), unblend2)
bmask	= avs26 ? mt_lutxy(qmask1, qmask2, yexpr="x range_half - abs y range_half - abs == range_half x range_half - abs 3 scalef + y range_half - abs < 0 y range_half - abs 3 scalef + x range_half - abs < range_max x range_half - abs y range_half - abs < 1 scalef 254 scalef ? ? ? ?", scale_inputs="allf", use_expr=1) : mt_lutxy(qmask1, qmask2, yexpr="x 128 - abs y 128 - abs == 128 x 128 - abs 3 + y 128 - abs < 0 y 128 - abs 3 + x 128 - abs < 255 x 128 - abs y 128 - abs < 1 254 ? ? ? ?", uexpr="x", vexpr="x")

diff	= avs26 ? mt_lutxy(input.duplicateframe(0), input, yexpr="x y - abs", use_expr=1).mt_expand() : mt_lutxy(input.duplicateframe(0), input, yexpr="x y - abs", uexpr="x", vexpr="x").mt_expand()
dmask	= avs26 ? mt_lutxy(diff,diff.trim(2,0), yexpr="x 2 * y < x 4 < & 0 y 2 * x < y 4 < & range_max x x y + / 200 scalef * 28 scalef + ? ?", use_expr=1) : mt_lutxy(diff,diff.trim(2,0), yexpr="x 2 * y < x 4 < & 0 y 2 * x < y 4 < & 255 x x y + / 200 * 28 + ? ?", uexpr="x", vexpr="x")
pmask	= avs26 ? mt_lutxy(dmask, bmask, yexpr="y 0 > y range_max < & x 0 == x range_max == | & x y ?", use_expr=1) : mt_lutxy(dmask, bmask, yexpr="y 0 > y 255 < & x 0 == x 255 == | & x y ?", uexpr="x", vexpr="x")

pp0 	= Average(input.trim(2,0), -0.5, input.trim(1,0), 1.0, input, 1.0, input.duplicateframe(0), -0.5)
pp1 	= pp0.RemoveGrain(mode=0, modeU=12, modeV=12)
pp2 	= mt_merge(unblend1, unblend2, dmask.RemoveGrain(mode=12, modeU=-1, modeV=-1).greyscale(), Y=3, U=3, V=3)
pp3 	= pp2.RemoveGrain(mode=0, modeU=12, modeV=12)
pp4 	= mt_merge(unblend1, unblend2, bmask.RemoveGrain(mode=12, modeU=-1, modeV=-1), luma=true)
pp5 	= mt_merge(unblend1, unblend2, pmask.RemoveGrain(mode=12, modeU=-1, modeV=-1).greyscale(), Y=3, U=3, V=3)
pp6	= mt_merge(pp5, unblend2, bmask.RemoveGrain(mode=12, modeU=-1, modeV=-1), Y=3, U=2, V=2).RemoveGrain(mode=0, modeU=12, modeV=12)


###### OUTPUT ######
global source	= input
global final	= IsString(pp) ? Eval(pp) : pp==1 ? pp1 : pp==2 ? pp2 : pp==3 ? pp3 : pp==4 ? pp4 : pp==5 ? pp5 : pp==6 ? pp6 : pp0


###### VAR.. ######
global fdc0	= 1.0								#(f)rame(d)ifference
global fdn1 	= 1.0
global fdn2 	= 1.0

global rvp1	= 1.0								#(r)estore(v)alue
global rvc0 	= 1.0
global rvn1 	= 1.0
global rvn2 	= 1.0

global counter	= 2								#pattern count variable


###### Conditional Function Chain, evaluated from bottom to top (!) ######
#ScriptClip(source, " source.subtitle(string(rvc0)) ")
ScriptClip(source, " counter==0 ? final : counter==1 ? source.trim(1,0) : source ")

FrameEvaluate(last, "
	global fdp1	= fdc0
	global fdc0	= fdn1
	global fdn1	= fdn2
	global fdn2	= AverageLuma(sdiff)

	global rvp2	= rvp1
	global rvp1	= rvc0
	global rvc0	= rvn1
	global rvn1	= rvn2
	global rvn2 	= AverageLuma(re_lut)

	bcalc	= rvc0<rvp2 && rvc0<rvp1 && rvc0<rvn1 && rvc0<rvn2 ? 
		\ (rvp2<rvp1 && rvp2<rvn1 && rvp2<rvn2 ? rvp2 : rvp1<rvn1 && rvp1<rvn2 ? rvp1 : rvn1<rvn2 ? rvn1 : rvn2) / rvc0 :
		\ rvc0<0.25*rvp1 && rvc0<0.25*rvn1 && (rvc0<0.5*rvp2 || rvc0<0.5*rvn2) ?
		\ -0.25 * (2*rvp2<rvp1 && 2*rvp2<rvn1 && rvp2>rvn2 ? 2*rvp2 : 2*rvn2<rvp1 && 2*rvn2<rvn1 && rvn2>rvp2 ? 2*rvn2 : rvp1<rvn1 ? rvp1 : rvn1) / rvc0 : 0

	global counter	= counter==-1 ? 1 : (abs(bcalc)>1.0 && rvc0<10*mthresh || abs(bcalc)>thresh) &&
			\ (counter>3 || bcalc>0) && (fdp1>mthresh || fdn1>mthresh || fdp1>0.5*fdc0 || fdn1>0.5*fdc0) ? 0 : counter+1

	global counter	= counter!=0 || sbd==false ? counter : fdp1<fdn1 && fdp1<mthresh ? -1 : fdn1<mthresh || fdc0<mthresh ? 1 : 0
		")
			
cache==-1 ? last.changefps(rate*2).changefps(rate,linear=true).addborders(8,0,0,0).crop(8,0,-0,-0) : \
            cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)

return(last)  
}