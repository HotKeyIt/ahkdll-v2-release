#Include <VersionRes>

ProcessDirectives(ExeFile, module, cmds, IcoFile, UseCompression, UsePassword)
{
  global GuiStatusBar
	state := { ExeFile: ExeFile, module: module, resLang: 0x409, verInfo: {}, IcoFile: IcoFile, PostExec: [] }
	for _,cmdline in cmds
	{
		If !CLIMode
      GuiStatusBar.SetText("Processing directive: " cmdline)
		if !RegExMatch(cmdline, "^(\w+)(?:\s+(.+))?$", o)
			Util_Error("Error: Invalid directive:`n`n" cmdline)
		_args := [], nargs := 0
		o2:=StrReplace(o.2, "```,", "`n")
		Loop Parse, o2, "`,", A_Space A_Tab
			_args.Push(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(A_LoopField, "`n", "`,"), "``n", "`n"), "``r", "`r"), "``t", "`t"), "````", "``")), nargs++
		fn := Func("Directive_" o.1)
		if !fn
			Util_Error("Error: Invalid directive: " o.1)
		if (o && o.1="AddResource")
			nargs+=2
		if (fn.MinParams-1) > nargs || nargs > (fn.MaxParams-1)
			Util_Error("Error: Wrongly formatted directive:`n`n" cmdline)
		if (o && o.1="AddResource")
			%fn%(state, UseCompression, UsePassword, _args*)
		else %fn%(state, _args*)
	}
	
	if !Util_ObjIsEmpty(state.verInfo)
	{
		If !CLIMode
      GuiStatusBar.SetText("Changing version information...")
		ChangeVersionInfo(ExeFile, module, state.verInfo)
	}
	
	if IcoFile := state.IcoFile
	{
		if !FileExist(IcoFile)
			Util_Error("Error changing icon: File does not exist.")
		
		If !CLIMode
      GuiStatusBar.SetText("Changing the main icon...")
		if !ReplaceAhkIcon(module, IcoFile, ExeFile)
			Util_Error("Error changing icon: Unable to read icon or icon was of the wrong format.")
	}
	return state
}

Directive_SetName(state, txt)
{
	state.verInfo.Name := txt
}

Directive_SetDescription(state, txt)
{
	state.verInfo.Description := txt
}

Directive_SetVersion(state, txt)
{
	state.verInfo.Version := txt
}

Directive_SetCopyright(state, txt)
{
	state.verInfo.Copyright := txt
}

Directive_SetOrigFilename(state, txt)
{
	state.verInfo.OrigFilename := txt
}

Directive_SetCompanyName(state, txt)
{
	state.verInfo.CompanyName := txt
}

Directive_SetMainIcon(state, txt := "")
{
	state.IcoFile := txt
}

Directive_PostExec(state, txt)
{
	state.PostExec.Push(txt)
}

Directive_UseSeparateTrayIcon(state)
{
	state.NoAhkWithIcon := true
}

Directive_SetConsoleApp(state)
{
	state.ConsoleApp := true
}

Directive_OutputPreproc(state, fileName)
{
	state.OutPreproc := fileName
}

Directive_UseResourceLang(state, resLang)
{
	if resLang < 0 || resLang > 0xFFFF
		Util_Error("Error: Resource language must be an integer between 0 and 0xFFFF.")
	state.resLang := resLang+0
}

