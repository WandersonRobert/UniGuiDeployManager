unit Deploy.IISControl;

interface

uses
  System.SysUtils, System.StrUtils, System.DateUtils,
  Deploy.ProcessUtils, Deploy.Config;

type
  TAppPoolState = (apsUnknown, apsStarted, apsStopped, apsStarting, apsStopping);

function GetAppPoolState(const AppPoolName: string): TAppPoolState;
function StopAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
function StartAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
function RecycleAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
function WaitForAppPoolState(const AppPoolName: string; DesiredState: TAppPoolState;
  TimeoutSec: Integer): Boolean;
function AppPoolExists(const AppPoolName: string): Boolean;

implementation

function QuoteArg(const S: string): string;
begin
  Result := '"' + S + '"';
end;

function AppCmdExe: string;
begin
  Result := AppConfig.Settings.AppCmdPath;
  if not FileExists(Result) then
    raise Exception.CreateFmt('appcmd.exe nao encontrado em "%s". Verifique se o IIS esta instalado e ajuste o caminho nas configuracoes.', [Result]);
end;

function GetAppPoolState(const AppPoolName: string): TAppPoolState;
var
  CmdLine, Output: string;
  ExitCode: Cardinal;
begin
  Result := apsUnknown;
  try
    CmdLine := QuoteArg(AppCmdExe) + ' list apppool ' + QuoteArg(AppPoolName) + ' /text:state';
    if RunConsoleCommand(CmdLine, Output, ExitCode, 15000) and (ExitCode = 0) then
    begin
      Output := Trim(Output);
      if SameText(Output, 'Started') then
        Result := apsStarted
      else if SameText(Output, 'Stopped') then
        Result := apsStopped
      else if SameText(Output, 'Starting') then
        Result := apsStarting
      else if SameText(Output, 'Stopping') then
        Result := apsStopping;
    end;
  except
    // appcmd indisponivel ou App Pool inexistente: mantem apsUnknown
    Result := apsUnknown;
  end;
end;

function AppPoolExists(const AppPoolName: string): Boolean;
begin
  Result := GetAppPoolState(AppPoolName) <> apsUnknown;
end;

function RunAppCmdAction(const Verb, AppPoolName: string; out ErrorMsg: string): Boolean;
var
  CmdLine, Output: string;
  ExitCode: Cardinal;
begin
  ErrorMsg := '';
  CmdLine := QuoteArg(AppCmdExe) + ' ' + Verb + ' apppool /apppool.name:' + QuoteArg(AppPoolName);
  try
    Result := RunConsoleCommand(CmdLine, Output, ExitCode, 30000);
    if Result and (ExitCode <> 0) then
    begin
      Result := False;
      ErrorMsg := Format('appcmd retornou codigo %d: %s', [ExitCode, Trim(Output)]);
    end
    else if not Result then
      ErrorMsg := 'Falha ao executar appcmd.exe';
  except
    on E: Exception do
    begin
      Result := False;
      ErrorMsg := E.Message;
    end;
  end;
end;

function StopAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
begin
  if GetAppPoolState(AppPoolName) = apsStopped then
  begin
    ErrorMsg := '';
    Exit(True);
  end;
  Result := RunAppCmdAction('stop', AppPoolName, ErrorMsg);
end;

function StartAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
begin
  if GetAppPoolState(AppPoolName) = apsStarted then
  begin
    ErrorMsg := '';
    Exit(True);
  end;
  Result := RunAppCmdAction('start', AppPoolName, ErrorMsg);
end;

function RecycleAppPool(const AppPoolName: string; out ErrorMsg: string): Boolean;
begin
  Result := RunAppCmdAction('recycle', AppPoolName, ErrorMsg);
end;

function WaitForAppPoolState(const AppPoolName: string; DesiredState: TAppPoolState;
  TimeoutSec: Integer): Boolean;
var
  Deadline: TDateTime;
begin
  Deadline := IncSecond(Now, TimeoutSec);
  repeat
    if GetAppPoolState(AppPoolName) = DesiredState then
      Exit(True);
    Sleep(500);
  until Now > Deadline;
  Result := GetAppPoolState(AppPoolName) = DesiredState;
end;

end.
