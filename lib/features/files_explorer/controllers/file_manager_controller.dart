import 'dart:async';
import 'dart:io' hide File, Directory, FileSystemEntity, FileSystemException;
import 'package:file/file.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

enum SortBy { name, modTime, accessedTime, type, size }

class FileManagerController {
  final ValueNotifier<String> _path = ValueNotifier<String>('');
  final ValueNotifier<SortBy> _sort = ValueNotifier<SortBy>(SortBy.name);
  final ValueNotifier<List<FileSystemEntity>> paginatedEntities =
      ValueNotifier<List<FileSystemEntity>>([]);

  static const int _pageSize = 20;

  final List<FileSystemEntity> _allEntities = [];
  List<FileSystemEntity> _filteredEntities = [];

  int _visibleCount = _pageSize;
  final Map<String, int> _visibleCounts = {};

  List<FileSystemEntity> get filteredEntities =>
      List.unmodifiable(_filteredEntities);

  bool _ascending = true;
  bool get isAscending => _ascending;

  bool get hasSortApplied => _hasSortApplied;
  bool _hasSortApplied = false;

  SortBy get sortedBy => _sort.value;

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  Timer? _debounce;

  bool showHiddenFiles = false;

  void _updatePath(String path) {
    if (_path.value.isNotEmpty) {
      _visibleCounts[_path.value] = _visibleCount;
    }
    _visibleCounts.removeWhere((savedPath, _) => p.isWithin(path, savedPath));
    _path.value = path;
  }

  String? newFolderPath;

  /// Mark the given folder path as the "new" folder and refresh the list.
  /// Call this *before* reloading so the UI can place it at the top immediately.
  void markNewFolder(String path) {
    newFolderPath = path;
    // Re-apply sort/filter so UI picks up this change
    _applySearchFilter();
  }

  /// Clear the "new folder" flag (e.g. when rename overlay closes)
  void clearNewFolder() {
    newFolderPath = null;
    _applySearchFilter();
  }

  String? _renamingPath;
  String? _renamingValue;

  void setLiveRename(String path, String value) {
    _renamingPath = path;
    _renamingValue = value;
    _applySearchFilter();
  }

  void clearLiveRename() {
    _renamingPath = null;
    _renamingValue = null;
    _applySearchFilter();
  }

  String getDisplayName(FileSystemEntity entity) {
    if (entity.path == _renamingPath && _renamingValue != null) {
      return _renamingValue!;
    }
    return p.basename(entity.path);
  }

  /// ValueNotifier of the current directory's basename
  ///
  /// ie:
  /// ```dart
  /// ValueListenableBuilder<String>(
  ///    valueListenable: controller.titleNotifier,
  ///    builder: (context, title, _) {
  ///     return Text(title);
  ///   },
  /// ),
  /// ```
  final ValueNotifier<String> titleNotifier = ValueNotifier<String>('');

  /// Get ValueNotifier of path
  ValueNotifier<String> get getPathNotifier => _path;

  /// Get ValueNotifier of SortedBy
  ValueNotifier<SortBy> get getSortedByNotifier => _sort;

  /// The sorting type that is currently in use is returned.
  SortBy get getSortedBy => _sort.value;

  /// [setSortedBy] is used to set the sorting type.
  ///
  /// `SortBy{ name, type, date, size }`
  /// ie: `controller.sortBy(SortBy.date)`
  // void sortBy(SortBy sortType) => _sort.value = sortType;

  /// Get current Directory.
  Directory get getCurrentDirectory =>
      AppFileSystem.instance.directory(_path.value);

  /// Get current path, similar to [getCurrentDirectory].
  String get getCurrentPath => _path.value;

  /// Set current directory path by providing string of path, similar to [openDirectory].
  set setCurrentPath(String path) {
    _updatePath(path);
  }

  /// return true if current directory is the root. false, if the current directory not on root of the stogare.
  Future<bool> isRootDirectory() async {
    final List<Directory> storageList = (await getStorageList());
    return (storageList
        .where(
          (element) =>
              element.path ==
              AppFileSystem.instance.directory(_path.value).path,
        )
        .isNotEmpty);
  }

