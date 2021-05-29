Function mRD_RestoreGrain (clip rd, clip o, float "str1", float "str2") {
sisavs26   = !(VersionNumber() < 2.60)

str1 = string(default(str1, 10.0))
str2 = string(default(str2, 20.0))

expr = sisavs26 ? " x range_half - abs "+str1+" scalef min "+str2+" scalef x range_half - abs - min 0 max x range_half - x range_half - abs 1 max / * range_half + " : " x 128 - abs "+str1+" min "+str2+" x 128 - abs - min 0 max x 128 - x 128 - abs 1 max / * 128 + "

Return sisavs26 ? mt_makediff(o, rd).mt_lut(expr, use_expr=2).mt_adddiff(rd, chroma="copy second") : mt_makediff(o, rd).mt_lut(expr).mt_adddiff(rd, chroma="copy second")
}