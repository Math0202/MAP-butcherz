import 'package:flutter/material.dart';

// Dummy Notification Model (replace with your actual data model)
class NotificationItem {
  final String id;
  final String title;
  final String? subtitle; // Optional additional detail
  final DateTime timestamp;
  final IconData icon;
  final Color? iconColor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.timestamp,
    required this.icon,
    this.iconColor,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Dummy list of notifications (replace with actual data fetching)
  final List<NotificationItem> _notifications = [
    NotificationItem(id: '1', title: 'Match Reminder: Team A vs Team B', subtitle: 'Starts in 1 hour at City Arena', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), icon: Icons.sports_hockey, iconColor: Colors.blue, isRead: false),
    NotificationItem(id: '2', title: 'New League Announcement!', subtitle: 'The Winter League registration is now open.', timestamp: DateTime.now().subtract(const Duration(hours: 2)), icon: Icons.campaign, iconColor: Colors.green, isRead: false),
    NotificationItem(id: '3', title: 'Roster Update Approved', subtitle: 'Player John Smith added to your team.', timestamp: DateTime.now().subtract(const Duration(hours: 5)), icon: Icons.group_add, iconColor: Colors.orange, isRead: true),
    NotificationItem(id: '4', title: 'Tournament Schedule Published', subtitle: 'Check the updated schedule for the Summer Slam.', timestamp: DateTime.now().subtract(const Duration(days: 1)), icon: Icons.event_note, iconColor: Colors.purple, isRead: true),
    NotificationItem(id: '5', title: 'Password Changed Successfully', subtitle: 'Your account password was updated.', timestamp: DateTime.now().subtract(const Duration(days: 2)), icon: Icons.lock_outline, isRead: true),
  ];

  void _markAsRead(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
    // TODO: API call to mark notification as read on the backend
  }

  void _navigateToNotificationContent(NotificationItem notification) {
    // TODO: Implement navigation based on notification type
    // For example, if it's a match reminder, navigate to the match details screen.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped on: ${notification.title} (Navigation not implemented)')),
    );
    if (!notification.isRead) {
      _markAsRead(notification);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Simple date format for older notifications
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications${unreadCount > 0 ? " ($unreadCount)" : ""}'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
                // TODO: API call to mark all as read
              },
              child: Text(
                'Mark All Read',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                  ),
                  Text(
                    'We\'ll let you know when something new comes up.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72, // Align with text content after icon
                color: theme.dividerColor.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                        : (notification.iconColor ?? theme.colorScheme.secondary).withOpacity(0.15),
                    child: Icon(
                      notification.icon,
                      color: notification.isRead
                          ? theme.hintColor
                          : notification.iconColor ?? theme.colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: notification.isRead ? theme.hintColor : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            notification.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: notification.isRead ? theme.hintColor.withOpacity(0.8) : theme.hintColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _formatTimestamp(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: notification.isRead ? theme.hintColor.withOpacity(0.7) : theme.hintColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: notification.isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () => _navigateToNotificationContent(notification),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                );
              },
            ),
    );
  }
} 