import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:mechanix_files/features/files_explorer/data/models/app_settings.dart';
import 'package:mechanix_files/features/files_explorer/services/hive_service.dart';
import 'package:hive/hive.dart';

class AppSettingsRepositoryImpl extends AppSettingsRepository {
  Box<AppSettings> get box => Hive.box<AppSettings>(appSettingsTable);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(appSettingsTable)) {
        await HiveService.initializeHive();
        await Hive.openBox<AppSettings>(appSettingsTable);
      }
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
    }
  }

  AppSettings _defaults() => AppSettings(showHiddenFiles: false);

  Box<AppSettings> _box() => Hive.box<AppSettings>(appSettingsTable);

  @override
  Future<AppSettings> getSettings() async {
    await ensureHiveConnected();

    final settings = _box().get(0, defaultValue: _defaults())!;

    return settings;
  }

  Future<void> saveSettings(AppSettings settings) async {
    await ensureHiveConnected();

    await _box().put(0, settings);
  }

  @override
  Future<void> updateShowHidden(bool value) async {
    final current = await getSettings();

    await saveSettings(current.copyWith(showHiddenFiles: value));
  }

  Future<void> resetToDefaults() async {
    await saveSettings(_defaults());
  }
}
