unit Deploy.Types;

interface

uses
  System.SysUtils, System.Generics.Collections, System.JSON;

type
  TDeployStatus = (dsNunca, dsEmAndamento, dsSucesso, dsFalha);

  TDeploySite = class
  private
    FName: string;
    FAppPoolName: string;
    FPhysicalPath: string;
    FPackageFolder: string;
    FBackupFolder: string;
    FProcessedFolder: string;
    FEnabled: Boolean;
    FWatchEnabled: Boolean;
    FPollIntervalSec: Integer;
    FKeepBackups: Integer;
    FLastDeployAt: TDateTime;
    FLastStatus: TDeployStatus;
    FLastMessage: string;
    FBusy: Boolean;
  public
    constructor Create;
    function Clone: TDeploySite;
    procedure AssignFrom(Source: TDeploySite);
    function ToJSON: TJSONObject;
    procedure FromJSON(JSON: TJSONObject);

    property Name: string read FName write FName;
    property AppPoolName: string read FAppPoolName write FAppPoolName;
    property PhysicalPath: string read FPhysicalPath write FPhysicalPath;
    property PackageFolder: string read FPackageFolder write FPackageFolder;
    property BackupFolder: string read FBackupFolder write FBackupFolder;
    property ProcessedFolder: string read FProcessedFolder write FProcessedFolder;
    property Enabled: Boolean read FEnabled write FEnabled;
    property WatchEnabled: Boolean read FWatchEnabled write FWatchEnabled;
    property PollIntervalSec: Integer read FPollIntervalSec write FPollIntervalSec;
    property KeepBackups: Integer read FKeepBackups write FKeepBackups;
    property LastDeployAt: TDateTime read FLastDeployAt write FLastDeployAt;
    property LastStatus: TDeployStatus read FLastStatus write FLastStatus;
    property LastMessage: string read FLastMessage write FLastMessage;
    property Busy: Boolean read FBusy write FBusy;
  end;

  TDeploySites = TObjectList<TDeploySite>;

  TDeployLogEntry = record
    When: TDateTime;
    SiteName: string;
    Status: TDeployStatus;
    Message: string;
  end;

function DeployStatusToStr(Status: TDeployStatus): string;
function StrToDeployStatus(const S: string): TDeployStatus;

implementation

function DeployStatusToStr(Status: TDeployStatus): string;
begin
  case Status of
    dsNunca: Result := 'Nunca implantado';
    dsEmAndamento: Result := 'Em andamento...';
    dsSucesso: Result := 'Sucesso';
    dsFalha: Result := 'Falha';
  else
    Result := '';
  end;
end;

function StrToDeployStatus(const S: string): TDeployStatus;
begin
  if SameText(S, 'Em andamento...') then
    Result := dsEmAndamento
  else if SameText(S, 'Sucesso') then
    Result := dsSucesso
  else if SameText(S, 'Falha') then
    Result := dsFalha
  else
    Result := dsNunca;
end;

{ TDeploySite }

constructor TDeploySite.Create;
begin
  inherited Create;
  FEnabled := True;
  FWatchEnabled := False;
  FPollIntervalSec := 15;
  FKeepBackups := 5;
  FLastStatus := dsNunca;
  FBusy := False;
end;

function TDeploySite.Clone: TDeploySite;
begin
  Result := TDeploySite.Create;
  Result.AssignFrom(Self);
end;

procedure TDeploySite.AssignFrom(Source: TDeploySite);
begin
  FName := Source.FName;
  FAppPoolName := Source.FAppPoolName;
  FPhysicalPath := Source.FPhysicalPath;
  FPackageFolder := Source.FPackageFolder;
  FBackupFolder := Source.FBackupFolder;
  FProcessedFolder := Source.FProcessedFolder;
  FEnabled := Source.FEnabled;
  FWatchEnabled := Source.FWatchEnabled;
  FPollIntervalSec := Source.FPollIntervalSec;
  FKeepBackups := Source.FKeepBackups;
  FLastDeployAt := Source.FLastDeployAt;
  FLastStatus := Source.FLastStatus;
  FLastMessage := Source.FLastMessage;
  FBusy := Source.FBusy;
end;

function TDeploySite.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', FName);
  Result.AddPair('appPoolName', FAppPoolName);
  Result.AddPair('physicalPath', FPhysicalPath);
  Result.AddPair('packageFolder', FPackageFolder);
  Result.AddPair('backupFolder', FBackupFolder);
  Result.AddPair('processedFolder', FProcessedFolder);
  Result.AddPair('enabled', TJSONBool.Create(FEnabled));
  Result.AddPair('watchEnabled', TJSONBool.Create(FWatchEnabled));
  Result.AddPair('pollIntervalSec', TJSONNumber.Create(FPollIntervalSec));
  Result.AddPair('keepBackups', TJSONNumber.Create(FKeepBackups));
  Result.AddPair('lastDeployAt', TJSONNumber.Create(FLastDeployAt));
  Result.AddPair('lastStatus', TJSONNumber.Create(Ord(FLastStatus)));
  Result.AddPair('lastMessage', FLastMessage);
end;

procedure TDeploySite.FromJSON(JSON: TJSONObject);
var
  V: TJSONValue;

  function GetStr(const Key, Default: string): string;
  begin
    if JSON.TryGetValue<TJSONValue>(Key, V) then
      Result := V.Value
    else
      Result := Default;
  end;

  function GetBool(const Key: string; Default: Boolean): Boolean;
  begin
    if JSON.TryGetValue<TJSONValue>(Key, V) then
      Result := (V is TJSONTrue)
    else
      Result := Default;
  end;

  function GetInt(const Key: string; Default: Integer): Integer;
  begin
    if JSON.TryGetValue<TJSONValue>(Key, V) then
      Result := StrToIntDef(V.Value, Default)
    else
      Result := Default;
  end;

  function GetFloat(const Key: string; Default: Double): Double;
  begin
    if JSON.TryGetValue<TJSONValue>(Key, V) then
      Result := StrToFloatDef(V.Value, Default, TFormatSettings.Invariant)
    else
      Result := Default;
  end;

begin
  FName := GetStr('name', '');
  FAppPoolName := GetStr('appPoolName', '');
  FPhysicalPath := GetStr('physicalPath', '');
  FPackageFolder := GetStr('packageFolder', '');
  FBackupFolder := GetStr('backupFolder', '');
  FProcessedFolder := GetStr('processedFolder', '');
  FEnabled := GetBool('enabled', True);
  FWatchEnabled := GetBool('watchEnabled', False);
  FPollIntervalSec := GetInt('pollIntervalSec', 15);
  FKeepBackups := GetInt('keepBackups', 5);
  FLastDeployAt := GetFloat('lastDeployAt', 0);
  FLastStatus := TDeployStatus(GetInt('lastStatus', 0));
  FLastMessage := GetStr('lastMessage', '');
end;

end.
