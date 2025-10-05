import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/colors.dart';
import 'DoctorDetailController.dart';

class DoctorDetailPage extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final DoctorDetailController controller = Get.put(DoctorDetailController());

  DoctorDetailPage({super.key, required this.doctor}) {
    controller.setDoctorDetails(doctor);
    controller.loadAnalytics();
  }

  // ---------------------------
  // Adjust counts bottom sheet (kept logic, small style improvements)
  // ---------------------------
  void _showAdjustCountsDialog(BuildContext context) {
    final apptCtrl = TextEditingController(text: controller.todayAppointments.value.toString());
    final followCtrl = TextEditingController(text: controller.todayFollowUps.value.toString());

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Adjust Counts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: apptCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Today Appointments',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _miniStepper(apptCtrl),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: followCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Today Follow-ups',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _miniStepper(followCtrl),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final appts = int.tryParse(apptCtrl.text.trim()) ?? -1;
                        final folls = int.tryParse(followCtrl.text.trim()) ?? -1;
                        if (appts < 0 || folls < 0) {
                          Get.snackbar('Error', 'Enter valid non-negative numbers', backgroundColor: Colors.red, colorText: Colors.white);
                          return;
                        }
                        Get.back();
                        await controller.updateAppointmentCount(appts);
                        await controller.updateFollowUpCount(folls);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _miniStepper(TextEditingController controller) {
    void setVal(int delta) {
      final v = int.tryParse(controller.text.trim()) ?? 0;
      final n = (v + delta).clamp(0, 1000000);
      controller.text = n.toString();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => setVal(-1),
          icon: const Icon(Icons.remove_circle_outline),
          splashRadius: 20,
        ),
        IconButton(
          onPressed: () => setVal(1),
          icon: const Icon(Icons.add_circle_outline),
          splashRadius: 20,
        ),
      ],
    );
  }

  // ---------------------------
  // Improved stat card widget
  // ---------------------------
  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    Color? iconBg,
  }) {
    final bg = iconBg ?? AppColors.primaryColor;
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220, minHeight: 84),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: bg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textColor2)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textColor1)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textColor2)),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------
  // Salary history card (improved)
  // ---------------------------
  Widget _salaryHistoryCard() {
    return Obx(() {
      final items = controller.salaryHistory;
      // compute total paid amount safely
      double totalPaid = 0;
      for (final e in items) {
        final amt = e['amount'];
        if (amt is int) totalPaid += amt.toDouble();
        if (amt is double) totalPaid += amt;
        if (amt is String) totalPaid += double.tryParse(amt) ?? 0;
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Salary History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Paid', style: TextStyle(fontSize: 12, color: AppColors.textColor2)),
                      const SizedBox(height: 4),
                      Text('₹${totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,color: AppColors.primaryColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.wallet_outlined, size: 36, color: AppColors.primaryColor.withOpacity(0.7)),
                      const SizedBox(height: 8),
                      const Text('No salary records', style: TextStyle(color: AppColors.textColor2)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, idx) {
                    final e = items[idx];
                    final amtVal = e['amount'];
                    final consultations = e['total_consultations'] ?? 0;
                    final rawDate = (e['payment_date'] ?? '').toString();
                    final dateText = rawDate.contains('T') ? rawDate.split('T').first : rawDate;

                    // leading avatar: amount (rounded)
                    String leadingText;
                    if (amtVal is num) {
                      leadingText = '₹${amtVal.toStringAsFixed(0)}';
                    } else {
                      leadingText = '₹${amtVal ?? ''}';
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Consultations + Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consultations: $consultations',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColor2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textColor2,
                                ),
                              ),
                            ],
                          ),

                          // Right side: Amount
                          Center(
                            child: Text(
                              '₹${amtVal ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                  },
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, // makes the button full width
                child: ElevatedButton.icon(
                  onPressed: () => _showCreditSalaryDialog(Get.context!),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Credit Salary',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor, // keep same primary color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // optional rounded corners
                    ),
                  ),
                ),
              )

            ],
          ),
        ),
      );
    });
  }

  // ---------------------------
  // Build common input field (same as before)
  // ---------------------------
  Widget _buildInputField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isEditable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          readOnly: !isEditable,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: !isEditable,
            fillColor: isEditable ? Colors.white : Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------
  // Top metrics area (responsive)
  // ---------------------------
  Widget _buildMetricsArea(BoxConstraints constraints) {
    // Use Wrap to be responsive across widths
    return Obx(() {
      final todayAppts = controller.todayAppointments.value.toString();
      final followUps = controller.todayFollowUps.value.toString();
      final todayOnline = controller.fmtDuration(controller.todayOnlineDuration.value);
      final avg30 = controller.fmtDuration(controller.monthAvgOnlineDuration.value);
      final monthTotal = controller.fmtDuration(controller.monthTotalOnlineDuration.value);
      final monthOffline = controller.fmtDuration(controller.monthTotalOfflineDuration.value);

      final tiles = [
        _statCard(icon: Icons.calendar_today_outlined, title: 'Today Appts', value: todayAppts, iconBg: AppColors.accent),
        _statCard(icon: Icons.follow_the_signs, title: 'Follow-ups', value: followUps, iconBg: AppColors.primaryColor),
        _statCard(icon: Icons.watch_later_outlined, title: 'Today Online', value: todayOnline, subtitle: 'hrs (today)', iconBg: AppColors.primaryColor),
        _statCard(icon: Icons.calendar_view_month, title: 'Monthly Avg (Daily Online)', value: controller.fmtDuration(controller.monthAvgOnlineDuration.value), iconBg: AppColors.accent),
        _statCard(icon: Icons.timer_outlined, title: 'Total This Month', value: controller.fmtDuration(controller.monthTotalOnlineDuration.value), iconBg: AppColors.primaryColor),
        _statCard(icon: Icons.power_settings_new, title: 'Offline (This Month)', value: monthOffline, iconBg: Colors.redAccent),
      ];

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles.map((w) => SizedBox(width: constraints.maxWidth > 800 ? 180 : constraints.maxWidth / 2 - 24, child: w)).toList(),
      );
    });
  }

  // ---------------------------
  // Buttons row (kept as before)
  // ---------------------------
  void _showUpdateConfirmationDialog() {
    Get.defaultDialog(
      title: "Confirm Update",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      middleText: "Are you sure you want to update this doctor's details?",
      middleTextStyle: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      radius: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // cancel
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            controller.updateDoctor();
            Get.back(); // close dialog
          },
          child: const Text("Update", style: TextStyle(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildButtonRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showDeleteConfirmationDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showUpdateConfirmationDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _buildButtonRow(),
    );
  }

  Widget _buildMobileBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _buildButtonRow(),
    );
  }

  void _showDeleteConfirmationDialog() {
    Get.defaultDialog(
      title: "Confirm Deletion",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      middleText: "Are you sure you want to delete this doctor?",
      middleTextStyle: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      radius: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // cancel
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: (){
            controller.deleteDoctor();
            Get.back(); // close dialog
          }, // cancel
          child: const Text("Delete",style: TextStyle(color: Colors.red),),
        ),
      ],
    );
  }


  Widget _metric(String title, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ],
  );

  void _showCreditSalaryDialog(BuildContext context) {
    final consCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Get.width * 0.85),
          child: Padding(
            // Controlled padding (no weird extra top padding)
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: title + close button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Credit Salary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // small circular hit area for close
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.back(),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),

                // Inputs
                TextFormField(
                  controller: consCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Consultations',
                    hintText: 'e.g. 25',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amtCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    hintText: 'e.g. 1000.00',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),

                const SizedBox(height: 20),

                // Actions aligned to bottom-right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final cons = int.tryParse(consCtrl.text.trim()) ?? 0;
                        final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;

                        if (cons <= 0 || amt <= 0) {
                          Get.snackbar(
                            'Error',
                            'Enter valid values',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        // Close dialog then perform action
                        Get.back();
                        await controller.creditSalary(
                          totalConsultations: cons,
                          amount: amt,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side:
                        BorderSide(color: AppColors.primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(100, 44),
                      ),
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Doctor Details',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black, size: 30),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmationDialog(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 800;

            final content = SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isLargeScreen ? 920 : double.infinity),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top card with inputs and online toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0,4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField('Name', controller.nameController),
                            _buildInputField('Degree', controller.degreeController),
                            _buildInputField('Experience', controller.experienceController, isNumeric: true),
                            _buildInputField('Hospital (Optional)', controller.hospitalController),
                            _buildInputField('Phone Number', controller.phoneController, isNumeric: true, isEditable: false),
                            const SizedBox(height: 4),
                            Obx(() => SwitchListTile(
                              title: const Text('Doctor is Online'),
                              value: controller.isOnline.value,
                              onChanged: (val) => controller.setOnline(val),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),


                      Text('Doctor Stats',style: TextStyle(fontSize: 16),),
                      const SizedBox(height: 12),
                      // Stats area
                      _buildMetricsArea(constraints),
                      const SizedBox(height: 16),





                      // Removed an empty Obx that caused GetX improper use warning
                      const SizedBox.shrink(),

                      const SizedBox(height: 8),


                      // Adjust counts button
                      SizedBox(
                        width: double.infinity, // full width
                        child: TextButton.icon(
                          onPressed: () => _showAdjustCountsDialog(context),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Manage Appointments'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black, // text & icon color
                            backgroundColor: Colors.transparent, // transparent background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // rounded corners
                              side: const BorderSide( // border style
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 16),


                      // Salary history card (improved)
                      _salaryHistoryCard(),

                      const SizedBox(height: 20),

                      // bottom button row (only on large screens)
                      if (isLargeScreen) _buildBottomBar(),
                    ],
                  ),
                ),
              ),
            );

            return isLargeScreen ? content : content;
          },
        );
      }),
      
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800 ? _buildMobileBottomBar() : null,
    );
  }
}
