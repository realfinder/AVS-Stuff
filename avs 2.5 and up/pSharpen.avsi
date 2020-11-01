# HBD mod
# 2020.10.31
function pSharpen   (clip clp,
                    \float "strength", float "threshold",
                    \float "ss_x", float "ss_y",
                    \int "dest_x", int "dest_y")
{
sisavs26= !(VersionNumber() < 2.60)
    # getting the input image size
    ox = clp.width()
    oy = clp.height()

    # parsing the input values
    strength = default(strength, 25)
    threshold = default(threshold, 75)
    ss_x = default(ss_x, 1.0)
    ss_y = default(ss_y, 1.0)
    dest_x = default(dest_x, ox)
    dest_y = default(dest_y, oy)

    strength = strength<0 ? 0 : strength>100 ? 100 : strength
    threshold = threshold<0 ? 0 : threshold>100 ? 100 : threshold
    ss_x = ss_x<1.0 ? 1.0 : ss_x
    ss_y = ss_y<1.0 ? 1.0 : ss_y

    # oversampling
    valp =   ss_x!=1.0 || ss_y!=1.0 ?
            \clp.lanczosresize(round(ox*ss_x/8)*8,round(oy*ss_y/8)*8) :
            \clp

    # calculating the max and min in every 3*3 square
    maxp = valp.mt_expand()
    minp = valp.mt_inpand()

    # normalizing max and val to values from 0 to (max-min)
    nmax = average(maxp, 1, minp, -1)
    nval = average(valp, 1, minp, -1)

    # initializing the strings used to obtain the output luma value
    s = string(strength/100.0)
    t = string(threshold/100.0)
    x0 = string((threshold/100.0)*(1.0-strength/100.0)/(1.0-(1.0-threshold/100.0)*(1.0-strength/100.0)))
    expr = \
        "x y / 2 * 1 - abs "+x0+" < "                   +\
            s+" 1 = "                                   +\
                "x y 2 / = 0 y 2 / ? "                  +\
                "x y / 2 * 1 - abs 1 "+s+" - / "        +\
            "? "                                        +\
            "x y / 2 * 1 - abs 1 "+t+" - * "+t+" + "    +\
        "? "                                            +\
        "x y 2 / > 1 -1 ? * 1 + y * 2 /"

    # calculates the new luma value pushing it towards min or max
    nval = sisavs26 ? mt_lutxy(nval, nmax, expr, scale_inputs="allf", use_expr=1) : mt_lutxy(nval, nmax, expr)

    # normalizing val to values from min to max
    valp = average(nval, 1, minp, 1)

    # applying the new luma value to the original clip &
    # resizing the image to the output values
    valp = valp.lanczosresize(dest_x, dest_y)
    clp = clp.lanczosresize(dest_x, dest_y).mergeluma(valp)

    return clp
}