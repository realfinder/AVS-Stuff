# AnimeIVTC() by thetoof
# v2.31 2020-10-22 mod
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
# added mode 7 same as 5 but use better but slower nnrep method to ediandnn, mode 8 too, but it's like 6, and now you can use negative value for use nnedi3 with Padding to avoids edges distortion on top and bottom
# add d2v and tfmtrimIn
# simiauto using tfmtrimIn (autoload TrimInFile.txt)
# change mode22 from bool to int from -1 to 3, 0 now same as false, 1 now same as true

# Read the documentation for all the required info to know how to use this function, With note that there are some things have changed in this MOD

function AnimeIVTC (clip i, int "mode", int "aa", int "precision", int "killcomb", int "cache", bool "ifade", float "sfthr", bool "sfshow"\
		, val "chrfix" \
		, bool "blend" \  
		, bool "normconv" \
		, int "pattern" \
		, int "pass", bool "rendering" \
		, int "bbob", int "cbob", string "edimode", int "degrain", int "omode", int "cthresh", int "blockx", int "blocky", int "MI", int "tfmm", int "pp", int "metric", int "micmatching", bool "mChroma", bool "Chroma" \
		, int "i1", int "i2", int "e1", int "e2", int "e3", int "p1", int "p2", bool "dchr", bool "palf", bool "tcfv1", bool "nvfr", bool "real30p", bool "autoAssuf", int "ediandnn", bool "o3025cfr", string "bbob4_params", bool "crepwithtdeint", int "tdeinttype" \
		, int "overlap", int "pel", int "search", bool "nnedi3pel", val "credconv", int "mode22", val "ediext", string "bob4p", clip "extbob", string "extbobf", bool "repwithtdeint", bool "bobpresmooth", string "cbob4_params", bool "tdeintsharp", val "prefiltered_i" \
		, float "dark", int "thin", int "sharp", int "smooth", bool "stabilize", int "tradius", int "aapel", int "aaov", int "aablk", string "aatype", int "vidDetect", string "d2v", string "tfmtrimIn", int "threads", float "autoAssufthr1", float "autoAssufthr2", float "autoAssufmthr", int "tfmslow"){

###General arguments###
Assert(defined(mode), "Specify a mode... please read the documentation.")

#Highest quality by default
precision 	= default ( precision, 		  3 ) 
tfmslow 	= default ( tfmslow, 		  2 ) 

#change pal fps
palf	= default ( palf,         false )
o3025cfr	= default ( o3025cfr,       false )

#VFR default optional
nvfr	= default ( nvfr,         false )
Threads      = default( Threads, sh_GetUserGlobalIMTint())

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
autoAssuf = default( autoAssuf,      false)
autoAssufthr1 = default( autoAssufthr1, 0.5)
autoAssufthr2 = default( autoAssufthr2, 2.0)
autoAssufmthr = default( autoAssufmthr, 3.0)

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


sisavs26 = !(VersionNumber() < 2.60)
yadiffun=!sisavs26 ? "yadifmod" : "yadifmod2"
sisyuy2 = i.isyuy2()
nonyuy2=sisavs26 && sisyuy2

prefiltered_i = defined(prefiltered_i) ? isclip(prefiltered_i) ? prefiltered_i : Eval("i." + prefiltered_i) : undefined()
iforbob = defined(prefiltered_i) ? prefiltered_i : bobpresmooth ? i.sh_bob(0,0.5).nonyuy2clipin(nonyuy2).reduceflicker(strength=2).nonyuy2clipout(nonyuy2).interlaced60or50(BFF=!(GetParity(i))) : i
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
mode22	= default ( mode22,       0 )

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
edeintn= ((usecbob && cbob < 6) || (usebbob && bbob < 6) || ((usefm || usehfm) && precision < 6)) || autoAssuf ? defined(ediext) ? ediext : ediandnn != 2 || ediandnn != -2 ? ediandnn < 0 ? iforbob.sh_Padding(2,4,2,4,threads=threads).nnedi3(-2,threads=threads).crop(2,4,-2,-4,true) : iforbob.nnedi3(-2,threads=threads) : nop() : nop()
ediandnn=abs(ediandnn)
edeint= ((usecbob && cbob < 6) || (usebbob && bbob < 6) || ((usefm || usehfm) && precision < 6)) || autoAssuf ? defined(ediext) ? ediext : ediandnn == 1 ? edeintn : ediandnn == 2 ? iforbob.eedi3(-2,threads=threads) : ediandnn > 6 ? i.eedi3(-2,sclip=edeintn,threads=threads).nonyuy2clipin(nonyuy2).slimit_dif(edeintn,thr=4).nonyuy2clipout(nonyuy2) : ediandnn > 4 ? sisyuy2 ? i.eedi3(-2,sclip=edeintn,threads=threads).Interleaved2Planar().Repair(edeintn,9,Planar=true).Planar2Interleaved() : i.eedi3(-2,sclip=edeintn,threads=threads).Repair(edeintn,9) : i.eedi3(-2,sclip=edeintn,threads=threads) : edeintn
emask = (usebbob && (bbob==2 || ((bbob==3 || bbob==4) && reptdei) || bbob==6)) || (usecbob && (cbob==2 || ((cbob==3 || cbob==4) && reptdei) || cbob==6)) || ((usefm || usehfm) && precision==3) ? iforbob.tmm2_ortmm1(1) : nop()


###Alright, let's start doing something :p ###

#########
#Bobbing#
#########

#Use non-motion-compensated bobber for blended clips since blends have a negative impact on motion detection (if blends are averaged with frames, they can be harder to detect/remove) (mode=2 and mode=1 with blend and chrfix because blend telecine... well has a lot of blends)
blendbob 	= usebbob ?	bbob<=0 ? iforbob.tdeint(1) 			 		 	                : 
\				bbob==1 ? iforbob.tdeint(1,		edeint=edeint	) 	 	                : 
\				bbob==2 ? iforbob.tdeint(1,		edeint=edeint,emask=emask)	 	        : 
\				bbob==3 ? reptdei ? ediandnn==4 || ediandnn==6 || ediandnn==8 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain, EdiThreads=Threads" + bbob4_params + ").yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=1,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) 		 		        :
\				bbob==4 ? Eval("iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain, EdiThreads=Threads" + bbob4_params + ")")	:
\				bbob==5 ? extbob	 	        : 
\				          i.tdeint(1, emask=emask, sharp=tdeintsharp, type=tdeinttype)                      	                                        : NOP()
blendbob 	= usebbob ?	((bbob==3 || bbob==4) && reptdei) ? isyuy2(i) ? blendbob.Interleaved2Planar.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype).Interleaved2Planar,Planar=true).Planar2Interleaved : blendbob.Repair(i.tdeint(1,emask=emask, sharp=tdeintsharp, type=tdeinttype)) : blendbob : nop()

