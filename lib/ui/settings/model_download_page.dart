import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/model_repository.dart';
import '../../services/model_downloader.dart';
import 'package:path_provider/path_provider.dart';
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
    final dir = await getApplicationDocumentsDirectory();
    final used = await _directorySize(dir) ~/ (1024 * 1024);
    const total = 8 * 1024; // 8 GB assumed total.
    return total - used;
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
        return ListTile(
          title: Text(meta.displayName),
          subtitle: Text('\${meta.sizeMb} MB'),
          trailing: downloaded
              ? TextButton(
                  onPressed: () async {
                    await ModelDownloader.instance.deleteModel(meta.id);
                    _loadData();
                  },
                  child: const Text('Delete'),
                )
              : ElevatedButton(
                  onPressed: () async {
                    await ModelDownloader.instance.downloadModel(context, meta);
                    _loadData();
                  },
                  child: const Text('Download'),
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
                  Text('Free storage: \${_freeMb} MB'),
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
