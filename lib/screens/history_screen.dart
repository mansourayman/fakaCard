import 'package:flutter/material.dart';

import '../models/operation_log.dart';
import '../services/log_store.dart';

enum _HistoryFilter { all, success, failed }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = LogStore();
  _HistoryFilter _filter = _HistoryFilter.all;
  late Future<List<OperationLog>> _logsFuture = _store.load();

  Future<void> _reload() async {
    setState(() => _logsFuture = _store.load());
  }

  Future<void> _clear() async {
    await _store.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل العمليات'),
          actions: [
            IconButton(
              tooltip: 'مسح السجل',
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: FutureBuilder<List<OperationLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            final logs = snapshot.data ?? const <OperationLog>[];
            final filtered = switch (_filter) {
              _HistoryFilter.all => logs,
              _HistoryFilter.success => logs
                  .where((log) => log.status == OperationStatus.success)
                  .toList(),
              _HistoryFilter.failed => logs
                  .where((log) => log.status == OperationStatus.failed)
                  .toList(),
            };

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  SegmentedButton<_HistoryFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _HistoryFilter.all,
                        label: Text('الكل'),
                      ),
                      ButtonSegment(
                        value: _HistoryFilter.success,
                        label: Text('ناجحة'),
                      ),
                      ButtonSegment(
                        value: _HistoryFilter.failed,
                        label: Text('فاشلة'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (values) {
                      setState(() => _filter = values.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    const _EmptyHistory()
                  else
                    ...filtered.map(_HistoryTile.new),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(this.log);

  final OperationLog log;

  @override
  Widget build(BuildContext context) {
    final color =
        log.isSuccess ? const Color(0xFF057A55) : const Color(0xFFB42318);
    final icon =
        log.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.productId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.message,
                    style: const TextStyle(color: Color(0xFF4B5565)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipText(text: log.receiver),
                      _ChipText(text: _formatDate(log.createdAt)),
                      if (log.statusCode != null)
                        _ChipText(text: 'HTTP ${log.statusCode}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5565)),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد عمليات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
