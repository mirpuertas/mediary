import 'package:flutter/material.dart';
import '../utils/fraction_helper.dart';

class FractionResult {
  final int numerator;
  final int denominator;

  const FractionResult({required this.numerator, required this.denominator});
}

class FractionPickerDialog extends StatefulWidget {
  final int initialNumerator;
  final int initialDenominator;
  final String title;

  const FractionPickerDialog({
    super.key,
    required this.initialNumerator,
    required this.initialDenominator,
    this.title = 'Cantidad',
  });

  static Future<FractionResult?> show(
    BuildContext context, {
    required int initialNumerator,
    required int initialDenominator,
    String title = 'Cantidad',
  }) async {
    return await showDialog<FractionResult>(
      context: context,
      builder: (context) => FractionPickerDialog(
        initialNumerator: initialNumerator,
        initialDenominator: initialDenominator,
        title: title,
      ),
    );
  }

  @override
  State<FractionPickerDialog> createState() => _FractionPickerDialogState();
}

class _FractionPickerDialogState extends State<FractionPickerDialog> {
  late int _whole;
  late String _selectedFrac;

  String _findClosestFraction(double value) {
    final options = [
      {'key': '0', 'value': 0.0},
      {'key': '1/4', 'value': 0.25},
      {'key': '1/2', 'value': 0.5},
      {'key': '3/4', 'value': 0.75},
    ];

    String closest = '0';
    double minDiff = double.infinity;

    for (final option in options) {
      final diff = ((option['value'] as double) - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = option['key'] as String;
      }
    }

    return closest;
  }

  @override
  void initState() {
    super.initState();

    _whole = widget.initialNumerator ~/ widget.initialDenominator;
    final fracNum = widget.initialNumerator % widget.initialDenominator;
    final fracDen = widget.initialDenominator;

    if (fracNum == 0) {
      _selectedFrac = '0';
    } else if (fracNum == 1 && fracDen == 4) {
      _selectedFrac = '1/4';
    } else if (fracNum == 1 && fracDen == 2) {
      _selectedFrac = '1/2';
    } else if (fracNum == 3 && fracDen == 4) {
      _selectedFrac = '3/4';
    } else {
      // No coincide: elegir la más cercana
      final fracValue = fracDen > 0 ? fracNum / fracDen : 0.0;
      _selectedFrac = _findClosestFraction(fracValue);
    }
  }

  void _calculateImproperFraction(
    int whole,
    String frac,
    void Function(int num, int den) callback,
  ) {
    if (frac == '0') {
      callback(whole, 1);
    } else {
      final parts = frac.split('/');
      final fNum = int.parse(parts[0]);
      final fDen = int.parse(parts[1]);
      final improperNum = whole * fDen + fNum;
      callback(improperNum, fDen);
    }
  }

  @override
  Widget build(BuildContext context) {
    int previewNum = 0;
    int previewDen = 1;
    _calculateImproperFraction(_whole, _selectedFrac, (n, d) {
      previewNum = n;
      previewDen = d;
    });
    final previewText = FractionHelper.fractionToText(previewNum, previewDen);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _whole,
            decoration: const InputDecoration(
              labelText: 'Enteros',
              border: OutlineInputBorder(),
            ),
            items: List.generate(11, (i) => i).map((n) {
              return DropdownMenuItem(value: n, child: Text(n.toString()));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _whole = value ?? 0;
              });
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedFrac,
            decoration: const InputDecoration(
              labelText: 'Fracción',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '0', child: Text('0 (ninguna)')),
              DropdownMenuItem(value: '1/4', child: Text('¼')),
              DropdownMenuItem(value: '1/2', child: Text('½')),
              DropdownMenuItem(value: '3/4', child: Text('¾')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFrac = value ?? '0';
              });
            },
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Preview: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  previewText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              FractionResult(numerator: previewNum, denominator: previewDen),
            );
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
