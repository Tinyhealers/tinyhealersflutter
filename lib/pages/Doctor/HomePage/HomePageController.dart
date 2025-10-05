import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_repository.dart';

class DoctorHomePageController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  late final SupabaseRepository repo;

  // Profile
  final name = ''.obs;
  final degree = ''.obs;
  final experience = 0.obs;
  final phoneNumber = ''.obs;
  final doctorId = ''.obs;

  // State / metrics
  final isOnline = false.obs;
  final isLoading = false.obs;
  final todayAppointments = 0.obs;
  final todayFollowUps = 0.obs;
  final todayOnlineDuration = Duration.zero.obs;
  final monthAvgOnlineDuration = Duration.zero.obs;
  final monthTotalOnlineDuration = Duration.zero.obs;
  final monthTotalOfflineDuration = Duration.zero.obs;
  final salaryHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    repo = SupabaseRepository(supabase);
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      await _loadPrefs();
      if (doctorId.value.isEmpty) return;
      await _refreshProfileAndStatus();
      await Future.wait([
        _loadTodayCounts(),
        _loadDurations(),
        _loadSalaryHistory(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    doctorId.value = prefs.getString('userId') ?? '';
    name.value = prefs.getString('userName') ?? '';
    degree.value = prefs.getString('degree') ?? '';
    experience.value = prefs.getInt('experience') ?? 0;
    phoneNumber.value = prefs.getString('userPhone') ?? '';
  }

  Future<void> _refreshProfileAndStatus() async {
    final doc = await repo.getDoctorById(doctorId.value);
    if (doc != null) {
      isOnline.value = doc['is_online'] == true;
    }
  }

  Future<void> _loadTodayCounts() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    // Base counts from appointments table
    todayAppointments.value = await repo.getAppointmentsCount(doctorId.value, from: start, to: end);
    todayFollowUps.value = await repo.getFollowUpCount(doctorId.value, from: start, to: end);

    // If admin overrides exist on doctors table, prefer them (same as Admin controller)
    try {
      final row = await supabase
          .from('doctors')
          .select('appointment_count, follow_up_count')
          .eq('id', doctorId.value)
          .maybeSingle();
      if (row != null) {
        final apptOverride = row['appointment_count'];
        final followOverride = row['follow_up_count'];
        if (apptOverride != null) {
          todayAppointments.value = (apptOverride is int)
              ? apptOverride
              : int.tryParse(apptOverride.toString()) ?? todayAppointments.value;
        }
        if (followOverride != null) {
          todayFollowUps.value = (followOverride is int)
              ? followOverride
              : int.tryParse(followOverride.toString()) ?? todayFollowUps.value;
        }
      }
    } on PostgrestException catch (_) {
      // ignore missing columns/tables just like admin controller
    }
  }

  Future<void> _loadDurations() async {
    final now = DateTime.now();
    // Include live tail similar to admin controller for running counter
    todayOnlineDuration.value = await repo.getOnlineDurationForTodayIncludingLiveTail(doctorId.value);
    // Use rolling last-30-days average like admin
    monthAvgOnlineDuration.value = await repo.getAverageDailyOnlineDurationLast30Days(doctorId.value);
    // Accurate totals for current month window
    monthTotalOnlineDuration.value = await repo.getTotalOnlineDurationForMonthAccurate(doctorId.value, now);
    monthTotalOfflineDuration.value = await repo.getTotalOfflineDurationForMonthAccurate(doctorId.value, now);
  }

  Future<void> _loadSalaryHistory() async {
    salaryHistory.assignAll(await repo.getSalaryPayments(doctorId.value));
  }

  Future<void> toggleOnline(bool value) async {
    final prev = isOnline.value;
    isOnline.value = value; // optimistic
    try {
      await repo.setDoctorOnline(doctorId.value, value);
      await _loadDurations();
    } catch (_) {
      isOnline.value = prev; // revert on error
    }
  }

  static String fmtDuration(Duration d) {
    // Match AdminDoctorDetailController formatting for consistency
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    } else if (d.inMinutes < 60) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else if (d.inHours < 24) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inDays}d ${d.inHours.remainder(24)}h';
  }
}