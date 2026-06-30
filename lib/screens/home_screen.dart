import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const bgBase     = Color(0xFF0d0d0f);
  static const bgSurface  = Color(0xFF141418);
  static const bgElevated = Color(0xFF1c1c22);
  static const accent     = Color(0xFF7c3aed);
  static const accentLight= Color(0xFF8b5cf6);
  static const border     = Color(0xFF2a2a34);
  static const textPri    = Color(0xFFF0F0F4);
  static const textSec    = Color(0xFF9090A8);
  static const textMuted  = Color(0xFF5A5A6E);
  static const green      = Color(0xFF10b981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 20),
                    _buildEditorCards(context),
                    const SizedBox(height: 24),
                    _buildFeatures(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: bgSurface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [accent, Color(0xFFa855f7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.content_cut, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EditPro', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPri)),
              Text('Video & Audio Editor', style: GoogleFonts.inter(fontSize: 9, color: textMuted)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color.fromRGBO(16, 185, 129, 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color.fromRGBO(16, 185, 129, 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 12, color: green),
              const SizedBox(width: 4),
              Text('100% Free', style: GoogleFonts.inter(fontSize: 11, color: green, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0f0a2e), Color(0xFF0a1a40)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.movie_creation, size: 30, color: Color(0xFFc4b5fd)),
            SizedBox(width: 8),
            Icon(Icons.audiotrack, size: 24, color: Color(0xFFa78bfa)),
          ]),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
              children: const [
                TextSpan(text: 'Edit videos & audio\nlike a pro. ', style: TextStyle(color: textPri)),
                TextSpan(text: '100% Free.', style: TextStyle(color: accentLight)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('No limits. No watermarks. No payments.', style: GoogleFonts.inter(fontSize: 13, color: textSec)),
        ],
      ),
    );
  }

  Widget _buildEditorCards(BuildContext context) {
    return Column(children: [
      _EditorCard(
        icon: Icons.video_library, title: 'Video Editor',
        desc: 'Trim, cut, effects, transitions, text & more',
        colors: const [Color(0xFF1e3a8a), Color(0xFF1e40af)],
        onTap: () => Navigator.pushNamed(context, '/video'),
      ),
      const SizedBox(height: 12),
      _EditorCard(
        icon: Icons.audiotrack, title: 'Audio Editor',
        desc: 'Cut, EQ, effects, voice presets & more',
        colors: const [Color(0xFF134e4a), Color(0xFF115e59)],
        onTap: () => Navigator.pushNamed(context, '/audio'),
      ),
    ]);
  }

  Widget _buildFeatures() {
    final items = [
      (Icons.flash_on,  'All Features Free',  'Everything 100% free forever'),
      (Icons.wifi_off,  'Works Offline',       'No internet needed after install'),
      (Icons.security,  'Secure & Private',    'Files never leave your device'),
    ];
    return Column(
      children: items.map((f) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgElevated, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Color.fromRGBO(124, 58, 237, 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(f.$1, size: 18, color: accentLight),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.$2, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPri)),
            Text(f.$3, style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
          ]),
        ]),
      )).toList(),
    );
  }
}

class _EditorCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final List<Color> colors;
  final VoidCallback onTap;
  const _EditorCard({required this.icon, required this.title, required this.desc, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        ]),
      ),
    );
  }
}
