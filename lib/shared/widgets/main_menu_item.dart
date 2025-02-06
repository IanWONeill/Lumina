import 'package:flutter/material.dart';

class MainMenuItem extends StatelessWidget {
  const MainMenuItem({
    super.key,
    required this.item,
    required this.isFocused,
  });

  final MenuItem item;
  final bool isFocused;

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isFocused ? Colors.blue : Colors.white10,
              isFocused ? Colors.blue.shade900 : Colors.black45,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFocused ? Colors.white30 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 36,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

class MenuItem {
  const MenuItem({
    required this.icon,
    required this.label,
    required this.destination,
  });

  final IconData icon;
  final String label;
  final Widget destination;
} 