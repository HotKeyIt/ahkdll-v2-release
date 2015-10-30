;
; File encoding:  UTF-8
;
; Script description:
;	Ahk2Exe - AutoHotkey Script Compiler
;	Written by fincs - Interface based on the original Ahk2Exe
;

;@Ahk2Exe-SetName         Ahk2Exe
;@Ahk2Exe-SetDescription  AutoHotkey Script Compiler
;@Ahk2Exe-SetCopyright    Copyright (c) since 2004
;@Ahk2Exe-SetCompanyName  AutoHotkey
;@Ahk2Exe-SetOrigFilename Ahk2Exe.ahk
;@Ahk2Exe-SetMainIcon     Ahk2Exe.ico

#NoTrayIcon
#SingleInstance Off
#Include %A_ScriptDir%
#Include Compiler.ahk
SendMode Input
Menu,Tray,Icon,%A_AhkPath%,2

global DEBUG := !A_IsCompiled

gosub BuildBinFileList
gosub LoadSettings
gosub ParseCmdLine

if CLIMode
{
	gosub ConvertCLI
	ExitApp
}

IcoFile := LastIcon
BinFileId := FindBinFile(LastBinFile)

#include *i __debug.ahk

ToolTip:=TT("Parent=1")

Menu, FileMenu, Add, &Convert, Convert
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, HelpMenu, Add, &Help, Help
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Help, :HelpMenu
Gui, Menu, MenuBar

Gui, +LastFound
GuiHwnd := WinExist("")
Gui, Add, Link, x287 y10,
(
©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-%A_Year% fincs
©2012-%A_Year% HotKeyIt
<a href="http://ahkscript.org">http://ahkscript.org</a>
Note: Compiling does not guarantee source code protection.
)
Gui, Add, Text, x11 y97 w570 h2 +0x1007
Gui, Font, Bold
Gui, Add, GroupBox, x11 y104 w570 h81, Required Parameters
Gui, Font, Normal
Gui, Add, Text, x17 y126, &Source (script file)
Gui, Add, Edit, x137 y121 w315 h23 +ReadOnly -WantTab vAhkFile, %AhkFile%
ToolTip.Add("Edit1","Select path of AutoHotkey Script to compile")
Gui, Add, Button, x459 y121 w53 h23 gBrowseAhk, &Browse
ToolTip.Add("Button2","Select path of AutoHotkey Script to compile")
Gui, Add, Text, x17 y155, &Destination (.exe file)
Gui, Add, Edit, x137 y151 w315 h23 +ReadOnly -WantTab vExeFile, %Exefile%
ToolTip.Add("Edit2","Select path to resulting exe / dll")
Gui, Add, Button, x459 y151 w53 h23 gBrowseExe, B&rowse
ToolTip.Add("Button3","Select path to resulting exe / dll")
Gui, Font, Bold
Gui, Add, GroupBox, x11 y187 w570 h148, Optional Parameters
Gui, Font, Normal
Gui, Add, Text, x18 y208, Custom Icon (.ico file)
Gui, Add, Edit, x138 y204 w315 h23 +ReadOnly vIcoFile, %IcoFile%
ToolTip.Add("Edit3","Select Icon to use in resulting exe / dll")
Gui, Add, Button, x461 y204 w53 h23 gBrowseIco, Br&owse
ToolTip.Add("Button5","Select Icon to use in resulting exe / dll")
Gui, Add, Button, x519 y204 w53 h23 gDefaultIco, D&efault
ToolTip.Add("Button6","Use default Icon")
Gui, Add, Text, x18 y237, Base File (.bin)
Gui, Add, DDL, x138 y233 w315 h23 R10 AltSubmit vBinFileId Choose%BinFileId%, %BinNames%
ToolTip.Add("ComboBox1","Select AutoHotkey binary file to use for compilation")
Gui, Add, CheckBox, x138 y260 w315 h20 gCheckCompression vUseCompression Checked%LastUseCompression%, Use compression to reduce size of resulting executable
ToolTip.Add("Button7","Compress all resources")
Gui, Add, CheckBox, x138 y282 w230 h20 vUseEncrypt gCheckCompression Checked%LastUseEncrypt%, Encrypt. Enter password used in executable:
ToolTip.Add("Button8","Use AES encryption for resources (requires a Password)")
Gui, Add, Edit,x370 y282 w100 h20 Password vUsePassword,AutoHotkey
ToolTip.Add("Edit4","Enter password for encryption (default = AutoHotkey).`nAutoHotkey binary must be using this password internally")
Gui, Add, CheckBox, x138 y304 w315 h20 gCheckCompression vUseMpress Checked%LastUseMPRESS%, Use MPRESS (if present) to compress resulting exe
ToolTip.Add("Button9","MPRESS makes executables smaller and decreases start time when loaded from slow media")
Gui, Add, Button, x235 y338 w125 h28 +Default gConvert, > &Compile Executable <
ToolTip.Add("Button10","Convert script to executable file")
Gui, Add, StatusBar,, Ready
;@Ahk2Exe-IgnoreBegin
Gui, Add, Pic, x30 y5 +0x801000, %A_ScriptDir%\logo.png
;@Ahk2Exe-IgnoreEnd
/*@Ahk2Exe-Keep
gosub AddPicture
*/
Gui, Show, w594 h400, Ahk2Exe for AutoHotkey v%A_AhkVersion% -- Script to EXE Converter
ControlFocus,Button2, ahk_id %GuiHwnd%
Return:
return

