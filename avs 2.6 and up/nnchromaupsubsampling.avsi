# NNEDI chroma upsubsampling v0.73 by A.SONY
FUNCTION nnchromaupsubsampling(clip srco, bool "interlaced", bool "inv420", int "Threads") {

interlaced    = default(interlaced, false)
inv420        = default(inv420    , false)
Threads       = default( Threads, sh_GetUserGlobalIMTint(true))
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly   = sisphbd ? srco.isy() : srco.isy8()
sis420        = sisphbd ? srco.is420() : srco.isyv12()
sisfullchroma = sisphbd ? srco.is444() : srco.isyv24()

Assert(IsPlanar(srco) && isyuv(srco), "nnchromaupsubsampling: input clip must be planar YUV")
Assert(!(sis420 && !interlaced), "nnchromaupsubsampling: YV12/420 must be interlaced PAL DV")
Assert(!(sisfullchroma || sislumaonly), "nnchromaupsubsampling: this function for subsampling sources")

src = interlaced ? srco.SeparateFields().AssumeFrameBased() : srco

chromay8     = sisphbd ? Interleave(src.ExtractU(),src.ExtractV()) : Interleave(src.UToY8(),src.VToY8())
chromaturn   = !sis420 ? Eval("try { fTurnLeft(IsAvsPlus ? dontdoft : chromay8, mt=threads!=1) } catch(error_msg) { TurnLeft(chromay8) }").sh_Padding(2,2,2,2).nnedi3(field=0,dh=true).crop(2,4,-2,-4,true) : nop()
chromaupturn = !sis420 ? Eval("try { fTurnRight(IsAvsPlus ? dontdoft : chromaturn, mt=threads!=1) } catch(error_msg) { TurnRight(chromaturn) }") : nop()

chromaup = sis420 ? sisphbd ? YToUV(chromay8.SelectEven().sh_Padding(2,2,2,2,Threads).nnedi3(field=inv420 ? 1 : 0,dh=true,Threads=Threads).crop(2,4,-2,-4,true),chromay8.SelectOdd().sh_Padding(2,2,2,2,Threads).nnedi3(field=inv420 ? 0 : 1,dh=true,Threads=Threads).crop(2,4,-2,-4,true),src.ConvertToY()) : \
                              YToUV(chromay8.SelectEven().sh_Padding(2,2,2,2,Threads).nnedi3(field=inv420 ? 1 : 0,dh=true,Threads=Threads).crop(2,4,-2,-4,true),chromay8.SelectOdd().sh_Padding(2,2,2,2,Threads).nnedi3(field=inv420 ? 0 : 1,dh=true,Threads=Threads).crop(2,4,-2,-4,true),src.ConvertToY8()) : \
                    sisphbd ? YToUV(chromaupturn.SelectEven(),chromaupturn.SelectOdd(),src.ConvertToY()) : \
                              YToUV(chromaupturn.SelectEven(),chromaupturn.SelectOdd(),src.ConvertToY8())

return interlaced ? GetParity(srco) ? chromaup.AssumeFieldBased().AssumeTFF().Weave() : chromaup.AssumeFieldBased().AssumeBFF().Weave() : chromaup
}

# NNEDI chroma upsubsampling v0.43 by A.SONY (Inverse for testing purposes)
FUNCTION Innchromaupsubsampling(clip srco, bool "interlaced", int "Threads") {
srco
nnchromaupsubsampling(interlaced,true,Threads)
}

