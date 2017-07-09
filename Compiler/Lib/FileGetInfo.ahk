;~ MsgBox % FileGetInfo(A_AhkPath,"FILEVERSION")
FileGetInfo( peFile:="", p*) {   ; Written by SKAN, modified by HotKeyIt
 ; www.autohotkey.com/forum/viewtopic.php?p=233188#233188  CD:24-Nov-2008 / LM:27-Oct-2010
 static DLL:="Version\GetFileVersion"
 If ! FSz := DllCall( DLL "InfoSizeW", "Str",peFile, "UInt",0 )
   Return (DllCall( "SetLastError", UInt,1 ),"")
 VarSetCapacity( FVI, FSz, 0 ),DllCall( DLL "InfoW", "Str",peFile, "UInt",0, "UInt",FSz, "PTR",&FVI )
 If !DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str","\VarFileInfo\Translation", "PTR*",Transl, "PTR",0 )
   Return (DllCall( "SetLastError", UInt,2 ),"")
 If !Trans:=format("{1:.8X}",NumGet(Transl+0,"UInt"))
   Return (DllCall( "SetLastError", UInt,3),"")
 for k,v in p
 { subBlock := "\StringFileInfo\" SubStr(Trans,-4) SubStr(Trans,1,4) "\" v
   If ! DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str",SubBlock, "PTR*",InfoPtr, "UInt",0 )
     continue
   If Value := StrGet( InfoPtr )
    Info .= p.Length()=1?Value:SubStr( v "                        ",1,24 ) . A_Tab . Value . "`n"
 } Info:=RTrim(Info,"`n")
Return Info
}