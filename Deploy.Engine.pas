unit Deploy.Engine;

interface

uses
  System.SysUtils, System.IOUtils, System.Zip, System.DateUtils, System.Types,
  System.Math, System.Generics.Collections,
  Deploy.Types, Deploy.IISControl, Deploy.Log, Deploy.Config;

// Localiza o pacote mais antigo (primeiro a chegar) pendente na pasta de
// monitoramento do site. Retorna '' se nao houver nenhum.
function FindPendingPackage(Site: TDeploySite): string;

// Executa o deploy de um pacote especifico para o site informado: para o app
// pool, substitui apenas o(s) arquivo(s) do pacote (fazendo backup somente
// do arquivo antigo que estiver sendo sobrescrito, sem limpar o restante da
// pasta publicada), reinicia o app pool e registra o resultado no log.
// O pacote pode ser um .zip (um ou mais arquivos, preservando subpastas) ou
// um unico arquivo solto (ex.: uma .dll), que e copiado direto para a raiz
// da pasta publicada. Retorna True em caso de sucesso.
function DeployPackage(Site: TDeploySite; const PackagePath: string; out ErrorMsg: string): Boolean;

implementation

// Copia UmArquivo para dentro da pasta publicada do site, na posicao dada
// por RelPath. Se ja existir um arquivo nesse destino, guarda uma copia dele
// na pasta de backup (BackupFolder\Stamp\RelPath) antes de sobrescrever.
procedure DeployOneFile(Site: TDeploySite; const SrcFile, RelPath, Stamp: string);
var
  TargetFile, BackupFile: string;
begin
  TargetFile := TPath.Combine(Site.PhysicalPath, RelPath);

  if TFile.Exists(TargetFile) and (Site.BackupFolder <> '') then
  begin
    BackupFile := TPath.Combine(TPath.Combine(Site.BackupFolder, Stamp), RelPath);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(BackupFile));
    TFile.Copy(TargetFile, BackupFile, True);
  end;

  TDirectory.CreateDirectory(TPath.GetDirectoryName(TargetFile));
  TFile.Copy(SrcFile, TargetFile, True);
end;

procedure PruneOldFolders(const ParentDir: string; KeepCount: Integer);
var
  Dirs: TStringDynArray;
  I: Integer;
begin
  if KeepCount <= 0 then
    Exit;
  if not TDirectory.Exists(ParentDir) then
    Exit;
  Dirs := TDirectory.GetDirectories(ParentDir);
  TArray.Sort<string>(Dirs);
  if Length(Dirs) <= KeepCount then
    Exit;
  for I := 0 to Length(Dirs) - KeepCount - 1 do
    try
      TDirectory.Delete(Dirs[I], True);
    except
      // ignora falha ao remover backup antigo
    end;
end;

procedure PruneOldFiles(const ParentDir: string; KeepCount: Integer);
var
  Files: TStringDynArray;
  I: Integer;
begin
  if (KeepCount <= 0) or not TDirectory.Exists(ParentDir) then
    Exit;
  Files := TDirectory.GetFiles(ParentDir, '*.*');
  TArray.Sort<string>(Files);
  if Length(Files) <= KeepCount then
    Exit;
  for I := 0 to Length(Files) - KeepCount - 1 do
    try
      TFile.Delete(Files[I]);
    except
      // ignora falha ao remover pacote antigo
    end;
end;

function FindPendingPackage(Site: TDeploySite): string;
var
  Files: TStringDynArray;
  Oldest: string;
  I: Integer;
begin
  Result := '';
  if not TDirectory.Exists(Site.PackageFolder) then
    Exit;
  Files := TDirectory.GetFiles(Site.PackageFolder, '*.*');
  if Length(Files) = 0 then
    Exit;

  Oldest := Files[0];
  for I := 1 to High(Files) do
    if TFile.GetLastWriteTimeUtc(Files[I]) < TFile.GetLastWriteTimeUtc(Oldest) then
      Oldest := Files[I];
  Result := Oldest;
end;

