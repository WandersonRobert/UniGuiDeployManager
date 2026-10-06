unit Main;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Graphics, Dialogs, DateUtils,
  uniGUITypes, uniGUIAbstractClasses, uniGUIClasses, uniGUIForm,
  uniGUIBaseClasses, uniGUIRegClasses, uniGUIDialogs,
  uniButton, uniLabel, uniPanel, uniStringGrid, uniTimer, uniFileUpload,
  Deploy.Types, Deploy.Config, Deploy.Engine, Deploy.IISControl, Deploy.Log;

type
  TMainForm = class(TUniForm)
  private
    FSidebar: TUniPanel;
    FSidebarBrand: TUniPanel;
    FLblBrand: TUniLabel;
    FNavItemSites: TUniPanel;
    FLblNavSites: TUniLabel;
    FNavbar: TUniPanel;
    FLblPageTitle: TUniLabel;
    FLblUserInfo: TUniLabel;
    FBtnLogout: TUniButton;
    FContentWrapper: TUniPanel;
    FPanelToolbar: TUniPanel;
    FBtnNovo: TUniButton;
    FBtnEditar: TUniButton;
    FBtnExcluir: TUniButton;
    FBtnAtualizar: TUniButton;
    FBtnParar: TUniButton;
    FBtnIniciar: TUniButton;
    FBtnReciclar: TUniButton;
    FBtnUpload: TUniButton;
    FUpload: TUniFileUpload;
    FGridSites: TUniStringGrid;
    FPanelLog: TUniPanel;
    FLblLogTitle: TUniLabel;
    FGridLog: TUniStringGrid;
    FTimerRefresh: TUniTimer;
    FRowSiteNames: TArray<string>;
    FUploadTargetSite: string;

    procedure BuildUI;
    procedure RefreshSitesGrid;
    procedure RefreshLogGrid;
    function SelectedSite: TDeploySite;

    procedure DoNovoClick(Sender: TObject);
    procedure DoEditarClick(Sender: TObject);
    procedure DoExcluirClick(Sender: TObject);
    procedure DoAtualizarClick(Sender: TObject);
    procedure DoPararClick(Sender: TObject);
    procedure DoIniciarClick(Sender: TObject);
    procedure DoReciclarClick(Sender: TObject);
    procedure DoUploadClick(Sender: TObject);
    procedure DoUploadCompleted(Sender: TObject; AStream: TFileStream);
    procedure DoLogoutClick(Sender: TObject);
    procedure DoTimerRefresh(Sender: TObject);
    procedure DoGridSitesDrawCell(Sender: TObject; ACol, ARow: Integer; var Value: string; Attribs: TUniCellAttribs);
    procedure DoGridLogDrawCell(Sender: TObject; ACol, ARow: Integer; var Value: string; Attribs: TUniCellAttribs);
  public
    constructor Create(AOwner: TComponent); override;
  end;

function MainForm: TMainForm;

implementation

uses
  IOUtils, uniGUIVars, MainModule, SiteEdit;

function MainForm: TMainForm;
begin
  Result := TMainForm(UniMainModule.GetFormInstance(TMainForm));
end;

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if not (csDesigning in ComponentState) then
  begin
    BuildUI;
    RefreshSitesGrid;
    RefreshLogGrid;
  end;
end;

