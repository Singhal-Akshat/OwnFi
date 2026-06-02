import 'package:isar/isar.dart';

part 'holding_model.g.dart';

@collection
class Holding {
  Id id = Isar.autoIncrement;

  String symbol = '';
  String name = '';
  double quantity = 0.0;
  double buyAvgPrice = 0.0;
  double currentPrice = 0.0;

  // We store asset type as string: 'stock', 'mutual_fund'
  String assetType = 'stock';

  // We store broker as string: 'zerodha', 'coin'
  String broker = 'zerodha';

  DateTime lastUpdated = DateTime.now();
}
