import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String password;

  const OtpPage({super.key, required this.email, required this.password});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  // 6 controller untuk 6 kotak OTP
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  // Countdown resend OTP (60 detik)
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto fokus ke kotak pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  // Verifikasi OTP
  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showError('Masukkan 6 digit kode OTP');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otpCode,
        type: OtpType.signup, // type signup untuk verifikasi register
      );

      if (!mounted) return;

      if (response.user != null) {
        _showSuccess('Email berhasil diverifikasi! 🎉');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } on AuthException catch (e) {
      _showError(_translateError(e.message));
      // Clear kotak OTP kalau salah
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } catch (e) {
      _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // Kirim ulang OTP
  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      if (!mounted) return;
      _showSuccess('Kode OTP baru telah dikirim ke ${widget.email}');
      _startCountdown();

      // Clear kotak OTP
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } on AuthException catch (e) {
      _showError(_translateError(e.message));
    } catch (e) {
      _showError('Gagal mengirim ulang OTP. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _translateError(String message) {
    if (message.contains('Token has expired') || message.contains('expired')) {
      return 'Kode OTP sudah kadaluarsa. Minta kode baru.';
    } else if (message.contains('Invalid') || message.contains('invalid')) {
      return 'Kode OTP tidak valid. Periksa kembali.';
    } else if (message.contains('network') ||
        message.contains('Unable to connect')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Gagal: $message';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1A6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Handle input di setiap kotak OTP
  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      // Maju ke kotak berikutnya
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Kotak terakhir — langsung verifikasi otomatis
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      // Hapus — mundur ke kotak sebelumnya
      _focusNodes[index - 1].requestFocus();
    }
  }

  // Handle paste OTP (copy-paste 6 digit sekaligus)
  void _onPaste(String pastedText) {
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[5].requestFocus();
      setState(() {});
      Future.delayed(const Duration(milliseconds: 300), _verifyOtp);
    }
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFF0D4A4A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              child: IconTheme(
                data: const IconThemeData(color: Color(0xFF0D4A4A), size: 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Satu kotak OTP
  Widget _buildOtpBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          // Handle paste via keyboard shortcut
          if (event is RawKeyDownEvent &&
              event.isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyV) {
            Clipboard.getData('text/plain').then((data) {
              if (data?.text != null) _onPaste(data!.text!);
            });
          }
        },
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: !_isVerifying,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D4A4A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isFilled
                ? const Color(0xFF1A6B6B).withOpacity(0.08)
                : Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isFilled ? const Color(0xFF1A6B6B) : Colors.grey[300]!,
                width: isFilled ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A6B6B), width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
            _onOtpChanged(index, value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allFilled = _otpCode.length == 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            // === HEADER ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildGlassButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // === KONTEN ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Ikon email
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        color: Color(0xFF1A6B6B),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Verifikasi Email',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D4A4A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Kami mengirimkan kode OTP 6 digit ke',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Color(0xFF1A6B6B),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 6 kotak OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _buildOtpBox),
                    ),
                    const SizedBox(height: 12),

                    // Hint paste
                    Center(
                      child: Text(
                        'Bisa langsung paste kode dari email',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tombol verifikasi
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isVerifying || !allFilled)
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B6B),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kirim ulang OTP
                    Center(
                      child: _isResending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A6B6B),
                              ),
                            )
                          : GestureDetector(
                              onTap: _resendCountdown == 0 ? _resendOtp : null,
                              child: RichText(
                                text: TextSpan(
                                  text: 'Tidak menerima kode? ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _resendCountdown > 0
                                          ? 'Kirim ulang (${_resendCountdown}s)'
                                          : 'Kirim Ulang',
                                      style: TextStyle(
                                        color: _resendCountdown > 0
                                            ? Colors.grey
                                            : const Color(0xFF1A6B6B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
