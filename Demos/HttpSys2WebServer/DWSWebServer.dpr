{
    Will serve static content and DWS dynamic content via http.sys
    kernel mode high-performance HTTP server (available since XP SP2).
    See http://blog.synopse.info/post/2011/03/11/HTTP-server-using-fast-http.sys-kernel-mode-server

    WARNING:
    * you need to first register the server URI and port to the http.sys stack.
    * or you need to run it as administrator

    The executable can be run either as an application or as service.

    Sample based on official mORMot's samples
    SQLite3\Samples\09 - HttpApi web server\HttpApiServer.dpr
    SQLite3\Samples\10 - Background Http service

    Synopse mORMot framework. Copyright (C) 2012 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

    Original tri-license: MPL 1.1/GPL 2.0/LGPL 2.1

    You would need at least the following files from mORMot framework
    to be available in your project path:
    - SynCommons.pas
    - Synopse.inc
    - SynLZ.pas
    - SynZip.pas
    - SynWinWock.pas
    - mORMotService.pas
    http://synopse.info/fossil/wiki?name=Downloads

}
program DWSWebServer;

{$IFNDEF VER200} // delphi 2009

   {$WEAKLINKRTTI ON}
   {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}

{$APPTYPE CONSOLE}

{$R *.res}

{$R *.dres}

uses
  FastMM4,
  Windows,
  SysUtils,
  dwsWindowsService,
  dwsJSON,
  dwsXPlatform,
  DSimpleDWScript,
  dwsSystemInfoLibModule,
  dwsCompiler,
  UHttpSys2WebServer in 'UHttpSys2WebServer.pas',
//  UCustomUnit in 'UCustomUnit.pas',
  dwsDatabaseLibModule in '..\..\Libraries\DatabaseLib\dwsDatabaseLibModule.pas' {dwsDatabaseLib: TDataModule},
  dwsSynSQLiteDatabase in '..\..\Libraries\DatabaseLib\dwsSynSQLiteDatabase.pas',
  dwsSynODBCDatabase in '..\..\Libraries\DatabaseLib\dwsSynODBCDatabase.pas',
  dwsSynOleDBDatabase in '..\..\Libraries\DatabaseLib\dwsSynOleDBDatabase.pas',
  dwsDatabase in '..\..\Libraries\DatabaseLib\dwsDatabase.pas',
  dwsWMIDatabase in '..\..\Libraries\DatabaseLib\dwsWMIDatabase.pas',
  dwsWebServerLibModule in '..\..\Libraries\SimpleServer\dwsWebServerLibModule.pas' {dwsWebServerLib: TDataModule},
  dwsWebServerInfo in '..\..\Libraries\SimpleServer\dwsWebServerInfo.pas',
  dwsFileFunctions in '..\..\Source\dwsFileFunctions.pas',
  dwsGraphicLibrary in '..\..\Libraries\GraphicsLib\dwsGraphicLibrary.pas',
  dwsBackgroundWorkersLibModule in '..\..\Libraries\SimpleServer\dwsBackgroundWorkersLibModule.pas' {dwsBackgroundWorkersLib: TDataModule},
  dwsEncodingLibModule in '..\..\Libraries\ClassesLib\dwsEncodingLibModule.pas' {dwsEncodingLib: TDataModule},
  dwsHTTPSysServer in '..\..\Libraries\SimpleServer\dwsHTTPSysServer.pas',
  dwsHTTPSysServerEvents in '..\..\Libraries\SimpleServer\dwsHTTPSysServerEvents.pas';

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE or IMAGE_FILE_RELOCS_STRIPPED}

type
   TWebServerHttpService = class(TdwsWindowsService)
      public
         Server: IHttpSys2WebServer;

         procedure DoStart(Sender: TdwsWindowsService);
         procedure DoStop(Sender: TdwsWindowsService);

         constructor Create(aOptions : TdwsJSONValue); override;
         destructor Destroy; override;

         class function DefaultServiceOptions : String; override;

         procedure ExecuteCommandLineParameters(var abortExecution : Boolean); override;
         procedure WriteCommandLineHelpExtra; override;
   end;

{ TWebServerHttpService }

constructor TWebServerHttpService.Create(aOptions : TdwsJSONValue);
begin
   inherited;

   OnStart := DoStart;
   OnStop := DoStop;
   OnResume := DoStart;
   OnPause := DoStop;
end;

destructor TWebServerHttpService.Destroy;
begin
   DoStop(nil);
   inherited;
end;

// DefaultServiceOptions
//
class function TWebServerHttpService.DefaultServiceOptions : String;
begin
   Result :=
      '{'
         // Windows service name
         +'"Name": "DWSServer",'
         // Windows service display name
         +'"DisplayName": "DWScript WebServer",'
         // Windows service description
         +'"Description": "DWScript WebServer Service",'
         // folder for log
         +'"DWSErrorLogDirectory": ""'
      +'}';
end;

procedure TWebServerHttpService.DoStart(Sender: TdwsWindowsService);
var
   wwwPath : TdwsJSONValue;
   basePath : String;
begin
  if Server<>nil then
    DoStop(nil); // should never happen

   wwwPath:=Options['Server']['WWWPath'];
   if wwwPath.ValueType=jvtString then
      basePath:=wwwPath.AsString;

   // default to subfolder 'www' of where the exe is placed
   if basePath='' then
      basePath:=ExtractFilePath(ParamStr(0))+'www';

   Server := THttpSys2WebServer.Create(basePath, Options, ServiceName);
end;

