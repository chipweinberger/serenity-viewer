import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environments/session/session_state_normalizer.dart';
import 'package:serenity_viewer/src/sry_document/models/workspace_state.dart';

@immutable
class SessionState {
  const SessionState({
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

  SessionState copyWith({
    List<WorkspaceState>? workspaces,
    String? activeWorkspaceId,
    List<String>? knownFolders,
    Map<String, int>? folderPopularity,
    int? imageLoadLimit,
    int? shortVideoLoadLimit,
    int? longVideoLoadLimit,
  }) {
    return normalizeSessionState(
      SessionState(
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

  factory SessionState.fromJson(Map<String, dynamic> json) {
    return normalizeSessionState(
      SessionState(
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

  factory SessionState.fromManifestJson(Map<String, dynamic> json, List<WorkspaceState> workspaces) {
    return normalizeSessionState(
      SessionState(
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
