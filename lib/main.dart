import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'screens/splash_screen.dart';
import 'providers/activity_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/more_screen.dart';
import 'firebase_options.dart';

// مفتاح عالمي للتحكم في التنقل
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة الإشعارات المحلية
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        _handleNotificationTap(response.payload!);
      }
    },
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// معالجة النقر على الإشعار
void _handleNotificationTap(String payload) {
  final navigationProvider =
      navigatorKey.currentContext?.read<NavigationProvider>();
  if (navigationProvider == null) return;

  if (payload == 'accident') {
    navigationProvider.setSelectedIndex(0); // الانتقال إلى HomeScreen
    navigatorKey.currentState?.pushNamed('/home');
  } else if (payload.startsWith('badge_')) {
    navigationProvider.setSelectedIndex(1); // الانتقال إلى ActivityScreen
    navigatorKey.currentState?.pushNamed('/activity');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accident Detection',
      navigatorKey: navigatorKey, // تعيين مفتاح التنقل
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.lightBlue),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/sign_in': (context) => const AuthScreen(),
        '/home': (context) => const MyHomePage(),
        '/activity': (context) => const ActivityScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/more': (context) => const MoreScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body:
              [
                const HomeScreen(),
                const ActivityScreen(),
                const ContactsScreen(),
                const MoreScreen(),
              ][navigationProvider.selectedIndex],
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: GNav(
                  gap: 10,
                  activeColor: Colors.blue,
                  color: Colors.black87,
                  iconSize: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundColor: Colors.transparent,
                  selectedIndex: navigationProvider.selectedIndex,
                  onTabChange: (index) {
                    navigationProvider.setSelectedIndex(index);
                  },
                  tabs: const [
                    GButton(icon: Icons.home, text: 'Home'),
                    GButton(icon: Icons.star_border, text: 'Recent'),
                    GButton(icon: Icons.phone, text: 'Contacts'),
                    GButton(icon: Icons.apps, text: 'More'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
