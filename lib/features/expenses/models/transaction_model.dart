import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  double amount = 0.0;
  String description = '';
  DateTime timestamp = DateTime.now();

  // We store enum value as string: 'income', 'expense', 'transfer'
  String transactionType = 'expense';

  String category = '';
  String source = 'manual'; // manual, sms, imap

  String?
  cardId; // Reference to CreditCard's ID (stored as string or parsed number)
  String? accountName; // Cash, Bank, etc.

  bool isSplit = false;
  List<TransactionSplitDetail> splitDetails = [];

  bool isDeleted = false;
  DateTime? deletedAt;

  String? parserSource; // e.g., 'gemini', 'gemma', 'regex'
  String? aiComparisonNotes; // A/B testing comparison
  String? rawMessage; // Store original SMS or Email body
}

@embedded
class TransactionSplitDetail {
  double amount = 0.0;
  String category = '';
  String? friendName;
  String? description;

  TransactionSplitDetail(); // Required empty constructor for Isar embedded
}
