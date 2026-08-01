# 
# https://forum.doom9.org/showthread.php?t=182831&page=7
# Fonction SpotDel
/*
SpotDel (Spotless+Delta Restore) 1.0, mod 1.3 in 2026 to add FastHBD parameter

Example

SpotDel(dark2Brt=0.9, dark2BrtLimit=0.85, SpotTH=10000, Rgr=True, Rgr1=5, Rgr2=10, RiskyBlur= False, TM=False, BlkSz=16)


 Script intended to clean and sharpen digitalized film.
 Can optionally restore grain after cleaning.
 Sharpening and denoising are basic. Please see doom9 forum, VideoFred's and JohnMeyer's scripts and posts fore more knowlege. (VideoFred's sharp-blur-sharp-blur-sharp trick). Please share improvements!

 Functions: Spotless:StainlessS, Delta Restore:Zorr, Restore Grain:real.finder. Huge Thanks !
 Script: chmars - 17/06/2021 - some parts copied here and there, thank to solutions given by doom9 forum users.
 Thread: https://forum.doom9.org/showthread.php?t=182831
 Spotless thread, last versions: https://forum.doom9.org/showthread.php?t=181777
 Lots of informaions on film capture/restoration: https://forum.doom9.org/showthread.php?t=144271
 

Script tested on HD 4:2:2 10bits sources with Avisynth+370_x64
            !                   !                  !                   !                  !
-You should maybe adapt the sizes parameters (blksz, radiuses, spotsizes) if your source is not HD


 How it works:
 Spotless removes dirt spots that are not present in neibourg frames.
 But sometimes, fast moving objects are removed too (balloons, birds, hands, feet) 
 Hence is Delta Restore needed. It brings back details that are part of the image.
As Spotless tends to soften/degrain the image, parts brought back from the original image by Delta Restore are more grainy.
 The solution for a discreete replacement (and nicer result) of these parts is to sharpen the Spotless input.
 
 Washed out, Slog rushes:
 Spotless seems to work as well with washed out images (old footage, Slog rushes), but Delta Restore needs colors and contrast to funtion properly. 
 In this case, a more contrasted clip can be made to feed Delta Restore and only generate masks. However, the final result will not be graded.

*/

