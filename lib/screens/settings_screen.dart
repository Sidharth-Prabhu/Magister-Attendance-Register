import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'theme_provider.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(List<Classroom>) onClassroomsUpdated;

  SettingsScreen({required this.onClassroomsUpdated});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = "Version ${packageInfo.version}";
    });
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ThemeProvider().toggleTheme(value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _backupData() async {
    // ...unchanged backup logic
  }

  Future<void> _restoreData() async {
    // ...unchanged restore logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header with app logo and version
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/logo.png'), // App logo
              ),
              SizedBox(height: 10),
              Text(
                'Magister',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(_appVersion, style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30),
            ],
          ),

          // Appearance section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(fontSize: 16)),
              secondary: Icon(Icons.dark_mode),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          SizedBox(height: 20),

          // Data management section
          Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_download_outlined),
                  title: Text('Backup Data'),
                  subtitle: Text('Export app data to .mbf file'),
                  onTap: _backupData,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore Data'),
                  subtitle: Text('Import app data from .mbf file'),
                  onTap: _restoreData,
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Developer info
          Column(
            children: [
              Text('Developed by', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/dev_logo_dark.png'
                    : 'assets/dev_logo_light.png',
                height: 40,
              ),
 // Developer/company logo
              SizedBox(height: 10),
              Text(
                '© ${DateTime.now().year} Frissco Creative Labs',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
