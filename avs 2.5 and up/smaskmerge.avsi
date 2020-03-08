# smaskmerge 1.23 by A.SONY
# base on MasknotCL and MaskCL
# need masktools 2.2.6 or up in avs 2.6 or avs+, will work with CLExpr if it possible

function smaskmerge(clip src, clip overlay, clip mask, int "y", int "u", int "v", bool "luma", string "cplace") {
 
y = Default(y,3)
u = Default(u,2)
v = Default(v,2)
luma = Default(luma,false)
cplace = default(cplace, "MPEG2")

assert(cplace == "MPEG2" || cplace == "MPEG1", "smaskmerge: chroma siting must be MPEG2 or MPEG1") 

yuy2 = isyuy2(src)
sisavs26 = !(VersionNumber() < 2.6)
sisphbd  = sisavs26 ? AvsPlusVersionNumber > 2294 : false
sislumaonly = sisphbd ? src.isy() : sisavs26 ? src.isy8() : true
fullchr     = sisphbd ? src.is444() : sisavs26 ? src.isyv24() : false
chr420      = sisphbd ? src.is420() : src.isyv12()
chr411      = sisavs26 ? src.isyv411() : false

luma = (sisavs26 && sislumaonly) || (u!=3 && v!=3) ? false : luma

uc=luma ? !sislumaonly && !fullchr ? sisphbd ? ExtractU(src) : UToY8(src) : !sisavs26 ? UToY(src) : nop() : nop()
uvh=luma && !fullchr ? !sisavs26 || !sislumaonly ? uc.height() : nop() : nop()
uvw=luma && !fullchr ? !sisavs26 || !sislumaonly ? uc.width() : nop() : nop()

mask = yuy2 && luma ? mask.planar2Interleaved(true) : mask

mask26=luma && !fullchr && sisavs26 ? sisphbd ? mask.converttoy() : mask.converttoy8() : mask
chromalumam=luma && !fullchr ? mask.BilinearResize(uvw,uvh,src_left=chr420 && cplace == "MPEG1" ? 0 : chr411 ? -1.5 : -0.5) : nop()
 
mask = luma && !fullchr ? sisphbd ? CombinePlanes(mask,chromalumam,chromalumam,source_planes="YYY",planes="YUV",sample_clip=mask) : ytouv(chromalumam,chromalumam,mask26) : mask
nocl=false
try { cl_exprxyz(src,overlay,mask,"x y x - z 255 / * +",y=y,u=u,v=v) } catch(error_msg) { nocl=true }
nocl ? sisavs26 ? mt_lutxyz(src,overlay,yuy2 && luma ? mask.Interleaved2planar() : mask,"x y x - z yrange_max / * +",use_expr=2,clamp_float_UV=false,y=y,u=u,v=v) : mt_lutxyz(src,overlay,mask,"x y x - z 255 / * +",y=y,u=u,v=v) : last
}