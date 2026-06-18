import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Pastikan semua file ini benar-benar ada di dalam folder lib/screens/
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawtopia Shelter App',
      debugShowCheckedModeBanner:
          false, // Menghilangkan banner debug (opsional)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Definisi rute aplikasi
      routes: {
        '/splash': (_) =>
            const SplashScreen(), // Menambahkan rute splash screen
        '/sign_in': (_) => const SignInScreen(),
        '/sign_up': (_) => const SignUpScreen(),
        '/home': (_) => const HomeScreen(),
        '/add_post': (_) => const AddPostScreen(),
        '/favorites': (_) => const FavoritesScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/search': (_) => const SearchScreen(),
      },
      // PERBAIKAN DI SINI: Langsung panggil SplashScreen() sebagai layar pertama utama aplikasi
      home: const SplashScreen(),
    );
  }
}
