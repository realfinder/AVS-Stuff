#  SeeSaw v0.3e (02 Jan 2006)
#  ( modded 07 Sep 2018 )
#    Mod due to this change in v2.6: Force int call arguments to user script function float params to be explicit floats.
#    yet another one in 2020-01-31 for avs+
#
#  (Full Name: "Denoiser-and-Sharpener-are-riding-the-SeeSaw" )
#
#  This function provides a (simple) implementation of the "crystality sharpen" principle.
#  In conjunction with a user-specified denoised clip, the aim is to enhance
#  weak detail, hopefully without oversharpening or creating jaggies on strong
#  detail, and produce a result that is temporally stable without detail shimmering, 
#  while keeping everything within reasonable bitrate requirements.
#  This is done by intermixing source, denoised source and a modified sharpening process,
#  in a seesaw-like manner.
#
#
#  Usage:
#
#  a = TheNoisySource
#  b = a.YourPreferredDenoising()
#  SeeSaw( a, b, [parameters] )
#
#  You're very much encouraged to feed your own custom denoised clip into SeeSaw.
#  If the "denoised" clip parameter is omitted, a simple "spatial pressdown" filter is used.
#
#
#  Fiddled together by Didée, for your pleasure.
#



# =======  Main function  =======

function SeeSaw( clip  input, clip "denoised", 
 \               int   "NRlimit",int "NRlimit2", 
 \               float "Sstr",   int "Slimit", float "Spower", float "SdampLo", float "SdampHi", float "Szp",
 \               float "bias",   int "Smode",    int "sootheT",  int "sootheS", float "ssx",     float "ssy")
{
sisavs26   = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? input.isy() : VersionNumber() < 2.6 ? true : input.isy8()
clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()
denoised = defined(denoised) ? sislumaonly ? denoised : sisphbd ? denoised.converttoy() : denoised.converttoy8() : denoised
ssx      = Float(default( ssx,1.0 ))         # supersampling factor x  /  SeeSaw doesn't require supersampling urgently. 


ssy      = Float(default( ssy,ssx ))         # supersampling factor y  /  if at all, small values ~1.25 seem to be enough.
NRlimit  = default( NRlimit,    2 )          # absolute limit for pixel change by denoising
NRlimit2 = default( NRlimit2, NRlimit+1)     # limit for intermediate denoising
Sstr     = Float(default( Sstr,1.5 ))        # Sharpening strength (don't touch this too much)
Slimit   = default( Slimit, NRlimit+2 )      # positive: absolute limit for pixel change by sharpening
                                             # negative: pixel's sharpening difference is reduced to diff=pow(diff,1/abs(limit))
Spower   = Int(default( Spower,4 ))          # exponent for modified sharpener
Szp      = Float(default(Szp,16+2 ))         # zero point - below: overdrive sharpening - above: reduced sharpening
SdampLo  = Float(default(SdampLo,Spower+1))  # reduces overdrive sharpening for very small changes
SdampHi  = Float(default(SdampHi,24 ))       # further reduces sharpening for big sharpening changes. Try 15~30. "0" disables.
bias     = Float(default( bias,49 ))         # bias towards detail ( >= 50 ) ,  or towards calm result ( < 50 )
Smode    = default(Smode,ssx<1.35 ? 11 : ssx<1.51 ? 20 : 19 )
sootheT  = default( sootheT,  49 )           # 0=minimum, 100=maximum soothing of sharpener's temporal instableness.
                                             # (-100 .. -1 : will chain 2 instances of temporal soothing.)
sootheS  = default( sootheS,   0 )           # 0=minimum, 100=maximum smoothing of sharpener's spatial effect.

Szp   = Szp / pow(Sstr, 1.0/4.0) / pow( (ssx+ssy)/2.0, 1.0/2.0 ) 
SdampLo = SdampLo / pow(Sstr, 1.0/4.0) / pow( (ssx+ssy)/2.0, 1.0/2.0 )

ox=clp.width
oy=clp.height
xss = m4_sh(ox*ssx)
yss = m4_sh(oy*ssy)
NRL   = string( NRlimit  )
NRL2  = string( NRlimit2 )
NRLL  = string( int(round( NRlimit2 * 100.0/bias - 1.0 )) )
SLIM  = string( abs(Slimit) )
BIAS1 = string( bias )
BIAS2 = string( 100-bias )
#ZRP   = string( abs(Szp) )
#PWR   = string( abs(Spower) )
#DMP   = string( SdampLo )

denoised = defined(denoised) ? denoised : sisavs26 ? mt_lutxy(clp,clp.removegrain(4,-1),"x "+NRL+" scalef + y < x "+NRL+" scalef + x "+NRL+" scalef - y > x "+NRL+" scalef - y ? ?",chroma="copy first",use_expr=1) : mt_lutxy(clp,clp.removegrain(4,-1),"x "+NRL+" + y < x "+NRL+" + x "+NRL+" - y > x "+NRL+" - y ? ?",chroma="copy first")

NRdiff = mt_makediff(clp,denoised,chroma="process")
tame   = sisavs26 ? mt_lutxy(clp,denoised,"x "+NRLL+" scalef + y < x "+NRL2+" scalef + x "+NRLL+" scalef - y > x "+NRL2+" scalef - x "+BIAS1+" * y "+BIAS2+" * + 100 / ? ?",use_expr=2) : mt_lutxy(clp,denoised,"x "+NRLL+" + y < x "+NRL2+" + x "+NRLL+" - y > x "+NRL2+" - x "+BIAS1+" * y "+BIAS2+" * + 100 / ? ?")
head   = tame.sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,4)
head = head.mt_merge(tame,tame.mt_edge("prewitt",0,255,0,0,U=1,V=1).mt_expand().removegrain(20,-1)) 