function SpotDel(clip input, int "RadT", float "dark2Brt", float "dark2BrtLimit", bool "RiskyBlur", bool "Rgr", int "Rgr1", int "Rgr2", \
                  int "Usharp_strength", int "Usharp_radius", int "Usharp_th", bool "Sharpen_it", bool "Slog", int "Pel", bool "Chroma", \
                  int "BlkSz", int "Olap", Int "SchParam", bool "Tm", int "DCT", int "SpotTH", float "Bblur", int "txt_sz",              \
                  bool "ReturnRestored", bool "ReturnStacked", bool "FastHBD", int "LessAggressive"                                      \  
                  )
{
    # VARIABLES 
    # Here, define what you want
    
    ReturnRestored   = default(ReturnRestored, True)       # True to returned the filterd clip, false to return comparaison
    ReturnStacked    = default(ReturnStacked, True)        # If false return interleaved
    
    txt_sz           = default(txt_sz, 36)                 # Test size if infos displayed
    Sharpen_it       = default(Sharpen_it, True)           # Default True. Sharpen clip or not (recomanded, see intro)
    Slog             = default(Slog, False)                # Default False. If True, Generate a leveled clip f or wahed-out or Slog rushes. Final result will not be changed levelwise

    #Grainitude, cancels sharpen effect
    Rgr              = default(Rgr, False)                 # Default false. True Restores grain after passed through Spotless. Might restore some dust too. 5,10 = good compromise grain/dirt.
    val1             = default(Rgr1, 10)                                   
    val2             = default(Rgr2, 20)                   # 5,10 = good compromise grain/dirt. Dunno how that works exactly...

    # Sharpen variables ----------------------------------------------------------------------------------------------------------------------------------------------------------
    Usharp_strength  = default(Usharp_strength, 80)        # Bigger = sharper & more grain
    Usharp_radius    = default(Usharp_radius, 5)
    Usharp_th        = default(Usharp_th, 1)                       

    # Spotless variables, to remove dirt and spots. -------------------------------------------------------------------------------------------------------------------------
    # See Function script for more advanced settings
    Chroma           = default(Chroma, True)
    BlkSz            = default(BlkSz, 32)                  # Spot Size, Default 8. MAnalyse BlkSize. Bigger blksz quicker and perhaps better for HD clips. [Info: current Pinterf MvTools allows for BlkSize=12, and overlap=6]
    Olap             = default(Olap, BlkSz/2)
    SchParam         = default(SchParam, Olap/2)
    Pel              = default(Pel, 1)                     # Default 2. 1, 2, or 4. Maybe set 1 for HD+. (1=precision to pixel, 2=half pixel, 4=quarter pixel)
    Tm               = default(Tm, False)                  # TrueMotion Default True. Some folk swear truemotion=false is better.
    DCT              = Default(DCT, 0)
    Bblur            = default(Bblur, 0.6)                 # Default 0.6. If used, Suggest about 0.6, where MAnalyse create vectors is performed on denoised (blurred) super clip for better motion analysis. 
    ThSAD            = default(SpotTH, 10000)              # [SAD, Sum of Absolute (pixelwise) Differences]  Default 10000=NEARLY OFF(ie ignore hardly any bad blocks), 0 < ThSAD < 16320(8*8*255). 8x8 block SAD threshold at radius 1 (ie at current_frame +- 1)
    RadT             = default(RadT, 1)                    # Removes Spots on up to RadT [Temporal Radius] consecutive frames. RadT > 2 will usually be overkill. Setting too high could possibly result in blurring.
                                                           # Each pixel in result frame is median pixel value of (2*RadT+1) motion compensated frames (including source, ie current_frame-RadT to current_frame+RadT).
    FastHB           = default(FastHBD, false)
    LessAggressive   = default(LessAggressive, 0)

    #Delta Restore variables
    dark2Brt         = default(dark2Brt, LessAggressive != 0 ? 1.17 : 0.97)      # Default 0.97. Decrease if too many spots coming back 
    dark2BrtLimit    = default(dark2BrtLimit, LessAggressive != 0 ? 1.06 : 0.86) # Default 0.86. Same mask. Try to change it too.
    Global RiskyBlur = default(RiskyBlur, True)                                  # True = use fastblur and risk some glitches.    False = Use Gblur and go stable, at the price of a  slower script
    
    bi               = BitsPerComponent(input)
    source1          = input
    # / END OF VARIABLES 
    
    # Leveled clip
    ## -------------------------------------------------------------------------------------------------------------------------------------------------------------
    #In case of washed-out footage or Slog captures
    # Needed to generate dark and saturated enough clips, to feed the filters whith what they need. 
    # Will NOT apply to final result. Only for mask building
    # If Slog = True, make a decently contrasted clip to feed the filters.
    # Else, do nothing, source1_lvl will be identical to  source1

    source1_lvl =  Slog ? source1.convertbits(8).Autolevels(filterradius = 3, sceneChgThresh = 20, autogamma = true, midpoint = 0.5, autolevel = true, border=500).convertbits(bi) : source1
    #~ lvl_src =  Slog ? source1.convertbits(8).Autolevels(filterradius = 3, sceneChgThresh = 20, autogamma = true, midpoint = 0.5, autolevel = true, border=500, input_high = 230 ).convertbits(bi) : source1
    #~ lvl_src =  Slog ? ColorYUV(source1, autogain = true) : source1
    
    #Sharpening
    #  -----------------------------------------------------------------------------------
    # Best results found by sharpening before (not after) cleaning.
    source1_shp = Sharpen_it && LessAggressive < 2 ? source1.UnsharpMask_avsi(Usharp_strength,Usharp_radius,Usharp_th) : source1
    # If Using Slog rushes, also sharpen the leveled clip
    source1_lvl_shp = Sharpen_it && LessAggressive < 2 ? source1_lvl.UnsharpMask_avsi(Usharp_strength,Usharp_radius,Usharp_th) : source1_lvl    
    
    #Remove spots, Spotless, version 1.07
    # ------------------------------------------------------------------------------------
    source1_shp_spt = LessAggressive == 1 ? SpotLess_Mod(source1_shp,blksz=BlkSz,OLap=Olap,pel=pel,Tm=Tm,thsad=thsad,RadT=RadT,chroma=Chroma, FastHBD=FastHB) : SpotLess107(source1_shp,blksz=BlkSz,OLap=Olap,pel=pel,Tm=Tm,Bblur=Bblur,thsad=thsad,RadT=RadT,chroma=Chroma, DCT=DCT, SchParam=SchParam, FastHBD=FastHB, LessAggressive=LessAggressive != 0)
    source1_lvl_shp_spt = Slog ? LessAggressive == 1 ? SpotLess_Mod(source1_lvl_shp,blksz=BlkSz,OLap=Olap,pel=pel,Tm=Tm,thsad=thsad,RadT=RadT,chroma=Chroma, FastHBD=FastHB) : SpotLess107(source1_lvl_shp,blksz=BlkSz,OLap=Olap,pel=pel,Tm=Tm,Bblur=Bblur,thsad=thsad,RadT=RadT,chroma=Chroma, DCT=DCT, SchParam=SchParam, FastHBD=FastHB, LessAggressive=LessAggressive != 0) : source1_shp_spt

    source1_shp_spt = Sharpen_it && LessAggressive > 1 ? FineDehalo_contrasharp(source1_shp_spt,source1,1,true) : source1_shp_spt
    source1_lvl_shp_spt = Sharpen_it && LessAggressive > 1 && Slog ? FineDehalo_contrasharp(source1_shp_spt,source1,1,true) : source1_lvl_shp_spt

    # Delta Restore -------------------------------------------------------------

    # diff with exaggerated chroma difference
    diff1 = mt_makediff(source1_lvl_shp, source1_lvl_shp_spt, y=3, u=3, v=3)
    diff2 = diff1.mt_adddiff(diff1, y=0, u=3, v=3)
    diff2 = diff2.mt_adddiff(diff1, y=0, u=3, v=3)
    diff = CombinePlanes(diff1, diff2, diff2, planes="YUV", source_planes="YUV", sample_clip=diff1)

    #Calculate masks with leveled clips
    ####----------------------------------------------------------------------------------------------------------------
    # prepare masks --------------------------------------------------------------------

    # luma mask - selects where source brightness > filtered brightness 

    # luma mask - selects where source brightness > filtered brightness 
    luma_mask = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, ">", brightness=1.1, spotSize=3).ExpandMask(3, blur=4)

    # chroma mask - selects where source and filtered chromas have large enough difference (formula: sqrt(u*u + v*v))
    chroma_mask = ChromaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, delta=3, spotSize=3)

    # suppression mask - selects where source brightness < filtered brightness
    # suppression mask removes too dark areas from chroma mask 
    suppression_mask = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, "<", brightness=0.9, spotSize=2)
    suppressed_chroma_mask = chroma_mask.SuppressWith(suppression_mask)

    # edge mask - detects sharp edges
    # don't detect edges near the frame edges
    edges = scharr(source1_lvl_shp).ZPadding(60, 14, 14, 10)
    edgeMask = edges.mt_binarize(52) 

    # chroma override mask - selects larger color deltas and spot sizes than plain chroma mask and is not suppressed
    chroma_override = ChromaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, delta=5, spotSize=6).ExpandMask(3, blur=2)

    # dark mask: select both darker and lighter mask and keep dark mask if it is near lighter mask or overlaps chroma override mask
    dark = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, "<", brightness=0.97, limitBrightness=0.66, spotSize=5)
    light = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, ">", brightness=1.04, spotSize=5).ZPadding(60, 14, 14, 10)
    dark_near_light = dark.MustBeNear(light, 28).ExpandMask(3, blur=4)
    expanded = dark.MustBeNear(light, 28, expanded=true) # for debugging

    # secondary dark mask - doesn't need to be near lighter area but has stricter limits
    dark2 = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, "<", brightness=dark2Brt, limitBrightness=dark2BrtLimit, limitAbsBrightness=0.12, spotSize=5).ExpandMask(2, blur=2)

    # edge test for dark areas
    darkEdgeMask = edges.mt_binarize(54) # at least 54 needed for frame 222
    darkEdgeAreaMask = mt_hysteresis(darkEdgeMask, dark_near_light.AddTo(dark2), chroma="-128")    # for debug

    dark_final = DarkDeltaMask(dark_near_light, secondary=dark2, edgeMask=darkEdgeMask)


    combined_mask = luma_mask.AddTo(suppressed_chroma_mask).AddTo(chroma_override)

    # remove mask areas where sharp edges were found (those are most likely dirt)
    edgeAreaMask = mt_hysteresis(edgeMask, combined_mask, chroma="-128")    # for debug

    #~ Apply masks with unleveled clips
    ####----------------------------------------------------------------------------------------------------------------
    delta_restore = DeltaRestore(source1_shp_spt, source1_shp, luma=luma_mask, chroma=suppressed_chroma_mask, chromaOverride=chroma_override, edges=edgeMask, dark=dark_final)
    ####----------------------------------------------------------------------------------------------------------------

    # Restore grain - cancels sharpen
    #------------------------------------------------------------------------------------
    delta_restore = Rgr ? mRD_RestoreGrain(delta_restore, source1,val1, val2) : delta_restore #5,10 = good compromise grain/dirt
    
    if (ReturnRestored) {
        return delta_restore
    }
    
    edgeAreaMask = mt_logic(edgeAreaMask, darkEdgeAreaMask, "or")
    #edgeAreaMask = darkEdgeAreaMask

    # create mask visualization (for debugging) -----------------------------------------
    black = BlankClip(source1)
    yellow = BlankClip(source1, color=$d1cc2e) # #d1cc2e    f7f140
    green = BlankClip(source1, color=$40f75b)
    gray = BlankClip(source1, color=$d0d0d0)
    darkgray = BlankClip(source1, color=$909090)
    orange = BlankClip(source1, color=$a36b02)
    purple = BlankClip(source1, color=$4e0091)
    purple_light = BlankClip(source1, color=$bc6eff)
    purple_dark = BlankClip(source1, color=$340061)
    red = BlankClip(source1, color=$9e2424)
    blue = BlankClip(source1, color=$0d3b7a) #24579e 243c9e

    # maskviz for dark mask
    maskviz = Overlay(black, purple, mask=expanded) 
    maskviz = Overlay(maskviz, purple_dark, mask=dark) 
    maskviz = Overlay(maskviz, purple_light, mask=light) 
    maskviz = Overlay(maskviz, black, mask=dark_near_light) 

    # reset masks
    maskviz = black
    #chroma_mask = black
    suppression_mask = black
    chroma_override = black
    edgeAreaMask = black

    # only show dark mask?
    showDarkMaskOnly = false
    if (!showDarkMaskOnly) {
        maskviz = Overlay(maskviz, yellow, mask=chroma_mask)                     # chroma mask - yellow
        maskviz = Overlay(maskviz, red, mask=suppression_mask, opacity=0.7)    # suppression mask - red
        maskviz = Overlay(maskviz, green, mask=chroma_override)                # chroma override - green
        maskviz = Overlay(maskviz, gray, mask=luma_mask)                        # luma mask - gray
        maskviz = Overlay(maskviz, blue, mask=edgeAreaMask, opacity=0.8)         # sharpness mask - blue
    }

    # mask overlay
    comp = Overlay(delta_restore, maskviz, opacity=0.45)
    comp = Overlay(comp, purple_light, mask=light, opacity=0.2)
    comp = Overlay(comp, black, mask=dark, opacity=0.2)
    comp = Overlay(comp, black, mask=dark_final, opacity=0.6)

    maskviz = Overlay(maskviz, black, mask=dark_final, opacity=0.6)

    ReturnStacked ? stacker(source1, source1_shp_spt, delta_restore, comp, maskviz, diff, txt_sz) : interleaver(source1, source1_shp_spt, delta_restore, comp, maskviz, diff, txt_sz)
    
}

