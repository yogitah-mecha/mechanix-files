import 'package:equatable/equatable.dart';
import 'package:file/file.dart';

class RecentFileState extends Equatable {
  final bool loading;
  final List<FileSystemEntity> fileSystemList;
  final String? error;
  final FileStat? fileDetails;
  final int currentPage;
  final bool hasMorePages;

  const RecentFileState({
    this.loading = false,
    this.fileSystemList = const [],
    this.error,
    this.fileDetails,
    this.currentPage = 1,
    this.hasMorePages = true,
  });

  RecentFileState copyWith({
    bool? loading,
    List<FileSystemEntity>? fileSystemList,
    String? error,
    FileStat? fileDetails,
    int? currentPage,
    bool? hasMorePages,
  }) {
    return RecentFileState(
      loading: loading ?? this.loading,
      fileSystemList: fileSystemList ?? this.fileSystemList,
      error: error ?? this.error,
      fileDetails: fileDetails ?? this.fileDetails,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    fileSystemList,
    error,
    fileDetails,
    currentPage,
    hasMorePages,
  ];
}
