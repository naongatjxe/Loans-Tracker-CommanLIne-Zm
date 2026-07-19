import 'package:flutter/services.dart';

class NrcInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final length = text.length;

    // Limit to 9 digits maximum
    final digits = length > 9 ? text.substring(0, 9) : text;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 5 && digits.length > 6) {
        buffer.write('/');
      } else if (i == 7 && digits.length > 8) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
