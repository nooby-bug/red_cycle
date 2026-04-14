import 'package:flutter/material.dart';
import 'package:red/database/database_helper.dart';
import 'package:red/models/period_entry.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;

  // --- State Variables for Metrics ---
  double _avgCycleLength = 0;
  double _avgPeriodLength = 0;
  int _lastCycleLength = 0;

  @override
  void initState() {
    super.initState();
    _loadAndCalculateStats();
  }

  /// Fetches period data and calculates all key metrics.
  Future<void> _loadAndCalculateStats() async {
    // 1. Fetch all periods
    final entries = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    // Edge Case: Not enough data to calculate anything
    if (entries.length < 2) {
      setState(() => _isLoading = false);
      return;
    }

    // 2. Sort periods oldest to newest
    final sortedEntries = List<PeriodEntry>.from(entries)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // --- A. Calculate Average Period Length ---
    int totalPeriodDays = 0;
    int validPeriodCount = 0;
    for (final entry in sortedEntries) {
      if (entry.endDate != null) {
        final length = entry.endDate!.difference(entry.startDate).inDays + 1;
        totalPeriodDays += length;
        validPeriodCount++;
      }
    }
    final avgPeriod = validPeriodCount > 0 ? totalPeriodDays / validPeriodCount : 0.0;

    // --- B. Calculate Average & Last Cycle Length ---
    int totalCycleDays = 0;
    int validCycleCount = 0;
    int lastCycle = 0;
    for (int i = 0; i < sortedEntries.length - 1; i++) {
      final length = sortedEntries[i + 1].startDate.difference(sortedEntries[i].startDate).inDays;

      if (length >= 10 && length <= 60) {
        totalCycleDays += length;
        validCycleCount++;
        lastCycle = length; // The last valid one calculated is the most recent
      }
    }
    final avgCycle = validCycleCount > 0 ? totalCycleDays / validCycleCount : 0.0;

    // --- Final Step: Update UI State ---
    setState(() {
      _avgPeriodLength = avgPeriod;
      _avgCycleLength = avgCycle;
      _lastCycleLength = lastCycle;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6), // Main screen background
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'A summary of your recent cycle data.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // --- Render the styled Key Metrics Card with real data ---
              _KeyMetricsCard(
                avgCycleLength: _avgCycleLength,
                avgPeriodLength: _avgPeriodLength,
                lastCycleLength: _lastCycleLength,
              ),

              // You can add more cards/widgets below this in the future
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// UI WIDGET: Key Metrics Card
// ===============================================
class _KeyMetricsCard extends StatelessWidget {
  final double avgCycleLength;
  final double avgPeriodLength;
  final int lastCycleLength;

  const _KeyMetricsCard({
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.lastCycleLength,
  });

  /// A reusable helper widget for displaying a single metric row.
  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF06292), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333).withValues(alpha: 0.5)
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD36275), // Darker pink for value
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
        color: const Color(0xFFFFF5F7), // VERY LIGHT PINK background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.06)),
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
              color: Color(0xFF6D4C51), // Darker pink-grey
            ),
          ),
          const SizedBox(height: 16),

          // --- Content Rows ---
          _buildMetricRow(
            icon: Icons.refresh_rounded,
            label: 'Average Cycle Length',
            value: avgCycleLength > 0 ? '${avgCycleLength.toStringAsFixed(0)} days' : '--',
          ),
          _buildMetricRow(
            icon: Icons.water_drop_outlined,
            label: 'Average Period Length',
            value: avgPeriodLength > 0 ? '${avgPeriodLength.round()} days' : '--',
          ),
          _buildMetricRow(
            icon: Icons.schedule_rounded,
            label: 'Last Cycle Length',
            value: lastCycleLength > 0 ? '$lastCycleLength days' : '--',
          ),
        ],
      ),
    );
  }
}