procedure TMainForm.BuildUI;
begin
  Caption := 'UniGUI Deploy Manager';
  WindowState := wsMaximized;
  BorderStyle := bsNone;

  // ---- Sidebar (estilo AdminLTE) ----
  FSidebar := TUniPanel.Create(Self);
  FSidebar.Parent := Self;
  FSidebar.Align := alLeft;
  FSidebar.Width := 230;
  FSidebar.BorderStyle := ubsNone;
  FSidebar.LayoutConfig.Cls := 'dm-sidebar';

  FSidebarBrand := TUniPanel.Create(Self);
  FSidebarBrand.Parent := FSidebar;
  FSidebarBrand.Align := alTop;
  FSidebarBrand.Height := 50;
  FSidebarBrand.BorderStyle := ubsNone;
  FSidebarBrand.LayoutConfig.Cls := 'dm-sidebar-brand';

  FLblBrand := TUniLabel.Create(Self);
  FLblBrand.Parent := FSidebarBrand;
  FLblBrand.Left := 16;
  FLblBrand.Top := 15;
  FLblBrand.Caption := 'DEPLOY MANAGER';
  FLblBrand.Font.Style := [fsBold];
  FLblBrand.Font.Color := clWhite;

  FNavItemSites := TUniPanel.Create(Self);
  FNavItemSites.Parent := FSidebar;
  FNavItemSites.Align := alTop;
  FNavItemSites.Top := 50;
  FNavItemSites.Height := 42;
  FNavItemSites.BorderStyle := ubsNone;
  FNavItemSites.LayoutConfig.Cls := 'dm-nav-active';

  FLblNavSites := TUniLabel.Create(Self);
  FLblNavSites.Parent := FNavItemSites;
  FLblNavSites.Left := 20;
  FLblNavSites.Top := 12;
  FLblNavSites.Caption := 'Sites';
  FLblNavSites.Font.Color := clWhite;
  FLblNavSites.Font.Style := [fsBold];

  // ---- Navbar superior (area a direita da sidebar) ----
  FNavbar := TUniPanel.Create(Self);
  FNavbar.Parent := Self;
  FNavbar.Align := alTop;
  FNavbar.Height := 50;
  FNavbar.BorderStyle := ubsNone;
  FNavbar.LayoutConfig.Cls := 'dm-navbar';

  FLblPageTitle := TUniLabel.Create(Self);
  FLblPageTitle.Parent := FNavbar;
  FLblPageTitle.Left := 20;
  FLblPageTitle.Top := 15;
  FLblPageTitle.Caption := 'Gerenciamento de Sites';
  FLblPageTitle.Font.Size := 13;
  FLblPageTitle.Font.Style := [fsBold];
  FLblPageTitle.Font.Color := RGB(44, 62, 80);

  FLblUserInfo := TUniLabel.Create(Self);
  FLblUserInfo.Parent := FNavbar;
  FLblUserInfo.Left := 780;
  FLblUserInfo.Top := 17;
  FLblUserInfo.Caption := AppConfig.Settings.AdminUser;
  FLblUserInfo.Font.Color := RGB(119, 119, 119);

  FBtnLogout := TUniButton.Create(Self);
  FBtnLogout.Parent := FNavbar;
  FBtnLogout.Left := 900;
  FBtnLogout.Top := 9;
  FBtnLogout.Width := 90;
  FBtnLogout.Height := 30;
  FBtnLogout.Caption := 'Sair';
  FBtnLogout.OnClick := DoLogoutClick;
  FBtnLogout.LayoutConfig.Cls := 'dm-btn-navlight';

  // ---- Area de conteudo ----
  FContentWrapper := TUniPanel.Create(Self);
  FContentWrapper.Parent := Self;
  FContentWrapper.Align := alClient;
  FContentWrapper.BorderStyle := ubsNone;
  FContentWrapper.Color := RGB(236, 240, 245);

  FPanelToolbar := TUniPanel.Create(Self);
  FPanelToolbar.Parent := FContentWrapper;
  FPanelToolbar.Align := alTop;
  FPanelToolbar.Height := 56;
  FPanelToolbar.BorderStyle := ubsNone;
  FPanelToolbar.LayoutConfig.Cls := 'dm-box-header';

  FBtnNovo := TUniButton.Create(Self);
  FBtnNovo.Parent := FPanelToolbar;
  FBtnNovo.Left := 12;
  FBtnNovo.Top := 13;
  FBtnNovo.Width := 110;
  FBtnNovo.Height := 30;
  FBtnNovo.Caption := 'Novo site';
  FBtnNovo.OnClick := DoNovoClick;
  FBtnNovo.LayoutConfig.Cls := 'dm-btn-primary';

  FBtnEditar := TUniButton.Create(Self);
  FBtnEditar.Parent := FPanelToolbar;
  FBtnEditar.Left := 130;
  FBtnEditar.Top := 13;
  FBtnEditar.Width := 90;
  FBtnEditar.Height := 30;
  FBtnEditar.Caption := 'Editar';
  FBtnEditar.OnClick := DoEditarClick;

  FBtnExcluir := TUniButton.Create(Self);
  FBtnExcluir.Parent := FPanelToolbar;
  FBtnExcluir.Left := 228;
  FBtnExcluir.Top := 13;
  FBtnExcluir.Width := 90;
  FBtnExcluir.Height := 30;
  FBtnExcluir.Caption := 'Excluir';
  FBtnExcluir.OnClick := DoExcluirClick;
  FBtnExcluir.LayoutConfig.Cls := 'dm-btn-danger';

  FBtnAtualizar := TUniButton.Create(Self);
  FBtnAtualizar.Parent := FPanelToolbar;
  FBtnAtualizar.Left := 334;
  FBtnAtualizar.Top := 13;
  FBtnAtualizar.Width := 100;
  FBtnAtualizar.Height := 30;
  FBtnAtualizar.Caption := 'Atualizar';
  FBtnAtualizar.OnClick := DoAtualizarClick;

  FBtnParar := TUniButton.Create(Self);
  FBtnParar.Parent := FPanelToolbar;
  FBtnParar.Left := 460;
  FBtnParar.Top := 13;
  FBtnParar.Width := 110;
  FBtnParar.Height := 30;
  FBtnParar.Caption := 'Parar pool';
  FBtnParar.OnClick := DoPararClick;
  FBtnParar.LayoutConfig.Cls := 'dm-btn-warning';

  FBtnIniciar := TUniButton.Create(Self);
  FBtnIniciar.Parent := FPanelToolbar;
  FBtnIniciar.Left := 578;
  FBtnIniciar.Top := 13;
  FBtnIniciar.Width := 110;
  FBtnIniciar.Height := 30;
  FBtnIniciar.Caption := 'Iniciar pool';
  FBtnIniciar.OnClick := DoIniciarClick;
  FBtnIniciar.LayoutConfig.Cls := 'dm-btn-success';

  FBtnReciclar := TUniButton.Create(Self);
  FBtnReciclar.Parent := FPanelToolbar;
  FBtnReciclar.Left := 696;
  FBtnReciclar.Top := 13;
  FBtnReciclar.Width := 110;
  FBtnReciclar.Height := 30;
  FBtnReciclar.Caption := 'Reciclar pool';
  FBtnReciclar.OnClick := DoReciclarClick;
  FBtnReciclar.LayoutConfig.Cls := 'dm-btn-info';

  FBtnUpload := TUniButton.Create(Self);
  FBtnUpload.Parent := FPanelToolbar;
  FBtnUpload.Left := 822;
  FBtnUpload.Top := 13;
  FBtnUpload.Width := 170;
  FBtnUpload.Height := 30;
  FBtnUpload.Caption := 'Enviar arquivo/pacote';
  FBtnUpload.OnClick := DoUploadClick;
  FBtnUpload.LayoutConfig.Cls := 'dm-btn-primary';

  FUpload := TUniFileUpload.Create(Self);
  FUpload.Filter := '*.zip;*.dll;*.exe;*.*';
  FUpload.MaxAllowedSize := 500 * 1024 * 1024;
  FUpload.OnCompleted := DoUploadCompleted;

  FGridSites := TUniStringGrid.Create(Self);
  FGridSites.Parent := FContentWrapper;
  FGridSites.Align := alClient;
  FGridSites.FixedRows := 1;
  FGridSites.FixedCols := 0;
  FGridSites.ColCount := 7;
  FGridSites.RowCount := 1;
  FGridSites.Cells[0, 0] := 'Nome';
  FGridSites.Cells[1, 0] := 'App Pool';
  FGridSites.Cells[2, 0] := 'Caminho fisico';
  FGridSites.Cells[3, 0] := 'Habilitado';
  FGridSites.Cells[4, 0] := 'Auto monitor';
  FGridSites.Cells[5, 0] := 'Status pool';
  FGridSites.Cells[6, 0] := 'Ultimo deploy';
  FGridSites.ColWidths[0] := 140;
  FGridSites.ColWidths[1] := 140;
  FGridSites.ColWidths[2] := 260;
  FGridSites.ColWidths[3] := 85;
  FGridSites.ColWidths[4] := 95;
  FGridSites.ColWidths[5] := 95;
  FGridSites.ColWidths[6] := 240;
  FGridSites.DefaultRowHeight := 30;
  FGridSites.OnDrawCell := DoGridSitesDrawCell;

  FPanelLog := TUniPanel.Create(Self);
  FPanelLog.Parent := FContentWrapper;
  FPanelLog.Align := alBottom;
  FPanelLog.Height := 260;
  FPanelLog.BorderStyle := ubsNone;
  FPanelLog.Color := clWhite;

  FLblLogTitle := TUniLabel.Create(Self);
  FLblLogTitle.Parent := FPanelLog;
  FLblLogTitle.Left := 12;
  FLblLogTitle.Top := 10;
  FLblLogTitle.Caption := 'HISTORICO DE DEPLOYS';
  FLblLogTitle.Font.Style := [fsBold];
  FLblLogTitle.Font.Size := 11;
  FLblLogTitle.Font.Color := RGB(44, 62, 80);

  FGridLog := TUniStringGrid.Create(Self);
  FGridLog.Parent := FPanelLog;
  FGridLog.Align := alBottom;
  FGridLog.Height := 222;
  FGridLog.FixedRows := 1;
  FGridLog.FixedCols := 0;
  FGridLog.ColCount := 4;
  FGridLog.RowCount := 1;
  FGridLog.Cells[0, 0] := 'Data/Hora';
  FGridLog.Cells[1, 0] := 'Site';
  FGridLog.Cells[2, 0] := 'Status';
  FGridLog.Cells[3, 0] := 'Mensagem';
  FGridLog.ColWidths[0] := 130;
  FGridLog.ColWidths[1] := 140;
  FGridLog.ColWidths[2] := 110;
  FGridLog.ColWidths[3] := 560;
  FGridLog.DefaultRowHeight := 28;
  FGridLog.OnDrawCell := DoGridLogDrawCell;

  FTimerRefresh := TUniTimer.Create(Self);
  FTimerRefresh.Interval := 10000;
  FTimerRefresh.OnTimer := DoTimerRefresh;
  FTimerRefresh.Enabled := True;