function stacker(clip src, clip filtered, clip delta_restore, clip comp, clip maskviz, clip diff, int "txt_sz")
{
    stack = StackHorizontal(\
    sub(src, "source", txt_sz), \
    sub(filtered, "Spotless", txt_sz), \
    sub(delta_restore, "Delta Restore", txt_sz), \
    sub(comp, "restore + mask", txt_sz), \
    sub(maskviz, "masks used", txt_sz),\
    sub(diff, "diff", txt_sz)\
    )
    #sub(edgeMask, "edge mask", txt_sz),\

    # scaling (if needed)
    #stack = stack.BilinearResize(stack.width/2 + 1, stack.height/2)

    return stack
}

function interleaver(clip src, clip filtered, clip delta_restore, clip comp, clip maskviz, clip diff, int "txt_sz")
{
    inter = Interleave(\
    sub(src, "source", txt_sz), \
    sub(filtered, "Spotless", txt_sz), \
    sub(delta_restore, "Delta Restore", txt_sz), \
    sub(comp, "restore + mask", txt_sz), \
    sub(maskviz, "masks used", txt_sz),\
    sub(diff, "diff", txt_sz)\
    )

    return inter    
}

function sub(c, label, txt_sz) {
    y=Round(txt_sz/2)+10
    return subtitle(c, label, size = txt_sz, align=8).ShowFrameNumber(scroll=true, x=10, y=y,size = txt_sz)
}