#Allow usage of mo-comp bobber (TempGaussMC) when source is not blended. Highly recommended for stability. (mode=3, interlaced credits, used in chrfix because impact is minimal compared to bob flicker on the whole clip)
clearbob 	= usecbob ?	cbob<=0 ? iforbob.tdeint(1)						                : 
\				cbob==1 ? iforbob.tdeint(1,		edeint=edeint)			                : 
\				cbob==2 ? iforbob.tdeint(1,		edeint=edeint,emask=emask)	                : 
\				cbob==3 ? creptdei ? ediandnn==4 || ediandnn==6 || ediandnn==8 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ").yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=1,edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2)			                :
\			        cbob==4 ? Eval("iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain, EdiThreads=Threads" + cbob4_params + ")")	:
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
\	(precision==5 && ((usefm && !blend) || usehfm)) ? reptdei ? ediandnn==4 || ediandnn==6 || ediandnn==8 ? Eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=2,edeint=iforbob.QTGMC(Preset=bob4p,edimode=edimode,ediext= !defined(edimode) && !defined(ediext) ? edeint : ediext,tr2=degrain" + bbob4_params + ").SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=2,edeint=edeint.SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : eval("iforbob.yadifmodclipin(nonyuy2)."+yadiffun+"(edeint=edeint.SelectEven().yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2) : 
\	(precision==6 && ((usefm && !blend) || usehfm)) ? i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype) : 
\	(precision==7 && ((usefm && !blend) || usehfm)) ? extbob.SelectEven : 
\	(precision==8 && ((usefm && !blend) || usehfm)) ? extbob : 
\	(precision==9 && ((usefm && !blend) || usehfm)) ? blendbob.SelectEven : 
\	nop()
tfmcli2=(usefm && !blend) || usehfm ? precision==5 && reptdei ? isyuy2(i) ? tfmcli2.Interleaved2Planar.Repair(i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype).Interleaved2Planar,Planar=true).Planar2Interleaved : tfmcli2.Repair(i.tdeint(0,emask=iforbob.tmm2_ortmm1(0), sharp=tdeintsharp, type=tdeinttype)) : tfmcli2 : nop()

