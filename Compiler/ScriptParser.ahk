
PreprocessScript(ByRef ScriptText, AhkScript, ExtraFiles, FileList := "", FirstScriptDir := "", Options := "", iOption := 0)
{
  global GuiStatusBar
	SplitPath AhkScript, ScriptName, ScriptDir
	if !IsObject(FileList)
	{
		FileList := [AhkScript]
		ScriptText := "; <COMPILER: v" A_AhkVersion ">`n"
		FirstScriptDir := ScriptDir
		IsFirstScript := true
		Options := { comm: ";", esc: "``", directives: [] }
		
		OldWorkingDir := A_WorkingDir
		SetWorkingDir ScriptDir
	}
	
	If !FileExist(AhkScript)
		if !iOption
			Util_Error((IsFirstScript ? "Script" : "#include") " file `"" AhkScript "`" cannot be opened.")
		else return
	
	cmtBlock := false, contSection := false, ignoreSection := false
	Loop Read, AhkScript
	{
		tline := Trim(A_LoopReadLine)
		if !cmtBlock
		{
			if ignoreSection
			{
				if (tline == Options.comm "@Ahk2Exe-IgnoreEnd")
					ignoreSection := false
				continue
			}
			if !contSection
			{
				if StrStartsWith(tline, Options.comm)
				{
					tline := SubStr(tline,1 + StrLen(Options.comm))
					if !StrStartsWith(tline, "@Ahk2Exe-")
						continue
					tline := SubStr(tline, 10)
					if (tline = "IgnoreBegin")
						ignoreSection := true
					else if (tline != "")
						Options.directives.Push(tline)
					continue
				}
				else if (tline = "")
					continue
				else if StrStartsWith(tline, "/*")
				{
					if (tline == "/*@Ahk2Exe-Keep")
						continue
					cmtBlock := true
					continue
				}
				else if StrStartsWith(tline, "*/")
					continue ; Will only happen in a 'Keep' section
			}
			if StrStartsWith(tline, "(") && !InStr(tline, ")")
				contSection := true
			else if StrStartsWith(tline, ")")
				contSection := false
			
			tline := RegExReplace(tline, "\s+" RegExEscape(Options.comm) ".*$", "")
			if !contSection && RegExMatch(tline, "i)^#Include(Again)?[ \t]*[, \t]?\s+(.*)$", o)
			{
				IsIncludeAgain := (o.1 = "Again")
				IgnoreErrors := false
				IncludeFile := o.2
				if RegExMatch(IncludeFile, "\*[iI]\s+?(.*)", o)
					IgnoreErrors := true, IncludeFile := Trim(o.1)
				
				if RegExMatch(IncludeFile, "^<(.+)>$", o)
				{
					if IncFile2 := FindLibraryFile(o.1, FirstScriptDir)
					{
						IncludeFile := IncFile2
						goto _skip_findfile
					}
				}
				
				IncludeFile:=StrReplace(StrReplace(StrReplace(IncludeFile, "`%A_ScriptDir`%", FirstScriptDir), "`%A_AppData`%", A_AppData), "`%A_AppDataCommon`%", A_AppDataCommon)
				
				if FileExist(IncludeFile) = "D"
				{
					SetWorkingDir IncludeFile
					continue
				}
				
				_skip_findfile:
				
				IncludeFile := Util_GetFullPath(IncludeFile)
				
				AlreadyIncluded := false
				for k,v in FileList
				if (v = IncludeFile)
				{
					AlreadyIncluded := true
					break
				}
				if(IsIncludeAgain || !AlreadyIncluded)
				{
					if !AlreadyIncluded
						FileList.Push(IncludeFile)
					PreprocessScript(ScriptText, IncludeFile, ExtraFiles, FileList, FirstScriptDir, Options, IgnoreErrors)
				}
			}else if (!contSection && tline ~= "i)^\s*FileInstall[, \t\(]")
			{
				if tline ~= "^\w+\s+(:=|\+=|-=|\*=|/=|//=|\.=|\|=|&=|\^=|>>=|<<=)"
					continue ; This is an assignment!
				if !RegExMatch(tline, "i)^\s*FileInstall[ \t]*[, \t\(][ \t]*([^,]+?)[ \t]*(,|$)", o) || o.1 ~= "[^``]`%" ; TODO: implement `, detection
					Util_Error("Error: Invalid `"FileInstall`" syntax found. Note that the first parameter must not be specified using a continuation section.")
				_ := Options.esc
				o1:=o.1
				o1:=StrReplace(StrReplace(StrReplace(o1, _ "`%", "`%"), _ "`,", "`,"), o1, _ _, _)
				ExtraFiles.Push(Trim(o1,"`""))
				ScriptText .= tline "`n"
			}else if !contSection && RegExMatch(tline, "i)^#CommentFlag\s+(.+)$", o)
				Options.comm := o.1, ScriptText .= tline "`n"
			else if !contSection && RegExMatch(tline, "i)^#EscapeChar\s+(.+)$", o)
				Options.esc := o.1, ScriptText .= tline "`n"
			else if !contSection && RegExMatch(tline, "i)^#DerefChar\s+(.+)$", o)
				Util_Error("Error: #DerefChar is not supported.")
			else if !contSection && RegExMatch(tline, "i)^#Delimiter\s+(.+)$", o)
				Util_Error("Error: #Delimiter is not supported.")
			else
				ScriptText .= (contSection ? A_LoopReadLine : tline) "`n"
		}else if StrStartsWith(tline, "*/")
			cmtBlock := false
	}
	
	Loop !!IsFirstScript ; equivalent to "if IsFirstScript" except you can break from the block
	{
		If !CLIMode
      GuiStatusBar.SetText("Auto-including any functions called from a library...")
		ilibfile := FirstScriptDir "\FAF4D55FBB00419A9ECFFE26ED983E93.ahk"
		FileDelete ilibfile
		FileDelete ilibfile ".script"
		FileDelete ilibfile ".error"
		static AhkPath := A_AhkPath ;A_IsCompiled ? A_ScriptDir "\..\AutoHotkey.exe" : A_AhkPath
		AhkType := AHKType(AhkPath)
		if AhkType = "FAIL"
			Util_Error("Error: The AutoHotkey build used for auto-inclusion of library functions is not recognized.", 1, AhkPath)
		if AhkType = "Legacy"
			Util_Error("Error: Legacy AutoHotkey versions (prior to v1.1) are not allowed as the build used for auto-inclusion of library functions.", 1, AhkPath)
		FileAppend ScriptText,ilibfile ".script", "UTF-8"
    RunWait "`"" A_Comspec "`" /C `"`"" AhkPath "`" /iLib `"" ilibfile "`" /ErrorStdOut `"" ilibfile ".script`" 2>`"" ilibfile ".error`"`"", FirstScriptDir, "HIDE UseErrorLevel"
		if (ErrorLevel = 2)
		{		
			script_error:=FileRead(ilibfile ".error")
			FileDelete ilibfile ".error"
			line_error:=SubStr(line_error:=SubStr(script_error,StrLen(ilibfile) + 10),1,InStr(line_error,")")-1)
			Loop Parse, ScriptText,"`n","`r"
				If (A_Index=line_error){
					line_error:=A_LoopField
					break
				}
			FileDelete ilibfile
			FileDelete ilibfile ".script"
			Util_Error("Error: The script contains syntax errors.",true,line_error "`n" SubStr(script_error,StrLen(ilibfile) + 9))
		}
		If FileExist(ilibfile)
			PreprocessScript(ScriptText, ilibfile, ExtraFiles, FileList, FirstScriptDir, Options)
		FileDelete ilibfile
		FileDelete ilibfile ".script"
		FileDelete ilibfile ".error"
		ScriptText:=SubStr(ScriptText, 1,-1) ; remove trailing newline
	}
	
	if OldWorkingDir
		SetWorkingDir OldWorkingDir
	
	if IsFirstScript
		return Options.directives
}

FindLibraryFile(name, ScriptDir)
{
	FileGetShortCut A_AhkPath "\lib.lnk",target
	libs := [ScriptDir "\Lib", A_MyDocuments "\AutoHotkey\Lib", A_ScriptDir "\..\Lib", A_AhkPath "\Lib",A_ScriptDir "\..\..\Lib",target]
	if p := InStr(name, "_")
		name_lib := SubStr(name, 1, p-1)
	
	for each,lib in libs
	{
		file := lib "\" name ".ahk"
		If FileExist(file)
			return file
		
		if !p
			continue
		
		file := lib "\" name_lib ".ahk"
		If FileExist(file)
			return file
	}
}

StrStartsWith(ByRef v, ByRef w)
{
	return SubStr(v, 1, StrLen(w)) = w
}

RegExEscape(t)
{
	static _ := "\.*?+[{|()^$"
	Loop Parse, _
		t:=StrReplace(t, A_LoopField, "\" A_LoopField)
	return t
}
