import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomeController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  RxList<Map<String, dynamic>> doctors = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RealtimeChannel? doctorsChannel; // Realtime subscription channel

  @override
  void onInit() {
    fetchDoctors(); // Fetch initial data
    setupRealTimeSubscription(); // Setup real-time listener
    super.onInit();
  }

  /// Fetch doctors initially
  Future<void> fetchDoctors() async {
    isLoading.value = true;
    try {
      final response = await supabase.from('doctors').select();
      doctors.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch doctors',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup real-time subscription for doctors table
  void setupRealTimeSubscription() {
    doctorsChannel = supabase.channel('public:doctors').onPostgresChanges(
      event: PostgresChangeEvent.all, // Listen to INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'doctors',
      callback: (payload) {
        handleRealTimeChanges(payload);
      },
    ).subscribe();
  }

  /// Handle real-time doctor updates
  void handleRealTimeChanges(PostgresChangePayload payload) {
    final newRecord = payload.newRecord as Map<String, dynamic>?;
    final oldRecord = payload.oldRecord as Map<String, dynamic>?;

    if (payload.eventType == PostgresChangeEvent.insert && newRecord != null) {
      // If a new doctor is added, insert into the list
      doctors.add(newRecord);
    } else if (payload.eventType == PostgresChangeEvent.update && newRecord != null) {
      // If a doctor is updated, replace the existing entry
      int index = doctors.indexWhere((doc) => doc['id'] == newRecord['id']);
      if (index != -1) {
        doctors[index] = newRecord;
      }
    } else if (payload.eventType == PostgresChangeEvent.delete && oldRecord != null) {
      // If a doctor is deleted, remove from the list
      doctors.removeWhere((doc) => doc['id'] == oldRecord['id']);
    }

    doctors.refresh(); // Refresh the observable list
  }

  /// Unsubscribe from real-time updates when the controller is disposed
  @override
  void onClose() {
    doctorsChannel?.unsubscribe();
    super.onClose();
  }
}
