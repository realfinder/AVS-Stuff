# AutoBorderFiller – V1.03
# based on SmartCrop.avsi
# will fill any black Border per-frame, should work with YUV 8-16 bits
# it kill any aplha channel, and always add new alpha channel for the detected Borders
function AutoBorderFiller(clip c, \
                   int "threshold", \
                   int "T", int "B", int "L", int "R", \
                   int "scan_v", int "scan_h") {
    thr     = Default(threshold, 24)
    mT      = Default(T, 0)
    mB      = Default(B, 0)
    mL      = Default(L, 0)
    mR      = Default(R, 0)
    sv      = Default(scan_v, 10)
    sh      = Default(scan_h, 6)
        ABFiller_Core(c, thr, mT, mB, mL, mR, sv, sh)
}

function BFinder_TopM(clip c, int thr, int sd, int mg, clip rgbc, bool mod2) {
    w = c.Width()
    n = current_frame
    b = 0
    s = false
    for (y = 0, sd - 1, 1) {
        a = s ? 255.0 : ((RT_RgbChanAve(rgbc, n=n, x=0, y=y, w=w, h=1)+16) + RT_YPlaneMax(c, n=n, x=0, y=y, w=w, h=1)) / 2
        s = s ? true : (a > thr)
        b = s ? b : y + 1
    }
    b = (b > 0) ? b + mg : 0
    return mod2 ? b + (b % 2) : b
}

function BFinder_BotM(clip c, int thr, int sd, int mg, clip rgbc, bool mod2) {
    w = c.Width()
    h = c.Height()
    n = current_frame
    b = 0
    s = false
    for (dy = 0, sd - 1, 1) {
        y = h - 1 - dy
        a = s ? 255.0 : ((RT_RgbChanAve(rgbc, n=n, x=0, y=y, w=w, h=1)+16) + RT_YPlaneMax(c, n=n, x=0, y=y, w=w, h=1)) / 2
        s = s ? true : (a > thr)
        b = s ? b : dy + 1
    }
    b = (b > 0) ? b + mg : 0
    return mod2 ? b + (b % 2) : b
}

function BFinder_LeftM(clip c, int thr, int sd, int mg, int top, int bot, clip rgbc, bool mod2) {
    h = c.Height()
    cy = top
    ch = Max(1, h - top - bot)
    n = current_frame
    b = 0
    s = false
    for (x = 0, sd - 1, 1) {
        a = s ? 255.0 : ((RT_RgbChanAve(rgbc, n=n, x=x, y=cy, w=1, h=ch)+16) + RT_YPlaneMax(c, n=n, x=x, y=cy, w=1, h=ch)) / 2
        s = s ? true : (a > thr)
        b = s ? b : x + 1
    }
    b = (b > 0) ? b + mg : 0
    return mod2 ? b + (b % 2) : b
}

function BFinder_RightM(clip c, int thr, int sd, int mg, int top, int bot, clip rgbc, bool mod2) {
    w = c.Width()
    h = c.Height()
    cy = top
    ch = Max(1, h - top - bot)
    n = current_frame
    b = 0
    s = false
    for (dx = 0, sd - 1, 1) {
        x = w - 1 - dx
        a = s ? 255.0 : ((RT_RgbChanAve(rgbc, n=n, x=x, y=cy, w=1, h=ch)+16) + RT_YPlaneMax(c, n=n, x=x, y=cy, w=1, h=ch)) / 2
        s = s ? true : (a > thr)
        b = s ? b : dx + 1
    }
    b = (b > 0) ? b + mg : 0
    return mod2 ? b + (b % 2) : b
}

function ABFiller_Core(clip base, \
                    int thr, int mT, int mB, int mL, int mR, \
                    int sv, int sh) {

    rgbc=base.converttorgb24()
    mod2 = !(isy(base) || is444(base))
    c8bit = base.convertbits(8)
    ScriptClip(base.AddAlphaPlane(0), function [thr, mT, mB, mL, mR, sv, sh, rgbc, c8bit, mod2] () {
        top = c8bit.BFinder_TopM(thr, sv, mT, rgbc, mod2)
        bot = c8bit.BFinder_BotM(thr, sv, mB, rgbc, mod2)
        lft = c8bit.BFinder_LeftM(thr, sh, mL, top, bot, rgbc, mod2)
        rgt = c8bit.BFinder_RightM(thr, sh, mR, top, bot, rgbc, mod2)
        AlphaBm=ExtractA().Letterbox(top, bot, x1=lft, x2=rgt, color_yuv =color_white)
        RemoveAlphaPlane().crop(lft,top,-rgt,-bot,align=true).ContinuityFixer(lft==0?0:3,top==0?0:3,rgt==0?0:3,bot==0?0:3,3)
        ConvertBits(32).bore_SinglePlane(lft==0?0:6,rgt==0?0:6,top==0?0:5,bot==0?0:5,plane=4).bore_SinglePlane(lft==0?0:6,rgt==0?0:6,top==0?0:5,bot==0?0:5,plane=1).bore_SinglePlane(lft==0?0:6,rgt==0?0:6,top==0?0:5,bot==0?0:5,plane=2).Convertbits(BitsPerComponent())
        sh_Padding(lft,top,rgt,bot,1).FillBorders(lft==0?0:1+lft,top=top==0?0:1+top,right=rgt==0?0:1+rgt,bottom=bot==0?0:1+bot,mode=6,u=2,v=2).FillBorders(lft==0?0:2+lft,top=top==0?0:2+top,right=rgt==0?0:2+rgt,bottom=bot==0?0:2+bot,mode=6,y=2).AddAlphaPlane(AlphaBm)
        mt_merge(last,TemporalSoften(3, 255, 255, 10, 2),mt_inflate(AlphaBm),luma=true)
    })
}