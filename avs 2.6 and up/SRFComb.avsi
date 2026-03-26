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