﻿CriticalSection(cs:=0){
  static 
  if !crisec
    i:=0,crisec:={base:{__Delete:"criticalsection"}}
  if IsObject(cs){
    Loop i
      DeleteCriticalSection(&c%i%)
    Return i:=0
  } else if cs
    return (DeleteCriticalSection(cs),cs)
  Return (i++,VarSetCapacity(c%i%,24),InitializeCriticalSection(&c%i%),&c%i%)
}
