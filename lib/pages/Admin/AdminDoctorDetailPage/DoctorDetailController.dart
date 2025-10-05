import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/colors.dart';
import '../../../services/supabase_repository.dart';

class DoctorDetailController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final RxBool isLoading = false.obs;
  final RxBool isOnline = false.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();

  // Analytics
  final todayAppointments = 0.obs;
  final todayFollowUps = 0.obs;
  final todayOnlineDuration = Duration.zero.obs;
  final monthAvgOnlineDuration = Duration.zero.obs;
  final monthTotalOnlineDuration = Duration.zero.obs;
  final monthTotalOfflineDuration = Duration.zero.obs;
  final salaryHistory = <Map<String, dynamic>>[].obs;

  late String doctorId;
  late final SupabaseRepository repo = SupabaseRepository(supabase);

  void setDoctorDetails(Map<String, dynamic> doctor) {
    print('[Admin][DoctorDetailController] setDoctorDetails -> id=${doctor['id']} name=${doctor['name']}');
    doctorId = doctor['id'];
    nameController.text = doctor['name'];
    degreeController.text = doctor['degree'];
    experienceController.text = doctor['experience'].toString();
    phoneController.text = doctor['phone_number'];
    hospitalController.text = doctor['hospital_name'] ?? '';
    isOnline.value = doctor['is_online'];
  }

  Future<void> setOnline(bool value) async {
    final prev = isOnline.value;
    isOnline.value = value; // optimistic update for snappy UI
    print('[Admin][DoctorDetailController] setOnline -> id=$doctorId, value=$value');
    try {
      await repo.setDoctorOnline(doctorId, value);
      Get.snackbar('Status Updated', value ? 'Doctor set Online' : 'Doctor set Offline',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
      // Refresh analytics to reflect the latest short intervals immediately
      await loadAnalytics();
    } catch (e) {
      // Revert on failure
      isOnline.value = prev;
      print('[Admin][DoctorDetailController] setOnline ERROR: $e');
      Get.snackbar('Error', 'Failed to update online status',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateDoctor() async {
    isLoading.value = true;
    try {
      print('[Admin][DoctorDetailController] updateDoctor -> id=$doctorId');
      await supabase.from('doctors').update({
        'name': nameController.text.trim(),
        'degree': degreeController.text.trim(),
        'experience': int.parse(experienceController.text.trim()), 
        'phone_number': phoneController.text.trim(),
        'hospital_name': hospitalController.text.trim().isEmpty ? null : hospitalController.text.trim(),
        'is_online': isOnline.value,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', doctorId);

      Get.snackbar('Success', 'Doctor details updated!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('[Admin][DoctorDetailController] updateDoctor ERROR: $e');
      Get.snackbar('Error', 'Failed to update doctor.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDoctor() async {
    isLoading.value = true;
    try {
      print('[Admin][DoctorDetailController] deleteDoctor -> id=$doctorId');
      await supabase.from('doctors').delete().eq('id', doctorId);
      Get.snackbar('Success', 'Doctor deleted successfully!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('[Admin][DoctorDetailController] deleteDoctor ERROR: $e');
      Get.snackbar('Error', 'Failed to delete doctor.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAnalytics() async {
    print('[Admin][DoctorDetailController] loadAnalytics -> id=$doctorId');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Defaults from appointments table
    todayAppointments.value = await repo.getAppointmentsCount(doctorId, from: start, to: end);
    todayFollowUps.value = await repo.getFollowUpCount(doctorId, from: start, to: end);

    // If admin overrides exist on doctors table, prefer them
    try {
      final row = await supabase
          .from('doctors')
          .select('appointment_count, follow_up_count')
          .eq('id', doctorId)
          .maybeSingle();
      if (row != null) {
        final apptOverride = row['appointment_count'];
        final followOverride = row['follow_up_count'];
        if (apptOverride != null) {
          todayAppointments.value = (apptOverride is int) ? apptOverride : int.tryParse(apptOverride.toString()) ?? todayAppointments.value;
        }
        if (followOverride != null) {
          todayFollowUps.value = (followOverride is int) ? followOverride : int.tryParse(followOverride.toString()) ?? todayFollowUps.value;
        }
      }
    } on PostgrestException catch (e) {
      // If columns not found or table missing, ignore and use computed defaults
      print('[Admin][DoctorDetailController] overrides fetch skipped: code=${e.code}, message=${e.message}');
    }

    // Include live tail while currently online for an accurate running counter
    todayOnlineDuration.value = await repo.getOnlineDurationForTodayIncludingLiveTail(doctorId);
    // Use a rolling last-30-days average to avoid partial-month skew
    monthAvgOnlineDuration.value = await repo.getAverageDailyOnlineDurationLast30Days(doctorId);
    monthTotalOnlineDuration.value = await repo.getTotalOnlineDurationForMonthAccurate(doctorId, now);
    monthTotalOfflineDuration.value = await repo.getTotalOfflineDurationForMonthAccurate(doctorId, now);
    salaryHistory.assignAll(await repo.getSalaryPayments(doctorId));
    print('[Admin][DoctorDetailController] loadAnalytics DONE -> appts=${todayAppointments.value}, followups=${todayFollowUps.value}, todayOnline=${todayOnlineDuration.value}, monthAvg=${monthAvgOnlineDuration.value}, monthTotal=${monthTotalOnlineDuration.value}, salaryItems=${salaryHistory.length}');
  }

  String fmtDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    } else if (d.inMinutes < 60) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else if (d.inHours < 24) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inDays}d ${d.inHours.remainder(24)}h';
  }

  String fmtShortDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  Future<void> creditSalary({required int totalConsultations, required double amount}) async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString('adminName') ?? 'System';

      if (totalConsultations <= 0) {
        throw Exception('Total consultations must be positive');
      }
      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      print('[Admin][DoctorDetailController] creditSalary -> id=$doctorId, consultations=$totalConsultations, amount=$amount, by=$createdBy');
      await repo.addSalaryPayment(
        doctorId: doctorId,
        totalConsultations: totalConsultations,
        amount: amount,
        createdBy: createdBy,
      );
      
      // Refresh salary history
      salaryHistory.assignAll(await repo.getSalaryPayments(doctorId));
      print('[Admin][DoctorDetailController] creditSalary DONE -> salaryItems=${salaryHistory.length}');
      
      Get.snackbar('Success', 'Salary credited successfully!', 
        backgroundColor: Colors.green, 
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      print('[Admin][DoctorDetailController] creditSalary ERROR: $e');
      Get.snackbar('Error', 'Failed to credit salary: ${e.toString()}', 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAppointmentCount(int count) async {
    isLoading.value = true;
    try {
      print('[Admin][DoctorDetailController] updateAppointmentCount -> id=$doctorId, count=$count');
      await repo.updateAppointmentCount(doctorId, count);
      todayAppointments.value = count;
      Get.snackbar('Success', 'Appointment count updated!', 
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('[Admin][DoctorDetailController] updateAppointmentCount ERROR: $e');
      Get.snackbar('Error', 'Failed to update appointment count: ${e.toString()}', 
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFollowUpCount(int count) async {
    isLoading.value = true;
    try {
      print('[Admin][DoctorDetailController] updateFollowUpCount -> id=$doctorId, count=$count');
      await repo.updateFollowUpCount(doctorId, count);
      todayFollowUps.value = count;
      Get.snackbar('Success', 'Follow-up count updated!', 
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('[Admin][DoctorDetailController] updateFollowUpCount ERROR: $e');
      Get.snackbar('Error', 'Failed to update follow-up count: ${e.toString()}', 
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
