import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to WelcomeScreen after 3 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/logo.png', // Ensure this asset exists
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              "AARS",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
