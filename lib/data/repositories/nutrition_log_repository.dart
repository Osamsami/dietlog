import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/logger.dart';
import '../local/hive_boxes.dart';
import '../models/nutrition_log.dart';

final _log = AppLogger('NutritionLogRepository');

/// Repository for nutrition log CRUD operations.
///
/// Implements an offline-first strategy:
/// 1. Write operations go to Supabase first, then cache in Hive.
/// 2. Read operations try Supabase first; fall back to Hive cache if offline.
class NutritionLogRepository {
  final SupabaseClient _client;

  NutritionLogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Reference to the Hive cache box for nutrition logs.
  Box<NutritionLog> get _cacheBox =>
      Hive.box<NutritionLog>(HiveBoxes.nutritionLogs);

  // ── Create ──────────────────────────────────────────────────────────────

  /// Insert a new nutrition log into Supabase and cache locally.
  Future<NutritionLog> addLog(NutritionLog log) async {
    _log.info('Adding log: ${log.foodName} (${log.calories} kcal)');

    final data = await _client
        .from('nutrition_logs')
        .insert(log.toJson()..remove('log_id')) // let DB generate UUID
        .select()
        .single();

    final inserted = NutritionLog.fromJson(data);

    // Cache in Hive
    await _cacheBox.put(inserted.logId, inserted);
    _log.debug('Log cached locally: ${inserted.logId}');

    return inserted;
  }

  // ── Read ────────────────────────────────────────────────────────────────

  /// Fetch logs within a date range from Supabase.
  ///
  /// Falls back to Hive cache if the network request fails.
  Future<List<NutritionLog>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('nutrition_logs')
          .select()
          .order('logged_at', ascending: false);

      if (startDate != null) {
        query = query.gte(
          'logged_at',
          DateFormatter.toSupabaseTimestamp(startDate),
        );
      }

      if (endDate != null) {
        query = query.lte(
          'logged_at',
          DateFormatter.toSupabaseTimestamp(endDate),
        );
      }

      final data = await query;

      final logs = data.map((json) => NutritionLog.fromJson(json)).toList();

      // Update local cache
      await _syncCache(logs);

      _log.info('Fetched ${logs.length} logs from Supabase');
      return logs;
    } catch (e) {
      _log.warning('Failed to fetch from Supabase, using cache: $e');
      return _getCachedLogs(startDate: startDate, endDate: endDate);
    }
  }

  /// Fetch today's nutrition logs.
  Future<List<NutritionLog>> getTodayLogs() {
    return getLogs(
      startDate: DateFormatter.startOfToday(),
      endDate: DateFormatter.endOfToday(),
    );
  }

  /// Fetch the last 7 days of nutrition logs.
  Future<List<NutritionLog>> getWeeklyLogs() {
    return getLogs(startDate: DateFormatter.startOfWeek());
  }

  /// Fetch the last 30 days of nutrition logs.
  Future<List<NutritionLog>> getMonthlyLogs() {
    return getLogs(startDate: DateFormatter.startOfMonth());
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  /// Delete a nutrition log by its ID from Supabase and local cache.
  Future<void> deleteLog(String logId) async {
    _log.info('Deleting log: $logId');

    await _client.from('nutrition_logs').delete().eq('log_id', logId);

    // Remove from local cache
    await _cacheBox.delete(logId);
    _log.debug('Log removed from cache: $logId');
  }

  // ── Aggregations ────────────────────────────────────────────────────────

  /// Compute daily nutrition summary for a given date.
  ///
  /// Returns a map with keys: totalCalories, totalProtein, totalCarbs, totalFats.
  Future<Map<String, num>> getDailySummary({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23, 59, 59, 999,
    );

    final logs = await getLogs(startDate: start, endDate: end);

    return {
      'totalCalories': logs.fold<int>(0, (sum, log) => sum + log.calories),
      'totalProtein': logs.fold<double>(0, (sum, log) => sum + log.proteinG),
      'totalCarbs': logs.fold<double>(0, (sum, log) => sum + log.carbsG),
      'totalFats': logs.fold<double>(0, (sum, log) => sum + log.fatsG),
      'logCount': logs.length,
    };
  }

  // ── Cache Helpers ───────────────────────────────────────────────────────

  /// Sync Supabase results into the local Hive cache.
  Future<void> _syncCache(List<NutritionLog> logs) async {
    for (final log in logs) {
      await _cacheBox.put(log.logId, log);
    }
    _log.debug('Synced ${logs.length} logs to local cache');
  }

  /// Retrieve logs from the Hive cache, optionally filtered by date range.
  List<NutritionLog> _getCachedLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = _cacheBox.values.toList();

    if (startDate != null) {
      logs = logs.where((l) => !l.loggedAt.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      logs = logs.where((l) => !l.loggedAt.isAfter(endDate)).toList();
    }

    // Sort descending by logged_at
    logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    _log.debug('Returned ${logs.length} cached logs');
    return logs;
  }
}
