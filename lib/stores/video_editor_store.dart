import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ClipTransform {
  final double x, y, scaleX, scaleY, rotation, opacity;
  final bool flipX, flipY;
  const ClipTransform({
    this.x = 0, this.y = 0, this.scaleX = 1, this.scaleY = 1,
    this.rotation = 0, this.opacity = 1, this.flipX = false, this.flipY = false,
  });
  ClipTransform copyWith({
    double? x, double? y, double? scaleX, double? scaleY,
    double? rotation, double? opacity, bool? flipX, bool? flipY,
  }) => ClipTransform(
    x: x ?? this.x, y: y ?? this.y,
    scaleX: scaleX ?? this.scaleX, scaleY: scaleY ?? this.scaleY,
    rotation: rotation ?? this.rotation, opacity: opacity ?? this.opacity,
    flipX: flipX ?? this.flipX, flipY: flipY ?? this.flipY,
  );
}

class MediaItem {
  final String id, name, type, mimeType, filePath;
  final double? duration;
  final int? width, height;
  final String? thumbnailPath;
  final int fileSize;
  const MediaItem({
    required this.id, required this.name, required this.type,
    required this.mimeType, required this.filePath,
    this.duration, this.width, this.height,
    this.thumbnailPath, required this.fileSize,
  });
  MediaItem copyWith({String? thumbnailPath}) => MediaItem(
    id: id, name: name, type: type, mimeType: mimeType,
    filePath: filePath, duration: duration, width: width, height: height,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath, fileSize: fileSize,
  );
}

class TimelineClip {
  final String id, trackId, type, name, mediaId;
  final double startTime, duration, trimStart, trimEnd;
  final double speed, volume, pan, fadeIn, fadeOut, pitch;
  final bool reverse, muted;
  final ClipTransform transform;
  const TimelineClip({
    required this.id, required this.trackId, required this.type,
    required this.name, required this.mediaId,
    required this.startTime, required this.duration,
    required this.trimStart, required this.trimEnd,
    this.speed = 1.0, this.volume = 1.0, this.pan = 0.0,
    this.fadeIn = 0.0, this.fadeOut = 0.0, this.pitch = 0.0,
    this.reverse = false, this.muted = false,
    this.transform = const ClipTransform(),
  });
  TimelineClip copyWith({
    String? id, String? trackId, double? startTime, double? duration,
    double? trimStart, double? trimEnd, double? speed, double? volume,
    double? pan, double? fadeIn, double? fadeOut, double? pitch,
    bool? reverse, bool? muted, ClipTransform? transform,
  }) => TimelineClip(
    id: id ?? this.id, trackId: trackId ?? this.trackId,
    type: type, name: name, mediaId: mediaId,
    startTime: startTime ?? this.startTime, duration: duration ?? this.duration,
    trimStart: trimStart ?? this.trimStart, trimEnd: trimEnd ?? this.trimEnd,
    speed: speed ?? this.speed, volume: volume ?? this.volume,
    pan: pan ?? this.pan, fadeIn: fadeIn ?? this.fadeIn,
    fadeOut: fadeOut ?? this.fadeOut, pitch: pitch ?? this.pitch,
    reverse: reverse ?? this.reverse, muted: muted ?? this.muted,
    transform: transform ?? this.transform,
  );
}

class Track {
  final String id, type, name;
  final bool locked, hidden, muted, solo;
  final double volume;
  final List<TimelineClip> clips;
  final int colorValue;
  const Track({
    required this.id, required this.type, required this.name,
    this.locked = false, this.hidden = false,
    this.muted = false, this.solo = false,
    this.volume = 1.0, this.clips = const [],
    this.colorValue = 0xFF6366f1,
  });
  Track copyWith({
    List<TimelineClip>? clips, bool? muted, bool? hidden, bool? locked, bool? solo,
  }) => Track(
    id: id, type: type, name: name,
    locked: locked ?? this.locked, hidden: hidden ?? this.hidden,
    muted: muted ?? this.muted, solo: solo ?? this.solo,
    volume: volume, clips: clips ?? this.clips, colorValue: colorValue,
  );
}

class VideoEditorState {
  final String projectName;
  final List<Track> tracks;
  final List<MediaItem> media;
  final double currentTime;
  final bool isPlaying;
  final double zoom;
  final List<String> selectedClipIds;

