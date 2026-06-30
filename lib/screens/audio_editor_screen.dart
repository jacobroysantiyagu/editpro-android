import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class AudioEditorScreen extends StatefulWidget {
  const AudioEditorScreen({super.key});
  @override
  State<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends State<AudioEditorScreen> {
  static const bgBase     = Color(0xFF0d0d0f);
  static const bgSurface  = Color(0xFF141418);
  static const bgElevated = Color(0xFF1c1c22);
  static const bgOverlay  = Color(0xFF24242c);
  static const accent     = Color(0xFF7c3aed);
  static const accentLight= Color(0xFF8b5cf6);
  static const border     = Color(0xFF2a2a34);
  static const textPri    = Color(0xFFF0F0F4);
  static const textSec    = Color(0xFF9090A8);
  static const textMuted  = Color(0xFF5A5A6E);
  static const green      = Color(0xFF10b981);

  final AudioPlayer _player = AudioPlayer();
  String? _filePath;
  String? _fileName;
  bool _isPlaying = false;
  double _currentTime = 0;
  double _totalDuration = 0;
  double _volume = 1.0;
  double _zoom = 80;
  String _projectName = 'Untitled Audio Project';
  String _activePanel = 'audio';

  // EQ
  List<double> _eqGains = List.filled(10, 0);
  String _eqPreset = 'Default';
  final Map<String, List<double>> _eqPresets = {
    'Default':    List.filled(10, 0),
    'Vocal':      [0,2,4,4,3,3,2,1,0,0],
    'Bass Boost': [8,6,4,2,0,0,0,0,0,0],
    'Podcast':    [2,2,0,0,2,3,3,2,1,0],
    'Rock':       [4,3,1,0,-1,2,3,4,3,2],
    'Pop':        [-1,2,4,4,2,0,2,3,3,2],
  };

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _currentTime = pos.inMilliseconds / 1000);
    });
    _player.durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => _totalDuration = dur.inMilliseconds / 1000);
    });
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _isPlaying = s.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    setState(() { _filePath = file.path; _fileName = file.name; });
    await _player.setFilePath(file.path!);
  }

  String _fmtTime(double s) {
    final m = s ~/ 60;
    final sec = (s % 60).toInt().toString().padLeft(2, '0');
    final ms  = ((s % 1) * 100).toInt().toString().padLeft(2, '0');
    return '${m.toString().padLeft(2, '0')}:$sec.$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Row(
                children: [
                  _buildLeftIcons(),
                  _buildMediaList(),
                  Expanded(child: _buildCenter()),
                  _buildRightPanel(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48, color: bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18, color: textSec),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_projectName, style: GoogleFonts.inter(fontSize: 12, color: textPri, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: textMuted),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showExportDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [accent, accentLight]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.download, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('Export Audio', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, size: 18, color: textSec),
        ],
      ),
    );
  }

  Widget _buildLeftIcons() {
    final items = [
      (Icons.music_note,   'Audio'),
      (Icons.auto_awesome, 'Effects'),
      (Icons.volume_up,    'Volume'),
      (Icons.show_chart,   'Fade'),
      (Icons.content_cut,  'Split'),
      (Icons.speed,        'Speed'),
      (Icons.equalizer,    'EQ'),
      (Icons.waves,        'Noise'),
      (Icons.history,      'Reverse'),
      (Icons.mic,          'Record'),
    ];
    return Container(
      width: 52, color: bgSurface,
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () => setState(() => _activePanel = item.$2.toLowerCase()),
            child: Column(
              children: [
                Icon(item.$1, size: 17,
                  color: _activePanel == item.$2.toLowerCase() ? accentLight : textMuted),
                const SizedBox(height: 2),
                Text(item.$2, style: GoogleFonts.inter(fontSize: 8,
                  color: _activePanel == item.$2.toLowerCase() ? accentLight : textMuted)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMediaList() {
    return Container(
      width: 180,
      decoration: const BoxDecoration(
        color: bgSurface, border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
            child: Column(children: [
              Text('My Audio', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPri)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.upload, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Upload Audio', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _filePath != null
              ? ListTile(
                  leading: const Icon(Icons.music_note, color: green, size: 20),
                  title: Text(_fileName ?? '', style: GoogleFonts.inter(fontSize: 11, color: textPri), overflow: TextOverflow.ellipsis),
                  subtitle: Text(_fmtTime(_totalDuration), style: GoogleFonts.inter(fontSize: 9, color: textMuted)),
                  onTap: () {},
                )
              : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.music_note, size: 28, color: textMuted),
                  const SizedBox(height: 8),
                  Text('Upload audio\nto start', style: GoogleFonts.inter(fontSize: 11, color: textMuted), textAlign: TextAlign.center),
                ])),
          ),
          // Voice presets
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: border))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VOICE PRESETS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4,
                children: ['Podcast','Studio','Radio','Robot','Alien','Cave','Deep','LoFi'].map((name) =>
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$name preset applied', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                      backgroundColor: accent, duration: const Duration(seconds: 1))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: bgOverlay, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
                      child: Text(name, style: GoogleFonts.inter(fontSize: 9, color: textMuted)),
                    ),
                  )
                ).toList(),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter() {
    return Column(
      children: [
        // Waveform
        Container(
          height: 160, color: const Color(0xFF080810),
          child: _filePath != null
            ? Stack(
                children: [
                  // Fake waveform
                  CustomPaint(size: const Size(double.infinity, 160), painter: _WaveformPainter()),
                  // Playhead
                  Positioned(
                    left: _totalDuration > 0
                      ? (MediaQuery.of(context).size.width * 0.4 * (_currentTime / _totalDuration))
                      : 0,
                    top: 0, bottom: 0,
                    child: Container(width: 2, color: accent),
                  ),
                ],
              )
            : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.audiotrack, size: 40, color: textMuted),
                const SizedBox(height: 8),
                Text('Upload an audio file to start', style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _pickFile,
                  icon: const Icon(Icons.upload, size: 14),
                  label: const Text('Upload Audio')),
              ])),
        ),

        // Effects bar
        Container(
          height: 44, color: bgSurface,
          child: Row(children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['Normalize','Equalizer','Compressor','Reverb','Echo','Noise Reduction'].map((e) =>
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
                      child: Text(e, style: GoogleFonts.inter(fontSize: 11, color: textSec)),
                    )
                  ).toList(),
                ),
              ),
            ),
            IconButton(onPressed: () => setState(() => _zoom = (_zoom * 0.8).clamp(20, 1000)),
              icon: const Icon(Icons.zoom_out, size: 14, color: textMuted)),
            IconButton(onPressed: () => setState(() => _zoom = (_zoom * 1.25).clamp(20, 1000)),
              icon: const Icon(Icons.zoom_in, size: 14, color: textMuted)),
          ]),
        ),

        // Audio tracks
        Expanded(
          child: Container(
            color: const Color(0xFF0f0f13),
            child: Column(
              children: [
                // Ruler
                Container(height: 24, color: bgSurface,
                  child: CustomPaint(size: const Size(double.infinity, 24),
                    painter: _RulerPainter(zoom: _zoom, duration: _totalDuration))),
                // Track
                Container(
                  height: 56,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
                  child: Row(children: [
                    Container(
                      width: 140, color: bgSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        const Icon(Icons.volume_up, size: 12, color: green),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Audio Track', style: GoogleFonts.inter(fontSize: 11, color: textPri), overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.volume_up, size: 10, color: textMuted),
                        const Icon(Icons.lock_open, size: 10, color: textMuted),
                      ]),
                    ),
                    Expanded(
                      child: _filePath != null
                        ? Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [green.withOpacity(0.8), green.withOpacity(0.5)]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, top: 3),
                              child: Text(_fileName ?? '', style: GoogleFonts.inter(fontSize: 9, color: Colors.white70), overflow: TextOverflow.ellipsis),
                            ),
                          )
                        : const SizedBox(),
                    ),
                  ]),
                ),
                // Add track
                GestureDetector(
                  onTap: () {},
                  child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      const Icon(Icons.add, size: 12, color: textMuted),
                      const SizedBox(width: 4),
                      Text('Add Audio Track', style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
                    ])),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 170,
      decoration: const BoxDecoration(color: bgSurface, border: Border(left: BorderSide(color: border))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
            child: Text('Adjustments', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPri)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _AdjRow('Volume', _volume, 0, 2, (v) { setState(() => _volume = v); _player.setVolume(v); },
                    displayValue: '${((_volume - 1) * 10).toStringAsFixed(1)} dB'),
                  _AdjRow('Fade In',  0, 0, 10, (v) {}),
                  _AdjRow('Fade Out', 0, 0, 10, (v) {}),
                  _AdjRow('Speed',    1, 0.25, 4, (v) { _player.setSpeed(v); }, displayValue: '1.00x'),
                  const SizedBox(height: 8),
                  const Divider(color: border),
                  const SizedBox(height: 8),
                  Text('Equalizer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textPri)),
                  const SizedBox(height: 8),
                  // EQ Preset
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
                    child: DropdownButton<String>(
                      value: _eqPreset, isExpanded: true,
                      dropdownColor: bgElevated, underline: const SizedBox(),
                      style: GoogleFonts.inter(fontSize: 11, color: textSec),
                      items: _eqPresets.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (v) => setState(() { _eqPreset = v!; _eqGains = List.of(_eqPresets[v]!); }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // EQ sliders
                  SizedBox(
                    height: 100,
                    child: Row(
                      children: List.generate(10, (i) {
                        final labels = ['60','170','310','600','1k','3k','6k','12k','14k','16k'];
                        return Expanded(
                          child: Column(children: [
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Slider(
                                  value: _eqGains[i].clamp(-12.0, 12.0),
                                  min: -12, max: 12,
                                  onChanged: (v) => setState(() { _eqGains[i] = v; _eqPreset = 'Custom'; }),
                                  activeColor: accentLight,
                                  inactiveColor: border,
                                ),
                              ),
                            ),
                            Text(labels[i], style: GoogleFonts.inter(fontSize: 7, color: textMuted)),
                          ]),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // EQ Preset buttons
                  Wrap(spacing: 4, runSpacing: 4,
                    children: ['Default','Vocal','Bass Boost','Podcast','Rock','Pop'].map((p) =>
                      GestureDetector(
                        onTap: () => setState(() { _eqPreset = p; _eqGains = List.of(_eqPresets[p]!); }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: _eqPreset == p ? accent : bgElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _eqPreset == p ? accent : border),
                          ),
                          child: Text(p, style: GoogleFonts.inter(fontSize: 9, color: _eqPreset == p ? Colors.white : textMuted)),
                        ),
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() { _eqGains = List.filled(10, 0); _eqPreset = 'Default'; }),
                    child: Container(
                      alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
                      child: Text('Reset', style: GoogleFonts.inter(fontSize: 10, color: textSec)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 64, color: bgBase,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.music_note, size: 16, color: accentLight),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_fileName ?? 'No file loaded',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textPri)),
            Text(_totalDuration > 0 ? _fmtTime(_totalDuration) : '--:--',
              style: GoogleFonts.inter(fontSize: 9, color: textMuted)),
          ]),
          const SizedBox(width: 16),
          _TBtn(icon: Icons.skip_previous, onTap: () => _player.seek(Duration.zero)),
          _TBtn(icon: Icons.fast_rewind, onTap: () async {
            final pos = await _player.position;
            _player.seek(Duration(milliseconds: (pos.inMilliseconds - 5000).clamp(0, 999999999)));
          }),
          GestureDetector(
            onTap: () async { _isPlaying ? await _player.pause() : await _player.play(); },
            child: Container(width: 40, height: 40,
              decoration: const BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 20, color: Colors.white)),
          ),
          _TBtn(icon: Icons.fast_forward, onTap: () async {
            final pos = await _player.position;
            _player.seek(Duration(milliseconds: pos.inMilliseconds + 5000));
          }),
          _TBtn(icon: Icons.skip_next, onTap: () => _player.seek(Duration(seconds: _totalDuration.toInt()))),
          const SizedBox(width: 8),
          Text(_fmtTime(_currentTime), style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace')),
          Text(' / ', style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
          Text(_fmtTime(_totalDuration), style: const TextStyle(fontSize: 12, color: Color(0xFF9090A8), fontFamily: 'monospace')),
          const Spacer(),
          const Icon(Icons.volume_up, size: 14, color: textMuted),
          SizedBox(width: 80, child: Slider(value: _volume, min: 0, max: 2,
            onChanged: (v) { setState(() => _volume = v); _player.setVolume(v); },
            activeColor: accentLight, inactiveColor: border)),
        ],
      ),
    );
  }

  Widget _AdjRow(String label, double value, double min, double max, ValueChanged<double> onChange, {String? displayValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: textSec)),
          Text(displayValue ?? value.toStringAsFixed(1),
            style: TextStyle(fontSize: 10, color: textPri, fontFamily: 'monospace')),
        ]),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChange,
          activeColor: accentLight, inactiveColor: border),
      ]),
    );
  }

  void _showExportDialog() {
    String fmt = 'mp3';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        backgroundColor: bgElevated,
        title: Text('Export Audio', style: GoogleFonts.inter(color: textPri, fontSize: 14, fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Format', style: GoogleFonts.inter(fontSize: 11, color: textSec)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: ['mp3','wav','aac','flac','ogg'].map((f) => ChoiceChip(
            label: Text(f.toUpperCase(), style: GoogleFonts.inter(fontSize: 10)),
            selected: fmt == f, onSelected: (_) => setD(() => fmt = f),
            selectedColor: accent, backgroundColor: bgSurface,
            labelStyle: TextStyle(color: fmt == f ? Colors.white : textSec),
          )).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: textSec))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Export as ${fmt.toUpperCase()} - Install full version for FFmpeg export',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                backgroundColor: accent,
              ));
            },
            icon: const Icon(Icons.download, size: 14),
            label: Text('Export ${fmt.toUpperCase()}'),
          ),
        ],
      )),
    );
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: const Color(0xFF9090A8)),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    constraints: const BoxConstraints(),
  );
}

