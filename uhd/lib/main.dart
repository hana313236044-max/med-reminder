import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uhd/screens/auth_gate.dart';
import 'package:uhd/screens/cart_page.dart';
import 'package:uhd/screens/checkout_page.dart';
import 'package:uhd/screens/medicine_library_details_page.dart';
import 'package:uhd/screens/pharmacy_details_page.dart';
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
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? '';
            if (routeName == '/medicine-library') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const AuthGate(initialHomeTab: 2),
              );
            }
            if (routeName == '/pharmacies') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const AuthGate(initialHomeTab: 3),
              );
            }
            if (routeName == '/cart') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CartPage(),
              );
            }
            if (routeName == '/checkout') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CheckoutPage(),
              );
            }
            if (routeName.startsWith('/medicine-library/')) {
              final medicineId = Uri.decodeComponent(
                routeName.substring('/medicine-library/'.length),
              );
              final args = settings.arguments;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => MedicineLibraryDetailsPage(
                  medicineId: medicineId,
                  onSaveMedicine: args is MedicineLibraryDetailsRouteArguments
                      ? args.onSaveMedicine
                      : null,
                ),
              );
            }
            if (routeName.startsWith('/pharmacies/')) {
              final pharmacyId = Uri.decodeComponent(
                routeName.substring('/pharmacies/'.length),
              );
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => PharmacyDetailsPage(pharmacyId: pharmacyId),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
