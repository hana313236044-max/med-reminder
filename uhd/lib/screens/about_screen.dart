// This screen explains the app and version information.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uhd/widgets/app_widgets.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'images/aa.jpg',
    'images/bb.jpg',
    'images/yy.jpg',
  ];

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= _images.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// ===== AUTO IMAGE SLIDER =====
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                  maxHeight: 350,
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Image.asset(
                          _images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "About This Application",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: appTextColor(context),
              ),
            ),

            const SizedBox(height: 20),

            _infoCard(
              context: context,
              title: "What is this application?",
              icon: Icons.info_outline,
              content:
                  "This application helps users manage tasks, access features, "
                  "and perform daily activities efficiently.",
            ),

            _infoCard(
              context: context,
              title: "How to use the application",
              icon: Icons.touch_app,
              content:
                  "• Navigate using the main menu\n"
                  "• Customize settings like Dark Mode\n"
                  "• Complete tasks quickly\n"
                  "• Learn more from About section",
            ),

            _infoCard(
              context: context,
              title: "Goal of this application",
              icon: Icons.flag_outlined,
              content:
                  "To simplify workflows, improve productivity, and "
                  "deliver a smooth modern experience.",
            ),

            const SizedBox(height: 24),

            Text(
              "Version 1.0.0",
              textAlign: TextAlign.center,
              style: TextStyle(color: appMutedTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  // helper method for cards
  static Widget _infoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      color: appSurfaceColor(context),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: authPrimary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: appTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(color: appMutedTextColor(context), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
