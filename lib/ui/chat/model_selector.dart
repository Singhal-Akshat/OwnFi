import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/model_repository.dart';
import '../../services/model_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Chat screen widget that lets the user pick which downloaded model to use.
class ModelSelector extends StatefulWidget {
  final VoidCallback? onChanged;
  const ModelSelector({Key? key, this.onChanged}) : super(key: key);

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  List<ModelMeta> _downloaded = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final repo = ModelRepository.instance;
    final all = await repo.loadModels();
    // Keep only models that have a local file.
    final downloaded = <ModelMeta>[];
    for (var m in all) {
      final localPath = await repo.localModelPath(m.assetPath);
      if (await File(localPath).exists()) {
        downloaded.add(m);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selectedModelId');
    setState(() {
      _downloaded = downloaded;
      _selectedId = selected ?? (downloaded.isNotEmpty ? downloaded.first.id : null);
      _loading = false;
    });
  }

  Future<void> _onSelect(String? id) async {
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedModelId', id);
    setState(() => _selectedId = id);
    if (widget.onChanged != null) {
      widget.onChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blueAccent),
      );
    }
    if (_downloaded.isEmpty) {
      return const Text(
        'No models',
        style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
      );
    }
    return DropdownButton<String>(
      value: _selectedId,
      hint: const Text('Select Model', style: TextStyle(fontSize: 11)),
      isDense: true,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 18),
      style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
      items: _downloaded
          .map((m) => DropdownMenuItem<String>(
                value: m.id,
                child: Text(
                  m.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ))
          .toList(),
      onChanged: _onSelect,
    );
  }
}
