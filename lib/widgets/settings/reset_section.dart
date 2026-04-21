import 'package:flutter/material.dart';
import 'package:red/services/data_service.dart';

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Reset"),
            onPressed: () async {
              Navigator.pop(context);

              await action();
              await Future.delayed(const Duration(milliseconds: 200));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data reset successful"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
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
        const SizedBox(height: 8),

        _buildTile(
          context: context,
          title: "Reset Period Data",
          subtitle: "Removes all logged cycles",
          icon: Icons.restart_alt_rounded,
          onTap: () {
            _showDialog(
              context: context,
              title: "Delete Period Data?",
              message: "This will remove all logged periods permanently.",
              action: () async {
                await DataService.resetPeriods();
              },
            );
          },
        ),

        _buildTile(
          context: context,
          title: "Reset Preferences",
          subtitle: "Resets cycle settings",
          icon: Icons.tune_rounded,
          onTap: () {
            _showDialog(
              context: context,
              title: "Reset Preferences?",
              message: "This will reset cycle settings.",
              action: () async {
                await DataService.resetPreferences();
              },
            );
          },
        ),

        _buildTile(
          context: context,
          title: "Reset Everything",
          subtitle: "Clears all app data",
          icon: Icons.delete_outline,
          onTap: () {
            _showDialog(
              context: context,
              title: "Reset Everything?",
              message: "This will delete ALL data permanently.",
              action: () async {
                await DataService.resetAllData();
                onResetComplete(); // ONLY here
              },
            );
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C1).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFFF06292),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}