import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import 'PhoneNumberController.dart';

class PhoneNumberScreen extends StatelessWidget {
  final String role;
  const PhoneNumberScreen({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PhoneNumberController controller = Get.put(PhoneNumberController());
    controller.setRole(role);

    // Determine if the platform is web
    final bool isWeb = MediaQuery.of(context).size.width > 800; // Consider screens wider than 800px as web
    final double maxWidth = isWeb ? 600.0 : double.infinity; // Constrain width for web

    return Scaffold(
      backgroundColor: isWeb ? Colors.grey[200] : AppColors.backgroundColor, // Different background for web
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isWeb ? 40 : 80), // Reduce top padding for web
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
                          children: [
                            const Text(
                              'VERIFICATION',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor1,
                              ),
                            ),
                            const Text(
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
                    const Text(
                      "Enter your mobile number to continue",
                      style: TextStyle(fontSize: 16, color: AppColors.textColor2),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: controller.phoneController,
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.none,
                      decoration: InputDecoration(
                        hintText: "Mobile Number",
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            "🇮🇳 +91 ",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: isWeb ? 45 : 50, // Slightly smaller button on web
                      child: ElevatedButton(
                        onPressed: controller.sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "CONTINUE",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    NumberPad(
                      onNumberSelected: (value) {
                        controller.updatePhoneNumber(value.toString());
                      },
                      isWeb: isWeb, // Pass isWeb to NumberPad for responsive styling
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
  final bool isWeb; // Add isWeb parameter to adjust styling

  NumberPad({required this.onNumberSelected, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    // Adjust button size based on screen size
    final double buttonSize = isWeb ? 60.0 : 90.0; // Smaller buttons for web

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
  final double buttonSize; // Add buttonSize parameter for responsive sizing

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
          style: TextStyle(fontSize: buttonSize * 0.3, color: Colors.black), // Scale font size with button size
        ),
      ),
    );
  }
}