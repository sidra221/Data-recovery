import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  static const _accent = Color(0xFF0891B2);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).login(
            username: _identifierController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(
        error.message.isNotEmpty ? error.message : 'Invalid login credentials',
      );
    } catch (_) {
      if (!mounted) return;
      _showError('Invalid login credentials');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  BoxDecoration get _fieldShadow {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: ClipPath(
                clipper: _HeaderBlobClipper(),
                child: ColoredBox(
                  color: Color(0xFFF3F4F6),
                  child: SizedBox(height: 210, width: double.infinity),
                ),
              ),
            ),
          ),
          const Positioned(
            top: -20,
            right: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(90, 90),
                    painter: _StripedCirclePainter(),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 96,
                      height: 96,
                      errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.storage_rounded, size: 32, color: _accent),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Access your dashboard and manage recovery cases',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 32),
                          DecoratedBox(
                            decoration: _fieldShadow,
                            child: TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !_isSubmitting,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                              decoration: _fieldDecoration(
                                hint: 'Email or Phone',
                                prefix: const Icon(Icons.person_outline, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: _fieldShadow,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !_isSubmitting,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                              decoration: _fieldDecoration(
                                hint: 'Password',
                                prefix: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting ? null : () {},
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [_gradientStart, _gradientEnd],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting ? null : _submit,
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  height: 52,
                                  child: Center(
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Sign in',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            right: -20,
            bottom: -10,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: CustomPaint(
                  size: Size(190, 76),
                  painter: _WavesPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBlobClipper extends CustomClipper<Path> {
  const _HeaderBlobClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 0);
    path.lineTo(0, size.height * 0.62);
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height,
      size.width * 0.52,
      size.height * 0.78,
    );
    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.54,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _StripedCirclePainter extends CustomPainter {
  const _StripedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var x = 3.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, size.height * 0.85);
    canvas.rotate(-0.55);

    final paint = Paint()
      ..color = const Color(0xFF5CCBED)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final path = Path();
      final baseline = i * 14.0;
      path.moveTo(0, baseline);
      for (var x = 0.0; x <= size.width * 1.15; x += 2) {
        final y = baseline + math.sin((x / size.width) * math.pi * 2.4) * 8;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
