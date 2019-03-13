# AnimeIVTC() by thetoof
# v2.22 2018-04-17 mod
# last update by AmjadSONY was:- make "precision=1" use "nnedi3" only for "Toriko Anime" by using it like this:- AnimeIVTC(1, precision=1)
# add mode22 bool to use it in mode 2 for Spatial field-blend (field-blend in a part of the picture), ex:- AnimeIVTC(2, bbob=1, mode22=true)
# TC file now will out in V2 ;) , add ediext clip to use it with QTGMC and add bob4p to change QTGMC Preset , add extbob clip to use an External bobber with bbob/cbob=5 , chrfix in mode 1 and other things fixed by doom9 member
# make chrfix work. add dchr bool, can help chrfix with some source, add palf bool for no decimate in mode 1 and make fps 24 instead of 25 for mode 2 in pal source, add tcfv1 bool to made TC file v1 and make it true by default
# add nvfr bool for VFR noisy sources, add real30p bool to not use daa with 30p, and some fix in for PAL cases and other things
# add TFM (mode, cthresh, blockx, blocky, MI) and some fix
# add extbobf string to use external bob function, old external bob clip (extbob) still exist, and if you use both the old extbob will win
# make precision=0 use pp=0 in tfm for speed and quality too, add precision=4 same as precision=3 but no blend, add precision=5 to use yadifmod (usefull for very old anime)
# add precision=6 to use extbobf\extbob with ConvertFPS to back to original fps, add precision=7 to use extbobf\extbob with SelectEven to back to original fps (no blend), and precision=8 for already half bob fps
# add autoAssuf to auto set field to match from in tfm to help with noisy old telecined source, add tfm pp and metric
# tweak autoAssuf in mode=1 with another method, others modifications
# add tfm micmatching for it important to set it to 0 (zero) in many dvd 20XX anime (maybe other source need that too)
# add ediandnn to chose between nnedi3 if set to 1 or eedi3 if set to 2 or eedi3+nnedi3 if set to 3, others modifications
# add yadifrepwithtdeint to use yadifmod with less Artefacts
# yadifrepwithtdeint more tweak
# add o3025cfr to out 25 in PAL and 30 in NTSC, and it useful to avoid blended with omode=1
# palf and o3025cfr more tweak, now palf work in pal only and in mode 1 and 3 will out 24
# fix nnedi3_rpow2 and make credconv accept external clip for credits
# workaround for RgTools Repair in yadifrepwithtdeint
# add bobpresmooth for more stability
# add bbob4_params and cbob4_params to use more settings for QTGMC, add precision=9 to use bbob (maybe you need it with bbob=4 to use QTGMC with TFM)
# add ediandnn=4 to use QTGMC in yadifmod in yadifrepwithtdeint
# make precision=6 TDeint + motion mask add b/c bob 6 TDeint + motion mask
# chrfix now work with YUY2 in avs 2.6
# yadifrepwithtdeint now repwithtdeint and work with bbob 3 and 4 and precision 5
# add crepwithtdeint for cbob 3 and 4
# tweak autoAssuf
# add tdeint sharp bool and type int to set interpolation for c/repwithtdeint and b/cbob precision 6
# fix chrfix bug
# update chroma_rep/chroma_rep2 to http://forum.doom9.org/showthread.php?p=1268074&highlight=chroma_rep#post1268074 (this not work without some edit I did in 2014), chrfix now will accept float as thr, add mChroma/chroma tfm
# ediext clip now can be used instead of ediandnn, add prefiltered_i to use it instead of bobpresmooth 
# add yadifmod2 and other things for yadifmod, make the cache more for mode22 and chrfix
# add tmm2
# added vidDetect parameter for VFR
# added mode 5 same as 3 but use nnrep method to ediandnn, mode 6 too, but it's like 4, and now you can use negative value for use nnedi3 with Padding to avoids edges distortion on top and bottom

# Read the documentation for all the required info to know how to use this function, With note that there are some things have changed in this MOD

