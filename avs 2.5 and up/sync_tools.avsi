# v1.24
function ssync(clip c, clip ref, float "thr", bool "debug", bool "nolimit", bool "MoreFrames")
{
c
thr = default(thr, 7.0)
debug = default(debug, false)
nolimit = default(nolimit, false)
MoreFrames = default(MoreFrames, false)
MoreFrames = nolimit ? MoreFrames : false
gScriptClip("""
p2shift=MoreFrames ? DeleteFrame(1).DeleteFrame(0)+Trim(framecount-2,framecount-1) : nop()
pshift=DeleteFrame(0)+Trim(framecount-1,framecount-1)
mshift=Loop(2,0,0).DeleteFrame(framecount-1)
m2shift=MoreFrames ? Loop(3,0,0).DeleteFrame(framecount-1).DeleteFrame(framecount-2) : nop()

ssprev2 = MoreFrames ? LumaDifference(m2shift,ref) : nop()
ssprev = LumaDifference(mshift,ref)
ssnow = LumaDifference(last,ref)
ssnext = LumaDifference(pshift,ref)
ssnext2 = MoreFrames ? LumaDifference(p2shift,ref) : nop()

p2shift=debug && MoreFrames ? p2shift.Subtitle("p2shift",size=40,align=5) : p2shift
pshift=debug ? pshift.Subtitle("pshift",size=40,align=5) : pshift
mshift=debug ? mshift.Subtitle("mshift",size=40,align=5) : mshift
m2shift=debug && MoreFrames ? m2shift.Subtitle("m2shift",size=40,align=5) : m2shift
debug ? Subtitle("noshift",size=40,align=5) : last

smallest = nolimit ? MoreFrames ? min(ssnext2,ssnext,ssnow,ssprev,ssprev2) : min(ssnext,ssnow,ssprev) : nop()

nolimit ? MoreFrames ? ssnext == smallest ? pshift : ssprev == smallest ? mshift : ssnext2 == smallest ? p2shift : ssprev2 == smallest ? m2shift : last
                   \ : ssnext == smallest ? pshift : ssprev == smallest ? mshift : last
      \ : last
!nolimit && ssnow > thr ? ssnext > thr ? ssprev > thr ? last : mshift : pshift : last
debug ? MoreFrames ? Subtitle("-2Diff="+string(ssprev2)+" "+"-1Diff="+string(ssprev)+" "+"0Diff="+string(ssnow)+" "+"+1Diff="+string(ssnext)+" "+"+2Diff="+string(ssnext2))
                 \ : Subtitle("PreviousDiff="+string(ssprev)+" "+"CurrentDiff="+string(ssnow)+" "+"NextDiff="+string(ssnext)) : last
            """, args="ref, thr, debug, nolimit, MoreFrames", local=false)
}