import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import 'OtpVerifyController.dart';
import 'dart:async';

class OtpVerifyScreen extends StatelessWidget {
  final String phoneNumber;
  final String role;

  OtpVerifyScreen({required this.phoneNumber, required this.role, required String otp});

  final OtpVerifyController controller = Get.put(OtpVerifyController());

  @override
  Widget build(BuildContext context) {
    controller.setPhoneNumber(phoneNumber);
    controller.setRole(role);

    // Determine if the platform is web
    final bool isWeb = MediaQuery.of(context).size.width > 800;
    final double maxWidth = isWeb ? 600.0 : double.infinity;

    // Timer variables
    const int timerDuration = 300; // 5 minutes in seconds
    RxInt remainingTime = timerDuration.obs;

    // Start timer
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value--;
      } else {
        timer.cancel();
        Get.back(); // Go back when timer reaches 0
      }
    });

    return Scaffold(
      backgroundColor: isWeb ? Colors.grey[200] : AppColors.backgroundColor,
      body: Center(
        child: Container(
          width: maxWidth,
          margin: isWeb ? const EdgeInsets.symmetric(vertical: 20) : EdgeInsets.zero,
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OTP',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Row(
                        children: const [
                          Text(
                            'VERIFICATION',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor1,
                            ),
                          ),
                          Text(
                            '.',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter the OTP sent to ${controller.phoneNumber}",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textColor2,
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: isWeb ? 50 : 60,
                        height: isWeb ? 50 : 60,
                        child: TextField(
                          controller: controller.otpControllers[index],
                          focusNode: controller.focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.none,
                          showCursor: false,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive OTP? ",
                        style: TextStyle(fontSize: 14, color: AppColors.textColor2),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: const Center(
                      child: Text(
                        "Change number",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Timer display
                  Obx(
                        () => Center(
                          child: Text(
                                                'Time remaining: ${remainingTime.value ~/ 60}:${(remainingTime.value % 60).toString().padLeft(2, '0')}',
                                                style: TextStyle(
                          fontSize: 14,
                          color: remainingTime.value <= 60
                              ? Colors.red
                              : AppColors.textColor2,
                          fontWeight: FontWeight.w500,
                                                ),
                                              ),
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => controller.verifyOtp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NumberPad(
                    onNumberSelected: controller.onNumberSelected,
                    isWeb: isWeb,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  final Function(int) onNumberSelected;
  final bool isWeb;

  NumberPad({required this.onNumberSelected, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isWeb ? 60.0 : 90.0;

    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int j = 1; j <= 3; j++)
                Expanded(
                  child: NumberButton(
                    number: i * 3 + j,
                    onNumberSelected: onNumberSelected,
                    buttonSize: buttonSize,
                  ),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Spacer(),
            Expanded(
              child: NumberButton(
                number: 0,
                onNumberSelected: onNumberSelected,
                buttonSize: buttonSize,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onNumberSelected(-1),
                child: Container(
                  height: buttonSize,
                  width: buttonSize,
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace, color: Colors.black, size: 28),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NumberButton extends StatelessWidget {
  final int number;
  final Function(int) onNumberSelected;
  final double buttonSize;

  NumberButton({
    required this.number,
    required this.onNumberSelected,
    required this.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onNumberSelected(number),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: buttonSize,
        width: buttonSize,
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: TextStyle(fontSize: buttonSize * 0.3, color: Colors.black),
        ),
      ),
    );
  }
}