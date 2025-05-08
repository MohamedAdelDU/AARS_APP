import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'feedback_screen.dart';
import 'privacy_policy_screen.dart';
import 'achievements_screen.dart';
import 'trip_history_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Save Profile?"),
            content: const Text(
              "Do you want to save your profile for quick access later?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );
    if (result == true) {
      await prefs.setBool('isLoggedIn', false);
    } else {
      await prefs.remove('isLoggedIn');
      await prefs.remove('user_name');
    }
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      Provider.of<NavigationProvider>(
        context,
        listen: false,
      ).setSelectedIndex(0);
    }
  }

  Future<Map<String, String>> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'Unknown User';
    final firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    return {'fullName': fullName, 'firstLetter': firstLetter};
  }

  Future<void> _inviteFriends(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white, // ← لون الخلفية الجديد
            title: const Text("Invite Friends"),
            content: const Text("Invite your friends to join the app!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // لون زر الإغلاق
                ),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("More"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, String>>(
              future: _getUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Error loading user name");
                }
                final fullName = snapshot.data?['fullName'] ?? 'Unknown User';
                final firstLetter = snapshot.data?['firstLetter'] ?? '!';
                return InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Show Profile",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue,
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                buildCardItem(
                  context,
                  Icons.history,
                  "Trip History",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TripHistoryScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.emoji_events,
                  "Achievements",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.settings,
                  "Settings",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.help,
                  "Support & Help",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.feedback,
                  "Feedback",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.privacy_tip,
                  "Privacy Policy",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                ),
                buildCardItem(
                  context,
                  Icons.person_add,
                  "Invite Friends",
                  onTap: () => _inviteFriends(context),
                ),
                const SizedBox(height: 20),
                buildCardItem(
                  context,
                  Icons.logout,
                  "Logout",
                  isLogout: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCardItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: isLogout ? Colors.red : Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
