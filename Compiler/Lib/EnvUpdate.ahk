﻿EnvUpdate(){
	static HWND_BROADCAST := 0xFFFF,WM_SETTINGCHANGE := 0x001A
	SendMessage % WM_SETTINGCHANGE, 0,% &"Environment",, ahk_id %HWND_BROADCAST%
}