import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/video_editor_store.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/media_panel_widget.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});
  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  static const bgBase     = Color(0xFF0d0d0f);
  static const bgSurface  = Color(0xFF141418);
  static const bgElevated = Color(0xFF1c1c22);
  static const accent     = Color(0xFF7c3aed);
  static const accentLight= Color(0xFF8b5cf6);
  static const border     = Color(0xFF2a2a34);
  static const textPri    = Color(0xFFF0F0F4);
  static const textSec    = Color(0xFF9090A8);
  static const textMuted  = Color(0xFF5A5A6E);

  final VideoEditorStore _store = VideoEditorStore();
  String _activePanel = 'media';
  double _zoom = 50.0;
  String _activeInspectorTab = 'video';

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        return Scaffold(
          backgroundColor: bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: isLandscape
                    ? _buildLandscape()
                    : _buildPortrait(),
                ),
              ],
            ),
          ),
        );
      },
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
          GestureDetector(
            onTap: _showRenameDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_store.projectName, style: GoogleFonts.inter(fontSize: 12, color: textPri, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: textMuted),
              ]),
            ),
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
                Text('Export', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscape() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildPreview()),
              _buildEditToolbar(),
              SizedBox(height: 220, child: TimelineWidget(store: _store, zoom: _zoom)),
            ],
          ),
        ),
        _buildInspector(),
      ],
    );
  }

  Widget _buildPortrait() {
    return Column(
      children: [
        SizedBox(height: 200, child: _buildPreview()),
        _buildEditToolbar(),
        SizedBox(height: 180, child: TimelineWidget(store: _store, zoom: _zoom)),
        Expanded(child: _buildSidebar()),
      ],
    );
  }

  Widget _buildSidebar() {
    final panels = [
      ('media',   Icons.folder,        'Media'),
      ('audio',   Icons.music_note,    'Audio'),
      ('text',    Icons.text_fields,   'Text'),
      ('effects', Icons.auto_awesome,  'Effects'),
      ('filters', Icons.filter,        'Filters'),
      ('adjust',  Icons.tune,          'Adjust'),
    ];
    return Container(
      width: MediaQuery.of(context).orientation == Orientation.landscape ? 260 : double.infinity,
      decoration: const BoxDecoration(color: bgSurface, border: Border(right: BorderSide(color: border))),
      child: Row(
        children: [
          // Icon strip
          Container(
            width: 52,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: border))),
            child: Column(
              children: panels.map((p) => _SidebarBtn(
                icon: p.$2, label: p.$3,
                active: _activePanel == p.$1,
                onTap: () => setState(() => _activePanel = p.$1),
              )).toList(),
            ),
          ),
          // Panel content
          Expanded(child: _buildPanelContent()),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    switch (_activePanel) {
      case 'media':
      case 'audio':
        return MediaPanelWidget(store: _store, audioOnly: _activePanel == 'audio');
      case 'effects':
        return _EffectsPanelWidget(store: _store);
      case 'text':
        return _TextPanelWidget(store: _store);
      case 'filters':
        return _FiltersPanelWidget(store: _store);
      default:
        return _AdjustPanelWidget(store: _store);
    }
  }

  Widget _buildPreview() {
    final state = _store.state;
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: state.tracks.every((t) => t.clips.isEmpty)
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.movie_creation_outlined, size: 48, color: Color(0xFF2a2a34)),
                    const SizedBox(height: 12),
                    Text('Add media to start editing',
                      style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_circle_outline, size: 56, color: accentLight),
                    const SizedBox(height: 8),
                    Text('${state.tracks.fold(0, (s, t) => s + t.clips.length)} clips on timeline',
                      style: GoogleFonts.inter(fontSize: 12, color: textSec)),
                  ]),
            ),
          ),
          // Controls
          Container(
            height: 44, color: bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _TransBtn(icon: Icons.skip_previous, onTap: () => _store.setCurrentTime(0)),
                _TransBtn(
                  icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                  filled: true,
                  onTap: _store.togglePlay,
                ),
                _TransBtn(icon: Icons.stop, onTap: () { _store.setPlaying(false); _store.setCurrentTime(0); }),
                _TransBtn(icon: Icons.skip_next, onTap: () => _store.setCurrentTime(state.totalDuration)),
                const SizedBox(width: 8),
                Text(_fmtTime(state.currentTime),
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace')),
                Text(' / ', style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
                Text(_fmtTime(state.totalDuration),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9090A8), fontFamily: 'monospace')),
                const Spacer(),
                const Icon(Icons.fullscreen, size: 16, color: textMuted),
              ],
            ),
          ),
          // Seek bar
          GestureDetector(
            onTapDown: (d) {
              final w = context.size?.width ?? 1;
              _store.setCurrentTime((d.localPosition.dx / w) * state.totalDuration);
            },
            child: Container(
              height: 3, color: const Color(0xFF2a2a34),
              child: FractionallySizedBox(
                widthFactor: state.totalDuration > 0
                  ? (state.currentTime / state.totalDuration).clamp(0.0, 1.0)
                  : 0,
                alignment: Alignment.centerLeft,
                child: Container(color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditToolbar() {
    final actions = [
      ('Cut',       Icons.content_cut,         () => _store.cutSelected()),
      ('Copy',      Icons.content_copy,         () => _store.copySelected()),
      ('Delete',    Icons.delete_outline,       () => _store.deleteSelected()),
      ('Split',     Icons.vertical_split,       () => _store.splitAtPlayhead()),
      ('Rotate',    Icons.rotate_90_degrees_cw, () => _store.rotateSelected()),
      ('Flip',      Icons.flip,                 () => _store.flipSelected()),
      ('Reverse',   Icons.history,              () => _store.reverseSelected()),
      ('Duplicate', Icons.copy_all,             () => _store.duplicateSelected()),
    ];
    return Container(
      height: 40, color: bgSurface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: actions.map((a) => GestureDetector(
                  onTap: a.$3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(a.$2, size: 13, color: textSec),
                      const SizedBox(width: 4),
                      Text(a.$1, style: GoogleFonts.inter(fontSize: 11, color: textSec)),
                    ]),
                  ),
                )).toList(),
              ),
            ),
          ),
          IconButton(onPressed: () => setState(() => _zoom = (_zoom * 0.8).clamp(10, 500)),
            icon: const Icon(Icons.zoom_out, size: 16, color: textMuted)),
          IconButton(onPressed: () => setState(() => _zoom = (_zoom * 1.25).clamp(10, 500)),
            icon: const Icon(Icons.zoom_in, size: 16, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildInspector() {
    final tabs = ['Video', 'Audio', 'Speed', 'Adjust'];
    final selectedId = _store.state.selectedClipIds.isNotEmpty ? _store.state.selectedClipIds.first : null;

    return Container(
      width: 200,
      decoration: const BoxDecoration(color: bgSurface, border: Border(left: BorderSide(color: border))),
      child: Column(
        children: [
          // Tab bar
          Container(
            height: 36,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
            child: Row(
              children: tabs.map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeInspectorTab = t.toLowerCase()),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: _activeInspectorTab == t.toLowerCase() ? accentLight : Colors.transparent,
                        width: 2,
                      )),
                    ),
                    child: Text(t, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
                      color: _activeInspectorTab == t.toLowerCase() ? accentLight : textMuted)),
                  ),
                ),
              )).toList(),
            ),
          ),
          // Content
          Expanded(
            child: selectedId == null
              ? Center(child: Text('Select a clip', style: GoogleFonts.inter(fontSize: 11, color: textMuted)))
              : _buildInspectorContent(selectedId),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorContent(String clipId) {
    TimelineClip? clip;
    for (final track in _store.state.tracks) {
      for (final c in track.clips) {
        if (c.id == clipId) { clip = c; break; }
      }
      if (clip != null) break;
    }
    if (clip == null) return const SizedBox();
    final TimelineClip c0 = clip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          if (_activeInspectorTab == 'video') ...[
            _SectionLabel('Transform'),
            _SliderRow('Scale', clip.transform.scaleX * 100, 10, 300, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(transform: c.transform.copyWith(scaleX: v/100, scaleY: v/100))),
              displayValue: '${(clip.transform.scaleX * 100).toStringAsFixed(0)}%'),
            _SliderRow('Rotation', clip.transform.rotation, -180, 180, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(transform: c.transform.copyWith(rotation: v))),
              unit: '°'),
            _SliderRow('Opacity', clip.transform.opacity * 100, 0, 100, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(transform: c.transform.copyWith(opacity: v/100))),
              unit: '%'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _ToggleBtn('Flip H', clip.transform.flipX,
                () => _store.updateClip(clipId, (c) => c.copyWith(transform: c.transform.copyWith(flipX: !c.transform.flipX))))),
              const SizedBox(width: 6),
              Expanded(child: _ToggleBtn('Flip V', clip.transform.flipY,
                () => _store.updateClip(clipId, (c) => c.copyWith(transform: c.transform.copyWith(flipY: !c.transform.flipY))))),
            ]),
          ],
          if (_activeInspectorTab == 'audio') ...[
            _SectionLabel('Audio'),
            _SliderRow('Volume', clip.volume * 100, 0, 200, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(volume: v/100)), unit: '%'),
            _SliderRow('Fade In', clip.fadeIn, 0, 10, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(fadeIn: v)), unit: 's'),
            _SliderRow('Fade Out', clip.fadeOut, 0, 10, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(fadeOut: v)), unit: 's'),
            _SliderRow('Pan', clip.pan, -1, 1, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(pan: v))),
          ],
          if (_activeInspectorTab == 'speed') ...[
            _SectionLabel('Speed'),
            _SliderRow('Speed', clip.speed, 0.1, 10, (v) =>
              _store.updateClip(clipId, (c) => c.copyWith(speed: v)),
              displayValue: '${clip.speed.toStringAsFixed(2)}x'),
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4,
              children: [0.25, 0.5, 1.0, 1.5, 2.0, 4.0].map((p) => GestureDetector(
                onTap: () => _store.updateClip(clipId, (c) => c.copyWith(speed: p)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (c0.speed - p).abs() < 0.01 ? accent : bgElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: border),
                  ),
                  child: Text('${p}x', style: GoogleFonts.inter(fontSize: 10,
                    color: (c0.speed - p).abs() < 0.01 ? Colors.white : textSec)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Checkbox(
                value: clip.reverse,
                onChanged: (v) => _store.updateClip(clipId, (c) => c.copyWith(reverse: v ?? false)),
                fillColor: MaterialStateProperty.all(accent), checkColor: Colors.white,
              ),
              Text('Reverse', style: GoogleFonts.inter(fontSize: 11, color: textSec)),
            ]),
          ],
          if (_activeInspectorTab == 'adjust') ...[
            _SectionLabel('Color'),
            _SliderRow('Brightness', 0, -100, 100, (v) {}),
            _SliderRow('Contrast',   0, -100, 100, (v) {}),
            _SliderRow('Saturation', 0, -100, 100, (v) {}),
            _SliderRow('Exposure',   0, -100, 100, (v) {}),
            _SliderRow('Hue',        0, -180, 180, (v) {}, unit: '°'),
          ],
        ],
      ),
    );
  }

  String _fmtTime(double s) {
    final m = s ~/ 60;
    final sec = (s % 60).toInt().toString().padLeft(2, '0');
    final ms  = ((s % 1) * 100).toInt().toString().padLeft(2, '0');
    return '${m.toString().padLeft(2, '0')}:$sec.$ms';
  }

  void _showRenameDialog() {
    final ctrl = TextEditingController(text: _store.projectName);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: bgElevated,
      title: Text('Rename Project', style: GoogleFonts.inter(color: textPri, fontSize: 14)),
      content: TextField(
        controller: ctrl, style: const TextStyle(color: textPri),
        decoration: InputDecoration(
          hintText: 'Project name', hintStyle: const TextStyle(color: textMuted),
          filled: true, fillColor: bgSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: textSec))),
        ElevatedButton(onPressed: () { _store.setProjectName(ctrl.text); Navigator.pop(context); }, child: const Text('Rename')),
      ],
    ));
  }

  void _showExportDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: bgElevated,
      title: Text('Export Video', style: GoogleFonts.inter(color: textPri, fontSize: 14, fontWeight: FontWeight.w600)),
      content: Text(
        'To export video, install the full version with FFmpeg support on your device.\n\nProject has ${_store.state.tracks.fold(0, (s, t) => s + t.clips.length)} clips.',
        style: GoogleFonts.inter(color: textSec, fontSize: 12),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ));
  }
}

