function ssync(clip c, clip ref, float "thr", int "cache")
{
c
thr = default(thr, 2.0)
cache = default(cache, 10)
global ssprev = 0
global ssnow = 0
global ssnext = 0
gScriptClip("""
ssprev = ssnow
ssnow = ssnext
ssnext = LumaDifference(last,ref,1)
ssnow > thr ? ssnext > thr ? ssprev > thr ? last : Trim(0,-1)+Trim(0,framecount-2) : Loop(2,0,0)+Trim(framecount-1,0) : last
            """, args="ref, thr", local=false)
cache<0 ? last : last.RequestLinear(8, cache, 5, false, false)
}