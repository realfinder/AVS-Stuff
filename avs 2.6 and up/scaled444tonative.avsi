# base on ChromaReconstructor and fulltonative by feisty2
# 1.12

function scaled444tonative (clip src, int "a", float "h", int "lowpass", int "mode", int "device_type", int "device_id", int "fast", float "sDev", float "iDev", float "cs", bool "d2", int "kernS", int "kernI", int "resType", bool "onecall", string "CkJMod", string "cplace")
{
	sisphbd 	= AvsPlusVersionNumber > 2294
	sishasalpha	= sisphbd ? src.hasalpha : false
	fullchr		= sisphbd ? src.is444() : src.isyv24()
	halfchr		= sisphbd ? src.is420() : src.isyv12()
	sis411      = src.isyv411()
	CkJMod     	= default(CkJMod, "none").LCase()
	cplace      = Default(cplace, "MPEG2")
	CkJMod != "none" ? Assert(!fullchr, "scaled444tonative: CkJMod not work with full chroma sampling input") : Assert(fullchr, "scaled444tonative: need 444 input")
	siscfloat	= sisphbd ? IsVideoFloat(src) : false
	fast     	= default(fast, 0)
	a	     	= default(a, fast!=0 ? 1 : 32)
	h	     	= default(h, 6.4)
	lowpass     	= default(lowpass, 6)
	mode     	= default(mode, 0)
	sDev		= default (sDev,      1.4)
	iDev		= default (iDev,      7)
	d2		= default (d2,        true)
	kernS		= default (kernS,        8)
	kernI		= default (kernI,        3)
	restype		= default (restype,      0)
	onecall     	= default(onecall, false)
	pad             = fast > -1 ? sishasalpha ? src.RemoveAlphaPlane().sh_padding (4, 4, 4, 4) : src.sh_padding (4, 4, 4, 4) : src
	srcy            = sisphbd ? ExtractY(pad) : ConvertToY8(pad)
	pad             = CkJMod != "none" ? pad.edi_rpow2(sis411 ? 4 : 2,halfchr ? 2 : 1,edi=CkJMod, cshift="bilinearresize",Y=false,cplace=cplace,bordfix=false) : pad
	srcu            = sisphbd ? ExtractU(pad) : UToY8(pad)
	srcv            = sisphbd ? ExtractV(pad) : VToY8(pad)
	srcu            = CkJMod != "none" ? sis411 ? srcu.bilinearresize(width(srcy),height(srcy),src_left=-0.375) : !(halfchr && cplace != "MPEG2") ? srcu.bilinearresize(width(srcy),height(srcy),src_left=-0.25) : srcu : srcu
	srcv            = CkJMod != "none" ? sis411 ? srcv.bilinearresize(width(srcy),height(srcy),src_left=-0.375) : !(halfchr && cplace != "MPEG2") ? srcv.bilinearresize(width(srcy),height(srcy),src_left=-0.25) : srcv : srcv
	u4x             = CkJMod != "none" ? nop() : abs(fast) < 3 && abs(fast) != 1 ? pad.nnedi3_rpow2(2, nns=4, qual=2, etype=1, nsize=0).nnedi3_rpow2(2, nns=4, qual=2, etype=1, nsize=0) : pad
	luma            = CkJMod != "none" ? srcy : abs(fast) < 3 && abs(fast) != 1 ? sisphbd ? ExtractY(u4x) : ConvertToY8(u4x) : srcy
	u               = siscfloat ? expr(CkJMod != "none" ? srcu : ExtractU(u4x), "x 0.5 +") : CkJMod == "none" && abs(fast) < 3 && abs(fast) != 1 ? sisphbd ? ExtractU(u4x) : UToY8(u4x) : srcu
	v               = siscfloat ? expr(CkJMod != "none" ? srcv : ExtractV(u4x), "x 0.5 +") : CkJMod == "none" && abs(fast) < 3 && abs(fast) != 1 ? sisphbd ? ExtractV(u4x) : VToY8(u4x) : srcv
	chroma		= onecall ? Interleave(u,v) : nop()
	luma            = onecall ? Interleave(luma,luma) : luma
	u               = onecall ? chroma : u
	unew            = abs(fast) > 1 ? U.svsTBilateral(diameterL=Round(pow(2 * a + 1,2)), sDevL=sDev, iDevL=iDev, csL=cs, d2=d2, chroma=false, ppclip=luma, kernS=kernS, kernI=kernI, resType=resType) : KNLMeansCL (u, d=0, a=a, s=0, h=h, wref=1.0, rclip=luma, device_type=device_type, device_id=device_id)
	unew            = CkJMod == "none" && abs(fast) < 3 && abs(fast) != 1 ? sresizexnr (unew, pad.width, pad.height, src_left=-1.5, src_top=-1.5, kernel="spline64") : unew
	vnew            = !onecall ? abs(fast) > 1 ? V.svsTBilateral(diameterL=Round(pow(2 * a + 1,2)), sDevL=sDev, iDevL=iDev, csL=cs, d2=d2, chroma=false, ppclip=luma, kernS=kernS, kernI=kernI, resType=resType) : KNLMeansCL (v, d=0, a=a, s=0, h=h, wref=1.0, rclip=luma, device_type=device_type, device_id=device_id) : nop()
	vnew            = !onecall ? CkJMod == "none" && abs(fast) < 3 && abs(fast) != 1 ? sresizexnr (vnew, pad.width, pad.height, src_left=-1.5, src_top=-1.5, kernel="spline64") : vnew : nop()
	unew            = CkJMod != "none" ? unew.Repair(U, 1) : unew
	vnew            = !onecall && CkJMod != "none" ? vnew.Repair(U, 1) : vnew
	uhi             = CkJMod != "none" ? mt_makediff(Unew, blur(Unew, 1.58).blur(1.58)) : mode == 1 ? mt_MakeDiff (unew, fgauss_h (unew, p=lowpass)) : mt_MakeDiff (unew, fgauss (unew, p=lowpass))
	vhi             = !onecall ? CkJMod != "none" ? mt_makediff(Vnew, blur(Vnew, 1.58).blur(1.58)) : mode == 1 ? mt_MakeDiff (vnew, fgauss_h (vnew, p=lowpass)) : mt_MakeDiff (vnew, fgauss (vnew, p=lowpass)) : nop()
	ufinal          = !siscfloat ? srcu.mt_AddDiff(uhi) : expr(mt_MakeDiff(expr(srcu, "x 0.5 +"), uhi), "x 0.5 -")
	vfinal          = !onecall ? !siscfloat ? srcv.mt_AddDiff(vhi) : expr(mt_MakeDiff(expr(srcv, "x 0.5 +"), vhi), "x 0.5 -") : nop()
	fmerge          = sisphbd ? CombinePlanes(!onecall ? UFinal : UFinal.SelectEven(), !onecall ? VFinal : UFinal.SelectOdd(),srcy,planes="UVY") : YToUV(!onecall ? UFinal : UFinal.SelectEven(), !onecall ? VFinal : UFinal.SelectOdd(), srcy)
	fclip           = fast > -1 ? Crop (fmerge, 4, 4, -4, -4) : fmerge
	fclip           = sishasalpha ? fclip.AddAlphaPlane(src.ExtractA) : fclip
	return fclip
	}

function fgauss_h(clip src, int "p")
{
             p        = default(p, 30)
             w        = src.width
             h        = src.height
             upsmp    = resizex(src, w * 2, h, kernel="gauss", a1=100)
             return resizex(upsmp, w, h, kernel="gauss", a1=p)
}

function fgauss(clip src, int "p")
{
             p        = default(p, 30)
             w        = src.width
             h        = src.height
             upsmp    = resizex(src, w * 2, h * 2, kernel="gauss", a1=100)
             return resizex(upsmp, w, h, kernel="gauss", a1=p)
}