end;

procedure TMainForm.RefreshSitesGrid;
var
  Sites: TDeploySites;
  I: Integer;
  Site: TDeploySite;
  PoolState: TAppPoolState;
  PoolStr, LastDeployStr: string;
begin
  Sites := AppConfig.LockSites;
  try
    SetLength(FRowSiteNames, Sites.Count);
    FGridSites.RowCount := Sites.Count + 1;
    for I := 0 to Sites.Count - 1 do
    begin
      Site := Sites[I];
      FRowSiteNames[I] := Site.Name;

      if Site.AppPoolName <> '' then
      begin
        PoolState := GetAppPoolState(Site.AppPoolName);
        case PoolState of
          apsStarted: PoolStr := 'Iniciado';
          apsStopped: PoolStr := 'Parado';
          apsStarting: PoolStr := 'Iniciando';
          apsStopping: PoolStr := 'Parando';
        else
          PoolStr := 'Desconhecido';
        end;
      end
      else
        PoolStr := '-';

      if Site.LastDeployAt > 0 then
        LastDeployStr := FormatDateTime('dd/mm/yyyy hh:nn:ss', Site.LastDeployAt) +
          ' - ' + DeployStatusToStr(Site.LastStatus)
      else
        LastDeployStr := DeployStatusToStr(Site.LastStatus);

      FGridSites.Cells[0, I + 1] := Site.Name;
      FGridSites.Cells[1, I + 1] := Site.AppPoolName;
      FGridSites.Cells[2, I + 1] := Site.PhysicalPath;
      if Site.Enabled then
        FGridSites.Cells[3, I + 1] := 'Sim'
      else
        FGridSites.Cells[3, I + 1] := 'Nao';
      if Site.WatchEnabled then
        FGridSites.Cells[4, I + 1] := 'Sim'
      else
        FGridSites.Cells[4, I + 1] := 'Nao';
      FGridSites.Cells[5, I + 1] := PoolStr;
      FGridSites.Cells[6, I + 1] := LastDeployStr;
    end;
  finally
    AppConfig.UnlockSites;
  end;
