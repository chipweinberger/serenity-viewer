import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

class WorkspaceThumbnailStore {
  WorkspaceThumbnailStore({required this.thumbnailDirectory});

  final Future<Directory> Function() thumbnailDirectory;

  Future<String> persistThumbnail({required String workspaceId, required Uint8List bytes}) async {
    final file = await _thumbnailFileForWorkspace(workspaceId);
    await file.writeAsBytes(bytes, flush: true);
    await FileImage(file).evict();
    return file.path;
  }

  Future<File> _thumbnailFileForWorkspace(String workspaceId) async {
    final directory = await thumbnailDirectory();
    return File('${directory.path}/$workspaceId.jpg');
  }
}
