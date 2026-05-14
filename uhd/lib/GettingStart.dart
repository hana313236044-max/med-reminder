import 'package:flutter/material.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Welcome to MediTrackApp',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Column(
                
           
              children: [
                Text(
                  'Follow these simple steps to start using the app.',
                  style: TextStyle(fontSize: 16),
                ),
                
              ],
            
           ),
           
            SizedBox(height: 20),
             
            StepCard(
              
              stepNumber: 1,
              title: 'Create an Account or Log In',
              description:
                  'Sign up using your details or log in if you already have an account.',
                  

            ),
            StepCard(
              stepNumber: 2,
              title: 'Set Up Your Profile',
              description:
                  'Complete your profile with basic personal or professional information.',
            ),
            StepCard(
              stepNumber: 3,
              title: 'Add Medical Information',
              description:
                  'Enter patient records, medical history, or treatment details.',
            ),
            StepCard(
              stepNumber: 4,
              title: 'Manage Appointments',
              description:
                  'Schedule, view, and track appointments in one place.',
            ),
            StepCard(
              stepNumber: 5,
              title: 'Track and Update Data',
              description:
                  'Keep records updated to ensure accurate medical information.',
            ),
          ],
        ),
      ),
    );
  }
}

class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal,
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}