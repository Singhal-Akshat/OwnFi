extension CurrencyFormatter on num {
  String toIndianRupee() {
    final sign = this < 0 ? '-' : '';
    final absVal = abs();
    final str = absVal.toStringAsFixed(0);
    String result = str;
    if (str.length > 3) {
      // Group last 3 digits, then groups of 2 for Indian Lakhs/Crores grouping
      final last3 = str.substring(str.length - 3);
      final rest = str.substring(0, str.length - 3);
      final restGrouped = rest.replaceAllMapped(
        RegExp(r'(\d+?)(?=(\d{2})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      result = '$restGrouped,$last3';
    }
    return '$sign₹$result';
  }
}
