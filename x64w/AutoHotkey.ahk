Class _LIST { ; List of found items
	Clear(){
    this.Delete(Chr(255)) ;,this.Delete(1,2**(A_PtrSize=8?63:31)-1)
	}
}
;~ LIST_:=CriticalObject(new _LIST)
LIST_:=new _LIST
LIST_.1:=1
hlib:=MemoryLoadLibrary(dll:=A_AHkDir "\AutoHotkeyMini.dll")
DllCall(MemoryGetProcAddress(hlib,"ahktextdll"),"Str","LIST_:=Object(" (&LIST_) ")`nMsgBox `% LIST_.1`nLoop`nToolTip `% A_Index LIST_.Clear()","Str","","CDecl")
MsgBox
;~ LIST_.1:="test"
;~ MsgBox % LIST_.1