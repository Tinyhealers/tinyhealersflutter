import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPService {
  static const String _otpKey = 'stored_otp';

  Future<String> generateOTP() async {
    final random = Random().nextInt(9000) + 1000;
    return random.toString();
  }

  Future<String> sendOTP(String phoneNumber, String otp) async {
    try {
      await dotenv.load();
      final apiKey = dotenv.env['SMS_API_KEY'];

      print('Preparing to send OTP to $phoneNumber');
      print(otp);

      final response = await http.post(
        Uri.parse('https://www.fast2sms.com/dev/bulkV2'),
        headers: {
          'authorization': apiKey!,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'variables_values': otp,
          'route': 'dlt',
          'sender_id': 'TINY',
          'message': '197889',
          'numbers': phoneNumber,
        },
      );

      print('Fast2SMS Response: ${response.body}');

      // Store OTP in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_otpKey, otp);
      print('OTP stored successfully');

      return response.body;
    } catch (error) {
      print('Error sending OTP: $error');
      throw Exception('Failed to send OTP');
    }
  }

  static Future<String?> getStoredOTP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_otpKey);
  }

  static Future<void> clearOTP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpKey);
  }
}
