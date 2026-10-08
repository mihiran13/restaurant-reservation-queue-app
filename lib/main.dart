import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/owner/owner_login.dart';
import 'screens/owner/owner_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the configured platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const RestaurantOwnerApp());
}

class RestaurantOwnerApp extends StatelessWidget {
  const RestaurantOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Owner Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // StreamBuilder listens to auth state changes:
      // If user is already authenticated -> directly load Owner Dashboard
      // Otherwise -> show Owner Login screen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Waiting for auth state check
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
              ),
            );
          }

          // If user exists and is signed in, proceed to Owner Dashboard
          if (snapshot.hasData && snapshot.data != null) {
            return const OwnerDashboardScreen();
          }

          // Otherwise show Owner Login
          return const OwnerLoginScreen();
        },
      ),
    );
  }
}
