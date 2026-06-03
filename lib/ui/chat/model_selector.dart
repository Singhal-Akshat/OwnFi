import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/model_repository.dart';
import '../../services/model_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Chat screen widget that lets the user pick which downloaded model to use.
class ModelSelector extends StatefulWidget {
  const ModelSelector({Key? key}) : super(key: key);

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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_downloaded.isEmpty) {
      return const Text('No AI models downloaded yet. Open Settings to download.');
    }
    return DropdownButton<String>(
      value: _selectedId,
      hint: const Text('Select Model'),
      items: _downloaded
          .map((m) => DropdownMenuItem<String>(value: m.id, child: Text(m.displayName)))
          .toList(),
      onChanged: _onSelect,
    );
  }
}
