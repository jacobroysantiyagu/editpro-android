import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/video_editor_store.dart';

class TimelineWidget extends StatefulWidget {
  final VideoEditorStore store;
  final double zoom;
  const TimelineWidget({super.key, required this.store, required this.zoom});
  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  static const bgBase     = Color(0xFF0f0f13);
  static const bgSurface  = Color(0xFF141418);
  static const accent     = Color(0xFF7c3aed);
  static const border     = Color(0xFF2a2a34);
  static const textPri    = Color(0xFFF0F0F4);
  static const textMuted  = Color(0xFF5A5A6E);
  static const trackH     = 56.0;
  static const headerW    = 130.0;
  static const rulerH     = 26.0;

  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  double? _dragStartX;
  String? _draggingId;
  double _dragOrigStart = 0;

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  Color _trackColor(String type) {
    switch (type) {
      case 'video':   return const Color(0xFF6366f1);
      case 'audio':   return const Color(0xFF10b981);
      case 'text':    return const Color(0xFFEAB308);
      case 'overlay': return const Color(0xFF8B5CF6);
      default:        return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final state = widget.store.state;
        final zoom = widget.zoom;
        final total = state.totalDuration;
        final totalW = (total + 10) * zoom;
        final playX = state.currentTime * zoom;

        return Container(
          color: bgBase,
          child: Column(
            children: [
              // Ruler row
              SizedBox(
                height: rulerH,
                child: Row(
                  children: [
                    // Corner — add track
                    GestureDetector(
                      onTap: () => widget.store.addTrack(),
                      child: Container(
                        width: headerW,
                        decoration: const BoxDecoration(
                          color: bgSurface,
                          border: Border(right: BorderSide(color: border), bottom: BorderSide(color: border)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.add, size: 12, color: textMuted),
                          const SizedBox(width: 2),
                          Text('Track', style: GoogleFonts.inter(fontSize: 10, color: textMuted)),
                        ]),
                      ),
                    ),
                    // Ruler
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _hScroll,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: totalW,
                          height: rulerH,
                          child: CustomPaint(
                            painter: _RulerPainter(zoom: zoom, total: total, playX: playX),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tracks body
              Expanded(
                child: Row(
                  children: [
                    // Track headers
                    SizedBox(
                      width: headerW,
                      child: ListView.builder(
                        controller: _vScroll,
                        itemCount: state.tracks.length + 1,
                        itemBuilder: (_, i) {
                          if (i == state.tracks.length) {
                            return GestureDetector(
                              onTap: () => widget.store.addTrack(),
                              child: Container(
                                height: 36, color: bgSurface,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(children: [
                                  const Icon(Icons.add, size: 12, color: textMuted),
                                  const SizedBox(width: 4),
                                  Text('Add Track', style: GoogleFonts.inter(fontSize: 10, color: textMuted)),
                                ]),
                              ),
                            );
                          }
                          final track = state.tracks[i];
                          final color = _trackColor(track.type);
                          return Container(
                            height: trackH,
                            decoration: const BoxDecoration(
                              color: bgSurface,
                              border: Border(right: BorderSide(color: border), bottom: BorderSide(color: border)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(children: [
                              Icon(
                                track.type == 'video' ? Icons.videocam
                                  : track.type == 'audio' ? Icons.music_note
                                  : track.type == 'text' ? Icons.text_fields : Icons.image,
                                size: 12, color: color,
                              ),
                              const SizedBox(width: 4),
                              Expanded(child: Text(track.name,
                                style: GoogleFonts.inter(fontSize: 10, color: textPri),
                                overflow: TextOverflow.ellipsis)),
                              GestureDetector(
                                onTap: () => widget.store.updateTrack(track.id, muted: !track.muted),
                                child: Icon(track.muted ? Icons.volume_off : Icons.volume_up,
                                  size: 11, color: track.muted ? accent : textMuted),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => widget.store.updateTrack(track.id, hidden: !track.hidden),
                                child: Icon(track.hidden ? Icons.visibility_off : Icons.visibility,
                                  size: 11, color: track.hidden ? accent : textMuted),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),

                    // Clips area
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (d) {
                          final x = d.localPosition.dx + _hScroll.offset;
                          widget.store.setCurrentTime(x / zoom);
                          widget.store.clearSelection();
                        },
                        child: SingleChildScrollView(
                          controller: _hScroll,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalW,
                            child: Stack(
                              children: [
                                // Track rows + clips
                                ListView.builder(
                                  controller: _vScroll,
                                  itemCount: state.tracks.length,
                                  itemBuilder: (_, i) {
                                    final track = state.tracks[i];
                                    final color = _trackColor(track.type);
                                    return Container(
                                      height: trackH, width: totalW,
                                      decoration: BoxDecoration(
                                        color: track.muted ? const Color(0x0DFFFFFF) : Colors.transparent,
                                        border: const Border(bottom: BorderSide(color: border)),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Grid lines
                                          CustomPaint(
                                            size: Size(totalW, trackH),
                                            painter: _GridPainter(zoom: zoom),
                                          ),
                                          // Clips
                                          ...track.clips.map((clip) {
                                            final left = clip.startTime * zoom;
                                            final width = (clip.duration * zoom).clamp(4.0, double.infinity);
                                            final selected = state.selectedClipIds.contains(clip.id);
                                            return Positioned(
                                              left: left, top: 4, bottom: 4, width: width,
                                              child: GestureDetector(
                                                onTap: () => widget.store.selectClip(clip.id),
                                                onLongPress: () => _showClipMenu(context, clip.id),
                                                onPanStart: (d) {
                                                  _dragStartX = d.globalPosition.dx;
                                                  _draggingId = clip.id;
                                                  _dragOrigStart = clip.startTime;
                                                },
                                                onPanUpdate: (d) {
                                                  if (_draggingId != clip.id) return;
                                                  final dx = d.globalPosition.dx - (_dragStartX ?? 0);
                                                  final newStart = (_dragOrigStart + dx / zoom).clamp(0.0, double.infinity);
                                                  widget.store.moveClip(clip.id, clip.trackId, newStart);
                                                },
                                                onPanEnd: (_) { _draggingId = null; _dragStartX = null; },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [color.withOpacity(0.85), color.withOpacity(0.6)],
                                                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: selected ? Colors.white : Colors.white12,
                                                      width: selected ? 1.5 : 0.5,
                                                    ),
                                                    boxShadow: selected
                                                      ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 4)]
                                                      : null,
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 6, top: 3),
                                                    child: Text(clip.name,
                                                      style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.9)),
                                                      overflow: TextOverflow.ellipsis),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                // Playhead
                                Positioned(
                                  left: playX - 1, top: 0, bottom: 0,
                                  child: IgnorePointer(child: Container(width: 2, color: accent)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClipMenu(BuildContext context, String clipId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1c1c22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          _MenuItem(Icons.vertical_split, 'Split at Playhead', () { Navigator.pop(context); widget.store.splitAtPlayhead(); }),
          _MenuItem(Icons.copy_all, 'Duplicate', () { Navigator.pop(context); widget.store.duplicateSelected(); }),
          _MenuItem(Icons.history, 'Reverse', () { Navigator.pop(context); widget.store.reverseSelected(); }),
          _MenuItem(Icons.rotate_90_degrees_cw, 'Rotate 90°', () { Navigator.pop(context); widget.store.rotateSelected(); }),
          _MenuItem(Icons.flip, 'Flip', () { Navigator.pop(context); widget.store.flipSelected(); }),
          _MenuItem(Icons.delete_outline, 'Delete', () { Navigator.pop(context); widget.store.deleteSelected(); }, danger: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _MenuItem(this.icon, this.label, this.onTap, {this.danger = false});
  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : const Color(0xFF9090A8);
    return ListTile(
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: GoogleFonts.inter(fontSize: 13, color: color)),
      onTap: onTap, dense: true,
    );
  }
}

// ── Painters ───────────────────────────────────────────────
class _RulerPainter extends CustomPainter {
  final double zoom, total, playX;
  const _RulerPainter({required this.zoom, required this.total, required this.playX});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141418));
    final tick = Paint()..color = const Color(0xFF3a3a48)..strokeWidth = 1;
    final interval = zoom >= 100 ? 1.0 : zoom >= 50 ? 2.0 : zoom >= 25 ? 5.0 : 10.0;
    final sub = interval / 5;
    final dur = total > 0 ? total : 60;

    for (double t = 0; t <= dur + interval; t += sub) {
      final x = t * zoom;
      final major = (t / interval - (t / interval).round()).abs() < 0.001;
      canvas.drawLine(Offset(x, major ? 10 : 17), Offset(x, 26), tick);
      if (major) {
        final m = t ~/ 60;
        final s = (t % 60).toInt().toString().padLeft(2, '0');
        final tp = TextPainter(
          text: TextSpan(text: '$m:$s',
            style: const TextStyle(fontSize: 8, color: Color(0xFF5A5A6E), fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 2));
      }
    }
    // Playhead
    canvas.drawLine(Offset(playX, 0), Offset(playX, 26),
      Paint()..color = const Color(0xFF7c3aed)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) => old.playX != playX || old.zoom != zoom;
}

class _GridPainter extends CustomPainter {
  final double zoom;
  const _GridPainter({required this.zoom});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2a2a34).withOpacity(0.3)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += zoom) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
