unit XelitanMem;

interface

uses Classes, Types, ZStream, MemoryModule;

type TDynLib = Pointer;

function DynLib(Name: String): TDynLib;
function DynFun(lib: TDynLib; Name: String): Pointer;
procedure DynFree(lib: TDynLib);

implementation

function DynFun(lib: TDynLib; Name: String): Pointer;
begin
  Result := MemoryGetProcAddress(TMemoryModule(lib), PAnsiChar(Name));
end;

procedure DynFree(lib: TDynLib);
begin
  MemoryFreeLibrary(TMemoryModule(lib));
end;

function UnGzip(InStr, OutStr: TStream): Boolean;
type THead = packed record
       Magic: Word;
       Method: Byte;
       Flag: Byte;
       DateTime: Cardinal;
       XFlag: Byte;
       Host: Byte;
     end;
var Head: THead;
    ExtraLen: Word;
    Crc16: Word;
    Zero: Byte;
    Deflate: TDecompressionStream;
    i: Integer;
    Buff: array of Byte;
    Len: Integer;
begin
  Result := False;
  InStr.Read(Head, SizeOf(THead));

  if (Head.Magic <> $8b1f) or (Head.Method <> 8) then Exit;

  if (Head.Flag and 4) = 4 then begin
    InStr.Read(ExtraLen, 2);
    InStr.Position := InStr.Position + ExtraLen;
  end;
  if (Head.Flag and 8) = 8 then begin
    for i:=InStr.Position to InStr.Size do begin
      InStr.Read(Zero, 1);
      if Zero = 0 then break;
    end;
  end;
  if (Head.Flag and 16) = 16 then begin
    for i:=InStr.Position to InStr.Size do begin
      InStr.Read(Zero, 1);
      if Zero = 0 then break;
    end;
  end;
  if (Head.Flag and 2) = 2 then begin
    InStr.Read(Crc16, 2);
  end;

  Deflate := TDecompressionStream.Create(InStr, True);
  SetLength(Buff, 4096);

  try
    while True do begin
      Len := Deflate.Read(Buff[0], 4096);
      OutStr.Write(Buff[0], Len);
      if Len < 4096 then break;
    end;
  finally
    Deflate.Free;
    Result := True;
  end;
end;

function DynLib(Name: String): TDynLib;
var Res: TResourceStream;
    Mem: TMemoryStream;
    Ret: Boolean;
begin
  Res := TResourceStream.Create(HInstance, Name, RT_RCDATA);
  Mem := TMemoryStream.Create;
  Ret := UnGzip(Res, Mem);

  if not Ret then begin
    Mem.Clear;
    Res.Position := 0;
    Mem.CopyFrom(Res, Res.Size);
  end;
  Res.Free;

  Result := MemoryLoadLibary(Mem.Memory);
  Mem.Free;
end;

end.
