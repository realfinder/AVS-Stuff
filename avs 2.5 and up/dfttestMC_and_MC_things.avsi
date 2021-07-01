####################################################
# script v2.124
####################################################
# Motion-compensated dfttest by twc
# Aka: Really Really Really Slow
#
# v2 by BakaProxy
# Aka: Even more Really Really Really slow
# Added: Recalculate, (proper) 16 bit input handling, dither_luma_rebuild and some masking to prevent 16 bit data loss from 8 bit Mdegrain and Mcompensate
#
#
# v3.936 by A.SONY
# make it work in normal avs again and some fix, and not that slow if you use it without lsb/lsb_in
# add slice bool to use it to avoid artifacts with avstp
# clean up
# New Features
#
# Requirements:
# dfttest
# MVTools2
# 
# Suggested:
# Dither (for stack16 processing)
#
# Description of function parameters:
#
# pp = Clip to calculate vectors from (default input)
# mc = Number of frames in each direction to compensate (default 2, max 5)
# mdg = Run MDeGrain before dfttest (default false)
# mdgSAD = thSAD for MDeGrain (default 400)
# lsb = stack16 output and processing (default false)
#
# dfttest Y, U, V, sigma, sbsize, sosize, tbsize, and dither are supported.
# Extra dfttest parameters may be passed via dfttest_params.
# MVTools2 pel, thSCD, thSAD, blksize, overlap, dct, search, and 
# searchparam are also supported. 
#
# sigma is the main control of dfttest strength.
# tbsize should not be set higher than mc * 2 + 1.

