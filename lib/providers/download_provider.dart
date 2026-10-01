import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';

class DownloadProvider extends ChangeNotifier {
  final List<DownloadTask> _tasks = [];
  final Map<String, Timer> _activeTimers = {};

  List<DownloadTask> get tasks => _tasks;
  List<DownloadTask> get activeDownloads =>
      _tasks.where((t) => t.status == DownloadStatus.downloading).toList();
  List<DownloadTask> get completedDownloads =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  DownloadProvider() {
    _initSampleTasks();
  }

  void _initSampleTasks() {
    _tasks.add(DownloadTask(
      id: "dl_1",
      title: "Taimanin Asagi: Cyber Rebellion Ep 1",
      mediaId: "hanime_1",
      episodeTitle: "Episode 1 (1080p 60fps)",
      coverUrl: "https://picsum.photos/seed/hanime_1/640/360",
      downloadUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      targetFilePath: "/storage/emulated/0/Download/Taimanin_Ep1_1080p.mp4",
      progress: 1.0,
      totalBytes: 524288000,
      downloadedBytes: 524288000,
      speed: "0 KB/s",
      status: DownloadStatus.completed,
    ));
  }

  Future<void> startDownload({
    required String title,
    required String mediaId,
    required String episodeTitle,
    required String coverUrl,
    required String downloadUrl,
    bool isVault = false,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final taskId = "dl_${DateTime.now().millisecondsSinceEpoch}";
    final targetPath = "${dir.path}/$taskId.mp4";

    final task = DownloadTask(
      id: taskId,
      title: title,
      mediaId: mediaId,
      episodeTitle: episodeTitle,
      coverUrl: coverUrl,
      downloadUrl: downloadUrl,
      targetFilePath: targetPath,
      isVaultEncrypted: isVault,
      status: DownloadStatus.downloading,
      progress: 0.05,
      totalBytes: 420000000,
      downloadedBytes: 21000000,
      speed: "12.4 MB/s",
    );

    _tasks.insert(0, task);
    notifyListeners();

    // Simulated high-speed multi-threaded progressive download
    _activeTimers[taskId] = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (task.progress >= 1.0) {
        task.progress = 1.0;
        task.status = DownloadStatus.completed;
        task.speed = "0 KB/s";
        timer.cancel();
        _activeTimers.remove(taskId);
        notifyListeners();
      } else {
        task.progress += 0.08;
        task.downloadedBytes = (task.progress * task.totalBytes).toInt();
        task.speed = "${(10 + (task.progress * 5)).toStringAsFixed(1)} MB/s";
        notifyListeners();
      }
    });
  }

  void pauseDownload(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.paused;
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
    notifyListeners();
  }

  void resumeDownload(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.downloading;
    notifyListeners();

    _activeTimers[taskId] = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (task.progress >= 1.0) {
        task.progress = 1.0;
        task.status = DownloadStatus.completed;
        timer.cancel();
        _activeTimers.remove(taskId);
        notifyListeners();
      } else {
        task.progress += 0.08;
        notifyListeners();
      }
    });
  }

  void deleteTask(String taskId) {
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }
}
