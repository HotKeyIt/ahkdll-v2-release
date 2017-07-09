;
; File encoding:  UTF-8
;

; Based on code from SciTEDebug.ahk
AHKType(exeName)
{
	if !vert:=FileGetVersion(exeName)
		return "FAIL"
	
	vert := StrSplit(vert, ".")
	vert := vert.4 | (vert.3 << 8) | (vert.2 << 16) | (vert.1 << 24)
	
	if (0x014C != exeMachine := GetExeMachine(exeName)) && (exeMachine != 0x8664)
		return "FAIL"
	
	if !(VersionInfoSize := DllCall("version\GetFileVersionInfoSize", "str", exeName, "uint*", null, "uint"))
		return "FAIL"
	
	VarSetCapacity(VersionInfo, VersionInfoSize)
	if !DllCall("version\GetFileVersionInfo", "str", exeName, "uint", 0, "uint", VersionInfoSize, "ptr", &VersionInfo)
		return "FAIL"
	
	if !DllCall("version\VerQueryValue", "ptr", &VersionInfo, "str", "\VarFileInfo\Translation", "ptr*", lpTranslate, "uint*", cbTranslate)
		return "FAIL"
	
	id := SubStr("0000" SubStr(format("0x{1:X}",NumGet(lpTranslate+0, "UShort")), 3), -4, 4) 
		. SubStr("0000" SubStr(format("0x{1:X}",NumGet(lpTranslate+2, "UShort")), 3), -4, 4)
	
	if !DllCall("version\VerQueryValue", "ptr", &VersionInfo, "str", "\StringFileInfo\" id "\ProductName", "ptr*", pField, "uint*", cbField)
		return "FAIL"
	
	; Check it is actually an AutoHotkey executable
	if !InStr(name:=StrGet(pField, cbField), "AutoHotkey") && !InStr(name,"Ahk2Exe")
		return "FAIL"
	
	; We're dealing with a legacy version if it's prior to v1.1
	return vert >= 0x01010000 ? "Modern" : "Legacy"
}
