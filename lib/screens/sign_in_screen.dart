import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regFullName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirmPass = TextEditingController();
  bool _obscurePassLogin = true;
  bool _obscurePassReg = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _error;
  late TabController _tabController;

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regFullName.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _regConfirmPass.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (_auth.currentUser != null || isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _signInWithEmail() async {
    if (_loginEmail.text.trim().isEmpty || !_loginEmail.text.contains('@')) {
      _showErrorDialog('Please enter a valid email.');
      return;
    }
    if (_loginPass.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _loginEmail.text.trim(),
        password: _loginPass.text,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      if (_rememberMe) {
        await prefs.setString('email', _loginEmail.text.trim());
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in successfully')));
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred.';
      }
      _showErrorDialog(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (_regFullName.text.trim().isEmpty) {
      _showErrorDialog('Please enter your full name.');
      return;
    }
    if (_regEmail.text.trim().isEmpty || !_regEmail.text.contains('@')) {
      _showErrorDialog('Please enter a valid email.');
      return;
    }
    if (_regPass.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters.');
      return;
    }
    if (_regPass.text != _regConfirmPass.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: _regEmail.text.trim(),
        password: _regPass.text,
      );
      await userCred.user?.updateDisplayName(_regFullName.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registered successfully')));
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred.';
      }
      _showErrorDialog(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in with Google')));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showErrorDialog('Google Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.signInWithProvider(appleProvider);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in with Apple')));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showErrorDialog('Apple Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_loginEmail.text.trim().isEmpty || !_loginEmail.text.contains('@')) {
      _showErrorDialog('Please enter a valid email to reset your password.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _loginEmail.text.trim());
      _showErrorDialog(
        'Password reset email sent. Check your inbox.',
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Failed to send reset email.');
    }
  }

  void _showErrorDialog(String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isSuccess ? 'Success' : 'Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF4A90E2)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
        suffixIcon:
            toggle != null
                ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: toggle,
                )
                : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: Colors.black,
      ),
      icon: const Icon(Icons.g_mobiledata, color: Color(0xFF4A90E2), size: 30),
      label: const Text("Google", style: TextStyle(color: Colors.black)),
      onPressed: _signInWithGoogle,
    );
  }

  Widget _buildAppleButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: Colors.black,
      ),
      icon: const Icon(Icons.apple, color: Color(0xFF4A90E2), size: 24),
      label: const Text("Apple", style: TextStyle(color: Colors.black)),
      onPressed: _signInWithApple,
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            dividerColor: Colors.transparent,
            tabBarTheme: const TabBarTheme(
              dividerColor: Colors.transparent,
              overlayColor: MaterialStatePropertyAll(Colors.transparent),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(30),
            ),
            indicatorColor: Colors.transparent,
            indicatorWeight: 0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorPadding: const EdgeInsets.all(6),
            tabs: const [
              Tab(child: Center(child: Text("Login"))),
              Tab(child: Center(child: Text("Register"))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                color: const Color(0xFFE3F2FD),
              ),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),
          SafeArea(
            top: false,
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A90E2),
                      ),
                    )
                    : Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            height: MediaQuery.of(context).size.height * 0.40,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Stay Prepared",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Log In or Sign Up for Emergency Management",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.31,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40),
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                _buildTabSelector(),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Login Page
                                      Transform.translate(
                                        offset: const Offset(0, -30),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: ListView(
                                            children: [
                                              _buildTextField(
                                                _loginEmail,
                                                "Email Address",
                                                Icons.email,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildTextField(
                                                _loginPass,
                                                "Password",
                                                Icons.lock,
                                                obscure: _obscurePassLogin,
                                                toggle:
                                                    () => setState(
                                                      () =>
                                                          _obscurePassLogin =
                                                              !_obscurePassLogin,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Checkbox(
                                                        value: _rememberMe,
                                                        onChanged:
                                                            (value) => setState(
                                                              () =>
                                                                  _rememberMe =
                                                                      value ??
                                                                      false,
                                                            ),
                                                        activeColor:
                                                            const Color(
                                                              0xFF4A90E2,
                                                            ),
                                                      ),
                                                      Text(
                                                        "Remember me",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TextButton(
                                                    onPressed: _resetPassword,
                                                    child: const Text(
                                                      "Forgot Password?",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF4A90E2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF4A90E2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    50,
                                                  ),
                                                ),
                                                onPressed: _signInWithEmail,
                                                child: const Text(
                                                  "Login",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "or with",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildGoogleButton(),
                                              const SizedBox(height: 8),
                                              _buildAppleButton(),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Register Page
                                      Transform.translate(
                                        offset: const Offset(0, -30),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: ListView(
                                            children: [
                                              _buildTextField(
                                                _regFullName,
                                                "Full Name",
                                                Icons.person,
                                              ),
                                              const SizedBox(height: 6),
                                              _buildTextField(
                                                _regEmail,
                                                "Email",
                                                Icons.email,
                                              ),
                                              const SizedBox(height: 6),
                                              _buildTextField(
                                                _regPass,
                                                "Password",
                                                Icons.lock,
                                                obscure: _obscurePassReg,
                                                toggle:
                                                    () => setState(
                                                      () =>
                                                          _obscurePassReg =
                                                              !_obscurePassReg,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              _buildTextField(
                                                _regConfirmPass,
                                                "Confirm Password",
                                                Icons.lock,
                                                obscure: _obscurePassReg,
                                                toggle:
                                                    () => setState(
                                                      () =>
                                                          _obscurePassReg =
                                                              !_obscurePassReg,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF4A90E2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    50,
                                                  ),
                                                ),
                                                onPressed: _registerWithEmail,
                                                child: const Text(
                                                  "Register",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
