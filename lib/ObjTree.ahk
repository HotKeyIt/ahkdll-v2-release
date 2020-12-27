/*
CLASS test extends Map{
}
t:=test.new()
t[1]:="int"
t["1"]:="String"
t["'1'"]:="String2"
ObjTree2 := ObjTree(obj:=Map("MyObject",Map("Key With Object",["a", "This is a test", "b", 2])
					, "Another Object",Map("Key",["c", 1, "d", 2])
					, "Array Object",[Func("MsgBox"),ie:=ComObjCreate("InternetExplorer.Application"),t,BufferAlloc(100,0)] ;Map("key","value","more","test","int",100)]
					, "Another Object 2",["e", 1, "f", 2])
		, "My ObjTree Gui Title", "-ReadOnly,Edit=wrap,+Resize"
		, Map("MyObject",Map("Key With Object","This is a an object`nKey is a string and value is object")
					, "Another Object",Map("Key","This is an object")
					, "Empty Object","This object is empty"
					, "Another Object 2","Another object"))
WinWaitClose "ahk_id " ObjTree2.hwnd
ie.Quit()
*/

ObjTree(ByRef obj, Title := "ObjTree", Options := "+ReadOnly +Resize, GuiShow=w640 h480", ToolTip := ""){
	return _ObjTree.new(obj, Title, Options, ToolTip)
}
Class _ObjTree {
	__New(ByRef obj, Title := "ObjTree", Options := "+ReadOnly +Resize, edit=-wrap, GuiShow=w640 h480", ToolTip := ""){
		local Font:="", Edit:="", GuiShow:="",newObj:=""
		If RegExMatch(Options, "i)^\s*([-\+]?ReadOnly)(\d+)?\s*$", option)
			Options := "+AlwaysOnTop +Resize, GuiShow=w640 h480", this.ReadOnly := option.1, this.ReadOnlyLevel := option.2
		else this.ReadOnly := "+ReadOnly"
		Loop Parse, Options, "`,", A_Space
		{
		 opt := Trim(SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1))
		 If RegExMatch(A_LoopField, "i)([-\+]?ReadOnly)(\d+)?", option)
			this.ReadOnly := option.1, this.ReadOnlyLevel := option.2
		 If (InStr("Font,GuiShow,Edit", opt))
			%opt% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1, StrLen(A_LoopField))  
		 else GuiOptions := RegExReplace(A_LoopField, "i)[-\+]?ReadOnly\s?")
		}
		this.Gui := Gui.New(GuiOptions " +MinSize640x480", Title), this.hwnd := this.gui.hwnd
		, fun := this.GetMethod("Close").Bind(this), this.Gui.OnEvent("Close", fun) ;, this.Gui.OnEvent("Escape", fun)
		if (Font)
			Gui.SetFont(SubStr(Font, 1, Pos := InStr(Font, ":") - 1), SubStr(Font, Pos + 2, StrLen(Font)))
		; Get Gui size
		if !RegExMatch(GuiShow, "\b[w]([0-9]+\b).*\b[h]([0-9]+\b)", size)
			size := [640, 480]
		; Get hwnd of new window
		this.Hwnd := this.gui.hwnd, IsAHK_H := this.IsAHK_H()
		; Apply Gui options and create Gui
		this.Gui.Add("Button", "x0 y0 NoTab Hidden Default", "Show/Expand Object")
		TV := this.TV := this.Gui.Add("TreeView", "xs w" (size[1]*0.3) " h" (size[2]) " ys " (IsAHK_H?"aw1/3 ah":"") " +0x800 +ReadOnly")
		this.TVHwnd:=TV.Hwnd
		LV := this.LV := this.Gui.Add("ListView", "x+1 w" (size[1]*0.7) " h" (size[2]*0.5) " ys " (IsAHK_H?" aw2/3 ah1/2 ax1/3":"") " AltSubmit Checked " this.ReadOnly, ["[IsObj] Key/Address","Value/Address","ItemID"])
		this.LVHwnd:=LV.Hwnd
		fun := this.GetMethod("TVSelect").Bind(this, LV)
		TV.OnEvent("ItemSelect", fun) 
		LV.ModifyCol(3, "0")
		fun := this.GetMethod("LVSelect").Bind(this, TV)
		LV.OnEvent("Click", fun)
		fun := this.GetMethod("LVDoubleClick").Bind(this, TV)
		LV.OnEvent("DoubleClick", fun)
		fun := this.GetMethod("LVEdit").Bind(this, TV)
		LV.OnEvent("ItemEdit", fun)
		fun := this.GetMethod("LVCheck").Bind(this, TV)
		LV.OnEvent("ItemCheck", fun)
		EditKey := this.EditKey := this.Gui.Add("Edit", "y+1 w" (size[1]*0.7) " h" (size[2]*0.11) (IsAHK_H?" axr aw2/3 ah1/5 ax1/3 ay1/2 +HScroll":"") " " this.ReadOnly " " Edit)
		EditKey.Enabled := false
		fun := this.GetMethod("EditKeyEdit").Bind(this, TV, LV)
		EditKey.OnEvent("Change", fun)
		EditValue := this.EditValue := this.Gui.Add("Edit", "y+1 w" (size[1]*0.7) " h" (size[2]*0.39) (IsAHK_H?" axr aw2/3 ah3/10 ax1/3 ay1/5 +HScroll":"") " " this.ReadOnly " " Edit)
		EditValue.Enabled := false
		fun := this.GetMethod("EditValueEdit").Bind(this, TV, LV)
		EditValue.OnEvent("Change", fun)
		; Items will hold TV_Item <> Object relation
		
		this.Items := Map()
		this.obj := obj
		this.changed := 0
        if !this.ReadOnlyLevel
          this.ReadOnlyLevel := 0
		; Create Menus to be used for all ObjTree windows (ReadOnly windows have separate Menu)
		this.Menu := Menu.New()
		fun := this.GetMethod("TVExpandAll").Bind(this.TV)


		this.Menu.Add("E&xpand All", fun)
		
		fun := this.GetMethod("TVCollapseAll").Bind(this, this.TV)
		this.Menu.Add("C&ollapse All", fun)
		; Convert object to TreeView and create a clone for our object
		; Changes can be optionally saved when ObjTree is closed when -ReadOnly is used
		If (this.ReadOnly="-ReadOnly"){
			this.newObj := this.CreateClone(obj), this.Items[newObj] := 0, this.TVAdd(this.newObj, 0)
			; Add additional Menu items when not Readonly
			, this.Menu.Add(), fun := this.GetMethod("TVInsert").Bind(this, this.TV), this.Menu.Add("&Insert", fun)
			, fun := this.GetMethod("TVInsertChild").Bind(this, this.TV), this.Menu.Add("I&nsertChild", fun)
			, this.Menu.Add(), fun := this.GetMethod("TVDelete").Bind(this, this.TV), this.Menu.Add("&Delete", fun)
			, this.Menu.Add(), fun := this.GetMethod("KeyToDigit").Bind(this, this.TV, this.LV), this.Menu.Add("&KeyToDigit", fun)
			, fun := this.GetMethod("ValueToDigit").Bind(this, this.TV, this.LV), this.Menu.Add("&ValueToDigit", fun)
			
		} else this.Items[this.newObj := obj] := 0, this.TVAdd(obj, 0)
		if IsAHK_H{
			ObjTree_Attach(TV.hwnd, "w1/2 h")
			, ObjTree_Attach(LV.hwnd, "w1/2 h1/2 x1/2 y0")
			, ObjTree_Attach(EditKey.hwnd, "w2/2 h1/5 x1/3 y1/2")
			, ObjTree_Attach(EditValue.hwnd, "w2/2 h3/10 x1/3 y1/5")
		}
		this.Tooltip := ToolTip, fun := this.GetMethod("TVContextMenu").Bind(this), this.TV.OnEvent("ContextMenu", fun), this.gui.Show(GuiShow)
		, this.WM_Notify := this.GetMethod("Notify").Bind(this, TV), OnMessage(78, this.WM_Notify) ;WM_NOTIFY
	}
	BaseType(obj) {
		static   ComObj		:={Name:"ComObj"    ,Obj:1,Enum:0,OwnProps:0,Clone:0}	,type:={Object    :{Name:"Object"     ,Enum:0,OwnProps:1,Clone:1}
				,Array      :{Name:"Array"      ,Enum:1,OwnProps:1,Clone:1}			,Map        :{Name:"Map"        ,Enum:1,OwnProps:1,Clone:1}
				,Func       :{Name:"Func"       ,Enum:0,OwnProps:0,Clone:0}			,File       :{Name:"File"       ,Enum:0,OwnProps:0,Clone:0}
				,RegExMatch :{Name:"RegExMatch" ,Enum:1,OwnProps:0,Clone:0}			,Struct     :{Name:"Struct"     ,Enum:1,OwnProps:0,Clone:1}
				,DynaCall   :{Name:"DynaCall"   ,Enum:0,OwnProps:0,Clone:0}			,Menu       :{Name:"Menu"       ,Enum:0,OwnProps:0,Clone:0}
				,MenuBar    :{Name:"MenuBar"    ,Enum:0,OwnProps:0,Clone:0}			,Gui        :{Name:"Gui"        ,Enum:1,OwnProps:0,Clone:0}
				,%'Gui.Control'%:{Name:"Gui.Control",Enum:0,OwnProps:0,Clone:0}		,%'Gui.List'%  :{Name:"Gui.List"  ,Enum:0,OwnProps:0,Clone:0}
				,InputHook  :{Name:"InputHook"  ,Enum:0,OwnProps:0,Clone:0}			,Closure    :{Name:"Closure"    ,Enum:0,OwnProps:0,Clone:0}
				,BoundFunc  :{Name:"BoundFunc"  ,Enum:0,OwnProps:0,Clone:0}			,Enumerator :{Name:"Enumerator" ,Enum:0,OwnProps:0,Clone:0}
				,Buffer     :{Name:"Buffer"     ,Enum:0,OwnProps:0,Clone:0}			,ClipboardAll:{Name:"ClipboardAll",Enum:0,OwnProps:0,Clone:0}
				,String     :{Name:"String"     ,Enum:0,OwnProps:0,Clone:0}			,Float      :{Name:"Float"      ,Enum:0,OwnProps:0,Clone:0}
				,Integer    :{Name:"Integer"    ,Enum:0,OwnProps:0,Clone:0}}
		if ComObjType(obj)
			return ComObj
		Loop {
			_class:=obj.__Class,obj:= obj.base
		} Until (InStr(".Object.Number.String.", "." obj.__Class "."))
		return type.%_class%
	}
	TypeOf(val) {
		if ComObjType(val)
			return "ComObj"
		Loop {
			_class:=val.__Class,val:= val.base
		} Until (InStr(".Object.Number.String.", "." val.__Class "."))
		return _class
	}
	IsAHK_H() {   ; Written by SKAN, modified by HotKeyIt
		; www.autohotkey.com/forum/viewtopic.php?p=233188#233188  CD:24-Nov-2008 / LM:27-Oct-2010
		If FSz := DllCall("Version\GetFileVersionInfoSizeW", "Str", A_AhkPath, "UInt", 0 ){
		FVI:=BufferAlloc(FSz, 0), DllCall("Version\GetFileVersionInfoW", "Str", A_AhkPath, "UInt", 0, "UInt", FSz, "PTR", FVI.Ptr )
		If DllCall( "Version\VerQueryValueW", "PTR", FVI.Ptr, "Str", "\VarFileInfo\Translation", "PTR*", Transl:=0, "PTR", 0 )
			&& (Trans := format("{1:.8X}", NumGet(Transl+0, "UInt")))
			&& DllCall( "Version\VerQueryValueW", "PTR", FVI.Ptr, "Str", "\StringFileInfo\" SubStr(Trans, -4) SubStr(Trans, 1, 4) "\FILEVERSION", "PTR*", InfoPtr:=0, "UInt", 0 )
			return !!InStr(StrGet(InfoPtr), "H")
		}
	}
	Notify(TV, wParam, lParam, msg, hwnd){
		local _object:=""
		static ToolTipText, TVN_GETINFOTIP := 0XFFFFFE70 - 14 - 0 ;TVN_FIRST := 0xfffffe70 / 0=Unicode
		/*
			ObjTree is also used to Monitor messages for TreeView: ObjeTree(obj=wParam, Title=lParam, Options=msg, ishwnd=hwnd)
			when ishwnd is a handle, this routine is taken
		*/
		; Check if this message is relevant
		If (this.hwnd != hwnd || NumGet(lParam, A_PtrSize*2, "Uint")!=TVN_GETINFOTIP)
			Return
		; HDR.Item contains the relevant TV_ID
		If !IsInteger(TV_Text := TV.GetText(TV_Item := NumGet(lParam+A_PtrSize*5, "PTR")))
			TV_Text:=SubStr(TV_Text,2,-1)
		
		; Check if this GUI uses a ToolTip object that contains the information in same structure as the TreeView
		If ToolTipText := this.ToolTip { ; Gui has own ToolTip object
			; following will resolve the item in ToolTip object
			_object := [TV_Text], item := TV_Item
			While item := TV.GetParent(item)
				_object.Push(TV.GetText(item))
			; Resolve our item/value in ToolTip object
			While _object.Length{
				if !IsObject(ToolTipText){
					ToolTipText := ""
					break
				}
				ToolTipText := ToolTipText.Has(text:=_object.Pop())?ToolTipText[text]:text
			}
			; Item is not an object and is not empty, display value in ToolTip
			If !IsObject(ToolTipText)&&ToolTipText!=""
				Return NumPut("PTR",(ToolTipText.="", StrPtr(ToolTipText)), lParam+A_PtrSize*3) ;HDR.pszText[""] := &(ToolTipText.="")
			ToolTipText := ""
		}
		; Gui has no ToolTip object or item could not be resolved
		; Get the value of item and display in ToolTip
		; Check if Item is an object and if so, display first 20 keys (first 50 chars) and values (first 100 chars)
		try _object := this.items[TV_Item][TV_Text]
		if !IsObject(_object)
			ToolTipText := _object ""
		else if (IsObject(_object) && !(base:=this.BaseType(_object)).Enum)
			ToolTipText := base.Name="Func" ? "[Func]`t`t" _object.Name "`nBuildIn:`t`t" _object.IsBuiltIn "`nVariadic:`t" _object.IsVariadic "`nMinParams:`t" _object.MinParams "`nMaxParams:`t" _object.MaxParams : base.Name="ComObj" ? "[ComObj]`t" Type(_object) "`nIID:`t`t" ComObjType(_object,"IID") "`nClass:`t`t" ComObjType(_object,"Class") "`nCLSID:`t`t" ComObjType(_object,"CLSID") : "[" Type(_object) "]"
		else{
			ToolTipText := "[" Type(_object) "]"
			for key, v in _object
			{
				ToolTipText.=(ToolTipText?"`n":"") SubStr(key, 1, 50) (StrLen(key)>50?"...":"") " = " (IsObject(v)?"[Obj] ":SubStr(v, 1, 100) (StrLen(v)>100?"...":""))
				If (A_Index>20){
					ToolTipText.="`n..."
					break
				}
			}
		}
		Return NumPut("PTR", StrPtr(ToolTipText), lParam+A_PtrSize*3) ;(HDR.pszText[""] := &ToolTipText)
	}
	Close(p*){
		this.gui.Opt("+OwnDialogs")
		If this.changed && "Yes"=MsgBox("Do you want to save changes?", , 4){
			for k, v in this.obj
				this.obj.Delete(k)
			for k, v in this.newObj
				this.obj[k] := v
		}
		this.newObj := ""
		this.gui.destroy()
		OnMessage(78, this.WM_Notify, 0)
	}
	GUID(){
		static sz:=77,pguid:=BufferAlloc(16, 0),g:=BufferAlloc(77, 0)
		if !DllCall("ole32.dll\CoCreateGuid", "ptr", pguid.Ptr) && DllCall("ole32.dll\StringFromGUID2", "ptr", pguid.Ptr, "ptr", g.Ptr, "int", sz)
			return StrGet(g.Ptr)
		else return "ERROR GUID COULD BE CREATED " A_TickCount
	}
	SelectObjType(p*){
		static objtype, key, gui, edit
		if p.Length
			objtype:=[this,edit.Value],Gui.Destroy
		else {
			objtype:=0,Gui:=Gui.New(,"Select Object Type")
			,edit:=Gui.Add("Edit","","Please enter a name for new Item.")
			,(_obj:=Gui.Add("Button",,"&Object")).OnEvent("Click",this.GetMethod("SelectObjType").Bind({}))
			,(_arr:=Gui.Add("Button","x+5","&Array")).OnEvent("Click",this.GetMethod("SelectObjType").Bind([]))
			,(_map:=Gui.Add("Button","x+5","&Map")).OnEvent("Click",this.GetMethod("SelectObjType").Bind(Map()))
			,Gui.Show(),WinWaitClose("ahk_id " gui.hwnd)
			return objtype
		}
	}
	TVContextMenu(TV, Item, IsRightClick, p*){
		if item
			TV.Modify(Item)
		this.Menu.Show()
	}
	CreateClone(obj){
		clone := obj.Clone()
		for k, v in obj{
			If IsObject(v)&&this.BaseType(v).Clone
				clone[k] := this.CreateClone(v)
		}
		if obj.HasMethod("OwnProps")
		for k, v in obj.OwnProps(){
			If IsObject(v)
				clone.%k% := this.CreateClone(v)
		}
		Return clone
	}
	UnEscape(value){
		return IsNumber(value) ? value+0 : SubStr(value,2,-1)
	}
	ToType(Value,Byref base:=""){
		return (IsByRef(base)&&Type(base)="Integer"||!IsByRef(base))&&IsNumber(value) ? value+0 : value ""
	}
	ToValue(value){
		return Type(value)="Integer" ? value : "'" value "'"
	}
	ValueToDigit(TV,LV,p*){
		if IsNumber(val:=this.EditValue.text)&&this.EditValue.Enabled{
			LV.Modify(LV.GetNext("Selected"), , , val)
			this.items[IsNumber(text:=TV.GetSelection())?text+0:SubStr(text,2,-1)][IsNumber(text:=LV.GetText(row := LV.GetNext("Selected")))?text+0:SubStr(text,2,-1)] := val
		}
	}
	KeyToDigit(TV,LV,p*){
		if IsNumber(newkey:=this.EditKey.text)&&this.EditKey.Enabled{
			id := LV.GetText(row := LV.GetNext("Selected"), 3)+0	, obj := this.items[id], key := this.UnEscape(TV.GetText(id)), newkey := newkey+0
			if this.TypeOf(obj)!="Map"||(newkey=key&&Type(key)="Integer")
				return
			If Obj.Has(newKey)
				Return (this.gui.Opt("+OwnDialogs"), this.EditKey.Text := key, MsgBox("Key " newKey " already exists"))
			obj[newkey] := obj[key], obj.Delete(key), TV.Modify(id, , newkey),LV.Modify(row, , newkey)
			, TV.Modify(TV.GetParent(id) ? this.items[obj] : "", "Sort"), LV.ModifyCol(1, "Sort AutoHdr"), this.changed := 1
		}
	}
	EditKeyEdit(TV, LV, p*){
		Critical
		id := LV.GetText(row := LV.GetNext("Selected"), 3)+0	, obj := this.items[id], key := this.UnEscape(TV.GetText(id)), newkey := this.ToType(this.EditKey.Value,key)
		;~ If (KeyIsDigitString:=SubStr(key,-1)="'"&&SubStr(key,2,-1) is "digit")||!(key is "digit")
			;~ key:=SubStr(key,2,-1)
		;~ else 
		if Type(key)="Integer"&&newkey=""
			return (this.gui.Opt("+OwnDialogs"), MsgBox("Empty key is not allowed for Integer!`nEnter any text to convert key to string or enter new integer value!"))
		;~ else
			;~ key:=key+0,newkey:=newkey is "digit"?newkey+0:newkey
		if (newkey=key)
			return
		If Obj.Has(newKey)
			Return (this.gui.Opt("+OwnDialogs"), this.EditKey.Text := key, MsgBox("Key " newKey " already exists"))
		;~ obj[newkey] := obj[key], obj.Delete(key), TV.Modify(id, , newkey:=KeyIsDigitString||!(newkey is "digit")?"'" newkey "'":newkey),LV.Modify(row, , newkey)
		obj[newkey] := obj[key], obj.Delete(key), TV.Modify(id, , newkey:=this.ToValue(newkey)),LV.Modify(row, , newkey)
		, TV.Modify(TV.GetParent(id) ? this.items[obj] : "", "Sort"), LV.ModifyCol(1, "Sort AutoHdr"), this.changed := 1
	}
	EditValueEdit(TV, LV, p*){
		Critical
		val:=this.EditValue.Value
		If IsNumber(ValIsNumber:=LV.GetText(row := LV.GetNext("Selected"),2))&&(val)=""
			return (this.gui.Opt("+OwnDialogs"), MsgBox("Empty value is not allowed for Integer!`nEnter any text to convert value to string or enter new integer value!"))
		if ValIsNumber&&IsNumber(val)
			val:=val+0
		this.changed := 1
		, this.items[IsNumber(text:=TV.GetSelection())?text+0:SubStr(text,2,-1)][IsNumber(text:=LV.GetText(row := LV.GetNext("Selected")))?text+0:SubStr(text,2,-1)] := val
		, LV.Modify(Row, , , Type(val)="String"?"'" val "'":val)
	}
	TVAdd(obj, parent := ""){
		for k, v in obj
		{
			If (IsObject(v) && !this.Items.Has(v) && this.BaseType(v).Clone)
				this.Items[v] := this.TV.Add(IsObject(k)?Chr(177) Type(k) " " (ObjPtr(k)):Type(k)="String"?"'" k "'":k, parent, "Sort"), this.Items[this.Items[v]] := obj
				, this.TVAdd(v, this.Items[v])
			else
				this.Items[lastParent := this.TV.Add(IsObject(k)?Chr(177) Type(k) " " (ObjPtr(k)):Type(k)="String"?"'" k "'":k, parent, "Sort")] := obj
			;~ If (IsObject(k) && !this.Items.Has(v))
				;~ this.Items[k] := this.TV.Add(Chr(177) " " (&k), IsObject(v)?this.Items[v]:lastParent, "Sort"), this.Items[this.Items[k]] := k
				;~ this.TVAdd(k, this.Items[k])
		}
	}
	TVExpandAll(Menu, p*){
		this.Modify(item := this.GetSelection(), "+Expand")
		if this.GetChild(item)
			While(item := this.GetNext(item, "F")) && this.GetParent(item)
				this.Modify(item, "+Expand")
	}
	TVInsert(TV, p*){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		if !(item := TV.GetSelection()) || !(parent:=TV.GetParent(item)) ; highest level
			return  (this.newObj[key:=this.GUID()] := 0,this.Items[TV.Add("'" key "'",,"Sort")]:=this.newObj) ;((!objType:=this.SelectObjType())?"":this.items[this.newObj[key:=objType[2]]:=newObj:=objType[1]] := item := TV.Add(key, , "Sort"), this.items[item] := this.newobj,this.TVSelect(this.LV,this.TV,item))
		else If !InStr(".Object.Array.Map.","." (type:=this.BaseType(this.Items[item])).name ".")
			return MsgBox("New Items can not be inserted in [" type.name "]!")
		type.Name="Array" ? (this.Items[item].Push(0),k:=this.Items[item].Length) : type.Name="Object" ? this.Items[item].%k:=this.GUID()%:=0 : this.Items[item][k:=this.GUID()]:=0
		,this.Items[newItem:=this.TV.Add(type.Name="Array" ? k : "'" k "'", parent, "Sort")] := this.Items[item],this.changed := 1,this.TVSelect(this.LV,this.TV,newItem)
	}
	TVInsertChild(TV, p*){
        Loop this.ReadOnlyLevel-1
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		this.gui.Opt("+OwnDialogs")
		if !IsObject(v := this.items[IsNumber(parent:=(parent := TV.GetSelection()))?parent+0:SubStr(parent,2,-1)][IsNumber(k := TV.GetText(parent))?k+0:SubStr(k,2,-1)]){
			if "Yes"=MsgBox(k " is not an object, would you like to convert it to object?", , 4) && objType:=this.SelectObjType()
				return (this.Items[parent][k] := newObj := objType[1], this.Items[newObj] := parent,item := TV.Add(this.BaseType(newObj).Name="Array"?(newObj.Push(objType[2]),1):this.BaseType(newObj).Name="Map"?(newObj[key:=objType[2]]:=0,"'" key "'"):(newObj.%key:=objType[2]%:=0,"'" key "'"), parent, "Sort"), this.Items[item]:=newObj,TV.Modify(item,"Vis"),this.TVSelect(this.LV,this.TV,parent))
			else Return
		}
		type:=this.BaseType(v),type.Name="Array" ? (this.Items[parent][k].Push(0),key:=this.Items[parent][k].Length) : type.Name="Map" ? (this.Items[parent][k][key:=this.GUID()]:=0) : this.Items[parent][k].%key:=this.GUID()%:=0
		,this.Items[item := TV.Add(Type(key)="Integer"?key:"'" key "'", parent, "Sort")] := this.Items[parent][k],this.changed := 1,TV.Modify(item,"Vis")
	}
	TVDelete(TV, p*){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be deleted only from level " this.ReadOnlyLevel "!")
		k:=(IsNumber(k := TV.GetText(item := TV.GetSelection())))?k+0:SubStr(k,2,-1)
		If "Yes"=MsgBox("Do you want to Delete " k, , 4){
            If IsObject(this.items[item][k])
				this.TVDeepDelete(TV, item)
            else
				this.items[item].Delete(k), this.items.Delete(item), TV.Delete(item)
			this.changed := 1
		}
	}
	TVDeepDelete(TV, parent){
		If child := TV.GetChild(parent){
			Loop {
				if TV.GetChild(child)
					this.TVDeepDelete(TV, child)
				this.Delete(this.items[parent],TV.GetText(child)), this.items.Delete(this.items[child]), this.items.Delete(child), TV.Delete(child), next := TV.GetNext(child, "F")
				if TV.GetParent(next)!=parent
					return
				child := next
			}
		} else if this.BaseType(this.items[parent]).Name="Array"{
          child:=parent,index:=TV.GetText(parent)
          While child:=TV.GetNext(child)
            TV.Modify(child,,index++)
          this.items[parent].RemoveAt(index), TV.Delete(parent), this.items.Delete(parent)
        } else 
          this.items[parent].Delete(TV.GetText(parent)), TV.Delete(parent), this.items.Delete(parent)
	}
	TVCollapseAll(TV, parent := 0, p*){
		if parent="C&ollapse All"
			parent := TV.GetSelection()
		If child := TV.GetChild(parent)
			Loop {
				if TV.GetChild(child)
					this.TVCollapseAll(TV, child)
				next := TV.GetNext(child, "F")
				if TV.GetParent(next)!=parent
					return TV.Modify(parent, "-Expand")
				child := next
			}
	}
	TVSelect(LV, TV, item, p*){
		local LV_CurrRow:=0, ReadOnly:=0
		this.LV.Delete(), this.EditKey.Text:="", this.EditValue.Text := "", this.EditValue.Enabled := false	, text := TV.GetText(item), TV.Modify(item, "Select")
		if !TV.Getparent(item)
			obj := this.newObj, next := item := 0
		else obj := this.items[item], next := item := TV.GetParent(item)
		Loop this.ReadOnlyLevel
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly := 1
		Loop {
			While item := TV.GetNext(item, "Full")
				if next=TV.GetParent(item)
					break
			if item=0||TV.GetParent(item)!=next
				break
			k:=(IsNumber(k := TV.GetText(item)))?k+0:SubStr(k,2,-1),v:=obj[k]
            LV.Add(((IsObject(v) || IsObject(k)) ? "Check" : "") (text = (IsObject(k) ? (Chr(177) Type(k) " " (ObjPtr(k))) : Type(k)="String"?"'" k "'":k) ? (LV_CurrRow := A_Index, " Select"):"")
						, IsObject(k)?(Chr(177) Type(k) " " (ObjPtr(k))):Type(k)="String"?"'" k "'":k, IsObject(v)?(Chr(177) Type(v) " " (this.BaseType(v).Name="Func"?v.name:(ObjPtr(v)))):Type(v)="String"?"'" v "'":v, item)
			If (LV_CurrRow=A_Index)
				LV.Modify(LV_CurrRow, "Vis Select"), this.EditValue.Enabled := !IsObject(v)&&!ReadOnly, this.EditValue.Text := v, this.EditKey.Enabled := IsObject(k)||ReadOnly||InStr("ArrayStruct",this.TypeOf(obj))?false:true, this.EditKey.Text := k, LV.opt(this.EditKey.Enabled ? "-ReadOnly" : "ReadOnly")
		}
		Loop 2
			LV.ModifyCol(A_Index, "AutoHdr") ;autofit contents
	}
	LVCheck(TV, LV, item, p*){
		if LV.GetCount()<item
			return
		LV.Modify(LV.GetNext("Selected"), "-Select"), LV.Modify(item, "Select"), this.LVSelect(TV, LV, item), LV.Modify(item, (TV.GetChild(LV.GetText(item, 3))?"":"-") "Check")
	}
	LVEdit(TV, LV, item, p*){
		id := LV.GetText(item, 3)+0	, obj := this.items[id], key := TV.GetText(id), newkey := LV.GetText(item), IsNumber(newkey)?"":LV.Modify(item, , "'" newkey "'")
		Loop this.ReadOnlyLevel
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return (this.gui.Opt("+OwnDialogs"), LV.Modify(item, , key), MsgBox("New Items can be edited only from level " this.ReadOnlyLevel "!"))
		If Obj.Has(newKey)
			Return (this.gui.Opt("+OwnDialogs"), LV.Modify(item, , key), MsgBox("Key " newKey " already exists"))
		obj[newkey] := obj[key:=IsNumber(key)?key+0:SubStr(key,2,-1)],obj.Delete(key),TV.Modify(id, ,IsNumber(newkey)?newkey:"'" newkey "'")
		,this.items[id]=this.newObj?TV.Modify(0,"Sort"):TV.Modify(this.items[this.items[id]], "Sort"),LV.ModifyCol(1, "Sort"),this.EditKey.Text := newkey, this.changed := 1
	}
	LVSelect(TV, LV, item, p*){
		local ReadOnly:=0
		if !item
			return (this.EditKey.Text:=this.EditValue.Text := "",this.EditKey.Enabled:=this.EditValue.Enabled:=false)
		;~ if LV.GetCount()<item
			;~ return
		TV.Modify(id := LV.GetText(item, 3)+0, "Select")
		Loop this.ReadOnlyLevel
			if !TV_Item := TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly := 1
		key:=this.EditKey.Text := IsNumber(text := LV.GetText(item))?text+0:SubStr(text,2,-1),obj:=this.items[id],this.EditKey.Enabled := ReadOnly||this.BaseType(obj).Name="Array"||this.BaseType(obj).Name="Struct"?false:true
		if !IsObject(this.items[id][key]){
			this.EditValue.Enabled := !ReadOnly, this.EditValue.Text := this.items[id][IsNumber(text:=LV.GetText(item))?text+0:SubStr(text,2,-1)]
		} else this.EditValue.Text := "", this.EditValue.Enabled := false
	}
	LVDoubleClick(TV, LV, p*){
		if IsObject(value := this.items[TV.GetSelection()][SubStr(key := LV.GetText(LV.GetNext("Selected")),-1)="'"?SubStr(key,2,-1):key+0])
			try TV.Modify(item := this.items[value], "+Expand Select"), (item := TV.GetChild(item))?this.TVSelect(LV, TV, item):(this.gui.Opt("+OwnDialogs"), MsgBox("Object `"" key "`" is empty!"))
	}
}
/*
  Function:		Attach
          Determines how a control is resized with its parent.

  hCtrl:			
          - hWnd of the control if aDef is not empty.					
          - hWnd of the parent to be reset if aDef is empty. If you omit this parameter function will use
          the first hWnd passed to it.
          With multiple parents you need to specify which one you want to reset.					
          - Handler name, if parameter is string and aDef is empty. Handler will be called after the function has finished 
          moving controls for the parent. Handler receives hWnd of the parent as its only argument.

  aDef:			
          Attach definition string. Space separated list of attach options. If omitted, function working depends on hCtrl parameter.
          You can use following elements in the definition string:
          
          - 	"x, y, w, h" letters along with coefficients, decimal numbers which can also be specified in m/n form (see example below).
          -   "r". Use "r1" (or "r") option to redraw control immediately after repositioning, set "r2" to delay redrawing 100ms for the control
            (prevents redrawing spam).
          -	"p" (for "proportional") is the special coefficient. It will make control's dimension always stay in the same proportion to its parent 
            (so, pin the control to the parent). Although you can mix pinned and non-pinned controls and dimensions that is rarely what you want. 
            You will generally want to pin every control in the parent.
          -	"+" or "-" enable or disable function for the control. If control is hidden, you may want to disable the function for 
            performance reasons, especially if control is container attaching its children. Its perfectly OK to leave invisible controls 
            attached, but if you have lots of them you can use this feature to get faster and more responsive updates. 
            When you want to show disabled hidden control, make sure you first attach it back so it can take its correct position
            and size while in hidden state, then show it. "+" must be used alone while "-" can be used either alone or in Attach definition string
            to set up control as initially disabled.

  Remarks:
          Function monitors WM_SIZE message to detect parent changes. That means that it can be used with other eventual container controls
          and not only top level windows.

          You should reset the function when you programmatically change the position of the controls in the parent control.
          Depending on how you created your GUI, you might need to put "autosize" when showing it, otherwise resetting the Gui before its 
          placement is changed will not work as intented. Autosize will make sure that WM_SIZE handler fires. Sometimes, however, WM_SIZE
          message isn't sent to the window. One example is for instance when some control requires Gui size to be set in advance in which case
          you would first have "Gui, Show, w100 h100 Hide" line prior to adding controls, and only Gui, Show after controls are added. This
          case will not trigger WM_SIZE message unless AutoSize is added.
        
        
  Examples:
  (start code)
          Attach(h, "w.5 h1/3 r2")	;Attach control's w, h and redraw it with delay.
          Attach(h, "-")				;Disable function for control h but keep its definition. To enable it latter use "+".
          Attach(h, "- w.5")			;Make attach definition for control but do not attach it until you call Attach(h, "+").
          Attach()					;Reset first parent. Use when you have only 1 parent.
          Attach(hGui2)				;Reset Gui2.
          Attach("Win_Redraw")		;Use Win_Redraw function as a Handler. Attach will call it with parent's handle as argument.
          Attach(h, "p r2")			;Pin control with delayed refreshing.

          
          ; This is how to do delayed refresh of entire window.
          ; To prevent redraw spam which can be annoying in some cases, ; you can choose to redraw entire window only when user has finished resizing it.
          ; This is similar to r2 option for controls, except it works with entire parent.
          
          Attach("OnAttach")			;Set Handler to OnAttach function
          ...
          
          OnAttach( Hwnd ) {
            global hGuiToRedraw := hwnd
            SetTimer, Redraw, -100
          }

          Redraw:
            Win_Redraw(hGuiToRedraw)
          return
  (end code)
  Working sample:
  (start code)
    #SingleInstance, force
      Gui, +Resize
      Gui, Add, Edit, HWNDhe1 w150 h100
      Gui, Add, Picture, HWNDhe2 w100 x+5 h100, pic.bmp 

      Gui, Add, Edit, HWNDhe3 w100 xm h100
      Gui, Add, Edit, HWNDhe4 w100 x+5 h100
      Gui, Add, Edit, HWNDhe5 w100 yp x+5 h100
      
      gosub SetAttach					;comment this line to disable Attach
      Gui, Show, autosize			
    return

    SetAttach:
      Attach(he1, "w.5 h")		
      Attach(he2, "x.5 w.5 h r")
      Attach(he3, "y w1/3")
      Attach(he4, "y x1/3 w1/3")
      Attach(he5, "y x2/3 w1/3")
    return
  (end code)

  About:
      o 1.1 by majkinetor
      o Licensed under BSD <http://creativecommons.org/licenses/BSD/> 
 */
ObjTree_Attach(hCtrl := "", aDef := "") {
   ObjTree_Attach_(hCtrl, aDef, "", "")
}

ObjTree_Attach_(hCtrl, aDef, Msg, hParent){
  static
  static Handler := "", adrWindowInfo := "", adrSetWindowPos := ""
  local s1, s2, enable := 0, reset := 0, oldCritical
  ListLines "Off"
  if (aDef = "") {							;Reset if integer, Handler if string
    if IsFunc(hCtrl)
      return Handler := hCtrl
  
    If adrWindowInfo=""
      return			;Resetting prior to adding any control just returns.
    hParent := hCtrl != "" ? hCtrl+0 : hGui
    loop parse, _%hParent%a, A_Space
    {
      hCtrl := A_LoopField, SubStr(_%hCtrl%, 1, 1), aDef := SubStr(_%hCtrl%, 1, 1)="-" ? SubStr(_%hCtrl%, 2) : _%hCtrl%, _%hCtrl% := ""
      _%hCtrl% := ""
      DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), lx := NumGet(B, 20, "UInt"), ly := NumGet(B, 24, "UInt"), DllCall(adrWindowInfo, "ptr", hCtrl, "ptr", adrB)
			, cx := NumGet(B, 4, "UInt"), cy := NumGet(B, 8, "UInt"), cw := NumGet(B, 12, "UInt")-cx, ch := NumGet(B, 16, "UInt")-cy, cx-=lx, cy-=ly
      loop parse, aDef, A_Space
      {
        z := StrSplit(A_LoopField, ":")
        z1 := z.1
        _%hCtrl% .= A_LoopField="r" ? "r " : (z[1] ":" z[2] ":" c%z1% " ")
      }
      _%hCtrl% := SubStr(_%hCtrl%, 1, -1)				
    }
    reset := 1, _%hParent%_s := _%hParent%_pw " " _%hParent%_ph
  }

  if (hParent = "")  {						;Initialize controls 
    if !adrSetWindowPos
      adrSetWindowPos := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "user32", "PTR"), "astr", "SetWindowPos", "ptr")
      , adrWindowInfo := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "user32", "PTR"), "astr", "GetWindowInfo", "ptr")
      , OnMessage(5, A_ThisFunc), B:=BufferAlloc(60), NumPut("PTR", 60, B.Ptr), adrB := B.Ptr
      , hGui := DllCall("GetParent", "ptr", hCtrl, "ptr") 

    hParent := DllCall("GetParent", "ptr", hCtrl, "ptr") 
    
    if !IsSet(_%hParent%_s)
      DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), _%hParent%_pw := NumGet(B, 28, "UInt") - NumGet(B, 20, "UInt"), _%hParent%_ph := NumGet(B, 32, "UInt") - NumGet(B, 24, "UInt"), _%hParent%_s := !_%hParent%_pw || !_%hParent%_ph ? "" : _%hParent%_pw " " _%hParent%_ph
    
    if InStr(" " aDef " ", "p")
      aDef := StrReplace(aDef, "p", "xp yp wp hp", 0, tmp, 1)
    if aDef="-"
      return SubStr(_%hCtrl%, 1, 1) != "-" ? _%hCtrl% := "-" _%hCtrl% : ""
    else if (aDef = "+")
      if SubStr(_%hCtrl%, 1, 1) != "-" 
         return
      else _%hCtrl% := SubStr(_%hCtrl%, 2), enable := 1 
    else {
      DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), lx := NumGet(B, 20, "UInt"), ly := NumGet(B, 24, "UInt"), DllCall(adrWindowInfo, "ptr", hCtrl, "ptr", adrB)
			, cx := NumGet(B, 4, "UInt"), cy := NumGet(B, 8, "UInt"), cw := NumGet(B, 12, "UInt")-cx, ch := NumGet(B, 16, "UInt")-cy, cx-=lx, cy-=ly
	  if hCtrl<0
		return
      _%hCtrl% := ""
      loop parse, aDef, A_Space
      {			
        if (l := A_LoopField) = "-"	{
          _%hCtrl% := "-" _%hCtrl%
          continue
        }
        f := SubStr(l, 1, 1), k := StrLen(l)=1 ? 1 : SubStr(l, 2)
        if (j := InStr(l, "/"))
          k := SubStr(l, 2, j-2) / SubStr(l, j+1)
        _%hCtrl% .= f ":" k ":" c%f% " "
      }
      return (_%hCtrl% := SubStr(_%hCtrl%, 1, -1), (IsSet(_%hParent%a) ? (_%hParent%a .= InStr(_%hParent%a, hCtrl) ? "" : (_%hParent%a = "" ? "" : " ")) : "")  hCtrl)
    }
  }
  if (!IsSet(_%hParent%a) || _%hParent%a="")
    return				;return if nothing to anchor.

  if !reset && !enable {					
    _%hParent%_pw := aDef & 0xFFFF, _%hParent%_ph := aDef >> 16
    if _%hParent%_ph=0
      return		;when u create gui without any control, it will send message with height=0 and scramble the controls ....
  } 

  if !_%hParent%_s
    _%hParent%_s := _%hParent%_pw " " _%hParent%_ph

  oldCritical := A_IsCritical
  critical 5000

  s := StrSplit(_%hParent%_s, A_Space)
  loop parse, _%hParent%a, A_Space
  {
    hCtrl := A_LoopField, aDef := _%hCtrl%, uw := uh := ux := uy := r := 0, hCtrl1 := SubStr(_%hCtrl%, 1, 1)
    if (hCtrl1 = "-")
      if reset=""
        continue
      else aDef := SubStr(aDef, 2)	
    
    DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), lx := NumGet(B, 20, "UInt"), ly := NumGet(B, 24, "UInt"), DllCall(adrWindowInfo, "ptr", hCtrl, "ptr", adrB)
			, cx := NumGet(B, 4, "UInt"), cy := NumGet(B, 8, "UInt"), cw := NumGet(B, 12, "UInt")-cx, ch := NumGet(B, 16, "UInt")-cy, cx-=lx, cy-=ly
    loop parse, aDef, A_Space
    {
      z := StrSplit(A_LoopField, ":")		; opt:coef:initial
      If z[1]="r"
        r := z[2]
      z1 := z[1]
      if z[2]="p"
         c%z1% := z[3] * (z[1]="x" || z[1]="w" ?  _%hParent%_pw/s[1] : _%hParent%_ph/s[2]), u%z1% := true
      else c%z1% := z[3] + z[2]*(z[1]="x" || z[1]="w" ?  _%hParent%_pw-s[1] : _%hParent%_ph-s[2]), u%z1% := true
    }
    flag := 4 | (r=1 ? 0x100 : 0) | (uw OR uh ? 0 : 1) | (ux OR uy ? 0 : 2)			; nozorder=4 nocopybits=0x100 SWP_NOSIZE=1 SWP_NOMOVE=2
    ;m(hParent, _%hParent%a, hCtrl, _%hCtrl%)
    DllCall(adrSetWindowPos, "ptr", hCtrl, "ptr", 0, "uint", cx, "uint", cy, "uint", cw, "uint", ch, "uint", flag)
    r+0=2 ? ObjTree_Attach_redrawDelayed(hCtrl) : ""
  }
  critical oldCritical
  return Handler != "" ? %Handler%(hParent) : ""
}

ObjTree_Attach_redrawDelayed(hCtrl){
  static s
  s .= !InStr(s, hCtrl) ? hCtrl " " : ""
  SetTimer A_ThisFunc, -100
  return
 Attach_redrawDelayed:
  loop parse, s, A_Space
    DllCall("InvalidateRect", "ptr", A_LoopField, "ptr", 0, "int", true)
  s := ""
 return
}