# NNEDI yv12 point subsampling fix v0.52 by A.SONY
# the output will be yv12 in mode 2 and yv16 in mode 1 and yv24 in mode 3, convert it back to yv12 by the method you like, the default setting work with Konjiki no Gash Bell!! S1 R2J DVD
FUNCTION yv12pointsamplingnnfix(clip srco, bool "interlaced", bool "top", bool "left", int "mode", bool "leftshift", int "qual", int  "nns", int "nsize", int "etype", int "pscrn", bool "eed", int "vcheck", float "vthresh0", float "vthresh1", float "vthresh2", int "nrad", int "mdis", float "alpha", float "beta", float "gamma", int "nnrep", int "Threads" ) {
interlaced    = default(interlaced, false)
eed           = default(eed,      false)
top           = default(top,       true)
left          = default(left,      true)
mode          = default(mode,         1)
leftshift     = default(leftshift, left)
nnrep         = Default(nnrep, 0)
Threads       = default( Threads, sh_GetUserGlobalIMTint(true))

Assert(Isyv12(srco), "yv12pointsamplingnnfix: input must be YV12")

src = interlaced ? srco.SeparateFields().AssumeFrameBased() : srco

chromay8 = mode==3 || mode==1 ? Interleave(src.UToY8(),src.VToY8()) : nop()

chromay8n = mode==3 || mode==1 ? chromay8.sh_Padding(2,2,2,2,Threads) : chromay8
chromay8n = mode==3 || mode==1 ? chromay8n.nnedi3(field=top ? 1 : 0,dh=true, qual=qual, nns=nns, nsize=nsize, etype=etype, pscrn=pscrn, Threads=Threads ).crop(2,4,-2,-4,true) : chromay8n
chromay8e = (mode==3 || mode==1) && eed ? chromay8.EEdi3(field=top ? 1 : 0,dh=true,sclip=chromay8n,u=false,v=false,vcheck=vcheck, nrad=nrad, mdis=mdis, alpha=alpha, beta=beta, gamma=gamma, vthresh0=vthresh0, vthresh1=vthresh1, vthresh2=vthresh2, Threads=Threads) : chromay8n
chromay8 = (mode==3 || mode==1) && eed && nnrep > 0 ? nnrep > 1 ? slimit_dif(chromay8e,chromay8n,thr=4) : chromay8e.Repair(chromay8n,9) : chromay8e

chromay8 = mode==2 || mode==3 ? Eval("try { fTurnRight(mode==3 ? chromay8 : Interleave(src.UToY8(),src.VToY8()), mt=threads!=1) } catch(error_msg) { TurnRight(mode==3 ? chromay8 : Interleave(src.UToY8(),src.VToY8())) }") : chromay8

chromay8n = mode==2 || mode==3 ? chromay8.sh_Padding(2,2,2,2,Threads) : chromay8
chromay8n = mode==2 || mode==3 ? chromay8n.nnedi3(field=left ? 1 : 0,dh=true, qual=qual, nns=nns, nsize=nsize, etype=etype, pscrn=pscrn, Threads=Threads ).crop(2,4,-2,-4,true) : chromay8n
chromay8e = (mode==2 || mode==3) && eed ? chromay8.EEdi3(field=left ? 1 : 0,dh=true,sclip=chromay8n,u=false,v=false,vcheck=vcheck, nrad=nrad, mdis=mdis, alpha=alpha, beta=beta, gamma=gamma, vthresh0=vthresh0, vthresh1=vthresh1, vthresh2=vthresh2, Threads=Threads) : chromay8n
chromay8 = (mode==2 || mode==3) && eed && nnrep > 0 ? nnrep > 1 ? slimit_dif(chromay8e,chromay8n,thr=4) : chromay8e.Repair(chromay8n,9) : chromay8e

chromay8 = mode==2 || mode==3 ? Eval("try { fTurnLeft(chromay8, mt=threads!=1) } catch(error_msg) { TurnLeft(chromay8) }") : chromay8

chromay8 = mode==2 ? chromay8.BilinearResize(width(chromay8)/2,height(chromay8),src_left=leftshift ? -0.5 : 0.5) : chromay8
chromaup = YToUV(chromay8.SelectEven(),chromay8.SelectOdd(),src.ConvertToY8())
return interlaced ? GetParity(srco) ? chromaup.AssumeFieldBased().AssumeTFF().Weave() :  chromaup.AssumeFieldBased().AssumeBFF().Weave() : chromaup
}