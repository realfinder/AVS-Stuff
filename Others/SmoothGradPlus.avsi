function SmoothGradPlus(clip m, int "radius", float "thr", clip "ref", float "elast", int "Y", int "UV")
{
radius = Default(radius, 16)
Y       = Default(Y,         3)
Y2     = Y==3 ? 3 : 1
UV     = Default(UV,      3)
UV2   = UV==3 ? 3 : 1
smooth = ex_boxblur(m, radius-1, mode="mean", Y=Y2, UV=UV2)
slimit_dif(smooth, m, ref, thr, elast, Y=Y, U=UV, V=UV)
}