CheckCompression:
Gui,Submit,NoHide
If A_GuiControl="UseCompression" && !UseCompression{
	GuiControl,,UseEncrypt,0
	GuiControl,,UseCompression,0
} else If A_GuiControl="UseEncrypt" && UseEncrypt{
	GuiControl,,UseCompression,1
}
Return

CheckInclude:
Gui,Submit,NoHide
If A_GuiControl="UseInclude" && UseInclude{
	GuiControl,,UseIncludeResource,0
	GuiControl,,UseIncludeLib,0
} else If A_GuiControl="UseIncludeResource" && UseIncludeResource{
	GuiControl,,UseInclude,0
	GuiControl,,UseIncludeLib,0
} else If A_GuiControl="UseIncludeLib" && UseIncludeLib{
	GuiControl,,UseInclude,0
	GuiControl,,UseIncludeResource,0
} else If A_GuiControl="UseInclude" && !UseInclude{
	GuiControl,,UseIncludeResource,1
	GuiControl,,UseIncludeLib,0
} else If A_GuiControl="UseIncludeResource" && !UseIncludeResource{
	GuiControl,,UseInclude,1
	GuiControl,,UseIncludeLib,0
} else If A_GuiControl="UseIncludeLib" && !UseIncludeLib{
	GuiControl,,UseInclude,1
	GuiControl,,UseIncludeResource,0
}
Return

GuiClose:
Gui, Submit
gosub SaveSettings
ExitApp

GuiDropFiles:
if A_EventInfo > 2
	Util_Error("You cannot drop more than one file into this window!")
SplitPath, A_GuiEvent,,, dropExt
if (dropExt = "ahk")
	GuiControl,, AhkFile, %A_GuiEvent%
else if dropExt = ico
	GuiControl,, IcoFile, %A_GuiEvent%
else if InStr(".exe.dll.","." dropExt ".")
	GuiControl,, ExeFile, %A_GuiEvent%
return

/*@Ahk2Exe-Keep

AddPicture:
; Code based on http://www.autohotkey.com/forum/viewtopic.php?p=147052
Gui, Add, Text, x40 y5 +0x80100E hwndhPicCtrl

;@Ahk2Exe-AddResource logo.png
hRSrc := FindResource(0, "LOGO.PNG", 10)
sData := SizeofResource(0, hRSrc)
hRes  := LoadResource(0, hRSrc)
pData := LockResource(hRes)
If NumGet(pData,0,"UInt")=0x04034b50
	sData:=UnZipRawMemory(pData,resLogo),pData:=&resLogo
hGlob := GlobalAlloc(2, sData) ; 2=GMEM_MOVEABLE
pGlob := GlobalLock(hGlob)
#DllImport,memcpy,msvcrt\memcpy,ptr,,ptr,,ptr,,CDecl
memcpy(pGlob, pData, sData)
GlobalUnlock(hGlob)
CreateStreamOnHGlobal(hGlob, 1, getvar(pStream:=0))

hGdip := LoadLibrary("gdiplus")
VarSetCapacity(si, 16, 0), NumPut(1, si, "UChar")
GdiplusStartup(getvar(gdipToken:=0), &si)
GdipCreateBitmapFromStream(pStream, getvar(pBitmap:=0))
GdipCreateHBITMAPFromBitmap(pBitmap, getvar(hBitmap:=0))
SendMessage, 0x172, 0, %hBitmap%,, ahk_id %hPicCtrl% ; 0x172=STM_SETIMAGE, 0=IMAGE_BITMAP
GuiControl, Move, %hPicCtrl%, w240 h78

GdipDisposeImage(pBitmap)
GdiplusShutdown(gdipToken)
FreeLibrary(hGdip)
ObjRelease(pStream)
return

*/