function DeltaRestore(clip filtered, clip source, clip "luma", clip "chroma", clip "chromaOverride", clip "edges", clip "dark") {
    Assert(luma.Defined || chroma.Defined || chromaOverride.Defined || dark.Defined, "DeltaRestore:must define at least one of luma, chroma, chromaOverride, dark")

    mask = Default(luma, BlankClip(filtered))
    if (chroma.Defined) {
        mask = mask.AddTo(chroma)
    }
    if (chromaOverride.Defined) {
        mask = mask.AddTo(chromaOverride)
    }
    if (edges.Defined) {
        mask = mask.MustNotOverlap(edges)
    }
    if (dark.Defined) {
        mask = mask.AddTo(dark)
    }
    return Overlay(filtered, source, mask=mask)
}

function DarkDeltaMask(clip mask, clip "secondary", clip "edgeMask") {    
    if (secondary.Defined) {
        mask = mask.AddTo(secondary)
    }
    if (edgeMask.Defined) {
        mask = mask.MustNotOverlap(edgeMask)
    }
    return mask
}

function AddTo(clip mask, clip other) {
    return mt_logic(mask, other, "or")
}

function SuppressWith(clip mask, clip suppressionMask) {
    return mt_lutxy(mask, suppressionMask, expr="x y -")
}

