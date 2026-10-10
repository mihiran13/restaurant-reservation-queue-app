import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'screens/owner/owner_login.dart';
import 'screens/owner/owner_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(FirebaseStartupErrorApp(error: error));
    return;
  }

  runApp(const RestaurantOwnerApp());
}

// --------------------------------------------------
// Firebase Startup Error Screen
// --------------------------------------------------

class FirebaseStartupErrorApp extends StatelessWidget {
  final Object error;

  const FirebaseStartupErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Firebase could not be initialized.\n'
              'Please check your internet connection and Firebase configuration.\n\n'
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Main Application
// --------------------------------------------------

class RestaurantOwnerApp extends StatelessWidget {
  const RestaurantOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Owner Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // Waiting for Firebase Authentication.
          if (authSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingScreen();
          }

          // Firebase Authentication error.
          if (authSnapshot.hasError) {
            return const AccessErrorScreen(
              message:
                  'Unable to verify your login. Please try again.',
            );
          }

          // If the user is logged in, verify the owner profile.
          final user = authSnapshot.data;

          if (user != null) {
            return OwnerAccessGate(
              key: ValueKey(user.uid),
              user: user,
            );
          }

          // If the user is not logged in, show login screen.
          return const OwnerLoginScreen();
        },
      ),
    );
  }
}

// --------------------------------------------------
// Loading Screen
// --------------------------------------------------

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Access Error Screen
// --------------------------------------------------

class AccessErrorScreen extends StatelessWidget {
  final String message;

  const AccessErrorScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.error,
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Restaurant access is not configured',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Owner Access Gate
// Reads the logged-in owner's restaurantId from Firestore.
// --------------------------------------------------

class OwnerAccessGate extends StatefulWidget {
  final User user;

  const OwnerAccessGate({
    super.key,
    required this.user,
  });

  @override
  State<OwnerAccessGate> createState() =>
      _OwnerAccessGateState();
}

class _OwnerAccessGateState extends State<OwnerAccessGate> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>
      _ownerStream = FirebaseFirestore.instance
          .collection('owners')
          .doc(widget.user.uid)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ownerStream,
      builder: (context, snapshot) {
        // Firestore returned an error.
        if (snapshot.hasError) {
          return const AccessErrorScreen(
            message:
                'Could not read your owner profile. '
                'Please check your Firestore security rules '
                'and internet connection.',
          );
        }

        // Wait for the owner document.
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingScreen();
        }

        // Owner document does not exist.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const AccessErrorScreen(
            message:
                'Your owner profile was not found in Firestore. '
                'Please contact the administrator.',
          );
        }

        final ownerData = snapshot.data!.data();

        // Get restaurantId from the owner's Firestore document.
        final restaurantId =
            ownerData?['restaurantId']?.toString().trim() ?? '';

        // Missing restaurantId.
        if (restaurantId.isEmpty) {
          return const AccessErrorScreen(
            message:
                'The restaurantId field is missing from your owner profile.',
          );
        }

        // Open the dashboard with the verified restaurant ID.
        return OwnerDashboardScreen(
          restaurantId: restaurantId,
        );
      },
    );
  }
}
