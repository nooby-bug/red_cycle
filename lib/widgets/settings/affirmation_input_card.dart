import 'package:flutter/material.dart';

class AffirmationInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isEnabled;
  final VoidCallback onAdd;

  const AffirmationInputCard({
    super.key,
    required this.controller,
    required this.isEnabled,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                decoration: const InputDecoration(
                  hintText: 'Write your affirmation...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFFF06292),
                size: 32,
              ),
              onPressed: isEnabled ? onAdd : null,
            ),
          ],
        ),
      ),
    );
  }
}