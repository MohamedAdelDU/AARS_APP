import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_screen.dart';
import 'about_app_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final String _selectedLanguage = 'English'; // لغة ثابتة
  int _selectedCountdownTime = 10; // Default countdown time
  final List<int> _countdownTimes = [10, 20, 30]; // Available countdown times

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedCountdownTime = prefs.getInt('countdown_time') ?? 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              title: const Text(
                "Enable Notifications",
                style: TextStyle(color: Colors.black87),
              ),
              value: _notificationsEnabled,
              activeColor: Colors.lightBlue,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveNotificationPreference(value);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              title: const Text(
                "Language",
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: Text(
                _selectedLanguage,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap: () => _showLanguagePicker(context),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              title: const Text(
                "Accident Alert Countdown",
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: Text(
                "$_selectedCountdownTime seconds",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap: () => _showCountdownTimePicker(context),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.security, color: Colors.lightBlue),
              title: const Text(
                "Security",
                style: TextStyle(color: Colors.black87),
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.lightBlue),
              title: const Text(
                "About the App",
                style: TextStyle(color: Colors.black87),
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  void _showLanguagePicker(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, color: Colors.lightBlue, size: 28),
                SizedBox(width: 8),
                Text(
                  "Language Support",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "The supported language is English.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "The app will be developed in the future to support all languages.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("OK", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  void _showCountdownTimePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int tempSelected = _selectedCountdownTime;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.timer, color: Colors.lightBlue, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Select Countdown Time",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content:
                  _countdownTimes.isEmpty
                      ? const Text("No countdown times available")
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            _countdownTimes.map((time) {
                              final isSelected = tempSelected == time;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    tempSelected = time;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.lightBlue.shade50
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "$time seconds",
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.lightBlue
                                                    : Colors.black87,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
              actionsAlignment: MainAxisAlignment.spaceBetween, // تنسيق أفضل
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedCountdownTime = tempSelected;
                    });
                    _saveCountdownTimePreference(tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveCountdownTimePreference(int time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('countdown_time', time);
  }
}
