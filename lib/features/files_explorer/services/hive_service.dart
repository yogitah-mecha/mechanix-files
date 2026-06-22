import 'dart:io' as io;
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:hive/hive.dart';

class HiveService {
  static Future<void> initializeHive() async {
    try {
      final home = io.Platform.environment['HOME'];
      final xdgConfig = io.Platform.environment['XDG_CONFIG_HOME'];
      final baseDir = xdgConfig ?? '$home/.config';
      final appDir = AppFileSystem.instance.directory(
        '$baseDir/mechanix_files',
      );

      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      Hive.init(appDir.path);
    } catch (e) {
      AppLogger.e('Failed to initialize Hive: $e');
    }
  }
}
