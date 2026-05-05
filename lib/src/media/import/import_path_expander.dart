import 'dart:io';

Future<List<String>> expandImportPaths(Iterable<String> paths) async {
  final expandedFiles = <String>[];
  final seenFiles = <String>{};
  final visitedDirectories = <String>{};

  Future<void> collectFiles(String path) async {
    final resolvedPath = await _resolveImportPath(path);
    if (resolvedPath == null) {
      return;
    }

    final entityType = await FileSystemEntity.type(resolvedPath, followLinks: false);
    switch (entityType) {
      case FileSystemEntityType.file:
        if (!seenFiles.add(resolvedPath)) {
          return;
        }
        expandedFiles.add(resolvedPath);
      case FileSystemEntityType.directory:
        if (!visitedDirectories.add(resolvedPath)) {
          return;
        }
        await for (final entity in Directory(resolvedPath).list(recursive: false, followLinks: false)) {
          await collectFiles(entity.path);
        }
      case FileSystemEntityType.link:
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        return;
    }
  }

  for (final path in paths) {
    await collectFiles(path);
  }

  return expandedFiles;
}

Future<String?> _resolveImportPath(String path) async {
  final absolutePath = File(path).absolute.path;
  final entityType = await FileSystemEntity.type(absolutePath, followLinks: false);

  switch (entityType) {
    case FileSystemEntityType.file:
      try {
        return await File(absolutePath).resolveSymbolicLinks();
      } catch (_) {
        return absolutePath;
      }
    case FileSystemEntityType.directory:
      try {
        return await Directory(absolutePath).resolveSymbolicLinks();
      } catch (_) {
        return absolutePath;
      }
    case FileSystemEntityType.link:
      try {
        return await Link(absolutePath).resolveSymbolicLinks();
      } catch (_) {
        return null;
      }
    case FileSystemEntityType.notFound:
    case FileSystemEntityType.pipe:
    case FileSystemEntityType.unixDomainSock:
      return null;
  }

  return null;
}