function MustNotOverlap(clip mask, clip other) {
    other = mt_hysteresis(other, mask, chroma="-128")
    return mt_lutxy(mask, other, expr="x y -")
}

function DeltaMaskChroma(clip src, clip filtered, int threshold, int "spotSize", int "expand", float "blur") {
    spotSize = Default(spotSize, 3)
    expand = Default(expand, 0)
    blur = Default(blur, 0)

    chroma_mask = ChromaDeltaMask(src, filtered, delta=threshold, spotSize=spotSize)    
    chroma_mask = ExpandMask(chroma_mask, expand, blur=blur)
    return chroma_mask
}

function MustOverlap(clip mask, clip otherMask) {
    return mt_logic(mask, mt_hysteresis(otherMask, mask), "and")
}

function storeClip(clip c, clip stored, string name) {
    return propSetClip(c, name, function[stored](clip c) { return stored } )
}

function restoreClip(clip c, string name) {
    return ScriptClip(c, function[name]() { return propGetClip(name) })
}

function MustBeNear(clip mask, clip otherMask, int maxDistance, bool "expanded") {
    expanded = Default(expanded, false)

    expand_amount = maxDistance / 2
    mask_expanded = ExpandMask(mask, expand_amount)
    other_expanded = ExpandMask(otherMask, maxDistance - expand_amount)
    common = mt_logic(mask_expanded, other_expanded, "or")


    if (expanded) {
        return common
    }
    other_near = mt_hysteresis(otherMask, common)
    final = mt_logic(mask, other_near, "and")    

    return final
}

function ZPadding(clip c, int left, int top, int right, int bottom) {
    return c.Crop(left, top, -right, -bottom).AddBorders(left, top, right, bottom, color_yuv=$008080)
}

