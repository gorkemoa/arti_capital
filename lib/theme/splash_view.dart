import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  final Widget nextRoute;
  
  const SplashView({super.key, required this.nextRoute});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.nextRoute,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash_image.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


