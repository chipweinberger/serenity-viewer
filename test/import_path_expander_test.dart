import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:serenity_viewer/src/media/import/import_path_expander.dart';

void main() {
  group('expandImportPaths', () {
    test('resolves symlinked files to their target path once', () async {
      final tempDir = await Directory.systemTemp.createTemp('serenity-import-paths-');
      addTearDown(() async => tempDir.delete(recursive: true));

      final targetFile = File('${tempDir.path}/target.jpg');
      await targetFile.writeAsString('image');
      final canonicalTargetPath = await targetFile.resolveSymbolicLinks();
      final symlink = Link('${tempDir.path}/alias.jpg');
      await symlink.create(targetFile.path);

      final expandedPaths = await expandImportPaths([targetFile.path, symlink.path]);

      expect(expandedPaths, [canonicalTargetPath]);
    });

    test('walks symlinked directories and avoids cycles', () async {
      final tempDir = await Directory.systemTemp.createTemp('serenity-import-paths-');
      addTearDown(() async => tempDir.delete(recursive: true));

      final targetDirectory = Directory('${tempDir.path}/media');
      await targetDirectory.create();
      final nestedFile = File('${targetDirectory.path}/clip.mp4');
      await nestedFile.writeAsString('video');
      final canonicalNestedFilePath = await nestedFile.resolveSymbolicLinks();

      final directoryLink = Link('${tempDir.path}/media-link');
      await directoryLink.create(targetDirectory.path);

      final cycleLink = Link('${targetDirectory.path}/self-link');
      await cycleLink.create(targetDirectory.path);

      final expandedPaths = await expandImportPaths([directoryLink.path]);

      expect(expandedPaths, [canonicalNestedFilePath]);
    });
  });
}