BuildBinFileList:
BinFiles := ["Please Select"]
If FileExist(A_AhkDir "\AutoHotkeySC.bin"){
	BinFiles.1:=A_AhkDir "\AutoHotkeySC.bin"
	SplitPath,% BinFiles.1,,d,, n
	FileGetVersion, v, % BinFiles.1
	BinNames := "v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
} else BinNames := "Please Select"

LoopFiles, %A_ScriptDir%\..\*.bin,FR
{
	SplitPath,% A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	BinFiles.Push(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
}
LoopFiles, %A_ScriptDir%\..\*.exe,FR
{
	SplitPath,% A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
		continue
	BinFiles.Push(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".exe" " (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
}
LoopFiles, %A_ScriptDir%\..\*.dll,FR
{
  SplitPath,% A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
		continue
	BinFiles.Push(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".dll" " (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
}

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
if !A_Args.Length()
	return

Error_ForceExit := true

p := []
Loop % A_Args.Length()
{
	; if (A_Args[A_Index] = "/NoDecompile")
		; Util_Error("Error: /NoDecompile is not supported.")
	; else 
	p.Push(A_Args[A_Index])
}

if Mod(p.Length(), 2)
	goto BadParams

Loop, % p.Length() // 2
{
	p1 := p[2*(A_Index-1)+1]
	p2 := p[2*(A_Index-1)+2]
	
	if !InStr(",/in,/out,/icon,/pass,/bin,/mpress,","," p1 ",")
		goto BadParams
	
	;~ if (p1 = "/pass")
		;~ Util_Error("Error: Password protection is not supported.")
	
	if (p2 = "")
		goto BadParams
	
	p1:=SubStr(p1,2)
	gosub _Process%p1%
}

if !AhkFile
	goto BadParams

if !IcoFile
	IcoFile := LastIcon

if !BinFile
	BinFile := LastBinFile

if (UseMPRESS = "")
	UseMPRESS := LastUseMPRESS

global CLIMode := true
return

BadParams:
MsgBox, 64, Ahk2Exe, Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]
ExitApp

_ProcessIn:
AhkFile := p2
return

_ProcessOut:
ExeFile := p2
return

_ProcessIcon:
IcoFile := p2
return

_ProcessBin:
CustomBinFile := true,BinFile := p2
return

_ProcessPass:
UseEncrypt := true,UseCompress := true,UsePassword := p2
return

_ProcessNoDecompile:
UseEncrypt := true,UseCompress := true
return

_ProcessMPRESS:
UseMPRESS := p2
return

BrowseAhk:
Gui, +OwnDialogs
FileSelect, ov, 1, %LastScriptDir%, Open, AutoHotkey files (*.ahk)
if ErrorLevel
	return
GuiControl,, AhkFile, %ov%
return

BrowseExe:
Gui, +OwnDialogs
FileSelect, ov, S16, %LastExeDir%, Save As, Executable files (*.exe;*.dll)
if ErrorLevel
	return
SplitPath, %ov%,,, ovExt
if !StrLen(ovExt) ;~ append a default file extension is none specified
	ov .= ".exe"
GuiControl,, ExeFile, %ov%
return

BrowseIco:
Gui, +OwnDialogs
FileSelect, ov, 1, %LastIconDir%, Open, Icon files (*.ico)
if ErrorLevel
	return
GuiControl,, IcoFile, %ov%
return

DefaultIco:
GuiControl,, IcoFile
return

Convert:
Gui, +OwnDialogs
Gui, Submit, NoHide
BinFile := BinFiles[BinFileId]
ConvertCLI:
If UseEncrypt && !UsePassword
{
	if !CLIMode
		MsgBox, 64, Ahk2Exe, Error compiling`, no password supplied: %ExeFile%
	else
		FileAppend, Error compiling`, no password supplied: %ExeFile%`n, *
	return
}
; else If UseEncrypt && SubStr(BinFile,-4)!=".bin"
; {
	; if !CLIMode
		; MsgBox, 64, Ahk2Exe, Resulting exe will not be protected properly, use AutoHotkeySC.bin file to have more secure protection.
	; else
		; FileAppend, Warning`, Resulting exe will not be protected properly`, use AutoHotkeySC.bin file to have more secure protection.: %ExeFile%`n, *
; }
AhkCompile(AhkFile, ExeFile, IcoFile, BinFile, UseMpress, UseCompression, UseInclude, UseIncludeResource, UseEncrypt?UsePassword:"")
if !CLIMode
	MsgBox, 64, Ahk2Exe, Conversion complete.
else
	FileAppend, Successfully compiled: %ExeFile%`n, *
return

LoadSettings:
RegRead, LastScriptDir, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastScriptDir
RegRead, LastExeDir, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastExeDir
RegRead, LastIconDir, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastIconDir
RegRead, LastIcon, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastIcon
RegRead, LastBinFile, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastBinFile
RegRead, LastUseCompression, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseCompression
RegRead, LastUseMPRESS, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseMPRESS
RegRead, LastUseEncrypt, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseEncrypt
RegRead, LastUseInclude, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseInclude
RegRead, LastUseIncludeResource, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeResource
RegRead, LastUseIncludeLib, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeLib
RegRead, LastUseIncludeAutoHotkeyDll, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeAutoHotkeyDll
RegRead, LastUseIncludeAutoHotkeyMini, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeAutoHotkeyMini
if !FileExist(LastIcon)
	LastIcon := ""
if (LastBinFile = "") || !FileExist(LastBinFile)
	LastBinFile := "AutoHotkeySC.bin"

if LastUseMPRESS
	LastUseMPRESS := true
return

SaveSettings:
SplitPath,% AhkFile,, AhkFileDir
if ExeFile
	SplitPath,% ExeFile,, ExeFileDir
else
	ExeFileDir := LastExeDir
if IcoFile
	SplitPath,% IcoFile,, IcoFileDir
else
	IcoFileDir := ""
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastScriptDir, %AhkFileDir%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastExeDir, %ExeFileDir%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastIconDir, %IcoFileDir%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastIcon, %IcoFile%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseCompression, %UseCompression%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseMPRESS, %UseMPRESS%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseEncrypt, %UseEncrypt%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseInclude, %UseInclude%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeResource, %UseIncludeResource%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeLib, %UseIncludeLib%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeAutoHotkeyDll, %UseIncludeAutoHotkeyDll%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastUseIncludeAutoHotkeyMini, %UseIncludeAutoHotkeyMini%
if !CustomBinFile
	RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe, LastBinFile,% BinFiles[BinFileId]
return

Help:
If !FileExist(helpfile := A_ScriptDir "\..\AutoHotkey.chm")
	Util_Error("Error: cannot find AutoHotkey help file!")

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
)
return

Util_Error(txt, doexit := 1, extra := "")
{
	global CLIMode, Error_ForceExit, ExeFileTmp
	
	if ExeFileTmp && FileExist(ExeFileTmp)
	{
		FileDelete, %ExeFileTmp%
		ExeFileTmp := ""
	}
	
	if extra
		txt .= "`n`nSpecifically: " extra
	
	SetCursor(LoadCursor(0, 32512)) ;Util_HideHourglass()
	MsgBox, 16, Ahk2Exe Error, % txt
	
	if CLIMode
		FileAppend, Failed to compile: %ExeFile%`n, *
	else	SB_SetText("Ready")
	
	if doexit
		if !Error_ForceExit
			Exit
		else
			ExitApp
}
