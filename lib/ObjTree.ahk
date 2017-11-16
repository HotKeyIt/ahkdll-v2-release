;~ ObjTree2:=ObjTree(Yaml("a very very long line with some stupid information data lkj lkjlk ölk jölkj öljk ölk jöljl jölö ljölj :`n  - test`n  - what",0)
		;~ ,"My ObjTree Gui Title","-ReadOnly")

ObjTree2:=ObjTree({MyObject:{"Key With Object":["a","This is a test","b",2]}
					,"Another Object":{Key:["c",1,"d",2]}
					,"Empty Object":[]
					,"Another Object 2":["e",1,"f",2]}
		,"My ObjTree Gui Title","-ReadOnly,Edit=wrap"
		,{MyObject:{"Key With Object":"This is a an object`nKey is a string and value is object"}
					,"Another Object":{Key:"This is an object"}
					,"Empty Object":"This object is empty"
					,"Another Object 2":"Another object"})
WinWaitClose "ahk_id " ObjTree2.hwnd

ObjTree(ByRef obj,Title:="ObjTree",Options:="+ReadOnly +Resize,GuiShow=w640 h480",ToolTip:=""){
	return new _ObjTree(obj,Title,Options,ToolTip)
}
Class _ObjTree {
	__New(ByRef obj, Title:="ObjTree",Options:="+ReadOnly +Resize,edit=-wrap,GuiShow=w640 h480",ToolTip:=""){
		If RegExMatch(Options,"i)^\s*([-\+]?ReadOnly)(\d+)?\s*$",option)
			Options:="+AlwaysOnTop +Resize,GuiShow=w640 h480",this.ReadOnly:=option.1,this.ReadOnlyLevel:=option.2
		else this.ReadOnly:="+ReadOnly"
		Loop Parse, Options, "`,", A_Space
		{
		 opt := Trim(SubStr(A_LoopField,1,InStr(A_LoopField,"=")-1))
		 If RegExMatch(A_LoopField,"i)([-\+]?ReadOnly)(\d+)?",option)
			this.ReadOnly:=option.1,this.ReadOnlyLevel:=option.2
		 If (InStr("Font,GuiShow,Edit",opt))
			%opt% := SubStr(A_LoopField,InStr(A_LoopField,"=") + 1,StrLen(A_LoopField))  
		 else GuiOptions:=RegExReplace(A_LoopField,"i)[-\+]?ReadOnly\s?")
		}
		this.Gui:=GuiCreate(GuiOptions,Title),	this.hwnd:=this.gui.hwnd
		,fun:=this.Close.Bind(this),	this.Gui.OnEvent("Close",fun) ;,	this.Gui.OnEvent("Escape",fun)
		if (Font)
			Gui.SetFont(SubStr(Font,1,Pos := InStr(Font,":") - 1),SubStr(Font,Pos + 2,StrLen(Font)))
		; Get Gui size
		if !RegExMatch(GuiShow,"\b[w]([0-9]+\b).*\b[h]([0-9]+\b)",size)
			size:=[640,480]
		; Get hwnd of new window
		this.Hwnd:=this.gui.hwnd,IsAHK_H:=this.IsAHK_H()
		; Apply Gui options and create Gui
		,this.Gui.AddButton("x0 y0 NoTab Hidden Default","Show/Expand Object")
		,TV:=this.TV:=this.Gui.AddTreeView("xs w" (size.1*0.3) " h" (size.2) " ys " (IsAHK_H?"aw1/3 ah":"") " +0x800 +ReadOnly")
		,LV:=this.LV:=this.Gui.AddListView("x+1 w" (size.1*0.7) " h" (size.2*0.5) " ys " (IsAHK_H?"aw2/3 ah1/2 ax1/3":"") " AltSubmit Checked " this.ReadOnly,"[IsObj] Key/Address|Value/Address| ItemID")
		,fun:=this.TVSelect.Bind(this,LV),	TV.OnEvent("ItemSelect",fun) ,LV.ModifyCol(3,"0")
		,fun:=this.LVSelect.Bind(this,TV),	LV.OnEvent("Click",fun)
		,fun:=this.LVDoubleClick.Bind(this,TV),	LV.OnEvent("DoubleClick",fun)
		,fun:=this.LVEdit.Bind(this,TV),	LV.OnEvent("ItemEdit",fun)
		,fun:=this.LVCheck.Bind(this,TV),	LV.OnEvent("ItemCheck",fun)
		,EditKey:=this.EditKey:=this.Gui.AddEdit("y+1 w" (size.1*0.7) " h" (size.2*0.11) (IsAHK_H?" axr aw2/3 ah1/5 ax1/3 ay1/2 +HScroll":"") " " this.ReadOnly " " Edit)
		,EditKey.Enabled:=false,	fun:=this.EditKeyEdit.Bind(this,TV,LV),EditKey.OnEvent("Change",fun)
		,EditValue:=this.EditValue:=this.Gui.AddEdit("y+1 w" (size.1*0.7) " h" (size.2*0.39) (IsAHK_H?" axr aw2/3 ah3/10 ax1/3 ay1/5 +HScroll":"") " " this.ReadOnly " " Edit)
		,EditValue.Enabled:=false,	fun:=this.EditValueEdit.Bind(this,TV,LV),EditValue.OnEvent("Change",fun)
		; Items will hold TV_Item <> Object relation
		,this.Items:={},	this.obj:=obj
		; Create Menus to be used for all ObjTree windows (ReadOnly windows have separate Menu)
		,fun:=this.TVExpandAll.Bind(this.TV),	Menu("ObjTree" (&this),"Add","E&xpand All",fun)
		,fun:=this.TVCollapseAll.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","C&ollapse All",fun)
		; Convert object to TreeView and create a clone for our object
		; Changes can be optionally saved when ObjTree is closed when -ReadOnly is used
		If (this.ReadOnly="-ReadOnly"){
			this.newObj:=this.CreateClone(obj),this.Items[newObj]:=0,this.TVAdd(this.newObj,0)
			; Add additional Menu items when not Readonly
			,Menu("ObjTree" (&this),"Add"),	fun:=this.TVInsert.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","&Insert",fun)
			,fun:=this.TVInsertChild.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","I&nsertChild",fun)
			,Menu("ObjTree" (&this),"Add"),	fun:=this.TVDelete.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","&Delete",fun)
		} else this.Items[this.newObj:=obj]:=0,this.TVAdd(obj,0)
		if !IsAHK_H{
			ObjTree_Attach(TV.hwnd,"w1/2 h")
			,ObjTree_Attach(LV.hwnd,"w1/2 h1/2 x1/2 y0")
			,ObjTree_Attach(EditKey.hwnd,"w2/2 h1/5 x1/3 y1/2")
			,ObjTree_Attach(EditValue.hwnd,"w2/2 h3/10 x1/3 y1/5")
		}
		this.Tooltip:=ToolTip,	fun:=this.TVContextMenu.Bind(this),		this.TV.OnEvent("ContextMenu",fun),		this.gui.Show(GuiShow)
		,this.WM_Notify:=this.Notify.Bind(this,TV),	OnMessage(78,this.WM_Notify) ;WM_NOTIFY
	}
	IsAHK_H() {   ; Written by SKAN, modified by HotKeyIt
		; www.autohotkey.com/forum/viewtopic.php?p=233188#233188  CD:24-Nov-2008 / LM:27-Oct-2010
		If FSz := DllCall("Version\GetFileVersionInfoSizeW", "Str",A_AhkPath, "UInt",0 ){
		VarSetCapacity( FVI, FSz, 0 ),DllCall("Version\GetFileVersionInfoW", "Str",A_AhkPath, "UInt",0, "UInt",FSz, "PTR",&FVI )
		If DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str","\VarFileInfo\Translation", "PTR*",Transl, "PTR",0 )
			&& (Trans:=format("{1:.8X}",NumGet(Transl+0,"UInt")))
			&& DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str","\StringFileInfo\" SubStr(Trans,-4) SubStr(Trans,1,4) "\FILEVERSION", "PTR*",InfoPtr, "UInt",0 )
			return !!InStr(StrGet(InfoPtr),"H")
		}
	}
	Notify(TV,wParam,lParam){
		static ToolTipText,TVN_GETINFOTIP := 0XFFFFFE70 - 14 - 0 ;TVN_FIRST := 0xfffffe70 / 0=Unicode
		/*
			ObjTree is also used to Monitor messages for TreeView: ObjeTree(obj=wParam,Title=lParam,Options=msg,ishwnd=hwnd)
			when ishwnd is a handle, this routine is taken
		*/
		
		; Check if this message is relevant
		If (NumGet(lParam,A_PtrSize*2,"Uint")!=TVN_GETINFOTIP)
			Return
		; HDR.Item contains the relevant TV_ID
		TV_Text:=TV.GetText(TV_Item:=NumGet(lParam+A_PtrSize*5,"PTR"))
		
		; Check if this GUI uses a ToolTip object that contains the information in same structure as the TreeView
		If ToolTipText:=this.ToolTip { ; Gui has own ToolTip object
			; following will resolve the item in ToolTip object
			object:=[TV_Text],item:=TV_Item
			While item:=TV.GetParent(item)
				object.Push(TV.GetText(item))
			; Resolve our item/value in ToolTip object
			While object.MaxIndex(){
				if !IsObject(ToolTipText){
					ToolTipText:=""
					break
				}
				ToolTipText:=ToolTipText[object.Pop()]
			}
			; Item is not an object and is not empty, display value in ToolTip
			If !IsObject(ToolTipText)&&ToolTipText!=""
				Return NumPut((ToolTipText.="",&ToolTipText),lParam+A_PtrSize*3,"PTR") ;HDR.pszText[""]:=&(ToolTipText.="")
			ToolTipText:=""
		}
		; Gui has no ToolTip object or item could not be resolved
		; Get the value of item and display in ToolTip
		; Check if Item is an object and if so, display first 20 keys (first 50 chars) and values (first 100 chars)
		object:=this.items[TV_Item,TV_Text]
		if !IsObject(object)
			ToolTipText:=object ""
		else If IsObject(object) && IsFunc(object)
			ToolTipText:="[Func]`t`t" object.Name "`nBuildIn:`t`t" object.IsBuiltIn "`nVariadic:`t" object.IsVariadic "`nMinParams:`t" object.MinParams "`nMaxParams:`t" object.MaxParams
		else
			for key,v in object
			{
				ToolTipText.=(ToolTipText?"`n":"") SubStr(key,1,50) (StrLen(key)>50?"...":"") " = " (IsObject(v)?"[Obj] ":SubStr(v,1,100) (StrLen(v)>100?"...":""))
				If (A_Index>20){
					ToolTipText.="`n..."
					break
				}
			}
		Return NumPut(&ToolTipText,lParam+A_PtrSize*3,"PTR") ;(HDR.pszText[""]:=&ToolTipText)
	}
	Close(){
		this.gui.Opt("+OwnDialogs")
		If this.changed && "Yes"=MsgBox("Do you want to save changes?",,4){
			for k,v in this.obj
				this.obj.Delete(k)
			for k,v in this.newObj
				this.obj[k]:=v
		}
		this.newObj:=""
		this.gui.destroy()
		OnMessage(78,this.WM_Notify,0)
	}
	TVContextMenu(TV,Item, IsRightClick){
		TV.Modify(Item)
		Menu "ObjTree" (&this),"Show"
	}
	CreateClone(obj){
		clone:=ObjClone(obj)
		for k,v in obj{
			If IsObject(v)
				clone[k]:=this.CreateClone(v)
		}
		Return clone
	}
	EditKeyEdit(TV,LV){
		static count:=0
		id:=LV.GetText(row:=LV.GetNext("Selected"),3)	,obj:=this.items[id],	key:=TV.GetText(id),	newkey:=this.EditKey.Value
		if newkey=key
			return
		If Obj.HasKey(newKey)
			Return (this.gui.Opt("+OwnDialogs"),this.EditKey.Text:=key,MsgBox("Key " newKey " already exists"))
		obj[newkey]:=obj[key],	obj.Delete(key),	TV.Modify(id,,newkey),	LV.Modify(row,,newkey)
		,TV.Modify(this.items[this.items[id]],"Sort"),	LV.ModifyCol(1,"Sort AutoHdr"),	this.changed:=1
	}
	EditValueEdit(TV,LV){
		this.changed:=1
		,this.items[TV.GetSelection(),LV.GetText(row:=LV.GetNext("Selected"))]:=value:=this.EditValue.Value
		,LV.Modify(Row,,,value)
	}
	TVAdd(obj,parent:=""){
		for k,v in obj
		{
			If (IsObject(v) && !this.Items.Haskey(v))
				this.Items[v]:=this.TV.Add(IsObject(k)?Chr(177) " " (&k):k,parent,"Sort"),this.Items[this.Items[v]]:=obj
				,this.TVAdd(v,this.Items[v])
			else
				this.Items[lastParent:=this.TV.Add(IsObject(k)?Chr(177) " " (&k):k,parent,"Sort")]:=obj
			;~ If (IsObject(k) && !this.Items.HasKey(v))
				;~ this.Items[k]:=this.TV.Add(Chr(177) " " (&k),IsObject(v)?this.Items[v]:lastParent,"Sort"),this.Items[this.Items[k]]:=k
				;~ this.TVAdd(k,this.Items[k])
		}
	}
	TVExpandAll(Menu){
		this.Modify(item:=this.GetSelection(),"+Expand")
		if this.GetChild(item)
			While(item:=this.GetNext(item,"F")) && this.GetParent(item)
				this.Modify(item,"+Expand")
	}
	TVInsert(TV){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		if !parent:=TV.GetParent(obj:=TV.GetSelection())
			item:=this.newObj.Push(obj:=[]),this.items[obj]:=TV.Add(item,,"Sort"),this.items[this.items[obj]]:=obj
		else
			this.Items[item:=this.TV.Add(k:=this.Items[obj].Push(""),parent,"Sort")]:=this.Items[obj]
		this.changed:=1
	}
	TVInsertChild(TV){
		Loop this.ReadOnlyLevel-1
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		this.gui.Opt("+OwnDialogs")
		if !IsObject(v:=this.items[parent:=TV.GetSelection(),k:=TV.GetText(parent)]){
			if "Yes"=MsgBox(k " is not an object, would you like to convert it to object?",,4)
				this.Items[parent,k]:=obj:={(k):v},this.Items[obj]:=TV.Add(k,parent,"Sort")
			else Return
		} else
			this.Items[item:=TV.Add(this.Items[parent,k].Push(""),parent,"Sort")]:=this.Items[parent,k]
		this.changed:=1
	}
	TVDelete(TV){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be deleted only from level " this.ReadOnlyLevel "!")
		k:=TV.GetText(item:=TV.GetSelection())
		If "Yes"=MsgBox("Do you want to Delete " k,,4){
			If IsObject(this.items[item])
				this.TVDeepDelete(TV,item)
			else
				this.items.Delete(item),TV.Delete(item)
			this.changed:=1
		}
	}
	TVDeepDelete(TV,parent){
		If child:=TV.GetChild(parent){
			Loop {
				if TV.GetChild(child)
					this.TVDeepDelete(TV,child)
				this.items[parent].Delete(TV.GetText(child)),	this.items.Delete(this.items[child]),	this.items.Delete(child),	TV.Delete(child),	next:=TV.GetNext(child,"F")
				if TV.GetParent(next)!=parent
					return
				child:=next
			}
		} else 
			this.items[parent].Delete(TV.GetText(parent)),TV.Delete(parent),this.items.Delete(parent)
	}
	TVCollapseAll(TV,parent:=0){
		if parent="C&ollapse All"
			parent:=TV.GetSelection()
		If child:=TV.GetChild(parent)
			Loop {
				if TV.GetChild(child)
					this.TVCollapseAll(TV,child)
				next:=TV.GetNext(child,"F")
				if TV.GetParent(next)!=parent
					return TV.Modify(parent,"-Expand")
				child:=next
			}
	}
	TVSelect(LV,TV,item){
		this.LV.Delete(),	this.EditValue.Text:="",	this.EditValue.Enabled:=false	,text:=TV.GetText(item),	TV.Modify(item,"Select")
		if !TV.Getparent(item)
			obj:=this.newObj,next:=item:=0
		else obj:=this.items[item],next:=item:=TV.GetParent(item)
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly:=1
		Loop {
			While item:=TV.GetNext(item,"Full")
				if next=TV.GetParent(item)
					break
			if item=0||TV.GetParent(item)!=next
				break
			k:=TV.GetText(item),v:=obj[k]
			LV.Add(((IsObject(v)||IsObject(k))?"Check":"") (text=(IsObject(k)?(Chr(177) " " (&k)):k)?(LV_CurrRow:=A_Index," Select"):"")
						,IsObject(k)?(Chr(177) " " (&k)):k,IsObject(v) && IsFunc(v)?"[" (v.IsBuiltIn?"BuildIn ":"") (v.IsVariadic?"Variadic ":"") "Func] " v.Name:IsObject(v)?(Chr(177) " " (&v)):v,item)
			If (LV_CurrRow=A_Index)
				LV.Modify(LV_CurrRow,"Vis Select"),	this.EditValue.Enabled:=!IsObject(v)&&!ReadOnly,	this.EditValue.Text:=v,	this.EditKey.Enabled:=!IsObject(k)&&!ReadOnly,	this.EditKey.Text:=k
		}
		Loop 2
			LV.ModifyCol(A_Index,"AutoHdr") ;autofit contents
	}
	LVCheck(TV,LV,item){
		if LV.GetCount()<item
			return
		LV.Modify(LV.GetNext("Selected"),"-Select"),	LV.Modify(item,"Select"),	this.LVSelect(TV,LV,item),	LV.Modify(item,(TV.GetChild(LV.GetText(item,3))?"":"-") "Check")
	}
	LVEdit(TV,LV,item){
		id:=LV.GetText(item,3)	,obj:=this.items[id],	key:=TV.GetText(id),	newkey:=LV.GetText(item)
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return (this.gui.Opt("+OwnDialogs"),LV.Modify(item,,key),MsgBox("New Items can be edited only from level " this.ReadOnlyLevel "!"))
		If Obj.HasKey(newKey)
			Return (this.gui.Opt("+OwnDialogs"),LV.Modify(item,,key),MsgBox("Key " newKey " already exists"))
		obj[newkey]:=obj[key],	obj.Delete(key),	TV.Modify(id,,newkey),	TV.Modify(this.items[this.items[id]],"Sort"),	LV.ModifyCol(1,"Sort")
		,this.EditKey.Text:=newkey,	this.changed:=1
	}
	LVSelect(TV,LV,item){
		if LV.GetCount()<item
			return
		TV.Modify(id:=LV.GetText(item,3),"Select")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly:=1
		this.EditKey.Enabled:=!ReadOnly,	this.EditKey.Text:=LV.GetText(item)
		if !IsObject(this.items[id,LV.GetText(item)]){
			this.EditValue.Enabled:=!ReadOnly,	this.EditValue.Text:=this.items[id,LV.GetText(item)]
		} else this.EditValue.Text:="",this.EditValue.Enabled:=false
	}
	LVDoubleClick(TV,LV){
		if IsObject(value:=this.items[TV.GetSelection(),key:=LV.GetText(LV.GetNext("Selected"))])
			TV.Modify(item:=this.items[value],"+Expand Select"),(item:=TV.GetChild(item))?this.TVSelect(LV,TV,item):(this.gui.Opt("+OwnDialogs"),MsgBox("Object `"" key "`" is empty!"))
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
          
          - 	"x,y,w,h" letters along with coefficients, decimal numbers which can also be specified in m/n form (see example below).
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
          ; To prevent redraw spam which can be annoying in some cases, 
          ; you can choose to redraw entire window only when user has finished resizing it.
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
ObjTree_Attach(hCtrl:="", aDef:="") {
   ObjTree_Attach_(hCtrl, aDef, "", "")
}

ObjTree_Attach_(hCtrl, aDef, Msg, hParent){
  static
  static Handler:="",adrWindowInfo:="",adrSetWindowPos:=""
  local s1,s2, enable:=0, reset:=0, oldCritical
  ListLines "Off"
  if (aDef = "") {							;Reset if integer, Handler if string
    if IsFunc(hCtrl)
      return Handler := hCtrl
  
    If adrWindowInfo=""
      return			;Resetting prior to adding any control just returns.
    hParent := hCtrl != "" ? hCtrl+0 : hGui
    loop parse, _%hParent%a, A_Space
    {
      hCtrl := A_LoopField, SubStr(_%hCtrl%,1,1), aDef := SubStr(_%hCtrl%,1,1)="-" ? SubStr(_%hCtrl%,2) : _%hCtrl%,  _%hCtrl% := ""
      _%hCtrl%:=""
      gosub Attach_GetPos
      loop parse, aDef, A_Space
      {
        z:=StrSplit(A_LoopField, ":")
        z1:=z.1
        _%hCtrl% .= A_LoopField="r" ? "r " : (z.1 ":" z.2 ":" c%z1% " ")
      }
      _%hCtrl% := SubStr(_%hCtrl%, 1, -1)				
    }
    reset := 1,  _%hParent%_s := _%hParent%_pw " " _%hParent%_ph
  }

  if (hParent = "")  {						;Initialize controls 
    if !adrSetWindowPos
      adrSetWindowPos		:= DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "user32","PTR"),"astr", "SetWindowPos","ptr")
      ,adrWindowInfo		:= DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "user32","PTR"),"astr", "GetWindowInfo","ptr")
      ,OnMessage(5, A_ThisFunc),	VarSetCapacity(B, 60), NumPut(60, B), adrB := &B
      ,hGui := DllCall("GetParent", "ptr", hCtrl, "ptr") 

    hParent := DllCall("GetParent", "ptr", hCtrl, "ptr") 
    
    if !_%hParent%_s
      DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), _%hParent%_pw := NumGet(B, 28,"UInt") - NumGet(B, 20,"UInt"), _%hParent%_ph := NumGet(B, 32,"UInt") - NumGet(B, 24,"UInt"), _%hParent%_s := !_%hParent%_pw || !_%hParent%_ph ? "" : _%hParent%_pw " " _%hParent%_ph
    
    if InStr(" " aDef " ", "p")
      aDef:=StrReplace(aDef, "p", "xp yp wp hp",,1)
    if aDef="-"
      return SubStr(_%hCtrl%,1,1) != "-" ? _%hCtrl% := "-" _%hCtrl% : ""
    else if (aDef = "+")
      if SubStr(_%hCtrl%,1,1) != "-" 
         return
      else _%hCtrl% := SubStr(_%hCtrl%, 2), enable := 1 
    else {
      gosub Attach_GetPos
	  if hCtrl<0
		return
      _%hCtrl% := ""
      loop parse, aDef, A_Space
      {			
        if (l := A_LoopField) = "-"	{
          _%hCtrl% := "-" _%hCtrl%
          continue
        }
        f := SubStr(l,1,1), k := StrLen(l)=1 ? 1 : SubStr(l,2)
        if (j := InStr(l, "/"))
          k := SubStr(l, 2, j-2) / SubStr(l, j+1)
        _%hCtrl% .= f ":" k ":" c%f% " "
      }
      return (_%hCtrl% := SubStr(_%hCtrl%, 1, -1), _%hParent%a .= InStr(_%hParent%, hCtrl) ? "" : (_%hParent%a = "" ? "" : " ")  hCtrl)
    }
  }
  if _%hParent%a=""
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

  s:=StrSplit(_%hParent%_s, A_Space)
  loop parse, _%hParent%a, A_Space
  {
    hCtrl := A_LoopField, aDef := _%hCtrl%, 	uw := uh := ux := uy := r := 0, hCtrl1 := SubStr(_%hCtrl%,1,1)
    if (hCtrl1 = "-")
      if reset=""
        continue
      else aDef := SubStr(aDef, 2)	
    
    gosub Attach_GetPos
    loop parse, aDef, A_Space
    {
      z:=StrSplit(A_LoopField, ":")		; opt:coef:initial
      If z.1="r"
        r := z.2
      z1:=z.1
      if z.2="p"
         c%z1% := z.3 * (z.1="x" || z.1="w" ?  _%hParent%_pw/s.1 : _%hParent%_ph/s.2), u%z1% := true
      else c%z1% := z.3 + z.2*(z.1="x" || z.1="w" ?  _%hParent%_pw-s.1 : _%hParent%_ph-s.2), 	u%z1% := true
    }
    flag := 4 | (r=1 ? 0x100 : 0) | (uw OR uh ? 0 : 1) | (ux OR uy ? 0 : 2)			; nozorder=4 nocopybits=0x100 SWP_NOSIZE=1 SWP_NOMOVE=2
    ;m(hParent, _%hParent%a, hCtrl, _%hCtrl%)
    DllCall(adrSetWindowPos, "ptr", hCtrl, "ptr", 0, "uint", cx, "uint", cy, "uint", cw, "uint", ch, "uint", flag)
    r+0=2 ? ObjTree_Attach_redrawDelayed(hCtrl) : ""
  }
  critical oldCritical
  return Handler != "" ? %Handler%(hParent) : ""

 Attach_GetPos:									;hParent & hCtrl must be set up at this point
    DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), 	lx := NumGet(B, 20,"UInt"), ly := NumGet(B, 24,"UInt"), DllCall(adrWindowInfo, "ptr", hCtrl, "ptr", adrB)
    ,cx :=NumGet(B, 4,"UInt"),	cy := NumGet(B, 8,"UInt"), cw := NumGet(B, 12,"UInt")-cx, ch := NumGet(B, 16,"UInt")-cy, cx-=lx, cy-=ly
 return
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