// ── Helper Widgets ─────────────────────────────────────────
class _SidebarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SidebarBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Color.fromRGBO(124, 58, 237, 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: active ? const Color(0xFF8b5cf6) : const Color(0xFF5A5A6E)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500,
            color: active ? const Color(0xFF8b5cf6) : const Color(0xFF5A5A6E))),
        ]),
      ),
    );
  }
}

class _TransBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _TransBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: filled ? 32 : 28, height: filled ? 32 : 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF7c3aed) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: filled ? 16 : 14, color: filled ? Colors.white : const Color(0xFF9090A8)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Align(alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
        color: const Color(0xFF5A5A6E), letterSpacing: 0.5))),
  );
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChange;
  final String? unit, displayValue;
  const _SliderRow(this.label, this.value, this.min, this.max, this.onChange, {this.unit, this.displayValue});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 60, child: Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9090A8)))),
      Expanded(child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChange,
        activeColor: const Color(0xFF8b5cf6), inactiveColor: const Color(0xFF2a2a34))),
      SizedBox(width: 36, child: Text(
        displayValue ?? '${value.toStringAsFixed(0)}${unit ?? ''}',
        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFFF0F0F4)),
        textAlign: TextAlign.right)),
    ]),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF7c3aed) : const Color(0xFF1c1c22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? const Color(0xFF7c3aed) : const Color(0xFF2a2a34)),
      ),
      alignment: Alignment.center,
      child: Text(label, style: GoogleFonts.inter(fontSize: 10,
        color: active ? Colors.white : const Color(0xFF9090A8), fontWeight: FontWeight.w500)),
    ),
  );
}

