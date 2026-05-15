import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/ContactUs.dart';
import 'package:uhd/FAQ.dart';
import 'package:uhd/auth_gate.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/main.dart';

class AppSettings extends StatefulWidget {
  final bool showScaffold;

  const AppSettings({super.key, this.showScaffold = true});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  bool notificationsEnabled = true;
  String selectedLanguage = 'English';

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _settingsRef {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('app');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final body = _SettingsBody(
      notificationsEnabled: notificationsEnabled,
      selectedLanguage: selectedLanguage,
      onNotificationsChanged: _setNotifications,
      onThemeChanged: _setTheme,
      onLanguageTap: _pickLanguage,
      onFaqTap: _showFaq,
      onContactTap: _showContactUs,
      onDeleteAccount: _confirmDeleteAccount,
      onLogout: _confirmLogout,
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: body,
    );
  }

  Future<void> _loadSettings() async {
    final settingsRef = _settingsRef;
    if (settingsRef == null) return;

    final snapshot = await settingsRef.get();
    final data = snapshot.data();
    if (data == null || !mounted) return;

    setState(() {
      notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
      selectedLanguage = data['language'] as String? ?? 'English';
      themeNotifier.value = data['darkMode'] == true
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _saveSettings(Map<String, dynamic> data) async {
    final settingsRef = _settingsRef;
    if (settingsRef == null) return;

    await settingsRef.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _setNotifications(bool value) {
    setState(() => notificationsEnabled = value);
    _saveSettings({'notificationsEnabled': value});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications enabled' : 'Notifications disabled',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: authPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _setTheme(bool value) {
    setState(() {
      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    });
    _saveSettings({'darkMode': value});
  }

  Future<void> _pickLanguage() async {
    var tempLanguage = selectedLanguage;
    final language = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LanguageOption(
                    title: 'English',
                    value: 'English',
                    groupValue: tempLanguage,
                    onChanged: (value) =>
                        setDialogState(() => tempLanguage = value),
                  ),
                  _LanguageOption(
                    title: 'Kurdish',
                    value: 'Kurdish',
                    groupValue: tempLanguage,
                    onChanged: (value) =>
                        setDialogState(() => tempLanguage = value),
                  ),
                  _LanguageOption(
                    title: 'Arabic',
                    value: 'Arabic',
                    groupValue: tempLanguage,
                    onChanged: (value) =>
                        setDialogState(() => tempLanguage = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: authPrimary),
                  onPressed: () => Navigator.pop(context, tempLanguage),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (language == null) return;
    setState(() => selectedLanguage = language);
    await _saveSettings({'language': selectedLanguage});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $selectedLanguage'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: authPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await _logout();
      return;
    }

    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        DateTime.now().difference(lastSignIn) > const Duration(minutes: 5)) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Please logout, login again, then delete your account.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    try {
      await _deleteUserData(user.uid);
      await user.delete();
      if (!mounted) return;
      showAuthMessage(
        context,
        'Account deleted successfully',
        backgroundColor: Colors.redAccent,
      );
      await _logout();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      showAuthMessage(
        context,
        error.code == 'requires-recent-login'
            ? 'Please logout, login again, then delete your account.'
            : error.message ?? 'Could not delete account',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);
    final batch = firestore.batch();

    for (final collectionName in ['medicines', 'reminders', 'settings']) {
      final snapshot = await userRef.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    batch.delete(userRef);
    await batch.commit();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Do you want to logout and return to login?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  void _showFaq() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FAQPage()),
    );
  }

  void _showContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactUsPage()),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final bool notificationsEnabled;
  final String selectedLanguage;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onLanguageTap;
  final VoidCallback onFaqTap;
  final VoidCallback onContactTap;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  const _SettingsBody({
    required this.notificationsEnabled,
    required this.selectedLanguage,
    required this.onNotificationsChanged,
    required this.onThemeChanged,
    required this.onLanguageTap,
    required this.onFaqTap,
    required this.onContactTap,
    required this.onDeleteAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: authInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage reminders, display, and account options.',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          children: [
            _SettingsSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Enable notifications',
              subtitle: 'Turn medicine reminders on or off',
              value: notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
            _SettingsSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              subtitle: 'Better for night use',
              value: themeNotifier.value == ThemeMode.dark,
              onChanged: onThemeChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          children: [
            _SettingsActionTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: selectedLanguage,
              trailing: Icons.chevron_right,
              onTap: onLanguageTap,
            ),
            _SettingsActionTile(
              icon: Icons.quiz_outlined,
              title: 'FAQ',
              subtitle: 'Common app questions',
              trailing: Icons.chevron_right,
              onTap: onFaqTap,
            ),
            _SettingsActionTile(
              icon: Icons.support_agent_outlined,
              title: 'Contact us',
              subtitle: 'Get help or send feedback',
              trailing: Icons.chevron_right,
              onTap: onContactTap,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          children: [
            _SettingsActionTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Return to the login screen',
              danger: true,
              onTap: onLogout,
            ),
            _SettingsActionTile(
              icon: Icons.delete_outline,
              title: 'Delete account',
              subtitle: 'Remove your account from this device',
              danger: true,
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      activeColor: authPrimary,
      secondary: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(color: authInk, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.blueGrey.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final bool danger;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : authPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _SettingsIcon(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? Colors.redAccent : authInk,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.blueGrey.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing == null
          ? null
          : Icon(trailing, color: Colors.blueGrey.shade400),
      onTap: onTap,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, this.color = authPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _LanguageOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      activeColor: authPrimary,
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
