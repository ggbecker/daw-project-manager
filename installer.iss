; Script do Inno Setup para DAW Project Manager

[Setup]
; --- Informações do Aplicativo ---
AppName=DAW Project Manager
AppVersion=1.0.0
AppPublisher=DAW Project Manager Co.
AppPublisherURL=https://www.github.com/ggbecker/daw-project-manager
AppSupportURL=https://www.github.com/ggbecker/daw-project-manager
AppUpdatesURL=https://www.github.com/ggbecker/daw-project-manager
DefaultDirName={autopf}\DAW Project Manager
DefaultGroupName=DAW Project Manager
; Nome do arquivo de saída
OutputBaseFileName=DAW_Project_Manager_Installer_{#SetupSetting("AppVersion")}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; --- Seção de Arquivos (CORRIGIDA) ---
[Files]
; Inclui todos os arquivos da pasta de release do Flutter em uma ÚNICA LINHA.
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; Cria atalhos
Name: "{group}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"
Name: "{autodesktop}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"

[Run]
; (Comentários sobre VCRedist omitidos para brevidade, mas você pode mantê-los no seu arquivo)

[Code]
; Se o seu projeto tiver ícone, coloque-o na raiz do projeto e adicione a linha:
SetupIconFile=app_icon.ico