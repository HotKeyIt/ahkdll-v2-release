StaticVar(name,func){
    if (fun:=FindFunc(func))&&mStaticVars:=Struct(_AHKUserFunc,fun).mStaticVars
        Loop mStaticVars.mCount
            If (var:=mStaticVars.mItem[A_Index]).mName = name
                return var
    return []
}