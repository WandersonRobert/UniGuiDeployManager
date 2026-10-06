program UniGuiDeployManager;

uses
  Forms,
  ServerModule in 'ServerModule.pas' {UniServerModule: TUniGUIServerModule},
  MainModule in 'MainModule.pas' {UniMainModule: TUniGUIMainModule},
  Login in 'Login.pas' {DeployLoginForm: TUniForm},
  Main in 'Main.pas' {MainForm: TUniForm},
  SiteEdit in 'SiteEdit.pas' {SiteEditForm: TUniForm},
  Deploy.Types in 'Deploy.Types.pas',
  Deploy.Config in 'Deploy.Config.pas',
  Deploy.Log in 'Deploy.Log.pas',
  Deploy.ProcessUtils in 'Deploy.ProcessUtils.pas',
  Deploy.IISControl in 'Deploy.IISControl.pas',
  Deploy.Engine in 'Deploy.Engine.pas',
  Deploy.Watcher in 'Deploy.Watcher.pas';

{$R *.res}

begin
  Application.Initialize;
  TUniServerModule.Create(Application);
  Application.Run;
end.
