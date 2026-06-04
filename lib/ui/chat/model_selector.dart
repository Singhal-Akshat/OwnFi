import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/model_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ModelItem {
  final String id;
  final String displayName;
  final bool isLocal;

  ModelItem({required this.id, required this.displayName, required this.isLocal});
}

/// Chat screen widget that lets the user pick which model (Cloud or Local) to use.
class ModelSelector extends StatefulWidget {
  final VoidCallback? onChanged;
  const ModelSelector({Key? key, this.onChanged}) : super(key: key);

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  List<ModelItem> _availableModels = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final available = <ModelItem>[];
    
    // 1. Cloud APIs
    const storage = FlutterSecureStorage();
    final geminiKey = await storage.read(key: 'ai_gemini_key');
    if (geminiKey != null && geminiKey.isNotEmpty) {
      available.add(ModelItem(id: '__gemini__', displayName: 'Gemini Cloud API', isLocal: false));
    }
    final openaiKey = await storage.read(key: 'ai_openai_key');
    if (openaiKey != null && openaiKey.isNotEmpty) {
      available.add(ModelItem(id: '__openai__', displayName: 'OpenAI Cloud API', isLocal: false));
    }

    final ollamaHost = await storage.read(key: 'ai_ollama_host');
    if (ollamaHost != null && ollamaHost.isNotEmpty) {
      available.add(ModelItem(id: '__ollama__', displayName: 'Ollama Local Host', isLocal: false));
    }

    // 2. Downloaded Local Models
    final repo = ModelRepository.instance;
    final all = await repo.loadModels();
    for (var m in all) {
      final localPath = await repo.localModelPath(m.assetPath);
      if (await File(localPath).exists()) {
        available.add(ModelItem(id: m.id, displayName: 'Local: ${m.displayName}', isLocal: true));
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selectedModelId');
    
    bool selectedExists = available.any((e) => e.id == selected);
    
    setState(() {
      _availableModels = available;
      _selectedId = selectedExists ? selected : (available.isNotEmpty ? available.first.id : null);
      _loading = false;
    });

    if (!selectedExists && _selectedId != null) {
      await prefs.setString('selectedModelId', _selectedId!);
    }
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
    if (_availableModels.isEmpty) {
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
      items: _availableModels
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