(ssx==1.0 && ssy==1.0) ? repair(tame.sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,Smode),head,1,-1,-1) 
 \                     : repair(tame.lanczosresize(xss,yss).sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,Smode),head.bicubicresize(xss,yss,-.2,.6),1,-1,-1).lanczosresize(ox,oy)

sh_SootheSS(last,tame,sootheT,sootheS)
sharpdiff= mt_makediff(tame,last)

(NRlimit==0) ? clp : \
sisavs26 ? mt_lutxy(clp,NRdiff, "y range_half "+NRL+" scalef + > x "+NRL+" scalef - y range_half "+NRL+" scalef - < x "+NRL+" scalef + x y range_half - - ? ?",chroma="process",use_expr=1) : mt_lutxy(clp,NRdiff, "y 128 "+NRL+" + > x "+NRL+" - y 128 "+NRL+" - < x "+NRL+" + x y 128 - - ? ?",chroma="process")

Slimit>=0 ? sisavs26 ? mt_lutxy(last,sharpdiff,"y range_half "+SLIM+" scalef + > x "+SLIM+" scalef - y range_half "+SLIM+" scalef - < x "+SLIM+" scalef + x y range_half - - ? ?",chroma="copy first",use_expr=1) : mt_lutxy(last,sharpdiff,"y 128 "+SLIM+" + > x "+SLIM+" - y 128 "+SLIM+" - < x "+SLIM+" + x y 128 - - ? ?",chroma="copy first")
 \        : sisavs26 ? mt_lutxy(last,sharpdiff,"y range_half == x x y range_half - abs 1 "+SlIM+" / ^ y range_half - y range_half - abs / * - ?",chroma="copy first",use_expr=1) : mt_lutxy(last,sharpdiff,"y 128 == x x y 128 - abs 1 "+SlIM+" / ^ y 128 - y 128 - abs / * - ?",chroma="copy first")

sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)

return( last )
}