function DeployPackage(Site: TDeploySite; const PackagePath: string; out ErrorMsg: string): Boolean;
var
  Stamp: string;
  TempExtractDir, ProcessedPath: string;
  PoolErr: string;
  StartedAt: TDateTime;
  PoolWasRunning: Boolean;
  SrcFile, RelPath: string;
begin
  Result := False;
  ErrorMsg := '';
  StartedAt := Now;
  Stamp := FormatDateTime('yyyymmdd_hhnnss', StartedAt);

  DeployLog.Add(Site.Name, dsEmAndamento, 'Iniciando deploy do pacote: ' + ExtractFileName(PackagePath));

  PoolWasRunning := GetAppPoolState(Site.AppPoolName) = apsStarted;
  try
    // 1) Para o App Pool para liberar os arquivos em uso pelo IIS
    if not StopAppPool(Site.AppPoolName, PoolErr) then
      raise Exception.Create('Falha ao parar o App Pool: ' + PoolErr);
    if not WaitForAppPoolState(Site.AppPoolName, apsStopped, 30) then
      raise Exception.Create('Tempo limite esperando o App Pool parar.');

    TDirectory.CreateDirectory(Site.PhysicalPath);

    // 2) Substitui somente o(s) arquivo(s) do pacote, fazendo backup apenas
    //    dos arquivos antigos que estiverem sendo sobrescritos.
    if SameText(ExtractFileExt(PackagePath), '.zip') then
    begin
      TempExtractDir := TPath.Combine(TPath.GetTempPath, 'deploy_' + Stamp);
      TDirectory.CreateDirectory(TempExtractDir);
      try
        TZipFile.ExtractZipFile(PackagePath, TempExtractDir);
        for SrcFile in TDirectory.GetFiles(TempExtractDir, '*', TSearchOption.soAllDirectories) do
        begin
          RelPath := ExtractRelativePath(IncludeTrailingPathDelimiter(TempExtractDir), SrcFile);
          DeployOneFile(Site, SrcFile, RelPath, Stamp);
        end;
      finally
        try
          TDirectory.Delete(TempExtractDir, True);
        except
          // ignora falha ao limpar temporario
        end;
      end;
    end
    else
      // pacote e um unico arquivo solto (ex.: uma .dll) -> vai direto para a
      // raiz da pasta publicada, com o mesmo nome
      DeployOneFile(Site, PackagePath, ExtractFileName(PackagePath), Stamp);

    if Site.BackupFolder <> '' then
      PruneOldFolders(Site.BackupFolder, Site.KeepBackups);

    // 3) Reinicia o App Pool
    if PoolWasRunning then
    begin
      if not StartAppPool(Site.AppPoolName, PoolErr) then
        raise Exception.Create('Deploy dos arquivos concluido, mas falhou ao iniciar o App Pool: ' + PoolErr);
      WaitForAppPoolState(Site.AppPoolName, apsStarted, 30);
    end;

    // 4) Move o pacote processado para a pasta de historico
    if Site.ProcessedFolder <> '' then
    begin
      TDirectory.CreateDirectory(Site.ProcessedFolder);
      ProcessedPath := TPath.Combine(Site.ProcessedFolder, Stamp + '_' + ExtractFileName(PackagePath));
      TFile.Move(PackagePath, ProcessedPath);
      PruneOldFiles(Site.ProcessedFolder, Max(Site.KeepBackups, 5));
    end
    else
      TFile.Delete(PackagePath);

    Site.LastDeployAt := Now;
    Site.LastStatus := dsSucesso;
    Site.LastMessage := Format('Concluido em %.1fs', [SecondSpan(StartedAt, Now)]);
    DeployLog.Add(Site.Name, dsSucesso, Site.LastMessage);
    Result := True;
  except
    on E: Exception do
    begin
      ErrorMsg := E.Message;
      Site.LastDeployAt := Now;
      Site.LastStatus := dsFalha;
      Site.LastMessage := ErrorMsg;
      DeployLog.Add(Site.Name, dsFalha, ErrorMsg);

      // rede de seguranca: tenta garantir que o App Pool nao fique parado
      if PoolWasRunning and (GetAppPoolState(Site.AppPoolName) <> apsStarted) then
        StartAppPool(Site.AppPoolName, PoolErr);
    end;
  end;
end;

end.
