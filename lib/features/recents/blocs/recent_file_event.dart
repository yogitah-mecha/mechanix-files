import 'package:equatable/equatable.dart';

abstract class RecentFilesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecentFiles extends RecentFilesEvent {}

class AddToRecentFiles extends RecentFilesEvent {
  final String path;
  AddToRecentFiles(this.path);
}
