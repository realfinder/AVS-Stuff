# 1.11

function s444To420(clip c, bool "bic", bool "desample") {
Assert(Is444(c), "s444To420: input clip must be 444")
  bic    = default(bic, false)
  desample = default(desample, false)
  resizer = desample ? bic ? "DeBicubicResizeMT" : "DeBilinearResizeMT" : bic ? "BicubicResize" : "BilinearResize"
  UV = eval("Interleave(c.ExtractU(), c.ExtractV())."+resizer+"(c.width/2, c.height/2, src_left=desample ? 0.25 : -0.25)")
  YToUV(UV.SelectEven(), UV.SelectOdd(), c)
}


function s420To444(clip c, bool "bic") {
Assert(Is420(c), "s420To444: input clip must be 420")
  bic    = default(bic, false)
  UV = bic ? Interleave(c.ExtractU(), c.ExtractV()).BicubicResize(c.width, c.height, src_left=0.25) : \
Interleave(c.ExtractU(), c.ExtractV()).BilinearResize(c.width, c.height, src_left=0.25)
  YToUV(UV.SelectEven(), UV.SelectOdd(), c)
}
