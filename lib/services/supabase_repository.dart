import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final SupabaseClient _supabase;
  SupabaseRepository(this._supabase);

  // Parse an ISO timestamp string as UTC. If the string has no timezone info,
  // we assume it is already in UTC (common when the DB column is 'timestamp' without tz).
  DateTime _parseAsUtc(String iso) {
    // If it already has a timezone designator, parse and convert to UTC.
    // Detect a 'Z' suffix or a +HH:MM / -HH:MM offset at the end of the string.
    final tzRegex = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');
    final hasZone = tzRegex.hasMatch(iso);
    if (hasZone) {
      return DateTime.parse(iso).toUtc();
    }
    // Otherwise, treat as UTC by appending 'Z'
    return DateTime.parse(iso + 'Z').toUtc();
  }

  // Same as accurate but excludes the ongoing tail if the last known state is online.
  Future<Duration> getTotalOnlineDurationAccurateCompletedOnly(String doctorId, DateTime from, DateTime to, {bool carryOverPriorState = false}) async {
    try {
      final fromUtc = from.toUtc();
      final toUtc = to.toUtc();

      final prior = await _supabase
          .from('doctor_status_logs')
          .select('is_online, timestamp')
          .eq('doctor_id', doctorId)
          .lt('timestamp', fromUtc.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final dynamic inside = await _supabase
          .from('doctor_status_logs')
          .select('is_online, timestamp')
          .eq('doctor_id', doctorId)
          .gte('timestamp', fromUtc.toIso8601String())
          .lte('timestamp', toUtc.toIso8601String())
          .order('timestamp');

      final List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from((inside as List?) ?? []);
      logs.sort((a, b) => _parseAsUtc(a['timestamp']).compareTo(_parseAsUtc(b['timestamp'])));

      final bool initialOnline = prior?['is_online'] == true;
      final List<Map<String, dynamic>> timeline = [
        {'is_online': initialOnline, 'timestamp': fromUtc.toIso8601String()},
        ...logs.map((e) => {'is_online': e['is_online'], 'timestamp': e['timestamp']}),
      ];

      Duration online = Duration.zero;
      for (int i = 1; i < timeline.length; i++) {
        final prev = timeline[i - 1];
        final curr = timeline[i];
        final prevT = _parseAsUtc(prev['timestamp']);
        final currT = _parseAsUtc(curr['timestamp']);
        if (prev['is_online'] == true && currT.isAfter(prevT)) {
          final segEnd = currT.isBefore(toUtc) ? currT : toUtc;
          final segStart = prevT.isAfter(fromUtc) ? prevT : fromUtc;
          if (segEnd.isAfter(segStart)) {
            online += segEnd.difference(segStart);
          }
        }
        if (!_parseAsUtc(curr['timestamp']).isBefore(toUtc)) {
          break;
        }
      }

      // DIFFERENCE: No tail addition here. Only completed segments are counted.

      final totalWindow = toUtc.difference(fromUtc);
      if (online > totalWindow) online = totalWindow;
      return online;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return Duration.zero;
      rethrow;
    }
  }

  Future<Duration> getOnlineDurationForTodayCompletedOnly(String doctorId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return getTotalOnlineDurationAccurateCompletedOnly(doctorId, start, now);
  }

  // Doctors
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    final res = await _supabase.from('doctors').select('*').eq('id', doctorId).maybeSingle();
    return res;
    }

  Future<int> getAppointmentsCount(String doctorId, {DateTime? from, DateTime? to}) async {
    try {
      var builder = _supabase
          .from('appointments')
          .select('id')
          .eq('doctor_id', doctorId);

      if (from != null) {
        builder = builder.filter('appointment_time', 'gte', from.toIso8601String());
      }
      if (to != null) {
        builder = builder.filter('appointment_time', 'lte', to.toIso8601String());
      }
      final dynamic data = await builder;
      final List list = (data as List);
      return list.length;
    } on PostgrestException catch (e) {
      print('[Supabase][getAppointmentsCount] PostgrestException: ${e.message}');
      if (e.code == 'PGRST205') {
        print('[Supabase][getAppointmentsCount] Table "appointments" not found - returning 0');
        return 0; // Return 0 if table doesn't exist
      }
      rethrow;
    }
  }

  Future<int> getFollowUpCount(String doctorId, {DateTime? from, DateTime? to}) async {
    if (doctorId.isEmpty) throw ArgumentError('doctorId cannot be empty');

    try {
      var builder = _supabase
          .from('appointments')
          .select('id')
          .eq('doctor_id', doctorId)
          .eq('is_follow_up', true);

      if (from != null) builder = builder.filter('appointment_time', 'gte', from.toIso8601String());
      if (to != null) builder = builder.filter('appointment_time', 'lte', to.toIso8601String());

      final dynamic data = await builder;
      final List list = (data as List);
      return list.length;
    } on PostgrestException catch (e) {
      print('[Supabase][getFollowUpCount] PostgrestException: code=${e.code}, message=${e.message}');
      if (e.code == 'PGRST205') {
        print('[Supabase][getFollowUpCount] Table "appointments" not found - returning 0');
        return 0;
      }
      rethrow;
    } catch (e) {
      print('[Supabase][getFollowUpCount] ERROR: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorStatusLogs(String doctorId, {DateTime? from, DateTime? to}) async {
    try {
      var builder = _supabase
          .from('doctor_status_logs')
          .select('is_online, timestamp')
          .eq('doctor_id', doctorId);
      if (from != null) builder = builder.filter('timestamp', 'gte', from.toIso8601String());
      if (to != null) builder = builder.filter('timestamp', 'lte', to.toIso8601String());
      final dynamic resp = await builder.order('timestamp');
      final list = (resp as List).cast<Map<String, dynamic>>();
      return list;
    } on PostgrestException catch (e) {
      print('[Supabase][getDoctorStatusLogs] PostgrestException: ${e.message}');
      if (e.code == 'PGRST205') {
        print('[Supabase][getDoctorStatusLogs] Table "doctor_status_logs" not found - returning empty list');
        return []; // Return empty list if table doesn't exist
      }
      rethrow;
    }
  }

  Future<void> insertDoctorStatusLog(String doctorId, bool isOnline) async {
    print('[Supabase] Inserting status log for doctor $doctorId: $isOnline');
    try {
      await _supabase.from('doctor_status_logs').insert({
        'doctor_id': doctorId,
        'is_online': isOnline,
        // store as UTC to avoid timezone window mismatches
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      print('[Supabase][insertDoctorStatusLog] PostgrestException: ${e.message}');
      if (e.code == 'PGRST205') {
        print('[Supabase][insertDoctorStatusLog] Table "doctor_status_logs" not found - skipping insert');
        return; // Skip if table doesn't exist
      }
      rethrow;
    }
  }

  Future<void> setDoctorOnline(String doctorId, bool isOnline) async {
    print('[Supabase] Updating doctor $doctorId online status to $isOnline');
    await _supabase.from('doctors').update({'is_online': isOnline, 'last_updated': DateTime.now().toIso8601String()}).eq('id', doctorId);
    await insertDoctorStatusLog(doctorId, isOnline);
  }

  Future<void> updateAppointmentCount(String doctorId, int count) async {
    print('[Supabase][updateAppointmentCount] doctor=$doctorId, count=$count');
    try {
      await _supabase.from('doctors').update({
        'appointment_count': count,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', doctorId);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        final msg = 'Column appointment_count not found in PostgREST schema cache. Run: select pg_notify(\'pgrst\', \'reload schema\'); in Supabase SQL editor after adding the column.';
        print('[Supabase][updateAppointmentCount] $msg');
        throw Exception(msg);
      }
      print('[Supabase][updateAppointmentCount] ERROR: code=${e.code}, message=${e.message}');
      rethrow;
    }
  }

  Future<void> updateFollowUpCount(String doctorId, int count) async {
    print('[Supabase][updateFollowUpCount] doctor=$doctorId, count=$count');
    try {
      await _supabase.from('doctors').update({
        'follow_up_count': count,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', doctorId);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        final msg = 'Column follow_up_count not found in PostgREST schema cache. Run: select pg_notify(\'pgrst\', \'reload schema\'); in Supabase SQL editor after adding the column.';
        print('[Supabase][updateFollowUpCount] $msg');
        throw Exception(msg);
      }
      print('[Supabase][updateFollowUpCount] ERROR: code=${e.code}, message=${e.message}');
      rethrow;
    }
  }

  // Salary payments
  Future<List<Map<String, dynamic>>> getSalaryPayments(String doctorId) async {
    // Try common table name variants to be resilient to schema naming differences
    final candidates = ['salary_payments', 'salary_payment', 'salaries', 'slaary_payments', 'slaary_payment'];
    PostgrestException? lastErr;
    for (final table in candidates) {
      try {
        print('[Supabase][getSalaryPayments] Querying table "$table" for doctor=$doctorId');
        final resp = await _supabase
            .from(table)
            .select('*')
            .eq('doctor_id', doctorId)
            .order('payment_date', ascending: false) as List;
        print('[Supabase][getSalaryPayments] Found table "$table" with ${resp.length} records');
        return List<Map<String, dynamic>>.from(resp);
      } on PostgrestException catch (e) {
        lastErr = e;
        // If table not found (pgrst205), try next
        if (e.code == 'PGRST205' || e.message.toLowerCase().contains('schema cache') || e.message.toLowerCase().contains('not found')) {
          print('[Supabase][getSalaryPayments] Table "$table" not found, trying next');
          continue;
        }
        rethrow;
      }
    }
    // None worked - return empty list instead of throwing
    final msg = 'No salary tables found: ${candidates.join(', ')}. Returning empty list.';
    print('[Supabase][getSalaryPayments] $msg');
    return []; // Return empty list instead of throwing error
  }

  Future<void> addSalaryPayment({
    required String doctorId,
    required int totalConsultations,
    required double amount,
    String? createdBy,
  }) async {
    print('[Supabase][addSalaryPayment] doctor=$doctorId, amount=$amount, consultations=$totalConsultations, createdBy=$createdBy');
    if (doctorId.isEmpty) throw ArgumentError('doctorId cannot be empty');
    if (totalConsultations < 0) throw ArgumentError('totalConsultations must be positive');
    if (amount <= 0) throw ArgumentError('amount must be positive');

    // Skip created_by if it's not a valid UUID
    final sanitizedCreatedBy = createdBy != null && _isValidUuid(createdBy) ? createdBy : null;

    // Try common table name variants
    final candidates = ['salary_payments', 'salary_payment', 'salaries', 'slaary_payments', 'slaary_payment'];
    PostgrestException? lastErr;
    for (final table in candidates) {
      try {
        print('[Supabase][addSalaryPayment] Inserting into table "$table"');
        await _supabase.from(table).insert({
          'doctor_id': doctorId,
          'total_consultations': totalConsultations,
          'amount': amount,
          'payment_date': DateTime.now().toIso8601String(),
          if (sanitizedCreatedBy != null) 'created_by': sanitizedCreatedBy,
        });
        print('[Supabase][addSalaryPayment] Inserted successfully into "$table"');
        return;
      } on PostgrestException catch (e) {
        lastErr = e;
        if (e.code == 'PGRST205' || e.message.toLowerCase().contains('schema cache') || e.message.toLowerCase().contains('not found')) {
          print('[Supabase][addSalaryPayment] Table "$table" not found, trying next');
          continue; // try next table name
        }
        print('[Supabase][addSalaryPayment] PostgrestException: code=${e.code}, message=${e.message}');
        rethrow; // real DB error
      }
    }
    // Create a helpful error message suggesting table creation
    final msg = 'No salary table found. Please create one of these tables in Supabase: ${candidates.take(3).join(', ')}';
    print('[Supabase][addSalaryPayment] $msg');
    throw Exception(msg);
  }

  bool _isValidUuid(String uuid) {
    final regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return regex.hasMatch(uuid);
  }

  // Helpers to compute durations
  // Returns total online duration in seconds for logs in window, and total offline in seconds.
  Map<String, Duration> computeOnlineOfflineDurations(List<Map<String, dynamic>> logs, {DateTime? windowStart, DateTime? windowEnd}) {
    if (logs.isEmpty) return {'online': Duration.zero, 'offline': Duration.zero};

    // Ensure sorted
    logs.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    DateTime start = windowStart ?? DateTime.parse(logs.first['timestamp']);
    DateTime end = windowEnd ?? DateTime.now();

    Duration online = Duration.zero;
    Duration offline = Duration.zero;

    // Assume state before first log is the first log's state until first timestamp or windowStart
    bool currentOnline = logs.first['is_online'] == true;
    DateTime cursor = start.isBefore(DateTime.parse(logs.first['timestamp'])) ? start : DateTime.parse(logs.first['timestamp']);

    for (int i = 0; i < logs.length; i++) {
      final logTime = DateTime.parse(logs[i]['timestamp']);
      if (logTime.isBefore(start)) {
        currentOnline = logs[i]['is_online'] == true;
        continue;
      }
      final nextTime = (i + 1 < logs.length) ? DateTime.parse(logs[i + 1]['timestamp']) : end;
      final fromT = logTime.isAfter(cursor) ? logTime : cursor;
      final toT = nextTime.isBefore(end) ? nextTime : end;
      if (toT.isAfter(fromT)) {
        final delta = toT.difference(fromT);
        if (currentOnline) online += delta; else offline += delta;
      }
      currentOnline = logs[i]['is_online'] == true;
      cursor = toT;
      if (!cursor.isBefore(end)) break;
    }

    // Tail till end
    if (cursor.isBefore(end)) {
      final delta = end.difference(cursor);
      if (currentOnline) online += delta; else offline += delta;
    }

    return {'online': online, 'offline': offline};
  }

  Future<Duration> getOnlineDurationForMonth(String doctorId, DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final windowEnd = now.isBefore(nextMonth) && now.isAfter(firstDay) ? now : nextMonth;
    return getTotalOnlineDurationAccurate(doctorId, firstDay, windowEnd);
  }

  // Accurate total online duration that considers state before the window start
  Future<Duration> getTotalOnlineDurationAccurate(String doctorId, DateTime from, DateTime to) async {
    final res = await getOnlineOfflineDurationsAccurate(doctorId, from, to);
    return res['online'] ?? Duration.zero;
  }

  Future<Duration> getOnlineDurationForToday(String doctorId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return getTotalOnlineDurationAccurate(doctorId, start, now);
  }

  // Accurate calculator that returns both online and offline durations for a window.
  Future<Map<String, Duration>> getOnlineOfflineDurationsAccurate(String doctorId, DateTime from, DateTime to) async {
    try {
      final fromUtc = from.toUtc();
      final toUtc = to.toUtc();

      final prior = await _supabase
          .from('doctor_status_logs')
          .select('is_online, timestamp')
          .eq('doctor_id', doctorId)
          .lt('timestamp', fromUtc.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final dynamic inside = await _supabase
          .from('doctor_status_logs')
          .select('is_online, timestamp')
          .eq('doctor_id', doctorId)
          .gte('timestamp', fromUtc.toIso8601String())
          .lte('timestamp', toUtc.toIso8601String())
          .order('timestamp');

      final List<Map<String, dynamic>> rawLogs = List<Map<String, dynamic>>.from((inside as List?) ?? []);
      final List<Map<String, dynamic>> logs = rawLogs
          .map((e) => {
                'is_online': e['is_online'] == true,
                'timestamp': e['timestamp'],
                '_t': _parseAsUtc(e['timestamp']),
              })
          .toList()
        ..sort((a, b) => (a['_t'] as DateTime).compareTo(b['_t'] as DateTime));

      final bool initialOnline = prior?['is_online'] == true;
      final List<Map<String, dynamic>> timeline = [
        {'is_online': initialOnline, 'timestamp': fromUtc.toIso8601String()},
        ...logs.map((e) => {'is_online': e['is_online'], 'timestamp': e['timestamp']}),
      ];

      Duration online = Duration.zero;
      Duration offline = Duration.zero;
      for (int i = 1; i < timeline.length; i++) {
        final prev = timeline[i - 1];
        final curr = timeline[i];
        final prevT = _parseAsUtc(prev['timestamp']);
        final currT = _parseAsUtc(curr['timestamp']);
        if (currT.isAfter(prevT)) {
          final segEnd = currT.isBefore(toUtc) ? currT : toUtc;
          final segStart = prevT.isAfter(fromUtc) ? prevT : fromUtc;
          if (segEnd.isAfter(segStart)) {
            final delta = segEnd.difference(segStart);
            if (prev['is_online'] == true) online += delta; else offline += delta;
          }
        }
        if (!_parseAsUtc(curr['timestamp']).isBefore(toUtc)) {
          break;
        }
      }

      final last = timeline.isNotEmpty ? timeline.last : null;
      if (last != null) {
        final lastT = _parseAsUtc(last['timestamp']);
        if (toUtc.isAfter(lastT)) {
          final segStart = lastT.isAfter(fromUtc) ? lastT : fromUtc;
          final delta = toUtc.difference(segStart);
          if (last['is_online'] == true) online += delta; else offline += delta;
        }
      }

      final totalWindow = toUtc.difference(fromUtc);
      if (online < Duration.zero) online = Duration.zero;
      if (offline < Duration.zero) offline = Duration.zero;
      if (online > totalWindow) online = totalWindow;
      if (offline > totalWindow) offline = totalWindow;

      return {'online': online, 'offline': offline};
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return {'online': Duration.zero, 'offline': Duration.zero};
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLastStatusLogInWindow(String doctorId, DateTime from, DateTime to) async {
    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();
    final resp = await _supabase
        .from('doctor_status_logs')
        .select('is_online, timestamp')
        .eq('doctor_id', doctorId)
        .gte('timestamp', fromUtc.toIso8601String())
        .lte('timestamp', toUtc.toIso8601String())
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    return resp;
  }

  Future<Duration> getOnlineDurationForTodayIncludingLiveTail(String doctorId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final completed = await getTotalOnlineDurationAccurateCompletedOnly(doctorId, start, now);
    final last = await getLastStatusLogInWindow(doctorId, start, now);
    if (last != null && (last['is_online'] == true)) {
      final lastT = _parseAsUtc(last['timestamp']);
      final tail = now.toUtc().difference(lastT);
      if (tail.isNegative) return completed; // defensive
      return completed + tail;
    }
    return completed;
  }

  // Wrapper used by controller: total online for month, capped to now if current month
  Future<Duration> getTotalOnlineDurationForMonthAccurate(String doctorId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final to = (now.isAfter(from) && now.isBefore(endOfMonth)) ? now : endOfMonth;
    return getTotalOnlineDurationAccurate(doctorId, from, to);
  }

  // Total offline for the month = window length - accurate online
  Future<Duration> getTotalOfflineDurationForMonthAccurate(String doctorId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final to = (now.isAfter(from) && now.isBefore(endOfMonth)) ? now : endOfMonth;
    final both = await getOnlineOfflineDurationsAccurate(doctorId, from, to);
    return both['offline'] ?? Duration.zero;
  }

  Future<Duration> getAverageDailyOnlineDurationForMonth(String doctorId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final to = (now.isAfter(from) && now.isBefore(endOfMonth)) ? now : endOfMonth;
    final totalOnline = await getTotalOnlineDurationAccurate(doctorId, from, to);
    // Average over elapsed days (India time friendly since using device local days)
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    final elapsedDays = toDay.difference(fromDay).inDays + 1; // at least 1 day
    final avgSeconds = (totalOnline.inSeconds / elapsedDays).round();
    return Duration(seconds: avgSeconds);
  }

  Future<Duration> getTotalOnlineDurationForMonth(String doctorId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final to = (now.isAfter(from) && now.isBefore(endOfMonth)) ? now : endOfMonth;
    return getTotalOnlineDurationAccurate(doctorId, from, to);
  }

  Future<Duration> getTotalOfflineDurationForMonth(String doctorId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    final to = (now.isAfter(from) && now.isBefore(endOfMonth)) ? now : endOfMonth;
    final both = await getOnlineOfflineDurationsAccurate(doctorId, from, to);
    return both['offline'] ?? Duration.zero;
  }

  // Average daily online duration over the last 30 days (rolling window)
  Future<Duration> getAverageDailyOnlineDurationLast30Days(String doctorId) async {
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 30));
    final totalOnline = await getTotalOnlineDurationAccurate(doctorId, from, to);
    final avgSeconds = (totalOnline.inSeconds / 30).round();
    return Duration(seconds: avgSeconds);
  }
}
