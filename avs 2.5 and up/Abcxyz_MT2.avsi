# 2020.03.24
# abcxyz with high bit support, need masktools 2.2.17 or up in avs26 and avs+

function abcxyz(clip input, float "rad", float "ss", float "yrad")
{
rad  = default(rad,  3.0)   #  radius for halo removal
yrad = default(yrad, rad)
ss   = default(ss,   1.5)   #  radius for supersampling / ss=1.0 -> no supersampling

sisavs26 = !(VersionNumber() < 2.6)

sisphbd = AvsPlusVersionNumber > 2294

sislumaonly = sisphbd ? input.isy() : sisavs26 ? input.isy8() : true

clp = sislumaonly ? input : sisphbd ? input.converttoy() : input.converttoy8()

ox  = clp.width()
oy  = clp.height()
 
x      = clp.bicubicresize(m4_sh(ox/rad),m4_sh(oy/yrad)).bicubicresize(ox,oy,1,0)
y      = !sisavs26 ? mt_lutxy(clp,x,"x 8 + y < x 8 + x 24 - y > x 24 - y ? ? x y - abs * x 32 x y - abs - * + 32 /",U=2,V=2)
         \         : mt_lutxy(clp,x,"x 8 scalef + y < x 8 scalef + x 24 scalef - y > x 24 scalef - y ? ? x y - abs * x 32 scalef x y - abs - * + 32 scalef /",use_expr=2,U=2,V=2)
z1     = ss==1.0 ? repair(clp,y,1) : nop()
maxbig = ss!=1.0 ? y.mt_expand().bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)) : nop()
minbig = ss!=1.0 ? y.mt_inpand().bicubicresize(m4_sh(ox*ss),m4_sh(oy*ss)) : nop()
z2     = ss!=1.0 ? clp.lanczosresize(m4_sh(ox*ss),m4_sh(oy*ss)) : nop()
z2     = ss!=1.0 ? z2.mt_logic(maxbig,"min",U=2,V=2).mt_logic(minbig,"max",U=2,V=2).lanczosresize(ox,oy) : nop()
z2     = ss!=1.0 ? sislumaonly ? z2 : sisphbd ? CombinePlanes(z2,input,planes="YUV",sample_clip=input) : ytouv(input.utoy8(),input.vtoy8(),z2) : nop()

return( (ss==1.0) ? z1 : z2 )
}