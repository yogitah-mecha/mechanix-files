import 'dart:io' as io;

import 'package:files/core/constants/icons.dart';

class FileItem {
  final String name;
  final String type;
  final List<FileItem>? children;
  final DateTime? modified;

  FileItem({
    required this.name,
    required this.type,
    this.children,
    this.modified,
  });

  @override
  String toString() {
    return 'FileItem(name: $name, type: $type, children: $children, modified: $modified)';
  }
}

extension FileItemIcon on FileItem {
  String get iconPath {
    if (type == 'dir') return FileIcons.unfoldDir;
    if (type == '.pdf') return FileIcons.pdfFile;
    if (type == '.xlsx') return FileIcons.excelFile;
    if (type == '.txt') return FileIcons.textFile;
    if (imageFileTypes.contains(type)) return FileIcons.imageFile;
    if (audioFileTypes.contains(type)) return FileIcons.audioFile;
    if (videoFileTypes.contains(type)) return FileIcons.videoFile;
    if (type == '.csv') return FileIcons.csvFile;
    if (type == '.zip') return FileIcons.archiveFile;
    if (textFileTypes.contains(type)) return FileIcons.codeFile;

    return FileIcons.file;
  }
}

const textFileTypes = [
  '.dart',
  '.yaml',
  '.yml',
  '.sql',
  '.json',
  '.java',
  '.c',
  '.cpp',
  '.js',
  '.py',
  '.ini',
  '.toml',
  '.rb',
  '.xml',
  '.rs',
  '.txt',
];

const audioFileTypes = ['.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus'];

const videoFileTypes = ['.mp4', '.mkv', '.avi', '.mov', '.wmv'];

const imageFileTypes = [
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.svg',
  '.gif',
  '.bmp',
];

// FileSystemEntity extension
extension FileSystemEntityIcon on io.FileSystemEntity {
  String get iconPath {
    final path = this.path;
    var ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'dir';
    ext = ".$ext";

    if (ext == '.dir') return FileIcons.unfoldDir;
    if (ext == '.pdf') return FileIcons.pdfFile;
    if (ext == '.xlsx' || ext == '.xls') return FileIcons.excelFile;
    if (ext == '.txt') return FileIcons.textFile;
    if (imageFileTypes.contains(ext)) return FileIcons.imageFile;
    if (audioFileTypes.contains(ext)) return FileIcons.audioFile;
    if (videoFileTypes.contains(ext)) return FileIcons.videoFile;
    if (ext == '.csv') return FileIcons.csvFile;
    if (ext == '.zip' || ext == '.rar' || ext == '.7z') {
      return FileIcons.archiveFile;
    }
    if (textFileTypes.contains(ext)) return FileIcons.codeFile;

    return FileIcons.file;
  }
}