  const VideoEditorState({
    this.projectName = 'Untitled Project',
    this.tracks = const [],
    this.media = const [],
    this.currentTime = 0,
    this.isPlaying = false,
    this.zoom = 50,
    this.selectedClipIds = const [],
  });

  double get totalDuration {
    double max = 0;
    for (final track in tracks) {
      for (final clip in track.clips) {
        final end = clip.startTime + clip.duration;
        if (end > max) max = end;
      }
    }
    return max > 0 ? max : 60;
  }

  VideoEditorState copyWith({
    String? projectName, List<Track>? tracks, List<MediaItem>? media,
    double? currentTime, bool? isPlaying, double? zoom, List<String>? selectedClipIds,
  }) => VideoEditorState(
    projectName: projectName ?? this.projectName,
    tracks: tracks ?? this.tracks, media: media ?? this.media,
    currentTime: currentTime ?? this.currentTime, isPlaying: isPlaying ?? this.isPlaying,
    zoom: zoom ?? this.zoom, selectedClipIds: selectedClipIds ?? this.selectedClipIds,
  );
}

class VideoEditorStore extends ChangeNotifier {
  VideoEditorState _state = VideoEditorState(
    tracks: [
      Track(id: _uuid.v4(), type: 'video',   name: 'Video Track',   colorValue: 0xFF6366f1),
      Track(id: _uuid.v4(), type: 'overlay', name: 'Overlay Track', colorValue: 0xFF8b5cf6),
      Track(id: _uuid.v4(), type: 'text',    name: 'Text Track',    colorValue: 0xFFEAB308),
      Track(id: _uuid.v4(), type: 'audio',   name: 'Audio Track 1', colorValue: 0xFF10b981),
      Track(id: _uuid.v4(), type: 'audio',   name: 'Audio Track 2', colorValue: 0xFF3B82F6),
    ],
  );

  VideoEditorState get state => _state;
  String get projectName => _state.projectName;

  void _update(VideoEditorState newState) {
    _state = newState;
    notifyListeners();
  }

  void setProjectName(String name) => _update(_state.copyWith(projectName: name));
  void setCurrentTime(double t) => _update(_state.copyWith(currentTime: t.clamp(0, _state.totalDuration)));
  void togglePlay() => _update(_state.copyWith(isPlaying: !_state.isPlaying));
  void setPlaying(bool v) => _update(_state.copyWith(isPlaying: v));

  void addMedia(MediaItem item) => _update(_state.copyWith(media: [..._state.media, item]));

  void addMediaToTimeline(String mediaId, {String? trackId, double startTime = 0}) {
    final media = _state.media.where((m) => m.id == mediaId).firstOrNull;
    if (media == null) return;
    final targetTrack = trackId != null
      ? _state.tracks.where((t) => t.id == trackId).firstOrNull
      : _state.tracks.where((t) => t.type == (media.type == 'video' ? 'video' : 'audio')).firstOrNull
      ?? _state.tracks.first;
    if (targetTrack == null) return;

    final duration = media.duration ?? 5.0;
    final clip = TimelineClip(
      id: _uuid.v4(), trackId: targetTrack.id, type: media.type,
      name: media.name, mediaId: mediaId,
      startTime: startTime, duration: duration,
      trimStart: 0, trimEnd: duration,
    );
    _updateTrack(targetTrack.id, (t) => t.copyWith(clips: [...t.clips, clip]));
  }

  void selectClip(String id, {bool add = false}) {
    if (add) {
      final ids = [..._state.selectedClipIds];
      if (ids.contains(id)) ids.remove(id); else ids.add(id);
      _update(_state.copyWith(selectedClipIds: ids));
    } else {
      _update(_state.copyWith(selectedClipIds: [id]));
    }
  }

  void clearSelection() => _update(_state.copyWith(selectedClipIds: []));

  void splitAtPlayhead() {
    for (final id in _state.selectedClipIds) {
      _splitClip(id, _state.currentTime);
    }
  }

  void _splitClip(String clipId, double time) {
    for (int ti = 0; ti < _state.tracks.length; ti++) {
      final track = _state.tracks[ti];
      final ci = track.clips.indexWhere((c) => c.id == clipId);
      if (ci == -1) continue;
      final clip = track.clips[ci];
      final rel = time - clip.startTime;
      if (rel <= 0 || rel >= clip.duration) return;
      final left = clip.copyWith(duration: rel, trimEnd: clip.trimStart + rel);
      final right = clip.copyWith(id: _uuid.v4(), startTime: time, duration: clip.duration - rel, trimStart: clip.trimStart + rel);
      final newClips = [...track.clips];
      newClips[ci] = left;
      newClips.insert(ci + 1, right);
      final newTracks = [..._state.tracks];
      newTracks[ti] = track.copyWith(clips: newClips);
      _update(_state.copyWith(tracks: newTracks));
      return;
    }
  }

