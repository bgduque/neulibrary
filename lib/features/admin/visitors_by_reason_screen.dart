import 'package:flutter/material.dart';
import '../../main.dart'; // To access apiService

/// Screen that displays a table of visitors, optionally filtered by visit reason.
class VisitorsByReasonScreen extends StatefulWidget {
  /// `null` means "Total Visitors" (show all).
  final String? reason;

  const VisitorsByReasonScreen({super.key, this.reason});

  @override
  State<VisitorsByReasonScreen> createState() => _VisitorsByReasonScreenState();
}

class _VisitorsByReasonScreenState extends State<VisitorsByReasonScreen> {
  bool _isLoading = false;
  List<dynamic> _allVisitors = [];

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);
    try {
      // Default to last 30 days of data for the table
      final to = DateTime.now();
      final from = to.subtract(const Duration(days: 30));
      final dateFrom = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final dateTo = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

      final data = await apiService.searchVisits(dateFrom, dateTo);
      setState(() => _allVisitors = data);
    } catch (e) {
      debugPrint('Error fetching visits: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filtered => widget.reason == null
      ? _allVisitors
      : _allVisitors.where((v) => v['reason'] == widget.reason).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitors = _filtered;
    final heading = widget.reason ?? 'Total Visitors';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Back + Title row ──
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back to Dashboard',
            ),
            const SizedBox(width: 8),
            Text(
              heading,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text('${visitors.length}'),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Data table ──
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : visitors.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Text(
                          'No visitors found.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      theme.colorScheme.surfaceContainerHighest,
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Reason for Visit')),
                    ],
                    rows: visitors
                        .map(
                          (v) => DataRow(
                            cells: [
                              DataCell(Text(v['userName'] ?? 'Unknown')),
                              DataCell(Text(v['userEmail'] ?? 'Unknown')),
                              DataCell(_ReasonChip(reason: v['reason'] ?? 'Unknown')),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Color-coded chip for the visit reason column.
class _ReasonChip extends StatelessWidget {
  final String reason;
  const _ReasonChip({required this.reason});

  static const _colors = {
    'Reading': Colors.blue,
    'Research': Colors.deepOrange,
    'Computer Use': Colors.teal,
    'Studying': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[reason] ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reason,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
