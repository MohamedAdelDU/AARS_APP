import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);
    final distance = provider.distanceTraveled;
    final activities = provider.recentActivities;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Achievements"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: const Text(
                    "Your Achievements",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "About Achievements",
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                      transitionBuilder: (_, anim, __, ___) {
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutBack,
                          ),
                          child: AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: const Center(
                              child: Text(
                                "About Achievements",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 60,
                                  color: Colors.lightBlue,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Achievements reward your safe driving habits. Earn trophies for milestones like distance traveled or accident-free days. Tap on each trophy to see more details!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            actionsPadding: const EdgeInsets.only(bottom: 12),
                            actions: [
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    "OK",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightBlue.withAlpha((0.2 * 255).round()),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.lightBlue,
                      semanticLabel: "Learn more about achievements",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Earn trophies for safe driving and milestones!",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildAchievement(
                    "Safe Driver: 100 km",
                    distance >= 100,
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "Safe Driver: 500 km",
                    distance >= 500,
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "Safe Driver: 1000 km",
                    distance >= 1000,
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "Safe Driver: 2000 km",
                    distance >= 2000,
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "7 Days No Accident",
                    _noAccidentFor(activities, 7),
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "14 Days No Accident",
                    _noAccidentFor(activities, 14),
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "Safe Speed: 100 km",
                    provider.badges.contains("Safe Speed: 100 km"),
                    context,
                    Icons.emoji_events,
                  ),
                  _buildAchievement(
                    "City Explorer",
                    provider.badges.contains("City Explorer"),
                    context,
                    Icons.location_city,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(
    String label,
    bool unlocked,
    BuildContext context,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Achievement",
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (_, anim, __, ___) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Center(
                  child: Text(
                    "Achievement Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 80,
                      color: unlocked ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label.replaceAll("\n", " "),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _achievementDescription(label),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.only(bottom: 12),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: unlocked ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                unlocked ? "Unlocked!" : "Locked",
                style: TextStyle(
                  fontSize: 10,
                  color: unlocked ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _achievementDescription(String label) {
    switch (label) {
      case "Safe Driver: 100 km":
        return "Awarded for driving 100 km without any accidents.";
      case "Safe Driver: 500 km":
        return "Awarded for driving 500 km without any accidents.";
      case "Safe Driver: 1000 km":
        return "Awarded for driving 1000 km without any accidents.";
      case "Safe Driver: 2000 km":
        return "Awarded for driving 2000 km without any accidents.";
      case "7 Days No Accident":
        return "No accidents recorded for 7 consecutive days.";
      case "14 Days No Accident":
        return "No accidents recorded for 14 consecutive days.";
      case "Safe Speed: 100 km":
        return "Maintained a safe speed for 100 km of driving.";
      case "City Explorer":
        return "Completed 100 trips inside a city.";
      default:
        return "Achievement unlocked!";
    }
  }

  bool _noAccidentFor(List<Activity> activities, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return activities
        .where((a) => a.timestamp.isAfter(cutoff))
        .every((a) => a.type != 'accident');
  }
}
