// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DAWプロジェクトマネージャー';

  @override
  String get projectDetails => 'プロジェクトの詳細';

  @override
  String get back => '戻る';

  @override
  String get save => '保存';

  @override
  String get enable => '有効にする';

  @override
  String get cancel => 'キャンセル';

  @override
  String get launch => '開く';

  @override
  String get view => '表示';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String get openInDaw => 'DAWで起動';

  @override
  String get extract => '抽出';

  @override
  String get extracting => '抽出中…';

  @override
  String get extractingMetadata => 'メタデータを抽出中...';

  @override
  String get deepScan => '詳細スキャン';

  @override
  String get rescan => '再スキャン';

  @override
  String get scanning => 'スキャン中…';

  @override
  String get projectName => 'プロジェクト名';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'キー（例：C#m、F major）';

  @override
  String get notes => 'メモ';

  @override
  String get projectPhase => 'プロジェクトフェーズ';

  @override
  String get failedToLoad => '読み込みに失敗しました';

  @override
  String get fileMissing => 'ファイルが見つかりません。';

  @override
  String launchingProject(String projectName) {
    return '$projectNameを開いています…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return '$projectNameを開けませんでした';
  }

  @override
  String get clearLibrary => 'ライブラリをクリア';

  @override
  String get clearLibraryMessage =>
      'これにより、保存されたすべてのプロジェクトとソースフォルダが削除されます。続行しますか？';

  @override
  String get clear => 'クリア';

  @override
  String get roots => 'プロジェクトフォルダ';

  @override
  String get pathsSettingsDangerZoneTitle => 'ライブラリ';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      '現在のプロファイルのすべてのプロジェクトとプロジェクトフォルダーをクリアします。';

  @override
  String get projectFoldersSectionTitle => 'プロジェクトフォルダー';

  @override
  String get projectFoldersSectionSubtitle => 'DAWプロジェクトを探すためにスキャンされるフォルダーです。';

  @override
  String get projectFoldersEmptyTitle => 'プロジェクトフォルダーがありません';

  @override
  String get projectFoldersEmptySubtitle =>
      '少なくとも1つのフォルダーを追加して、プロジェクトのスキャンを開始してください。';

  @override
  String get notScannedYet => '未スキャン';

  @override
  String lastScan(String date) {
    return '最終スキャン: $date';
  }

  @override
  String get excludedFoldersSectionTitle => '除外フォルダー';

  @override
  String get excludedFoldersSectionSubtitle =>
      'これらのフォルダーは、プロジェクトフォルダー内にあってもスキャン時にスキップされます。';

  @override
  String get addExcludedFolder => '除外を追加';

  @override
  String get selectExcludedFolder => '除外するフォルダーを選択';

  @override
  String get excludedFoldersEmptyTitle => '除外フォルダーはありません';

  @override
  String get excludedFoldersEmptySubtitle => '任意: スキャンしたくないフォルダーを追加できます。';

  @override
  String get removeExcludedFolderTitle => '除外フォルダーを削除しますか？';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'このフォルダーは除外されなくなります:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath => 'このフォルダーは除外されなくなります。';

  @override
  String get desktopOnlyPathsSettings => 'このページはデスクトップアプリでのみ利用できます。';

  @override
  String get removeProjectFolderTitle => 'プロジェクトフォルダーを削除しますか？';

  @override
  String removeProjectFolderMessage(String path) {
    return '「$path」を削除してもよろしいですか？これにより、リリースに含まれていないこのフォルダー内のプロジェクトも削除されます。';
  }

  @override
  String get projects => 'プロジェクト';

  @override
  String get hidden => '非表示';

  @override
  String get profileManager => 'プロファイルマネージャー';

  @override
  String get createNewProfile => '新しいプロファイルを作成';

  @override
  String get profileName => 'プロファイル名';

  @override
  String get create => '作成';

  @override
  String get profiles => 'プロファイル';

  @override
  String get active => 'アクティブ';

  @override
  String get switchProfile => '切り替え';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get addFolder => 'フォルダを追加';

  @override
  String get searchProjects => 'プロジェクトを検索...';

  @override
  String get searchReleases => 'リリースを検索...';

  @override
  String get searchPlaylists => 'プレイリストを検索...';

  @override
  String get noReleasesFound => 'リリースが見つかりません';

  @override
  String get noPlaylistsFound => 'プレイリストが見つかりません';

  @override
  String get tryDifferentSearch => '別の検索用語を試してください';

  @override
  String get deepScanTooltip =>
      '詳細スキャンは、プロジェクトファイルから完全なメタデータを抽出します：\n• BPM（1分あたりのビート数）\n• 音楽キー\n• DAWバージョン\nこれは遅いですが、完全な情報を提供します。';

  @override
  String get deepScanConfirm =>
      'これにより、すべてのプロジェクトをスキャンし、完全なメタデータ（BPM、キー、DAWバージョン）を抽出します。これには時間がかかる場合があります。続行しますか？';

  @override
  String get metadataExtractedSuccessfully => 'メタデータの抽出に成功しました';

  @override
  String failedToExtractMetadata(String error) {
    return 'メタデータの抽出に失敗しました: $error';
  }

  @override
  String get saved => '保存しました';

  @override
  String get failedToLaunchDaw => 'DAWを開けませんでした';

  @override
  String get releaseDetails => 'リリースの詳細';

  @override
  String get releaseNotFound => 'リリースが見つかりません';

  @override
  String get error => 'エラー';

  @override
  String get loading => '読み込み中...';

  @override
  String get deleteProfile => 'プロファイルを削除';

  @override
  String deleteProfileMessage(String profileName) {
    return '「$profileName」を削除してもよろしいですか？これにより、このプロファイルのすべてのプロジェクト、プロジェクトフォルダ、リリースが削除されます。';
  }

  @override
  String get editProfile => 'プロファイルを編集';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get remove => '削除';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'このリリースから「$trackName」を削除してもよろしいですか？';
  }

  @override
  String get saveName => '名前を保存';

  @override
  String get profilePhotoUpdated => 'プロファイル写真を更新しました。';

  @override
  String get profilePhotoRemoved => 'プロファイル写真を削除しました。';

  @override
  String profileRenamed(String newName) {
    return 'プロファイル名を「$newName」に変更しました';
  }

  @override
  String profileCreated(String name) {
    return 'プロファイル「$name」を作成しました';
  }

  @override
  String profileDeleted(String name) {
    return 'プロファイル「$name」を削除しました';
  }

  @override
  String get pleaseEnterProfileName => 'プロファイル名を入力してください';

  @override
  String failedToCreateProfile(String error) {
    return 'プロファイルの作成に失敗しました: $error';
  }

  @override
  String get noProfilesFound => 'プロファイルが見つかりません。上で作成してください。';

  @override
  String get clearLibraryTooltip => 'ライブラリをクリア（プロジェクトとプロジェクトフォルダ）';

  @override
  String lastModified(String date) {
    return '最終更新: $date';
  }

  @override
  String get name => '名前';

  @override
  String get status => 'ステータス';

  @override
  String get phase => 'フェーズ';

  @override
  String get filterByPhase => 'フェーズでフィルター';

  @override
  String get allPhases => 'すべてのフェーズ';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => '最終更新';

  @override
  String get actions => 'アクション';

  @override
  String get hide => '非表示にする';

  @override
  String get unhide => '表示する';

  @override
  String get extractMetadata => 'メタデータを抽出';

  @override
  String get createRelease => 'リリースを作成';

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get selectAllProjects => 'すべてのプロジェクトを選択';

  @override
  String get switchingProfiles => 'プロファイルを切り替え中...';

  @override
  String get scanningProjects => 'プロジェクトをスキャン中...';

  @override
  String get search => '検索';

  @override
  String get projectsTab => 'プロジェクト';

  @override
  String get releasesTab => 'リリース';

  @override
  String get showHidden => '非表示を表示';

  @override
  String get showAll => 'すべて表示';

  @override
  String get showOnlyHidden => '非表示のみ表示';

  @override
  String get deleteRootPath => 'プロジェクトフォルダーを削除';

  @override
  String deleteRootPathMessage(String path) {
    return '「$path」を削除してもよろしいですか？これにより、リリースに含まれていないこのフォルダ内のすべてのプロジェクトも削除されます。';
  }

  @override
  String rootsCount(int count) {
    return 'プロジェクトフォルダ: $count';
  }

  @override
  String projectsCount(int count) {
    return 'プロジェクト: $count';
  }

  @override
  String get hiddenOnly => '（非表示のみ）';

  @override
  String hiddenCount(int count) {
    return '（$count非表示）';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$countプロジェクト$pluralを非表示にしました。';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$countプロジェクト$pluralを表示しました。';
  }

  @override
  String failedToHideProjects(String error) {
    return 'プロジェクトの非表示に失敗しました: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'プロジェクトの表示に失敗しました: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return '「$projectName」を非表示にしてもよろしいですか？';
  }

  @override
  String releaseCreated(String title) {
    return 'リリース「$title」を作成しました。';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'リリースの作成に失敗しました: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'フォルダの追加エラー: $error';
  }

  @override
  String get noProjectsFoundInRoots => '選択したプロジェクトフォルダにプロジェクトが見つかりませんでした。';

  @override
  String get selectProjectsFolder => 'プロジェクトフォルダを選択';

  @override
  String get enterReleaseTitle => 'リリースタイトルを入力';

  @override
  String get releaseTitle => 'リリースタイトル';

  @override
  String get enterReleaseTitleHint => 'リリースタイトルを入力';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return '$countプロジェクト$pluralのメタデータを抽出しました。$failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count失敗しました。';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'BPMファイルの書き込みに失敗しました: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'キーファイルの書き込みに失敗しました: $error';
  }

  @override
  String failedToLaunch(String error) {
    return '起動に失敗しました: $error';
  }

  @override
  String get libraryCleared => 'ライブラリをクリアしました。';

  @override
  String scanType(String type) {
    return '$typeスキャン';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type完了: $countプロジェクト$pluralを追加/更新しました。';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$countプロジェクト$pluralを選択しました';
  }

  @override
  String openingFolder(String projectName) {
    return '$projectNameのフォルダを開いています…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder => 'フォルダを開くためのOSがサポートされていません。';

  @override
  String get noProjectsAvailable => 'プロジェクトがありません。まずプロジェクトを追加してください。';

  @override
  String get createNewRelease => '新しいリリースを作成';

  @override
  String get deleteRelease => 'リリースを削除';

  @override
  String deleteReleaseMessage(String title) {
    return '「$title」を削除してもよろしいですか？';
  }

  @override
  String releaseDeleted(String title) {
    return 'リリース「$title」を削除しました。';
  }

  @override
  String get selectTracks => 'トラックを選択';

  @override
  String get continueButton => '続行';

  @override
  String get noReleasesYet => 'まだリリースがありません';

  @override
  String get createFirstRelease => 'プロジェクトからトラックを選択して最初のリリースを作成してください';

  @override
  String releasesCount(int count) {
    return 'リリース（$count）';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'リリースの読み込みエラー: $error';
  }

  @override
  String tracksCount(int count) {
    return 'トラック（$count）';
  }

  @override
  String get addTracks => 'トラックを追加';

  @override
  String get allProjectsAlreadyInRelease => 'すべてのプロジェクトがすでにこのリリースに含まれています。';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'リリースに$countトラック$pluralを追加しました。';
  }

  @override
  String releaseFilesCount(int count) {
    return 'リリースファイル（$count）';
  }

  @override
  String get addFiles => 'ファイルを追加';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'リリースに$countファイル$pluralを追加しました。';
  }

  @override
  String failedToAddFiles(String error) {
    return 'ファイルの追加に失敗しました: $error';
  }

  @override
  String get noFilesToDownload => 'ダウンロードするファイルがありません。';

  @override
  String zipFileSaved(String path) {
    return 'ZIPファイルを保存しました: $path';
  }

  @override
  String get creatingZipFile => 'ZIPファイルを作成中...';

  @override
  String failedToCreateZip(String error) {
    return 'ZIPの作成に失敗しました: $error';
  }

  @override
  String get selectedFileDoesNotExist => '選択したファイルが存在しません。';

  @override
  String get imageSavedSuccessfully => '画像を正常に保存しました！';

  @override
  String failedToSaveImage(String error) {
    return '画像の保存に失敗しました: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'リリースの読み込みエラー: $error';
  }

  @override
  String get errorLoadingProjects => 'プロジェクトの読み込みエラー: null';

  @override
  String get releaseSaved => 'リリースを保存しました。';

  @override
  String get releaseDate => 'リリース日';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'リリース日の保存に失敗しました: $error';
  }

  @override
  String get releaseDateSaved => 'リリース日を保存しました。';

  @override
  String get releaseDateCleared => 'リリース日をクリアしました。';

  @override
  String get saveReleaseFilesZip => 'リリースファイルZIPを保存';

  @override
  String get failedToOpenFile => 'ファイルを開けませんでした';

  @override
  String failedToPlayAudio(String error) {
    return 'オーディオの再生に失敗しました: $error';
  }

  @override
  String get renameFile => 'ファイル名を変更';

  @override
  String get selectTracksToAdd => '追加するトラックを選択';

  @override
  String get fileNameUpdated => 'ファイル名を更新しました。';

  @override
  String errorUpdatingFileName(String error) {
    return 'ファイル名の更新エラー: $error';
  }

  @override
  String get deleteFile => 'ファイルを削除';

  @override
  String deleteFileMessage(String fileName) {
    return '「$fileName」を削除してもよろしいですか？';
  }

  @override
  String fileDeleted(String fileName) {
    return 'ファイル「$fileName」を削除しました。';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'ファイルの削除に失敗しました: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get artwork => 'アートワーク';

  @override
  String get title => 'タイトル';

  @override
  String get tracks => 'トラック';

  @override
  String get description => '説明';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'リリースに含めるトラックを選択（$count選択済み）';
  }

  @override
  String get searchTracks => 'トラックを検索';

  @override
  String get searchTracksHint => '名前またはDAWタイプで検索';

  @override
  String get noTracksFound => 'トラックが見つかりませんでした';

  @override
  String get unknown => '不明';

  @override
  String get fileNotFound => 'ファイルが見つかりません';

  @override
  String get fileName => 'ファイル名';

  @override
  String get editTodo => 'タスクを編集';

  @override
  String get todoText => 'タスクテキスト';

  @override
  String get enterTodoText => 'タスクテキストを入力';

  @override
  String get addNewTodo => '新しいタスクを追加';

  @override
  String get enterTodoItem => 'タスク項目を入力';

  @override
  String get todoList => 'タスクリスト';

  @override
  String get todoTemplates => 'TODOテンプレート';

  @override
  String get createTemplate => 'テンプレート作成';

  @override
  String get editTemplate => 'テンプレート編集';

  @override
  String get deleteTemplate => 'テンプレート削除';

  @override
  String deleteTemplateConfirm(String name) {
    return 'テンプレート「$name」を削除してもよろしいですか？';
  }

  @override
  String get templateName => 'テンプレート名';

  @override
  String get templateNameHint => '例：ミキシングチェックリスト';

  @override
  String get templateItems => 'テンプレート項目';

  @override
  String get templateItemsHint => '1行に1項目';

  @override
  String get templateNameAndItemsRequired => 'テンプレート名と項目が必要です';

  @override
  String get templateItemsRequired => '少なくとも1つの項目が必要です';

  @override
  String get templateCreated => 'テンプレートを作成しました';

  @override
  String get templateUpdated => 'テンプレートを更新しました';

  @override
  String get templateDeleted => 'テンプレートを削除しました';

  @override
  String get noTemplatesYet => 'まだテンプレートがありません';

  @override
  String get createFirstTemplate => '最初のTODOテンプレートを作成';

  @override
  String templateItemCount(int count) {
    return '$count個の項目';
  }

  @override
  String get selectTemplate => 'テンプレート選択';

  @override
  String get importFromTemplate => 'テンプレートからインポート';

  @override
  String get manageTemplates => 'テンプレート管理';

  @override
  String get noTemplatesAvailable => 'テンプレートがありません。最初に作成してください。';

  @override
  String templateImported(String name, int count) {
    return 'テンプレート「$name」をインポート（$count項目）';
  }

  @override
  String get errorLoadingTemplates => 'テンプレート読み込みエラー';

  @override
  String get importTodos => 'ファイルからタスクをインポート';

  @override
  String get noTodosInFile => 'ファイルにタスクが見つかりません';

  @override
  String todosImported(int count) {
    return '$count個のタスクをインポートしました';
  }

  @override
  String errorImportingTodos(String error) {
    return 'インポートエラー: $error';
  }

  @override
  String get addToRelease => 'リリースに追加';

  @override
  String get createNew => '新規作成';

  @override
  String get addToExisting => '既存に追加';

  @override
  String get createAndAdd => '作成して追加';

  @override
  String get selectRelease => 'リリースを選択';

  @override
  String get noExistingReleasesFound => '既存のリリースが見つかりませんでした。';

  @override
  String get addToSelectedRelease => '選択したリリースに追加';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'プロファイル写真の保存に失敗しました: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'プロファイル写真の削除に失敗しました: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'プロファイルの名前変更に失敗しました: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'プロファイルの削除に失敗しました: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'プロファイルの読み込みエラー: $error';
  }

  @override
  String get projectPhaseIdea => 'アイデア';

  @override
  String get projectPhaseArranging => 'アレンジ';

  @override
  String get projectPhaseMixing => 'ミキシング';

  @override
  String get projectPhaseMastering => 'マスタリング';

  @override
  String get projectPhaseFinished => '完了';

  @override
  String get changeStatus => 'フェーズを変更';

  @override
  String get selectNewStatus => '新しいフェーズを選択:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return '$count プロジェクト$pluralのフェーズを「$status」に変更しました';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return '$successCount プロジェクト$successPluralのフェーズを「$status」に変更しましたが、$failCount が失敗$failPluralしました';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'フェーズの変更に失敗しました: $error';
  }

  @override
  String get tooltipEditProfileName => 'プロファイル名を編集';

  @override
  String get tooltipAddTodo => 'タスクを追加';

  @override
  String get tooltipClearDate => '日付をクリア';

  @override
  String get tooltipPickDate => '日付を選択';

  @override
  String get tooltipViewDetails => '詳細を表示';

  @override
  String get tooltipLaunchInDaw => 'DAWで開く';

  @override
  String get tooltipRemoveFromRelease => 'リリースから削除';

  @override
  String get profile => 'プロファイル';

  @override
  String get noDateSet => '日付が設定されていません';

  @override
  String get imageNotFound => '画像が見つかりません';

  @override
  String get clickToBrowseArtwork => 'アートワークを参照するにはクリック';

  @override
  String get noFilesAddedYet =>
      'まだファイルが追加されていません。\n「ファイルを追加」をクリックしてリリースファイルをアップロードしてください。';

  @override
  String get noTodosYet => 'まだタスクがありません。上に追加してください。';

  @override
  String get done => '完了';

  @override
  String get backupAndRestore => 'バックアップと復元';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String get backupExportedSuccessfully => 'バックアップのエクスポートに成功しました';

  @override
  String failedToExportBackup(String error) {
    return 'バックアップのエクスポートに失敗しました: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'バックアップのインポートに成功しました: $projectsCount プロジェクト、$rootsCount プロジェクトフォルダ、$releasesCount リリース';
  }

  @override
  String failedToImportBackup(String error) {
    return 'バックアップのインポートに失敗しました: $error';
  }

  @override
  String get importBackupMessage => 'バックアップのインポート方法を選択してください:';

  @override
  String get mergeWithCurrentProfile => '現在のアクティブなプロフィールとマージ';

  @override
  String get replaceCurrentProfile =>
      '現在のプロフィールを完全に置き換える（警告: これにより現在のプロフィールのすべてのデータが削除されます）';

  @override
  String get createNewProfileForImport => 'このデータ用に新しいプロフィールを作成';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '新しいプロフィール \"$profileName\" にバックアップをインポートしました: $projectsCount プロジェクト、$rootsCount プロジェクトフォルダ、$releasesCount リリース';
  }

  @override
  String get noProfileSelected => 'プロフィールが選択されていません';

  @override
  String get exportBackupDialogTitle => 'バックアップをエクスポート';

  @override
  String get importBackupDialogTitle => 'バックアップをインポート';

  @override
  String get invalidBackupFileFormat => '無効なバックアップファイル形式: バージョンがありません';

  @override
  String get profileNameRequiredForNewProfile =>
      '新しいプロフィールを作成する際は、プロフィール名が必要です';

  @override
  String get currentProfileRequired => 'マージまたは置き換えモードには現在のプロフィールが必要です';

  @override
  String get previewSong => 'プレビュー曲';

  @override
  String get previewSongRemoved => 'プレビュー曲が削除されました';

  @override
  String get previewSongAdded => 'プレビュー曲が追加されました';

  @override
  String get previewSongFileNotFound => 'プレビュー曲のファイルが見つかりません';

  @override
  String failedToPlayPreview(String error) {
    return 'プレビューの再生に失敗しました: $error';
  }

  @override
  String get removePreviewSong => 'プレビュー曲を削除';

  @override
  String get removePreviewSongConfirm => 'プレビュー曲を削除してもよろしいですか？この操作は元に戻せません。';

  @override
  String get noPreviewSongSelected => 'プレビュー曲が選択されていません';

  @override
  String get changePreviewSong => 'プレビュー曲を変更';

  @override
  String get selectPreviewSong => 'プレビュー曲を選択';

  @override
  String get dropAudioFileHere => 'オーディオファイルをここにドロップ';

  @override
  String projectAge(String age) {
    return 'プロジェクト経過時間: $age';
  }

  @override
  String createdDate(String date) {
    return '$dateに作成';
  }

  @override
  String completedIn(String duration) {
    return '完成までの期間: $duration';
  }

  @override
  String finishedDate(String date) {
    return '$dateに完成';
  }

  @override
  String get dateToday => '今日';

  @override
  String get dateYesterday => '昨日';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count週間前',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countヶ月前',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年前',
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
    return '$years年$monthsヶ月';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years年';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$monthsヶ月$days日';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$monthsヶ月';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days日';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours時間';
  }

  @override
  String get ageJustNow => 'たった今';

  @override
  String get ageLessThanHour => '1時間未満';

  @override
  String get viewProfile => 'プロフィールを表示';

  @override
  String get googleDriveSync => 'Google Drive同期';

  @override
  String get googleDriveSyncDescription =>
      'Google Driveとデータを同期して、デバイス間でバックアップと復元を行います。';

  @override
  String get manageGoogleDriveSync => 'Google Drive同期を管理';

  @override
  String get signInToGoogleDrive => 'Google Driveにサインイン';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get uploadBackup => 'バックアップをアップロード';

  @override
  String get downloadBackup => 'バックアップをダウンロード';

  @override
  String get newerBackupAvailable => 'クラウドに新しいバックアップが利用可能';

  @override
  String get signOut => 'サインアウト';

  @override
  String get downloadPreviewSongs => 'プレビュー曲をダウンロード';

  @override
  String get downloadPreviewSongsExplanation =>
      'チェックを外すと、プレビュー曲はスキップされます（時間とストレージを節約）。必要に応じて後でダウンロードできます。';

  @override
  String get replaceLocalData => 'ローカルデータを置き換え';

  @override
  String get downloadBackupConfirmation =>
      'これにより、ローカルデータがGoogle Driveのバックアップに置き換えられます。\n\n続行してもよろしいですか？';

  @override
  String get enterAuthorizationCode => '認証コードを入力';

  @override
  String get authorizationCode => '認証コード';

  @override
  String get pasteCodeFromBrowser => 'ブラウザからコードを貼り付け';

  @override
  String get sessionActive => 'セッション有効';

  @override
  String get signedIn => 'サインイン済み';

  @override
  String get creatingInitialBackup => '初期バックアップを作成中...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Google Driveに正常にサインインし、バックアップしました';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Google Driveに正常にサインインし、バックアップしました！';

  @override
  String get successfullySignedInToGoogleDrive => 'Google Driveに正常にサインインしました';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Google Driveに正常にサインインしました！';

  @override
  String get signInCancelledOrFailed =>
      'サインインがキャンセルされたか失敗しました。詳細はコンソールを確認してください。';

  @override
  String get failedToLaunchBrowser => 'ブラウザの起動に失敗しました';

  @override
  String get signInCancelled => 'サインインがキャンセルされました';

  @override
  String get failedToExchangeAuthorizationCode => '認証コードの交換に失敗しました';

  @override
  String errorSigningIn(String error) {
    return 'サインインエラー: $error';
  }

  @override
  String get unknownError => '不明なエラー';

  @override
  String get googleSignInError => 'Googleサインインエラー';

  @override
  String get developerConsoleNotSetUp =>
      '開発者コンソールが正しく設定されていません。Google Cloud ConsoleでOAuth設定を確認してください。';

  @override
  String get platformError => 'プラットフォームエラー';

  @override
  String get signedOutFromGoogleDrive => 'Google Driveからサインアウトしました';

  @override
  String errorSigningOut(String error) {
    return 'サインアウトエラー: $error';
  }

  @override
  String get syncing => '同期中...';

  @override
  String get errorNoProfileSelected => 'エラー: プロフィールが選択されていません';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '同期完了！プロジェクト: +$projectsAdded ~$projectsUpdated、リリース: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return '同期エラー: $error';
  }

  @override
  String get uploadingBackup => 'バックアップをアップロード中...';

  @override
  String get backupUploadedSuccessfully => 'バックアップが正常にアップロードされました！';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Google Driveにバックアップが正常にアップロードされました！';

  @override
  String errorUploadingBackup(String error) {
    return 'バックアップのアップロードエラー: $error';
  }

  @override
  String get downloadingBackup => 'バックアップをダウンロード中...';

  @override
  String get checkingForBackup => 'バックアップを確認中...';

  @override
  String get backupUpToDate => 'バックアップは最新です';

  @override
  String errorCheckingBackup(String error) {
    return 'バックアップの確認エラー: $error';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get remoteBackupIsNewer =>
      'リモートバックアップはローカルデータより新しいです。アップロードすると上書きされます。';

  @override
  String get confirmUpload => 'アップロードを確認';

  @override
  String get noBackupFileFound =>
      'Google Driveにバックアップファイルが見つかりません。データを同期して最初にバックアップを作成してください。';

  @override
  String get noBackupFileFoundStatus =>
      'バックアップファイルが見つかりません。最初にバックアップを作成してください。';

  @override
  String get downloadCancelled => 'ダウンロードがキャンセルされました';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'バックアップをダウンロードしました！プロジェクト: +$projectsAdded ~$projectsUpdated、リリース: +$releasesAdded ~$releasesUpdated';
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
    return 'バックアップがダウンロードされました!\n\nプロジェクト:\n  • $projectsAdded 追加\n  • $projectsUpdated 更新\n\nリリース:\n  • $releasesAdded 追加\n  • $releasesUpdated 更新\n\nプレビュー曲:\n  • $previewSongsDownloaded ダウンロード\n  • $previewSongsUpdated 更新';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'バックアップのダウンロードエラー: $error';
  }

  @override
  String signedInAs(String email) {
    return 'サインイン: $email';
  }

  @override
  String lastSync(String date) {
    return '最終同期: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'リモートバックアップ: $date';
  }

  @override
  String lastUploadTime(String date) {
    return '最後のアップロード: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return '最後のダウンロード: $date';
  }

  @override
  String get checkForBackup => 'バックアップを確認';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get notificationsOnlyOnAndroid => '期限通知はAndroidデバイスでのみ利用可能です。';

  @override
  String get notificationPermissionRequired => '通知の許可が必要です';

  @override
  String get notificationPermissionDescription =>
      '期限のリマインダーを受け取るには、通知を有効にしてください。';

  @override
  String get notificationPermissionDenied => '通知の許可が拒否されました。設定で有効にしてください。';

  @override
  String get notificationSettingsSaved => '通知設定を正常に保存しました';

  @override
  String get errorSavingSettings => '設定の保存エラー';

  @override
  String get enableDeadlineNotifications => '期限通知を有効にする';

  @override
  String get receiveRemindersForDeadlines => 'プロジェクトの期限のリマインダーを受け取る';

  @override
  String get notificationTime => '通知時刻';

  @override
  String get timeToReceiveNotifications => '通知を受け取る時刻';

  @override
  String get reminderDays => 'リマインダー日数';

  @override
  String get selectDaysBeforeDeadline => '期限の何日前に通知を受け取るか選択してください';

  @override
  String get notifyOnDeadlineDay => '期限当日に通知';

  @override
  String get receiveNotificationOnDeadlineDay => '期限当日にも通知を受け取る';

  @override
  String get howItWorks => '使い方';

  @override
  String get deadlineNotificationsHelp =>
      '各プロジェクトの期限の前に選択した日数で、指定された時刻に通知を受け取ります。通知をタップするとプロジェクトの詳細が開きます。';

  @override
  String get oneDay => '1日';

  @override
  String xDays(int count) {
    return '$count日';
  }

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get support => 'サポート';

  @override
  String get supportTheProject => 'プロジェクトをサポート';

  @override
  String couldNotOpenBrowser(String url) {
    return 'ブラウザを開けませんでした。次のURLにアクセスしてください: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'ブラウザを開く際にエラーが発生しました: $error';
  }

  @override
  String get generateTestingDatabase => 'テストデータベースを生成';

  @override
  String get generateTestingDatabaseMessage =>
      'これにより、テスト用のサンプルプロジェクトとリリースでデータベースが入力されます。続行しますか？';

  @override
  String get testingDatabaseGenerated => 'テストデータベースが正常に生成されました！';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'テストデータベースの生成に失敗しました: $error';
  }

  @override
  String get playlists => 'プレイリスト';

  @override
  String get playlistsDesktopOnly => 'プレイリストはAndroidでのみ利用可能です。';

  @override
  String get noPlaylistsYet => 'まだプレイリストがありません';

  @override
  String get createFirstPlaylist => '+ボタンをタップして最初のプレイリストを作成';

  @override
  String playlistSongCount(int count) {
    return '$count曲';
  }

  @override
  String get createPlaylist => 'プレイリスト作成';

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get playlistNameHint => 'マイプレイリスト';

  @override
  String get playlistNameRequired => 'プレイリスト名が必要です';

  @override
  String get editPlaylist => 'プレイリスト編集';

  @override
  String get stopPlaybackBeforeEditing => 'プレイリストを編集する前に再生を停止してください';

  @override
  String get selectPreviewSongs => 'プレビュー曲を選択';

  @override
  String get deletePlaylist => 'プレイリスト削除';

  @override
  String deletePlaylistConfirm(String name) {
    return '本当に「$name」を削除しますか？';
  }

  @override
  String get playlistDeleted => 'プレイリストを削除しました';

  @override
  String get errorDeletingPlaylist => 'プレイリスト削除エラー';

  @override
  String get playlistUpdated => 'プレイリストを更新しました';

  @override
  String get changeSong => '曲を変更';

  @override
  String get changeSongConfirm => '現在曲が再生中です。この曲に切り替えますか？';

  @override
  String get changeSongButton => '変更';

  @override
  String playlistProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get noPreviewSongsInPlaylist => 'このプレイリストに利用可能なプレビュー曲がありません';

  @override
  String get tapEditToAddSongs => '編集をタップして、このプレイリストに曲を追加してください';

  @override
  String get noProjectsAvailableForPlaylist => '追加できるプレビュー曲を持つプロジェクトがありません';

  @override
  String get noProjectsInDatabase => 'データベースにプロジェクトが見つかりません。まずプロジェクトを同期してください。';

  @override
  String get firstTimeSyncTitle => '初めてのご利用のようですね！';

  @override
  String get firstTimeSyncMessage => 'Google Driveからデータを同期して始めましょう';

  @override
  String get syncWithGoogleDrive => 'Google Driveと同期';

  @override
  String get errorLoadingPlaylists => 'プレイリスト読み込みエラー';

  @override
  String get playlistItems => 'プレイリスト項目';

  @override
  String get addSongs => '曲を追加';

  @override
  String get addAudioFiles => 'オーディオファイルを追加';

  @override
  String get selectAudioFiles => 'オーディオファイルを選択';

  @override
  String get selectFromProjects => 'プロジェクトから選択';

  @override
  String get add => '追加';

  @override
  String get fromProject => 'プロジェクトから';

  @override
  String get projectDeadline => 'プロジェクトの期限';

  @override
  String get noDeadlineSet => '期限未設定';

  @override
  String get camelotCode => 'キャメロットコード';

  @override
  String get deadline => '期限';

  @override
  String get dueToday => '今日期限';

  @override
  String daysLate(int days) {
    return '$days日遅延';
  }

  @override
  String daysLeft(int days) {
    return '残り$days日';
  }

  @override
  String get hideFinished => '完了を非表示';

  @override
  String get showOnlyDeadlines => '期限を表示';

  @override
  String get filterByDeadline => '期限でフィルタ';

  @override
  String get allDeadlines => 'すべての期限';

  @override
  String get hasDeadline => '期限あり';

  @override
  String get overdue => '期限超過';

  @override
  String get dueSoon => 'もうすぐ期限 (7日)';

  @override
  String get today => '今日';

  @override
  String get noPreviewSong => 'プレビューなし';

  @override
  String get playPreview => 'プレビュー再生';

  @override
  String get uploadCancelled => 'アップロードがキャンセルされました';

  @override
  String get backupUploadCancelledByUser => 'ユーザーによってバックアップのアップロードがキャンセルされました';

  @override
  String get collectingData => 'データを収集中...';

  @override
  String get uploadingPreviewSongs => 'プレビュー曲をアップロード中...';

  @override
  String get uploadingProfilePhotos => 'プロフィール写真をアップロード中...';

  @override
  String get uploadingReleaseArtwork => 'リリースアートワークをアップロード中...';

  @override
  String get uploadingDatabase => 'データベースをアップロード中...';

  @override
  String get completed => '完了！';

  @override
  String get cancelling => 'キャンセル中...';

  @override
  String get uploadingBackupTitle => 'バックアップをアップロード中';

  @override
  String get cancellingUpload => 'アップロードをキャンセル中...';

  @override
  String get pleaseWaitCancellingUpload => 'アップロードを停止していますのでお待ちください...';

  @override
  String get downloadingDatabase => 'データベースをダウンロード中...';

  @override
  String get downloadingPreviewSongs => 'プレビュー曲をダウンロード中...';

  @override
  String get downloadingProfilePhotos => 'プロフィール写真をダウンロード中...';

  @override
  String get downloadingReleaseArtwork => 'リリースアートワークをダウンロード中...';

  @override
  String get mergingData => 'データを統合中...';

  @override
  String get downloadingBackupTitle => 'バックアップをダウンロード中';

  @override
  String get sourceFileNotFoundOnThisMachine => 'このマシンにソースファイルが見つかりません';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'プレビュー曲が利用できません。先にバックアップをダウンロードしてください。';

  @override
  String get sharePreviewSong => 'プレビュー曲を共有';

  @override
  String get shareAsZip => 'ZIPとして共有';

  @override
  String get share => '共有';

  @override
  String get shareZip => 'ZIPを共有';

  @override
  String failedToSharePreviewSong(String error) {
    return 'プレビュー曲を共有できませんでした: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'プレビュー曲をZIPとして共有できませんでした: $error';
  }

  @override
  String get biographySaved => 'プロフィールが保存されました';

  @override
  String failedToSaveBiography(String error) {
    return 'プロフィールを保存できませんでした: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'ファイルを $filename に保存しました';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'ファイルをダウンロードできませんでした: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'すべてのファイルを $filename に保存しました';
  }

  @override
  String get artworkAdded => 'アートワークを追加しました';

  @override
  String failedToAddArtwork(String error) {
    return 'アートワークを追加できませんでした: $error';
  }

  @override
  String get artworkRemoved => 'アートワークを削除しました';

  @override
  String failedToRemoveArtwork(String error) {
    return 'アートワークを削除できませんでした: $error';
  }

  @override
  String get pressKitFileAdded => 'プレスキットファイルを追加しました';

  @override
  String failedToAddPressKitFile(String error) {
    return 'プレスキットファイルを追加できませんでした: $error';
  }

  @override
  String get pressKitFileRemoved => 'プレスキットファイルを削除しました';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'プレスキットファイルを削除できませんでした: $error';
  }

  @override
  String get selectFilesToDownload => 'ダウンロードするファイルを選択';

  @override
  String get biography => 'プロフィール';

  @override
  String get biographyWillBeSaved => 'biography.txt として保存されます';

  @override
  String get artworkFiles => 'アートワークファイル';

  @override
  String get pressKitFiles => 'プレスキットファイル';

  @override
  String get additionalAssets => '追加アセット';

  @override
  String downloadNFiles(int count, String plural) {
    return '$count個のファイル$pluralをダウンロード';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count個のファイル$pluralを $filename に保存しました';
  }

  @override
  String get addAsset => 'アセットを追加';

  @override
  String get assetNameLabel => 'アセット名';

  @override
  String get assetNameHint => '例：ロゴ、バナー、写真';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName を正常に追加しました';
  }

  @override
  String failedToAddAsset(String error) {
    return 'アセットを追加できませんでした: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName を削除しました';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'アセットを削除できませんでした: $error';
  }

  @override
  String get profileNotFound => 'プロフィールが見つかりません';

  @override
  String get selectFiles => 'ファイルを選択';

  @override
  String get downloadAll => 'すべてダウンロード';

  @override
  String get saveBiographyTooltip => 'プロフィールを保存';

  @override
  String get enterBiographyHint => 'プロフィールの経歴を入力...';

  @override
  String get addArtwork => 'アートワークを追加';

  @override
  String get addFile => 'ファイルを追加';

  @override
  String get openFile => 'ファイルを開く';

  @override
  String get menuView => '表示';

  @override
  String get menuAbout => 'DAW Project Manager について';

  @override
  String get menuLanguage => '言語';

  @override
  String get menuWarnBeforeQuit => '終了前に警告する (Cmd+Q)';

  @override
  String get menuQuit => 'DAW Project Manager を終了';

  @override
  String get menuWindow => 'ウィンドウ';

  @override
  String get donate => '寄付';

  @override
  String get website => 'ウェブサイト';

  @override
  String get switchToClassicDark => 'Classic Dark に切り替え';

  @override
  String get switchToNeonDark => 'Neon Dark に切り替え';

  @override
  String get switchToClassicTheme => 'Classic テーマに切り替え';

  @override
  String get switchToNeonTheme => 'Neon テーマに切り替え';

  @override
  String get menuTheme => 'テーマ';

  @override
  String get appDescription =>
      'A project manager for music producers and sound designers.';

  @override
  String get neonDarkThemeName => 'Neon Dark';

  @override
  String get classicDarkThemeName => 'Classic Dark';
}
