import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Trip History"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Trip History",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "View your recent trips and details.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  provider.recentActivities.isEmpty
                      ? const Center(
                        child: Text(
                          "No trips recorded yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: provider.recentActivities.length,
                        itemBuilder: (context, index) {
                          final activity = provider.recentActivities[index];
                          if (activity.type == 'trip') {
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.drive_eta,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  "Trip ${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(activity.timestamp),
                                    ),
                                    Text(
                                      "Distance: ${(activity.distance ?? 0).toStringAsFixed(1)} km",
                                    ),
                                    Text(
                                      "Avg Speed: ${(activity.speed ?? 0).toStringAsFixed(1)} km/h",
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