Directive_AddResource(state, UseCompression, UsePassword, rsrc, resName := "")
{
	resType := "" ; auto-detect
	if RegExMatch(rsrc, "^\s*(\w+|\d+)\s+(.+)$", o)
		resType := o.1, rsrc := o.2
	if !resFile := Util_GetFullPath(rsrc)
		Util_Error("Error: specified resource does not exist: " rsrc)
	SplitPath resFile, resFileName,, resExt
	if !resName
		resName := resFileName, defResName := true
	resName:=StrUpper(resName)
	if (resType = "")
	{
		; Auto-detect resource type
		if InStr(".bmp.dib.","." resExt ".")
			resType := 2 ; RT_BITMAP
		else if resExt = "ico"
			Util_Error("Error: Icon resource adding is not supported yet!")
		else if resExt = "cur"
			Util_Error("Error: Cursor resource adding is not supported yet!")
		else if InStr(".htm.html.mht.css.js.","." resExt ".")
			resType := 23 ; RT_HTML
		else if (resExt = "manifest")
		{
			resType := 24 ; RT_MANIFEST
			if defResName
				resName := 1
		} else
			resType := 10 ; RT_RCDATA
	}
	typeType := "str"
	nameType := "str"
	if Type(resType+0) = "Integer"
		if between(resType ,0,0xFFFF)
			typeType := "uint"
	if Type(resName+0) = "Integer"
		if between(resName,0,0xFFFF)
			nameType := "uint"
	If UseCompression && resType=10{
		tempdata:=FileRead(resFile,"RAW")
		tempsize:=FileGetSize(resFile)
		If !fSize := ZipRawMemory(&tempdata, tempsize, fData)
			Util_Error("Error: Could not compress the file to: " file)
	} else {
		fSize:=FileGetSize(resFile)
		fData:=FileRead(resFile,"RAW")
	}
	pData := &fData
	if resType = 2
	{
		; Remove BM header in order to make it a valid bitmap resource
		if fSize < 14
			Util_Error("Error: Impossible BMP file!")
		pData += 14, fSize -= 14
	}
	if !UpdateResource(state.module, resType+0?resType+0:resType, resName, state.resLang, pData, fSize)
		Util_Error("Error adding resource:`n`n" rsrc)
	VarSetCapacity(fData, 0)
}

ChangeVersionInfo(ExeFile, hUpdate, verInfo)
{
	hModule := LoadLibraryEx(ExeFile, 0, 2)
	if !hModule
		Util_Error("Error: Error opening destination file.")
	
	hRsrc := FindResource(hModule, 1, 16) ; Version Info\1
	hMem := LoadResource(hModule, hRsrc)
	vi := new VersionRes(LockResource(hMem))
	FreeLibrary(hModule)
	
	ffi := vi.GetDataAddr()
	props := SafeGetViChild(SafeGetViChild(vi, "StringFileInfo"), "040904b0")
	for k,v in verInfo
	{
		if IsLabel(lbl := "_VerInfo_" k)
			gosub(lbl)
		continue
		_VerInfo_Name:
		SafeGetViChild(props, "ProductName").SetText(v)
		SafeGetViChild(props, "InternalName").SetText(v)
		return
		_VerInfo_Description:
		SafeGetViChild(props, "FileDescription").SetText(v)
		return
		_VerInfo_Version:
		SafeGetViChild(props, "FileVersion").SetText(v)
		SafeGetViChild(props, "ProductVersion").SetText(v)
		ver := VersionTextToNumber(v)
		hiPart := (ver >> 32)&0xFFFFFFFF, loPart := ver & 0xFFFFFFFF
		NumPut(hiPart, ffi+8, "UInt"), NumPut(loPart, ffi+12, "UInt")
		NumPut(hiPart, ffi+16, "UInt"), NumPut(loPart, ffi+20, "UInt")
		return
		_VerInfo_Copyright:
		SafeGetViChild(props, "LegalCopyright").SetText(v)
		return
		_VerInfo_OrigFilename:
		SafeGetViChild(props, "OriginalFilename").SetText(v)
		return
		_VerInfo_CompanyName:
		SafeGetViChild(props, "CompanyName").SetText(v)
		return
	}
	
	VarSetCapacity(newVI, 16384) ; Should be enough
	viSize := vi.Save(&newVI)
	if !UpdateResource(hUpdate, 16, 1, 0x409, &newVI, viSize)
		Util_Error("Error changing the version information.")
}

VersionTextToNumber(v)
{
	r := 0, i := 0
	while i < 4 && RegExMatch(v, "^(\d+).?", o)
	{
		v:= Substr(v,o.Len + 1)
		val := o[1] + 0
		r |= (val&0xFFFF) << ((3-i)*16)
		i++
	}
	return r
}

SafeGetViChild(vi, name)
{
	c := vi.GetChild(name)
	if !c
	{
		c := new VersionRes()
		c.Name := name
		vi.AddChild(c)
	}
	return c
}

Util_ObjIsEmpty(obj)
{
	for _,__ in obj
		return false
	return true
}
