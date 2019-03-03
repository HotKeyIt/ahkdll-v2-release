/*
notepad := A_WinDir "\notepad.exe"
if A_Is64bitOS && A_PtrSize = 4
    notepad := A_WinDir "\SysWOW64\notepad.exe"

Run(notepad, , , PID)
WinWaitActive("ahk_pid" PID)

Clipboard := ""
rThread := InjectAhkDll(PID, A_AhkDir "\AutoHotkey.dll", 'Clipboard := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")')
Sleep 500
MsgBox "ModuleHandle of Notepad Process: " Clipboard

OnExit(() => ProcessClose(PID))
ExitApp
*/


InjectAhkDll(PID, dll := "AutoHotkey.dll", script := 0) {
  static PROCESS_ALL_ACCESS := 0x1F0FFF, MEM_COMMIT := 0x1000, MEM_RELEASE := 0x8000, PAGE_EXECUTE_READWRITE := 64
       , hKernel32 := DllCall("LoadLibrary", "Str", "kernel32.dll", "Ptr")
       , LoadLibraryA := DllCall("GetProcAddress", "Ptr", hKernel32, "AStr", "LoadLibraryA", "Ptr")
       , FreeLibrary := DllCall("GetProcAddress", "Ptr", hKernel32, "AStr", "FreeLibrary", "Ptr")
       , Module32First := "Module32First" (A_IsUnicode ? "W" : "")
       , Module32Next := "Module32Next" (A_IsUnicode ? "W" : "")
       , base := {__Call: "InjectAhkDll", __Delete: "InjectAhkDll"}

  static TH32CS_SNAPMODULE := 0x00000008, INVALID_HANDLE_VALUE := -1
       , MAX_PATH := 260, MAX_MODULE_NAME32 := 255, ModuleName := "", init := VarSetCapacity(ModuleName, MAX_PATH * (A_IsUnicode ? 2 : 1))
       , _MODULEENTRY32 := Format("
        (
          DWORD   dwSize;
          DWORD   th32ModuleID;
          DWORD   th32ProcessID;
          DWORD   GlblcntUsage;
          DWORD   ProccntUsage;
          BYTE    *modBaseAddr;
          DWORD   modBaseSize;
          HMODULE hModule;
          TCHAR   szModule[{1:}];
          TCHAR   szExePath[{2:}];
        )", MAX_MODULE_NAME32 + 1, MAX_PATH)

  if IsObject(PID)
  {
    if (dll != "Exec" && script)
      return DllCall("MessageBox", "Ptr", 0, "Str", "Only Exec method can be used here!", "Str", "Error", "UInt", 0)
    if !proc := ProcessExist(PID.PID)
      return
    hProc := DllCall("OpenProcess", "UInt", PROCESS_ALL_ACCESS, "Int", 0, "UInt", PID.PID, "Ptr")
    if !hProc
      return DllCall("MessageBox", "Ptr", 0, "Str", "Could not open process for PID: " PID.PID, "Str", "Error", "UInt", 0)

    if !script ; Free Library in remote process (object is being deleted)
    {
      ; Terminate the thread in ahkdll
      hThread := DllCall("CreateRemoteThread", "Ptr", hProc, "Ptr", 0, "Ptr", 0, "Ptr", PID.ahkTerminate, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
      DllCall("WaitForSingleObject", "Ptr", hThread, "UInt", 0xFFFFFFFF)
    , DllCall("CloseHandle", "Ptr", hThread)

      ; Free library in remote process
      hThread := DllCall("CreateRemoteThread", "Ptr", hProc, "UInt", 0, "UInt", 0, "Ptr", FreeLibrary, "Ptr", PID.hModule, "UInt", 0, "UInt", 0, "Ptr")
      DllCall("WaitForSingleObject", "Ptr", hThread, "UInt", 0xFFFFFFFF)
    , DllCall("CloseHandle", "Ptr", hThread)
    , DllCall("CloseHandle", "Ptr", hProc)
      return
    }

    nScriptLength := VarSetCapacity(nScript, (StrLen(script) + 1) * (A_IsUnicode ? 2 : 1), 0)
  , StrPut(script, &nScript)

    ; Reserve memory in remote process where our script will be saved
    if !pBufferRemote := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "Ptr", nScriptLength, "UInt", MEM_COMMIT, "UInt", PAGE_EXECUTE_READWRITE, "Ptr")
      return (DllCall("MessageBox", "Ptr", 0, "Str", "Could not reserve memory for process.", "Str", "Error", "UInt", 0)
            , DllCall("CloseHandle", "Ptr", hProc))

    ; Write script to remote process memory
    DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", &nScript, "Ptr", nScriptLength, "Ptr", 0)

    ; Start execution of code
    hThread := DllCall("CreateRemoteThread", "Ptr", hProc, "Ptr", 0, "Ptr", 0, "Ptr", PID.ahkExec, "Ptr", pBufferRemote, "UInt", 0, "Ptr", 0,"Ptr")
    if !hThread
    {
      DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nScriptLength, "UInt", MEM_RELEASE)
    , DllCall("CloseHandle", "Ptr", hProc)
      return DllCall("MessageBox", "Ptr", 0, "Str", "Could not execute script in remote process.", "Str", "Error", "UInt", 0)
    }

    ; Wait for thread to finish
    DllCall("WaitForSingleObject", "Ptr", hThread, "UInt", 0xFFFFFFFF)

    ; Get Exit code returned by ahkExec (1 = script could be executed / 0 = script could not be executed)
    DllCall("GetExitCodeThread", "Ptr", hThread, "UInt*", lpExitCode)
    if !lpExitCode
      return DllCall("MessageBox", "Ptr", 0, "Str", "Could not execute script in remote process.", "Str", "Error", "UInt", 0)

    DllCall("CloseHandle", "Ptr", hThread)
  , DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nScriptLength, "UInt", MEM_RELEASE)
  , DllCall("CloseHandle", "Ptr", hProc)
    return
  }
  else if !hDll := DllCall("LoadLibrary", "Str", dll, "Ptr")
    return (DllCall("MessageBox", "Ptr", 0, "Str", "Could not find " dll " library.", "Str", "Error", "UInt", 0)
          , DllCall("CloseHandle", "Ptr", hProc))
  else
  {
    hProc := DllCall("OpenProcess", "UInt", PROCESS_ALL_ACCESS, "Int", 0, "UInt", DllCall("GetCurrentProcessId"), "Ptr")
    DllCall("GetModuleFileName", "Ptr", hDll, "Ptr", &ModuleName, "UInt", MAX_PATH)
    DllCall("CloseHandle", "Ptr", hProc)
  }

  ; Open Process to PID
  hProc := DllCall("OpenProcess", "UInt", PROCESS_ALL_ACCESS, "Int", 0, "UInt", PID, "Ptr")
  if !hProc
    return DllCall("MessageBox", "Ptr", 0, "Str", "Could not open process for PID: " PID, "Str", "Error", "UInt", 0)

  ; Reserve some memory and write dll path (ANSI)
  nDirLength := VarSetCapacity(nDir, StrLen(dll) + 1, 0)
