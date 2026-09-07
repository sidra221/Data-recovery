import 'package:flutter/material.dart';

enum AppButtonVariant { primary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.height = 52,
    this.width,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final IconData? icon;

  static const radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDanger = variant == AppButtonVariant.danger;
    const primaryStart = Color(0xFF5CCBED);
    const primaryEnd = Color(0xFF2EABD2);
    const dangerStart = Color(0xFFFF8A7A);
    const dangerEnd = Color(0xFFE11D48);
    final shadow = isDanger ? dangerEnd : const Color(0xFF33BEE9);

    return Container(
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDanger ? const [dangerStart, dangerEnd] : const [primaryStart, primaryEnd],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              child: SizedBox(
                height: height,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
