# MCBob v0.3u7: (July 1st, 2020)
# nnedi and nnedibob was made possible by tritical and the fellow Doom9 community who contributed CPU cycles.
# Another approach to motion compensated bobbing, build by Didée.
#
#   ( Between-all-chairs version with some quick hacks )
#   ( v0.3c:  as stated above, but worse ;-) )
#   ( v0.3u:  use new nnedi interpolator by tritical; modded by Terranigma)
#   ( v0.3u2: updated to use the new MVTools2 branch)
#   ( v0.3u3: Fix & Script Cleanup by Terranigma. Also added the "search" parameter and changed the default m.e. algorithm to 2. Thanks to jase99 
#   for providing source clip)
#   ( v0.3u4: Re-Introduced EEDI2 as an interpolator, and also added nnedi and nnedi3 as interpolator options. 
#   Interpolation type is controlled by "EDIType". 1 = EEDI2; 2 = NNEDI; 3 = NNEDI2 (default); 4 = NNEDI3.
#   ( v0.3u5: Cosmetics - Removed redundant options (helper bobbers), and changed "EDIType" to "EDIMode", and made it into a string to simplify the script.
#   Now the behavior is the same as for TempGaussMC, e.g. EDIMode="nnedi3" (default is nnedi3). Also added the new "nns" parameter for the new version of nnedi3.
#   ( v0.3u6: Cosmetics - Wording.
#   ( v0.3u7: HBD and others.
# Features:
#
# - No residual combing, due to STT (Shape Transposition Technology)
# - Works without thresholds (with adaptive thresholds instead of fixed ones)
# - Motion Search between fields of same parity, for maximum flicker/bob reduction in motion areas
# - Motion Masking adaptive to local complexity, for maximum flicker/bob reduction in static areas
# - spatial Interpolation overweights spatio-temporal interpolation
#     ( in areas where the information obtained from temporal neighbors in itself was only spatially 
#       interpolated, use a mix of spatial and spatio-temporal interpolation )
# - error correction for temporal interpolation is fully self adaptive
#
# Prerequisites:
#
# - MVTools, v2.0.9.1 (or newer)
# - MaskTools v2.0
# - EEDI2
# - nnedi2 v1.3+
# - nnedi3 v0.9+
# - RemoveGrain/Repair package
# - ReduceFlicker (if temp-NR for ME is used)
# - MedianBlur

