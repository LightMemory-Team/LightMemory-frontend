import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  final String userName;
  final String dailyTip;

  const GreetingSection({
    super.key,
    required this.userName,
    required this.dailyTip,
  });

  String get _timeGreetingWord {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return '早安';
    } else if (hour < 18) {
      return '午安';
    } else {
      return '晚安';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_timeGreetingWord，$userName！',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dailyTip,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}