end;

procedure TMainForm.RefreshLogGrid;
var
  Entries: TArray<TDeployLogEntry>;
  I: Integer;
begin
  Entries := DeployLog.GetEntries;
  FGridLog.RowCount := Length(Entries) + 1;
  for I := 0 to High(Entries) do
  begin
    FGridLog.Cells[0, I + 1] := FormatDateTime('dd/mm/yyyy hh:nn:ss', Entries[I].When);
    FGridLog.Cells[1, I + 1] := Entries[I].SiteName;
    FGridLog.Cells[2, I + 1] := DeployStatusToStr(Entries[I].Status);
    FGridLog.Cells[3, I + 1] := Entries[I].Message;
  end;
end;

function TMainForm.SelectedSite: TDeploySite;
var
  Idx: Integer;
begin
  Result := nil;
  Idx := FGridSites.Row - 1;
  if (Idx >= 0) and (Idx <= High(FRowSiteNames)) then
    Result := AppConfig.FindSite(FRowSiteNames[Idx]);
end;

procedure TMainForm.DoNovoClick(Sender: TObject);
var
  NewSite: TDeploySite;
  EditForm: TSiteEditForm;
begin
  NewSite := TDeploySite.Create;
  NewSite.Name := 'NovoSite';
  NewSite.PollIntervalSec := 15;
  NewSite.KeepBackups := 5;

  EditForm := TSiteEditForm.Create(UniApplication);
  EditForm.LoadSite(NewSite);
  EditForm.ShowModal(
    procedure(Sender: TComponent; AResult: Integer)
    begin
      try
        if AResult = mrOk then
        begin
          EditForm.SaveInto(NewSite);
          if AppConfig.FindSite(NewSite.Name) <> nil then
            ShowMessage('Ja existe um site com esse nome.')
          else
          begin
            AppConfig.LockSites.Add(NewSite.Clone);
            AppConfig.UnlockSites;
            AppConfig.Save;
            RefreshSitesGrid;
          end;
        end;
      finally
        EditForm.Release;
        NewSite.Free;
      end;
    end);
