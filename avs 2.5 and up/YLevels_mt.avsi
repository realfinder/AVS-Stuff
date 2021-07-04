########
# Levels transforms by Did?e
# Requires MaskTools v2.0 or greater
# last revision 2004-12-07; update to MaskTools v2.0 semantics 2008-03-09
# HBD update 2021.07.04
#
# PARAMETERS:
#   "input_low"     : (Default: 0)
#   "gamma"         : (Default: 1.0)
#   "input_high"    : (Default: 255)
#   "output_low"    : (Default: 0)
#   "output_high"   : (Default: 255)
#   "show_function" : (Default: false) - the function to be made into a lookup-table
#                                        transform, shown in postfix notation
#
# USAGE:
#   YLevels(0, 1.2, 255, 0, 255, false)
#   YLevels(0, 1.2, 255)
#   YLevels(gamma=1.2)



# Constant
# StainlessS edit
function Ylevels(clip clp,
\                float "input_low", float "gamma", float "input_high",
\                float "output_low", float "output_high", bool "show_function")
{ 
    input_low     = Default(input_low, 0)
    gamma         = Default(gamma, 1.0)
    input_high    = Default(input_high, 255)
    output_low    = Default(output_low, 0)
    output_high   = Default(output_high, 255)
    show_function = Default(show_function, false)
    #
    invGam  = 1.0 / min(max(0.1,Gamma),10.0)                                                                    # Sane range, avoid div by zero
    divisor = (input_high==input_low) ? 1 : input_high-input_low                                                # Avoid divide by zero
    try { bpc = clp.BitsPerComponent }  catch(msg) { bpc=8 }                                                    # Use scalef only if bpc > 8 (ie Avs+)
    fclip = (bpc==32) ? "0 1 clip " : ""
    #
    wicked = (bpc>8)
    \  ?     "x " +string(input_low)+" scalef - "+string(divisor)+" scalef / "
    \     +  fclip
    \     +  string(invGam) + " ^ "
    \     +  string(output_high)+" scalef " +string(output_low)+" scalef - * "+string(output_low)+" scalef +"
    \  :     "x " +string(input_low)+" - "+string(divisor)+" / "
    \     +  string(invGam) + " ^ "
    \     +  string(output_high)+" " +string(output_low)+" - * "+string(output_low)+" +"
    # UnComment next line to explicitly round & clamp to output range, although Masktools will do this anyway. 32 bit Float NOT rounded. Here as documentation.
    # wicked = wicked + ((bpc==32) ? " 0 max 255 scalef min" : (bpc>8) ? " round 0 max 255 scalef min" : " round 0 max 255 min")     [* P = min(max(int(P+0.5) , 0.0), 255.0) *]
    return( show_function ? clp.subtitle(wicked) : (bpc>8) ? clp.mt_lut(Yexpr = wicked, use_expr=2, U=2,V=2) : clp.mt_lut(Yexpr = wicked, U=2,V=2) )
}
         
# Gradient
function YlevelsG(clip clp,
\                float "input_low", float "gamma", float "input_high",
\                float "output_low", float "output_high", bool "show_function")
{ 
sisavs26 = !(VersionNumber() < 2.60)
    input_low = Default(input_low, 0)
    gamma = Default(gamma, 1.0)
    input_high = Default(input_high, 255)
    output_low = Default(output_low, 0)
    output_high = Default(output_high, 255)
    show_function = Default(show_function, false)	
    
    wicked = gamma > 1.0 ?
    \      sisavs26 ? "x " +string(input_low)+ " scalef - " +string(input_high)+ " scalef " +string(input_low)+ " scalef - / 0 1 clip 1 " +string(gamma)+
    \        " / ^ " +string(output_high)+ " scalef " +string(output_low)+ " scalef - * " +string(output_low)+ " scalef + x * x range_max x - * + range_max /"
	\                   : "x " +string(input_low)+ " - " +string(input_high)+ " " +string(input_low)+ " - / 1 " +string(gamma)+
    \        " / ^ " +string(output_high)+ " " +string(output_low)+ " - * " +string(output_low)+ " + x * x 255 x - * + 255 /"
    \    : sisavs26 ? "x " +string(input_low)+ " scalef - " +string(input_high)+ " scalef " +string(input_low)+ " scalef - / 1 " +string(gamma)+
    \        " / ^ " +string(output_high)+ " scalef " +string(output_low)+ " scalef - * " +string(output_low)+ " scalef + range_max x - * x x * + range_max /"
	\                   : "x " +string(input_low)+ " - " +string(input_high)+ " " +string(input_low)+ " - / 1 " +string(gamma)+
    \        " / ^ " +string(output_high)+ " " +string(output_low)+ " - * " +string(output_low)+ " + 255 x - * x x * + 255 /"
    
    return( show_function ? clp.subtitle(wicked) : sisavs26 ? clp.mt_lut(Yexpr = wicked, use_expr=2, U=2,V=2) : clp.mt_lut(Yexpr = wicked, U=2,V=2) )  
}

# Sine
function YlevelsS(clip clp,
\                float "input_low", float "gamma", float "input_high",
\                float "output_low", float "output_high", bool "show_function")
{ 
sisavs26 = !(VersionNumber() < 2.60)
    input_low = Default(input_low, 0)
    gamma = Default(gamma, 1.0)
    input_high = Default(input_high, 255)
    output_low = Default(output_low, 0)
    output_high = Default(output_high, 255)
    show_function = Default(show_function, false)
    
    wicked="x " +string(input_low)+ " - " +string(input_high)+ " " +string(input_low)+ " - / 0 1 clip 1 " +string(gamma)+
    \      " / ^ " +string(output_high)+ " " +string(output_low)+ " - * " +string(output_low)+ " + x 162.97466 /" +
    \      " sin 255 * * x 255 x 162.97466 / sin 255 * - * + 255 /"
    
    return( show_function ? clp.subtitle(wicked) : sisavs26 ? clp.mt_lut(Yexpr = wicked, scale_inputs="allf", use_expr=2, U=2,V=2) : clp.mt_lut(Yexpr = wicked, U=2,V=2) )  
}

# Cosine
function YlevelsC(clip clp,
\                int "input_low", float "gamma", int "input_high",
\                int "output_low", int "output_high", bool "show_function")
{ 
sisavs26 = !(VersionNumber() < 2.60)
    input_low = Default(input_low, 0)
    gamma = Default(gamma, 1.0)
    input_high = Default(input_high, 255)
    output_low = Default(output_low, 0)
    output_high = Default(output_high, 255)
    show_function = Default(show_function, false)
    
    wicked="x " +string(input_low)+ " - "+ string(input_high)+ " " +string(input_low)+ " - / 0 1 clip 1 "+string(gamma)+
    \      " / ^ " +string(output_high)+ " " +string(output_low)+ " - * " +string(output_low)+ " + 255 x 162.97466" +
    \      " / cos 255 * - * x x 162.97466 / cos 255 * * + 255 /"
    
    return( show_function ? clp.subtitle(wicked) : sisavs26 ? clp.mt_lut(Yexpr = wicked, scale_inputs="allf", use_expr=2, U=2,V=2) : clp.mt_lut(Yexpr = wicked, U=2,V=2) )  
}

