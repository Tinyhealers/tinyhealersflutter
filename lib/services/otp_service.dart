import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OTPService {
  static const String _otpKey = 'stored_otp';

  Future<String> generateOTP() async {
    final random = Random().nextInt(9000) + 1000;
    return random.toString();
  }

  Future<String> sendOTP(String phoneNumber, String otp) async {
    try {
      print('Preparing to send OTP to $phoneNumber');
      print(otp);

      final uri = Uri.parse('https://tinyhealersnode.vercel.app/send-otp');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );

      print('Local send-otp response: ${response.body}');

      if (response.statusCode != 200) {
        print('Non-200 response from send-otp: ${response.statusCode}');
        throw Exception('Failed to send OTP');
      }

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      final bool success = data['return'] == true || data['return']?.toString() == 'true';

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_otpKey, otp);
        print('OTP stored successfully');
      } else {
        print('send-otp returned failure: ${response.body}');
        final message = data['message'] ?? 'Unknown error';
        throw Exception('Failed to send OTP: $message');
      }

      return response.body;
    } catch (error) {
      print('Error sending OTP: $error');
      rethrow;
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
