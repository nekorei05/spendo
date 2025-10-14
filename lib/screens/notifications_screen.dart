import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  // For now, this is a static list of notifications.
  // You can later connect this to your notification storage or Firebase.
  final List<String> notifications = [
    "Welcome to Expense Tracker!",
    "Your transaction of ₹500 has been recorded.",
    "Don't forget to check your weekly report.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications yet.'))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (_, index) {
                return ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(notifications[index]),
                );
              },
            ),
    );
  }
}
