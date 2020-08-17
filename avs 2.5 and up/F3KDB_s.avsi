###############
# F3KDB_3 and it sisters v1.337


function F3KDB_3(clip clip, int "range", int "Y", int "Cb", int "Cr", \
		int "grainY", int "grainC", int "sample_mode", int "seed", \
		bool "blur_first", bool "dynamic_grain", int "opt", bool "mt", \
		int "dither_algo", bool "keep_tv_range", int "input_mode", \
		int "input_depth", int "output_mode", int "output_depth", \
		int "random_algo_ref", int "random_algo_grain", \
		float "random_param_ref", float "random_param_grain", bool "chroma", int "pass", bool "lastpassgrain", bool "masking", float "mask_thr", int "mask_radius", bool "lastpassmask") {

		try { 
sample_mode = default (sample_mode, 4)
pass = default (pass, sample_mode==4 ? 2 : 1)
isgrYd = defined(grainY)
nlpgra  = default (lastpassgrain, !isgrYd && pass > 1)
nlpmsk  = default (lastpassmask, nlpgra && pass > 1)
ngrainY = isgrYd && !nlpgra ? grainY : pass > 1 ? 0 : pass < 2 && nlpgra ? undefined : 0
chromad = defined(chroma)
chroma      = default (chroma, true)
cb = default (cb, chroma ? undefined : 0)
cr = default (cr, chroma ? undefined : 0)
ngrainC = default (grainC, chromad && chroma ? 64 : chroma ? ngrainY : 0)
sisphbd   = AvsPlusVersionNumber > 2294
hbdbits = sisphbd ? clip.BitsPerComponent() : 8
sischbd  = hbdbits > 8
input_depth = defined(input_mode) ? input_mode!=0 ? (defined(input_depth) ? input_depth : 16) : hbdbits : hbdbits
output_depth = defined(output_depth) ? output_depth : sischbd ? hbdbits : defined(output_mode) ? output_mode>0 ? 16 : 8 : 8
input_mode  = default (input_mode, input_depth==8 || sischbd ? 0 : 1)
noutput_mode = default (output_mode, input_mode)
masking      = default (masking, true)
sisyuy2 = clip.isyuy2()
pclip   = sisyuy2 ? clip.ConvertToYV16() : clip
pclip   = input_mode==1 ? pclip.ConvertFromStacked(input_depth) : input_mode==2 ? pclip.ConvertFromDoubleWidth(input_depth) : pclip

Assert(!(input_mode>0 && sischbd), "F3KDB_3: lsb/interleaved hack is not Compatible with HBD")
Assert(!(noutput_mode>0 && sischbd), "F3KDB_3: lsb/interleaved hack is not Compatible with HBD")
Assert(isYUV(clip), "F3KDB_3: YUV only")

outd2 = pass > 1 && sisphbd ? 16 : output_depth

pclip.neo_F3KDB(range, Y, Cb, Cr, \
		ngrainY, ngrainC, sample_mode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, \
		outd2, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain)

pclip = masking && (nlpmsk ? pass < 2 : true) && outd2 != input_depth ? pclip.convertbits(outd2,dither=outd2 < input_depth ? 1 : undefined) : pclip

masking && (nlpmsk ? pass < 2 : true) ? mt_merge(last,pclip,pclip.F3KDB_3_masking(mask_thr, mask_radius), u=chroma ? 3 : 2, v=chroma ? 3 : 2, luma=chroma) : last

noutput_mode==1 ? pclip.convertbits(16,false).ConvertToStacked() : noutput_mode==2 ? pclip.convertbits(16,false).ConvertToDoubleWidth() : last

        pass > 1 ? last.F3KDB_3(range, Y, Cb, Cr, \
		ngrainY, grainC, sample_mode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		pass > 1 && sisphbd ? 16 : input_depth, noutput_mode, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, pass - 1, nlpgra, masking, mask_thr, mask_radius) : last

sisyuy2 ? ConvertToYUY2() : last

} catch(error_msg) {clip.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, sample_mode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, output_mode, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, pass, lastpassgrain, masking, mask_thr, mask_radius, lastpassmask)}
}


