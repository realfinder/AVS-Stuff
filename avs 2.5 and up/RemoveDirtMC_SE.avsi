#########################################################################################################################
###                                                                                                                   ###
###                                                  RemoveDirtMC                                                     ###
###                                                      v1.57                                                        ###
###                                               **SPECIAL EDITION**                                                 ###
###                                           	      By NEPHILIS                                                     ###
###                                                      @2011                                                        ###
###                                    mod by Great Dragon to work with NLMeansCL2                                    ###
###                                 mod2 by A.SONY to make it more friendly in motions                                ###
#########################################################################################################################

##################################################################
##                                                              ##
## --------------                                               ##
## Requirements : - MVTools      (v2.5.11.2)                    ##
## --------------                                               ##
##         - RemoveGrainT (v1.0) package                        ##
##         - RemoveDirt   (v0.9) package                        ##
##         - AvsRecursion (v0.2)                                ##
##         - FluxSmooth   (v1.1)                                ##
##                                                              ##
##           As Additional                                      ##
##              --------                                        ##
##        => To Prefiltering with FFT3DFilter                   ##
##         - FFT3DFilter  (v2.1.1)                              ##
##         - Dither_Luma_Rebuild from SMDegrain or elsewhere    ##
##              --------                                        ##
##        => To Prefiltering with NLMeansCL2                    ##
##         - NLMeansCL2.dll v0.4.0 (2015-01-08)                 ##
##                                                              ##
##################################################################

##########################################################################################################################
# -------                                                                                                                #
# Usage :                                                                                                                #
# -------                                                                                                                #
#                                                                                                                        #
# RemoveDirtMC_SE(clip input, bool"GPU", int"radius", int"repmode", int"clmode", bool"TwoPass", int"thSAD", int"thSADC") #
#                                                                                                                        #
##########################################################################################################################

##################
# -----------    #
# PARAMETERS:    #
# -----------    #
##################

##########################################################################################################################
#
# ----------
# GPU       : -- To choose NLMeansCL or FFT3Dfilter for PreFiltering process.
# ----------     ATI GPU owners should use "GPU=false" 
#	     	      
# ----------
# Radius    : -- Temporal Radius for MDeGrain at second stage DeNoising.
# ----------
#
# ----------
# repmode   : -- Repair mode value in main RemoveDirtSE function.
# ----------     
#
# ----------
# clmode    : -- RemoveGrain mode value in main RemoveDirtSE function.
# ----------
#
# ----------
# Twopass   : -- To make a Temporal Denoising (MDeGrain) after Spatial Denoising (RemoveDirtSE).   
# ----------   
#
# ----------
# thSAD, 
# thSADC    : -- MDeGrain's thSAD and thSADC parameters.
# ---------- 
#
##########################################################################################################################

Function RemoveDirtMC_SE(clip input, bool"GPU", int"radius", int"repmode", int"clmode", bool"TwoPass", int"thSAD", int"thSADC", int"resrepmode",float "rStr",float "Amp", bool "luma_rebuild", clip "PreNR", bool "recalculate", int "limit", bool "_grey", int "noisy", int "dist", int "gmthreshold", string "RDSE_params", int "mcthSAD", int "pel", int "dct", int "thSCD1", int "thSCD2", int "Threads")

