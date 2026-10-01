import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/download_provider.dart';
import '../../models/download_task.dart';
import '../../theme/app_theme.dart';

class PrivateVaultView extends StatefulWidget {
  const PrivateVaultView({super.key});

  @override
  State<PrivateVaultView> createState() => _PrivateVaultViewState();
}

class _PrivateVaultViewState extends State<PrivateVaultView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context);
    final downloads = Provider.of<DownloadProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Downloads & Vault", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: "Downloads (${downloads.tasks.length})"),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(vault.isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded, size: 15),
                  const SizedBox(width: 6),
                  const Text("Encrypted Vault"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Standard Downloads
          _buildDownloadsList(downloads),

          // Tab 2: Encrypted Vault
          vault.isUnlocked
              ? _buildVaultList(vault)
              : _buildVaultLockScreen(vault),
        ],
      ),
    );
  }

  Widget _buildDownloadsList(DownloadProvider downloads) {
    if (downloads.tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_rounded, size: 56, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text("No downloads yet", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: downloads.tasks.length,
      itemBuilder: (context, idx) {
        final task = downloads.tasks[idx];
        final isDownloading = task.status == DownloadStatus.downloading;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(task.coverUrl, width: 60, height: 45, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.episodeTitle,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDownloading ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                      color: AppTheme.primaryAccent,
                      size: 24,
                    ),
                    onPressed: () {
                      if (isDownloading) {
                        downloads.pauseDownload(task.id);
                      } else {
                        downloads.resumeDownload(task.id);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () => downloads.deleteTask(task.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.status == DownloadStatus.completed ? AppTheme.accentGreen : AppTheme.primaryAccent,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVaultLockScreen(VaultProvider vault) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 44, color: AppTheme.primaryAccent),
            ),
            const SizedBox(height: 18),
            const Text(
              "Encrypted Private Vault",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              "Protected sandbox isolated from system media indexer",
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 8, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "PIN",
                  hintStyle: const TextStyle(letterSpacing: 2, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              onPressed: () {
                if (vault.unlockWithPin(_pinController.text)) {
                  _pinController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Incorrect Vault PIN (Default is 1234)")),
                  );
                }
              },
              child: const Text("Unlock Vault", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultList(VaultProvider vault) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: vault.vaultItems.length,
      itemBuilder: (context, idx) {
        final item = vault.vaultItems[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.coverUrl, width: 60, height: 45, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13), maxLines: 1),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 12, color: AppTheme.accentGreen),
                        SizedBox(width: 4),
                        Text("AES Encrypted Sandbox", style: TextStyle(fontSize: 10.5, color: AppTheme.accentGreen)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 18),
                onPressed: () => vault.lockVault(),
              ),
            ],
          ),
        );
      },
    );
  }
}
