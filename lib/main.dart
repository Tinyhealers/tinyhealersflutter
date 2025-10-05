import 'package:docon/constants/colors.dart';
import 'package:docon/pages/Admin/AdminBottomNavigation/AdminBottomNavigationScreen.dart';
import 'package:docon/pages/Doctor/BottomNavigation/BottomNavigationScreen.dart';
import 'package:docon/pages/Login/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html; // For web favicon manipulation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Set up web-specific configurations (like favicon) if running on web
  if (GetPlatform.isWeb) {
    setWebFavicon();
  }

  // Get user role
  String userRole = await getUserRole();

  runApp(MyApp(userRole: userRole));
}

// Function to set favicon dynamically for web
void setWebFavicon() {
  // Ensure the favicon is set in the HTML document head
  final favicon = html.LinkElement()
    ..rel = 'icon'
    ..type = 'image/png'
    ..href = '/favicon.png'; // Must match the path in your web folder
  html.document.head?.append(favicon);
}

// Function to fetch user role from SharedPreferences
Future<String> getUserRole() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userLoggedIn') ?? ""; // Default to empty string if null
}

class MyApp extends StatelessWidget {
  final String userRole;

  const MyApp({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tinyhealers',
      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.quicksand(
              fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black),
          bodyMedium: GoogleFonts.quicksand(
              fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.black54),
          displayLarge: GoogleFonts.quicksand(
              fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: GoogleFonts.quicksand(
              fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
          titleMedium: GoogleFonts.quicksand(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.quicksand(fontSize: 20),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: _getHomeScreen(userRole),
    );
  }

  Widget _getHomeScreen(String role) {
    if (role == "doctor") {
      return BottomNavigationScreen();
    } else if (role == "admin") {
      return AdminBottomNavigationScreen();
    } else {
      return LoginPage();
    }
  }
}