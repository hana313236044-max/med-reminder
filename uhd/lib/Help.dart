import 'package:flutter/material.dart';
import 'package:uhd/About.dart';
import 'package:uhd/ContactUs.dart';
import 'package:uhd/FAQ.dart';
import 'package:uhd/GettingStart.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Getting Started',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Icon(Icons.arrow_forward, color: Colors.black, size: 24),
              ],
            ),
            onPressed: () {Navigator.push(
  context,
  
  MaterialPageRoute(builder: (context) => const GettingStartedPage()),
);
},
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FAQs',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Icon(Icons.arrow_forward, color: Colors.black, size: 24),
              ],
            ),
            onPressed: () {Navigator.push(
  context,
  
  MaterialPageRoute(builder: (context) => const HelpSupportPage()),);},
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact Us',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Icon(Icons.arrow_forward, color: Colors.black, size: 24),
              ],
            ),
            onPressed: () {Navigator.push(
  context,
  //roshtn bo page cotact
  MaterialPageRoute(builder: (context) => const ContactUsPage()),
);},

          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About App',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Icon(Icons.arrow_forward, color: Colors.black, size: 24),
              ],
            ),
            // detaily about page ka arwat bo page about
            onPressed: () {Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AboutPage()),
);
},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
