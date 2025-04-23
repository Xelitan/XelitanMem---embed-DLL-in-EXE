# XelitanMem - embed DLL in EXE

This library uses https://github.com/Fr0sT-Brutal/Delphi_MemoryModule. Tested on Lazarus 3.8 64 bit.

## What is this for?

This allows you to embed any number of DLLs inside your EXE and use them **directly** from RAM without unpacking to disk.

## Usage example

If you use DLL functions ina static style in your exe:

```
function MyFun(const data: PByte; data_size: Cardinal; var width, height: Integer): Integer; cdecl; external 'my_lib.dll';
```
then you need to change to dynamic style:
```
type TMyFun = function(const data: PByte; data_size: Cardinal; var width, height: Integer): Integer; cdecl;
```
Now instead of using LoadLibrary, GetProcAddress and FreeLibrary you do:

### 1) Add XelitanMem to uses

### 2) Add initialization and finalization sections on the bottom of your .pas file:
```
initialization
  Load; 

finalization
  UnLoad; 
```

### 3) Add and customize these 2 functions somwhere in your .pas file:
```
var MyFun   : TMyFun   = nil; //put this somewhere global

{$R my_dll.rc}
var lib : TDynLib;
procedure Load;
begin
  try
    lib := DynLib('MY_DLL'); //change name of your DLL here

    MyFun   := DynFun(lib, 'MyFun'); //list all your functions here
  except
  end;
end;

procedure UnLoad;
begin
  DynFree(lib);
end; 
```

### 4) Create file my_dll.rc, open in a text editor and enter:
```
MY_DLL         RCDATA "name_of_my_dll.dll"
```

Now the best part- you can use as many .rc files as you want or create 1 big .rc file with many DLLs.
You can gzip your DLLS and put gzipped DLLS in .rc file:
```
MY_DLL         RCDATA "name_of_my_dll.dll.gz"
```