, StrPut(dll, &nDir, "CP0")

  ; Reserve memory in remote process
  if !pBufferRemote := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "Ptr", nDirLength, "UInt", MEM_COMMIT, "UInt", PAGE_EXECUTE_READWRITE, "Ptr")
    return (DllCall("MessageBox", "Ptr", 0, "Str", "Could not reseve memory for process.", "Str", "Error", "UInt", 0)
          , DllCall("CloseHandle", "Ptr", hProc))

  ; Write dll path to remote process memory
  DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", &nDir, "Ptr", nDirLength, "Ptr", 0)

  ; Start new thread loading our dll
  hThread := DllCall("CreateRemoteThread", "Ptr", hProc, "Ptr", 0, "Ptr", 0, "Ptr", LoadLibraryA, "Ptr", pBufferRemote, "UInt", 0, "Ptr", 0, "Ptr")
  if !hThread
  {
    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nDirLength, "UInt", MEM_RELEASE)
  , DllCall("CloseHandle", "Ptr", hProc)
    return DllCall("MessageBox", "Ptr", 0, "Str", "Could not load " dll " in remote process.", "Str", "Error", "UInt", 0)
  }

  ; Wait for thread to finish
  DllCall("WaitForSingleObject", "Ptr", hThread, "UInt", 0xFFFFFFFF)

  ; Get Exit code returned by thread (HMODULE for our dll)
  DllCall("GetExitCodeThread", "Ptr", hThread, "UInt*", hModule)

  ; Close Thread
  DllCall("CloseHandle", "Ptr", hThread)

  if (A_PtrSize = 8) ; use different method to retrieve base address because GetExitCodeThread returns DWORD only
  {
    hModule := 0, me32 := Struct(_MODULEENTRY32)

    ;  Take a snapshot of all modules in the specified process.
    hModuleSnap := DllCall("CreateToolhelp32Snapshot", "UInt", TH32CS_SNAPMODULE, "UInt", PID, "Ptr")

    if (hModuleSnap != INVALID_HANDLE_VALUE)
    {
      ; reset hModule and set the size of the structure before using it.
      me32.dwSize := sizeof(_MODULEENTRY32)

      ;  Retrieve information about the first module. Exit if unsuccessful
      if !DllCall(Module32First, "Ptr", hModuleSnap, "Ptr", me32[])
      {
        ; Free memory used for passing dll path to remote thread
        DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nDirLength, "UInt", MEM_RELEASE)
      , DllCall("CloseHandle", "Ptr", hModuleSnap) ; Must clean up the snapshot object!
        return false
      }

      ;  Now walk the module list of the process,and display information about each module
      while(A_Index = 1 || DllCall(Module32Next, "Ptr", hModuleSnap, "Ptr", me32[]))
      {
        if (StrGet(me32.szExePath[""]) = dll)
        {
          hModule := me32.modBaseAddr["",""]
          break
        }
      }

      DllCall("CloseHandle","Ptr",hModuleSnap) ; clean up
    }
  }

  hDll := DllCall("LoadLibrary", "Str", dll, "Ptr")

  ; Calculate pointer to ahkdll and ahkExec functions
  ahktextdll := hModule + DllCall("GetProcAddress", "Ptr", hDll, "AStr", "ahktextdll", "Ptr") - hDll
  ahkExec := hModule + DllCall("GetProcAddress", "Ptr", hDll, "AStr", "ahkExec", "Ptr") - hDll
  ahkTerminate := hModule + DllCall("GetProcAddress", "Ptr", hDll, "AStr", "ahkTerminate", "Ptr") - hDll


  if script
  {
    nScriptLength := VarSetCapacity(nScript, (StrLen(script) + 1) * (A_IsUnicode ? 2 : 1), 0)
  , StrPut(script, &nScript)

    ; Reserve memory in remote process where our script will be saved
    if !pBufferScript := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "Ptr", nScriptLength, "UInt", MEM_COMMIT, "UInt", PAGE_EXECUTE_READWRITE, "Ptr")
      return (DllCall("MessageBox", "Ptr", 0, "Str", "Could not reserve memory for process.", "Str", "Error", "UInt", 0)
            , DllCall("CloseHandle", "Ptr", hProc))

    ; Write script to remote process memory
    DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", pBufferScript, "Ptr", &nScript, "Ptr", nScriptLength, "Ptr", 0)

  }
  else
    pBufferScript := 0

  ; Run ahkdll function in remote thread
  hThread := DllCall("CreateRemoteThread", "Ptr", hProc, "Ptr", 0, "Ptr", 0, "Ptr", ahktextdll, "Ptr", pBufferScript, "Ptr", 0, "UInt", 0, "Ptr")
  if !hThread ; could not start ahkdll in remote process
  {
    ; Free memory used for passing dll path to remote thread
    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nDirLength, "UInt", MEM_RELEASE)
  , DllCall("CloseHandle", "Ptr", hProc)
    return DllCall("MessageBox", "Ptr", 0, "Str", "Could not start ahkdll in remote process", "Str", "Error", "UInt", 0)
  }
  DllCall("WaitForSingleObject", "Ptr", hThread, "UInt", 0xFFFFFFFF)
  DllCall("GetExitCodeThread", "Ptr", hThread, "UInt*", lpExitCode)

  ; Release memory and handles
  DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", pBufferRemote, "Ptr", nDirLength, "UInt", MEM_RELEASE)
, DllCall("CloseHandle", "Ptr", hThread)
, DllCall("CloseHandle", "Ptr", hProc)

  if !lpExitCode ; thread could not be created.
    return DllCall("MessageBox", "Ptr", 0, "Str", "Could not create a thread in remote process", "Str", "Error", "UInt", 0)

  return {PID: PID, hModule: hModule, ahkExec: ahkExec, ahkTerminate: ahkTerminate, base: base}
}
