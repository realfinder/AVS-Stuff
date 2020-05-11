#########################################################################################
###                                                                                   ###
###                      function Smooth Levels : oSmoothLevels()                      ###
###                                                                                   ###
###                                v1.02 by "LaTo INV."                               ###
###                                                                                   ###
###                                  28 January 2009                                  ###
###                                   24 April 2020                                   ###
###                                                                                   ###
#########################################################################################
### 
### 
### /!\ Needed filters : Masktools (v2.0a35), Removegrain (v1.0PR), GradFun2db (v1.0).
### --------------------
### 
###
### USAGE: SmoothLevels(input_low, gamma, input_high, output_low, output_high, 
###                     chroma, limiter,
###                     Lmode, DarkSTR, BrightSTR, Ecenter, protect, Ecurve,
###                     Smode, Mfactor, RGmode, useGF,
###                     show, screenW, screenH, preset)
###
###
###
### +---------+
### | GENERAL |
### +---------+
###
### Levels options:
### ---------------
### input_low, gamma, input_high, output_low, output_high [default: 0, 1.0, 255, 0, 255]
### 
### chroma [default: 50]
### ---------------------
### 0   = no chroma processing     (similar as Ylevels)
### xx  = intermediary
### 100 = normal chroma processing (similar as Levels)
### 
### limiter [default: 0]
### --------------------
### 0 = no limiter             (similar as Ylevels)
### 1 = input limiter
### 2 = output limiter         (similar as Levels: coring=false)
### 3 = input & output limiter (similar as Levels: coring=true)
###
###
###
### +----------+
### | LIMITING |
### +----------+
###
### Lmode [default: 0]
### ------------------
### 0 = no limit
### 1 = limit conversion on dark & bright areas (apply conversion @0%   at luma=0 & @100% at luma=Ecenter & @0% at luma=255)
### 2 = limit conversion on dark areas          (apply conversion @0%   at luma=0 & @100% at luma=255)
### 3 = limit conversion on bright areas        (apply conversion @100% at luma=0 & @0%   at luma=255)
###
### DarkSTR [default: 100]
### ----------------------
### Strength for limiting: the higher, the more conversion are reduced on dark areas (for Lmode=1&2)
###
### BrightSTR [default: 100]
### ------------------------
### Strength for limiting: the higher, the more conversion are reduced on bright areas (for Lmode=1&3)
###
### Ecenter [default: 128]
### ----------------------
### Center of expression for Lmode=1
### 
### protect [default: -1]
### ---------------------
### -1  = protect off
### >=0 = pure black protection
###       ---> don't apply conversion on pixels egal or below this value 
###            (ex: with 16, the black areas like borders 
###                 and generic are untouched so they don't look washed out)
###
### Ecurve [default: 0]
### -------------------
### Curve used for limit & protect:
### 0 = use sine curve
### 1 = use linear curve
###
###
###
### +-----------+
### | SMOOTHING |
### +-----------+
###
### Smode [default: -2]
### -------------------
### 2  = smooth on, maxdiff must be < to "255/Mfactor"
### 1  = smooth on, maxdiff must be < to "128/Mfactor"
### 0  = smooth off
### -1 = smooth on if maxdiff < "128/Mfactor", else off
### -2 = smooth on if maxdiff < "255/Mfactor", else off
###
### Mfactor [default: 2]
### --------------------
### The higher, the more precise but the less maxdiff alowed: 
### maxdiff=128/Mfactor for Smode1&-1 and maxdiff=255/Mfactor for Smode2&-2
###
### RGmode [default: 12]
### --------------------
### In strength order: + 19 > 12 >> 20 > 11 -
###
### useGF [default: true]
### ---------------------
### Use gradfun2db on top of removegrain: prevent posterize when doing levels conversion
### 
###
###
### +--------+
### | OTHERS |
### +--------+
###
### show [default: false]
### ---------------------
### Show the debug clip
###
### screenW [default: 1280]
### -----------------------
### Screen horizontal resolution for debug clip
###
### screenH [default: 1024]
### ----------------------
### Screen vertical resolution for debug clip
###
### preset: 
### -------
### pc2tv = "PC -> TV" conversion
### tv2pc = "TV -> PC" conversion 
### 
### 
###
### +-----------+
### | CHANGELOG |
### +-----------+ 
###
### v1.02    : changed show clip (with screenW & screenH)
###
### v1.01    : fixed a bug in Lmode=1&3 (pi approx)
###
### v1.00    : first stable release
###            optimized limiting code (faster and less rounding error)
###            added new parameters for limiting (Ecenter,Ecurve)
###            changed strength parameter for 2 others (DarkSTR & BrightSTR)
###            changed code of protect option (hard->soft threshold)
###
### 1.0beta2 : changed Lmode parameter (added Ecenter & strength)
###            updated the documentation + cosmetic
###
### 1.0beta1 : changed chroma parameter (more precise)
###            cosmetic changes
###
### 1.0alpha : changed name Ulevels() --> SmoothLevels()
###            *big* bugfix with limiter>0
###            changed smooth --> RGmode
###            added useGF, useful to prevent posterize
###            changed all Smode code, deleted unuseful mode and added new one
###            deleted SS parameter
###            added Mfactor parameter
###            some cosmetic change & speed up
###            updated the documentation
### 
### v0.9.00a : new Smode (-1,-2,-3)
###            speed optimization & cosmetic change
###            mode ---> Lmode & smooth ---> Smode
###            smooth setting
### 
### v0.8.05f : no more mt_lutxyz for smooth=-3
### 
### v0.8.05e : fix another chroma problem
### 
### v0.8.05d : fix chroma shift problem
### 
### v0.8.05c : first public release
###
###
#########################################################################################



