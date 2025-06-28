import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final Color overlayColor;
  final double overlayOpacity;

  const BackgroundScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar, // Usamos directamente el appBar que te pasan
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_planlive.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: overlayColor.withOpacity(overlayOpacity),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

