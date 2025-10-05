import 'package:docon/pages/Admin/AdminProfile/AdminProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import '../AddDoctor/AddDoctorPage.dart';
import '../AdminHomePage/AdminHomePageScreen.dart';
import 'AdminBottomNavigationController.dart';

class AdminBottomNavigationScreen extends StatefulWidget {
  @override
  State<AdminBottomNavigationScreen> createState() => _AdminBottomNavigationScreenState();
}

class _AdminBottomNavigationScreenState extends State<AdminBottomNavigationScreen> {
  final AdminBottomNavigationController controller = Get.put(AdminBottomNavigationController());

  final List<Widget> _screens = [
    AdminHomePageScreen(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Set the top (status bar) and bottom system navigation bar colors
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF5F9FF), // Status bar color
      statusBarIconBrightness: Brightness.dark, // Status bar icon color
      systemNavigationBarColor: AppColors.backgroundColor, // Bottom navigation bar color
      systemNavigationBarIconBrightness: Brightness.dark, // Bottom bar icon color
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Obx(() => _screens[controller.selectedIndex.value]),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundColor,
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onItemTapped,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 10.0,
          unselectedFontSize: 9.0,
          items: [
            BottomNavigationBarItem(
              backgroundColor: Color(0xFFF5F9FF),
              icon: Icon(
                Icons.home,
                size: 18,
                color: controller.selectedIndex.value == 0
                    ? AppColors.primaryColor
                    : Colors.grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              backgroundColor: Color(0xFFF5F9FF),
              icon: Icon(
                Icons.person,
                size: 18,
                color: controller.selectedIndex.value == 1
                    ? AppColors.primaryColor
                    : Colors.grey,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: Obx(() {
        return controller.selectedIndex.value == 0
            ? FloatingActionButton(
          onPressed: () {
            Get.to(AddDoctorPage());
          },
          backgroundColor: AppColors.primaryColor, // Customize color
          shape: CircleBorder(), // Ensures the button is perfectly circular
          child: Icon(Icons.add, color: Colors.white), // Customize icon
        )
            : SizedBox(); // Hide when not on HomePage
      }),

    );
  }
}
