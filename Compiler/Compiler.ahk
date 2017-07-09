#Include ScriptParser.ahk
#Include IconChanger.ahk
#Include Directives.ahk

AhkCompile(ByRef AhkFile, ExeFile := "", ByRef CustomIcon := "", BinFile := "", UseMPRESS := "",UseCompression := "", UseInclude := "", UseIncludeResource := "", UsePassword := "AutoHotkey")
{
	global ExeFileTmp, GuiStatusBar
	AhkFile := Util_GetFullPath(AhkFile)
	if (AhkFile = "")
		Util_Error("Error: Source file not specified.")
	SplitPath AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
	
	if (ExeFile = "")
		ExeFile := AhkFile_Dir "\" AhkFile_NameNoExt ".exe"
	else
		ExeFile := Util_GetFullPath(ExeFile)
	
	ExeFileTmp := ExeFile
	
	if (BinFile = "")
		BinFile := A_ScriptDir "\AutoHotkeySC.bin"
	SetCursor(LoadCursor(0, 32514)) ; Util_DisplayHourglass()
	FileCopy BinFile, ExeFile, 1
	if ErrorLevel
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
	
	BundleAhkScript(ExeFile, AhkFile, CustomIcon, UseCompression, UsePassword)
	
	if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
	{
		If !CLIMode
      GuiStatusBar.SetText("Compressing final executable...")
		if UseCompression ; do not compress resources
			RunWait "`"" A_ScriptDir "\mpress.exe`" -q -x -r `"" ExeFile "`"",, "Hide"
		else RunWait "`"" A_ScriptDir "\mpress.exe`" -q -x `"" ExeFile "`"",, "Hide"
	}
	
	SetCursor(LoadCursor(0, 32512)) ; Util_HideHourglass()
	If !CLIMode
      GuiStatusBar.SetText("")
}

BundleAhkScript(ExeFile, AhkFile, IcoFile := "", UseCompression := 0, UsePassword := "")
{
  global GuiStatusBar
	SplitPath AhkFile,, ScriptDir
	
	ExtraFiles := []
	,Directives := PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	,ScriptBody :=Trim(ScriptBody,"`n")
	,VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
	,StrPut(ScriptBody, &BinScriptBody, "UTF-8")
	If UseCompression {
		VarSetCapacity(buf,bufsz:=65536,00),totalsz:=0,VarSetCapacity(buf1,65536)
		Loop Parse,ScriptBody,"`n","`r"
		{
			If (A_LoopField=""){
				NumPut(10,(&buf) + totalsz, "Char")
				,totalsz+=1
				continue
			}
			len:=StrPutVar(A_LoopField,data,"UTF-8")
			,sz:=ZipRawMemory(&data, len, zip, UsePassword)
			,CryptBinaryToStringA(&zip, sz, 0x1|0x40000000, 0, getvar(cryptedsz:=0))
			,tosavesz:=cryptedsz
			,CryptBinaryToStringA(&zip, sz, 0x1|0x40000000, &buf1, getvar(cryptedsz))
			,NumPut(10,&buf1,cryptedsz,"Char")
			if (totalsz+tosavesz>bufsz)
				VarSetCapacity(buf,bufsz*=2)
			RtlMoveMemory((&buf) + totalsz,&buf1,tosavesz)
			,totalsz+=tosavesz
		}
		NumPut(0,&buf,totalsz-1,"UShort")
		If !BinScriptBody_Len := ZipRawMemory(&buf,totalsz,BinScriptBody,UsePassword)
			Util_Error("Error: Could not compress the source file.")
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
	
	If !CLIMode
      GuiStatusBar.SetText("Adding: Master Script")
	if !UpdateResource(module, 10, "E4847ED08866458F8DD35F94B37001C0", 0x409, &BinScriptBody, BinScriptBody_Len)
		goto _FailEnd
		
	for each,file in ExtraFiles
	{
		If !CLIMode
        GuiStatusBar.SetText("Adding: " file)
		resname:=StrUpper(file)
		
		If !FileExist(file)
			goto _FailEnd2
		If UseCompression{
			tempdata:=FileRead(file,"RAW")
			tempsize:=FileGetSize(file)
			If !filesize := ZipRawMemory(&tempdata, tempsize, filedata)
				Util_Error("Error: Could not compress the file to: " file)
		} else {
			filedata:=FileRead(file,"RAW")
			filesize:=FileGetSize(file)
		}
		
		if !UpdateResource(module, 10, resname, 0x409, &filedata, filesize)
			goto _FailEnd2
	}
	VarSetCapacity(filedata, 0)
	
	gosub _EndUpdateResource
	
	if dirState.ConsoleApp
	{
		If !CLIMode
        GuiStatusBar.SetText("Marking executable as a console application...")
		if !SetExeSubsystem(ExeFile, 3)
			Util_Error("Could not change executable subsystem!")
	}
	
	for each,cmd in dirState.PostExec
	{
		If !CLIMode
        GuiStatusBar.SetText("PostExec: " cmd)
		RunWait cmd,, "UseErrorLevel"
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
		SetWorkingDir newWD
	}
	__Delete()
	{
		SetWorkingDir this.oldWD
	}
}

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	return GetFullPathName(path, 260, fullpath, 0) ? (VarSetCapacity(fullpath,-1),fullpath) : ""
}