end;

procedure TMainForm.DoEditarClick(Sender: TObject);
var
  Site, Working: TDeploySite;
  EditForm: TSiteEditForm;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade.');
    Exit;
  end;

  Working := Site.Clone;
  EditForm := TSiteEditForm.Create(UniApplication);
  EditForm.LoadSite(Working);
  EditForm.ShowModal(
    procedure(Sender: TComponent; AResult: Integer)
    begin
      try
        if AResult = mrOk then
        begin
          EditForm.SaveInto(Working);
          Site.AssignFrom(Working);
          AppConfig.Save;
          RefreshSitesGrid;
        end;
      finally
        EditForm.Release;
        Working.Free;
      end;
    end);
end;

procedure TMainForm.DoExcluirClick(Sender: TObject);
var
  Site: TDeploySite;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade.');
    Exit;
  end;

  MessageDlg('Remover o site "' + Site.Name + '" da lista? Os arquivos publicados NAO serao apagados.',
    mtConfirmation, [mbYes, mbNo],
    procedure(Sender: TComponent; AResult: Integer)
    var
      Sites: TDeploySites;
    begin
      if AResult = mrYes then
      begin
        Sites := AppConfig.LockSites;
        try
          Sites.Remove(Site);
        finally
          AppConfig.UnlockSites;
        end;
        AppConfig.Save;
        RefreshSitesGrid;
      end;
    end);
end;

procedure TMainForm.DoAtualizarClick(Sender: TObject);
begin
  RefreshSitesGrid;
  RefreshLogGrid;
end;

procedure TMainForm.DoPararClick(Sender: TObject);
var
  Site: TDeploySite;
  ErrorMsg: string;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade.');
    Exit;
  end;
  if StopAppPool(Site.AppPoolName, ErrorMsg) then
    ShowMessage('App Pool parado.')
  else
    ShowMessage('Falha ao parar: ' + ErrorMsg);
  RefreshSitesGrid;
end;

procedure TMainForm.DoIniciarClick(Sender: TObject);
var
  Site: TDeploySite;
  ErrorMsg: string;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade.');
    Exit;
  end;
  if StartAppPool(Site.AppPoolName, ErrorMsg) then
    ShowMessage('App Pool iniciado.')
  else
    ShowMessage('Falha ao iniciar: ' + ErrorMsg);
  RefreshSitesGrid;
end;

