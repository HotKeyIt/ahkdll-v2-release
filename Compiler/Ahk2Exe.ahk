; 
; File encoding:  UTF-8 with BOM
;
; Script description:
;	Ahk2Exe - AutoHotkey Script Compiler
;	Written by fincs - Interface based on the original Ahk2Exe
;
; @Ahk2Exe-Bin             Unicode 32*            ; Commented out
;@Ahk2Exe-SetName         Ahk2Exe
;@Ahk2Exe-SetDescription  AutoHotkey Script Compiler
;@Ahk2Exe-SetCopyright    Copyright (c) since 2004
;@Ahk2Exe-SetCompanyName  AutoHotkey
;@Ahk2Exe-SetOrigFilename Ahk2Exe.ahk
;@Ahk2Exe-SetMainIcon     Ahk2Exe.ico

SendMode Input
SetBatchLines -1
#NoEnv
#NoTrayIcon
#SingleInstance Off

#Include %A_ScriptDir%
#Include Compiler.ahk

If !A_IsCompiled
  Menu,Tray,Icon,%A_ScriptDir%\Ahk2Exe.ico

OnExit("Util_HideHourglass")             ; Reset cursor on exit

CompressCode := {-1:2, 0:-1, 1:-1, 2:-1} ; Valid compress codes (-1 => 2)

global UseAhkPath := "", AhkWorkingDir := A_WorkingDir

; Set default codepage from any installed AHK
ScriptFileCP := A_FileEncoding
RegRead wk, HKCR\\AutoHotkeyScript\Shell\Open\Command
if (wk != "" && RegExMatch(wk, "i)/(CP\d+)", o))
	ScriptFileCP := o1

gosub BuildBinFileList
gosub LoadSettings
gosub ParseCmdLine
if !CustomBinFile
	gosub CheckAutoHotkeySC

if UseMPRESS =
	UseMPRESS := LastUseMPRESS
if IcoFile =
	IcoFile := LastIcon

if CLIMode
{
	gosub ConvertCLI
	ExitApp, 0 ; Success
}

BinFileId := FindBinFile(LastBinFile)

#include *i __debug.ahk

ToolTip:=TT("Parent=1")

