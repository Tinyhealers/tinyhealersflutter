import 'package:docon/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Login/LoginPage.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String adminId = '';
  String name = '';
  String email = '';
  String phoneNumber = '';
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminId = prefs.getString('userId') ?? '';
      name = prefs.getString('userName') ?? 'N/A';
      email = prefs.getString('userEmail') ?? 'N/A';
      phoneNumber = prefs.getString('userPhone') ?? 'N/A';
      nameController.text = name;
    });
  }

  Future<void> _updateAdminName() async {
    if (adminId.isEmpty) {
      Get.snackbar('Error', 'Admin ID not found!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String newName = nameController.text.trim();
    if (newName.isEmpty || newName == name) {
      Get.snackbar('No Changes', 'Name is the same or empty!',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      if (phoneNumber.isEmpty) {
        Get.snackbar('Error', 'Phone number is missing!',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final response = await supabase
          .from('admins')
          .update({'name': newName})
          .match({'phone_number': phoneNumber})
          .select()
          .maybeSingle();

      if (response == null) {
        Get.snackbar('Error', 'Failed to update name!',
            backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        setState(() {
          name = newName;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userName', newName);

        Get.snackbar('Success', 'Name updated successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      print('Error updating name: $e');
      Get.snackbar('Error', 'Update failed: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: AppColors.primaryColor, fontSize: 20),
        ),
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 16,
          vertical: isWeb ? 24 : 16,
        ),
        child: Align(
          alignment: isWeb ? Alignment.center : Alignment.topCenter, // Top on mobile, center on web
          child: Container(
            width: isWeb ? 600 : double.infinity, // Fixed width for web
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
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailField('Name', nameController, true),
                  _buildDetailField('Email', TextEditingController(text: email), false),
                  _buildDetailField('Phone Number', TextEditingController(text: phoneNumber), false),
                  const SizedBox(height: 16),
                  _buildButtons(context, isWeb),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, TextEditingController controller, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF414141),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: isEditable,
          controller: controller,
          decoration: InputDecoration(
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
            fillColor: isEditable ? Colors.white : Colors.grey.shade100,
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, bool isWeb) {
    return isWeb
        ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            onPressed: _updateAdminName,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update Name'),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Get.offAll(() => LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.red, width: 1.0),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    )
        : Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _updateAdminName,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update Name'),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Get.offAll(() => LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.red, width: 1.0),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }
}