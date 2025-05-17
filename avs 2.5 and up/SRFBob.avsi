# SRFBob by Doom9 real.finder
# it should give Best of all of AVS Deinterlacers, it Plane to be as SAnimeBob3 but I change it to SRFBob
# 1.01
function SRFBob(clip clip, bool "QTGMC_cleane", bool "TV_range")
{
UseQTGMC = Default(QTGMC_cleane, false)
EEdic=clip.nnedi3(-2,nsize=3,nns=4,qual=2,pscrn=3)
emtnc=EEdic.removegrain().Repair(EEdic).reduceflicker(2).Repair(EEdic,4).interlaced60or50(BFF=!(GetParity(clip)))
tdeic=clip.TDeintSFix(1,emtn=emtnc,map=4,denoise=true,Tryweave=true,blockx=8,blocky=4,Mi=5)
tdeicm=tdeic.Crop(0, clip.Height(), 0, 0)
tdeic=tdeic.Crop(0, 0, 0, -clip.Height())
sallpreserve = mt_merge(clip.yadifmod2(mode=3,edeint=tdeic.Repair(EEdic,7)), clip.TDeintSFix(1,emtn=emtnc.Blur(1.58,0).Sharpen(1,0),denoise=true,edeint=EEdic.Repair(sh_SootheSS(tdeic,EEdic,25,25,uv=3),3)).Repair(tdeic),tdeicm,v=3,u=3)
UseQTGMC ? sallpreserve.QTGMC(InputType=1, tr0=1, tr1=1, tr2=1,rep1=11, rep2=11, Sharpness=0.0,dct=8,TV_range=TV_range) : sallpreserve
}