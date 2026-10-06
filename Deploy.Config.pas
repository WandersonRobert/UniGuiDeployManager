unit Deploy.Config;

interface

uses
  System.SysUtils, System.IOUtils, System.JSON, System.Generics.Collections,
  System.Hash, System.SyncObjs, Deploy.Types;

type
  TAppSettings = class
  private
    FAppCmdPath: string;
    FAdminUser: string;
    FAdminPasswordHash: string;
    FAdminPasswordSalt: string;
  public
    constructor Create;
    procedure SetPassword(const PlainPassword: string);
    function CheckPassword(const PlainPassword: string): Boolean;
    property AppCmdPath: string read FAppCmdPath write FAppCmdPath;
    property AdminUser: string read FAdminUser write FAdminUser;
    property AdminPasswordHash: string read FAdminPasswordHash write FAdminPasswordHash;
    property AdminPasswordSalt: string read FAdminPasswordSalt write FAdminPasswordSalt;
  end;

  TDeployConfig = class
  private
    FLock: TCriticalSection;
    FSites: TDeploySites;
    FSettings: TAppSettings;
    FConfigFolder: string;
    FSitesFile: string;
    FSettingsFile: string;
    procedure EnsureDefaultSettings;
  public
    constructor Create(const AConfigFolder: string);
    destructor Destroy; override;

    procedure Load;
    procedure Save;

    function LockSites: TDeploySites;
    procedure UnlockSites;

    function FindSite(const AName: string): TDeploySite;

    property Settings: TAppSettings read FSettings;
  end;

function AppConfig: TDeployConfig;
procedure InitAppConfig(const AConfigFolder: string);

implementation

var
  GConfig: TDeployConfig;

function AppConfig: TDeployConfig;
begin
  Result := GConfig;
end;

procedure InitAppConfig(const AConfigFolder: string);
begin
  if not Assigned(GConfig) then
  begin
    GConfig := TDeployConfig.Create(AConfigFolder);
    GConfig.Load;
  end;
end;

{ TAppSettings }

constructor TAppSettings.Create;
begin
  inherited Create;
  FAppCmdPath := 'C:\Windows\System32\inetsrv\appcmd.exe';
  FAdminUser := 'administrador';
end;

procedure TAppSettings.SetPassword(const PlainPassword: string);
begin
  FAdminPasswordSalt := THashSHA2.GetHashString(GUIDToString(TGUID.NewGuid));
  FAdminPasswordHash := THashSHA2.GetHashString(FAdminPasswordSalt + PlainPassword);
end;

function TAppSettings.CheckPassword(const PlainPassword: string): Boolean;
begin
  Result := (FAdminPasswordHash <> '') and
    (THashSHA2.GetHashString(FAdminPasswordSalt + PlainPassword) = FAdminPasswordHash);
end;

{ TDeployConfig }

constructor TDeployConfig.Create(const AConfigFolder: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FSites := TDeploySites.Create(True);
  FSettings := TAppSettings.Create;
  FConfigFolder := AConfigFolder;
  FSitesFile := TPath.Combine(FConfigFolder, 'sites.json');
  FSettingsFile := TPath.Combine(FConfigFolder, 'settings.json');
end;

destructor TDeployConfig.Destroy;
begin
  FSites.Free;
  FSettings.Free;
  FLock.Free;
  inherited;
end;

procedure TDeployConfig.EnsureDefaultSettings;
begin
  if FSettings.AdminPasswordHash = '' then
    FSettings.SetPassword('net@2019');
end;

procedure TDeployConfig.Load;
var
  JSONArr: TJSONArray;
  JSONObj, SiteObj: TJSONObject;
  V: TJSONValue;
  Site: TDeploySite;
  I: Integer;
begin
  FLock.Enter;
  try
    TDirectory.CreateDirectory(FConfigFolder);
    FSites.Clear;

    if TFile.Exists(FSitesFile) then
    begin
      JSONArr := TJSONObject.ParseJSONValue(TFile.ReadAllText(FSitesFile, TEncoding.UTF8)) as TJSONArray;
      if Assigned(JSONArr) then
      try
        for I := 0 to JSONArr.Count - 1 do
        begin
          SiteObj := JSONArr.Items[I] as TJSONObject;
          Site := TDeploySite.Create;
          Site.FromJSON(SiteObj);
          FSites.Add(Site);
        end;
      finally
        JSONArr.Free;
      end;
    end;

    if TFile.Exists(FSettingsFile) then
    begin
      JSONObj := TJSONObject.ParseJSONValue(TFile.ReadAllText(FSettingsFile, TEncoding.UTF8)) as TJSONObject;
      if Assigned(JSONObj) then
      try
        if JSONObj.TryGetValue<TJSONValue>('appCmdPath', V) then
          FSettings.AppCmdPath := V.Value;
        if JSONObj.TryGetValue<TJSONValue>('adminUser', V) then
          FSettings.AdminUser := V.Value;
        if JSONObj.TryGetValue<TJSONValue>('adminPasswordHash', V) then
          FSettings.AdminPasswordHash := V.Value;
        if JSONObj.TryGetValue<TJSONValue>('adminPasswordSalt', V) then
          FSettings.AdminPasswordSalt := V.Value;
      finally
        JSONObj.Free;
      end;
    end;

    EnsureDefaultSettings;
  finally
    FLock.Leave;
  end;
  Save;
end;

procedure TDeployConfig.Save;
var
  JSONArr: TJSONArray;
  JSONObj: TJSONObject;
  Site: TDeploySite;
begin
  FLock.Enter;
  try
    TDirectory.CreateDirectory(FConfigFolder);

    JSONArr := TJSONArray.Create;
    try
      for Site in FSites do
        JSONArr.AddElement(Site.ToJSON);
      TFile.WriteAllText(FSitesFile, JSONArr.Format(2), TEncoding.UTF8);
    finally
      JSONArr.Free;
    end;

    JSONObj := TJSONObject.Create;
    try
      JSONObj.AddPair('appCmdPath', FSettings.AppCmdPath);
      JSONObj.AddPair('adminUser', FSettings.AdminUser);
      JSONObj.AddPair('adminPasswordHash', FSettings.AdminPasswordHash);
      JSONObj.AddPair('adminPasswordSalt', FSettings.AdminPasswordSalt);
      TFile.WriteAllText(FSettingsFile, JSONObj.Format(2), TEncoding.UTF8);
    finally
      JSONObj.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

function TDeployConfig.LockSites: TDeploySites;
begin
  FLock.Enter;
  Result := FSites;
end;

procedure TDeployConfig.UnlockSites;
begin
  FLock.Leave;
end;

function TDeployConfig.FindSite(const AName: string): TDeploySite;
var
  Site: TDeploySite;
begin
  Result := nil;
  FLock.Enter;
  try
    for Site in FSites do
      if SameText(Site.Name, AName) then
        Exit(Site);
  finally
    FLock.Leave;
  end;
end;

initialization

finalization
  GConfig.Free;

end.
