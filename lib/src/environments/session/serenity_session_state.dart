import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/workspace_state.dart';

SerenitySessionState _normalizeSessionState(SerenitySessionState session) {
  final dedupedWorkspaces = <WorkspaceState>[];
  final seenWorkspaceIds = <String>{};

  for (final workspace in session.workspaces) {
    if (seenWorkspaceIds.add(workspace.id)) {
      dedupedWorkspaces.add(workspace);
    }
  }

  if (dedupedWorkspaces.isEmpty) {
    return session;
  }

  final hasActiveWorkspace = dedupedWorkspaces.any((workspace) => workspace.id == session.activeWorkspaceId);
  final nextActiveWorkspaceId = hasActiveWorkspace ? session.activeWorkspaceId : dedupedWorkspaces.first.id;
  final hasOpenWorkspace = dedupedWorkspaces.any((workspace) => workspace.isOpen);
  final normalizedWorkspaces = dedupedWorkspaces
      .map(
        (workspace) => (!hasOpenWorkspace || workspace.id == nextActiveWorkspaceId) && !workspace.isOpen
            ? workspace.copyWith(isOpen: true)
            : workspace,
      )
      .toList();

  final changed =
      dedupedWorkspaces.length != session.workspaces.length ||
      nextActiveWorkspaceId != session.activeWorkspaceId ||
      normalizedWorkspaces.asMap().entries.any((entry) => entry.value.isOpen != dedupedWorkspaces[entry.key].isOpen);

  if (!changed) {
    return session;
  }

  return SerenitySessionState(
    workspaces: normalizedWorkspaces,
    activeWorkspaceId: nextActiveWorkspaceId,
    knownFolders: session.knownFolders,
    folderPopularity: session.folderPopularity,
    imageLoadLimit: session.imageLoadLimit,
    shortVideoLoadLimit: session.shortVideoLoadLimit,
    longVideoLoadLimit: session.longVideoLoadLimit,
  );
}

@immutable
class SerenitySessionState {
  const SerenitySessionState({
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.knownFolders,
    required this.folderPopularity,
    required this.imageLoadLimit,
    required this.shortVideoLoadLimit,
    required this.longVideoLoadLimit,
  });

  final List<WorkspaceState> workspaces;
  final String activeWorkspaceId;
  final List<String> knownFolders;
  final Map<String, int> folderPopularity;
  final int imageLoadLimit;
  final int shortVideoLoadLimit;
  final int longVideoLoadLimit;

  SerenitySessionState copyWith({
    List<WorkspaceState>? workspaces,
    String? activeWorkspaceId,
    List<String>? knownFolders,
    Map<String, int>? folderPopularity,
    int? imageLoadLimit,
    int? shortVideoLoadLimit,
    int? longVideoLoadLimit,
  }) {
    return _normalizeSessionState(
      SerenitySessionState(
        workspaces: workspaces ?? this.workspaces,
        activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
        knownFolders: knownFolders ?? this.knownFolders,
        folderPopularity: folderPopularity ?? this.folderPopularity,
        imageLoadLimit: imageLoadLimit ?? this.imageLoadLimit,
        shortVideoLoadLimit: shortVideoLoadLimit ?? this.shortVideoLoadLimit,
        longVideoLoadLimit: longVideoLoadLimit ?? this.longVideoLoadLimit,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspaces': workspaces.map((workspace) => workspace.toJson()).toList(),
      'activeWorkspaceId': activeWorkspaceId,
      'knownFolders': knownFolders,
      'folderPopularity': folderPopularity,
      'imageLoadLimit': imageLoadLimit,
      'shortVideoLoadLimit': shortVideoLoadLimit,
      'longVideoLoadLimit': longVideoLoadLimit,
    };
  }

  Map<String, dynamic> toManifestJson() {
    return {
      'workspaceIds': workspaces.map((workspace) => workspace.id).toList(),
      'activeWorkspaceId': activeWorkspaceId,
      'knownFolders': knownFolders,
      'folderPopularity': folderPopularity,
      'imageLoadLimit': imageLoadLimit,
      'shortVideoLoadLimit': shortVideoLoadLimit,
      'longVideoLoadLimit': longVideoLoadLimit,
    };
  }

  factory SerenitySessionState.fromJson(Map<String, dynamic> json) {
    return _normalizeSessionState(
      SerenitySessionState(
        workspaces: (json['workspaces'] as List<dynamic>)
            .map((entry) => WorkspaceState.fromJson(entry as Map<String, dynamic>))
            .toList(),
        activeWorkspaceId: json['activeWorkspaceId'] as String,
        knownFolders: (json['knownFolders'] as List<dynamic>? ?? const []).cast<String>(),
        folderPopularity: (json['folderPopularity'] as Map<String, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(key, value as int),
        ),
        imageLoadLimit: json['imageLoadLimit'] as int? ?? 300,
        shortVideoLoadLimit: json['shortVideoLoadLimit'] as int? ?? 36,
        longVideoLoadLimit: json['longVideoLoadLimit'] as int? ?? 12,
      ),
    );
  }

  factory SerenitySessionState.fromManifestJson(Map<String, dynamic> json, List<WorkspaceState> workspaces) {
    return _normalizeSessionState(
      SerenitySessionState(
        workspaces: workspaces,
        activeWorkspaceId: json['activeWorkspaceId'] as String,
        knownFolders: (json['knownFolders'] as List<dynamic>? ?? const []).cast<String>(),
        folderPopularity: (json['folderPopularity'] as Map<String, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(key, value as int),
        ),
        imageLoadLimit: json['imageLoadLimit'] as int? ?? 300,
        shortVideoLoadLimit: json['shortVideoLoadLimit'] as int? ?? 36,
        longVideoLoadLimit: json['longVideoLoadLimit'] as int? ?? 12,
      ),
    );
  }
}
