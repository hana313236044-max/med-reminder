import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/screens/splash_screen.dart';
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
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: authPrimary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: authPrimary,
              brightness: Brightness.dark,
              surface: appDarkSurface,
            ),
            scaffoldBackgroundColor: appDarkBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: authPrimary,
              foregroundColor: Colors.white,
            ),
            cardColor: appDarkSurface,
            dialogTheme: const DialogThemeData(
              backgroundColor: appDarkSurface,
              surfaceTintColor: Colors.transparent,
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: authPrimary,
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          ),
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