function AnimeIVTC (clip i, int "mode", int "aa", int "precision", int "killcomb", int "cache", bool "ifade", float "sfthr", bool "sfshow"\
		, val "chrfix" \
		, bool "blend" \  
		, bool "normconv" \
		, int "pattern" \
		, int "pass", bool "rendering" \
		, int "bbob", int "cbob", string "edimode", int "degrain", int "omode", int "cthresh", int "blockx", int "blocky", int "MI", int "tfmm", int "pp", int "metric", int "micmatching", bool "mChroma", bool "Chroma" \
		, int "i1", int "i2", int "e1", int "e2", int "e3", int "p1", int "p2", bool "dchr", bool "palf", bool "tcfv1", bool "nvfr", bool "real30p", bool "autoAssuf", int "ediandnn", bool "o3025cfr", string "bbob4_params", bool "crepwithtdeint", int "tdeinttype" \
		, int "overlap", int "pel", int "search", bool "nnedi3pel", val "credconv", bool "mode22", val "ediext", string "bob4p", clip "extbob", string "extbobf", bool "repwithtdeint", bool "bobpresmooth", string "cbob4_params", bool "tdeintsharp", val "prefiltered_i" \
		, float "dark", int "thin", int "sharp", int "smooth", bool "stabilize", int "tradius", int "aapel", int "aaov", int "aablk", string "aatype", int "vidDetect"){

###General arguments###
Assert(defined(mode), "Specify a mode... please read the documentation.")

#Highest quality by default
precision 	= default ( precision, 		  3 ) 

#change pal fps
palf	= default ( palf,         false )
o3025cfr	= default ( o3025cfr,       false )

#VFR default optional
nvfr	= default ( nvfr,         false )

#boolean "creds" is set to true if any of the i/p arguments are defined (i.e. if there's a 30i or 30p section to process)
creds = defined(i1) ? true : false
creds = defined(i2) ? true : creds
creds = defined(p1) ? true : creds
creds = defined(p2) ? true : creds
creds = defined(e1) ? true : creds
creds = defined(e2) ? true : creds
creds = defined(e3) ? true : creds

# real30p
real30p	 = default( real30p,        false)

# auto set field to match from to help with noisy old telecined source
autoAssuf= default( autoAssuf,      false)

###Framerate preparation###
normconv = default( normconv, false)
#Determine source region by analysing framerate
Ifrate 	= round(framerate(i))==30 ? 1 : framerate(i)==25 ? 2 : 3
assert(ifrate!=3, "What is your input clip?? It's not 30fps NTSC nor 25fps PAL... maybe you're using the function for a purpose it was not meant to. Please post in the AnimeIVTC thread.")

#Set the output to the other region if normconv (norm-conversion) is set to true, use same as input if not
Ofrate 	= Ifrate==1 && normconv ? 2 : Ifrate==2 && normconv ? 1 : Ifrate

#prepare arguments for srestore and tdecimate based on user settings (as seen previously)
frate  	= Ofrate==1 ? o3025cfr ? 29.970 : 23.976 : palf ? 24 : 25
tnum	= Ofrate==1 ? o3025cfr ? 30000 : 24000 : mode!=4 && palf ? 24 : ((mode==1 || mode==3) && o3025cfr) || mode==2 ? 25 : 20
tden	= Ofrate==1 ? 1001 : 1



#Set pattern=0 (tdecimate) for DHT (safest)
pattern		= default ( pattern,		  0 )

#Set defaults of bobbing filters to use to general optimal quality
ediandnn	= default ( ediandnn, 	          1 )
reptdei         = default (repwithtdeint,      false)
creptdei        = default (crepwithtdeint,      false)
bobpresmooth    = default (bobpresmooth      , false)
bbob		= default ( bbob, 	          3 )
cbob		= default ( cbob, 	          4 )


yadiffun=VersionNumber() < 2.6 ? "yadifmod" : "yadifmod2"
nonyuy2=!(VersionNumber() < 2.6) && i.isyuy2()

prefiltered_i = defined(prefiltered_i) ? isclip(prefiltered_i) ? prefiltered_i : Eval("i." + prefiltered_i) : undefined()
iforbob = defined(prefiltered_i) ? prefiltered_i : bobpresmooth ? i.QTGMC_bob(0,0.5).nonyuy2clipin(nonyuy2).reduceflicker(strength=2).nonyuy2clipout(nonyuy2).interlaced60or50(BFF=!(GetParity(i))) : i
iforbob = bobpresmooth ? isyuy2(i) ? iforbob.SeparateFields.Interleaved2Planar.Repair(i.SeparateFields.Interleaved2Planar,Planar=true).Planar2Interleaved.weave : iforbob.SeparateFields.Repair(i.SeparateFields).weave : iforbob
bob5_with_extbob= (cbob == 5 || bbob == 5 || (precision >= 7 && precision != 9)) ? (defined(extbobf) || defined(extbob)) ? 1 : 0 : 2
Assert(bob5_with_extbob!=0 , "please specify extbobf or extbob if you use bbob or cbob 5 or precision 7 or 8.")
extbob = defined(extbobf) && !defined(extbob) ? Eval("iforbob." + extbobf) : extbob

#Sets output mode to 1 (23.976fps for NTSC and 25fps for PAL) when no 30i or 30p sections are specified and sets it to 0 to use NOP() for every operation where it needs to be specified by the user
omode = (creds==false && mode!=4) || ofrate==2 || normconv ? 1 : default (omode, 0)
Assert(omode!=0, "Specify an output mode (omode)... please read the documentation.")
normconv ? assert(mode==2, "Why would you use normconv=true with a telecined source?") : nop()

###Framerate conversion arguments###
bs		= (i.width>1100) ? 16 : 8
overlap 	= default ( overlap,	       bs/2 )
pel       	= default ( pel, 		  2 )
search 		= default ( search, 		  4 )
assert(search >= 2, "Using a lower search than 2 will most probably lead to weird artifacts")
nnedi3pel 	= default ( nnedi3pel, 	      false )
credconv	= default ( credconv, 	    omode==2 ? "a" : "blah" )
creds && !isclip(credconv) ? assert(credconv!= "blah", "Please specify credconv. Check in the docs to see which is more appropriate to your source.") : nop()

#VFR - If this is pass=2 and that the user made a rendering pass out of pass=1, use input directly for decimation instead of recomputing everything
pass		= default (pass,		  1 )
rendering 	= default ( rendering,	      false )

#Ask if hard telecine (mode=1) is actually blend telecine (patter = 3 clean frames followed by 2 blended ones)
blend		= default ( blend, 	      false )

#Ask if double chroma blend removal is needed (see guide for more info about this problem)
chrfix_f=defined(chrfix) ? isfloat(chrfix) : false
defined(chrfix) ? Assert(chrfix_f || isbool(chrfix),"'chrfix' only accepts float and bool inputs") : nop()
chrfix_b= default ( chrfix_f ? true : chrfix,       false )
dchr	= default ( dchr,       false )
chr_rep_thr = chrfix_f ? chrfix : 0.125

#mode22 for Spatial field-blend
mode22	= default ( mode22,       false )

#Set cache to 10 frames for all functions using scriptclip to prevent seeking issues + frame order mess-up with temporal filters
cache		= default ( cache,		 10 )

#Let the user decide which edimode (optimal varies greatly depending on source) and degrain (++ affects quality vs speed) settings to use in qTGMC
degrain         = default ( degrain,              1 )
bbob4_params    = default (bbob4_params,          "")
cbob4_params    = default (cbob4_params,          "")

#Set decombing and antialiasing filters to off by default
killcomb	= default ( killcomb,		  0 )
aa		= default ( aa,			  0 )
aa = killcomb==3 && aa==2 ? 0 : aa

#Set interlaced fade ins detection (and correction to off by default)
ifade		= default ( ifade,	       false )
#Also turn it off if aa=2 (use daa()), since it applies the same operation on the whole clip as ifade would have had selectively)
ifade		= aa==2 || killcomb==3 ? false : ifade
sfthr	= default ( sfthr,  0.4 ) 
sfshow = default ( sfshow, false )


usefm = mode==1 || (mode==4 && (pass==2 || creds || omode==1))
usehfm = mode==4 && pass==1 && usefm==false

#For later NOP() use if blendbob is not needed
usebbob = (chrfix_b && blend) || mode==2 || (precision==9 && (usefm || usehfm))

#For later NOP() use if clearbob is not needed
usecbob = mode==3 || defined(i1) || chrfix_b && blend==false

#Assign clip to prevent double computation
ediext= defined(ediext) ? isclip(ediext) ? ediext : Eval("i." + ediext) : undefined()
edeintn= ((usecbob && cbob < 6) || (usebbob && bbob < 6) || ((usefm || usehfm) && precision < 6)) || autoAssuf ? defined(ediext) ? ediext : ediandnn != 2 || ediandnn != -2 ? ediandnn < 0 ? iforbob.Padding(2,4,2,4).nnedi3(-2).crop(2,4,-2,-4,true) : iforbob.nnedi3(-2) : nop() : nop()
edeint= ((usecbob && cbob < 6) || (usebbob && bbob < 6) || ((usefm || usehfm) && precision < 6)) || autoAssuf ? defined(ediext) ? ediext : ediandnn == 1 ? edeintn : ediandnn == 2 ? iforbob.eedi3(-2) : ediandnn == 5 || ediandnn == 6 ? i.eedi3(-2,sclip=edeintn).Repair(edeintn,9) : i.eedi3(-2,sclip=edeintn) : edeintn
emask = (usebbob && (bbob==2 || ((bbob==3 || bbob==4) && reptdei) || bbob==6)) || (usecbob && (cbob==2 || ((cbob==3 || cbob==4) && reptdei) || cbob==6)) || ((usefm || usehfm) && precision==3) ? iforbob.tmm2_ortmm1(1) : nop()


###Alright, let's start doing something :p ###

#########
#Bobbing#
#########

#Use non-motion-compensated bobber for blended clips since blends have a negative impact on motion detection (if blends are averaged with frames, they can be harder to detect/remove) (mode=2 and mode=1 with blend and chrfix because blend telecine... well has a lot of blends)
blendbob 	= usebbob ?	bbob<=0 ? iforbob.tdeint(1) 			 		 	                : 
\				bbob==1 ? iforbob.tdeint(1,		edeint=edeint	) 	 	                : 
\				bbob==2 ? iforbob.tdeint(1,		edeint=edeint,emask=emask)	 	        : 
\				bbob==3 ? reptdei ? ediandnn==4 || ediandnn==6 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ").yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=1,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) 		 		        :
\				bbob==4 ? Eval("iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ")")	:
\				bbob==5 ? extbob	 	        : 
\				          i.tdeint(1, emask=emask, sharp=tdeintsharp, type=tdeinttype)                      	                                        : NOP()
blendbob 	= usebbob ?	((bbob==3 || bbob==4) && reptdei) ? isyuy2(i) ? blendbob.Interleaved2Planar.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype).Interleaved2Planar,Planar=true).Planar2Interleaved : blendbob.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype)) : blendbob : nop()

