unit WebpImage;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Description:	Reader and writer for Webp images                             //
// Version:	0.2                                                           //
// Date:	01-MAR-2025                                                   //
// License:     MIT                                                           //
// Target:	Win64, Free Pascal, Delphi                                    //
// Copyright:	(c) 2025 Xelitan.com.                                         //
//		All rights reserved.                                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses Classes, Graphics, SysUtils, Math, Types, XelitanMem, Dialogs;

type
  TWebPGetInfo = function(const data: PByte; data_size: Cardinal; var width, height: Integer): Integer; cdecl;
  TWebPDecodeBGRA = function(const data: PByte; data_size: Cardinal; var width, height: Integer): PByte; cdecl;
  TWebPEncodeRGBA = function(const rgba: PByte; width, height, stride: Integer; quality: Single; out output: PByte): LongWord; cdecl;
  TWebPFree      = procedure(ptr: Pointer); cdecl;

  { TWebpImage }
type
  TWebpImage = class(TGraphic)
  private
    FBmp: TBitmap;
    FCompression: Integer;
    procedure DecodeFromStream(Str: TStream);
    procedure EncodeToStream(Str: TStream);
  protected
    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;
  //    function GetEmpty: Boolean; virtual; abstract;
    function GetHeight: Integer; override;
    function GetTransparent: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetTransparent(Value: Boolean); override;
    procedure SetWidth(Value: Integer);override;
  public
    procedure SetLossyCompression(Value: Cardinal);
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    constructor Create; override;
    destructor Destroy; override;
    function ToBitmap: TBitmap;
  end;

implementation

var
  WebPGetInfo   : TWebPGetInfo   = nil;
  WebPDecodeBGRA: TWebPDecodeBGRA= nil;
  WebPEncodeRGBA: TWebPEncodeRGBA= nil;
  WebPFree      : TWebPFree      = nil;

{ TWebpImage }

procedure TWebpImage.DecodeFromStream(Str: TStream);
var AWidth, AHeight: Integer;
    Data: PByte;
    P: PByteArray;
    x,y: Integer;
    Mem: array of Byte;
begin
  try
    SetLength(Mem, Str.Size);
    Str.Read(Mem[0], Str.Size);

    if WebPGetInfo(@Mem[0], Str.Size, AWidth, AHeight) = 0 then
      raise Exception.Create('Invalid WebP image');

    Data := WebPDecodeBGRA(@Mem[0], Str.Size, AWidth, AHeight);
    if Data = nil then
      raise Exception.Create('Failed to decode WebP image');

    FBmp.SetSize(AWidth, AHeight);

    for y:=0 to AHeight-1 do begin
      P := FBmp.Scanline[y];

      for x:=0 to AWidth-1 do begin
        P[4*x  ] := Data^; Inc(Data); //B
        P[4*x+1] := Data^; Inc(Data); //G
        P[4*x+2] := Data^; Inc(Data); //R
        P[4*x+3] := Data^; Inc(Data); //A
        end;
      end;
  finally
  end;
end;

procedure TWebpImage.EncodeToStream(Str: TStream);
var AWidth, AHeight: Integer;
    Data: array of Byte;
    x,y: Integer;
    P: PByteArray;
    i: Integer;
    OutData: PByte;
    OutSize: Cardinal;
begin
  AWidth := FBmp.Width;
  AHeight := FBmp.Height;

  try
    SetLength(Data, AHeight*AWidth * 4);
    i := 0;

    for y:=0 to AHeight-1 do begin
      P := Fbmp.ScanLine[y];

      for x:=0 to AWidth-1 do begin
        Data[i  ] := P[4*x+2]; //B
        Data[i+1] := P[4*x+1]; //G
        Data[i+2] := P[4*x  ]; //R
        Data[i+3] := P[4*x+3]; //A
        Inc(i, 4);
      end;
    end;

    OutSize := WebPEncodeRGBA(@Data[0], AWidth, AHeight, AWidth*4, FCompression, OutData);
    Str.Write(OutData^, OutSize);
  finally
  end;
end;

procedure TWebpImage.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  ACanvas.StretchDraw(Rect, FBmp);
end;

function TWebpImage.GetHeight: Integer;
begin
  Result := FBmp.Height;
end;

function TWebpImage.GetTransparent: Boolean;
begin
  Result := False;
end;

function TWebpImage.GetWidth: Integer;
begin
  Result := FBmp.Width;
end;

procedure TWebpImage.SetHeight(Value: Integer);
begin
  FBmp.Height := Value;
end;

procedure TWebpImage.SetTransparent(Value: Boolean);
begin
  //
end;

procedure TWebpImage.SetWidth(Value: Integer);
begin
  FBmp.Width := Value;
end;

procedure TWebpImage.SetLossyCompression(Value: Cardinal);
begin
  FCompression := Value;
end;

procedure TWebpImage.Assign(Source: TPersistent);
var Src: TGraphic;
begin
  if source is tgraphic then begin
    Src := Source as TGraphic;
    FBmp.SetSize(Src.Width, Src.Height);
    FBmp.Canvas.Draw(0,0, Src);
  end;
end;

procedure TWebpImage.LoadFromStream(Stream: TStream);
begin
  DecodeFromStream(Stream);
end;

procedure TWebpImage.SaveToStream(Stream: TStream);
begin
  EncodeToStream(Stream);
end;

constructor TWebpImage.Create;
begin
  inherited Create;

  FBmp := TBitmap.Create;
  FBmp.PixelFormat := pf32bit;
  FBmp.SetSize(1,1);
  FCompression := 90;
end;

destructor TWebpImage.Destroy;
begin
  FBmp.Free;
  inherited Destroy;
end;

function TWebpImage.ToBitmap: TBitmap;
begin
  Result := FBmp;
end;

{$R my_dll.rc}
var lib : TDynLib;
procedure Load;
begin
  try
    lib := DynLib('LIBWEBP');

    WebPGetInfo   := DynFun(lib, 'WebPGetInfo');
    WebPDecodeBGRA:= DynFun(lib, 'WebPDecodeBGRA');
    WebPEncodeRGBA:= DynFun(lib, 'WebPEncodeRGBA');
    WebPFree      := DynFun(lib, 'WebPFree');
  except
  end;
end;

procedure UnLoad;
begin
  DynFree(lib);
end;

initialization
  Load;
  TPicture.RegisterFileFormat('webp','Webp Image', TWebpImage);

finalization
  UnLoad;
  TPicture.UnregisterGraphicClass(TWebpImage);

end.
