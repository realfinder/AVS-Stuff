# SRFComb by Doom9 real.finder
# it should give Best of many of AVS Rainbow & Dot Crawl Removal, it Planed to be as SComb2 but I change it to SRFComb
# 1.01
Function SRFComb(clip clip, int "DotCrawlThSAD", int "RainbowThSAD", bool "SpatialDeDotCraw")
{

Assert(IsPlanar(clip) && !IsRGB(clip), "SRFComb: Planar YUV input only")

sisphbd = AvsPlusVersionNumber > 2294

fullchr = sisphbd ? is444(clip) : isyv24(clip)
chr420  = sisphbd ? is420(clip) : isyv12(clip)
chr422  = sisphbd ? is422(clip) : isyv16(clip)
nochr   = sisphbd ?   isy(clip) : isy8(clip)

Assert(!nochr, "SRFComb: not work with Greyscale video")
thSAD = Default(DotCrawlThSAD, 500)
thSADC = Default(RainbowThSAD, 500)
SpatialDeDotCraw = Default(SpatialDeDotCraw, true)
clip.SeparateFields()
LumaSpatialDeDot=SpatialDeDotCraw ? YToUV(ExtractU(),ExtractV(),ConvertToY().Blur(1.58,0).Sharpen(1,0)).Repair(last,5,0) : last
ogs=last
ogy=clip.ConvertToY()
pre=ogy.DeDot(10,30).TemporalRepair(ogy,3).checkmate().TemporalRepair(ogy,3).Repair(ogy).SeparateFields().Ablur(1,blurv=0).Blur(1.58,0).Sharpen(1,0)
preymask=ogy.SeparateFields().Blur(0,1.58).Sharpen(0.1,1).mt_edge("0 0 0 -1 0 1 0 0 0",4,8)
precmask=pre.mt_edge("0 0 0 -1 0 1 0 0 0",1,3)
cuvmask=Mt_makediff(ogs.Tweak(sat=0),ogs.Tweak(sat=10),1,u=3,v=3)
cuvmask=Interleave(cuvmask.ExtractU(),cuvmask.ExtractV()).mt_lut("x range_half == range_min range_half x - abs 2.28 * ?")
cuvmask=mt_logic(cuvmask.SelectEven(),cuvmask.SelectOdd(),"max")
cuvmaskf=cuvmask.BilinearResize(ogs.Width(),ogs.Height(),chr422 || chr420 ? 0.25 : fullchr ? undefined : 0.375)
premask=mt_logic(cuvmaskf,precmask,"min").mt_expand(mode="horizontal").mt_inflate()
pre2=mt_merge(ogs,pre.MatchColorFormat(ogs),premask,luma=true,y=4,u=3)
pre2=Merge(pre2,pre2.TemporalRepair(ogs,1))

super_search = pre2.MSuper(rfilter=4)

bv1 = super_search.MAnalyse(8,4,isb = true,  delta = 2, overlap= 2,dct=8)
fv1 = super_search.MAnalyse(8,4,isb = false, delta = 2, overlap= 2,dct=8)
ycombmask=mt_logic(cuvmaskf,preymask,"min").mt_expand(mode="horizontal").mt_expand(mode="horizontal").mt_inflate()
uvcombmask=premask.BilinearResize(cuvmask.Width(),cuvmask.Height(),chr422 || chr420 ? -0.25 : fullchr ? undefined : -0.375)
fullcombmask=YToUV(uvcombmask,uvcombmask,ycombmask)
lastLumaSpatialDeDot=mt_merge(last,LumaSpatialDeDot,fullcombmask,u=2,v=2)
lastLumaSpatialDeDot.MDegrain1(lastLumaSpatialDeDot.MSuper(levels=1), bv1, fv1, thSAD=thSAD, thSADC=thSADC)

mt_merge(ogs,last,fullcombmask,u=3,v=3)

Weave()
}