#Allow usage of mo-comp bobber (TempGaussMC) when source is not blended. Highly recommended for stability. (mode=3, interlaced credits, used in chrfix because impact is minimal compared to bob flicker on the whole clip)
clearbob 	= usecbob ?	cbob<=0 ? iforbob.tdeint(1)						                : 
\				cbob==1 ? iforbob.tdeint(1,		edeint=edeint)			                : 
\				cbob==2 ? iforbob.tdeint(1,		edeint=edeint,emask=emask)	                : 
\				cbob==3 ? creptdei ? ediandnn==4 || ediandnn==6 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ").yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=1,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2)			                :
\			        cbob==4 ? Eval("iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + cbob4_params + ")")	:
\				cbob==5 ? extbob	                : 
\				          i.tdeint(1, emask=emask, sharp=tdeintsharp, type=tdeinttype)                                                        	: NOP()
clearbob 	= usecbob ?	((cbob==3 || cbob==4) && creptdei) ? isyuy2(i) ? clearbob.Interleaved2Planar.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype).Interleaved2Planar,Planar=true).Planar2Interleaved : clearbob.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype)) : clearbob : nop()

############################
#Chroma swap between fields# chrfix
############################

#Repair double chroma blending if requested by user using xbob depending on source (known by the mode)
chrdeb = chrfix_b ? blend || mode==2 ? dchr ? blendbob.chroma_rep2(cache*2,chr_rep_thr) : blendbob.chroma_rep(cache*2,chr_rep_thr) : dchr ? clearbob.chroma_rep2(cache*2,chr_rep_thr) : clearbob.chroma_rep(cache*2,chr_rep_thr) : nop()

#Remove duplicates (like a safe selecteven/odd) for further processing before final decimation (hybrid decimation (except blend decimation to prevent having 2 calls of tdecimate) or blend telecine IVTC)
#Once bobbed, in mode=1 (tdecimate(1,3,5), in mode=1 + blend = back to 30fps for further deblending, in mode=2 srestore will do the job, in mode=3 tdecimate(1,3,5), in mode 4 VFR needs 30, CFR can do it (personal notes)
debprep = chrfix_b ? mode==1 && blend || mode==4 && omode==2 ? chrdeb.tdecimate(1,1,2) : chrdeb : i

################
#Field matching# MODE=1 AND 4
################

#Field match for mode 1, pass 2 of mode 4 (hybrid without tfm.txt output) or mode=4 with blend decimation (no need for txt file) or mode=4 with interlaced credits (txt file unusable)

tfmcli2=(precision==0 && ((usefm && !blend) || usehfm)) ? undefined : 
\	(precision==1 && ((usefm && !blend) || usehfm)) ? edeint.SelectEven() : 
\	(precision==2 && ((usefm && !blend) || usehfm)) ? iforbob.tdeint(2,edeint=edeint) : 
\	(precision==3 && ((usefm && !blend) || usehfm)) ? iforbob.tdeint(2,edeint=edeint,emask=emask) : 
\	(precision==4 && ((usefm && !blend) || usehfm)) ? iforbob.tdeint(0,edeint=edeint.SelectEven(),emask=iforbob.tmm2_ortmm1(0)) : 
\	(precision==5 && ((usefm && !blend) || usehfm)) ? reptdei ? ediandnn==4 || ediandnn==6 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=2,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ").SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=2,edeint=edeint.SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(edeint=edeint.SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : 
\	(precision==6 && ((usefm && !blend) || usehfm)) ? i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype) : 
\	(precision==7 && ((usefm && !blend) || usehfm)) ? extbob.SelectEven : 
\	(precision==8 && ((usefm && !blend) || usehfm)) ? extbob : 
\	(precision==9 && ((usefm && !blend) || usehfm)) ? blendbob.SelectEven : 
\	nop()
tfmcli2=(usefm && !blend) || usehfm ? precision==5 && reptdei ? isyuy2(i) ? tfmcli2.Interleaved2Planar.Repair(i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype).Interleaved2Planar,Planar=true).Planar2Interleaved : tfmcli2.Repair(i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype)) : tfmcli2 : nop()

#field match for hard telecine or blend telecine restoration for mode==1

global fm=(precision==0 && usefm) ? blend ? debprep.srestore(omode="pp0") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=0,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==1 && usefm) ? blend ? debprep.srestore(omode="pp1") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==2 && usefm) ? blend ? debprep.srestore(omode="pp2") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==3 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==4 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==5 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==6 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==7 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==8 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  (precision==9 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\	  nop()

autoAssuf ? eval("""
sourford = i.getparity() ? 1 : 0
global iyadifmc = eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3, edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2)

global invfm = usefm ? autoAssuf ? i.Tfm(field=sourford==1 ? 0 : 1,slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=defined(MI) ? Int(MI*5/4) : undefined,metric=metric,pp=precision==0 ? 0 : pp,clip2=tfmcli2,micmatching=0, mchroma=false,Chroma=Chroma) : nop() : nop()
fminv2       = usefm ? autoAssuf ? ScriptClip(Interleave(fm,fm), "
						invfv=Interleave(iyadifmc.DeleteFrame(0).SelectEven(),invfm).crop(16,16,-16,-16).cFrameDiff(prevf=true, chroma=false, denoise=true, nt=1)
						fv   =Interleave(iyadifmc.SelectEven(),                  fm).crop(16,16,-16,-16).cFrameDiff(prevf=true, chroma=false, denoise=true, nt=1)
						fv > 0.5 && invfv < 2 ? fv > invfv ? Interleave(invfm,invfm) : last : last
						").Selectodd() : fm : nop()
fm       = usefm ? autoAssuf ? conditionalfilter(fm.crop(16,16,-16,-16),fminv2,fm,"cFrameDiff(prevf=false, chroma=false, denoise=true, nt=1)","<","3") : fm : nop() 
""") : nop()

fm = usefm ? ifade ? fm.smartfademod(sfthr, sfshow, cache) : fm : nop()

#Field match + tfm.txt output for VFR clips (mode=4, pass=1)

global hybridfm=(usehfm && precision==0) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=0,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==1) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==2) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==3) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==4) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==5) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==6) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==7) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==8) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		(usehfm && precision==9) ? i.tfm(slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma) : 
\		nop()

invhybridfm    = usehfm ? autoAssuf ? conditionalfilter(hybridfm.crop(16,16,-16,-16),i.Tfm(field=sourford==1 ? 0 : 1,slow=2,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=defined(MI) ? Int(MI*5/4) : undefined,metric=metric,pp=precision==0 ? 0 : pp,clip2=tfmcli2,micmatching=0, mchroma=false,Chroma=Chroma),hybridfm,"IsCombedTIVTC(15,13,false,8,4,1)","=","true") : hybridfm : nop()
hybridfm       = usehfm ? autoAssuf ? conditionalfilter(blankclip(hybridfm,length=1).crop(16,16,-16,-16)+invhybridfm.crop(16,16,-16,-16),hybridfm,invhybridfm,"IsCombedTIVTC(10,7,false,4,4,0)","=","true") : hybridfm : nop()

hybridfm = usehfm ? ifade ? hybridfm.smartfademod(sfthr, sfshow, cache) : hybridfm : nop()

