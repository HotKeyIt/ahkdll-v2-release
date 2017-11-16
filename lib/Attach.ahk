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
Attach(hCtrl:="", aDef:="") {
   Attach_(hCtrl, aDef, "", "")
}

Attach_(hCtrl, aDef, Msg, hParent){
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
    r+0=2 ? Attach_redrawDelayed(hCtrl) : ""
  }
  critical oldCritical
  return Handler != "" ? %Handler%(hParent) : ""

 Attach_GetPos:									;hParent & hCtrl must be set up at this point
    DllCall(adrWindowInfo, "ptr", hParent, "ptr", adrB), 	lx := NumGet(B, 20,"UInt"), ly := NumGet(B, 24,"UInt"), DllCall(adrWindowInfo, "ptr", hCtrl, "ptr", adrB)
    ,cx :=NumGet(B, 4,"UInt"),	cy := NumGet(B, 8,"UInt"), cw := NumGet(B, 12,"UInt")-cx, ch := NumGet(B, 16,"UInt")-cy, cx-=lx, cy-=ly
 return
}

Attach_redrawDelayed(hCtrl){
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
