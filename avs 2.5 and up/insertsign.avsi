# fixed ver. to deal with HD video correctly v.1.38 mod by AmjadSONY

function insertsign(clip mainclip, clip overlayclip, int startframe, int "endframe", int "xoffset", int "yoffset", clip "External") {
	# make the endframe parameter optional (defaulting to where the overlay clip ends)
	endframe = default(endframe,startframe+overlayclip.framecount-1)
	endframe = (endframe == 0) ? startframe+overlayclip.framecount()-1 : endframe
	endframe = (endframe >= mainclip.framecount()-1) ? mainclip.framecount()-1 : endframe
	
	# make sure the special case startframe=1 is dealt with correctly
	# (needed because trim(0,0) returns the entire clip, which is obviously not what we want)
	# note that the first frame of the clip is ZER0, _not_ one!
	begin	= (startframe == 1) ? mainclip.trim(0,-1) : mainclip.trim(0,startframe-1)
	middle	= mainclip.trim(startframe,endframe)
	end	= (endframe == mainclip.framecount()-1) ? blankclip(mainclip,length=0) : mainclip.trim(endframe+1,0)
	
	sisphbd = AvsPlusVersionNumber > 2294
	shasalp = sisphbd ? middle.IsRGB64() || middle.IsRGB32() : middle.IsRGB32()
	middleoverlay = shasalp ? Layer(middle,overlayclip, "add", x=xoffset, y=yoffset) : Overlay(middle, defined(External) ? External : overlayclip.IsRGB() && !(middle.IsRGB()) ? (VersionNumber() < 2.60) ? \
	(mainclip.height() < 600) ?  overlayclip.ConvertToYV12() : overlayclip.ConvertToYV12(matrix="Rec709") : \
	(mainclip.height() < 600) ?  sisphbd ? overlayclip.ConvertToYUV444() : overlayclip.ConvertToYV24() : sisphbd ? overlayclip.ConvertToYUV444(matrix=mainclip.BitsPerComponent() > 8 && mainclip.width() > 1440 ? "rec2020" : "Rec709") : overlayclip.ConvertToYV24(matrix="Rec709") : overlayclip, mask=overlayclip.showalpha(), x=xoffset, y=yoffset)
	
	# deal with the special case startframe=0 (in which case we don't have anything before the overlay)
	# note that trim(-1,0) does nothing (it returns the same as trim(0,0)...)
	
	final = (startframe == 0) ? middleoverlay ++ end : begin ++ middleoverlay ++ end
	return final
}

# insert_types 1.00 for avs by A.SONY
# need RT_Stats, and in non plus avs it also need GSCript
Function insert_types(clip clp, string "dir", string "container", string "sourcecall") {

Assert(Defined(dir), "insert_types: you must set the dir")

WildCard=Default(container,"*.AVI")
sourcecall=Default(sourcecall,"ffms2")

	clp
    TMPFile="~AVIVid.TMP"
    scstr= """
        eS=RightStr(dir,1)
        Path=(eS!="\" && eS!="/") ? dir+"\" : dir                   # Ensure End Slash
        TestPath=LeftStr(Path,Strlen(Path)-1)                       # Test PATH Exist without End Slash, else Error
        Assert(Exist(TestPath),"insert_types: Path Does not exist ("+Path+")")
        SearchString = Path + WildCard
        Got = RT_WriteFileList(SearchString,TMPFile)
        while(Got > 0) {
            SS=RT_ReadTxtFromFile(TMPFile)                          # Read multiline list of filenames
            got=Got-1
                S=RT_TxtGetLine(SS,Got)
				fi=FindStr(s,"_")
				fr=s.MidStr(fi+1).Value.Int
                last.insertsign(eval(sourcecall+string("(s)")),fr)
        }
        RT_FileDelete(TMPFile)
    """
    IsAvsPlus ? eval(scstr) : GSCript(scstr)
    return last
}