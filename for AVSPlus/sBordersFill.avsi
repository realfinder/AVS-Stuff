# sBordersFill by real.finder
# Beta 081
Function sBordersFill(clip c, int "left", int "top", int "right", int "bottom")
{
left   = default(left,   0)
top    = default(top,    0)
right  = default(right,  0)
bottom = default(bottom, 0)
c
isy() ? last : z_ConvertFormat(chroma_subsampling="444", use_props=1)
propSet("_FieldBased", 0)
c2=last
mask=BlankClip(last).LetterBox(top,bottom,left,right,color_yuv=$FFFFFF)
ContinuityFixer(left,top,right,bottom).FillBorders(left=left>1?1:0,right=right>1?1:0,top=top>1?1:0,bottom=bottom>1?1:0,mode=6)
inp=c2.crop(left>2?left-1:left,top>2?top-1:top,right>2?-(right-1):-right,bottom>2?-(bottom-1):-bottom).sh_Padding((left>2?left-1:left)+4,(top>2?top-1:top)+4,(right>2?right-1:right)+4,(bottom>2?bottom-1:bottom)+4).InpaintLogo(mask.sh_Padding(4, 4, 4, 4)).Crop(4,4,-4,-4)
propCopy(last,c).z_ConvertFormat(pixel_type=PixelType(c), use_props=1)
ex_merge(c,last.merge(inp.z_ConvertFormat(pixel_type=PixelType(c))),mask,luma=true)
ReferenceFixer(FastBlur(left>0||right>0?0.8125:0, top>0||bottom>0?0.8125:0, iterations = 1, gamma = false), left>0?left+1:left,top>0?top+1:top,right>0?right+1:right,bottom>0?bottom+1:bottom)
}