tfmtrimIn = defined(tfmtrimIn) ? tfmtrimIn : defined(d2v) && Exist("TrimInFile.txt") ? "TrimInFile.txt" : undefined

#field match for hard telecine or blend telecine restoration for mode==1

fm =  (precision==0 && usefm) ? blend ? debprep.srestore(omode="pp0") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=0,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==1 && usefm) ? blend ? debprep.srestore(omode="pp1") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==2 && usefm) ? blend ? debprep.srestore(omode="pp2") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==3 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==4 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==5 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==6 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==7 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==8 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  (precision==9 && usefm) ? blend ? debprep.srestore(omode="pp3") : i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI,metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\	  nop()
fm =  usefm ? ifade ? fm.smartfademod(sfthr, sfshow, cache) : fm : nop()

#Field match + tfm.txt output for VFR clips (mode=4, pass=1)

hybridfm = (usehfm && precision==0) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=0,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==1) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==2) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==3) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==4) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==5) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==6) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==7) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==8) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		   (usehfm && precision==9) ? i.tfm(slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=MI, output="tfm.txt",metric=metric,micmatching=micmatching,pp=pp,clip2=tfmcli2,mChroma=mChroma,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn) : 
\		    nop()

usefm && autoAssuf ? eval("""
global aivtcfm = fm
global aivtcaAthr1 = autoAssufthr1
global aivtcaAthr2 = autoAssufthr2
sourford = i.getparity() ? 1 : 0
iyadifmc = eval("i.yadifmodclipin(nonyuy2)."+yadiffun+"(mode=3, edeint=edeint.yadifmodclipin(nonyuy2))").yadifmodclipout(nonyuy2)

global invfm = i.Tfm(field=sourford==1 ? 0 : 1,slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=defined(MI) ? Int(MI*5/4) : undefined,metric=metric,pp=precision==0 ? 0 : pp,clip2=tfmcli2,micmatching=0, mchroma=false,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn)
fminv2       = ScriptClip(iyadifmc, "
						invfv=Interleave(DeleteFrame(0).SelectEven(),invfm).crop(16,16,-16,-16).cFrameDiff(prevf=true, chroma=false, denoise=true, nt=1)
						fv   =Interleave(SelectEven(),             aivtcfm).crop(16,16,-16,-16).cFrameDiff(prevf=true, chroma=false, denoise=true, nt=1)
						fv > aivtcaAthr1 && invfv < aivtcaAthr2 ? fv > invfv ? Interleave(invfm,invfm) : Interleave(aivtcfm,aivtcfm) : Interleave(aivtcfm,aivtcfm)
						").Selectodd()
fm           = conditionalfilter(fm.crop(16,16,-16,-16),fminv2,fm,"cFrameDiff(prevf=false, chroma=false, denoise=true, nt=1)","<",string(autoAssufmthr))
""") : nop()

