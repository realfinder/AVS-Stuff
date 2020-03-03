# 2020.01.31
function BalanceBorders(clip c, int cTop, int cBottom, int cLeft, int cRight, int "thresh", int "blur")
{
    sisavs26     = !(VersionNumber() < 2.6)
    sisphbd = AvsPlusVersionNumber > 2294
 
    sislumaonly  = sisphbd ? c.isy() : sisavs26 ? c.isy8() : false
    
    sisfullchrom = sisphbd ? c.is444() : sisavs26 ? c.isyv24() : false
    
    sis420chr    = sisphbd ? c.is420() : c.isyv12()
    
    Assert(sis420chr || sisfullchrom || sislumaonly, "This is not a Square chroma clip.")

    thresh = Default(thresh, 128)
    blur   = Default(blur,   999)

    Assert(blur   > 0, "Blur parameter in BalanceBorders() must be > 0")
    Assert(thresh > 0, "Thresh parameter in BalanceBorders() must be > 0")

    c
    cTop    >0 ? BalanceTopBorder(cTop,    thresh, blur, sislumaonly, sis420chr, sisavs26).sTryFTurnRight() : last.sTryFTurnRight()
    cLeft   >0 ? BalanceTopBorder(cLeft,   thresh, blur, sislumaonly, sis420chr, sisavs26).sTryFTurnRight() : last.sTryFTurnRight()
    cBottom >0 ? BalanceTopBorder(cBottom, thresh, blur, sislumaonly, sis420chr, sisavs26).sTryFTurnRight() : last.sTryFTurnRight()
    cRight  >0 ? BalanceTopBorder(cRight,  thresh, blur, sislumaonly, sis420chr, sisavs26).sTryFTurnRight() : last.sTryFTurnRight()
}

function BalanceTopBorder(clip c, int cTop, int "thresh", int "blur", bool "sislumaonly", bool "sis420chr", bool "sisavs26")
{
    cWidth = c.width
    cHeight = c.height
    cTop = min(cTop,cHeight-1)
	cTop2 = max(sis420chr ? 4 : 2,cTop)
    blurWidth = max(4,floor(cWidth/blur))

    c2 = c.PointResize(cWidth*2,cHeight*2)

    c2.\
    Crop(0,cTop*2,cWidth*2,2)
    PointResize(cWidth*2,cTop2*2)
    BilinearResize(blurWidth*2,cTop2*2)
    mt_convolution("1 1 1","0 1 0",y=3,u=sislumaonly ? 1 : 3,v=sislumaonly ? 1 : 3)
	PointResize(blurWidth*2,cTop*2)
    BilinearResize(cWidth*2,cTop*2)
    referenceBlur = last

    original = c2.Crop(0,0,cWidth*2,cTop*2)

    original
	PointResize(Width(),cTop2*2)
    BilinearResize(blurWidth*2,cTop2*2)
    mt_convolution("1 1 1","0 1 0",y=3,u=sislumaonly ? 1 : 3,v=sislumaonly ? 1 : 3)
	PointResize(blurWidth*2,cTop*2)
    BilinearResize(cWidth*2,cTop*2)
    originalBlur = last

    balanced = sisavs26 ? mt_lutXYZ(original,originalBlur,referenceBlur,"z y - x +",use_expr=3,y=3,u=3,v=3) : mt_lutXYZ(original,originalBlur,referenceBlur,"z y - x +",y=3,u=3,v=3)
    difference = mt_makeDiff(balanced,original,y=3,u=3,v=3)

    tp = string(128+thresh)
    tm = string(128-thresh)
    difference = sisavs26 ? difference.mt_lut("x "+tp+" scalef > "+tp+" scalef x ?",Use_expr=2,y=3,u=3,v=3) : difference.mt_lut("x "+tp+" > "+tp+" x ?",y=3,u=3,v=3)
    difference = sisavs26 ? difference.mt_lut("x "+tm+" scalef < "+tm+" scalef x ?",Use_expr=2,y=3,u=3,v=3) : difference.mt_lut("x "+tm+" < "+tm+" x ?",y=3,u=3,v=3)

    mt_addDiff(original,difference,y=3,u=3,v=3)

    StackVertical(last,c2.Crop(0,cTop*2,cWidth*2,(cHeight-cTop)*2)).PointResize(cWidth,cHeight)
}