import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../stores/video_editor_store.dart';

class MediaPanelWidget extends StatefulWidget {
  final VideoEditorStore store;
  final bool audioOnly;
  const MediaPanelWidget({super.key, required this.store, this.audioOnly = false});
  @override
  State<MediaPanelWidget> createState() => _MediaPanelState();
}

class _MediaPanelState extends State<MediaPanelWidget> {

  static const bgElevated = Color(0xFF1c1c22);
  static const bgOverlay  = Color(0xFF24242c);
  static const accent     = Color(0xFF7c3aed);
  static const border     = Color(0xFF2a2a34);
  static const textPri    = Color(0xFFF0F0F4);
  static const textSec    = Color(0xFF9090A8);
  static const textMuted  = Color(0xFF5A5A6E);
  static const green      = Color(0xFF10b981);

  String _filter = 'all';
  bool _loading = false;

  Future<void> _pickFiles() async {
    setState(() => _loading = true);
    try {
      final type = widget.audioOnly ? FileType.audio : FileType.media;
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: type);
      if (result == null) return;
      for (final f in result.files) {
        if (f.path == null) continue;
        final ext = f.extension?.toLowerCase() ?? '';
        final isVideo = ['mp4','mov','avi','mkv','webm','hevc','h264','h265'].contains(ext);
        final isAudio = ['mp3','wav','aac','flac','ogg','m4a','aiff'].contains(ext);
        final type = isVideo ? 'video' : isAudio ? 'audio' : 'image';
        final item = MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + f.name,
          name: f.name, type: type,
          mimeType: isVideo ? 'video/mp4' : isAudio ? 'audio/mpeg' : 'image/jpeg',
          filePath: f.path!, fileSize: f.size,
          duration: isVideo || isAudio ? 30.0 : null,
        );
        widget.store.addMedia(item);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.store.state.media.where((m) {
      if (widget.audioOnly) return m.type == 'audio';
      if (_filter == 'all') return true;
      return m.type == _filter;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft,
              child: Text(widget.audioOnly ? 'My Audio' : 'Project Media',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPri))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.upload, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(widget.audioOnly ? 'Upload Audio' : 'Upload',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        if (!widget.audioOnly)
          Container(
            height: 34,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
            child: Row(
              children: ['all','video','audio','image'].map((f) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    color: _filter == f ? bgOverlay : Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(f[0].toUpperCase() + f.substring(1),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
                        color: _filter == f ? textPri : textMuted)),
                  ),
                ),
              )).toList(),
            ),
          ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: accent))
            : media.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.upload_file, size: 32, color: textMuted),
                  const SizedBox(height: 8),
                  Text('Upload files here', style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
                  const SizedBox(height: 4),
                  Text('Double tap to add to timeline', style: GoogleFonts.inter(fontSize: 10, color: textMuted)),
                ]))
              : ListView.builder(
                  itemCount: media.length,
                  padding: const EdgeInsets.all(6),
                  itemBuilder: (_, i) {
                    final m = media[i];
                    final color = m.type == 'video' ? const Color(0xFF6366f1)
                      : m.type == 'audio' ? green : const Color(0xFFf59e0b);
                    return GestureDetector(
                      onDoubleTap: () => widget.store.addMediaToTimeline(m.id),
                      onLongPress: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: bgElevated,
                        builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.add, color: textSec),
                            title: Text('Add to Timeline', style: GoogleFonts.inter(color: textSec, fontSize: 13)),
                            onTap: () { Navigator.pop(context); widget.store.addMediaToTimeline(m.id); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Remove', style: GoogleFonts.inter(color: Colors.red, fontSize: 13)),
                            onTap: () { Navigator.pop(context); },
                          ),
                        ]),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              m.type == 'video' ? Icons.videocam
                                : m.type == 'audio' ? Icons.music_note : Icons.image,
                              size: 18, color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textPri),
                              overflow: TextOverflow.ellipsis),
                            Text(m.duration != null
                              ? '${(m.duration! ~/ 60)}:${(m.duration! % 60).toInt().toString().padLeft(2,"0")}'
                              : '${(m.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                              style: GoogleFonts.inter(fontSize: 9, color: textMuted)),
                          ])),
                          const Icon(Icons.more_vert, size: 14, color: textMuted),
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
