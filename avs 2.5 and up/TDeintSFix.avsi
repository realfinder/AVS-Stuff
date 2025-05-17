function TDeintSFix(clip clip, int "mode", int "order", int "field", int "mthreshL", int "mthreshC", int "map", string "ovr", int "ovrDefault", int "type", bool "debug", int "mtnmode", bool "sharp", bool "hints", Clip "clip2", bool "full", int "cthresh", bool "chroma", int "MI", bool "tryWeave", int "link", bool "denoise", int "AP", int "blockx", int "blocky", int "APType", Clip "edeint", Clip "emask", float "blim", int "metric", int "expand", int "slow", Clip "emtn", bool "tshints", int "opt")
{
istff=GetParity(clip)
mode  = Default(mode, 0)
edeint1=Defined(edeint) && mode==1 ? edeint.SelectEven() : edeint
edeint2=Defined(edeint) && mode==1 ? edeint.SelectOdd () : edeint
emask1=Defined(emask) && mode==1 ? emask.SelectEven() : emask
emask2=Defined(emask) && mode==1 ? emask.SelectOdd () : emask

mode<1 ? TDeint(clip, mode, order, field, mthreshL, mthreshC, map, ovr, ovrDefault, type, debug, mtnmode, sharp, hints, clip2, full, cthresh, chroma, MI, tryWeave, link, denoise, AP, blockx, blocky, APType, edeint, emask, blim, metric, expand, slow, emtn, tshints, opt) :
            \ Interleave(TDeint(clip, 0, order, istff?1:0, mthreshL, mthreshC, map, ovr, ovrDefault, type, debug, mtnmode, sharp, hints, clip2, full, cthresh, chroma, MI, tryWeave, link, denoise, AP, blockx, blocky, APType, edeint1, emask1, blim, metric, expand, slow, emtn, tshints, opt),
                              \TDeint(clip, 0, order, istff?0:1, mthreshL, mthreshC, map, ovr, ovrDefault, type, debug, mtnmode, sharp, hints, clip2, full, cthresh, chroma, MI, tryWeave, link, denoise, AP, blockx, blocky, APType, edeint2, emask2, blim, metric, expand, slow, emtn, tshints, opt))
 }