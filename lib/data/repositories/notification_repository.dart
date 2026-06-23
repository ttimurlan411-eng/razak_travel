import 'package:razak_travel/core/services/user_identity_service.dart';
import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/data/models/app_notification_model.dart';

class NotificationRepository {
  NotificationRepository({
    UserIdentityService? userIdentityService,
  }) : _userIdentityService =
            userIdentityService ?? UserIdentityService.instance;

  final SupabaseService _supabase = SupabaseService.instance;
  final UserIdentityService _userIdentityService;

  Future<List<AppNotificationModel>> getNotifications({
    int limit = 50,
    bool includeAll = false,
  }) async {
    final currentUserId =
        includeAll ? '' : (await _userIdentityService.getUserId()).trim();

    final data = await _supabase.query(
      _supabase.notifications,
      order: 'timestamp',
      ascending: false,
      limit: limit,
    );

    final notifications = data
        .map((json) => AppNotificationModel.fromJson(json))
        .where(
          (n) =>
              includeAll ||
              n.targetUserId.isEmpty ||
              n.targetUserId == currentUserId,
        )
        .toList(growable: false);

    return notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      return;
    }

    await _supabase.update(
      _supabase.notifications,
      {'read': true},
      'id',
      notificationId,
    );
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String tourId = '',
    String targetUserId = '',
  }) async {
    final id = 'notif_${DateTime.now().microsecondsSinceEpoch}';
    await _supabase.insert(_supabase.notifications, {
      'id': id,
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim(),
      'tour_id': tourId.trim(),
      'target_user_id': targetUserId.trim(),
      'read': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
