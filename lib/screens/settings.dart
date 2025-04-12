// import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io' show Platform;
//
// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});
//
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   String _appVersion = '';
//   bool _isDarkMode = false;
//   bool _notificationsEnabled = false;
//   String _selectedLanguage = 'English';
//   final _prefs = SharedPreferences.getInstance();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//     if (Platform.isAndroid || Platform.isIOS) {
//       _loadAppVersion();
//     }
//   }
//
//   Future<void> _loadSettings() async {
//     final prefs = await _prefs;
//     setState(() {
//       _isDarkMode = prefs.getBool('darkMode') ?? false;
//       _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
//       _selectedLanguage = prefs.getString('language') ?? 'English';
//     });
//   }
//
//   Future<void> _loadAppVersion() async {
//     try {
//       final packageInfo = await PackageInfo.fromPlatform();
//       setState(() {
//         _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
//       });
//     } catch (e) {
//       setState(() {
//         _appVersion = 'Error loading version';
//       });
//     }
//   }
//
//   Future<void> _toggleDarkMode(bool value) async {
//     final prefs = await _prefs;
//     await prefs.setBool('darkMode', value);
//     setState(() {
//       _isDarkMode = value;
//     });
//   }
//
//   // Future<void> _toggleNotifications(bool value) async {
//   //   final prefs = await _prefs;
//   //   await prefs.setBool('notificationsEnabled', value);
//   //   setState(() {
//   //     _notificationsEnabled = value;
//   //   });
//   // }
//
//   Future<void> _changeLanguage(String language) async {
//     final prefs = await _prefs;
//     await prefs.setString('language', language);
//     setState(() {
//       _selectedLanguage = language;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//       ),
//       body: ListView(
//         children: [
//           if (Platform.isAndroid || Platform.isIOS) ...[
//             const SectionHeader(title: 'App Information'),
//             ListTile(
//               title: const Text('Version'),
//               subtitle: Text(_appVersion),
//             ),
//           ],
//           // const SectionHeader(title: 'Appearance'),
//           // SwitchListTile(
//           //   title: const Text('Dark Mode'),
//           //   subtitle: const Text('Toggle dark/light theme'),
//           //   value: _isDarkMode,
//           //   onChanged: (bool value) {
//           //     _toggleDarkMode(value);
//           //   },
//           // ),
//           // const SectionHeader(title: 'Notifications'),
//           // SwitchListTile(
//           //   title: const Text('Enable Notifications'),
//           //   value: _notificationsEnabled,
//           //   onChanged: (bool value) {
//           //     _toggleNotifications(value);
//           //   },
//           // ),
//           const SectionHeader(title: 'Language'),
//           ListTile(
//             title: const Text('App Language'),
//             subtitle: Text(_selectedLanguage),
//             onTap: () async {
//               final selectedLanguage = await showDialog<String>(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return SimpleDialog(
//                     title: const Text('Select Language'),
//                     children: <Widget>[
//                       SimpleDialogOption(
//                         onPressed: () {
//                           Navigator.pop(context, 'English');
//                         },
//                         child: const Text('English'),
//                       ),
//                       // Add more languages here
//                     ],
//                   );
//                 },
//               );
//               if (selectedLanguage != null) {
//                 _changeLanguage(selectedLanguage);
//               }
//             },
//           ),
//           // const SectionHeader(title: 'About'),
//           // ListTile(
//           //   title: const Text('Privacy Policy'),
//           //   leading: const Icon(Icons.privacy_tip_outlined),
//           //   onTap: () {
//           //   },
//           // ),
//         ],
//       ),
//     );
//   }
// }
//
// class SectionHeader extends StatelessWidget {
//   final String title;
//
//   const SectionHeader({super.key, required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//           color: Theme.of(context).colorScheme.primary,
//         ),
//       ),
//     );
//   }
// }