###############        ######################
#Field blended# MODE=2 #Double hard telecine# MODE=3
###############	       ######################

#Since during double chroma blend removal it was checked whether to use blendbob or clearbob depending on the source (blendbob was used for field blended and clearbob was used for double hard telecine), use chrbob when chrfix=true, else use the appropriate one

fbbob = mode==2 ? chrfix_b ? debprep : blendbob : nop()

dhtbob = mode==3 ? chrfix_b ? debprep : clearbob : nop()

################
#CFR decimation# OMODE=1
################

#HT decimation (mode=1), remove 3 frames out of 5 when chrfix=true since the clip has been bobbed to 60fps
fmdecim = mode==1 ? chrfix_b ? (palf && Ofrate==2) ? debprep.tdecimate(1,13,25) : (o3025cfr) ? debprep.tdecimate(1,3,6) : debprep.tdecimate(1,3,5) : (palf && Ofrate==2) ? fm.tdecimate(1,1,25) : (o3025cfr) ? fm : (autoAssuf) ? fm.tdecimate(1) : fm.tdecimate() : nop()

#Field blended blend removal & decimation (mode=2) No need to check for chrfix since it was done in the previous step
fbdecim = mode==2 ? mode22 ? chrfix_b ? fbbob.srestore(omode=2, mode=4, thresh=44, cache=cache*3/2, dclip=fbbob.crop(16,16,-16,-16)).srestore(frate=frate, mode=4, speed=-4, cache=cache) : 	fbbob.srestore(omode=2, mode=4, thresh=44, cache=cache*3/2, dclip=fbbob.crop(16,16,-16,-16)).srestore(frate=frate, mode=-4, speed=-4, cache=cache) 	:
\chrfix_b ? fbbob.srestore(frate=frate, cache=cache) : 	fbbob.srestore(frate=frate, cache=cache, dclip=i.bob(-0.2,0.6).nonyuy2clipin(nonyuy2).reduceflicker(strength=1).nonyuy2clipout(nonyuy2)) 	: nop()

#Pattern finding and decimation for double hard telecine (mode=3) No need to check for chrfix since it was done in the previous step
a= mode==3 && (pattern==1 || pattern==-1) ? palf && Ofrate==2 ? dhtbob.selectevery(4,0,2).tdecimate(1,1,25) : o3025cfr ? dhtbob.selectevery(4,0,2) : dhtbob.selectevery(5,0,3) : NOP()
b= mode==3 && (pattern==2 || pattern==-1) ? palf && Ofrate==2 ? dhtbob.selectevery(4,1,3).tdecimate(1,1,25) : o3025cfr ? dhtbob.selectevery(4,1,3) : dhtbob.selectevery(5,1,4) : NOP()
c= mode==3 && (pattern==3 || pattern==-1) ? palf && Ofrate==2 ? dhtbob.selectevery(4,0,1).tdecimate(1,1,25) : o3025cfr ? dhtbob.selectevery(4,0,1) : dhtbob.selectevery(5,0,2) : NOP()
d= mode==3 && (pattern==4 || pattern==-1) ? palf && Ofrate==2 ? dhtbob.selectevery(4,1,2).tdecimate(1,1,25) : o3025cfr ? dhtbob.selectevery(4,1,2) : dhtbob.selectevery(5,1,3) : NOP()
e= mode==3 && (pattern==5 || pattern==-1) ? palf && Ofrate==2 ? dhtbob.selectevery(4,2,3).tdecimate(1,1,25) : o3025cfr ? dhtbob.selectevery(4,2,3) : dhtbob.selectevery(5,2,4) : NOP()
dhtdecim = mode==3 ? 			pattern==-1 ? stackvertical(stackhorizontal(a.subtitle("pattern=1"),b.subtitle("pattern=2"),c.subtitle("pattern=3")),stackhorizontal(d.subtitle("pattern=4"),e.subtitle("pattern=5"),e.blackness())) : 
\					pattern==1 ? a : 
\					pattern==2 ? b : 
\					pattern==3 ? c : 
\					pattern==4 ? d : 
\					pattern==5 ? e : 
\ palf && Ofrate==2 ? tdecimate(1,13,25) : o3025cfr ? dhtbob.tdecimate(1,3,6) : dhtbob.tdecimate(1,3,5) : nop()

#Hybrid CFR blend decimation of 30p into 24p
blenddecim = (mode==4 && omode==1) ? chrfix_b ? (palf && Ofrate==2) ? debprep.tdecimate(1,13,25,hybrid=1) : o3025cfr ? debprep.tdecimate(1,3,6) : debprep.tdecimate(1,3,5,hybrid=1) : o3025cfr ? fm : (palf && Ofrate==2) ? fm.tdecimate(1,1,25,hybrid=1) : fm.tdecimate(hybrid=1) : nop()

#########
#Credits# CREDS=TRUE (USER SPECIFIES I1, I2, P1, P2, E1, E2 OR E3)
#########

#Interlaced : use the same smart-bobbed clip as before; we don't care if the background is blended or not since it is unrecoverable anyways (at least for now... see developments about using masking to isolate creds from background)
credbob = defined(i1) ? clearbob.selecteven() : nop()

#Progressive : Blend deinterlace the 24t background while doing minimal damage on the 30p credits
blendbg= defined(p1) ? real30p ? i : i.daa3() : nop()

###CFR conversion###
#######################
###Framerate conversion (recommended for static or low-motion backgrounds since it is prone artifacts... it reduces framerate/motion based on motion vectors)

####Convert the framerate of the interlaced credits
#Determine if usage of the following conversion is required
usemocompi = isclip(credconv) ? defined(i1) : defined(i1) && credconv=="mocomp"

#External pelclip on source with nnedi, if requested
upsi = 		nnedi3pel && usemocompi ? pel==2 ? credbob.nnedi3_rpow2(rfactor=2) : credbob.nnedi3_rpow2(rfactor=2).nnedi3_rpow2(rfactor=2) : nop()

#Prepare super clip for the interlaced credits
credbobsuper	= usemocompi ? 			credbob.	MSuper(pel=pel, levels=0) 					 : nop()
credbobupsuper	= usemocompi && nnedi3pel ? 	credbob.	MSuper(pel=pel, levels=0, pelclip=upsi) 			 : nop()

#Calculate vectors
bvi = 		usemocompi ? nnedi3pel ? 	credbobupsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : 
\						credbobsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : nop()

fvi = 		usemocompi ? nnedi3pel ? 	credbobupsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : 
\						credbobsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : nop()

#Apply framerate conversion
fpsconvi =  	usemocompi ? nnedi3pel ? 	credbob.	MFlowFps(credbobupsuper,bvi, fvi, tnum, tden) 			 : 
\						credbob.	MFlowFps(credbobsuper,  bvi, fvi, tnum, tden) 			 : nop()

###Convert the framerate of the progressive credits
#Determine if usage of the following conversion is required
usemocompp = isclip(credconv) ? defined(p1) : defined(p1) && credconv=="mocomp"

#External pelclip on source with nnedi, if requested
upsp = 		nnedi3pel && usemocompp ? pel==2 ? blendbg.nnedi3_rpow2(rfactor=2) : blendbg.nnedi3_rpow2(rfactor=2).nnedi3_rpow2(rfactor=2) : nop()

#Prepare super clip for the progressive credits
blendbgsuper	= usemocompp ?			blendbg.MSuper(pel=pel, levels=0) 						 : nop()
blendbgsuperup	= usemocompp && nnedi3pel ? 	blendbg.MSuper(pel=pel, levels=0, pelclip=upsp) 				 : nop()

