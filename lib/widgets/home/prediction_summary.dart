import 'package:flutter/material.dart';

class PredictionSummary extends StatelessWidget {
  const PredictionSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Your Cycle Summary",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333), // Near black
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow:[
              BoxShadow(
                color: Colors.black.withOpacity(0.02), // Extremely subtle shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.05)), // Clean definition without harshness
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children:[
                _buildSummaryRow(
                  icon: Icons.water_drop_rounded,
                  iconBgColor: const Color(0xFFFFF0F5),
                  iconColor: const Color(0xFFE57373), // Desaturated soft red
                  title: "Next Period",
                  date: "12 April",
                ),
                Divider(height: 1, indent: 64, endIndent: 20, color: Colors.grey.withOpacity(0.08)), // Very clean separator
                _buildSummaryRow(
                  icon: Icons.egg_alt_rounded,
                  iconBgColor: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFFBA68C8), // Soft lavender
                  title: "Ovulation",
                  date: "26 March",
                ),
                Divider(height: 1, indent: 64, endIndent: 20, color: Colors.grey.withOpacity(0.08)),
                _buildSummaryRow(
                  icon: Icons.favorite_rounded,
                  iconBgColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF81C784), // Soft green
                  title: "Fertile Window",
                  date: "22–27 March",
                ),
              ],
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
          child: Icon(icon, color: iconColor, size: 20), // Slightly smaller icon
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500, // Medium weight for calmness
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