# HBD mod, and others
# 2020.11.04
Function HaloBuster(clip input, int "a", float "h", float "thr", float "elast", clip "predehalo", bool "lsb")
{
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? input.isy() : input.isy8()
exdhb = defined(predehalo)
lsb = Default(lsb, False)
a= Default (a, exdhb ? 8 : 32)
h = Default(h, 6.4)
thr = Default(thr, 1.0)
elast = Default(elast, 1.5)
rclip = exdhb ? !sislumaonly ? sisphbd ? predehalo.converttoy() : predehalo.converttoy8() : predehalo : undefined
rclip = exdhb ? lsb ? stackvertical (dither_get_msb (rclip).sh_padding (a, a, a, a),dither_get_lsb (rclip).sh_padding (a, a, a, a)) : rclip.sh_padding (a, a, a, a) : rclip
gray = !sislumaonly ? sisphbd ? input.converttoy() : input.converttoy8() : input
gray = lsb ? stackvertical (dither_get_msb (gray).sh_padding (a, a, a, a),dither_get_lsb (gray).sh_padding (a, a, a, a)) : gray.sh_padding (a, a, a, a)
clean = knlmeanscl (gray, d=0, a=a, s=0, h=h, stacked=lsb, rclip=rclip)
mask = svsTcanny (!lsb ? clean : clean.ditherpost (mode=-1), sigma=1.5, mode=1, gmmax=50)
mask = mt_lut (mask, "x range_max / 0.24 - 3.2 * 0.0 max 1.0 min range_max *", use_expr=2)
mask = mt_expand (mask)
mask = mt_inflate (mask)
merge  = lsb ? dither_merge16_8 (gray, clean, mask) : mt_merge (gray, clean, mask)
limit = lsb ? Dither_limit_dif16 (gray, merge, thr=thr, elast=elast) : slimit_dif(gray, merge, thr=thr, elast=elast)
crop = lsb ? Dither_crop16 (limit, a, a, -a, -a) : crop(limit, a, a, -a, -a, true)
final = sislumaonly ? crop : sisphbd ? CombinePlanes(crop,input,planes="YUV",sample_clip=input) : ytouv (input.utoy8 (), input.vtoy8 (), crop)
return final
}