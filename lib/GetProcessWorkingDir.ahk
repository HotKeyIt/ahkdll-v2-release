; ProcessExist,PID, notepad.exe
; If !PID
  ; Run notepad.exe,,,PID
; MsgBox % GetProcessWorkingDir(PID)
GetProcessWorkingDir(PID){
  static PROCESS_ALL_ACCESS:=0x1F0FFF,MEM_COMMIT := 0x1000,MEM_RELEASE:=0x8000,PAGE_EXECUTE_READWRITE:=64
        ,GetCurrentDirectoryW,len:=VarSetCapacity(GetCurrentDirectoryW,1024,00),l:=DllCall("LoadLibrary","Str","kernel32.dll"),u
        ,init:=DllCall("RtlMoveMemory","PTR",&GetCurrentDirectoryW,"PTR",u:=DllCall("GetProcAddress","PTR",l,"AStr","GetCurrentDirectoryW","PTR"),"PTR",len)
              NumPut(NumGet(&GetCurrentDirectoryW,7,"UCHAR")-A_PtrSize,&GetCurrentDirectoryW,7,"UCHAR")
  ;~ GetCurrentDirectoryW,init:=MCode(GetCurrentDirectoryW,"8BFF558BECFF75088B450803C050FF15A810807CD1E85DC20800")
  
  ;~ Loop 31
    ;~ MsgBox % format("{1:X}",NumGet(&GetCurrentDirectoryW,A_Index-1,"UCHAR")) "`n" A_Index
  ;~ MsgBox % format("{1:X}",NumGet(&GetCurrentDirectoryW+7,"UCHAR"))
  nDirLength := VarSetCapacity(nDir, 512, 0)
  
  hProcess := DllCall("OpenProcess", "UInt", PROCESS_ALL_ACCESS, "Int",0, "UInt", PID)
  if !hProcess 
    return
  pBufferRemote := DllCall("VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "PTR", nDirLength + 1, "UInt", MEM_COMMIT, "UInt", PAGE_EXECUTE_READWRITE, "Ptr")

  pThreadRemote := DllCall("VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "PTR", len, "UInt", MEM_COMMIT, "UInt", PAGE_EXECUTE_READWRITE, "Ptr")
  GetCurrentDirectoryW:=RegisterCallback("ThreadProc","",1)
  DllCall("WriteProcessMemory", "Ptr", hProcess, "Ptr", pThreadRemote, "Ptr", &GetCurrentDirectoryW, "PTR", len, "Ptr", 0)

  If hThread := DllCall("CreateRemoteThread", "PTR", hProcess, "UInt", 0, "UInt", 0, "PTR", pThreadRemote, "PTR", pBufferRemote, "UInt", 0, "UInt", 0)
  {
    DllCall("WaitForSingleObject", "PTR", hThread, "UInt", 0xFFFFFFFF)
    DllCall("GetExitCodeThread", "PTR", hThread, "UIntP", lpExitCode)
    ;~ MsgBox % lpExitCode
    If lpExitCode {
      DllCall("ReadProcessMemory", "PTR", hProcess, "PTR", pBufferRemote, "PTR", &nDir, "PTR", lpExitCode*2, "UInt", 0)
      VarSetCapacity(nDir,-1)
    }
    DllCall("CloseHandle", "PTR", hThread)
  }
  DllCall("VirtualFreeEx","PTR",hProcess,"PTR",pBufferRemote,"PTR",nDirLength + 1,MEM_RELEASE)
  DllCall("VirtualFreeEx","PTR",hProcess,"PTR",pThreadRemote,"PTR",31,MEM_RELEASE)
  DllCall("CloseHandle", "PTR", hProcess)

  return nDir
}

ThreadProc(p){
  MsgBox ja
}