; AutoHotkey v2 alpha

; EnvUpdate: Directly equivalent to the v1 EnvUpdate command.
; Notifies the OS and all running applications that environment
; variable(s) have changed.  For example, after making changes to the
; following registry key on Windows NT/2000/XP or later, EnvUpdate()
; could be used to broadcast the change:
;   HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment
EnvUpdate(){
    static HWND_BROADCAST := 0xFFFF,WM_SETTINGCHANGE := 0x001A
    SendMessage, %WM_SETTINGCHANGE%, 0, Environment,, ahk_id %HWND_BROADCAST%
}