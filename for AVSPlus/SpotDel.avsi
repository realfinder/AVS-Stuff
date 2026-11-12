#
# https://forum.doom9.org/showthread.php?t=182831&page=7
# Fonction SpotDel
/*
SpotDel (Spotless+Delta Restore) 1.0, mod 1.32 in 2026 to add FastMA parameter

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

# neo-mv port: motion estimation and compensation use neo_mv_* functions.
# Original SpotDel sections, comments and helper-function order are retained;
# SpotLess_Mod_Neo is appended after the original SpotLess107 implementation.

function SpotDel(clip input, int "RadT", float "dark2Brt", float "dark2BrtLimit", bool "RiskyBlur", bool "Rgr", int "Rgr1", int "Rgr2", \
                 int "Usharp_strength", int "Usharp_radius", int "Usharp_th", bool "Sharpen_it", bool "Slog", int "Pel", bool "Chroma", \
                 int "BlkSz", int "Olap", Int "SchParam", bool "Tm", int "DCT", int "SpotTH", float "Bblur", int "txt_sz", \
                 bool "ReturnRestored", bool "ReturnStacked", bool "FastMA", int "LessAggressive")
{
    # VARIABLES
    # Here, define what you want
    ReturnRestored   = default(ReturnRestored, True)       # True to returned the filterd clip, false to return comparaison
    ReturnStacked    = default(ReturnStacked, True)        # If false return interleaved

    txt_sz           = default(txt_sz, 36)                 # Test size if infos displayed
    Sharpen_it       = default(Sharpen_it, True)           # Default True. Sharpen clip or not (recomanded, see intro)
    Slog             = default(Slog, False)                # Default False. If True, Generate a leveled clip for washed-out or Slog rushes. Final result will not be changed levelwise

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
    ThSAD            = default(SpotTH, 10000)              # [SAD, Sum of Absolute (pixelwise) Differences] Default 10000=NEARLY OFF(ie ignore hardly any bad blocks), 0 < ThSAD < 16320(8*8*255). 8x8 block SAD threshold at radius 1 (ie at current_frame +- 1)
    RadT             = default(RadT, 1)                    # Removes spots on up to RadT [Temporal Radius] consecutive frames. RadT > 2 will usually be overkill. Setting too high could possibly result in blurring.
                                                           # Each pixel in result frame is median pixel value of (2*RadT+1) motion compensated frames (including source, ie current_frame-RadT to current_frame+RadT).
    FastMA           = default(FastMA, false)
    LessAggressive   = default(LessAggressive, 0)

    #Delta Restore variables
    dark2Brt         = default(dark2Brt, LessAggressive != 0 ? 1.17 : 0.97)      # Default 0.97. Decrease if too many spots coming back
    dark2BrtLimit    = default(dark2BrtLimit, LessAggressive != 0 ? 1.06 : 0.86) # Default 0.86. Same mask. Try to change it too.
    Global RiskyBlur = default(RiskyBlur, True)                                  # True = use fastblur and risk some glitches. False = Use Gblur and go stable, at the price of a slower script

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
    source1_lvl = Slog ? source1.ConvertBits(8).Autolevels(filterradius=3, sceneChgThresh=20, autogamma=true, midpoint=0.5, autolevel=true, border=500).ConvertBits(bi) : source1

    #Sharpening
    #  -----------------------------------------------------------------------------------
    # Best results found by sharpening before (not after) cleaning.
    source1_shp = Sharpen_it && LessAggressive < 2 ? source1.UnsharpMask_avsi(Usharp_strength, Usharp_radius, Usharp_th) : source1
    source1_lvl_shp = Sharpen_it && LessAggressive < 2 ? source1_lvl.UnsharpMask_avsi(Usharp_strength, Usharp_radius, Usharp_th) : source1_lvl

    #Remove spots, Spotless, version 1.07
    # ------------------------------------------------------------------------------------
    # LessAggressive == 1 uses the independent SpotLess_Mod_Neo path;
    # all other values keep the original SpotLess107 path.
    if (LessAggressive == 1) {
        source1_shp_spt = SpotLess_Mod_Neo(source1_shp, RadT=RadT, ThSAD=ThSAD, ThSAD2=ThSAD, Pel=Pel, Chroma=Chroma, BlkSz=BlkSz, Olap=Olap, Tm=Tm, FastMA=FastMA)
        source1_lvl_shp_spt = Slog ? SpotLess_Mod_Neo(source1_lvl_shp, RadT=RadT, ThSAD=ThSAD, ThSAD2=ThSAD, Pel=Pel, Chroma=Chroma, BlkSz=BlkSz, Olap=Olap, Tm=Tm, FastMA=FastMA) : source1_shp_spt
    }
    else {
        spotLessAgg = LessAggressive > 1 ? LessAggressive-1 : 0
        source1_shp_spt = SpotLess107(source1_shp, BlkSz=BlkSz, Olap=Olap, Pel=Pel, Tm=Tm, Bblur=Bblur, ThSAD=ThSAD, RadT=RadT, Chroma=Chroma, DCT=DCT, SchParam=SchParam, FastMA=FastMA, LessAggressive=spotLessAgg)
        source1_lvl_shp_spt = Slog ? SpotLess107(source1_lvl_shp, BlkSz=BlkSz, Olap=Olap, Pel=Pel, Tm=Tm, Bblur=Bblur, ThSAD=ThSAD, RadT=RadT, Chroma=Chroma, DCT=DCT, SchParam=SchParam, FastMA=FastMA, LessAggressive=spotLessAgg) : source1_shp_spt
    }

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
    luma_mask = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, ">", brightness=1.1, spotSize=3).ExpandMask(3, blur=4)
    chroma_mask = ChromaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, delta=3, spotSize=3)
    # chroma mask - selects where source and filtered chromas have large enough difference (formula: sqrt(u*u + v*v))
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
    expanded = dark.MustBeNear(light, 28, expanded=true)

    # secondary dark mask - doesn't need to be near lighter area but has stricter limits
    dark2 = LumaDeltaMask(source1_lvl_shp, source1_lvl_shp_spt, "<", brightness=dark2Brt, limitBrightness=dark2BrtLimit, limitAbsBrightness=0.12, spotSize=5).ExpandMask(2, blur=2)

    # edge test for dark areas
    darkEdgeMask = edges.mt_binarize(54) # at least 54 needed for frame 222
    darkEdgeAreaMask = mt_hysteresis(darkEdgeMask, dark_near_light.AddTo(dark2), chroma="-128")
    dark_final = DarkDeltaMask(dark_near_light, secondary=dark2, edgeMask=darkEdgeMask)
    combined_mask = luma_mask.AddTo(suppressed_chroma_mask).AddTo(chroma_override)

    # remove mask areas where sharp edges were found (those are most likely dirt)
    edgeAreaMask = mt_hysteresis(edgeMask, combined_mask, chroma="-128")

    #~ Apply masks with unleveled clips
    ####----------------------------------------------------------------------------------------------------------------
    delta_restore = DeltaRestore(source1_shp_spt, source1_shp, luma=luma_mask, chroma=suppressed_chroma_mask, chromaOverride=chroma_override, edges=edgeMask, dark=dark_final)
    ####----------------------------------------------------------------------------------------------------------------

    # Restore grain - cancels sharpen
    #------------------------------------------------------------------------------------
    delta_restore = Rgr ? mRD_RestoreGrain(delta_restore, source1, val1, val2) : delta_restore

    if (ReturnRestored) {
        return delta_restore
    }

    edgeAreaMask = mt_logic(edgeAreaMask, darkEdgeAreaMask, "or")

    # create mask visualization (for debugging) -----------------------------------------
    black = BlankClip(source1)
    yellow = BlankClip(source1, color=$d1cc2e)
    green = BlankClip(source1, color=$40f75b)
    gray = BlankClip(source1, color=$d0d0d0)
    darkgray = BlankClip(source1, color=$909090)
    orange = BlankClip(source1, color=$a36b02)
    purple = BlankClip(source1, color=$4e0091)
    purple_light = BlankClip(source1, color=$bc6eff)
    purple_dark = BlankClip(source1, color=$340061)
    red = BlankClip(source1, color=$9e2424)
    blue = BlankClip(source1, color=$0d3b7a)

    maskviz = Overlay(black, purple, mask=expanded)
    maskviz = Overlay(maskviz, purple_dark, mask=dark)
    maskviz = Overlay(maskviz, purple_light, mask=light)
    maskviz = Overlay(maskviz, black, mask=dark_near_light)

    # reset masks
    maskviz = black
    suppression_mask = black
    chroma_override = black
    edgeAreaMask = black

    # only show dark mask?
    showDarkMaskOnly = false
    if (!showDarkMaskOnly) {
        maskviz = Overlay(maskviz, yellow, mask=chroma_mask)
        maskviz = Overlay(maskviz, red, mask=suppression_mask, opacity=0.7)
        maskviz = Overlay(maskviz, green, mask=chroma_override)
        maskviz = Overlay(maskviz, gray, mask=luma_mask)
        maskviz = Overlay(maskviz, blue, mask=edgeAreaMask, opacity=0.8)
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
        sub(maskviz, "masks used", txt_sz), \
        sub(diff, "diff", txt_sz))
    return stack
}

function interleaver(clip src, clip filtered, clip delta_restore, clip comp, clip maskviz, clip diff, int "txt_sz")
{
    inter = Interleave(\
        sub(src, "source", txt_sz), \
        sub(filtered, "Spotless", txt_sz), \
        sub(delta_restore, "Delta Restore", txt_sz), \
        sub(comp, "restore + mask", txt_sz), \
        sub(maskviz, "masks used", txt_sz), \
        sub(diff, "diff", txt_sz))
    return inter
}

function sub(clip c, string label, int txt_sz)
{
    y = Round(txt_sz/2) + 10
    return Subtitle(c, label, size=txt_sz, align=8).ShowFrameNumber(scroll=true, x=10, y=y, size=txt_sz)
}

function DeltaRestore(clip filtered, clip source, clip "luma", clip "chroma", clip "chromaOverride", clip "edges", clip "dark") {
    Assert(luma.Defined || chroma.Defined || chromaOverride.Defined || dark.Defined, "DeltaRestore:must define at least one of luma, chroma, chromaOverride, dark")
    mask = Default(luma, BlankClip(filtered))
    if (chroma.Defined) { mask = mask.AddTo(chroma) }
    if (chromaOverride.Defined) { mask = mask.AddTo(chromaOverride) }
    if (edges.Defined) { mask = mask.MustNotOverlap(edges) }
    if (dark.Defined) { mask = mask.AddTo(dark) }
    return Overlay(filtered, source, mask=mask)
}

# Combine dark masks and remove edge areas.
function DarkDeltaMask(clip mask, clip "secondary", clip "edgeMask")
{
    if (secondary.Defined) { mask = mask.AddTo(secondary) }
    if (edgeMask.Defined) { mask = mask.MustNotOverlap(edgeMask) }
    return mask
}

# Merge two masks.
function AddTo(clip mask, clip other)
{
    return mt_logic(mask, other, "or")
}

# Remove areas selected by a suppression mask.
function SuppressWith(clip mask, clip suppressionMask)
{
    return mt_lutxy(mask, suppressionMask, expr="x y -")
}

# Keep mask areas that do not overlap the other mask.
function MustNotOverlap(clip mask, clip other)
{
    other = mt_hysteresis(other, mask, chroma="-128")
    return mt_lutxy(mask, other, expr="x y -")
}

function DeltaMaskChroma(clip src, clip filtered, int threshold, int "spotSize", int "expand", float "blur")
{
    spotSize = Default(spotSize, 3)
    expand = Default(expand, 0)
    blur = Default(blur, 0)
    chroma_mask = ChromaDeltaMask(src, filtered, delta=threshold, spotSize=spotSize)
    chroma_mask = ExpandMask(chroma_mask, expand, blur=blur)
    return chroma_mask
}

function MustOverlap(clip mask, clip otherMask)
{
    return mt_logic(mask, mt_hysteresis(otherMask, mask), "and")
}

function storeClip(clip c, clip stored, string name)
{
    return propSetClip(c, name, function[stored](clip c) { return stored })
}

function restoreClip(clip c, string name)
{
    return ScriptClip(c, function[name]() { return propGetClip(name) })
}

# Keep mask areas that are close to another mask.
function MustBeNear(clip mask, clip otherMask, int maxDistance, bool "expanded")
{
    expanded = Default(expanded, false)
    expand_amount = maxDistance / 2
    mask_expanded = ExpandMask(mask, expand_amount)
    other_expanded = ExpandMask(otherMask, maxDistance - expand_amount)
    common = mt_logic(mask_expanded, other_expanded, "or")
    if (expanded) { return common }
    other_near = mt_hysteresis(otherMask, common)
    final = mt_logic(mask, other_near, "and")
    return final
}

# Add padding around the frame for edge calculations.
function ZPadding(clip c, int left, int top, int right, int bottom)
{
    return c.Crop(left, top, -right, -bottom).AddBorders(left, top, right, bottom, color_yuv=$008080)
}

# Scharr edge detector.
function Scharr(clip c)
{
    scharr_x = c.mt_edge("3 0 -3 10 0 -10 3 0 -3", thY1=0, thY2=255, y=3, u=1, v=1)
    scharr_y = c.mt_edge("3 10 3 0 0 0 -3 -10 -3", thY1=0, thY2=255, y=3, u=1, v=1)
    scharr = mt_lutxy(scharr_x, scharr_y, yexpr=mt_polish("((x*x)+(y*y))^0.5"), chroma="-128")
    return scharr
}

function RemoveSmallSpots(clip mask, int spotSize)
{
    # remove too small spots
    mask_orig = mask
    for (i=1, spotSize) {
        mask = mask.mt_inpand()
    }
    mask = mt_hysteresis(mask, mask_orig, chroma="-128")
    return mask
}

function LumaDeltaMask(clip source, clip filtered, string direction, float "brightness", float "limitBrightness", float "limitAbsBrightness", int "spotSize")
{
    # direction is ">" if you want mask to contain areas where source is brighter than filtered by "brightness", direction "<" selects where source is darker
    # adjust brightness to change how bright objects are selected, typical values between 1.0 and 1.1, larger value = brighter object
    # remove too bright or dark areas using limitBrightness
    # spotSize controls the smallest spot size allowed in the mask, typical values between 0 and 3
    brightness = Default(brightness, 0.9)
    spotSize = Default(spotSize, 2)
    limitBrightness = Default(limitBrightness, brightness)
    limitAbsBrightness = Default(limitAbsBrightness, 0.0)

    diff = Grayscale(mt_makediff(source, filtered))
    mask = mt_lut(diff, expr="x range_half " + String(brightness) + " * " + direction + " 255 scalef 0 ?")
    mask_orig = mask

    if (limitBrightness != brightness) {
        mask_suppression = mt_lut(diff, expr="x range_half " + String(limitBrightness) + " * " + direction + " 255 scalef 0 ?")
        mask = mt_lutxy(mask, mask_suppression, expr="x y -")
    }
    if (limitAbsBrightness > 0.0) {
        mask = mt_lutxy(mask, source, expr="y range_max " + String(limitAbsBrightness) + " * < 0 x ?")
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

function ChromaDeltaMask(clip source, clip filtered, int "delta", int "spotSize")
{
    # adjust delta to change how different colors are selected
    # spotSize controls the smallest spot size allowed in the mask, typical values between 0 and 3
    delta = Default(delta, 3)
    spotSize = Default(spotSize, 2)
    # diff
    diff = mt_makediff(source, filtered, y=3, u=3, v=3)

    # extract chroma channels
    u = ExtractU(diff)
    v = ExtractV(diff)
    u_delta = mt_lut(u, expr="x range_half - abs")
    v_delta = mt_lut(v, expr="x range_half - abs")
    # calculate deltas
    uv_delta = mt_lutxy(u_delta, v_delta, expr="x x * y y * + 0.5 ^")

    if (uv_delta.width < source.width || uv_delta.height < source.height) {
        uv_delta = uv_delta.BilinearResize(source.width, source.height)
    }
    # create mask
    mask = uv_delta.mt_binarize(delta)
    mask = RemoveSmallSpots(mask, spotSize)

    # restore original format
    blank = BlankClip(source)
    mask = CombinePlanes(mask, blank, blank, planes="YUV", source_planes="YUV", sample_clip=source)
    return mask
}

function ExpandMask(clip mask, int amount, float "blur")
{
    blur = Default(blur, 0)
    for (i=1, amount) {
        mask = mask.mt_expand(chroma="-128")
    }
    if (blur > 0) { mask = mask.GBlur(rad=6, sd=blur, u=true) }
    return mask
}


# Remove spots, Spotless, version 1.07
# ------------------------------------------------------------------------------------
# neo-mv implementation of the original SpotLess107 motion-compensation path.
Function SpotLess107(clip c, int "RadT", int "ThSAD", int "ThSAD2", int "pel", bool "chroma", int "BlkSz", int "Olap", int "SchParam", bool "tm", int "DCT", bool "glob", float "bBlur", clip "dc", bool "FastMA", int "LessAggressive")
{
    myName = "SpotLess107: "
    RadT = Default(RadT, 1)          # Temporal radius. (MCompensate arg)
    ThSAD = Default(ThSAD, 10000)    # SAD threshold at radius 1 (Default Nearly OFF).
    ThSAD2 = Default(ThSAD2, ThSAD)  # SAD threshold at radius RadT.
    Pel = Default(pel, 2)            # Default 2. 1, 2, or 4. Maybe set 1 for HD+.
    Chroma = Default(chroma, true)   # Use chroma in block matching.
    BlkSz = Default(BlkSz, 8)        # MAnalyse BlkSize. Bigger blocks may be quicker/better for HD clips.
    OLap = Default(OLap, BlkSz/2)    # Default half of BlkSz.
    SchParam = Default(SchParam, OLap/2)
    Tm = Default(tm, true)           # TrueMotion; some users prefer truemotion=false.
    DCT = Default(DCT, 0)
    Glob = Default(glob, true)       # Allow global motion independently of TrueMotion.
    bBlur = Default(bBlur, 0.6)      # Blur analysis source for better motion analysis; ignored when dc is supplied.
    HasDC = dc.Defined
    FastMA = Default(FastMA, false)  # Analyse at 8-bit; render/compensate at source bit depth.
    LessAggressive = Default(LessAggressive, 0)

    Assert(1 <= RadT, myName + "1 <= RadT")
    Assert(0.0 <= bBlur && bBlur <= 1.58, myName + "0.0 <= bBlur <= 1.58")
    Assert(Pel == 1 || Pel == 2 || Pel == 4, myName + "Pel must be 1, 2 or 4")
    Assert(0 <= DCT && DCT <= 10, myName + "DCT must be between 0 and 10")

    pad = Max(BlkSz, 8)
    analysis_src = HasDC ? dc : (bBlur > 0.0 ? c.Blur(bBlur) : c)
    analysis_src = FastMA ? analysis_src.ConvertBits(8) : analysis_src

    # neo_mv_Super requires explicit block size and overlap.
    sup = neo_mv_Super(analysis_src, blksize=BlkSz, overlap=OLap, pad=pad, pel=Pel, sharp=2)
    sup_rend = (HasDC || bBlur > 0.0 || FastMA) ? neo_mv_Super(c, blksize=BlkSz, overlap=OLap, pad=pad, pel=Pel, sharp=2, onelevel=true) : sup

    # MVTools truemotion has no direct neo-mv equivalent. Keep its intent as a
    # compatible approximation through the predictor and pyramid penalties.
    mvlambda = Tm ? 1000 : 0
    plevel = Tm ? 1 : 0
    pnew = Tm ? 25 : 0
    pzero = pnew

    # Translate MVTools DCT selector to the neo-mv metric API.
    metric = "sad"
    metricWeight = 0.5
    metricThreshold = 0.03125
    localMetric = false
    if (DCT == 1) {
        metric = "dct"
    }
    else if (DCT == 2) {
        metric = "sad_dct_global"
    }
    else if (DCT == 3) {
        metric = "sad_dct_local"
        localMetric = true
        metricWeight = 0.5
        metricThreshold = 0.03125
    }
    else if (DCT == 4) {
        metric = "sad_dct_local"
        localMetric = true
        metricWeight = 0.75
        metricThreshold = 0.03125
    }
    else if (DCT == 5) {
        metric = "satd"
    }
    else if (DCT == 6) {
        metric = "sad_satd_global"
    }
    else if (DCT == 7) {
        metric = "sad_satd_local"
        localMetric = true
        metricWeight = 0.5
        metricThreshold = 0.03125
    }
    else if (DCT == 8) {
        metric = "sad_satd_local"
        localMetric = true
        metricWeight = 0.75
        metricThreshold = 0.03125
    }
    else if (DCT == 9) {
        metric = "sad_satd_global_half"
    }
    else if (DCT == 10) {
        metric = "sad_satd_local"
        localMetric = true
        metricWeight = 0.25
        metricThreshold = 0.0625
    }

    # The original Pinterf MVTools MAnalyse default is search=4 (Hexagon); neo-mv equivalent is search=2.
    analysisExpr = "neo_mv_AnalyseMany(sup, blksize=BlkSz, overlap=OLap, radius=RadT, search=2, searchparam=SchParam, chroma=Chroma, globalmv=Glob, mvlambda=" + String(mvlambda) + ", plevel=" + String(plevel) + ", pnew=" + String(pnew) + ", pzero=" + String(pzero) + ", metric=" + Chr(34) + metric + Chr(34)
    if (localMetric) { analysisExpr = analysisExpr + ", metric_weight=" + String(metricWeight) + ", metric_threshold=" + String(metricThreshold) }
    analysisExpr = analysisExpr + ")"
    MultiVec = Eval(analysisExpr)

    # Recreate MVTools MCompensate(tr=RadT, center=true): frame order is
    # +RadT ... +1, source, -1 ... -RadT. AnalyseMany returns
    # [+1, -1, +2, -2, ...], so each reference is compensated separately.
    compExpr = "Interleave("
    for (i=RadT-1, 0, -1) {
        distance = i + 1
        th = RadT == 1 ? ThSAD : Round(ThSAD + (ThSAD2-ThSAD) * (distance-1.0) / (RadT-1))
        compExpr = compExpr + "neo_mv_Compensate(c, sup_rend, MultiVec[" + String(i*2) + "], thsad=" + String(th) + "),"
    }
    compExpr = compExpr + "c,"
    for (i=0, RadT-1) {
        distance = i + 1
        th = RadT == 1 ? ThSAD : Round(ThSAD + (ThSAD2-ThSAD) * (distance-1.0) / (RadT-1))
        compExpr = compExpr + "neo_mv_Compensate(c, sup_rend, MultiVec[" + String(i*2+1) + "], thsad=" + String(th) + "),"
    }
    compExpr = LeftStr(compExpr, StrLen(compExpr)-1) + ")"
    mcomp = Eval(compExpr)

    # LessAggressive mask: port MVTools MMask(kind=1, ml=44) to neo-mv SADMask.
    # neo-mv converts ml to 1/ml internally, so keep ml=44 (do NOT pass 1/44).
    # SADMask returns GRAY, therefore luma=true applies that mask to Y/U/V.
    # This is an approximation: MVTools can emit independent Y/U/V mask planes.
    if (LessAggressive > 0) {
        cmoma = mt_logic(neo_mv_SADMask(MultiVec[0], ml=44), neo_mv_SADMask(MultiVec[1], ml=44), "min")
        # Set the implicit 'last' clip before querying its frame rate, as in the
        # original SpotLess107 expression chain.
        mcomp
        mcompFPS = FrameRate()
        cmoma = cmoma.ChangeFPS(mcompFPS)
        # SADMask may be 8-bit when FastMA analyses an 8-bit proxy, while
        # mcomp and the original clip remain at the source bit depth (e.g. 16-bit).
        # mt_merge requires matching component depths, so promote only the mask
        # to the source depth. Keep mask values full-range during this conversion.
        if (cmoma.BitsPerComponent() != mcomp.BitsPerComponent()) {
            cmoma = cmoma.ConvertBits(mcomp.BitsPerComponent(), fulls=true, fulld=true)
        }
        mcomp = mt_merge(mcomp, c.ChangeFPS(mcompFPS), cmoma, luma=true)
    }

    # The median window covers the 2*RadT+1 interleaved compensated frames.
    cleaned = mcomp.MedianBlurTemporal(radiusY=0, radiusU=0, radiusV=0, temporalradius=RadT)
    cleaned = cleaned.SelectEvery(RadT*2+1, RadT)

    # Repair syntax: Repair requires (processed_clip, reference_clip, mode).
    if (LessAggressive > 0) {
        cleaned = LessAggressive < 2 ? RestoreMotionBlocks(cleaned, Repair(cleaned, c, mode=1).Merge(cleaned), c) : RestoreMotionBlocks(cleaned, Repair(cleaned, c, mode=1), c)
    }
    return cleaned
}


# -----------------------------------------------------------------------------
# SpotLess_Mod_Neo: independent neo-mv port of the supplied SpotLess_Mod code.
# FastMA converts only the analysis source to 8-bit; output/render clips remain
# at the original bit depth. MVTools search=5 means UMH; neo-mv has no UMH mode,
# so search=3 (cross/sparse + hex refinement) is the nearest available pattern.
# MVTools dct=7 maps to neo-mv metric="sad_satd_local", weight=.5, threshold=.03125.
# -----------------------------------------------------------------------------

Function SpotLess_Mod_Neo(clip c, bool "DeGrain", int "RadT", int "ThSAD", int "ThSAD2", int "Pel", bool "Chroma", \
                          int "BlkSz", int "Olap", bool "Tm", bool "Glob", string "Denoiser", bool "FastMA")
{
    myName = "SpotLess_Mod_Neo: "
    DeGrain = Default(DeGrain, false)
    RadT = Default(RadT, 1)
    ThSAD = Default(ThSAD, 10000)
    ThSAD2 = Default(ThSAD2, ThSAD)
    Pel = Default(Pel, 1)
    Chroma = Default(Chroma, true)
    BlkSz = Default(BlkSz, 8)
    Olap = Default(Olap, BlkSz/2)
    Tm = Default(Tm, true)
    Glob = Default(Glob, true)
    Denoiser = Default(Denoiser, Undefined)
    FastMA = Default(FastMA, false)

    Assert(RadT >= 1, myName + "RadT must be >= 1")
    Assert(Pel == 1 || Pel == 2 || Pel == 4, myName + "Pel must be 1, 2 or 4")
    Assert(BlkSz >= 4, myName + "BlkSz must be >= 4")
    Assert(Olap >= 0 && Olap <= BlkSz/2, myName + "Olap must be between 0 and BlkSz/2")

    pad = Max(BlkSz, 8)

    # Original SpotLess_Mod analyses a preconditioned clip but compensates the
    # original pixels. FastMA mirrors SpotLess107's fast-analysis option.
    analysis_src = SpotLess_Pre_Clip_Neo(c, blur=1.0, contrast=0, brightness=0)
    analysis_src = FastMA ? analysis_src.ConvertBits(8) : analysis_src
    sup = neo_mv_Super(analysis_src, blksize=BlkSz, overlap=Olap, pad=pad, pel=Pel, sharp=2)
    sup_rend = neo_mv_Super(c, blksize=BlkSz, overlap=Olap, pad=pad, pel=Pel, sharp=2, onelevel=true)

    # DCT=7 in MVTools is adaptive SAD/SATD (local); neo-mv's documented map.
    # TrueMotion's MVTools lambda scales with block area; plevel=0 is explicit
    # in the supplied function. UMH search=5 has no direct neo-mv equivalent.
    metric = "sad_satd_local"
    metricWeight = 0.5
    metricThreshold = 0.03125
    mvlambda = Tm ? Round(1000.0 * BlkSz * BlkSz / 64.0) : 0
    lsad = Tm ? 1200 : 400
    pnew = Tm ? 50 : 0
    pzero = pnew

    vecExpr = "neo_mv_AnalyseMany(sup, blksize=BlkSz, overlap=Olap, radius=RadT, search=3, searchparam=2, chroma=Chroma, globalmv=Glob, mvlambda=" + String(mvlambda) + ", lsad=" + String(lsad) + ", plevel=0, pnew=" + String(pnew) + ", pzero=" + String(pzero) + ", badrange=24, trymany=1, metric=" + Chr(34) + metric + Chr(34) + ", metric_weight=" + String(metricWeight) + ", metric_threshold=" + String(metricThreshold) + ")"
    MultiVec = Eval(vecExpr)

    # Build the same temporal order used by MVTools MCompensate(center=true):
    # +RadT ... +1, center, -1 ... -RadT. AnalyseMany returns [+1,-1,...].
    compExpr = "Interleave("
    for (i=RadT-1, 0, -1) {
        distance = i + 1
        th = RadT == 1 ? ThSAD : Round(ThSAD + (ThSAD2-ThSAD) * (distance-1.0) / (RadT-1))
        compExpr = compExpr + "neo_mv_Compensate(c, sup_rend, MultiVec[" + String(i*2) + "], thsad=" + String(th) + "),"
    }
    compExpr = compExpr + "c,"
    for (i=0, RadT-1) {
        distance = i + 1
        th = RadT == 1 ? ThSAD : Round(ThSAD + (ThSAD2-ThSAD) * (distance-1.0) / (RadT-1))
        compExpr = compExpr + "neo_mv_Compensate(c, sup_rend, MultiVec[" + String(i*2+1) + "], thsad=" + String(th) + "),"
    }
    compExpr = LeftStr(compExpr, StrLen(compExpr)-1) + ")"
    c0 = Eval(compExpr)

    c0 = RadT == 1 ? Clense(c0) : MedianBlurTemporal(c0, radiusY=0, radiusU=0, radiusV=0, temporalradius=RadT)
    c0 = SelectEvery(c0, RadT*2+1, RadT)
    c1 = SpotLess_Restore_Objects_Neo(c, c0, threshold_dark=30, threshold_light=30, Y=3, U=2, V=2)

    clensed = Clense(c, cache=4)
    restore = Repair(clensed, c, mode=1)
    c3 = RestoreMotionBlocks(clensed, restore, neighbour=c, alternative=restore, gmthreshold=70, dist=1, dmode=2, noise=10, noisy=12, grey=false, debug=false, show=false)

    mask_c3 = mt_lutxy(c0, c3, expr="x y - abs", Y=3, U=2, V=2, scale_inputs="allf", use_expr=2).mt_binarize(threshold=7)
    mask_c3 = mask_c3.mt_inpand().mt_expand().mt_expand().mt_expand().Blur(1.58)
    clear = mt_merge(c1, c, mask_c3, Y=3, U=2, V=2)

    # Optional denoiser/degrain stage. AnalyseMany returns [+1,-1], so Flow's
    # previous-frame vector is member 1 and the next-frame vector is member 0.
    if (Defined(Denoiser) || DeGrain) {
        analysis_clear = FastMA ? clear.ConvertBits(8) : clear
        sup2 = neo_mv_Super(analysis_clear, blksize=BlkSz, overlap=Olap, pad=pad, pel=Pel, sharp=2)
        sup_rend2 = neo_mv_Super(clear, blksize=BlkSz, overlap=Olap, pad=pad, pel=Pel, sharp=2)
        vec2Expr = "neo_mv_AnalyseMany(sup2, blksize=BlkSz, overlap=Olap, radius=1, search=3, searchparam=2, chroma=Chroma, globalmv=Glob, mvlambda=" + String(mvlambda) + ", lsad=" + String(lsad) + ", plevel=0, pnew=" + String(pnew) + ", pzero=" + String(pzero) + ", badrange=24, trymany=1, metric=" + Chr(34) + metric + Chr(34) + ", metric_weight=" + String(metricWeight) + ", metric_threshold=" + String(metricThreshold) + ")"
        vec2 = Eval(vec2Expr)
        bvec1 = vec2[1]
        fvec1 = vec2[0]
        backw1 = neo_mv_Flow(clear, sup_rend2, bvec1)
        forw1 = neo_mv_Flow(clear, sup_rend2, fvec1)
        DN = Defined(Denoiser) ? Interleave(backw1, clear, forw1).Eval(Denoiser).SelectEvery(3, 1) : clear
        return DeGrain ? neo_mv_Degrain1(DN, sup_rend2, [bvec1, fvec1], planes=[0,1,2], limit=255.0, thsad=400) : DN
    }

    return clear
}

# Private helper corresponding to the supplied Pre_Clip function.
Function SpotLess_Pre_Clip_Neo(clip clp, float "blur", float "contrast", float "brightness")
{
    blur = Default(blur, 1.0)
    contrast = Default(contrast, 1.2)
    brightness = Default(brightness, 10.0)

    v = clp.mt_lut(expr="x 20 1 x 127.5 / - 21 ^ pi x * 255 / cos 21 ^ - * 1.05 * -", Y=3, U=2, V=2, scale_inputs="allf", use_expr=2)
    mask_1 = clp.Tweak(sat=0).Blur(blur).mt_edge(mode="min/max", thY1=0, thY2=255, Y=3, U=2, V=2)
    pre_1 = v.Tweak(cont=contrast, bright=brightness)
    pre_2 = mt_merge(v, pre_1, mask_1, Y=3, U=2, V=2)
    pre_3 = pre_2.Tweak(sat=0).mt_invert().Blur(1.58).Blur(1.58).Blur(1.58)
    pre_4 = mt_lutxy(pre_2, pre_3, expr="x 127.5 > y 255 x - 127.5 / * x 255 x - - + y x 127.5 / * ?", scale_inputs="allf", use_expr=2)
    return pre_4
}

Function SpotLess_RemoveDust_Neo(clip input, int "mode")
{
    mode = Default(mode, 17)
    clensed = Clense(input)
    rep = Repair(clensed, input, mode=mode)
    return RemoveGrain(rep, mode=10)
}

Function SpotLess_Restore_Objects_Neo(clip source, clip filtered, float "threshold_dark", float "threshold_light", int "Y", int "U", int "V")
{
    dark = String(Default(threshold_dark, 20.0))
    light = String(Default(threshold_light, 20.0))
    Y = Default(Y, 3)
    U = Default(U, 2)
    V = Default(V, 2)

    m1 = mt_lut(source.ColorYUV(autogain=true), expr="x " + dark + " > x 255 " + light + " - < 0 255 ? 255 ?", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_expand().mt_expand().mt_expand(chroma="-128")
    m2 = mt_lutxy(source, filtered, expr="x y * 255 /", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_binarize(threshold=128, chroma="-128")
    mask_1 = mt_logic(m1, m2, "max").mt_expand().mt_expand(chroma="-128").Blur(1.58)

    r = mt_merge(SpotLess_RemoveDust_Neo(source), filtered, mask_1, Y=Y, U=U, V=V)
    m3 = mt_lutxy(source, r, expr="x y - abs", Y=Y, U=U, V=V, scale_inputs="allf", use_expr=2).mt_binarize(threshold=5).mt_inpand(chroma="-128", thY=128, thC=128)
    m4 = m3.mt_inpand().mt_inpand(chroma="-128")
    mask_2 = mt_logic(m3, m4, "xor").Blur(1.58)
    return mt_merge(Repair(filtered, r, 17), SpotLess_RemoveDust_Neo(filtered), mask_2, Y=Y, U=U, V=V)
}
