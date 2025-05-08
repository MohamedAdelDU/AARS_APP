import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  // دالة لإظهار رسالة النجاح أو الخطأ
  void _showErrorDialog(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              isSuccess ? "Success" : "Error",
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.lightBlue),
                ),
              ),
            ],
          ),
    );
  }

  // دالة لإرسال رابط إعادة تعيين كلمة المرور
  Future<void> _resetPassword(
    BuildContext context,
    TextEditingController emailController,
  ) async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog(
        context,
        'Please enter a valid email to reset your password.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showErrorDialog(
        context,
        'Password reset email sent. Check your inbox.',
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(context, e.message ?? 'Failed to send reset email.');
    }
  }

  // دالة لتحديث البريد الإلكتروني
  Future<void> _changeEmail(
    BuildContext context,
    TextEditingController currentEmailController,
    TextEditingController newEmailController,
  ) async {
    final currentEmail = currentEmailController.text.trim();
    final newEmail = newEmailController.text.trim();

    // التحقق من صحة الإدخال
    if (currentEmail.isEmpty || !currentEmail.contains('@')) {
      _showErrorDialog(context, 'Please enter your current email correctly.');
      return;
    }
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showErrorDialog(context, 'Please enter a valid new email.');
      return;
    }
    if (currentEmail == newEmail) {
      _showErrorDialog(
        context,
        'The new email must be different from the current email.',
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog(context, 'No user is currently signed in.');
        return;
      }

      // التحقق من أن البريد الحالي يتطابق مع بريد المستخدم
      if (user.email != currentEmail) {
        _showErrorDialog(
          context,
          'The current email does not match your account email.',
        );
        return;
      }

      // تحديث البريد الإلكتروني
      await user.verifyBeforeUpdateEmail(newEmail);
      _showErrorDialog(
        context,
        'A verification email has been sent to $newEmail. Please verify it to complete the email change.',
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(context, e.message ?? 'Failed to update email.');
    }
  }

  // دالة لإظهار نافذة إدخال البريد الإلكتروني لإعادة تعيين كلمة المرور
  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              "Reset Password",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your email address to receive a password reset link.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(
                      Icons.email,
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  _resetPassword(context, emailController);
                },
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
                child: const Text(
                  "Send Reset Link",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
    );
  }

  // دالة لإظهار نافذة تغيير البريد الإلكتروني
  void _showChangeEmailDialog(BuildContext context) {
    final currentEmailController = TextEditingController();
    final newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              "Change Email",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your current and new email addresses.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentEmailController,
                  decoration: InputDecoration(
                    labelText: "Current Email",
                    labelStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(
                      Icons.email,
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newEmailController,
                  decoration: InputDecoration(
                    labelText: "New Email",
                    labelStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(
                      Icons.email,
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  _changeEmail(
                    context,
                    currentEmailController,
                    newEmailController,
                  );
                },
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
                child: const Text(
                  "Update Email",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
    );
  }

  // دالة لإظهار رسالة "سيتم تطويرها في المستقبل"
  void _showFutureFeatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              "Coming Soon",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "This feature will be developed in the future.",
              style: TextStyle(color: Colors.black54),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.lightBlue),
                ),
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
        title: const Text("Security"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // عنوان فرعي مع أيقونة
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, color: Colors.lightBlue, size: 32),
                const SizedBox(width: 8),
                const Text(
                  "Manage Your Account Security",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
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
              leading: const Icon(Icons.lock, color: Colors.lightBlue),
              title: const Text(
                "Change Password",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                "Reset your password via email",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap: () => _showResetPasswordDialog(context),
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
              leading: const Icon(Icons.email, color: Colors.lightBlue),
              title: const Text(
                "Change Email",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                "Update your email address",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap: () => _showChangeEmailDialog(context),
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
              leading: const Icon(Icons.security, color: Colors.lightBlue),
              title: const Text(
                "Two-Factor Authentication",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                "Enhance your account security",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlue,
                size: 16,
              ),
              onTap: () => _showFutureFeatureDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
