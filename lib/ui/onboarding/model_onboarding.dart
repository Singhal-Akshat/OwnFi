import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/model_repository.dart';
import '../../services/model_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
/// Onboarding screen that runs on first launch.
/// Shows free storage, explains the default model (Gemma 2 Turbo 2B) and asks for consent.
class ModelOnboardingScreen extends StatefulWidget {
  const ModelOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<ModelOnboardingScreen> createState() => _ModelOnboardingScreenState();
}

class _ModelOnboardingScreenState extends State<ModelOnboardingScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;

  Future<int> _freeStorageMb() async {
    // Approximate free storage – using the same logic as ModelDownloader.
    final dir = await getApplicationDocumentsDirectory();
    final usedMb = await _directorySize(dir) ~/ (1024 * 1024);
    const totalMb = 8 * 1024; // 8 GB assumed total.
    return totalMb - usedMb;
  }

  Future<int> _directorySize(Directory dir) async {
    int size = 0;
    await for (FileSystemEntity e in dir.list(recursive: true, followLinks: false)) {
      if (e is File) size += await e.length();
    }
    return size;
  }

  Future<void> _startDownload() async {
    setState(() { _isDownloading = true; _progress = 0.0; });
    final meta = await ModelRepository.instance.getMeta('gemma2_turbo_2b');
    if (meta == null) return;
    final localPath = await ModelDownloader.instance.downloadModel(context, meta);
    if (localPath != null) {
      // Save selected model id for future sessions.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedModelId', meta.id);
    }
    setState(() { _isDownloading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Money Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app uses an on‑device AI model to power the finance advisor chat.\n'
              'The default model (Gemma 2 Turbo 2B) is about 600 MB in size.\n'
              'It will be downloaded once and stored locally for offline use.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            FutureBuilder<int>(
              future: _freeStorageMb(),
              builder: (ctx, snap) {
                final free = snap.hasData ? '\${snap.data} MB' : '...';
                return Text('Free storage on device: $free');
              },
            ),
            const SizedBox(height: 20),
            if (_isDownloading)
              LinearProgressIndicator(value: _progress)
            else
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _startDownload,
                    child: const Text('Download Model'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
