import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Model metadata representation
class ModelMeta {
  final String id;
  final String displayName;
  final int sizeMb;
  final bool defaultDownload;
  final bool premium;
  final String assetPath;
  final String officialUrl;

  ModelMeta({
    required this.id,
    required this.displayName,
    required this.sizeMb,
    required this.defaultDownload,
    required this.premium,
    required this.assetPath,
    required this.officialUrl,
  });

  factory ModelMeta.fromJson(Map<String, dynamic> json) => ModelMeta(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        sizeMb: json['sizeMb'] as int,
        defaultDownload: json['defaultDownload'] as bool,
        premium: json['premium'] as bool,
        assetPath: json['assetPath'] as String,
        officialUrl: json['officialUrl'] as String,
      );
}

/// Singleton repository that loads the catalogue from assets/models/models.json
class ModelRepository {
  ModelRepository._privateConstructor();
  static final ModelRepository _instance = ModelRepository._privateConstructor();
  static ModelRepository get instance => _instance;

  List<ModelMeta>? _models;

  /// Load models from the bundled JSON. Caches after first load.
  Future<List<ModelMeta>> loadModels() async {
    if (_models != null) return _models!;
    final jsonStr = await rootBundle.loadString('assets/models/models.json');
    final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
    _models = decoded.map((e) => ModelMeta.fromJson(e as Map<String, dynamic>)).toList();
    return _models!;
  }

  /// Helper to get a model meta by id.
  Future<ModelMeta?> getMeta(String id) async {
    final models = await loadModels();
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Returns only lightweight (premium == false) models.
  Future<List<ModelMeta>> listLightWeight() async =>
      (await loadModels()).where((m) => !m.premium).toList();

  /// Returns only premium (large) models.
  Future<List<ModelMeta>> listLarge() async =>
      (await loadModels()).where((m) => m.premium).toList();

  /// Compute the local file system path where downloaded models are stored.
  Future<String> localModelPath(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    // Ensure subfolder "models" exists
    final modelsDir = Directory('${dir.path}/models');
    if (!await modelsDir.exists()) await modelsDir.create(recursive: true);
    return '${modelsDir.path}/${assetPath.split('/').last}';
  }
}
