import 'package:flutter/material.dart';
import 'package:the_factory/services/auth_service.dart';
import 'pages/login_screens/login.dart';
import 'pages/login_screens/signup.dart';
import 'pages/login_screens/forgot_password.dart';
import 'pages/login_screens/OtpVerificationScreen.dart'; // Updated import
import 'pages/login_screens/reset_password_screen.dart'; // New import
import 'pages/Home_screen/home_screen.dart';
import 'pages/Profile/manage_profile.dart';
import 'pages/events/events_screen.dart';
import 'pages/online_training/online_training_screen.dart';
import 'pages/apparel_store_screen/apparel_store_screen.dart';
import 'package:provider/provider.dart';
import 'providers/event_provider.dart';
import 'providers/user_provider.dart';
import 'providers/profile_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TEMPORARILY COMMENT OUT THESE 2 LINES
  Stripe.publishableKey =
      'pk_test_51RTPwXR23CAa1CnAjXPthRwCOBBkwQfj0QDU30u8jhkygtaqDuDK83LxdQYNJEV9l9ypByvHQVYQ7f7enSmqdwas00HiFBD0lQ';
  await Future.delayed(const Duration(milliseconds: 100));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // Add the new event providers
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    print("🚀 App started, checking authentication...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authService.getUserData(context);
      // Preload profile cache immediately
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Factory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          print(
            "🏠 Building home widget - Loading: ${userProvider.isLoading}, LoggedIn: ${userProvider.isLoggedIn}",
          );
          print(
            "👤 Current user token: ${userProvider.user.token.isEmpty ? 'empty' : userProvider.user.token.substring(0, 10)}...",
          );

          if (userProvider.isLoading) {
            print("⏳ Showing loading screen");
            return const LoadingScreen();
          }

          if (userProvider.isLoggedIn) {
            print("✅ User is logged in, showing home screen");
            return FactoryFeedScreen();
          }

          print("🔑 User not logged in, showing login screen");
          return const FactoryLoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const FactoryLoginScreen(),
        '/register': (context) => const FactorySignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/otp_verification': (context) => const OTPVerificationScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/home': (context) => FactoryFeedScreen(),
        '/profile': (context) => const ManageProfileScreen(),
        '/events': (context) => const EventsScreen(),
        '/training': (context) => const OnlineTrainingScreen(),
        '/store': (context) => const ApparelScreen(),
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder:
              (context) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Match your app theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo here if you have one
            Image.asset(
              'assets/images/factory_logo.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.factory,
                  size: 80,
                  color: Color(0xFFA6E22E),
                );
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFFA6E22E)),
            const SizedBox(height: 24),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
