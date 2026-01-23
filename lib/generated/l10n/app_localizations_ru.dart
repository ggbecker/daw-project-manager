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
  String get cancel => 'Отмена';

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
  String get noReleasesFound => 'Релизы не найдены';

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
  String failedToOpenFile(String error) {
    return 'Ошибка открытия файла: $error';
  }

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
  String get previewSongRemoved => 'Превью трека удалено';

  @override
  String get previewSongAdded => 'Превью трека добавлено';

  @override
  String get previewSongFileNotFound => 'Файл превью трека не найден';

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
    return '$count дн. назад';
  }

  @override
  String dateWeeksAgo(int count, String plural) {
    return '$count нед. назад';
  }

  @override
  String dateMonthsAgo(int count, String plural) {
    return '$count мес. назад';
  }

  @override
  String dateYearsAgo(int count, String plural) {
    return '$count г. назад';
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
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get support => 'Поддержать';

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
  String playlistProgress(int current, int total) {
    return '$current из $total';
  }

  @override
  String get noPreviewSongsInPlaylist => 'В этом плейлисте нет превью';

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
  String get showOnlyDeadlines => 'Показать только с дедлайном';

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
}
