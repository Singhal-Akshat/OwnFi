import 'package:isar/isar.dart';

part 'card_loan_models.g.dart';

@collection
class CreditCard {
  Id id = Isar.autoIncrement;

  String cardName = '';
  String last4 = '';
  double creditLimit = 0.0;
  int statementDay = 15;
  int dueDay = 5;
  double balance = 0.0;

  String fullCardNumber = '';
  String expiryDate = '';
  String cvv = '';
  String brand = '';
  String imageUrl = '';

  double currentSpendings = 0.0;
  double statementAmount = 0.0;

  List<CreditCardEmi> activeEmis = [];
}

@embedded
class CreditCardEmi {
  String description = '';
  double totalAmount = 0.0;
  double monthlyInstallment = 0.0;
  int totalMonths = 12;
  int remainingMonths = 12;
  DateTime startDate = DateTime.now();

  CreditCardEmi(); // Required empty constructor for Isar embedded
}

@collection
class Loan {
  Id id = Isar.autoIncrement;

  String contactName = '';
  bool isLent = false; // true if lent, false if borrowed

  double amount = 0.0;
  double interestRate = 0.0; // annual percentage rate (APR)
  String compoundInterval = 'none'; // none, monthly, quarterly, yearly
  DateTime startDate = DateTime.now();
  DateTime? paybackDate;

  double emiAmount = 0.0;
  double remainingBalance = 0.0;

  int? linkedTransactionId; // reference to the transaction id in database
  bool isCompleted = false;
}

@collection
class BankAccount {
  Id id = Isar.autoIncrement;

  String bankName = ''; // e.g. HDFC, SBI
  String accountHolderName = '';
  String last4 = '';
  String fullAccountNumber = '';
  String ifscCode = '';
  double balance = 0.0;
  String logoAsset = ''; // e.g. HDB.svg, SBI-logo.svg
  String colorHex = ''; // e.g. #003366
}
