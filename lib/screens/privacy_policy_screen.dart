import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Last Updated: May 06, 2025\n\n"
                "At AARS, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application.\n\n"
                "1. Information We Collect\n"
                "- Location data to track your driving.\n"
                "- Speed and distance data for activity analysis.\n"
                "- Emergency contact information you provide.\n\n"
                "2. How We Use Your Information\n"
                "- To provide driving safety features.\n"
                "- To detect and respond to accidents.\n"
                "- To improve our services based on your feedback.\n\n"
                "3. Data Security\n"
                "We use industry-standard security measures to protect your data. However, no method is 100% secure.\n\n"
                "4. Your Choices\n"
                "You can review or update your emergency contact information in the settings.\n\n"
                "For more details or to contact us, please reach out at support@aars.com.",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
