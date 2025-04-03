import 'package:flutter/material.dart';
import 'package:utube/login_page.dart';
import 'package:utube/splash_screen.dart';
import 'package:utube/video_player_screen.dart';

import 'home_page.dart'; // Import the splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Utube',
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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const HomePage(),
        '/videoPlayer': (context) => VideoPlayerScreen(videoUrl: '', channelName: '', channelLogo: '', videoId: null, videoTitle: '', videoDescription: '', title: null,),

      },
    );
  }
}
