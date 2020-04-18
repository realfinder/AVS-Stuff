# EdgeCleaner() v1.041 (18/04/2020)
# - a simple edge cleaning and weak dehaloing function
#
# Description:
# Functions have been briefly tested to work with MT on mode 1 and 2 without any problems
#
# Requirements:
# aWarpSharp (SEt's updated version), mt_masktools, Repair (optional), RemoveGrain (optional) and Deen (optional) plugins required
# YV12 input required and mod16 or even mod32 input is preferred since aWarpSharp borks sometimes
#
# Parameters:
# strength (float)      - specifies edge denoising strength (10)
# rep (boolean)         - actives Repair for the aWarpSharped clip (true; requires Repair)
# rmode (integer)       - specifies the Repair mode; 1 is very mild and good for halos, 
#                         16 and 18 are good for edge structure preserval on strong settings but keep more halos and edge noise, 
#                         17 is similar to 16 but keeps much less haloing, other modes are not recommended (17; requires Repair)
# smode (integer)       - specifies what method will be used for finding small particles, ie stars; 0 is disabled, 
#                         1 uses RemoveGrain and 2 uses Deen (0; requires RemoveGrain/Repair/Deen)
# hot (boolean)         - specifies whether removal of hot pixels should take place (false)


function EdgeCleaner(clip c, int "strength", bool "rep", int "rmode", int "smode", bool "hot") {
sisavs26 = !(VersionNumber() < 2.60)

    strength    = default(strength, 10)
    rep         = default(rep, true)
    rmode       = default(rmode, 17)
    smode       = default(smode, 0)
    hot         = default(hot, false)

    c           = sisavs26 ? c : (c.isYV12()) ? c : c.ConvertToYV12()
    strength    = (smode==0) ? strength : strength+4

    main	= c.aWarpSharp2(depth=Round(strength/2),blur=1) 
    main        = (rep) ? Repair(main,c,rmode) : main

    mask        = c.mt_edge("prewitt",4,32,4,32).mt_invert().mt_convolution()

    final       = (!hot) ? mt_merge(c,main,mask) : Repair(mt_merge(c,main,mask),c,2)
    final       = (smode != 0) ? mt_merge(final,c,c.EdgeCleaner_StarMask(smode)) : final

    return final

}

function EdgeCleaner_StarMask(clip c, int "mode") {
sisavs26 = !(VersionNumber() < 2.60)

    mode        = default(mode, 1)

    clean       = (mode==1) ? c.RemoveGrain(17) : Repair(sisavs26 ? c.sminideen(4,12,0) : c.Deen("a3d",4,12,0),c,15).RemoveGrain(21)
    diff        = (mode==1) ? mt_makediff(c,clean) : NOP
    
    final       = (mode==1) ? sisavs26 ? diff.Greyscale().mt_lut("x 40 scalef - 168 scalef 40 scalef - / 1 0.350 / ^ range_max 0 - * 0 +", use_expr=2).removegrain(7,-1).mt_edge("prewitt",4,16,4,16) : diff.Greyscale().Levels(40,0.350,168,0,255).removegrain(7,-1).mt_edge("prewitt",4,16,4,16) : \
                  Subtract(mt_merge(clean,c,c.mt_edge("roberts",0,2,0,2).mt_expand(mode=mt_circle(1)).mt_invert()),c).mt_edge("roberts",0,0,0,0).mt_deflate()
    
    return final

}

# Changelog:
#   03/04/2012  v1.041
#	- removed converttoyv12 in avs 2.6
#	- HBD in avs+
#   03/04/2012  v1.04
#	- adapted the code to work with SEt's updated aWarpSharp
#	- removed the redundant fix parametre
#	- increased default strength to 10
#   06/08/2008  v1.03
#       - improved mask that leaves less warping and more original line structure, therefore higher strengths are now safe to use
#       - improved StarMask()
#       - removed super mode
#       - removed srep, sshiqloc, some smodes and VD_SmartSmoothHiQ() due to StarMask() changes
#   01/06/2008  v1.02
#       - added srep parameter
#       - improved particle masking
#   01/06/2008  v1.01
#       - added masking for particles with two parameters; smode and sshiqloc
#   12/05/2008  v1.00
#       - removed line darkening, mode 2 mask, RemoveGrain
#       - assert changed to colorspace conversion to yv12
#       - fixed some logic problems
#       - "fixed" the aWarpSharp black pixel bug
#       - added Repair