#Calculate vectors
bvp = 		usemocompp ? nnedi3pel ? 	blendbgsuperup.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : 
\						blendbgsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : nop()

fvp = 		usemocompp ? nnedi3pel ? 	blendbgsuperup.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : 
\						blendbgsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : nop()

#Apply framerate conversion
fpsconvp = 	usemocompp ? nnedi3pel ?	blendbg.MFlowFps(blendbgsuperup,bvp, fvp, tnum, tden) 				 : 
\						blendbg.MFlowFps(blendbgsuper,  bvp, fvp, tnum, tden) 				 : nop()

#######################
###Blend 30p creds into 24t (ugly and fast, but can lead to less disturbing artifacts when you have a high motion background)
blendi = isclip(credconv) ? nop() : defined(i1) && credconv=="blend" ? o3025cfr ? credbob : credbob.convertfps(tnum,tden) : nop()

blendp = isclip(credconv) ? nop() : defined(p1) && credconv=="blend" ? o3025cfr ? blendbg : blendbg.convertfps(tnum,tden) : nop()

#######################
###Drop frames 30p creds into 24t (ugly and fast, will lead to stuttery motion)
drop_credconv = isclip(credconv) ? nop() : (credconv=="drop" && normconv) ? 1 : 0

assert(drop_credconv!=1, "Please choose another credconv. drop not compatible with normconv=true.")

dropi = isclip(credconv) ? nop() : defined(i1) && credconv=="drop" ? (mode!=4 && palf && Ofrate==2) ? credbob.tdecimate(1,1,25) : o3025cfr ? credbob : credbob.tdecimate(1) : nop()

dropp = isclip(credconv) ? nop() : defined(p1) && credconv=="drop" ? (mode!=4 && palf && Ofrate==2) ? blendbg.tdecimate(1,1,25) : o3025cfr ? blendbg : blendbg.tdecimate(1) : nop()

########
#SPLICE# CREDS=TRUE (USER SPECIFIES I1, I2, P1, P2, E1, E2 OR E3)
########

#Determine the "mix" mode (how the different sections (30i, 24t, 30p) are spliced together)
#Also check for user error when entering the frame numbers

mix22a17	= defined(e1) && defined(e2) && defined(e3) && defined(i1) && defined(p1)	? true : false
mix7 		= defined(e1) && defined(e2) && defined(e3) && defined(i1) && defined(i2)	? true : false
mix14 		= defined(e1) && defined(e2) && defined(e3) && defined(p1) && defined(p2)	? true : false

mix21a20a16a15 	= defined(e1) && defined(e2) && defined(i1) && defined(p1) && mix22a17==false	? true : false
mix6a3 		= defined(e1) && defined(e2) && defined(i1) && defined(i2) && mix7==false	? true : false
mix13a10	= defined(e1) && defined(e2) && defined(p1) && defined(p2) && mix14==false	? true : false

mix19a18	= defined(e1) && defined(p1) && defined(i1) && mix21a20a16a15==false	? true : false 
mix9 		= defined(e1) && defined(p1) && defined(p2) && mix13a10==false		? true : false
mix2 		= defined(e1) && defined(i1) && defined(i2) && mix6a3==false		? true : false
mix4 		= defined(e1) && defined(e2) && defined(i1) && mix21a20a16a15==false && mix6a3==false	? true : false
mix11 		= defined(e1) && defined(e2) && defined(p1) && mix21a20a16a15==false && mix13a10==false	? true : false

mix1a5 	= defined(e1) && defined(i1) && mix19a18==false && mix2==false && mix4==false		? true : false
mix8a12 = defined(e1) && defined(p1) && mix19a18==false && mix11==false && mix9==false		? true : false


#Getting the "mix" mode based on user input
mix = 0
mix = mix1a5 		&& i1<e1 		? 1 : mix
mix = mix2 		&& i1<e1<i2 		? 2 : mix
mix = mix6a3 		&& i1<e1<i2<e2 		? 3 : mix
mix = mix4 		&& e1<i1<e2 		? 4 : mix
mix = mix1a5 		&& e1<i1 		? 5 : mix
mix = mix6a3 		&& e1<i1<e2<i2 		? 6 : mix
mix = mix7 		&& e1<i1<e2<i2<e3 	? 7 : mix
mix = mix8a12 		&& p1<e1 		? 8 : mix
mix = mix9 		&& p1<e1<p2 		? 9 : mix
mix = mix13a10 		&& p1<e1<p2<e2 		? 10 : mix
mix = mix11 		&& e1<p1<e2 		? 11 : mix
mix = mix8a12 		&& e1<p1 		? 12 : mix
mix = mix13a10 		&& e1<p1<e2<p2 		? 13 : mix
mix = mix14 		&& e1<p1<e2<p2<e3 	? 14 : mix
mix = mix21a20a16a15 	&& e1<i1<e2<p1 		? 15 : mix
mix = mix21a20a16a15 	&& i1<e1<p1<e2 		? 16 : mix
mix = mix22a17 		&& e1<i1<e2<p1<e3 	? 17 : mix
mix = mix19a18 		&& i1<e1<p1 		? 18 : mix
mix = mix19a18 		&& p1<e1<i1 		? 19 : mix
mix = mix21a20a16a15 	&& e1<p1<e2<i1 		? 20 : mix
mix = mix21a20a16a15 	&& p1<e1<i1<e2 		? 21 : mix
mix = mix22a17 		&& e1<p1<e2<i1<e3 	? 22 : mix
mix = defined(i2) && defined(i1)==false ? 0 : mix
mix = defined(p2) && defined(p1)==false ? 0 : mix
mix = defined(e2) && defined(e1)==false ? 0 : mix
mix = defined(e3) && defined(e2)==false ? 0 : mix
mix = defined(e3) && defined(e1)==false ? 0 : mix
mix = defined(i1) && defined(e1)==false ? 0 : mix
mix = defined(p1) && defined(e1)==false ? 0 : mix
creds ? assert(mix!=0, "Mistake in entering i1, e1.... parameters. Please check.") : nop()

#Determine frame numbers based on mix mode and user input of i/p/e1/2/3
istart1=mix==1 || mix==2 || mix==3 || mix==16 || mix==18 					? 0 	: \
	mix==4 || mix==5 || mix==6 || mix==7 || mix==15 || mix==17 || mix==19 || mix==21  	? e1+1 	: \
	mix==20	|| mix==22									? e2+1  : nop()

istart2=mix==2 || mix==3 ? e1+1 : mix==6 || mix==7 ? e2+1 : nop()

pstart1=mix==8 || mix==9 || mix==10 || mix==19 || mix==21 					? 0 	: \
	mix==11 || mix==12 || mix==13 || mix==14 || mix==16 || mix==18 || mix==20 || mix==22  	? e1+1 	: \
	mix==15	|| mix==17									? e2+1  : nop()

pstart2=mix==9 || mix==10 ? e1+1 : mix==13 || mix==14 ? e2+1 : nop()

estart1=mix==4 || mix==5 || mix==6 || mix==7 || mix==11 || mix==12 || mix==13 || mix==14 || mix==15 || mix==17 || mix==20 || mix==22	? 0 	: \
	mix==1 || mix==2 || mix==3 || mix==16 || mix==18  										? i1+1 	: \
	mix==8 || mix==9 || mix==10 || mix==19 || mix==21										? p1+1  : nop()

