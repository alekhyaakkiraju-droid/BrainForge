import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.timestamp,
    this.metadata = const {},
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id'] as String,
        actorUid: json['actorUid'] as String,
        action: json['action'] as String,
        resourceType: json['resourceType'] as String,
        resourceId: json['resourceId'] as String,
        timestamp: _parseTimestamp(json['timestamp']),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  final String id;
  final String actorUid;
  final String action;
  final String resourceType;
  final String resourceId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorUid': actorUid,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

DateTime _parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
