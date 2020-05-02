
class VersionRes
{
	Name := ""
	,Data := BufferAlloc(0)
	,IsText := true
	,DataSize := 0
	,Children := []
	
	__New(addr := 0)
	{
		if !addr
			return this
		
		wLength := NumGet(addr, "UShort"), addrLimit := addr + wLength, addr += 2
		,wValueLength := NumGet(addr, "UShort"), addr += 2
		,wType := NumGet(addr, "UShort"), addr += 2
		,szKey := StrGet(addr), addr += 2*(StrLen(szKey)+1), addr := (addr+3)&~3
		,wValueLength ? (this.Data.size := wValueLength*(wType+1)) : 0
		,this.Name := szKey
		,this.DataSize := wValueLength
		,this.IsText := wType
		,DllCall("msvcrt\memcpy", "ptr", this.Data, "ptr", addr, "ptr", this.Data.size, "cdecl"), addr += this.Data.size, addr := (addr+3)&~3
		while addr < addrLimit
		{
			size := (NumGet(addr, "UShort") + 3) & ~3
			,this.Children.Push(VersionRes.new(addr))
			,addr += size
		}
	}
	
	AddChild(node)
	{
		this.Children.Push(node)
	}
	
	GetChild(name)
	{
		for k,v in this.children
			if v.Name = name
				return v
	}
	
	GetText()
	{
		if this.IsText
			return this.Data
	}
	
	SetText(txt)
	{
		size:=this.Data.size:=2*(StrLen(txt)+1)
		DllCall("msvcrt\memcpy","ptr",this.Data,"ptr", &txt, "ptr", size, "cdecl")
		,this.IsText := true
		,this.DataSize := size
	}
	
	GetDataAddr()
	{
		return this.Data.ptr
	}
	
	Save(addr)
	{
		orgAddr := addr
		,addr += 2
		,NumPut(ds:=this.DataSize, addr, "UShort"), addr += 2
		,NumPut(it:=this.IsText, addr, "UShort"), addr += 2
		,addr += 2*StrPut(this.Name, addr, "UTF-16")
		,addr := (addr+3)&~3
		,realSize := ds*(it+1)
		,DllCall("msvcrt\memcpy", "ptr", addr, "ptr", this.Data, "ptr", realSize, "cdecl"), addr += realSize
		,addr := (addr+3)&~3
		for k,v in this.children
			addr += v.Save(addr)
		size := addr - orgAddr
		,NumPut(size, orgAddr, "UShort")
		return size
	}
}