procedure TMainForm.DoReciclarClick(Sender: TObject);
var
  Site: TDeploySite;
  ErrorMsg: string;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade.');
    Exit;
  end;
  if RecycleAppPool(Site.AppPoolName, ErrorMsg) then
    ShowMessage('App Pool reciclado.')
  else
    ShowMessage('Falha ao reciclar: ' + ErrorMsg);
  RefreshSitesGrid;
end;

procedure TMainForm.DoUploadClick(Sender: TObject);
var
  Site: TDeploySite;
begin
  Site := SelectedSite;
  if not Assigned(Site) then
  begin
    ShowMessage('Selecione um site na grade antes de enviar o pacote.');
    Exit;
  end;
  if Site.Busy then
  begin
    ShowMessage('Ja existe um deploy em andamento para este site.');
    Exit;
  end;
  FUploadTargetSite := Site.Name;
  FUpload.Execute;
end;

procedure TMainForm.DoUploadCompleted(Sender: TObject; AStream: TFileStream);
var
  Site: TDeploySite;
  DestPath, ErrorMsg, OrigName: string;
begin
  Site := AppConfig.FindSite(FUploadTargetSite);
  if not Assigned(Site) then
  begin
    ShowMessage('Site de destino nao encontrado.');
    Exit;
  end;

  if Site.Busy then
  begin
    ShowMessage('Ja existe um deploy em andamento para este site.');
    Exit;
  end;

  OrigName := ExtractFileName(FUpload.FileName);
  if OrigName = '' then
    OrigName := 'pacote.zip';

  TDirectory.CreateDirectory(Site.PackageFolder);
  DestPath := TPath.Combine(Site.PackageFolder,
    FormatDateTime('yyyymmdd_hhnnss', Now) + '_' + OrigName);
  TFile.Copy(AStream.FileName, DestPath, True);

  Site.Busy := True;
  ShowProgress('Implantando pacote em "' + Site.Name + '"...');
  try
    if DeployPackage(Site, DestPath, ErrorMsg) then
      ShowMessageN('Deploy concluido com sucesso para "' + Site.Name + '".')
    else
      ShowMessageN('Falha no deploy de "' + Site.Name + '": ' + ErrorMsg);
    AppConfig.Save;
  finally
    Site.Busy := False;
    HideProgress;
  end;

  RefreshSitesGrid;
  RefreshLogGrid;
end;

procedure TMainForm.DoLogoutClick(Sender: TObject);
begin
  UniApplication.Terminate('Sessao encerrada.');
end;

procedure TMainForm.DoTimerRefresh(Sender: TObject);
begin
  RefreshSitesGrid;
  RefreshLogGrid;
end;

procedure ApplyStatusBadge(Attribs: TUniCellAttribs; const Value: string);
begin
  if SameText(Value, 'Iniciado') or SameText(Value, 'Sucesso') or SameText(Value, 'Sim') then
  begin
    Attribs.Color := RGB(0, 166, 90);
    Attribs.Font.Color := clWhite;
    Attribs.Font.Style := [fsBold];
  end
  else if SameText(Value, 'Parado') or SameText(Value, 'Falha') then
  begin
    Attribs.Color := RGB(221, 75, 57);
    Attribs.Font.Color := clWhite;
    Attribs.Font.Style := [fsBold];
  end
  else if SameText(Value, 'Iniciando') or SameText(Value, 'Parando') or SameText(Value, 'Em andamento...') then
  begin
    Attribs.Color := RGB(243, 156, 18);
    Attribs.Font.Color := clWhite;
    Attribs.Font.Style := [fsBold];
  end
  else
  begin
    Attribs.Color := RGB(210, 214, 222);
    Attribs.Font.Color := RGB(68, 68, 68);
  end;
end;

procedure TMainForm.DoGridSitesDrawCell(Sender: TObject; ACol, ARow: Integer; var Value: string; Attribs: TUniCellAttribs);
begin
  if (ARow = 0) or not (ACol in [3, 4, 5]) then
    Exit;
  ApplyStatusBadge(Attribs, Value);
end;

procedure TMainForm.DoGridLogDrawCell(Sender: TObject; ACol, ARow: Integer; var Value: string; Attribs: TUniCellAttribs);
begin
  if (ARow = 0) or (ACol <> 2) then
    Exit;
  ApplyStatusBadge(Attribs, Value);
end;

initialization
  RegisterAppFormClass(TMainForm);

end.
