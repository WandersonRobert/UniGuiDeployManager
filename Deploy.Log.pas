unit Deploy.Log;

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections, System.SyncObjs,
  System.DateUtils, Deploy.Types;

type
  TDeployLog = class
  private
    FLock: TCriticalSection;
    FEntries: TList<TDeployLogEntry>;
    FLogFile: string;
    FMaxEntries: Integer;
    procedure LoadExisting;
  public
    constructor Create(const ALogFile: string);
    destructor Destroy; override;

    procedure Add(const SiteName: string; Status: TDeployStatus; const Msg: string);
    function GetEntries: TArray<TDeployLogEntry>;
  end;

function DeployLog: TDeployLog;
procedure InitDeployLog(const ALogFile: string);

implementation

var
  GLog: TDeployLog;

function DeployLog: TDeployLog;
begin
  Result := GLog;
end;

procedure InitDeployLog(const ALogFile: string);
begin
  if not Assigned(GLog) then
    GLog := TDeployLog.Create(ALogFile);
end;

{ TDeployLog }

constructor TDeployLog.Create(const ALogFile: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FEntries := TList<TDeployLogEntry>.Create;
  FLogFile := ALogFile;
  FMaxEntries := 500;
  LoadExisting;
end;

function TryParseLogTimestamp(const S: string; out DT: TDateTime): Boolean;
var
  Y, Mo, D, H, Mi, Se: Integer;
begin
  Result := False;
  if Length(S) <> 19 then
    Exit;
  if not (TryStrToInt(Copy(S, 1, 4), Y) and TryStrToInt(Copy(S, 6, 2), Mo) and
          TryStrToInt(Copy(S, 9, 2), D) and TryStrToInt(Copy(S, 12, 2), H) and
          TryStrToInt(Copy(S, 15, 2), Mi) and TryStrToInt(Copy(S, 18, 2), Se)) then
    Exit;
  try
    DT := EncodeDateTime(Y, Mo, D, H, Mi, Se, 0);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TDeployLog.LoadExisting;
var
  Lines: TArray<string>;
  Line, Rest, StatusStr: string;
  Entry: TDeployLogEntry;
  PBracket, PSep1, PSep2: Integer;
begin
  if not TFile.Exists(FLogFile) then
    Exit;
  try
    Lines := TFile.ReadAllLines(FLogFile, TEncoding.UTF8);
  except
    Exit;
  end;

  for Line in Lines do
  begin
    if (Trim(Line) = '') or (Line[1] <> '[') then
      Continue;
    PBracket := Pos(']', Line);
    if PBracket = 0 then
      Continue;
    if not TryParseLogTimestamp(Copy(Line, 2, PBracket - 2), Entry.When) then
      Continue;

    Rest := Copy(Line, PBracket + 2, MaxInt);
    PSep1 := Pos(' | ', Rest);
    if PSep1 = 0 then
      Continue;
    Entry.SiteName := Copy(Rest, 1, PSep1 - 1);
    Rest := Copy(Rest, PSep1 + 3, MaxInt);

    PSep2 := Pos(' | ', Rest);
    if PSep2 = 0 then
      Continue;
    StatusStr := Copy(Rest, 1, PSep2 - 1);
    Entry.Message := Copy(Rest, PSep2 + 3, MaxInt);
    Entry.Status := StrToDeployStatus(StatusStr);

    FEntries.Insert(0, Entry);
  end;

  while FEntries.Count > FMaxEntries do
    FEntries.Delete(FEntries.Count - 1);
end;

destructor TDeployLog.Destroy;
begin
  FEntries.Free;
  FLock.Free;
  inherited;
end;

procedure TDeployLog.Add(const SiteName: string; Status: TDeployStatus; const Msg: string);
var
  Entry: TDeployLogEntry;
  Line: string;
begin
  Entry.When := Now;
  Entry.SiteName := SiteName;
  Entry.Status := Status;
  Entry.Message := Msg;

  FLock.Enter;
  try
    FEntries.Insert(0, Entry);
    while FEntries.Count > FMaxEntries do
      FEntries.Delete(FEntries.Count - 1);

    Line := Format('[%s] %s | %s | %s', [
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.When),
      SiteName, DeployStatusToStr(Status), Msg]);
    try
      TDirectory.CreateDirectory(TPath.GetDirectoryName(FLogFile));
      TFile.AppendAllText(FLogFile, Line + sLineBreak, TEncoding.UTF8);
    except
      // nao deixa falha de log derrubar o deploy
    end;
  finally
    FLock.Leave;
  end;
end;

function TDeployLog.GetEntries: TArray<TDeployLogEntry>;
begin
  FLock.Enter;
  try
    Result := FEntries.ToArray;
  finally
    FLock.Leave;
  end;
end;

initialization

finalization
  GLog.Free;

end.
