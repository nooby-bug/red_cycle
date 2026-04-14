import 'package:flutter/material.dart';
import 'package:red/database/database_helper.dart';
import 'package:red/models/period_entry.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;

  // --- Metrics ---
  double _avgCycleLength = 0;
  double _avgPeriodLength = 0;
  int _lastCycleLength = 0;

  int _shortestCycle = 0;
  int _longestCycle = 0;

  List<int> _cycleLengths = [];

  @override
  void initState() {
    super.initState();
    _loadAndCalculateStats();
  }

  Future<void> _loadAndCalculateStats() async {
    final entries = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    if (entries.length < 2) {
      setState(() => _isLoading = false);
      return;
    }

    final sorted = List<PeriodEntry>.from(entries)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // -------- Period Length --------
    int totalPeriod = 0;
    int periodCount = 0;

    for (final e in sorted) {
      if (e.endDate != null) {
        final len = e.endDate!.difference(e.startDate).inDays + 1;
        totalPeriod += len;
        periodCount++;
      }
    }

    final avgPeriod =
    periodCount > 0 ? totalPeriod / periodCount : 0.0;

    // -------- Cycle Length --------
    int totalCycle = 0;
    int cycleCount = 0;
    int lastCycle = 0;

    List<int> cycleLengths = [];

    for (int i = 0; i < sorted.length - 1; i++) {
      final len = sorted[i + 1]
          .startDate
          .difference(sorted[i].startDate)
          .inDays;

      if (len >= 10 && len <= 60) {
        totalCycle += len;
        cycleCount++;
        lastCycle = len;
        cycleLengths.add(len);
      }
    }

    final avgCycle =
    cycleCount > 0 ? totalCycle / cycleCount : 0.0;

    // -------- Variation --------
    int shortest = 0;
    int longest = 0;

    if (cycleLengths.isNotEmpty) {
      shortest = cycleLengths.reduce((a, b) => a < b ? a : b);
      longest = cycleLengths.reduce((a, b) => a > b ? a : b);
    }

    setState(() {
      _avgCycleLength = avgCycle;
      _avgPeriodLength = avgPeriod;
      _lastCycleLength = lastCycle;

      _shortestCycle = shortest;
      _longestCycle = longest;

      _cycleLengths = cycleLengths;

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        title: const Text("Cycle Insights"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              const Text(
                "Based on your recent cycles",
                style:
                TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 24),

              _KeyMetricsCard(
                avgCycleLength: _avgCycleLength,
                avgPeriodLength: _avgPeriodLength,
                lastCycleLength: _lastCycleLength,
              ),

              const SizedBox(height: 24),

              _CycleVariationCard(
                shortest: _shortestCycle,
                longest: _longestCycle,
              ),

              const SizedBox(height: 24),

              _CycleTrendCard(
                cycleLengths: _cycleLengths,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ===================== KEY METRICS =====================
//
class _KeyMetricsCard extends StatelessWidget {
  final double avgCycleLength;
  final double avgPeriodLength;
  final int lastCycleLength;

  const _KeyMetricsCard({
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.lastCycleLength,
  });

  Widget row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF06292)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF333333)
                  .withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD36275),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      title: "Your Cycle Overview",
      children: [
        row(
            "Average Cycle Length",
            avgCycleLength > 0
                ? "${avgCycleLength.round()} days"
                : "--",
            Icons.refresh),
        row(
            "Average Period Length",
            avgPeriodLength > 0
                ? "${avgPeriodLength.round()} days"
                : "--",
            Icons.water_drop),
        row(
            "Last Cycle Length",
            lastCycleLength > 0
                ? "$lastCycleLength days"
                : "--",
            Icons.schedule),
      ],
    );
  }
}

//
// ===================== VARIATION =====================
//
class _CycleVariationCard extends StatelessWidget {
  final int shortest;
  final int longest;

  const _CycleVariationCard({
    required this.shortest,
    required this.longest,
  });
  Widget _buildSimpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF333333)
                  .withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD36275),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      title: "Cycle Variation",
      subtitle: "Based on recent cycles",
      children: [
        _buildSimpleRow(
          "Shortest Cycle",
          shortest > 0 ? "$shortest days" : "--",
        ),
        _buildSimpleRow(
          "Longest Cycle",
          longest > 0 ? "$longest days" : "--",
        ),
      ],
    );
  }
}

//
// ===================== TREND =====================
//
class _CycleTrendCard extends StatelessWidget {
  final List<int> cycleLengths;

  const _CycleTrendCard({required this.cycleLengths});

  @override
  Widget build(BuildContext context) {
    if (cycleLengths.length < 2) {
      return _card(
        title: "Cycle Trend",
        subtitle: "Last few cycles",
        children: const [
          Text("Not enough data for trend"),
        ],
      );
    }
    final minY =
    cycleLengths.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY =
    cycleLengths.reduce((a, b) => a > b ? a : b).toDouble();

    final spots = List.generate(
      cycleLengths.length,
          (i) => FlSpot(
        i.toDouble(),
        cycleLengths[i].toDouble(),
      ),
    );

    return _card(
      title: "Cycle Trend",
      subtitle: "Last few cycles",
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: minY - 2,
              maxY: maxY + 2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey
                        .withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= cycleLengths.length) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "C${index + 1}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: false)),
              ),
              borderData:
              FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.15,
                  color: const Color(0xFFF48FB1),
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//
// ===================== COMMON CARD =====================
//
Widget _card({
  required String title,
  String? subtitle,
  required List<Widget> children,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5F7),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
      border: Border.all(
        color: Colors.pink.withValues(alpha: 0.05),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF6D4C51),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}
