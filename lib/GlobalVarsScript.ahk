GlobalVarsScript(var:="",size:=102400,ByRef object:=0){
  global
  static globalVarsScript
  If (var="")
    Return globalVarsScript
  else if !size {
    If !InStr(globalVarsScript,var ":= Object(" . &object .  ")`n"){
      If !CriticalObject(object,1)
        object:=CriticalObject(object)
      globalVarsScript .= var ":= CriticalObject(" CriticalObject(object,1) "," CriticalObject(object,2) ")`n"
    }
  } else {
    Loop Parse, Var, "|"
    If !InStr(globalVarsScript,"Alias(" A_LoopField "," GetVar(%A_LoopField%) ")`n"){
      If size
        VarSetCapacity(%A_LoopField%,size,0)
      globalVarsScript:=globalVarsScript . "Alias(" A_LoopField "," GetVar(%A_LoopField%) "+0)`n"
    }
  }
  Return globalVarsScript
}