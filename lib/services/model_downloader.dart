import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:disk_space_2/disk_space_2.dart';
import '../services/model_repository.dart';

/// ---------------------------------------------------------
/// 🔑 PASTE YOUR HUGGING FACE TOKEN HERE FOR QUICK TESTING
/// ---------------------------------------------------------
const String kHardcodedHuggingFaceToken = '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';


class CancelToken {
  bool isCancelled = false;
  VoidCallback? onCancel;
  void cancel() {
    isCancelled = true;
    onCancel?.call();
  }
}

/// Handles downloading and deletion of model files.
class ModelDownloader {
  ModelDownloader._();
  static final ModelDownloader instance = ModelDownloader._();

  /// Active downloads maps
  final Map<String, ValueNotifier<double>> activeDownloads = {};
  final Map<String, CancelToken> activeCancelTokens = {};

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
    try {
      final freeSpaceMb = await DiskSpace.getFreeDiskSpace;
      if (freeSpaceMb != null) {
        return freeSpaceMb.toInt();
      }
    } catch (e) {
      debugPrint('Failed to get disk space: $e');
    }
    return 8000; // Fallback
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
  Future<String?> downloadModel(BuildContext context, ModelMeta meta, {Function(double)? onProgress, CancelToken? cancelToken}) async {
    final freeMb = await _getFreeStorageMb();
    if (freeMb < meta.sizeMb + 150) {
      // Not enough space – inform user.
      if (context.mounted) {
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
      }
      return null;
    }

    final consent = await _showConsentDialog(context, meta, freeMb);
    if (!consent) return null;

    final progressNotifier = ValueNotifier<double>(0.0);
    final token = cancelToken ?? CancelToken();
    
    activeDownloads[meta.id] = progressNotifier;
    activeCancelTokens[meta.id] = token;

    final localPath = await ModelRepository.instance.localModelPath(meta.assetPath);
    final file = File(localPath);
    final client = http.Client();
    
    final completer = Completer<String?>();
    IOSink? sink;
    StreamSubscription? subscription;

    try {
      final request = http.Request('GET', Uri.parse(meta.officialUrl));
      
      const storage = FlutterSecureStorage();
      String? hfToken = await storage.read(key: 'huggingface_token');
      
      // Fallback to hardcoded token if not empty
      if (hfToken == null || hfToken.isEmpty) {
        if (kHardcodedHuggingFaceToken != 'PASTE_YOUR_TOKEN_HERE' && kHardcodedHuggingFaceToken.isNotEmpty) {
          hfToken = kHardcodedHuggingFaceToken;
        }
      }

      if (hfToken != null && hfToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $hfToken';
      }

      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: HTTP ${response.statusCode}');
      }
      
      sink = file.openWrite();
      int received = 0;
      final total = response.contentLength ?? (meta.sizeMb * 1024 * 1024);
      int lastReported = 0;
      
      token.onCancel = () async {
        if (subscription != null) await subscription!.cancel();
        if (sink != null) {
          try {
            await sink!.close();
          } catch (_) {}
        }
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      };

      if (token.isCancelled) {
        token.onCancel!();
        return null;
      }

      subscription = response.stream.listen(
        (chunk) {
          if (token.isCancelled) {
            token.onCancel!();
            return;
          }
          
          sink?.add(chunk);
          received += chunk.length;
          
          final currentProgress = total > 0 ? received / total : 0.0;
          if ((received - lastReported) / total >= 0.01) {
            progressNotifier.value = currentProgress;
            if (onProgress != null) {
              onProgress(currentProgress);
            }
            lastReported = received;
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        onDone: () async {
          progressNotifier.value = 1.0;
          if (onProgress != null) {
            onProgress(1.0);
          }
          try {
            await sink?.flush();
            await sink?.close();
            if (!completer.isCompleted) {
              completer.complete(localPath);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future;
      return result;
    } catch (e) {
      if (token.isCancelled) return null;
      // Show error dialog.
      if (context.mounted) {
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
      }
      return null;
    } finally {
      client.close();
      activeDownloads.remove(meta.id);
      activeCancelTokens.remove(meta.id);
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
