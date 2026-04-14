import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cycle Insights",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Text(
              "Based on your recent cycles",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // TEMP PLACEHOLDER
            const Expanded(
              child: Center(
                child: Text("Stats coming soon..."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}