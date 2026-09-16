import 'package:razak_travel/data/models/model_parsers.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.tourId = '',
    this.targetUserId = '',
    this.timestamp,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String tourId;
  final String targetUserId;
  final DateTime? timestamp;

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? read,
    String? tourId,
    String? targetUserId,
    DateTime? timestamp,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      tourId: tourId ?? this.tourId,
      targetUserId: targetUserId ?? this.targetUserId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString().trim() ?? '';
    final message = json['message']?.toString().trim() ?? '';
    final type = json['type']?.toString().trim() ?? '';

    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: title.isNotEmpty ? title : message,
      message: message,
      type: type,
      read: json['read'] == true,
      tourId: (json['tour_id'] ?? json['tourId'])?.toString().trim() ?? '',
      targetUserId:
          (json['target_user_id'] ?? json['targetUserId'])?.toString().trim() ??
              '',
      timestamp: parseNullableDateTime(json['timestamp']),
    );
  }
}