  void deleteSelected() {
    final ids = Set.of(_state.selectedClipIds);
    final newTracks = _state.tracks.map((t) =>
      t.copyWith(clips: t.clips.where((c) => !ids.contains(c.id)).toList())
    ).toList();
    _update(_state.copyWith(tracks: newTracks, selectedClipIds: []));
  }

  void duplicateSelected() {
    for (final track in _state.tracks) {
      for (final clip in track.clips) {
        if (_state.selectedClipIds.contains(clip.id)) {
          final newClip = clip.copyWith(id: _uuid.v4(), startTime: clip.startTime + clip.duration);
          _updateTrack(clip.trackId, (t) => t.copyWith(clips: [...t.clips, newClip]));
        }
      }
    }
  }

  void cutSelected() => deleteSelected();
  void copySelected() => duplicateSelected();

  void rotateSelected() {
    _forSelected((c) => c.copyWith(transform: c.transform.copyWith(rotation: (c.transform.rotation + 90) % 360)));
  }

  void flipSelected() {
    _forSelected((c) => c.copyWith(transform: c.transform.copyWith(flipX: !c.transform.flipX)));
  }

  void reverseSelected() {
    _forSelected((c) => c.copyWith(reverse: !c.reverse));
  }

  void updateClip(String clipId, TimelineClip Function(TimelineClip) updater) {
    _forClipId(clipId, updater);
  }

  void moveClip(String clipId, String newTrackId, double newStartTime) {
    TimelineClip? found;
    List<Track> newTracks = _state.tracks.map((t) {
      final ci = t.clips.indexWhere((c) => c.id == clipId);
      if (ci == -1) return t;
      found = t.clips[ci];
      final clips = [...t.clips]..removeAt(ci);
      return t.copyWith(clips: clips);
    }).toList();
    if (found == null) return;
    newTracks = newTracks.map((t) {
      if (t.id != newTrackId) return t;
      final updated = found!.copyWith(trackId: newTrackId, startTime: newStartTime);
      final clips = [...t.clips, updated]..sort((a, b) => a.startTime.compareTo(b.startTime));
      return t.copyWith(clips: clips);
    }).toList();
    _update(_state.copyWith(tracks: newTracks));
  }

  void updateTrack(String trackId, {bool? muted, bool? hidden, bool? locked, bool? solo}) {
    _updateTrack(trackId, (t) => t.copyWith(muted: muted, hidden: hidden, locked: locked, solo: solo));
  }

  void addTrack({String type = 'audio'}) {
    final colors = {'video': 0xFF6366f1, 'audio': 0xFF10b981, 'text': 0xFFEAB308, 'overlay': 0xFF8B5CF6};
    final track = Track(
      id: _uuid.v4(), type: type,
      name: '${type[0].toUpperCase()}${type.substring(1)} Track',
      colorValue: colors[type] ?? 0xFF6366f1,
    );
    _update(_state.copyWith(tracks: [..._state.tracks, track]));
  }

  void removeTrack(String trackId) {
    _update(_state.copyWith(tracks: _state.tracks.where((t) => t.id != trackId).toList()));
  }

  void setZoom(double z) => _update(_state.copyWith(zoom: z.clamp(10, 500)));

  void _updateTrack(String trackId, Track Function(Track) updater) {
    _update(_state.copyWith(tracks: _state.tracks.map((t) => t.id == trackId ? updater(t) : t).toList()));
  }

  void _forSelected(TimelineClip Function(TimelineClip) updater) {
    final ids = Set.of(_state.selectedClipIds);
    _update(_state.copyWith(tracks: _state.tracks.map((t) =>
      t.copyWith(clips: t.clips.map((c) => ids.contains(c.id) ? updater(c) : c).toList())
    ).toList()));
  }

  void _forClipId(String clipId, TimelineClip Function(TimelineClip) updater) {
    _update(_state.copyWith(tracks: _state.tracks.map((t) =>
      t.copyWith(clips: t.clips.map((c) => c.id == clipId ? updater(c) : c).toList())
    ).toList()));
  }
}
