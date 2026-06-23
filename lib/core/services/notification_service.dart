import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
    debugPrint('Notifications disabled');
  }

  Future<void> bindUser(String userId) async {}

  Future<void> unbindUser(String userId) async {}
}