{

version  = "v1.57"

     GPU = default(GPU,     true)
   _grey = default(_grey,  false)
  radius = default(radius,     2)
 repmode = default(repmode,   16)
  clmode = default(clmode,     5)
 TwoPass = default(TwoPass, true)
   thSAD = default(thSAD ,   150)
   thSAD2= thSAD/2
  thSADC = default(thSADC, thSAD)
   rStr  = default( rStr,    1.0)
   Amp   = default( Amp,  0.0625)
 luma_rebuild = default(luma_rebuild,   true)
 recalculate  = default(recalculate, TwoPass)
 Threads      = default(Threads, sh_GetUserGlobalIMTint())
 mtbd         = Defined(threads)
    
      ox = input.width()
      oy = input.height()
      HD = (ox > 1099 || oy > 599)
     pel = default( pel, HD ? 1 : 2 )
 blksize = HD ? 16 : 8
 blksize2= int(blksize/2) + (int(blksize/2)%2)
  search = HD ? 4 : 5
 overlap = blksize/2
 overlap2= int(overlap/2) + (int(overlap/2)%2)

         src = input
       PreNR = defined(PreNR) ? PreNR : (GPU==true) ? src.SH_KNLMeansCL(a=2,h=radius*1.5,chroma=!_grey).TemporalDeGrain_SE(5,9,_grey=_grey) \
                           : src.sneo_FFT3D(u=_grey ? 1 : 3,v=_grey ? 1 : 3,sigma=radius*2,bw=16,bh=16,ow=8,oh=8,bt=3,wintype=1,ncpu=Threads).TemporalDeGrain_SE(5,9,_grey=_grey)
       PreNR = luma_rebuild ? isyuy2(input) ? PreNR.Interleaved2Planar(_grey).dither_luma_rebuild(S0=rStr,c=Amp,uv=_grey ? 1 : 3).Planar2Interleaved(_grey) \
                           : PreNR.dither_luma_rebuild(S0=rStr,c=Amp,uv=_grey ? 1 : 3) : PreNR
 PreNR_super = mtbd ? MSuper(PreNR,hpad=4,vpad=4,pel=pel,sharp=2,chroma=!_grey, mt=threads!=1) : MSuper(PreNR,hpad=4,vpad=4,pel=pel,sharp=2,chroma=!_grey)
   src_super = mtbd ? MSuper(src  ,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey, mt=threads!=1) : MSuper(src  ,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey)
  recalc_sup = recalculate ? mtbd ? MSuper(PreNR  ,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey, mt=threads!=1) : MSuper(PreNR  ,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey) : nop()

 bwv1 = mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=1, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=1, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey)
 bwv2 = (radius>=2) ? \
	mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=2, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=2, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey) : nop()
 bwv3 = (radius==3) ? \
	mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=3, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=true,  delta=3, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey) : nop()
 fwv1 = mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=1, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=1, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey)
 fwv2 = (radius>=2) ? \
	mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=2, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=2, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey) : nop()
 fwv3 = (radius==3) ? \
	mtbd ? MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=3, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey, mt=threads!=1) : MAnalyse(PreNR_super, blksize=blksize, search=search, isb=false, delta=3, dct=dct, overlap=overlap, truemotion=true,chroma=!_grey) : nop()
	
	
	recalculate ? Eval("""
 bwv1 = mtbd ? MRecalculate(recalc_sup,bwv1, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey, mt=threads!=1) : MRecalculate(recalc_sup,bwv1, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey)
 bwv2 = (radius>=2) ? \
	mtbd ? MRecalculate(recalc_sup,bwv2, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey, mt=threads!=1) : MRecalculate(recalc_sup,bwv2, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey) : nop()
 bwv3 = (radius==3) ? \
	mtbd ? MRecalculate(recalc_sup,bwv3, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey, mt=threads!=1) : MRecalculate(recalc_sup,bwv3, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey) : nop()
 fwv1 = mtbd ? MRecalculate(recalc_sup,fwv1, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true, mt=threads!=1) : MRecalculate(recalc_sup,fwv1, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true)
 fwv2 = (radius>=2) ? \
	mtbd ? MRecalculate(recalc_sup,fwv2, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey, mt=threads!=1) : MRecalculate(recalc_sup,fwv2, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey) : nop()
 fwv3 = (radius==3) ? \
	mtbd ? MRecalculate(recalc_sup,fwv3, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey, mt=threads!=1) : MRecalculate(recalc_sup,fwv3, blksize=blksize2, search=search, dct=dct, overlap=overlap2,thSAD=thSAD2, truemotion=true,chroma=!_grey) : nop()
                  """) : nop()
	

 bcomp = mtbd ? MCompensate(src,src_super,bwv1,thSAD=defined(mcthSAD) ? mcthSAD : TwoPass ? undefined : thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=threads!=1) : MCompensate(src,src_super,bwv1,thSAD=defined(mcthSAD) ? mcthSAD : TwoPass ? undefined : thSAD, thSCD1=thSCD1, thSCD2=thSCD2)
 fcomp = mtbd ? MCompensate(src,src_super,fwv1,thSAD=defined(mcthSAD) ? mcthSAD : TwoPass ? undefined : thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=threads!=1) : MCompensate(src,src_super,fwv1,thSAD=defined(mcthSAD) ? mcthSAD : TwoPass ? undefined : thSAD, thSCD1=thSCD1, thSCD2=thSCD2)
  
 NR1 = src.RemoveDirtSE(fcomp, bcomp, limit=limit, _grey=_grey, noisy=noisy, dist=dist, gmthreshold=gmthreshold, repmode=repmode, clmode=clmode, resrepmode=resrepmode, RDSE_params=RDSE_params)
 NR1_super = ( TwoPass==true  ) ? mtbd ? MSuper(NR1,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey, mt=threads!=1) : MSuper(NR1,hpad=4,vpad=4,pel=pel,sharp=2,levels=1,chroma=!_grey) : nop()
       NR2 = ( TwoPass==false ) ? NR1
