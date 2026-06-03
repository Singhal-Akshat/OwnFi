import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disk_space_2/disk_space_2.dart';
import '../../services/model_repository.dart';
import '../../services/model_downloader.dart';
import 'dart:io';

/// Settings page that lists available models and lets the user download/delete them.
class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({Key? key}) : super(key: key);

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  List<ModelMeta> _lightModels = [];
  List<ModelMeta> _largeModels = [];
  bool _isLoading = true;
  int _freeMb = 0;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ModelRepository.instance;
    final light = await repo.listLightWeight();
    final large = await repo.listLarge();
    final free = await _freeStorageMb();
    setState(() {
      _lightModels = light;
      _largeModels = large;
      _freeMb = free;
      _isLoading = false;
    });
  }

  Future<int> _freeStorageMb() async {
    try {
      final freeSpaceMb = await DiskSpace.getFreeDiskSpace;
      if (freeSpaceMb != null) {
        return freeSpaceMb.toInt();
      }
    } catch (e) {
      debugPrint('Failed to get disk space: $e');
    }
    return 8000;
  }

  Future<int> _directorySize(Directory dir) async {
    int size = 0;
    await for (FileSystemEntity e in dir.list(recursive: true, followLinks: false)) {
      if (e is File) size += await e.length();
    }
    return size;
  }

  Future<bool> _isDownloaded(ModelMeta meta) async {
    final path = await ModelRepository.instance.localModelPath(meta.assetPath);
    return await File(path).exists();
  }

  Widget _buildModelRow(ModelMeta meta) {
    return FutureBuilder<bool>(
      future: _isDownloaded(meta),
      builder: (ctx, snap) {
        final downloaded = snap.data ?? false;
        final progressNotifier = ModelDownloader.instance.activeDownloads[meta.id];
        
        return ListTile(
          title: Text(meta.displayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${meta.sizeMb} MB'),
              if (progressNotifier != null)
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (ctx, progress, child) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.grey.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          trailing: downloaded
              ? TextButton(
                  onPressed: () async {
                    await ModelDownloader.instance.deleteModel(meta.id);
                    _loadData();
                  },
                  child: const Text('Delete'),
                )
              : ElevatedButton(
                  onPressed: progressNotifier != null 
                    ? () {
                        // User clicked cancel
                        ModelDownloader.instance.activeCancelTokens[meta.id]?.cancel();
                        setState(() {});
                      } 
                    : () async {
                        // Start the download
                        ModelDownloader.instance.downloadModel(context, meta).then((_) {
                          _loadData();
                        });
                        // Rebuild to show the progress bar immediately
                        setState(() {});
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: progressNotifier != null ? Colors.redAccent : null,
                  ),
                  child: Text(
                    progressNotifier != null ? 'Cancel' : 'Download',
                    style: TextStyle(color: progressNotifier != null ? Colors.white : null),
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Manager')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free storage: ${_freeMb} MB'),
                  const SizedBox(height: 12),
                  const Text('Light‑weight Models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._lightModels.map(_buildModelRow).toList(),
                  const SizedBox(height: 20),
                  const Text('Large Models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._largeModels.map(_buildModelRow).toList(),
                ],
              ),
            ),
    );
  }
}
