import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class PollResultsScreen extends StatelessWidget {
  final DocumentSnapshot pollDoc;

  const PollResultsScreen({super.key, required this.pollDoc});

  @override
  Widget build(BuildContext context) {
    final poll = pollDoc.data() as Map<String, dynamic>;
    final Map<String, dynamic> votes = Map<String, dynamic>.from(poll['votes']);
    final int totalVotes = votes.values.fold<int>(0, (totalsum, val) => totalsum + (val as int));
    final List<String> options = votes.keys.toList();

    // Blue-themed colors for the bars
    final List<Color> barColors = [
      const Color(0xFF1976D2),  // Blue shade 600
      const Color(0xFF1565C0),  // Blue shade 700
      const Color(0xFF0D47A1),  // Blue shade 800
      const Color(0xFF64B5F6),  // Light Blue accent
      const Color(0xFF1976D2),  // Blue shade 600 (repeat)
      const Color(0xFF0288D1),  // Light Blue accent
    ];

    final int maxVote = votes.values.isEmpty
        ? 1
        : (votes.values.map((v) => v as int).reduce(max) + 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Poll Results"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),  // Blue shade 600
        elevation: 4,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll['title'] ?? 'Poll Title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF4F6FA)),  // Blue shade 600
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVote.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${options[group.x]}: ${rod.toY.toInt()} vote(s)',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  barGroups: votes.entries.map((entry) {
                    final int index = options.indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value as int).toDouble(),
                          color: barColors[index % barColors.length],
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVote.toDouble(),
                            color: const Color(0xFFE3F2FD), // Light Blue background
                          ),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              options[index],
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),  // Blue shade 700
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0)),  // Blue shade 700
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Total Votes: $totalVotes",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1976D2)),  // Blue shade 600
              ),
            ),
          ],
        ),
      ),
    );
  }
}
