import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:the_factory/services/auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final AuthService _authService = AuthService();
  String _enteredOTP = '';
  bool _isLoading = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the email from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'] as String?;
  }

  void _verifyOTP() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found. Please go back and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_enteredOTP.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 4-digit OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.verifyOTP(
        context: context,
        email: _email!,
        otp: _enteredOTP,
      );

      if (success && mounted) {
        // Navigate to reset password screen
        Navigator.pushReplacementNamed(
          context,
          '/reset_password',
          arguments: {'email': _email, 'otp': _enteredOTP},
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resendOTP() async {
    if (_email == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendForgotPasswordOTP(
        context: context,
        email: _email!,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.6)),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset('assets/images/factory_logo.png', height: 80),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      "OTP Verification",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle with email
                    Text(
                      "Enter the 4-digit code sent to\n${_email ?? 'your email'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OTP Input Field
                    OTPTextField(
                      length: 4,
                      width: size.width * 0.7,
                      fieldWidth: 60,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textFieldAlignment: MainAxisAlignment.spaceAround,
                      fieldStyle: FieldStyle.box,
                      otpFieldStyle: OtpFieldStyle(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        borderColor: const Color(0xFFA6E22E),
                        enabledBorderColor: const Color(0xFFA6E22E),
                        focusBorderColor: Colors.white,
                        disabledBorderColor: Colors.grey.shade600,
                      ),
                      onChanged: (code) {
                        setState(() {
                          _enteredOTP = code;
                        });
                      },
                      onCompleted: (code) {
                        setState(() {
                          _enteredOTP = code;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || _enteredOTP.length != 4)
                                ? null
                                : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA6E22E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Resend OTP Button
                    TextButton(
                      onPressed: _isLoading ? null : _resendOTP,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: Color(0xFFA6E22E),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Back Button
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
