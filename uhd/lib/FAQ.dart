import 'package:flutter/material.dart';
import 'package:uhd/auth_widgets.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = [
      _FAQItem(
        question: 'What is MediTrack for?',
        answer:
            'MediTrack helps you save your medicines, create reminders, and quickly see what is taken, waiting, delayed, or missed.',
      ),
      _FAQItem(
        question: 'Can I add a medicine without a reminder?',
        answer:
            'Yes. Save medicines first in the Medicine tab, then use them later when creating reminders.',
      ),
      _FAQItem(
        question: 'Why cant I edit old reminders?',
        answer:
            'Past reminders are locked so your medicine history stays clear. If a waiting reminder passes, it becomes Not taken.',
      ),
      _FAQItem(
        question: 'Can I repeat a reminder?',
        answer:
            'Yes. You can schedule repeated reminders for a number of days, like every 4 hours for 7 days.',
      ),
      _FAQItem(
        question: 'Is my data saved online?',
        answer:
            'Not yet. This version has no backend, so the app works as a local prototype for now.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'FAQ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          const _PageIntro(
            icon: Icons.quiz_outlined,
            title: 'Questions about the app',
            subtitle:
                'A quick guide to how MediTrack handles medicines, reminders, and missed doses.',
          ),
          const SizedBox(height: 18),
          const _AboutAppCard(),
          const SizedBox(height: 18),
          ...questions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FAQCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });
}

class _FAQCard extends StatelessWidget {
  final _FAQItem item;

  const _FAQCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2F3F0)),
          boxShadow: [
            BoxShadow(
              color: authPrimary.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: authPrimary,
          collapsedIconColor: Colors.blueGrey.shade400,
          title: Text(
            item.question,
            style: const TextStyle(
              color: authInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answer,
                style: TextStyle(
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutAppCard extends StatelessWidget {
  const _AboutAppCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2F3F0)),
        boxShadow: [
          BoxShadow(
            color: authPrimary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medication_outlined, color: authPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About MediTrack',
                  style: TextStyle(
                    color: authInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'MediTrack is a simple medicine reminder app for keeping your storage, schedules, and daily medicine status in one calm place.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _PageIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2F3F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: authPrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w600,
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