function dfttestMC(clip input, clip "pp", int "mc", bool "mdg", bool "Y", bool "U", bool "V", float "sigma", int "sbsize", int "sosize", int "tbsize", int "dither", bool "lsb",bool "lsb_in",bool "pp_lsb_in",int "super_filter",
	\ string "dfttest_params",float "rStr",float "Amp", int "mdgSAD", int "thSAD", int "thSCD1", int "thSCD2", bool "recalculate", bool "truemotion", int "pel", int "blksize", int "search", int "searchparam", int "overlap",
		\ int "dct", bool "slices", bool "luma_rebuild", string "nstring", string "sstring", string "ssx", string "ssy", string "sst", bool "mdg_domask", string "mdg_mask", clip "ppsuper", clip "super", clip "exmcclip", bool "hd", clip "input8", int "threads", string "chrnlocation", string "chrslocation", string "chrssx", string "chrssy", string "chrsst", bool "chromaMA", bool "MCContraSharp")
{
	# Set default options. Most external parameters are passed valueless.

	exmc = defined(exmcclip)
	threads = default(threads, sh_GetUserGlobalIMTint())
	bomt    = sh_GetUserGlobalIMTbool()
	dbomt   = defined(bomt)
	mc = default(mc, 2).min(5)
	Y = default(Y, true)
	U = default(U, true)
	V = default(V, true)
	chroma = (U || V)
	chromaMA = default(chromaMA, chroma)
	mdg = default(mdg, false)
	lsb = default(lsb, false)
	lsb_in = default(lsb_in, false)
	input8 = defined(input8) ? input8 : lsb_in ? input.ditherpost(mode=7,slice=slices,y=y ? 3 : 2,u=u ? 3 : chromaMA ? 2 : 1,v=v ? 3 : chromaMA ? 2 : 1) : input
	super_filter = default(super_filter,4)
	pp_enabled = defined(pp)
	pp_lsb_in = default(pp_lsb_in,(pp_enabled ? lsb_in ? (height(input) == height(pp)) ? true : false : false : false ))
	lsb_enable = false
	truemotion = default(truemotion,true)
	tbsize = default(tbsize, mc * 2 + 1)
	dfttest_params = default(dfttest_params, "")
	ox = defined(HD) ? nop() : input8.width()
	oy = defined(HD) ? nop() : input8.height()
	HD = defined(HD) ? HD : (ox > 1099 || oy > 599)
	pel = default( pel, HD ? 1 : 2 )
	blksize = default(blksize,HD ? 16:8)
	blksize2 = int(blksize/2) + (int(blksize/2)%2)
	search = default(search, HD ? 4 : 5)
	overlap = default(overlap,blksize2)
	overlap2 = int(overlap/2) + (int(overlap/2)%2)
	recalculate = default(recalculate,mdg)
	mdgSAD = default(mdgSAD,   400)
	mdgSAD2= mdgSAD/2
	thSAD  = default(thSAD ,   mdgSAD)
	rStr         = default( rStr, 1.0 )
	Amp          = default( Amp, 0.0625 )
	slices       = default(slices, true)
	luma_rebuild = default(luma_rebuild, true)
	mdg_domask   = default(mdg_domask, mdg)
	MCContraSharp = default(MCContraSharp, false)

	sisavs26  = VersionNumber() < 2.60 ? false : true

	# Set chroma parameters.
	plane  = U && !Y && !V ? 1 : V && !Y && !U ? 2 : chroma && !Y ? 3 : Y && chroma ? 4 : 0

	bomts = dbomt ? ", mt=bomt" : ""
	# Prepare supersampled clips.
	!exmc || mdg ? eval("""
	pp = (pp_enabled) && !defined(ppsuper) ? luma_rebuild ? pp.dither_luma_rebuild(S0=rStr,c=Amp,slice=slices,lsb_in=pp_lsb_in,lsb_out=false,uv=(choma?3:1)) : pp : nop()
	pp_super = defined(ppsuper) ? ppsuper : exmc ? nop() : pp_enabled ? MSuper(pp, pel=pel, chroma=pp_enabled ? chromaMA : chroma,rfilter=super_filter""" + bomts + """) : MSuper(input8, pel=pel, chroma=chromaMA""" + bomts + """)
	super = defined(super) ? super : pp_enabled ? input8.MSuper(pel=pel, levels=1, chroma=chroma""" + bomts + """) : pp_super
	recalc_sup = recalculate && pp_enabled ? MSuper(pp,pel=pel, levels=1, chroma=chromaMA""" + bomts + """) : pp_super
	
	# Motion vector search.
	b5vec = mc == 5 ? MAnalyse(pp_super, delta=5, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	b4vec = mc >  3 ? MAnalyse(pp_super, delta=4, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	b3vec = mc >  2 ? MAnalyse(pp_super, delta=3, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	b2vec = mc >  1 ? MAnalyse(pp_super, delta=2, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	b1vec = MAnalyse(pp_super, delta=1, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """)
	f1vec = MAnalyse(pp_super, delta=1, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """)
	f2vec = mc >  1 ? MAnalyse(pp_super, delta=2, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	f3vec = mc >  2 ? MAnalyse(pp_super, delta=3, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	f4vec = mc >  3 ? MAnalyse(pp_super, delta=4, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	f5vec = mc == 5 ? MAnalyse(pp_super, delta=5, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion""" + bomts + """) : nop()
	""") : nop()

	
	recalculate ? Eval("""
	b5vec = mc == 5 ? MRecalculate(recalc_sup,b5vec , chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	b4vec = mc >  3 ? MRecalculate(recalc_sup,b4vec , chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	b3vec = mc >  2 ? MRecalculate(recalc_sup,b3vec , chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	b2vec = mc >  1 ? MRecalculate(recalc_sup,b2vec , chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	b1vec = MRecalculate(recalc_sup,b1vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """)
	f1vec = MRecalculate(recalc_sup,f1vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """)
	f2vec = mc >  1 ? MRecalculate(recalc_sup,f2vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	f3vec = mc >  2 ? MRecalculate(recalc_sup,f3vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	f4vec = mc >  3 ? MRecalculate(recalc_sup,f4vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	f5vec = mc == 5 ? MRecalculate(recalc_sup,f5vec, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap2, blksize=blksize2, dct=dct,thSAD=mdgSAD2,truemotion=truemotion""" + bomts + """) : nop()
	""") : nop()

	# Optional MDegrain.
	Eval("""
	try {
		degrained = lsb || lsb_in ? mc == 5 && mdg ? MDeGrain5(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, b4vec, f4vec, b5vec, f5vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2, lsb=true""" + bomts + """) :
			\ mc == 4 && mdg ? MDeGrain4(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, b4vec, f4vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2, lsb=true""" + bomts + """) :
			\ mc == 3 && mdg ? MDeGrain3(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2, lsb=true""" + bomts + """) :
			\ mc == 2 && mdg ? MDeGrain2(input8, super, b1vec, f1vec, b2vec, f2vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2, lsb=true""" + bomts + """) :
			\ mdg ? MDeGrain1(input8, super, b1vec, f1vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2, lsb=true""" + bomts + """) : lsb_in ? input : errmsggonext :
			\ errmsggonext
			degrained  = mdg_domask && mdg ? defined(mdg_mask) ? eval(mdg_mask) : DarkPreserve_function(degrained,input,lsb_in=lsb_in) : degrained
			degrained8 = lsb ? degrained.dither_get_msb() : degrained.ditherpost(mode=7,slice=slices,y=y ? 3 : 1,u=u ? 3 : 1,v=v ? 3 : 1)
			lsb_enable = true
		} catch(err_msg)
		{
		degrained8 = sisavs26 && mc == 5 && mdg ? MDeGrain5(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, b4vec, f4vec, b5vec, f5vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : 
			\ sisavs26 && mc == 4 && mdg ? MDeGrain4(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, b4vec, f4vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : 
			\ mc >= 3 && mdg ? MDeGrain3(input8, super, b1vec, f1vec, b2vec, f2vec, b3vec, f3vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) :
			\ mc == 2 && mdg ? MDeGrain2(input8, super, b1vec, f1vec, b2vec, f2vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) :
			\ mdg ? MDeGrain1(input8, super, b1vec, f1vec, thSAD=mdgSAD, plane=plane, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : input8
			degrained8 = mdg_domask && mdg ? defined(mdg_mask) ? eval(mdg_mask) : DarkPreserve_function(degrained8,input,lsb_in=lsb_in) : degrained8
		lsb_enable = false
		}
	""")
	lsbandsep = (lsb_enable || lsb_in || lsb) && (defined(chrnlocation) || defined(chrslocation) || defined(chrssx) || defined(chrssy) || defined(chrsst))
	Assert(!lsbandsep, "dfttestMC: Cannot use chr* things with lsb things.")
	!exmc ? eval("""
	degrained_super = mdg ? MSuper(degrained8, pel=pel, levels=1, chroma=chroma""" + bomts + """) : super
	b5clip = mc == 5 ? MCompensate(degrained8, degrained_super, b5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	b4clip = mc >  3 ? MCompensate(degrained8, degrained_super, b4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	b3clip = mc >  2 ? MCompensate(degrained8, degrained_super, b3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	b2clip = mc >  1 ? MCompensate(degrained8, degrained_super, b2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	b1clip = MCompensate(degrained8, degrained_super, b1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """)
	f1clip = MCompensate(degrained8, degrained_super, f1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """)
	f2clip = mc >  1 ? MCompensate(degrained8, degrained_super, f2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	f3clip = mc >  2 ? MCompensate(degrained8, degrained_super, f3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	f4clip = mc >  3 ? MCompensate(degrained8, degrained_super, f4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	f5clip = mc == 5 ? MCompensate(degrained8, degrained_super, f5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2""" + bomts + """) : nop()
	""") : nop()

	# Create compensated clip.
	interleaved = !exmc && mc == 5 ? Interleave(f5clip, f4clip, f3clip, f2clip, f1clip, degrained8, b1clip, b2clip, b3clip, b4clip, b5clip) :
		\ !exmc &&  mc == 4 ? Interleave(f4clip, f3clip, f2clip, f1clip, degrained8, b1clip, b2clip, b3clip, b4clip) :
		\ !exmc &&  mc == 3 ? Interleave(f3clip, f2clip, f1clip, degrained8, b1clip, b2clip, b3clip) :
		\ !exmc &&  mc == 2 ? Interleave(f2clip, f1clip, degrained8, b1clip, b2clip) :
		\ !exmc ?  Interleave(f1clip, degrained8, b1clip) : exmcclip
	mc16 = (Height(interleaved)) == (Height(degrained8)*2) && AvsPlusVersionNumber > 2294

      degrained = lsb_enable ? lsb_in && mdg ? input.Dither_limit_dif16(degrained, thr=1.0, elast=2.0) : degrained : nop()
      degrained = lsb_enable ? degrained : lsb_in ? mdg ? input.Dither_limit_dif16(degrained8.dither_convert_8_to_16(), thr=1.0, elast=2.0) : input : nop()

		degrained16mc = lsb_enable || lsb_in ? mc16 && !mdg ? nop() : degrained.changefps(interleaved,linear=true) : nop()

		mask = lsb_enable || lsb_in ? mc16 ? !mdg ? nop() : mt_logic(interleaved.ConvertFromStacked(),degrained16mc.ConvertFromStacked(), "xor",y=y ? 3 : 1,u=u ? 3 : 1,v=v ? 3 : 1).mt_binarize(0,y=y ? 3 : 1,u=u ? 3 : 1,v=v ? 3 : 1).ConvertToStacked() : mt_logic(interleaved,degrained16mc.dither_get_msb(), "xor",y=y ? 3 : 1,u=u ? 3 : 1,v=v ? 3 : 1).mt_binarize(0,y=y ? 3 : 1,u=u ? 3 : 1,v=v ? 3 : 1) : nop()

		interleaved16 = lsb_enable || lsb_in ? mc16 ? !mdg ? interleaved : Dither_merge16(degrained16mc,interleaved,mask,u=u ? 3 : 1,v=v ? 3 : 1) : Dither_merge16_8(degrained16mc,interleaved.dither_convert_8_to_16(),mask,u=u ? 3 : 1,v=v ? 3 : 1) : interleaved
		
	# Perform dfttest. Exception handling required for official dfttest.
	Eval("""
	try {
	lsb || lsb_enable || lsb_in ? nop() : isNotlsb
		filtered = Eval("dfttest(interleaved16, Y=Y, U=U, V=V, sigma=sigma, sbsize=sbsize, sosize=sosize, tbsize=tbsize, dither=dither, lsb=lsb,lsb_in=lsb_enable || lsb_in, nstring=nstring, sstring=sstring, ssx=ssx, ssy=ssy, sst=sst, threads=threads" + dfttest_params + ")")
		} catch(err_msg)
		{
		nfi=defined(nstring) ? FindStr(nstring,"a:") : 0
		salpha = nfi !=0 ? nstring.LeftStr(FindStr(nstring," ")-1) : undefined
		salpha = nfi !=0 ? RightStr(salpha,FindStr(salpha.RevStr,":")-1) : salpha
		alpha = nfi !=0 ? salpha.Value : salpha
		nlocation = defined(alpha) ? sh_StrReplace(nstring,"a:"+salpha+ " ","") : nstring
		sfi=defined(sstring) ? FindStr(sstring,"$") : 0
		slocation = sfi != 0 ? sh_StrReplace(sstring,"$" + " ","") : sstring
		filtered = Eval("sneo_dfttest(mc16 ? lsbNotWorthIt : interleaved, Y=Y ? 3 : 2, U=U ? 3 : 2, V=V ? 3 : 2, sigma=sigma, sbsize=sbsize, sosize=sosize, tbsize=tbsize, dither=dither, nlocation=nlocation, alpha=alpha, slocation=slocation, ssystem=sfi, ssx=ssx, ssy=ssy, sst=sst, threads=threads, fft_threads=threads, chrnlocation=chrnlocation, chrslocation=chrslocation, chrssx=chrssx, chrssy=chrssy, chrsst=chrsst" + dfttest_params + ")")
		}
	""")
		
	return selectEvery(filtered, mc * 2 + 1, mc)
	MCContraSharp ? last.ContraSharpening(input, MC=true, cb1=b1clip, cf1=f1clip, Super=degrained_super) : last
}


