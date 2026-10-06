# UniGUI Deploy Manager

Aplicacao UniGUI (Delphi) que automatiza a publicacao de outras aplicacoes no
IIS: recebe um pacote (por upload no navegador ou por uma pasta monitorada),
para o App Pool, substitui apenas o(s) arquivo(s) do pacote (ex.: uma `.dll`)
dentro da pasta publicada e reinicia o App Pool -- sem precisar abrir o
Gerenciador do IIS manualmente.

O deploy e feito por **arquivo**, nao por pasta inteira: nada alem do que
esta no pacote e tocado, e o restante do conteudo publicado permanece
intacto. Antes de sobrescrever um arquivo que ja existe no destino, o
Deploy Manager guarda uma copia apenas **daquele arquivo** na pasta de
backup (nao da pasta inteira).

Testado com Delphi 11 Alexandria + UniGUI 1.99, compilando e rodando como
aplicacao standalone (servidor HTTP embutido do UniGUI, porta 8077 por
padrao).

## Como funciona

1. Cada "site" cadastrado no Deploy Manager aponta para:
   - o **App Pool** do IIS que sera parado/iniciado a cada deploy;
   - a **pasta publicada** (o `PhysicalPath` do site/aplicacao no IIS);
   - uma **pasta de pacotes** onde os pacotes chegam;
   - opcionalmente, uma **pasta de backup** (copia apenas dos arquivos que
     forem sobrescritos a cada deploy, nao da pasta publicada inteira) e uma
     **pasta de processados** (historico dos pacotes ja aplicados).
2. O pacote pode ser:
   - um **arquivo unico** (ex.: `MinhaApp.dll`) -- e copiado direto para a
     raiz da pasta publicada, substituindo so esse arquivo;
   - um **.zip** com um ou mais arquivos, preservando subpastas -- cada
     arquivo do zip substitui o correspondente na pasta publicada (o
     restante da pasta publicada nao e alterado nem limpo).
3. Um deploy pode ser disparado de duas formas:
   - **Upload manual**: selecione o site na grade e clique em
     "Enviar arquivo/pacote";
   - **Monitoramento automatico**: marque "Monitorar pasta de pacotes
     automaticamente" ao cadastrar o site; uma thread em segundo plano
     verifica a pasta de pacotes a cada poucos segundos e implanta
     automaticamente qualquer arquivo novo (util para integrar com um
     pipeline de CI que apenas copia o arquivo para essa pasta).
4. O controle do IIS e feito chamando `appcmd.exe` (vem com o proprio IIS,
   normalmente em `C:\Windows\System32\inetsrv\appcmd.exe`).

## Requisitos no servidor Windows/IIS

- IIS instalado (para existir `appcmd.exe`).
- A conta que executa o Deploy Manager precisa de permissao para:
  - iniciar/parar/reciclar Application Pools (normalmente requer ser
    Administrador local, ou ter permissao especifica via
    `%windir%\system32\inetsrv\config\administration.config` /
    IIS Manager Permissions);
  - ler e escrever nas pastas publicadas dos sites que ela vai gerenciar.
- Recomenda-se rodar o Deploy Manager **fora do IIS**, como aplicacao
  standalone (executavel proprio) ou como **Windows Service**, e nao como
  extensao ISAPI dentro do proprio IIS -- assim ele consegue reciclar
  App Pools (inclusive o de outras aplicacoes) sem risco de derrubar a si
  mesmo.

## Rodando como Windows Service

O UniGUI Standalone ja vem preparado para rodar como servico Windows.
A partir de um prompt com privilegios de administrador, no servidor:

```bash
UniGuiDeployManager.exe /install
```

Isso registra o executavel como servico Windows (nome baseado no titulo do
`ServerModule`). Depois, inicie o servico normalmente pelo
`services.msc` ou via `net start`. Para remover o registro do servico:

```bash
UniGuiDeployManager.exe /uninstall
```

