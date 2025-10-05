import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import 'AddDoctorController.dart';

class AddDoctorPage extends StatelessWidget {
  AddDoctorPage({super.key});

  final AddDoctorController controller = Get.put(AddDoctorController());

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is wide (e.g., web)
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black, size: 30),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Add Doctor',
          style: TextStyle(color: AppColors.primaryColor, fontSize: 24),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 16, // Minimal horizontal padding for mobile
          vertical: isWeb ? 24 : 16,  // Slightly less vertical padding on mobile
        ),
        child: Align(
          alignment: isWeb ? Alignment.center : Alignment.topCenter, // Top on mobile, center on web
          child: Container(
            width: isWeb ? 600 : double.infinity, // Fixed width for web, full width for mobile
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: isWeb
                  ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null, // Shadow only for web
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Minimize height to fit content
                children: [
                  _buildInputField(
                    'Name',
                    controller.nameController,
                    hintText: 'Enter doctor\'s name',
                  ),
                  _buildInputField(
                    'Degree',
                    controller.degreeController,
                    hintText: 'Enter doctor\'s degree (e.g., MBBS)',
                  ),
                  _buildInputField(
                    'Experience',
                    controller.experienceController,
                    hintText: 'Enter years of experience',
                    isNumeric: true,
                  ),
                  _buildInputField(
                    'Phone Number',
                    controller.phoneController,
                    hintText: 'Enter phone number',
                    isNumeric: true,
                  ),
                  _buildInputField(
                    'Hospital (Optional)',
                    controller.hospitalController,
                    hintText: 'Enter hospital name (optional)',
                  ),
                  const SizedBox(height: 18),
                  Obx(
                        () => controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : _buildButtonRow(context, isWeb),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller, {
        String? hintText,
        bool isNumeric = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF414141), fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB3B3B3), width: 1.0),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB3B3B3), width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildButtonRow(BuildContext context, bool isWeb) {
    return isWeb
        ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () => controller.addDoctor(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.addDoctor(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}