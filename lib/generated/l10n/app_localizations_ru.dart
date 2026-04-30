// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Менеджер проектов DAW';

  @override
  String get projectDetails => 'Детали проекта';

  @override
  String get back => 'Назад';

  @override
  String get save => 'Сохранить';

  @override
  String get enable => 'Включить';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get launch => 'Открыть';

  @override
  String get view => 'Просмотр';

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get openInDaw => 'Запустить в DAW';

  @override
  String get extract => 'Извлечь';

  @override
  String get extracting => 'Извлечение…';

  @override
  String get extractingMetadata => 'Извлечение метаданных...';

  @override
  String get deepScan => 'Глубокое сканирование';

  @override
  String get rescan => 'Повторное сканирование';

  @override
  String get scanning => 'Сканирование…';

  @override
  String get projectName => 'Название проекта';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Тональность (например: C#m, F мажор)';

  @override
  String get notes => 'Заметки';

  @override
  String get projectPhase => 'Фаза проекта';

  @override
  String get failedToLoad => 'Ошибка загрузки';

  @override
  String get fileMissing => 'Файл отсутствует.';

  @override
  String launchingProject(String projectName) {
    return 'Открытие $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Не удалось открыть $projectName';
  }

  @override
  String get clearLibrary => 'Очистить библиотеку';

  @override
  String get clearLibraryMessage =>
      'Это удалит все сохраненные проекты и исходные папки. Продолжить?';

  @override
  String get clear => 'Очистить';

  @override
  String get roots => 'Папки Проектов';

  @override
  String get pathsSettingsDangerZoneTitle => 'Библиотека';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Очистить все проекты и папки проектов текущего профиля.';

  @override
  String get projectFoldersSectionTitle => 'Папки проектов';

  @override
  String get projectFoldersSectionSubtitle =>
      'Папки, которые будут сканироваться для поиска проектов DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Папки проектов отсутствуют';

  @override
  String get projectFoldersEmptySubtitle =>
      'Добавьте хотя бы одну папку, чтобы начать сканирование проектов.';

  @override
  String get notScannedYet => 'Ещё не сканировано';

  @override
  String lastScan(String date) {
    return 'Последнее сканирование: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Исключённые папки';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Эти папки будут пропускаться при сканировании, даже если они находятся внутри папки проектов.';

  @override
  String get addExcludedFolder => 'Добавить исключение';

  @override
  String get selectExcludedFolder => 'Выберите папку для исключения';

  @override
  String get excludedFoldersEmptyTitle => 'Исключённых папок нет';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Необязательно: добавьте папки, которые вы никогда не хотите сканировать.';

  @override
  String get removeExcludedFolderTitle => 'Удалить исключённую папку?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Эта папка больше не будет исключаться:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Эта папка больше не будет исключаться.';

  @override
  String get desktopOnlyPathsSettings =>
      'Эта страница доступна только в настольном приложении.';

  @override
  String get removeProjectFolderTitle => 'Удалить папку проектов?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Вы уверены, что хотите удалить \"$path\"? Это также удалит все проекты из этой папки, которые не находятся в релизах.';
  }

  @override
  String get projects => 'Проекты';

  @override
  String get hidden => 'скрытые';

  @override
  String get profileManager => 'Менеджер профилей';

  @override
  String get createNewProfile => 'Создать новый профиль';

  @override
  String get profileName => 'Имя профиля';

  @override
  String get create => 'Создать';

  @override
  String get profiles => 'Профили';

  @override
  String get active => 'Активный';

  @override
  String get switchProfile => 'Переключить';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get searchProjects => 'Поиск проектов...';

  @override
  String get searchReleases => 'Поиск релизов...';

  @override
  String get searchPlaylists => 'Поиск плейлистов...';

  @override
  String get noReleasesFound => 'Релизы не найдены';

  @override
  String get noPlaylistsFound => 'Плейлисты не найдены';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get deepScanTooltip =>
      'Глубокое сканирование извлекает полные метаданные из файлов проекта:\n• BPM (ударов в минуту)\n• Музыкальная тональность\n• Версия DAW\nЭто медленнее, но предоставляет полную информацию.';

  @override
  String get deepScanConfirm =>
      'Это просканирует все проекты и извлечет полные метаданные (BPM, тональность, версия DAW). Это может занять некоторое время. Продолжить?';

  @override
  String get metadataExtractedSuccessfully => 'Метаданные успешно извлечены';

  @override
  String failedToExtractMetadata(String error) {
    return 'Ошибка извлечения метаданных: $error';
  }

  @override
  String get saved => 'Сохранено';

  @override
  String get failedToLaunchDaw => 'Не удалось открыть DAW';

  @override
  String get releaseDetails => 'Детали релиза';

  @override
  String get releaseNotFound => 'Релиз не найден';

  @override
  String get error => 'Ошибка';

  @override
  String get loading => 'Загрузка...';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Вы уверены, что хотите удалить \"$profileName\"? Это удалит все проекты, папки проектов и релизы этого профиля.';
  }

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get remove => 'Удалить';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Вы уверены, что хотите удалить \"$trackName\" из этого релиза?';
  }

  @override
  String get saveName => 'Сохранить имя';

  @override
  String get profilePhotoUpdated => 'Фото профиля обновлено.';

  @override
  String get profilePhotoRemoved => 'Фото профиля удалено.';

  @override
  String profileRenamed(String newName) {
    return 'Профиль переименован в \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Профиль \"$name\" успешно создан';
  }

  @override
  String profileDeleted(String name) {
    return 'Профиль \"$name\" удален';
  }

  @override
  String get pleaseEnterProfileName => 'Пожалуйста, введите имя профиля';

  @override
  String failedToCreateProfile(String error) {
    return 'Ошибка создания профиля: $error';
  }

  @override
  String get noProfilesFound => 'Профили не найдены. Создайте один выше.';

  @override
  String get clearLibraryTooltip =>
      'Очистить библиотеку (проекты и папки проектов)';

  @override
  String lastModified(String date) {
    return 'Последнее изменение: $date';
  }

  @override
  String get name => 'Название';

  @override
  String get status => 'Статус';

  @override
  String get phase => 'Фаза';

  @override
  String get filterByPhase => 'Фильтровать по Фазе';

  @override
  String get filters => 'Фильтры';

  @override
  String get allPhases => 'Все Фазы';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Последнее Изменение';

  @override
  String get actions => 'Действия';

  @override
  String get hide => 'Скрыть';

  @override
  String get unhide => 'Показать';

  @override
  String get extractMetadata => 'Извлечь Метаданные';

  @override
  String get createRelease => 'Создать Релиз';

  @override
  String get clearSelection => 'Очистить Выбор';

  @override
  String get selectAllProjects => 'Выбрать все проекты';

  @override
  String get switchingProfiles => 'Переключение профилей...';

  @override
  String get scanningProjects => 'Сканирование проектов...';

  @override
  String get search => 'Поиск';

  @override
  String get projectsTab => 'Проекты';

  @override
  String get releasesTab => 'Релизы';

  @override
  String get showHidden => 'Показать Скрытые';

  @override
  String get showAll => 'Показать Все';

  @override
  String get showOnlyHidden => 'Показать Только Скрытые';

  @override
  String get deleteRootPath => 'Удалить папку проектов';

  @override
  String deleteRootPathMessage(String path) {
    return 'Вы уверены, что хотите удалить \"$path\"? Это также удалит все проекты из этой папки, которые не находятся в релизах.';
  }

  @override
  String rootsCount(int count) {
    return 'Папки Проектов: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Проекты: $count';
  }

  @override
  String get hiddenOnly => '(только скрытые)';

  @override
  String hiddenCount(int count) {
    return '($count скрытых)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count проект$plural скрыт$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count проект$plural показан$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Ошибка скрытия проектов: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Ошибка показа проектов: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Вы уверены, что хотите скрыть \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Релиз \"$title\" успешно создан.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Ошибка создания релиза: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Ошибка добавления папки: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'Проекты не найдены в выбранных папках проектов.';

  @override
  String get selectProjectsFolder => 'Выберите папку проектов';

  @override
  String get enterReleaseTitle => 'Введите Название Релиза';

  @override
  String get releaseTitle => 'Название Релиза';

  @override
  String get enterReleaseTitleHint => 'Введите название релиза';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Метаданные извлечены для $count проект$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count не удалось$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Ошибка записи файла BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Ошибка записи файла тональности: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Ошибка открытия: $error';
  }

  @override
  String get libraryCleared => 'Библиотека очищена.';

  @override
  String scanType(String type) {
    return 'Сканирование $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type завершено: $count проект$plural добавлен$plural/обновлен$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count проект$plural выбран$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Открытие папки для $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Ошибка открытия папки: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Операционная система не поддерживается для открытия папки.';

  @override
  String get noProjectsAvailable =>
      'Проекты недоступны. Пожалуйста, сначала добавьте проекты.';

  @override
  String get createNewRelease => 'Создать Новый Релиз';

  @override
  String get deleteRelease => 'Удалить Релиз';

  @override
  String deleteReleaseMessage(String title) {
    return 'Вы уверены, что хотите удалить \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Релиз \"$title\" удален.';
  }

  @override
  String get selectTracks => 'Выбрать Треки';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get noReleasesYet => 'Пока нет релизов';

  @override
  String get createFirstRelease =>
      'Создайте свой первый релиз, выбрав треки из ваших проектов';

  @override
  String releasesCount(int count) {
    return 'Релизы ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Ошибка загрузки релизов: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Треки ($count)';
  }

  @override
  String get addTracks => 'Добавить Треки';

  @override
  String get allProjectsAlreadyInRelease => 'Все проекты уже в этом релизе.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Добавлен$plural $count трек$plural в релиз.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Файлы Релиза ($count)';
  }

  @override
  String get addFiles => 'Добавить Файлы';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Добавлен$plural $count файл$plural в релиз.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Ошибка добавления файлов: $error';
  }

  @override
  String get noFilesToDownload => 'Нет файлов для загрузки.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP файл сохранен в: $path';
  }

  @override
  String get creatingZipFile => 'Создание ZIP-файла...';

  @override
  String failedToCreateZip(String error) {
    return 'Ошибка создания ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Выбранный файл не существует.';

  @override
  String get imageSavedSuccessfully => 'Изображение успешно сохранено!';

  @override
  String failedToSaveImage(String error) {
    return 'Ошибка сохранения изображения: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Ошибка загрузки релиза: $error';
  }

  @override
  String get errorLoadingProjects => 'Ошибка загрузки проектов: null';

  @override
  String get releaseSaved => 'Релиз сохранен.';

  @override
  String get releaseDate => 'Дата Релиза';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Ошибка сохранения даты релиза: $error';
  }

  @override
  String get releaseDateSaved => 'Дата релиза сохранена.';

  @override
  String get releaseDateCleared => 'Дата релиза очищена.';

  @override
  String get saveReleaseFilesZip => 'Сохранить ZIP файлы релиза';

  @override
  String get failedToOpenFile => 'Не удалось открыть файл';

  @override
  String failedToPlayAudio(String error) {
    return 'Ошибка воспроизведения аудио: $error';
  }

  @override
  String get renameFile => 'Переименовать Файл';

  @override
  String get selectTracksToAdd => 'Выбрать Треки для Добавления';

  @override
  String get fileNameUpdated => 'Имя файла обновлено.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Ошибка обновления имени файла: $error';
  }

  @override
  String get deleteFile => 'Удалить Файл';

  @override
  String deleteFileMessage(String fileName) {
    return 'Вы уверены, что хотите удалить \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Файл \"$fileName\" удален.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Ошибка удаления файла: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Не удалось открыть папку: $error';
  }

  @override
  String get artwork => 'Обложка';

  @override
  String get title => 'Название';

  @override
  String get tracks => 'Треки';

  @override
  String get description => 'Описание';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Выбрать треки для включения в релиз ($count выбрано)';
  }

  @override
  String get searchTracks => 'Поиск треков';

  @override
  String get searchTracksHint => 'Поиск по названию или типу DAW';

  @override
  String get noTracksFound => 'Треки не найдены';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get fileNotFound => 'Файл не найден';

  @override
  String get fileName => 'Имя Файла';

  @override
  String get editTodo => 'Редактировать Задачу';

  @override
  String get todoText => 'Текст задачи';

  @override
  String get enterTodoText => 'Введите текст задачи';

  @override
  String get addNewTodo => 'Добавить новую задачу';

  @override
  String get enterTodoItem => 'Введите элемент задачи';

  @override
  String get todoList => 'Список Задач';

  @override
  String get todoTemplates => 'Шаблоны TODO';

  @override
  String get createTemplate => 'Создать Шаблон';

  @override
  String get editTemplate => 'Редактировать Шаблон';

  @override
  String get deleteTemplate => 'Удалить Шаблон';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Вы уверены, что хотите удалить шаблон \"$name\"?';
  }

  @override
  String get templateName => 'Название Шаблона';

  @override
  String get templateNameHint => 'напр. Чеклист Микширования';

  @override
  String get templateItems => 'Элементы Шаблона';

  @override
  String get templateItemsHint => 'Один элемент на строку';

  @override
  String get templateNameAndItemsRequired => 'Название и элементы обязательны';

  @override
  String get templateItemsRequired => 'Требуется хотя бы один элемент';

  @override
  String get templateCreated => 'Шаблон создан';

  @override
  String get templateUpdated => 'Шаблон обновлен';

  @override
  String get templateDeleted => 'Шаблон удален';

  @override
  String get noTemplatesYet => 'Пока нет шаблонов';

  @override
  String get createFirstTemplate => 'Создайте свой первый шаблон TODO';

  @override
  String templateItemCount(int count) {
    return '$count элемент(ов)';
  }

  @override
  String get selectTemplate => 'Выбрать Шаблон';

  @override
  String get importFromTemplate => 'Импортировать из Шаблона';

  @override
  String get manageTemplates => 'Управление Шаблонами';

  @override
  String get noTemplatesAvailable =>
      'Нет доступных шаблонов. Создайте сначала.';

  @override
  String templateImported(String name, int count) {
    return 'Шаблон \"$name\" импортирован ($count элементов)';
  }

  @override
  String get errorLoadingTemplates => 'Ошибка загрузки шаблонов';

  @override
  String get importTodos => 'Импортировать Задачи из Файла';

  @override
  String get noTodosInFile => 'Задачи не найдены в файле';

  @override
  String todosImported(int count) {
    return '$count задач(и) импортировано успешно';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get addToRelease => 'Добавить в Релиз';

  @override
  String get createNew => 'Создать Новый';

  @override
  String get addToExisting => 'Добавить в Существующий';

  @override
  String get createAndAdd => 'Создать и Добавить';

  @override
  String get selectRelease => 'Выберите релиз';

  @override
  String get noExistingReleasesFound => 'Существующие релизы не найдены.';

  @override
  String get addToSelectedRelease => 'Добавить в Выбранный Релиз';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Ошибка сохранения фото профиля: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Ошибка удаления фото профиля: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Ошибка переименования профиля: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Ошибка удаления профиля: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Ошибка загрузки профилей: $error';
  }

  @override
  String get projectPhaseIdea => 'Идея';

  @override
  String get projectPhaseArranging => 'Аранжировка';

  @override
  String get projectPhaseMixing => 'Сведение';

  @override
  String get projectPhaseMastering => 'Мастеринг';

  @override
  String get projectPhaseFinished => 'Завершено';

  @override
  String get changeStatus => 'Изменить Фазу';

  @override
  String get selectNewStatus => 'Выберите новую фазу:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Фаза изменена на \"$status\" для $count проект$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Фаза изменена на \"$status\" для $successCount проект$successPlural, $failCount не удалось$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Ошибка при изменении фазы: $error';
  }

  @override
  String get tooltipEditProfileName => 'Редактировать имя профиля';

  @override
  String get tooltipAddTodo => 'Добавить задачу';

  @override
  String get tooltipClearDate => 'Очистить дату';

  @override
  String get tooltipPickDate => 'Выбрать дату';

  @override
  String get tooltipViewDetails => 'Просмотр Деталей';

  @override
  String get tooltipLaunchInDaw => 'Открыть в DAW';

  @override
  String get tooltipRemoveFromRelease => 'Удалить из Релиза';

  @override
  String get profile => 'Профиль';

  @override
  String get noDateSet => 'Дата не установлена';

  @override
  String get imageNotFound => 'Изображение не найдено';

  @override
  String get clickToBrowseArtwork => 'Нажмите, чтобы найти обложку';

  @override
  String get noFilesAddedYet =>
      'Файлы еще не добавлены.\nНажмите \"Добавить Файлы\", чтобы загрузить файлы релиза.';

  @override
  String get noTodosYet => 'Задач пока нет. Добавьте одну выше.';

  @override
  String get done => 'Готово';

  @override
  String get backupAndRestore => 'Резервное копирование и восстановление';

  @override
  String get exportBackup => 'Экспорт резервной копии';

  @override
  String get importBackup => 'Импорт резервной копии';

  @override
  String get backupExportedSuccessfully =>
      'Резервная копия успешно экспортирована';

  @override
  String failedToExportBackup(String error) {
    return 'Ошибка при экспорте резервной копии: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Резервная копия успешно импортирована: $projectsCount проектов, $rootsCount папок проектов, $releasesCount релизов';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Ошибка при импорте резервной копии: $error';
  }

  @override
  String get importBackupMessage => 'Выберите способ импорта резервной копии:';

  @override
  String get mergeWithCurrentProfile =>
      'Объединить с текущим активным профилем';

  @override
  String get replaceCurrentProfile =>
      'Полностью заменить текущий профиль (ВНИМАНИЕ: Это удалит все данные текущего профиля)';

  @override
  String get createNewProfileForImport =>
      'Создать новый профиль для этих данных';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Резервная копия импортирована в новый профиль \"$profileName\": $projectsCount проектов, $rootsCount папок проектов, $releasesCount релизов';
  }

  @override
  String get noProfileSelected => 'Профиль не выбран';

  @override
  String get exportBackupDialogTitle => 'Экспорт резервной копии';

  @override
  String get importBackupDialogTitle => 'Импорт резервной копии';

  @override
  String get invalidBackupFileFormat =>
      'Неверный формат файла резервной копии: отсутствует версия';

  @override
  String get profileNameRequiredForNewProfile =>
      'Имя профиля обязательно при создании нового профиля';

  @override
  String get currentProfileRequired =>
      'Текущий профиль обязателен для режима объединения или замены';

  @override
  String get previewSong => 'Превью Трека';

  @override
  String get noPreviewSongTitle => 'Нет песни для предпрослушивания';

  @override
  String get noPreviewSongMessage =>
      'Для этого проекта не задана песня для предпрослушивания. Выберите аудиофайл, чтобы загрузить и воспроизвести его.';

  @override
  String get noPreviewSongDragHint =>
      'Вы также можете перетащить аудиофайл прямо на строку проекта в таблице.';

  @override
  String get previewSongRemoved => 'Превью трека удалено';

  @override
  String get previewSongAdded => 'Превью трека добавлено';

  @override
  String get previewSongFileNotFound => 'Файл превью трека не найден';

  @override
  String get previewSongFileNotFoundMessage =>
      'Файл песни для предварительного прослушивания не найден на диске. Хотите выбрать новый файл или удалить запись?';

  @override
  String get selectNewFile => 'Выбрать новый файл';

  @override
  String failedToPlayPreview(String error) {
    return 'Не удалось воспроизвести превью: $error';
  }

  @override
  String get removePreviewSong => 'Удалить превью трека';

  @override
  String get removePreviewSongConfirm =>
      'Вы уверены, что хотите удалить превью трека? Это действие нельзя отменить.';

  @override
  String get noPreviewSongSelected => 'Превью трека не выбрано';

  @override
  String get changePreviewSong => 'Изменить Превью Трека';

  @override
  String get selectPreviewSong => 'Выбрать Превью Трека';

  @override
  String get dropAudioFileHere => 'Перетащите аудиофайл сюда';

  @override
  String projectAge(String age) {
    return 'Возраст проекта: $age';
  }

  @override
  String createdDate(String date) {
    return 'создан $date';
  }

  @override
  String completedIn(String duration) {
    return 'Завершён за: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'завершён $date';
  }

  @override
  String get dateToday => 'сегодня';

  @override
  String get dateYesterday => 'вчера';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
      one: '1 день назад',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нед. назад',
      one: '1 неделя назад',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мес. назад',
      one: '1 месяц назад',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count г. назад',
      one: '1 год назад',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years г., $months мес.';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years г.';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months мес., $days дн.';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months мес.';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days дн.';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours ч.';
  }

  @override
  String get ageJustNow => 'Только что';

  @override
  String get ageLessThanHour => 'Менее часа';

  @override
  String get viewProfile => 'Просмотр профиля';

  @override
  String get googleDriveSync => 'Синхронизация Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Синхронизируйте свои данные с Google Drive для резервного копирования и восстановления между устройствами.';

  @override
  String get manageGoogleDriveSync => 'Управление синхронизацией Google Drive';

  @override
  String get signInToGoogleDrive => 'Войти в Google Drive';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String get uploadBackup => 'Загрузить резервную копию';

  @override
  String get downloadBackup => 'Скачать резервную копию';

  @override
  String get newerBackupAvailable => 'Доступна новая резервная копия в облаке';

  @override
  String get signOut => 'Выйти';

  @override
  String get downloadPreviewSongs => 'Скачать превью-песни';

  @override
  String get downloadPreviewSongsExplanation =>
      'Если не отмечено, превью-песни будут пропущены (экономит время и место). Вы можете скачать их позже при необходимости.';

  @override
  String get replaceLocalData => 'Заменить локальные данные';

  @override
  String get downloadBackupConfirmation =>
      'Это заменит ваши локальные данные резервной копией из Google Drive.\n\nВы уверены, что хотите продолжить?';

  @override
  String get enterAuthorizationCode => 'Ввести код авторизации';

  @override
  String get authorizationCode => 'Код авторизации';

  @override
  String get pasteCodeFromBrowser => 'Вставьте код из браузера';

  @override
  String get sessionActive => 'Сессия активна';

  @override
  String get signedIn => 'Вход выполнен';

  @override
  String get creatingInitialBackup => 'Создание начальной резервной копии...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Успешный вход и резервное копирование в Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Успешный вход и резервное копирование в Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Успешный вход в Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Успешный вход в Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Вход отменен или не удался. Проверьте консоль для деталей.';

  @override
  String get failedToLaunchBrowser => 'Не удалось запустить браузер';

  @override
  String get signInCancelled => 'Вход отменен';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Не удалось обменять код авторизации';

  @override
  String errorSigningIn(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get googleSignInError => 'Ошибка входа Google';

  @override
  String get developerConsoleNotSetUp =>
      'Консоль разработчика настроена неправильно. Пожалуйста, проверьте конфигурацию OAuth в Google Cloud Console.';

  @override
  String get platformError => 'Ошибка платформы';

  @override
  String get signedOutFromGoogleDrive => 'Выход из Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Ошибка выхода: $error';
  }

  @override
  String get syncing => 'Синхронизация...';

  @override
  String get errorNoProfileSelected => 'Ошибка: Профиль не выбран';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Синхронизация завершена! Проекты: +$projectsAdded ~$projectsUpdated, Релизы: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Ошибка синхронизации: $error';
  }

  @override
  String get uploadingBackup => 'Загрузка резервной копии...';

  @override
  String get backupUploadedSuccessfully => 'Резервная копия успешно загружена!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Резервная копия успешно загружена в Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Ошибка загрузки резервной копии: $error';
  }

  @override
  String get downloadingBackup => 'Скачивание резервной копии...';

  @override
  String get checkingForBackup => 'Проверка резервной копии...';

  @override
  String get backupUpToDate => 'Резервная копия актуальна';

  @override
  String errorCheckingBackup(String error) {
    return 'Ошибка проверки резервной копии: $error';
  }

  @override
  String get download => 'Скачать';

  @override
  String get remoteBackupIsNewer =>
      'Удаленная копия новее локальных данных. Загрузка перезапишет её.';

  @override
  String get confirmUpload => 'Подтвердить загрузку';

  @override
  String get noBackupFileFound =>
      'Файл резервной копии не найден в Google Drive. Сначала создайте резервную копию, синхронизировав данные.';

  @override
  String get noBackupFileFoundStatus =>
      'Файл резервной копии не найден. Сначала создайте резервную копию.';

  @override
  String get downloadCancelled => 'Скачивание отменено';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Резервная копия скачана! Проекты: +$projectsAdded ~$projectsUpdated, Релизы: +$releasesAdded ~$releasesUpdated';
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
    return 'Резервная копия скачана!\n\nПроекты:\n  • $projectsAdded добавлено\n  • $projectsUpdated обновлено\n\nРелизы:\n  • $releasesAdded добавлено\n  • $releasesUpdated обновлено\n\nПревью песен:\n  • $previewSongsDownloaded скачано\n  • $previewSongsUpdated обновлено';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Ошибка скачивания резервной копии: $error';
  }

  @override
  String signedInAs(String email) {
    return 'Вход выполнен как: $email';
  }

  @override
  String lastSync(String date) {
    return 'Последняя синхронизация: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Удаленная копия: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Последняя загрузка: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Последнее скачивание: $date';
  }

  @override
  String get checkForBackup => 'Проверить резервную копию';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get notificationsOnlyOnAndroid =>
      'Уведомления о сроках доступны только на устройствах Android.';

  @override
  String get notificationPermissionRequired =>
      'Требуется разрешение на уведомления';

  @override
  String get notificationPermissionDescription =>
      'Пожалуйста, включите уведомления, чтобы получать напоминания о сроках.';

  @override
  String get notificationPermissionDenied =>
      'Разрешение на уведомления отклонено. Пожалуйста, включите его в настройках.';

  @override
  String get notificationSettingsSaved =>
      'Настройки уведомлений успешно сохранены';

  @override
  String get errorSavingSettings => 'Ошибка сохранения настроек';

  @override
  String get enableDeadlineNotifications => 'Включить уведомления о сроках';

  @override
  String get receiveRemindersForDeadlines =>
      'Получать напоминания о сроках проектов';

  @override
  String get notificationTime => 'Время уведомления';

  @override
  String get timeToReceiveNotifications =>
      'Время суток для получения уведомлений';

  @override
  String get reminderDays => 'Дни напоминания';

  @override
  String get selectDaysBeforeDeadline =>
      'Выберите, за сколько дней до срока вы хотите получать уведомления';

  @override
  String get notifyOnDeadlineDay => 'Уведомить в день срока';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Также получать уведомление в сам день срока';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get deadlineNotificationsHelp =>
      'Вы будете получать уведомления в указанное время в выбранные дни до каждого срока проекта. Нажмите на уведомление, чтобы открыть детали проекта.';

  @override
  String get oneDay => '1 день';

  @override
  String xDays(int count) {
    return '$count дней';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get support => 'Поддержать';

  @override
  String get supportTheProject => 'Поддержать проект';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Не удалось открыть браузер. Пожалуйста, посетите: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Ошибка при открытии браузера: $error';
  }

  @override
  String get generateTestingDatabase => 'Создать тестовую базу данных';

  @override
  String get generateTestingDatabaseMessage =>
      'Это заполнит базу данных примерами проектов и релизов для тестирования. Продолжить?';

  @override
  String get testingDatabaseGenerated =>
      'Тестовая база данных успешно создана!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Ошибка при создании тестовой базы данных: $error';
  }

  @override
  String get playlists => 'Плейлисты';

  @override
  String get playlistsDesktopOnly => 'Плейлисты доступны только на Android.';

  @override
  String get noPlaylistsYet => 'Плейлистов пока нет';

  @override
  String get createFirstPlaylist => 'Нажмите + чтобы создать первый плейлист';

  @override
  String playlistSongCount(int count) {
    return '$count треков';
  }

  @override
  String get createPlaylist => 'Создать Плейлист';

  @override
  String get playlistName => 'Название Плейлиста';

  @override
  String get playlistNameHint => 'Мой Плейлист';

  @override
  String get playlistNameRequired => 'Название плейлиста обязательно';

  @override
  String get editPlaylist => 'Редактировать Плейлист';

  @override
  String get stopPlaybackBeforeEditing =>
      'Пожалуйста, остановите воспроизведение перед редактированием плейлиста';

  @override
  String get selectPreviewSongs => 'Выбрать Превью';

  @override
  String get deletePlaylist => 'Удалить Плейлист';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Вы уверены, что хотите удалить \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Плейлист удален';

  @override
  String get errorDeletingPlaylist => 'Ошибка удаления плейлиста';

  @override
  String get playlistUpdated => 'Плейлист обновлен';

  @override
  String get changeSong => 'Сменить Песню';

  @override
  String get changeSongConfirm =>
      'Песня сейчас воспроизводится. Хотите переключиться на эту песню?';

  @override
  String get changeSongButton => 'Сменить';

  @override
  String playlistProgress(int current, int total) {
    return '$current из $total';
  }

  @override
  String get noPreviewSongsInPlaylist => 'В этом плейлисте нет превью';

  @override
  String get tapEditToAddSongs =>
      'Нажмите «Изменить», чтобы добавить песни в этот плейлист';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Нет проектов с превью-песнями для добавления';

  @override
  String get noProjectsInDatabase =>
      'Проекты не найдены в базе данных. Пожалуйста, сначала синхронизируйте ваши проекты.';

  @override
  String get firstTimeSyncTitle => 'Похоже, вы здесь впервые!';

  @override
  String get firstTimeSyncMessage =>
      'Давайте синхронизируем ваши данные из Google Drive, чтобы начать';

  @override
  String get syncWithGoogleDrive => 'Синхронизировать с Google Drive';

  @override
  String get errorLoadingPlaylists => 'Ошибка загрузки плейлистов';

  @override
  String get playlistItems => 'Элементы Плейлиста';

  @override
  String get addSongs => 'Добавить Треки';

  @override
  String get addAudioFiles => 'Добавить Аудиофайлы';

  @override
  String get selectAudioFiles => 'Выбрать Аудиофайлы';

  @override
  String get selectFromProjects => 'Выбрать из Проектов';

  @override
  String get add => 'Добавить';

  @override
  String get fromProject => 'Из Проекта';

  @override
  String get projectDeadline => 'Срок Проекта';

  @override
  String get noDeadlineSet => 'Срок не установлен';

  @override
  String get camelotCode => 'Код Камелот';

  @override
  String get deadline => 'Срок';

  @override
  String get dueToday => 'Истекает сегодня';

  @override
  String daysLate(int days) {
    return '$daysд просрочено';
  }

  @override
  String daysLeft(int days) {
    return '$daysд осталось';
  }

  @override
  String get hideFinished => 'Скрыть Завершенные';

  @override
  String get showOnlyDeadlines => 'Показать дедлайн';

  @override
  String get filterByDeadline => 'Фильтр по Сроку';

  @override
  String get allDeadlines => 'Все Сроки';

  @override
  String get hasDeadline => 'Со Сроком';

  @override
  String get overdue => 'Просрочено';

  @override
  String get dueSoon => 'Скоро Истекает (7д)';

  @override
  String get today => 'Сегодня';

  @override
  String get noPreviewSong => 'Нет превью';

  @override
  String get playPreview => 'Воспроизвести Превью';

  @override
  String get uploadCancelled => 'Загрузка отменена';

  @override
  String get backupUploadCancelledByUser =>
      'Загрузка резервной копии отменена пользователем';

  @override
  String get collectingData => 'Сбор данных...';

  @override
  String get uploadingPreviewSongs => 'Загрузка превью песен...';

  @override
  String get uploadingProfilePhotos => 'Загрузка фото профиля...';

  @override
  String get uploadingReleaseArtwork => 'Загрузка обложек релизов...';

  @override
  String get uploadingDatabase => 'Загрузка базы данных...';

  @override
  String get completed => 'Завершено!';

  @override
  String get cancelling => 'Отмена...';

  @override
  String get uploadingBackupTitle => 'Загрузка Резервной Копии';

  @override
  String get cancellingUpload => 'Отмена загрузки...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Пожалуйста, подождите, пока мы остановим загрузку...';

  @override
  String get downloadingDatabase => 'Скачивание базы данных...';

  @override
  String get downloadingPreviewSongs => 'Скачивание превью песен...';

  @override
  String get downloadingProfilePhotos => 'Скачивание фотографий профиля...';

  @override
  String get downloadingReleaseArtwork => 'Скачивание обложек релизов...';

  @override
  String get mergingData => 'Объединение данных...';

  @override
  String get downloadingBackupTitle => 'Скачивание Резервной Копии';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Исходный файл не найден на этом устройстве';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Исходный файл не найден на этом устройстве — режим только метаданных. Вы всё равно можете редактировать и экспортировать метаданные.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Превью недоступно. Пожалуйста, сначала загрузите резервную копию.';

  @override
  String get sharePreviewSong => 'Поделиться превью';

  @override
  String get shareAsZip => 'Поделиться как ZIP';

  @override
  String get share => 'Поделиться';

  @override
  String get shareZip => 'Поделиться ZIP';

  @override
  String get saveCopy => 'Сохранить копию';

  @override
  String savedCopyTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Не удалось поделиться превью: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Не удалось поделиться превью как ZIP: $error';
  }

  @override
  String get biographySaved => 'Биография сохранена';

  @override
  String failedToSaveBiography(String error) {
    return 'Не удалось сохранить биографию: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Файл сохранён в $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Не удалось скачать файл: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Все файлы сохранены в $filename';
  }

  @override
  String get artworkAdded => 'Обложка добавлена';

  @override
  String failedToAddArtwork(String error) {
    return 'Не удалось добавить обложку: $error';
  }

  @override
  String get artworkRemoved => 'Обложка удалена';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Не удалось удалить обложку: $error';
  }

  @override
  String get pressKitFileAdded => 'Файл пресс-кита добавлен';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Не удалось добавить файл пресс-кита: $error';
  }

  @override
  String get pressKitFileRemoved => 'Файл пресс-кита удалён';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Не удалось удалить файл пресс-кита: $error';
  }

  @override
  String get selectFilesToDownload => 'Выберите файлы для загрузки';

  @override
  String get biography => 'Биография';

  @override
  String get biographyWillBeSaved => 'Будет сохранена как biography.txt';

  @override
  String get artworkFiles => 'Файлы обложек';

  @override
  String get pressKitFiles => 'Файлы пресс-кита';

  @override
  String get additionalAssets => 'Дополнительные ресурсы';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Скачать $count файл$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count файл$plural сохранено в $filename';
  }

  @override
  String get addAsset => 'Добавить ресурс';

  @override
  String get assetNameLabel => 'Название ресурса';

  @override
  String get assetNameHint => 'Например: Логотип, Баннер, Фото';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName успешно добавлен';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Не удалось добавить ресурс: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName удалён';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Не удалось удалить ресурс: $error';
  }

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String get selectFiles => 'Выбрать файлы';

  @override
  String get downloadAll => 'Скачать всё';

  @override
  String get saveBiographyTooltip => 'Сохранить биографию';

  @override
  String get enterBiographyHint => 'Введите биографию профиля...';

  @override
  String get addArtwork => 'Добавить обложку';

  @override
  String get addFile => 'Добавить файл';

  @override
  String get openFile => 'Открыть файл';

  @override
  String get menuView => 'Вид';

  @override
  String get menuAbout => 'О программе DAW Project Manager';

  @override
  String get menuLanguage => 'Язык';

  @override
  String get menuWarnBeforeQuit => 'Предупреждать перед выходом (Cmd+Q)';

  @override
  String get menuQuit => 'Выйти из DAW Project Manager';

  @override
  String get menuWindow => 'Окно';

  @override
  String get donate => 'Пожертвовать';

  @override
  String get website => 'Сайт';

  @override
  String get switchToClassicDark => 'Переключить на Classic Dark';

  @override
  String get switchToNeonDark => 'Переключить на Neon Dark';

  @override
  String get switchToClassicTheme => 'Переключить на Classic тему';

  @override
  String get switchToNeonTheme => 'Переключить на Neon тему';

  @override
  String get menuTheme => 'Тема';

  @override
  String get appDescription =>
      'Менеджер проектов для музыкальных продюсеров и звуковых дизайнеров.';

  @override
  String get neonDarkThemeName => 'Неоновая тёмная';

  @override
  String get classicDarkThemeName => 'Классическая тёмная';

  @override
  String get statisticsTab => 'Статистика';

  @override
  String get statsTotalProjects => 'Всего проектов';

  @override
  String get statsInProgress => 'В работе';

  @override
  String get statsFinished => 'Завершено';

  @override
  String get statsAvgCompletion => 'Ср. завершение';

  @override
  String get statsPhaseDistribution => 'Проекты по фазам';

  @override
  String get statsAvgTimePerPhase => 'Ср. дней на фазу';

  @override
  String get statsProductivity => 'Продуктивность';

  @override
  String get statsCreatedSeries => 'Создано';

  @override
  String get statsProjectHealth => 'Возраст и состояние проектов';

  @override
  String get statsCatalogInsights => 'Анализ каталога';

  @override
  String get statsBpmDistribution => 'Распределение BPM';

  @override
  String get statsTopKeys => 'Популярные тональности';

  @override
  String get statsDawTypes => 'Типы DAW';

  @override
  String get statsProjectActivity => 'Активность проектов';

  @override
  String get statsNoData => 'Нет данных';

  @override
  String get statsNoPhaseData => 'Данные появятся после смены фаз.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Последняя активность: $days дн. назад';
  }

  @override
  String get statsLastActivityToday => 'Активен сегодня';

  @override
  String get statsNoEvents => 'Событий пока нет';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Фаза: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Обновлено: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Выполнено: $text';
  }

  @override
  String get statsEventFileModified => 'Файл изменён на диске';

  @override
  String get statsClearHistory => 'Очистить историю';

  @override
  String get statsClearHistoryConfirm =>
      'Удалить все записанные события для этого проекта?';

  @override
  String get statsSearchProjects => 'Поиск проектов…';

  @override
  String statsEventCount(int count) {
    return '$count событий';
  }

  @override
  String get statsViewHistory => 'Статистика проекта';

  @override
  String get statsPhaseHistory => 'История фаз';

  @override
  String get statsEventBreakdown => 'Сводка событий';

  @override
  String statsDaysSoFar(int days) {
    return 'Уже $daysд';
  }

  @override
  String get statsNoProjectsFound => 'Проекты не найдены';

  @override
  String statsNotTouchedDays(int days) {
    return 'Не изменялся $days дн.';
  }

  @override
  String get sortByLastModified => 'Дата изменения';

  @override
  String get sortByName => 'Имя';

  @override
  String get sortByPhase => 'Фаза';

  @override
  String get sortByCreatedAt => 'Дата добавления';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get monoLabel => 'Моно';

  @override
  String get monoToggleTooltip => 'Переключить моно воспроизведение';

  @override
  String get monoRequiresWav => 'Для монофонического микса требуется WAV-файл';

  @override
  String get monoUnsupportedFormat =>
      'Не удалось создать монофонический микс — неподдерживаемый формат';

  @override
  String monoSwitchFailed(String error) {
    return 'Ошибка переключения моно: $error';
  }

  @override
  String get analyzeLabel => 'Анализировать';

  @override
  String get reAnalyzeLabel => 'Повторный анализ';

  @override
  String get analysisRequiresWav => 'Для анализа требуется WAV-файл';

  @override
  String get noResultsForFilter => 'Нет результатов для текущего фильтра';

  @override
  String get noResultsForFilterHint => 'Попробуйте изменить поиск или фильтры.';

  @override
  String get noProjectsFound => 'Проекты не найдены';

  @override
  String get noProjectsFoundHint =>
      'Добавьте корневую папку в настройках, чтобы начать.';

  @override
  String get queueTab => 'Задачи';

  @override
  String get queueSearchHint => 'Поиск задач...';

  @override
  String get queueNoPendingTasks => 'Всё готово!';

  @override
  String get queueNoPendingTasksHint =>
      'Нет незавершённых задач в ваших проектах.';

  @override
  String get queueNoMatchingTasks => 'Задачи не найдены';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks незавершённых задач в $projects проектах';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager v$version';
  }

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get renameProjectFileTitle => 'Переименовать файл проекта';

  @override
  String get renameFileButtonLabel => 'Переименовать файл';

  @override
  String get newFileNameLabel => 'Новое имя файла (без расширения)';

  @override
  String renameAlreadyExists(String name) {
    return 'Файл с именем \"$name\" уже существует.';
  }

  @override
  String renameSuccess(String name) {
    return 'Переименовано в \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Не удалось переименовать: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Имя не может быть пустым';

  @override
  String get nameInvalidCharacters => 'Имя не может содержать / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'Также переименовать содержащую папку';

  @override
  String get renameButton => 'Переименовать';

  @override
  String get previewMixdownFolderTitle => 'Папка миксов для предпросмотра';

  @override
  String get previewMixdownFolderSubtitle =>
      'Имя подпапки в каждой папке проекта, которую нужно проверять в первую очередь при автоматическом обнаружении песен для предпросмотра. Оставьте пустым для использования настроек DAW по умолчанию.';

  @override
  String get previewMixdownFolderHint => 'например, Миксы';

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
    return 'Тональность: $key';
  }

  @override
  String get audioFileNotFound => 'Аудиофайл не найден';

  @override
  String errorPlayingAudio(String error) {
    return 'Ошибка воспроизведения аудио: $error';
  }

  @override
  String get notificationTestTitle =>
      'Тестирование уведомлений для проверки часового пояса и планирования:';

  @override
  String get notificationSendNow => 'Отправить сейчас';

  @override
  String get notificationSchedule30s => 'Запланировать +30с';

  @override
  String get notificationShowDebugInfo => 'Показать отладочную информацию';

  @override
  String get notificationRescheduleAll => 'Перепланировать все';

  @override
  String get notificationTestSent => '✅ Тестовое уведомление отправлено!';

  @override
  String get notificationTestScheduled =>
      '✅ Тестовое уведомление запланировано на 30 секунд! Проверьте журналы консоли.';

  @override
  String notificationTestError(String error) {
    return '❌ Ошибка: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Отладочная информация';

  @override
  String get autoDetected => 'Определено автоматически';

  @override
  String get matchedInDescription => 'Совпадение в описании';

  @override
  String get relocateFolderDialogTitle => 'Переместить папку';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Обновлено $count путей проектов',
      one: 'Обновлён 1 путь проекта',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Настроить вкладки';

  @override
  String get customizeTabsDescription =>
      'Выберите, какие вкладки отображать на панели навигации. Вкладка «Проекты» всегда видима.';

  @override
  String get keyboardShortcuts => 'Сочетания клавиш';

  @override
  String get shortcutGroupGlobal => 'Глобальные';

  @override
  String get shortcutGroupProjectsTable =>
      'Таблица проектов (таблица должна быть в фокусе)';

  @override
  String get shortcutGroupReleasesTable =>
      'Таблица релизов (таблица должна быть в фокусе)';

  @override
  String get shortcutGroupNavigation => 'Навигация';

  @override
  String get shortcutFocusSearch => 'Перейти к строке поиска';

  @override
  String get shortcutRescan => 'Повторно сканировать папки';

  @override
  String get shortcutFocusTable => 'Перейти к таблице проектов';

  @override
  String get shortcutPlayPause => 'Воспроизвести / пауза превью';

  @override
  String get shortcutOpenInDaw => 'Открыть проект в DAW';

  @override
  String get shortcutViewDetails => 'Просмотр деталей проекта';

  @override
  String get shortcutOpenFolder => 'Открыть папку проекта';

  @override
  String get shortcutNavigateRows => 'Навигация по строкам';

  @override
  String get shortcutEditCell => 'Открыть детали проекта';

  @override
  String get shortcutViewRelease => 'Просмотр деталей релиза';

  @override
  String get shortcutGoBack => 'Назад';

  @override
  String get shortcutGroupPreviewPlayer => 'Плеер предпросмотра';

  @override
  String get shortcutPlayerPlayPause => 'Воспроизведение / пауза';

  @override
  String get shortcutPlayerSeek5 => 'Перемотка ±5 секунд';

  @override
  String get shortcutPlayerSeek30 => 'Перемотка ±30 секунд';

  @override
  String get newerExportFound => 'Найден более новый экспорт';

  @override
  String newerExportFoundMessage(String filename) {
    return 'В той же папке найден более новый файл:\n$filename\n\nЗаменить песню для предпросмотра?';
  }

  @override
  String get replaceAndPlay => 'Заменить и воспроизвести';

  @override
  String get keepCurrent => 'Оставить текущую';
}
