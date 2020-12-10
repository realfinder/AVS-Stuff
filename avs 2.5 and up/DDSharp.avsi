# DDSharp, Didée unfinshed sharping
# 2020.12.09
Function DDSharp(clip c, int "rad")
{
sisavs26=!(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
sisfullchr = sisphbd ? c.is444() : sisavs26 ? c.isyv24() : false
sislumaonly = sisphbd ? c.isy() : sisavs26 ? c.isy8() : true
rad = Default(rad, round(c.height() / 90))
Assert(rad > 0, "rad must be more than 0")
pad = m4_sh(rad,sisfullchr || sislumaonly ? 0 : 2)
c = c.sh_Padding(pad,pad,pad,pad)
reppasses = round(rad/1.5)
crad = sisfullchr ? rad : reppasses
b = c.medianblur(rad,crad,crad)
d = b.spasses2(reppasses,"fclip2.repair(i,1)",fclip2=c)
sisavs26 ? mt_lutxy(c,d,"x x y - abs 1.62 2 ^ / 1 1.62 / ^ 1.62 3 ^ * x y - x y - abs 1.62 + / * +", scale_inputs="allf", use_expr=1, U=3, V=3) : mt_lutxy(c,d,"x x y - abs 1.62 2 ^ / 1 1.62 / ^ 1.62 3 ^ * x y - x y - abs 1.62 + / * +",U=3,V=3)
crop(pad,pad,-pad,-pad,true)
}