// ── Waveform Painter ───────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080810));
    final paint = Paint()..color = const Color(0xFF10b981)..strokeWidth = 1;
    final mid = size.height / 2;
    for (int x = 0; x < size.width.toInt(); x++) {
      final h = (mid * 0.7 * (0.3 + 0.7 * ((x * 7919) % 100) / 100));
      canvas.drawLine(Offset(x.toDouble(), mid - h), Offset(x.toDouble(), mid + h), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Ruler Painter ──────────────────────────────────────────
class _RulerPainter extends CustomPainter {
  final double zoom, duration;
  const _RulerPainter({required this.zoom, required this.duration});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141418));
    final tickPaint = Paint()..color = const Color(0xFF3a3a48)..strokeWidth = 1;
    final interval = zoom >= 100 ? 1.0 : zoom >= 50 ? 2.0 : 5.0;
    for (double t = 0; t <= (duration > 0 ? duration : 60) + interval; t += interval / 5) {
      final x = t * zoom;
      final major = (t / interval - (t / interval).round()).abs() < 0.001;
      canvas.drawLine(Offset(x, major ? 10 : 16), Offset(x, 24), tickPaint);
      if (major) {
        final m = t ~/ 60;
        final s = (t % 60).toInt().toString().padLeft(2, '0');
        final tp = TextPainter(
          text: TextSpan(text: '$m:$s', style: const TextStyle(fontSize: 8, color: Color(0xFF5A5A6E), fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 1));
      }
    }
  }
  @override
  bool shouldRepaint(covariant _RulerPainter old) => old.zoom != zoom || old.duration != duration;
}