Configure a conta do servico (aba "Log On" do servico no `services.msc`)
para um usuario com as permissoes descritas acima.

## Primeiro acesso

- Porta padrao: `8077` (ex.: `http://localhost:8077` ou
  `http://servidor:8077`, ajustavel em `ServerModule.dfm`/`Bindings`).
- Usuario padrao: `admin`
- Senha padrao: `admin`

**Troque a senha padrao antes de expor a aplicacao na rede.** As
credenciais ficam em `config/settings.json` (hash SHA-256 com salt, nao em
texto puro). Para trocar a senha, o jeito mais simples e apagar o arquivo
`config/settings.json` (a aplicacao recria com a senha padrao) e depois
gerar um novo hash — ou adicione uma tela de "trocar senha" chamando
`AppConfig.Settings.SetPassword('novaSenha')` + `AppConfig.Save`.

## Estrutura de pastas sugerida por site

```
D:\Deploys\MeuSite\Pacotes\        <- pacotes (.zip ou arquivo unico) chegam aqui
D:\Deploys\MeuSite\Backup\         <- copia de cada arquivo sobrescrito, antes de cada deploy
D:\Deploys\MeuSite\Processados\    <- historico dos pacotes ja aplicados
C:\inetpub\wwwroot\MeuSite\        <- pasta publicada pelo IIS (PhysicalPath do site/app)
```

## Arquivos de configuracao e log gerados em tempo de execucao

- `config/sites.json` -- lista de sites cadastrados.
- `config/settings.json` -- caminho do `appcmd.exe`, usuario e hash da senha.
- `log/deploy.log` -- historico de deploys (texto simples).
- `log/<nome_do_exe>/AAAA-MM-DD.log` -- log interno do UniGUI (requisicoes,
  erros do servidor web).

Nenhum desses arquivos precisa ser versionado; a aplicacao os cria
automaticamente na primeira execucao.

## Organizacao do codigo

| Unidade | Responsabilidade |
|---|---|
| `Deploy.Types.pas` | Modelo `TDeploySite` e enum de status de deploy |
| `Deploy.Config.pas` | Carrega/salva `sites.json` e `settings.json`, hash de senha |
| `Deploy.ProcessUtils.pas` | Executa comandos de console capturando saida/timeout |
| `Deploy.IISControl.pas` | Start/Stop/Recycle de App Pool via `appcmd.exe` |
| `Deploy.Engine.pas` | Orquestra um deploy: para pool, substitui arquivo(s) com backup por arquivo, reinicia pool |
| `Deploy.Watcher.pas` | Thread que varre as pastas de pacotes dos sites com monitoramento ativado |
| `Deploy.Log.pas` | Historico de deploys em memoria + arquivo |
| `ServerModule.pas` | Inicializacao unica da aplicacao (config, log, watcher) |
| `Login.pas` | Tela de login (usuario/senha do `settings.json`) |
| `Main.pas` | Dashboard: grade de sites, upload, acoes de pool, historico |
| `SiteEdit.pas` | Formulario modal de cadastro/edicao de site |

## Limitacoes conhecidas / proximos passos

- O Deploy Manager controla o IIS da **mesma maquina** onde ele roda (via
  `appcmd.exe` local). Para gerenciar IIS de servidores remotos seria
  necessario adaptar `Deploy.IISControl.pas` para usar PowerShell Remoting/
  WinRM ou Web Deploy (`msdeploy`) apontando para o host remoto.
  A pergunta original filtrou justamente por esta opcao de arquitetura
  (execucao local via `appcmd.exe`); um cenario multi-servidor requer essa
  extensao.
- Autenticacao e de um unico usuario administrador. Para multiplos usuarios
  ou integracao com Active Directory, adaptar `Deploy.Config.pas`.
- O upload de pacote tem limite de 500 MB (`FUpload.MaxAllowedSize` em
  `Main.pas`), ajustavel conforme necessidade.
