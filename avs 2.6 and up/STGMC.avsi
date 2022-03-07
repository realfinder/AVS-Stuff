#-------------------------------------------------------------------#
#                                                                   #
#                           STGMC 3.387                             #
#                       it need QTGMC 3.383                         #
#                                                                   #
#-------------------------------------------------------------------#

function STGMC( clip Input, string "Preset", int "TR0", int "TR1", int "TR2", int "Rep0", int "Rep1", int "Rep2", string "EdiMode", bool "RepChroma", \
                    int "NNSize", int "NNeurons", int "EdiQual", int "EdiMaxD", string "ChromaEdi", int "EdiThreads", clip "EdiExt", float "Sharpness", \
                    int "SMode", int "SLMode", int "SLRad", int "SOvs", float "SVThin", int "Sbb", int "SrchClipPP", int "SubPel", int "SubPelInterp", \
                    int "BlockSize", int "Overlap", int "Search", int "SearchParam", int "PelSearch", bool "ChromaMotion", bool "TrueMotion", int "Lambda", \
                    int "LSAD", int "PNew", int "PLevel", bool "GlobalMotion", int "DCT", int "ThSAD1", int "ThSAD2", int "ThSCD1", int "ThSCD2", \
                    int "SourceMatch", string "MatchPreset", string "MatchEdi", string "MatchPreset2", string "MatchEdi2", int "MatchTR2", \
                    float "MatchEnhance", int "Lossless", int "NoiseProcess", float "EZDenoise", float "EZKeepGrain", string "NoisePreset", string "Denoiser", \
                    int "FftThreads", bool "DenoiseMC", int "NoiseTR", float "Sigma", bool "ChromaNoise", val "ShowNoise", float "GrainRestore", \
                    float "NoiseRestore", string "NoiseDeint", bool "StabilizeNoise", int "InputType", float "ProgSADMask", int "FPSDivisor", \
                    int "ShutterBlur", float "ShutterAngleSrc", float "ShutterAngleOut", int "SBlurLimit", bool "Border", bool "Precise", string "Tuning", \
                    bool "ShowSettings", string "GlobalNames", string "PrevGlobals", int "ForceTR", \
                    val "BT", val "DetailRestore", val "MotionBlur", val "MBlurLimit", val "NoiseBypass", float "Str", float "Amp", bool "TV_range", int "UseEdiExt", int "DftDither", bool "lsbd", bool "lsb", bool "n16", bool "keep_tv_range", String "device_type", int "device_id", bool "n16d", bool "FastMA", bool "ESearchP", bool "Refinemotion" )
{
    TV_range      = default( TV_range, !(Isrgb(input)))
QTGMC( Input, Preset, TR0, TR1, TR2, Rep0, Rep1, Rep2, EdiMode, RepChroma, \
                    NNSize, NNeurons, EdiQual, EdiMaxD, ChromaEdi, EdiThreads, EdiExt, Sharpness, \
                    SMode, SLMode, SLRad, SOvs, SVThin, Sbb, SrchClipPP, SubPel, SubPelInterp, \
                    BlockSize, Overlap, Search, SearchParam, PelSearch, ChromaMotion, TrueMotion, Lambda, \
                    LSAD, PNew, PLevel, GlobalMotion, DCT, ThSAD1, ThSAD2, ThSCD1, ThSCD2, \
                    SourceMatch, MatchPreset, MatchEdi, MatchPreset2, MatchEdi2, MatchTR2, \
                    MatchEnhance, Lossless, NoiseProcess, EZDenoise, EZKeepGrain, NoisePreset, Denoiser, \
                    FftThreads, DenoiseMC, NoiseTR, Sigma, ChromaNoise, ShowNoise, GrainRestore, \
                    NoiseRestore, NoiseDeint, StabilizeNoise, InputType, ProgSADMask, FPSDivisor, \
                    ShutterBlur, ShutterAngleSrc, ShutterAngleOut, SBlurLimit, Border, Precise, Tuning, \
                    ShowSettings, GlobalNames, PrevGlobals, ForceTR, \
                    BT, DetailRestore, MotionBlur, MBlurLimit, NoiseBypass, Str, Amp, TV_range, UseEdiExt, DftDither, lsbd, lsb, n16, keep_tv_range, device_type, device_id, n16d, FastMA, ESearchP, Refinemotion )
}