// ── Effects Panel ──────────────────────────────────────────
class _EffectsPanelWidget extends StatelessWidget {
  final VideoEditorStore store;
  const _EffectsPanelWidget({required this.store});

  static const _effects = [
    (Icons.blur_on,       'Blur'),
    (Icons.brightness_6,  'Brightness'),
    (Icons.contrast,      'Contrast'),
    (Icons.color_lens,    'Saturation'),
    (Icons.camera,        'Exposure'),
    (Icons.grain,         'Film Grain'),
    (Icons.photo_filter,  'Vintage'),
    (Icons.tv,            'VHS'),
    (Icons.bolt,          'Glitch'),
    (Icons.filter_b_and_w,'B & W'),
    (Icons.invert_colors, 'Invert'),
    (Icons.vignette,      'Vignette'),
    (Icons.lens_blur,     'Glow'),
    (Icons.flare,         'Lens Flare'),
    (Icons.grid_on,       'Pixelate'),
    (Icons.filter_vintage,'Sepia'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2a2a34)))),
          child: Text('Video Effects', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF0F0F4))),
        ),
        if (store.state.selectedClipIds.isEmpty)
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAB308).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.2)),
            ),
            child: Text('Select a clip to apply effects', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCA8A04))),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2,
            ),
            itemCount: _effects.length,
            itemBuilder: (_, i) {
              final eff = _effects[i];
              return GestureDetector(
                onTap: () {
                  if (store.state.selectedClipIds.isEmpty) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Applied ${eff.$2}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFF7c3aed),
                    duration: const Duration(seconds: 1),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1c1c22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2a2a34)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Icon(eff.$1, size: 18, color: const Color(0xFF8b5cf6)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(eff.$2, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF0F0F4)))),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Text Panel ─────────────────────────────────────────────
