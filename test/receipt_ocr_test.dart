import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/features/expenses/services/receipt_ocr_service.dart';

void main() {
  group('Receipt OCR Text Parsing Tests', () {
    test('Should parse simple merchant, date, and amount correctly', () {
      const sample = '''
Reliance Retail
Date: 15-07-2026
Item 1: 200.00
Item 2: 300.00
Total Amount: Rs 500.00
Thank you for shopping!
''';

      final result = ReceiptOcrService.parseText(sample);

      expect(result.merchant, 'Reliance Retail');
      expect(result.amount, 500.00);
      expect(result.date, DateTime(2026, 7, 15));
    });

    test('Should parse different date format (YYYY/MM/DD) and currency symbol (INR)', () {
      const sample = '''
Amazon Pay
Date: 2026/08/20
Total due: INR 1250.75
''';

      final result = ReceiptOcrService.parseText(sample);

      expect(result.merchant, 'Amazon Pay');
      expect(result.amount, 1250.75);
      expect(result.date, DateTime(2026, 8, 20));
    });

    test('Should parse unstructured receipt text with spaces and headers gracefully', () {
      const sample = '''
McDonalds India
Address: Connaught Place, New Delhi
18-07-2026 12:45
TAX INVOICE
2x McVeggie: Rs. 320
Total: Rs. 320.00
''';

      final result = ReceiptOcrService.parseText(sample);

      expect(result.merchant, 'McDonalds India');
      expect(result.amount, 320.00);
      expect(result.date, DateTime(2026, 7, 18));
    });
  });
}
