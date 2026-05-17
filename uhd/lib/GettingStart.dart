import 'package:flutter/material.dart';
import 'package:uhd/auth_widgets.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  static const List<_GuideStep> _steps = [
    _GuideStep(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Create an account',
      description: 'Sign up with your email, age, and blood type.',
    ),
    _GuideStep(
      icon: Icons.medication_liquid_outlined,
      title: 'Add your medicines',
      description: 'Save the medicine name, category, and useful notes.',
    ),
    _GuideStep(
      icon: Icons.notifications_active_outlined,
      title: 'Set reminders',
      description: 'Choose the time and condition for each medicine.',
    ),
    _GuideStep(
      icon: Icons.checklist_rtl_outlined,
      title: 'Track your day',
      description: 'Review reminders and keep your treatment routine clear.',
    ),
    _GuideStep(
      icon: Icons.settings_outlined,
      title: 'Adjust anytime',
      description:
          'Update settings, medicines, and reminders as things change.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: AuthCard(
        maxWidth: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              icon: Icons.favorite_border,
              title: 'Getting started',
              subtitle: 'A quick path from first login to your first reminder.',
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: appSurfaceColor(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      color: authPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'MediTrack helps you keep medicine routines simple, visible, and easy to update.',
                      style: TextStyle(
                        color: appMutedTextColor(context),
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _steps.length; i++) ...[
              StepCard(
                stepNumber: i + 1,
                icon: _steps[i].icon,
                title: _steps[i].title,
                description: _steps[i].description,
              ),
              if (i != _steps.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Back to Login',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class StepCard extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final String title;
  final String description;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: authPrimary, size: 25),
              ),
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: authPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appSurfaceColor(context),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String description;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