invhybridfm    = usehfm ? autoAssuf ? conditionalfilter(hybridfm.crop(16,16,-16,-16),i.Tfm(field=sourford==1 ? 0 : 1,slow=tfmslow,mode=tfmm,cthresh=cthresh,blockx=blockx,blocky=blocky,MI=defined(MI) ? Int(MI*5/4) : undefined,metric=metric,pp=precision==0 ? 0 : pp,clip2=tfmcli2,micmatching=0, mchroma=false,Chroma=Chroma,d2v=d2v,trimIn=tfmtrimIn),hybridfm,"IsCombedTIVTC(15,13,false,8,4,1)","=","true") : hybridfm : nop()
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
fbdecim = mode==2 ? mode22 > 2 ? chrfix_b ? Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob.detearing()).srestore(omode=1, thresh=44).RequestLinear().SelectOdd().srestore(omode=2, mode=4, thresh=44, cache=cache*3/2).srestore(frate=frate, mode=4, speed=-4, cache=cache) : 	Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob.detearing()).srestore(omode=1, thresh=44).RequestLinear().SelectOdd().srestore(omode=2, mode=4, thresh=44, cache=cache*3/2).srestore(frate=frate, mode=-4, speed=-4, cache=cache) 	:
\                   mode22 > 1 ? chrfix_b ? Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob).srestore(omode=1, thresh=44).RequestLinear().SelectOdd().srestore(omode=2, mode=4, thresh=44, cache=cache*3/2).srestore(frate=frate, mode=4, speed=-4, cache=cache) : 	Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob).srestore(omode=1, thresh=44).RequestLinear().SelectOdd().srestore(omode=2, mode=4, thresh=44, cache=cache*3/2).srestore(frate=frate, mode=-4, speed=-4, cache=cache) 	:
\                   mode22 > 0 ? chrfix_b ? fbbob.srestore(omode=2, mode=4, thresh=44, cache=cache*3/2, dclip=fbbob.crop(16,16,-16,-16)).srestore(frate=frate, mode=4, speed=-4, cache=cache) : 	fbbob.srestore(omode=2, mode=4, thresh=44, cache=cache*3/2, dclip=fbbob.crop(16,16,-16,-16)).srestore(frate=frate, mode=-4, speed=-4, cache=cache) 	:
\                   mode22 < 0 ? chrfix_b ? Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob).srestore(frate=frate*2, mode=4, speed=-4).RequestLinear().srestore(frate=frate, mode=4, speed=-4, cache=cache) : 	Interleave(Merge(fbbob.DuplicateFrame(0).DeleteFrame(fbbob.FrameCount()),fbbob),fbbob).srestore(frate=frate*2, mode=-4, speed=-4).RequestLinear().srestore(frate=frate, mode=-4, speed=-4, cache=cache) 	:
\                                chrfix_b ? fbbob.srestore(frate=frate, cache=cache) : 	fbbob.srestore(frate=frate, cache=cache, dclip=i.bob(-0.2,0.6).nonyuy2clipin(nonyuy2).reduceflicker(strength=1).nonyuy2clipout(nonyuy2)) 	: nop()

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
credbobsuper	= usemocompi ? Defined(threads) ? credbob.MSuper(pel=pel, levels=0, mt=threads!=1) : credbob.MSuper(pel=pel, levels=0) : nop()
credbobupsuper	= usemocompi && nnedi3pel ? Defined(threads) ? credbob.MSuper(pel=pel, levels=0, pelclip=upsi, mt=threads!=1) : credbob.MSuper(pel=pel, levels=0, pelclip=upsi) : nop()

#Calculate vectors
bvi = 		usemocompi ? nnedi3pel ? 	Defined(threads) ? credbobupsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap, mt=threads!=1)  : credbobupsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : 
\						Defined(threads) ? credbobsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap, mt=threads!=1)  : credbobsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : nop()

fvi = 		usemocompi ? nnedi3pel ? 	Defined(threads) ? credbobupsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : credbobupsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : 
\						Defined(threads) ? credbobsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : credbobsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : nop()

#Apply framerate conversion
fpsconvi =  	usemocompi ? nnedi3pel ? 	credbob.	MFlowFps(credbobupsuper,bvi, fvi, tnum, tden) 			 : 
\						credbob.	MFlowFps(credbobsuper,  bvi, fvi, tnum, tden) 			 : nop()

###Convert the framerate of the progressive credits
#Determine if usage of the following conversion is required
usemocompp = isclip(credconv) ? defined(p1) : defined(p1) && credconv=="mocomp"

#External pelclip on source with nnedi, if requested
upsp = 		nnedi3pel && usemocompp ? pel==2 ? blendbg.nnedi3_rpow2(rfactor=2,threads=threads) : blendbg.nnedi3_rpow2(rfactor=2,threads=threads).nnedi3_rpow2(rfactor=2,threads=threads) : nop()