Menu, FileMenu, Add, S&ave Script Settings As…`tCtrl+S, SaveAsMenu
Menu, FileMenu, Disable, S&ave Script Settings As…`tCtrl+S
Menu, FileMenu, Add, &Convert, Convert
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, HelpMenu, Add, &Help`tF1, Help
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar,  Add, &File, :FileMenu
Menu, MenuBar,  Add, &Help, :HelpMenu
Gui, Menu, MenuBar

Gui, +LastFound +Resize +MinSize594x390
GuiHwnd := WinExist("")
Gui, Add, Link, x303 y1,
(
©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-2016 fincs
©2012-%A_Year% HotKeyIt
©2019-%A_Year% TAC109
<a href="https://www.autohotkey.com">https://www.autohotkey.com</a>
Note: Compiling does not guarantee source code protection.
)
Gui, Add, Text, x11 y97 w570 h2 +0x1007
Gui, Font, Bold
Gui, Add, GroupBox, x11 y104 w570 h81, Required Parameters
Gui, Font, Normal
Gui, Add, Text, x17 y126, &Source (script file)
Gui, Add, Edit, x137 y121 w315 h23 aw1 +ReadOnly -WantTab vAhkFile, %AhkFile%
ToolTip.Add("Edit1","Select path of AutoHotkey Script to compile")
Gui, Add, Button, x459 y121 w53 h23 ax1 gBrowseAhk, &Browse
ToolTip.Add("Button2","Select path of AutoHotkey Script to compile")
Gui, Add, Text, x17 y155, &Destination (.exe file)
Gui, Add, Edit, x137 y151 w315 h23 awr aw1 +ReadOnly -WantTab vExeFile, %Exefile%
ToolTip.Add("Edit2","Select path to resulting exe / dll")
Gui, Add, Button, x459 y151 w53 h23 axr ax1 gBrowseExe, B&rowse
ToolTip.Add("Button3","Select path to resulting exe / dll")
Gui, Font, Bold
Gui, Add, GroupBox, x11 y187 w570 h148 awr aw1, Optional Parameters
Gui, Font, Normal
Gui, Add, Text, x18 y208, Custom Icon (.ico file)
Gui, Add, Edit, x138 y204 w315 h23 awr aw1 +ReadOnly vIcoFile, %IcoFile%
ToolTip.Add("Edit3","Select Icon to use in resulting exe / dll")
Gui, Add, Button, x461 y204 w53 h23 axr ax1 gBrowseIco, Br&owse
ToolTip.Add("Button5","Select Icon to use in resulting exe / dll")
Gui, Add, Button, x519 y204 w53 h23 axr ax1 gDefaultIco, D&efault
ToolTip.Add("Button6","Use default Icon")
Gui, Add, Text, x18 y237, Base File (.bin)`n`nUse Win32a for ANSI`nand Win32w or x64w`nfor Unicode compilation!
Gui, Add, DDL, x138 y233 w315 h23 R10 awr aw1 AltSubmit vBinFileId Choose%BinFileId%, %BinNames%
ToolTip.Add("ComboBox1","Select AutoHotkey binary file to use for compilation")
Gui, Add, CheckBox, x138 y260 w315 h20 gCheckCompression vUseCompression Checked%LastUseCompression%, Use compression to reduce size of resulting executable
ToolTip.Add("Button7","Compress all resources")
Gui, Add, CheckBox, x138 y282 w230 h20 vUseEncrypt gCheckCompression Checked%LastUseEncrypt%, Encrypt. Enter password used in executable:
ToolTip.Add("Button8","Use AES encryption for resources (requires a Password)")
Gui, Add, Edit,x370 y282 w85 h20 awr aw1 Password vUsePassword,AutoHotkey
ToolTip.Add("Edit4","Enter password for encryption (default = AutoHotkey).`nAutoHotkey binary must be using this password internally")
Gui, Add, DDL,% "x138 y304 w75 AltSubmit gCompress vUseMPress Choose" UseMPRESS+1, (none)|MPRESS|UPX
ToolTip.Add("ComboBox2","Makes executables smaller and decreases start time when loaded from slow media")
Gui, Add, Button, x235 y338 w125 h28 axr ax0.5 +Default gConvert, > &Compile Executable <
ToolTip.Add("Button10","Convert script to executable file")
Gui, Add, StatusBar,, Ready
;@Ahk2Exe-IgnoreBegin
Gui, Add, Pic, x5 y16 w295 h78, %A_ScriptDir%\logo.png
;@Ahk2Exe-IgnoreEnd
/*@Ahk2Exe-Keep
gosub AddPicture
*/
GuiControl, Focus, Button1
Gui, Show, w594 h390, Ahk2Exe for AutoHotkey_H v%A_AhkVersion% -- Script to EXE Converter
gosub compress
return

CheckCompression:
Gui,Submit,NoHide
If (A_GuiControl="UseCompression" && !UseCompression)
{
	GuiControl,,UseEncrypt,0
	GuiControl,,UseCompression,0
} else If (A_GuiControl="UseEncrypt" && UseEncrypt)
{
	GuiControl,,UseCompression,1
}
Return

CheckInclude:
Gui,Submit,NoHide
If (A_GuiControl="UseInclude" && UseInclude)
{
	GuiControl,,UseIncludeResource,0
	GuiControl,,UseIncludeLib,0
} else If (A_GuiControl="UseIncludeResource" && UseIncludeResource)
{
	GuiControl,,UseInclude,0
	GuiControl,,UseIncludeLib,0
} else If (A_GuiControl="UseIncludeLib" && UseIncludeLib)
{
	GuiControl,,UseInclude,0
	GuiControl,,UseIncludeResource,0
} else If (A_GuiControl="UseInclude" && !UseInclude)
{
	GuiControl,,UseIncludeResource,1
	GuiControl,,UseIncludeLib,0
} else If (A_GuiControl="UseIncludeResource" && !UseIncludeResource)
{
	GuiControl,,UseInclude,1
	GuiControl,,UseIncludeLib,0
} else If (A_GuiControl="UseIncludeLib" && !UseIncludeLib)
{
	GuiControl,,UseInclude,1
	GuiControl,,UseIncludeResource,0
}
Return

