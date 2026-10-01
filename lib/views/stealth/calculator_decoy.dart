import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stealth_provider.dart';

class CalculatorDecoy extends StatefulWidget {
  const CalculatorDecoy({super.key});

  @override
  State<CalculatorDecoy> createState() => _CalculatorDecoyState();
}

class _CalculatorDecoyState extends State<CalculatorDecoy> {
  String _display = "0";

  void _onKeyPress(String key) {
    final stealth = Provider.of<StealthProvider>(context, listen: false);

    if (key == "C") {
      setState(() {
        _display = "0";
      });
      return;
    }

    if (key == "=") {
      if (stealth.unlockFromDecoy(_display)) {
        return;
      }
      setState(() {
        _display = "Error";
      });
      return;
    }

    setState(() {
      if (_display == "0" || _display == "Error") {
        _display = key;
      } else {
        _display += key;
      }
    });

    if (stealth.unlockFromDecoy(_display)) {
      _display = "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Calculator Display Area
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Keypad Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildRow(["C", "+/-", "%", "/"]),
                  const SizedBox(height: 12),
                  _buildRow(["7", "8", "9", "*"]),
                  const SizedBox(height: 12),
                  _buildRow(["4", "5", "6", "-"]),
                  const SizedBox(height: 12),
                  _buildRow(["1", "2", "3", "+"]),
                  const SizedBox(height: 12),
                  _buildRow(["0", ".", "AC", "="]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) {
        final isOp = ["/", "*", "-", "+", "="].contains(k);
        final isClear = ["C", "+/-", "%", "AC"].contains(k);

        return GestureDetector(
          onTap: () => _onKeyPress(k),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isOp
                  ? Colors.orange
                  : isClear
                      ? Colors.grey.shade700
                      : Colors.grey.shade900,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isClear ? Colors.black : Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