#  SeeSaw2 ( modified for standard definition dvds. by jeremy duncan november 11, 2008 )
# this is fix ver. in 2018 9 07
#    yet another one in 2019-07-30 for avs+
#
#  (Full Name: "Denoiser-and-Sharpener-are-riding-the-SeeSaw" )
#
#  This function provides a (simple) implementation of the "crystality sharpen" principle.
#  In conjunction with a user-specified denoised clip, the aim is to enhance
#  weak detail, hopefully without oversharpening or creating jaggies on strong
#  detail, and produce a result that is temporally stable without detail shimmering, 
#  while keeping everything within reasonable bitrate requirements.
#  This is done by intermixing source, denoised source and a modified sharpening process,
#  in a seesaw-like manner.
#
#  This version is considered alpha.  
#
#  Usage:
#
#  a = TheNoisySource
#  b = a.YourPreferredDenoising()
#  SeeSaw( a, b, [parameters] )
#
#  You're very much encouraged to feed your own custom denoised clip into SeeSaw.
#  If the "denoised" clip parameter is omitted, a simple "spatial pressdown" filter is used.
#
#
#  Fiddled together by Didée, for your pleasure.
#
# - If you use a different resolution than standard definition dvd. Disable supersampling ssx by setting it to 1.0


# =======  Main function  =======

function SeeSaw2( clip  input, clip "denoised", 
 \               int   "NRlimit",int "NRlimit2", 
 \               float "Sstr",   int "Slimit", float "Spower", float "SdampLo", float "SdampHi", float "Szp",
 \               float "bias",   int "Smode",    int "sootheT",  int "sootheS", float "ssx",     float "ssy", bool "PAL")
{
sisavs26   = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? input.isy() : VersionNumber() < 2.6 ? true : input.isy8()
clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()
denoised = defined(denoised) ? sislumaonly ? denoised : sisphbd ? denoised.converttoy() : denoised.converttoy8() : denoised
PAL      = default( PAL,   false )
ssx      = default( ssx, PAL ? 1.17 : 1.24 ) # supersampling factor x  /  Set this to 1.24 for ntsc supersampling. Set this to 1.17 for Pal supersampling.
# for a superspeed, set ssx to 1.00 
 
ssy      = default( ssy,      ssx )       # supersampling factor y  /  if at all, small values ~1.25 seem to be enough.
NRlimit  = default( NRlimit,    0 )       # absolute limit for pixel change by denoising
NRlimit2 = default( NRlimit2, 5 )  # limit for intermediate denoising
Sstr     = default( Sstr,     1.30 )       # Sharpening strength (don't touch this too much)
Slimit   = default( Slimit, 40 )   # positive: absolute limit for pixel change by sharpening
                                          # negative: pixel's sharpening difference is reduced to diff=pow(diff,1/abs(limit))
Spower   = default( Spower,     1.0 )       # exponent for modified sharpener
Szp      = default( Szp,     1 )       # zero point - below: overdrive sharpening - above: reduced sharpening
SdampLo  = default( SdampLo, 25 )   # reduces overdrive sharpening for very small changes
SdampHi  = default( SdampHi,   52 )       # further reduces sharpening for big sharpening changes. Try 15~30. "0" disables.
bias     = default( bias,      49 )       # bias towards detail ( >= 50 ) ,  or towards calm result ( < 50 )
Smode    = default( Smode,     ssx<1.35 ? 11 : ssx<1.51 ? 20 : 19 )
sootheT  = default( sootheT,  55 )        # 0=minimum, 100=maximum soothing of sharpener's temporal instableness.
                                          # (-100 .. -1 : will chain 2 instances of temporal soothing.)
sootheS  = default( sootheS,   0 )        # 0=minimum, 100=maximum smoothing of sharpener's spatial effect.

Szp   = Szp / pow(Sstr, 1.0/4.0) / pow( (ssx+ssy)/2.0, 1.0/2.0 ) 
SdampLo = SdampLo / pow(Sstr, 1.0/4.0) / pow( (ssx+ssy)/2.0, 1.0/2.0 )

ox=clp.width
oy=clp.height
xss = m4_sh(ox*ssx, PAL ? 2 : 1)
yss = m4_sh(oy*ssy, PAL ? 2 : 1)
NRL   = string( NRlimit  )
NRL2  = string( NRlimit2 )
NRLL  = string( int(round( NRlimit2 * 100.0/bias - 1.0 )) )
SLIM  = string( abs(Slimit) )
BIAS1 = string( bias )
BIAS2 = string( 100-bias )
#ZRP   = string( abs(Szp) )
#PWR   = string( abs(Spower) )
#DMP   = string( SdampLo )

denoised = defined(denoised) ? denoised : sisavs26 ? mt_lutxy(clp,clp.removegrain(1,-1),"x "+NRL+" scalef + y < x "+NRL+" scalef + x "+NRL+" scalef - y > x "+NRL+" scalef - y ? ?",chroma="copy first",use_expr=1) : mt_lutxy(clp,clp.removegrain(1,-1),"x "+NRL+" + y < x "+NRL+" + x "+NRL+" - y > x "+NRL+" - y ? ?",chroma="copy first")

NRdiff = mt_makediff(clp,denoised,chroma="process")
tame   = sisavs26 ? mt_lutxy(clp,denoised,"x "+NRLL+" scalef + y < x "+NRL2+" scalef + x "+NRLL+" scalef - y > x "+NRL2+" scalef - x "+BIAS1+" * y "+BIAS2+" * + 100 / ? ?",use_expr=2) : mt_lutxy(clp,denoised,"x "+NRLL+" + y < x "+NRL2+" + x "+NRLL+" - y > x "+NRL2+" - x "+BIAS1+" * y "+BIAS2+" * + 100 / ? ?")
head   = tame.sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,4,true)
head   = head.mt_merge(tame,tame.mt_edge("prewitt",0,255,0,0,U=1,V=1).mt_expand().removegrain(1,-1)) 

