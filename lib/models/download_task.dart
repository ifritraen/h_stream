enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String title;
  final String mediaId;
  final String episodeTitle;
  final String coverUrl;
  final String downloadUrl;
  final String targetFilePath;
  final bool isHls;
  final bool isVaultEncrypted;
  
  double progress; // 0.0 - 1.0
  int totalBytes;
  int downloadedBytes;
  String speed; // e.g. "8.5 MB/s"
  DownloadStatus status;
  DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.title,
    required this.mediaId,
    required this.episodeTitle,
    required this.coverUrl,
    required this.downloadUrl,
    required this.targetFilePath,
    this.isHls = false,
    this.isVaultEncrypted = false,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.speed = '0 KB/s',
    this.status = DownloadStatus.queued,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      mediaId: json['mediaId'] ?? '',
      episodeTitle: json['episodeTitle'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      targetFilePath: json['targetFilePath'] ?? '',
      isHls: json['isHls'] ?? false,
      isVaultEncrypted: json['isVaultEncrypted'] ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalBytes: json['totalBytes'] ?? 0,
      downloadedBytes: json['downloadedBytes'] ?? 0,
      speed: json['speed'] ?? '0 KB/s',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.completed,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'mediaId': mediaId,
        'episodeTitle': episodeTitle,
        'coverUrl': coverUrl,
        'downloadUrl': downloadUrl,
        'targetFilePath': targetFilePath,
        'isHls': isHls,
        'isVaultEncrypted': isVaultEncrypted,
        'progress': progress,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'speed': speed,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
