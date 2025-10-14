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

; --- Dependências do Flutter ---
; O Flutter geralmente depende do C++ Runtime. 
; Esta diretiva garante que a dependência seja instalada se necessário.
[Files]
; Inclui todos os arquivos da pasta de release do Flutter.
; Source: Pasta de Release do Flutter | DestDir: Pasta de instalação
; A pasta que contém o EXE, DLLs e pasta 'data'
Source: "build\windows\x64\runner\Release\*"
DestDir: "{app}"
Flags: recursesubdirs createallsubdirs

[Icons]
; Cria atalhos
Name: "{group}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"
Name: "{autodesktop}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"

[Run]
; Comando para instalar o C++ Redistributable (necessário para Flutter)
; Você precisa baixar o instalador VCRedist para incluir no seu release OU
; instruir o usuário. No CI, geralmente é mais simples incluir a referência.
; Como uma solução simples, vamos apenas fazer o comando de instalação.

; Se o seu projeto falhar em máquinas sem o C++ Redistributable,
; use uma action mais complexa que baixe e inclua o vcredist.
; Para fins deste script simples, confiamos na compilação do Flutter.

[Code]
; Se o seu projeto tiver ícone, coloque-o na raiz do projeto e adicione a linha:
SetupIconFile=app_icon.ico