estart2=mix==4 || mix==6 || mix==7 || mix==15 || mix==17 || mix==21  	? i1+1 	: \
	mix==3 								? i2+1  : \
	mix==11 || mix==13 || mix==14 || mix==16 || mix==20 || mix==22 	? p1+1 	: \
	mix==10								? p2+1  : nop()

estart3=mix==7 ? i2+1 : mix==14 ? p2+1 : mix==17 ? p1+1 : mix==22 ? i1+1 : nop()

maxfps = defined(i1) ? framerate(i) : defined(p1) ? framerate(i) : nop()

#Final 24fps ivtced clip and deinterlaced + framerate converted for CFR (omode=1)
tocfrfinalt = omode==1 ? (mode==1) ? fmdecim : (mode==2) ? fbdecim : (mode==3) ? dhtdecim : (mode==4 && omode==1) ? blenddecim : nop() : nop()
tocfrfinali = omode==1 && creds ? isclip(credconv) ? credconv : (credconv=="mocomp") ? o3025cfr ? credbob : fpsconvi : (credconv=="blend") ? blendi : credconv=="drop" ? dropi : nop() : nop()
tocfrfinalp = omode==1 && creds ? isclip(credconv) ? credconv : (credconv=="mocomp") ? o3025cfr ? blendbg : fpsconvp : (credconv=="blend") ? blendp : credconv=="drop" ? dropp : nop() : nop()

#Final 30fps clips (prepare for hybrid decimation, make everything 30fps) for hybrid use fm since it will be spliced (txt file will be useless) (used when creds=true)
tovfrfinalt = omode==2 && creds ? (mode==1) ? fm : (mode==2) ? !(Ofrate==2 && palf) || !normconv ? fbdecim : fbdecim.changefps(maxfps) : (mode==3) ? (o3025cfr && !(palf && Ofrate==2)) ? dhtdecim : dhtdecim.changefps(maxfps) : (mode==4 && omode==2) ? fm : nop() : nop()
tovfrfinali = omode==2 && creds ? credbob : nop()
tovfrfinalp = omode==2 && creds ? blendbg : nop()

#Final clip to splice
spliceprept = mix!=0 ? omode==1 ? tocfrfinalt : omode==2 ? tovfrfinalt : nop() : nop()
spliceprepi = mix!=0 ? omode==1 ? tocfrfinali : omode==2 ? tovfrfinali : nop() : nop()
spliceprepp = mix!=0 ? omode==1 ? tocfrfinalp : omode==2 ? tovfrfinalp : nop() : nop()

#######################
###Trim
#Factor to get the proper trim values after decimating
factor = omode==1 ? defined(i1) ? float(framerate(tocfrfinali)/framerate(i)) : defined(p1) ? float(framerate(tocfrfinalp)/framerate(i)) : nop() : nop()

et1 = 	defined(e1) ? omode==2 ? spliceprept.trim(estart1,e1) : spliceprept.trim(int(estart1*factor),int(e1*factor)) : nop()
et2 = 	defined(e2) ? omode==2 ? spliceprept.trim(estart2,e2) : spliceprept.trim(int(estart2*factor),int(e2*factor)) : nop()
et3 = 	defined(e3) ? omode==2 ? spliceprept.trim(estart3,e3) : spliceprept.trim(int(estart3*factor),int(e3*factor)) : nop()

ci1 = 	defined(i1) ? omode==2 ? spliceprepi.trim(istart1,i1) : spliceprepi.trim(int(istart1*factor),int(i1*factor)) : nop()
ci2 = 	defined(i2) ? omode==2 ? spliceprepi.trim(istart2,i2) : spliceprepi.trim(int(istart2*factor),int(i2*factor)) : nop()

#Prepare 30p sections for splicing
cp1 = 	defined(p1) ? omode==2 ? spliceprepp.trim(pstart1,p1) : spliceprepp.trim(int(pstart1*factor),int(p1*factor)) : nop()
cp2 = 	defined(p2) ? omode==2 ? spliceprepp.trim(pstart2,p2) : spliceprepp.trim(int(pstart2*factor),int(p2*factor)) : nop()

spliced=(mix==1) ? 	ci1 + 	et1 : \
	(mix==2) ? 	ci1 + 	et1 + 	ci2 : \
	(mix==3) ? 	ci1 + 	et1 + 	ci2 + 	et2 : \ 
	(mix==4) ? 	et1 + 	ci1 + 	et2 : \
	(mix==5) ? 	et1 + 	ci1 : \ 
	(mix==6) ? 	et1 + 	ci1 + 	et2 + 	ci2 : \
	(mix==7) ? 	et1 + 	ci1 + 	et2 + 	ci2 + 	et3 : \
	(mix==8) ? 	cp1 + 	et1 : \
	(mix==9) ? 	cp1 + 	et1 + 	cp2 : \
	(mix==10) ? 	cp1 + 	et1 + 	cp2 + 	et2 : \ 
	(mix==11) ? 	et1 + 	cp1 + 	et2 : \
	(mix==12) ? 	et1 + 	cp1 : \ 
	(mix==13) ? 	et1 + 	cp1 + 	et2 + 	cp2 : \
	(mix==14) ? 	et1 + 	cp1 + 	et2 + 	cp2 + 	et3 : \
	(mix==15) ? 	et1 + 	ci1 + 	et2 + 	cp1 : \
	(mix==16) ? 	ci1 + 	et1 + 	cp1 + 	et2 : \
	(mix==17) ?	et1 + 	ci1 + 	et2 + 	cp1 +	et3 : \
	(mix==18) ? 	ci1 + 	et1 + 	cp1 : \
	(mix==19) ? 	cp1 + 	et1 + 	ci1 : \ 
	(mix==20) ? 	et1 + 	cp1 + 	et2 + 	ci1 : \
	(mix==21) ? 	cp1 + 	et1 + 	ci1 + 	et2 : \
	(mix==22) ? 	et1 + 	cp1 + 	et2 + 	ci1 +	et3 : \
	NOP()

finalcfr =  omode==1 ? creds ? spliced : tocfrfinalt : nop()
tovfrdec1 = omode==2 ? creds ? spliced : chrfix_b ? debprep : hybridfm : nop()
tovfrdec2 = omode==2 ? rendering ? i : creds ? spliced : chrfix_b ? debprep : fm : nop()

finalvfr = 	omode==2 && pass==1 ? nvfr ? tovfrdec1.TDecimate(4, output="stats.txt",denoise=true,vidThresh=0.8,dupThresh=0.9,vidDetect=vidDetect) : tovfrdec1.TDecimate(4, output="stats.txt",vidDetect=vidDetect) :
\		omode==2 && pass==2 ? nvfr ? tovfrdec2.TDecimate(5,hybrid=2,tfmin=creds ? "" : "tfm.txt",input="stats.txt",mkvout="timecodes.txt",tcfv1=tcfv1,batch=true,vidThresh=0.4,dupThresh=0.6,vidDetect=vidDetect) : tovfrdec2.TDecimate(5,hybrid=2,tfmin=creds ? "" : "tfm.txt",input="stats.txt",mkvout="timecodes.txt",tcfv1=tcfv1,batch=true,vidDetect=vidDetect) : nop()

topp = omode==1 ? finalcfr : omode==2 ? finalvfr : nop()

