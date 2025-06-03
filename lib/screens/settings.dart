import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsync/screens/sign_out.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  // bool _isDarkMode = false;
  // bool _notificationsEnabled = false;
  String _selectedLanguage = 'English';
  final _prefs = SharedPreferences.getInstance();

  // Add GitHub and Crowdin URLs
  final String _githubUrl = 'https://github.com/aadishsamir123/asdev-shopsync';
  final String _crowdinUrl = 'https://crowdin.com/project/as-shopsync';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      // _isDarkMode = prefs.getBool('darkMode') ?? false;
      // _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (kIsWeb) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
      if (!kIsWeb) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      setState(() {
        _appVersion = 'Error loading version';
      });
    }
  }

  // Future<void> _toggleDarkMode(bool value) async {
  //   final prefs = await _prefs;
  //   await prefs.setBool('darkMode', value);
  //   setState(() {
  //     _isDarkMode = value;
  //   });
  // }

  // Future<void> _toggleNotifications(bool value) async {
  //   final prefs = await _prefs;
  //   await prefs.setBool('notificationsEnabled', value);
  //   setState(() {
  //     _notificationsEnabled = value;
  //   });
  // }

  Future<void> _changeLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Future<void> _signOut() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignOutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF181A20) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF23262B) : Colors.white;
    final iconColor = isDark ? Colors.green[200]! : Colors.green[700]!;
    final textColor = isDark ? Colors.white : Colors.grey[900]!;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    Widget buildSettingsTile({
      required IconData icon,
      required String title,
      String? subtitle,
      Color? iconColorOverride,
      Color? textColorOverride,
      VoidCallback? onTap,
      bool isDestructive = false,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(30)
                  : Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColorOverride ?? iconColor).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              icon,
              color: iconColorOverride ?? iconColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color:
                  isDestructive ? Colors.red : (textColorOverride ?? textColor),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                )
              : null,
          trailing: onTap != null
              ? Icon(Icons.chevron_right,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])
              : null,
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // About App Section
          SectionHeader(title: 'About App', color: iconColor),
          buildSettingsTile(
            icon: FontAwesomeIcons.circleInfo,
            title: 'App Version',
            subtitle: _appVersion,
            iconColorOverride: iconColor,
          ),
          buildSettingsTile(
            icon: FontAwesomeIcons.github,
            title: 'GitHub Repository',
            subtitle: 'View source code',
            // iconColorOverride: Colors.black,
            onTap: () => _launchUrl(_githubUrl),
          ),
          buildSettingsTile(
            icon: FontAwesomeIcons.language,
            title: 'Help Translate',
            subtitle: 'Contribute on Crowdin',
            iconColorOverride: Colors.blue[700],
            onTap: () => _launchUrl(_crowdinUrl),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: dividerColor, thickness: 1.2),
          ),
          // Settings Section
          SectionHeader(title: 'Settings', color: iconColor),
          buildSettingsTile(
            icon: FontAwesomeIcons.rightFromBracket,
            title: 'Sign Out',
            iconColorOverride: Colors.red,
            textColorOverride: Colors.red,
            isDestructive: true,
            onTap: _signOut,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: dividerColor, thickness: 1.2),
          ),
          SectionHeader(title: 'Language', color: iconColor),
          buildSettingsTile(
            icon: FontAwesomeIcons.language,
            title: 'App Language',
            subtitle: _selectedLanguage,
            onTap: () async {
              final selectedLanguage = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    backgroundColor: cardColor,
                    title: Text('Select Language',
                        style: TextStyle(color: textColor)),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'English');
                        },
                        child:
                            Text('English', style: TextStyle(color: textColor)),
                      ),
                      // Add more languages here
                    ],
                  );
                },
              );
              if (selectedLanguage != null) {
                _changeLanguage(selectedLanguage);
              }
            },
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const SectionHeader({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
