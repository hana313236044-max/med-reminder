import 'package:flutter/material.dart';
import 'package:uhd/ContactUs.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFFFF5FA),
      appBar: AppBar(
        title:  Text("Frequently Asked Questions"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding:  EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Need Help?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _faqItem(
              question: "How do I get started with the app?",
              answer:
                  "To get started, create an account or log in. "
                  "After logging in, explore the main menu to access features.",
            ),

            _faqItem(
              question: "How can I reset my password?",
              answer:
                  "Go to the login screen and tap on 'Forgot Password'. "
                  "Follow the instructions sent to your email.",
            ),

            _faqItem(
              question: "Does the app support Dark Mode?",
              answer:
                  "Yes, you can enable Dark Mode from the Settings page "
                  "to improve visibility and save battery.",
            ),

            _faqItem(
              question: "How do I contact support?",
              answer:
                  "You can contact support from the 'Contact Us' section "
                  "or send an email to our support team.",
            ),

            _faqItem(
              question: "Is my data safe?",
              answer:
                  "Yes, we take data security seriously. "
                  "Your data is encrypted and securely stored.",
            ),

             SizedBox(height: 30),

            Center(
              child: TextButton(
                onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsPage()));},
                child: Text(
                  "Still need help? Contact us anytime.",

                  style: TextStyle(color: Colors.grey.shade700),  
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _faqItem({required String question, required String answer}) {
    return Card(
      elevation: 4,  //shadowy bashi xwaraua 
      margin:  EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        iconColor: Colors.redAccent,//ka aikainawa rangy sahmaka nameny
        collapsedIconColor: Colors.redAccent,//rangy sahmakay xwarawa nameny
        title: Text(
          question,
          style:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding:  EdgeInsets.all(16),
            child: Text(answer, style:  TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
