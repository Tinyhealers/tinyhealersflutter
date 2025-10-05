import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import '../HomePage/HomePageScreen.dart';
import '../Profile/ProfilePage.dart';
import 'BottomNavigationController.dart';

class BottomNavigationScreen extends StatefulWidget {
  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  final BottomNavigationController controller = Get.put(BottomNavigationController());

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _screens = [
    HomePageScreen(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    // Set the top (status bar) and bottom system navigation bar colors
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF5F9FF), // Top system navigation bar (status bar) color
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
          selectedFontSize: 10.0, // Decrease font size for selected label
          unselectedFontSize: 9.0, // Decrease font size for unselected label
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
    );
  }
}