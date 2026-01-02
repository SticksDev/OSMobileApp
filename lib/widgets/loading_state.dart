import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingState extends StatefulWidget {
  final String? message;
  final bool useNavbarLogo;
  final double size;

  const LoadingState({
    super.key,
    this.message,
    this.useNavbarLogo = false,
    this.size = 80,
  });

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: SvgPicture.asset(
              widget.useNavbarLogo
                  ? 'assets/os/NavbarLogoSpin.svg'
                  : 'assets/os/IconLoadingSpin.svg',
              width: widget.size,
              height: widget.size,
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
