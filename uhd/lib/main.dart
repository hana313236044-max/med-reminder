import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uhd/Splash.dart';
import 'package:uhd/firebase_options.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          home: const SplashScreen(),
        );
      },
    );
  }
}
