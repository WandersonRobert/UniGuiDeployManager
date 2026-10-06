unit Login;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Graphics,
  uniGUITypes, uniGUIAbstractClasses, uniGUIClasses, uniGUIForm,
  uniGUIBaseClasses, uniButton, uniLabel, uniEdit, uniPanel, uniGUIRegClasses,
  Deploy.Config;

type
  TDeployLoginForm = class(TUniLoginForm)
  private
    FPanel: TUniPanel;
    FLblTitle: TUniLabel;
    FLblSubtitle: TUniLabel;
    FLblUser: TUniLabel;
    FEdtUser: TUniEdit;
    FLblPass: TUniLabel;
    FEdtPass: TUniEdit;
    FBtnLogin: TUniButton;
    FLblError: TUniLabel;
    procedure BuildUI;
    procedure DoLoginClick(Sender: TObject);
    procedure DoPassKeyPress(Sender: TObject; var Key: Char);
  public
    constructor Create(AOwner: TComponent); override;
  end;

function DeployLoginForm: TDeployLoginForm;

implementation

uses
  uniGUIVars, MainModule;

function DeployLoginForm: TDeployLoginForm;
begin
  Result := TDeployLoginForm(UniMainModule.GetFormInstance(TDeployLoginForm));
end;

constructor TDeployLoginForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if not (csDesigning in ComponentState) then
    BuildUI;
end;

procedure TDeployLoginForm.BuildUI;
begin
  Caption := 'UniGUI Deploy Manager - Login';
  Width := 380;
  Height := 360;
  Position := poScreenCenter;
  BorderStyle := bsNone;
  LayoutConfig.Cls := 'dm-login-window';

  FPanel := TUniPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alClient;
  FPanel.BorderStyle := ubsNone;
  FPanel.Color := clWhite;
  FPanel.LayoutConfig.Cls := 'dm-login-card';

  FLblTitle := TUniLabel.Create(Self);
  FLblTitle.Parent := FPanel;
  FLblTitle.Left := 28;
  FLblTitle.Top := 28;
  FLblTitle.Width := 320;
  FLblTitle.Alignment := taCenter;
  FLblTitle.Caption := 'DEPLOY MANAGER';
  FLblTitle.Font.Size := 17;
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Font.Color := RGB(44, 62, 80);

  FLblSubtitle := TUniLabel.Create(Self);
  FLblSubtitle.Parent := FPanel;
  FLblSubtitle.Left := 28;
  FLblSubtitle.Top := 54;
  FLblSubtitle.Width := 320;
  FLblSubtitle.Alignment := taCenter;
  FLblSubtitle.Caption := 'Automacao de deploy e App Pools do IIS';
  FLblSubtitle.Font.Color := RGB(119, 119, 119);

  FLblUser := TUniLabel.Create(Self);
  FLblUser.Parent := FPanel;
  FLblUser.Left := 28;
  FLblUser.Top := 100;
  FLblUser.Caption := 'Usuario';
  FLblUser.Font.Color := RGB(85, 85, 85);

  FEdtUser := TUniEdit.Create(Self);
  FEdtUser.Parent := FPanel;
  FEdtUser.Left := 28;
  FEdtUser.Top := 120;
  FEdtUser.Width := 320;
  FEdtUser.Height := 34;
  FEdtUser.Text := AppConfig.Settings.AdminUser;

  FLblPass := TUniLabel.Create(Self);
  FLblPass.Parent := FPanel;
  FLblPass.Left := 28;
  FLblPass.Top := 166;
  FLblPass.Caption := 'Senha';
  FLblPass.Font.Color := RGB(85, 85, 85);

  FEdtPass := TUniEdit.Create(Self);
  FEdtPass.Parent := FPanel;
  FEdtPass.Left := 28;
  FEdtPass.Top := 186;
  FEdtPass.Width := 320;
  FEdtPass.Height := 34;
  FEdtPass.PasswordChar := '*';
  FEdtPass.OnKeyPress := DoPassKeyPress;

  FBtnLogin := TUniButton.Create(Self);
  FBtnLogin.Parent := FPanel;
  FBtnLogin.Left := 28;
  FBtnLogin.Top := 238;
  FBtnLogin.Width := 320;
  FBtnLogin.Height := 38;
  FBtnLogin.Caption := 'Entrar';
  FBtnLogin.OnClick := DoLoginClick;
  FBtnLogin.LayoutConfig.Cls := 'dm-btn-primary';

  FLblError := TUniLabel.Create(Self);
  FLblError.Parent := FPanel;
  FLblError.Left := 28;
  FLblError.Top := 286;
  FLblError.Width := 320;
  FLblError.Font.Color := RGB(221, 75, 57);
  FLblError.Caption := '';
end;

procedure TDeployLoginForm.DoPassKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    DoLoginClick(FBtnLogin);
  end;
end;

procedure TDeployLoginForm.DoLoginClick(Sender: TObject);
begin
  if SameText(Trim(FEdtUser.Text), AppConfig.Settings.AdminUser) and
     AppConfig.Settings.CheckPassword(FEdtPass.Text) then
  begin
    ModalResult := mrOk;
  end
  else
  begin
    FLblError.Caption := 'Usuario ou senha invalidos.';
    FEdtPass.Text := '';
  end;
end;

initialization
  RegisterAppFormClass(TDeployLoginForm);

end.
