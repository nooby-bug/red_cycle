import 'package:flutter/material.dart';

class KeyMetricsCard extends StatelessWidget {
  const KeyMetricsCard({super.key});

  /// A reusable helper widget for displaying a single metric row.
  Widget _buildMetricRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333).withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title ---
          const Text(
            'Your Cycle Overview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600, // Semi-bold
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          // --- Content Rows ---
          _buildMetricRow(
            label: 'Average Cycle Length',
            value: '29 days',
          ),
          _buildMetricRow(
            label: 'Average Period Length',
            value: '5 days',
          ),
          _buildMetricRow(
            label: 'Last Cycle Length',
            value: '30 days',
          ),
        ],
      ),
    );
  }
}