; Script do Inno Setup para DAW Project Manager

; Version is injected by CI via environment variable APP_VERSION.
; Fallback keeps local builds working.
#define APP_VERSION GetEnv('APP_VERSION')
#if APP_VERSION == ""
  #define APP_VERSION "0.0.0"
#endif

[Setup]
; --- Informações do Aplicativo ---
AppName=DAW Project Manager
AppVersion={#APP_VERSION}
AppPublisher=BandPass Records
AppPublisherURL=https://dpm.bandpassrecords.com
AppSupportURL=https://github.com/bandpassrecords/daw-project-manager/issues
AppUpdatesURL=https://github.com/bandpassrecords/daw-project-manager/releases
DefaultDirName={autopf}\DAW Project Manager
DefaultGroupName=DAW Project Manager
; Nome do arquivo de saída
OutputBaseFileName=DAW_Project_Manager_Installer_v{#SetupSetting("AppVersion")}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; DIRETIVA MOVIDA PARA [Setup] (Esta é a correção principal!)
SetupIconFile=app_icon.ico

; --- Seção de Arquivos (Corrigida da última interação) ---
[Files]
; Inclui todos os arquivos da pasta de release do Flutter em uma ÚNICA LINHA.
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; Cria atalhos
Name: "{group}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"
Name: "{autodesktop}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"

; [Run] e [Code] foram removidos pois não contêm comandos essenciais e podem causar erros de sintaxe se vazios ou mal formatados.