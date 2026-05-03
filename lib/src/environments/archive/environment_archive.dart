import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environments/session/session_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';

@immutable
class SerenityDecodedEnvironment {
  const SerenityDecodedEnvironment({required this.session, required this.thumbnailBytesByWorkspaceId});

  final SerenitySessionState session;
  final Map<String, Uint8List> thumbnailBytesByWorkspaceId;
}

Uint8List buildEnvironmentArchiveBytes({
  required SerenitySessionState session,
  Map<String, List<int>> thumbnailBytesByWorkspaceId = const {},
  DateTime? savedAt,
}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert({
          'app': 'Serenity',
          'format': 'sry',
          'version': 2,
          'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
          ...session.toManifestJson(),
        }),
      ),
    );

  for (final workspace in session.workspaces) {
    archive.addFile(
      ArchiveFile.string(
        'workspaces/${workspace.id}.json',
        const JsonEncoder.withIndent('  ').convert(workspace.toJson()),
      ),
    );
  }

  thumbnailBytesByWorkspaceId.forEach((workspaceId, bytes) {
    archive.addFile(ArchiveFile('thumbnails/$workspaceId.jpg', bytes.length, bytes));
  });

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

SerenityDecodedEnvironment decodeEnvironmentArchiveBytes(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final manifestEntry = archive.findFile('manifest.json');
  if (manifestEntry == null) {
    throw const FormatException('Missing manifest.json');
  }

  final manifestJson = jsonDecode(utf8.decode(manifestEntry.content as List<int>)) as Map<String, dynamic>;
  if (manifestJson['format'] != 'sry' || manifestJson['version'] != 2) {
    throw const FormatException('Unsupported .sry format');
  }

  final workspaceIds = (manifestJson['workspaceIds'] as List<dynamic>? ?? const []).cast<String>();
  final workspaces = <WorkspaceState>[];
  for (final workspaceId in workspaceIds) {
    final workspaceEntry = archive.findFile('workspaces/$workspaceId.json');
    if (workspaceEntry == null) {
      throw FormatException('Missing workspace file for $workspaceId');
    }

    final workspaceJson = jsonDecode(utf8.decode(workspaceEntry.content as List<int>)) as Map<String, dynamic>;
    workspaces.add(WorkspaceState.fromJson(workspaceJson));
  }

  final thumbnailBytesByWorkspaceId = <String, Uint8List>{};
  for (final workspaceId in workspaceIds) {
    final thumbnailEntry = archive.findFile('thumbnails/$workspaceId.jpg');
    if (thumbnailEntry == null) {
      continue;
    }
    thumbnailBytesByWorkspaceId[workspaceId] = Uint8List.fromList(thumbnailEntry.content as List<int>);
  }

  return SerenityDecodedEnvironment(
    session: SerenitySessionState.fromManifestJson(manifestJson, workspaces),
    thumbnailBytesByWorkspaceId: thumbnailBytesByWorkspaceId,
  );
}
