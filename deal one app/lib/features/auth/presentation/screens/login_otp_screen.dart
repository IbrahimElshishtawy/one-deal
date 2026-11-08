import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatPhone(String input) {
    String trimmed = input.trim().replaceAll(' ', '');
    if (trimmed.startsWith('01')) {
      return '+2$trimmed';
    } else if (trimmed.startsWith('201')) {
      return '+$trimmed';
    }
    return trimmed;
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text;
    final formatted = _formatPhone(rawPhone);

    // Validate Egyptian format: +2010, +2011, +2012, +2015 followed by 7 digits
    final egRegex = RegExp(r'^\+201[0125][0-9]{8}$');
    if (!egRegex.hasMatch(formatted)) {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم هاتف مصري صحيح (مثال: 01012345678)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendOtp(formatted);
      setState(() {
        _isCodeSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر إرسال رمز التحقق: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'يرجى إدخال رمز التحقق المكون من 6 أرقام';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formatted = _formatPhone(_phoneController.text);
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtp(formatted, code);

      ref.invalidate(sessionProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'رمز التحقق غير صحيح أو منتهي الصلاحية';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مرحباً بك في صفقة ون',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isCodeSent
                  ? 'أدخل الرمز المكون من 6 أرقام المرسل إلى ${_formatPhone(_phoneController.text)}'
                  : 'أدخل رقم هاتفك لتسجيل الدخول أو إنشاء حساب جديد',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ],

            if (!_isCodeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف المحمول',
                  hintText: '01012345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('إرسال رمز التحقق', style: TextStyle(fontSize: 16)),
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('تأكيد وتسجيل الدخول', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isCodeSent = false;
                          _otpController.clear();
                        });
                      },
                child: const Text('تعديل رقم الهاتف'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