#Prepare super clip for the progressive credits
blendbgsuper	= usemocompp ?			Defined(threads) ? blendbg.MSuper(pel=pel, levels=0, mt=threads!=1) : blendbg.MSuper(pel=pel, levels=0) 						 : nop()
blendbgsuperup	= usemocompp && nnedi3pel ? 	Defined(threads) ? blendbg.MSuper(pel=pel, levels=0, pelclip=upsp, mt=threads!=1) : blendbg.MSuper(pel=pel, levels=0, pelclip=upsp) 				 : nop()

#Calculate vectors
bvp = 		usemocompp ? nnedi3pel ? 	Defined(threads) ? blendbgsuperup.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : blendbgsuperup.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : 
\						Defined(threads) ? blendbgsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : blendbgsuper.	MAnalyse(isb = true,search=search, blksize=bs, overlap=overlap)  : nop()

fvp = 		usemocompp ? nnedi3pel ? 	Defined(threads) ? blendbgsuperup.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : blendbgsuperup.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : 
\						Defined(threads) ? blendbgsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap, mt=threads!=1) : blendbgsuper.	MAnalyse(isb = false,search=search, blksize=bs, overlap=overlap) : nop()

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


#############
# helper functions for trims

# Abridgement trims
function abtrim(string "trimline") {
Assert(defined(trimline), "'abtrim' trimline is needed")
function abtrimloop(string "trimline", int "remainder") {
remainder = default(remainder, -1)
otrimline = trimline
sisending = !(remainder < StrLen(trimline))
trimline = remainder > 0 ? !sisending ? RightStr(trimline, StrLen(trimline) - remainder) : trimline : trimline
ofindtrim = sisending ? nop() : FindStr(trimline, "trim")
sishtrim = sisending ? false : ofindtrim != 0
trimstart = !sishtrim ? nop() : ofindtrim + FindStr(MidStr(trimline, ofindtrim + 1), "(")
findtrimstart = !sishtrim ? nop() : trimstart + 1
trimend = !sishtrim ? nop() : ofindtrim + FindStr(MidStr(trimline, ofindtrim + 1), ")")
findtrimend = !sishtrim ? nop() : trimend - 1
taketrim = !sishtrim ? nop() : MidStr(trimline, findtrimstart, findtrimend - findtrimstart + 1)
trims = !sishtrim ? nop() : FindStr(taketrim, ",")
strim = !sishtrim ? nop() : MidStr(taketrim,1,trims-1).Value.Int
etrim = !sishtrim ? nop() : MidStr(taketrim,trims+1).Value.Int
ntrimr = !sishtrim ? nop() : RightStr(trimline,StrLen(trimline)-trimend)
ofindntrim = !sishtrim ? nop() : FindStr(ntrimr, "trim")
sishntrim = !sishtrim ? nop() : ofindntrim != 0
ntrimstart = !sishtrim ? nop() : sishntrim ? FindStr(ntrimr, "(") : nop()
findntrimstart = !sishtrim ? nop() : !sishntrim ? nop() : ntrimstart + 1
ntrims = !sishtrim ? nop() : !sishntrim ? nop() : FindStr(ntrimr, ",")
sntrim = !sishtrim ? nop() : !sishntrim ? nop() : MidStr(ntrimr,findntrimstart,ntrims-1).Value.Int
domerge = !sishtrim ? nop() : sishntrim ? ((etrim+1)==sntrim) : false
ntrimline=!sishtrim ? nop() : !domerge ? otrimline : LeftStr(otrimline,(remainder > 0 ? remainder : 0) + findtrimstart + trims - 1) + MidStr(ntrimr,ntrims+1)
remainder = !sishtrim ? nop() : domerge ? remainder : max(0,remainder) + trimend
!sishtrim ? otrimline : sishntrim ? abtrimloop(ntrimline, remainder) : ntrimline
}
abtrimloop(LCase(trimline))
}