function L_F3KDB_3(clip clip, int "range", int "Y", int "Cb", int "Cr", \
		int "grainY", int "grainC", int "sample_mode", int "seed", \
		bool "blur_first", bool "dynamic_grain", int "opt", bool "mt", \
		int "dither_algo", bool "keep_tv_range", int "input_mode", \
		int "input_depth", int "output_mode", int "output_depth", \
		int "random_algo_ref", int "random_algo_grain", \
		float "random_param_ref", float "random_param_grain", bool "chroma", int "pass", bool "lastpassgrain", bool "masking", float "mask_thr", int "mask_radius", bool "lastpassmask") {
sisavs26     = !(VersionNumber() < 2.60)
sample_mode = default (sample_mode, 4)
pass = default (pass, sample_mode==4 ? 2 : 1)
isgrYd = defined(grainY)
lpgra  = default (lastpassgrain, !isgrYd && pass > 1)
lpmsk  = default (lastpassmask, lpgra && pass > 1)
grainY = isgrYd && !lpgra ? grainY : pass > 1 ? 0 : pass < 2 && lpgra ? undefined : 0
chromad = defined(chroma)
chroma      = default (chroma, true)
cb = default (cb, chroma ? undefined : 0)
cr = default (cr, chroma ? undefined : 0)
pgrainC = default (grainC, chromad && chroma ? 64 : chroma ? grainY : 0)
sisphbd   = AvsPlusVersionNumber > 2294
hbdbits  = sisphbd ? clip.BitsPerComponent() : 8
sischbd  = sisphbd ? hbdbits > 8 : false
input_mode  = default (input_mode, 0)
output_mode = default (output_mode, sischbd ? 3 : defined(output_depth) ? output_depth > 8 ? 3 : input_mode : input_mode)
sm4lsb = output_mode != 0 && output_mode != 3 && sample_mode == 4
sm4i16 = sm4lsb && output_mode == 2
output_mode = sm4i16 ? 1 : output_mode
masking      = default (masking, true)
Assert(masking && output_mode==2 ? sample_mode==4 : true, "L_F3KDB_3: when using output_mode=2 masking only work with sample_mode=4")
sisyuy2 = clip.isyuy2()
pclip   = sisyuy2 && sisavs26 ? clip.ConvertToYV16() : clip

sample_mode != 4 ? Eval("""
i_mode  = sischbd ? 2 : input_mode
o_mode = output_mode == 3 ? 2 : output_mode
i_depth   = sischbd ? clip.BitsPerComponent() : defined(input_depth) ? input_depth : 8

Assert(!(sischbd && (input_mode>0)), "L_F3KDB_3: lsb/interleaved hack is not Compatible with HBD")
Assert(isYUV(clip), "L_F3KDB_3: YUV only")
noSquarechr = sisphbd ? (is422(clip) || isyv411(clip)) : sisavs26 ? (isyv16(clip) || isyv411(clip)) : false
sisavs26 ? nop() : Assert(!(sample_mode==3 && chroma && (sisyuy2 || noSquarechr)), "L_F3KDB_3: Square chroma only for sample_mode > 2")

o_depth     = defined(output_depth) ? output_depth : i_depth
smode       = sample_mode > 2 ? 1 : sample_mode

Yd = defined(y)
Cbd = defined(Cb)
Crd = defined(Cr)
grainCd = defined(grainC)
doUp = (grainCd ? grainC !=0 : true) || (Cbd ? Cb != 0 : true)
doVp = (grainCd ? grainC !=0 : true) || (Crd ? Cr != 0 : true)
dosep = chroma && (sisyuy2 || noSquarechr) && (doUp || doVp)
ktvr = defined(keep_tv_range)
Ypclip   = dosep ? sisphbd ? converttoY(pclip) : converttoY8(pclip) : pclip
Ypclip   = sample_mode == 3 ? Ypclip.sTryFTurnLeft(chroma,input_mode==2 ? 16 : input_mode==1 ? 88 : 8,mt) : Ypclip
Ypclip   = sischbd ? i_depth != 8 ? Ypclip.convertbits(16,false).ConvertToDoubleWidth() : Ypclip.ConvertToDoubleWidth() : Ypclip
Upclip   = dosep ? sisphbd ? ExtractU(pclip) : UToY8(pclip) : nop()
Upclip   = dosep ? sample_mode == 3 ? Upclip.sTryFTurnLeft(chroma,input_mode==2 ? 16 : input_mode==1 ? 88 : 8,mt) : Upclip : nop()
Upclip   = dosep ? sischbd ? i_depth != 8 ? Upclip.convertbits(16,false).ConvertToDoubleWidth() : Upclip.ConvertToDoubleWidth() : Upclip : nop()
Vpclip   = dosep ? sisphbd ? ExtractV(pclip) : VToY8(pclip) : nop()
Vpclip   = dosep ? sample_mode == 3 ? Vpclip.sTryFTurnLeft(chroma,input_mode==2 ? 16 : input_mode==1 ? 88 : 8,mt) : Vpclip : nop()
Vpclip   = dosep ? sischbd ? i_depth != 8 ? Vpclip.convertbits(16,false).ConvertToDoubleWidth() : Vpclip.ConvertToDoubleWidth() : Vpclip : nop()
Ypclip  = ((isgrYd ? grainY !=0 : true) || (Yd ? Y != 0 : true)) && dosep ? Ypclip.F3KDB(range, Y, 0, 0, \
		grainY, 0, smode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, false, i_mode, \
		i_depth, o_mode, o_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain) : dosep ? Ypclip : Ypclip.F3KDB(range, Y, Cb, Cr, \
		grainY, pgrainC, smode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, i_mode, \
		i_depth, o_mode, o_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain)
Cbclip  = doUp && dosep ? Upclip.F3KDB(range, Cb, 0, 0, \
		pgrainC, 0, smode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, false, i_mode, \
		i_depth, o_mode, o_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain) : Upclip
Crclip  = doVp && dosep ? Vpclip.F3KDB(range, Cr, 0, 0, \
		pgrainC, 0, smode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, false, i_mode, \
		i_depth, o_mode, o_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain) : Vpclip
		
Ypclip  = output_mode == 3 && sischbd || o_depth>8 ? Ypclip.ConvertFromDoubleWidth(o_depth) : Ypclip
Ypclip  = sample_mode == 3 ? Ypclip.sTryFTurnRight(chroma,output_mode==2 ? 16 : output_mode==1 ? 88 : 8,mt) : Ypclip
Cbclip  = !dosep ? nop() : output_mode == 3 && sischbd || o_depth>8 ? Cbclip.ConvertFromDoubleWidth(o_depth) : Cbclip
Cbclip  = !dosep ? nop() : sample_mode == 3 ? Cbclip.sTryFTurnRight(chroma,output_mode==2 ? 16 : output_mode==1 ? 88 : 8,mt) : Cbclip
Crclip  = !dosep ? nop() : output_mode == 3 && sischbd || o_depth>8 ? Crclip.ConvertFromDoubleWidth(o_depth) : Crclip
Crclip  = !dosep ? nop() : sample_mode == 3 ? Crclip.sTryFTurnRight(chroma,output_mode==2 ? 16 : output_mode==1 ? 88 : 8,mt) : Crclip

dosep ? sisphbd ? CombinePlanes(Cbclip, Crclip , Ypclip, planes="UVY",sample_clip=clip) : YToUV(Cbclip, Crclip , Ypclip) : Ypclip
dosep && ktvr ? keep_tv_range ? sisphbd ? Limiter(16, 235, 16, 240, autoscale=true) : Limiter(16, 235, 16, 240) : last : last

""") : sm4lsb ? Dither_merge16(pclip.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, 1, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, 1, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, 1, pass == 1 ? lpgra : false, false),pclip.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, 3, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, 1, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, 1, pass == 1 ? lpgra : false, false),BlankClip(input_mode != 1 ? pclip.Bitdepth(from=input_mode == 2 ? 16 : 8, to=88) : pclip,color_yuv=color_gray).BitdepthMsb(bitdepth=88).Bitdepth(from=8, to=88),luma=chroma) \
		: Merge(pclip.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, 1, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, output_mode, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, 1, pass == 1 ? lpgra : false, false),pclip.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, 3, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, output_mode, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, 1, pass == 1 ? lpgra : false, false))

