function UnsharpMask_avsi(clip clip, float "strength", int "radius", float "threshold")
{
sisavs26 = !(VersionNumber() < 2.60)
  strength = Default(strength,64)
  radius = Default(radius,3)
  threshold = Default(threshold,8)

  rad=sspasses("1 1 1", radius - 1, " 1 1")
  blurclip = clip.mt_convolution(rad,rad)

sIsRGB=clip.IsRGB()
  e = sisavs26 ? "x y - abs " + String(threshold) + " scalef > x y - " + String(strength/128.0)+ " * x + x ?" : "x y - abs " + String(threshold) + " > x y - " + String(strength/128.0)+ " * x + x ?"
sisavs26 ? mt_lutxy(clip, blurclip, e, use_expr=1,u=sIsRGB?3:2,v=sIsRGB?3:2) : mt_lutxy(clip, blurclip, e,u=2,v=2)
}