class _TextPanelWidget extends StatefulWidget {
  final VideoEditorStore store;
  const _TextPanelWidget({required this.store});
  @override
  State<_TextPanelWidget> createState() => _TextPanelState();
}

class _TextPanelState extends State<_TextPanelWidget> {
  final _ctrl = TextEditingController(text: 'Your Text');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2a2a34)))),
          child: Column(children: [
            Text('Text', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF0F0F4))),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF0F0F4)),
              decoration: InputDecoration(
                hintText: 'Enter text...',
                hintStyle: const TextStyle(color: Color(0xFF5A5A6E)),
                filled: true, fillColor: const Color(0xFF1c1c22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2a2a34))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Text added: ${_ctrl.text}', style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: const Color(0xFF7c3aed))),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Text'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Text('Presets', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5A5A6E))),
              const SizedBox(height: 6),
              ...['Title', 'Subtitle', 'Lower Third', 'Caption'].map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1c1c22), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2a2a34)),
                ),
                child: Text(p, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9090A8))),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Filters Panel ──────────────────────────────────────────
class _FiltersPanelWidget extends StatefulWidget {
  final VideoEditorStore store;
  const _FiltersPanelWidget({required this.store});
  @override
  State<_FiltersPanelWidget> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanelWidget> {
  String _active = 'Original';
  final _filters = ['Original','Vivid','Fade','Cold','Warm','B&W','Sepia','Drama','Golden','Midnight','Summer','Noir'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2a2a34)))),
          child: Text('Filters', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF0F0F4))),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _filters.length,
            itemBuilder: (_, i) {
              final f = _filters[i];
              return GestureDetector(
                onTap: () => setState(() => _active = f),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1c1c22), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _active == f ? const Color(0xFF7c3aed) : const Color(0xFF2a2a34), width: _active == f ? 2 : 1),
                  ),
                  child: Column(children: [
                    Expanded(child: Container(
                      decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.green.shade900, Colors.red.shade900])),
                    )),
                    Padding(padding: const EdgeInsets.all(6),
                      child: Text(f, style: GoogleFonts.inter(fontSize: 10,
                        color: _active == f ? const Color(0xFF8b5cf6) : const Color(0xFF9090A8)))),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Adjust Panel ───────────────────────────────────────────
class _AdjustPanelWidget extends StatelessWidget {
  final VideoEditorStore store;
  const _AdjustPanelWidget({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2a2a34)))),
          child: Text('Adjust', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF0F0F4))),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _SliderRow('Brightness', 0, -100, 100, (v) {}),
              _SliderRow('Contrast',   0, -100, 100, (v) {}),
              _SliderRow('Saturation', 0, -100, 100, (v) {}),
              _SliderRow('Exposure',   0, -100, 100, (v) {}),
              _SliderRow('Hue',        0, -180, 180, (v) {}, unit: '°'),
              _SliderRow('Temperature',0, -100, 100, (v) {}),
              _SliderRow('Tint',       0, -100, 100, (v) {}),
              _SliderRow('Sharpen',    0, 0,    100, (v) {}),
              _SliderRow('Blur',       0, 0,    50,  (v) {}),
              _SliderRow('Vignette',   0, 0,    100, (v) {}),
            ],
          ),
        ),
      ],
    );
  }
}