function scharr(clip c) {
    scharr_x = c.mt_edge("3 0 -3 10 0 -10 3 0 -3", thY1 = 0, thY2 = 255, y=3, u=1, v=1)
    scharr_y = c.mt_edge("3 10 3 0 0 0 -3 -10 -3", thY1 = 0, thY2 = 255, y=3, u=1, v=1)
    scharr = mt_lutxy(scharr_x, scharr_y, yexpr=mt_polish("((x*x)+(y*y))^0.5"), chroma="-128")
    return scharr
}

function RemoveSmallSpots(clip mask, int spotSize) {
    mask_orig = mask

    # remove too small spots
    for (i = 1, spotSize) {
        mask = mask.mt_inpand()
    }
    mask = mt_hysteresis(mask, mask_orig, chroma="-128") 
    return mask
}

function LumaDeltaMask(clip source, clip filtered, string direction, float "brightness", float "limitBrightness", float "limitAbsBrightness", int "spotSize") {
    # direction is ">" if you want mask to contain areas where source is brighter than filtered by "brightness", direction "<" selects where source is darker
    # adjust brightness to change how bright objects are selected, typical values between 1.0 and 1.1, larger value = brighter object
    # remove too bright or dark areas using limitBrightness
    # spotSize controls the smallest spot size allowed in the mask, typical values between 0 and 3

    brightness = Default(brightness, 0.9)
    spotSize   = Default(spotSize, 2)
    limitBrightness = Default(limitBrightness, brightness)
    limitAbsBrightness = Default(limitAbsBrightness, 0.0)

    # diff 
    diff = Grayscale(mt_makediff(source, filtered))

    # mask 
    mask = mt_lut(diff, expr="x range_half "+String(brightness)+" * " + direction + " 255 scalef 0 ?")
    mask_orig = mask

    # limitBrightness suppression
    if (limitBrightness != brightness) {
        mask_suppression = mt_lut(diff, expr="x range_half "+String(limitBrightness)+" * " + direction + " 255 scalef 0 ?")
        mask = mt_lutxy(mask, mask_suppression, expr="x y -")
    }

    # limitAbsBrightness suppression
    if (limitAbsBrightness > 0.0) {
        mask = mt_lutxy(mask, source, expr="y range_max "+String(limitAbsBrightness)+" * < 0 x ?")
    }

    # remove too small spots
    mask = RemoveSmallSpots(mask, spotSize)

    # limitBrightness or limitAbsBrightness suppression (part 2)
    if (limitBrightness != brightness || limitAbsBrightness > 0.0) {
        # if suppression didn't kill the whole mask then return it without suppression
        mask = mt_hysteresis(mask, mask_orig, chroma="-128")
    }
    
    return mask
}

function ChromaDeltaMask(clip source, clip filtered, int "delta", int "spotSize") {

    # adjust delta to change how different colors are selected
    # spotSize controls the smallest spot size allowed in the mask, typical values between 0 and 3

    delta = Default(delta, 3)
    spotSize   = Default(spotSize, 2)

    # diff 
    diff = mt_makediff(source, filtered, y=3, u=3, v=3)

    # extract chroma channels
    u = ExtractU(diff)
    v = ExtractV(diff)

    # calculate deltas
    u_delta = mt_lut(u, expr="x range_half - abs")
    v_delta = mt_lut(v, expr="x range_half - abs")

    # combine deltas
#    uv_delta = mt_lutxy(u_delta, v_delta, expr="x y +")
    uv_delta = mt_lutxy(u_delta, v_delta, expr="x x * y y * + 0.5 ^")

    # rescale (if needed)
    if (uv_delta.width < source.width || uv_delta.height < source.height) {
        uv_delta = uv_delta.BilinearResize(source.width, source.height)
    }

    # create mask
    mask = uv_delta.mt_binarize(delta)

    # remove too small spots 
    mask = RemoveSmallSpots(mask, spotSize)    

    # restore original format
    blank = BlankClip(source)
    mask = CombinePlanes(mask, blank, blank, planes="YUV", source_planes="YUV", sample_clip=source)

    return mask
}

