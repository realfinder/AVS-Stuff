# SRFTFMBob by Doom9 real.finder
# 1.01
function SRFTFMBob(clip clip, int "cleane", bool "lessrep", int "QTGMC_cleane", bool "TV_range")
{
sUsefcleaners = Default(cleane, 1) #2 better for Field blended
lessrep = Default(lessrep, false)
UseQTGMC = Default(QTGMC_cleane, 0)

EEdic=clip.sh_Padding(2,4,2,4).nnedi3(-2,nsize=3,nns=4,qual=2,pscrn=3).crop(2,4,-2,-4,true)

istff=GetParity(clip)
tfmdeibc=Interleave(clip.TFM(field=istff ? 1 : 0, slow=2, micmatching=0, mode=0, PP=0), clip.TFM(field=istff ? 0 : 1, slow=2, micmatching=0, mode=0, PP=0))

EEdicrep = sUsefcleaners > 0 && lessrep ? tfmdeibc.SeparateFields().Repair(EEdic.SeparateFields(),18).Weave() : EEdic
sUsefcleaners > 0 ? lessrep ? tfmdeibc.TemporalRepair(EEdicrep,3).Repair(tfmdeibc,17) : tfmdeibc.TemporalRepair(EEdicrep,3) : tfmdeibc

tfmbmask = sUsefcleaners > 1 ? 
                             \ sUsefcleaners == 2 ? Interleave(SelectEven().Sharpen(0,1).Blur(1.58).CombMask2(3,3),SelectOdd().Sharpen(0,1).Blur(1.58).CombMask2(3,3)) :
                             \ sUsefcleaners == 3 ? mt_logic(Blur(1.58).Sharpen(0,1).CombMask2(),EEdic.Blur(1.58,0).CombMask(),"and",u=3,v=3) : 
                                                  \ Interleave(mt_logic(SelectEven().Blur(1.58).Sharpen(0,1).CombMask2(),EEdic.SelectEven().Blur(1.58,0).CombMask(),"and",u=3,v=3),mt_logic(SelectOdd().Blur(1.58).Sharpen(0,1).CombMask2(),EEdic.SelectOdd().Blur(1.58,0).CombMask(),"and",u=3,v=3)) :
                             \ nop()

sUsefcleaners > 1 ? sUsefcleaners == 2 ?last.MaskedMerge2(vinverse(), tfmbmask, blockx=16, blocky=8, Mi=2) : last.MT_Merge(vinverse(clip2=EEdic), tfmbmask.mt_expand(v=3,u=3), u=3,v=3) : last

QTGMCcleaneC = UseQTGMC > 0 ? QTGMC(InputType=1, tr0=1, tr1=1, tr2=1,rep1=11, rep2=11, Sharpness=0.0,dct=8,TV_range=TV_range) : NOP()
UseQTGMC > 1 ? mt_merge(last, QTGMCcleaneC.TemporalRepair(last,3), tfmbmask.mt_expand(v=3,u=3).TemporalSoften(5, 255, 255, mode=2).mt_expand(v=3,u=3).mt_binarize(1).mt_expand(v=3,u=3).mt_deflate(v=3,u=3),v=3,u=3) : UseQTGMC > 0 ? QTGMCcleaneC : last

}