unit Deploy.ProcessUtils;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

// Executa um comando de console, aguarda terminar (com timeout) e captura stdout+stderr.
function RunConsoleCommand(const CommandLine: string; out Output: string;
  out ExitCode: Cardinal; TimeoutMs: Cardinal = 30000): Boolean;

implementation

function RunConsoleCommand(const CommandLine: string; out Output: string;
  out ExitCode: Cardinal; TimeoutMs: Cardinal): Boolean;
var
  SecAttr: TSecurityAttributes;
  StdOutRead, StdOutWrite: THandle;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Buffer: array[0..4095] of AnsiChar;
  BytesRead: Cardinal;
  ChunkStr: AnsiString;
  MutableCmd: string;
  WaitResult: Cardinal;
begin
  Output := '';
  ExitCode := 0;
  Result := False;

  FillChar(SecAttr, SizeOf(SecAttr), 0);
  SecAttr.nLength := SizeOf(SecAttr);
  SecAttr.bInheritHandle := True;
  SecAttr.lpSecurityDescriptor := nil;

  if not CreatePipe(StdOutRead, StdOutWrite, @SecAttr, 0) then
    RaiseLastOSError;
  try
    if not SetHandleInformation(StdOutRead, HANDLE_FLAG_INHERIT, 0) then
      RaiseLastOSError;

    FillChar(StartInfo, SizeOf(StartInfo), 0);
    StartInfo.cb := SizeOf(StartInfo);
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.wShowWindow := SW_HIDE;
    StartInfo.hStdOutput := StdOutWrite;
    StartInfo.hStdError := StdOutWrite;
    StartInfo.hStdInput := 0;

    FillChar(ProcInfo, SizeOf(ProcInfo), 0);

    MutableCmd := CommandLine;
    UniqueString(MutableCmd);

    if not CreateProcess(nil, PChar(MutableCmd), nil, nil, True,
      CREATE_NO_WINDOW, nil, nil, StartInfo, ProcInfo) then
      RaiseLastOSError;

    CloseHandle(StdOutWrite);
    StdOutWrite := 0;
    try
      while True do
      begin
        if not ReadFile(StdOutRead, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) or (BytesRead = 0) then
          Break;
        SetString(ChunkStr, PAnsiChar(@Buffer), BytesRead);
        Output := Output + string(ChunkStr);
      end;

      WaitResult := WaitForSingleObject(ProcInfo.hProcess, TimeoutMs);
      if WaitResult = WAIT_TIMEOUT then
      begin
        TerminateProcess(ProcInfo.hProcess, 1);
        raise Exception.Create('Tempo limite excedido ao executar: ' + CommandLine);
      end;

      GetExitCodeProcess(ProcInfo.hProcess, ExitCode);
      Result := True;
    finally
      CloseHandle(ProcInfo.hProcess);
      CloseHandle(ProcInfo.hThread);
    end;
  finally
    if StdOutWrite <> 0 then
      CloseHandle(StdOutWrite);
    CloseHandle(StdOutRead);
  end;
end;

end.