function ExpandMask(clip mask, int amount, float "blur") {
    blur = Default(blur, 0)

    for (i = 1, amount) {
        mask = mask.mt_expand(chroma="-128")
    }
    if (blur > 0) {
        #mask = mask.FastBlur(blur)
        #mask = mask.binomialBlur(varY=blur)
        mask = mask.GBlur(rad=6, sd=blur, u=true)
    }
    return mask
}


Function SpotLess107(clip c, int "RadT", int "ThSAD", int "ThSAD2", int "pel", bool "chroma", int "BlkSz", Int "Olap", Int "SchParam", bool "tm", int "DCT", Bool "glob", Float "bBlur", clip "dc", bool "FastHBD", bool "LessAggressive" ) {
    myName   = "SpotLess107: "
    RadT     = Default(RadT,1)        # Temporal radius. (MCompensate arg)
    ThSAD    = Default(ThSAD,10000)   # SAD threshold at radius 1 (Default Nearly OFF).
    ThSAD2   = Default(ThSAD2,ThSAD)  # SAD threshold at radius RadT.
    Pel      = Default(pel,2)         # Default 2. 1, 2, or 4. Maybe set 1 for HD+. (1=precision to pixel, 2=precision to half pixel, 4=quarter pixel)
    Chroma   = Default(chroma,True)   # MAnalyse chroma arg. If set to true, use chroma in block matching.
    BlkSz    = Default(BlkSz,8)       # Default 8. MAnalyse BlkSize. Bigger blksz quicker and perhaps  better, esp for HD clips. Maybe also better where BIG noise.
    OLap     = Default(OLap, BlkSz/2) # Default half of BlkSz.
    SchParam = Default(SchParam, OLap/2)
    Tm       = Default(tm,True)       # TrueMotion, Some folk swear MAnalyse(truemotion=false) is better.
    DCT      = Default(DCT,0)
    Glob     = Default(glob,True)     # Default True, Allow set MAnalyse(global) independently of TrueMotion.
    bBlur    = Default(bblur,0.6)     # Default 0.6. Suggest about 0.6 for better motion analysis, but a bit slower.
    HasDC    = dc.Defined             # bblur ignored if HasDC, ie user already provided prefiltered clip.
    FastHB   = default(FastHBD, false)
    LessAggressive   = default(LessAggressive, false)
    
    Assert(1 <= RadT,myName + " 1 <= RadT")
    Assert(0.0 <= bblur <= 1.58, myName + "0.0 <= bblur <= 1.58")
    Assert(pel==1 || pel==2 || pel==4, myName + "pel==1 || pel==2 || pel==4")
    pad = max(BlkSz,8)
    sup = (HasDC ? dc : bBlur>0.0  ? c.blur(bBlur) : c )
    sup = (FastHB ? sup.convertbits(8) : sup ).MSuper(hpad=pad,vpad=pad,pel=pel, sharp=2)
    # Only 1 Level required where not MAnalyse-ing.
    sup_rend = (HasDC||bBlur>0.0) ? c.MSuper(hpad=pad,vpad=pad,pel=pel, sharp=2,Levels=1) : sup
    MultiVec = sup.MAnalyse(multi=true, delta=RadT,blksize=BlkSz,overlap=OLap, searchparam=SchParam, chroma=Chroma,truemotion=Tm,global=Glob, DCT=DCT)
    c.MCompensate(sup_rend, MultiVec, tr=RadT, thSad=ThSAD, thSad2=ThSAD2)
    cmoma=LessAggressive ? mt_logic(MMask(MultiVec.SelectEvery(RadT*2,0),kind=1,ml=44),MMask(MultiVec.SelectEvery(RadT*2,1),kind=1,ml=44),"min",u=3,v=3) : nop()
    LessAggressive ? mt_merge(last,c.ChangeFPS(FrameRate()),cmoma.ChangeFPS(FrameRate()),u=3,v=3) : last
    MedianBlurTemporal(radiusY=0,radiusU=0,radiusV=0,temporalradius=RadT)  # Temporal median blur only [not spatial]
    SelectEvery(RadT*2+1,RadT)                                             # Return middle frame
    LessAggressive ? RestoreMotionBlocks(last,Repair(c,1).Merge(last),c) : last
}