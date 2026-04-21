import 'package:flutter/material.dart';

class KeyMetricsCard extends StatelessWidget {
  final double avgCycleLength;
  final double avgPeriodLength;
  final int lastCycleLength;

  const KeyMetricsCard({
    super.key,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.lastCycleLength,
  });

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
          const Text(
            'Your Cycle Overview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          _buildMetricRow(
            label: 'Average Cycle Length',
            value: avgCycleLength > 0
                ? '${avgCycleLength.round()} days'
                : '--',
          ),
          _buildMetricRow(
            label: 'Average Period Length',
            value: avgPeriodLength > 0
                ? '${avgPeriodLength.round()} days'
                : '--',
          ),
          _buildMetricRow(
            label: 'Last Cycle Length',
            value: lastCycleLength > 0
                ? '$lastCycleLength days'
                : '--',
          ),
        ],
      ),
    );
  }
}