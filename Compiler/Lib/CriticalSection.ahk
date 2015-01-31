CriticalSection(cs:=0){
  static 
  static i:=0,crisec:={base:{__Delete:"criticalsection"}}
  if IsObject(cs){
    Loop i
      DllCall("DeleteCriticalSection",PTR,&c%i%)
    Return i:=0
  } else if cs
    return DllCall("DeleteCriticalSection",PTR,cs),cs
  Return i++,VarSetCapacity(c%i%,24),DllCall("InitializeCriticalSection",PTR,&c%i%),&c%i%
}
