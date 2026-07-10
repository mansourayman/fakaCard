import 'package:shared_preferences/shared_preferences.dart';

import '../models/operation_log.dart';

class LogStore {
  static const _storageKey = 'operation_logs';

  Future<List<OperationLog>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_storageKey) ?? const [];
    final logs = <OperationLog>[];

    for (final raw in rawLogs) {
      try {
        logs.add(OperationLog.fromJson(raw));
      } catch (_) {
        // Ignore unreadable old entries instead of breaking the history screen.
      }
    }

    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  Future<void> add(OperationLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? const [];
    await prefs.setStringList(_storageKey, [log.toJson(), ...current]);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
