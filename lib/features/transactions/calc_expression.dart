const _operators = {'+', '−', '×', '÷'};

bool isCalcOperator(String key) => _operators.contains(key);

double? evaluateExpression(String expression) {
  var text = expression;
  while (text.isNotEmpty && isCalcOperator(text[text.length - 1])) {
    text = text.substring(0, text.length - 1);
  }
  if (text.isEmpty) return null;

  final numbers = <double>[];
  final ops = <String>[];
  final buffer = StringBuffer();

  for (final ch in text.split('')) {
    if (isCalcOperator(ch)) {
      final n = double.tryParse(buffer.toString());
      if (n == null) return null;
      numbers.add(n);
      ops.add(ch);
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  final last = double.tryParse(buffer.toString());
  if (last == null) return null;
  numbers.add(last);

  var i = 0;
  while (i < ops.length) {
    if (ops[i] == '×' || ops[i] == '÷') {
      if (ops[i] == '÷' && numbers[i + 1] == 0) return null;
      numbers[i] = ops[i] == '×'
          ? numbers[i] * numbers[i + 1]
          : numbers[i] / numbers[i + 1];
      numbers.removeAt(i + 1);
      ops.removeAt(i);
    } else {
      i++;
    }
  }

  var result = numbers.first;
  for (var j = 0; j < ops.length; j++) {
    result = ops[j] == '+' ? result + numbers[j + 1] : result - numbers[j + 1];
  }
  return result;
}

String formatCalcResult(double value) {
  final rounded = (value * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String spaceExpression(String expression) {
  final buffer = StringBuffer();
  for (final ch in expression.split('')) {
    buffer.write(isCalcOperator(ch) ? ' $ch ' : ch);
  }
  return buffer.toString();
}
