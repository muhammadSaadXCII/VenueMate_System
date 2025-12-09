import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  const CommonButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorToUse = backgroundColor ?? const Color(0xFFF47C20);

    final foregroundColorToUse = foregroundColor ?? Colors.white;

    final radiusToUse = borderRadius ?? 12.0;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorToUse,
          foregroundColor: foregroundColorToUse.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusToUse),
          ),
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(icon, color: foregroundColorToUse, size: 20),
              ),

            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: foregroundColorToUse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
