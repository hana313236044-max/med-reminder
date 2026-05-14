import 'package:flutter/material.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});//key bo nasenaway widget-aka

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();//leraea peman alet am widget la claseky tr barewa achet
}

class _ContactUsPageState extends State<ContactUsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Us'), centerTitle: true,
      backgroundColor: Colors.purple[200],),

      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),//icon u email u phone la naw container la saratawa abet ba py zhmarakay ka
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,//hamuy abata nawarast
            children: [
              Icon(Icons.contact_mail, size: 100, color: Colors.blueGrey),//rangy icony nawarast
              SizedBox(height: 32),
              Text(
                'Contact Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 24),

              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.email),
                    SizedBox(width: 16),//naw emailaka dur akawetawa la iconaka
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('support@example.com'),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded),
                    SizedBox(width: 16),//naw raqamaka dur akawetawa la iconaka
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('+964 770 123 4567'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
