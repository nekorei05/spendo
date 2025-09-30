import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'home_screen.dart'; // <-- make sure this exists

enum FilterPeriod { thisMonth, lastMonth, custom }

class InsightsScreen extends StatefulWidget {
  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _showPieChart = true;
  Map<String, double> categoryTotals = {};
  FilterPeriod _filter = FilterPeriod.thisMonth;

  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _loadFilteredData();
  }

  Future<void> _loadFilteredData() async {
    Map<String, double> data;
    switch (_filter) {
      case FilterPeriod.thisMonth:
        data = await DBHelper.getCategoryTotalsForMonth(DateTime.now());
        break;
      case FilterPeriod.lastMonth:
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        data = await DBHelper.getCategoryTotalsForMonth(lastMonth);
        break;
      case FilterPeriod.custom:
        if (_customStart != null && _customEnd != null) {
          data = await DBHelper.getCategoryTotalsBetween(
            _customStart!,
            _customEnd!,
          );
        } else {
          data = {};
        }
        break;
    }
    setState(() {
      categoryTotals = data;
    });
  }

  void _onFilterChanged(FilterPeriod f) async {
    setState(() {
      _filter = f;
    });
    if (f == FilterPeriod.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        _customStart = picked.start;
        _customEnd = picked.end;
      }
    }
    await _loadFilteredData();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7345EE);
    final entries = categoryTotals.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton<FilterPeriod>(
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: FilterPeriod.thisMonth,
                child: Text("This Month"),
              ),
              const PopupMenuItem(
                value: FilterPeriod.lastMonth,
                child: Text("Last Month"),
              ),
              const PopupMenuItem(
                value: FilterPeriod.custom,
                child: Text("Custom Range"),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: categoryTotals.isEmpty
            ? const Center(child: Text('No expense data available.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pie"),
                      Switch(
                        value: !_showPieChart,
                        onChanged: (value) {
                          setState(() {
                            _showPieChart = !value;
                          });
                        },
                      ),
                      const Text("Bar"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _filter == FilterPeriod.custom &&
                            _customStart != null &&
                            _customEnd != null
                        ? "Showing: ${_customStart!.toLocal().toString().split(' ')[0]} - ${_customEnd!.toLocal().toString().split(' ')[0]}"
                        : _filter == FilterPeriod.thisMonth
                        ? "Showing: This Month"
                        : "Showing: Last Month",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _showPieChart
                              ? _buildPieChart(entries)
                              : _buildBarChart(entries, primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Expanded(flex: 1, child: _buildLegend()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      // ✅ Bottom Navigation Bar for switching
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: primaryColor),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.insights, color: primaryColor),
                onPressed: () {
                  // Already here, so maybe disable or just do nothing
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> entries) {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    return PieChart(
      PieChartData(
        sections: entries.map((entry) {
          final value = entry.value;
          final percent = (value / total) * 100;
          return PieChartSectionData(
            color: _getColorForCategory(entry.key),
            value: value,
            title: percent >= 5
                ? '${entry.key}\n${percent.toStringAsFixed(1)}%'
                : '',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildBarChart(
    List<MapEntry<String, double>> entries,
    Color primaryColor,
  ) {
    if (entries.isEmpty) {
      return const Center(child: Text("No data"));
    }

    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final yMax = (maxValue * 1.2).ceilToDouble(); // some headroom

    final barWidth = 28.0;
    // Determine a reasonable chart width. For e.g. each bar + spacing ~ 60 px
    final double approxPerBar = 60;
    final chartWidth = (entries.length * approxPerBar).clamp(
      0.0,
      double.infinity,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: yMax,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.grey.shade700,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final cat = entries[group.x.toInt()].key;
                  final val = rod.toY;
                  return BarTooltipItem(
                    '$cat\n₹${val.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  // Use rotated or multiline labels to avoid overlap
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final label = entries[idx].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Transform.rotate(
                        angle: -0.6, // rotate a bit (radians), ~ -34°
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  interval: yMax / 5,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: yMax / 5,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 1),
                left: BorderSide(color: Colors.black, width: 1),
                right: BorderSide(color: Colors.transparent),
                top: BorderSide(color: Colors.transparent),
              ),
            ),
            barGroups: entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: amount,
                    width: barWidth,
                    color: _getColorForCategory(category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categoryTotals.keys.map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getColorForCategory(category),
              ),
            ),
            const SizedBox(width: 4),
            Text(category, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.deepPurple,
      Colors.blueAccent,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.green,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.redAccent,
    ];
    return colors[category.hashCode % colors.length];
  }
}
