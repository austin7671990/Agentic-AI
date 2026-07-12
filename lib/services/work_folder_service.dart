import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class WorkFile {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final bool isDirectory;
  String? content;

  WorkFile({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    this.isDirectory = false,
    this.content,
  });
}

class WorkFolderService extends GetxService {
  final RxList<WorkFile> files = <WorkFile>[].obs;
  final RxString currentPath = ''.obs;
  String? _workDir;

  Future<WorkFolderService> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _workDir = p.join(dir.path, 'work');
    final workDir = Directory(_workDir!);
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }
    await refreshFiles();
    return this;
  }

  Future<String> getWorkDirectory() async {
    return _workDir ?? '';
  }

  Future<void> refreshFiles() async {
    if (_workDir == null) return;
    final workDir = Directory(_workDir!);
    if (!await workDir.exists()) return;

    final list = <WorkFile>[];
    await for (final entity in workDir.list(recursive: true, followLinks: false)) {
      final stat = await entity.stat();
      final relPath = p.relative(entity.path, from: _workDir);
      list.add(WorkFile(
        name: p.basename(entity.path),
        path: relPath,
        size: stat.size,
        modified: stat.modified,
        isDirectory: entity is Directory,
      ));
    }
    list.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });
    files.assignAll(list);
  }

  Future<WorkFile> createFile(String name, String content) async {
    if (_workDir == null) throw Exception('Work folder not initialized');
    final filePath = p.join(_workDir!, name);
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
    await refreshFiles();
    return WorkFile(
      name: name,
      path: p.relative(filePath, from: _workDir),
      size: content.length,
      modified: DateTime.now(),
      content: content,
    );
  }

  Future<String> readFile(String path) async {
    if (_workDir == null) return '';
    final filePath = p.join(_workDir!, path);
    final file = File(filePath);
    if (!await file.exists()) return '';
    return await file.readAsString();
  }

  Future<void> deleteFile(String path) async {
    if (_workDir == null) return;
    final filePath = p.join(_workDir!, path);
    final entity = FileSystemEntity.typeSync(filePath);
    if (entity == FileSystemEntityType.file) {
      await File(filePath).delete();
    } else if (entity == FileSystemEntityType.directory) {
      await Directory(filePath).delete(recursive: true);
    }
    await refreshFiles();
  }

  Future<void> exportFile(String path, String destination) async {
    if (_workDir == null) return;
    final srcPath = p.join(_workDir!, path);
    final src = File(srcPath);
    if (!await src.exists()) return;
    final dest = File(destination);
    await dest.create(recursive: true);
    await src.copy(destination);
  }

  Future<List<String>> listAllFiles() async {
    if (_workDir == null) return [];
    final workDir = Directory(_workDir!);
    if (!await workDir.exists()) return [];
    final result = <String>[];
    await for (final entity in workDir.list(recursive: true)) {
      if (entity is File) {
        result.add(p.relative(entity.path, from: _workDir));
      }
    }
    return result;
  }
}