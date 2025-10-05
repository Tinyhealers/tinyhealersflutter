import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../constants/colors.dart';

class AdminDoctorCard extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String degree;
  final bool online;
  final int experience;

  const AdminDoctorCard({
    Key? key,
    required this.name,
    required this.phoneNumber,
    required this.degree,
    required this.online,
    required this.experience,
  }) : super(key: key);

  @override
  _AdminDoctorCardState createState() => _AdminDoctorCardState();
}

class _AdminDoctorCardState extends State<AdminDoctorCard> {
  bool isOnline = true;

  void toggleStatus(bool value) {
    setState(() {
      isOnline = value;
    });
  }

  void _makePhoneCall(String phoneNumber) async {
    Uri dialNumber = Uri(scheme: 'tel', path: phoneNumber);
    print(phoneNumber);
    await launchUrl(dialNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Make the doctor's name selectable
                  SelectableText(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Colors.white, size: 14),
                      onPressed: () => _makePhoneCall(widget.phoneNumber),
                    ),
                  ),
                ],
              ),
              // Make the degree selectable
              SelectableText(
                widget.degree,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              // Make the experience selectable
              SelectableText(
                '${widget.experience} years experience',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: widget.online ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.online ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: widget.online ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Make the phone number selectable
                  SelectableText(
                    '+91 ${widget.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}