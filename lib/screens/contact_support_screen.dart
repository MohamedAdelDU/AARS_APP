import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Contact Support"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "If you need assistance, please reach out to our support team.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text(
                    "Email Support",
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: const Text(
                    "support@aars.com",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => _launchEmail("support@aars.com"),
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text(
                    "Call Support",
                    style: TextStyle(color: Colors.black87),
                  ),
                  subtitle: const Text(
                    "+201080340793",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => _launchPhone("+201080340793"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw "Could not launch email";
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw "Could not launch phone";
    }
  }
}