# make trimIn from avs trims v1.1
function intrim(clip i, string "trimline", string "output") {
Assert(defined(trimline), "'intrim' trimline is needed")
i
lastframe = framecount() - 1
TrimFile=defined(output) ? output : "TrimInFile.TXT"
function intrimloop(clip i, string "trimline", string "output", int "lastframe", bool "firstcall") {
firstcall = default(firstcall, false)
ofindtrim = FindStr(trimline, "trim")
sishtrim = ofindtrim != 0
trimstart = !sishtrim ? nop() : FindStr(trimline, "(")
findtrimstart = !sishtrim ? nop() : trimstart + 1
trimend = !sishtrim ? nop() : FindStr(trimline, ")")
findtrimend = !sishtrim ? nop() : trimend - 1
taketrim = !sishtrim ? nop() : MidStr(trimline, findtrimstart, findtrimend-findtrimstart+1)
trims = !sishtrim ? nop() : FindStr(taketrim, ",")
strim = !sishtrim ? nop() : MidStr(taketrim,1,trims-1).Value.Int
etrim = !sishtrim ? nop() : MidStr(taketrim,trims+1).Value.Int
etrim = !sishtrim ? nop() : etrim == 0 ? lastframe : etrim
ntrimr = !sishtrim ? nop() : rightStr(trimline,StrLen(trimline)-trimend)
ofindntrim = !sishtrim ? nop() : FindStr(ntrimr, "trim")
sishntrim = !sishtrim ? nop() : ofindntrim != 0
ntrimstart = !sishtrim ? nop() : sishntrim ? FindStr(ntrimr, "(") : nop()
findntrimstart = !sishtrim ? nop() : !sishntrim ? nop() : ntrimstart + 1
ntrims = !sishtrim ? nop() : !sishntrim ? nop() : FindStr(ntrimr, ",")
sntrim = !sishtrim ? nop() : !sishntrim ? nop() : MidStr(ntrimr,findntrimstart,ntrims-1).Value.Int
istrim = !sishtrim ? nop() : !sishtrim ? nop() : strim !=0 && firstcall ? 0 : etrim + 1
ietrim = !sishtrim ? nop() : !sishtrim ? nop() : firstcall && istrim == 0 ? strim-1 : sishntrim ? sntrim - 1 : lastframe
writeline = sishtrim ? etrim < lastframe : false
writeline ? RT_WriteFile(output, \
                 "%d,%d\n", istrim, ietrim, append=!firstcall) : nop()
sishtrim ? intrimloop(i, firstcall && istrim == 0 ? trimline : rightStr(trimline,StrLen(trimline)-trimend), output, lastframe) : i
}
intrimloop(abtrim(trimline), TrimFile, lastframe, true)
eval(trimline)
}


# ghetto IVTC by Katie Boundary
# maybe it need some modification in the future
# v1.0, mod 0.0

function KIVTC(clip i) {
i
separatefields()

A=selecteven().tdecimate(mode=1)
B=selectodd().tdecimate(mode=1)

interleave(A,B).weave()
}


##############
# detearing

function detearing(clip c)
{
c
swapped = StackVertical(Crop(0,0,0,-Height()/2, align=true),DuplicateFrame(0).Crop(0,Height()/2,0,0, align=true))
cmetric = Crop(0, (Height()/2)-2, 0, (Height()/2)+2, align=true)
smetric = swapped.Crop(0, (Height()/2)-2, 0, (Height()/2)+2, align=true)

gscriptclip(last,"""
sisphbd = AvsPlusVersionNumber > 2294
sischbd = sisphbd ? BitsPerComponent() > 8 : false
vsc = sischbd ? BitsPerComponent() == 10 ? 4 : BitsPerComponent() == 12 ? 8 : BitsPerComponent() == 14 ? 64 : 256 : nop()
diff=LumaDifference(smetric, cmetric)
botc=last.Crop(0,Height()/2,0,0, align=true)
cdiff=mt_average(swapped.Crop(0,Height()/2,0,0, align=true),botc)
cdiff=LumaDifference(cdiff, botc)
smetric=YPlaneMax(smetric.mt_convolution(horizontal="-1 2 -1",vertical="-1 2 -1"))
cmetric=YPlaneMax(cmetric.mt_convolution(horizontal="-1 2 -1",vertical="-1 2 -1"))
smetric > cmetric || diff > (sischbd ? isvideofloat() ? 0.6/255 : 0.6*vsc : 0.6) ? last : cdiff < (sischbd ? isvideofloat() ? 1.0/255 : 1.0*vsc : 1) ? swapped : last
""", args="cmetric,smetric,swapped")
}