function MCBob(clip clp, float "EdiPre", int "EdiPost", int "blocksize", int "search", int "MEdepth", string "EdiMode", int "nsize", int "nns", int "qual", int "maxd", float "sharpness", int "mtnmode", float "mtnth1", float "mtnth2", float "errth1", float "errth2", float "MEspatNR", float "MEtempNR", int "EdiThreads", int "nnrep", bool "nnedi3pad")
{
sisavs26=!(VersionNumber() < 2.6)
sisphbd = AvsPlusVersionNumber > 2294
    EdiPre    = default( EdiPre,       1.0 )  #  What bob to start with: 0.0 = dumbbob, 1.0 = EdiBob, inbetween = mix of both
    EdiPost   = default( EdiPost,        2 )  #  0 = no EDI PP / 1 = Framesized Edi PP / Average two Fieldbased Edi PP's
    bs        = default( blocksize,     16 )  #  Blocksize for motion search
    search    = default( search,         2 )  #  Motion Search Algorithm. Default is "Diamond"
    me        = default( MEdepth,        2 )  #  Search effort of motion search
    EdiMode   = default( EdiMode, "nnedi3" )  #  Interpolator. Select between EEDI2, nnedi, nnedi2, & nnedi3
    nsize     = default( nsize,          2 )  #  nnedi2/nnedi3 only: Sets the size of the local neighborhood around each pixel that is used by the predictor neural network. For deinterlacing, larger x_diameter settings will allow connecting lines of smaller slope. 0-2 for nnedi2; 0-4 for nnedi3. Possible settings (x_diameter x y_diameter): 0 (8x6), 1 (16x6), 2 (32x6), 3 (48x6), 4 (8x4)
    nns       = default( nns,            1 )  #  nnedi3 only: "Speed" vs. "Quality" option. Sets the number of neurons in the predictor neural network. Settings ranges from 0 to 3 (3 being the best/slowest). 0 (32), 1 (64), 2 (128), or 3 (256)
    qual      = default( qual,           1 )  #  nnedi2/nnedi3 only: Controls the number of different neural network predictions that are blended together to compute the final output value. Each neural network was trained on a different set of training data. Blending the results of these different networks improves generalization to unseen data. Possible values are 1-3 for nnedi2, and 1 or 2 for nnedi3. Essentially this is a quality vs speed option. Larger values will result in more processing time, but should give better results
    maxd      = default( maxd,          24 )  #  Adjustable parameter for EEDI2 only. Refer to EEDI2's doc for details
    sharpness = (EdiPost==2)
     \        ? default( sharpness,    0.7 )  
     \        : default( sharpness,    1.0 )  #  use slight sharpening before STT routine
    
    mtnmode   = default( mtnmode,        1 )  #  0 = use only same-parity motion check, 1|2 use an additional 
                                              #  inter-parity check: 1 = on vertical edges / 2 = not on horizontal edges
    mtnth1    = default( mtnth1,      0.20 )  #  below this %age of local min/max is static
    mtnth2    = default( mtnth2,      0.40 )  #  above this %age of local min/max is motion
    errth1    = default( errth1,      0.40 )  #  similar for error detection
    errth2    = default( errth2,      0.60 )  #  of motion interpolation errors
    MEspatNR  = default( MEspatNR,    0.00 )  #  amount of spatial NR (for motion search only)
    MEtempNR  = default( MEtempNR,    0.00 )  #  amount of temporal NR (for motion search only)
    nnrep     = default (nnrep,           0)
    nnedi3pad = default (nnedi3pad,   false)

    order = (clp.GetParity == True) ? 0 : 1
    ORDR  = (order==0) ? "TFF" : "BFF"

    ox    = clp.width()
    oy    = clp.height()
    ERTH1 = string(errth1)
    ERTH2 = string(errth2)
    MNTH1 = string(mtnth1)
    MNTH2 = string(mtnth2)
    SSTR  = string(sharpness)


# Create basic operations that we will work with
# ==============================================

# Basic Field & Bob clips
# -----------------------
    flatbob   = clp.sh_Bob(1,0)
    normbob   = clp.sh_Bob(0.0,0.5) 
    ofields   = clp.SeparateFields()
    oweave    = clp.DoubleWeave()
	oEdiMode  = EdiMode
	EdiMode   = EdiMode=="EEDI3+NNEDI3" ? "nnedi3" : EdiMode
    edibobbed = (EdiMode=="nnedi3")        ? nnedi3pad ? clp.sh_Padding(2,4,2,4).nnedi3(field=-2,nsize=nsize,nns=nns,qual=qual,threads=EdiThreads).crop(2,4,-2,-4,true) : clp.nnedi3(field=-2,nsize=nsize,nns=nns,qual=qual,threads=EdiThreads)
     \        : (EdiMode=="nnedi2")        ? clp.nnedi2(field=-2,nsize=nsize,qual=qual,threads=EdiThreads)
     \        : (EdiMode=="nnedi")         ? clp.nnedi(field=-2)
     \        : (EdiMode=="EEDI3")         ? clp.EEDI3(field=-2,mdis=maxd,threads=EdiThreads)
     \        : (EdiMode=="EEDI2")         ? clp.SeparateFields().EEDI2(field=-2,maxd=maxd,threads=EdiThreads)
	 \                                     : clp

    edibobbed = (oEdiMode=="EEDI3+NNEDI3") ? nnrep > 0 ? nnrep > 1 ? clp.EEDI3(field=-2,mdis=maxd,threads=EdiThreads,sclip=edibobbed).slimit_dif(edibobbed,thr=4) : clp.EEDI3(field=-2,mdis=maxd,threads=EdiThreads,sclip=edibobbed).Repair(edibobbed,9)
	 \                                                 : clp.EEDI3(field=-2, mdis=maxd,threads=EdiThreads, sclip=edibobbed)
	 \                                     : edibobbed

    bobbed    = (EdiPre == 0.0) ? normbob
     \        : (EdiPre == 1.0) ? edibobbed
     \        :                   normbob.merge(edibobbed,EdiPre)


# Mask to check if motion compensation has delivered only the neighbor's spatial interpolated part
# ------------------------------------------------------------------------------------------------
    black    = Blankclip(ofields,Color_yuv=color_black).Trim(1,1).Loop(Framecount(clp))
    white    = Blankclip(ofields,Color_yuv=color_white).Trim(1,1).Loop(Framecount(clp))
    interpol = Interleave(black,white,white,black).AssumeFieldbased().AssumeParity(ORDR).Weave()


# Vertical Edge mask, needed for more safe motion masking
# -------------------------------------------------------
    Vedge  = bobbed.mt_Edge("1 0 -1 2 0 -2 1 0 -1",0,255,0,255,U=1,V=1)
    Vedge2 = Vedge.mt_Inpand(mode="vertical").mt_Inpand(mode="vertical").mt_Expand(mode="vertical").mt_Expand(mode="vertical")
    Vedge  = sisavs26 ? mt_Lutxy(Vedge,Vedge2,yexpr="y 2 scalef - 2 * x > x y 2 scalef - 2 * ?", use_expr=1) : mt_Lutxy(Vedge,Vedge2,yexpr="y 2 - 2 * x > x y 2 - 2 * ?") #.mt_Expand()

    Hedge = bobbed.mt_Edge("1 2 1 0 0 0 -1 -2 -1",0,255,0,255,U=1,V=1)
    Hedge = Hedge.mt_logic(Hedge.temporalsoften(1,255,0,255,2),"max")


# If requested, do flicker reduction before searching motion vectors
# -------------------------------------------------------------------
    (MEspatNR==0.0) ? bobbed : bobbed.Merge(bobbed.minblur(2,uv=3),MEspatNR)
    (MEtempNR==0.0) ? last : last.Merge(reduceflicker(2),MEtempNR)
    srch=last


# Perform Motion Search
# ---------------------
    lmbda = 128
    pnw   =  40
    srch_super = srch.SelectEven().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    srch_super2 = srch.SelectOdd().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    bw_vec2 = MAnalyse(srch_super,isb=true, truemotion=false,delta=1,lambda=lmbda,search=search,searchparam=me,blksize=bs,overlap=1*bs/2,pnew=pnw)
    fw_vec2 = MAnalyse(srch_super, isb=false, truemotion=false,delta=1,lambda=lmbda,search=search,searchparam=me,blksize=bs,overlap=1*bs/2,pnew=pnw)
    bw_vec3 = MAnalyse(srch_super2, isb=true, truemotion=false,delta=1,lambda=lmbda,search=search,searchparam=me,blksize=bs,overlap=1*bs/2,pnew=pnw)
    fw_vec3 = MAnalyse(srch_super2, isb=false, truemotion=false,delta=1,lambda=lmbda,search=search,searchparam=me,blksize=bs,overlap=1*bs/2,pnew=pnw)


# Create RAW motion interpolation
# -------------------------------
    bobbed_Clip  = bobbed.SelectEven().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    bobbed_Clip2 = bobbed.SelectOdd().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    alt_1   = MFlowInter(bobbed_Clip,bw_vec2,fw_vec2,time=50.0,thSCD1=64*18,thSCD2=227)
    alt_2   = MFlowInter(bobbed_Clip2,bw_vec3,fw_vec3,time=50.0,thSCD1=64*18,thSCD2=227).DuplicateFrame(0)
    alt     = Interleave(alt_2,alt_1)


# Create motion interpolation of "nothing new" mask
# -------------------------------------------------
    Flow_Clip  = interpol.SelectEven().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    Flow_Clip2  = interpol.SelectOdd().MSuper(hpad=bs, vpad=bs, sharp=2, rfilter=0)
    interpol_1   = MFlowInter(Flow_Clip,bw_vec2,fw_vec2,time=50.0,thSCD1=64*8,thSCD2=127)
    interpol_2   = MFlowInter(Flow_Clip2,bw_vec3,fw_vec3,time=50.0,thSCD1=64*8,thSCD2=127).DuplicateFrame(0)
    interpol_comp= Interleave(interpol_2,interpol_1)
    nothing_new  = sisavs26 ? mt_lutxy(interpol,interpol_comp,"x y * range_max / range_max / 1 2 / ^ 160 scaleb *", clamp_float=true, use_expr=1) : mt_lutxy(interpol,interpol_comp,"x y * 255 / 255 / 1 2 / ^ 160 *")


# Error check of motion interpolation
# ===================================
# Errors that are neutralized by errors in direct vertical neighborhood are not considered, because bob-typical.
# Remaining error is checked against [min,max] of local error to decide if it's valid or not.
#
# Build error mask, neutralize vertical-only errors
# ---------------------------------------------------
    altD     = mt_Makediff(bobbed,alt,U=3,V=3)
    altDmin  = altD.mt_Inpand(mode="vertical",U=3,V=3)
    altDmin  = altDmin.mt_Deflate().mt_Merge(altDmin,Vedge,U=4,V=4)
    altDmax  = altD.mt_Expand(mode="vertical",U=3,V=3)
    altDmax  = altDmax.mt_Inflate().mt_Merge(altDmax,Vedge,U=4,V=4)
    altDmm   = sisavs26 ? mt_Lutxy(altDmax.mt_Expand(mode="horizontal",U=3,V=3),altDmin.mt_Inpand(mode="horizontal",U=3,V=3),"x y -",U=3,V=3, use_expr=1) : mt_Lutxy(altDmax.mt_Expand(mode="horizontal",U=3,V=3),altDmin.mt_Inpand(mode="horizontal",U=3,V=3),"x y -",U=3,V=3)
    altDmm   = altDmm.mt_Inflate().mt_Merge(altDmm,Vedge,U=4,V=4)
    altD1    = sisavs26 ? altD .mt_Lutxy(altDmin,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",U=3,V=3, use_expr=1) : altD .mt_Lutxy(altDmin,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?",U=3,V=3)
    altD1    = sisavs26 ? altD1.mt_Lutxy(altDmax,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",U=3,V=3, use_expr=1) : altD1.mt_Lutxy(altDmax,"x 128 - y 128 - * 0 < 128 x 128 - abs y 128 - abs < x y ? ?",U=3,V=3)
    altD2    = altD.Repair(altD1,1)


# Build correction mask by combining:  error mask  +  "nothing new" mask  +  a scenechange mask
# ---------------------------------------------------------------------------------------------
    corrmask = sisavs26 ? mt_Lutxy(altD2,altDmm,"x 128 - abs 2 - y 2 + / "+ERTH1+" - "+ERTH2+" "+ERTH1+" - / 255 * range_min -",U=3,V=3,scale_inputs="allf", clamp_float=true,clamp_float_uv=true, use_expr=1).mt_Expand(U=3,V=3) : mt_Lutxy(altD2,altDmm,"x 128 - abs 2 - y 2 + / "+ERTH1+" - "+ERTH2+" "+ERTH1+" - / 255 *",U=3,V=3).mt_Expand(U=3,V=3)
    sc       = corrmask.BilinearResize(64,64)
    sc       = mt_LutF(sc,sc,mode="average",expr=sisavs26 ? "x range_max 0.5 * > range_max 0 ?" : "x 255 0.6 * > 255 0 ?").PointResize(ox,oy)
    corrmask = corrmask.mt_Logic(nothing_new,"max",U=2,V=2)
    corrmask = corrmask.mt_Logic(sc,"max",U=2,V=2)


# Create a first bob from motion interpolation, not yet error corrected ...
# -------------------------------------------------------------------------
# ***( temporarily changed ... yet unsure what works best )***

    Interleave(bobbed,alt).AssumeParity(ORDR)
    SeparateFields().SelectEvery(8,0,3,5,6).Weave()
    naked= last
    naked2 = last.vinverseD(1.6) # flatbob # 
    
    naked_mm = naked.mt_Edge("min/max",0,255,0,255,U=1,V=1)
    edibb_mm = edibobbed.mt_Edge("min/max",0,255,0,255,U=1,V=1).mt_Expand(mode="vertical")
    check2   = sisavs26 ? mt_LutXY(naked_mm,edibb_mm,"x y / 3 - 5 3 - / 255 *",scale_inputs="allf", clamp_float=true,clamp_float_uv=true, use_expr=1) : mt_LutXY(naked_mm,edibb_mm,"x y / 3 - 5 3 - / 255 *")
    corrmask = corrmask.mt_Logic(check2,"max",U=2,V=2)


# ... and build a motion mask from this one.
# ------------------------------------------
# ***( temporarily changed ... tickertapes might suffer. )***

    stc = bobbed .removegrain(2)# oweave.removegrain(11)
    mm         = stc.mt_Edge("min/max",0,255,0,255,U=3,V=3)
   #  mm = mm .mt_Logic(mm.DuplicateFrame(0),"max",U=3,V=3).mt_Logic(mm.DeleteFrame(0),"max",U=3,V=3)
    #  max = stc.mt_expand(U=3,V=3)
    #  max = max.mt_logic(max.Duplicateframe(0),"max",U=3,V=3).mt_logic(max.Duplicateframe(0).Duplicateframe(0),"max",U=3,V=3)
    #  min = stc.mt_inpand(U=3,V=3)
    #  min = min.mt_logic(min.Duplicateframe(0),"min",U=3,V=3).mt_logic(min.Duplicateframe(0).Duplicateframe(0),"min",U=3,V=3)
    #  mm = mt_LutXY(max,min,"x y -",U=3,V=3)
    diff2prev1 = sisavs26 ? mt_LutXY(stc,stc.DuplicateFrame(0),"x y - abs range_min +",U=3,V=3, use_expr=1) : mt_LutXY(stc,stc.DuplicateFrame(0),"x y - abs",U=3,V=3)
    diff2prev2 = sisavs26 ? mt_LutXY(stc,stc.DuplicateFrame(0).DuplicateFrame(0),"x y - abs range_min +",U=3,V=3, use_expr=1) : mt_LutXY(stc,stc.DuplicateFrame(0).DuplicateFrame(0),"x y - abs",U=3,V=3)

    diff2prev12 = (mtnmode==0) ? diff2prev2 :
     \            (mtnmode==1) ? diff2prev2 .mt_Merge(diff2prev1,Vedge,U=2,V=2)
     \                         : diff2prev1 .mt_Merge(diff2prev2,Hedge,U=2,V=2)

    motn       = diff2prev12.mt_Logic(diff2prev12.DeleteFrame(0),"max",U=3,V=3).mt_Logic(diff2prev12.DeleteFrame(0).DeleteFrame(0),"max",U=3,V=3)
    notstatic  = sisavs26 ? mt_LutXY(motn,mm,"x 1 - y 1 + / "+MNTH1+" - "+MNTH2+" "+MNTH1+" - / 255 *",U=3,V=3,scale_inputs="allf", clamp_float=true,clamp_float_uv=true, use_expr=1).mt_Expand(U=3,V=3).mt_Inpand(U=3,V=3) : mt_LutXY(motn,mm,"x 1 - y 1 + / "+MNTH1+" - "+MNTH2+" "+MNTH1+" - / 255 *",U=3,V=3).mt_Expand(U=3,V=3).mt_Inpand(U=3,V=3)
   # notstatic  = notstatic.mt_Logic(notstatic.RemoveGrain(4),"max",U=3,V=3).mt_Expand(U=3,V=3).mt_Inpand(U=3,V=3)


# Now do the error correction of the "naked" MC-bob
# -------------------------------------------------
    naked .mt_Merge(edibobbed,corrmask,luma=false,U=3,V=3) .VinverseD(2.7-sharpness)
    repaired = last


# If requested, sharpen the corrected MC-bob up a little 
# ( pre-sharpen for EdiPost = 0 | 1 )
# ------------------------------------------------------
    shrpbase  = last#.MinBlur(1,1).Merge(RemoveGrain(12,-1),0.23)
    shrp      = sisavs26 ? mt_LutXY(shrpbase,shrpbase.RemoveGrain(11,-1),"x x y - abs 16 / 1 1 x y - abs 1 4 / ^ + / ^ 16 * "+SSTR+" * x y - x y - abs 1.3 + / * 1 x y - abs 16 / 1 4 / ^ + / +",U=2,V=2,scale_inputs="allf", use_expr=1) : mt_LutXY(shrpbase,shrpbase.RemoveGrain(11,-1),"x x y - abs 16 / 1 1 x y - abs 1 4 / ^ + / ^ 16 * "+SSTR+" * x y - x y - abs 1.3 + / * 1 x y - abs 16 / 1 4 / ^ + / +",U=2,V=2)
    # \ .Repair(repaired,1,0)
    shrpD     = mt_Makediff(shrpbase,shrp)

    (sharpness==0.0 || EdiPost==2) ? last : last .mt_Makediff(MergeLuma(shrpD.MinBlur(1,uv=1),shrpD.RemoveGrain(12,-1),0.24),U=2,V=2)


# If requested, do additional PP via ediI
# ----------------------------------------
oweave.mt_merge(last,notstatic,luma=false,U=3,V=3)
    AssumeTFF()
    edisingle = (EdiMode=="nnedi3") ? nnedi3(dh=true,field=1,nsize=nsize,nns=nns,qual=qual).LanczosResize(ox,oy,0,-0.5,ox,2*oy+0.001,taps=3)
	\         : (EdiMode=="nnedi2") ? nnedi2(dh=true,field=1,nsize=nsize,qual=qual).LanczosResize(ox,oy,0,-0.5,ox,2*oy+0.001,taps=3)
	\         : (EdiMode=="nnedi")  ? nnedi(dh=true,field=1).LanczosResize(ox,oy,0,-0.5,ox,2*oy+0.001,taps=3)
	\         : (EdiMode=="EEDI2")  ? EEDI2(maxd=maxd).LanczosResize(ox,oy,0,-0.5,ox,2*oy+0.001,taps=3)
	\                               : clp
	edidouble = (EdiMode=="nnedi3") ? merge(nnedi3(field=1,nsize=nsize,nns=nns,qual=qual),nnedi3(field=0,nsize=nsize,nns=nns,qual=qual),0.5)
	\         : (EdiMode=="nnedi2") ? merge(nnedi2(field=1,nsize=nsize,qual=qual),nnedi2(field=0,nsize=nsize,qual=qual),0.5)
	\         : (EdiMode=="nnedi")  ? merge(nnedi(field=1),nnedi(field=0),0.5)
	\         : (EdiMode=="EEDI2")  ? merge(SeparateFields().SelectEven().EEDI2(field=1,maxd=maxd),SeparateFields().SelectOdd().EEDI2(field=0,maxd=maxd),0.5)
	\                               : clp
    edidoubleD = mt_makediff(last,edidouble,U=3,V=3)
    (EdiPost==1) ? edisingle : \
    (EdiPost==2) ? edidouble : last

# ( post-sharpen for EdiPost = 2 )
# ------------------------------------------------------
    edidoubleshrpD = mt_makediff(edidouble,sharpness==1.0?edidouble.removegrain(20):edidouble.removegrain(20).merge(edidouble,1.0-sharpness),U=3,V=3)
    edidoubleshrpD = edidoubleshrpD.repair(edidoubleD,13)
    (EdiPost==2) ? edidouble.mt_adddiff(edidoubleshrpD,U=3,V=3) : last


# STT (Shape Transposition Technology) Routine:
# =============================================
# Simply weaving the corrected output with the original fields is bad, because the risk of 
# creating unwanted residual combing is too high.
# Instead, the vertical "shape" is taken off the corrected output, and transposed 
# onto the fixed "poles" of the original fields' scanlines. Et Voila.
# ----------------------------------------------------------------------------------------
    synthbob   = last.AssumeParity(ORDR).SeparateFields().SelectEvery(4,0,3).Weave().Bob(1,0)
    mapped_new = flatbob.mt_makediff(mt_makediff(synthbob,last,U=3,V=3),U=3,V=3)
    newfields  = mapped_new.AssumeParity(ORDR).SeparateFields().SelectEvery(4,1,2)
    mappedbob  = Interleave(ofields,newfields).SelectEvery(4,0,1,3,2).AssumeParity(ORDR).Weave()


# Finally, for static areas use just original fields
# --------------------------------------------------
    mappedbob
    #bobbed
    
    oweave.mt_merge(last,notstatic.mt_inpand(Y=2,U=2,V=2),luma=false,U=3,V=3)


# Lastly, set correct parity for the bobbed clip
# ----------------------------------------------
    (order==0) ? AssumeTFF() : AssumeBFF()
    
    return(last)
}

############################
#  Helper functions below  #
############################


# Helper to simplify script
function AssumeParity(clip clp, string "order")
{
order == "TFF" ? clp.assumeTFF() : clp.assumeBFF()
return(last)
}