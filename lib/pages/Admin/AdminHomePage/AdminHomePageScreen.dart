import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import '../AdminDoctorDetailPage/DoctorDetailPage.dart';
import 'AdminHomeComponents/AdminDoctorCard.dart';
import 'AdminHomeController.dart';

class AdminHomePageScreen extends StatelessWidget {
  AdminHomePageScreen({super.key});

  final AdminHomeController controller = Get.put(AdminHomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'Manage your Dashboard',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Fetch and Show Doctors List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.doctors.isEmpty) {
                    return const Center(
                      child: Text(
                        'No doctors found.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = controller.doctors[index];
                      return GestureDetector(
                        onTap: () {
                          Get.to(() => DoctorDetailPage(doctor: doctor)); // Navigate to DoctorDetailPage
                        },
                        child: AdminDoctorCard(
                          name: doctor['name'],
                          phoneNumber: doctor['phone_number'],
                          degree: doctor['degree'],
                          experience: doctor['experience'],
                          online: doctor['is_online'],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
