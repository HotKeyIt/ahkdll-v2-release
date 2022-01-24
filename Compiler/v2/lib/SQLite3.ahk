Class SQLite3 {
  __Delete(){
    this.shutdown(),MemoryFreeLibrary(this._library)
  }
  __New(Options:="", dll:=""){
    static Functions:={aggregate_context:"t==ti",auto_extension:"i==t",bind_blob:"i==titit",bind_double:"i==tid",bind_int:"i==tii",bind_int64:"i==ti6",bind_null:"i==ti",bind_text:"i==titit",bind_text16:"i==tiwit",bind_value:"i==tit",bind_zeroblob:"i==tii",bind_parameter_count:"i==t",bind_parameter_index:"i==tt",bind_parameter_name:"t==ti",blob_bytes:"i==t",blob_open:"i==tttt6it*",blob_close:"i==t",blob_read:"i==ttii",blob_reopen:"i==t6",blob_write:"i==ttii",busy_handler:"i==ttt",busy_timeout:"i==ti",changes:"i==t",clear_bindings:"i==t",close:"i==t",close_v2:"i==t",collation_needed:"i==ttt",collation_needed16:"i==ttt",column_blob:"t==ti",column_bytes:"i==ti",column_bytes16:"i==ti",column_double:"d==ti",column_int:"i==ti",column_int64:"6==ti",column_text:"t==ti",column_text16:"s==ti",column_type:"i==ti",column_value:"t==ti",column_count:"i==t",column_name:"t==ti",column_name16:"s==ti",commit_hook:"t==ttt",rollback_hook:"t==ttt",compileoption_used:"i==t",compileoption_get:"t==i",complete:"i==t",complete16:"i==t",context_db_handle:"t==t",create_collation:"i==ttitt",create_collation_v2:"i==ttittt",create_collation16:"i==ttitt",create_function:"i==ttiitttt",create_function16:"i==ttiitttt",create_function_v2:"i==ttiitttt",create_module:"i==tttt",create_module_v2:"i==ttttt",data_count:"i==t",db_config:"i==tittt",db_filename:"t==tt",db_mutex:"t==t",db_handle:"t==t",db_readonly:"i==tt",db_release_memory:"i==t",interrupt:"i==t",db_status:"i==tititi",declare_vtab:"i==tt",enable_load_extension:"i==ti",errcode:"i==t",extended_errcode:"i==t",errmsg:"t==t",errstr:"a==i",errmsg16:"s==t",exec:"i==tattt*",extended_result_codes:"i==ti",file_control:"i==ttit",finalize:"i==t",malloc:"t==i",realloc:"t==ti",free:"t==t",get_table:"i==ttt*ttt*",free_table:"t==t",get_autocommit:"i==t",get_auxdata:"t==ti",set_auxdata:"t==tittt",shutdown:"i==",os_init:"i==",os_end:"i==",last_insert_rowid:"6==t",libversion:"t==",sourceid:"t==",libversion_number:"i==",limit:"i==tii",load_extension:"i==tttt*",log:"t==itttt",memory_used:"6==",memory_highwater:"6==i",mprintf:"t==ttttttttttt",vmprintf:"t==ttttttttttt",snprintf:"t==itttttttttt",vsnprintf:"t==itttttttttt",mutex_alloc:"t==i",mutex_free:"t==t",mutex_enter:"t==t",mutex_try:"i==t",mutex_leave:"t==t",next_stmt:"t==tt",open_v2:"i=tt*it",open:"i==tt*",overload_function:"i==tti",prepare:"i==ttit*t*",prepare_v2:"i==ttit*t*",prepare_v3:"i==ttiit*t*",prepare16:"i==tsit*t*",prepare16_v2:"i==twit*t*",prepare16_v3:"i==twiit*t*",trace:"t==ttt",profile:"t==ttt",randomness:"t==it",release_memory:"i==i",reset:"i==t",reset_auto_extension:"t==",result_blob:"t==ttit",result_double:"t==td",result_error:"t==tti",result_error16:"t==tti",result_error_toobig:"t==t",result_error_nomem:"t==t",result_error_code:"t==ti",result_int:"t==ti",result_int64:"t==t6",result_null:"t==t",result_text:"t==ttit",result_text16:"t==ttit",result_text16le:"t==ttit",result_text16be:"t==ttit",result_value:"t==tt",result_zeroblob:"t==ti",set_authorizer:"i==ttt",sleep:"i==i",soft_heap_limit64:"6==6",sql:"t==t",status:"i==itti",step:"i==t",stmt_busy:"i==t",stmt_readonly:"i==t",stmt_status:"i==tii",strnicmp:"i==tti",stricmp:"i==tti",threadsafe:"i==",total_changes:"i==t",backup_finish:"i==t",backup_init:"t==tata",backup_pagecount:"i==t",backup_remaining:"i==t",backup_step:"i==ti",open16:"i==wt*",db_cacheflush:"i==t",filename_database:"a==a",filename_journal:"a==a",filename_wal:"a==a",wal_checkpoint:"i=tt",wal_checkpoint_v2:"i=ttiii"} ;,enable_shared_cache:"i==i",column_decltype:"t==ti",column_decltype16:"s==ti",progress_handler:"t==titt"
    if !dll
      dll:="sqlite3_x" (A_PtrSize=8?"64":"86") ".dll"
    If !_library:=ResourceLoadLibrary(dll)
      If !_library:=MemoryLoadLibrary(dll)
      MsgBox("Library " dll " not found`n" A_WorkingDirectory "\" dll),ExitApp()
    this._library:=_library
    ,this.initialize:=DynaCall(MemoryGetProcAddress(_library,"sqlite3_initialize"),"i=")
    ,this.config:=DynaCall(MemoryGetProcAddress(_library,"sqlite3_config"),"i=ittt")
    If options 
    {
      If IsObject(options.1)
      {
      for k,v in options
        this.config[v*]
      } else if IsObject(options)
      this.config[options*]
      else this.config[options]
    }
    this.initialize[]
    for func,param in functions
      this[func]:=DynaCall(MemoryGetProcAddress(_library,"sqlite3_" func),param)
  }
  ListClose(){
    ;~ if ListGui=0
      ;~ MsgBox(IsObject(A_EventInfo)),Listvars()
    ListGui.Destroy()
  }
  List(hDB, SQL, BlobToHex:=false){
    static SQLiteGUI1,SQLiteGUI2,SQLiteGUI3,SQLiteGUI4,SQLiteGUI5,SQLiteGUI6,SQLiteGUI7,SQLiteGUI8,SQLiteGUI9,SQLiteGUI10 ;required for AutoHotkeyMini.dll so it does not complain about not existing functions
    if !(types:=this.SQLType(hDB,SQL)) || !SQL:=this.SQLToObj(hDB,SQL,true)
      return false
    for k,v in SQL.RemoveAt(1)
      columns.=(columns?"|":"") v " (" types[A_Index] ")"
    (SQLiteGUI:=GuiCreate("+Resize")).OnEvent("Close",SQLite3.ListClose.Bind(SQLiteGUI))
    SQLiteGUI.OnEvent("Escape",SQLite3.ListClose.Bind(SQLiteGUI))
    LV:=SQLiteGUI.Add("ListView","w640 h480 aw ah ReadOnly",columns)
    for k,v in SQL
    {
      values:=[]
      for l,i in v
      values.Push(types[A_Index]="BLOB"?(BlobToHex&&i.size?BinToHex(i.ptr,i.size):"[Binary data]"):i)
      LV.Add("",values*)
    }
    LV.ModifyCol()
    SQLiteGUI.Show()
    return SQLiteGUI
  }
  Execute(hDB, SQL){
    Loop 50 {
      pzTail:=&SQL,end:=pzTail + StrLen(SQL)*2
      While pzTail!=end 
      {
        if this.prepare16_v3[hDB,pzTail,-1,1,pStmt,pzTail]{
          if this.errcode[hDB]=17
            continue 2
          else
            return "Error Prepare: " A_Index "`n" this.errmsg16[hDB]
        }
        if pStmt=0
          continue
        else if (err:=this.step[pStmt])!=101 && err!=100 {
          if this.errcode[hDB]=17
            continue 2
          else
            return (this.finalize[pStmt],"Error Step: " A_Index "`n" err ": " this.errmsg16[hDB])
        }
        if this.finalize[pStmt]{
          if this.errcode[hDB]=17 {
            Sleep 100
            continue 2
          }
          else
            return "Error Finalize: " A_Index "`n" this.errmsg16[hDB]
        }
      }
      break
    }
  }
  SQLType(hDB, SQL){
    static type:=["int","float","text","blob","text"] ; Use TEXT for 5 instead of NULL
    pzTail:=&SQL,final:=pzTail + StrLen(SQL)*2,res:=[]
    While pzTail!=final
    {
      if this.prepare16_v2[hDB,pzTail,-1,pStmt,pzTail]
      return (ErrorLevel:=this.errmsg16[hDB],"")
      if pStmt=0
      continue
      else if 100=ret:=this.step[pStmt]
      break
      else if ret!=101
      return (this.finalize[pStmt],ErrorLevel:=this.errmsg16[hDB],"")
      if this.finalize[pStmt]
      return (ErrorLevel:=this.errmsg16[hDB],"")
    }
    if ret=101 ; Done
      return
    Loop this.column_count[pStmt]
      res.Push(type[this.column_type[pStmt,A_Index - 1]])
    return (this.finalize[pStmt],res)
  }
  SQLToObj(hDB, SQL, column:=false){
    pzTail:=&SQL,final:=pzTail + StrLen(SQL)*2,res:=[]
    While pzTail!=final
    {
      if this.prepare16_v2[hDB,pzTail,-1,pStmt,pzTail]
        return (ErrorLevel:=this.errmsg16[hDB],"")
      if pStmt=0
        continue
      else if (100=ret:=this.step[pStmt])||ret=101
      {
        if column && !res.Length()
        {
          res.Push(cols := [])
          Loop this.column_count[pStmt]
          cols.Push(this.column_name16[pStmt,A_Index - 1])
        }
        if ret=101
        {
          if this.finalize[pStmt]
          return (ErrorLevel:=this.errmsg16[hDB],"")
          continue
        }
        types:=[]
        Loop ColumnCount:=this.column_count[pStmt]
          types.Push(this.column_type[pStmt,A_Index - 1])
        While ret=100 
        {
          row := res[A_Index + column] := []
          Loop ColumnCount
          (1 = type:=types[A_Index])
            ? row.Push(this.column_int64[pStmt,A_Index - 1])
          : type = 2
            ? row.Push(this.column_double[pStmt,A_Index - 1])
          : type = 4 ;|| types[A_Index] = 5 ; use TEXT for NULL
            ? ((!sz:=this.column_bytes[pStmt,A_Index-1]) ? row.Push() : row.Push(buf:=Buffer(sz)),RtlMoveMemory(buf.ptr,this.column_blob[pStmt,A_Index-1],sz))
          : row.Push(this.column_text16[pStmt,A_Index - 1])
          ret:=this.step[pStmt]
        }
      }
      else
        return (this.finalize[pStmt],ErrorLevel:=this.errmsg16[hDB],"")
      if this.finalize[pStmt]
        return (ErrorLevel:=this.errmsg16[hDB],"")
    }
    return res.Length()?res:""
  }
  SQLToString(hDB, SQL, column:=true, sep:="`t", end:="`r`n"){
    pzTail:=&SQL,final:=pzTail + StrLen(SQL)*2
    While pzTail!=final
    {
      if this.prepare16_v2[hDB,pzTail,-1,pStmt,pzTail]
        return (ErrorLevel:=this.errmsg16[hDB],"")
      if pStmt=0
        continue
      else if (100=ret:=this.step[pStmt])||ret=101
      {
        if column && !res
        {
          res .= this.column_name16[pStmt]
          Loop this.column_count[pStmt] - 1
          res .= sep this.column_name16[pStmt,A_Index]
          res .= end
        }
        if ret=101
        {
          if this.finalize[pStmt]
          return (ErrorLevel:=this.errmsg16[hDB],"")
          continue
        }
        types:=[]
        Loop ColumnCount:=this.column_count[pStmt]
          types.Push(this.column_type[pStmt,A_Index - 1])
        While ret=100 
        {
          if types[1] = 4 ; || types[1] = 5 ; use TEXT for NULL
            hex:=(sz:=this.column_bytes[pStmt,0]) ? BinToHex(this.column_blob[pStmt,0],sz) : "",res .= hex
          else res .= this.column_text16[pStmt,0]
          Loop ColumnCount - 1
            if types[A_Index + 1] = 4 ;|| types[A_Index] = 5 ; use TEXT for NULL
              hex:=(sz:=this.column_bytes[pStmt,A_Index]) ? BinToHex(this.column_blob[pStmt,A_Index],sz) : "",res .= sep hex
            else res .= sep this.column_text16[pStmt,A_Index]
          res .= end,ret:=this.step[pStmt]
        }
      }
      else
        return (this.finalize[pStmt],ErrorLevel:=this.errmsg16[hDB],"")
      if this.finalize[pStmt]
        return (ErrorLevel:=this.errmsg16[hDB],false)
    }
    return res
  }
  SQLToFile(hDB, SQL, path, column:=true, sep:="`t", end:="`r`n"){
    While !hFile:=FileOpen(path,"rw-rwd","UTF-8")
      MsgBox "Could not open " path ".`nMake Sure it is not write protected and not opened in other program","Error accessing File","262148 t3"
    hFile.Length(0) ; delete file content
    pzTail:=&SQL,final:=pzTail + StrLen(SQL)*2
    While pzTail!=final
    {
      if this.prepare16_v2[hDB,pzTail,-1,pStmt,pzTail]
        return (ErrorLevel:=this.errmsg16[hDB],false)
      if pStmt=0
        continue
      else if (100=ret:=this.step[pStmt])||ret=101
      {
        if column && !hFile.Pos
        {
          hFile.Write(this.column_name16[pStmt])
          Loop this.column_count[pStmt] - 1
          hFile.Write(sep this.column_name16[pStmt,A_Index])
          hFile.Write(end)
        }
        if ret=101
        {
          if this.finalize[pStmt]
          return (ErrorLevel:=this.errmsg16[hDB],false)
          continue
        }
        types:=[]
        Loop ColumnCount:=this.column_count[pStmt]
          types.Push(this.column_type[pStmt,A_Index - 1])
        While ret=100
        {
          if types[1] = 4 ;|| types[A_Index] = 5 ; use TEXT for NULL
          hex:=(sz:=this.column_bytes[pStmt,0]) ? BinToHex(this.column_blob[pStmt,0],sz) : "",hFile.Write(hex)
          else
          hFile.Write(this.column_text16[pStmt,0])
          Loop ColumnCount - 1
          if types[A_Index + 1] = 4 ;|| types[A_Index] = 5 ; use TEXT for NULL
            hex:=(sz:=this.column_bytes[pStmt,A_Index]) ? BinToHex(this.column_blob[pStmt,A_Index],sz) : "",hFile.Write(sep hex)
          else
            hFile.Write(sep this.column_text16[pStmt,A_Index])
          hFile.Write(end),ret:=this.step[pStmt]
        }
      }
      else
        return (this.finalize[pStmt],ErrorLevel:=this.errmsg16[hDB],"")
      if this.finalize[pStmt]
        return (ErrorLevel:=this.errmsg16[hDB],"")
    }
    ret:=hFile.Pos?true:false,hFile.Close()
    return ret
  }
  SQLToADO(hDB, SQL, Connection, table, delete:=true, head:=""){
    ComErr:=ComObjError(false)
    If !( conn := ComObjCreate( "ADODB.Connection" ) )
      return MsgBox("Fatal Error: ADODB.Connection is not available.")
    ComObjError(true)
    conn.Open( Connection ) ; open the connection.
    If conn.State!=1
      return (ComObjError(ComErr),"") ; Error already displayed.
    pzTail:=&SQL,final:=pzTail + StrLen(SQL)*2
    While pzTail!=final
    {
      if this.prepare16_v2[hDB,pzTail,-1,pStmt,pzTail]
        return (ComObjError(ComErr),conn.Close(),ErrorLevel:=this.errmsg16[hDB],"")
      if pStmt=0
        continue
      else if (100=ret:=this.step[pStmt])||ret=101
      {
        if !ColumnCount{
          ColumnCount:=this.column_count[pStmt],types := []
          ,ComObjError(false)
          if head
          {
          if !delete
            return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Table must be deleted to apply header, use true for delete parameter!"))
          If !conn.Execute("Create TABLE " table " (" Trim(head,"()") ")")
            return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Syntax error:`nCreate TABLE " table " (" Trim(head,"()") ")"))
          }
          ; use existing columns and types if table exists
          if tbl:=conn.execute("SELECT * FROM " table)
          {
          if ColumnCount != (Fields:=tbl.Fields).Count
            return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Error: Result Query has " ColumnCount " columns but destination table has " oFields.Count " columns."))
          Loop ColumnCount
            types.Push(InStr(".4.5.6.14.131.","." (type:=Fields.Item(A_Index - 1).Type) ".") ? 2 : InStr(".2.3.10.11.16.17.18.19.20.21.139.201.","." type ".") ? 3 : InStr(".128.204.205.","." type ".") ? 4 : 5)
          if delete
            conn.Execute("DELETE * FROM " table)  
          } else { ; table does not exist and head was not given, create it from query
          Loop ColumnCount
            types.Push(this.column_type[pStmt,A_Index - 1]),head.=this.column_name16[pStmt,A_Index - 1] " " ((1=type:=types[A_Index]) ? "Integer" : type=2 ? "double" : type=3 ? "string" : type=5 ? "string" : "OLEObject") ","
                If !conn.Execute("Create TABLE " table " (" RTrim(head,",") ")")
            return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Syntax error:`nCreate TABLE " table " (" RTrim(head,",") ")"))
          }
        }
        if ret=101
        {
          if this.finalize[pStmt]
          return (conn.Close(),ComObjError(ComErr),MsgBox("Error Finalize: " this.errmsg16[hDB]))
          continue
        }
        If !record := ComObjCreate( "ADODB.recordset" )
          return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Fatal Error: ADODB.recordset is not available."))
        record.Open(table,conn,1,3,2) ;adOpenKeyset, adLockOptimistic, adCmdTable
        if record.State!=1
          return (this.finalize[pStmt],conn.Close(),ComObjError(ComErr),MsgBox("Error: could not connect to table " table))
        ComObjError(true)
        While ret=100 
        {
          record.AddNew()
          Loop ColumnCount
          (1 = type := types[A_Index])
            ? (record.Fields.Item(A_Index - 1).Value := this.column_int64[pStmt,A_Index - 1])
          : type = 2
            ? (record.Fields.Item(A_Index - 1).Value := this.column_double[pStmt,A_Index - 1])
          : type = 4  ;|| types[A_Index] = 5 ; use TEXT for NULL 
            ? ((sz:=this.column_bytes[pStmt,A_Index-1])
            ? (arr := ComObjArray(0x11,sz),SafeArrayAccessData(ComObjValue(arr),getvar(parr:=0))
              ,RtlMoveMemory(parr,this.column_blob[pStmt,A_Index-1],sz),SafeArrayUnaccessData(ComObjValue(safearray))
              ,record.Fields.Item(A_Index - 1).AppendChunk(arr),arr:="")
            : "")
          : record.Fields.Item(A_Index - 1).Value := this.column_text16[pStmt,A_Index - 1]
          ret:=this.step[pStmt]
        }
        record.Update(),record.Close()
      }
      else if ret!=101
        return (ComObjError(ComErr),conn.Close(),this.finalize[pStmt],ErrorLevel:=this.errmsg16[hDB],"")
      if this.finalize[pStmt]
        return (ComObjError(ComErr),conn.Close(),ErrorLevel:=this.errmsg16[hDB],"")
    }
    return (conn.Close(),ComObjError(ComErr),true)
  }
  TableDeclType(hDB, table){
    colType:=[]
    if idx:=InStr(table,".")
    {
      for k,v in this.SQLToObj(hDB,"Pragma " SubStr(table,1,idx) "table_info(" SubStr(table,idx+1) ")",false)
        colType.Push(v.3)
    } else
      for k,v in this.SQLToObj(hDB,"Pragma table_info(" table ")",false)
        colType.Push(v.3)
    return colType
  }
  TableFromObj(hDB, source, table, head:="", delete:=true, primary:=""){
    If delete && this.Execute(hDB,"DROP TABLE IF EXISTS " table "`;CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )" (Primary?" WITHOUT ROWID":""))
      return (err:=this.errmsg16[hDB],MsgBox("Error: " err "`n`n" "CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )"),0)
    colType:=this.TableDeclType(hDB,table)
    Loop ColIdx:=colType.Length()
      stmt.="?,"
    this.Exec[hDB,"BEGIN TRANSACTION"]
    if this.prepare16_v2[hDB,"INSERT INTO " table " VALUES (" RTrim(stmt,",") ")",-1,pStmt]
      return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],MsgBox("Error prepare " table "`n" err))
    for k,line in source
      If line.Length()=ColIdx
      {
        Loop ColIdx
          (InStr(columnType:=colType[A_Index],"int"))
          ? this.bind_int64[pStmt,A_Index,line[A_Index]+0]
          : InStr(columnType,"char")||InStr(columnType,"clob")||InStr(columnType,"text")
          ? this.bind_text16[pStmt,A_Index,line[A_Index] "",-1,-1] ;SQLITE_TRANSIENT
          : columnType="blob"  ; || columnType="" ;use text for null
          ? ((binlen:=line.GetCapacity(A_Index))
            ? this.bind_blob[pStmt,A_Index,line.GetAddress(A_Index),binlen,-1] ;SQLITE_TRANSIENT
            : this.bind_null[pStmt,A_Index])
          : InStr(columnType,"double")||InStr(columnType,"real")||InStr(columnType,"floa")
          ? this.bind_double[pStmt,A_Index,line[A_Index]+0]
          : this.bind_text16[pStmt,A_Index,line[A_Index] "",-1,-1] ;SQLITE_TRANSIENT
        If 101!=this.step[pStmt]
          return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],this.finalize[pStmt],MsgBox("Error step " table "`n" err))
        this.reset[pStmt]
      }
    if this.Exec[hDB,"END TRANSACTION"]
      return (this.finalize[pStmt],MsgBox("Error end transaction " table))
    if this.finalize[pStmt]
      return MsgBox("Error finalize " table)
    return true
    }
  TableFromFile(hDB, source, table, head:="", Delimiter:="`t", skip:=0, trim:="", delete:=true, primary:=""){
    If !FileExist(source)||!FileGetSize(source)
      return MsgBox("File " source " does not exist or is empty")
    If delete && errr:=this.Execute(hDB,"DROP TABLE IF EXISTS " table "`;CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )" (Primary?" WITHOUT ROWID":""))
      return (err:=this.errmsg16[hDB],MsgBox("Error: " err " - " errr "`n`n" "CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )" ),0)
    colType:=this.TableDeclType(hDB,table)
    Loop ColIdx:=colType.Length()
      stmt.="?,"
    this.Exec[hDB,"BEGIN TRANSACTION"]
    if this.prepare16_v2[hDB,"INSERT INTO " table " VALUES (" RTrim(stmt,",") ")",-1,pStmt]
      return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],MsgBox("Error prepare " table "`n" err "`nINSERT INTO " table " VALUES (" RTrim(stmt,",") ")"))
    Loop Read, source
      If (A_Index>skip && headLine!=A_LoopReadLine)
      {
        If (SubStr(A_LoopReadLine,1,1) SubStr(A_LoopReadLine,-1) = Delimiter Delimiter)
          line:=StrSplit(SubStr(A_LoopReadLine,2,-1),Delimiter)
        else line:=StrSplit(A_LoopReadLine,Delimiter)
        if line.Length()=ColIdx
        {
          Loop ColIdx
          (InStr(columnType:=colType[A_Index],"int"))
            ? this.bind_int64[pStmt,A_Index,Trim(line[A_Index],trim)+0]
          : columnType="blob"  ; || columnType="" ;use text for null
            ? ((binlen:=StrLen(Trim(line[A_Index],trim))/2)
            ? this.bind_blob[pStmt,A_Index,HexToBin(bin,Trim(line[A_Index],trim)),binlen,-1] ;SQLITE_TRANSIENT
            : this.bind_null[pStmt,A_Index])
          : InStr(columnType,"double")||InStr(columnType,"real")||InStr(columnType,"floa")
            ? this.bind_double[pStmt,A_Index,Trim(line[A_Index],trim)+0]
          ; if InStr(columnType,"char")||InStr(columnType,"clob")||InStr(columnType,"text")
          : this.bind_text16[pStmt,A_Index,Trim(line[A_Index],trim),-1,-1] ;SQLITE_TRANSIENT
          If 101!=this.step[pStmt]
          return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],this.finalize[pStmt],MsgBox("Error step " table "`n" err))
          this.reset[pStmt]
        }
      }
    if this.Exec[hDB,"END TRANSACTION"]
      return (this.finalize[pStmt],MsgBox("Error end transaction " table))
    if this.finalize[pStmt]
      MsgBox("Error finalize " table)
    return true
  }
  TableFromString(hDB, ByRef source, table, head:="", Delimiter:="`t", skip:=0, trim:="", delete:=true, primary:=""){
    If source=""
      return MsgBox("Source is empty")
    If delete && this.Execute(hDB,"DROP TABLE IF EXISTS " table "`;CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )" (Primary?" WITHOUT ROWID":""))
      return (err:=this.errmsg16[hDB],MsgBox("Error: " err "`n`n" "CREATE TABLE " table " ( " head (!Primary?"":",PRIMARY KEY (" primary ")") " )" ),0)
    colType:=this.TableDeclType(hDB,table)
    Loop ColIdx:=colType.Length()
      stmt.="?,"
    this.Exec[hDB,"BEGIN TRANSACTION"]
    if this.prepare16_v2[hDB,"INSERT INTO " table " VALUES (" RTrim(stmt,",") ")",-1,pStmt]
      return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],MsgBox("Error prepare " table "`n" err "`nINSERT INTO " table " VALUES (" RTrim(stmt,",") ")"))
    Loop Parse, source,"`n","`r"
      If (A_Index>skip && headLine!=A_LoopField)
      {
        If (SubStr(A_LoopField,1,1) SubStr(A_LoopField,-1) = Delimiter Delimiter)
          line:=StrSplit(SubStr(A_LoopField,2,-1),Delimiter)
        else line:=StrSplit(A_LoopField,Delimiter)
        if line.Length()=ColIdx
        {  
          Loop ColIdx
          (InStr(columnType:=colType[A_Index],"int"))
            ? this.bind_int64[pStmt,A_Index,Trim(line[A_Index],trim)+0]
          : columnType="blob" ; || columnType="" ;use text for null
            ? ((binlen:=StrLen(Trim(line[A_Index],trim))/2)
            ? this.bind_blob[pStmt,A_Index,HexToBin(bin,Trim(line[A_Index],trim)),binlen,-1] ;SQLITE_TRANSIENT
            : this.bind_null[pStmt,A_Index])
          : InStr(columnType,"double")||InStr(columnType,"real")||InStr(columnType,"floa")
            ? this.bind_double[pStmt,A_Index,Trim(line[A_Index],trim)+0]
          ; if InStr(columnType,"char")||InStr(columnType,"clob")||InStr(columnType,"text")
          : this.bind_text16[pStmt,A_Index,Trim(line[A_Index],trim),-1,-1] ;SQLITE_TRANSIENT
          If 101!=this.step[pStmt]
          return (err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],this.finalize[pStmt],MsgBox("Error step " table "`n" err))
          this.reset[pStmt]
        }
      }
    if this.Exec[hDB,"END TRANSACTION"]
      return (this.finalize[pStmt],MsgBox("Error end transaction " table))
    if this.finalize[pStmt]
      MsgBox("Error finalize " table)
    return true
  }
  TableFromADO(hDB, Connection, Query, table, head:="", delete:=1, primary:="" ) {
    If !(conn := ComObjCreate( "ADODB.Connection" )) ; ||  !(cmd := ComObjCreate("ADODB.Command"))
      Return MsgBox("Fatal Error: ADODB is not available.")
    conn.ConnectionTimeout := 60*60 ; Seconds to wait for a connection to open
    ,conn.CursorLocation := 2 ; adUseServer ; adUseClient
    ,conn.CommandTimeout := 0 ; 10 minute timeout on the actual SQL statement.
    Loop 10 {
        try conn.Open( Connection ) ; open the connection.
        sleep 1000
      } Until conn.State=1
    if conn.State!=1
      return (ComObjError(ComErr),MsgBox("Error: Could not open Connection `n" Connection))
    ; Execute the query statement and process the recordset. > http://www.w3schools.com/ado/ado_ref_recordset.asp
    If ( record := conn.execute( Query ) )
    {
      oFields:=record.Fields
      Loop ColIdx := oFields.Count
        stmt.="?,"
      Loop !head?ColIdx:0
        head.=oFields.Item(A_Index - 1).Name " " (InStr(".4.5.6.14.131.","." (type:=oFields.Item(A_Index - 1).Type) ".") ? "real" : InStr(".2.3.10.11.16.17.18.19.20.21.64.139.","." type ".") ? "int" : InStr(".128.204.205.","." type ".") ? "blob" : InStr(".135.134.","." type ".") ? "datetime" : InStr(".7.133.","." type ".") ? "date" : "text") ","
      If delete && this.Execute(hDB,"DROP TABLE IF EXISTS " table "`;CREATE TABLE " table " ( " RTrim(head,",") (!Primary?"":",PRIMARY KEY (" primary ")") " )" (Primary?" WITHOUT ROWID":""))
        return (record.Close(),conn.Close(),ComObjError(ComErr),err:=this.errmsg16[hDB],MsgBox("Error: " err "`n`n" "CREATE TABLE " table " ( " RTrim(head,",") (!Primary?"":",PRIMARY KEY (" primary ")") " )"),0)
      colType:=this.TableDeclType(hDB,table)
      for k,v in colType
        colType[k]:=v="int"?1:v="blob"?2:InStr(v,"double")||InStr(v,"real")||InStr(v,"float")?3:4
      this.Exec[hDB,"BEGIN TRANSACTION"]
      if this.prepare16_v2[hDB,"INSERT INTO " table " VALUES (" RTrim(stmt,",") ")",-1,pStmt]
        return ((record?record.Close():""),conn.Close(),ComObjError(ComErr),err:=this.errmsg16[hDB],conn.Close(),this.Exec[hDB,"ROLLBACK TRANSACTION"],MsgBox("Error prepare " table "`n" err))
      While IsObject( record )
        If !record.State ; Recordset.State is zero if the recordset is closed, so we skip it.
          record := record.NextRecordset()
        else { ; A row-returning operation returns an open recordset
          Fields := record.Fields
          While !record.EOF
          { ; While the record pointer is not at the end of the recordset...
            Loop ColIdx
              (4=columnType:=colType[A_Index])
                ? this.bind_text16[pStmt,A_Index,Fields.Item( A_Index - 1 ).Value "",-1,-1] ;SQLITE_TRANSIENT ; use TEXT FOR NULL
              : columnType=1
                ? this.bind_int64[pStmt,A_Index,Fields.Item( A_Index - 1 ).Value]
              : columnType=3
                ? this.bind_double[pStmt,A_Index,Fields.Item( A_Index - 1 ).Value] ;StrReplace(Fields.Item( A_Index - 1 ).Value,",",".")
              : ((binlen:=Fields.Item( A_Index - 1 ).ActualSize) ; Get SafeArray and pointer to data to process in sqlite3
                ? (SafeArrayAccessData(ComObjValue(safearray:=Fields.Item( A_Index - 1 ).GetChunk(binlen)),getvar(safearraypdata:=0))
                ,this.bind_blob[pStmt,A_Index,safearraypdata,binlen,-1] ;SQLITE_TRANSIENT
                ,SafeArrayUnaccessData(ComObjValue(safearray)),safearray:="")
                : this.bind_null[pStmt,A_Index])
            If 101!=this.step[pStmt]
              return (record.Close(),conn.Close(),ComObjError(ComErr),err:=this.errmsg16[hDB],this.Exec[hDB,"ROLLBACK TRANSACTION"],this.finalize[pStmt],MsgBox("Error step " table "`n" err))
            this.reset[pStmt],record.MoveNext() ; reset statement move the record pointer to the next row of values
          }
          record := record.NextRecordset() ; Get the next recordset, break the loop on error = end of records.
        }
    } else { ; Show errors.
      Loop (Errors := conn.Errors).Count ; http://www.w3schools.com/ado/ado_ref_error.asp
        Err .= SubStr( str := (Field := Errors.Item( A_Index - 1 )).Description,1 + InStr( str,"]",0,2 + InStr( str,"][",0,0 ) ) ) "`n   Number: " Field.Number ", NativeError: " Field.NativeError ", Source: " Field.Source ", SQLState: " Field.SQLState "`n`n"
      return (conn.Close(),ComObjError(ComErr),MsgBox(RTrim( Err,"`n")))
    }

    ; Close the connection and process the result.
    conn.Close(),ComObjError(ComErr)
    if this.Exec[hDB,"END TRANSACTION"]
      return (this.finalize[pStmt],MsgBox("Error end transaction " table))
    if this.finalize[pStmt]
      return MsgBox("Error finalize " table)
    Return true
  }
}