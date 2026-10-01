import 'package:flutter/material.dart';
import '../models/media_item.dart';

class PlayerProvider extends ChangeNotifier {
  MediaItem? _activeMedia;
  EpisodeItem? _activeEpisode;
  StreamSource? _activeStreamSource;
  
  bool _isPlaying = false;
  bool _isMiniPlayerActive = false;
  Duration _currentPosition = Duration.zero;
  final Duration _totalDuration = const Duration(minutes: 24, seconds: 30);
  double _volume = 1.0;
  double _brightness = 0.8;
  double _playbackSpeed = 1.0;
  
  // A-B Looper
  Duration? _loopPointA;
  Duration? _loopPointB;
  bool _isLooping = false;

  // Heatmap & Markers
  List<double> _currentHeatmap = [0.1, 0.25, 0.5, 0.85, 1.0, 0.9, 0.4, 0.3, 0.95, 0.8, 0.2];
  List<SceneMarker> _sceneMarkers = [];

  MediaItem? get activeMedia => _activeMedia;
  EpisodeItem? get activeEpisode => _activeEpisode;
  StreamSource? get activeStreamSource => _activeStreamSource;
  bool get isPlaying => _isPlaying;
  bool get isMiniPlayerActive => _isMiniPlayerActive;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get volume => _volume;
  double get brightness => _brightness;
  double get playbackSpeed => _playbackSpeed;
  Duration? get loopPointA => _loopPointA;
  Duration? get loopPointB => _loopPointB;
  bool get isLooping => _isLooping;
  List<double> get currentHeatmap => _currentHeatmap;
  List<SceneMarker> get sceneMarkers => _sceneMarkers;

  void playVideo({
    required MediaItem media,
    required EpisodeItem episode,
    required StreamSource source,
    List<double>? heatmap,
    List<SceneMarker>? markers,
  }) {
    _activeMedia = media;
    _activeEpisode = episode;
    _activeStreamSource = source;
    _isPlaying = true;
    _isMiniPlayerActive = false;
    _currentPosition = Duration.zero;
    if (heatmap != null && heatmap.isNotEmpty) {
      _currentHeatmap = heatmap;
    }
    if (markers != null) {
      _sceneMarkers = markers;
    }
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setPosition(Duration pos) {
    _currentPosition = pos;
    // Handle A-B loop boundary
    if (_isLooping && _loopPointB != null && _loopPointA != null) {
      if (pos >= _loopPointB!) {
        _currentPosition = _loopPointA!;
      }
    }
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 2.0); // 200% Audio Boost support
    notifyListeners();
  }

  void setBrightness(double val) {
    _brightness = val.clamp(0.1, 1.0);
    notifyListeners();
  }

  void setSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void setLoopPointA(Duration a) {
    _loopPointA = a;
    notifyListeners();
  }

  void setLoopPointB(Duration b) {
    _loopPointB = b;
    _isLooping = true;
    notifyListeners();
  }

  void clearLoop() {
    _loopPointA = null;
    _loopPointB = null;
    _isLooping = false;
    notifyListeners();
  }

  void toggleMiniPlayer(bool isMini) {
    _isMiniPlayerActive = isMini;
    notifyListeners();
  }

  void closePlayer() {
    _activeMedia = null;
    _activeEpisode = null;
    _activeStreamSource = null;
    _isPlaying = false;
    _isMiniPlayerActive = false;
    notifyListeners();
  }
}