function oSmoothLevels(clip input, float "input_low", float "gamma", float "input_high", float "output_low", float "output_high",
\                     int "chroma", int "limiter",
\                     int "Lmode", float "DarkSTR", float "BrightSTR", float "Ecenter", float "protect", int "Ecurve",
\                     int "Smode", int "Mfactor", int "RGmode", bool "useGF",
\                     bool "show", int "screenW", int "screenH", string "preset")
{
sisavs26 = !(VersionNumber() < 2.60)
### VERSION
version = "v1.02"
sisavs26 ? nop() : Assert(isYV12(input) == True ? true : false, chr(10) + "This is not an YV12 clip ! Please convert color space to YV12 before using SmoothLevels()" + chr(10))

preset     = Default(preset, "default")
preset_num =  -1 
preset_num = (preset == "default") ? 0 : preset_num
preset_num = (preset == "pc2tv")   ? 1 : preset_num
preset_num = (preset == "tv2pc")   ? 2 : preset_num
Assert(preset_num >=0 ? true : false, chr(10) + "This preset does not exist !" + chr(10))


### PRESET_DEFAULT                                       #  DEFAULT  #   PC2TV   #   TV2PC   #
input_low   = Default(input_low,     Select(preset_num   ,   0       ,   0       ,   16      ) )
gamma       = Default(gamma,         Select(preset_num   ,   1.0     ,   1.0     ,   1.0     ) )
input_high  = Default(input_high,    Select(preset_num   ,   255     ,   255     ,   235     ) )
output_low  = Default(output_low,    Select(preset_num   ,   0       ,   16      ,   0       ) )
output_high = Default(output_high,   Select(preset_num   ,   255     ,   235     ,   255     ) )

chroma      = Default(chroma,        Select(preset_num   ,   50      ,   50      ,   50      ) )
limiter     = Default(limiter,       Select(preset_num   ,   0       ,   2       ,   2       ) )

Lmode       = Default(Lmode,         Select(preset_num   ,   0       ,   0       ,   0       ) )
DarkSTR     = Default(DarkSTR,       Select(preset_num   ,   100     ,   100     ,   100     ) )
BrightSTR   = Default(BrightSTR,     Select(preset_num   ,   100     ,   100     ,   100     ) )
Ecenter     = Default(Ecenter,       Select(preset_num   ,   128     ,   128     ,   128     ) )
protect     = Default(protect,       Select(preset_num   ,   -1      ,   -1      ,   -1      ) )
Ecurve      = Default(Ecurve,        Select(preset_num   ,   0       ,   0       ,   0       ) )

Smode       = Default(Smode,         Select(preset_num   ,   -2      ,   1       ,   1       ) )
Mfactor     = Default(Mfactor,       Select(preset_num   ,   2       ,   4       ,   4       ) )
RGmode      = Default(RGmode,        Select(preset_num   ,   12      ,   19      ,   19      ) )
useGF       = Default(useGF,         Select(preset_num   ,   True    ,   True    ,   True    ) )

show        = Default(show,          Select(preset_num   ,   False   ,   False   ,   False   ) )
screenW     = Default(screenW,       Select(preset_num   ,   1280    ,   1280    ,   1280    ) )
screenH     = Default(screenH,       Select(preset_num   ,   1024    ,   1024    ,   1024    ) )

Assert( ( input_low >= 0 && input_low <= 255 )                             ? true : false, chr(10) + "'input_low' have not a correct value! [0;255]" + chr(10))
Assert( ( gamma > 0.0 )                                                    ? true : false, chr(10) + "'gamma' have not a correct value! [>0.0]" + chr(10))
Assert( ( input_high >= 0 && input_high <= 255 )                           ? true : false, chr(10) + "'input_high' have not a correct value! [0;255]" + chr(10))
Assert( ( output_low >= 0 && output_low <= 255 )                           ? true : false, chr(10) + "'output_low' have not a correct value! [0;255]" + chr(10))
Assert( ( output_high >= 0 && output_high <= 255 )                         ? true : false, chr(10) + "'output_high' have not a correct value! [0;255]" + chr(10))
Assert( ( chroma >= 0 && chroma <= 100 )                                   ? true : false, chr(10) + "'chroma' have not a correct value! [0;100]" + chr(10))
Assert( ( limiter >= 0 && limiter <= 3 )                                   ? true : false, chr(10) + "'limiter' have not a correct value! [0;3]" + chr(10))
Assert( ( Lmode >= 0 &&  Lmode <= 3 )                                      ? true : false, chr(10) + "'Lmode' have not a correct value! [0;3]" + chr(10))
Assert( ( DarkSTR >= 0 )                                                   ? true : false, chr(10) + "'DarkSTR' have not a correct value! [>=0]" + chr(10))
Assert( ( BrightSTR >= 0 )                                                 ? true : false, chr(10) + "'BrightSTR' have not a correct value! [>=0]" + chr(10))
Assert( ( Ecenter >= 0 )                                                   ? true : false, chr(10) + "'Ecenter' have not a correct value! [>=0]" + chr(10))
Assert( ( protect >=-1 && protect <= 255 )                                 ? true : false, chr(10) + "'protect' have not a correct value! [-1;255]" + chr(10))
Assert( ( Ecurve >= 0 && Ecurve <= 1 )                                     ? true : false, chr(10) + "'Ecurve' have not a correct value! [0;1]" + chr(10))
Assert( ( Smode >= -2 && Smode <= 2 )                                      ? true : false, chr(10) + "'Smode' have not a correct value! [-2;2]" + chr(10))
Assert( ( Mfactor > 0 )                                                    ? true : false, chr(10) + "'Mfactor' have not a correct value! [>0]" + chr(10))
Assert( ( RGmode == 19 || RGmode == 20 ||  RGmode == 11 ||  RGmode == 12 ) ? true : false, chr(10) + "'RGmode' have not a correct value! [19;20;11;12]" + chr(10))

chr31    = ( chroma == 0 ) ? 1  : 3
chr41    = ( chroma == 0 ) ? 1  : 4
RGmodeUV = ( chroma == 0 ) ? -1 : RGmode


### EXPRESSION
exprY  = sisavs26 ? "x "+string(input_low)+" scalef - "+string(input_high)+" scalef "+string(input_low)+" scalef - / 0 1 clip 1 "+string(gamma)+
\        " / ^ "+string(output_high)+" scalef "+string(output_low)+" scalef - * "+string(output_low)+" scalef +" : 
\                   "x "+string(input_low)+" - "+string(input_high)+" "+string(input_low)+" - / 1 "+string(gamma)+
\        " / ^ "+string(output_high)+" "+string(output_low)+" - * "+string(output_low)+" +"

scaleC = ( float(output_high) - output_low ) / ( input_high - input_low )
scaleC = ( scaleC + (100.0/chroma) - 1.0 ) / ( 100.0/chroma )

exprC  = ( chroma != 0 ) ? sisavs26 ? "x range_half - "+string(scaleC)+" * range_half +" : "x 128 - "+string(scaleC)+" * 128 +" : "x"

Dstr   = string(float(DarkSTR)  /100.0)
Bstr   = string(float(BrightSTR)/100.0)

exprL  = ( Lmode == 1 && Ecurve == 0 ) ? "x "+string(Ecenter)+" < x 333 106 / * 2 "+string(Ecenter)+" * / sin "+Dstr+" ^ x "+string(Ecenter)+" > 333 106 / 2 / x "+string(Ecenter)+" - 333 106 / * 2 255 "+string(Ecenter)+" - * / + sin "+Bstr+" ^ 1 ? ?"
\      : ( Lmode == 2 && Ecurve == 0 ) ? "x 333 106 / * 2 255 * / sin "+Dstr+" ^"
\      : ( Lmode == 3 && Ecurve == 0 ) ? "333 106 / 2 / x 333 106 / * 2 255 * / + sin "+Bstr+" ^"
\      : ( Lmode == 1 && Ecurve == 1 ) ? "x "+string(Ecenter)+" < x "+string(Ecenter)+" / abs "+Dstr+" ^ x "+string(Ecenter)+" > 1 x "+string(Ecenter)+" - 255 "+string(Ecenter)+" - / abs - "+Bstr+" ^ 1 ? ?"
\      : ( Lmode == 2 && Ecurve == 1 ) ? "1 x 255 - 255 / abs - "+Dstr+" ^"
\      : ( Lmode == 3 && Ecurve == 1 ) ? "x 255 - 255 / abs "+Bstr+" ^"
\      :                                 "1"

exprP  = ( protect == -1 ) ? "1"
\      : ( Ecurve  == 0  ) ? "x "+string(protect)+" <= 0 x "+string(protect)+" 16 + >= 1 x "+string(protect)+" - 333 106 / * 2 16 * / sin ? ?"
\      :                     "x "+string(protect)+" <= 0 x "+string(protect)+" 16 + >= 1 x "+string(protect)+" - 16 / abs ? ?"


### PROCESS
thrshld = ( 1.0 + (float(abs(input_low - output_low) + abs(input_high - output_high)) / 128.0) ) * gamma

limitI = ( limiter == 1 || limiter == 3 ) ? sisavs26 ? mt_lut(input, expr="x "+string(input_low)+" scalef < "+string(input_low)+" scalef x "+string(input_high)+" scalef > "+string(input_high)+" scalef x ? ?",use_expr=2, U=chr31, V=chr31) : mt_lut(input, expr="x "+string(input_low)+" < "+string(input_low)+" x "+string(input_high)+" > "+string(input_high)+" x ? ?", U=chr31, V=chr31)
\      :                                    input

level   = sisavs26 ? mt_lut(limitI, Yexpr=exprL+" "+exprP+" * "+exprY+" x - * x +", scale_inputs="allf", use_expr=2, Uexpr=exprC, Vexpr=exprC, U=chr31, V=chr31) : mt_lut(limitI, Yexpr=exprL+" "+exprP+" * "+exprY+" x - * x +", Uexpr=exprC, Vexpr=exprC, U=chr31, V=chr31)
diff    = sisavs26 ? mt_lutxy(limitI, level, "x y - "+string(Mfactor)+" * range_half +", use_expr=2, U=chr31, V=chr31) : mt_lutxy(limitI, level, "x y - "+string(Mfactor)+" * 128 +", U=chr31, V=chr31)
process = diff.RemoveGrain(RGmode,RGmodeUV)
process = ( useGF == True ) ? sisavs26 ? process.mt_lut("x range_half - "+string(Mfactor)+" / range_half +", use_expr=2, U=chr31, V=chr31).addborders(16,16,16,16,color=$808080).GradFun2DB(thrshld).crop(16,16,-16,-16) : process.mt_lut("x 128 - "+string(Mfactor)+" / 128 +", U=chr31, V=chr31).addborders(16,16,16,16,color=$808080).GradFun2DB(thrshld).crop(16,16,-16,-16)
\       :                     process
smth    = ( useGF == True ) ? mt_makediff(limitI, process, U=chr31, V=chr31)
\       :                     sisavs26 ? mt_lutxy(limitI, process, "x y range_half - "+string(Mfactor)+" / -", use_expr=1, U=chr31, V=chr31) : mt_lutxy(limitI, process, "x y 128 - "+string(Mfactor)+" / -", U=chr31, V=chr31)

level2   = sisavs26 ? mt_lutxy(limitI, diff, "x y range_half - "+string(Mfactor)+" / -", use_expr=1, U=chr31, V=chr31) : mt_lutxy(limitI, diff, "x y 128 - "+string(Mfactor)+" / -", U=chr31, V=chr31)
diff2    = sisavs26 ? mt_lutxy(level2, level, "x y - "+string(Mfactor)+" * range_half +", use_expr=1, U=chr31, V=chr31) : mt_lutxy(level2, level, "x y - "+string(Mfactor)+" * 128 +", U=chr31, V=chr31)
process2 = diff2.RemoveGrain(RGmode,RGmodeUV)
process2 = ( useGF == True ) ? sisavs26 ? process2.mt_lut("x range_half - "+string(Mfactor)+" / range_half +", use_expr=2, U=chr31, V=chr31).addborders(16,16,16,16,color=$808080).GradFun2DB(thrshld).crop(16,16,-16,-16) : process2.mt_lut("x 128 - "+string(Mfactor)+" / 128 +", U=chr31, V=chr31).addborders(16,16,16,16,color=$808080).GradFun2DB(thrshld).crop(16,16,-16,-16)
\        :                     process2
smth2    = ( useGF == True ) ? mt_makediff(smth, process2, U=chr31, V=chr31)
\        :                     sisavs26 ? mt_lutxy(smth, process2, "x y range_half - "+string(Mfactor)+" / -", use_expr=1, U=chr31, V=chr31) : mt_lutxy(smth, process2, "x y 128 - "+string(Mfactor)+" / -", U=chr31, V=chr31)

mask1  = sisavs26 ? mt_lutxy(limitI, level, expr="x y - abs range_half "+string(Mfactor)+" / >= range_max 0 ?", use_expr=1, U=chr31, V=chr31) : mt_lutxy(limitI, level, expr="x y - abs 128 "+string(Mfactor)+" / >= 255 0 ?", U=chr31, V=chr31)
mask2  = sisavs26 ? mt_lutxy(limitI, level, expr="x y - abs range_max "+string(Mfactor)+" / >= range_max 0 ?", use_expr=1, U=chr31, V=chr31) : mt_lutxy(limitI, level, expr="x y - abs 255 "+string(Mfactor)+" / >= 255 0 ?", U=chr31, V=chr31)

Slevel = ( Smode ==  2 ) ? smth2
\      : ( Smode ==  1 ) ? smth
\      : ( Smode == -1 ) ? mt_merge(smth, level, mask1, U=chr31, V=chr31)
\      : ( Smode == -2 ) ? mt_merge(smth, smth2, mask1, U=chr31, V=chr31).mt_merge(level, mask2, U=chr31, V=chr31)
\      :                   level
  
limitO = ( limiter == 2 || limiter == 3 ) ? sisavs26 ? mt_lut(Slevel, expr="x "+string(output_low)+" scalef < "+string(output_low)+" scalef x "+string(output_high)+" scalef > "+string(output_high)+" scalef x ? ?", use_expr=2, U=chr31, V=chr31) : mt_lut(Slevel, expr="x "+string(output_low)+" < "+string(output_low)+" x "+string(output_high)+" > "+string(output_high)+" x ? ?", U=chr31, V=chr31)
\      :                                    Slevel

output = ( chroma == 0 ) ? limitO.MergeChroma(input) : limitO


### SHOW
   function SL_show(clip input, clip output,
   \                int "input_low", float "gamma", int "input_high", int "output_low", int "output_high",
   \                int "chroma", int "limiter",
   \                int "Lmode", int "DarkSTR", int "BrightSTR", int "Ecenter", int "protect", int "Ecurve",
   \                int "Smode", int "Mfactor", int "RGmode", bool "useGF",
   \                string "version", string "preset", int "screenW", int "screenH")
   {
   x = screenW
   y = screenH - 240
   h = input.height
   w = input.width

   xR = round( (w*y) / (4*h) ) * 4
   xC = ( x - (xR*2) ) / 4

   img_in  = input.spline36resize(xR,y)
   img_in  = xC > 0 ? img_in.addborders(-xC,0,-xC,0) : img_in
   img_in  = xC < 0 ? img_in.crop(-xC,0,xC,0)        : img_in
   img_in  = img_in.SubTitle("Input",text_color=$FFFFFF,size=20,x=20,y=20)

   img_out = output.spline36resize(xR,y)
   img_out = xC > 0 ? img_out.addborders(-xC,0,-xC,0) : img_out
   img_out = xC < 0 ? img_out.crop(-xC,0,xC,0)        : img_out
   img_out = img_out.SubTitle("Output",text_color=$FFFFFF,size=20,x=20,y=20)

   histo_in  = input.histogram(mode="levels").crop(w,0,0,-(h-240)).SubTitle("Input",text_color=$FFFFFF,size=10)
   histo_out = output.histogram(mode="levels").crop(w,0,0,-(h-240)).SubTitle("Output",text_color=$FFFFFF,size=10)

   black = blankclip(input,width=x-512,height=240)
   param = black.SubTitle("SmoothLevels    " + string(version)       ,text_color=$FFFFFF,font="COURIER NEW",size=24,x=240,y=40)

   param = param.SubTitle("PRESET        = " + string(preset)        ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=80)
   param = param.SubTitle("Input Low     = " + string(input_low)     ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=100)
   param = param.SubTitle("Gamma         = " + string(gamma)         ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=110)
   param = param.SubTitle("Input High    = " + string(input_high)    ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=120)
   param = param.SubTitle("Output Low    = " + string(output_low)    ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=130)
   param = param.SubTitle("Output High   = " + string(output_high)   ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=140)
   param = param.SubTitle("Chroma        = " + string(chroma)        ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=150)
   param = param.SubTitle("Limiter       = " + string(limiter)       ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=20,y=160)

   param = param.SubTitle("LIMITING:"                                ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=80)
   param = param.SubTitle("---------"                                ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=90)
   param = param.SubTitle("Lmode         = " + string(Lmode)         ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=110)
   param = param.SubTitle("DarkSTR       = " + string(DarkSTR)       ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=120)
   param = param.SubTitle("BrightSTR     = " + string(BrightSTR)     ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=130)
   param = param.SubTitle("Ecenter       = " + string(Ecenter)       ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=140)
   param = param.SubTitle("Protect       = " + string(protect)       ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=150)
   param = param.SubTitle("Ecurve        = " + string(Ecurve)        ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=320,y=160)

   param = param.SubTitle("SMOOTHING:"                               ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=80)
   param = param.SubTitle("----------"                               ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=90)
   param = param.SubTitle("Smode         = " + string(Smode)         ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=110)
   param = param.SubTitle("Mfactor       = " + string(Mfactor)       ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=120)
   param = param.SubTitle("RGmode        = " + string(RGmode)        ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=130)
   param = param.SubTitle("useGF         = " + string(useGF)         ,text_color=$FFFFFF,font="COURIER NEW",size=12,x=620,y=140)

   down  = stackhorizontal(img_in,img_out)
   up    = stackhorizontal(histo_in,param,histo_out)
   debug = stackvertical(up,down)

   return debug
   }

output = ( show == False ) ? output
\      :                     SL_show(input, output,
\                                    input_low, gamma, input_high, output_low, output_high,
\                                    chroma, limiter,
\                                    Lmode, DarkSTR, BrightSTR, Ecenter, protect, Ecurve,
\                                    Smode, Mfactor, RGmode, useGF,
\                                    version, preset, screenW, screenH)

return output
}