import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDoctorController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();

  RxBool isLoading = false.obs;

  Future<void> addDoctor() async {
    final String name = nameController.text.trim();
    final String degree = degreeController.text.trim();
    final String experienceText = experienceController.text.trim();
    final String phone = phoneController.text.trim();
    final String hospital = hospitalController.text.trim();

    // Input Validation
    if (name.isEmpty || degree.isEmpty || experienceText.isEmpty || phone.isEmpty) {
      Get.snackbar('Error', 'Please fill all required fields.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    int? experience = int.tryParse(experienceText);
    if (experience == null) {
      Get.snackbar('Error', 'Experience must be a valid number.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    try {
      final response = await supabase.from('doctors').insert({
        'name': name,
        'degree': degree,
        'experience': experience,
        'phone_number': phone,
        'hospital_name': hospital.isEmpty ? null : hospital,
        'is_online': false,
      }).select();  // This ensures you get a proper response

      print(response.toString());

        // Successfully added
        Get.snackbar('Success', 'Doctor added successfully!',
            backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.TOP);
        clearFields();
        // Get.back(); // Navigate back after successful addition
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong! Please try again.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    nameController.clear();
    degreeController.clear();
    experienceController.clear();
    phoneController.clear();
    hospitalController.clear();
  }
}
