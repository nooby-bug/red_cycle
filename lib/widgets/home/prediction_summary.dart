import 'package:flutter/material.dart';
import 'package:red/screens/stats/stats_screen.dart';

class PredictionSummary extends StatelessWidget {
  final String nextPeriodDate;
  final String ovulationDate;
  final String fertileWindow;

  const PredictionSummary({
    super.key,
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileWindow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Your Cycle Summary",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 16),

        /// 👇 Wrapped with GestureDetector
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatsScreen(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.05)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildSummaryRow(
                    icon: Icons.water_drop_rounded,
                    iconBgColor: const Color(0xFFFFF0F5),
                    iconColor: const Color(0xFFE57373),
                    title: "Next Period",
                    date: nextPeriodDate,
                  ),
                  _buildSummaryRow(
                    icon: Icons.egg_alt_rounded,
                    iconBgColor: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFFBA68C8),
                    title: "Ovulation",
                    date: ovulationDate,
                  ),
                  _buildSummaryRow(
                    icon: Icons.favorite_rounded,
                    iconBgColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF81C784),
                    title: "Fertile Window",
                    date: fertileWindow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF333333),
          ),
        ),
        trailing: Text(
          date,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}