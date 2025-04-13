import 'package:flutter/material.dart';
import 'package:utube/SharedPref.dart';
import 'package:utube/home_page.dart';
import 'package:utube/login_page.dart';
import 'package:utube/video_player_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    final enrollment = await SharedPrefService.getString('enrollmentNumber');
    if (enrollment != null && enrollment.isNotEmpty) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          } else {
            return snapshot.data!;
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/homepage': (context) => const HomePage(),
        '/videoPlayer': (context) => VideoPlayerScreen(
          videoUrl: '',
          channelName: '',
          channelLogo: '',
          videoId: null,
          videoTitle: '',
          videoDescription: '',
          title: null,
        ),
      },
    );
  }
}