GuiClose:
Gui, Submit
UseMPRESS--
gosub SaveSettings
ExitApp

compress:
gui, Submit, NoHide
if (UseMPRESS !=1
 && !FileExist(wk := A_ScriptDir "\" . {2:"MPRESS.exe",3:"UPX.exe"}[UseMPRESS]))
	Util_Status("Warning: """ wk """ not found.")
else Util_Status("Ready")
return

GuiDropFiles:
if A_EventInfo > 4
	Util_Error("You cannot drop more than one file of each type into this window!", 0x51)
loop, parse, A_GuiEvent, `n
{
	SplitPath, A_LoopField,,, dropExt
	if SubStr(dropExt,1,2) = "ah"          ; Allow for v2, e.g. ah2, ahk2, etc
		GuiControl,, AhkFile, %A_LoopField%
	else GuiControl,, %dropExt%File, %A_LoopField%
	if (dropExt = "bin")
		CustomBinFile:=1, BinFile := A_LoopField
		, Util_Status("""" BinFile """ will be used for this compile only.")
}
return

/*@Ahk2Exe-Keep

AddPicture:
; Code based on http://www.autohotkey.com/forum/viewtopic.php?p=147052
Gui, Add, Text, x5 y16 w295 h78 +0xE hwndhPicCtrl

;@Ahk2Exe-AddResource logo.png
hRSrc := DllCall("FindResource", "PTR", 0,"STR", "LOGO.PNG", "PTR", 10, "PTR")
sData := SizeofResource(0, hRSrc)
hRes  := LoadResource(0, hRSrc)
pData := LockResource(hRes)
If (NumGet(pData+0,0,"UInt")=0x04034b50)
	sData:=UnZipRawMemory(pData,sData,resLogo),pData:=&resLogo
hGlob := GlobalAlloc(2, sData) ; 2=GMEM_MOVEABLE
pGlob := GlobalLock(hGlob)
#DllImport,memcpy,msvcrt\memcpy,ptr,,ptr,,ptr,,CDecl
memcpy(pGlob, pData, sData)
GlobalUnlock(hGlob)
CreateStreamOnHGlobal(hGlob, 1, getvar(pStream:=0))

hGdip := LoadLibrary("gdiplus")
VarSetCapacity(si, 16, 0), NumPut(1, &si, "UChar")
GdiplusStartup(getvar(gdipToken:=0), &si)
GdipCreateBitmapFromStream(pStream, getvar(pBitmap:=0))
GdipCreateHBITMAPFromBitmap(pBitmap, getvar(hBitmap:=0))
SendMessage, 0x172, 0, hBitmap,, ahk_id %hPicCtrl% ; 0x172=STM_SETIMAGE, 0=IMAGE_BITMAP
GuiControl, Move, %hPicCtrl%, w295 h78

GdipDisposeImage(pBitmap)
GdiplusShutdown(gdipToken)
FreeLibrary(hGdip)
ObjRelease(pStream)
return

*/

BuildBinFileList:
BinFiles := ["AutoHotkeySC.bin"]
BinNames := "AutoHotkeySC.bin (default)"
Loop, %A_ScriptDir%\..\*.bin,0,1
{
	SplitPath,A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	BinFiles.Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".bin (" StrReplace(A_LoopFileDir,A_AhkDir "\") ")"
}
Loop, %A_ScriptDir%\..\*.exe,0,1
{
	SplitPath,A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
		continue
	BinFiles.Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".exe" " (" StrReplace(A_LoopFileDir,A_AhkDir "\") ")"
}
Loop, %A_ScriptDir%\..\*.dll,0,1
{
	SplitPath, A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
		continue
	BinFiles.Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".dll" " (" StrReplace(A_LoopFileDir,A_AhkDir "\") ")"
}

return


CheckAutoHotkeySC:
; IfNotExist, %A_ScriptDir%\AutoHotkeySC.bin
; {
	;; Check if we can actually write to the compiler dir
	; try FileAppend, test, %A_ScriptDir%\___.tmp
	; catch
	; {
		; MsgBox, 52, Ahk2Exe Error,
		; (LTrim
		; Unable to copy the appropriate binary file as AutoHotkeySC.bin because the current user does not have write/create privileges in the %A_ScriptDir% folder (perhaps you should run this program as administrator?)
		
		; Do you still want to continue?
		; )
		; IfMsgBox, Yes
			; return
		; ExitApp, 0x2 ; Compilation cancelled
	; }
	; FileDelete, %A_ScriptDir%\___.tmp
	
	; IfNotExist, %A_ScriptDir%\..\AutoHotkey.exe
	; {
		; BinFile = %A_ScriptDir%\Unicode 32-bit.bin

		; if !FileExist(BinFile)                  ; Ahk2Exe in non-standard folder?
		; {	FileCopy  %A_AhkPath%\..\Compiler\Unicode 32-bit.bin
			       ; ,  %A_ScriptDir%\AutoHotkeySC.bin
			; BinFile = %A_ScriptDir%\AutoHotkeySC.bin
			; FileCopy  %A_AhkPath%\..\Compiler\*bit.bin, %A_ScriptDir%\, 1
		; }
	; } else {
		; BinType := AHKType(A_ScriptDir "\..\AutoHotkey.exe")
		; if (BinType.PtrSize = 8)
			; BinFile = %A_ScriptDir%\Unicode 64-bit.bin
		; else if (BinType.IsUnicode)
			; BinFile = %A_ScriptDir%\Unicode 32-bit.bin
		; else 
			; BinFile = %A_ScriptDir%\ANSI 32-bit.bin
	; }

	; IfNotExist, %BinFile%
	; {
		; MsgBox, 52, Ahk2Exe Error,
		; (LTrim
		; Unable to copy the appropriate binary file as AutoHotkeySC.bin because said file does not exist:
		; %BinFile%
		
		; Do you still want to continue?
		; )
		; IfMsgBox, Yes
			; return
		; ExitApp, 0x2 ; Compilation cancelled
	; }
	
	; FileCopy, %BinFile%, %A_ScriptDir%\AutoHotkeySC.bin
; }
return

FindBinFile(name)
{
	global BinFiles
	for k,v in BinFiles
		if (v = name)
			return k
	return 1
}

ParseCmdLine:
if 0 = 0
	return

Error_ForceExit := true

p := []
Loop, %0%
		p.Insert(%A_Index%)

CLIMode := true  ; Set default - may be overridden.

while p.MaxIndex()
{
	p1 := p.RemoveAt(1)
	
	if SubStr(p1,1,1) != "/" || !(p1fn := Func("CmdArg_" SubStr(p1,2)))
		BadParams("Error: Unrecognised parameter:`n" p1)
	
	if p1fn.MaxParams  ; Currently assumes 0 or 1 params.
	{
		p2 := p.RemoveAt(1)
		if p2 =
			BadParams("Error: Blank or missing parameter for " p1 ".")
	}
	
	%p1fn%(p2)
}

if (AhkFile = "" && CLIMode)
	BadParams("Error: No input file specified.")

if BinFile =
	BinFile := A_ScriptDir "\" LastBinFile
return

BadParams(Message, ErrorCode=0x3)
{ Util_Error(Message, ErrorCode,, "Command Line Parameters:`n`n" A_ScriptName "`n`t  /in infile.ahk`n`t [/out outfile.exe]`n`t [/icon iconfile.ico]`n`t [/bin AutoHotkeySC.bin]`n`t [/compress 0 (none), 1 (MPRESS), or 2 (UPX)]`n`t [/cp codepage]`n`t [/ahk path\name]`n`t [/gui]")
}

CmdArg_Gui() {
	global
	CLIMode := false
	Error_ForceExit := false
}

CmdArg_In(p2) {
	global AhkFile := p2
}

CmdArg_Out(p2) {
	global ExeFile := p2
}

CmdArg_Icon(p2) {
	global IcoFile := p2
}

CmdArg_Bin(p2) {
	global
	CustomBinFile := true
	BinFile := p2
}

CmdArg_MPRESS(p2) {
	CmdArg_Compress(p2)
}
CmdArg_Compress(p2) {
	global
	if !CompressCode[p2]                ; Invalid codes?
		BadParams("Error: " p1 " parameter invalid:`n" p2)
	if CompressCode[p2] > 0             ; Convert any old codes
		p2 := CompressCode[p2]
	UseMPRESS := p2
}

CmdArg_Ahk(p2) {
	global
	if !FileExist(p2)
		Util_Error("Error: Specified resource does not exist.", 0x36
		, "Command line parameter /ahk`n""" p2 """")
	UseAhkPath := Util_GetFullPath(p2)
}

CmdArg_CP(p2) { ; for example: '/cp 1252' or '/cp UTF-8'
	global
	if p2 is number
		ScriptFileCP := "CP" p2
	else
		ScriptFileCP := p2
}

CmdArg_Pass(p2) {
  global
	UsePassword:=p2 ;BadParams("Error: Password protection is not supported.", 0x24)
}

CmdArg_NoDecompile(p2) {
  global
	UseCompression := p2=0 ? false : true ;BadParams("Error: /NoDecompile is not supported.", 0x23)
}

BrowseAhk:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastScriptDir%, Open, AutoHotkey files (*.ahk)
if ErrorLevel
	return
SplitPath ov,, LastScriptDir
GuiControl,, AhkFile, %ov%
menu, FileMenu, Enable, S&ave Script Settings As…`tCtrl+S
return

BrowseExe:
Gui, +OwnDialogs
FileSelectFile, ov, S16, %LastExeDir%, Save As, Executable files (*.exe)
if ErrorLevel
	return
if !RegExMatch(ov, "\.[^\\/]+$") ; append a default file extension if none
	ov .= ".exe"
SplitPath ov,, LastExeDir
GuiControl,, ExeFile, %ov%
return

BrowseIco:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastIconDir%, Open, Icon files (*.ico)
if ErrorLevel
	return
SplitPath ov,, LastIconDir
GuiControl,, IcoFile, %ov%
return

DefaultIco:
GuiControl,, IcoFile
return

SaveAsMenu:
Gui, +OwnDialogs
Gui, Submit, NoHide
BinFile := A_ScriptDir "\" BinFiles[BinFileId]
SaveAs := ""
FileSelectFile, SaveAs, S,% RegExReplace(AhkFile,"\.[^.]+$") "_Compile"
 , Save Script Settings As, *.ahk            ;^ Removes extension
If (SaveAs = "") or ErrorLevel
	Return
If !RegExMatch(SaveAs,"\.ahk$")
	SaveAs .= ".ahk"
FileDelete %SaveAs%
FileAppend % "RunWait """ A_ScriptDir "\Ahk2Exe.exe"" /in """ AhkFile """"
. (ExeFile ? " /out """ ExeFile """" : "")
. (IcoFile ? " /icon """ IcoFile """": "") 
. (UseCompression ? " /NoDecompile": "") 
. (UseEncryption ? " /pass """ UsePassword """": "") 
. " /bin """ BinFile """ /compress " UseMpress-1, %SaveAs%
Return

Convert:
Gui, +OwnDialogs
Gui, Submit, NoHide
UseMPRESS--
if !CustomBinFile
	BinFile := BinFiles[BinFileId]
else CustomBinFile := ""

ConvertCLI:
AhkFile := Util_GetFullPath(AhkFile)
if AhkFile =
	Util_Error("Error: Source file not specified.", 0x33)
SplitPath, AhkFile, ScriptName, ScriptDir
DerefIncludeVars.A_ScriptFullPath := AhkFile
DerefIncludeVars.A_ScriptName := ScriptName
DerefIncludeVars.A_ScriptDir := ScriptDir
SetWorkingDir %A_ScriptDir%

global DirDone := []                   ; Process Bin directives
DirBinsWk := [], DirBins := [], DirExe := [], DirCP := [], Cont := 0
Loop Read, %AhkFile%                   ;v Handle 1-2 unknown comment characters
{	if (Cont=1 && RegExMatch(A_LoopReadLine,"i)^\s*\S{1,2}@Ahk2Exe-Cont (.*$)",o))
		DirBinsWk[DirBinsWk.MaxIndex()] .= RegExReplace(o1,"\s+;.*$")
		, DirDone[A_Index] := 1
	else if (Cont!=2)
	&& RegExMatch(A_LoopReadLine,"i)^\s*\S{1,2}@Ahk2Exe-Bin (.*$)",o)
		DirBinsWk.Push(RegExReplace(o1, "\s+;.*$")), Cont := 1, DirDone[A_Index]:= 1
	else if SubStr(LTrim(A_LoopReadLine),1,2) = "/*"
		Cont := 2
	else if Cont != 2
		Cont := 0
	if (Cont = 2) && A_LoopReadLine~="^\s*\*/|\*/\s*$"  ;End block comment
		Cont := 0
}
for k, v1 in DirBinsWk
{	Util_Status("Processing directive: " v1)
	StringReplace, v, v1, ```,, `n, All
	Loop Parse, v, `,, %A_Space%%A_Tab%
	{	if A_LoopField =
			continue
		StringReplace, o1, A_LoopField, `n, `,, All
		StringReplace, o,o1, ``n, `n, All
		StringReplace, o, o, ``r, `r, All
		StringReplace, o, o, ``t, `t, All
		StringReplace, o, o,````, ``, All
		o := DerefIncludePath(o, DerefIncludeVars, 1)
		if A_Index = 1
		{	o .= RegExReplace(o, "\.[^\\]*$") = o ? ".bin" : "" ; Add extension?
			if !(FileExist(o) && FileExist(o:= A_AhkDir "\" o) && (RegExReplace(o,"^.+\.") = "bin" || RegExReplace(o,"^.+\.") = "exe" || RegExReplace(o,"^.+\.") = "dll"))
			 Util_Error("Error: The selected AutoHotkeySC binary does not exist. (A1)"
			 , 0x34, """" o1 """")
			Loop Files, % o
				DirBins.Push(A_LoopFileLongPath), DirExe.Push(ExeFile), Cont := A_Index
		} else if A_Index = 2
		{	SplitPath ExeFile    ,, edir,,ename
			SplitPath A_LoopField,, idir,,iname
			Loop % Cont
				DirExe[DirExe.MaxIndex()-A_Index+1] 
				:= (idir ? idir : edir) "\" (iname ? iname : ename) ".exe"
		}	else if A_Index = 3
		{	wk := A_LoopField~="^\d+$" ? "CP" A_LoopField : A_LoopField
			Loop % Cont
				DirCP[DirExe.MaxIndex()-A_Index+1] := wk
		}	else Util_Error("Error: Wrongly formatted directive. (A1)", 0x64, v1)
}	}
if Util_ObjNotEmpty(DirBins)
	for k in DirBins
		 AhkCompile(AhkFile, DirExe[k], IcoFile, DirBins[k],UseMpress
		                                       , DirCP[k] ? DirCP[k] : ScriptFileCP, UseCompression, UseInclude, UseIncludeResource, UsePassword)
else AhkCompile(AhkFile, ExeFile,   IcoFile, BinFile,   UseMpress, ScriptFileCP, UseCompression, UseInclude, UseIncludeResource, UsePassword)

if !CLIMode
	Util_Info("Conversion complete.")
else
	FileAppend, Successfully compiled: %ExeFile%`n, *
return

LoadSettings:
RegRead, LastScriptDir, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastScriptDir
RegRead, LastExeDir,    HKCU, Software\AutoHotkey\Ahk2Exe_H, LastExeDir
RegRead, LastIconDir,   HKCU, Software\AutoHotkey\Ahk2Exe_H, LastIconDir
RegRead, LastIcon,      HKCU, Software\AutoHotkey\Ahk2Exe_H, LastIcon
RegRead, LastBinFile,   HKCU, Software\AutoHotkey\Ahk2Exe_H, LastBinFile
RegRead, LastUseMPRESS, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseMPRESS
RegRead, UseCompression, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseCompression
RegRead, LastUseEncrypt,HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseEncrypt
if !FileExist(LastIcon)
	LastIcon := ""
if (LastBinFile = "") || !FileExist(LastBinFile)
	LastBinFile = AutoHotkeySC.bin
if !CompressCode[LastUseMPRESS]                ; Invalid codes := 0
	LastUseMPRESS := false
if CompressCode[LastUseMPRESS] > 0             ; Convert any old codes
	LastUseMPRESS := CompressCode[LastUseMPRESS]
return

SaveSettings:
SplitPath, AhkFile,, AhkFileDir
if ExeFile
	SplitPath, ExeFile,, ExeFileDir
else
	ExeFileDir := LastExeDir
if IcoFile
	SplitPath, IcoFile,, IcoFileDir
else
	IcoFileDir := ""
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastScriptDir, %AhkFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastExeDir,    %ExeFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastIconDir,   %IcoFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastIcon,      %IcoFile%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseMPRESS, %UseMPRESS%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseCompression, %UseCompression%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastUseEncrypt, %UseEncrypt%
if !CustomBinFile
	RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe_H, LastBinFile, % BinFiles[BinFileId]
return

Help:
helpfile = %A_ScriptDir%\..\AutoHotkey.chm
IfNotExist, %helpfile%
	Util_Error("Error: cannot find AutoHotkey help file!", 0x52)

#DllImport,HtmlHelp,hhctrl.ocx\HtmlHelp,PTR,,Str,,UInt,,PTR,
VarSetCapacity(ak, ak_size := 8+5*A_PtrSize+4, 0) ; HH_AKLINK struct
,NumPut(ak_size, ak, 0, "UInt"),name := "Ahk2Exe",NumPut(&name, ak, 8)
,HtmlHelp(GuiHwnd, helpfile, 0x000D, &ak) ; 0x000D: HH_KEYWORD_LOOKUP
return

About:
Gui, +OwnDialogs
MsgBox, 64, About Ahk2Exe,
(
Ahk2Exe - Script to EXE Converter

Original version:
  Copyright @1999-2003 Jonathan Bennett & AutoIt Team
  Copyright @2004-2009 Chris Mallet
  Copyright @2008-2011 Steve Gray (Lexikos)

Script rewrite:
  Copyright @2011-%A_Year% fincs
  Copyright @2012-%A_Year% HotKeyIt

Special thanks:
  joedf, benallred, aviaryan, TAC109
)
return

Util_Status(s)
{	SB_SetText(s)
}

Util_Error(txt, exitcode, extra := "", extra1 := "")
{
	global CLIMode, Error_ForceExit, ExeFileTmp
	
	if extra
		txt .= "`n`nSpecifically:`n" extra
	
	if extra1
		txt .= "`n`n" extra1
	
	Util_HideHourglass()
	if exitcode
		MsgBox, 16, Ahk2Exe Error, % txt
	else {
		MsgBox, 49, Ahk2Exe Warning, % txt
	. (extra||extra1 ? "" : "`n`nPress 'OK' to continue, or 'Cancel' to abandon.")
		IfMsgBox Cancel
			exitcode := 2
	}
	if (exitcode && ExeFileTmp && FileExist(ExeFileTmp))
	{	FileDelete, %ExeFileTmp%
		ExeFileTmp =
	}

	if CLIMode && exitcode
		FileAppend, Failed to compile: %ExeFile%`n, *
	Util_Status("Ready")
	
	if exitcode
		if !Error_ForceExit
			Exit, exitcode
		else ExitApp, exitcode
	Util_DisplayHourglass()
}

Util_Info(txt)
{	MsgBox, 64, Ahk2Exe, % txt
}

Util_DisplayHourglass()    ; Change IDC_ARROW (32512) to IDC_APPSTARTING (32650)
{	DllCall("SetSystemCursor", "Ptr",DllCall("LoadCursor", "Ptr",0, "Ptr",32512)
	,"Ptr",32650)
}

Util_HideHourglass()                           ; Reset arrow cursor to standard
{	DllCall("SystemParametersInfo", "Ptr",0x57, "Ptr",0, "Ptr",0, "Ptr",0)
}

Util_ObjNotEmpty(obj)
{	for _,__ in obj
		return true
}
