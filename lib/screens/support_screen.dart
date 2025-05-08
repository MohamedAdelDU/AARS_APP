import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'contact_support_screen.dart';
import 'report_issue_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Support & Help"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            child: ListTile(
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text(
                "FAQs",
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                "Frequently Asked Questions",
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FAQScreen()),
                  ),
            ),
          ),
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
            child: ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.green),
              title: const Text(
                "Contact Support",
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                "Get in touch with our support team",
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen(),
                    ),
                  ),
            ),
          ),
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
            child: ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text(
                "Report an Issue",
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                "Report bugs or problems with the app",
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportIssueScreen(),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
