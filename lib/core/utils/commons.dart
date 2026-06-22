import 'dart:math' as math;

import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

String formatModifiedTime(BuildContext context, DateTime modified) {
  final now = DateTime.now();

  // If modified just now (within last 30 seconds)
  if (now.difference(modified).inSeconds.abs() < 30) {
    return AppLocalizations.of(context)!.now;
  }

  final isSameDay =
      now.year == modified.year &&
      now.month == modified.month &&
      now.day == modified.day;

  final isSameYear = now.year == modified.year;

  if (isSameDay) {
    return DateFormat.jm().format(modified); // e.g., 12:30 PM
  } else if (isSameYear) {
    return DateFormat('dd MMM').format(modified); // e.g., 20 Jul
  } else {
    return DateFormat('dd MMM yyyy').format(modified); // e.g., 20 Jul 2025
  }
}

String formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('dd-MM-yyyy, hh:mm a');
  return formatter.format(dateTime).toUpperCase();
}

String formatBytesDecimal(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';

  const base = 1000;
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

  final exponent = (math.log(bytes) / math.log(base)).floor().clamp(
    0,
    suffixes.length - 1,
  );

  final size = bytes / math.pow(base, exponent);

  return '${size.toStringAsFixed(decimals)} ${suffixes[exponent]}';
}

Future<String> generateUniqueFolderName(
  BuildContext context,
  String basePath,
) async {
  final baseName = AppLocalizations.of(context)!.newFolder;

  // First check the default folder name
  String candidate = p.join(basePath, baseName);

  int counter = 1;

  // If "New Folder" exists, try "New Folder (1)", "New Folder (2)"...
  while (await AppFileSystem.instance.directory(candidate).exists()) {
    candidate = p.join(basePath, '$baseName ($counter)');
    counter++;
  }

  // Only return the folder name, not full path
  return p.basename(candidate);
}
