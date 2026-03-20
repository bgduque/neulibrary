import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart'; // To access apiService
import 'stat_card_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _filter = 'Today';
  DateTimeRange? _customRange;
  bool _isLoading = false;
  Map<String, dynamic>? _statsData;

  static const _reasonIcons = {
    'Reading': Icons.menu_book_rounded,
    'Research': Icons.science_rounded,
    'Computer Use': Icons.computer_rounded,
    'Studying': Icons.edit_note_rounded,
  };
  
  static const _reasonColors = {
    'Reading': Colors.blue,
    'Research': Colors.deepOrange,
    'Computer Use': Colors.teal,
    'Studying': Colors.purple,
  };

  static const _collegeColorsList = [
    Colors.blue,
    Colors.deepOrange,
    Colors.teal,
    Colors.purple,
    Colors.amber,
    Colors.green,
    Colors.pink,
    Colors.orange,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end = now;

      switch (_filter) {
        case 'Today':
          start = now;
          break;
        case 'Weekly':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'Monthly':
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Custom':
          start = _customRange?.start ?? now;
          end = _customRange?.end ?? now;
          break;
        default:
          start = now;
      }

      final dateFrom = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final dateTo = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final data = await apiService.getStats(dateFrom, dateTo);
      setState(() => _statsData = data);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _filter = 'Custom';
      });
      _fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Header ──
        Text(
          'Dashboard',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // ── Filter chips ──
        Wrap(
          spacing: 8,
          children: [
            for (final label in ['Today', 'Weekly', 'Monthly', 'Custom'])
              FilterChip(
                label: Text(label),
                selected: _filter == label,
                onSelected: (selected) {
                  if (label == 'Custom') {
                    _pickCustomRange();
                  } else {
                    setState(() => _filter = label);
                    _fetchStats();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Stat cards grid ──
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth >= 900
                ? 5
                : constraints.maxWidth >= 600
                ? 3
                : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCardWidget(
                  title: 'Total Visitors',
                  value: _statsData?['totalVisitors']?.toString() ?? '0',
                  icon: Icons.groups_rounded,
                  color: theme.colorScheme.primary,
                  onTap: () => context.push('/admin/visitors'),
                ),
                if (_statsData != null && _statsData!['reasonBreakdown'] != null)
                  ...(Map<String, dynamic>.from(_statsData!['reasonBreakdown'])).entries.map(
                    (entry) {
                      final reason = entry.key;
                      return StatCardWidget(
                        title: reason,
                        value: entry.value.toString(),
                        icon: _reasonIcons[reason] ?? Icons.category_rounded,
                        color: _reasonColors[reason] ?? Colors.grey,
                        onTap: () => context.push('/admin/visitors?reason=$reason'),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // ── College breakdown line graph ──
        Text(
          'Visitors by College / Office',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _statsData == null || _statsData!['collegeBreakdown'] == null || (_statsData!['collegeBreakdown'] as Map).isEmpty
                      ? const Center(child: Text("No data available"))
                      : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outlineVariant.withAlpha(80),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, _) {
                              final collegeMap = Map<String, dynamic>.from(_statsData!['collegeBreakdown']);
                              final titles = collegeMap.keys.toList();
                              final idx = value.toInt();
                              if (idx < 0 || idx >= titles.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  titles[idx],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 2,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final collegeMap = Map<String, dynamic>.from(_statsData!['collegeBreakdown']);
                            final college = collegeMap.keys.elementAt(groupIndex);
                            return BarTooltipItem(
                              '$college: ${rod.toY.toInt()}',
                              TextStyle(
                                color: _collegeColorsList[groupIndex % _collegeColorsList.length],
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: (Map<String, dynamic>.from(_statsData?['collegeBreakdown'] ?? {})).entries.toList().asMap().entries.map((e) {
                        final index = e.key;
                        final count = (e.value.value as num).toDouble();
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: count,
                              width: 32,
                              color: _collegeColorsList[index % _collegeColorsList.length],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
