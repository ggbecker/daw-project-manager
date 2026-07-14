// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gerenciador de Projetos DAW';

  @override
  String get projectDetails => 'Detalhes do Projeto';

  @override
  String get back => 'Voltar';

  @override
  String get save => 'Salvar';

  @override
  String get enable => 'Ativar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get customInterval => 'Personalizado';

  @override
  String get close => 'Fechar';

  @override
  String get launch => 'Abrir';

  @override
  String get view => 'Ver';

  @override
  String get openFolder => 'Abrir Pasta';

  @override
  String get openInDaw => 'Lançar no DAW';

  @override
  String get extract => 'Extrair';

  @override
  String get extracting => 'Extraindo…';

  @override
  String get extractingMetadata => 'Extraindo metadados...';

  @override
  String get deepScan => 'Varredura Profunda';

  @override
  String get rescan => 'Reescanear';

  @override
  String get refreshProject => 'Atualizar';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get projectName => 'Nome do Projeto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tom (ex: C#m, F maior)';

  @override
  String get notes => 'Notas';

  @override
  String get projectPhase => 'Fase do Projeto';

  @override
  String get failedToLoad => 'Falha ao carregar';

  @override
  String get fileMissing => 'Arquivo ausente.';

  @override
  String launchingProject(String projectName) {
    return 'Abrindo $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Falha ao abrir $projectName';
  }

  @override
  String get clearLibrary => 'Limpar Biblioteca';

  @override
  String get clearLibraryMessage =>
      'Isso removerá todos os projetos salvos e pastas de origem. Continuar?';

  @override
  String get clear => 'Limpar';

  @override
  String get roots => 'Pastas de Projetos';

  @override
  String get pathsSettingsDangerZoneTitle => 'Biblioteca';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Limpe todos os projetos e pastas de projetos do perfil atual.';

  @override
  String get projectFoldersSectionTitle => 'Pastas de projetos';

  @override
  String get projectFoldersSectionSubtitle =>
      'Pastas que serão escaneadas para encontrar projetos de DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Nenhuma pasta de projetos ainda';

  @override
  String get projectFoldersEmptySubtitle =>
      'Adicione pelo menos uma pasta para começar a escanear projetos.';

  @override
  String get notScannedYet => 'Ainda não escaneado';

  @override
  String lastScan(String date) {
    return 'Último scan: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Pastas excluídas';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Estas pastas serão ignoradas durante o scan, mesmo que estejam dentro de uma pasta de projetos.';

  @override
  String get addExcludedFolder => 'Adicionar excluída';

  @override
  String get selectExcludedFolder => 'Selecione uma pasta para excluir';

  @override
  String get excludedFoldersEmptyTitle => 'Nenhuma pasta excluída';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Opcional: adicione pastas que você nunca quer escanear.';

  @override
  String get removeExcludedFolderTitle => 'Remover pasta excluída?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Esta pasta não será mais excluída:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Esta pasta não será mais excluída.';

  @override
  String get desktopOnlyPathsSettings =>
      'Esta página está disponível apenas no app desktop.';

  @override
  String get removeProjectFolderTitle => 'Remover pasta de projetos?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Tem certeza de que deseja remover \"$path\"? Isso também removerá todos os projetos desta pasta que não estão em lançamentos.';
  }

  @override
  String get projects => 'Projetos';

  @override
  String get hidden => 'ocultos';

  @override
  String get profileManager => 'Gerenciador de Perfis';

  @override
  String get createNewProfile => 'Criar Novo Perfil';

  @override
  String get profileName => 'Nome do Perfil';

  @override
  String get create => 'Criar';

  @override
  String get profiles => 'Perfis';

  @override
  String get active => 'Ativo';

  @override
  String get switchProfile => 'Alternar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get addFolder => 'Adicionar Pasta';

  @override
  String get searchProjects => 'Pesquisar projetos...';

  @override
  String get searchReleases => 'Pesquisar lançamentos...';

  @override
  String get searchPlaylists => 'Pesquisar playlists...';

  @override
  String get noReleasesFound => 'Nenhum lançamento encontrado';

  @override
  String get noPlaylistsFound => 'Nenhuma playlist encontrada';

  @override
  String get tryDifferentSearch => 'Tente um termo de busca diferente';

  @override
  String get deepScanConfirm =>
      'A Varredura Profunda extrai metadados completos dos arquivos de projeto:\n• BPM (Batidas Por Minuto)\n• Tom Musical\n• Versão do DAW\nSuportado atualmente: Ableton Live, Cubase e Bitwig Studio.\n\nIsso é mais lento que uma varredura comum e pode levar um tempo. Continuar?';

  @override
  String get deepScanOnlyUnscanned => 'Escanear apenas projetos sem metadados';

  @override
  String get metadataExtractedSuccessfully => 'Metadados extraídos com sucesso';

  @override
  String failedToExtractMetadata(String error) {
    return 'Falha ao extrair metadados: $error';
  }

  @override
  String get saved => 'Salvo';

  @override
  String get failedToLaunchDaw => 'Falha ao abrir DAW';

  @override
  String get releaseDetails => 'Detalhes do Lançamento';

  @override
  String get releaseNotFound => 'Lançamento Não Encontrado';

  @override
  String get error => 'Erro';

  @override
  String get loading => 'Carregando...';

  @override
  String get deleteProfile => 'Excluir Perfil';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Tem certeza de que deseja excluir \"$profileName\"? Isso excluirá todos os projetos, pastas de projetos e lançamentos deste perfil.';
  }

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get changePhoto => 'Alterar Foto';

  @override
  String get remove => 'Remover';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Tem certeza de que deseja remover \"$trackName\" deste lançamento?';
  }

  @override
  String get saveName => 'Salvar Nome';

  @override
  String get profilePhotoUpdated => 'Foto do perfil atualizada.';

  @override
  String get profilePhotoRemoved => 'Foto do perfil removida.';

  @override
  String profileRenamed(String newName) {
    return 'Perfil renomeado para \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Perfil \"$name\" criado com sucesso';
  }

  @override
  String profileDeleted(String name) {
    return 'Perfil \"$name\" excluído';
  }

  @override
  String get pleaseEnterProfileName => 'Por favor, insira um nome de perfil';

  @override
  String failedToCreateProfile(String error) {
    return 'Falha ao criar perfil: $error';
  }

  @override
  String get noProfilesFound => 'Nenhum perfil encontrado. Crie um acima.';

  @override
  String get clearLibraryTooltip =>
      'Limpar Biblioteca (projetos e pastas de projetos)';

  @override
  String lastModified(String date) {
    return 'Última modificação: $date';
  }

  @override
  String get name => 'Nome';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Fase';

  @override
  String get filterByPhase => 'Filtrar por Fase';

  @override
  String get filters => 'Filtros';

  @override
  String get allPhases => 'Todas as Fases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Última Modificação';

  @override
  String get actions => 'Ações';

  @override
  String get hide => 'Ocultar';

  @override
  String get unhide => 'Mostrar';

  @override
  String get extractMetadata => 'Extrair Metadados';

  @override
  String get createRelease => 'Criar Lançamento';

  @override
  String get clearSelection => 'Limpar Seleção';

  @override
  String get selectAllProjects => 'Selecionar todos os projetos';

  @override
  String get switchingProfiles => 'Alternando perfis...';

  @override
  String get scanningProjects => 'Escaneando projetos...';

  @override
  String get search => 'Buscar';

  @override
  String get projectsTab => 'Projetos';

  @override
  String get releasesTab => 'Lançamentos';

  @override
  String get showHidden => 'Mostrar Ocultos';

  @override
  String get showAll => 'Mostrar Todos';

  @override
  String get showOnlyHidden => 'Mostrar Apenas Ocultos';

  @override
  String get deleteRootPath => 'Remover pasta de projetos';

  @override
  String deleteRootPathMessage(String path) {
    return 'Tem certeza de que deseja remover \"$path\"? Isso também removerá todos os projetos desta pasta que não estão em lançamentos.';
  }

  @override
  String rootsCount(int count) {
    return 'Pastas de Projetos: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projetos: $count';
  }

  @override
  String get hiddenOnly => '(apenas ocultos)';

  @override
  String hiddenCount(int count) {
    return '($count ocultos)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count projeto$plural oculto$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count projeto$plural mostrado$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Falha ao ocultar projetos: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Falha ao mostrar projetos: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Tem certeza de que deseja ocultar \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Lançamento \"$title\" criado com sucesso.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Falha ao criar lançamento: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Erro ao adicionar pasta: $error';
  }

  @override
  String get folderAlreadyAdded => 'Esta pasta já foi adicionada.';

  @override
  String get noProjectsFoundInRoots =>
      'Nenhum projeto encontrado nas pastas de projetos selecionadas.';

  @override
  String get selectProjectsFolder => 'Selecione uma pasta de projetos';

  @override
  String get enterReleaseTitle => 'Digite o Título do Lançamento';

  @override
  String get releaseTitle => 'Título do Lançamento';

  @override
  String get enterReleaseTitleHint => 'Digite o título do lançamento';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadados extraídos para $count projeto$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count falhou$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Falha ao escrever arquivo BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Falha ao escrever arquivo de tom: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Falha ao abrir: $error';
  }

  @override
  String get libraryCleared => 'Biblioteca limpa.';

  @override
  String scanType(String type) {
    return 'Varredura $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type concluída: $count projeto$plural adicionado$plural/atualizado$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count projeto$plural selecionado$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Abrindo pasta para $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Falha ao abrir pasta: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Sistema operacional não suportado para abrir pasta.';

  @override
  String get noProjectsAvailable =>
      'Nenhum projeto disponível. Por favor, adicione projetos primeiro.';

  @override
  String get createNewRelease => 'Criar Novo Lançamento';

  @override
  String get deleteRelease => 'Excluir Lançamento';

  @override
  String deleteReleaseMessage(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Lançamento \"$title\" excluído.';
  }

  @override
  String get selectTracks => 'Selecionar Faixas';

  @override
  String get continueButton => 'Continuar';

  @override
  String get noReleasesYet => 'Ainda não há lançamentos';

  @override
  String get createFirstRelease =>
      'Crie seu primeiro lançamento selecionando faixas dos seus projetos';

  @override
  String releasesCount(int count) {
    return 'Lançamentos ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Erro ao carregar lançamentos: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Faixas ($count)';
  }

  @override
  String get addTracks => 'Adicionar Faixas';

  @override
  String get allProjectsAlreadyInRelease =>
      'Todos os projetos já estão neste lançamento.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Adicionada$plural $count faixa$plural ao lançamento.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Arquivos do Lançamento ($count)';
  }

  @override
  String get addFiles => 'Adicionar Arquivos';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Adicionado$plural $count arquivo$plural ao lançamento.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Falha ao adicionar arquivos: $error';
  }

  @override
  String get noFilesToDownload => 'Nenhum arquivo para baixar.';

  @override
  String zipFileSaved(String path) {
    return 'Arquivo ZIP salvo em: $path';
  }

  @override
  String get creatingZipFile => 'Criando arquivo ZIP...';

  @override
  String failedToCreateZip(String error) {
    return 'Falha ao criar ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Arquivo selecionado não existe.';

  @override
  String get imageSavedSuccessfully => 'Imagem salva com sucesso!';

  @override
  String failedToSaveImage(String error) {
    return 'Falha ao salvar imagem: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Erro ao carregar lançamento: $error';
  }

  @override
  String get errorLoadingProjects => 'Erro ao carregar projetos';

  @override
  String get releaseSaved => 'Lançamento salvo.';

  @override
  String get releaseDate => 'Data do Lançamento';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Falha ao salvar data do lançamento: $error';
  }

  @override
  String get releaseDateSaved => 'Data do lançamento salva.';

  @override
  String get releaseDateCleared => 'Data do lançamento limpa.';

  @override
  String get saveReleaseFilesZip => 'Salvar arquivos ZIP do lançamento';

  @override
  String get failedToOpenFile => 'Falha ao abrir arquivo';

  @override
  String failedToPlayAudio(String error) {
    return 'Falha ao reproduzir áudio: $error';
  }

  @override
  String get renameFile => 'Renomear Arquivo';

  @override
  String get selectTracksToAdd => 'Selecionar Faixas para Adicionar';

  @override
  String get fileNameUpdated => 'Nome do arquivo atualizado.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Erro ao atualizar nome do arquivo: $error';
  }

  @override
  String get deleteFile => 'Excluir Arquivo';

  @override
  String deleteFileMessage(String fileName) {
    return 'Tem certeza de que deseja excluir \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Arquivo \"$fileName\" excluído.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Falha ao excluir arquivo: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Não foi possível abrir a pasta: $error';
  }

  @override
  String get artwork => 'Arte';

  @override
  String get title => 'Título';

  @override
  String get tracks => 'Faixas';

  @override
  String get description => 'Descrição';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Selecionar faixas para incluir no lançamento ($count selecionada$plural)';
  }

  @override
  String get searchTracks => 'Pesquisar faixas';

  @override
  String get searchTracksHint => 'Pesquisar por nome ou tipo de DAW';

  @override
  String get noTracksFound => 'Nenhuma faixa encontrada';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get fileNotFound => 'Arquivo não encontrado';

  @override
  String get fileName => 'Nome do Arquivo';

  @override
  String get editTodo => 'Editar Tarefa';

  @override
  String get todoText => 'Texto da tarefa';

  @override
  String get enterTodoText => 'Digite o texto da tarefa';

  @override
  String get addNewTodo => 'Adicionar nova tarefa';

  @override
  String get enterTodoItem => 'Digite o item da tarefa';

  @override
  String get todoList => 'Lista de Tarefas';

  @override
  String get todoTemplates => 'Templates de TODO';

  @override
  String get createTemplate => 'Criar Template';

  @override
  String get editTemplate => 'Editar Template';

  @override
  String get deleteTemplate => 'Excluir Template';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Tem certeza que deseja excluir o template \"$name\"?';
  }

  @override
  String get templateName => 'Nome do Template';

  @override
  String get templateNameHint => 'ex. Checklist de Mixagem';

  @override
  String get templateItems => 'Itens do Template';

  @override
  String get templateItemsHint => 'Um item por linha';

  @override
  String get templateNameAndItemsRequired =>
      'Nome e itens do template são obrigatórios';

  @override
  String get templateItemsRequired => 'Pelo menos um item é obrigatório';

  @override
  String get templateCreated => 'Template criado';

  @override
  String get templateUpdated => 'Template atualizado';

  @override
  String get templateDeleted => 'Template excluído';

  @override
  String get noTemplatesYet => 'Nenhum template ainda';

  @override
  String get createFirstTemplate => 'Crie seu primeiro template de TODO';

  @override
  String templateItemCount(int count) {
    return '$count item(ns)';
  }

  @override
  String get selectTemplate => 'Selecionar Template';

  @override
  String get importFromTemplate => 'Importar de Template';

  @override
  String get manageTemplates => 'Gerenciar Templates';

  @override
  String get noTemplatesAvailable =>
      'Nenhum template disponível. Crie um primeiro.';

  @override
  String templateImported(String name, int count) {
    return 'Template \"$name\" importado ($count itens)';
  }

  @override
  String get errorLoadingTemplates => 'Erro ao carregar templates';

  @override
  String get importTodos => 'Importar Tarefas de Arquivo';

  @override
  String get noTodosInFile => 'Nenhuma tarefa encontrada no arquivo';

  @override
  String todosImported(int count) {
    return '$count tarefa(s) importada(s) com sucesso';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Erro ao importar tarefas: $error';
  }

  @override
  String get addToRelease => 'Adicionar ao Lançamento';

  @override
  String get createNew => 'Criar Novo';

  @override
  String get addToExisting => 'Adicionar ao Existente';

  @override
  String get createAndAdd => 'Criar e Adicionar';

  @override
  String get selectRelease => 'Selecione um lançamento';

  @override
  String get noExistingReleasesFound =>
      'Nenhum lançamento existente encontrado.';

  @override
  String get addToSelectedRelease => 'Adicionar ao Lançamento Selecionado';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Falha ao salvar foto do perfil: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Falha ao remover foto do perfil: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Falha ao renomear perfil: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Falha ao excluir perfil: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get projectPhaseIdea => 'Ideia';

  @override
  String get projectPhaseArranging => 'Arranjo';

  @override
  String get projectPhaseMixing => 'Mixagem';

  @override
  String get projectPhaseMastering => 'Masterização';

  @override
  String get projectPhaseFinished => 'Finalizado';

  @override
  String get changeStatus => 'Alterar Fase';

  @override
  String get selectNewStatus => 'Selecione a nova fase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Fase alterada para \"$status\" em $count projeto$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Fase alterada para \"$status\" em $successCount projeto$successPlural, $failCount falhou$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Falha ao alterar fase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Editar nome do perfil';

  @override
  String get tooltipAddTodo => 'Adicionar tarefa';

  @override
  String get tooltipClearDate => 'Limpar data';

  @override
  String get tooltipPickDate => 'Escolher data';

  @override
  String get tooltipViewDetails => 'Ver Detalhes';

  @override
  String get tooltipLaunchInDaw => 'Abrir no DAW';

  @override
  String get tooltipRemoveFromRelease => 'Remover do Lançamento';

  @override
  String get profile => 'Perfil';

  @override
  String get noDateSet => 'Nenhuma data definida';

  @override
  String get imageNotFound => 'Imagem não encontrada';

  @override
  String get clickToBrowseArtwork => 'Clique para procurar arte';

  @override
  String get dropImageHere => 'Drop image here';

  @override
  String get removeArtwork => 'Remove Artwork';

  @override
  String get removeArtworkConfirm =>
      'Remove this artwork? The image file will be deleted.';

  @override
  String get noFilesAddedYet =>
      'Nenhum arquivo adicionado ainda.\nClique em \"Adicionar Arquivos\" para fazer upload dos arquivos do lançamento.';

  @override
  String get noTodosYet => 'Nenhuma tarefa ainda. Adicione uma acima.';

  @override
  String get done => 'Concluído';

  @override
  String get backupAndRestore => 'Backup e Restauração';

  @override
  String get exportBackup => 'Exportar Backup';

  @override
  String get importBackup => 'Importar Backup';

  @override
  String get backupExportedSuccessfully => 'Backup exportado com sucesso';

  @override
  String failedToExportBackup(String error) {
    return 'Falha ao exportar backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importado com sucesso: $projectsCount projetos, $rootsCount pastas de projetos, $releasesCount lançamentos';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Falha ao importar backup: $error';
  }

  @override
  String get importBackupMessage => 'Escolha como importar o backup:';

  @override
  String get mergeWithCurrentProfile => 'Mesclar com o perfil ativo atual';

  @override
  String get replaceCurrentProfile =>
      'Substituir completamente o perfil atual (AVISO: Isso excluirá todos os dados do perfil atual)';

  @override
  String get createNewProfileForImport =>
      'Criar um novo perfil para estes dados';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importado para o novo perfil \"$profileName\": $projectsCount projetos, $rootsCount pastas de projetos, $releasesCount lançamentos';
  }

  @override
  String get noProfileSelected => 'Nenhum perfil selecionado';

  @override
  String get exportBackupDialogTitle => 'Exportar Backup';

  @override
  String get importBackupDialogTitle => 'Importar Backup';

  @override
  String get invalidBackupFileFormat =>
      'Formato de arquivo de backup inválido: versão ausente';

  @override
  String get profileNameRequiredForNewProfile =>
      'O nome do perfil é obrigatório ao criar um novo perfil';

  @override
  String get currentProfileRequired =>
      'O perfil atual é obrigatório para o modo mesclar ou substituir';

  @override
  String get previewSong => 'Música de Prévia';

  @override
  String get noPreviewSongTitle => 'Sem música de visualização';

  @override
  String get noPreviewSongMessage =>
      'Este projeto não tem uma música de visualização definida. Selecione um arquivo de áudio para carregá-lo e reproduzi-lo.';

  @override
  String get noPreviewSongDragHint =>
      'Você também pode arrastar e soltar um arquivo de áudio diretamente na linha do projeto na tabela.';

  @override
  String get previewSongRemoved => 'Música de prévia removida';

  @override
  String get previewSongAdded => 'Música de prévia adicionada';

  @override
  String get previewSongFileNotFound =>
      'Arquivo de música de prévia não encontrado';

  @override
  String get previewSongFileNotFoundMessage =>
      'O arquivo da música de visualização não foi encontrado no disco. Deseja selecionar um novo arquivo ou remover a entrada?';

  @override
  String get selectNewFile => 'Selecionar novo arquivo';

  @override
  String failedToPlayPreview(String error) {
    return 'Falha ao reproduzir prévia: $error';
  }

  @override
  String get removePreviewSong => 'Remover música de prévia';

  @override
  String get removePreviewSongConfirm =>
      'Tem certeza de que deseja remover a música de prévia? Esta ação não pode ser desfeita.';

  @override
  String get noPreviewSongSelected => 'Nenhuma música de prévia selecionada';

  @override
  String get changePreviewSong => 'Alterar Música de Prévia';

  @override
  String get selectPreviewSong => 'Selecionar Música de Prévia';

  @override
  String get dropAudioFileHere => 'Solte o arquivo de áudio aqui';

  @override
  String projectAge(String age) {
    return 'Idade do projeto: $age';
  }

  @override
  String createdDate(String date) {
    return 'criado $date';
  }

  @override
  String completedIn(String duration) {
    return 'Concluído em: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'finalizado $date';
  }

  @override
  String get dateToday => 'hoje';

  @override
  String get dateYesterday => 'ontem';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count semanas',
      one: 'há 1 semana',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    return 'há $count ano$plural';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years ano$yearPlural, $months meses';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years ano$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months meses, $days dia$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months meses';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days dia$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours hora$plural';
  }

  @override
  String get ageJustNow => 'Agora mesmo';

  @override
  String get ageLessThanHour => 'Menos de uma hora';

  @override
  String get viewProfile => 'Ver Perfil';

  @override
  String get googleDriveSync => 'Sincronização Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sincronize seus dados com o Google Drive para fazer backup e restaurar entre dispositivos.';

  @override
  String get manageGoogleDriveSync => 'Gerenciar Sincronização Google Drive';

  @override
  String get signInToGoogleDrive => 'Entrar no Google Drive';

  @override
  String get syncNow => 'Sincronizar Agora';

  @override
  String get uploadBackup => 'Enviar Backup';

  @override
  String get downloadBackup => 'Baixar Backup';

  @override
  String get newerBackupAvailable => 'Novo backup disponível na nuvem';

  @override
  String get restoreProjectFromDrive => 'Restaurar do Drive';

  @override
  String get restoringProjectFromDrive => 'Restaurando do Drive...';

  @override
  String get projectRestoredFromDrive => 'Projeto restaurado do Drive';

  @override
  String get projectNotFoundInBackup =>
      'Este projeto não foi encontrado no backup do Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Por favor, faça login no Google Drive primeiro (abra as configurações do Drive Sync)';

  @override
  String get signOut => 'Sair';

  @override
  String get downloadPreviewSongs => 'Baixar músicas de prévia';

  @override
  String get downloadPreviewSongsExplanation =>
      'Se desmarcado, as músicas de prévia serão ignoradas (economiza tempo e armazenamento). Você pode baixá-las depois se necessário.';

  @override
  String get replaceLocalData => 'Substituir Dados Locais';

  @override
  String get downloadBackupConfirmation =>
      'Isso substituirá seus dados locais pelo backup do Google Drive.\n\nTem certeza de que deseja continuar?';

  @override
  String get enterAuthorizationCode => 'Inserir Código de Autorização';

  @override
  String get authorizationCode => 'Código de Autorização';

  @override
  String get pasteCodeFromBrowser => 'Cole o código do navegador';

  @override
  String get sessionActive => 'Sessão ativa';

  @override
  String get signedIn => 'Conectado';

  @override
  String get creatingInitialBackup => 'Criando backup inicial...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Conectado e backup criado com sucesso no Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Conectado e backup criado com sucesso no Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Conectado com sucesso ao Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Conectado com sucesso ao Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Entrada cancelada ou falhou. Verifique o console para detalhes.';

  @override
  String get failedToLaunchBrowser => 'Falha ao abrir o navegador';

  @override
  String get signInCancelled => 'Entrada cancelada';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Falha ao trocar código de autorização';

  @override
  String errorSigningIn(String error) {
    return 'Erro ao entrar: $error';
  }

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String get googleSignInError => 'Erro de Entrada do Google';

  @override
  String get developerConsoleNotSetUp =>
      'O console do desenvolvedor não está configurado corretamente. Verifique sua configuração OAuth no Google Cloud Console.';

  @override
  String get platformError => 'Erro de Plataforma';

  @override
  String get signedOutFromGoogleDrive => 'Desconectado do Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Erro ao sair: $error';
  }

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get errorNoProfileSelected => 'Erro: Nenhum perfil selecionado';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sincronização concluída! Projetos: +$projectsAdded ~$projectsUpdated, Lançamentos: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Erro ao sincronizar: $error';
  }

  @override
  String get uploadingBackup => 'Enviando backup...';

  @override
  String get backupUploadedSuccessfully => 'Backup enviado com sucesso!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup enviado com sucesso para o Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Erro ao enviar backup: $error';
  }

  @override
  String get downloadingBackup => 'Baixando backup...';

  @override
  String get checkingForBackup => 'Verificando backup...';

  @override
  String get backupUpToDate => 'Backup está atualizado';

  @override
  String errorCheckingBackup(String error) {
    return 'Erro ao verificar backup: $error';
  }

  @override
  String get download => 'Baixar';

  @override
  String get remoteBackupIsNewer =>
      'O backup remoto é mais recente que os dados locais. O upload irá sobrescrevê-lo.';

  @override
  String get confirmUpload => 'Confirmar Upload';

  @override
  String get noBackupFileFound =>
      'Nenhum arquivo de backup encontrado no Google Drive. Crie um backup primeiro sincronizando seus dados.';

  @override
  String get noBackupFileFoundStatus =>
      'Nenhum arquivo de backup encontrado. Crie um backup primeiro.';

  @override
  String get downloadCancelled => 'Download cancelado';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup baixado! Projetos: +$projectsAdded ~$projectsUpdated, Lançamentos: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  ) {
    return 'Backup baixado!\n\nProjetos:\n  • $projectsAdded adicionados\n  • $projectsUpdated atualizados\n\nLançamentos:\n  • $releasesAdded adicionados\n  • $releasesUpdated atualizados\n\nPreview Songs:\n  • $previewSongsDownloaded baixadas\n  • $previewSongsUpdated atualizadas';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Erro ao baixar backup: $error';
  }

  @override
  String signedInAs(String email) {
    return 'Conectado como: $email';
  }

  @override
  String lastSync(String date) {
    return 'Última sincronização: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Backup remoto: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Último envio: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Último download: $date';
  }

  @override
  String get checkForBackup => 'Verificar Backup';

  @override
  String get notificationSettings => 'Configurações de Notificação';

  @override
  String get notificationsOnlyOnAndroid =>
      'Notificações de prazo estão disponíveis apenas em dispositivos Android.';

  @override
  String get notificationPermissionRequired =>
      'Permissão de Notificação Necessária';

  @override
  String get notificationPermissionDescription =>
      'Por favor, habilite notificações para receber lembretes de prazos.';

  @override
  String get notificationPermissionDenied =>
      'Permissão de notificação negada. Por favor, habilite nas configurações.';

  @override
  String get notificationSettingsSaved =>
      'Configurações de notificação salvas com sucesso';

  @override
  String get errorSavingSettings => 'Erro ao salvar configurações';

  @override
  String get enableDeadlineNotifications => 'Habilitar Notificações de Prazo';

  @override
  String get receiveRemindersForDeadlines =>
      'Receber lembretes para prazos de projetos';

  @override
  String get notificationTime => 'Horário de Notificação';

  @override
  String get timeToReceiveNotifications =>
      'Horário do dia para receber notificações';

  @override
  String get reminderDays => 'Dias de Lembrete';

  @override
  String get selectDaysBeforeDeadline =>
      'Selecione quantos dias antes do prazo você deseja ser notificado';

  @override
  String get notifyOnDeadlineDay => 'Notificar no Dia do Prazo';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Também receber uma notificação no próprio dia do prazo';

  @override
  String get howItWorks => 'Como Funciona';

  @override
  String get deadlineNotificationsHelp =>
      'Você receberá notificações no horário especificado nos dias selecionados antes de cada prazo de projeto. Toque em uma notificação para abrir os detalhes do projeto.';

  @override
  String get oneDay => '1 dia';

  @override
  String xDays(int count) {
    return '$count dias';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get support => 'Apoiar';

  @override
  String get shareDiagnosticLog => 'Compartilhar Log de Diagnóstico';

  @override
  String get shareDiagnosticLogEmpty => 'Ainda não há log de diagnóstico';

  @override
  String get supportTheProject => 'Apoie o projeto';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Não foi possível abrir o navegador. Por favor, visite: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Erro ao abrir o navegador: $error';
  }

  @override
  String get generateTestingDatabase => 'Gerar Base de Dados de Teste';

  @override
  String get generateTestingDatabaseMessage =>
      'Isso irá popular a base de dados com projetos e releases de exemplo para testes. Continuar?';

  @override
  String get testingDatabaseGenerated =>
      'Base de dados de teste gerada com sucesso!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Falha ao gerar base de dados de teste: $error';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get playlistsDesktopOnly =>
      'Playlists estão disponíveis apenas no Android.';

  @override
  String get noPlaylistsYet => 'Ainda não há playlists';

  @override
  String get createFirstPlaylist =>
      'Toque no botão + para criar sua primeira playlist';

  @override
  String playlistSongCount(int count) {
    return '$count músicas';
  }

  @override
  String get createPlaylist => 'Criar Playlist';

  @override
  String get playlistName => 'Nome da Playlist';

  @override
  String get playlistNameHint => 'Minha Playlist';

  @override
  String get playlistNameRequired => 'Nome da playlist é obrigatório';

  @override
  String get editPlaylist => 'Editar Playlist';

  @override
  String get stopPlaybackBeforeEditing =>
      'Por favor, pare a reprodução antes de editar a playlist';

  @override
  String get selectPreviewSongs => 'Selecionar Prévias';

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Playlist excluída';

  @override
  String get errorDeletingPlaylist => 'Erro ao excluir playlist';

  @override
  String get playlistUpdated => 'Playlist atualizada';

  @override
  String get changeSong => 'Trocar Música';

  @override
  String get changeSongConfirm =>
      'Uma música está tocando. Deseja trocar para esta música?';

  @override
  String get changeSongButton => 'Trocar';

  @override
  String playlistProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Nenhuma prévia disponível nesta playlist';

  @override
  String get tapEditToAddSongs =>
      'Toque em editar para adicionar músicas a esta playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Nenhum projeto com músicas de preview disponíveis para adicionar';

  @override
  String get noProjectsInDatabase =>
      'Nenhum projeto encontrado no banco de dados. Por favor, sincronize seus projetos primeiro.';

  @override
  String get firstTimeSyncTitle => 'Parece que é sua primeira vez aqui!';

  @override
  String get firstTimeSyncMessage =>
      'Vamos sincronizar seus dados do Google Drive para começar';

  @override
  String get syncWithGoogleDrive => 'Sincronizar com Google Drive';

  @override
  String get errorLoadingPlaylists => 'Erro ao carregar playlists';

  @override
  String get playlistItems => 'Itens da Playlist';

  @override
  String get addSongs => 'Adicionar Músicas';

  @override
  String get addAudioFiles => 'Adicionar Arquivos de Áudio';

  @override
  String get selectAudioFiles => 'Selecionar Arquivos de Áudio';

  @override
  String get selectFromProjects => 'Selecionar dos Projetos';

  @override
  String get add => 'Adicionar';

  @override
  String get fromProject => 'Do Projeto';

  @override
  String get projectDeadline => 'Prazo do Projeto';

  @override
  String get noDeadlineSet => 'Sem prazo definido';

  @override
  String get camelotCode => 'Código Camelot';

  @override
  String get deadline => 'Prazo';

  @override
  String get dueToday => 'Vence hoje';

  @override
  String daysLate(int days) {
    return '${days}d atrasado';
  }

  @override
  String daysLeft(int days) {
    return '${days}d restantes';
  }

  @override
  String get hideFinished => 'Ocultar Finalizados';

  @override
  String get showOnlyDeadlines => 'Mostrar prazo';

  @override
  String get filterByDeadline => 'Filtrar por Prazo';

  @override
  String get allDeadlines => 'Todos os Prazos';

  @override
  String get hasDeadline => 'Com Prazo';

  @override
  String get overdue => 'Atrasado';

  @override
  String get dueSoon => 'Vence em Breve (7d)';

  @override
  String get today => 'Hoje';

  @override
  String get noPreviewSong => 'Sem prévia';

  @override
  String get playPreview => 'Reproduzir Prévia';

  @override
  String get uploadCancelled => 'Upload cancelado';

  @override
  String get backupUploadCancelledByUser =>
      'Upload de backup cancelado pelo usuário';

  @override
  String get collectingData => 'Coletando dados...';

  @override
  String get uploadingPreviewSongs => 'Enviando músicas de prévia...';

  @override
  String get uploadingProfilePhotos => 'Enviando fotos de perfil...';

  @override
  String get uploadingReleaseArtwork => 'Enviando artwork de lançamentos...';

  @override
  String get uploadingDatabase => 'Enviando banco de dados...';

  @override
  String get completed => 'Concluído!';

  @override
  String get cancelling => 'Cancelando...';

  @override
  String get uploadingBackupTitle => 'Enviando Backup';

  @override
  String get cancellingUpload => 'Cancelando upload...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Por favor aguarde enquanto paramos o upload...';

  @override
  String get downloadingDatabase => 'Baixando banco de dados...';

  @override
  String get downloadingPreviewSongs => 'Baixando músicas de prévia...';

  @override
  String get downloadingProfilePhotos => 'Baixando fotos de perfil...';

  @override
  String get downloadingReleaseArtwork => 'Baixando artwork de lançamentos...';

  @override
  String get mergingData => 'Mesclando dados...';

  @override
  String get downloadingBackupTitle => 'Baixando Backup';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Arquivo fonte não encontrado nesta máquina';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Arquivo fonte não encontrado nesta máquina — modo somente metadados. Você ainda pode editar e exportar metadados.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Música de prévia não disponível. Por favor, baixe o backup primeiro.';

  @override
  String get sharePreviewSong => 'Compartilhar música de prévia';

  @override
  String get shareAsZip => 'Compartilhar como ZIP';

  @override
  String get share => 'Compartilhar';

  @override
  String get backupInProgressTitle => 'Backup em Andamento';

  @override
  String get backupInProgressMessage =>
      'Um backup está sendo enviado ao Google Drive agora. Sair pode deixá-lo incompleto — esperar terminar, ou sair mesmo assim?';

  @override
  String get waitForBackup => 'Esperar';

  @override
  String get quitAnyway => 'Sair Mesmo Assim';

  @override
  String get finishingBackup => 'Finalizando backup…';

  @override
  String get dragToShare => 'Arraste para Compartilhar';

  @override
  String get dragToShareTooltip =>
      'Arraste isso para a janela de outro app (ex: WhatsApp) pra compartilhar o arquivo direto — útil quando o botão Compartilhar não abre um menu de compartilhamento.';

  @override
  String get mp3ConversionFailed =>
      'Não foi possível converter para MP3 por compatibilidade (ffmpeg não encontrado) — compartilhando o arquivo original, que alguns apps como o WhatsApp podem rejeitar.';

  @override
  String get shareZip => 'Compartilhar ZIP';

  @override
  String get saveCopy => 'Baixar cópia';

  @override
  String savedCopyTo(String path) {
    return 'Guardado em $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Falha ao compartilhar música de prévia: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Falha ao compartilhar música de prévia como ZIP: $error';
  }

  @override
  String get biographySaved => 'Biografia salva';

  @override
  String failedToSaveBiography(String error) {
    return 'Falha ao salvar biografia: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Arquivo salvo em $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Falha ao baixar arquivo: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Todos os arquivos salvos em $filename';
  }

  @override
  String get artworkAdded => 'Arte adicionada';

  @override
  String failedToAddArtwork(String error) {
    return 'Falha ao adicionar arte: $error';
  }

  @override
  String get artworkRemoved => 'Arte removida';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Falha ao remover arte: $error';
  }

  @override
  String get pressKitFileAdded => 'Arquivo do press kit adicionado';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Falha ao adicionar arquivo do press kit: $error';
  }

  @override
  String get pressKitFileRemoved => 'Arquivo do press kit removido';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Falha ao remover arquivo do press kit: $error';
  }

  @override
  String get selectFilesToDownload => 'Selecionar Arquivos para Baixar';

  @override
  String get biography => 'Biografia';

  @override
  String get biographyWillBeSaved => 'Será salvo como biography.txt';

  @override
  String get artworkFiles => 'Arquivos de Arte';

  @override
  String get pressKitFiles => 'Arquivos do Press Kit';

  @override
  String get additionalAssets => 'Ativos Adicionais';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Baixar $count arquivo$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count arquivo$plural salvo em $filename';
  }

  @override
  String get addAsset => 'Adicionar Ativo';

  @override
  String get assetNameLabel => 'Nome do Ativo';

  @override
  String get assetNameHint => 'ex.: Logo, Banner, Foto';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName adicionado com sucesso';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Falha ao adicionar ativo: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName removido';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Falha ao remover ativo: $error';
  }

  @override
  String get profileNotFound => 'Perfil não encontrado';

  @override
  String get selectFiles => 'Selecionar Arquivos';

  @override
  String get downloadAll => 'Baixar Tudo';

  @override
  String get saveBiographyTooltip => 'Salvar Biografia';

  @override
  String get enterBiographyHint => 'Digite a biografia do perfil...';

  @override
  String get addArtwork => 'Adicionar Arte';

  @override
  String get addFile => 'Adicionar Arquivo';

  @override
  String get openFile => 'Abrir Arquivo';

  @override
  String get menuView => 'Visualizar';

  @override
  String get menuAbout => 'Sobre o DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentação';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get menuWarnBeforeQuit => 'Avisar Antes de Sair (⌘+Q)';

  @override
  String get menuQuit => 'Sair do DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Sair do DAW Project Manager?';

  @override
  String get quitConfirmMessage => 'Tem certeza de que deseja sair?';

  @override
  String get quit => 'Sair';

  @override
  String get trayShowWindow => 'Mostrar DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Último backup: $when';
  }

  @override
  String get trayNeverBackedUp => 'Nenhum backup feito ainda';

  @override
  String get trayBackupNow => 'Fazer Backup Agora';

  @override
  String get trayPauseSession => 'Pausar Sessão';

  @override
  String get trayResumeSession => 'Retomar Sessão';

  @override
  String get closeToTray => 'Fechar para a bandeja';

  @override
  String get closeToTrayDescription =>
      'Continuar rodando em segundo plano (ícone na bandeja) ao fechar a janela, para o backup automático e as notificações continuarem funcionando';

  @override
  String get menuWindow => 'Janela';

  @override
  String get donate => 'Doar';

  @override
  String get website => 'Site';

  @override
  String get switchToClassicDark => 'Mudar para Classic Dark';

  @override
  String get switchToNeonDark => 'Mudar para Neon Dark';

  @override
  String get switchToClassicTheme => 'Mudar para Tema Classic';

  @override
  String get switchToNeonTheme => 'Mudar para Tema Neon';

  @override
  String get switchToStudioLight => 'Switch to Studio Light';

  @override
  String get menuTheme => 'Tema';

  @override
  String get appDescription =>
      'Um gerenciador de projetos para produtores musicais e designers de som.';

  @override
  String get neonDarkThemeName => 'Neon Escuro';

  @override
  String get classicDarkThemeName => 'Clássico Escuro';

  @override
  String get studioLightThemeName => 'Studio Light';

  @override
  String get statisticsTab => 'Estatísticas';

  @override
  String get statsTotalProjects => 'Total de Projetos';

  @override
  String get statsInProgress => 'Em andamento';

  @override
  String get statsFinished => 'Concluídos';

  @override
  String get statsAvgCompletion => 'Conclusão média';

  @override
  String get statsPhaseDistribution => 'Projetos por Fase';

  @override
  String get statsAvgTimePerPhase => 'Dias médios por Fase';

  @override
  String get statsProductivity => 'Produtividade';

  @override
  String get statsCreatedSeries => 'Criados';

  @override
  String get statsProjectHealth => 'Idade e Saúde dos Projetos';

  @override
  String get statsCatalogInsights => 'Análise do Catálogo';

  @override
  String get statsBpmDistribution => 'Distribuição de BPM';

  @override
  String get statsTopKeys => 'Tonalidades mais usadas';

  @override
  String get statsDawTypes => 'Tipos de DAW';

  @override
  String get statsProjectActivity => 'Atividade dos Projetos';

  @override
  String get statsNoData => 'Sem dados ainda';

  @override
  String get statsNoPhaseData =>
      'Os dados de fases aparecerão após os projetos mudarem de fase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Última atividade: há $days dias';
  }

  @override
  String get statsLastActivityToday => 'Ativo hoje';

  @override
  String get statsNoEvents => 'Nenhum evento registrado ainda';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Fase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Atualizado: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Concluído: $text';
  }

  @override
  String get statsEventFileModified => 'Arquivo modificado no disco';

  @override
  String get statsClearHistory => 'Limpar histórico';

  @override
  String get statsClearHistoryConfirm =>
      'Limpar todos os eventos registrados para este projeto?';

  @override
  String get statsSearchProjects => 'Pesquisar projetos…';

  @override
  String statsEventCount(int count) {
    return '$count eventos';
  }

  @override
  String get statsViewHistory => 'Estatísticas do Projeto';

  @override
  String get statsPhaseHistory => 'Histórico de Fases';

  @override
  String get statsEventBreakdown => 'Resumo de Eventos';

  @override
  String statsDaysSoFar(int days) {
    return '${days}d até agora';
  }

  @override
  String get statsNoProjectsFound => 'Nenhum projeto encontrado';

  @override
  String statsNotTouchedDays(int days) {
    return 'Sem alterações há $days dias';
  }

  @override
  String get sortByLastModified => 'Última modificação';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByPhase => 'Fase';

  @override
  String get sortByCreatedAt => 'Data de criação';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Alternar reprodução mono';

  @override
  String get monoRequiresWav => 'A mixagem mono requer um ficheiro WAV';

  @override
  String get monoUnsupportedFormat =>
      'Não foi possível criar a mistura mono — formato não suportado';

  @override
  String monoSwitchFailed(String error) {
    return 'Falha na troca para mono: $error';
  }

  @override
  String get analyzeLabel => 'Analisar';

  @override
  String get reAnalyzeLabel => 'Re-analisar';

  @override
  String get analysisRequiresWav => 'A análise requer um ficheiro WAV';

  @override
  String get noResultsForFilter => 'Nenhum resultado para o filtro atual';

  @override
  String get noResultsForFilterHint =>
      'Tente ajustar a pesquisa ou os filtros.';

  @override
  String get noProjectsFound => 'Nenhum projeto encontrado';

  @override
  String get noProjectsFoundHint =>
      'Adicione uma pasta raiz nas configurações para começar.';

  @override
  String get queueTab => 'Tarefas';

  @override
  String get queueSearchHint => 'Buscar tarefas...';

  @override
  String get queueNoPendingTasks => 'Tudo em dia!';

  @override
  String get queueNoPendingTasksHint =>
      'Sem tarefas pendentes nos seus projetos.';

  @override
  String get queueNoMatchingTasks => 'Nenhuma tarefa encontrada';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks tarefas pendentes em $projects projetos';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager v$version';
  }

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get renameProjectFileTitle => 'Renomear arquivo de projeto';

  @override
  String get renameFileButtonLabel => 'Renomear arquivo';

  @override
  String get newFileNameLabel => 'Novo nome do arquivo (sem extensão)';

  @override
  String renameAlreadyExists(String name) {
    return 'Um arquivo chamado \"$name\" já existe.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renomeado para \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Falha ao renomear: $error';
  }

  @override
  String get nameCannotBeEmpty => 'O nome não pode estar vazio';

  @override
  String get nameInvalidCharacters => 'O nome não pode conter / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'Também renomear a pasta que o contém';

  @override
  String get renameButton => 'Renomear';

  @override
  String get previewMixdownFolderTitle => 'Pasta de mixagem de visualização';

  @override
  String get previewMixdownFolderSubtitle =>
      'Nome da subpasta dentro de cada pasta de projeto a verificar primeiro ao detectar automaticamente músicas de visualização. Deixe vazio para usar os padrões do DAW.';

  @override
  String get previewMixdownFolderHint => 'ex. Mixdowns';

  @override
  String dawInfoLabel(String daw) {
    return 'DAW: $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Tom: $key';
  }

  @override
  String get audioFileNotFound => 'Arquivo de áudio não encontrado';

  @override
  String errorPlayingAudio(String error) {
    return 'Erro ao reproduzir áudio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Testar notificações para verificar fuso horário e agendamento:';

  @override
  String get notificationSendNow => 'Enviar agora';

  @override
  String get notificationSchedule30s => 'Agendar +30s';

  @override
  String get notificationShowDebugInfo => 'Mostrar informações de depuração';

  @override
  String get notificationRescheduleAll => 'Reagendar tudo';

  @override
  String get notificationTestSent => '✅ Notificação de teste enviada!';

  @override
  String get notificationTestScheduled =>
      '✅ Notificação de teste agendada para 30 segundos! Verifique os logs.';

  @override
  String notificationTestError(String error) {
    return '❌ Erro: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Informações de depuração';

  @override
  String get autoDetected => 'Detectado automaticamente';

  @override
  String get matchedInDescription => 'Encontrado na descrição';

  @override
  String get relocateFolderDialogTitle => 'Realocar pasta';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caminhos de projeto atualizados',
      one: '1 caminho de projeto atualizado',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personalizar abas';

  @override
  String get customizeTabsDescription =>
      'Escolha quais abas exibir na barra de navegacao. A aba Projetos e sempre visivel.';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Tabela de projetos (a tabela deve estar focada)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tabela de lançamentos (a tabela deve estar focada)';

  @override
  String get shortcutGroupNavigation => 'Navegação';

  @override
  String get shortcutFocusSearch => 'Focar na barra de pesquisa';

  @override
  String get shortcutRescan => 'Reanalisar pastas de projetos';

  @override
  String get shortcutFocusTable => 'Focar na tabela de projetos';

  @override
  String get shortcutPlayPause =>
      'Reproduzir / pausar música de pré-visualização';

  @override
  String get shortcutOpenInDaw => 'Abrir projeto no DAW';

  @override
  String get shortcutViewDetails => 'Ver detalhes do projeto';

  @override
  String get shortcutOpenFolder => 'Abrir pasta do projeto';

  @override
  String get shortcutNavigateRows => 'Navegar nas linhas';

  @override
  String get shortcutEditCell => 'Abrir detalhes do projeto';

  @override
  String get shortcutViewRelease => 'Ver detalhes do lançamento';

  @override
  String get shortcutGoBack => 'Voltar';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Modo padrão';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Modo sessão';

  @override
  String get shortcutToggleSession => 'Iniciar / Encerrar sessão';

  @override
  String get shortcutGroupPreviewPlayer => 'Reprodutor de prévia';

  @override
  String get shortcutPlayerPlayPause => 'Reproduzir / pausar';

  @override
  String get shortcutPlayerSeek5 => 'Avançar/Retroceder ±5 segundos';

  @override
  String get shortcutPlayerSeek30 => 'Avançar/Retroceder ±30 segundos';

  @override
  String get startupDialogTitle => 'Bem-vindo ao DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Comece adicionando uma pasta de projetos ou restaurando um backup do Google Drive.';

  @override
  String get startupAddFolderTitle => 'Adicionar pasta de projetos';

  @override
  String get startupAddFolderSubtitle =>
      'Selecione uma pasta com seus projetos DAW.';

  @override
  String get startupGoogleDriveTitle => 'Sincronizar backup do Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restaure seus projetos a partir de um backup no Google Drive.';

  @override
  String get startupDontShowAgain => 'Não mostrar isso na inicialização';

  @override
  String get deleteAllData => 'Excluir todos os dados';

  @override
  String get deleteAllDataSubtitle =>
      'Remover todos os perfis, projetos, lançamentos, playlists e configurações deste dispositivo.';

  @override
  String get deleteAllDataConfirm1Title => 'Excluir todos os dados?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Isso apagará permanentemente todos os perfis, projetos, lançamentos, playlists e configurações deste dispositivo. Seu backup no Google Drive (se houver) não será afetado.';

  @override
  String get deleteAllDataConfirm2Title => 'Tem certeza absoluta?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Esta ação não pode ser desfeita. O aplicativo voltará ao estado inicial.';

  @override
  String get deleteEverything => 'Excluir tudo';

  @override
  String get allDataDeleted => 'Todos os dados foram excluídos.';

  @override
  String get newerExportFound => 'Exportação mais recente encontrada';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Um arquivo mais recente foi encontrado na mesma pasta:\n$filename\n\nSubstituir a música de pré-visualização?';
  }

  @override
  String get replaceAndPlay => 'Substituir e reproduzir';

  @override
  String get keepCurrent => 'Manter atual';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription =>
      'Automatically upload a backup to Google Drive at the selected interval.';

  @override
  String get autoBackupInterval => 'Backup interval';

  @override
  String get autoBackupOff => 'Off';

  @override
  String get autoBackupEvery30Min => 'Every 30 minutes';

  @override
  String get autoBackupHourly => 'Every hour';

  @override
  String get autoBackupEvery6Hours => 'Every 6 hours';

  @override
  String get autoBackupDaily => 'Daily';

  @override
  String autoBackupNextBackup(String time) {
    return 'Próximo backup: $time';
  }

  @override
  String get playerTitle => 'Reprodutor de Música';

  @override
  String get playerToggleQueue => 'Alternar fila';

  @override
  String get playerSearchHint => 'Pesquisar faixas…';

  @override
  String playerTrackCount(int count) {
    return '$count faixas';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Nenhuma prévia encontrada.\nAbra um projeto e defina uma prévia.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Nenhuma faixa corresponde a\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Clique duplo para começar a reproduzir';

  @override
  String get playerSingleClickToPreview =>
      'Clique simples para ouvir na barra abaixo';

  @override
  String get playerQueueTitle => 'Fila';

  @override
  String get playerClearQueue => 'Limpar fila';

  @override
  String get playerQueueEmptyHint =>
      'Clique duplo para começar,\nou arraste faixas para a fila.';

  @override
  String get playerPrev => 'Anterior';

  @override
  String get playerNext => 'Próximo';

  @override
  String get playerGoToProject => 'Ir ao projeto';

  @override
  String get playerAddToQueue => 'Adicionar à fila';

  @override
  String get playerRemoveFromQueue => 'Remover da fila';

  @override
  String get playerDismissDetail => 'Fechar detalhes';

  @override
  String get playerNotes => 'NOTAS';

  @override
  String get playerTasks => 'TAREFAS';

  @override
  String get playerNoTasks => 'Nenhuma tarefa ainda.';

  @override
  String get playerAddTaskHint => 'Adicionar uma tarefa…';

  @override
  String playerCompletedTasks(int count) {
    return '$count concluída(s)';
  }

  @override
  String get playerPreviousTrack => 'Faixa anterior';

  @override
  String get playerNextTrack => 'Próxima faixa';

  @override
  String get playerOpenProject => 'Abrir projeto';

  @override
  String get playerRepeatAll => 'Repetir tudo';

  @override
  String get playerShuffle => 'Aleatório';

  @override
  String get volumeMute => 'Silenciar';

  @override
  String get volumeUnmute => 'Reativar som';

  @override
  String totalWorkTime(String time) {
    return 'Trabalho total: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Sessão: $time';
  }

  @override
  String get sessionHistory => 'Histórico de sessões';

  @override
  String get noSessionsYet => 'Nenhuma sessão registrada ainda';

  @override
  String get removeSessionTitle => 'Remover sessão?';

  @override
  String get editSessionTitle => 'Editar duração da sessão';

  @override
  String get editSessionHours => 'Horas';

  @override
  String get editSessionInvalid => 'A duração deve ser de pelo menos 1 minuto';

  @override
  String get sessionTableDate => 'Data';

  @override
  String get sessionTableTime => 'Hora';

  @override
  String get sessionTableDuration => 'Duração';

  @override
  String get sessionTableTotal => 'Total';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões',
      one: '1 sessão',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Trabalho por fase';

  @override
  String get tabPosition => 'Posição das abas';

  @override
  String get tabPositionTop => 'Topo';

  @override
  String get tabPositionLeft => 'Esquerda';

  @override
  String updateAvailableMessage(String version) {
    return 'Versão $version disponível';
  }

  @override
  String get dismiss => 'Dispensar';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checkForUpdatesDescription =>
      'Seja notificado quando uma nova versão estiver disponível.';

  @override
  String get checkNow => 'Verificar agora';

  @override
  String updateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get upToDate => 'O app está atualizado';

  @override
  String get updateAvailableTitle => 'Atualização disponível';

  @override
  String updateAvailableVersion(String version) {
    return 'A versão $version está pronta.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Você está usando v$version.';
  }

  @override
  String get viewUpdateDetails => 'Ver detalhes';

  @override
  String get getOnMicrosoftStore => 'Obter na Microsoft Store';

  @override
  String get downloadFromGitHub => 'Baixar do GitHub';

  @override
  String get updateWindowsInstructions =>
      'Abra a Microsoft Store e atualize o DAW Project Manager, ou clique abaixo.';

  @override
  String get updateMacInstructions =>
      'Baixe a versão mais recente do GitHub e substitua o app atual.';

  @override
  String get resetOnboarding => 'Redefinir integração inicial';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organize todos os seus projetos musicais em um só lugar.';

  @override
  String get onboardingLanguageTitle => 'Escolha o Idioma';

  @override
  String get onboardingThemeTitle => 'Escolha um Tema';

  @override
  String get onboardingFoldersTitle => 'Adicionar Pastas de Projetos';

  @override
  String get onboardingFoldersBody =>
      'Adicione a pasta raiz onde seus projetos de DAW estão armazenados.';

  @override
  String get onboardingDriveTitle => 'Sincronização Google Drive';

  @override
  String get onboardingDriveBody =>
      'Faça backup e sincronize os metadados do projeto com o Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Verificações de Atualizações';

  @override
  String get onboardingUpdatesBody =>
      'Seja notificado quando uma nova versão estiver disponível.';

  @override
  String get onboardingDoneTitle => 'Tudo Pronto!';

  @override
  String get onboardingDoneBody => 'Comece a explorar seus projetos.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get dawSession => 'Sessão DAW';

  @override
  String get clearDawSession => 'Encerrar sessão';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Retomar';

  @override
  String get workTimerSection => 'Lembretes de sessão de trabalho';

  @override
  String get workTimerSectionDesc =>
      'Receba notificações enquanto trabalha em um projeto inscrito';

  @override
  String get workTimerEnabled => 'Ativar lembretes de sessão de trabalho';

  @override
  String get workTimerIntervalLabel => 'Notificar a cada';

  @override
  String get minutes => 'minutos';

  @override
  String workTimerNotifBody(String time) {
    return 'Você está trabalhando há $time';
  }

  @override
  String get general => 'Geral';

  @override
  String get expand => 'Expandir';

  @override
  String get collapse => 'Recolher';

  @override
  String get lastModifiedColors => 'Cores da data de última modificação';

  @override
  String get lastModifiedColorsDescription =>
      'Colore a data de última modificação com base na idade e no estado. Verde = Concluído. Datas mais antigas desvanecem de amarelo para vermelho — vermelho mais intenso significa que o projeto não foi tocado há mais tempo.';

  @override
  String get sessionMode => 'Modo sessão';

  @override
  String get sessionModeDescription =>
      'Inscreva-se em um projeto antes de lançá-lo para rastrear o tempo de trabalho e gerenciá-lo pela barra de ferramentas';

  @override
  String get startSession => 'Iniciar sessão';

  @override
  String get endSession => 'Encerrar sessão';

  @override
  String get switchSession => 'Trocar sessão';

  @override
  String get switchSessionBody => 'Encerrar a sessão atual e iniciar uma nova?';

  @override
  String switchSessionCurrent(String project) {
    return 'Atual: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Nova: $project';
  }

  @override
  String get sessionDuration => 'Tempo de sessão';

  @override
  String get scanModeLabel => 'Modo de varredura:';

  @override
  String get scanModeSectionTitle => 'Modo de varredura';

  @override
  String get scanModeSectionDescription =>
      'Controla como os projetos em cada pasta são exibidos na tabela — como uma lista simples ou agrupados por subpasta.';

  @override
  String get scanModeFlat => 'Simples';

  @override
  String get scanModeSmartFolder => 'Pasta inteligente';

  @override
  String get scanModeFlatDescription =>
      'Mostra cada projeto como uma lista simples. Simples e rápido.';

  @override
  String get scanModeSmartFolderDescription =>
      'Agrupa projetos por pasta quando uma pasta contém mais de um projeto.';

  @override
  String get skip => 'Pular';

  @override
  String get suggestionsLabel => 'Sugestões';

  @override
  String get suggestionsRefresh => 'Atualizar';

  @override
  String get suggestionsEmptyState =>
      'Sem sugestões no momento. Toque em Atualizar para redefinir os itens descartados.';

  @override
  String get showSuggestions => 'Mostrar sugestões';

  @override
  String get showSuggestionsDescription =>
      'Exibe sugestões inteligentes na barra de ferramentas quando nenhuma sessão está em execução';

  @override
  String get onboardingSuggestionsTitle => 'Sugestões inteligentes';

  @override
  String get onboardingSuggestionsBody =>
      'Receba recomendações de projetos personalizadas na barra de ferramentas enquanto trabalha';

  @override
  String get onboardingSessionModeTitle => 'Modo sessão';

  @override
  String get onboardingSessionModeBody =>
      'Inicie sessões de trabalho focadas e acompanhe automaticamente o tempo gasto em cada projeto';

  @override
  String get suggestionsFeatureDeadlines =>
      'Lembretes de prazo para projetos futuros';

  @override
  String get suggestionsFeatureResume =>
      'Retomar o último projeto em que você trabalhou';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continuar as faixas modificadas recentemente';

  @override
  String get suggestionsEnableToggle => 'Ativar sugestões inteligentes';

  @override
  String get canBeChangedInSettings =>
      'Pode ser alterado mais tarde nas Configurações';

  @override
  String get next => 'Próximo';

  @override
  String get createProject => 'Criar';

  @override
  String get createProjectTooltip => 'Criar uma nova pasta de projeto';

  @override
  String get createProjectSelectFolder => 'Escolher local';

  @override
  String get createProjectSelectFolderHint =>
      'Selecione em qual pasta criar o novo projeto';

  @override
  String get createProjectNameTitle => 'Nomeie seu projeto';

  @override
  String get createProjectNameHint =>
      'Escolha um esquema de nomenclatura para a nova pasta';

  @override
  String get createProjectSchemeArtistTrack => 'Artista — Faixa';

  @override
  String get createProjectSchemeCollab => 'Colaboração';

  @override
  String get createProjectSchemeDate => 'Data — Faixa';

  @override
  String get createProjectSchemeCustom => 'Personalizado';

  @override
  String get createProjectArtistName => 'Nome do artista';

  @override
  String get createProjectTrackName => 'Nome da faixa';

  @override
  String get createProjectCustomName => 'Nome da pasta';

  @override
  String get createProjectAddArtist => 'Adicionar artista';

  @override
  String get createProjectSelectDaw => 'Abrir no DAW';

  @override
  String get createProjectSelectDawHint =>
      'Escolha qual DAW abrir para trabalhar neste projeto';

  @override
  String get createProjectDetectDaws => 'Detectar DAWs instalados';

  @override
  String get createProjectSkipDaw => 'Apenas criar a pasta';

  @override
  String get createProjectNoDawsFound =>
      'Nenhum DAW encontrado. A pasta ainda será criada.';

  @override
  String get createProjectCreateOnly => 'Criar pasta';

  @override
  String get createProjectCreateAndOpen => 'Criar e abrir';

  @override
  String get createProjectFolderExists => 'Já existe uma pasta com este nome';

  @override
  String get createProjectInvalidChars => 'O nome contém caracteres inválidos';

  @override
  String get createProjectError => 'Falha ao criar pasta';

  @override
  String get createProjectIncludeDate => 'Incluir prefixo de data';

  @override
  String get createProjectCreatedTitle => 'Pasta criada';

  @override
  String get createProjectCreatedMessage =>
      'A pasta do seu projeto foi criada:';

  @override
  String get createProjectCopyName => 'Copiar nome da pasta';

  @override
  String get createProjectNameCopied => 'Nome da pasta copiado';

  @override
  String get createProjectTrackSession => 'Rastrear sessão a partir de agora';

  @override
  String get pendingFolderSessionTitle => 'Sessão de trabalho detectada';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Você trabalhou em \"$projectName\" por $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continuar sessão';

  @override
  String get pendingFolderSessionEndRecord => 'Encerrar e registrar';

  @override
  String get activeSessionSwitchTitle => 'Sessão já ativa';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Uma sessão está ativa para \"$current\". Mudar para \"$next\" e salvar a sessão atual?';
  }

  @override
  String get activeSessionSwitch => 'Mudar';

  @override
  String get pendingProjectWaiting => 'Aguardando arquivo de projeto…';

  @override
  String get pendingProjectDelete => 'Excluir pasta vazia';

  @override
  String get pendingProjectDeleteTitle => 'Excluir pasta?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Excluir \"$folderName\" e seu conteúdo?';
  }

  @override
  String get pendingProjectDismiss => 'Parar de rastrear esta pasta';

  @override
  String get pendingProjectDismissTitle => 'Parar de rastrear?';

  @override
  String get pendingProjectDismissKeep => 'Manter pasta';

  @override
  String get pendingProjectDismissDelete => 'Excluir e fechar';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'A pasta não está vazia';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contém arquivos. Excluir tudo permanentemente?';
  }

  @override
  String get pendingProjectRefresh => 'Verificar arquivo de projeto';

  @override
  String get pendingProjectNotFound =>
      'Nenhum arquivo de projeto encontrado ainda';

  @override
  String get phases => 'Fases';

  @override
  String get phasesSubtitle =>
      'Adicionar, remover e reordenar fases do projeto';

  @override
  String get resetToDefaults => 'Restaurar padrões';

  @override
  String get addPhase => 'Adicionar fase';

  @override
  String get phaseNameHint => 'Nome da fase';

  @override
  String get phaseDuplicateError => 'Já existe uma fase com esse nome';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projetos usam esta fase',
      one: '1 projeto usa esta fase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Selecionar cor';

  @override
  String get markAsFinished => 'Marcar como fase concluída';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projetos usam fases que não existirão mais.',
      one: '1 projeto usa uma fase que não existirá mais.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Esses projetos manterão seu status atual, mas não aparecerão nos filtros de fase. Você sempre pode adicionar essas fases novamente depois.';

  @override
  String get camelotGenerateButton => 'Gerar mix';

  @override
  String get camelotDialogTitle => 'Mix Camelot';

  @override
  String get camelotDialogDescription =>
      'Ordena suas faixas por compatibilidade harmônica usando a roda Camelot. A proximidade de BPM é usada como critério de desempate.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count faixas elegíveis (tonalidade definida)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count serão ignoradas (sem tonalidade)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Nenhuma faixa tem tonalidade definida. Abra um projeto e defina sua tonalidade.';

  @override
  String get camelotGenerate => 'Gerar';

  @override
  String camelotQueueGenerated(int count) {
    return 'Fila preenchida com $count faixas em ordem harmônica';
  }

  @override
  String get camelotWheelGuideTooltip => 'Guia da roda Camelot';

  @override
  String get camelotWheelGuideTitle => 'Guia da Roda Camelot';

  @override
  String get camelotGuideRingsTitle => 'Os Anéis';

  @override
  String get camelotGuideRingsBody =>
      'Anel interno (A)  →  tonalidades menores\nAnel externo (B)  →  tonalidades maiores';

  @override
  String get camelotGuideNumbersTitle => 'Números 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Posições dispostas no sentido horário. Cada número representa uma vizinhança harmônica — os vizinhos compartilham fortes relações tonais.';

  @override
  String get camelotGuideColoursTitle => 'Guia de Cores';

  @override
  String get camelotGuideColoursBody =>
      '● Brilhante  →  a tonalidade da sua música\n● Suavemente iluminado  →  compatível para mixagem\n● Apagado  →  evitar para uma mixagem suave';

  @override
  String get camelotGuideTransitionsTitle => 'Transições Compatíveis';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (mesmo número, trocar anel)\n  Maior/menor relativo — praticamente sem emenda.\n\n8A → 7A ou 9A  (±1, mesmo anel)\n  Tom adjacente — mudança suave e sutil.\n\n8A → 1A ou 3A  (±7, mesmo anel)\n  Impulso ou queda de energia — mudança mais dramática.';

  @override
  String get playerMixSuggestions => 'SUGESTÕES DE MIX';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noPreviewSongsAvailable => 'No preview songs available';

  @override
  String get upNext => 'A seguir';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Repeat';

  @override
  String get playbackModeShuffle => 'Shuffle';
}
