import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _savedUserName;
  Timer? _timer;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: "Accident Detection in Real-Time",
      subtitle: "Monitoring your speed and safety every moment.",
      imagePath: "assets/onboard1.png",
    ),
    _OnboardingPage(
      title: "Quick Access to Emergency Services",
      subtitle: "One tap to call for help — no matter where you are.",
      imagePath: "assets/onboard2.png",
    ),
    _OnboardingPage(
      title: "Safe Travels Made Smarter",
      subtitle: "Your safety is our mission.",
      imagePath: "assets/onboard3.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
    // Start auto-scrolling timer
    _startAutoScroll();
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    setState(() {
      _savedUserName = name;
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // Loop back to the first page
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToLogin() => Navigator.pushReplacementNamed(context, '/sign_in');

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the screen is disposed
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = Colors.blue.shade700;
    final grey = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder:
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(_pages[index].imagePath, height: 240),
                              const SizedBox(height: 30),
                              Text(
                                _pages[index].title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: blue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pages[index].subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, color: grey),
                              ),
                            ],
                          ),
                        ),
                  ),
                  // Show arrow button on the third screen
                  if (_currentPage == _pages.length - 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: _goToLogin,
                        backgroundColor: blue,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 16,
                  ),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  if (_savedUserName != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: BorderSide(color: blue),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Continue as $_savedUserName"),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String imagePath;

  _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}