\   	   : (  radius==1  ) ? mtbd ? MDeGrain1(NR1, NR1_super, bwv1, fwv1, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2, mt=threads!=1) : MDeGrain1(NR1, NR1_super, bwv1, fwv1, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2)
\   	   : (  radius==2  ) ? mtbd ? MDeGrain2(NR1, NR1_super, bwv1, bwv2, fwv1, fwv2, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2, mt=threads!=1) : MDeGrain2(NR1, NR1_super, bwv1, bwv2, fwv1, fwv2, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2)
\   	   : 		           mtbd ? MDeGrain3(NR1, NR1_super, bwv1, bwv2, bwv3, fwv1, fwv2, fwv3, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2, mt=threads!=1) : MDeGrain3(NR1, NR1_super, bwv1, bwv2, bwv3, fwv1, fwv2, fwv3, thSAD=thSAD, thSADC=thSADC,plane=_grey ? 0 : 4, thSCD1=thSCD1, thSCD2=thSCD2)
 	Return(NR2)

}

function TemporalDeGrain_SE(clip input, int "mode", int "thr", bool "_grey")

{
  _grey       = default(_grey, false)
input = isYUY2(input) ? input.Interleaved2Planar(_grey) : input
	mode = default(mode, 5)
	thr  = default(thr,  8)
	rg = RemoveGrain(input, mode=mode, modeU=_grey ? -1 : mode, Planar=true)
	tr = TemporalRepair(rg, input, grey=_grey, Planar=true)
tr = isYUY2(input) ? tr.Planar2Interleaved(_grey) : tr
        fs = FluxSmoothT(tr,thr)
	Return(fs)
	 
}

function RemoveDirtSE(clip input, clip fcomp, clip bcomp, int "limit", bool "_grey", int "noisy", int "dist", int "gmthreshold", int "repmode", int "clmode", int "resrepmode", string "RDSE_params")