(ssx==1.0 && ssy==1.0) ? repair(tame.sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,Smode,true),head,1,-1,-1) 
 \                     : repair(tame.spline64resize(xss, yss).sh_sharpen2(Sstr,Spower,Szp,SdampLo,SdampHi,Smode,true),head.bicubicresize(xss, yss,0.75,1.0),1,-1,-1).lanczosresize(ox,oy)

sh_SootheSS(last,tame,sootheT,sootheS,true)
sharpdiff= mt_makediff(tame,last)

(NRlimit==0) ? clp : \
sisavs26 ? mt_lutxy(clp,NRdiff, "y range_half "+NRL+" scalef + > x "+NRL+" scalef - y range_half "+NRL+" scalef - < x "+NRL+" scalef + x y range_half - - ? ?",chroma="process",use_expr=1) : mt_lutxy(clp,NRdiff, "y 128 "+NRL+" + > x "+NRL+" - y 128 "+NRL+" - < x "+NRL+" + x y 128 - - ? ?",chroma="process")

Slimit>=0 ? sisavs26 ? mt_lutxy(last,sharpdiff,"y range_half "+SLIM+" scalef + > x "+SLIM+" scalef - y range_half "+SLIM+" scalef - < x "+SLIM+" scalef + x y range_half - - ? ?",chroma="copy first",use_expr=1) : mt_lutxy(last,sharpdiff,"y 128 "+SLIM+" + > x "+SLIM+" - y 128 "+SLIM+" - < x "+SLIM+" + x y 128 - - ? ?",chroma="copy first")
 \        : sisavs26 ? mt_lutxy(last,sharpdiff,"y range_half == x x y range_half - abs 1 "+SlIM+" / ^ y range_half - y range_half - abs / * - ?",chroma="copy first",use_expr=1) : mt_lutxy(last,sharpdiff,"y 128 == x x y 128 - abs 1 "+SlIM+" / ^ y 128 - y 128 - abs / * - ?",chroma="copy first")

sislumaonly ? last : sisphbd ? CombinePlanes(last,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),last)

return( last )
}