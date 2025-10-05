import 'package:docon/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Login/LoginPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String doctorId = '';
  String name = '';
  String degree = '';
  int experience = 0;
  String hospitalName = '';
  String phoneNumber = '';

  TextEditingController nameController = TextEditingController();
  TextEditingController degreeController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController hospitalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      doctorId = prefs.getString('userId') ?? '';
      name = prefs.getString('userName') ?? 'N/A';
      degree = prefs.getString('degree') ?? 'N/A';
      experience = prefs.getInt('experience') ?? 0;
      hospitalName = prefs.getString('hospitalName') ?? 'N/A';
      phoneNumber = prefs.getString('userPhone') ?? 'N/A';

      nameController.text = name;
      degreeController.text = degree;
      experienceController.text = experience.toString();
      hospitalController.text = hospitalName;
    });
  }

  Future<void> _updateProfile() async {
    if (doctorId.isEmpty) {
      Get.snackbar('Error', 'Doctor ID not found!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String newName = nameController.text.trim();
    String newDegree = degreeController.text.trim();
    int newExperience = int.tryParse(experienceController.text.trim()) ?? 0;
    String newHospital = hospitalController.text.trim();

    bool hasChanges = newName != name ||
        newDegree != degree ||
        newExperience != experience ||
        newHospital != hospitalName;

    if (!hasChanges) {
      Get.snackbar('No Changes', 'No updates to save!',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      final response = await supabase
          .from('doctors')
          .update({
        if (newName != name) 'name': newName,
        if (newDegree != degree) 'degree': newDegree,
        if (newExperience != experience) 'experience': newExperience,
        if (newHospital != hospitalName) 'hospital_name': newHospital,
      })
          .match({'id': doctorId})
          .select()
          .maybeSingle();

      if (response == null) {
        Get.snackbar('Error', 'Failed to update profile!',
            backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        setState(() {
          name = newName;
          degree = newDegree;
          experience = newExperience;
          hospitalName = newHospital;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userName', newName);
        prefs.setString('degree', newDegree);
        prefs.setInt('experience', newExperience);
        prefs.setString('hospitalName', newHospital);

        Get.snackbar('Success', 'Profile updated successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar('Error', 'Update failed',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;
    final double maxWidth = isWeb ? 800.0 : double.infinity;

    return Scaffold(
      backgroundColor: isWeb ? Colors.grey[200] : AppColors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Doctor Profile',
          style: TextStyle(color: AppColors.primaryColor, fontSize: 20),
        ),
        backgroundColor: isWeb ? Colors.grey[200] : AppColors.backgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: isWeb,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: isWeb ? 16 : 0, // Top 16 for web, 0 for mobile
          bottom: 16,
          right: isWeb ? 24 : 16,
          left: isWeb ? 24 : 16,
        ),
        child: Align(
          alignment: isWeb ? Alignment.center : Alignment.topCenter, // Top on mobile, center on web
          child: Container(
            width: maxWidth,
            margin: isWeb ? const EdgeInsets.symmetric(vertical: 20, horizontal: 16) : EdgeInsets.zero,
            decoration: isWeb
                ? BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
                : null,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        isWeb
                            ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailField('Name', nameController, true),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailField('Degree', degreeController, true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailField('Experience (Years)', experienceController, true, isNumber: true),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailField('Current Hospital Working at (Optional)', hospitalController, true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailField('Phone Number', TextEditingController(text: phoneNumber), false),
                          ],
                        )
                            : Column(
                          children: [
                            _buildDetailField('Name', nameController, true),
                            _buildDetailField('Degree', degreeController, true),
                            _buildDetailField('Experience (Years)', experienceController, true, isNumber: true),
                            _buildDetailField('Current Hospital Working at (Optional)', hospitalController, true),
                            _buildDetailField('Phone Number', TextEditingController(text: phoneNumber), false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                isWeb
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 45,
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
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                          ),
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
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Update'),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            side: const BorderSide(
                              color: Colors.red,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, TextEditingController controller, bool isEditable, {bool isNumber = false}) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;

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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isWeb ? 10 : 12),
            fillColor: isEditable ? Colors.white : Colors.grey.shade200,
            filled: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        if (!isWeb) const SizedBox(height: 16),
      ],
    );
  }
}