#### helper functions for admfilter, and some others MC warper/template

function sMCclips(clip input, clip pp_super, clip super, int "mc",
	\ int "thSAD", int "thSCD1", int "thSCD2", bool "truemotion", bool "chromaMA", int "blksize", int "search", int "searchparam", int "overlap",
		\ int "dct", bool "HD", clip "b1vec", clip "f1vec", clip "b2vec", clip "f2vec", clip "b3vec", clip "f3vec", clip "b4vec", clip "f4vec", clip "b5vec", clip "f5vec")
{
	sisphbd = AvsPlusVersionNumber > 2294
	bomt    = sh_GetUserGlobalIMTbool()
	dbomt   = defined(bomt)
	mc = default(mc, 2).min(5)
	HD = default(HD, false)
	truemotion = default(truemotion,true)
	blksize = default(blksize,HD ? 16:8)
	blksize2 = int(blksize/2) + (int(blksize/2)%2)
	search = default(search, HD ? 4 : 5)
	overlap = default(overlap,blksize2)
	thSAD  = default(thSAD ,   400)
	chromaMA = default(chromaMA, true)
	
	# Motion vector search.
	b5vec = mc == 5 ? defined(b5vec) ? b5vec : dbomt ? MAnalyse(pp_super, delta=5, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=5, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	b4vec = mc >  3 ? defined(b4vec) ? b4vec : dbomt ? MAnalyse(pp_super, delta=4, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=4, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	b3vec = mc >  2 ? defined(b3vec) ? b3vec : dbomt ? MAnalyse(pp_super, delta=3, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=3, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	b2vec = mc >  1 ? defined(b2vec) ? b2vec : dbomt ? MAnalyse(pp_super, delta=2, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=2, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	b1vec = defined(b1vec) ? b1vec : dbomt ? MAnalyse(pp_super, delta=1, isb=true, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=1, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion)
	f1vec = defined(f1vec) ? f1vec : dbomt ? MAnalyse(pp_super, delta=1, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt)           : MAnalyse(pp_super, delta=1, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion)
	f2vec = mc >  1 ? defined(f2vec) ? f2vec : dbomt ? MAnalyse(pp_super, delta=2, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=2, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	f3vec = mc >  2 ? defined(f3vec) ? f3vec : dbomt ? MAnalyse(pp_super, delta=3, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=3, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	f4vec = mc >  3 ? defined(f4vec) ? f4vec : dbomt ? MAnalyse(pp_super, delta=4, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=4, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()
	f5vec = mc == 5 ? defined(f5vec) ? f5vec : dbomt ? MAnalyse(pp_super, delta=5, chroma=chromaMA, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion, mt=bomt) : MAnalyse(pp_super, delta=5, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion) : nop()

	sbitsn = sisphbd ? input.BitsPerComponent() : 8
	super = sisphbd ? sbitsn != super.BitsPerComponent() ? super.ConvertBits(sbitsn) : super : super

	b5clip = mc == 5 ? dbomt ? MCompensate(input, super, b5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, b5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	b4clip = mc >  3 ? dbomt ? MCompensate(input, super, b4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, b4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	b3clip = mc >  2 ? dbomt ? MCompensate(input, super, b3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, b3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	b2clip = mc >  1 ? dbomt ? MCompensate(input, super, b2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, b2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	b1clip = dbomt ? MCompensate(input, super, b1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, b1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2)
	f1clip = dbomt ? MCompensate(input, super, f1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, f1vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2)
	f2clip = mc >  1 ? dbomt ? MCompensate(input, super, f2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, f2vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	f3clip = mc >  2 ? dbomt ? MCompensate(input, super, f3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, f3vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	f4clip = mc >  3 ? dbomt ? MCompensate(input, super, f4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, f4vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()
	f5clip = mc == 5 ? dbomt ? MCompensate(input, super, f5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2, mt=bomt) : MCompensate(input, super, f5vec, thSAD=thSAD, thSCD1=thSCD1, thSCD2=thSCD2) : nop()

	# Create compensated clip.
	interleaved = mc == 5 ? Interleave(f5clip, f4clip, f3clip, f2clip, f1clip, input, b1clip, b2clip, b3clip, b4clip, b5clip) :
		\  mc == 4 ? Interleave(f4clip, f3clip, f2clip, f1clip, input, b1clip, b2clip, b3clip, b4clip) :
		\ mc == 3 ? Interleave(f3clip, f2clip, f1clip, input, b1clip, b2clip, b3clip) :
		\ mc == 2 ? Interleave(f2clip, f1clip, input, b1clip, b2clip) :
		\ Interleave(f1clip, input, b1clip)
		
	return interleaved
}


function spp_super(clip input, clip "pp", bool "lsb", bool "lsb_in",bool "pp_lsb_in",int "super_filter",
	\ float "rStr",float "Amp", int "pel", bool "Y", bool "U", bool "V",
		\ bool "slices", bool "luma_rebuild", bool "HD", int "Subpixel", bool "chromaMA")
{
	threads = sh_GetUserGlobalIMTint()
	bomt    = sh_GetUserGlobalIMTbool()
	dbomt   = defined(bomt)
	Y = default(Y, true)
	U = default(U, true)
	V = default(V, true)
	chroma = (U || V)
	chromaMA = default(chromaMA, chroma)
	HD = default(HD, false)
	subpixel = default( subpixel,  2 )
	lsb_in = default(lsb_in, false)
	input8 = lsb_in && !pp_enabled ? input.ditherpost(mode=7,slice=slices,y=y ? 3 : 2,u=u ? 3 : chromaMA ? 2 : 1,v=v ? 3 : chromaMA ? 2 : 1) : input
	super_filter = default(super_filter,4)
	pp_enabled = defined(pp)
	pp_lsb_in = default(pp_lsb_in,(pp_enabled ? lsb_in ? (height(input) == height(pp)) ? true : false : false : false ))
	pel = default( pel, HD ? 1 : 2 )
	rStr         = default( rStr, 1.0 )
	Amp          = default( Amp, 0.0625 )
	slices       = default(slices, true)
	luma_rebuild = default(luma_rebuild, true)

	# Prepare supersampled clips.
	pp = (pp_enabled) ? luma_rebuild ? pp.dither_luma_rebuild(S0=rStr,c=Amp,slice=slices,lsb_in=pp_lsb_in,lsb=lsb_in,lsb_out=false,uv=(chromaMA?3:1)) : pp : nop()

	pelclip = pel>1 && subpixel == 3
	pclip = pelclip ? pel==4 ? pp.nnedi3_rpow2(rfactor=2,nns=4, threads).nnedi3_rpow2(rfactor=2,nns=4, threads) : pp.nnedi3_rpow2(rfactor=2,nns=4, threads) : undefined
	pp_super = pp_enabled ? dbomt ? MSuper(pp, pel=pel, chroma=chromaMA,rfilter=super_filter, pelclip=pclip, mt=bomt) : MSuper(pp, pel=pel, chroma=chromaMA,rfilter=super_filter, pelclip=pclip) : dbomt ? MSuper(input8, pel=pel, chroma=chromaMA, mt=bomt) : MSuper(input8, pel=pel, chroma=chromaMA)
		
	return pp_super
}

# sMCwarper v1.26
function sMCwarper(clip input, string "filter", int "mc", val "prefilter", bool "TV_range", clip "exmcclip", clip "super", clip "pp_super", bool "Y", bool "U", bool "V",
	\ int "thSAD", int "thSCD1", int "thSCD2", bool "truemotion", bool "chromaMA", int "blksize", int "search", int "searchparam", int "overlap", int "dct",
		\ bool  "HD",bool "slices",float "rStr",float "Amp", int "pel",int "super_filter", bool "interlaced", int "Subpixel", val "para1", val "para2", bool "chroma")
{
		exmc = defined(exmcclip)
		threads = sh_GetUserGlobalIMTint()
		bomt    = sh_GetUserGlobalIMTbool()
		dbomt   = defined(bomt)
		Assert(defined(filter), "sMCwarper: filter is needed")
		!exmc ? eval("""
		mc = default(mc, 2).min(5)
		chroma = default(chroma, true)
		chromaMA = default(chromaMA, true)
		Y = default(Y, true)
		U = default(U, chromaMA)
		V = default(V, U)
		TV_range  = default( TV_range, !(Isrgb(input)))
		interlaced = default( interlaced, false)
		HDbool = defined(HD)
		ox = HDbool ? nop() : input.width()
		oy = HDbool ? nop() : input.height()
		HD = HDbool ? HD : (ox > 1099 || oy > 599)
		pel = default( pel, HD ? 1 : 2 )
		input = interlaced ? input.SeparateFields() : input
		prefilterdef = defined(prefilter)
		prefilterisint = prefilterdef ? isint(prefilter) : false
		prefilterbool = prefilterdef ? isbool(prefilter) ? prefilter : prefilterisint ? prefilter!=0 : true : false
		prefilter = prefilterdef ? prefilterisint && prefilterbool ? prefilter == 1 ? input.blur(1.53,interlaced ? 0 : undefined) : input.Ablur(1,blurv=interlaced ? 0 : undefined,chroma=chromaMA?3:2, threads) : eval("input."+prefilter) : prefilter
		prefilterisclip = prefilterdef ? isclip(prefilter) : false
		prefilter = prefilterisclip && interlaced && prefilter.IsFrameBased() ? prefilter.SeparateFields() : prefilter
		sppbool = prefilterbool ? true : TV_range ? true : false
		pp_super =  defined(pp_super) ? pp_super : sppbool ? spp_super(input ,prefilterisclip ? prefilter :  input ,HD=HD,slices=slices,rStr=rStr,Amp=Amp,pel=pel,super_filter=super_filter,luma_rebuild=TV_range,y=y,u=u,v=v,subpixel=subpixel, chromaMA=chromaMA) : dbomt ? input.MSuper(pel=pel,rfilter=super_filter, chroma=chromaMA, mt=bomt) : input.MSuper(pel=pel,rfilter=super_filter, chroma=chromaMA)
		subpixel = default( subpixel,  2 )
		pelclip = pel>1 && subpixel == 3
		pclip = pelclip ? pel==4 ? input.nnedi3_rpow2(rfactor=2,nns=4, threads).nnedi3_rpow2(rfactor=2,nns=4, threads) : input.nnedi3_rpow2(rfactor=2,nns=4, threads) : undefined
		super = defined(super) ? super : sppbool ? dbomt ? input.MSuper(levels=1,pel=pel,rfilter=0, pelclip=pclip, chroma=chroma, mt=bomt) : input.MSuper(levels=1,pel=pel,rfilter=0, pelclip=pclip) : pp_super
		            """) : nop()
		exmc ? exmcclip : interlaced ? interleave(input.selecteven().sMCclips(pp_super.selecteven(), super.selecteven(),mc,thSAD,thSCD1,thSCD2,truemotion,chromaMA,blksize,search,searchparam,overlap,dct,HD), input.selectodd().sMCclips(pp_super.selectodd(), super.selectodd(),mc,thSAD,thSCD1,thSCD2,truemotion,chromaMA,blksize,search,searchparam,overlap,dct,HD)).weave() :
		                             \ input.sMCclips(pp_super, super,mc,thSAD,thSCD1,thSCD2,truemotion,chromaMA,blksize,search,searchparam,overlap,dct,HD)
		eval(filter)
		selectEvery(last, mc * 2 + 1, mc)
}

# mcKNLMeansCL v1.51
function mcKNLMeansCL(clip input, String "device_type", int "device_id", bool "knlchroma", bool "lsb", bool "lsb_in", float "h", int "d", int "a", String "knlm_params", bool "Y", bool "U", bool "V",
	\ val "prefilter", bool "TV_range", clip "exmcclip", clip "super", clip "pp_super", int "thSAD", int "thSCD1", int "thSCD2", bool "truemotion", bool "chroma", int "blksize", int "search", int "searchparam", int "overlap", int "dct",
		\ bool "HD", bool "slices", float "rStr",float "Amp", int "pel", int "super_filter", bool "rprefilter", clip "r_super")
{
		sisphbd = AvsPlusVersionNumber > 2294
		bomt    = sh_GetUserGlobalIMTbool()
		dbomt   = defined(bomt)
		d            = Default( d ,1).min(5)
		a            = Default( a ,2)
		h            = Default( h ,1.2)
		lsb_in       = Default( lsb_in  ,false)
		lsb          = Default( lsb     ,lsb_in)
		rprefilter   = Default( rprefilter  ,false)
		knlchroma    = Default( knlchroma  ,false)
                Assert(!(lsb_in || lsb_in), "mcKNLMeansCL: lsb things not supported yet")
		prefilterdef = defined(prefilter)
		prefilterisint = prefilterdef ? isint(prefilter) : false
		prefilterbool = prefilterdef ? isbool(prefilter) ? prefilter : prefilterisint ? prefilter!=0 : true : true
		prefilter = prefilterisint && prefilterbool ? input.blur(1.53) : prefilter
		exmc = defined(exmcclip)
		bomts = dbomt ? ", mt=bomt" : ""
		d!=0 && (!exmc || rprefilter) ? eval("
		mc = d
		chroma = default(chroma, true) #for motion analysis
		Y = default(Y, true)
		U = default(U, chroma)
		V = default(V, U)
		TV_range  = default( TV_range, !(Isrgb(input)))
		HDbool = defined(HD)
		ox = HDbool ? nop() : input.width()
		oy = HDbool ? nop() : input.height()
		HD = HDbool ? HD : (ox > 1099 || oy > 599)
		pel = default( pel, HD ? 1 : 2 )
		prefilterisclip = prefilterdef ? isclip(prefilter) : false
		sppbool = prefilterisclip ? true : TV_range ? true : false
		pp_super =  defined(pp_super) ? pp_super : sppbool ? spp_super(input ,prefilterisclip ? prefilter :  input ,HD=HD,slices=slices,rStr=rStr,Amp=Amp,pel=pel,super_filter=super_filter,luma_rebuild=TV_range,y=y,u=u,v=v, chromaMA=chroma) : MSuper(prefilterisclip ? prefilter :  input ,pel=pel,rfilter=super_filter, chroma=chroma" + bomts + ")
		super = defined(super) ? super : sppbool ? input.MSuper(levels=1,pel=pel,rfilter=0" + bomts + ") : pp_super
		r_super = rprefilter ? defined(r_super) ? r_super : sppbool ? prefilter.MSuper(levels=1,pel=pel,rfilter=0" + bomts + ") : pp_super : nop()
		b5vec = mc == 5 ? MAnalyse(pp_super, delta=5, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		b4vec = mc >  3 ? MAnalyse(pp_super, delta=4, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		b3vec = mc >  2 ? MAnalyse(pp_super, delta=3, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		b2vec = mc >  1 ? MAnalyse(pp_super, delta=2, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		b1vec = MAnalyse(pp_super, delta=1, isb=true, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ")
		f1vec = MAnalyse(pp_super, delta=1, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ")
		f2vec = mc >  1 ? MAnalyse(pp_super, delta=2, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		f3vec = mc >  2 ? MAnalyse(pp_super, delta=3, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		f4vec = mc >  3 ? MAnalyse(pp_super, delta=4, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		f5vec = mc == 5 ? MAnalyse(pp_super, delta=5, chroma=chroma, search=search, searchparam=searchparam, overlap=overlap, blksize=blksize, dct=dct,truemotion=truemotion" + bomts + ") : undefined
		            ") : nop()
		rclip = rprefilter && prefilterdef ? d==0 ? prefilter : prefilter.sMCclips(pp_super, r_super,mc,thSAD,thSCD1,thSCD2,truemotion,chroma,blksize,search,searchparam,overlap,dct,HD,b1vec,f1vec,b2vec,f2vec,b3vec,f3vec,b4vec,f4vec,b5vec,f5vec) : undefined
		sbitsn = rprefilter && prefilterdef && sisphbd ? input.BitsPerComponent() : 8
		rclip = rprefilter && prefilterdef ? sisphbd ? rclip.BitsPerComponent() != sbitsn ? rclip.ConvertBits(sbitsn) : rclip : rclip : rclip
d==0 ? SH_KNLMeansCL(input, device_type, device_id, knlchroma, lsb, lsb_in, h, d, a, knlm_params, rclip) : \
        eval("""
		exmc ? exmcclip : input.sMCclips(pp_super, super,mc,thSAD,thSCD1,thSCD2,truemotion,chroma,blksize,search,searchparam,overlap,dct,HD,b1vec,f1vec,b2vec,f2vec,b3vec,f3vec,b4vec,f4vec,b5vec,f5vec)
		SH_KNLMeansCL(last, device_type, device_id, knlchroma, lsb, lsb_in, h, d, a, knlm_params, rclip)
		selectEvery(last, mc * 2 + 1, mc)
		""")
}