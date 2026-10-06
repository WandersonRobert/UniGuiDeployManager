unit SiteEdit;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Graphics,
  uniGUITypes, uniGUIAbstractClasses, uniGUIClasses, uniGUIForm,
  uniGUIBaseClasses, uniButton, uniLabel, uniEdit, uniPanel, uniCheckBox,
  uniGUIDialogs,
  Deploy.Types;

type
  TSiteEditForm = class(TUniForm)
  private
    FLblName, FLblAppPool, FLblPhysical, FLblPackage, FLblBackup, FLblProcessed,
      FLblPoll, FLblKeep: TUniLabel;
    FEdtName, FEdtAppPool, FEdtPhysical, FEdtPackage, FEdtBackup, FEdtProcessed,
      FEdtPoll, FEdtKeep: TUniEdit;
    FChkEnabled, FChkWatch: TUniCheckBox;
    FBtnSalvar, FBtnCancelar: TUniButton;
    procedure BuildUI;
    procedure DoSalvarClick(Sender: TObject);
    procedure DoCancelarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadSite(Site: TDeploySite);
    procedure SaveInto(Site: TDeploySite);
  end;

implementation

const
  LBL_LEFT = 24;
  EDT_LEFT = 200;
  EDT_WIDTH = 420;
  ROW_HEIGHT = 34;

constructor TSiteEditForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if not (csDesigning in ComponentState) then
    BuildUI;
end;

procedure TSiteEditForm.BuildUI;
  function MakeLabel(const ACaption: string; ATop: Integer): TUniLabel;
  begin
    Result := TUniLabel.Create(Self);
    Result.Parent := Self;
    Result.Left := LBL_LEFT;
    Result.Top := ATop + 4;
    Result.Caption := ACaption;
    Result.Font.Color := RGB(75, 85, 99);
  end;
  function MakeEdit(ATop: Integer): TUniEdit;
  begin
    Result := TUniEdit.Create(Self);
    Result.Parent := Self;
    Result.Left := EDT_LEFT;
    Result.Top := ATop;
    Result.Width := EDT_WIDTH;
    Result.Height := 28;
  end;
var
  Y: Integer;
begin
  Caption := 'Site de deploy';
  Width := 680;
  Height := 480;
  Position := poScreenCenter;
  BorderStyle := bsSingle;

  Y := 16;
  FLblName := MakeLabel('Nome do site', Y);
  FEdtName := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblAppPool := MakeLabel('Nome do App Pool (IIS)', Y);
  FEdtAppPool := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblPhysical := MakeLabel('Pasta publicada (IIS)', Y);
  FEdtPhysical := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblPackage := MakeLabel('Pasta de pacotes (.zip ou arquivo unico)', Y);
  FEdtPackage := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblBackup := MakeLabel('Pasta de backup', Y);
  FEdtBackup := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblProcessed := MakeLabel('Pasta de pacotes processados', Y);
  FEdtProcessed := MakeEdit(Y);
  Inc(Y, ROW_HEIGHT);

  FLblPoll := MakeLabel('Intervalo de monitoramento (seg)', Y);
  FEdtPoll := MakeEdit(Y);
  FEdtPoll.Width := 100;
  Inc(Y, ROW_HEIGHT);

  FLblKeep := MakeLabel('Backups a manter', Y);
  FEdtKeep := MakeEdit(Y);
  FEdtKeep.Width := 100;
  Inc(Y, ROW_HEIGHT);

  FChkEnabled := TUniCheckBox.Create(Self);
  FChkEnabled.Parent := Self;
  FChkEnabled.Left := EDT_LEFT;
  FChkEnabled.Top := Y;
  FChkEnabled.Width := EDT_WIDTH;
  FChkEnabled.Caption := 'Site habilitado';
  Inc(Y, 28);

  FChkWatch := TUniCheckBox.Create(Self);
  FChkWatch.Parent := Self;
  FChkWatch.Left := EDT_LEFT;
  FChkWatch.Top := Y;
  FChkWatch.Width := EDT_WIDTH;
  FChkWatch.Caption := 'Monitorar pasta de pacotes automaticamente';
  Inc(Y, 40);

  FBtnSalvar := TUniButton.Create(Self);
  FBtnSalvar.Parent := Self;
  FBtnSalvar.Left := EDT_LEFT;
  FBtnSalvar.Top := Y;
  FBtnSalvar.Width := 120;
  FBtnSalvar.Height := 32;
  FBtnSalvar.Caption := 'Salvar';
  FBtnSalvar.OnClick := DoSalvarClick;
  FBtnSalvar.LayoutConfig.Cls := 'dm-btn-primary';

  FBtnCancelar := TUniButton.Create(Self);
  FBtnCancelar.Parent := Self;
  FBtnCancelar.Left := EDT_LEFT + 130;
  FBtnCancelar.Top := Y;
  FBtnCancelar.Width := 120;
  FBtnCancelar.Caption := 'Cancelar';
  FBtnCancelar.OnClick := DoCancelarClick;

  Height := Y + 90;
end;

procedure TSiteEditForm.LoadSite(Site: TDeploySite);
begin
  FEdtName.Text := Site.Name;
  FEdtAppPool.Text := Site.AppPoolName;
  FEdtPhysical.Text := Site.PhysicalPath;
  FEdtPackage.Text := Site.PackageFolder;
  FEdtBackup.Text := Site.BackupFolder;
  FEdtProcessed.Text := Site.ProcessedFolder;
  FEdtPoll.Text := IntToStr(Site.PollIntervalSec);
  FEdtKeep.Text := IntToStr(Site.KeepBackups);
  FChkEnabled.Checked := Site.Enabled;
  FChkWatch.Checked := Site.WatchEnabled;
end;

procedure TSiteEditForm.SaveInto(Site: TDeploySite);
begin
  Site.Name := Trim(FEdtName.Text);
  Site.AppPoolName := Trim(FEdtAppPool.Text);
  Site.PhysicalPath := Trim(FEdtPhysical.Text);
  Site.PackageFolder := Trim(FEdtPackage.Text);
  Site.BackupFolder := Trim(FEdtBackup.Text);
  Site.ProcessedFolder := Trim(FEdtProcessed.Text);
  Site.PollIntervalSec := StrToIntDef(FEdtPoll.Text, 15);
  Site.KeepBackups := StrToIntDef(FEdtKeep.Text, 5);
  Site.Enabled := FChkEnabled.Checked;
  Site.WatchEnabled := FChkWatch.Checked;
end;

procedure TSiteEditForm.DoSalvarClick(Sender: TObject);
begin
  if Trim(FEdtName.Text) = '' then
  begin
    ShowMessage('Informe o nome do site.');
    Exit;
  end;
  if Trim(FEdtAppPool.Text) = '' then
  begin
    ShowMessage('Informe o nome do App Pool no IIS.');
    Exit;
  end;
  if Trim(FEdtPhysical.Text) = '' then
  begin
    ShowMessage('Informe a pasta publicada pelo IIS.');
    Exit;
  end;
  if Trim(FEdtPackage.Text) = '' then
  begin
    ShowMessage('Informe a pasta onde os pacotes .zip serao colocados.');
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TSiteEditForm.DoCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
