import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => ReportIssueScreenState();
}

class ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Report an Issue"),
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
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // أيقونة وعنوان فرعي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_problem,
                        color: Colors.red.withOpacity(0.8),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Help Us Improve",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please describe the issue you're facing in detail so we can assist you better.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // حقل إدخال النص
                  TextFormField(
                    controller: _issueController,
                    decoration: InputDecoration(
                      labelText: "Describe the issue",
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.lightBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.lightBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 5,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Please describe the issue"
                                : null,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  // أزرار الإجراءات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // زر إلغاء
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      // زر إرسال
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submitIssue(_issueController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Submit Issue",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitIssue(String issue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Thank you for reporting the issue! We'll look into it soon.",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    _issueController.clear();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }
}
