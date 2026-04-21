import 'package:flutter/material.dart';
import '../../services/data_reset_service.dart';

class ResetSection extends StatelessWidget {
  final VoidCallback onResetComplete;

  const ResetSection({super.key, required this.onResetComplete});

  Future<void> _showDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context); // close dialog

              await action(); // perform reset
              await Future.delayed(const Duration(milliseconds: 200));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data reset successful"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              onResetComplete(); // navigate back to home
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        ListTile(
          title: const Text("Reset Period Data"),
          onTap: () {
            _showDialog(
              context: context,
              title: "Delete Period Data?",
              message: "This will remove all logged periods permanently.",
              action: DataResetService.resetPeriods,
            );
          },
        ),

        ListTile(
          title: const Text("Reset Preferences"),
          onTap: () {
            _showDialog(
              context: context,
              title: "Reset Preferences?",
              message: "This will reset cycle settings.",
              action: DataResetService.resetPreferences,
            );
          },
        ),

        ListTile(
          title: const Text("Reset Everything"),
          onTap: () {
            _showDialog(
              context: context,
              title: "Reset Everything?",
              message: "This will delete ALL data permanently.",
              action: DataResetService.resetAll,
            );
          },
        ),
      ],
    );
  }
}