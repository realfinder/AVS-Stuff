# AnimeIVTC_helper by A.SONY v1.4
# and put tcomb before IVTC filter the source has Rainbow and/or Dot Crawl Removal will help, and if it was yuy2 convert it to yv12 will help too, or convert it to y8 (luma only), because the chroma noise may destroy IVTC filter accuracy in some frames 

function AnimeIVTC_helper(clip input, bool "Fieldsorderconvert", bool "iaa", bool "aachroma") {
foc	= default ( Fieldsorderconvert,        true  )
iaa	= default ( iaa,        false  )
chroma	= default ( aachroma,        false  )

Assert(!(!foc && !iaa), "why do you use AnimeIVTC_helper then?!")

return foc && !iaa ? input.convert_Fields_scan_order : !foc && iaa ? input.interlaced_aa(chroma=chroma) : \
foc && iaa ? input.convert_Fields_scan_order.interlaced_aa(chroma=chroma) : nop()
}


#############################

# Unnoticeable Anti-aliasing for interlaced source

    FUNCTION interlaced_aa(clip c1, bool "chroma") {
sisphbd = AvsPlusVersionNumber > 2294
sislumaonly = sisphbd ? c1.isy() : VersionNumber() < 2.6 ? true : c1.isy8()
chroma	= default ( chroma,        false  )
aai = VersionNumber() < 2.60 ? c1.ConvertToYV12(interlaced=true).DoubleWeave().SangNom2(order=0) : chroma && Isyuy2(c1) ? c1.ConvertToYV16().DoubleWeave().SangNom2(order=0,aac=48) : \
!chroma && !sislumaonly ? sisphbd ? c1.ConvertToY().DoubleWeave().SangNom2(order=0) : c1.ConvertToY8().DoubleWeave().SangNom2(order=0) : c1.DoubleWeave().SangNom2(order=0,aac=48)
newiaaluma = aai.maa2(mask=0,maskt=0,ss=3,ss_h=1,chroma=chroma).interlaced60or50(bff=!(c1.getparity()))
return VersionNumber() < 2.60 ? YToUV(c1.utoy(), c1.vtoy(), Isyuy2(c1) ? newiaaluma.ConvertToYUY2() : newiaaluma) : Isyuy2(c1) && chroma ? newiaaluma.ConvertToYuy2() : !chroma && !sislumaonly ? YToUV(sisphbd ? c1.ExtractU() : c1.utoy8(), sisphbd ? c1.ExtractV() : c1.vtoy8(), newiaaluma) : newiaaluma
}