##############
# sanimebob by A.SONY
# 1.74

function sanimebob(clip i, val "useqtgmc", val "bobpresmooth", float "Str", float "Amp", bool "TV_range", bool "qtgmc_lsb", bool "usedaa3mod", bool "usesmam", int "tr2", bool "repblend", val "dslow", bool "qtgmc_n16", int "nnrep", bool "nnedi3pad", bool "usetfm", string "tfm_params", bool "useBWDIF", int "NNSize", int "NNeurons", int "EdiQual", int "EdiMaxD", int "tfm_mi") {

sisphbd = AvsPlusVersionNumber > 2294
qtgmc_lsb = default(qtgmc_lsb, sisphbd ? false : true)
qtgmc_n16 = default(qtgmc_n16, sisphbd ? i.BitsPerComponent() > 8 ? false : true : false)
threads = sh_GetUserGlobalIMTint()

useq                  = default (useqtgmc,                                                                                                           0)
Stringuseq        = IsString(useq                                                                                                                 )
useBWDIF       = default (useBWDIF, false)
bobpresmbool = defined(bobpresmooth) ? isbool(bobpresmooth) ? bobpresmooth : true : !Stringuseq ? useq==8 : useBWDIF
Str                     = default (Str,                                                                                                              1.5)
tr2                     = default (tr2,                                                                                !Stringuseq ? useq==8 ? 3 : 1 : 1)
usedaa3mod   = default (usedaa3mod,                                          useBWDIF || ( !Stringuseq ? useq==4 || useq==5 || useq==7 || useq==9 : false))
usesmam        = default (usesmam,                           (usedaa3mod && useBWDIF) || (  !Stringuseq ? !(useq==0 || useq==1 || useq==8) : false))
nnrep               = default (nnrep, useBWDIF ? 2 : 0)
nnedi3pad       = default (nnedi3pad, useBWDIF)
tfm_mi = default (tfm_mi, useBWDIF ? 40 : undefined)
usetfm       = default (usetfm, false)
tfm_params = default(tfm_params, "")
NNeurons = default(NNeurons, usesmam && useBWDIF ? 1 : undefined)
NNSize = default(NNSize, usesmam && useBWDIF ? 1 : undefined)
EdiMaxD = default(EdiMaxD, usesmam && useBWDIF ? 8 : undefined)

sisyuy2 = i.isyuy2()
sisavs26 = !(VersionNumber() < 2.60)

Assert(Isint(useq) || Stringuseq, "'useqtgmc' only accepts int or string")

prefiltered_i   = defined(bobpresmooth) ? isclip(bobpresmooth) ? bobpresmooth : IsString(bobpresmooth) ? Eval("i." + bobpresmooth) : undefined() : undefined()

nonyuy2=sisavs26 && sisyuy2
iforbob   = bobpresmbool ? defined(prefiltered_i) ? prefiltered_i : i.sh_bob(0,0.5).nonyuy2clipin(nonyuy2).reduceflicker(strength=2).nonyuy2clipout(nonyuy2).interlaced60or50(BFF=!(GetParity(i))) : i
iforbob   = bobpresmbool && !defined(prefiltered_i) ? isyuy2(i) ? iforbob.SeparateFields().Interleaved2Planar().Repair(i.SeparateFields().Interleaved2Planar(),Planar=true).Planar2Interleaved().weave() : iforbob.SeparateFields().Repair(i.SeparateFields()).weave() : iforbob

pyi       = i.sh_Padding(0,4,0,4,threads=threads)
pni       = nnedi3pad ? iforbob.sh_Padding(2,4,2,4,threads=threads).nnedi3(-2, nsize=NNSize, nns=NNeurons, qual=EdiQual,threads=threads).crop(2,4,-2,-4,true) : iforbob.nnedi3(-2, nsize=NNSize, nns=NNeurons, qual=EdiQual,threads=threads)
pei       = i.eedi3(-2, mdis=EdiMaxD,sclip=pni,threads=threads)
pei       = nnrep > 0 ? nnrep > 1 ? pei.nonyuy2clipin(nonyuy2).slimit_dif(pni.nonyuy2clipin(nonyuy2),thr=4).nonyuy2clipout(nonyuy2).sh_Padding(0,4,0,4,threads=threads) : isyuy2(i) ? pei.Interleaved2Planar().Repair(pni.Interleaved2Planar(),9,Planar=true).Planar2Interleaved().sh_Padding(0,4,0,4,threads=threads) : pei.Repair(pni,9).sh_Padding(0,4,0,4,threads=threads) : pei.sh_Padding(0,4,0,4,threads=threads)
istff     = GetParity(i)

ymodclip  = useBWDIF ? pyi.nonyuy2clipin(nonyuy2).BWDIF(-2, edeint=pei.nonyuy2clipin(nonyuy2)).crop(0,4,-0,-4) : !sisavs26 ? pyi.yadifmod(mode=3, edeint=pei).crop(0,4,-0,-4) : pyi.nonyuy2clipin(nonyuy2).yadifmod2(mode=3, edeint=pei.nonyuy2clipin(nonyuy2)).crop(0,4,-0,-4)
ymodclip  = usetfm ? eval("Interleave(i.TFM(field=istff ? 1 : 0, micmatching=0, mode=0, clip2=ymodclip.selecteven(), mi=tfm_mi" + tfm_params + "), i.TFM(field=istff ? 0 : 1, micmatching=0, mode=0, clip2=ymodclip.selectodd(), mi=tfm_mi" + tfm_params + "))") : ymodclip
yadifclip = sisyuy2 && !sisavs26 ? ymodclip.Interleaved2Planar().Repair(i.TDeint(1,emask=iforbob.tmm2_ortmm1(1)).Interleaved2Planar(),Planar=true).Planar2Interleaved() : \
                                                  ymodclip.Repair(i.TDeint(1,emask=iforbob.tmm2_ortmm1(1)).nonyuy2clipin(nonyuy2)).nonyuy2clipout(nonyuy2)

# for custom qtgmc, don't forget to put the input clip like this:- iforbob.QTGMC(... or yadifclip.QTGMC(... or i.QTGMC(...
QTGMCclip = isstring(useq) ? eval(useq) : \
                             useq==0 ? yadifclip : \
       useq==1 || useq==2 || useq==4 ? iforbob.QTGMC(SourceMatch=3, Lossless=2, EdiExt=yadifclip, tr0=1, tr1=1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep0=11, rep1=11, rep2=11, Sharpness=0.1, TV_range=TV_range, Str=Str, Amp=Amp, EdiThreads=threads) : \
                  useq==3 || useq==5 ? yadifclip.QTGMC(InputType=1, tr0=1, tr1=1, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, rep0=11, rep1=11, rep2=11, Sharpness=0.1, TV_range=TV_range, Str=Str, Amp=Amp, EdiThreads=threads) : \
                  useq==6 || useq==7 ? yadifclip.QTGMC(InputType=1, tr0=0, lsb=qtgmc_lsb, n16=qtgmc_n16, Sharpness=usedaa3mod ? 0.0 : 0.1, TV_range=TV_range, Str=Str, Amp=Amp, EdiThreads=threads) : \
                                       i.QTGMC(SourceMatch=3, Lossless=2, EdiExt=yadifclip, useEdiExt=!(useq==9), tr0=useq==9 ? -1 : undefined(), rep0=useq==9 ? undefined() : 11, tr2=tr2, lsb=qtgmc_lsb, n16=qtgmc_n16, Sharpness=0.0, TV_range=TV_range, Str=Str, Amp=Amp, EdiThreads=threads)

daa3mclip = usedaa3mod ? QTGMCclip.daa3mod(dslow,threads=threads) : QTGMCclip

!usesmam ? daa3mclip : \
           useBWDIF ? yadifclip.Vinverse_avsi(custem=yadifclip.smam(filter=daa3mclip,repblend=repblend)) : yadifclip.smam(filter=daa3mclip,repblend=repblend)
}