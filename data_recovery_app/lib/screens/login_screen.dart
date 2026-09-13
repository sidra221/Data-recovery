import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import 'widgets/app_button.dart';

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

  static const _accent = Color(0xFF33BEE9);

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
      // ما منتنقّل من هون: _AuthGate بـ main.dart بيبدّل الشاشة
      // لما تصير الحالة authenticated. تنقّل يدوي هون بيكدّس HomeScreen مرتين.
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
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          color: Color(0x1A000000),
          blurRadius: 18,
          offset: Offset(0, 8),
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
                  color: Color(0xFFF1F2F4),
                  child: SizedBox(height: 250, width: double.infinity),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 18,
            left: -40,
            child: IgnorePointer(
              child: ClipPath(
                clipper: _SoftWaveClipper(),
                child: ColoredBox(
                  color: Colors.white,
                  child: SizedBox(width: 220, height: 90),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 210,
            right: -48,
            child: IgnorePointer(
              child: CustomPaint(
                size: Size(120, 120),
                painter: _StripedCirclePainter(),
              ),
            ),
          ),
          const Positioned(
            right: -30,
            bottom: -24,
            child: IgnorePointer(
              child: CustomPaint(
                size: Size(240, 140),
                painter: _BrushStrokePainter(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 88,
                          height: 88,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.storage_rounded,
                            size: 48,
                            color: _accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Access your dashboard and manage recovery cases',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 40),
                    DecoratedBox(
                      decoration: _fieldShadow,
                      child: TextFormField(
                        controller: _identifierController,
                        // اسم المستخدم فقط: create_employee ما بيحط إيميل،
                        // وإيميل Django مش فريد. والكيبورد لازم ما يكبّر أول حرف.
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        enabled: !_isSubmitting,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                        decoration: _fieldDecoration(
                          hint: 'Username',
                          prefix: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          prefix: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
                          suffix: IconButton(
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Sign in',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 80),
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

class _HeaderBlobClipper extends CustomClipper<Path> {
  const _HeaderBlobClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 0);
    path.lineTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.18,
      size.height * 1.05,
      size.width * 0.42,
      size.height * 0.62,
      size.width * 0.62,
      size.height * 0.78,
    );
    path.cubicTo(
      size.width * 0.82,
      size.height * 0.94,
      size.width * 0.92,
      size.height * 0.5,
      size.width,
      size.height * 0.58,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SoftWaveClipper extends CustomClipper<Path> {
  const _SoftWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.05,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF111827));
    final stripe = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var x = 8.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrushStrokePainter extends CustomPainter {
  const _BrushStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.15, size.height * 0.55);
    canvas.rotate(-0.42);

    final paint = Paint()
      ..color = const Color(0xFF5CCBED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, 0);
    for (var x = 0.0; x <= size.width; x += 2) {
      final y = math.sin((x / size.width) * math.pi * 1.6) * 16;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final inner = Paint()
      ..color = const Color(0x995CCBED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.translate(0, 16);
    canvas.drawPath(path, inner);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
