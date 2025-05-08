import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // تعريف صحيح لـ GlobalKey

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      // استخدام currentState بشكل صحيح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully!")),
      );
      _feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Feedback"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // تمرير _formKey كـ GlobalKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Share Your Thoughts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We’d love to hear your feedback to improve AARS!",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Type your feedback here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your feedback";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