# SRFComb2 by Doom9 real.finder
# same goal as SRFComb but with deferet different
# 1.00
Function SRFComb2(clip clip, bool "SpatialDeDotCraw", bool "SpatialDeRainbow", int "DotCrawlThSAD", int "RainbowThSAD", bool "PAL")
{
Assert(IsPlanar(clip) && !IsRGB(clip), "SRFComb2: Planar YUV input only")
sisphbd = AvsPlusVersionNumber > 2294

fullchr = sisphbd ? is444(clip) : isyv24(clip)
chr420  = sisphbd ? is420(clip) : isyv12(clip)
chr422  = sisphbd ? is422(clip) : isyv16(clip)
nochr   = sisphbd ?   isy(clip) : isy8(clip)

Assert(!nochr, "SRFComb2: not work with Greyscale video")
SpatialDeDotCraw = Default(SpatialDeDotCraw, false)
SpDeRa = Default(SpatialDeRainbow, false)
thSAD = Default(DotCrawlThSAD, 500)
thSADC = Default(RainbowThSAD, 500)
PAL = Default(PAL, FrameRate(clip) == 25)

SeparateFields(clip)
o=last
oY=o.ConvertToY()

e=mt_logic(oY.mt_edge("0 0 0 -16 0 16 0 0 0",0,0),oY.mt_edge("0 0 0 0 2 -2 0 0 0",3,5),"and")

m=mt_logic(e,oY.mt_invert(),"min")

Mt_makediff(Tweak(sat=0),Tweak(sat=PAL ? 20 : 10),1,u=3,v=3)
Interleave(ExtractU(),ExtractV()).mt_lut("x range_half == range_min range_half x - abs 2.28 * ?")
ouvm=mt_logic(SelectEven(),SelectOdd(),"max")
ouvm.BilinearResize(m.Width(),m.Height(),chr422 || chr420 ? 0.25 : fullchr ? undefined : 0.375)
fm=mt_logic(PAL ? mt_expand() : mt_expand(mode="horizontal"),m.mt_binarize(30),"min").mt_expand(mode="horizontal").mt_expand(mode="horizontal").mt_inflate()
CleFFTY=oY.FFT3DFilter(33,plane=0 ,bw=4,ow=2 ,bh=2,oh=1 ,bt=1,sigma2=33,sigma3=22,sigma4=0,wintype=2).Merge(oY.aBlur(2,blurv=0))
CleFFTYi=Weave(CleFFTY)
mt_merge(o,CleFFTYi.checkmate().TemporalRepair(CleFFTYi,3).SeparateFields().Repair(CleFFTY),fm)

chm=mt_logic(oY.mt_edge("0 0 0 -1 0 1 0 0 0").mt_expand(mode="horizontal"),oY.mt_edge("0 0 0 0 2 -2 0 0 0",3,5),"and")
chm=mt_logic(chm,oY.mt_invert().mt_binarize(50),"min").mt_expand(mode="horizontal").mt_inflate()

SpatiCombC=mt_merge(last,FFT3DFilter(0,plane=3 ,bt=1,interlaced=true,sigma2=22,sigma3=11,sigma4=44),chm,Luma=true)

SpatiCombUV = Interleave(ExtractU(SpatiCombC), ExtractV(SpatiCombC)).svsTBilateral(diameterL=11, sDevL=1.4, iDevL=7.1, d2=true, chroma=false, ppclip=last.Converttoy().BilinearResize(ouvm.Width(),ouvm.Height(),chr422 || chr420 ? -0.25 : fullchr ? undefined : -0.375).changefps(FrameRate()*2), kernS=8, kernI=3, resType=0)

SpatiCombC=YToUV(SpatiCombUV.SelectEven(),SpatiCombUV.SelectOdd(),last).aWarpSharp2(depth=0,depthv=16,chroma=6).aWarpSharp2(depth=16,depthv=0,chroma=6,cplace="MPEG2")

super_searchE = SpatiCombC.SelectEven().MSuper(rfilter=4)
super_searchO = SpatiCombC.SelectOdd().MSuper(rfilter=4)
bv1e = super_searchE.MAnalyse(8,4,isb = true,  delta = 1, overlap= 2,dct=8)
bv1o = super_searchO.MAnalyse(8,4,isb = true,  delta = 1, overlap= 2,dct=8)
fv1e = super_searchE.MAnalyse(8,4,isb = false,  delta = 1, overlap= 2,dct=8)
fv1o = super_searchO.MAnalyse(8,4,isb = false,  delta = 1, overlap= 2,dct=8)

uvcombmask=chm.BilinearResize(ouvm.Width(),ouvm.Height(),chr422 || chr420 ? -0.25 : fullchr ? undefined : -0.375)
fullcombmask=YToUV(uvcombmask,uvcombmask,fm)

MDegrsuperE = o.SelectEven().MSuper(levels=1)
MDegrsuperO = o.SelectOdd().MSuper(levels=1)
Interleave(o.SelectEven().MDegrain1(MDegrsuperE, bv1e, fv1e, thSAD=thSAD, thSADC=thSADC), o.SelectOdd().MDegrain1(MDegrsuperO, bv1o, fv1o, thSAD=thSAD, thSADC=thSADC))

momaskbv1e = SpatialDeDotCraw || SpDeRa ? o.SelectEven().MMask(bv1e, kind = 0, ml=1,Ysc=255) : nop()
momaskbv1o = SpatialDeDotCraw || SpDeRa ? o.SelectOdd().MMask(bv1o, kind = 0, ml=1,Ysc=255) : nop()
momaskfv1e = SpatialDeDotCraw || SpDeRa ? o.SelectEven().MMask(fv1e, kind = 0, ml=1,Ysc=255) : nop()
momaskfv1o = SpatialDeDotCraw || SpDeRa ? o.SelectOdd().MMask(fv1o, kind = 0, ml=1,Ysc=255) : nop()
momaskE=SpatialDeDotCraw || SpDeRa ? mt_logic(momaskbv1e,momaskfv1e,"max",u=3,v=3) : nop()
momaskO=SpatialDeDotCraw || SpDeRa ? mt_logic(momaskbv1o,momaskfv1o,"max",u=3,v=3) : nop()
m=SpatialDeDotCraw || SpDeRa ? Interleave(mt_logic(momaskE,momaskE.mt_expand(u=3,v=3).TemporalSoften(2, 255, 255, 0, 2),"max",u=3,v=3), mt_logic(momaskO, momaskO.mt_expand(u=3,v=3).TemporalSoften(2, 255, 255, 0, 2),"max",u=3,v=3)).mt_expand(u=3,v=3).mt_expand(mode="horizontal",u=3,v=3).mt_inflate(u=3,v=3) : nop()

SpatialDeDotCraw || SpDeRa ? mt_merge(last,SpatiCombC,m,y=SpatialDeDotCraw ? 3 : 2,u=SpDeRa ? 3 : 2,v=SpDeRa ?  3 : 2) : last

mt_merge(o,last,fullcombmask,u=3,v=3)

Weave()
}