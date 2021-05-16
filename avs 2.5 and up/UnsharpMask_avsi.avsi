function UnsharpMask_avsi(clip clip, float "strength", int "radius", float "threshold")
{
  strength = Default(strength,64)
  radius = Default(radius,3)
  threshold = Default(threshold,8)

  rad=sspasses("1 1 1", radius - 1, " 1 1")
  blurclip = clip.mt_convolution(rad,rad)

sIsRGB=clip.IsRGB()
  e = "x y - abs " + String(threshold) + " scalef > x y - " + String(strength/128.0)+ " * x + x ?"
mt_lutxy(clip, blurclip, e, use_expr=1,u=sIsRGB?3:2,v=sIsRGB?3:2)
}