import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import 'HomePageController.dart';

class HomePageScreen extends StatelessWidget {
  HomePageScreen({super.key});
  final c = Get.put(DoctorHomePageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Obx(() {
            if (c.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Hello ${c.name.value},',
                        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500)),
                  ]),
                  const Text('Welcome Back',
                      style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  DoctorCard(
                    doctorId: c.doctorId.value,
                    name: c.name.value,
                    phoneNumber: c.phoneNumber.value,
                    degree: c.degree.value,
                    experience: c.experience.value,
                    isOnline: c.isOnline.value,
                    onStatusChange: c.toggleOnline,
                  ),

                  const SizedBox(height: 12),
                  _TodayMetrics(c: c),

                  const SizedBox(height: 12),
                  _SalaryHistory(c: c),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final String name;
  final String phoneNumber;
  final String degree;
  final int experience;
  final bool isOnline;
  final Function(bool) onStatusChange;

  const DoctorCard({
    Key? key,
    required this.doctorId,
    required this.name,
    required this.phoneNumber,
    required this.degree,
    required this.experience,
    required this.isOnline,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Switch(
                value: isOnline,
                onChanged: onStatusChange,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
            Text(degree, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('$experience years experience', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 5),
                Text(isOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ]),
              Text('+91 $phoneNumber',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TodayMetrics extends StatelessWidget {
  final DoctorHomePageController c;
  const _TodayMetrics({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todayAppts = c.todayAppointments.value.toString();
      final followUps = c.todayFollowUps.value.toString();
      final todayOnline = DoctorHomePageController.fmtDuration(c.todayOnlineDuration.value);
      final avg30 = DoctorHomePageController.fmtDuration(c.monthAvgOnlineDuration.value);
      final monthTotal = DoctorHomePageController.fmtDuration(c.monthTotalOnlineDuration.value);
      final monthOffline = DoctorHomePageController.fmtDuration(c.monthTotalOfflineDuration.value);

      final tiles = <Widget>[
        _statCard(
          icon: Icons.calendar_today_outlined,
          title: 'Today Appts',
          value: todayAppts,
          iconBg: AppColors.accent,
        ),
        _statCard(
          icon: Icons.follow_the_signs,
          title: 'Follow-ups',
          value: followUps,
          iconBg: AppColors.primaryColor,
        ),
        _statCard(
          icon: Icons.watch_later_outlined,
          title: 'Today Online',
          value: todayOnline,
          subtitle: 'hrs (today)',
          iconBg: AppColors.primaryColor,
        ),
        _statCard(
          icon: Icons.calendar_view_month,
          title: 'Monthly Avg (Daily Online)',
          value: avg30,
          iconBg: AppColors.accent,
        ),
        _statCard(
          icon: Icons.timer_outlined,
          title: 'Total This Month',
          value: monthTotal,
          iconBg: AppColors.primaryColor,
        ),
        _statCard(
          icon: Icons.power_settings_new,
          title: 'Offline (This Month)',
          value: monthOffline,
          iconBg: Colors.redAccent,
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          // Two cards per row: account for one spacing gap between columns
          const spacing = 12.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles
                .map((w) => SizedBox(width: cardWidth, child: w))
                .toList(),
          );
        },
      );
    });
  }

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
}

class _SalaryHistory extends StatelessWidget {
  final DoctorHomePageController c;
  const _SalaryHistory({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = c.salaryHistory;
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
            ],
          ),
        ),
      );
    });
  }
}