input_depth = defined(input_depth) ? input_depth : input_mode!=0 ? 16 : hbdbits
output_depth = defined(output_depth) ? output_depth : sischbd ? hbdbits : output_mode>0 ? 16 : 8
pclip = masking && (lpmsk ? pass < 2 : true) && output_mode == 3 && output_depth != input_depth ? pclip.convertbits(output_depth,dither=output_depth < input_depth ? 1 : undefined) : pclip
masking && (lpmsk ? pass < 2 : true) ? sm4i16 || output_mode == 1 ? Dither_merge16_8(last,input_mode!=1 ? pclip.Bitdepth(from=input_mode==2 ? 16 : 8, to=88) : pclip,input_mode!=0 ? pclip.Bitdepth(from=input_mode==2 ? 16 : 88, to=8).F3KDB_3_masking(mask_thr, mask_radius) : pclip.F3KDB_3_masking(mask_thr, mask_radius), luma=chroma) : mt_merge(last,pclip,pclip.F3KDB_3_masking(mask_thr, mask_radius), u=chroma ? 3 : 2, v=chroma ? 3 : 2, luma=chroma) : last
output_mode = sm4i16 ? 2 : output_mode
sm4i16 ? Bitdepth(from=88, to=16) : last

        pass > 1 ? last.L_F3KDB_3(range, Y, Cb, Cr, \
		grainY, grainC, sample_mode, seed, \
		blur_first, dynamic_grain, opt, mt, \
		dither_algo, keep_tv_range, input_mode, \
		input_depth, output_mode, output_depth, \
		random_algo_ref, random_algo_grain, \
		random_param_ref, random_param_grain, chroma, pass - 1, lpgra, masking, mask_thr, mask_radius) : last

sisyuy2 ? ConvertToYUY2() : last

}


