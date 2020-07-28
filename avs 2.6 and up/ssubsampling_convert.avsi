# custom interlaced YV12<->YV16 functions for avs 2.6
# 1.1

function YV16ToYV12i(clip c, bool "bic", bool "desample") {
Assert(IsYV16(c), "YV16ToYV12i: input clip must be YV16")
  bic    = default(bic, false)
  desample = default(desample, false)
  sourcford = c.getparity() ? 1 : 0
  f = c.SeparateFields()
  top = sourcford == 1 ? f.SelectEven() : f.SelectOdd()
  bot = sourcford == 1 ? f.SelectOdd() : f.SelectEven()
  resizer = desample ? bic ? "DeBicubicResizeMT" : "DeBilinearResizeMT" : bic ? "BicubicResize" : "BilinearResize"
  topUV = eval("Interleave(top.UToY8(), top.VToY8())."+resizer+"(c.width/2, c.height/4, src_top=desample ? 0.25 : -0.25)")
  botUV = eval("Interleave(bot.UToY8(), bot.VToY8())."+resizer+"(c.width/2, c.height/4, src_top=desample ? -0.25 : 0.25)")
  U = sourcford == 1 ? Interleave(topUV.SelectEven(), botUV.SelectEven()) : Interleave(botUV.SelectEven(), topUV.SelectEven())
  V = sourcford == 1 ? Interleave(topUV.SelectOdd(), botUV.SelectOdd()) : Interleave(botUV.SelectOdd(), topUV.SelectOdd())
  YToUV(U, V, f).Weave()
}


function YV12ToYV16i(clip c, bool "bic") {
Assert(Isyv12(c), "YV12ToYV16i: input clip must be yv12")
  bic    = default(bic, false)
  sourcford = c.getparity() ? 1 : 0
  f = c.SeparateFields()
  top = sourcford == 1 ? f.SelectEven() : f.SelectOdd()
  bot = sourcford == 1 ? f.SelectOdd() : f.SelectEven()
  topUV = bic ? Interleave(top.UToY8(), top.VToY8()).BicubicResize(c.width/2, c.height/2, src_top=0.125) : \
Interleave(top.UToY8(), top.VToY8()).BilinearResize(c.width/2, c.height/2, src_top=0.125) 
  botUV = bic ? Interleave(bot.UToY8(), bot.VToY8()).BicubicResize(c.width/2, c.height/2, src_top=-0.125) : \
Interleave(bot.UToY8(), bot.VToY8()).BilinearResize(c.width/2, c.height/2, src_top=-0.125)
  U = sourcford == 1 ? Interleave(topUV.SelectEven(), botUV.SelectEven()) : Interleave(botUV.SelectEven(), topUV.SelectEven())
  V = sourcford == 1 ? Interleave(topUV.SelectOdd(), botUV.SelectOdd()) : Interleave(botUV.SelectOdd(), topUV.SelectOdd())
  YToUV(U, V, f).Weave()
}

