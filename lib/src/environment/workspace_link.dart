import 'package:flutter/foundation.dart';

@immutable
class WorkspaceLink {
  const WorkspaceLink({required this.id, required this.url, this.customName = ''});

  final String id;
  final String url;
  final String customName;

  String get trimmedCustomName => customName.trim();
  bool get hasCustomName => trimmedCustomName.isNotEmpty;
  String get displayName => hasCustomName ? trimmedCustomName : url;

  WorkspaceLink copyWith({String? id, String? url, String? customName}) {
    return WorkspaceLink(id: id ?? this.id, url: url ?? this.url, customName: customName ?? this.customName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'customName': customName};
  }

  factory WorkspaceLink.fromJson(Map<String, dynamic> json) {
    return WorkspaceLink(
      id: json['id'] as String,
      url: json['url'] as String,
      customName: json['customName'] as String? ?? '',
    );
  }
}
