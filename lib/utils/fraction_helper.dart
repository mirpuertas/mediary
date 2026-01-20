class FractionHelper {
  // Convierte una fracción (numerator/denominator) a texto legible
  // Ejemplos:
  // - 1/1 → "1"
  // - 1/2 → "½"
  // - 3/4 → "¾"
  // - 5/4 → "1¼"
  static String fractionToText(int numerator, int denominator) {
    if (denominator == 0) return '0';
    if (denominator == 1) return numerator.toString();

    final gcd = _gcd(numerator, denominator);
    final simplifiedNum = numerator ~/ gcd;
    final simplifiedDen = denominator ~/ gcd;

    if (simplifiedDen == 1) return simplifiedNum.toString();

    if (simplifiedNum < simplifiedDen) {
      return _getFractionSymbol(simplifiedNum, simplifiedDen);
    } else {
      final whole = simplifiedNum ~/ simplifiedDen;
      final remainder = simplifiedNum % simplifiedDen;

      if (remainder == 0) {
        return whole.toString();
      }

      final fractionPart = _getFractionSymbol(remainder, simplifiedDen);
      return '$whole$fractionPart';
    }
  }

  // Retorna el símbolo Unicode para fracciones comunes, o formato "n/d" para otras
  static String _getFractionSymbol(int num, int den) {
    final key = '$num/$den';
    const symbols = {
      '1/2': '½',
      '1/3': '⅓',
      '2/3': '⅔',
      '1/4': '¼',
      '3/4': '¾',
      '1/5': '⅕',
      '2/5': '⅖',
      '3/5': '⅗',
      '4/5': '⅘',
      '1/6': '⅙',
      '5/6': '⅚',
      '1/8': '⅛',
      '3/8': '⅜',
      '5/8': '⅝',
      '7/8': '⅞',
    };

    return symbols[key] ?? '$num/$den';
  }

  // Calcula el máximo común divisor para simplificar fracciones
  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }
}
