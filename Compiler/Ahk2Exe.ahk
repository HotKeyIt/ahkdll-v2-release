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
TraySetIcon(A_AhkPath,2)

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
FileMenu:=MenuCreate(),HelpMenu:=MenuCreate(),MenuBar:=MenuBarCreate()
FileMenu.Add("&Convert", "Convert")
FileMenu.Add()
FileMenu.Add("E&xit`tAlt+F4", "GuiClose")
HelpMenu.Add("&Help", "Help")
HelpMenu.Add()
HelpMenu.Add("&About", "About")
MenuBar.Add("&File", FileMenu)
MenuBar.Add("&Help", HelpMenu)

Gui :=GuiCreate()
ToolTip:=TT(Gui.Hwnd)
Gui.OnEvent("Close","GuiClose")
Gui.OnEvent("DropFiles","GuiDropFiles")
Gui.MenuBar := MenuBar
Gui.AddLink "x287 y10",
(
"©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-" A_Year "  fincs
©2012-" A_Year " HotKeyIt
<a href=`"http://ahkscript.org`">http://ahkscript.org</a>
Note: Compiling does not guarantee source code protection."
)
Gui.AddText "x11 y97 w570 h2 +0x1007"
Gui.SetFont("Bold")
Gui.AddGroupBox "x11 y104 w570 h81", "Required Parameters"
Gui.SetFont("Normal")
Gui.AddText "x17 y126", "&Source (script file)"
GuiBrowseAhk:=Gui.AddEdit("x137 y121 w315 h23 +ReadOnly -WantTab vAhkFile", AhkFile)
ToolTip.Add("Edit1","Select path of AutoHotkey Script to compile")
(GuiButton2:=Gui.AddButton("x459 y121 w53 h23", "&Browse")).OnEvent("Click","BrowseAhk")
ToolTip.Add("Button2","Select path of AutoHotkey Script to compile")
Gui.AddText "x17 y155", "&Destination (.exe file)"
GuiBrowseExe:=Gui.AddEdit("x137 y151 w315 h23 +ReadOnly -WantTab vExeFile", Exefile)
ToolTip.Add("Edit2","Select path to resulting exe / dll")
(GuiButton3:=Gui.AddButton("x459 y151 w53 h23", "B&rowse")).OnEvent("Click","BrowseExe")
ToolTip.Add("Button3","Select path to resulting exe / dll")
Gui.SetFont("Bold")
Gui.AddGroupBox "x11 y187 w570 h148", "Optional Parameters"
Gui.SetFont("Normal")
Gui.AddText "x18 y208", "Custom Icon (.ico file)"
GuiBrowseIco:=Gui.AddEdit("x138 y204 w315 h23 +ReadOnly vIcoFile", IcoFile)
ToolTip.Add("Edit3","Select Icon to use in resulting exe / dll")
(GuiButton4:=Gui.AddButton("x461 y204 w53 h23", "Br&owse")).OnEvent("Click","BrowseIco")
ToolTip.Add("Button5","Select Icon to use in resulting exe / dll")
Gui.AddButton("x519 y204 w53 h23", "D&efault").OnEvent("Click","DefaultIco")
ToolTip.Add("Button6","Use default Icon")
Gui.AddText "x18 y237", "Base File (.bin)"
Gui.AddDDL "x138 y233 w315 h23 R10 AltSubmit vBinFileId Choose" BinFileId, BinNames
ToolTip.Add("ComboBox1","Select AutoHotkey binary file to use for compilation")
(GuiUseCompression:=Gui.AddCheckBox("x138 y260 w315 h20 vUseCompression Checked" LastUseCompression, "Use compression to reduce size of resulting executable")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button7","Compress all resources")
(GuiUseEncrypt:=Gui.AddCheckBox("x138 y282 w230 h20 vUseEncrypt Checked" LastUseEncrypt, "Encrypt. Enter password used in executable:")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button8","Use AES encryption for resources (requires a Password)")
Gui.AddEdit "x370 y282 w100 h20 Password vUsePassword", "AutoHotkey"
ToolTip.Add("Edit4","Enter password for encryption (default = AutoHotkey).`nAutoHotkey binary must be using this password internally")
(GuiUseMPRESS:=Gui.AddCheckBox("x138 y304 w315 h20 vUseMpress Checked" LastUseMPRESS, "Use MPRESS (if present) to compress resulting exe")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button9","MPRESS makes executables smaller and decreases start time when loaded from slow media")
Gui.AddButton("x235 y338 w125 h28 +Default", "> &Compile Executable <").OnEvent("Click","Convert")
ToolTip.Add("Button10","Convert script to executable file")
GuiStatusBar:=Gui.AddStatusBar(, "Ready")
;@Ahk2Exe-IgnoreBegin
Gui.AddPic "x30 y5 +0x801000", A_ScriptDir "\logo.png"
;@Ahk2Exe-IgnoreEnd
/*@Ahk2Exe-Keep
gosub AddPicture
*/
Gui.Show "w594 h400", "Ahk2Exe for AutoHotkey v" A_AhkVersion " -- Script to EXE Converter"
GuiButton2.Focus()
Return:
return

CheckCompression(Control){
  global
  GuiSubMit := Gui.SubMit(0)
  If Control.name="UseCompression" && !GuiSubMit.UseCompression{
    GuiUseEncrypt.value := false
    GuiUseCompression.value := false
  } else If Control.Name="UseEncrypt" && GuiSubMit.UseEncrypt{
    GuiUseCompression := true
  }
}

GuiClose(){
  gosub SaveSettings
  ExitApp
}

GuiDropFiles(){
  global
  if A_EventInfo > 2
    Util_Error("You cannot drop more than one file into this window!")
  SplitPath A_GuiEvent,,, dropExt
  if (dropExt = "ahk")
    GuiBrowseAhk.text :=A_GuiEvent
  else if (dropExt = "ico")
    GuiBrowseIco.text :=A_GuiEvent
  else if InStr(".exe.dll.","." dropExt ".")
    GuiBrowseExe.text := A_GuiEvent
}

/*@Ahk2Exe-Keep

AddPicture:
; Code based on http://www.autohotkey.com/forum/viewtopic.php?p=147052
GuiPicCtrl:=Gui.AddText("x40 y5 +0x80100E")

;@Ahk2Exe-AddResource logo.png
hRSrc := FindResource(0, "LOGO.PNG", 10)
sData := SizeofResource(0, hRSrc)
hRes  := LoadResource(0, hRSrc)
pData := LockResource(hRes)
If NumGet(pData,0,"UInt")=0x04034b50
	sData:=UnZipRawMemory(pData,sData,resLogo),pData:=&resLogo
hGlob := GlobalAlloc(2, sData) ; 2=GMEM_MOVEABLE
pGlob := GlobalLock(hGlob)
#DllImport memcpy,msvcrt\memcpy,ptr,,ptr,,ptr,,CDecl
memcpy(pGlob, pData, sData)
GlobalUnlock(hGlob)
CreateStreamOnHGlobal(hGlob, 1, getvar(pStream:=0))

hGdip := LoadLibrary("gdiplus")
VarSetCapacity(si, 16, 0), NumPut(1, si, "UChar")
GdiplusStartup(getvar(gdipToken:=0), &si)
GdipCreateBitmapFromStream(pStream, getvar(pBitmap:=0))
GdipCreateHBITMAPFromBitmap(pBitmap, getvar(hBitmap:=0))
SendMessage 0x172, 0, hBitmap,, "ahk_id " GuiPicCtrl.hwnd ; 0x172=STM_SETIMAGE, 0=IMAGE_BITMAP
GuiPicCtrl.Move("w240 h78")

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
	SplitPath BinFiles.1,,d,, n
	v:=FileGetVersion(BinFiles.1)
	BinNames := "v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
} else BinNames := "Please Select"

Loop Files, A_ScriptDir "\..\*.bin","FR"
{
	SplitPath A_LoopFileFullPath,,d,, n
	v :=FileGetVersion(A_LoopFileFullPath)
	BinFiles.Push(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
}
Loop Files, A_ScriptDir "\..\*.exe","FR"
{
	SplitPath A_LoopFileFullPath,,d,, n
	v:=FileGetVersion(A_LoopFileFullPath)
	If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
		continue
	BinFiles.Push(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".exe" " (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")"
}
Loop Files, A_ScriptDir "\..\*.dll","FR"
{
  SplitPath A_LoopFileFullPath,,d,, n
	v:=FileGetVersion(A_LoopFileFullPath)
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
Loop A_Args.Length()
{
	; if (A_Args[A_Index] = "/NoDecompile")
		; Util_Error("Error: /NoDecompile is not supported.")
	; else 
	p.Push(A_Args[A_Index])
}

if Mod(p.Length(), 2)
	goto BadParams

Loop p.Length() // 2
{
	p1 := p[2*(A_Index-1)+1]
	p2 := p[2*(A_Index-1)+2]
	
	if !InStr(",/in,/out,/icon,/pass,/bin,/mpress,","," p1 ",")
		goto BadParams
	
	;~ if (p1 = "/pass")
		;~ Util_Error("Error: Password protection is not supported.")
	
	if (p2 = "")
		goto BadParams
	
	gosub("_Process" SubStr(p1,2))
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
MsgBox "Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]", "Ahk2Exe", 64
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
UseEncrypt := true,UseCompression := true,UsePassword := p2
return

_ProcessNoDecompile:
UseEncrypt := true,UseCompression := true
return

_ProcessMPRESS:
UseMPRESS := p2
return

BrowseAhk(Control){
  global
  ov := FileSelect(1, LastScriptDir, "Open", "AutoHotkey files (*.ahk)")
  if ErrorLevel
    return
  GuiBrowseAhk.text:=ov
}

BrowseExe(Control){
  global
  ov :=FileSelect("S16", LastExeDir, "Save As", "Executable files (*.exe;*.dll)")
  if ErrorLevel
    return
  SplitPath ov,,, ovExt
  if !StrLen(ovExt) ;~ append a default file extension is none specified
    ov .= ".exe"
  GuiBrowseExe.text:=ov
}

BrowseIco(Control){
  global
  ov:=FileSelect(1, LastIconDir, "Open", "Icon files (*.ico)")
  if ErrorLevel
    return
  GuiBrowseIco.text:= ov
}

DefaultIco(Control){
  global
  GuiBrowseIco.text :=IcoFile
}


ConvertCLI:
  If UseEncrypt && !UsePassword
  {
    FileAppend "Error compiling`, no password supplied: " ExeFile "`n", "*"
    return
  }
  AhkCompile(AhkFile, ExeFile, IcoFile, BinFile, UseMpress, UseCompression, UseInclude, UseIncludeResource, UseEncrypt?UsePassword:"")
  FileAppend "Successfully compiled: " ExeFile "`n", "*"
Return

Convert(){
  global
  guiSubMit := Gui.SubMit(0)
  BinFile := BinFiles[BinFileId]
  If UseEncrypt && !UsePassword
  {
    MsgBox "Error compiling`, no password supplied: " ExeFile, "Ahk2Exe", 64
    return
  }
  ; else If UseEncrypt && SubStr(BinFile,-4)!=".bin"
  ; {
    ; if !CLIMode
      ; MsgBox, 64, Ahk2Exe, Resulting exe will not be protected properly, use AutoHotkeySC.bin file to have more secure protection.
    ; else
      ; FileAppend, Warning`, Resulting exe will not be protected properly`, use AutoHotkeySC.bin file to have more secure protection.: %ExeFile%`n, *
  ; }
  AhkCompile(guiSubMit.AhkFile, guiSubMit.ExeFile, guiSubMit.IcoFile, BinFiles[guiSubMit.BinFileId], guiSubMit.UseMpress, guiSubMit.UseCompression, guiSubMit.UseInclude, guiSubMit.UseIncludeResource, guiSubMit.UseEncrypt?guiSubMit.UsePassword:"")
  MsgBox "Conversion complete.", "Ahk2Exe", 64
}

LoadSettings:
LastScriptDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastScriptDir")
LastExeDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeDir")
LastIconDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconDir")
LastIcon:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIcon")
LastBinFile:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastBinFile")
LastUseCompression:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseCompression")
LastUseMPRESS:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseMPRESS")
LastUseEncrypt:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseEncrypt")

if !FileExist(LastIcon)
	LastIcon := ""
if (LastBinFile = "") || !FileExist(LastBinFile)
	LastBinFile := "AutoHotkeySC.bin"

if LastUseMPRESS
	LastUseMPRESS := true
return

SaveSettings:
guiSubMit:=Gui.SubMit(0)
SplitPath guiSubMit.AhkFile,, AhkFileDir
if guiSubMit.ExeFile
	SplitPath guiSubMit.ExeFile,, ExeFileDir
else
	ExeFileDir := LastExeDir
if guiSubMit.IcoFile
	SplitPath guiSubMit.IcoFile,, IcoFileDir
else
	IcoFileDir := ""
RegWrite AhkFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastScriptDir"
RegWrite ExeFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeDir"
RegWrite IcoFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconDir"
RegWrite guiSubMit.IcoFile, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIcon"
RegWrite guiSubMit.UseCompression, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseCompression"
RegWrite guiSubMit.UseMPRESS, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseMPRESS"
RegWrite guiSubMit.UseEncrypt, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseEncrypt"
if !CustomBinFile
	RegWrite BinFiles[guiSubMit.BinFileId], "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastBinFile"
return

Help(){
If !FileExist(helpfile := A_ScriptDir "\..\AutoHotkey.chm")
	Util_Error("Error: cannot find AutoHotkey help file!")
}

#DllImport HtmlHelp,hhctrl.ocx\HtmlHelp,PTR,,Str,,UInt,,PTR,
VarSetCapacity(ak, ak_size := 8+5*A_PtrSize+4, 0) ; HH_AKLINK struct
,NumPut(ak_size, ak, 0, "UInt"),name := "Ahk2Exe",NumPut(&name, ak, 8)
,HtmlHelp(Gui.Hwnd, helpfile, 0x000D, &ak) ; 0x000D: HH_KEYWORD_LOOKUP
return

About(){
  MsgBox "
  (Q
  Ahk2Exe - Script to EXE Converter

  Original version:
    Copyright @1999-2003 Jonathan Bennett & AutoIt Team
    Copyright @2004-2009 Chris Mallet
    Copyright @2008-2011 Steve Gray (Lexikos)

  Script rewrite:
    Copyright @2011-" A_Year " fincs
    Copyright @2012-" A_Year " HotKeyIt
  )", "About Ahk2Exe", 64
}

Util_Error(txt, doexit := 1, extra := "")
{
	global CLIMode, Error_ForceExit, ExeFileTmp, GuiStatusBar
	
	if ExeFileTmp && FileExist(ExeFileTmp)
	{
		FileDelete ExeFileTmp
		ExeFileTmp := ""
	}
	
	if extra
		txt .= "`n`n" extra
	
	SetCursor(LoadCursor(0, 32512)) ;Util_HideHourglass()
	MsgBox txt, "Ahk2Exe Error", 16
	
	if CLIMode
		FileAppend "Failed to compile: " ExeFile "`n", "*"
	else	GuiStatusBar.SetText("Ready")
	
	if doexit
		if !Error_ForceExit
			Exit
		else
			ExitApp
}