{
  _grey       = default(_grey, false)
  limit       = default(limit,8)
  noisy       = default(noisy,12)
  dist        = default(dist,1)
  gmthreshold = default(gmthreshold,50)
  RDSE_params = default(RDSE_params, "") # RestoreMotionBlocks
         YUY2 = isYUY2(input)
        avs25 = VersionNumber() < 2.60
input = YUY2 ? input.Interleaved2Planar(_grey) : input
fcomp = YUY2 ? fcomp.Interleaved2Planar(_grey) : fcomp
bcomp = YUY2 ? bcomp.Interleaved2Planar(_grey) : bcomp
      
	repmode = default(repmode, 16)
     resrepmode = default(resrepmode,repmode)
	 clmode = default(clmode,   5)
	clensed = interleave(fcomp,input,bcomp)
	clensed = YUY2 || avs25 ? clensed.Clense(cache=-1, grey=_grey, Planar=true).selectevery(3,1) : clensed.Clense(grey=_grey).selectevery(3,1)
      clensedn2 = repmode==0 && resrepmode!=0 ? undefined : YUY2 || avs25 ? Clense(input, cache=-1, grey=_grey, Planar=true) : Clense(input, grey=_grey)
	 sbegin = YUY2 || avs25 ? ForwardClense(input, cache=-1, grey=_grey, Planar=true) : ForwardClense(input, grey=_grey)
	   send = YUY2 || avs25 ? BackwardClense(input, cache=-1, grey=_grey, Planar=true) : BackwardClense(input, grey=_grey)
	    alt = SCSelect(input, sbegin, send, clensed, debug=false, Planar=true)
	    alt = repmode==0 ? alt : Repair(alt, input, mode=repmode, modeU=_grey ? -1 : repmode, Planar=true)
	restore = resrepmode==0 ? clensed : Repair(clensed, input, mode=resrepmode, modeU=_grey ? -1 : resrepmode, Planar=true)
      corrected = Eval("RestoreMotionBlocks(clensed, restore, neighbour=input, neighbour2=clensedn2, alternative=alt, gmthreshold=gmthreshold, \
				      dist=dist, dmode=2, debug=false, noise=limit, noisy=noisy, grey=_grey, Planar=true" + RDSE_params + ")")
	 postNR0 = clmode == 0 ? corrected : RemoveGrain(corrected, mode=clmode, modeU=_grey ? -1 : clmode, Planar=true)
	 postNR1 = isYUY2(input) ? postNR0.Planar2Interleaved(_grey) : postNR0
	 Return(postNR1)
	
}


function RemoveDirtMC_SE_nofade(clip input, int "cache")
{
    cache   = default(cache,10)
input
global rdcpm=0
global rdnpm=0
global rdnav=0
global rdmcsenofade = RemoveDirtMC_SE(twopass=false,mcthSAD=10000,clmode=0,rstr=1.5,PreNR=FFT3DFilter(sigma=4,plane=4,bw=16,bh=16,ow=8,oh=8,bt=3,wintype=1).ColorYUV(autogain=true).TemporalDeGrain_SE(5,9))
ScriptClip("""
preb=Blur(1.5)

cfr=current_frame
 rdppm=cfr<3 ? 0 : rdcpm
global rdcpm=cfr<2 ? 0 : rdnpm
global rdnpm=preb.trim(1,0).YPlaneMedian()

 rdpav=cfr<1 ? 0 : rdnav
global rdnav=preb.YDifferenceToNext()

fadedec=(rdcpm > rdnpm && rdcpm < rdppm) || (rdcpm < rdnpm && rdcpm > rdppm)

fadedec && (rdnav < 12 && rdpav < 12) ? last : rdmcsenofade

""")
cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)
}

function snofade(clip "o", clip "filtered", int "cache")
{
    cache   = default(cache,10)
o
global rdcpm=0
global rdnpm=0
global rdcav=0
global rdnav=0
global snofadeclip = filtered
ScriptClip("""
preb=Blur(1.5)

cfr=current_frame
 rdppm=cfr<3 ? 0 : rdcpm
global rdcpm=cfr<2 ? 0 : rdnpm
global rdnpm=preb.trim(1,0).YPlaneMedian()

 rdpav=cfr<3 ? 0 : rdcav
global rdcav=cfr<2 ? 0 : rdnav
global rdnav=preb.trim(1,0).AverageLuma()

fadedec=(rdcpm > rdnpm && rdcpm < rdppm) || (rdcpm < rdnpm && rdcpm > rdppm)

fadedec && (abs(rdcav-rdnav) < 12 && abs(rdcav-rdpav) < 12) ? last : snofadeclip

""")
cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)
}

function snofadeg(clip "o", clip "filtered")
{
o
gScriptClip("""
preb=Blur(1.5)

pav=preb.YPlaneMedian(-1)
cav=preb.YPlaneMedian()
nav=preb.YPlaneMedian(1)
 
fadedec=(cav > nav && cav < pav) || (cav < nav && cav > pav)
 
fadedec && (preb.YDifferenceToNext < 12 && preb.YDifferenceFromPrevious < 12) ? last : filtered
 
""", args="filtered")
}