import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/model_repository.dart';

/// Handles downloading and deletion of model files.
class ModelDownloader {
  ModelDownloader._();
  static final ModelDownloader instance = ModelDownloader._();

  /// Shows a consent dialog with free storage info before downloading.
  Future<bool> _showConsentDialog(BuildContext context, ModelMeta meta, int freeMb) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Download Model'),
          content: Text(
            'Model: ${meta.displayName}\n'
            'Size: ${meta.sizeMb} MB\n'
            'Free space: $freeMb MB\n'
            '\nProceed with download?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Download')),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  /// Returns free internal storage in megabytes.
  Future<int> _getFreeStorageMb() async {
    final dir = await getApplicationDocumentsDirectory();
    final stat = await dir.stat();
    // On many platforms we can approximate using total space - used space.
    // Since Dart does not expose free space directly, we fallback to a safe estimate.
    // For this demo we assume at least 8 GB free; replace with proper implementation if needed.
    // We'll query the file system using `stat` which provides size of the directory.
    // We'll treat free space as (8 GB - used) for simplicity.
    const totalMb = 8 * 1024; // 8 GB total assumption.
    final usedMb = (await _directorySize(dir)) ~/ (1024 * 1024);
    return totalMb - usedMb;
  }

  Future<int> _directorySize(Directory dir) async {
    int size = 0;
    await for (FileSystemEntity entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Downloads the model file to the app's documents/models directory.
  /// Returns the local file path on success, null on failure or user cancellation.
  Future<String?> downloadModel(BuildContext context, ModelMeta meta) async {
    final freeMb = await _getFreeStorageMb();
    if (freeMb < meta.sizeMb + 150) {
      // Not enough space – inform user.
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Insufficient Storage'),
          content: Text('Not enough free space to download ${meta.displayName}.\nRequired: ${meta.sizeMb + 150} MB, Available: $freeMb MB.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return null;
    }

    final consent = await _showConsentDialog(context, meta, freeMb);
    if (!consent) return null;

    final localPath = await ModelRepository.instance.localModelPath(meta.assetPath);
    final file = File(localPath);
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(meta.officialUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: HTTP ${response.statusCode}');
      }
      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.close();
      return localPath;
    } catch (e) {
      // Show error dialog.
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Download Failed'),
          content: Text('Error downloading ${meta.displayName}: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return null;
    } finally {
      client.close();
    }
  }

  /// Deletes a downloaded model file.
  Future<bool> deleteModel(String id) async {
    final meta = await ModelRepository.instance.getMeta(id);
    if (meta == null) return false;
    final path = await ModelRepository.instance.localModelPath(meta.assetPath);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
