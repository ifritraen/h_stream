import 'dart:io';
import 'package:flutter/material.dart';

class LanStreamProvider extends ChangeNotifier {
  HttpServer? _server;
  bool _isServerRunning = false;
  String _localIpAddress = "192.168.1.105";
  final int _serverPort = 8080;
  String? _currentlyStreamingTitle;
  String? _currentlyStreamingUrl;

  bool get isServerRunning => _isServerRunning;
  String get streamUrl => "http://$_localIpAddress:$_serverPort";
  String? get currentlyStreamingTitle => _currentlyStreamingTitle;

  Future<void> toggleServer({String? title, String? videoUrl}) async {
    if (_isServerRunning) {
      await stopServer();
    } else {
      await startServer(title: title, videoUrl: videoUrl);
    }
  }

  Future<void> startServer({String? title, String? videoUrl}) async {
    _currentlyStreamingTitle = title ?? "Stream Channel 1";
    _currentlyStreamingUrl = videoUrl ?? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";

    try {
      // Find local IP
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _localIpAddress = addr.address;
            break;
          }
        }
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort);
      _isServerRunning = true;
      notifyListeners();

      _server?.listen((HttpRequest request) {
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>NeoCast TV: $_currentlyStreamingTitle</title>
  <style>
    body { margin: 0; background: #07080B; color: #F0F3F8; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; }
    video { width: 90vw; max-width: 1200px; border-radius: 16px; border: 1px solid #FF2A6D; box-shadow: 0 0 30px rgba(255,42,109,0.3); }
    h1 { font-size: 24px; margin-bottom: 20px; color: #05D9E8; }
    .badge { background: #161922; padding: 6px 14px; border-radius: 20px; font-size: 14px; color: #FFC72C; border: 1px solid #333; margin-top: 15px; }
  </style>
</head>
<body>
  <h1>📡 Streaming to TV / PC: $_currentlyStreamingTitle</h1>
  <video controls autoplay>
    <source src="$_currentlyStreamingUrl" type="video/mp4">
    Your browser does not support video playback.
  </video>
  <div class="badge">Connected from Phone Stream Gateway</div>
</body>
</html>
''');
        request.response.close();
      });
    } catch (e) {
      _isServerRunning = false;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _isServerRunning = false;
    _currentlyStreamingTitle = null;
    _currentlyStreamingUrl = null;
    notifyListeners();
  }
}
