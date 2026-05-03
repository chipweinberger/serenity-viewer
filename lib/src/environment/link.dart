import 'package:flutter/foundation.dart';

@immutable
class Link {
  const Link({required this.id, required this.url, this.customName = ''});

  final String id;
  final String url;
  final String customName;

  String get trimmedCustomName => customName.trim();
  bool get hasCustomName => trimmedCustomName.isNotEmpty;
  String get displayName => hasCustomName ? trimmedCustomName : url;

  Link copyWith({String? id, String? url, String? customName}) {
    return Link(id: id ?? this.id, url: url ?? this.url, customName: customName ?? this.customName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'customName': customName};
  }

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(id: json['id'] as String, url: json['url'] as String, customName: json['customName'] as String? ?? '');
  }
}
