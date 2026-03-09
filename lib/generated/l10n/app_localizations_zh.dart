// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DAW项目管理器';

  @override
  String get projectDetails => '项目详情';

  @override
  String get back => '返回';

  @override
  String get save => '保存';

  @override
  String get enable => '启用';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get launch => '打开';

  @override
  String get view => '查看';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get openInDaw => '在DAW中启动';

  @override
  String get extract => '提取';

  @override
  String get extracting => '提取中…';

  @override
  String get extractingMetadata => '正在提取元数据...';

  @override
  String get deepScan => '深度扫描';

  @override
  String get rescan => '重新扫描';

  @override
  String get scanning => '扫描中…';

  @override
  String get projectName => '项目名称';

  @override
  String get bpm => 'BPM';

  @override
  String get key => '调性（例如：C#m，F大调）';

  @override
  String get notes => '备注';

  @override
  String get projectPhase => '项目阶段';

  @override
  String get failedToLoad => '加载失败';

  @override
  String get fileMissing => '文件缺失。';

  @override
  String launchingProject(String projectName) {
    return '正在打开$projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return '无法打开$projectName';
  }

  @override
  String get clearLibrary => '清空库';

  @override
  String get clearLibraryMessage => '这将删除所有保存的项目和源文件夹。继续吗？';

  @override
  String get clear => '清空';

  @override
  String get roots => '项目文件夹';

  @override
  String get pathsSettingsDangerZoneTitle => '库';

  @override
  String get pathsSettingsDangerZoneSubtitle => '清除当前配置文件中的所有项目和项目文件夹。';

  @override
  String get projectFoldersSectionTitle => '项目文件夹';

  @override
  String get projectFoldersSectionSubtitle => '将扫描这些文件夹以查找 DAW 项目。';

  @override
  String get projectFoldersEmptyTitle => '还没有项目文件夹';

  @override
  String get projectFoldersEmptySubtitle => '请至少添加一个文件夹以开始扫描项目。';

  @override
  String get notScannedYet => '尚未扫描';

  @override
  String lastScan(String date) {
    return '上次扫描: $date';
  }

  @override
  String get excludedFoldersSectionTitle => '排除的文件夹';

  @override
  String get excludedFoldersSectionSubtitle => '扫描时将跳过这些文件夹，即使它们位于项目文件夹内。';

  @override
  String get addExcludedFolder => '添加排除';

  @override
  String get selectExcludedFolder => '选择要排除的文件夹';

  @override
  String get excludedFoldersEmptyTitle => '没有排除的文件夹';

  @override
  String get excludedFoldersEmptySubtitle => '可选：添加你永远不想扫描的文件夹。';

  @override
  String get removeExcludedFolderTitle => '移除排除的文件夹？';

  @override
  String removeExcludedFolderMessage(String path) {
    return '该文件夹将不再被排除：\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath => '该文件夹将不再被排除。';

  @override
  String get desktopOnlyPathsSettings => '此页面仅在桌面应用中可用。';

  @override
  String get removeProjectFolderTitle => '移除项目文件夹？';

  @override
  String removeProjectFolderMessage(String path) {
    return '确定要移除「$path」吗？这也会移除该文件夹中未包含在发布中的所有项目。';
  }

  @override
  String get projects => '项目';

  @override
  String get hidden => '隐藏';

  @override
  String get profileManager => '配置文件管理器';

  @override
  String get createNewProfile => '创建新配置文件';

  @override
  String get profileName => '配置文件名称';

  @override
  String get create => '创建';

  @override
  String get profiles => '配置文件';

  @override
  String get active => '活动';

  @override
  String get switchProfile => '切换';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get addFolder => '添加文件夹';

  @override
  String get searchProjects => '搜索项目...';

  @override
  String get searchReleases => '搜索发布...';

  @override
  String get searchPlaylists => '搜索播放列表...';

  @override
  String get noReleasesFound => '未找到发布';

  @override
  String get noPlaylistsFound => '未找到播放列表';

  @override
  String get tryDifferentSearch => '尝试不同的搜索词';

  @override
  String get deepScanTooltip =>
      '深度扫描从项目文件中提取完整的元数据：\n• BPM（每分钟节拍数）\n• 音乐调性\n• DAW版本\n这较慢，但提供完整信息。';

  @override
  String get deepScanConfirm =>
      '这将扫描所有项目并提取完整的元数据（BPM、调性、DAW版本）。这可能需要一些时间。继续吗？';

  @override
  String get metadataExtractedSuccessfully => '元数据提取成功';

  @override
  String failedToExtractMetadata(String error) {
    return '元数据提取失败: $error';
  }

  @override
  String get saved => '已保存';

  @override
  String get failedToLaunchDaw => '无法打开DAW';

  @override
  String get releaseDetails => '发布详情';

  @override
  String get releaseNotFound => '未找到发布';

  @override
  String get error => '错误';

  @override
  String get loading => '加载中...';

  @override
  String get deleteProfile => '删除配置文件';

  @override
  String deleteProfileMessage(String profileName) {
    return '您确定要删除「$profileName」吗？这将删除此配置文件的所有项目、项目文件夹和发布。';
  }

  @override
  String get editProfile => '编辑配置文件';

  @override
  String get changePhoto => '更改照片';

  @override
  String get remove => '删除';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return '您确定要从此发布中删除「$trackName」吗？';
  }

  @override
  String get saveName => '保存名称';

  @override
  String get profilePhotoUpdated => '配置文件照片已更新。';

  @override
  String get profilePhotoRemoved => '配置文件照片已删除。';

  @override
  String profileRenamed(String newName) {
    return '配置文件已重命名为「$newName」';
  }

  @override
  String profileCreated(String name) {
    return '配置文件「$name」创建成功';
  }

  @override
  String profileDeleted(String name) {
    return '配置文件「$name」已删除';
  }

  @override
  String get pleaseEnterProfileName => '请输入配置文件名称';

  @override
  String failedToCreateProfile(String error) {
    return '创建配置文件失败: $error';
  }

  @override
  String get noProfilesFound => '未找到配置文件。请在上面创建一个。';

  @override
  String get clearLibraryTooltip => '清空库（项目和项目文件夹）';

  @override
  String lastModified(String date) {
    return '最后修改: $date';
  }

  @override
  String get name => '名称';

  @override
  String get status => '状态';

  @override
  String get phase => '阶段';

  @override
  String get filterByPhase => '按阶段筛选';

  @override
  String get allPhases => '所有阶段';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => '最后修改';

  @override
  String get actions => '操作';

  @override
  String get hide => '隐藏';

  @override
  String get unhide => '显示';

  @override
  String get extractMetadata => '提取元数据';

  @override
  String get createRelease => '创建发布';

  @override
  String get clearSelection => '清除选择';

  @override
  String get selectAllProjects => '选择所有项目';

  @override
  String get switchingProfiles => '切换配置文件中...';

  @override
  String get scanningProjects => '扫描项目中...';

  @override
  String get search => '搜索';

  @override
  String get projectsTab => '项目';

  @override
  String get releasesTab => '发布';

  @override
  String get showHidden => '显示隐藏';

  @override
  String get showAll => '显示全部';

  @override
  String get showOnlyHidden => '仅显示隐藏';

  @override
  String get deleteRootPath => '移除项目文件夹';

  @override
  String deleteRootPathMessage(String path) {
    return '您确定要删除「$path」吗？这也会删除此文件夹中不在发布中的所有项目。';
  }

  @override
  String rootsCount(int count) {
    return '项目文件夹: $count';
  }

  @override
  String projectsCount(int count) {
    return '项目: $count';
  }

  @override
  String get hiddenOnly => '（仅隐藏）';

  @override
  String hiddenCount(int count) {
    return '（$count个隐藏）';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count个项目$plural已隐藏。';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count个项目$plural已显示。';
  }

  @override
  String failedToHideProjects(String error) {
    return '隐藏项目失败: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return '显示项目失败: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return '您确定要隐藏「$projectName」吗？';
  }

  @override
  String releaseCreated(String title) {
    return '发布「$title」创建成功。';
  }

  @override
  String failedToCreateRelease(String error) {
    return '创建发布失败: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return '添加文件夹错误: $error';
  }

  @override
  String get noProjectsFoundInRoots => '在选定的项目文件夹中未找到项目。';

  @override
  String get selectProjectsFolder => '选择项目文件夹';

  @override
  String get enterReleaseTitle => '输入发布标题';

  @override
  String get releaseTitle => '发布标题';

  @override
  String get enterReleaseTitleHint => '输入发布标题';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return '已为$count个项目$plural提取元数据。$failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count个失败。';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return '写入BPM文件失败: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return '写入调性文件失败: $error';
  }

  @override
  String failedToLaunch(String error) {
    return '启动失败: $error';
  }

  @override
  String get libraryCleared => '库已清空。';

  @override
  String scanType(String type) {
    return '$type扫描';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type完成: $count个项目$plural已添加/更新。';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count个项目$plural已选择';
  }

  @override
  String openingFolder(String projectName) {
    return '正在为$projectName打开文件夹…';
  }

  @override
  String failedToOpenFolder(String error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder => '不支持打开文件夹的操作系统。';

  @override
  String get noProjectsAvailable => '没有可用的项目。请先添加项目。';

  @override
  String get createNewRelease => '创建新发布';

  @override
  String get deleteRelease => '删除发布';

  @override
  String deleteReleaseMessage(String title) {
    return '您确定要删除「$title」吗？';
  }

  @override
  String releaseDeleted(String title) {
    return '发布「$title」已删除。';
  }

  @override
  String get selectTracks => '选择曲目';

  @override
  String get continueButton => '继续';

  @override
  String get noReleasesYet => '还没有发布';

  @override
  String get createFirstRelease => '通过从项目中选择曲目来创建您的第一个发布';

  @override
  String releasesCount(int count) {
    return '发布（$count）';
  }

  @override
  String errorLoadingReleases(String error) {
    return '加载发布错误: $error';
  }

  @override
  String tracksCount(int count) {
    return '曲目（$count）';
  }

  @override
  String get addTracks => '添加曲目';

  @override
  String get allProjectsAlreadyInRelease => '所有项目已在此发布中。';

  @override
  String addedTracksToRelease(int count, String plural) {
    return '已向发布添加$count首曲目$plural。';
  }

  @override
  String releaseFilesCount(int count) {
    return '发布文件（$count）';
  }

  @override
  String get addFiles => '添加文件';

  @override
  String addedFilesToRelease(int count, String plural) {
    return '已向发布添加$count个文件$plural。';
  }

  @override
  String failedToAddFiles(String error) {
    return '添加文件失败: $error';
  }

  @override
  String get noFilesToDownload => '没有要下载的文件。';

  @override
  String zipFileSaved(String path) {
    return 'ZIP文件已保存到: $path';
  }

  @override
  String get creatingZipFile => '正在创建ZIP文件...';

  @override
  String failedToCreateZip(String error) {
    return '创建ZIP失败: $error';
  }

  @override
  String get selectedFileDoesNotExist => '所选文件不存在。';

  @override
  String get imageSavedSuccessfully => '图像保存成功！';

  @override
  String failedToSaveImage(String error) {
    return '保存图像失败: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return '加载发布错误: $error';
  }

  @override
  String get errorLoadingProjects => '加载项目错误: null';

  @override
  String get releaseSaved => '发布已保存。';

  @override
  String get releaseDate => '发布日期';

  @override
  String failedToSaveReleaseDate(String error) {
    return '保存发布日期失败: $error';
  }

  @override
  String get releaseDateSaved => '发布日期已保存。';

  @override
  String get releaseDateCleared => '发布日期已清除。';

  @override
  String get saveReleaseFilesZip => '保存发布文件ZIP';

  @override
  String get failedToOpenFile => '无法打开文件';

  @override
  String failedToPlayAudio(String error) {
    return '播放音频失败: $error';
  }

  @override
  String get renameFile => '重命名文件';

  @override
  String get selectTracksToAdd => '选择要添加的曲目';

  @override
  String get fileNameUpdated => '文件名已更新。';

  @override
  String errorUpdatingFileName(String error) {
    return '更新文件名错误: $error';
  }

  @override
  String get deleteFile => '删除文件';

  @override
  String deleteFileMessage(String fileName) {
    return '您确定要删除「$fileName」吗？';
  }

  @override
  String fileDeleted(String fileName) {
    return '文件「$fileName」已删除。';
  }

  @override
  String failedToDeleteFile(String error) {
    return '删除文件失败: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return '无法打开文件夹: $error';
  }

  @override
  String get artwork => '封面';

  @override
  String get title => '标题';

  @override
  String get tracks => '曲目';

  @override
  String get description => '描述';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return '选择要包含在发布中的曲目（已选择$count）';
  }

  @override
  String get searchTracks => '搜索曲目';

  @override
  String get searchTracksHint => '按名称或DAW类型搜索';

  @override
  String get noTracksFound => '未找到曲目';

  @override
  String get unknown => '未知';

  @override
  String get fileNotFound => '文件未找到';

  @override
  String get fileName => '文件名';

  @override
  String get editTodo => '编辑待办事项';

  @override
  String get todoText => '待办事项文本';

  @override
  String get enterTodoText => '输入待办事项文本';

  @override
  String get addNewTodo => '添加新待办事项';

  @override
  String get enterTodoItem => '输入待办事项项';

  @override
  String get todoList => '待办事项列表';

  @override
  String get todoTemplates => 'TODO模板';

  @override
  String get createTemplate => '创建模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String deleteTemplateConfirm(String name) {
    return '确定要删除模板「$name」吗？';
  }

  @override
  String get templateName => '模板名称';

  @override
  String get templateNameHint => '例如：混音清单';

  @override
  String get templateItems => '模板项目';

  @override
  String get templateItemsHint => '每行一个项目';

  @override
  String get templateNameAndItemsRequired => '模板名称和项目是必需的';

  @override
  String get templateItemsRequired => '至少需要一个项目';

  @override
  String get templateCreated => '模板已创建';

  @override
  String get templateUpdated => '模板已更新';

  @override
  String get templateDeleted => '模板已删除';

  @override
  String get noTemplatesYet => '还没有模板';

  @override
  String get createFirstTemplate => '创建您的第一个TODO模板';

  @override
  String templateItemCount(int count) {
    return '$count个项目';
  }

  @override
  String get selectTemplate => '选择模板';

  @override
  String get importFromTemplate => '从模板导入';

  @override
  String get manageTemplates => '管理模板';

  @override
  String get noTemplatesAvailable => '没有可用的模板。请先创建一个。';

  @override
  String templateImported(String name, int count) {
    return '模板「$name」已导入（$count个项目）';
  }

  @override
  String get errorLoadingTemplates => '加载模板错误';

  @override
  String get importTodos => '从文件导入待办事项';

  @override
  String get noTodosInFile => '文件中未找到待办事项';

  @override
  String todosImported(int count) {
    return '成功导入了$count个待办事项';
  }

  @override
  String errorImportingTodos(String error) {
    return '导入错误: $error';
  }

  @override
  String get addToRelease => '添加到发布';

  @override
  String get createNew => '创建新';

  @override
  String get addToExisting => '添加到现有';

  @override
  String get createAndAdd => '创建并添加';

  @override
  String get selectRelease => '选择发布';

  @override
  String get noExistingReleasesFound => '未找到现有发布。';

  @override
  String get addToSelectedRelease => '添加到选定的发布';

  @override
  String failedToSaveProfilePhoto(String error) {
    return '保存配置文件照片失败: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return '删除配置文件照片失败: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return '重命名配置文件失败: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return '删除配置文件失败: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return '加载配置文件错误: $error';
  }

  @override
  String get projectPhaseIdea => '想法';

  @override
  String get projectPhaseArranging => '编曲';

  @override
  String get projectPhaseMixing => '混音';

  @override
  String get projectPhaseMastering => '母带处理';

  @override
  String get projectPhaseFinished => '完成';

  @override
  String get changeStatus => '更改阶段';

  @override
  String get selectNewStatus => '选择新阶段:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return '$count 个项目$plural的阶段已更改为「$status」';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return '$successCount 个项目$successPlural的阶段已更改为「$status」，$failCount 个失败$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return '更改阶段失败: $error';
  }

  @override
  String get tooltipEditProfileName => '编辑配置文件名称';

  @override
  String get tooltipAddTodo => '添加待办事项';

  @override
  String get tooltipClearDate => '清除日期';

  @override
  String get tooltipPickDate => '选择日期';

  @override
  String get tooltipViewDetails => '查看详情';

  @override
  String get tooltipLaunchInDaw => '在DAW中打开';

  @override
  String get tooltipRemoveFromRelease => '从发布中移除';

  @override
  String get profile => '配置文件';

  @override
  String get noDateSet => '未设置日期';

  @override
  String get imageNotFound => '未找到图像';

  @override
  String get clickToBrowseArtwork => '点击浏览封面';

  @override
  String get noFilesAddedYet => '尚未添加文件。\n点击\"添加文件\"上传发布文件。';

  @override
  String get noTodosYet => '还没有待办事项。请在上面添加一个。';

  @override
  String get done => '完成';

  @override
  String get backupAndRestore => '备份和恢复';

  @override
  String get exportBackup => '导出备份';

  @override
  String get importBackup => '导入备份';

  @override
  String get backupExportedSuccessfully => '备份导出成功';

  @override
  String failedToExportBackup(String error) {
    return '导出备份失败: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '备份导入成功: $projectsCount 个项目，$rootsCount 个项目文件夹，$releasesCount 个发布';
  }

  @override
  String failedToImportBackup(String error) {
    return '导入备份失败: $error';
  }

  @override
  String get importBackupMessage => '选择如何导入备份:';

  @override
  String get mergeWithCurrentProfile => '与当前活动配置文件合并';

  @override
  String get replaceCurrentProfile => '完全替换当前配置文件（警告：这将删除当前配置文件的所有数据）';

  @override
  String get createNewProfileForImport => '为此数据创建新配置文件';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '备份已导入到新配置文件 \"$profileName\": $projectsCount 个项目，$rootsCount 个项目文件夹，$releasesCount 个发布';
  }

  @override
  String get noProfileSelected => '未选择配置文件';

  @override
  String get exportBackupDialogTitle => '导出备份';

  @override
  String get importBackupDialogTitle => '导入备份';

  @override
  String get invalidBackupFileFormat => '无效的备份文件格式: 缺少版本';

  @override
  String get profileNameRequiredForNewProfile => '创建新配置文件时需要配置文件名称';

  @override
  String get currentProfileRequired => '合并或替换模式需要当前配置文件';

  @override
  String get previewSong => '预览歌曲';

  @override
  String get previewSongRemoved => '预览歌曲已删除';

  @override
  String get previewSongAdded => '预览歌曲已添加';

  @override
  String get previewSongFileNotFound => '未找到预览歌曲文件';

  @override
  String failedToPlayPreview(String error) {
    return '播放预览失败: $error';
  }

  @override
  String get removePreviewSong => '删除预览歌曲';

  @override
  String get removePreviewSongConfirm => '您确定要删除预览歌曲吗？此操作无法撤销。';

  @override
  String get noPreviewSongSelected => '未选择预览歌曲';

  @override
  String get changePreviewSong => '更改预览歌曲';

  @override
  String get selectPreviewSong => '选择预览歌曲';

  @override
  String get dropAudioFileHere => '将音频文件拖放到此处';

  @override
  String projectAge(String age) {
    return '项目年龄: $age';
  }

  @override
  String createdDate(String date) {
    return '创建于 $date';
  }

  @override
  String completedIn(String duration) {
    return '完成耗时: $duration';
  }

  @override
  String finishedDate(String date) {
    return '完成于 $date';
  }

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天前',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count周前',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个月前',
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
    return '$years年$months个月';
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
    return '$months个月$days天';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months个月';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days天';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours小时';
  }

  @override
  String get ageJustNow => '刚刚';

  @override
  String get ageLessThanHour => '不到一小时';

  @override
  String get viewProfile => '查看个人资料';

  @override
  String get googleDriveSync => 'Google Drive 同步';

  @override
  String get googleDriveSyncDescription =>
      '将您的数据与 Google Drive 同步，以便在设备之间备份和恢复。';

  @override
  String get manageGoogleDriveSync => '管理 Google Drive 同步';

  @override
  String get signInToGoogleDrive => '登录 Google Drive';

  @override
  String get syncNow => '立即同步';

  @override
  String get uploadBackup => '上传备份';

  @override
  String get downloadBackup => '下载备份';

  @override
  String get newerBackupAvailable => '云端有新备份可用';

  @override
  String get signOut => '退出';

  @override
  String get downloadPreviewSongs => '下载预览歌曲';

  @override
  String get downloadPreviewSongsExplanation =>
      '如果未选中，将跳过预览歌曲（节省时间和存储空间）。如果需要，您可以稍后下载它们。';

  @override
  String get replaceLocalData => '替换本地数据';

  @override
  String get downloadBackupConfirmation =>
      '这将用 Google Drive 的备份替换您的本地数据。\n\n您确定要继续吗？';

  @override
  String get enterAuthorizationCode => '输入授权代码';

  @override
  String get authorizationCode => '授权代码';

  @override
  String get pasteCodeFromBrowser => '从浏览器粘贴代码';

  @override
  String get sessionActive => '会话活跃';

  @override
  String get signedIn => '已登录';

  @override
  String get creatingInitialBackup => '正在创建初始备份...';

  @override
  String get successfullySignedInAndBackedUp => '成功登录并备份到 Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage => '成功登录并备份到 Google Drive！';

  @override
  String get successfullySignedInToGoogleDrive => '成功登录到 Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage => '成功登录到 Google Drive！';

  @override
  String get signInCancelledOrFailed => '登录已取消或失败。请查看控制台了解详细信息。';

  @override
  String get failedToLaunchBrowser => '无法启动浏览器';

  @override
  String get signInCancelled => '登录已取消';

  @override
  String get failedToExchangeAuthorizationCode => '无法交换授权代码';

  @override
  String errorSigningIn(String error) {
    return '登录错误: $error';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get googleSignInError => 'Google 登录错误';

  @override
  String get developerConsoleNotSetUp =>
      '开发者控制台未正确设置。请在 Google Cloud Console 中检查您的 OAuth 配置。';

  @override
  String get platformError => '平台错误';

  @override
  String get signedOutFromGoogleDrive => '已退出 Google Drive';

  @override
  String errorSigningOut(String error) {
    return '退出错误: $error';
  }

  @override
  String get syncing => '同步中...';

  @override
  String get errorNoProfileSelected => '错误: 未选择个人资料';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '同步完成！项目: +$projectsAdded ~$projectsUpdated，发布: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return '同步错误: $error';
  }

  @override
  String get uploadingBackup => '正在上传备份...';

  @override
  String get backupUploadedSuccessfully => '备份上传成功！';

  @override
  String get backupUploadedSuccessfullyMessage => '备份已成功上传到 Google Drive！';

  @override
  String errorUploadingBackup(String error) {
    return '上传备份错误: $error';
  }

  @override
  String get downloadingBackup => '正在下载备份...';

  @override
  String get checkingForBackup => '正在检查备份...';

  @override
  String get backupUpToDate => '备份是最新的';

  @override
  String errorCheckingBackup(String error) {
    return '检查备份错误: $error';
  }

  @override
  String get download => '下载';

  @override
  String get remoteBackupIsNewer => '远程备份比本地数据更新。上传将覆盖它。';

  @override
  String get confirmUpload => '确认上传';

  @override
  String get noBackupFileFound => '在 Google Drive 中未找到备份文件。请先通过同步数据创建备份。';

  @override
  String get noBackupFileFoundStatus => '未找到备份文件。请先创建备份。';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '备份已下载！项目: +$projectsAdded ~$projectsUpdated，发布: +$releasesAdded ~$releasesUpdated';
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
    return '备份已下载!\n\n项目:\n  • $projectsAdded 已添加\n  • $projectsUpdated 已更新\n\n发布:\n  • $releasesAdded 已添加\n  • $releasesUpdated 已更新\n\n预览歌曲:\n  • $previewSongsDownloaded 已下载\n  • $previewSongsUpdated 已更新';
  }

  @override
  String errorDownloadingBackup(String error) {
    return '下载备份错误: $error';
  }

  @override
  String signedInAs(String email) {
    return '登录为: $email';
  }

  @override
  String lastSync(String date) {
    return '最后同步: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return '远程备份: $date';
  }

  @override
  String lastUploadTime(String date) {
    return '上次上传: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return '上次下载: $date';
  }

  @override
  String get checkForBackup => '检查备份';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get notificationsOnlyOnAndroid => '截止日期通知仅在Android设备上可用。';

  @override
  String get notificationPermissionRequired => '需要通知权限';

  @override
  String get notificationPermissionDescription => '请启用通知以接收截止日期提醒。';

  @override
  String get notificationPermissionDenied => '通知权限被拒绝。请在设置中启用。';

  @override
  String get notificationSettingsSaved => '通知设置已成功保存';

  @override
  String get errorSavingSettings => '保存设置时出错';

  @override
  String get enableDeadlineNotifications => '启用截止日期通知';

  @override
  String get receiveRemindersForDeadlines => '接收项目截止日期提醒';

  @override
  String get notificationTime => '通知时间';

  @override
  String get timeToReceiveNotifications => '接收通知的时间';

  @override
  String get reminderDays => '提醒天数';

  @override
  String get selectDaysBeforeDeadline => '选择在截止日期前多少天收到通知';

  @override
  String get notifyOnDeadlineDay => '在截止日期当天通知';

  @override
  String get receiveNotificationOnDeadlineDay => '在截止日期当天也接收通知';

  @override
  String get howItWorks => '工作原理';

  @override
  String get deadlineNotificationsHelp =>
      '您将在每个项目截止日期前的选定天数在指定时间收到通知。点击通知以打开项目详情。';

  @override
  String get oneDay => '1天';

  @override
  String xDays(int count) {
    return '$count天';
  }

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get support => '支持';

  @override
  String get supportTheProject => '支持项目';

  @override
  String couldNotOpenBrowser(String url) {
    return '无法打开浏览器。请访问: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return '打开浏览器时出错: $error';
  }

  @override
  String get generateTestingDatabase => '生成测试数据库';

  @override
  String get generateTestingDatabaseMessage => '这将用示例项目和发布填充数据库以进行测试。继续吗？';

  @override
  String get testingDatabaseGenerated => '测试数据库生成成功！';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return '生成测试数据库失败: $error';
  }

  @override
  String get playlists => '播放列表';

  @override
  String get playlistsDesktopOnly => '播放列表仅在Android上可用。';

  @override
  String get noPlaylistsYet => '还没有播放列表';

  @override
  String get createFirstPlaylist => '点击+按钮创建您的第一个播放列表';

  @override
  String playlistSongCount(int count) {
    return '$count首歌曲';
  }

  @override
  String get createPlaylist => '创建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get playlistNameHint => '我的播放列表';

  @override
  String get playlistNameRequired => '需要播放列表名称';

  @override
  String get editPlaylist => '编辑播放列表';

  @override
  String get stopPlaybackBeforeEditing => '请在编辑播放列表之前停止播放';

  @override
  String get selectPreviewSongs => '选择预览歌曲';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String deletePlaylistConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get playlistDeleted => '播放列表已删除';

  @override
  String get errorDeletingPlaylist => '删除播放列表错误';

  @override
  String get playlistUpdated => '播放列表已更新';

  @override
  String get changeSong => '更换歌曲';

  @override
  String get changeSongConfirm => '当前正在播放歌曲。是否要切换到这首歌曲？';

  @override
  String get changeSongButton => '更换';

  @override
  String playlistProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get noPreviewSongsInPlaylist => '此播放列表中没有预览歌曲';

  @override
  String get tapEditToAddSongs => '点击编辑以向此播放列表添加歌曲';

  @override
  String get noProjectsAvailableForPlaylist => '没有可添加的预览歌曲项目';

  @override
  String get noProjectsInDatabase => '数据库中未找到项目。请先同步您的项目。';

  @override
  String get firstTimeSyncTitle => '看起来这是您第一次来这里！';

  @override
  String get firstTimeSyncMessage => '让我们从Google云端硬盘同步您的数据以开始使用';

  @override
  String get syncWithGoogleDrive => '与Google云端硬盘同步';

  @override
  String get errorLoadingPlaylists => '加载播放列表错误';

  @override
  String get playlistItems => '播放列表项目';

  @override
  String get addSongs => '添加歌曲';

  @override
  String get addAudioFiles => '添加音频文件';

  @override
  String get selectAudioFiles => '选择音频文件';

  @override
  String get selectFromProjects => '从项目中选择';

  @override
  String get add => '添加';

  @override
  String get fromProject => '来自项目';

  @override
  String get projectDeadline => '项目截止日期';

  @override
  String get noDeadlineSet => '未设置截止日期';

  @override
  String get camelotCode => 'Camelot代码';

  @override
  String get deadline => '截止日期';

  @override
  String get dueToday => '今天到期';

  @override
  String daysLate(int days) {
    return '$days天延期';
  }

  @override
  String daysLeft(int days) {
    return '剩余$days天';
  }

  @override
  String get hideFinished => '隐藏已完成';

  @override
  String get showOnlyDeadlines => '显示截止日期';

  @override
  String get filterByDeadline => '按截止日期筛选';

  @override
  String get allDeadlines => '所有截止日期';

  @override
  String get hasDeadline => '有截止日期';

  @override
  String get overdue => '逾期';

  @override
  String get dueSoon => '即将到期 (7天)';

  @override
  String get today => '今天';

  @override
  String get noPreviewSong => '无预览';

  @override
  String get playPreview => '播放预览';

  @override
  String get uploadCancelled => '上传已取消';

  @override
  String get backupUploadCancelledByUser => '用户取消了备份上传';

  @override
  String get collectingData => '正在收集数据...';

  @override
  String get uploadingPreviewSongs => '正在上传预览歌曲...';

  @override
  String get uploadingProfilePhotos => '正在上传个人资料照片...';

  @override
  String get uploadingReleaseArtwork => '正在上传发行封面...';

  @override
  String get uploadingDatabase => '正在上传数据库...';

  @override
  String get completed => '完成！';

  @override
  String get cancelling => '正在取消...';

  @override
  String get uploadingBackupTitle => '正在上传备份';

  @override
  String get cancellingUpload => '正在取消上传...';

  @override
  String get pleaseWaitCancellingUpload => '请稍候，我们正在停止上传...';

  @override
  String get downloadingDatabase => '正在下载数据库...';

  @override
  String get downloadingPreviewSongs => '正在下载预览歌曲...';

  @override
  String get downloadingProfilePhotos => '正在下载个人资料照片...';

  @override
  String get downloadingReleaseArtwork => '正在下载发行封面...';

  @override
  String get mergingData => '正在合并数据...';

  @override
  String get downloadingBackupTitle => '正在下载备份';

  @override
  String get sourceFileNotFoundOnThisMachine => '在此设备上找不到源文件';

  @override
  String get previewSongNotAvailableDownloadFirst => '预览歌曲不可用。请先下载备份。';

  @override
  String get sharePreviewSong => '分享预览歌曲';

  @override
  String get shareAsZip => '以ZIP格式分享';

  @override
  String get share => '分享';

  @override
  String get shareZip => '分享ZIP';

  @override
  String get saveCopy => '保存副本';

  @override
  String savedCopyTo(String path) {
    return '已保存到 $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return '无法分享预览歌曲：$error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return '无法以ZIP格式分享预览歌曲：$error';
  }

  @override
  String get biographySaved => '简介已保存';

  @override
  String failedToSaveBiography(String error) {
    return '无法保存简介：$error';
  }

  @override
  String fileSavedTo(String filename) {
    return '文件已保存至 $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return '无法下载文件：$error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return '所有文件已保存至 $filename';
  }

  @override
  String get artworkAdded => '封面已添加';

  @override
  String failedToAddArtwork(String error) {
    return '无法添加封面：$error';
  }

  @override
  String get artworkRemoved => '封面已删除';

  @override
  String failedToRemoveArtwork(String error) {
    return '无法删除封面：$error';
  }

  @override
  String get pressKitFileAdded => '新闻资料袋文件已添加';

  @override
  String failedToAddPressKitFile(String error) {
    return '无法添加新闻资料袋文件：$error';
  }

  @override
  String get pressKitFileRemoved => '新闻资料袋文件已删除';

  @override
  String failedToRemovePressKitFile(String error) {
    return '无法删除新闻资料袋文件：$error';
  }

  @override
  String get selectFilesToDownload => '选择要下载的文件';

  @override
  String get biography => '简介';

  @override
  String get biographyWillBeSaved => '将保存为 biography.txt';

  @override
  String get artworkFiles => '封面文件';

  @override
  String get pressKitFiles => '新闻资料袋文件';

  @override
  String get additionalAssets => '附加资源';

  @override
  String downloadNFiles(int count, String plural) {
    return '下载 $count 个文件$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count 个文件$plural已保存至 $filename';
  }

  @override
  String get addAsset => '添加资源';

  @override
  String get assetNameLabel => '资源名称';

  @override
  String get assetNameHint => '例如：Logo、横幅、照片';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName 已成功添加';
  }

  @override
  String failedToAddAsset(String error) {
    return '无法添加资源：$error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName 已删除';
  }

  @override
  String failedToRemoveAsset(String error) {
    return '无法删除资源：$error';
  }

  @override
  String get profileNotFound => '找不到个人资料';

  @override
  String get selectFiles => '选择文件';

  @override
  String get downloadAll => '全部下载';

  @override
  String get saveBiographyTooltip => '保存简介';

  @override
  String get enterBiographyHint => '输入个人简介...';

  @override
  String get addArtwork => '添加封面';

  @override
  String get addFile => '添加文件';

  @override
  String get openFile => '打开文件';

  @override
  String get menuView => '视图';

  @override
  String get menuAbout => '关于 DAW Project Manager';

  @override
  String get menuLanguage => '语言';

  @override
  String get menuWarnBeforeQuit => '退出前警告 (Cmd+Q)';

  @override
  String get menuQuit => '退出 DAW Project Manager';

  @override
  String get menuWindow => '窗口';

  @override
  String get donate => '捐赠';

  @override
  String get website => '网站';

  @override
  String get switchToClassicDark => '切换到 Classic Dark';

  @override
  String get switchToNeonDark => '切换到 Neon Dark';

  @override
  String get switchToClassicTheme => '切换到经典主题';

  @override
  String get switchToNeonTheme => '切换到霓虹主题';

  @override
  String get menuTheme => '主题';

  @override
  String get appDescription => '面向音乐制作人和音效设计师的项目管理工具。';

  @override
  String get neonDarkThemeName => '霓虹暗色';

  @override
  String get classicDarkThemeName => '经典暗色';

  @override
  String get statisticsTab => '统计';

  @override
  String get statsTotalProjects => '总项目数';

  @override
  String get statsInProgress => '进行中';

  @override
  String get statsFinished => '已完成';

  @override
  String get statsAvgCompletion => '平均完成时间';

  @override
  String get statsPhaseDistribution => '各阶段项目';

  @override
  String get statsAvgTimePerPhase => '每阶段平均天数';

  @override
  String get statsProductivity => '生产力';

  @override
  String get statsCreatedSeries => '已创建';

  @override
  String get statsProjectHealth => '项目年龄与健康';

  @override
  String get statsCatalogInsights => '目录洞察';

  @override
  String get statsBpmDistribution => 'BPM分布';

  @override
  String get statsTopKeys => '热门音乐调式';

  @override
  String get statsDawTypes => 'DAW类型';

  @override
  String get statsProjectActivity => '项目活动';

  @override
  String get statsNoData => '暂无数据';

  @override
  String get statsNoPhaseData => '项目变更阶段后将显示数据。';

  @override
  String statsLastActivityDaysAgo(int days) {
    return '最近活动: $days天前';
  }

  @override
  String get statsLastActivityToday => '今日活跃';

  @override
  String get statsNoEvents => '暂无事件记录';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return '阶段: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return '已更新: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return '已完成: $text';
  }

  @override
  String get statsEventFileModified => '磁盘上的文件已修改';

  @override
  String get statsClearHistory => '清除历史';

  @override
  String get statsClearHistoryConfirm => '清除此项目的所有记录事件？';

  @override
  String get statsSearchProjects => '搜索项目…';

  @override
  String statsEventCount(int count) {
    return '$count个事件';
  }

  @override
  String get statsViewHistory => '项目统计';

  @override
  String get statsPhaseHistory => '阶段历史';

  @override
  String get statsEventBreakdown => '事件概览';

  @override
  String statsDaysSoFar(int days) {
    return '已$days天';
  }

  @override
  String get statsNoProjectsFound => '未找到项目';

  @override
  String statsNotTouchedDays(int days) {
    return '$days天未修改';
  }
}
