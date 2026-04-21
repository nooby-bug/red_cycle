import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:red/database/database_helper.dart'; // Adjust path if needed
import 'package:red/models/period_entry.dart';    // Adjust path if needed
import 'package:red/widgets/stats/key_metrics_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;

  // --- State Variables for Metrics ---
  double _avgCycleLength = 0;
  List<int> _periodLengths = [];
  double _avgPeriodLength = 0;
  int _lastCycleLength = 0;
  int _shortestCycle = 0;
  int _longestCycle = 0;
  List<int> _cycleLengths = [];
  String _insightText = "";

  @override
  void initState() {
    super.initState();
    _loadAndCalculateStats();
  }

  Future<void> _loadAndCalculateStats() async {
    // DATABASE ACCESS: Uses getAllPeriods() directly and returns List<PeriodEntry>
    final entries = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    if (entries.length < 2) {
      setState(() {
        _insightText = "Tracking more cycles can improve predictions.";
        _isLoading = false;
      });
      return;
    }

    final sortedEntries = List<PeriodEntry>.from(entries)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Period Length Calculation
    int totalPeriodDays = 0;
    int validPeriodCount = 0;
    List<int> periodLengths = [];
    for (final entry in sortedEntries) {
      if (entry.endDate != null) {
        final length = entry.endDate!.difference(entry.startDate).inDays + 1;

        totalPeriodDays += length;
        validPeriodCount++;
        periodLengths.add(length);
      }
    }
    final avgPeriod = validPeriodCount > 0 ? totalPeriodDays / validPeriodCount : 0.0;

    // Cycle Length, Variation, and Insight Calculation
    List<int> cycleLengths = [];
    for (int i = 0; i < sortedEntries.length - 1; i++) {
      final length = sortedEntries[i + 1].startDate.difference(sortedEntries[i].startDate).inDays;
      if (length >= 10 && length <= 60) {
        cycleLengths.add(length);
      }
    }

    double avgCycle = 0;
    int lastCycle = 0;
    int shortest = 0;
    int longest = 0;

    if (cycleLengths.isNotEmpty) {
      avgCycle = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      lastCycle = cycleLengths.last;
      shortest = cycleLengths.reduce((a, b) => a < b ? a : b);
      longest = cycleLengths.reduce((a, b) => a > b ? a : b);
    }

    // Insight Logic
    String insightText;
    int variation = longest - shortest;

    if (cycleLengths.length < 3) {
      insightText = "Tracking more cycles can improve predictions.";
    } else {
      if (variation <= 3) {
        insightText = "Your cycle is fairly regular.";
      } else if (variation <= 6) {
        insightText = "Your cycle shows some variation.";
      } else {
        insightText = "Your cycle is irregular.";
      }
    }

    setState(() {
      _avgPeriodLength = avgPeriod;
      _avgCycleLength = avgCycle;
      _lastCycleLength = lastCycle;
      _shortestCycle = shortest;
      _longestCycle = longest;
      _cycleLengths = cycleLengths;
      _periodLengths = periodLengths;
      _insightText = insightText;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        title: const Text('Cycle Insights'), // Fixed Title
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

              KeyMetricsCard(
                avgCycleLength: _avgCycleLength,
                avgPeriodLength: _avgPeriodLength,
                lastCycleLength: _lastCycleLength,
              ),

              const SizedBox(height: 24),
              _CycleVariationCard(
                shortestCycle: _shortestCycle,
                longestCycle: _longestCycle,
              ),

              const SizedBox(height: 24),
              _CycleTrendCard(cycleLengths: _cycleLengths),
              const SizedBox(height: 24),

              _PeriodTrendCard(periodLengths: _periodLengths),

              const SizedBox(height: 24),
              _InsightCard(text: _insightText),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// UI WIDGETS
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
              color: const Color(0xFF333333).withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
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
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cycle Variation',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C51),
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

class _CycleTrendCard extends StatelessWidget {
  final List<int> cycleLengths;

  const _CycleTrendCard({required this.cycleLengths});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < cycleLengths.length; i++) {
      spots.add(FlSpot(i.toDouble(), cycleLengths[i].toDouble()));
    }

    if (cycleLengths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Not enough data for trend.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    final minValue = cycleLengths.reduce((a, b) => a < b ? a : b);
    final maxValue = cycleLengths.reduce((a, b) => a > b ? a : b);

// smart step size
    double step;
    if (maxValue <= 30) {
      step = 2;
    } else if (maxValue <= 50) {
      step = 5;
    } else {
      step = 10;
    }

    final minY = (minValue / step).floor() * step;
    final maxY = (maxValue / step).ceil() * step;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cycle Trend',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C51),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last few cycles',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

        cycleLengths.length < 2
            ? const SizedBox(
          height: 150,
          child: Center(
            child: Text(
              "Not enough data for trend.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
            : SizedBox(
          height: 260,
          child: Row(
            children: [

              // 🔵 FIXED Y-AXIS
              SizedBox(
                width: 40,
                child: LineChart(
                  LineChartData(
                    minY: (minY - step).clamp(0, double.infinity),
                    maxY: maxY + step,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [],

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: step,
                          reservedSize: 40,
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
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),

              // 🔴 SCROLLABLE GRAPH
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: (cycleLengths.length * 80)
                        .clamp(320, double.infinity)
                        .toDouble(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      child: LineChart(
                        LineChartData(
                          clipData: FlClipData.none(),
                          minY: (minY - step).clamp(0, double.infinity),
                          maxY: maxY + step,
                          baselineY: minY,

                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withValues(alpha: 0.08),
                                strokeWidth: 1,
                              );
                            },
                          ),

                          borderData: FlBorderData(show: false),

                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFFF48FB1),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFFF48FB1),
                                    strokeWidth: 0,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF48FB1)
                                        .withValues(alpha: 0.3),
                                    const Color(0xFFF48FB1)
                                        .withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],

                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),

                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),

                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 != 0) return const SizedBox();

                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= cycleLengths.length) {
                                    return const SizedBox();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'C${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        ],
      ),
    );
  }
}

class _PeriodTrendCard extends StatelessWidget {
  final List<int> periodLengths;

  const _PeriodTrendCard({required this.periodLengths});

  @override
  Widget build(BuildContext context) {
    if (periodLengths.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Not enough data for period trend",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = List.generate(
      periodLengths.length,
          (i) => FlSpot(i.toDouble(), periodLengths[i].toDouble()),
    );

    if (periodLengths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Not enough data for period trend.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    final minValue = periodLengths.reduce((a, b) => a < b ? a : b);
    final maxValue = periodLengths.reduce((a, b) => a > b ? a : b);

// smart step size
    double step;
    if (maxValue <= 10) {
      step = 1;
    } else if (maxValue <= 20) {
      step = 2;
    } else if (maxValue <= 40) {
      step = 5;
    } else {
      step = 10;
    }

    final minY = (minValue / step).floor() * step;
    final maxY = (maxValue / step).ceil() * step;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Period Length Trend',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C51),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last few periods',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: Row(
              children: [
                // 🔵 FIXED Y AXIS (does NOT scroll)
                SizedBox(
                  width: 40,
                  child: LineChart(
                    LineChartData(
                      minY: minY.clamp(0, double.infinity),
                      maxY: maxY + step,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: step,
                            reservedSize: 40,
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
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: const [],
                    ),
                  ),
                ),

                // 🔴 SCROLLABLE GRAPH
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (periodLengths.length * 80)
                          .clamp(320, double.infinity)
                          .toDouble(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 12),
                        child: LineChart(
                          LineChartData(
                            clipData: FlClipData.none(),
                            minY: minY.clamp(0, double.infinity),
                            maxY: maxY + step,
                            baselineY: minY,

                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),

                            borderData: FlBorderData(show: false),

                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: periodLengths.length > 3,
                                color: const Color(0xFFF48FB1),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF48FB1)
                                          .withValues(alpha: 0.3),
                                      const Color(0xFFF48FB1)
                                          .withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],

                            titlesData: FlTitlesData(
                              // ❌ hide left axis here (already shown separately)
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return const SizedBox();

                                    final index = value.toInt();
                                    if (index < 0 || index >= periodLengths.length) {
                                      return const SizedBox();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'P${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C51),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}