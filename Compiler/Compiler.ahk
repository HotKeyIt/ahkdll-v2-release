#Include ScriptParser.ahk
#Include IconChanger.ahk
#Include Directives.ahk

AhkCompile(ByRef AhkFile, ExeFile := "", ByRef CustomIcon := "", BinFile := "", UseMPRESS := "",UseCompression := "", UseInclude := "", UseIncludeResource := "", UsePassword := "AutoHotkey")
{
	global ExeFileTmp
	AhkFile := Util_GetFullPath(AhkFile)
	if (AhkFile = "")
		Util_Error("Error: Source file not specified.")
	SplitPath,% AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
	
	if (ExeFile = "")
		ExeFile := AhkFile_Dir "\" AhkFile_NameNoExt ".exe"
	else
		ExeFile := Util_GetFullPath(ExeFile)
	
	ExeFileTmp := ExeFile
	
	if (BinFile = "")
		BinFile := A_ScriptDir "\AutoHotkeySC.bin"
	SetCursor(LoadCursor(0, 32514)) ; Util_DisplayHourglass()
	FileCopy, %BinFile%, %ExeFile%, 1
	if ErrorLevel
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
	
	BundleAhkScript(ExeFile, AhkFile, CustomIcon, UseCompression, UsePassword)
	
	if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
	{
		If !CLIMode,	SB_SetText("Compressing final executable...")
		if UseCompression ; do not compress resources
			RunWait, "%A_ScriptDir%\mpress.exe" -q -x -r "%ExeFile%",, Hide
		else RunWait, "%A_ScriptDir%\mpress.exe" -q -x "%ExeFile%",, Hide
	}
	
	SetCursor(LoadCursor(0, 32512)) ; Util_HideHourglass()
	If !CLIMode,	SB_SetText("")
}

BundleAhkScript(ExeFile, AhkFile, IcoFile := "", UseCompression := 0, UsePassword := "")
{
	SplitPath,% AhkFile,, ScriptDir
	
	ExtraFiles := []
	,Directives := PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	,ScriptBody :=Trim(ScriptBody,"`n")
	;StrReplace,ScriptBody,%ScriptBody%,`n,`r`n
	VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
	StrPut(ScriptBody, &BinScriptBody, "UTF-8")
	If UseCompression {
		If !BinScriptBody_Len:=ZipFileRaw(&BinScriptBody,BinScriptBody_Len "|" A_Temp "\Ahk2Exe_compress_script.bin",UsePassword)
			Util_Error("Error: Could not compress the source file to: " A_Temp "\Ahk2Exe_compress_script.bin")
		FileRead,BinScriptBody,% "*c " A_Temp "\Ahk2Exe_compress_script.bin"
		FileDelete % A_Temp "\Ahk2Exe_compress_script.bin"
	}
	
	module := BeginUpdateResource(ExeFile)
	if !module
		Util_Error("Error: Error opening the destination file.")
	
	tempWD := new CTempWD(ScriptDir)
	dirState := ProcessDirectives(ExeFile, module, Directives, IcoFile, UseCompression, UsePassword)
	IcoFile := dirState.IcoFile
	
	if outPreproc := dirState.OutPreproc
	{
		f := FileOpen(outPreproc, "w", "UTF-8-RAW")
		f.RawWrite(BinScriptBody, BinScriptBody_Len)
		f := ""
	}
	
	scriptResName := (!dirState.NoAhkWithIcon && IcoFile) ? ">AHK WITH ICON<" : ">AUTOHOTKEY SCRIPT<"
	
	If !CLIMode,	SB_SetText("Adding: Master Script")
	if !UpdateResource(module, 10, scriptResName, 0x409, &BinScriptBody, BinScriptBody_Len)
		goto _FailEnd
		
	for each,file in ExtraFiles
	{
		If !CLIMode,	SB_SetText("Adding: " file)
		StrUpper, resname, %file%
		
		If !FileExist(file)
			goto _FailEnd2
		If UseCompression
			filesize:=ZipFileRaw(file,A_Temp "\Ahk2Exe_compress_script.bin")
		else FileGetSize,filesize,%file%
		; This "old-school" method of reading binary files is way faster than using file objects.
		VarSetCapacity(filedata, filesize)
		If UseCompression {
			FileRead, filedata,% "*c " A_Temp "\Ahk2Exe_compress_script.bin"
			FileDelete % A_Temp "\Ahk2Exe_compress_script.bin"
		} else FileRead, filedata,*c %file%
		
		if !UpdateResource(module, 10, resname, 0x409, &filedata, filesize)
			goto _FailEnd2
	}
	VarSetCapacity(filedata, 0)
	
	gosub _EndUpdateResource
	
	if dirState.ConsoleSubsys
	{
		If !CLIMode,	SB_SetText("Marking executable as a console application...")
		if !SetExeSubsystem(ExeFile, 3)
			Util_Error("Could not change executable subsystem!")
	}
	
	for each,cmd in dirState.PostExec
	{
		If !CLIMode,	SB_SetText("PostExec: " cmd)
		RunWait, % cmd,, UseErrorLevel
		if (ErrorLevel != 0)
			Util_Error("Command failed with RC=" ErrorLevel ":`n" cmd)
	}
	
	
	return
	
_FailEnd:
	gosub _EndUpdateResource
	Util_Error("Error adding script file:`n`n" AhkFile)
	
_FailEnd2:
	gosub _EndUpdateResource
	Util_Error("Error adding FileInstall file:`n`n" file)
	
_EndUpdateResource:
	if !EndUpdateResource(module)
		Util_Error("Error: Error opening the destination file.")
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

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	return GetFullPathName(path, 260, fullpath, 0) ? (VarSetCapacity(fullpath,-1),fullpath) : ""
}