function F3KDB_3_masking(clip c, float "mask_thr", int "mask_radius")
{
sisavs26     = !(VersionNumber() < 2.60)
mthr = default(mask_thr, 2)
mrad = default(mask_radius, 2)
Assert(mrad > 0, "F3KDB_3_masking: mask_radius must be more than 0")

thr_lo = string(max(mthr * 0.75, 1) - 0.0001)
thr_hi = string(max(mthr,         1) + 0.0001)

c
mrad > 1 ? sisavs26 ? mt_lutxy (mt_expand_multi (sw=mrad, sh=mrad, mode="ellipse"), mt_inpand_multi (sw=mrad, sh=mrad, mode="ellipse"), "x y -",clamp_float=true, use_expr=1) : mt_lutxy (mt_expand_multi (sw=mrad, sh=mrad, mode="ellipse"), mt_inpand_multi (sw=mrad, sh=mrad, mode="ellipse"), "x y -") : mt_edge (mode="min/max", thY1=0, thY2=255)
sisavs26 ? mt_lut (expr="x "+thr_lo+" scalef - "+thr_hi+" scalef "+thr_lo+" scalef - / 0 1 clip range_max *", use_expr=2) : mt_lut (expr="x "+thr_lo+" - "+thr_hi+" "+thr_lo+" - / 0 1 clip 255 *")
removegrain (22, -1)
mrad > 1 ? removegrain (11, -1) : last
mrad > 2 ? removegrain (20, -1) : last
}


# F3KDB_3_adg F3KDB_3 with adaptive grain

function F3KDB_3_adg(clip clip, int "range", int "Y", int "Cb", int "Cr", int "seed", \
        bool "blur_first", bool "dynamic_grain", int "opt", bool "mt", \
        int "dither_algo", bool "keep_tv_range", int "output_depth", \
        int "random_algo_ref", int "random_algo_grain", \
        float "random_param_ref", float "random_param_grain", bool "chroma", int "pass", bool "masking", float "mask_thr", int "mask_radius", float "gf", float "gmin", float "gmax", bool "useL_F3KDB_3") {
sisphbd = AvsPlusVersionNumber > 2294
bits = sisphbd ? BitsPerComponent(clip) : 8
output_depth = default(output_depth, bits) 
!sisphbd ? Assert(bits==8, "F3KDB_3_adg: this avs not work with HBD") : nop()
pass = default (pass, 2)
masking = default (masking, true)
gf = default (gf, 512.0) / pow(2, 16 - bits)
gmin = default (gmin, 12.0)
gmax = default (gmax, 100.0)
uL_F_3 = default (useL_F3KDB_3, false)

sF_3 = uL_F_3 ? "L_F3KDB_3" : "F3KDB_3"

pass != 1 ? eval("clip." + sF_3 + "(range, Y, Cb, Cr, 0, 0, 4, seed, \
        blur_first, dynamic_grain, opt, mt, \
        dither_algo, keep_tv_range, 0, \
        undefined, undefined, sisphbd && pass > 2 ? 16 : output_depth, \
        random_algo_ref, random_algo_grain, \
        random_param_ref, random_param_grain, chroma, 1, false, false, mask_thr, mask_radius)") : clip
		
pass > 1 ? last.F3KDB_3_adg(range, Y, Cb, Cr, seed, \
        blur_first, dynamic_grain, opt, mt, \
        dither_algo, keep_tv_range, output_depth, \
        random_algo_ref, random_algo_grain, \
        random_param_ref, random_param_grain, chroma, pass - 1, masking, mask_thr, mask_radius, gf, gmin, gmax, uL_F_3) : last
		
pass == 1 && bits != output_depth ? convertbits(output_depth,dither=output_depth < bits ? 1 : undefined) : last
symax = pass == 1 ? BitLShift(1, output_depth) - 1 : nop()
F3KDB_rt = pass == 1 ? "last." + sF_3 + "(range, Y, Cb, Cr, \
        round(max(min((symax - AverageLuma())/gf,gmax),gmin)), 0, 4, seed, \
        blur_first, dynamic_grain, opt, mt, \
        dither_algo, keep_tv_range, 0, \
        undefined, undefined, output_depth, \
        random_algo_ref, random_algo_grain, \
        random_param_ref, random_param_grain, chroma, 1, false, masking, mask_thr, mask_radius)" : nop()
pass == 1 ? last.gScriptClip("""
eval(F3KDB_rt)
""",args="range, Y, Cb, Cr, seed, blur_first, dynamic_grain, opt, mt, dither_algo, keep_tv_range, output_depth, random_algo_ref, random_algo_grain, random_param_ref, random_param_grain, chroma, masking, mask_thr, mask_radius, gf, gmin, gmax, symax, F3KDB_rt") : last
}