import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/video_editor_screen.dart';
import 'screens/audio_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const EditProApp());
}

class EditProApp extends StatelessWidget {
  const EditProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditPro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(),
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/video': (_) => const VideoEditorScreen(),
        '/audio': (_) => const AudioEditorScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    const accent = Color(0xFF7c3aed);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0d0d0f),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: Color(0xFF141418),
        onSurface: Color(0xFFF0F0F4),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
