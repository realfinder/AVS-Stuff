# SRFBob by Doom9 real.finder
# it should give Best of all of AVS Deinterlacers, it Plane to be as SAnimeBob3 but I change it to SRFBob
# 1.03
function SRFBob(clip clip, int "QTGMC_cleane", bool "TV_range", bool "Tryweave", int "Mi", val "emtn", val "emtn2")
{
UseQTGMC = Default(QTGMC_cleane, 0)
Tryweave = Default(Tryweave, true)
Mi       = Default(Mi, 2)

EEdic=clip.sh_Padding(2,4,2,4).nnedi3(-2,nsize=3,nns=4,qual=2,pscrn=3).crop(2,4,-2,-4,true)

emtnD = Defined(emtn)
emtnc = emtnD ? isclip(emtn) ? emtn : eval(emtn) : EEdic.removegrain().Repair(EEdic).reduceflicker(2).Repair(EEdic,4).interlaced60or50(BFF=!(GetParity(clip)))
emtnD2 = Defined(emtn2)
emtnc2 = emtnD2 ? isclip(emtn2) ? emtn2 : eval(emtn2) : emtnc.Blur(1.58,0).Sharpen(1,0)

tdeic=clip.TDeint(1,denoise=true,emtn=emtnc,map=4,Tryweave=Tryweave,blockx=8,blocky=4,Mi=2)

tdeicm=tdeic.Crop(0, clip.Height(), 0, 0)
tdeic=tdeic.Crop(0, 0, 0, -clip.Height())

tdeicm=tdeicm.mt_makediff(tdeic,v=3,u=3)
tdeicm=BlankClip(tdeicm,color_yuv=$000000).mt_adddiff(tdeicm,v=3,u=3).mt_adddiff(tdeicm,v=3,u=3).ColorYUV(levels="TV->PC")

tdeics=tdeic.TemporalRepair(EEdic,3)
sallpreserve = mt_merge(clip.sh_Padding(2,4,2,4).yadifmod2(mode=3,edeint=tdeics.sh_Padding(2,4,2,4)).crop(2,4,-2,-4,true).Repair(tdeics,3), clip.TDeint(1,denoise=true,emtn=emtnc2,edeint=EEdic.Repair(sh_SootheSS(tdeic,EEdic,25,25,uv=2),3)).Repair(tdeics),tdeicm,v=3,u=3)

QTGMCcleaneC = UseQTGMC > 0 ? sallpreserve.QTGMC(InputType=1, tr0=1, tr1=1, tr2=1,rep1=11, rep2=11, Sharpness=0.0,dct=8,TV_range=TV_range) : NOP()
UseQTGMC > 1 ? mt_merge(sallpreserve, QTGMCcleaneC.TemporalRepair(sallpreserve,3), tdeicm.mt_expand(v=3,u=3).TemporalSoften(5, 255, 255, mode=2).mt_expand(v=3,u=3).mt_binarize(1).mt_expand(v=3,u=3).mt_deflate(v=3,u=3),v=3,u=3) : UseQTGMC > 0 ? QTGMCcleaneC : sallpreserve
}