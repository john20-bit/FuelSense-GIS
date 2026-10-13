import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingOrb extends StatefulWidget {
  const LoadingOrb({super.key, this.size = 90});

  final double size;

  @override
  State<LoadingOrb> createState() => _LoadingOrbState();
}

class _LoadingOrbState extends State<LoadingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,

      child: Container(
        width: widget.size,

        height: widget.size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),

          boxShadow: [
            BoxShadow(
              color: AppColors.primary,

              blurRadius: 35,

              spreadRadius: 5,
            ),
          ],
        ),

        child: Center(
          child: Container(
            width: widget.size * 0.35,

            height: widget.size * 0.35,

            decoration: const BoxDecoration(
              color: Colors.white,

              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
