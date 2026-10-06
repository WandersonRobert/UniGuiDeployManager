unit ServerModule;

interface

uses
  SysUtils, IOUtils, uniGUIServer, uniGUIMainModule, uniGUIApplication,
  Deploy.Config, Deploy.Log, Deploy.Watcher;

type
  TUniServerModule = class(TUniGUIServerModule)
  private
    { Private declarations }
  protected
    procedure FirstInit; override;
  public
    { Public declarations }
  end;

function UniServerModule: TUniServerModule;

implementation

{$R *.dfm}

uses
  UniGUIVars;

function UniServerModule: TUniServerModule;
begin
  Result:=TUniServerModule(UniGUIServerInstance);
end;

procedure TUniServerModule.FirstInit;
var
  BasePath: string;
begin
  InitServerModule(Self);

  BasePath := IncludeTrailingPathDelimiter(StartPath);
  InitAppConfig(BasePath + 'config');
  InitDeployLog(BasePath + 'log\deploy.log');
  StartWatcher;
end;

initialization
  RegisterServerModuleClass(TUniServerModule);
end.