  /// Get list of available storage in the device
  /// returns an empty list if there is no storage
  static Future<List<Directory>> getStorageList() async {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return [AppFileSystem.instance.directory(home)];
      }
      return [AppFileSystem.instance.directory('/')]; // final fallback
    }
    return [];
  }

  /// Jumps to the parent directory of currently opened directory if the parent is accessible.
  Future<void> goToParentDirectory() async {
    if (!(await isRootDirectory())) {
      openDirectory(AppFileSystem.instance.directory(_path.value).parent);
    }
  }

  /// Open a directory and initialize pagination
  Future<void> openDirectory(FileSystemEntity entity) async {
    if (entity is! Directory) {
      throw Exception('Please provide a Directory');
    }

    _updatePath(entity.path);

    _searchQuery.value = '';

    try {
      _allEntities.clear();

      final contents =
          await entity.list(recursive: false, followLinks: false).toList();

      _allEntities.addAll(contents);
      _visibleCount = _visibleCounts[entity.path] ?? _pageSize;
      _applySearchFilter();
    } catch (e, st) {
      AppLogger.e('Error loading directory ${entity.path}: $e\n$st');

      paginatedEntities.value = [];
    }
  }

  /// Load next page of files and emit via StreamController
  void loadNextChunk() {
    if (_visibleCount >= _filteredEntities.length) {
      return;
    }

    _visibleCount += _pageSize;
    _emitVisibleItems();
  }

  void _emitVisibleItems() {
    final count = _visibleCount.clamp(0, _filteredEntities.length);

    paginatedEntities.value = _filteredEntities.take(count).toList();
  }

  void toggleShowHiddenFiles() {
    showHiddenFiles = !showHiddenFiles;
    reload(); // Reapply filtering
  }

  void sortBy(SortBy sortBy, {bool? isAscending}) {
    _hasSortApplied = true;
    // If tapping same field → toggle
    if (sortBy == _sort.value) {
      _ascending = isAscending ?? !_ascending;
    } else {
      // New field → default ascending unless specified
      _ascending = isAscending ?? true;
    }

    _sort.value = sortBy;
    _applySearchFilter();
  }

  List<FileSystemEntity> _sortEntities(List<FileSystemEntity> list) {
    final Map<String, int> sizeMap = {};
    list.sort((a, b) {
      final aName = p.basename(a.path).toLowerCase();
      final bName = p.basename(b.path).toLowerCase();

      switch (_sort.value) {
        case SortBy.name:
          // Group folders first
          if (a is Directory && b is! Directory) return -1;
          if (b is Directory && a is! Directory) return 1;

          // If both are the same type, sort by name
          return _ascending ? aName.compareTo(bName) : bName.compareTo(aName);

        case SortBy.type:
          if (a is Directory && b is! Directory) return -1;
          if (b is Directory && a is! Directory) return 1;

          // Same type
          final aType = a is Directory ? 'dir' : p.extension(a.path);
          final bType = b is Directory ? 'dir' : p.extension(b.path);
          final typeCompare =
              _ascending ? aType.compareTo(bType) : bType.compareTo(aType);
          if (typeCompare != 0) return typeCompare;

          // Secondary: by name
          final aName = p.basename(a.path).toLowerCase();
          final bName = p.basename(b.path).toLowerCase();
          return _ascending ? aName.compareTo(bName) : bName.compareTo(aName);

        case SortBy.size:
          if (_ascending) {
            // Group folders first
            if (a is Directory && b is! Directory) return -1;
            if (b is Directory && a is! Directory) return 1;

            // Only compare files by size
            if (a is File && b is File) {
              sizeMap[a.path] ??= a.lengthSync();
              sizeMap[b.path] ??= b.lengthSync();
              final aSize = sizeMap[a.path]!;
              final bSize = sizeMap[b.path]!;
              return aSize.compareTo(bSize); // ascending
            }

            // If both are directories, sort alphabetically
            final aName = p.basename(a.path).toLowerCase();
            final bName = p.basename(b.path).toLowerCase();
            return aName.compareTo(bName);
          } else {
            // Group folders last
            if (a is Directory && b is! Directory) return 1;
            if (b is Directory && a is! Directory) return -1;

            // Only compare files by size
            if (a is File && b is File) {
              sizeMap[a.path] ??= a.lengthSync();
              sizeMap[b.path] ??= b.lengthSync();
              final aSize = sizeMap[a.path]!;
              final bSize = sizeMap[b.path]!;
              return bSize.compareTo(aSize); // descending
            }

            // If both are directories, sort alphabetically
            final aName = p.basename(a.path).toLowerCase();
            final bName = p.basename(b.path).toLowerCase();
            return aName.compareTo(bName);
          }

        case SortBy.modTime:
          final aTime = a.statSync().modified;
          final bTime = b.statSync().modified;
          return _ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);

        case SortBy.accessedTime:
          final aTime = a.statSync().accessed;
          final bTime = b.statSync().accessed;
          return _ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);

        default:
          return 0;
      }
    });

    return list;
  }

  void search(String query, {bool recursive = false}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final trimmedQuery = query.trim().toLowerCase();
      _searchQuery.value = trimmedQuery;

      if (trimmedQuery.isEmpty) {
        // Reset to normal paginated view
        _applySearchFilter();
        return;
      }

      // Perform filtering or recursive search
      if (recursive) {
        await _searchRecursively(trimmedQuery);
      } else {
        _applySearchFilter();
      }
    });
  }

  void _applySearchFilter() {
    List<FileSystemEntity> list = List<FileSystemEntity>.from(_allEntities);

    if (!showHiddenFiles) {
      list =
          list.where((entity) {
            return !p.basename(entity.path).startsWith('.');
          }).toList();
    }

    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value;

      list =
          list.where((entity) {
            return p.basename(entity.path).toLowerCase().contains(query);
          }).toList();
    }

    list = _sortEntities(list);

    _filteredEntities = list;

    _emitVisibleItems();
  }

  Future<void> _searchRecursively(String query) async {
    final dir = AppFileSystem.instance.directory(_path.value);
    if (!dir.existsSync()) return;

    final List<FileSystemEntity> results = [];

    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        final name = p.basename(entity.path).toLowerCase();
        if (name.contains(query)) {
          results.add(entity);
        }
      }
      _sortEntities(results);
      _filteredEntities = results;
      paginatedEntities.value = results;
    } catch (e) {
      AppLogger.e('Recursive search error: $e');
    }
  }

  /// Reloads the currently open directory (same as reopening it)
  Future<void> reload() async {
    final currentPath = getPathNotifier.value;

    if (currentPath.isEmpty) return;

    final dir = AppFileSystem.instance.directory(currentPath);

    if (!dir.existsSync()) return;

    await openDirectory(dir);
  }

  /// Dispose FileManagerController
  void dispose() {
    _path.dispose();
    paginatedEntities.dispose();
    titleNotifier.dispose();
    _sort.dispose();
    _searchQuery.dispose();
    _debounce?.cancel();
    _visibleCounts.clear();
  }

  void syncSettings({required bool showHidden}) {
    showHiddenFiles = showHidden;

    // Apply immediately to existing files
    _applySearchFilter();
  }
}
