import 'package:mechanix_files/features/recents/data/models/recent_files.dart';

abstract class RecentFilesRepository {
  Future<List<RecentFile>> getRecentFiles();

  Future<void> addRecentFile(String path);
}
