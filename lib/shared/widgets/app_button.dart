import 'package:flutter/material.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = !widget.isLoading && widget.onPressed != null;

    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.97 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? const [
                      Color(0xFF14B8A6),
                      Color(0xFF0EA5E9),
                      Color(0xFF7C3AED),
                    ]
                  : [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surfaceContainerHighest,
                    ],
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: isEnabled ? widget.onPressed : null,
              onHighlightChanged: isEnabled ? _setPressed : null,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: colorScheme.onPrimary,
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
