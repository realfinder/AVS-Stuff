function Xsharpen_avsi(clip clip, float "strength", float "threshold")
{
sisavs26 = !(VersionNumber() < 2.60)
  strength = Default(strength,128)
  threshold = Default(threshold,8)

sIsRGB=clip.IsRGB()
  e = sisavs26 ? "y x - x z - min " + String(threshold) + " scalef < x z - y x - < z y ? " + String(strength / 256.0) + " * x " + String((256 - strength) / 256.0) + " * + x ?" : "y x - x z - min " + String(threshold) + " < x z - y x - < z y ? " + String(strength / 256.0) + " * x " + String((256 - strength) / 256.0) + " * + x ?"
sisavs26 ? mt_lutxyz(clip, clip.mt_expand(), clip.mt_inpand(), e, use_expr=1,u=sIsRGB?3:2,v=sIsRGB?3:2) : mt_lutxyz(clip, clip.mt_expand(), clip.mt_inpand(), e,u=2,v=2)
}