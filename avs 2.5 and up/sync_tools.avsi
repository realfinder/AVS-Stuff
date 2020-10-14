# v1.22
function ssync(clip c, clip ref, float "thr", bool "debug", bool "nolimit")
{
c
thr = default(thr, 7.0)
debug = default(debug, false)
nolimit = default(nolimit, false)
gScriptClip("""
pshift=DeleteFrame(0)+Trim(framecount-1,framecount-1)
mshift=Loop(2,0,0).DeleteFrame(framecount-1)
ssprev = LumaDifference(mshift,ref)
ssnow = LumaDifference(last,ref)
ssnext = LumaDifference(pshift,ref)
smallest = nolimit ? min(ssnext,ssnow,ssprev) : nop()
nolimit ? ssnext == smallest ? pshift : ssprev == smallest ? mshift : last : last
!nolimit && ssnow > thr ? ssnext > thr ? ssprev > thr ? last : mshift : pshift : last
debug ? Subtitle("CurrentDiff="+string(ssnow)+" "+"NextDiff="+string(ssnext)+" "+"PreviousDiff="+string(ssprev)) : last
            """, args="ref, thr, debug, nolimit", local=false)
}