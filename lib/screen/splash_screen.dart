import 'package:flutter/material.dart';
import 'package:food_pick_app/widget/appbars.dart';
import 'package:food_pick_app/widget/buttons.dart';
import 'package:food_pick_app/widget/texts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(
      Duration(milliseconds: 1500),
      () {
        // 1.5초 뒤에 실행될 로직 구현
        Navigator.popAndPushNamed(context, '/login');
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 46),
            Text(
              'Food PICK',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