#Kill combing depending on user settings
dec = 	killcomb==0 ? topp : 
\	killcomb==1 ? topp.vinverse() : 
\	killcomb==2 ? topp.vinverseD() : 
\	killcomb==3 ? topp.daa3() : 
\		interleave(	topp.		 subtitle("killcomb=0",align=9),
\				topp.vinverse(). subtitle("killcomb=1",align=9),
\				topp.vinverseD().subtitle("killcomb=2",align=9),
\				topp.daa3().subtitle("killcomb=3",align=9))

aaed = 	aa==0 ? dec : 
\	aa==1 ? dec.ediaa() : 
\	aa==2 ? dec.daa3() : 
\	aa==3 ? dec.maa() : 
\	aa==4 ? dec.sharpaamcmod(dark,thin,sharp,smooth,stabilize,tradius,aapel,aaov,aablk,aatype) : 
\			interleave(	dec.		subtitle("aa=0",align=9),
\					dec.ediaa().	subtitle("aa=1",align=9),
\					dec.daa3().	subtitle("aa=2",align=9),
\					dec.maa().	subtitle("aa=3",align=9),
\					dec.sharpaamcmod(dark,thin,sharp,smooth,stabilize,tradius,aapel,aaov,aablk,aatype).subtitle("aa=4",align=9))

return omode==2 && pass==1 ? finalvfr : aaed
}


function chroma_rep(clip sourceo, int "cache", float "thr")
{
###### parameters & other necessary vars ######
    cache   = default(cache,-1)
global  rep_thr = default(thr, 0.125)


avs26=!(VersionNumber() < 2.6)
nonyuy2=avs26 && sourceo.isyuy2()

source=nonyuy2 ? sourceo.nonyuy2clipin(true) : sourceo

###### source preparation & lut ######
global  out1    = source
global  out2    = mergechroma(source,mt_adddiff(source.trim(1,0),mt_makediff(source.trim(1,0),source.trim(2,0),y=1,u=3,v=3),y=1,u=3,v=3).blur(1))


###### initialise variables ######
global  alfr     = -100


###### evaluation call & output calculation ######
scriptclip( source, """

 ### preparation ###
        cfr = current_frame
        ajmp = alfr+1==cfr
        
    global  alfr = cfr

        al_v = LumaDifference(out1.trim(1,0),out1.trim(2,0))
        ac_v = ChromaUDifference(out1.trim(1,0),out1.trim(2,0)) + ChromaVDifference(out1.trim(1,0),out1.trim(2,0))

  ## luma value shifting ##
    l10 = ajmp ? l01 : al_v
global 		l01	= ajmp ? l12 : al_v
global 		l12	= al_v
  
  ## chroma value shifting ##
    c10 = ajmp ? c01 : ac_v
global 		c01 = ajmp ? c12 : ac_v
global 		c12 = ac_v
	
 ### condition ###
    change  = l12*2<l01 && c01*1.25<c12 && c01*l12/c12/l01<rep_thr
    chango  = l01*2<l10 && c10*1.25<c01 && c10*l01/c01/l10<rep_thr
    
    change ? out2 : chango ? out1.trim(1,0) : out1

""")

nonyuy2 ? nonyuy2clipout(true) : last


###### final decimation & caching ######
cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)

return last
}


function chroma_rep2(clip sourceo, int "cache", float "thr")
{
###### parameters & other necessary vars ######
    cache   = default(cache,-1)
global  rep_thr = default(thr, 0.125)


avs26=!(VersionNumber() < 2.6)
nonyuy2=avs26 && sourceo.isyuy2()

source=nonyuy2 ? sourceo.nonyuy2clipin(true) : sourceo

###### source preparation & lut ######
global  out1    = source
global  out2    = mergechroma(source,mt_adddiff(source.trim(1,0),mt_makediff(source.trim(1,0),source.trim(2,0),y=1,u=3,v=3),y=1,u=3,v=3).blur(1))


###### initialise variables ######
global  alfr     = -100


###### evaluation call & output calculation ######
chrixout = scriptclip( source, """

 ### preparation ###
        cfr = current_frame
        ajmp = alfr+1==cfr
        
    global  alfr = cfr

        al_v = LumaDifference(out1,out1.trim(1,0))
        ac_v = ChromaUDifference(out1,out1.trim(1,0)) + ChromaVDifference(out1,out1.trim(1,0))

  ## luma value shifting ##
    l10 = ajmp ? l01 : al_v
global 		l01	= ajmp ? l12 : al_v
global 		l12	= al_v
  
  ## chroma value shifting ##
    c10 = ajmp ? c01 : ac_v
global 		c01 = ajmp ? c12 : ac_v
global 		c12 = ac_v
	
 ### condition ###
    change  = l12*2<l01 && c01*1.25<c12 && c01*l12/c12/l01<rep_thr
    chango  = l01*2<l10 && c10*1.25<c01 && c10*l01/c01/l10<rep_thr
    
    change ? out2 : chango ? out1.trim(1,0) : out1

""")

chrixout=nonyuy2 ? chrixout.nonyuy2clipout(true) : chrixout


###### final decimation & caching ######
chrixout2 = cache<0 ? sourceo.mergechroma(chrixout) : sourceo.mergechroma(chrixout).RequestLinear(8, cache, 5, false, false)

return chrixout2
}


#based on smartfade v0.2 by martino - Aimed at removing interlaced fades in anime. Uses luma difference between two fields as activation threshold.
#mod by thetoof : removed degrainmedian post-processing, 
#		changed how the fields are blended together (average of 2 nnedi interpolations + contra-sharpening to retain more detail) and 
#		added cache parameter to forward the setting of animeivtc to this function
#		renamed global parameter to something less general than "threshold"

function smartfademod(clip c, float "sfthr", bool "sfshow", int "cache") {
    
global sfthr	= default ( sfthr,  0.4 ) # Threshold for fade detection.
show		= default ( sfshow, false ) # Displays luma difference between fields without processing anything.
cache		= default ( cache,   10 ) # Cache the frames to help seeking and other functions requesting many frames

show ? scriptclip(c, "subtitle(string(abs(	  separatefields().selectodd().averageluma() \
            				- separatefields().selecteven().averageluma())))") : \
       scriptclip(c, "sep = separatefields() \
       avg = sep.selectodd().averageluma() - sep.selecteven().averageluma() \
       abs(avg) > sfthr ? interleave(sep.selecteven(),sep.selectodd()).weave().daa3() : last")

cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)

    return last

}

#Suggested by Mystery Keeper in "Denoise of tv-anime" thread
function ediaa(clip a) {return a.EEDI2(field=1).TurnRight().EEDI2(field=1).TurnLeft().spline36resize(a.width,a.height,-0.5,-0.5)}

#Anti-aliasing with contra-sharpening by Didée
function daa(clip c) {
nn	= c.nnedi2(field=-2)
dbl   	= mt_average(selecteven(nn),selectodd(nn),U=3,V=3)
dblD 	= mt_makediff(c,dbl,U=3,V=3)
shrpD 	= mt_makediff(dbl,dbl.removegrain((width(c)>1100) ? 20 : 11),U=3,V=3)
DD 	= shrpD.repair(dblD,13)
return dbl.mt_adddiff(DD,U=3,V=3) }

#Anti-aliasing with edge masking by martino, mask using "sobel" taken from Kintaro's useless filterscripts and modded by thetoof for spline36
function maa(clip input, int "mask") {
mask = input.mt_edge("sobel",7,7,5,5).mt_inflate()
aa_clip=input.spline36Resize(width(input)*2,height(input)*2).TurnLeft().SangNom().TurnRight().SangNom().spline36Resize(width(input),height(input)).MergeChroma(input) 
return mt_merge(input,aa_clip,mask) }

