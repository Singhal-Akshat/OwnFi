import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() {
  print('--- ModelType ---');
  for (var val in ModelType.values) {
    print(val);
  }
  print('\n--- ModelFileType ---');
  for (var val in ModelFileType.values) {
    print(val);
  }
}