procedure TWebServerHttpService.DoStop(Sender: TdwsWindowsService);
begin
   if Server<>nil then begin
      Server.Shutdown;
      Server:=nil;
   end;
end;

procedure TWebServerHttpService.ExecuteCommandLineParameters(var abortExecution : Boolean);
var
   authorize : Boolean;
   serverOptions : TdwsJSONValue;
   infos : THttpSys2URLInfos;
   i : Integer;
   msg, param : String;
   json : TdwsJSONValue;
begin
   param := ParamStr(1);

   if param='/options-defaults' then begin

      abortExecution := True;

      json := TdwsJSONObject.Create;
      try
         json.Items['Service'] := TdwsJSONValue.ParseString(DefaultServiceOptions);
         json.Items['Server'] := TdwsJSONValue.ParseString(cDefaultServerOptions);
         json.Items['CPU'] := TdwsJSONValue.ParseString(cDefaultCPUOptions);
         json.Items['DWScript'] := TdwsJSONValue.ParseString(cDefaultDWScriptOptions);
         Writeln(json.ToBeautifiedString);
      finally
         json.Free;
      end;

   end else if (param='/authorize') or (param='/unauthorize') then begin

      abortExecution := True;
      authorize := (ParamStr(1)='/authorize');

      serverOptions:=TdwsJSONValue.ParseString(cDefaultServerOptions);
      try
         serverOptions.Extend(Options['Server']);
         infos := THttpSys2WebServer.EnumerateURLInfos(serverOptions);
         for i := 0 to High(infos) do begin
            Write(infos[i].ToString, ' -> ');
            msg := THttpApi2Server.AddUrlAuthorize(infos[i], not authorize);
            if msg = '' then
               Writeln('success!')
            else WriteLn(msg);
         end;
      finally
         serverOptions.Free;
      end;

   end else if param='/report-memory-leaks' then begin

      ReportMemoryLeaksOnShutdown := True;

   end else inherited ExecuteCommandLineParameters(abortExecution);
end;

procedure TWebServerHttpService.WriteCommandLineHelpExtra;
begin
   Writeln('* /authorize & /unauthorize : enable/disable ACL (must be run as administrator)');
   Writeln('* /options-defaults : prints the default options.json settings');
   Writeln('* /report-memory-leaks : memory leaks report on shutdown');
   Writeln;
   Writeln(  'Compiler version ' + Format('%.01f', [cCompilerVersion])
           + ', compiled on ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ExecutableLinkTimeStamp/SecsPerDay+UnixDateDelta) + ' Z');

   inherited WriteCommandLineHelpExtra;
end;


procedure LogServiceError(options : TdwsJSONValue; const msg : String); overload;
var
   log : String;
   h : THandle;
begin
   if options <> nil then begin
      log := options['Server']['DWSErrorLogDirectory'].AsString;
      if log<>'undefined' then begin
         log:=IncludeTrailingPathDelimiter(log)+'service.log';
         AppendTextToUTF8File(log, UTF8Encode(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz ', Now)+msg+#13#10));
      end;
   end;
   h := GetStdHandle(STD_ERROR_HANDLE);
   if (h <> 0) and (h <> INVALID_HANDLE_VALUE) then
      WriteLn(ErrOutput, msg);
end;

procedure LogServiceError(options : TdwsJSONValue; E: Exception); overload;
begin
   LogServiceError(options, E.ClassName+': '+E.Message);
end;

var
   i : Integer;
   optionsFileName : String;
   options : TdwsJSONValue;
   service : TWebServerHttpService;
   abortExecution : Boolean;
begin
   options:=nil;
   {$if Defined(WIN32)}
   if Win32MajorVersion<6 then begin
      LogServiceError(options, 'This program requires at least Windows 2008 or Vista');
      exit;
   end;
   {$ifend}

   SetDecimalSeparator('.');

   optionsFileName:=ExtractFilePath(ParamStr(0))+'options.json';
   if FileExists(optionsFileName) then begin
      try
         options:=TdwsJSONValue.ParseFile(optionsFileName);
      except
         on E: Exception do begin
            LogServiceError(options, 'Invalid options.json '+E.Message);
            Exit;
         end;
      end;
   end else options:=TdwsJSONObject.Create;
   service:=TWebServerHttpService.Create(options);
   try
      try
         if ParamCount<>0 then begin
            abortExecution := False;
            service.ExecuteCommandLineParameters(abortExecution);
            if abortExecution then
               Exit;
         end;

         if service.LaunchedBySCM then begin

            // started as service
            TdwsSystemInfoLibModule.RunningAsService:=True;
            ServicesRun;

         end else begin

            // started as application
            try
               service.DoStart(service);
            except
               on E: Exception do begin
                  LogServiceError(options, E);
                  Exit;
               end;
            end;
            {$ifndef CPU64BITS}
               {$ifdef CPUX64}
                  {$define CPU64BITS}     // not defined in XE2 to XE7
               {$endif}
            {$endif}
            {$ifdef CPU64BITS}
            write('DWScript 64bits Server is now running on ');
            {$else}
            write('DWScript 32bits Server is now running on ');
            {$endif}
            for i := 0 to High(service.Server.URLInfos) do
               Writeln(service.Server.URLInfos[i].ToString);
            Writeln;
            Writeln('Press [Enter] to quit');
            Readln;

         end;

      except

         on E: Exception do

            LogServiceError(options, E);
      end;
   finally
      try
         service.Free;
         options.Free;
      except
         on E: Exception do
            LogServiceError(options, E);
      end;
   end;
end.
