import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class CalculatorSheet extends StatefulWidget {
  final Function(double amount)? onAmountSelected;
  final double? initialAmount;

  const CalculatorSheet({
    super.key,
    this.onAmountSelected,
    this.initialAmount,
  });

  static Future<double?> show(BuildContext context, {double? initialAmount, Function(double amount)? onAmountSelected}) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalculatorSheet(
        initialAmount: initialAmount,
        onAmountSelected: onAmountSelected,
      ),
    );
  }

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expression = '';
  String _liveResult = '';
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _expression = widget.initialAmount!.toStringAsFixed(
        widget.initialAmount! % 1 == 0 ? 0 : 2,
      );
      _calculateLiveResult();
    }
  }

  void _onKeyPress(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'AC') {
        _expression = '';
        _liveResult = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        final res = _evaluate();
        if (res != null) {
          final resStr = res % 1 == 0 ? res.toInt().toString() : res.toStringAsFixed(2);
          if (_expression.isNotEmpty && _expression != resStr) {
            _history.insert(0, '$_expression = $resStr');
            if (_history.length > 5) _history.removeLast();
          }
          _expression = resStr;
          _liveResult = '';
        }
      } else {
        // Operators check to avoid invalid double operators like ++ or **
        if (_isOperator(value)) {
          if (_expression.isEmpty) {
            if (value == '-') _expression += value;
            return;
          }
          final lastChar = _expression[_expression.length - 1];
          if (_isOperator(lastChar)) {
            _expression = _expression.substring(0, _expression.length - 1) + value;
            _calculateLiveResult();
            return;
          }
        }
        _expression += value;
      }
      _calculateLiveResult();
    });
  }

  bool _isOperator(String char) {
    return ['+', '-', '×', '÷', '%'].contains(char);
  }

  void _calculateLiveResult() {
    if (_expression.isEmpty) {
      _liveResult = '';
      return;
    }
    final res = _evaluate();
    if (res != null) {
      _liveResult = res % 1 == 0 ? res.toInt().toString() : res.toStringAsFixed(2);
    } else {
      _liveResult = '';
    }
  }

  double? _evaluate() {
    if (_expression.isEmpty) return null;
    try {
      String clean = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll(' ', '');

      if (clean.isEmpty) return null;

      // Tokenize
      List<String> tokens = [];
      String currentNum = '';
      for (int i = 0; i < clean.length; i++) {
        String char = clean[i];
        if ('0123456789.'.contains(char)) {
          currentNum += char;
        } else if ('+-*/%'.contains(char)) {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          } else if (char == '-' && (tokens.isEmpty || '+-*/%'.contains(tokens.last))) {
            currentNum += char;
            continue;
          }
          tokens.add(char);
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(currentNum);
      }

      if (tokens.isEmpty) return null;

      // Pass 1: Multiply, Divide, Percent
      List<String> pass1 = [];
      int i = 0;
      while (i < tokens.length) {
        String token = tokens[i];
        if (token == '*' || token == '/' || token == '%') {
          if (pass1.isEmpty || i + 1 >= tokens.length) return null;
          double prev = double.tryParse(pass1.removeLast()) ?? 0;
          double next = double.tryParse(tokens[i + 1]) ?? 0;
          double res = 0;
          if (token == '*') res = prev * next;
          if (token == '/') {
            if (next == 0) return null;
            res = prev / next;
          }
          if (token == '%') res = prev * (next / 100);
          pass1.add(res.toString());
          i += 2;
        } else {
          pass1.add(token);
          i++;
        }
      }

      if (pass1.isEmpty) return null;

      // Pass 2: Add, Subtract
      double result = double.tryParse(pass1[0]) ?? 0;
      int j = 1;
      while (j < pass1.length) {
        String op = pass1[j];
        if (j + 1 >= pass1.length) break;
        double next = double.tryParse(pass1[j + 1]) ?? 0;
        if (op == '+') result += next;
        if (op == '-') result -= next;
        j += 2;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  void _applyResult() {
    final res = _evaluate() ?? double.tryParse(_expression) ?? 0.0;
    if (widget.onAmountSelected != null) {
      widget.onAmountSelected!(res);
    }
    Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Smart Calculator',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Display Screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // History snippet if any
                  if (_history.isNotEmpty)
                    Text(
                      _history.first,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Active Expression
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _expression.isEmpty
                            ? Colors.grey.shade400
                            : (isDark ? Colors.white : Colors.black87),
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // Live Calculated Result Preview
                  if (_liveResult.isNotEmpty && _liveResult != _expression)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '= $_liveResult',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calculator Keypad Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.35,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildCalcButton('AC', color: Colors.red.shade100, textColor: Colors.red.shade800),
                _buildCalcButton('⌫', color: Colors.orange.shade100, textColor: Colors.orange.shade900),
                _buildCalcButton('%', color: AppColors.primary.withValues(alpha: 0.15), textColor: AppColors.primary),
                _buildCalcButton('÷', color: AppColors.primary.withValues(alpha: 0.15), textColor: AppColors.primary),

                _buildCalcButton('7'),
                _buildCalcButton('8'),
                _buildCalcButton('9'),
                _buildCalcButton('×', color: AppColors.primary.withValues(alpha: 0.15), textColor: AppColors.primary),

                _buildCalcButton('4'),
                _buildCalcButton('5'),
                _buildCalcButton('6'),
                _buildCalcButton('-', color: AppColors.primary.withValues(alpha: 0.15), textColor: AppColors.primary),

                _buildCalcButton('1'),
                _buildCalcButton('2'),
                _buildCalcButton('3'),
                _buildCalcButton('+', color: AppColors.primary.withValues(alpha: 0.15), textColor: AppColors.primary),

                _buildCalcButton('00'),
                _buildCalcButton('0'),
                _buildCalcButton('.'),
                _buildCalcButton('=', color: AppColors.primary, textColor: Colors.white, isFilled: true),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Action (If opened to return amount or general use)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _applyResult,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  widget.onAmountSelected != null
                      ? 'Use Amount (${_liveResult.isNotEmpty ? _liveResult : (_expression.isEmpty ? "0" : _expression)})'
                      : 'Done',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcButton(
    String label, {
    Color? color,
    Color? textColor,
    bool isFilled = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final defaultTxt = isDark ? Colors.white : Colors.black87;

    return Material(
      color: isFilled ? (color ?? AppColors.primary) : (color ?? defaultBg),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onKeyPress(label),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isFilled ? (textColor ?? Colors.white) : (textColor ?? defaultTxt),
            ),
          ),
        ),
      ),
    );
  }
}
