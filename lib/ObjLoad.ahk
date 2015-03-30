ObjLoad(addr){
  ; Arrays to retrieve type and size from number type
  static type,num
  if !type
    type:=["Char","UChar","Short","UShort","Int","UInt","Int64","UInt64","Double"],num:=[1,1,2,2,4,4,8,8,8]
  If addr+0=""{ ; FileRead Mode
    If !FileExist(addr),return
    else v:=FileRead("*c " addr)
    If ErrorLevel||!FileGetSize(addr),return
    else addr:=&v
  }
  obj:=[],end:=addr+8+(sz:=NumGet(addr,"Int64")),addr+=8
  While addr<end{ ; 9 = Int64 for size and Char for type
    If NumGet(addr,"Char")=-11,k:=ObjLoad(++addr),addr+=8+NumGet(addr,"Int64")
    else if NumGet(addr,"Char")=-10,sz:=NumGet(addr+1,"Int64"),k:=StrGet(addr+9),addr+=sz+9
    else k:=NumGet(addr+1,type[sz:=-NumGet(addr,"Char")]),addr+=num[sz]+1
    If NumGet(addr,"Char")= 11,obj[k]:=ObjLoad(++addr),addr+=8+NumGet(addr,"Int64")
    else if NumGet(addr,"Char")= 10,obj.SetCapacity(k,sz:=NumGet(addr+1,"Int64")),obj[k]:=StrGet(addr+9),DllCall("RtlMoveMemory","PTR",obj.GetAddress(k),"PTR",addr+9,"PTR",sz),addr+=sz+9
    else obj[k]:=NumGet(addr+1,type[sz:=NumGet(addr,"Char")]),addr+=num[sz]+1
  }
  return obj
}
/*
ObjLoad(addr,sz:=""){
  If sz=""{ ; FileRead Mode
    If !FileExist(addr)
      return
    FileGetSize,sz,%addr%
    FileRead,v,*c %addr%
    If ErrorLevel||!sz
      return
    addr:=&v
  }
  end:=addr+sz,  obj:=[]
  While addr<end{
    If NumGet(addr,"Short")=-4,k:=ObjLoad(addr+A_PtrSize+2,sz:=NumGet(addr+2,"PTR")),addr+=sz+2+A_PtrSize
    else if NumGet(addr,"Short")=-1,k:=StrGet(addr+2+A_PtrSize),addr+=NumGet(addr+2,"PTR")*2+A_PtrSize+2
    else      k:=NumGet(addr+2,NumGet(addr,"Short")=-3?"Double":"Int64"),addr+=8+2
    
    If NumGet(addr,"Short")= 4,obj[k]:=ObjLoad(addr+A_PtrSize+2,sz:=NumGet(addr+2,"PTR")),addr+=sz+2+A_PtrSize
    else if NumGet(addr,"Short")= 1,obj.SetCapacity(k,NumGet(addr+2,"PTR")),DllCall("RtlMoveMemory","PTR",obj.GetAddress(k),"PTR",addr+2+A_PtrSize,"PTR",NumGet(addr+2,"PTR")),addr+=NumGet(addr+2,"PTR")+A_PtrSize+2
    else obj[k]:=NumGet(addr+2,NumGet(addr,"Short")=3?"Double":"Int64"),addr+=8+2
  }
  return obj
}