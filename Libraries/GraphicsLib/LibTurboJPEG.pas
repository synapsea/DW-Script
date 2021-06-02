unit LibTurboJPEG;
{ This unit is automatically generated by Chet:
  https://github.com/neslib/Chet }

{$MINENUMSIZE 4}

interface

uses Windows, SysUtils;

const
  {$IF Defined(WIN32)}
  TURBOJPEG_DLL = 'turbojpeg-32.dll';
  {$ELSEIF Defined(WIN64)}
  TURBOJPEG_DLL = 'turbojpeg-64.dll';
  {$ELSE}
    {$MESSAGE Error 'Unsupported platform'}
  {$ENDIF}

const
  TJ_NUMSAMP = 6;
  TJ_NUMPF = 12;
  TJ_NUMCS = 5;
  TJFLAG_BOTTOMUP = 2;
  TJFLAG_FASTUPSAMPLE = 256;
  TJFLAG_NOREALLOC = 1024;
  TJFLAG_FASTDCT = 2048;
  TJFLAG_ACCURATEDCT = 4096;
  TJFLAG_STOPONWARNING = 8192;
  TJFLAG_PROGRESSIVE = 16384;
  TJFLAG_LIMITSCANS = 32768;
  TJ_NUMERR = 2;
  TJ_NUMXOP = 8;
  TJXOPT_PERFECT = 1;
  TJXOPT_TRIM = 2;
  TJXOPT_CROP = 4;
  TJXOPT_GRAY = 8;
  TJXOPT_NOOUTPUT = 16;
  TJXOPT_PROGRESSIVE = 32;
  TJXOPT_COPYNONE = 64;
  { TODO : Unable to convert function-like macro: }
  (* TJPAD ( width ) ( ( ( width ) + 3 ) & ( ~ 3 ) ) *)
  { TODO : Unable to convert function-like macro: }
  (* TJSCALED ( dimension , scalingFactor ) ( ( dimension * scalingFactor . num + scalingFactor . denom - 1 ) / scalingFactor . denom ) *)
  TJFLAG_FORCEMMX = 8;
  TJFLAG_FORCESSE = 16;
  TJFLAG_FORCESSE2 = 32;
  TJFLAG_FORCESSE3 = 128;
  NUMSUBOPT = TJ_NUMSAMP;
  TJ_BGR = 1;
  TJ_BOTTOMUP = TJFLAG_BOTTOMUP;
  TJ_FORCEMMX = TJFLAG_FORCEMMX;
  TJ_FORCESSE = TJFLAG_FORCESSE;
  TJ_FORCESSE2 = TJFLAG_FORCESSE2;
  TJ_ALPHAFIRST = 64;
  TJ_FORCESSE3 = TJFLAG_FORCESSE3;
  TJ_FASTUPSAMPLE = TJFLAG_FASTUPSAMPLE;
  TJ_YUV = 512;

type
  // Forward declarations
  PPByte = ^PByte;
  PTJScalingFactor = ^TJScalingFactor;
  PTJRegion = ^TJRegion;
  PTJTransform = ^TJTransform;

  TJSAMP = (
    TJSAMP_444 = 0,
    TJSAMP_422 = 1,
    TJSAMP_420 = 2,
    TJSAMP_GRAY = 3,
    TJSAMP_440 = 4,
    TJSAMP_411 = 5);
  PTJSAMP = ^TJSAMP;

  TJPF = (
    TJPF_RGB = 0,
    TJPF_BGR = 1,
    TJPF_RGBX = 2,
    TJPF_BGRX = 3,
    TJPF_XBGR = 4,
    TJPF_XRGB = 5,
    TJPF_GRAY = 6,
    TJPF_RGBA = 7,
    TJPF_BGRA = 8,
    TJPF_ABGR = 9,
    TJPF_ARGB = 10,
    TJPF_CMYK = 11,
    TJPF_UNKNOWN = -1);
  PTJPF = ^TJPF;

  TJCS = (
    TJCS_RGB = 0,
    TJCS_YCbCr = 1,
    TJCS_GRAY = 2,
    TJCS_CMYK = 3,
    TJCS_YCCK = 4);
  PTJCS = ^TJCS;

  TJERR = (
    TJERR_WARNING = 0,
    TJERR_FATAL = 1);
  PTJERR = ^TJERR;

  TJXOP = (
    TJXOP_NONE = 0,
    TJXOP_HFLIP = 1,
    TJXOP_VFLIP = 2,
    TJXOP_TRANSPOSE = 3,
    TJXOP_TRANSVERSE = 4,
    TJXOP_ROT90 = 5,
    TJXOP_ROT180 = 6,
    TJXOP_ROT270 = 7);
  PTJXOP = ^TJXOP;

  TJScalingFactor = record
    num: Integer;
    denom: Integer;
  end;

  TJRegion = record
    x: Integer;
    y: Integer;
    w: Integer;
    h: Integer;
  end;

  TJTransform = record
    r: TJRegion;
    op: Integer;
    options: Integer;
    data: Pointer;
    customFilter: function(coeffs: PSmallint; arrayRegion: TJRegion; planeRegion: TJRegion; componentIndex: Integer; transformIndex: Integer; transform: PTJTransform): Integer; cdecl;
  end;

  TJHandle = Pointer;

const
  TJ_444 = TJSAMP_444;
  TJ_422 = TJSAMP_422;
  TJ_420 = TJSAMP_420;
  TJ_411 = TJSAMP_420;
  TJ_GRAYSCALE = TJSAMP_GRAY;

type
   TLibTurboJPeg = record
      var InitCompress : function : TJHandle; cdecl;

      var Compress2 : function (handle: TJHandle; const srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; jpegBuf: PPByte; jpegSize: PCardinal; jpegSubsamp: TJSAMP; jpegQual: Integer; flags: Integer): Integer; cdecl;
      var CompressFromYUV : function (handle: TJHandle; const srcBuf: PByte; width: Integer; pad: Integer; height: Integer; subsamp: Integer; jpegBuf: PPByte; jpegSize: PCardinal; jpegQual: Integer; flags: Integer): Integer; cdecl;
      var CompressFromYUVPlanes : function (handle: TJHandle; srcPlanes: PPByte; width: Integer; const strides: PInteger; height: Integer; subsamp: Integer; jpegBuf: PPByte; jpegSize: PCardinal; jpegQual: Integer; flags: Integer): Integer; cdecl;

      var BufSize : function (width: Integer; height: Integer; jpegSubsamp: Integer): Cardinal; cdecl;
      var BufSizeYUV2 : function (width: Integer; pad: Integer; height: Integer; subsamp: Integer): Cardinal; cdecl;

      var PlaneSizeYUV : function (componentID: Integer; width: Integer; stride: Integer; height: Integer; subsamp: Integer): Cardinal; cdecl;
      var PlaneWidth : function (componentID: Integer; width: Integer; subsamp: Integer): Integer; cdecl;
      var PlaneHeight : function (componentID: Integer; height: Integer; subsamp: Integer): Integer; cdecl;

      var EncodeYUV3 : function (handle: TJHandle; const srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; dstBuf: PByte; pad: Integer; subsamp: Integer; flags: Integer): Integer; cdecl;
      var EncodeYUVPlanes : function (handle: TJHandle; const srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; dstPlanes: PPByte; strides: PInteger; subsamp: Integer; flags: Integer): Integer; cdecl;

      var InitDecompress : function : TJHandle; cdecl;

      var DecompressHeader3 : function (handle: TJHandle; const jpegBuf: PByte; jpegSize: Cardinal; width: PInteger; height: PInteger; jpegSubsamp: PInteger; jpegColorspace: PInteger): Integer; cdecl;

      var GetScalingFactors : function (numscalingfactors: PInteger): PTJScalingFactor; cdecl;

      var Decompress2 : function (handle: TJHandle; const jpegBuf: PByte; jpegSize: Cardinal; dstBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; flags: Integer): Integer; cdecl;
      var DecompressToYUV2 : function (handle: TJHandle; const jpegBuf: PByte; jpegSize: Cardinal; dstBuf: PByte; width: Integer; pad: Integer; height: Integer; flags: Integer): Integer; cdecl;
      var DecompressToYUVPlanes : function (handle: TJHandle; const jpegBuf: PByte; jpegSize: Cardinal; dstPlanes: PPByte; width: Integer; strides: PInteger; height: Integer; flags: Integer): Integer; cdecl;
      var DecodeYUV : function (handle: TJHandle; const srcBuf: PByte; pad: Integer; subsamp: Integer; dstBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; flags: Integer): Integer; cdecl;
      var DecodeYUVPlanes : function (handle: TJHandle; srcPlanes: PPByte; const strides: PInteger; subsamp: Integer; dstBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; flags: Integer): Integer; cdecl;

      var InitTransform : function (): TJHandle; cdecl;
      var Transform : function (handle: TJHandle; const jpegBuf: PByte; jpegSize: Cardinal; n: Integer; dstBufs: PPByte; dstSizes: PCardinal; transforms: PTJTransform; flags: Integer): Integer; cdecl;

      var Destroy : function (handle: TJHandle): Integer; cdecl;

      var Alloc : function (bytes: Integer): PByte; cdecl;

      var LoadImage : function (const filename: PUTF8Char; width: PInteger; align: Integer; height: PInteger; pixelFormat: TJPF; flags: Integer): PByte; cdecl;
      var SaveImage : function (const filename: PUTF8Char; buffer: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; flags: Integer): Integer; cdecl;

      var Free : procedure (buffer: PByte); cdecl;

      var GetErrorStr2 : function (handle: TJHandle): PUTF8Char; cdecl;

      var GetErrorCode : function (handle: TJHandle): Integer; cdecl;

      var TJBUFSIZE : function (width: Integer; height: Integer): Cardinal; cdecl;

      var TJBUFSIZEYUV : function (width: Integer; height: Integer; jpegSubsamp: Integer): Cardinal; cdecl;

      var BufSizeYUV : function (width: Integer; height: Integer; subsamp: Integer): Cardinal; cdecl;

      var Compress : function (handle: TJHandle; srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelSize: Integer; dstBuf: PByte; compressedSize: PCardinal; jpegSubsamp: Integer; jpegQual: Integer; flags: Integer): Integer; cdecl;

      var EncodeYUV : function (handle: TJHandle; srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelSize: Integer; dstBuf: PByte; subsamp: Integer; flags: Integer): Integer; cdecl;
      var EncodeYUV2 : function (handle: TJHandle; srcBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelFormat: TJPF; dstBuf: PByte; subsamp: Integer; flags: Integer): Integer; cdecl;

      var DecompressHeader : function (handle: TJHandle; jpegBuf: PByte; jpegSize: Cardinal; width: PInteger; height: PInteger): Integer; cdecl;
      var DecompressHeader2 : function (handle: TJHandle; jpegBuf: PByte; jpegSize: Cardinal; width: PInteger; height: PInteger; jpegSubsamp: PInteger): Integer; cdecl;
      var Decompress : function (handle: TJHandle; jpegBuf: PByte; jpegSize: Cardinal; dstBuf: PByte; width: Integer; pitch: Integer; height: Integer; pixelSize: Integer; flags: Integer): Integer; cdecl;
      var DecompressToYUV : function (handle: TJHandle; jpegBuf: PByte; jpegSize: Cardinal; dstBuf: PByte; flags: Integer): Integer; cdecl;

      var GetErrorStr : function : PUTF8Char; cdecl;
   end;

   ETurboJPEG = class (Exception);

function TJ : TLibTurboJPeg;

var vOnNeedTurboJPEGDLLName : function : String;
function LoadTurboJPEG(dllName : String = '') : Boolean;
procedure UnloadTurboJPEG;

procedure RaiseLastTurboJPEGError(handle : TJHandle);

implementation

var
   vTJ : TLibTurboJPeg;
   vTJHandle : THandle;
   vCS : TRTLCriticalSection;

// TJ
//
function TJ : TLibTurboJPeg;
begin
   if vTJHandle = 0 then
      if not LoadTurboJPEG then
         raise  ETurboJPEG.Create('TurboJPEG DLL not available');
   Result := vTJ;
end;

// LoadTurboJPEG
//
function LoadTurboJPEG(dllName : String = '') : Boolean;

   function GetProc(const name : String) : Pointer;
   begin
      Result := GetProcAddress(vTJHandle, PChar('tj' + name));
      Assert(Assigned(Result), 'Missing tj' + name);
   end;


begin
   if dllName = '' then begin
      if Assigned(vOnNeedTurboJPEGDLLName) then
         dllName := vOnNeedTurboJPEGDLLName;
      if dllName = '' then
         dllName := TURBOJPEG_DLL;
   end;

   EnterCriticalSection(vCS);
   try
      if vTJHandle <> 0 then Exit(True);

      vTJHandle := LoadLibrary(PChar(dllName));
      if vTJHandle = 0 then Exit(False);

      vTJ.InitCompress := GetProc('InitCompress');

      vTJ.Compress2 := GetProc('Compress2');
      vTJ.CompressFromYUV := GetProc('CompressFromYUV');
      vTJ.CompressFromYUVPlanes := GetProc('CompressFromYUVPlanes');

      vTJ.BufSize := GetProc('BufSize');
      vTJ.BufSizeYUV2 := GetProc('BufSizeYUV2');

      vTJ.PlaneSizeYUV := GetProc('PlaneSizeYUV');
      vTJ.PlaneWidth := GetProc('PlaneWidth');
      vTJ.PlaneHeight := GetProc('PlaneHeight');

      vTJ.EncodeYUV3 := GetProc('EncodeYUV3');
      vTJ.EncodeYUVPlanes := GetProc('EncodeYUVPlanes');

      vTJ.InitDecompress := GetProc('InitDecompress');

      vTJ.DecompressHeader3 := GetProc('DecompressHeader3');

      vTJ.GetScalingFactors := GetProc('GetScalingFactors');

      vTJ.Decompress2 := GetProc('Decompress2');
      vTJ.DecompressToYUV2 := GetProc('DecompressToYUV2');
      vTJ.DecompressToYUVPlanes := GetProc('DecompressToYUVPlanes');
      vTJ.DecodeYUV := GetProc('DecodeYUV');
      vTJ.DecodeYUVPlanes := GetProc('DecodeYUVPlanes');

      vTJ.InitTransform := GetProc('InitTransform');
      vTJ.Transform := GetProc('Transform');

      vTJ.Destroy := GetProc('Destroy');

      vTJ.Alloc := GetProc('Alloc');

      vTJ.LoadImage := GetProc('LoadImage');
      vTJ.SaveImage := GetProc('SaveImage');

      vTJ.Free := GetProc('Free');

      vTJ.GetErrorStr2 := GetProc('GetErrorStr2');

      vTJ.GetErrorCode := GetProc('GetErrorCode');

      vTJ.TJBUFSIZE := GetProcAddress(vTJHandle, 'TJBUFSIZE');

      vTJ.TJBUFSIZEYUV := GetProcAddress(vTJHandle, 'TJBUFSIZEYUV');

      vTJ.BufSizeYUV := GetProc('BufSizeYUV');

      vTJ.Compress := GetProc('Compress');

      vTJ.EncodeYUV := GetProc('EncodeYUV');
      vTJ.EncodeYUV2 := GetProc('EncodeYUV2');

      vTJ.DecompressHeader := GetProc('DecompressHeader');
      vTJ.DecompressHeader2 := GetProc('DecompressHeader2');
      vTJ.Decompress := GetProc('Decompress');
      vTJ.DecompressToYUV := GetProc('DecompressToYUV');

      vTJ.GetErrorStr := GetProc('GetErrorStr');

      Result := True;
   finally
      LeaveCriticalSection(vCS);
   end;
end;

// UnloadTurboJPEG
//
procedure UnloadTurboJPEG;
begin
   EnterCriticalSection(vCS);
   try
      if vTJHandle = 0 then Exit;

      FreeLibrary(vTJHandle);
      FillChar(vTJ, SizeOf(vTJ), 0);
      vTJHandle := 0;
   finally
      LeaveCriticalSection(vCS);
   end;
end;

// RaiseLastTurboJPEGError
//
procedure RaiseLastTurboJPEGError(handle : TJHandle);
begin
   raise ETurboJPEG.CreateFmt(
      'TurboJPEG error %d: %s',
      [ TJ.GetErrorCode(handle), TJ.GetErrorStr2(handle) ]
   );
end;

initialization

   InitializeCriticalSection(vCS);

finalization

   UnloadTurboJPEG;
   DeleteCriticalSection(vCS);

end.
