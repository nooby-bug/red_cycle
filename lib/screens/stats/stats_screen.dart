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
  // --- New State Variables ---
  int _shortestCycle = 0;
  int _longestCycle = 0;

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

    // --- B. Calculate Cycle Variations & Averages (UPDATED LOGIC) ---
    // STEP 1.1: Create list to store valid cycle lengths
    List<int> cycleLengths = [];

    for (int i = 0; i < sortedEntries.length - 1; i++) {
      final length = sortedEntries[i + 1].startDate.difference(sortedEntries[i].startDate).inDays;

      // STEP 1.2: Add valid lengths to the list
      if (length >= 10 && length <= 60) {
        cycleLengths.add(length);
      }
    }

    double avgCycle = 0;
    int lastCycle = 0;
    // STEP 1.3: Calculate shortest and longest from the collected list
    int shortest = 0;
    int longest = 0;

    if (cycleLengths.isNotEmpty) {
      avgCycle = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      lastCycle = cycleLengths.last;
      shortest = cycleLengths.reduce((a, b) => a < b ? a : b);
      longest = cycleLengths.reduce((a, b) => a > b ? a : b);
    }

    // --- Final Step: Update UI State ---
    setState(() {
      _avgPeriodLength = avgPeriod;
      _avgCycleLength = avgCycle;
      _lastCycleLength = lastCycle;
      // STEP 1.4: Update new state variables
      _shortestCycle = shortest;
      _longestCycle = longest;
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

              // --- STEP 3: Add new card to the UI ---
              const SizedBox(height: 24),
              _CycleVariationCard(
                shortestCycle: _shortestCycle,
                longestCycle: _longestCycle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// UI WIDGET: Key Metrics Card (Unchanged)
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
              color: const Color(0xFF333333).withOpacity(0.8), // Fixed
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
            color: Colors.pink.withOpacity(0.03), // Fixed
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withOpacity(0.05)), // Fixed
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
            value: avgCycleLength > 0 ? '${avgCycleLength.round()} days' : '--',
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

// ===============================================
// STEP 2: UI WIDGET: Cycle Variation Card (NEW)
// ===============================================
class _CycleVariationCard extends StatelessWidget {
  final int shortestCycle;
  final int longestCycle;

  const _CycleVariationCard({
    required this.shortestCycle,
    required this.longestCycle,
  });

  Widget _buildVariationRow({required String label, required String value}) {
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
            color: Colors.pink.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title ---
          const Text(
            'Cycle Variation',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600, // Semi-bold
              color: Color(0xFF6D4C51), // Darker pink-grey
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on recent cycles',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // --- Content Rows ---
          _buildVariationRow(
            label: 'Shortest Cycle',
            value: shortestCycle > 0 ? '$shortestCycle days' : '--',
          ),
          _buildVariationRow(
            label: 'Longest Cycle',
            value: longestCycle > 0 ? '$longestCycle days' : '--',
          ),
        ],
      ),
    );
  }
}