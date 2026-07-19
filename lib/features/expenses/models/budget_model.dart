import 'package:isar/isar.dart';

part 'budget_model.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;

  String category = ''; // 'All' for global, or category name e.g. 'Food'
  double amountLimit = 0.0;
  int yearMonth = 0; // e.g. 202607 for July 2026
}
