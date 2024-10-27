import 'package:flutter/material.dart';
import 'dart:async';

import 'gass_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0; // Initial opacity for fade-in animation

  @override
  void initState() {
    super.initState();

    // Start the animation and navigate to home screen after a delay
    _startAnimation();
    _navigateToHome();
  }

  void _startAnimation() {
    // Delay to allow for smooth animation
    Timer(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0; // Change opacity to fully visible
      });
    });
  }

  void _navigateToHome() {
    // Wait for the splash screen duration
    Timer(Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GasScreen(),
        ),
      ); // Replace '/home' with your main route
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Customize your background color if needed
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: Duration(seconds: 2), // Control animation speed
          child: Image.asset(
            'assets/images/gas.png', // Your gas.png image path
            width: 200, // Adjust the size of the image
            height: 200,
          ),
        ),
      ),
    );
  }
}
