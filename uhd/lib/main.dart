import 'package:flutter/material.dart';
import 'package:uhd/Home.dart';
import 'package:uhd/Splash.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() {
  runApp(const Midterm());
}

class Midterm extends StatelessWidget {
  const Midterm({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          darkTheme: ThemeData.dark(),
          themeMode: currentMode,
          home: HomePage(
            userName: 'User',
            email: 'user@example.com',
            age: 'Not added',
            bloodType: 'Not added',
          ),
        );
      },
    );
  }
}
