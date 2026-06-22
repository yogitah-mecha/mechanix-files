import 'package:mechanix_files/features/files_explorer/data/models/app_settings.dart';

abstract class AppSettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> updateShowHidden(bool showHidden);
}
