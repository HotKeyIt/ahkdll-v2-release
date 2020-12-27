GlobalVarsScript(var:="",ByRef object:=0){
  global
  static globalVarsScript
  If (var="")
    Return globalVarsScript
  else if IsByRef(object) {
    If !InStr(globalVarsScript,var ":= Object(" StrPtr(object)  ")`n"){
      If !CriticalObject(object,1)
        object:=CriticalObject(object)
      globalVarsScript .= var ":= CriticalObject(" StrPtr(object) ")`n"
    }
  } else {
    Loop Parse, Var, "|"
      If !InStr(globalVarsScript,"Alias(" A_LoopField "," GetVar(%A_LoopField%) ")`n")
        globalVarsScript:=globalVarsScript . "Alias(" A_LoopField "," GetVar(%A_LoopField%) "+0)`n"
  }
  Return globalVarsScript
}