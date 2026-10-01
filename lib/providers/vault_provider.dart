import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_task.dart';

class VaultProvider extends ChangeNotifier {
  bool _isUnlocked = false;
  String _vaultPin = "1234";
  bool _biometricEnabled = true;
  final List<DownloadTask> _vaultItems = [];

  bool get isUnlocked => _isUnlocked;
  bool get biometricEnabled => _biometricEnabled;
  List<DownloadTask> get vaultItems => _vaultItems;

  VaultProvider() {
    _loadVaultSettings();
    _initSampleVault();
  }

  void _initSampleVault() {
    _vaultItems.add(DownloadTask(
      id: "vault_1",
      title: "Overwatch D.Va & Mercy 3D Special 4K",
      mediaId: "r34_vault_1",
      episodeTitle: "Master Render 60FPS",
      coverUrl: "https://picsum.photos/seed/r34_vault/450/600",
      downloadUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
      targetFilePath: "/data/user/0/com.antigravity.hstream/app_flutter/vault_encrypted_1.enc",
      progress: 1.0,
      isVaultEncrypted: true,
      status: DownloadStatus.completed,
    ));
  }

  bool unlockWithPin(String enteredPin) {
    if (enteredPin == _vaultPin) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockVault() {
    _isUnlocked = false;
    notifyListeners();
  }

  void setPin(String newPin) {
    _vaultPin = newPin;
    _saveVaultSettings();
    notifyListeners();
  }

  void toggleBiometric() {
    _biometricEnabled = !_biometricEnabled;
    _saveVaultSettings();
    notifyListeners();
  }

  void addToVault(DownloadTask item) {
    _vaultItems.add(item);
    notifyListeners();
  }

  void removeFromVault(String id) {
    _vaultItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> _loadVaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _vaultPin = prefs.getString('vault_pin') ?? "1234";
    _biometricEnabled = prefs.getBool('vault_biometric') ?? true;
    notifyListeners();
  }

  Future<void> _saveVaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vault_pin', _vaultPin);
    await prefs.setBool('vault_biometric', _biometricEnabled);
  }
}
