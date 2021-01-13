;
; File encoding:  UTF-8 with BOM
;
#Include ScriptParser.ahk
#Include IconChanger.ahk
#Include Directives.ahk

AhkCompile(ByRef AhkFile, ExeFile := "", ByRef CustomIcon := "", BinFile := "", UseMPRESS := "", fileCP:="", UseCompression := "", UseInclude := "", UseIncludeResource := "", UsePassword := "AutoHotkey")
{
	global ExeFileTmp, ExeFileG

	SetWorkingDir %AhkWorkingDir%
	SplitPath AhkFile,, Ahk_Dir,, Ahk_Name
	SplitPath ExeFile,, Edir,,    Ename
	ExeFile := (Edir ? Edir : Ahk_Dir) "\" (xe:= Ename ? Ename : Ahk_Name ) ".exe"
	ExeFile := Util_GetFullPath(ExeFile)
	if (CustomIcon != "")
	{	SplitPath CustomIcon,, Idir,, Iname
		CustomIcon := (Idir ? Idir : Ahk_Dir) "\" (Iname ? Iname : Ahk_Name ) ".ico"
		CustomIcon := Util_GetFullPath(CustomIcon)
	}
	SetWorkingDir %Ahk_Dir%             ; Initial folder for any #Include's

	; Get temp file name - remove any invalid "path/" from exe name (/ should be \)
	ExeFileTmp := Util_TempFile(, "exe~", RegExReplace(xe,"^.*/"))
	
	if BinFile =
		BinFile = %A_ScriptDir%\AutoHotkeySC.bin
	
	Util_DisplayHourglass()
	
	IfNotExist, %BinFile%
		Util_Error("Error: The selected AutoHotkeySC binary does not exist. (C1)"
		, 0x34, """" BinFile """")
	
	try FileCopy, %BinFile%, %ExeFileTmp%, 1
	catch
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination."
		, 0x41, """" ExeFileTmp """")

	DerefIncludeVars.Delete("U_", "V_")         ; Clear Directives entries
	DerefIncludeVars.Delete("A_WorkFileName")
	DerefIncludeVars.Delete("A_PriorLine")

	BinType := AHKType(ExeFileTmp)
	DerefIncludeVars.A_AhkVersion := BinType.Version
	DerefIncludeVars.A_PtrSize := BinType.PtrSize
	DerefIncludeVars.A_IsUnicode := BinType.IsUnicode

	ExeFileG := ExeFile
	BundleAhkScript(ExeFileTmp, AhkFile, UseMPRESS, CustomIcon, fileCP, UseCompression, UsePassword)
	; the final step...
	Util_Status("Moving .exe to destination")

	Loop
	{	FileMove, %ExeFileTmp%, %ExeFileG%, 1
		if !ErrorLevel
			break
		Util_HideHourglass()
		DetectHiddenWindows On
		if !WinExist("ahk_exe " ExeFileG)
			Util_Error("Error: Could not move final compiled binary file to "
			. "destination. (C1)", 0x45, """" ExeFileG """")
		else
		{	SetTimer Buttons, 50
			wk := """" RegExReplace(ExeFileG, "^.+\\") """"
			MsgBox 51,Ahk2Exe Query,% "Warning: " wk " is still running, "
			.  "and needs to be unloaded to allow replacement with this new version."
			. "`n`n Press the appropriate button to continue."
			. " ('Reload' unloads and reloads the new " wk " without any parameters.)"
			IfMsgBox Cancel
				Util_Error("Error: Could not move final compiled binary file to "
				. "destination. (C2)", 0x45, """" ExeFileG """")
			WinClose     ahk_exe %ExeFileG%
			WinWaitClose ahk_exe %ExeFileG%,,1
			IfMsgBox No
				Reload := 1
	}	}
	if Reload
		run "%ExeFileG%", %ExeFileG%\..
	Util_HideHourglass()
	Util_Status("")
}

Buttons()
{	IfWinNotExist Ahk2Exe Query
		return
	SetTimer,, Off
	WinActivate
	ControlSetText Button1, &Unload
	ControlSetText Button2, && &Reload
}

BundleAhkScript(ExeFile, AhkFile, UseMPRESS, IcoFile="", fileCP="", UseCompression := 0, UsePassword := "")
{
  global AhkPath := UseAhkPath
  if (AhkPath = "")
    AhkPath := SubStr(BinFile,"SC.bin") ? SubStr(BinFile,1,-5) ".exe" ? BinFile
   
	if fileCP is space
		if SubStr(DerefIncludeVars.A_AhkVersion,1,1) = 2
			fileCP := "UTF-8"           ; Default for v2 is UTF-8
		else fileCP := A_FileEncoding
	
	try FileEncoding, %fileCP%
	catch e
		Util_Error("Error: Invalid codepage parameter """ fileCP """ was given.", 0x53)
	
	SplitPath, AhkFile,, ScriptDir

	ExtraFiles := []
	,Directives := PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	,ScriptBody :=Trim(ScriptBody,"`n")
	If UseCompression {
    FileDelete, %A_AhkDir%\BinScriptBody.ahk
    FileAppend, %ScriptBody%, %A_AhkDir%\BinScriptBody.ahk
    If SubStr(DerefIncludeVars.A_AhkVersion,1,1) = 2
      PID:=DynaRun("
      (
        UsePassword:=''
        buf:=BufferAlloc(bufsz:=10485760,00),totalsz:=0,buf1:=BufferAlloc(10485760)
        Loop Read, '" A_AhkDir "\BinScriptBody.ahk'
        {
          If (A_LoopReadLine=''){
            NumPut('Char', 10, buf.Ptr + totalsz)
            ,totalsz+=1
            continue
          }
          data:=StrBuf(A_LoopReadLine,'UTF-8')
          ,zip:=UsePassword?ZipRawMemory(data,, '" UsePassword "' ):ZipRawMemory(data)
          ,CryptBinaryToStringA(zip, zip.size, 0x1|0x40000000, 0, getvar(cryptedsz:=0))
          ,tosavesz:=cryptedsz
          ,CryptBinaryToStringA(zip, zip.size, 0x1|0x40000000, buf1, getvar(cryptedsz))
          ,NumPut('Char', 10, buf1.Ptr+cryptedsz)
          if (totalsz+tosavesz>bufsz)
            newbuf:=BufferAlloc(bufsz*=2),RtlMoveMemory(newbuf,buf,totalsz),buf:=newbuf
          RtlMoveMemory(buf.Ptr + totalsz,buf1,tosavesz)
          ,totalsz+=tosavesz
        }
        NumPut('Char', 0, buf.Ptr + totalsz - 1)
        If !BinScriptBody := ZipRawMemory(buf.Ptr,totalsz,'" UsePassword "')
          ExitApp
        f:=FileOpen(A_AhkDir '\..\BinScriptBody.bin','w -rwd'),f.RawWrite(BinScriptBody),f.Close()
      )","BinScriptBody","",A_AhkDir "\v2\AutoHotkeyU.exe")
    else
      PID:=DynaRun("
      (
        VarSetCapacity(buf,bufsz:=10485760,00),totalsz:=0,VarSetCapacity(buf1,10485760)
        Loop, Read, " A_AhkDir "\BinScriptBody.ahk
        {
          If (A_LoopReadLine=""""){
            NumPut(10, &buf, totalsz,""Char"")
            ,totalsz+=1
            continue
          }
          len:=StrPutVar(A_LoopReadLine,data,""UTF-8"")
          ,sz:=ZipRawMemory(&data, len, zip, """ UsePassword """)
          ,DllCall(""crypt32\CryptBinaryToStringA"",""PTR"", &zip,""UInt"", sz,""UInt"", 0x1|0x40000000,""UInt"", 0,""UIntP"", cryptedsz:=0)
          ,tosavesz:=cryptedsz
          ,DllCall(""crypt32\CryptBinaryToStringA"",""PTR"", &zip,""UInt"", sz,""UInt"", 0x1|0x40000000,""PTR"", &buf1,""UIntP"", cryptedsz)
          ,NumPut(10,&buf1,cryptedsz,""Char"")
          if (totalsz+tosavesz>bufsz)
            VarSetCapacity(buf,bufsz*=2)
          RtlMoveMemory((&buf) + totalsz,&buf1,tosavesz)
          ,totalsz+=tosavesz
        }
        NumPut(0,&buf,totalsz-1,""Char"")
        If !BinScriptBody_Len := ZipRawMemory(&buf,totalsz,BinScriptBody,""" UsePassword """)
          ExitApp
        f:=FileOpen(A_AhkDir ""\BinScriptBody.bin"",""w -rwd""),f.RawWrite(&BinScriptBody,BinScriptBody_Len),f.Close()
      )","BinScriptBody","",DerefIncludeVars.A_IsUnicode ? A_AhkDir "\AutoHotkeyU.exe" : A_AhkDir "\AutoHotkeyA.exe")
    Loop {
      Process, Exist, %PID%
    } Until (!ErrorLevel)
    FileRead,BinScriptBody, *c %A_AhkDir%\BinScriptBody.bin
    FileGetSize, BinScriptBody_Len, %A_AhkDir%\BinScriptBody.bin
    FileDelete, %A_AhkDir%\BinScriptBody.ahk
    FileDelete, %A_AhkDir%\BinScriptBody.bin
	} else
    VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
    ,StrPut(ScriptBody, &BinScriptBody, "UTF-8")
	
	module := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
	if !module
		Util_Error("Error: Error opening the destination file. (C1)", 0x31)
	
	SetWorkingDir % ScriptDir

	DerefIncludeVars.A_WorkFileName := ExeFile
	dirState := ProcessDirectives(ExeFile, module, Directives, IcoFile, UseCompression, UsePassword)
	IcoFile := dirState.IcoFile
	
	if outPreproc := dirState.OutPreproc
	{
		f := FileOpen(outPreproc, "w", "UTF-8-RAW")
		f.RawWrite(BinScriptBody, BinScriptBody_Len)
    f.Close()
		f := ""
	}
	
	Util_Status("Adding: Master Script")
	if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", "E4847ED08866458F8DD35F94B37001C0"
	          , "ushort", 0x409, "ptr", &BinScriptBody, "uint", BinScriptBody_Len, "uint")
		goto _FailEnd
		
	for each,file in ExtraFiles
	{
		Util_Status("Adding: " file)
		StringUpper, resname, file
		
		IfNotExist, %file%
			goto _FailEnd2
		If UseCompression{
			FileRead, tempdata, *c %file%
			FileGetSize, tempsize, %file%
			If !filesize := ZipRawMemory(&tempdata, tempsize, filedata)
				Util_Error("Error: Could not compress the file to: " file, 0x43)
		} else {
			FileRead, filedata, *c %file%
			FileGetSize, filesize, %file%
		}
		
		if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", resname
				  , "ushort", 0x409, "ptr", &filedata, "uint", filesize, "uint")
			goto _FailEnd2
		VarSetCapacity(filedata, 0)
	}
	
	gosub _EndUpdateResource
	
	if dirState.ConsoleApp
	{
		Util_Status("Marking executable as a console application...")
		if !SetExeSubsystem(ExeFile, 3)
			Util_Error("Could not change executable subsystem!", 0x61)
	}
	SetWorkingDir %A_ScriptDir%
	
	RunPostExec(dirState)
	
	for k,v in [{MPRESS:"-x"},{UPX:"--all-methods --compress-icons=0"}][UseMPRESS]
	{	Util_Status("Compressing final executable with " k " ...")
		if FileExist(wk := A_ScriptDir "\" k ".exe")
			RunWait % """" wk """ -q " v " """ ExeFile """",, Hide
		else Util_Error("Warning: """ wk """ not found.`n`n'Compress exe with " k
			. "' specified, but freeware " k ".EXE is not in compiler directory.",0)
			, UseMPRESS := 9
	}
	RunPostExec(dirState, UseMPRESS)
	
	return                             ; BundleAhkScript() exits here
	
_FailEnd:
	gosub _EndUpdateResource
	Util_Error("Error adding script file:`n`n" AhkFile, 0x43)
	
_FailEnd2:
	gosub _EndUpdateResource
	Util_Error("Error adding FileInstall file:`n`n" file, 0x44)
	
_EndUpdateResource:
	if !DllCall("EndUpdateResource", "ptr", module, "uint", 0)
	{	Util_Error("Error: Error opening the destination file. (C2)", 0
		,,"This error may be caused by your anti-virus checker.`n"
		. "Press 'OK' to try again, or 'Cancel' to abandon.")
		goto _EndUpdateResource
	}
	return
}

class CTempWD
{
	__New(newWD)
	{
		this.oldWD := A_WorkingDir
		SetWorkingDir % newWD
	}
	__Delete()
	{
		SetWorkingDir % this.oldWD
	}
}

RunPostExec(dirState, UseMPRESS := "")
{	for k, v in dirState["PostExec" UseMPRESS]
	{	Util_Status("PostExec" UseMPRESS ": " v.1)
		RunWait % v.1, % v.2 ? v.2 : A_ScriptDir, % "UseErrorLevel " (v.3?"Hide":"")
		if (ErrorLevel != 0 && !v.4)
			Util_Error("Command failed with RC=" ErrorLevel ":`n" v.1, 0x62)
}	}

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	return DllCall("GetFullPathName", "str", path, "uint", 260, "str", fullpath, "ptr", 0, "uint") ? fullpath : ""
}
