import 'package:isar/isar.dart';

part 'alert_model.g.dart';

@collection
class InAppAlert {
  Id id = Isar.autoIncrement;

  String title = '';
  String message = '';
  DateTime timestamp = DateTime.now();
  bool isRead = false;
}
