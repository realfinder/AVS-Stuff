# based on ChubbyRain2
Function ChubbyRain3(clip c, int "th", int "radius", bool "show", int "sft", bool "interlaced")
{

sisavs26 = !(VersionNumber() < 2.60)
sisphbd = AvsPlusVersionNumber > 2294

    interlaced = default(interlaced, false)
    th = default(th,10)
    radius = default(radius,10)
    show = default(show,false)
    sft = default (sft, 10)
    f = interlaced ? GetParity(c) : nop()
    
    c = interlaced ? c.TDeint(1,tryWeave=true) : c
    u = sisphbd ? ExtractU(c) : sisavs26 ? Utoy8(c) : Utoy(c)
    v = sisphbd ? ExtractV(c) : sisavs26 ? Vtoy8(c) : Vtoy(c)
    uc = mt_convolution(u, horizontal="1",vertical="1 -2 1")
    vc = mt_convolution(v, horizontal="1",vertical="1 -2 1")
    cc = sisavs26 ? mt_convolution(c, horizontal="1",vertical="1 2 1",Y=2,U=3,V=3).bifrost(interlaced=false).vsCnr2().temporalsoften(radius,0,sft,2,2) : 
                  \ mt_convolution(c, horizontal="1",vertical="1 2 1",Y=2,U=3,V=3).bifrost(interlaced=false).Cnr2().temporalsoften(radius,0,sft,2,2)
    
    rainbow = mt_lutxy(uc, vc, "x y + "+string(th)+" scalef > range_max 0 ?", use_expr=1).Blur(1.58)
    
    YToUV(mt_merge(u, sisphbd ? ExtractU(cc) : sisavs26 ? Utoy8(cc) : Utoy(cc), rainbow),mt_merge(v, sisphbd ? ExtractV(cc) : sisavs26 ? Vtoy8(cc) : Vtoy(cc), rainbow),c)
    show ? rainbow.pointresize(c.width,c.height) : last
    
    return (interlaced) ? f ? AssumeBFF().DoubleWeave().SelectEvery(4,1) : AssumeTFF().DoubleWeave().SelectEvery(4,1) : last
}
