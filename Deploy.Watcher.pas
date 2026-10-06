unit Deploy.Watcher;

interface

uses
  System.Classes, System.SysUtils, Deploy.Types, Deploy.Config, Deploy.Engine,
  Deploy.Log;

type
  TDeployWatcherThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

procedure StartWatcher;
procedure StopWatcher;

implementation

var
  GWatcherThread: TDeployWatcherThread;

procedure StartWatcher;
begin
  if not Assigned(GWatcherThread) then
    GWatcherThread := TDeployWatcherThread.Create;
end;

procedure StopWatcher;
begin
  if Assigned(GWatcherThread) then
  begin
    GWatcherThread.Terminate;
    GWatcherThread.WaitFor;
    FreeAndNil(GWatcherThread);
  end;
end;

{ TDeployWatcherThread }

constructor TDeployWatcherThread.Create;
begin
  inherited Create(False);
  FreeOnTerminate := False;
end;

procedure TDeployWatcherThread.Execute;
var
  Sites: TDeploySites;
  SiteNames: TArray<string>;
  I: Integer;
  Site: TDeploySite;
  ZipPath, ErrorMsg: string;
begin
  while not Terminated do
  begin
    try
      Sites := AppConfig.LockSites;
      try
        SetLength(SiteNames, Sites.Count);
        for I := 0 to Sites.Count - 1 do
          SiteNames[I] := Sites[I].Name;
      finally
        AppConfig.UnlockSites;
      end;

      for I := 0 to High(SiteNames) do
      begin
        if Terminated then
          Break;

        Site := AppConfig.FindSite(SiteNames[I]);
        if not Assigned(Site) then
          Continue;
        if not (Site.Enabled and Site.WatchEnabled) then
          Continue;
        if Site.Busy then
          Continue;

        ZipPath := FindPendingPackage(Site);
        if ZipPath = '' then
          Continue;

        Site.Busy := True;
        try
          DeployPackage(Site, ZipPath, ErrorMsg);
          AppConfig.Save;
        finally
          Site.Busy := False;
        end;
      end;
    except
      on E: Exception do
        DeployLog.Add('(watcher)', dsFalha, E.Message);
    end;

    Sleep(3000);
  end;
end;

end.
