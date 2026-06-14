import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../screens/notifications/notification_list_screen.dart';

class NotificationBell extends StatelessWidget {
  final double iconSize;
  final Color iconColor;

  const NotificationBell({
    super.key,
    this.iconSize = 24,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                count > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_outlined,
                size: iconSize,
                color: iconColor,
              ),
              onPressed: () => _openNotifications(context),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationListScreen(),
      ),
    );
  }
}
