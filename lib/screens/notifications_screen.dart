import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.white],
          ),
        ),
        child:
            activityProvider.activities.isEmpty
                ? const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: activityProvider.activities.length,
                  itemBuilder: (context, index) {
                    final activity = activityProvider.activities[index];
                    IconData icon;
                    Color gradientStart, gradientEnd;

                    // Define icons and gradients based on activity type
                    if (activity.type == 'accident') {
                      icon = Icons.warning;
                      gradientStart = Colors.red[700]!;
                      gradientEnd = Colors.red[300]!;
                    } else if (activity.type == 'help_request') {
                      icon = Icons.help;
                      gradientStart = Colors.orange[700]!;
                      gradientEnd = Colors.orange[300]!;
                    } else if (activity.type == 'location_update') {
                      icon = Icons.location_on;
                      gradientStart = Colors.green[700]!;
                      gradientEnd = Colors.green[300]!;
                    } else if (activity.type == 'speed_alert') {
                      icon = Icons.speed;
                      gradientStart = Colors.purple[700]!;
                      gradientEnd = Colors.purple[300]!;
                    } else if (activity.type == 'emergency_contact') {
                      icon = Icons.phone;
                      gradientStart = Colors.teal[700]!;
                      gradientEnd = Colors.teal[300]!;
                    } else {
                      icon = Icons.info;
                      gradientStart = Colors.grey[700]!;
                      gradientEnd = Colors.grey[300]!;
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(icon, color: Colors.white, size: 30),
                          ),
                          title: Text(
                            activity.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM d, yyyy, hh:mm a',
                            ).format(activity.timestamp),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
