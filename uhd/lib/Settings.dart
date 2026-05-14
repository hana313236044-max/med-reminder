 import 'package:flutter/material.dart';
import 'package:uhd/Login_Screen.dart';
import 'package:uhd/main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool notificationsEnabled = true;
  bool darkMode = false;

  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(//scroll haea
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'),
            subtitle: Text('Turn medicine reminders on/off'),
            value: notificationsEnabled,//doxy switch off and on bet
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          size: 20,
                          color: Colors.white,
                        ),
                        Text(
                          notificationsEnabled
                              ? 'Notifications Enabled'
                              : 'Notifications Disabled',
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
            secondary: Icon(Icons.notifications),
          ),

          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Better for night use'),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (bool value) {
              setState(() {
                themeNotifier.value =
                    value ? ThemeMode.dark : ThemeMode.light;
              });
            },
            secondary: Icon(Icons.dark_mode),
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text(selectedLanguage),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String tempLanguage = selectedLanguage;//gorawy katy bo halbzhardny zman

                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: Text('Select Language'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(//halbzhardny zman
                              title: Text('English'),
                              value: 'English',
                              groupValue: tempLanguage,
                              onChanged: (value) {
                                setStateDialog(() {
                                  tempLanguage = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('کوردی'),
                              value: 'Kurdish',
                              groupValue: tempLanguage,
                              onChanged: (value) {
                                setStateDialog(() {
                                  tempLanguage = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('عربي'),
                              value: 'Arabic',
                              groupValue: tempLanguage,
                              onChanged: (value) {
                                setStateDialog(() {
                                  tempLanguage = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(//zmany halbzherdraw jeger aby
                            onPressed: () {
                              setState(() {
                                selectedLanguage = tempLanguage;
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Language changed to $selectedLanguage'),//ka zmanek halabzheren awa peshan ayat
                                ),
                              );
                            },
                            child: Text('Apply'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          Divider(),

          // 🗑️ DELETE ACCOUNT (ADDED)
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Delete Account'),
                    content: Text(
                        'Are you sure you want to delete your account? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Account deleted successfully'),
                            ),
                          );

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