#Developped in the "fine anime antialiasing thread"
function SharpAAMCmod(clip orig, float "dark", int "thin", int "sharp", int "smooth", bool "stabilize", int "tradius", int "aapel", int "aaov", int "aablk", string "aatype")
{
dark	= default ( dark,     0.2 ) # strokes darkening strength
thin	= default ( thin,      10 ) # Presharpening
sharp	= default ( sharp,    150 ) # Postsharpening
smooth	= default ( smooth,    -1 ) # Postsmoothing
stabilize= default ( stabilize,false ) # Use post stabilization with Motion Compensation
Tradius	= default ( Tradius,    2 ) # 2 = MDegrain2 / 3 = MDegrain3 
aapel	= default ( aapel,      1 ) # accuracy of the motion estimation (Value can only be 1, 2 or 4. 1 means a precision to the pixel. 2 means a precision to half a pixel, 4 means a precision to quarter a pixel, produced by spatial interpolation (better but slower).)
aaov	= default ( aaov,       (orig.width>1100) ? 8 : 4 ) # block overlap value (horizontal). Must be even and less than block size. (Higher = more precise & slower)
aablk	= default ( aablk,      (orig.width>1100) ? 16 : 8 ) # Size of a block (horizontal). It's either 4, 8 or 16 ( default is 8 ). Larger blocks are less sensitive to noise, are faster, but also less accurate.
aatype	= default ( aatype, "Sangnom" ) # Use Sangnom() or EEDI2() for anti-aliasing

w=width(orig)
h=height(orig)
m=mt_logic( orig.DEdgeMask(0,255,0,255,"5 10 5 0 0 0 -5 -10 -5", divisor=4,Y=3,U=3,V=3)
 \       ,orig.DEdgeMask(0,255,0,255,"5 0 -5 10 0 -10 5 0 -5", divisor=4,Y=3,U=3,V=3)
 \       ,"max").mt_lut("x 128 / 0.86 ^ 255 *")
preaa=(thin==0 && dark==0) ? orig : (thin==0) ? orig.Toon(dark) : (dark==0) ? orig.awarpsharp2(depth=thin) : orig.Toon(dark).awarpsharp2(depth=thin)
aa= (aatype=="Sangnom") ? preaa.spline36resize(w*2,h*2).TurnLeft().SangNom().TurnRight().SangNom().spline36resize(w,h) : (aatype=="EEDI2") ? preaa.ediaa() : blankclip(pixel_type="YV12").subtitle("Please use Sangnom or EEDI2 for aatype")
postsh=(sharp==0 && smooth==0) ? aa : aa.lsfmod(edgemode=1,strength=sharp,overshoot=1,soft=smooth)
merged=mt_merge(orig,postsh,m,Y=3,U=3,V=3)

sD=mt_makediff(orig,merged)

origsuper= orig.MSuper(pel=aapel)
sDsuper  = sD.  MSuper(pel=aapel, levels=1)


fv3 = tradius==3 ? origsuper.MAnalyse(isb=false,delta=3,overlap=aaov,blksize=aablk) : nop()
fv2 = tradius>=2 ? origsuper.MAnalyse(isb=false,delta=2,overlap=aaov,blksize=aablk) : nop()
fv1 = tradius>=1 ? origsuper.MAnalyse(isb=false,delta=1,overlap=aaov,blksize=aablk) : nop()
bv1 = tradius>=1 ? origsuper.MAnalyse(isb=true, delta=1,overlap=aaov,blksize=aablk) : nop()
bv2 = tradius>=2 ? origsuper.MAnalyse(isb=true, delta=2,overlap=aaov,blksize=aablk) : nop()
bv3 = tradius==3 ? origsuper.MAnalyse(isb=true, delta=3,overlap=aaov,blksize=aablk) : nop()
sDD = tradius==1 ? sD.MDegrain1(sDsuper,bv1,fv1) : tradius==2 ? sD.MDegrain2(sDsuper,bv1,fv1,bv2,fv2) : sD.MDegrain3(sDsuper,bv1,fv1,bv2,fv2,bv3,fv3)

reduc = 0.4
sDD = mt_lutxy(sD,sDD,"x 128 - abs y 128 - abs < x y ?").mergeluma(sDD,1.0-reduc)

return stabilize ? orig.mt_makediff(sDD,U=2,V=2) : merged
}

# Kill Combing Function from mcbob
function VinverseD(clip clp, float "sstr", int "amnt", int "uv")
{
uv   = default(uv,3)
sstr = default(sstr,2.7)
amnt = default(amnt,255)
uv2  = (uv==2) ? 1 : uv
STR  = string(sstr)
AMN  = string(amnt)
vblur  = clp.mt_convolution("1","50 99 50",U=uv,V=uv)
vblurD = mt_makediff(clp,vblur,U=uv2,V=uv2)
Vshrp  = mt_lutxy(vblur,vblur.mt_convolution("1","1 4 6 4 1",U=uv2,V=uv2),expr="x x y - "+STR+" * +",U=uv2,V=uv2)
VshrpD = mt_makediff(Vshrp,vblur,U=uv2,V=uv2)
VlimD  = mt_lutxy(VshrpD,VblurD,expr="x 128 - y 128 - * 0 < x 128 - abs y 128 - abs < x y ? 128 - 0.25 * 128 + x 128 - abs y 128 - abs < x y ? ?",U=uv2,V=uv2)
mt_adddiff(Vblur,VlimD,U=uv,V=uv)
(amnt>254) ? last : (amnt==0) ? clp : mt_lutxy(clp,last,expr="x "+AMN+" + y < x "+AMN+" + x "+AMN+" - y > x "+AMN+" - y ? ?",U=uv,V=uv) 
return(last)
}


function yadifmodclipin(clip i, bool "doyv16")
{
i.nonyuy2clipin(doyv16)
pointresize(width(),height()+8,0,-4,width(),height()+8.0001)
}

function yadifmodclipout(clip i, bool "doyuy2")
{
i.crop(0,4,-0,-4)
nonyuy2clipout(doyuy2)
}

function tmm2_ortmm1(clip clip, int "mode", int "order", int "field", int "length", int "mtype", int "ttype", int "mtqL", int "mthL", int "mtqC", int "mthC", int "nt", int "minthresh", int "maxthresh", int "cstr", int "opt")
{
avs26=!(VersionNumber() < 2.6)
nonyuy2=avs26 && clip.isyuy2()
avs26 ? clip.nonyuy2clipin(nonyuy2).tmm2(mode, order, field, length, mtype, ttype, mtqL, mthL, mtqC, mthC, nt, minthresh, maxthresh, cstr, opt).nonyuy2clipout(nonyuy2) : \
        clip.TMM(mode, order, field, length, mtype, ttype, mtqL, mthL, mtqC, mthC, nt, minthresh, maxthresh, cstr)
}

function nonyuy2clipin(clip i, bool "doyv16")
{
doyv16 ? Eval("try { i.PackedToPlanar() } catch(error_msg) { i.converttoyv16() }") : i
}

function nonyuy2clipout(clip i, bool "doyuy2")
{
doyuy2 ? Eval("try { i.PlanarToPacked() } catch(error_msg) { i.converttoyuy2() }") : i
}